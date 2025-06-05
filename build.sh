#!/usr/bin/env bash
workdir=$(pwd)

# Write output logs into build.log file
exec > >(tee $workdir/build.log) 2>&1

# Import config and functions
source $workdir/config.sh
source $workdir/functions.sh

# Set timezone
sudo timedatectl set-timezone "$TIMEZONE"

# Clone kernel patches
SHIRKNEKO_PATCHES=https://github.com/ShirkNeko/SukiSU_patch
log "Cloning kernel patches from $(simplify_gh_url "$SHIRKNEKO_PATCHES")"
git clone -q --depth=1 $SHIRKNEKO_PATCHES shirkneko_patches

# Clone kernel source
log "Cloning kernel source from $(simplify_gh_url "$KERNEL_REPO")"
git clone -q --depth=1 $KERNEL_REPO -b $KERNEL_BRANCH ksrc

cd $workdir/ksrc
LINUX_VERSION=$(make kernelversion)
DEFCONFIG_FILE=$(find $workdir/ksrc/arch/arm64/configs -name "$KERNEL_DEFCONFIG")
cd $workdir

# Set KernelSU Variant
log "Setting KernelSU variant..."
case "$KSU" in
  "Next") VARIANT="KSUN" ;;
  "Suki") VARIANT="SUKISU" ;;
  "None") VARIANT="NKSU" ;;
  *) error "Invalid KernelSU Variant '$KSU'" ;;
esac
[[ $KSU_SUSFS == "true" ]] && VARIANT+="+SuSFS"

# Replace Placeholder in zip name
ZIP_NAME=${ZIP_NAME//KVER/$LINUX_VERSION}
ZIP_NAME=${ZIP_NAME//VARIANT/$VARIANT}

# Download Clang
CLANG_DIR="$workdir/clang"
if [[ -z "$CLANG_BRANCH" ]]; then
  log "🔽 Downloading Clang..."
  wget -q "$CLANG_URL" -O tarball || error "Failed to download Clang."
  mkdir -p "$CLANG_DIR"
  tar -xf tarball -C "$CLANG_DIR" || error "Failed to extract Clang."
  rm -f tarball

  if [[ $(find "$CLANG_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l) -eq 1 ]] \
    && [[ $(find "$CLANG_DIR" -mindepth 1 -maxdepth 1 -type f | wc -l) -eq 0 ]]; then
    SINGLE_DIR=$(find "$CLANG_DIR" -mindepth 1 -maxdepth 1 -type d)
    mv -f $SINGLE_DIR/* $CLANG_RIR/
    rm -rf $SINGLE_DIR
  fi
else
  log "🔽 Cloning Clang..."
  git clone --depth=1 -q "$CLANG_URL" -b "$CLANG_BRANCH" "$CLANG_DIR" || error "Failed to clone clang"
fi

export PATH="$CLANG_DIR/bin:$PATH"

# Extract clang version
COMPILER_STRING=$(clang -v 2>&1 | head -n 1 | sed 's/(https..*//' | sed 's/ version//')

# Clone GCC if not available
if ! ls $CLANG_DIR/bin | grep -q "aarch64-linux-gnu"; then
  log "🔽 Cloning GCC..."
  git clone --depth=1 -q https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-gnu-9.3 $workdir/gcc
  export PATH="$workdir/gcc/bin:$PATH"
  CROSS_COMPILE_PREFIX="aarch64-linux-"
else
  CROSS_COMPILE_PREFIX="aarch64-linux-gnu-"
fi

cd $workdir/ksrc

## KernelSU setup
if ksu_included; then
  for KSU_PATH in drivers/staging/kernelsu drivers/kernelsu KernelSU; do
    if [[ -d $KSU_PATH ]]; then
      log "KernelSU driver found in $KSU_PATH, Removing..."
      KSU_DIR=$(dirname "$KSU_PATH")

      [[ -f "$KSU_DIR/Kconfig" ]] && sed -i '/kernelsu/d' $KSU_DIR/Kconfig
      [[ -f "$KSU_DIR/Makefile" ]] && sed -i '/kernelsu/d' $KSU_DIR/Makefile

      rm -rf $KSU_PATH
    fi
  done

  log "Installing KernelSU..."
  case "$KSU" in
    "Next") install_ksu KernelSU-Next/KernelSU-Next $(susfs_included && echo next-susfs-dev) ;;
    "Suki") install_ksu SukiSU-Ultra/SukiSU-Ultra $(susfs_included && echo susfs-dev) ;;
  esac
fi

# KSU Manual Hooks
if [[ $KSU_MANUAL_HOOK == "true" ]]; then
  config --enable CONFIG_KSU_MANUAL_HOOK
  config --disable CONFIG_KSU_WITH_KPROBE
  config --disable CONFIG_KSU_WITH_KPROBES
  config --disable CONFIG_KSU_KPROBES_HOOK
  config --disable CONFIG_KSU_SUSFS_SUS_SU
fi

# SUSFS
if [[ $KSU_SUSFS == "true" ]]; then
  SUSFS_VERSION=$(grep -E '^#define SUSFS_VERSION' ./include/linux/susfs.h | cut -d' ' -f3 | sed 's/"//g' 2> /dev/null)
  if [[ -z "$SUSFS_VERSION" ]]; then
    error "Your Kernel doesn't support SuSFS!"
  else
    config --enable CONFIG_KSU_SUSFS
  fi
fi

# set localversion
if [[ $TODO == "kernel" ]]; then
  if [[ $STATUS == "BETA" ]]; then
    SUFFIX=$(git rev-parse --short HEAD)
  else
    SUFFIX="release"
  fi
  config --set-str CONFIG_LOCALVERSION "-$KERNEL_NAME/$SUFFIX"
fi

# Enable KPM Supports for SukiSU
if [[ $KSU == "Suki" ]]; then
  config --enable CONFIG_KPM
fi

# Declare needed variables
export KBUILD_BUILD_USER="$USER"
export KBUILD_BUILD_HOST="$HOST"
export KBUILD_BUILD_TIMESTAMP=$(date)

text=$(
  cat << EOF
*==== Krenol CI ====*
🐧 *Linux Version*: $LINUX_VERSION
📅 *Build Date*: $KBUILD_BUILD_TIMESTAMP
📛 *KernelSU*: ${KSU}$(ksu_included && echo " | $KSU_VERSION")
ඞ *SuSFS*: $(susfs_included && echo "$SUSFS_VERSION" || echo "None")
🔰 *Compiler*: $COMPILER_STRING
EOF
)

MESSAGE_ID=$(send_msg "$text" 2>&1 | jq -r .result.message_id)

# Define build flags and kernel image
BUILD_FLAGS="-j$(nproc --all) ARCH=arm64 LLVM=1 LLVM_IAS=1 O=out CROSS_COMPILE=$CROSS_COMPILE_PREFIX"
KERNEL_IMAGE="$workdir/ksrc/out/arch/arm64/boot/Image"

## Build GKI
set +e

log "Generating config..."
make $BUILD_FLAGS $KERNEL_DEFCONFIG

# Upload config file
if [[ $TODO == "defconfig" ]]; then
  log "Uploading defconfig..."
  upload_file $workdir/ksrc/out/.config
  exit 0
fi

# Build the actual kernel
log "Building kernel..."
make $BUILD_FLAGS Image
retVal=${PIPESTATUS[0]}

set -e

if [[ ! -f $KERNEL_IMAGE ]] || [[ $retVal -gt 0 ]]; then
  error "Build Failed!"
fi

## Post-compiling stuff
cd $workdir

# Patch the kernel Image for KPM Supports
if [[ $KSU == "Suki" ]]; then
  mkdir -p sukisu-patch && cd sukisu-patch
  # Setup patch_linux
  cp $workdir/shirkneko_patches/kpm/patch_linux .
  chmod a+x ./patch_linux
  # Patch kernel image
  cp $KERNEL_IMAGE ./Image
  sudo ./patch_linux
  mv oImage Image
  KERNEL_IMAGE=$(pwd)/Image
  cd -
fi

# Clone AnyKernel
log "Cloning anykernel from $(simplify_gh_url "$ANYKERNEL_REPO")"
git clone -q --depth=1 $ANYKERNEL_REPO -b $ANYKERNEL_BRANCH anykernel

# Set kernel string in anykernel
if [[ $STATUS == "BETA" ]]; then
  BUILD_DATE=$(date -d "$KBUILD_BUILD_TIMESTAMP" +"%Y%m%d-%H%M")
  ZIP_NAME=${ZIP_NAME//BUILD_DATE/$BUILD_DATE}
  sed -i \
    "s/kernel.string=.*/kernel.string=${KERNEL_NAME} ${LINUX_VERSION} (${BUILD_DATE}) ${VARIANT}/g" \
    $workdir/anykernel/anykernel.sh
else
  ZIP_NAME=${ZIP_NAME//-BUILD_DATE/}
  sed -i \
    "s/kernel.string=.*/kernel.string=${KERNEL_NAME} ${LINUX_VERSION} ${VARIANT}/g" \
    $workdir/anykernel/anykernel.sh
fi

# Zip the anykernel
cd anykernel
log "Zipping anykernel..."
cp $KERNEL_IMAGE .
zip -r9 $workdir/$ZIP_NAME ./*
cd -

if [[ $BUILD_BOOTIMG == "true" ]]; then
  # Clone required tools
  AOSP_MIRROR=https://android.googlesource.com
  AOSP_BRANCH=main-kernel-build-2024
  log "Cloning build tools..."
  git clone -q --depth=1 $AOSP_MIRROR/kernel/prebuilts/build-tools -b $AOSP_BRANCH build-tools
  log "Cloning mkbootimg..."
  git clone -q --depth=1 $AOSP_MIRROR/platform/system/tools/mkbootimg -b $AOSP_BRANCH mkbootimg

  # Variables
  AVBTOOL="$workdir/build-tools/linux-x86/bin/avbtool"
  MKBOOTIMG="$workdir/mkbootimg/mkbootimg.py"
  UNPACK_BOOTIMG="$workdir/mkbootimg/unpack_bootimg.py"
  BOOT_SIGN_KEY_PATH="$workdir/key/key.pem"
  BOOTIMG_NAME="${ZIP_NAME%.zip}-boot-dummy.img"

  # Function
  generate_bootimg() {
    local kernel="$1"
    local output="$2"

    # Create boot image
    log "Creating $output"
    $MKBOOTIMG --header_version 4 \
      --kernel "$kernel" \
      --output "$output" \
      --ramdisk out/ramdisk \
      --os_version 12.0.0 \
      --os_patch_level $(date +"%Y-%m")

    sleep 0.5

    # Sign the boot image
    log "Signing $output"
    $AVBTOOL add_hash_footer \
      --partition_name boot \
      --partition_size $((64 * 1024 * 1024)) \
      --image "$output" \
      --algorithm SHA256_RSA2048 \
      --key $BOOT_SIGN_KEY_PATH
  }

  # Prepare boot image
  mkdir -p bootimg && cd bootimg
  cp $KERNEL_IMAGE .
  gzip -n -f -9 -c Image > Image.gz
  lz4 -l -12 --favor-decSpeed Image Image.lz4

  # Download and unpack prebuilt GKI
  log "Downloading prebuilt GKI..."
  wget -qO gki.zip https://dl.google.com/android/gki/gki-certified-boot-android12-5.10-2023-01_r1.zip
  log "Unpacking prebuilt GKI..."
  unzip -q gki.zip && rm gki.zip
  $UNPACK_BOOTIMG --boot_img=boot-5.10.img
  rm boot-5.10.img

  # Generate and sign boot images in multiple formats (raw, lz4, gz)
  for format in raw lz4 gz; do
    # Initialize kernel variable
    kernel="./Image"
    [[ $format != "raw" ]] && kernel+=".$format"

    log "Using kernel: $kernel"
    output="${BOOTIMG_NAME/dummy/$format}"
    generate_bootimg "$kernel" "$output"

    log "Moving $output to work directory"
    mv -f "$output" $workdir
  done
  cd $workdir
fi

if [[ $STATUS != "BETA" ]]; then
  echo "BASE_NAME=$KERNEL_NAME-$VARIANT" >> $GITHUB_ENV
  mkdir -p $workdir/artifacts
  mv -f $workdir/{*.zip,*.img} $workdir/artifacts
fi

if [[ $LAST_BUILD == "true" && $STATUS != "BETA" ]]; then
  (
    echo "LINUX_VERSION=$LINUX_VERSION"
    echo "SUSFS_VERSION=$(curl -s https://gitlab.com/simonpunk/susfs4ksu/-/raw/${SUSFS_BRANCH}/kernel_patches/include/linux/susfs.h | grep -E '^#define SUSFS_VERSION' | cut -d' ' -f3 | sed 's/"//g')"
    echo "KSU_NEXT_VERSION=$(gh api repos/KernelSU-Next/KernelSU-Next/tags --jq '.[0].name')"
    echo "SUKISU_VERSION=$(gh api repos/SukiSU-Ultra/SukiSU-Ultra/tags --jq '.[0].name')"
    echo "KERNEL_NAME=$KERNEL_NAME"
    echo "RELEASE_REPO=$(simplify_gh_url "$GKI_RELEASES_REPO")"
  ) >> $workdir/artifacts/info.txt
fi

if [[ $STATUS == "BETA" ]]; then
  for file in $workdir/{*.zip,*.img}; do
    if [[ -f $file ]]; then
      reply_file "$MESSAGE_ID" "$file"
    fi
  done
else
  reply_msg "$MESSAGE_ID" "✅ Build Succeeded"
fi

exit 0
