// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Object has a non-trivial constructor and hence cannot be used as mixin.

class S {}

class C0 extends S
//    ^
// [cfe] Can't use 'Object' as a mixin because it has constructors.
with Object
//   ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
{}

class C1 = S with Object;
//    ^
// [cfe] Can't use 'Object' as a mixin because it has constructors.
//                ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR

main() {
  new C0();
  new C1();
}
