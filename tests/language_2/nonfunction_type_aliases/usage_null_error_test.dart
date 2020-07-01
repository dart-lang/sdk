// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

// Introduce an aliased type.

typedef T = Null;

// Use the aliased type.

abstract class C {
  final T v12;

  C(): v12 = T();
  //         ^
  // [analyzer] unspecified
  // [cfe] unspecified

  T operator +(T other);
  T get g;
  set g(T value);
  Map<T, T> m1(covariant T arg1, [Set<Set<T>> arg2]);
  void m2({T arg1, T arg2(T arg21, T arg22)});
}

class D1 extends T {}
//               ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D2 extends C with T {}
//                               ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D3 implements T {}
//                           ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D4 = C with T;
//                         ^
// [analyzer] unspecified
// [cfe] unspecified

X foo<X>(X x) => x;

main() {
  var v13 = <T>[];
  var v14 = <Set<T>, Set<T>>{{}: {}};
  v14[{}] = {T()};
  //         ^
  // [analyzer] unspecified
  // [cfe] unspecified

  var v15 = {v13};
  Set<List<T>> v16 = v15;
  v15 = v16;
  T();
//^
// [analyzer] unspecified
// [cfe] unspecified

  T.named();
  //^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  T v17 = foo<T>(T());
  //             ^
  // [analyzer] unspecified
  // [cfe] unspecified

  T.staticMethod<T>();
  //^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}
