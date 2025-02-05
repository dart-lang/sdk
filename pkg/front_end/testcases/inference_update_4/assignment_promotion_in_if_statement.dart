// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the promotion of assignment expressions in if statements as described
// by https://github.com/dart-lang/language/issues/3658

int? nullableInt() => 1;

notEqualNull_assignIfNull() {
  int? x = null;
  if ((x ??= nullableInt()) != null) {
    x.isEven; // x promoted to int
  }
}

notEqualNullNull_eq() {
  int? x = null;
  if ((x = nullableInt()) != null) {
    x.isEven; // x promoted to int
  }
}

is_eq() {
  int? x = null;
  if ((x = nullableInt()) is int) {
    x.isEven; // x promoted to int
  }
}

is_plusEq() {
  num x = 2;
  if ((x += 1) is int) {
    x.isEven; // x promoted to int
  }
}

is_postfix() {
  num x = 2;
  if ((x++) is int) {
    // No promotion because the value being is checked is the value of `x`
    // before the increment, and that value isn't relevant after the increment
    // occurs.
    x.isEven; // Error.
  }
}

is_prefix() {
  num x = 2;
  if ((++x) is int) {
    x.isEven; // x promoted to int
  }
}
