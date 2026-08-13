// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Introduce an aliased type.

typedef T = FutureOr<int>;

// Use the aliased type.

abstract class C {
  final T v12;

  C() : v12 = T();
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Couldn't find constructor 'T'.
}

class D1 extends T {}
//    ^
// [cfe] The superclass, 'FutureOr', has no unnamed constructor that takes no arguments.
//               ^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class D2 extends C with T {}
//             ^
// [cfe] Can't use 'FutureOr' as a mixin because it has constructors.
//                               ^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
// [cfe] The class 'FutureOr' can't be used as a mixin because it isn't a mixin class nor a mixin.
// [cfe] The type 'T' which is an alias of 'FutureOr<int>' can't be used as supertype.

abstract class D3 implements T {}
//             ^
// [cfe] The type 'FutureOr' can't be used in an 'implements' clause.
//                           ^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class D4 = C with T;
//             ^
// [cfe] Can't use 'FutureOr' as a mixin because it has constructors.
//                         ^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
// [cfe] The class 'FutureOr' can't be used as a mixin because it isn't a mixin class nor a mixin.
// [cfe] The type 'T' which is an alias of 'FutureOr<int>' can't be used as supertype.

X foo<X>(X x) => x;

main() {
  var v14 = <Set<T>, Set<T>>{{}: {}};
  v14[{}] = {T()};
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Couldn't find constructor 'T'.

  T();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Couldn't find constructor 'T'.

  T.named();
  //^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Member not found: 'FutureOr.named'.

  T v17 = foo<T>(T());
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Couldn't find constructor 'T'.

  T.staticMethod<T>();
  //^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] A constructor invocation can't have type arguments after the constructor name.
  // [cfe] Member not found: 'FutureOr.staticMethod'.
}
