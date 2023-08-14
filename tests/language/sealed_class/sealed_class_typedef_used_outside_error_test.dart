// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when trying to extend or implement a typedef sealed class outside of
// the sealed class' library when the typedef is also outside the sealed class
// library.

import 'sealed_class_typedef_used_outside_lib.dart';

typedef ATypeDef = SealedClass;

class A extends ATypeDef {}
//              ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.

class B implements ATypeDef {
//                 ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
  int foo = 1;
}
