#!/data/data/com.termux/files/usr/bin/bash
set -x
__DIR=$(dirname $0)
if ! command -v shfmt &> /dev/null; then
  echo "Installing shfmt..."
  sleep 1
  pkg update && pkg install shfmt -y
fi

find "$__DIR" -name "*.sh" -exec shfmt -w -i 2 -ci -sr -bn {} +
