// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  /*<T>*/ foo/*<T>*/({/*=T*/ x}) => x;
}

class B extends A {
  int bar() {
    try {
      throw 'bar';
      return 1;
    } finally {
      var x = super.foo(x: 41);
      return x + 1;
    }
  }
}

main() {
  Expect.equals(42, new B().bar());
}
