// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Introduce an aliased type.

class A {
  A();
  A.named();
  static void staticMethod<X>() {}
}

typedef T<X extends A> = X;

// Use the aliased type.

class C {
  final T v12;

  C() : v12 = T();
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.
}

class D1 extends T {}
//               ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.

abstract class D2 extends C with T {}
//             ^
// [cfe] The type 'T' can't be mixed in.
//                               ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.

abstract class D3 implements T {}
//                           ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.

abstract class D4 = C with T;
//             ^
// [cfe] The type 'T' can't be mixed in.
//                         ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.

X foo<X>(X x) => x;

main() {
  var v14 = <Set<T>, Set<T>>{{}: {}};
  v14[{}] = {T()};
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.

  T();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.

  T v17 = foo<T>(T());
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.

  T.named();
  // [error column 3]
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  //^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'named' isn't defined for the type 'Type'.

  T().unknownInstanceMethod();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.

  T.staticMethod<T>();
  // [error column 3]
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  //^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'staticMethod' isn't defined for the type 'Type'.

  T.unknownStaticMethod();
  // [error column 3]
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  //^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'unknownStaticMethod' isn't defined for the type 'Type'.
}
