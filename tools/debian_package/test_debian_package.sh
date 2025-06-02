#!/usr/bin/env bash
# Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
set -ex

debfile="$1"
checkout=$(pwd)

function test_image() {
  image="$1"
  docker run -v $checkout:$checkout -w $checkout -i --rm $image tools/debian_package/test_debian_package_inside_docker.sh $debfile
}

test_image ubuntu:latest
test_image ubuntu:devel
test_image debian:stable
test_image debian:oldstable
