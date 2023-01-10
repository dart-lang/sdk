// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class,class-modifiers

// Error when attempting to mix in a sealed class outside of library.

import 'sealed_class_as_mixin_lib.dart';

abstract class OutsideA with SealedClass {}
// [error column 1, length 43]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY
//             ^
// [cfe] Class 'SealedClass' can't be used as a mixin.
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.

class OutsideB with SealedClass {
// [error column 1, length 431]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY
//    ^
// [cfe] Class 'SealedClass' can't be used as a mixin.
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.
  @override
  int foo = 2;

  @override
  int bar(int value) => value;
}

abstract class OutsideC = Object with SealedClass;
// [error column 1, length 50]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY
//             ^
// [cfe] Class 'SealedClass' can't be used as a mixin.
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.

abstract class OutsideD with SealedClass, Class {}
// [error column 1, length 50]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY
//             ^
// [cfe] Class 'Class' can't be used as a mixin.
// [cfe] Class 'SealedClass' can't be used as a mixin.
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.

class OutsideE with Class, SealedMixin {}
// [error column 1, length 41]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY
//    ^
// [cfe] Class 'Class' can't be used as a mixin.
// [cfe] Sealed mixin 'SealedMixin' can't be mixed in outside of its library.

abstract class OutsideF with Mixin, SealedClass {}
// [error column 1, length 50]
// [analyzer] COMPILE_TIME_ERROR.CLASS_USED_AS_MIXIN
// [analyzer] COMPILE_TIME_ERROR.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY
//             ^
// [cfe] Class 'SealedClass' can't be used as a mixin.
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.
