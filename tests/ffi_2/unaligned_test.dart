// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This tests exercises misaligned reads/writes on memory.
//
// The only architecture on which this is known to fail is arm32 on Android.

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

void main() {
  print("hello");
  testUnalignedInt16(); //# 01: ok
  testUnalignedInt32(); //# 02: ok
  testUnalignedInt64(); //# 03: ok
  if (!Platform.isAndroid || sizeOf<Pointer>() == 8) {
    // TODO(http://dartbug.com/45009): Support unaligned reads/writes on
    // Android arm32.
    testUnalignedFloat(); //# 04: ok
    testUnalignedDouble(); //# 05: ok
  }
  _freeAll();
}

void testUnalignedInt16() {
  final pointer = _allocateUnaligned<Int16>();
  pointer.value = 20;
  Expect.equals(20, pointer.value);
}

void testUnalignedInt32() {
  final pointer = _allocateUnaligned<Int32>();
  pointer.value = 20;
  Expect.equals(20, pointer.value);
}

void testUnalignedInt64() {
  final pointer = _allocateUnaligned<Int64>();
  pointer.value = 20;
  Expect.equals(20, pointer.value);
}

void testUnalignedFloat() {
  final pointer = _allocateUnaligned<Float>();
  pointer.value = 20.0;
  Expect.approxEquals(20.0, pointer.value);
}

void testUnalignedDouble() {
  final pointer = _allocateUnaligned<Double>();
  pointer.value = 20.0;
  Expect.equals(20.0, pointer.value);
}

final Set<Pointer> _pool = {};

void _freeAll() {
  for (final pointer in _pool) {
    calloc.free(pointer);
  }
}

/// Up to `size<T>() == 8`.
Pointer<T> _allocateUnaligned<T extends NativeType>() {
  final pointer = calloc<Int8>(16);
  _pool.add(pointer);
  final misaligned = pointer.elementAt(1).cast<T>();
  Expect.equals(1, misaligned.address % 2);
  return misaligned;
}
