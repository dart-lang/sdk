// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that there are no crashes when enum shorthands are used in places
// with no context type, or it's not allowed.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

void main() async {
  // Enum shorthands in postfix and prefix expressions.
  .red++;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red--;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  ++.red;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  --.red;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  -.red;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  ~.red;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  !.red;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Await.
  await .red;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Parenthesis.
  (.red);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Map operators.
  var map = <Color, Color> {.red: .red, .blue: .blue, .green: .green};
  map[.red];
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  map[.blue] = Color.red;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Null assert.
  .one!;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Assignment operators.
  .red = 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red *= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red /= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red ~/= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red %= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red += 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red -= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red <<= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red >>>= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red >>= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red &= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red ^= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red |= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  .red ??= 1;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
