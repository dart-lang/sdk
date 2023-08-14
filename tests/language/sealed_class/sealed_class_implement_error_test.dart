// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when attempting to implement a sealed class outside of its library.

import "sealed_class_implement_lib.dart";

abstract class OutsideA implements SealedClass {}
//                                 ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.

class OutsideB implements SealedClass {
//                        ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
  int nonAbstractFoo = 2;
  int foo = 2;
  int nonAbstractBar(int value) => value;
  int bar(int value) => value;
}

mixin OutsideMixin implements SealedClass {}
//                            ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.

enum EnumOutside implements ClassForEnum { x }
//                          ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'ClassForEnum' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
