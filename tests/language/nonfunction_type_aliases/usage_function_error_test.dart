// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Introduce an aliased type.

typedef T = Function;

// Use the aliased type.

abstract class C {
  final T v12;

  C() : v12 = T();
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'Function' is abstract and can't be instantiated.
}

class D1<X> extends T {}
//                  ^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Function' can't be extended outside of its library because it's a final class.

abstract class D2 extends C with T {}
//             ^
// [cfe] The type 'D2' must be 'base', 'final' or 'sealed' because the supertype 'Function' is 'final'.
//                               ^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Function' can't be used as a mixin because it isn't a mixin class nor a mixin.

abstract class D3<X, Y> implements T {}
//                                 ^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Function' can't be implemented outside of its library because it's a final class.

abstract class D4 = C with T;
//                         ^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Function' can't be used as a mixin because it isn't a mixin class nor a mixin.

X foo<X>(X x) => x;

main() {
  var v14 = <Set<T>, Set<T>>{{}: {}};
  v14[{}] = {T()};
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'Function' is abstract and can't be instantiated.

  T();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'Function' is abstract and can't be instantiated.

  T.named();
  //^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Member not found: 'Function.named'.

  T v17 = foo<T>(T());
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  // [cfe] The class 'Function' is abstract and can't be instantiated.
}
