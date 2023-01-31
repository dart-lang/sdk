// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class,class-modifiers

// Error when attempting to mix in a sealed class outside of library.

import 'sealed_class_as_mixin_lib.dart';

abstract class OutsideA with SealedClass {}
//             ^
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY

class OutsideB with SealedClass {
//    ^
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
  @override
  int foo = 2;

  @override
  int bar(int value) => value;
}

abstract class OutsideC = Object with SealedClass;
//             ^
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                                    ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY

abstract class OutsideD with SealedClass, Class {}
//             ^
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
//                                        ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN

class OutsideE with Class, SealedMixin {}
//    ^
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.
// [cfe] The mixin 'SealedMixin' can't be mixed in outside of its library because it's a sealed mixin.
//                  ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
//                         ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY

abstract class OutsideF with Mixin, SealedClass {}
//             ^
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                                  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
