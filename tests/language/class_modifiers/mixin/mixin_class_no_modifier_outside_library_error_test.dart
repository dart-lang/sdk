// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error mixing in a regular class outside its library.

import 'mixin_class_no_modifier_lib.dart';

abstract class OutsideA with Class {}
// [error column 1, length 37]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
//             ^
// [cfe] Class 'Class' can't be used as a mixin.

class OutsideB with Class {}
// [error column 1, length 28]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
//    ^
// [cfe] Class 'Class' can't be used as a mixin.

class OutsideC = Object with Class;
// [error column 1, length 35]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
//    ^
// [cfe] Class 'Class' can't be used as a mixin.

abstract class OutsideD with Class, Mixin {}
// [error column 1, length 44]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
//             ^
// [cfe] Class 'Class' can't be used as a mixin.

class OutsideE with Class, Mixin {}
// [error column 1, length 35]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
//    ^
// [cfe] Class 'Class' can't be used as a mixin.

class OutsideF with NamedMixinClassApplication {}
// [error column 1, length 49]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
//    ^
// [cfe] Class 'NamedMixinClassApplication' can't be used as a mixin.

class OutsideG with AbstractClass {}
// [error column 1, length 36]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
//    ^
// [cfe] Class 'AbstractClass' can't be used as a mixin.
