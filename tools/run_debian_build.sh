#!/usr/bin/env bash
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
set -x

ninja=$(which ninja)
depot_tools=$(dirname $ninja)
cmd="sed -i /jessie-updates/d /etc/apt/sources.list\
    && apt-get update && apt-get -y install build-essential debhelper git python\
    && PATH=\"$depot_tools:\$PATH\"\
    python tools/bots/linux_distribution_support.py"
image="launcher.gcr.io/google/debian8:latest"
docker run -e BUILDBOT_BUILDERNAME -v $depot_tools:$depot_tools\
    -v `pwd`:`pwd` -w `pwd` -i --rm $image bash -c "$cmd"
