// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<U> {
  static U foo1() {
    return null;
  }

  static List<U> foo1Prime() {
    throw '';
  }

  static void foo2(U x) {}
  static void foo2Prime(List<U> x) {}
  static void foo3() {
    U foo4;
    List<U> foo4Prime;
    void foo5(U y) => print(y);
    void foo5Prime(List<U> y) => print(y);
    U foo6() => null;
    List<U> foo6Prime() => throw '';
    void Function(U y) foo7 = (U y) => y;
    void Function(List<U> y) foo7Prime = (List<U> y) => y;
  }

  static U Function() foo8() {
    throw '';
  }

  static List<U> Function() foo8Prime() {
    throw '';
  }

  static void Function(U) foo9() {}
  static void Function(List<U>) foo9Prime() {}
  static void foo10(U Function()) {}

  static void foo10Prime(List<U> Function()) {}

  // old syntax: variable named "U" of a function called 'Function'.
  static void foo11(void Function(U)) {}

  static void foo12(void Function(U) b) {}

  static void foo12Prime(void Function(List<U>) b) {}

  // old syntax: variable named "b" of type "U" of a function called 'Function'.
  static void foo13(void Function(U b)) {}

  // old syntax: variable named "b" of type "List<U>" of a function called 'Function'.
  static void foo13Prime(void Function(List<U> b)) {}

  static late U foo14;
  static late List<U> foo14Prime;
  static late U Function(U) foo15;
  static late List<U> Function(List<U>) foo15Prime;
}

main() {}
