// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when trying to implement a typedef base class outside of
// the base class' library when the typedef is also outside the base class
// library.

import 'base_class_typedef_used_outside_lib.dart';

typedef ATypeDef = BaseClass;

base class B implements ATypeDef {
//                      ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.
  int foo = 1;
}
