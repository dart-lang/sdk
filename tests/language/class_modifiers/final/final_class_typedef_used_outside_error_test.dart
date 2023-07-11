// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when trying to implement or extend a typedef final class outside of
// the final class' library when the typedef is also outside the final class
// library.

import 'final_class_typedef_used_outside_lib.dart';

typedef ATypeDef = FinalClass;

final class A extends ATypeDef {}
//                    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

final class B implements ATypeDef {
//                       ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.
  int foo = 1;
}
