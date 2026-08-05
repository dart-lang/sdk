#!/usr/bin/env bash
# Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
set -ex

debfile="$1"
arch="$2"
checkout=$(pwd)

# api.buildbucket.gitiles_commit.id is not populated in try jobs :(
if [ ! -f $debfile ]; then
  echo "warning: $debfile does not exist"
  version=$(tools/debian_package/get_version.py)
  case $arch in
    x64) debfile="out/ReleaseX64/dart_${version}-1_amd64.deb" ;;
    arm64) debfile="out/ReleaseARM64/dart_${version}-1_arm64.deb" ;;
    riscv64) debfile="out/ReleaseRISCV64/dart_${version}-1_riscv64.deb" ;;
  esac
fi

function test_image() {
  image="$1"
  docker run -v $checkout:$checkout -w $checkout -i --rm $image tools/debian_package/test_debian_package_inside_docker.sh $debfile
}

test_image ubuntu:latest
test_image ubuntu:devel
test_image debian:stable
test_image debian:oldstable
