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
  testInlineArray2();
  testInlineArrayNested2();
  testInlineArrayNestedDeep2();
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

void testInlineArray2() {
  const length = 10;
  final lengthInBytes =
      sizeOf<StructInlineArrayVariable2>() + sizeOf<Uint8>() * (length - 1);
  final pointer = calloc.allocate<StructInlineArrayVariable2>(lengthInBytes);
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

void testInlineArrayNested2() {
  const length = 10;

  final lengthInBytes =
      sizeOf<StructInlineArrayVariableNested2>() +
      sizeOf<Uint8>() * (length - 1) * 2 * 2;
  final pointer = calloc.allocate<StructInlineArrayVariableNested2>(
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

void testInlineArrayNestedDeep2() {
  const length = 10;
  final lengthInBytes =
      sizeOf<StructInlineArrayVariableNestedDeep2>() +
      sizeOf<Uint8>() * (length - 1) * 2 * 2 * 2 * 2 * 2 * 2;
  final pointer = calloc.allocate<StructInlineArrayVariableNestedDeep2>(
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

  @Array.variable()
  external Array<Uint32> field1;
}

final class Foo3 extends Struct {
  @Int8()
  external int field0;

  @Array.variableMulti([2, 2])
  external Array<Array<Array<Uint32>>> field1;
}

final class Foo4 extends Struct {
  @Int8()
  external int field0;

  @Array.variableWithVariableDimension(0)
  external Array<Uint32> field1;
}

final class Foo5 extends Struct {
  @Int8()
  external int field0;

  @Array.variableWithVariableDimension(1)
  external Array<Uint32> field1;
}

final class Foo6 extends Struct {
  @Int8()
  external int field0;

  @Array.variableMulti(variableDimension: 0, [2, 2])
  external Array<Array<Array<Uint32>>> field1;
}

final class Foo7 extends Struct {
  @Int8()
  external int field0;

  @Array.variableMulti(variableDimension: 1, [2, 2])
  external Array<Array<Array<Uint32>>> field1;
}

void testSizeOf() {
  Expect.equals(1, sizeOf<Foo>());
  Expect.equals(4, sizeOf<Foo2>());
  Expect.equals(4, sizeOf<Foo3>());
  Expect.equals(4, sizeOf<Foo4>());
  Expect.equals(8, sizeOf<Foo5>());
  Expect.equals(4, sizeOf<Foo6>());
  Expect.equals(20, sizeOf<Foo7>());
}
