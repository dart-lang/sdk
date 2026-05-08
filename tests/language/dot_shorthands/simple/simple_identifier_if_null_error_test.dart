// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors with `??` and dot shorthands with static properties or enums.

import '../dot_shorthand_helper.dart';

void test() {
  // Warning when LHS is not able to be `null`.
  Color colorLocal = .blue ?? Color.red;
  // ^
  // [analyzer] unspecified

  Integer integerLocal = .one ?? Integer.two;
  // ^
  // [analyzer] unspecified

  IntegerMixin integerMixinLocal = .mixinOne ?? IntegerMixin.mixinTwo;
  // ^
  // [analyzer] unspecified
}
