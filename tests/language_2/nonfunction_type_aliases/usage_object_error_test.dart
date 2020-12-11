// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

// Introduce an aliased type.

typedef T = Object;

// Use the aliased type.

abstract class C {
  T v10;
  final T v12;
  C(): v12 = T();
  C.name1(this.v10, this.v12);
  factory C.name2(T arg1, T arg2) = C1.name1;
}

class C1 implements C {
  C1.name1(T arg1, T arg2);
  noSuchMethod(Invocation invocation) => throw 0;
}

abstract class D2 extends C with T {}
//             ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D3 implements T {}
//             ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D4 = C with T;
//             ^
// [analyzer] unspecified
// [cfe] unspecified

main() {
  T.named();
//  ^^^^^
// [analyzer] unspecified
// [cfe] unspecified

  T.staticMethod<T>();
//  ^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] Method not found: 'Object.staticMethod'.
//  ^^^^^^^^^^^^
// [cfe] A constructor invocation can't have type arguments on the constructor name.
}
