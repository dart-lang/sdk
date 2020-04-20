// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  static const b = const B();
}

class B implements A {
  const B();

  operator ==(o) => true;
}

main() {
  // It is a compile-time error if the key type overrides operator ==.
  dynamic m = const {A.b: 42};
  //          ^
  // [cfe] Constant evaluation error:
  //                 ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
  Expect.equals(42, m[const B()]);

  m = const {"foo": 99, A.b: 499};
  //  ^
  // [cfe] Constant evaluation error:
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
  Expect.equals(499, m[const B()]);
}
