// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Introduce an aliased type.

typedef T = dynamic;

// Use the aliased type.

abstract class C {
  final T v12;

  C() : v12 = T();
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Couldn't find constructor 'T'.
}

class D1 extends T {}
//               ^
// [analyzer] COMPILE_TIME_ERROR.EXTENDS_NON_CLASS
// [cfe] The type 'T' which is an alias of 'dynamic' can't be used as supertype because it is nullable.

abstract class D2 extends C with T {}
//             ^
// [cfe] The type 'T' can't be mixed in.
//                               ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
// [cfe] The type 'T' which is an alias of 'dynamic' can't be used as supertype because it is nullable.

abstract class D3 implements T {}
//                           ^
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
// [cfe] The type 'T' which is an alias of 'dynamic' can't be used as supertype because it is nullable.

abstract class D4 = C with T;
//             ^
// [cfe] The type 'T' can't be mixed in.
//                         ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
// [cfe] The type 'T' which is an alias of 'dynamic' can't be used as supertype because it is nullable.

X foo<X>(X x) => x;

main() {
  var v14 = <Set<T>, Set<T>>{{}: {}};
  v14[{}] = {T()};
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Couldn't find constructor 'T'.

  T();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Couldn't find constructor 'T'.

  T.named();
  //^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'named' isn't defined for the type 'Type'.

  T v17 = foo<T>(T());
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Couldn't find constructor 'T'.

  T.staticMethod<T>();
  //^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'staticMethod' isn't defined for the type 'Type'.
}
