// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to mix in interface mixin outside of library.

import 'interface_mixin_with_lib.dart';

abstract class AOutside with InterfaceMixin {}
//                           ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'InterfaceMixin' can't be mixed-in outside of its library because it's an interface mixin.

class BOutside with InterfaceMixin {}
//                  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'InterfaceMixin' can't be mixed-in outside of its library because it's an interface mixin.

enum EnumOutside with MixinForEnum { x }
//                    ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'MixinForEnum' can't be mixed-in outside of its library because it's an interface mixin.
