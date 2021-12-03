// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the support for generic function instantiation with constant and
// potentially constant expressions. Include both some explicit generic
// function instantiations, and some implicit ones (for the latter, the type
// arguments are derived by type inference based on the context type). The
// main goal is to test the new feature where the underlying function is
// given as an existing function object, which also implies that there are
// several new possible syntactic forms, e.g., `(b ? f1 : f2)<int>`.

import 'instantiated_function_constant_test.dart' as prefix;

void f1<X extends num>(X x, [num n = 0, List<X> xList = const []]) {}
void f2<Y extends num>(Y y, [int i = 1, Map<Y, Y> yMap = const {}]) {}

const b = true;

const c01 = f1;
const c02 = f2;

// Explicitly instantiate function declaration.
const c03 = f1<int>;
const c04 = prefix.f2<int>;
const c05 = prefix.f1<int>;
const c06 = f2<int>;

// Explicitly instantiate constant variable.
const c07 = prefix.c01<int>;
const c08 = c02<int>;
const c09 = c01<int>;
const c10 = prefix.c02<int>;

// Implicitly instantiate function declaration.
const void Function(double) c11 = f1;
const void Function(Never, [int, Map<int, int>]) c12 = prefix.f2;

// Implicitly instantiate constant variable.
const void Function(double) c13 = prefix.c01;
const void Function(Never, [int, Map<int, int>]) c14 = c02;

// Test new potentially constant expressions. A type variable is a potentially
// constant type expression, so there are no errors in the initializer list.
class A<U extends num> {
  final x1, x2, x3, x4, x5, x6;
  final void Function(U) x7;
  final void Function(U) x8;
  final void Function(U, [int, Map<num, Never>]) x9;
  final void Function(U) x10;
  final void Function(num) x11;
  final void Function(double) x12;
  final void Function(num, [int, Map<num, Never>]) x13;
  final void Function(int) x14;

  const A(bool b)
      : x1 = b ? (b ? f1 : prefix.f2)<U> : (b ? f1 : prefix.f2)<int>,
        x2 = b ? (b ? prefix.c01 : c02)<U> : (b ? prefix.c01 : c02)<int>,
        x3 = b ? ((b ? prefix.f1 : f2))<U> : ((b ? prefix.f1 : f2))<int>,
        x4 = b ? ((b ? c01 : prefix.c02))<U> : ((b ? c01 : prefix.c02))<int>,
        x5 = b ? (null ?? f1)<U> : (null ?? f1)<int>,
        x6 = b
            ? ((c01 as dynamic) as void Function<X extends num>(X,
                [num, List<X>]))<U>
            : ((c01 as dynamic) as void Function<X extends num>(X,
                [num, List<X>]))<int>,
        x7 = b ? f1 : f2,
        x8 = b ? c01 : c02,
        x9 = null ?? c02,
        x10 =
            (c01 as dynamic) as void Function<X extends num>(X, [int, List<X>]),
        x11 = b ? f1 : f2,
        x12 = b ? c01 : c02,
        x13 = null ?? c02,
        x14 =
            (c01 as dynamic) as void Function<X extends num>(X, [int, List<X>]);
}

void main() {
  const ff = false;
  const A<double>(true);
  const A<num>(ff);
}
