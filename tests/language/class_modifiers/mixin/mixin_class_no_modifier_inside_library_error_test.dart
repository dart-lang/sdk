// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when mixing in a regular class inside its library.

class Class {
  int foo = 0;
}

mixin Mixin {
  int foo = 0;
}

abstract class A with Class {}
//                    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

class B with Class {}
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

class C = Object with Class;
//                    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

abstract class D with Class, Mixin {}
//                    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

class E with Class, Mixin {}
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

class NamedMixinClassApplication = Object with Class;
//                                             ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.
