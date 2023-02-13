// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to implement final mixin outside of library.

import 'final_mixin_implement_lib.dart';

abstract final class AOutside implements FinalMixin {}
//                                       ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'FinalMixin' can't be implemented outside of its library because it's a final mixin.

final class BOutside implements FinalMixin {
//                              ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'FinalMixin' can't be implemented outside of its library because it's a final mixin.
  int foo = 1;
}

enum EnumOutside implements MixinForEnum { x }
//                          ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'MixinForEnum' can't be implemented outside of its library because it's a final mixin.
