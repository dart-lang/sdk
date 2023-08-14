// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that all the expression types permitted by the grammar are allowed
// inside a relational pattern.

import 'package:expect/expect.dart';

void usingEquals() {
  // bitwiseOrExpression
  Expect.isTrue(switch(7) { == 5 | 6 => true, _ => false });

  // bitwiseXorExpression
  Expect.isTrue(switch(3) { == 5 ^ 6 => true, _ => false });

  // bitwiseAndExpression
  Expect.isTrue(switch(4) { == 5 & 6 => true, _ => false });

  // shiftExpression
  Expect.isTrue(switch(4) { == 1 << 2 => true, _ => false });
  Expect.isTrue(switch(1) { == 4 >> 2 => true, _ => false });

  // additiveExpression
  Expect.isTrue(switch(4) { == 3 + 1 => true, _ => false });
  Expect.isTrue(switch(2) { == 3 - 1 => true, _ => false });

  // multiplicativeExpression
  Expect.isTrue(switch(10) { == 5 * 2 => true, _ => false });
  Expect.isTrue(switch(2.5) { == 5 / 2 => true, _ => false });
  Expect.isTrue(switch(1) { == 5 % 2 => true, _ => false });
  Expect.isTrue(switch(2) { == 5 ~/ 2 => true, _ => false });

  // unaryExpression
  Expect.isTrue(switch(-3) { == -3 => true, _ => false });
  Expect.isTrue(switch(true) { == !false => true, _ => false });
  Expect.isTrue(switch(~3) { == ~3 => true, _ => false });

  // assignableExpression
  Expect.isTrue(switch(3) { == 'foo'.length => true, _ => false });

  // primary
  Expect.isTrue(switch('xyz') { == 'xyz' => true, _ => false });
}

void usingNotEquals() {
  // bitwiseOrExpression
  Expect.isFalse(switch(7) { != 5 | 6 => true, _ => false });

  // bitwiseXorExpression
  Expect.isFalse(switch(3) { != 5 ^ 6 => true, _ => false });

  // bitwiseAndExpression
  Expect.isFalse(switch(4) { != 5 & 6 => true, _ => false });

  // shiftExpression
  Expect.isFalse(switch(4) { != 1 << 2 => true, _ => false });
  Expect.isFalse(switch(1) { != 4 >> 2 => true, _ => false });

  // additiveExpression
  Expect.isFalse(switch(4) { != 3 + 1 => true, _ => false });
  Expect.isFalse(switch(2) { != 3 - 1 => true, _ => false });

  // multiplicativeExpression
  Expect.isFalse(switch(10) { != 5 * 2 => true, _ => false });
  Expect.isFalse(switch(2.5) { != 5 / 2 => true, _ => false });
  Expect.isFalse(switch(1) { != 5 % 2 => true, _ => false });
  Expect.isFalse(switch(2) { != 5 ~/ 2 => true, _ => false });

  // unaryExpression
  Expect.isFalse(switch(-3) { != -3 => true, _ => false });
  Expect.isFalse(switch(true) { != !false => true, _ => false });
  Expect.isFalse(switch(~3) { != ~3 => true, _ => false });

  // assignableExpression
  Expect.isFalse(switch(3) { != 'foo'.length => true, _ => false });

  // primary
  Expect.isFalse(switch('xyz') { != 'xyz' => true, _ => false });
}

void usingLessThanOrEquals() {
  // bitwiseOrExpression
  Expect.isTrue(switch(7) { <= 5 | 6 => true, _ => false });

  // bitwiseXorExpression
  Expect.isTrue(switch(3) { <= 5 ^ 6 => true, _ => false });

  // bitwiseAndExpression
  Expect.isTrue(switch(4) { <= 5 & 6 => true, _ => false });

  // shiftExpression
  Expect.isTrue(switch(4) { <= 1 << 2 => true, _ => false });
  Expect.isTrue(switch(1) { <= 4 >> 2 => true, _ => false });

  // additiveExpression
  Expect.isTrue(switch(4) { <= 3 + 1 => true, _ => false });
  Expect.isTrue(switch(2) { <= 3 - 1 => true, _ => false });

  // multiplicativeExpression
  Expect.isTrue(switch(10) { <= 5 * 2 => true, _ => false });
  Expect.isTrue(switch(2.5) { <= 5 / 2 => true, _ => false });
  Expect.isTrue(switch(1) { <= 5 % 2 => true, _ => false });
  Expect.isTrue(switch(2) { <= 5 ~/ 2 => true, _ => false });

  // unaryExpression
  Expect.isTrue(switch(-3) { <= -3 => true, _ => false });
  Expect.isTrue(switch(~3) { <= ~3 => true, _ => false });

  // assignableExpression
  Expect.isTrue(switch(3) { <= 'foo'.length => true, _ => false });

  // primary
  Expect.isTrue(switch(3) { <= 3 => true, _ => false });
}

void usingLessThan() {
  // bitwiseOrExpression
  Expect.isFalse(switch(7) { < 5 | 6 => true, _ => false });

  // bitwiseXorExpression
  Expect.isFalse(switch(3) { < 5 ^ 6 => true, _ => false });

  // bitwiseAndExpression
  Expect.isFalse(switch(4) { < 5 & 6 => true, _ => false });

  // shiftExpression
  Expect.isFalse(switch(4) { < 1 << 2 => true, _ => false });
  Expect.isFalse(switch(1) { < 4 >> 2 => true, _ => false });

  // additiveExpression
  Expect.isFalse(switch(4) { < 3 + 1 => true, _ => false });
  Expect.isFalse(switch(2) { < 3 - 1 => true, _ => false });

  // multiplicativeExpression
  Expect.isFalse(switch(10) { < 5 * 2 => true, _ => false });
  Expect.isFalse(switch(2.5) { < 5 / 2 => true, _ => false });
  Expect.isFalse(switch(1) { < 5 % 2 => true, _ => false });
  Expect.isFalse(switch(2) { < 5 ~/ 2 => true, _ => false });

  // unaryExpression
  Expect.isFalse(switch(-3) { < -3 => true, _ => false });
  Expect.isFalse(switch(~3) { < ~3 => true, _ => false });

  // assignableExpression
  Expect.isFalse(switch(3) { < 'foo'.length => true, _ => false });

  // primary
  Expect.isFalse(switch(3) { < 3 => true, _ => false });
}

void usingGreaterThanOrEquals() {
  // bitwiseOrExpression
  Expect.isTrue(switch(7) { >= 5 | 6 => true, _ => false });

  // bitwiseXorExpression
  Expect.isTrue(switch(3) { >= 5 ^ 6 => true, _ => false });

  // bitwiseAndExpression
  Expect.isTrue(switch(4) { >= 5 & 6 => true, _ => false });

  // shiftExpression
  Expect.isTrue(switch(4) { >= 1 << 2 => true, _ => false });
  Expect.isTrue(switch(1) { >= 4 >> 2 => true, _ => false });

  // additiveExpression
  Expect.isTrue(switch(4) { >= 3 + 1 => true, _ => false });
  Expect.isTrue(switch(2) { >= 3 - 1 => true, _ => false });

  // multiplicativeExpression
  Expect.isTrue(switch(10) { >= 5 * 2 => true, _ => false });
  Expect.isTrue(switch(2.5) { >= 5 / 2 => true, _ => false });
  Expect.isTrue(switch(1) { >= 5 % 2 => true, _ => false });
  Expect.isTrue(switch(2) { >= 5 ~/ 2 => true, _ => false });

  // unaryExpression
  Expect.isTrue(switch(-3) { >= -3 => true, _ => false });
  Expect.isTrue(switch(~3) { >= ~3 => true, _ => false });

  // assignableExpression
  Expect.isTrue(switch(3) { >= 'foo'.length => true, _ => false });

  // primary
  Expect.isTrue(switch(3) { >= 3 => true, _ => false });
}

void usingGreaterThan() {
  // bitwiseOrExpression
  Expect.isFalse(switch(7) { > 5 | 6 => true, _ => false });

  // bitwiseXorExpression
  Expect.isFalse(switch(3) { > 5 ^ 6 => true, _ => false });

  // bitwiseAndExpression
  Expect.isFalse(switch(4) { > 5 & 6 => true, _ => false });

  // shiftExpression
  Expect.isFalse(switch(4) { > 1 << 2 => true, _ => false });
  Expect.isFalse(switch(1) { > 4 >> 2 => true, _ => false });

  // additiveExpression
  Expect.isFalse(switch(4) { > 3 + 1 => true, _ => false });
  Expect.isFalse(switch(2) { > 3 - 1 => true, _ => false });

  // multiplicativeExpression
  Expect.isFalse(switch(10) { > 5 * 2 => true, _ => false });
  Expect.isFalse(switch(2.5) { > 5 / 2 => true, _ => false });
  Expect.isFalse(switch(1) { > 5 % 2 => true, _ => false });
  Expect.isFalse(switch(2) { > 5 ~/ 2 => true, _ => false });

  // unaryExpression
  Expect.isFalse(switch(-3) { > -3 => true, _ => false });
  Expect.isFalse(switch(~3) { > ~3 => true, _ => false });

  // assignableExpression
  Expect.isFalse(switch(3) { > 'foo'.length => true, _ => false });

  // primary
  Expect.isFalse(switch(3) { > 3 => true, _ => false });
}

main() {
  usingEquals();
  usingNotEquals();
  usingLessThanOrEquals();
  usingLessThan();
  usingGreaterThanOrEquals();
  usingGreaterThan();
}
