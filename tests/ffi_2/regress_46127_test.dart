// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

final nativeLib = dlopenPlatformSpecific("ffi_test_functions");

class Struct46127 extends Struct {
  @Uint64()
  int val;
}

void main() {
  final struct =
      nativeLib.lookupFunction<Struct46127 Function(), Struct46127 Function()>(
          'Regress46127')();
  Expect.equals(123, struct.val);
}
