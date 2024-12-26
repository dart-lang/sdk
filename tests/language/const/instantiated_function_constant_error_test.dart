// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the support for error detection with generic function instantiation
// expressions that are constant or potentially constant. Include both some
// explicit generic function instantiations, and some implicit ones (for the
// latter, the type arguments are derived by type inference based on the
// context type). The main goal is to test the new feature where the underlying
// function is given as an existing function object, which also implies that
// there are several new possible syntactic forms, e.g., `(b ? f1 : f2)<int>`.
// The errors generally arise because one or more subexpressions are not
// constant.

import 'instantiated_function_constant_test.dart' as prefix;

void f1<X extends num>(X x, [num n = 0, List<X> xList = const []]) {}
void f2<Y extends num>(Y y, [int i = 1, Map<Y, Y> yMap = const {}]) {}

const b = true;

const c01 = f1;
const c02 = f2;

void test<Z extends num>() {
  void g1<X extends num>(X x, [num n = 0, List<X> xList = const []]) {}
  void g2<Y extends num>(Y y, [int i = 1, Map<Y, Y> yMap = const {}]) {}

  // Explicitly instantiate function declaration.

  const c03 = f1<Z>;
  //            ^
  // [cfe] Type variables can't be used as constants.
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c04 = prefix.f2<Z>;
  //                   ^
  // [cfe] Type variables can't be used as constants.
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c05 = prefix.f1<Z>;
  //                   ^
  // [cfe] Type variables can't be used as constants.
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c06 = f2<Z>;
  //            ^
  // [cfe] Type variables can't be used as constants.
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c07 = g1<int>;
  //          ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] Not a constant expression.

  const c08 = prefix.g2<int>;
  //          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                 ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_PREFIXED_NAME
  // [cfe] Undefined name 'g2'.

  const c09 = prefix.g1<int>;
  //          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                 ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_PREFIXED_NAME
  // [cfe] Undefined name 'g1'.

  const c10 = g2<int>;
  //          ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] Not a constant expression.

  const c11 = g1<Z>;
  //          ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] Not a constant expression.
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c12 = prefix.g2<Z>;
  //          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                 ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_PREFIXED_NAME
  // [cfe] Undefined name 'g2'.
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c13 = prefix.g1<Z>;
  //          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                 ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_PREFIXED_NAME
  // [cfe] Undefined name 'g1'.
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c14 = g2<Z>;
  //          ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] Not a constant expression.
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  // Explicitly instantiate constant variable.

  const c07 = prefix.c01<Z>;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'c07' is already declared in this scope.
  //                     ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c08 = c02<Z>;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'c08' is already declared in this scope.
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c09 = c01<Z>;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'c09' is already declared in this scope.
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const c10 = prefix.c02<Z>;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'c10' is already declared in this scope.
  //                     ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  // Implicitly instantiate function declaration.

  const void Function(Z) c11 = f1;
  //                     ^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'c11' is already declared in this scope.
  //                           ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const void Function(Z, [int, Map<int, int>]) c12 = prefix.f2;
  //                                           ^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'c12' is already declared in this scope.

  // Implicitly instantiate constant variable.

  const void Function(Z) c13 = prefix.c01;
  //                     ^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'c13' is already declared in this scope.
  //                           ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS

  const void Function(Z, [int, Map<int, int>]) c14 = c02;
  //                                           ^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'c14' is already declared in this scope.
}

// Test new potentially constant expressions. A type variable is a potentially
// constant type expression, so there are no errors in the initializer list.
class A<U extends num> {
  final x1, x2, x3, x4, x5, x6;
  final void Function(U) x7;
  final void Function(U) x8;
  final void Function(U, [int, Map<num, Never>]) x9;
  final void Function(U) x10;

  const A(bool b)
    : x1 = (b ? f1 : prefix.f2)<U>,
      x2 = (b ? prefix.c01 : c02)<U>,
      x3 = ((b ? prefix.f1 : f2))<U>,
      x4 = ((b ? c01 : prefix.c02))<U>,
      x5 = (null ?? f1)<U>,
      x6 =
          ((c01 as dynamic)
              as void Function<X extends num>(X, [num, List<X>]))<U>,
      x7 = b ? f1 : f2,
      x8 = b ? c01 : c02,
      x9 = null ?? c02,
      x10 = (c01 as dynamic) as void Function<X extends num>(X, [int, List<X>]);
}

void main() {
  const ff = false;
  const A<double>(true);
  const A<num>(ff);

  void h<V>() {
    const A<V>(true);
    // [error column 5, length 16]
    // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS
    //    ^
    // [cfe] Type argument 'V' doesn't conform to the bound 'num' of the type variable 'U' on 'A'.
    // [cfe] Type variables can't be used as constants.
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

    const A<V>(ff);
    // [error column 5, length 14]
    // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS
    //    ^
    // [cfe] Type argument 'V' doesn't conform to the bound 'num' of the type variable 'U' on 'A'.
    // [cfe] Type variables can't be used as constants.
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  }
}
