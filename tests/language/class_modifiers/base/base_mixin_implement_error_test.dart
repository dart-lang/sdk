// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when attempting to implement base mixin outside of library.

import 'base_mixin_implement_lib.dart';

abstract base class AOutside implements BaseMixin {}
//                                      ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base class BOutside implements BaseMixin {
//                             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.
  int foo = 1;
}

enum EnumOutside implements MixinForEnum { x }
//                          ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'MixinForEnum' can't be implemented outside of its library because it's a base mixin.
