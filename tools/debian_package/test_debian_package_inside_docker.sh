#!/usr/bin/env bash
# Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
set -ex

# 'dart' starts absent
! dart

# Install package
dpkg -i "$1"

# Write test program
echo 'main() { print("Hello, world!"); }' > /tmp/hello.dart

# Test dart2js
dart compile js /tmp/hello.dart

# Test analyzer
dart analyze /tmp/hello.dart

# Test VM JIT
dart /tmp/hello.dart

# Test VM AOT - proper library, dartaotruntime on PATH
dart compile aot-snapshot -o /tmp/libhello.so /tmp/hello.dart
dartaotruntime /tmp/libhello.so

# Test VM AOT - self-contained executable
dart compile exe -o /tmp/hello.exe /tmp/hello.dart
/tmp/hello.exe

# Uninstall package
dpkg -r dart

# 'dart' was removed
! dart
