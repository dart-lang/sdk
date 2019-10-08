// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:expect/expect.dart';

main() {
  testInt8Load();
  testInt8Store();
  testUint8Load();
  testUint8Store();
  testInt16Load();
  testInt16Store();
  testUint16Load();
  testUint16Store();
  testInt32Load();
  testInt32Store();
  testUint32Load();
  testUint32Store();
  testInt64Load();
  testInt64Store();
  testUint64Load();
  testUint64Store();
  testIntPtr();
  testFloatLoad();
  testFloatStore();
  testDoubleLoad();
  testDoubleStore();
  testArrayLoad();
  testArrayStore();
  testNegativeArray();
  testAlignment();
}

// For signed int tests, we store 0xf* and load -1 to check sign-extension.
// For unsigned int tests, we store 0xf* and load the same to check truncation.

void testInt8Load() {
  // Load
  Pointer<Int8> ptr = Pointer.allocate();
  ptr.value = 0xff;
  Int8List list = ptr.asExternalTypedData();
  Expect.equals(list[0], -1);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testInt8Store() {
  // Store
  Pointer<Int8> ptr = Pointer.allocate();
  Int8List list = ptr.asExternalTypedData();
  list[0] = 0xff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, -1);
  ptr.free();
}

void testUint8Load() {
  // Load
  Pointer<Uint8> ptr = Pointer.allocate();
  ptr.value = 0xff;
  Uint8List list = ptr.asExternalTypedData();
  Expect.equals(list[0], 0xff);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testUint8Store() {
  // Store
  Pointer<Uint8> ptr = Pointer.allocate();
  Uint8List list = ptr.asExternalTypedData();
  list[0] = 0xff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, 0xff);
  ptr.free();
}

void testInt16Load() {
  // Load
  Pointer<Int16> ptr = Pointer.allocate();
  ptr.value = 0xffff;
  Int16List list = ptr.asExternalTypedData();
  Expect.equals(list[0], -1);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testInt16Store() {
  // Store
  Pointer<Int16> ptr = Pointer.allocate();
  Int16List list = ptr.asExternalTypedData();
  list[0] = 0xffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, -1);
  ptr.free();
}

void testUint16Load() {
  // Load
  Pointer<Uint16> ptr = Pointer.allocate();
  ptr.value = 0xffff;
  Uint16List list = ptr.asExternalTypedData();
  Expect.equals(list[0], 0xffff);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testUint16Store() {
  // Store
  Pointer<Uint16> ptr = Pointer.allocate();
  Uint16List list = ptr.asExternalTypedData();
  list[0] = 0xffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, 0xffff);
  ptr.free();
}

void testInt32Load() {
  // Load
  Pointer<Int32> ptr = Pointer.allocate();
  ptr.value = 0xffffffff;
  Int32List list = ptr.asExternalTypedData();
  Expect.equals(list[0], -1);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testInt32Store() {
  // Store
  Pointer<Int32> ptr = Pointer.allocate();
  Int32List list = ptr.asExternalTypedData();
  list[0] = 0xffffffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, -1);
  ptr.free();
}

void testUint32Load() {
  // Load
  Pointer<Uint32> ptr = Pointer.allocate();
  ptr.value = 0xffffffff;
  Uint32List list = ptr.asExternalTypedData();
  Expect.equals(list[0], 0xffffffff);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testUint32Store() {
  // Store
  Pointer<Uint32> ptr = Pointer.allocate();
  Uint32List list = ptr.asExternalTypedData();
  list[0] = 0xffffffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, 0xffffffff);
  ptr.free();
}

void testInt64Load() {
  // Load
  Pointer<Int64> ptr = Pointer.allocate();
  ptr.value = 0xffffffffffffffff;
  Int64List list = ptr.asExternalTypedData();
  Expect.equals(list[0], -1);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testInt64Store() {
  // Store
  Pointer<Int64> ptr = Pointer.allocate();
  Int64List list = ptr.asExternalTypedData();
  list[0] = 0xffffffffffffffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, -1);
  ptr.free();
}

void testUint64Load() {
  // Load
  Pointer<Uint64> ptr = Pointer.allocate();
  ptr.value = 0xffffffffffffffff;
  Uint64List list = ptr.asExternalTypedData();
  Expect.equals(list[0], 0xffffffffffffffff);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testUint64Store() {
  // Store
  Pointer<Uint64> ptr = Pointer.allocate();
  Uint64List list = ptr.asExternalTypedData();
  list[0] = 0xffffffffffffffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, 0xffffffffffffffff);
  ptr.free();
}

void testIntPtr() {
  bool is32Bit = sizeOf<IntPtr>() == 4;
  Pointer<IntPtr> ptr = Pointer.allocate();
  final array = ptr.asExternalTypedData();
  if (is32Bit) {
    Expect.type<Int32List>(array);
  } else {
    Expect.type<Int64List>(array);
  }
  ptr.free();
}

double maxFloat = (2 - pow(2, -23)) * pow(2, 127);
double maxDouble = (2 - pow(2, -52)) * pow(2, pow(2, 10) - 1);

void testFloatLoad() {
  // Load
  Pointer<Float> ptr = Pointer.allocate();
  ptr.value = maxFloat;
  Float32List list = ptr.asExternalTypedData();
  Expect.equals(list[0], maxFloat);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testFloatStore() {
  // Store
  Pointer<Float> ptr = Pointer.allocate();
  Float32List list = ptr.asExternalTypedData();
  list[0] = maxFloat;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, maxFloat);
  ptr.free();
}

void testDoubleLoad() {
  // Load
  Pointer<Double> ptr = Pointer.allocate();
  ptr.value = maxDouble;
  Float64List list = ptr.asExternalTypedData();
  Expect.equals(list[0], maxDouble);
  Expect.equals(list.length, 1);
  ptr.free();
}

void testDoubleStore() {
  // Store
  Pointer<Double> ptr = Pointer.allocate();
  Float64List list = ptr.asExternalTypedData();
  list[0] = maxDouble;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, maxDouble);
  ptr.free();
}

void testArrayLoad() {
  const int count = 0x100;
  Pointer<Int32> ptr = Pointer.allocate(count: count);
  for (int i = 0; i < count; ++i) {
    ptr[i] = i;
  }
  Int32List array = ptr.asExternalTypedData(count: count);
  for (int i = 0; i < count; ++i) {
    Expect.equals(array[i], i);
  }
  ptr.free();
}

void testArrayStore() {
  const int count = 0x100;
  Pointer<Int32> ptr = Pointer.allocate(count: count);
  Int32List array = ptr.asExternalTypedData(count: count);
  for (int i = 0; i < count; ++i) {
    array[i] = i;
  }
  for (int i = 0; i < count; ++i) {
    Expect.equals(ptr[i], i);
  }
  ptr.free();
}

void testNegativeArray() {
  Pointer<Int32> ptr = nullptr.cast();
  Expect.throws<ArgumentError>(() => ptr.asExternalTypedData(count: -1));
}

// Tests that the address we're creating an ExternalTypedData from is aligned to
// the element size.
void testAlignment() {
  Expect.throws<ArgumentError>(
      () => Pointer<Int16>.fromAddress(1).asExternalTypedData());
  Expect.throws<ArgumentError>(
      () => Pointer<Int32>.fromAddress(2).asExternalTypedData());
  Expect.throws<ArgumentError>(
      () => Pointer<Int64>.fromAddress(4).asExternalTypedData());
  Expect.throws<ArgumentError>(
      () => Pointer<Uint16>.fromAddress(1).asExternalTypedData());
  Expect.throws<ArgumentError>(
      () => Pointer<Uint32>.fromAddress(2).asExternalTypedData());
  Expect.throws<ArgumentError>(
      () => Pointer<Uint64>.fromAddress(4).asExternalTypedData());
  Expect.throws<ArgumentError>(
      () => Pointer<Float>.fromAddress(2).asExternalTypedData());
  Expect.throws<ArgumentError>(
      () => Pointer<Double>.fromAddress(4).asExternalTypedData());
}
