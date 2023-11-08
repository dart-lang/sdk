// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that when there is a control flow join implied by a pattern, the
// split point is the beginning of the top level pattern.

import '../../static_type_helper.dart';

void guarded(int Function(Object) f, int? i) {
  if (f(throw '') case int() when i == null) {
  } else {
    // There is a join point here, joining the flow control paths where (a) the
    // pattern `int()` failed to match and (b) the guard `i == null` was not
    // satisfied. Since the scrutinee has type `int`, and the pattern is
    // `int()`, the pattern is guaranteed to match, so path (a) is
    // unreachable. Path (b) is also unreachable due to the fact that the
    // scrutinee throws, but since the split point is the beginning of the
    // pattern, path (b) is reachable from the split point. So the promotion
    // implied by (b) is preserved after the join.
    i.expectStaticType<Exactly<int>>();
  }
}

void logicalOr((Null, Null, int?) x) {
  if (x
      case ((!= null, _, _)
              // At this point, control flow is unreachable due to the fact that
              // the `!= null` pattern in the first field of the record pattern
              // above can never match the type `Null`.
              &&
              ((_, != null, _)
                  // At this point, control flow is unreachable for a second
                  // reason: because the `!= null` pattern in the second field
                  // of the record pattern above can never match the type
                  // `Null`.
                  ||
                  (_, _, _?)
              // At this point, the third field of the scrutinee is promoted
              // from `int?` to `int`, due to the null check pattern.
              )
          // At this point, there is a control flow join between the two
          // branches of the logical-or pattern. Since the split point
          // corresponding to the control flow join is at the beginning of the
          // top level pattern, both branches are considered unreachable, so
          // neither is favored in the join, and therefore, the promotion from
          // the second branch is lost.
          ) &&
          // The record pattern below matches `x` to the unpromoted type of the
          // third field of the scrutinee, so we just have to verify that it has
          // the expected type of `int?`.
          (_, _, var y)) {
    y.expectStaticType<Exactly<int?>>();
  }
}

main() {}
