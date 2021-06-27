// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9
// Requirements=nnbd-weak


// Test that a type alias `T` denoting `FutureOr<int>`
// can give rise to the expected errors.

import 'usage_futureor_error_lib.dart';

// Use the aliased type.

abstract class C {
  final T v12;

  C() : v12 = T();
  //         ^
  // [analyzer] unspecified
  // [cfe] unspecified
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

  T.staticMethod<T>();
  //^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}
