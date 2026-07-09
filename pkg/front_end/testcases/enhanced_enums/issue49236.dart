// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M {
  String toString() => "M";
}

abstract mixin class A {
  String toString() => "A";
}

abstract class B implements Enum {
  String toString() => "B";
}

enum E1 with M { element }

enum E2 with M {
  element;

  String toString() => "E2";
}

enum E3 {
  element;

  String toString() => "E3";
}

enum E4 implements B { element }

enum E5 implements B {
  element;

  String toString() => "E5";
}

enum E6 with A { element }

enum E7 with A {
  element;

  String toString() => "E7";
}

checkEqual(x, y) {
  if (x != y) {
    throw "Expected '${x}' and '${y}' to be equal.";
  }
}

main() {
  checkEqual("${E1.element}", "M");
  checkEqual("${E2.element}", "E2");
  checkEqual("${E3.element}", "E3");
  checkEqual("${E4.element}", "E4.element");
  checkEqual("${E5.element}", "E5");
  checkEqual("${E6.element}", "A");
  checkEqual("${E7.element}", "E7");
}
