#!/usr/bin/env bash
#
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Sets the compiler environment variables to use a downloaded Debian sysroot
# when building Dart with architecture x64.
# Run this in the same working directory that you have run
# sdk/tools/download_chromium_sysroot.sh in.
# Must be sourced, not run in a subshell, to modify the environment.
# Run with the command ". sdk/tools/set_x64_sysroot.sh"
# Only tested and used on Ubuntu trusty linux. Used to build dart with
# no requirement for glibc greater than version 2.14.

export CXXFLAGS="--sysroot=$PWD/build/linux/debian_jessie_amd64-sysroot -I=/usr/include/c++/4.8 -I=/usr/include/c++/4.8/x86_64-linux-gnu"

export LDFLAGS=--sysroot=$PWD/build/linux/debian_jessie_amd64-sysroot
export CFLAGS=--sysroot=$PWD/build/linux/debian_jessie_amd64-sysroot
