#!/bin/sh

# Install Alpine sysroots for building with musl libc.
#
# Sysroots will be installed into //buildtools/sysroot/alpine-linux-$arch
#
# Architectures to be installed can be configured at the end of the script
#
# List of available architectures can be found at:
#   https://pkgs.alpinelinux.org/packages?name=alpine-base

set -e

if test ! -f /etc/alpine-release; then
  echo "Error: This script must be run directly on alpine linux or inside alpine linux container." >&2
  exit 1
fi

SCRIPT="$(readlink -f -- "$0")"

WORKDIR="$(dirname -- "$(dirname -- "$(dirname -- "$(dirname -- "$SCRIPT")")")")"

if test $# -eq 0; then
  set aarch64 armv7 x86_64 x86 riscv64
fi

echo "$@" | xargs -n 1 -- sh -xc 'apk add --root "$1/buildtools/sysroot/alpine-linux-$2" --repositories-file /etc/apk/repositories --allow-untrusted --arch "$2" --no-cache --no-scripts --initdb -- build-base linux-headers' -- "$WORKDIR"
