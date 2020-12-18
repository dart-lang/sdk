// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This tests the non trampoline aspects of nested structs.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");
void main() {
  for (int i = 0; i < 10; ++i) {
    testSizeOf();
    testAllocate();
    testRead();
    testWrite();
    testCopy();
  }
}

class Struct4BytesHomogeneousInt16 extends Struct {
  @Int16()
  int a0;

  @Int16()
  int a1;

  String toString() => "(${a0}, ${a1})";
}

class Struct8BytesNestedInt extends Struct {
  Struct4BytesHomogeneousInt16 a0;

  Struct4BytesHomogeneousInt16 a1;

  String toString() => "(${a0}, ${a1})";
}

void testSizeOf() {
  print(sizeOf<Struct8BytesNestedInt>());
  Expect.equals(8, sizeOf<Struct8BytesNestedInt>());
}

void testAllocate() {
  final p = allocate<Struct8BytesNestedInt>();
  Expect.type<Pointer<Struct8BytesNestedInt>>(p);
  print(p);
  free(p);
}

/// Test that reading does not segfault, even uninitialized.
void testRead() {
  print("read");
  final p = allocate<Struct8BytesNestedInt>();
  print(p);
  print(p.ref.runtimeType);
  print(p.ref.addressOf);
  print(p.ref.addressOf.address);
  print(p.ref.a0.runtimeType);
  print(p.ref.a0.addressOf);
  print(p.ref.a0.a0);
  free(p);
  print("read");
}

void testWrite() {
  print("write");
  final p = allocate<Struct8BytesNestedInt>(count: 2);
  p[0].a0.a0 = 12;
  p[0].a0.a1 = 13;
  p[0].a1.a0 = 14;
  p[0].a1.a1 = 15;
  p[1].a0.a0 = 16;
  p[1].a0.a1 = 17;
  p[1].a1.a0 = 18;
  p[1].a1.a1 = 19;
  Expect.equals(12, p[0].a0.a0);
  Expect.equals(13, p[0].a0.a1);
  Expect.equals(14, p[0].a1.a0);
  Expect.equals(15, p[0].a1.a1);
  Expect.equals(16, p[1].a0.a0);
  Expect.equals(17, p[1].a0.a1);
  Expect.equals(18, p[1].a1.a0);
  Expect.equals(19, p[1].a1.a1);
  free(p);
  print("written");
}

void testCopy() {
  print("copy");
  final p = allocate<Struct8BytesNestedInt>();
  p.ref.a0.a0 = 12;
  p.ref.a0.a1 = 13;
  p.ref.a1 = p.ref.a0;
  Expect.equals(12, p.ref.a1.a0);
  Expect.equals(13, p.ref.a1.a1);
  free(p);
  print("copied");
}
