// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {
  void f(int i);
  void g([int i]);
  void h({int i});
}

abstract class Mixin implements Base {}

class Derived extends Object with Mixin {
  // Type `(int) -> void` should be inherited from `Base`
  f(i) {}

  // Type `([int]) -> void` should be inherited from `Base`
  g([i]) {}

  // Type `({h: int}) -> void` should be inherited from `Base`
  h({i}) {}
}

main() {
  var d = new Derived();
  d.f('bad'); //# 01: compile-time error
  d.g('bad'); //# 02: compile-time error
  d.h(i: 'bad'); //# 03: compile-time error
  Object x = d.f(1); //# 04: compile-time error
  Object y = d.g(1); //# 05: compile-time error
  Object z = d.h(i: 1); //# 06: compile-time error
}
