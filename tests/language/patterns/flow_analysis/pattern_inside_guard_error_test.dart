// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";
import "dart:async";

test() {
  {
    // This test verifies that when a pattern match occurs inside a guard, flow
    // analysis doesn't mix up the "unmatched" states between the inner and
    // outer pattern matches.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<FutureOr<int>>();
    var y = expr<FutureOr<String>>();
    if (expr<bool>()) {
      if (x case int _
          when pickSecond(() {
            if (y case String _) {
              x.expectStaticType<Exactly<int>>();
              y.expectStaticType<Exactly<String>>();
            } else {
              x.expectStaticType<Exactly<int>>();
              // Note that even though flow analysis doesn't run the
              // exhaustiveness checker, it understands that `y` has type
              // `Future<String>` here, because this is understood by the
              // "factor" algorithm (see
              // https://github.com/dart-lang/language/blob/main/resources/type-system/flow-analysis.md#promotion)
              y.expectStaticType<Exactly<Future<String>>>();
            }
          }, throw expr<Object>())) {
        // Unreachable because the guard clause throws
        reachability0 = null;
      } else {
        reachability1 = null;
        // `x` is known to have type `Future<int>` because if it had type `int`,
        // the guard clause would have executed (and an exception would have
        // been thrown).
        x.expectStaticType<Exactly<Future<int>>>();
      }
    }
    reachability0.expectStaticType<Exactly<int>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
}

T expr<T>() => throw UnimplementedError();

T pickSecond<T>(dynamic x, T y) => y;

main() {}
