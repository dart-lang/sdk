// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

void main() {
  testCurrent();
  testPlatformVersionCompatibility();
}

void testCurrent() {
  final currentAbi = Abi.current();
  Expect.isTrue(Abi.values.contains(currentAbi));
}

void testPlatformVersionCompatibility() {
  final abiStringFromPlatformVersion = Platform.version.split('"')[1];
  final abiStringFromCurrent = Abi.current().toString();
  Expect.equals(abiStringFromPlatformVersion, abiStringFromCurrent);
}
