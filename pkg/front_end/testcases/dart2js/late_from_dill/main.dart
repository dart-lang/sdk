// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib1.dart';
import 'main_lib2.dart' as lib;

void main() {
  testUninitializedNonFinalInstanceField();
  testUninitializedFinalInstanceField();
  testInitializedNonFinalInstanceField();
  testInitializedFinalInstanceField();

  testNullableUninitializedNonFinalLocal();
  testNonNullableUninitializedNonFinalLocal();
  testNullableUninitializedFinalLocal();
  testNonNullableUninitializedFinalLocal();
  testNullableInitializedNonFinalLocal();
  testNonNullableInitializedNonFinalLocal();
  testNullableInitializedFinalLocal();
  testNonNullableInitializedFinalLocal();

  testUninitializedNonFinalStaticField();
  testUninitializedFinalStaticField();
  testInitializedNonFinalStaticField();
  testInitializedFinalStaticField();
  testUninitializedNonFinalTopLevelField();
  testUninitializedFinalTopLevelField();
  testInitializedNonFinalTopLevelField();
  testInitializedFinalTopLevelField();
}

var c = C();

void testUninitializedNonFinalInstanceField() {
  print(c.a);
  c.a = 42;
  print(c.a);
}

void testUninitializedFinalInstanceField() {
  print(c.b);
  c.b = 42;
  print(c.b);
}

void testInitializedNonFinalInstanceField() {
  print(c.c);
  c.c = 42;
  print(c.c);
}

void testInitializedFinalInstanceField() {
  print(c.d);
}

void testUninitializedNonFinalStaticField() {
  print(Statics.a);
  Statics.a = 42;
  print(Statics.a);
}

void testUninitializedFinalStaticField() {
  print(Statics.b);
  Statics.b = 42;
  print(Statics.b);
}

void testInitializedNonFinalStaticField() {
  print(Statics.c);
  Statics.c = 42;
  print(Statics.c);
}

void testInitializedFinalStaticField() {
  print(Statics.d);
}

void testUninitializedNonFinalTopLevelField() {
  print(lib.a);
  lib.a = 42;
  print(lib.a);
}

void testUninitializedFinalTopLevelField() {
  print(lib.b);
  lib.b = 42;
  print(lib.b);
}

void testInitializedNonFinalTopLevelField() {
  print(lib.c);
  lib.c = 42;
  print(lib.c);
}

void testInitializedFinalTopLevelField() {
  print(lib.d);
}
