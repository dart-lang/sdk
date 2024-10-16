// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // Guard expressions can promote (in this case, the guard `x != null`
    // promotes `x` to non-nullable `int`).
    int? reachability0 = 0;
    int? reachability1 = 0;
    int? x;
    (switch (expr<Object>()) {
      _ when x != null => pickSecond(
          <Object?>[reachability0 = null, x.expectStaticType<Exactly<int>>()],
          expr<String>()),
      _ => pickSecond(
          <Object?>[reachability1 = null, x.expectStaticType<Exactly<int?>>()],
          expr<String>())
    });
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // When a pattern fully covers the scrutinee type, a guard can cause
    // promotion in later cases (in this case, the guard `x == null` causes `x`
    // to be promoted to non-nullable later in the switch).
    int? x;
    (switch (expr<Object?>()) {
      _ when x == null => 0,
      _ => pickSecond(x.expectStaticType<Exactly<int>>(), 1)
    });
  }
  {
    // When a pattern doesn't fully cover the scrutinee type, a guard doesn't
    // cause promotion in later cases (in this case, the guard `x == null` does
    // *not* cause `x` to be promoted to non-nullable later in the switch,
    // because the guard only executes when the scrutinee is a `String`).
    int? x;
    (switch (expr<Object?>()) {
      String _ when x == null => 0,
      _ => pickSecond(x.expectStaticType<Exactly<int?>>(), 1)
    });
  }
  {
    // A switch expression can promote the scrutinee.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<num>();
    (switch (x) {
      int y => pickSecond(
          <Object?>[reachability0 = null, x.expectStaticType<Exactly<int>>()],
          expr<String>()),
      _ => pickSecond(
          <Object?>[reachability1 = null, x.expectStaticType<Exactly<num>>()],
          expr<String>())
    });
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // But if the scrutinee is reassigned in a guard clause, it no longer
    // promotes.
    var x = expr<Object>();
    (switch (x) {
      int _ && var y when expr<bool>() => pickSecond(<Object?>[
          x.expectStaticType<Exactly<int>>(),
          y.expectStaticType<Exactly<int>>()
        ], 0),
      _ when pickSecond(x = expr<Object>(), expr<bool>()) => 1,
      int _ && var z => pickSecond(<Object?>[
          x.expectStaticType<Exactly<Object>>(),
          z.expectStaticType<Exactly<int>>()
        ], 2),
      _ => 3
    });
  }
  {
    // The matched value is promoted even if the scrutinee is reassigned in a
    // guard clause.
    var x = expr<Object>();
    x as int;
    x.expectStaticType<Exactly<int>>();
    (switch (x) {
      _ when pickSecond(x = expr<Object>(), expr<bool>()) => 0,
      var y => pickSecond(<Object?>[
          x.expectStaticType<Exactly<Object>>(),
          y.expectStaticType<Exactly<int>>()
        ], 1)
    });
  }
  {
    // A switch expression with no cases acts like a `throw`.
    int? reachability0 = 0;
    if (expr<bool>()) {
      (switch (expr<EmptySealedClass>()) {});
      reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
  }
}

T expr<T>() => throw UnimplementedError();

T pickSecond<T>(dynamic x, T y) => y;

sealed class EmptySealedClass {}

main() {}
