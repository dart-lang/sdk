// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Introduce an aliased type.

typedef T<X> = Object;

// Use the aliased type.

abstract class C {}

abstract class D2 extends C with T<int> {}
//             ^
// [cfe] Can't use 'Object' as a mixin because it has constructors.
//                               ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] The class 'Object' can't be used as a mixin because it isn't a mixin class nor a mixin.

abstract class D4 = C with T<void>;
//             ^
// [cfe] Can't use 'Object' as a mixin because it has constructors.
//                         ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] The class 'Object' can't be used as a mixin because it isn't a mixin class nor a mixin.

main() {
  T<Null>.named();
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR
  // [cfe] Couldn't find constructor 'T.named'.

  T<List<List<List<List>>>>.staticMethod<T<int>>();
  //                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] A constructor invocation can't have type arguments after the constructor name.
  // [cfe] Member not found: 'Object.staticMethod'.
}
