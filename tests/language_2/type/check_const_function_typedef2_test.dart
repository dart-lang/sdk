// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Tests that typechecks on const objects with typedefs work.

import "package:expect/expect.dart";

typedef String Int2String(int x);

class A {
  final Int2String f;
  const A(this.f);
}

int foo(String x) => 499;

const a = const A(foo);
//        ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
//                ^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'int Function(String)' can't be assigned to the parameter type 'String Function(int)'.

main() {
  a.f(499);
}
