// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'coordinate.dart';

void main() {
  testZeroInt();
  testZeroFloat();
  testZeroStruct();
}

void testZeroInt() {
  final p = calloc<Uint8>();
  Expect.equals(0, p.value);
  calloc.free(p);
}

void testZeroFloat() {
  final p = calloc<Float>();
  Expect.approxEquals(0.0, p.value);
  calloc.free(p);
}

void testZeroStruct() {
  final p = calloc<Coordinate>();
  Expect.approxEquals(0, p.ref.x);
  Expect.approxEquals(0, p.ref.y);
  Expect.equals(nullptr, p.ref.next);
  calloc.free(p);
}
