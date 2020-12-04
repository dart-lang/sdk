// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions
//
// VMOptions=--deterministic --optimization-counter-threshold=5 --use-slow-path --stacktrace-every=100

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

// Reuse the struct classes.
import 'function_structs_by_value_generated_test.dart';

void main() {
  for (int i = 0; i < 10; i++) {
    recursiveTest(10);
    recursiveTest(11);
  }
}

void recursiveTest(int recursionCounter) {
  final struct = allocate<Struct20BytesHomogeneousInt32>().ref;
  struct.a0 = 1;
  struct.a1 = 2;
  struct.a2 = 3;
  struct.a3 = 4;
  struct.a4 = 5;
  final result = dartPassStructRecursive(recursionCounter, struct);
  Expect.equals(struct.a0 + recursionCounter * 2, result.a0);
  Expect.equals(struct.a1, result.a1);
  Expect.equals(struct.a2, result.a2);
  Expect.equals(struct.a3, result.a3);
  Expect.equals(struct.a4, result.a4);
  free(struct.addressOf);
}

Struct20BytesHomogeneousInt32 dartPassStructRecursive(
    int recursionCounter, Struct20BytesHomogeneousInt32 struct) {
  print("callbackPassStructRecurisive($recursionCounter, $struct)");
  struct.a0++;
  final structA0Saved = struct.a0;
  if (recursionCounter <= 0) {
    print("returning");
    return struct;
  }

  final result =
      cPassStructRecursive(recursionCounter - 1, struct, functionPointer);
  result.a0++;

  // Check struct.a0 is not modified by Dart->C call.
  Expect.equals(structA0Saved, struct.a0);

  // Check struct.a0 is not modified by C->Dart callback, if so struct.a4 == 0.
  Expect.notEquals(0, struct.a4);

  return result;
}

final functionPointer = Pointer.fromFunction<
    Struct20BytesHomogeneousInt32 Function(
        Int64, Struct20BytesHomogeneousInt32)>(dartPassStructRecursive);

final cPassStructRecursive = ffiTestFunctions.lookupFunction<
    Struct20BytesHomogeneousInt32 Function(Int64 recursionCounter,
        Struct20BytesHomogeneousInt32 struct, Pointer callbackAddress),
    Struct20BytesHomogeneousInt32 Function(int recursionCounter,
        Struct20BytesHomogeneousInt32, Pointer)>("PassStructRecursive");
