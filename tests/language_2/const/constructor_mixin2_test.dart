// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Mixin {
  var nonFinalField;
}

class A {
  const A(foo);
}

class B extends A
    with Mixin
{
  const B(foo) : super(foo);
//      ^
// [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD
//      ^
// [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD
//               ^
// [cfe] A constant constructor can't call a non-constant super constructor.
}

main() {
  var a = const B(42);
  a.nonFinalField = 54;
}
