// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error mixing in a regular class outside its library.

import 'mixin_class_no_modifier_lib.dart';

abstract class OutsideA with Class {}
//             ^
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN

class OutsideB with Class {}
//    ^
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                  ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN

class OutsideC = Object with Class;
//    ^
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN

abstract class OutsideD with Class, Mixin {}
//             ^
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN

class OutsideE with Class, Mixin {}
//    ^
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                  ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN

class OutsideF with NamedMixinClassApplication {}
//    ^
// [cfe] The class 'NamedMixinClassApplication' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN

class OutsideG with AbstractClass {}
//    ^
// [cfe] The class 'AbstractClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
