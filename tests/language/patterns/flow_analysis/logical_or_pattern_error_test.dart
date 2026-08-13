// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // Promotions from the LHS and RHS are joined using the normal flow analysis
    // rules (common promotions are retained), so if the LHS promotes to `num`
    // and then to `int`, whereas the RHS promotes to just `num`, then the
    // promotion to `num` is retained.
    var x = expr<Object>();
    if (x case (num() && int()) || num()) {
      x.expectStaticType<Exactly<num>>();
    }
  }
  {
    // Whereas if the RHS promotes to `num` and then to `int`, whereas the LHS
    // promotes to just `num`, then the promotion to `num` is retained.
    var x = expr<Object>();
    if (x case num() || (num() && int())) {
      x.expectStaticType<Exactly<num>>();
    }
  }
  {
    // Promotions of the matched value are treated similarly; in this case, the
    // LHS promotes to `num` and then to `int`, whereas the RHS promotes to just
    // `num`, so the promotion to `num` is retained.
    if (expr<Object>() case ((num() && int()) || num()) && var x) {
      x.expectStaticType<Exactly<num>>();
    }
  }
  {
    // And in this case, the RHS promotes to `num` and then to `int`, whereas
    // the LHS promotes to just `num`, so the promotion to `num` is retained.
    if (expr<Object>() case (num() || (num() && int())) && var x) {
      x.expectStaticType<Exactly<num>>();
    }
  }
  {
    // Promotions of explicitly declared match variables are treated similarly;
    // in this case, the LHS promotes `x` to `int`, whereas the RHS does not, so
    // `x` is not promoted.
    if (expr<int?>() case int? x? || int? x) {
      x.expectStaticType<Exactly<int?>>();
    }
  }
  {
    // And in this case, the RHS promotes `x` to `int`, whereas the LHS does
    // not, so `x` is not promoted.
    if (expr<int?>() case int? x || int? x?) {
      x.expectStaticType<Exactly<int?>>();
    }
  }
  {
    // And in this case, both the LHS and RHS promote `x` to `int`, so the
    // promotion to `int` is retained.
    if (expr<int?>() case int? x? || int? x?) {
      x.expectStaticType<Exactly<int>>();
    }
  }
  {
    // Similar rules apply inside a record pattern. In this example, both the
    // LHS and RHS could both promote the record's field type, and the LHS
    // promotes to a subtype of the RHS. But the record's field type is
    // unchanged because the join finds no common types.
    var x = expr<(Object,)>();
    if (x case (int _ || num _,)) {
      x.expectStaticType<Exactly<(Object,)>>();
    }
  }
  {
    // Similarly, in this case the RHS promotes to a subtype of the LHS. But the
    // record's field type is unchanged because the join finds no common types.
    var x = expr<(Object,)>();
    if (x case (num _ || int _,)) {
      x.expectStaticType<Exactly<(Object,)>>();
    }
  }
  {
    // In this case the LHS and RHS promote to the same type, so the record's
    // field type is promoted to that type.
    var x = expr<(Object,)>();
    if (x case (num _ || num _,)) {
      x.expectStaticType<Exactly<(num,)>>();
    }
  }
  {
    // In this case the LHS promotes and the RHS does not, so the join finds no
    // common types, and the record's field type is unchanged.
    var x = expr<(num,)>();
    if (x case (int _ || Object _,)) {
      x.expectStaticType<Exactly<(num,)>>();
    }
  }
  {
    // In this case the RHS promotes and the LHS does not, so the join finds no
    // common types, and the record's field type is unchanged.
    var x = expr<(num,)>();
    if (x case (Object _ || int _,)) {
      x.expectStaticType<Exactly<(num,)>>();
    }
  }
  {
    // In this case the required type of the LHS is a subtype of the required
    // type of the RHS, but neither type promotes, so the record's field type is
    // unchanged.
    var x = expr<(int,)>();
    if (x case (num _ || Object _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // And in this case the required type of the RHS is a subtype of the
    // required type of the LHS, but neither type promotes, so the record's
    // field type is unchanged.
    var x = expr<(int,)>();
    if (x case (Object _ || num _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // This case demonstrates that even if a least upper bound exists between
    // the required types of the LHS and RHS, the record's field type is not
    // promoted to that least upper bound.
    var x = expr<(Object?,)>();
    if (x case (int _ || double _,)) {
      x.expectStaticType<Exactly<(Object?,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
