// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  Foo(this.x);
  //       ^
  // [analyzer] STATIC_WARNING.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR
  // [cfe] 'x' is a final instance variable that has already been initialized.
  final int x = 42;
}

class CoffeeShop {
  final String shopName = "Coffee Lab";
  CoffeeShop.name(String shopName)
      : this.shopName = shopName;
      //     ^^^^^^^^
      // [analyzer] STATIC_WARNING.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION
      //              ^
      // [cfe] 'shopName' is a final instance variable that has already been initialized.
}

void main() {
  Foo f = new Foo(10);
  CoffeeShop presidentialCoffee =
      new CoffeeShop.name("Covfefe Lab");
}
