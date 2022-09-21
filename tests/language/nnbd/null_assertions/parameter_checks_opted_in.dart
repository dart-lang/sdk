// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opted-in library for parameter_checks_test.dart.

import 'dart:async' show FutureOr;

bool topLevelField = false;
int get topLevelGetterSetterPair => 0;
set topLevelGetterSetterPair(int i) => null;
set topLevelSetterOnly(String s) => null;

foo1(int a) {}
foo2(int a, [int b = 1, String c = '']) {}
foo3({int a = 0, required int b}) {}
foo4a<T>(T a) {}
foo4b<T extends Object>(T a) {}
foo5a<T>(FutureOr<T> a) {}
foo5b<T extends Object>(FutureOr<T> a) {}
foo6a<T extends FutureOr<S>, S extends U, U extends int?>(T a) {}
foo6b<T extends FutureOr<S>, S extends U, U extends int>(T a) {}

void Function(int) bar() => (int x) {};

class A {
  int get getterSetterPair => 0;
  set getterSetterPair(int i) => null;
  set setterOnly(String s) => null;
  int field = 0;
  static bool staticField = false;
  static int get staticGetterSetterPair => 0;
  static set staticGetterSetterPair(int i) => null;
  static set staticSetterOnly(String s) => null;

  void instanceMethod(String s) => print(s);
  static void staticMethod(String s) => print(s);
}

class B extends A {
  // Overrides the getters but not the setters.
  @override
  int get getterSetterPair => 999;
  @override
  int get field => 999;
}
