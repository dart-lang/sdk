// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  int foo();

  noSuchMethod(im) => 42;
}

class B extends Object with A {
  foo() => super.foo();
  //             ^^^
  // [analyzer] COMPILE_TIME_ERROR.ABSTRACT_SUPER_MEMBER_REFERENCE
  // [cfe] Superclass has no method named 'foo'.
}

main() {
  Expect.equals(42, new B().foo());
}
