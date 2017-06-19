// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  Foo(this.x);
  final int x = 42;
}

class CoffeeShop {
  final String name = "Coffee Lab";
  CoffeeShop.name(String name) : this.name = name;
}

void main() {
  Foo f = new Foo(10); //# 01: compile-time error
  CoffeeShop presidentialCoffee = //# 02: compile-time error
      new CoffeeShop.name("Covfefe Lab"); //# 02: compile-time error
}
