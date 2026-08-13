// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  Function get fooFunction;
  dynamic get fooDynamic;
  void fooRegular(Object? arg);
  Never get fooNever;

  void bar() {}

  test() {
    fooFunction(bar());
    //          ^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
    fooDynamic(bar());
    //         ^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
    fooRegular(bar());
    //         ^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
    fooNever(bar());
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}

void main() {}
