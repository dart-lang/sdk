#!/usr/bin/env bash
# Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

function follow_links() {
  file="$1"
  while [ -h "$file" ]; do
    # On Mac OS, readlink -f doesn't work.
    file="$(readlink "$file")"
  done
  echo "$file"
}

function get_realpath() {
  file="$1"
  if [ -f "$file" ]; then
    file="$(cd "$(dirname "$file")"; pwd -P)/$(basename "$file")"
  fi
  echo "$(follow_links "$file")"
}

# Unlike $0, $BASH_SOURCE points to the absolute path of this file.
UTILS_SCRIPT="$(follow_links "${BASH_SOURCE[0]}")"
UTILS_DIR="$(cd "${UTILS_SCRIPT%/*}" ; pwd -P)"
SDK_DIR="$(cd "${UTILS_DIR}/../../.." ; pwd -P)"

function get_host_arch() {
  case `uname -m` in
    x86_64) echo "x64" ;;
    aarch64 | arm64 | armv8*) echo "arm64" ;;
    *)
      echo "Unsupported host architecture" `uname -m` >&2
      exit 1
      ;;
  esac
}
