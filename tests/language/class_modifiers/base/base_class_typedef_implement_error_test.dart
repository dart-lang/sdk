// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when attempting to implement typedef base class outside of its library.

import 'base_class_typedef_lib.dart';

base class BTypeDef implements BaseClassTypeDef {
//                             ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.
  int foo = 1;
}

// Testing another layer of typedefs outside of the library.
typedef BaseClassTypeDef2 = BaseClassTypeDef;

base class BTypeDef2 implements BaseClassTypeDef2 {
//                              ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.
  int foo = 1;
}
