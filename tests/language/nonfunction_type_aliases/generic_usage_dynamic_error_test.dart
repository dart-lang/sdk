// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Introduce an aliased type.

typedef T<X> = dynamic;

// Use the aliased type.

abstract class C {
  final T<Null> v7;

  C() : v7 = T();
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Couldn't find constructor 'T'.
}

class D1<X> extends T<X> {}
//                  ^
// [analyzer] COMPILE_TIME_ERROR.EXTENDS_NON_CLASS
// [cfe] The type 'T<X>' which is an alias of 'dynamic' can't be used as supertype because it is nullable.

abstract class D2 extends C with T<int> {}
//             ^
// [cfe] The type 'T<int>' can't be mixed in.
//                               ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
// [cfe] The type 'T<int>' which is an alias of 'dynamic' can't be used as supertype because it is nullable.

abstract class D3<X, Y> implements T<T> {}
//                                 ^
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
// [cfe] The type 'T<T>' which is an alias of 'dynamic' can't be used as supertype because it is nullable.

abstract class D4 = C with T<void>;
//             ^
// [cfe] The type 'T<void>' can't be mixed in.
//                         ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
// [cfe] The type 'T<void>' which is an alias of 'dynamic' can't be used as supertype because it is nullable.

X foo<X>(X x) => x;

main() {
  var v9 = <Set<T<T>>, Set<T<T>>>{{}: {}};
  v9[{}] = {T<T>()};
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Couldn't find constructor 'T'.

  T<Null>();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Couldn't find constructor 'T'.

  T<Null>.named();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  //      ^
  // [cfe] Couldn't find constructor 'T.named'.

  T<Object> v12 = foo<T<bool>>(T<bool>());
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Couldn't find constructor 'T'.

  T<List<List<List<List>>>>.staticMethod<T<int>>();
  //                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'staticMethod' isn't defined for the type 'Type'.
}
