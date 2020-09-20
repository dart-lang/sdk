// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var b = new B();
  Expect.equals(42, b.foo());
}

class A {
//    ^
// [cfe] The non-abstract class 'A' is missing implementations for these members:
  foo();
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
  static bar();
  //          ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
  // [cfe] Expected a function body or '=>'.
}

class B extends A {
  foo() => 42;
  bar() => 87;
}
