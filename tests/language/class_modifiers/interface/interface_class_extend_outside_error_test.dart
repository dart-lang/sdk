// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when attempting to extend an interface class outside of library.

import 'interface_class_extend_lib.dart';

abstract class AOutside extends InterfaceClass {}
//                              ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

class BOutside extends InterfaceClass {
//                     ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.
}
