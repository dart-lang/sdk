// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors with `??` and enum shorthands with static properties or enums.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

void test() {
  // Warning when LHS is not able to be `null`.
  Color colorLocal = .blue ?? Color.red;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  Integer integerLocal = .one ?? Integer.two;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  IntegerMixin integerMixinLocal = .mixinOne ?? IntegerMixin.mixinTwo;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
