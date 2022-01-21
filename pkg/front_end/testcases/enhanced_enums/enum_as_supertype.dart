// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A extends Enum { // Ok.
  int get foo => index;
}

enum EA with A { element }

abstract class B implements Enum { // Ok.
  int get foo => index;
}

enum EB with B { element }

mixin M on Enum { // Ok.
  int get foo => index;
}

enum EM with M { element }

mixin N implements Enum { // Ok.
  int get foo => index;
}

enum EN with N { element }

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '$x' to be equal to '$y'.";
  }
}

main() {
  expectEquals(EA.element.foo, EA.element.index);
  expectEquals(EB.element.foo, EB.element.index);
  expectEquals(EM.element.foo, EM.element.index);
  expectEquals(EN.element.foo, EN.element.index);
}
