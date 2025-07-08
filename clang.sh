#!/usr/bin/env bash

# slim llvm
SLIM_REPO="https://www.kernel.org/pub/tools/llvm/files/"
# rv clang
RV_REPO="https://api.github.com/repos/Rv-Project/RvClang/releases/latest"
# aosp clang
AOSP_REPO="https://api.github.com/repos/bachnxuan/aosp_clang_mirror/releases/latest"
# yuki clang
YUKI_REPO="https://api.github.com/repos/Klozz/Yuki_clang_releases/releases/latest"
# lilium clang
LILIUM_REPO="https://api.github.com/repos/liliumproject/clang/releases/latest"
# topnotchfreaks clang
TNF_REPO="https://api.github.com/repos/topnotchfreaks/clang/releases/latest"
# neutron clang
NEUTRON_REPO="https://api.github.com/repos/Neutron-Toolchains/clang-build-catalogue/releases/latest"

show_usage() {
  CLANG_NAME="slim, rv, aosp, yuki, lilium, tnf, neutron"
  echo "Usage: $0 <clang name>"
  echo "clang name: $CLANG_NAME"
}

case "$1" in
  "slim")
    curl -s "$SLIM_REPO" | grep -oP 'llvm-[\d.]+-x86_64\.tar\.xz' | sort -V | tail -n1 | sed "s|^|$SLIM_REPO|"
    ;;
  "rv")
    curl -s "$RV_REPO" | grep "browser_download_url" | grep ".tar.gz" | cut -d '"' -f 4
    ;;
  "aosp")
    curl -s "$AOSP_REPO" | grep "browser_download_url" | grep ".tar.gz" | cut -d '"' -f 4
    ;;
  "yuki")
    curl -s "$YUKI_REPO" | grep "browser_download_url" | grep ".tar.gz" | cut -d '"' -f 4
    ;;
  "lilium")
    curl -s "$LILIUM_REPO" | grep "browser_download_url" | grep ".tar.gz" | cut -d '"' -f 4
    ;;
  "tnf")
    curl -s "$TNF_REPO" | grep "browser_download_url" | grep ".tar.gz" | cut -d '"' -f 4
    ;;
  "neutron")
    curl -s "$NEUTRON_REPO" | grep "browser_download_url" | grep ".tar.zst" | cut -d '"' -f 4
    ;;
  *)
    if [[ -z $1 ]]; then
      show_usage
    else
      echo "Invalid clang name '$1'"
      echo
      show_usage
    fi
    exit 1
    ;;
esac
