// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test of a common rounding bug.
///
/// This bug is common in JavaScript implementations because the ECMA-262
/// specification of JavaScript incorrectly claims:
///
///     The value of [:Math.round(x):] is the same as the value of
///     [:Math.floor(x+0.5):], except when x is 0 or is less than 0 but greater
///     than or equal to -0.5; for these cases [:Math.round(x):] returns 0, but
///     [:Math.floor(x+0.5):] returns +0.
///
/// However, 0.49999999999999994 + 0.5 is 1 and 9007199254740991 + 0.5 is
/// 9007199254740992, so you cannot implement Math.round in terms of
/// Math.floor.

import 'package:expect/expect.dart';

main() {
  Expect.equals(0, (0.49999999999999994).round());
  Expect.equals(0, (-0.49999999999999994).round());

  Expect.equals(9007199254740991, (9007199254740991.0).round());
  Expect.equals(-9007199254740991, (-9007199254740991.0).round());
}
