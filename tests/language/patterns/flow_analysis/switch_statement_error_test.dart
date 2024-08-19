// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "../../static_type_helper.dart";

test() {
  {
    // Guard expressions can promote (in this case, the guard `x != null`
    // promotes `x` to non-nullable `int`).
    int? reachability0 = 0;
    int? reachability1 = 0;
    int? x;
    switch (expr<Object>()) {
      case _ when x != null:
        reachability0 = null;
        x.expectStaticType<Exactly<int>>();
      default:
        reachability1 = null;
        x.expectStaticType<Exactly<int?>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // When a pattern fully covers the scrutinee type, a guard can cause
    // promotion in later cases (in this case, the guard `x == null` causes `x`
    // to be promoted to non-nullable later in the switch).
    int? x;
    switch (expr<Object?>()) {
      case _ when x == null:
        break;
      case _:
        x.expectStaticType<Exactly<int>>();
    }
  }
  {
    // When a pattern doesn't fully cover the scrutinee type, a guard doesn't
    // cause promotion in later cases (in this case, the guard `x == null` does
    // *not* cause `x` to be promoted to non-nullable later in the switch,
    // because the guard only executes when the scrutinee is a `String`).
    int? x;
    switch (expr<Object?>()) {
      case String _ when x == null:
        break;
      case _:
        x.expectStaticType<Exactly<int?>>();
    }
  }
  {
    // A switch statement can promote the scrutinee.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<num>();
    switch (x) {
      case int y:
        reachability0 = null;
        x.expectStaticType<Exactly<int>>();
      default:
        reachability1 = null;
        x.expectStaticType<Exactly<num>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // Every case ends in an implicit break, so in this example, the code after
    // the switch statement is reachable.
    int? reachability0 = 0;
    var x = expr<Object>();
    if (expr<bool>()) {
      switch (expr<Object>()) {
        case int _:
          x as int;
        default:
          return;
      }
      reachability0 = null;
      x.expectStaticType<Exactly<int>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
  }
  {
    // A switch on an always-exhaustive type is guaranteed to be exhaustive
    // (thanks to the exhaustiveness checker), so in this example, the code
    // after the switch statement is not reachable.
    int? reachability0 = 0;
    if (expr<bool>()) {
      switch (expr<SealedClass>()) {
        case DerivedFromSealedClass _:
          return;
      }
      reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
  }
  {
    // A switch on a type that is not always-exhaustive is not guaranteed to be
    // exhaustive.
    int? reachability0 = 0;
    if (expr<bool>()) {
      switch (expr<int>()) {
        case 0:
          return;
      }
      reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
  }
  {
    // An empty switch statement on an always-exhaustive type acts like a
    // `throw`.
    int? reachability0 = 0;
    if (expr<bool>()) {
      switch (expr<EmptySealedClass>()) {}
      reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
  }
  {
    // Test nested switch statements. This test verifies that the scrutinee
    // types between the inner and outer switch statements are not mixed up.
    switch (expr<int>()) {
      case var x when expr<bool>():
        x.expectStaticType<Exactly<int>>();
        switch (expr<String>()) {
          case var y:
            y.expectStaticType<Exactly<String>>();
        }
      case var z:
        z.expectStaticType<Exactly<int>>();
    }
  }
  {
    // This test verifies that the scrutinee references between the inner and
    // outer switch statements are not mixed up.
    var x = expr<Object>();
    var y = expr<Object>();
    switch (x) {
      case num _:
        x.expectStaticType<Exactly<num>>();
        y.expectStaticType<Exactly<Object>>();
        switch (y) {
          case int _:
            x.expectStaticType<Exactly<num>>();
            y.expectStaticType<Exactly<int>>();
          default:
            return;
        }
        x.expectStaticType<Exactly<num>>();
        y.expectStaticType<Exactly<int>>();
      case String _:
        x.expectStaticType<Exactly<String>>();
        y.expectStaticType<Exactly<Object>>();
    }
  }
  {
    // If the scrutinee is reassigned in a guard clause, a successful match
    // won't promote it. But the matched value is still promoted.
    var x = expr<Object>();
    switch (x) {
      case int _ && var y when expr<bool>():
        x.expectStaticType<Exactly<int>>();
        y.expectStaticType<Exactly<int>>();
      case _ when pickSecond(x = expr<Object>(), expr<bool>()):
        break;
      case int _ && var z:
        x.expectStaticType<Exactly<Object>>();
        z.expectStaticType<Exactly<int>>();
    }
  }
  {
    // If multiple cases share a body, promotions in those cases are joined. In
    // this example, the first case promotes to `num` and then to `int`, whereas
    // the second case promotes only to `num`, so the promotion to `num` is
    // retained.
    var x = expr<Object>();
    switch (x) {
      case num() && int():
      case num():
        x.expectStaticType<Exactly<num>>();
    }
  }
  {
    // In this example, the second case promotes to `num` and then to `int`,
    // whereas the second case promotes only to `num`, so the promotion to `num`
    // is retained.
    var x = expr<Object>();
    switch (x) {
      case num() when expr<bool>():
      case num() && int():
        x.expectStaticType<Exactly<num>>();
    }
  }
  {
    // A similar rule applies to variables declared in patterns. In this
    // example, `x` is promoted to `int` in the first case but not the second
    // (because the matched value type is `int` in the first case), so the
    // promotion is not retained.
    switch (expr<(int, int?)>()) {
      case (0, int? x?):
      case (1, int? x):
        x.expectStaticType<Exactly<int?>>();
    }
  }
  {
    // In this example, `x` is promoted to `int` in the second case but not the
    // first, so the promotion is not retained.
    switch (expr<(int, int?)>()) {
      case (0, int? x):
      case (1, int? x?):
        x.expectStaticType<Exactly<int?>>();
    }
  }
  {
    // In this example, `x` is promoted to `int` in both the first and second
    // cases, so the promotion is retained.
    switch (expr<int?>()) {
      case int? x? when expr<bool>():
      case int? x?:
        x.expectStaticType<Exactly<int>>();
    }
  }
  {
    // A guard clause can also promote a variable declared in a pattern. In this
    // example, `x` is promoted to `int` in both the first and second clauses;
    // in the first case it's promoted at the declaration site (because the
    // matched value type is `int`), and in the second case it's promoted in the
    // guard clause.
    switch (expr<(int, int?)>()) {
      case (0, int? x?):
      case (1, int? x) when x != null:
        x.expectStaticType<Exactly<int>>();
    }
  }
  {
    // Here's a more complex example of promotion of matched variables, based on
    // a co19 test that was failing early in the implementation.
    switch (expr<Object?>()) {
      case String? a? when a is Never:
      case String? a when a != null:
      case String? a! when a == 1:
        a.expectStaticType<Exactly<String>>();
    }
  }
  {
    // If a switch statement contains a case that fully covers the matched value
    // type, it is recognized to be trivially exhaustive (so in this example,
    // the code after the switch statement is unreachable)..
    int? reachability0 = 0;
    if (expr<bool>()) {
      switch (expr<Object>()) {
        case _:
          return;
      }
      reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
  }
  {
    // However, if a switch statement is trivially exhaustive, but one of its
    // reachable switch cases completes normally, the code after the switch
    // statements is reachable.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<bool>()) {
      switch (expr<Object>()) {
        case int _:
          reachability0 = null;
        case _:
          return;
      }
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // Conversely, if a switch statement is trivially exhaustive, and one of its
    // switch cases completes normally, but that switch case is itself trivially
    // unreachable, then the code after the switch statements is unreachable.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<bool>()) {
      switch (expr<Object>()) {
        case _:
          return;
        case int _:
//      ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
          reachability0 = null;
      }
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
    reachability1.expectStaticType<Exactly<int>>();
  }
  {
    // If a switch statement is trivially exhaustive, but one of its reachable
    // switch cases contains a reachable `break` statement, the code after the
    // switch statements is reachable.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<bool>()) {
      switch (expr<Object>()) {
        case int _:
          reachability0 = null;
          break;
        case _:
          return;
      }
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // However, if a switch statement is trivially exhaustive, and one of its
    // switch cases contains a `break` statement that is reachable from the top
    // of that case, but the switch case is itself trivially unreachable, then
    // the code after the switch statements is unreachable.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<bool>()) {
      switch (expr<Object>()) {
        case _:
          return;
        case int _:
//      ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
          reachability0 = null;
          break;
      }
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
    reachability1.expectStaticType<Exactly<int>>();
  }
  {
    // Here is an example of a switch statement that is not trivially
    // exhaustive, to verify that the code after the switch statement is
    // considered reachable.
    int? reachability0 = 0;
    if (expr<bool>()) {
      switch (expr<Object>()) {
        case int _:
          return;
      }
      reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
  }
}

T expr<T>() => throw UnimplementedError();

T pickSecond<T>(dynamic x, T y) => y;

sealed class SealedClass {}

class DerivedFromSealedClass extends SealedClass {}

sealed class EmptySealedClass {}

main() {}
