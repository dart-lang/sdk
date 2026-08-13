// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Introduce an aliased type.

typedef T<X> = Function;

// Use the aliased type.

abstract class C {
  final T<Null> v7;

  C() : v7 = T();
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'Function' is abstract and can't be instantiated.
}

class D1<X> extends T<X> {}
//                  ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Function' can't be extended outside of its library because it's a final class.

abstract class D2 extends C with T<int> {}
//             ^
// [cfe] The type 'D2' must be 'base', 'final' or 'sealed' because the supertype 'Function' is 'final'.
//                               ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Function' can't be used as a mixin because it isn't a mixin class nor a mixin.

abstract class D3<X, Y> implements T<T> {}
//                                 ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Function' can't be implemented outside of its library because it's a final class.

abstract class D4 = C with T<void>;
//                         ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Function' can't be used as a mixin because it isn't a mixin class nor a mixin.

X foo<X>(X x) => x;

main() {
  var v9 = <Set<T<T>>, Set<T<T>>>{{}: {}};
  v9[{}] = {T<T>()};
  //        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'Function' is abstract and can't be instantiated.

  T<Null>();
  // [error column 3, length 7]
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'Function' is abstract and can't be instantiated.

  T<Null>.named();
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR
  // [cfe] Couldn't find constructor 'T.named'.

  T<Object> v12 = foo<T<bool>>(T<bool>());
  //                           ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'Function' is abstract and can't be instantiated.

  T<List<List<List<List>>>>.staticMethod<T<int>>();
  //                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] A constructor invocation can't have type arguments after the constructor name.
  // [cfe] Member not found: 'Function.staticMethod'.
}
