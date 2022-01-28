// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

void main() {
  testSizeOf();
  testStoreLoad();
  testStoreLoadIndexed();
  testStruct();
  testInlineArray();
  testInlineArray2();
}

void testSizeOf() {
  final size = sizeOf<WChar>();
  if (Platform.isWindows) {
    Expect.equals(2, size);
  } else {
    Expect.equals(4, size);
  }
}

void testStoreLoad() {
  final p = calloc<WChar>();
  p.value = 10;
  Expect.equals(10, p.value);
  calloc.free(p);
}

void testStoreLoadIndexed() {
  final p = calloc<WChar>(2);
  p[0] = 10;
  p[1] = 3;
  Expect.equals(10, p[0]);
  Expect.equals(3, p[1]);
  calloc.free(p);
}

class WCharStruct extends Struct {
  @WChar()
  external int a0;

  @WChar()
  external int a1;
}

void testStruct() {
  final p = calloc<WCharStruct>();
  p.ref.a0 = 1;
  Expect.equals(1, p.ref.a0);
  p.ref.a0 = 2;
  Expect.equals(2, p.ref.a0);
  calloc.free(p);
}

class WCharArrayStruct extends Struct {
  @Array(100)
  external Array<WChar> a0;
}

void testInlineArray() {
  final p = calloc<WCharArrayStruct>();
  final array = p.ref.a0;
  for (int i = 0; i < 100; i++) {
    array[i] = i;
  }
  for (int i = 0; i < 100; i++) {
    Expect.equals(i, array[i]);
  }
  calloc.free(p);
}

const _dim0 = 3;
const _dim1 = 8;
const _dim2 = 4;

class WCharArrayArrayStruct extends Struct {
  @Array(_dim1, _dim2)
  external Array<Array<WChar>> a0;
}

void testInlineArray2() {
  int someValue(int a, int b, int c) => a * 1337 + b * 42 + c;
  final p = calloc<WCharArrayArrayStruct>(_dim0);
  for (int i0 = 0; i0 < _dim0; i0++) {
    final array = p.elementAt(i0).ref.a0;
    for (int i1 = 0; i1 < _dim1; i1++) {
      final array2 = array[i1];
      for (int i2 = 0; i2 < _dim2; i2++) {
        array2[i2] = someValue(i0, i1, i2);
      }
    }
  }
  for (int i0 = 0; i0 < _dim0; i0++) {
    final array = p.elementAt(i0).ref.a0;
    for (int i1 = 0; i1 < _dim1; i1++) {
      final array2 = array[i1];
      for (int i2 = 0; i2 < _dim2; i2++) {
        Expect.equals(someValue(i0, i1, i2), array2[i2]);
      }
    }
  }
  calloc.free(p);
}
