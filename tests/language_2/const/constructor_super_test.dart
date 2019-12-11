// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final a;
  A(this.a); // Not const.
  const A.five() : a = 5;
}

class B extends A {
  final b;
  B(x)
      : b = x + 1,
        super(x);

  // Const constructor cannot call non-const super constructor.
  const B.zerofive() : b = 0, super(5);
  //                          ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER
  // [cfe] A constant constructor can't call a non-constant super constructor.
}

class C extends A {
  C() : super(0);
  // Implicit call to non-const constructor A(x).
  const C.named(x);
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER
  // [cfe] The superclass, 'A', has no unnamed constructor that takes no arguments.
  //    ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NO_DEFAULT_SUPER_CONSTRUCTOR
}

main() {
  var b = new B.zerofive();
  var b1 = new B(0);
  var c = new C.named("");
}
