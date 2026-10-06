// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when `inference-update-4` is enabled:
// - A `late final` variable that is not definitely assigned before a loop is
//   considered potentially assigned inside the loop, so it may be read there
//   without a compile-time error.
// - Promotions of `late final` variables are preserved in closures and loops,
//   even if the variable is only potentially assigned (because if the read
//   that caused the promotion succeeded, the variable has been assigned, and
//   it can never be assigned again).
//
// This is a regression test for a bug in which such variables were treated as
// definitely unassigned inside the loop.

// SharedOptions=--enable-experiment=inference-update-4

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

void promotionPreservedInClosure(bool b) {
  late final int? x;
  x = b ? 1 : null;
  if (x != null) {
    // `x` is definitely assigned and final, so the promotion is preserved.
    () => x.expectStaticType<Exactly<int>>();
  }
}

int? potentiallyAssignedPromotionPreservedInClosure(bool b) {
  late final int? x;
  if (b) x = 1;
  if (x != null) {
    // `x` is only potentially assigned, but since the read of `x` succeeded,
    // it has been assigned, so the promotion is preserved.
    return (() => x.expectStaticType<Exactly<int>>() + 1)();
  }
  return null;
}

void potentiallyAssignedPromotionPreservedInLoop(bool b) {
  late final int? x;
  if (b) x = 1;
  if (x != null) {
    for (var i = 0; i < 2; i++) {
      // `x` is only potentially assigned, but since the read of `x`
      // succeeded, it has been assigned, so the promotion is preserved (and
      // the assignment below will throw).
      x.expectStaticType<Exactly<int>>();
      if (i == 1) x = null;
    }
  }
}

main() {
  Expect.equals(20, readInLoop());
  promotionPreservedInClosure(true);
  promotionPreservedInClosure(false);
  Expect.equals(2, potentiallyAssignedPromotionPreservedInClosure(true));
  Expect.throws(() => potentiallyAssignedPromotionPreservedInClosure(false));
  Expect.throws(() => potentiallyAssignedPromotionPreservedInLoop(true));
  Expect.throws(() => potentiallyAssignedPromotionPreservedInLoop(false));
}
