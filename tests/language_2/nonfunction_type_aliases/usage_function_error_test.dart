// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

// Introduce an aliased type.

typedef T = Function;

// Use the aliased type.

abstract class C {
  final T v12;

  C(): v12 = T();
  //         ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

X foo<X>(X x) => x;

main() {
  var v14 = <Set<T>, Set<T>>{{}: {}};
  v14[{}] = {T()};
  //         ^
  // [analyzer] unspecified
  // [cfe] unspecified

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
}
