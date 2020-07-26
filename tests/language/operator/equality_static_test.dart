// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the static analysis of expressions of the form `e1 == e2`: Null is
// allowed on both the left and right hand side, but handled separately, so
// the instance member `operator ==` is only invoked with non-null receiver
// and argument.

import 'dart:async';

class A {}

class Covar1 {
  // When `typeof(e1)` is `Covar1`, `e1 == e2` requires `typeof(e2) <: Covar1`.
  operator ==(covariant Covar1 other) => identical(this, other);
}

abstract class AbstractCovar2 {
  // When typeof(e1) is a subtype of `AbstractCovar2`, but not a subtype of
  // `Covar2Impl`, `e1 == e2` requires `typeof(e2) <: AbstractCovar2`. We use
  // `const` to make it statically known that the actual object for `e1` is a
  // `Covar2Impl`, thus checking that the `==` check uses the specified static
  // type rather than using knowledge about the constant expression directly.
  operator ==(covariant AbstractCovar2 other);
  const factory AbstractCovar2() = Covar2Impl;
}

class Covar2Impl implements AbstractCovar2 {
  const Covar2Impl();
  operator ==(Object other) => identical(this, other);
}

void main() {
  num numVar = 2;
  A aVar = A();
  Covar1 covar1Var = Covar1();
  A? aNullableVar = null;
  Covar1? covar1NullableVar = null;
  FutureOr<int?> futureOrNullableIntVar = null;
  FutureOr<Covar1> futureOrCovar1Var = covar1Var;
  List<void> voidListVar = [1];
  var voidVar = voidListVar[0];

  null == null;
  null == true;
  null == <int>{};
  null == numVar;
  null == aVar;
  null == covar1Var;
  null == aNullableVar;
  null == covar1NullableVar;
  null == futureOrNullableIntVar;
  null == futureOrCovar1Var;
  null == const AbstractCovar2();
  null == voidListVar;
  null == voidVar;
  //      ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  true == null;
  true == true;
  true == <int>{};
  true == numVar;
  true == aVar;
  true == covar1Var;
  true == aNullableVar;
  true == covar1NullableVar;
  true == futureOrNullableIntVar;
  true == futureOrCovar1Var;
  true == const AbstractCovar2();
  true == voidListVar;
  true == voidVar;
  //      ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  <int>{} == null;
  <int>{} == true;
  <int>{} == <int>{};
  <int>{} == numVar;
  <int>{} == aVar;
  <int>{} == covar1Var;
  <int>{} == aNullableVar;
  <int>{} == covar1NullableVar;
  <int>{} == futureOrNullableIntVar;
  <int>{} == futureOrCovar1Var;
  <int>{} == const AbstractCovar2();
  <int>{} == voidListVar;
  <int>{} == voidVar;
  //         ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  numVar == null;
  numVar == true;
  numVar == <int>{};
  numVar == numVar;
  numVar == aVar;
  numVar == covar1Var;
  numVar == aNullableVar;
  numVar == covar1NullableVar;
  numVar == futureOrNullableIntVar;
  numVar == futureOrCovar1Var;
  numVar == const AbstractCovar2();
  numVar == voidListVar;
  numVar == voidVar;
  //        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  aVar == null;
  aVar == true;
  aVar == <int>{};
  aVar == numVar;
  aVar == aVar;
  aVar == covar1Var;
  aVar == aNullableVar;
  aVar == covar1NullableVar;
  aVar == futureOrNullableIntVar;
  aVar == futureOrCovar1Var;
  aVar == const AbstractCovar2();
  aVar == voidListVar;
  aVar == voidVar;
  //      ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  covar1Var == null;
  covar1Var == true;
  //           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1Var == <int>{};
  //           ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1Var == numVar;
  //           ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1Var == aVar;
  //           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1Var == covar1Var;
  covar1Var == aNullableVar;
  //           ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1Var == covar1NullableVar;
  covar1Var == futureOrNullableIntVar;
  //           ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1Var == futureOrCovar1Var;
  //           ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1Var == const AbstractCovar2();
  //           ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1Var == voidListVar;
  //           ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1Var == voidVar;
  //           ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  aNullableVar == null;
  aNullableVar == true;
  aNullableVar == <int>{};
  aNullableVar == numVar;
  aNullableVar == aVar;
  aNullableVar == covar1Var;
  aNullableVar == aNullableVar;
  aNullableVar == covar1NullableVar;
  aNullableVar == futureOrNullableIntVar;
  aNullableVar == futureOrCovar1Var;
  aNullableVar == const AbstractCovar2();
  aNullableVar == voidListVar;
  aNullableVar == voidVar;
  //              ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  covar1NullableVar == null;
  covar1NullableVar == true;
  //                   ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1NullableVar == <int>{};
  //                   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1NullableVar == numVar;
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1NullableVar == aVar;
  //                   ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1NullableVar == covar1Var;
  covar1NullableVar == aNullableVar;
  //                   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1NullableVar == covar1NullableVar;
  covar1NullableVar == futureOrNullableIntVar;
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1NullableVar == futureOrCovar1Var;
  //                   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1NullableVar == const AbstractCovar2();
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1NullableVar == voidListVar;
  //                   ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  covar1NullableVar == voidVar;
  //                   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  futureOrNullableIntVar == null;
  futureOrNullableIntVar == true;
  futureOrNullableIntVar == <int>{};
  futureOrNullableIntVar == numVar;
  futureOrNullableIntVar == aVar;
  futureOrNullableIntVar == covar1Var;
  futureOrNullableIntVar == aNullableVar;
  futureOrNullableIntVar == covar1NullableVar;
  futureOrNullableIntVar == futureOrNullableIntVar;
  futureOrNullableIntVar == futureOrCovar1Var;
  futureOrNullableIntVar == const AbstractCovar2();
  futureOrNullableIntVar == voidListVar;
  futureOrNullableIntVar == voidVar;
  //                        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  futureOrCovar1Var == null;
  futureOrCovar1Var == true;
  futureOrCovar1Var == <int>{};
  futureOrCovar1Var == numVar;
  futureOrCovar1Var == aVar;
  futureOrCovar1Var == covar1Var;
  futureOrCovar1Var == aNullableVar;
  futureOrCovar1Var == covar1NullableVar;
  futureOrCovar1Var == futureOrNullableIntVar;
  futureOrCovar1Var == futureOrCovar1Var;
  futureOrCovar1Var == const AbstractCovar2();
  futureOrCovar1Var == voidListVar;
  futureOrCovar1Var == voidVar;
  //                   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  const AbstractCovar2() == null;
  const AbstractCovar2() == true;
  //                        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == <int>{};
  //                        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == numVar;
  //                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == aVar;
  //                        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == covar1Var;
  //                        ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == aNullableVar;
  //                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == covar1NullableVar;
  //                        ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == futureOrNullableIntVar;
  //                        ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == futureOrCovar1Var;
  //                        ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == const AbstractCovar2();
  const AbstractCovar2() == voidListVar;
  //                        ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
  const AbstractCovar2() == voidVar;
  //                        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  voidListVar == null;
  voidListVar == true;
  voidListVar == <int>{};
  voidListVar == numVar;
  voidListVar == aVar;
  voidListVar == covar1Var;
  voidListVar == aNullableVar;
  voidListVar == covar1NullableVar;
  voidListVar == futureOrNullableIntVar;
  voidListVar == futureOrCovar1Var;
  voidListVar == const AbstractCovar2();
  voidListVar == voidListVar;
  voidListVar == voidVar;
  //             ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  voidVar == null;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == true;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == <int>{};
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == numVar;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == aVar;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == covar1Var;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == aNullableVar;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == covar1NullableVar;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == futureOrNullableIntVar;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == futureOrCovar1Var;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == voidListVar;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] unspecified
  voidVar == voidVar;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.
//           ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  void fun<X extends Covar1, Y extends Covar1?, Z extends FutureOr<Covar1>>(
      X covar1Var, Y covar1NullableVar, Z futureOrCovar1Var) {
    covar1Var == null;
    covar1Var == true;
    //           ^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1Var == <int>{};
    //           ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1Var == numVar;
    //           ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1Var == aVar;
    //           ^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1Var == covar1Var;
    covar1Var == aNullableVar;
    //           ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1Var == covar1NullableVar;
    covar1Var == futureOrNullableIntVar;
    //           ^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1Var == futureOrCovar1Var;
    //           ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1Var == const AbstractCovar2();
    //           ^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1Var == voidListVar;
    //           ^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1Var == voidVar;
    //           ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.

    covar1NullableVar == null;
    covar1NullableVar == true;
    //                   ^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1NullableVar == <int>{};
    //                   ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1NullableVar == numVar;
    //                   ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1NullableVar == aVar;
    //                   ^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1NullableVar == covar1Var;
    covar1NullableVar == aNullableVar;
    //                   ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1NullableVar == covar1NullableVar;
    covar1NullableVar == futureOrNullableIntVar;
    //                   ^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1NullableVar == futureOrCovar1Var;
    //                   ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1NullableVar == const AbstractCovar2();
    //                   ^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1NullableVar == voidListVar;
    //                   ^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] unspecified
    covar1NullableVar == voidVar;
    //                   ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.

    futureOrCovar1Var == null;
    futureOrCovar1Var == true;
    futureOrCovar1Var == <int>{};
    futureOrCovar1Var == numVar;
    futureOrCovar1Var == aVar;
    futureOrCovar1Var == covar1Var;
    futureOrCovar1Var == aNullableVar;
    futureOrCovar1Var == covar1NullableVar;
    futureOrCovar1Var == futureOrNullableIntVar;
    futureOrCovar1Var == futureOrCovar1Var;
    futureOrCovar1Var == const AbstractCovar2();
    futureOrCovar1Var == voidListVar;
    futureOrCovar1Var == voidVar;
    //                   ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}
