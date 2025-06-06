#!/usr/bin/env bash

# Kernel name
KERNEL_NAME="QuartiX"
# Kernel Build variables
USER="eraselk"
HOST="gacorprjkt"
TIMEZONE="Asia/Makassar"
# AnyKernel
ANYKERNEL_REPO="https://github.com/bintang774/anykernel"
ANYKERNEL_BRANCH="gki"
# Kernel Source
KERNEL_REPO="https://github.com/bintang774/gki-android12-5.10"
KERNEL_BRANCH="quartix/main"
KERNEL_DEFCONFIG="gki_defconfig"
# Release repository
GKI_RELEASES_REPO="https://github.com/bintang774/quartix-releases"
# Clang
CLANG_URL="https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git"
CLANG_BRANCH="15.0"
# Zip name
# Format: Kernel_name-Linux_version-Variant-Build_date
ZIP_NAME="$KERNEL_NAME-KVER-VARIANT-BUILD_DATE.zip"
