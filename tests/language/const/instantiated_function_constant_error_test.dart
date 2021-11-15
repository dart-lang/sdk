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
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c04 = prefix.f2<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c05 = prefix.f1<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c06 = f2<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c07 = g1<int>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c08 = prefix.g2<int>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c09 = prefix.g1<int>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c10 = g2<int>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c11 = g1<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c12 = prefix.g2<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c13 = prefix.g1<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c14 = g2<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Explicitly instantiate constant variable.

  const c07 = prefix.c01<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c08 = c02<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c09 = c01<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const c10 = prefix.c02<Z>;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Implicitly instantiate function declaration.

  const void Function(Z) c11 = f1;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const void Function(Z, [int, Map<int, int>]) c12 = prefix.f2;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Implicitly instantiate constant variable.

  const void Function(Z) c13 = prefix.c01;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  const void Function(Z, [int, Map<int, int>]) c14 = c02;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified
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
        x6 = ((c01 as dynamic) as void Function<X extends num>(X,
            [num, List<X>]))<U>,
        x7 = b ? f1 : f2,
        x8 = b ? c01 : c02,
        x9 = null ?? c02,
        x10 =
            (c01 as dynamic) as void Function<X extends num>(X, [int, List<X>]);
}

void main() {
  const ff = false;
  const A<double>(true);
  const A<num>(ff);

  void h<V>() {
    const A<V>(true);
    //^
    // [analyzer] unspecified
    // [cfe] unspecified

    const A<V>(ff);
    //^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}
