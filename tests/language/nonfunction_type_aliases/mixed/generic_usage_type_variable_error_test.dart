// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9
// Requirements=nnbd-weak


// Test that a generic type alias `T<X>` denoting `X`
// can give rise to the expected errors.

import 'dart:async';
import 'generic_usage_type_variable_error_lib.dart';

// Use the aliased type.

abstract class C {
  final T<Map> v7;

  C(): v7 = T<Map>();
  //        ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class D {}
mixin M {}

abstract class D1<X> extends T<D> {}
//                           ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D2 extends C with T<M> {}
//                               ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D3<X, Y> implements T<T<D>> {}
//                                 ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D4 = C with T<D>;
//                         ^
// [analyzer] unspecified
// [cfe] unspecified

class D5<X> extends T<X> {}
//                  ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D6 extends C with T<int> {}
//                               ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D7<X, Y> implements T<T> {}
//                                 ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D8 = C with T<void>;
//                         ^
// [analyzer] unspecified
// [cfe] unspecified

X foo<X>(X x) => x;

main() {
  var v9 = <Set<T<T>>, Set<T<T>>>{{}: {}};
  v9[{}] = {T<C>()};
  //        ^
  // [analyzer] unspecified
  // [cfe] unspecified

  T<Null>();
//^
// [analyzer] unspecified
// [cfe] unspecified

  T<Null>.named();
  //      ^
  // [analyzer] unspecified
  // [cfe] unspecified

  T<Object> v12 = foo<T<bool>>(T<bool>());
  //                           ^
  // [analyzer] unspecified
  // [cfe] unspecified

  T<List<List<List<List>>>>.staticMethod<T<int>>();
  //                        ^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  T<Object>();
//^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified

  T<C>.name1(C(), null);
//^^^^^^^^^^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] unspecified
}
