#!/usr/bin/env bash
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
set -x

ninja=$(which ninja)
depot_tools=$(dirname $ninja)
image="debian-package:0.1"
dockerfile=tools/linux_dist_support/Debian.dockerfile
docker build --build-arg depot_tools=$depot_tools -t $image - < $dockerfile
checkout=$(pwd)
docker run -e BUILDBOT_BUILDERNAME -v $depot_tools:$depot_tools\
    -v $checkout:$checkout -w $checkout -i --rm $image
