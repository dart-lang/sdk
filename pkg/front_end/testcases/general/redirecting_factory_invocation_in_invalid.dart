// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  int field = 0;

  factory Class1() = Class1._;

  Class1._();

  int get getter => 0;
}

class Class2 extends Class1 {
  final Class2 _c2;

  Class2(this._c2) : super._() {
    // Invocation inside an invalid unary expression.
    -new Class1();
    // Invocation inside an invalid binary expression.
    ('' + '') - new Class1();
    // Invocation inside an invalid index set.
    (0 + 1)[0] = new Class1();
    _c2[0] = new Class1();
    // Invocation inside an invalid index get.
    (0 + 1)[new Class1()];
    // Invocation inside an invalid property get.
    new Class1().foo;
    // Invocation inside an invalid property set.
    (0 + 1).foo = new Class1();
    // Invocation inside an invalid invocation.
    new Class1().foo();
    // Invocation inside an invalid implicit call invocation.
    new Class1()();
    // Invocation inside an invalid implicit field invocation.
    new Class1().field();
    // Invocation inside an invalid implicit getter invocation.
    new Class1().getter();
    // Invocation inside an invalid implicit call-getter invocation.
    _c2(new Class1());
    // Duplicate named arguments
    method(a: 0, a: new Class1());
    // Triple named arguments
    method(a: 0, a: 1, a: new Class1());
    // Invocation inside an invalid super index get.
    super[new Class1()];
    // Invocation inside an invalid super index set.
    super[0] = new Class1();
    // Invocation inside an invalid super set.
    super.foo = new Class1();
    // Invocation inside an invalid super invocation.
    super.foo(new Class1());
    // Invocation inside an invalid super binary.
    super + new Class1();
  }

  method({a}) {}

  int get call => 0;
}

main() {}