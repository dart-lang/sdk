#!/usr/bin/env bash
#
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Downloads the ia32 and x64 Debian jessie sysroot that chromium uses,
# Only tested and used on Ubuntu trusty linux. Used to keep glibc version low.
# Creates directories called "build" and "tools" in the current directory.
# After running this, source set_ia32_sysroot.sh or set_x64_sysroot.sh, in 
# the same working directory, to set the compilation environment variables.
# Sourcing a script means running the script with a '.', so that it runs
# in the current shell, not a subshell, as in:
#   . sdk/tools/set_ia32_sysroot.sh

git clone https://chromium.googlesource.com/chromium/src/build
mkdir tools
cd tools
git clone https://chromium.googlesource.com/external/gyp
cd ..

build/linux/sysroot_scripts/install-sysroot.py --arch i386
build/linux/sysroot_scripts/install-sysroot.py --arch amd64
