#!/usr/bin/env bash

# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Uploads the following dill files to CIPD, indexed by the current ABI version:
#   $build_dir/vm_platform_strong.dill
#   $build_dir/gen/kernel_service.dill
#   $build_dir/gen_kernel_bytecode.dill
# This script is a no-op unless $BUILDBOT_BUILDERNAME is "dart-sdk-linux-be".
# It's also a no-op if dill files were already uploaded today.
#
# If the ABI was modified, the ABI_VERSION in tools/VERSIONS should be manually
# incremented accordingly.
set -e
set -x

if [ -z "$2" ]; then
  echo "Usage: upload_abi_dills.sh version_file build_dir"
  exit 1
fi

if [ "$BUILDBOT_BUILDERNAME" != "dart-sdk-linux-be" ]; then
  echo "This script only works on the dart-sdk-linux-be buildbot"
  exit 0
fi

abi_version=$(sed -n "s/^ABI_VERSION \([0-9]*\)$/\1/p" "$1")
git_revision=$(git rev-parse HEAD)
current_date=$(date +%F)
search_results=$(cipd search \
  "dart/abiversions/$abi_version" \
  -tag "date:$current_date" | grep "Instances:" || echo "")

if [ ! -z "$search_results" ]; then
  exit 0
fi

sdk_dir=$(pwd)
tmpdir=$(mktemp -d)
chmod 755 $tmpdir
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT HUP INT QUIT TERM PIPE
pushd "$tmpdir"

mkdir abiversions
cp "$sdk_dir/$2/vm_platform_strong.dill" "abiversions/vm_platform_strong.dill"
cp "$sdk_dir/$2/gen/kernel_service.dill" "abiversions/kernel_service.dill"
cp "$sdk_dir/$2/gen_kernel_bytecode.dill" "abiversions/gen_kernel_bytecode.dill"

cipd create \
  -name dart/abiversions/$abi_version \
  -in abiversions \
  -install-mode copy \
  -tag version:$abi_version \
  -tag date:$current_date \
  -tag git_revision:$git_revision \
  -ref latest \
  -ref version_$abi_version

popd
