// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'late_statics_lib.dart' as lib;
export 'late_statics_lib.dart';

void main() {
  testUninitializedNonFinalStaticField();
  testUninitializedFinalStaticField();
  testInitializedNonFinalStaticField();
  testInitializedFinalStaticField();
  testUninitializedNonFinalTopLevelField();
  testUninitializedFinalTopLevelField();
  testInitializedNonFinalTopLevelField();
  testInitializedFinalTopLevelField();
}

class Statics {
  static late int a;
  static late final int b;
  static late int c = -1;
  static late final int d = -1;
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
