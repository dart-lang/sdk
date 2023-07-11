// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when attempting to extend an final class outside of library.

import 'final_class_extend_lib.dart';

abstract final class AOutside extends FinalClass {}
//                                    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

final class BOutside extends FinalClass {
//                           ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.
}
