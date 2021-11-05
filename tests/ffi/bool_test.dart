// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi bools.

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

import 'function_structs_by_value_generated_compounds.dart';

void main() {
  testSizeOf();
  testStoreLoad();
  testStoreLoadIndexed();
  testStruct();
  testStruct2();
  testInlineArray();
}

void testSizeOf() {
  Expect.equals(1, sizeOf<Bool>());
}

void testStoreLoad() {
  final p = calloc<Bool>();
  p.value = true;
  Expect.equals(true, p.value);
  p.value = false;
  Expect.equals(false, p.value);
  calloc.free(p);
}

void testStoreLoadIndexed() {
  final p = calloc<Bool>(2);
  p[0] = true;
  p[1] = false;
  Expect.equals(true, p[0]);
  Expect.equals(false, p[1]);
  calloc.free(p);
}

void testStruct() {
  final p = calloc<Struct1ByteBool>();
  p.ref.a0 = true;
  Expect.equals(true, p.ref.a0);
  p.ref.a0 = false;
  Expect.equals(false, p.ref.a0);
  calloc.free(p);
}

void testStruct2() {
  final p = calloc<Struct10BytesHomogeneousBool>();
  p.ref.a0 = true;
  p.ref.a1 = false;
  p.ref.a2 = true;
  p.ref.a3 = false;
  p.ref.a4 = true;
  p.ref.a5 = false;
  p.ref.a6 = true;
  p.ref.a7 = false;
  p.ref.a8 = true;
  p.ref.a9 = false;
  Expect.equals(true, p.ref.a0);
  Expect.equals(false, p.ref.a1);
  Expect.equals(true, p.ref.a2);
  Expect.equals(false, p.ref.a3);
  Expect.equals(true, p.ref.a4);
  Expect.equals(false, p.ref.a5);
  Expect.equals(true, p.ref.a6);
  Expect.equals(false, p.ref.a7);
  Expect.equals(true, p.ref.a8);
  Expect.equals(false, p.ref.a9);
  calloc.free(p);
}

void testInlineArray() {
  final p = calloc<Struct10BytesInlineArrayBool>();
  final array = p.ref.a0;
  for (int i = 0; i < 10; i++) {
    array[i] = i % 2 == 0;
  }
  for (int i = 0; i < 10; i++) {
    Expect.equals(i % 2 == 0, array[i]);
  }
  calloc.free(p);
}
