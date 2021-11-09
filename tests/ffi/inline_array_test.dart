// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";
import 'package:ffi/ffi.dart';

// Reuse compound definitions.
import 'function_structs_by_value_generated_compounds.dart';

void main() {
  testSizeOf();
  testLoad();
  testStore();
  testToString();
  testRange();
}

void testSizeOf() {
  Expect.equals(8, sizeOf<Struct8BytesInlineArrayInt>());
  Expect.equals(10, sizeOf<StructInlineArrayIrregular>());
  Expect.equals(4008, sizeOf<StructInlineArrayBig>());
}

// Only tests with Pointer as backing store.
void testLoad() {
  final pointer = calloc<Struct8BytesInlineArrayInt>();
  final struct = pointer.ref;
  final array = struct.a0;
  pointer.cast<Uint8>()[0] = 42;
  pointer.cast<Uint8>()[7] = 3;
  Expect.equals(42, array[0]);
  Expect.equals(3, array[7]);
  calloc.free(pointer);
}

// Only tests with Pointer as backing store.
void testStore() {
  final pointer = calloc<Struct8BytesInlineArrayInt>();
  pointer.cast<Uint8>()[0] = 42;
  pointer.cast<Uint8>()[7] = 3;
  final pointer2 = calloc<Struct8BytesInlineArrayInt>();
  pointer2.ref.a0 = pointer.ref.a0;
  Expect.equals(42, pointer2.ref.a0[0]);
  Expect.equals(3, pointer2.ref.a0[7]);
  calloc.free(pointer);
  calloc.free(pointer2);
}

// Tests the toString of the test generator.
void testToString() {
  final pointer = calloc<Struct8BytesInlineArrayInt>();
  final struct = pointer.ref;
  final array = struct.a0;
  for (var i = 0; i < 8; i++) {
    array[i] = i;
  }
  Expect.equals("([0, 1, 2, 3, 4, 5, 6, 7])", struct.toString());
  calloc.free(pointer);

  final pointer2 = calloc<StructInlineArrayIrregular>();
  final struct2 = pointer2.ref;
  struct2.a0[0].a0 = 0;
  struct2.a0[0].a1 = 1;
  struct2.a0[1].a0 = 2;
  struct2.a0[1].a1 = 3;
  struct2.a1 = 4;
  print(struct2);
  Expect.equals("([(0, 1), (2, 3)], 4)", struct2.toString());
  calloc.free(pointer2);
}

void testRange() {
  final pointer = calloc<Struct8BytesInlineArrayInt>();
  final struct = pointer.ref;
  final array = struct.a0;
  array[0] = 1;
  Expect.equals(1, array[0]);
  array[7] = 7;
  Expect.equals(7, array[7]);
  Expect.throws(() => array[-1]);
  Expect.throws(() => array[-1] = 0);
  Expect.throws(() => array[8]);
  Expect.throws(() => array[8] = 0);
  calloc.free(pointer);
}
