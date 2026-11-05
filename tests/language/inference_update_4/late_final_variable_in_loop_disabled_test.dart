// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when `inference-update-4` is disabled:
// - A `late final` variable that is not definitely assigned before a loop is
//   considered potentially assigned inside the loop, so it may be read there
//   without a compile-time error.
// - Promotions of `late final` variables are not preserved in closures or in
//   loops that assign to them.
//
// See `late_final_variable_in_loop_test.dart` for the behavior when
// `inference-update-4` is enabled.

// @dart=3.6

import 'package:expect/expect.dart';

import '../static_type_helper.dart';

int readInLoop() {
  late final int x;
  var sum = 0;
  for (var i = 0; i < 3; i++) {
    // `x` is potentially assigned here (on the second and third iterations),
    // so reading it is not a compile-time error.
    if (i > 0) sum += x;
    if (i == 0) x = 10;
  }
  return sum;
}

void promotionNotPreservedInClosure(bool b) {
  late final int? x;
  x = b ? 1 : null;
  if (x != null) {
    () => x.expectStaticType<Exactly<int?>>();
  }
}

int? potentiallyAssignedPromotionNotPreservedInClosure(bool b) {
  late final int? x;
  if (b) x = 1;
  if (x != null) {
    return (() => x.expectStaticType<Exactly<int?>>()! + 1)();
  }
  return null;
}

void potentiallyAssignedPromotionNotPreservedInLoop(bool b) {
  late final int? x;
  if (b) x = 1;
  if (x != null) {
    for (var i = 0; i < 2; i++) {
      x.expectStaticType<Exactly<int?>>();
      if (i == 1) x = null;
    }
  }
}

main() {
  Expect.equals(20, readInLoop());
  promotionNotPreservedInClosure(true);
  promotionNotPreservedInClosure(false);
  Expect.equals(2, potentiallyAssignedPromotionNotPreservedInClosure(true));
  Expect.throws(() => potentiallyAssignedPromotionNotPreservedInClosure(false));
  Expect.throws(() => potentiallyAssignedPromotionNotPreservedInLoop(true));
  Expect.throws(() => potentiallyAssignedPromotionNotPreservedInLoop(false));
}
