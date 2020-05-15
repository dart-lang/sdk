// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

library opt_out;

class LegacyClass {
  int method1() => 0;

  int method2() => 0;

  int method3a(int a, int b) => 0;

  int method3b(int a, [int b]) => 0;

  int method3c([int a, int b]) => 0;

  int method4a(int a, int b) => 0;

  int method4b(int a, [int b]) => 0;

  int method4c([int a, int b]) => 0;

  int method5a(int a, {int b}) => 0;

  int method5b({int a, int b}) => 0;

  int method5c({int a, int b}) => 0;

  int method6a(int a, {int b}) => 0;

  int method6b({int a, int b}) => 0;

  int method6c({int a, int b}) => 0;

  int get getter1 => 0;

  int get getter2 => 0;

  void set setter1(int value) {}

  void set setter2(int value) {}

  int field1;

  int field2;

  int field3;

  int field4;

  int get property1 => 0;

  void set property1(int value) {}

  int get property2 => 0;

  void set property2(int value) {}

  int get property3 => 0;

  void set property3(int value) {}

  int get property4 => 0;

  void set property4(int value) {}
}

class GenericLegacyClass<T> {
  T method1() => null;
}
