// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Introduce an aliased type.

typedef T<X> = FutureOr<X>;

// Use the aliased type.

abstract class C {
  final T<Null> v7;

  C() : v7 = T();
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  //         ^^^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_NOT_ASSIGNABLE
  // [cfe] Couldn't find constructor 'T'.
}

class D1<X> extends T<X> {}
//    ^
// [cfe] The superclass, 'FutureOr', has no unnamed constructor that takes no arguments.
//                  ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class D2 extends C with T<int> {}
//             ^
// [cfe] Can't use 'FutureOr' as a mixin because it has constructors.
//                               ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
// [cfe] The class 'FutureOr' can't be used as a mixin because it isn't a mixin class nor a mixin.
// [cfe] The type 'T<int>' which is an alias of 'FutureOr<int>' can't be used as supertype.

abstract class D3<X, Y> implements T<T> {}
//             ^
// [cfe] The type 'FutureOr' can't be used in an 'implements' clause.
//                                 ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

abstract class D4 = C with T<void>;
//             ^
// [cfe] Can't use 'FutureOr' as a mixin because it has constructors.
//                         ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
// [cfe] The class 'FutureOr' can't be used as a mixin because it isn't a mixin class nor a mixin.
// [cfe] The type 'T<void>' which is an alias of 'FutureOr<void>' can't be used as supertype because it is nullable.

X foo<X>(X x) => x;

main() {
  var v9 = <Set<T<T>>, Set<T<T>>>{{}: {}};
  v9[{}] = {T<T>()};
  //        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Couldn't find constructor 'T'.

  T<Null>();
  // [error column 3, length 7]
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Couldn't find constructor 'T'.

  T<Null>.named();
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR
  // [cfe] Couldn't find constructor 'T.named'.

  T<Object> v12 = foo<T<bool>>(T<bool>());
  //                           ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Couldn't find constructor 'T'.

  T<List<List<List<List>>>>.staticMethod<T<int>>();
  //                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] A constructor invocation can't have type arguments after the constructor name.
  // [cfe] Member not found: 'FutureOr.staticMethod'.
}
