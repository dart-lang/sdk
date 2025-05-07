// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=90
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

const int arrayLength = 5;
const int deeplyNestedArrayLength = 2;

void main() {
  // Loop enough to trigger optimizations or stacktraces. See "VMOptions" above.
  for (int i = 0; i < 100; ++i) {
    testPointerArrayElements();
    testMallocedPointerArrayElements();
    testWriteToPointerArrayElements();
    testStructArrayElements();
    testMallocedStructArrayElements();
    testWriteToStructArrayElements();
    testUnionArrayElements();
    testMallocedUnionArrayElements();
    testWriteToUnionArrayElements();
    testArrayArrayElements();
    testMallocedArrayArrayElements();
    testWriteToArrayArrayElements();
    testDeeplyNestedArrayElements();
    testMallocedDeeplyNestedArrayElements();
  }
}

final class TestStruct extends Struct {
  // Placeholder value before array to test the offset calculation logic.
  @Int8()
  external int placeholder;

  @Array(arrayLength)
  external Array<Pointer<Int8>> pointerArray;

  @Array(arrayLength)
  external Array<MyStruct> structArray;

  @Array(arrayLength)
  external Array<MyUnion> unionArray;

  @Array(arrayLength, arrayLength)
  external Array<Array<Int8>> arrayArray;

  @Array(
    deeplyNestedArrayLength,
    deeplyNestedArrayLength,
    deeplyNestedArrayLength,
    deeplyNestedArrayLength,
  )
  external Array<Array<Array<Array<Int8>>>> deplyNestedArray;
}

final class MyStruct extends Struct {
  @Int8()
  external int structValue;
}

final class MyUnion extends Union {
  @Int32()
  external int unionAlt1;

  @Float()
  external double unionAlt2;
}

void testPointerArrayElements() {
  final struct = Struct.create<TestStruct>();
  final array = struct.pointerArray;
  final expected = <Pointer<Int8>>[];
  for (int i = 0; i < arrayLength; i++) {
    Pointer<Int8> intPointer = malloc<Int8>()..value = 100 + i;
    array[i] = intPointer;
    expected.add(intPointer);
  }
  Expect.listEquals(expected, array.elements);
  expected.forEach(malloc.free);
}

void testMallocedPointerArrayElements() {
  final struct = malloc<TestStruct>();
  final array = struct.ref.pointerArray;
  final expected = <Pointer<Int8>>[];
  for (int i = 0; i < arrayLength; i++) {
    Pointer<Int8> intPointer = malloc<Int8>()..value = 100 + i;
    array[i] = intPointer;
    expected.add(intPointer);
  }
  Expect.listEquals(expected, array.elements);
  expected.forEach(malloc.free);
  malloc.free(struct);
}

void testWriteToPointerArrayElements() {
  final struct = Struct.create<TestStruct>();
  final array = struct.pointerArray;
  final expected = <Pointer<Int8>>[];
  for (int i = 0; i < arrayLength; i++) {
    Pointer<Int8> intPointer = malloc<Int8>()..value = 100 + i;
    array.elements[i] = intPointer;
    expected.add(intPointer);
  }
  Expect.listEquals(expected, array.elements);
  final actual = <Pointer<Int8>>[];
  for (int i = 0; i < arrayLength; i++) {
    actual.add(array[i]);
  }
  Expect.listEquals(expected, actual);
  expected.forEach(malloc.free);
}

void testStructArrayElements() {
  final struct = Struct.create<TestStruct>();
  final array = struct.structArray;
  final expected = <int>[];
  for (int i = 0; i < arrayLength; i++) {
    int value = 100 + i;
    array[i].structValue = value;
    expected.add(value);
  }
  Expect.listEquals(expected, [
    for (var element in array.elements) element.structValue,
  ]);
}

void testMallocedStructArrayElements() {
  final struct = malloc<TestStruct>();
  final array = struct.ref.structArray;
  final expected = <int>[];
  for (int i = 0; i < arrayLength; i++) {
    int value = 100 + i;
    array[i].structValue = value;
    expected.add(value);
  }
  Expect.listEquals(expected, [
    for (var element in array.elements) element.structValue,
  ]);
  malloc.free(struct);
}

void testWriteToStructArrayElements() {
  final struct = Struct.create<TestStruct>();
  final array = struct.structArray;
  final myStruct = Struct.create<MyStruct>();
  for (int i = 0; i < arrayLength; i++) {
    final e = Expect.throwsUnsupportedError(() {
      array.elements[i] = myStruct;
    });
    Expect.isTrue(e.message!.contains('Cannot modify an unmodifiable list'));
  }
}

void testUnionArrayElements() {
  final struct = Struct.create<TestStruct>();
  final array = struct.unionArray;
  final expected = <int>[];
  for (int i = 0; i < arrayLength; i++) {
    int value = 100 + i;
    array[i].unionAlt1 = value;
    expected.add(value);
  }
  Expect.listEquals(expected, [
    for (var element in array.elements) element.unionAlt1,
  ]);
}

void testMallocedUnionArrayElements() {
  final struct = malloc<TestStruct>();
  final array = struct.ref.unionArray;
  final expected = <int>[];
  for (int i = 0; i < arrayLength; i++) {
    int value = 100 + i;
    array[i].unionAlt1 = value;
    expected.add(value);
  }
  Expect.listEquals(expected, [
    for (var element in array.elements) element.unionAlt1,
  ]);
  malloc.free(struct);
}

void testWriteToUnionArrayElements() {
  final struct = Struct.create<TestStruct>();
  final array = struct.unionArray;
  final myUnion = Union.create<MyUnion>();
  for (int i = 0; i < arrayLength; i++) {
    final e = Expect.throwsUnsupportedError(() {
      array.elements[i] = myUnion;
    });
    Expect.isTrue(e.message!.contains('Cannot modify an unmodifiable list'));
  }
}

void testArrayArrayElements() {
  final struct = Struct.create<TestStruct>();
  final array = struct.arrayArray;
  final expected = <List<int>>[];
  for (int i = 0; i < arrayLength; i++) {
    final values = <int>[];
    for (int j = 0; j < arrayLength; j++) {
      int value = (10 * i) + j;
      array[i][j] = value;
      values.add(value);
    }
    expected.add(values);
  }
  Expect.deepEquals(expected, [
    for (var element in array.elements) element.elements,
  ]);
}

void testMallocedArrayArrayElements() {
  final struct = malloc<TestStruct>();
  final array = struct.ref.arrayArray;
  final expected = <List<int>>[];
  for (int i = 0; i < arrayLength; i++) {
    final values = <int>[];
    for (int j = 0; j < arrayLength; j++) {
      int value = (10 * i) + j;
      array[i][j] = value;
      values.add(value);
    }
    expected.add(values);
  }
  Expect.deepEquals(expected, [
    for (var element in array.elements) element.elements,
  ]);
  malloc.free(struct);
}

void testWriteToArrayArrayElements() {
  final struct = Struct.create<TestStruct>();
  final array = struct.arrayArray;
  final source = Struct.create<TestStruct>().arrayArray;
  for (int i = 0; i < arrayLength; i++) {
    for (int j = 0; j < arrayLength; j++) {
      source[i][j] = (10 * i) + j;
    }
    array.elements[i] = source[i];
  }
  for (int i = 0; i < arrayLength; i++) {
    final actual = <int>[];
    for (int j = 0; j < arrayLength; j++) {
      actual.add(array[i][j]);
    }
    Expect.listEquals(source[i].elements, actual);
    Expect.listEquals(source[i].elements, array[i].elements);
  }
}

void testDeeplyNestedArrayElements() {
  final struct = Struct.create<TestStruct>();
  final array = struct.deplyNestedArray;
  final expected = <int>[];

  for (int a = 0; a < deeplyNestedArrayLength; a++) {
    for (int b = 0; b < deeplyNestedArrayLength; b++) {
      for (int c = 0; c < deeplyNestedArrayLength; c++) {
        for (int d = 0; d < deeplyNestedArrayLength; d++) {
          int value = a + b + c + d;
          array[a][b][c][d] = value;
          expected.add(value);
        }
      }
    }
  }

  final actual = <int>[];
  for (var a in array.elements) {
    for (var b in a.elements) {
      for (var c in b.elements) {
        for (var d in c.elements) {
          actual.add(d);
        }
      }
    }
  }

  Expect.listEquals(expected, actual);
}

void testMallocedDeeplyNestedArrayElements() {
  final struct = malloc<TestStruct>();
  final array = struct.ref.deplyNestedArray;
  final expected = <int>[];
  for (int a = 0; a < deeplyNestedArrayLength; a++) {
    for (int b = 0; b < deeplyNestedArrayLength; b++) {
      for (int c = 0; c < deeplyNestedArrayLength; c++) {
        for (int d = 0; d < deeplyNestedArrayLength; d++) {
          int value = a + b + c + d;
          array[a][b][c][d] = value;
          expected.add(value);
        }
      }
    }
  }

  final actual = <int>[];
  for (var a in array.elements) {
    for (var b in a.elements) {
      for (var c in b.elements) {
        for (var d in c.elements) {
          actual.add(d);
        }
      }
    }
  }

  Expect.listEquals(expected, actual);
  malloc.free(struct);
}
