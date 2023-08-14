// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when trying to extend a typedef interface class outside of
// the interface class' library when the typedef is also outside the interface
// class library.

import 'interface_class_typedef_used_outside_lib.dart';

typedef ATypeDef = InterfaceClass;

class A extends ATypeDef {}
//              ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.
