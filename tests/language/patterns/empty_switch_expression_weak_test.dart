// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

/// Test that switch expressions are allowed to be empty, and that they have the
/// proper static type and runtime behavior.
///
/// Note that the runtime behavior only matters in mixed-mode programs, since in
/// fully sound programs an empty switch expression will be unreachable.

import "package:expect/expect.dart";

import '../static_type_helper.dart';

import 'empty_switch_expression_lib.dart';

// Note: no subtypes.
sealed class A {}

Never emptySwitchOnSealedClass(A a) =>
    (switch (a) {  })..expectStaticType<Never>();

void unreachableAfterEmptySwitch(A a, int? i) {
  if (i == null) {
    (switch (a) {  });
    // Flow analysis should understand that since `switch (a) {}` has type
    // `Never`, the rest of this block is unreachable.
  }
  // Hence, `i` is promoted to non-nullable.
  i.isEven;
}

main() {
  Expect.throwsReachabilityError(() => emptySwitchOnSealedClass(nullOfTypeA()));
  unreachableAfterEmptySwitch(nullOfTypeA(), 0);
}
