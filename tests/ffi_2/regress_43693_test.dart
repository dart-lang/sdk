// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:expect/expect.dart';

import 'dylib_utils.dart';

class Struct43693 extends Struct {
  Pointer<Void> somePtr;

  @Uint64()
  int someValue;
}

final int Function(Pointer<Struct43693>) readMyStructSomeValue =
    ffiTestFunctions
        .lookup<NativeFunction<Uint64 Function(Pointer<Struct43693>)>>(
            "Regress43693")
        .asFunction<int Function(Pointer<Struct43693>)>();

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

void main() {
  final myStructs = allocate<Struct43693>();
  myStructs[0].somePtr = nullptr;
  myStructs[0].someValue = 0xAAAAAAAABBBBBBBB;
  final result = readMyStructSomeValue(myStructs);
  Expect.equals(0xAAAAAAAABBBBBBBB, result);
  free(myStructs);
}
