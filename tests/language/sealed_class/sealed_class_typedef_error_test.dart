// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when attempting to extend or implement typedef sealed class
// outside of its library.

import 'sealed_class_typedef_lib.dart';

class ATypeDef extends SealedClassTypeDef {}
//    ^
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
//                     ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY

class BTypeDef implements SealedClassTypeDef {
//    ^
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
//                        ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
  @override
  int foo = 1;
}
