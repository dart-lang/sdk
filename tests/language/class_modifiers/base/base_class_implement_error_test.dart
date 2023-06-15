// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when attempting to implement base class outside of library.

import 'base_class_implement_lib.dart';

abstract base class AOutside implements BaseClass {}
//                                      ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base class BOutside implements BaseClass {
//                             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.
  int foo = 1;
}

enum EnumOutside implements ClassForEnum { x }
//                          ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'ClassForEnum' can't be implemented outside of its library because it's a base class.
