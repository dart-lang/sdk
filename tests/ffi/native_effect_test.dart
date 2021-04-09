// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// Tests that the dart:internal _nativeEffect flow graph builder works.

import 'dart:ffi';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

void main() {
  testReturnStruct1ByteInt();
}

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final returnStruct1ByteInt = ffiTestFunctions.lookupFunction<
    Struct1ByteInt Function(Int8),
    Struct1ByteInt Function(int)>("ReturnStruct1ByteInt");

void testReturnStruct1ByteInt() {
  final result = returnStruct1ByteInt(1);
  Expect.equals(1, result.a0);
}

class Struct1ByteInt extends Struct {
  @Int8()
  external int a0;
}
