// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Introduce an aliased type.

typedef T<X> = X;

// Use the aliased type.

abstract class C {
  final T<Map> v7;

  C() : v7 = T<Map>();
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.
}

class D {}

mixin M {}

abstract class D1<X> extends T<D> {}
//                           ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.

abstract class D2 extends C with T<M> {}
//             ^
// [cfe] The type 'T<M>' can't be mixed in.
//                               ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.

abstract class D3<X, Y> implements T<T<D>> {}
//                                 ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.

abstract class D4 = C with T<D>;
//             ^
// [cfe] The type 'T<D>' can't be mixed in.
//                         ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.

class D5<X> extends T<X> {}
//                  ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
// [cfe] The type 'T<X>' which is an alias of 'X' can't be used as supertype.

abstract class D6 extends C with T<int> {}
//             ^
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
// [cfe] The type 'T<int>' can't be mixed in.
//                               ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
// [cfe] The class 'int' can't be used as a mixin because it extends a class other than 'Object'.

abstract class D7<X, Y> implements T<T> {}
//                                 ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
// [cfe] The type 'T<T>' which is an alias of 'dynamic' can't be used as supertype because it is nullable.

abstract class D8 = C with T<void>;
//             ^
// [cfe] The type 'T<void>' can't be mixed in.
//                         ^
// [analyzer] COMPILE_TIME_ERROR.SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER
// [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
// [cfe] The type 'T<void>' which is an alias of 'void' can't be used as supertype because it is nullable.

X foo<X>(X x) => x;

main() {
  var v9 = <Set<T<T>>, Set<T<T>>>{{}: {}};
  v9[{}] = {T<C>()};
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.

  T<Null>();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.

  T<Null>.named();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  //      ^
  // [cfe] Couldn't find constructor 'T.named'.

  T<Object> v12 = foo<T<bool>>(T<bool>());
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.

  T<List<List<List<List>>>>.staticMethod<T<int>>();
  // [error column 3]
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  //                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'staticMethod' isn't defined for the type 'Type'.

  T<Object>();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  // [cfe] Couldn't find constructor 'T'.

  T<C>.name1(C(), null);
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER
  // [cfe] Can't use a typedef denoting a type variable as a constructor, nor for a static member access.
  //   ^
  // [cfe] Couldn't find constructor 'T.name1'.
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'C' is abstract and can't be instantiated.
}
