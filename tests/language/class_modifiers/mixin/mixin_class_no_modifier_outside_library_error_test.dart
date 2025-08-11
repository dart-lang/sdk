// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error mixing in a regular class outside its library.

import 'mixin_class_no_modifier_lib.dart';

abstract class OutsideA with Class {}
//                           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

class OutsideB with Class {}
//                  ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

class OutsideC = Object with Class;
//                           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

abstract class OutsideD with Class, Mixin {}
//                           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

class OutsideE with Class, Mixin {}
//                  ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

class OutsideF with NamedMixinClassApplication {}
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'NamedMixinClassApplication' can't be used as a mixin because it isn't a mixin class nor a mixin.

class OutsideG with AbstractClass {}
//                  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'AbstractClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
