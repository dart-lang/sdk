// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Introduce an aliased type.

class A<X> {
  A();
  A.named();
  static void staticMethod<Y>() {}
}

typedef T<X> = A<X>;

// Use the aliased type.

abstract class C {}

abstract class D2 extends C with T<int> {}
//             ^
// [cfe] Can't use 'A' as a mixin because it has constructors.
//                               ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] The class 'A' can't be used as a mixin because it isn't a mixin class nor a mixin.

abstract class D4 = C with T<void>;
//             ^
// [cfe] Can't use 'A' as a mixin because it has constructors.
//                         ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] The class 'A' can't be used as a mixin because it isn't a mixin class nor a mixin.

main() {
  T<List<List<List<List>>>>.staticMethod<T<int>>();
  //                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Cannot access static member on an instantiated generic class.
}
