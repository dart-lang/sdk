// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Foo<U> on List {
  static U foo1() { return null; }
  static void foo2(U x) { return null; }
  static void foo3() {
    U foo4;
    void foo5(U y) => print(y);
    U foo6() => null;
    void Function (U y) foo7 = (U y) => y;
  }
  static U Function() foo8() { return null; }
  static void Function(U) foo9() { return null; }
  static void foo10(U Function()) { return null; }
  // old syntax: variable named "U" of a function called 'Function'.
  static void foo11(void Function(U)) { return null; }
  static void foo12(void Function(U) b) { return null; }
  // old syntax: variable named "b" of type "U" of a function called 'Function'.
  static void foo13(void Function(U b)) { return null; }
  static U foo14 = null;
  static U Function(U) foo15 = null;
}

main() {}
