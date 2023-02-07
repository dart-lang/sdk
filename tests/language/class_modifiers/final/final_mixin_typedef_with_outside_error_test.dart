// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to mix in a typedef final mixin outside of library.

import 'final_mixin_typedef_with_lib.dart';

abstract final class AOutside with FinalMixinTypeDef {}
//                                 ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'FinalMixin' can't be mixed-in outside of its library because it's a final mixin.

final class BOutside with FinalMixinTypeDef {}
//                        ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'FinalMixin' can't be mixed-in outside of its library because it's a final mixin.
