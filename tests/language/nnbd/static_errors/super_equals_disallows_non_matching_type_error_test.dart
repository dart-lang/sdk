// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "package:expect/expect.dart";

// SharedOptions=--enable-experiment=non-nullable

// Test that `super == x` is properly type checked against the target
// `operator==` method.  That is, the special allowance in the following spec
// text (from accepted/future-releases/nnbd/feature-specification.md) allows `x`
// to be nullable, but still requires that the type otherwise matches:
//
//     Similarly, consider an expression `e` of the form `super == e2` that
//     occurs in a class whose superclass is `C`, where the static type of `e2`
//     is `T2`. Let `S` be the formal parameter type of the concrete declaration
//     of `operator ==` found by method lookup in `C` (_if that search succeeds,
//     otherwise it is a compile-time error_).  It is a compile-time error
//     unless `T2` is assignable to `S?`.

class Base {
  bool operator ==(covariant num other) => false;
}

class Derived extends Base {
  void test() {
    String string = 'foo';
    var stringQuestion = 'foo' as String?;
    super == string;
    //       ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'String' can't be assigned to the parameter type 'num?'.
    super == stringQuestion;
    //       ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'String?' can't be assigned to the parameter type 'num?'.
  }
}
