// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  late int a;
  late final int b;
  late int c = -1;
  late final int d = -1;
}

class Statics {
  static late int a;
  static late final int b;
  static late int c = -1;
  static late final int d = -1;
}

void testNullableUninitializedNonFinalLocal() {
  late int? x;
  x = 42;
  print(x);
}

void testNonNullableUninitializedNonFinalLocal() {
  late int x;
  x = 42;
  print(x);
}

void testNullableUninitializedFinalLocal() {
  late final int? x;
  x = 42;
  print(x);
}

void testNonNullableUninitializedFinalLocal() {
  late final int x;
  x = 42;
  print(x);
}

void testNullableInitializedNonFinalLocal() {
  late int? x = -1;
  print(x);
  x = 42;
  print(x);

  late int? y = null;
  print(y);
  y = 42;
  print(y);
}

void testNonNullableInitializedNonFinalLocal() {
  late int x = -1;
  print(x);
  x = 42;
  print(x);
}

void testNullableInitializedFinalLocal() {
  late final int? x = -1;
  print(x);

  late final int? y = null;
  print(y);
}

void testNonNullableInitializedFinalLocal() {
  late final int x = -1;
  print(x);
}
