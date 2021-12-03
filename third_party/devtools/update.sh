#!/bin/bash

# Copyright 2021 The Dart Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex #echo on

if [ -z "$1" ]; then
  echo "Usage: update.sh revision"
  exit 1
fi

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}

trap cleanup EXIT HUP INT QUIT TERM PIPE
cd "$tmpdir"

# Clone DevTools and build.
git clone git@github.com:flutter/devtools.git
cd devtools
git checkout -b cipd_release $1

./tool/update_flutter_sdk.sh
./tool/build_release.sh

# Copy the build output as well as the devtools packages needed
# to serve from DDS.
mkdir cipd_package
cp -R packages/devtools/build/ cipd_package/web
cp -r packages/devtools_shared cipd_package
cp -r packages/devtools_server cipd_package

cipd create \
  -name dart/third_party/flutter/devtools \
  -in cipd_package \
  -install-mode copy \
  -preserve-writable \
  -tag git_revision:$1
