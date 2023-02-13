// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to mix in a typedef interface mixin outside of library.

import 'interface_mixin_typedef_with_lib.dart';

abstract class AOutside with InterfaceMixinTypeDef {}
//                           ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'InterfaceMixin' can't be mixed-in outside of its library because it's an interface mixin.

class BOutside with InterfaceMixinTypeDef {}
//                  ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'InterfaceMixin' can't be mixed-in outside of its library because it's an interface mixin.
