// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class,class-modifiers

// Error when attempting to mix in a sealed class outside of library.

import 'sealed_class_as_mixin_lib.dart';

abstract class OutsideA with SealedClass {}
//                           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.

class OutsideB with SealedClass {
//                  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
  int foo = 2;
  int bar(int value) => value;
}

abstract class OutsideC = Object with SealedClass;
//                                    ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.

abstract class OutsideD with SealedClass, Class {}
//                           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                                        ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.

class OutsideE with Class, SealedMixin {}
//                  ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [cfe] The class 'Class' can't be used as a mixin because it isn't a mixin class nor a mixin.
//                         ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'SealedMixin' can't be mixed in outside of its library because it's a sealed mixin.

abstract class OutsideF with Mixin, SealedClass {}
//                                  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
// [cfe] The class 'SealedClass' can't be used as a mixin because it isn't a mixin class nor a mixin.
