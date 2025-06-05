#!/usr/bin/env bash

# Kernel name
KERNEL_NAME="QuartiX"
# SuSFS
SUSFS_REPO="https://gitlab.com/simonpunk/susfs4ksu"
SUSFS_BRANCH="gki-android12-5.10"
# Kernel Build variables
USER="eraselk"
HOST="gacorprjkt"
TIMEZONE="Asia/Makassar"
# AnyKernel
ANYKERNEL_REPO="https://github.com/linastorvaldz/anykernel"
ANYKERNEL_BRANCH="gki"
# Kernel Source
KERNEL_REPO="https://github.com/linastorvaldz/kernel_new"
KERNEL_BRANCH="android12-5.10"
KERNEL_DEFCONFIG="gki_defconfig"
# Release repository
GKI_RELEASES_REPO="https://github.com/linastorvaldz/quartix-releases"
# Clang
CLANG_URL="https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git"
CLANG_BRANCH="15.0"
# Zip name
# These "KVER" "VARIANT" "BUILD_DATE"
# are placeholders, they would be changed in main script
ZIP_NAME="$KERNEL_NAME-KVER-VARIANT-BUILD_DATE.zip"
