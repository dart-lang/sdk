// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // Flow analysis recognizes that `case null` is guaranteed to match an
    // expression of type `Null`.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Null>() case null) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int>>();
  }
  {
    // In the general case, flow analysis assumes that a constant pattern may or
    // may not match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Object?>() case 0) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // If `case null` does not match, the scrutinee is promoted to non-nullable.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<int?>();
    if (x case null) {
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
    // `case null` does not promote the scrutinee if it's been changed by a
    // previous case.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<int?>();
    switch (x) {
      case _ when pickSecond(x = expr<int?>(), expr<bool>()):
        break;
      case null:
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
    // `case null` can even match non-nullable types.

    // Note that in most cases, flow analysis assumes soundness when analyzing
    // patterns. This is an exception: `case null` is assumed to be a possible
    // match even for a non-nullable scrutinee; this makes `case null` behave
    // similarly to an `if (x == null)` test.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<int>() case null) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // If a constant pattern appears inside a record pattern, the record's field
    // type is not changed.
    var x = expr<(Object,)>();
    if (x case (1,)) {
      // Note that at this point, we don't know that `x.$1` is an `int`; we just
      // know that `1 == x.$1` returned `true`. (`x` could be `1.0`, for
      // instance). In the general case where the constant value has a user
      // defined type, we can't assume anything because the type might have a
      // user-defined `==` operator. So for simplicity and consistency, we don't
      // do any promotion for the case where a constant matches, regardless of
      // the type of the constant.
      x.expectStaticType<Exactly<(Object,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

T pickSecond<T>(dynamic x, T y) => y;

main() {}
