// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to implement base mixin outside of library.

import 'base_mixin_implement_lib.dart';

abstract class AOutside implements BaseMixin {}
//             ^
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.
// [analyzer] unspecified

class BOutside implements BaseMixin {
//    ^
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.
// [analyzer] unspecified
  @override
  int foo = 1;
}
