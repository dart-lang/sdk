// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  static void foo();
  //               ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
  // [cfe] Expected a function body or '=>'.
}

main() {
  A();
//^
// [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
// [cfe] The class 'A' is abstract and can't be instantiated.
}
