#!/usr/bin/env bash

# Kernel name
KERNEL_NAME="Zero"
# Kernel Build variables
USER="Yoro1836"
HOST="AkoTheCow"
TIMEZONE="Asia/Seoul"
# AnyKernel
ANYKERNEL_REPO="https://github.com/bintang774/anykernel"
ANYKERNEL_BRANCH="gki"
# Kernel Source
KERNEL_REPO="https://github.com/yoro1836/zero_kernel"
KERNEL_BRANCH="zero"
KERNEL_DEFCONFIG="zero_defconfig"
# Release repository
GKI_RELEASES_REPO="https://github.com/yoro1836/zero_kernel"
# Clang
CLANG_URL="$(./clang.sh ndk)"
CLANG_BRANCH=""
# Zip name
# Format: Kernel_name-Linux_version-Variant-Build_date
ZIP_NAME="$KERNEL_NAME-KVER-VARIANT-BUILD_DATE.zip"
