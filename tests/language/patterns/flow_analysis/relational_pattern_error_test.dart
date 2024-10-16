// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // If the matched value type is `Null`, an `== null` pattern is guaranteed
    // to match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Null>() case == null) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int>>();
  }
  {
    // An `== null` pattern inside a subpattern is guaranteed to match if the
    // matched value type of the subpattern is `Null`.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<(Null,)>() case (== null,)) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int>>();
  }
  {
    // In the general case, a relational pattern using `==` may or may not
    // match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Object?>() case == 0) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // An `== null` pattern promotes a scrutinee in the case where it does *not*
    // match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<int?>();
    if (x case == null) {
      reachability0 = null;
      // Note that in this branch, `x` is known to be `null`, but we don't
      // promote to the type `Null`, for consistency with the flow analysis
      // behavior of `== null`. See
      // https://github.com/dart-lang/language/issues/1505#issuecomment-975706918
      // for details.
      x.expectStaticType<Exactly<int?>>();
    } else {
      reachability1 = null;
      x.expectStaticType<Exactly<int>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // An `== null` pattern doesn't promote a scrutinee that has been changed in
    // a previous guard clause.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<int?>();
    switch (x) {
      case _ when pickSecond(x = expr<int?>(), expr<bool>()):
        break;
      case == null:
        reachability0 = null;
        x.expectStaticType<Exactly<int?>>();
      case var y:
        reachability1 = null;
        x.expectStaticType<Exactly<int?>>();
        y.expectStaticType<Exactly<int>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // An `== null` pattern can even match non-nullable types.

    // Note that in most cases, flow analysis assumes soundness when analyzing
    // patterns. This is an exception: `case == null` is assumed to be a
    // possible match even for a non-nullable scrutinee; this makes `case ==
    // null` behave similarly to an `if (x == null)` test.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<int>() case == null) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // If a relational pattern using `==` appears inside a record pattern, the
    // record's field type is not changed.
    var x = expr<(Object?,)>();
    if (x case (== const Object(),)) {
      x.expectStaticType<Exactly<(Object?,)>>();
    }
  }
  {
    // Even if the relational pattern is an `== null` pattern.
    var x = expr<(Object?,)>();
    if (x case (== null,)) {
      x.expectStaticType<Exactly<(Object?,)>>();
    }
  }
  {
    // A `!= null` pattern cannot match the `Null` type.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Null>() case != null) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // In general, a relational pattern using `!=` may or may not match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Object?>() case != 0) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // A `!= null` pattern promotes a scrutinee to non-nullable.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<int?>();
    if (x case != null) {
      reachability0 = null;
      x.expectStaticType<Exactly<int>>();
    } else {
      reachability1 = null;
      x.expectStaticType<Exactly<int?>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // A `!= null` pattern doesn't promote a scrutinee that has been changed in
    // a previous guard clause.
    int? reachability0 = 0;
    var x = expr<int?>();
    switch (x) {
      case _ when pickSecond(x = expr<int?>(), expr<bool>()):
        break;
      case != null && var y:
        reachability0 = null;
        x.expectStaticType<Exactly<int?>>();
        y.expectStaticType<Exactly<int>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
  }
  {
    // A `!= null` pattern promotes the matched value.
    if (expr<int?>() case != null && var x) {
      x.expectStaticType<Exactly<int>>();
    }
  }
  {
    // A `!= null` pattern may or may not match, even if the matched value type
    // if non-nullable.

    // Note that in most cases, flow analysis assumes soundness when analyzing
    // patterns. This is an exception: `case != null` is assumed to be a
    // possible mismatch even for a non-nullable scrutinee; this makes `case !=
    // null` behave similarly to an `if (x != null)` test.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<int>() case != null) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // If a relational pattern using `!=` appears inside a record pattern, the
    // record's field type is not changed.
    var x = expr<(Object?,)>();
    if (x case (!= const Object(),)) {
      x.expectStaticType<Exactly<(Object?,)>>();
    }
  }
  {
    // Even if the relational pattern is a `!= null` pattern.
    var x = expr<(Object?,)>();
    if (x case (!= null,)) {
      x.expectStaticType<Exactly<(Object,)>>();
    }
  }
  {
    // A relational pattern using a non-equality operator doesn't have any flow
    // analysis effects. To verify this, we use an extension method so that `<
    // null` is a valid pattern; this ensures that we don't accidentally apply
    // the flow analysis rules for `== null` or `!= null`.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Null>() case < null) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // If a relational pattern using a non-equality operator appears inside a
    // record pattern, the record's field type is not changed.
    var x = expr<(int,)>();
    if (x case (> 0,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

T pickSecond<T>(dynamic x, T y) => y;

extension on Null {
  bool operator <(Object? _0) => throw UnimplementedError();
}

main() {}
