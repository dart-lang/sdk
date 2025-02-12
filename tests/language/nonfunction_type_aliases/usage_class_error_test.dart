// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Introduce an aliased type.

class A {
  A();
}

typedef T = A;

// Use the aliased type.

abstract class C {}

abstract class D2 extends C with T {}
//             ^
// [cfe] Can't use 'A' as a mixin because it has constructors.
//                               ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] The class 'A' can't be used as a mixin because it isn't a mixin class nor a mixin.

abstract class D4 = C with T;
//             ^
// [cfe] Can't use 'A' as a mixin because it has constructors.
//                         ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] The class 'A' can't be used as a mixin because it isn't a mixin class nor a mixin.

main() {
  T();
}
