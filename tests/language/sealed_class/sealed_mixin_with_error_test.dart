// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when attempting to mix in a sealed mixin outside of its library.

import 'sealed_mixin_with_lib.dart';

abstract class OutsideA with SealedMixin {}
//                           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'SealedMixin' can't be mixed in outside of its library because it's a sealed mixin.

class OutsideB with SealedMixin {
//                  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'SealedMixin' can't be mixed in outside of its library because it's a sealed mixin.
  int foo = 2;
  int bar(int value) => value;
}

abstract class OutsideC = Object with SealedMixin;
//                                    ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'SealedMixin' can't be mixed in outside of its library because it's a sealed mixin.

enum EnumOutside with MixinForEnum { x }
//                    ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'MixinForEnum' can't be mixed in outside of its library because it's a sealed mixin.
