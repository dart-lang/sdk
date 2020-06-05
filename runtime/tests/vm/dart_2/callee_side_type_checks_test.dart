// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--reify-generic-functions

import "package:expect/expect.dart";

// This test tests that AOT compiler does not optimize away necessary
// type checks.

class A {
  int _addOneToArgument(int x) => x + 1;
}

abstract class G<T> {
  int _addOneToArgument(T x);
}

class B extends A implements G<int> {}

class C {
  int _addTwoToArgument(int x) => x + 2;
}

class D {
  int _addThreeToArgument(num x) {
    return 0;
  }
}

class E extends D {
  int _addThreeToArgument(covariant int x) {
    return x + 3;
  }
}

typedef dynamic F0<T>(T val);
typedef U F1<T, U>(T val);

class F<T> {
  T fMethod1(F0<T> f, T val) => f(val) as T;
  U fMethod2<U>(F1<T, U> f, T val) => f(val);
}

final arr = <Object>[
  new B(),
  new C(),
  new E(),
  new D(), // Just to confuse CHA
  new F<int>(),
];

int _add42Int(int v) => v + 42;
double _add42Double(double v) => v + 42;
double _add42_0Int(int v) => v + 42.0;

main() {
  final b = arr[0] as G<num>;

  Expect.equals(1, b._addOneToArgument(0));
  Expect.equals(0, b._addOneToArgument(-1));
  Expect.throwsTypeError(() => b._addOneToArgument(1.1));

  final c = (arr[1] as C);
  final tornMethod = c._addTwoToArgument;
  Expect.equals(2, c._addTwoToArgument(0));
  Expect.equals(0, c._addTwoToArgument(-2));
  Expect.throwsTypeError(() => (tornMethod as dynamic)(1.1));

  final e = (arr[2] as D);
  Expect.equals(3, e._addThreeToArgument(0));
  Expect.equals(0, e._addThreeToArgument(-3));
  Expect.throwsTypeError(() => e._addThreeToArgument(1.1));

  final f = (arr[4] as F<num>);
  final torn1 = f.fMethod1 as dynamic;
  Expect.equals(43, torn1(_add42Int, 1));
  Expect.throwsTypeError(() => torn1(_add42Double, 1));
  Expect.throwsTypeError(() => torn1(_add42Int, 1.1));

  final torn2 = f.fMethod2 as dynamic;
  Expect.equals(43, torn2<int>(_add42Int, 1));
  Expect.equals(43.0, torn2<double>(_add42_0Int, 1));
  Expect.throwsTypeError(() => torn2<double>(_add42Int, 1));
  Expect.throwsTypeError(() => torn2<int>(_add42_0Int, 1));
}
