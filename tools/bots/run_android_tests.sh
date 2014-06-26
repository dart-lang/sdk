#!/bin/bash
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This script is meant to be run inside the src directory of a Dartium
# (or Chromium) checkout, with android_tools installed in third_party.
# It expects ContentShell to have been build for ARM android, using the
# ninja build system.
# It expects a single android device to be connected by USB to the machine.
set -v
set -x
cd src
ninja -C out/Release forwarder2
ninja -C out/Release pkg_packages
cp -R out/Release/packages out/ReleaseARM/packages
export PATH=$PATH:third_party/android_tools/sdk/platform-tools/\
:third_party/android_tools/sdk/tools/

adb uninstall org.chromium.content_shell_apk
adb install -r $1
./build/android/adb_reverse_forwarder.py 8081 8081 8082 8082 \
                                         8083 8083 8084 8084 &
FORWARDER_PID=$!
sleep 15
./dart/tools/test.py -m release -a arm --progress=line --report --time \
    --failure-summary --write-debug-log --local_ip=localhost \
    --test_server_port=8083 --test_server_cross_origin_port=8084 \
    --test_driver_port=8081 --test_driver_error_port=8082 \
    -r ContentShellOnAndroid
EXIT_CODE=$?
kill -9 $FORWARDER_PID
exit $EXIT_CODE
