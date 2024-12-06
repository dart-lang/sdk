// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
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
  testInlineArray();
  testInlineArrayNested();
  testInlineArrayNestedDeep();
  testSizeOf();
}

void testInlineArray() {
  const length = 10;
  final lengthInBytes =
      sizeOf<StructInlineArrayVariable>() + sizeOf<Uint8>() * length;
  final pointer = calloc.allocate<StructInlineArrayVariable>(lengthInBytes);
  pointer.ref.a0 = length;
  final struct = pointer.ref;
  for (int i = 0; i < length; i++) {
    struct.a1[i] = i;
  }
  var sum = 0;
  for (int i = 0; i < length; i++) {
    sum += struct.a1[i];
  }
  calloc.free(pointer);
  Expect.equals(45, sum);
}

void testInlineArrayNested() {
  const length = 10;
  final lengthInBytes =
      sizeOf<StructInlineArrayVariableNested>() +
      sizeOf<Uint8>() * length * 2 * 2;
  final pointer = calloc.allocate<StructInlineArrayVariableNested>(
    lengthInBytes,
  );
  pointer.ref.a0 = length;
  final struct = pointer.ref;
  for (int i = 0; i < length; i++) {
    struct.a1[i][0][0] = i;
  }
  var sum = 0;
  for (int i = 0; i < length; i++) {
    sum += struct.a1[i][0][0];
  }
  calloc.free(pointer);
  Expect.equals(45, sum);
}

void testInlineArrayNestedDeep() {
  const length = 10;
  final lengthInBytes =
      sizeOf<StructInlineArrayVariableNestedDeep>() +
      sizeOf<Uint8>() * length * 2 * 2 * 2 * 2 * 2 * 2;
  final pointer = calloc.allocate<StructInlineArrayVariableNestedDeep>(
    lengthInBytes,
  );
  pointer.ref.a0 = length;
  final struct = pointer.ref;
  for (int i = 0; i < length; i++) {
    struct.a1[i][0][0][1][1][0][0] = i;
  }
  var sum = 0;
  for (int i = 0; i < length; i++) {
    sum += struct.a1[i][0][0][1][1][0][0];
  }
  calloc.free(pointer);
  Expect.equals(45, sum);
}

final class Foo extends Struct {
  @Int8()
  external int field0;
}

final class Foo2 extends Struct {
  @Int8()
  external int field0;

  @Array<Uint32>.variable()
  external Array<Uint32> field1;
}

void testSizeOf() {
  Expect.equals(1, sizeOf<Foo>());
  Expect.equals(4, sizeOf<Foo2>());
}
