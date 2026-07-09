// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // If the LHS promotes the matched value type, this promotion is reflected
    // in the matched value type seen by the RHS.
    var x = expr<num>();
    if (x case int _ && var y) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    // Promotion of the matched value type is seen by the RHS even if the
    // scrutinee is not promotable.
    if (expr<num>() case int _ && var x) {
      x.expectStaticType<Exactly<int>>();
    }
  }
  {
    // A matched value type that is already promoted can be promoted again.
    var x = expr<Object>();
    if (x case num _ && (int _ && var y)) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    // Inside a record pattern, if the LHS and RHS could both promote the
    // record's field type, and the LHS promotes to a subtype of the RHS, the
    // LHS promotion is retained.
    var x = expr<(Object,)>();
    if (x case (int _ && num _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // Whereas if the RHS promotes to a subtype of the LHS, the RHS promotion is
    // retained.
    var x = expr<(Object,)>();
    if (x case (num _ && int _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // If the LHS could promote the record's field type, and the RHS could not
    // promote it (because its required type is the same as the record's field
    // type), the LHS promotion is retained.
    var x = expr<(num,)>();
    if (x case (int _ && num _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // Whereas if the RHS could promote the record's field type, and the LHS
    // could not promote it (because its required type is the same as the
    // record's field type), the RHS promotion is retained.
    var x = expr<(num,)>();
    if (x case (num _ && int _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // If the LHS could promote the record's field type, and the RHS could not
    // promote it (because its required type is not a subtype of the record's
    // field type), the LHS promotion is retained.
    var x = expr<(num,)>();
    if (x case (int _ && Object _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // Whereas if the RHS could promote the record's field type, and the LHS
    // could not promote it (because its required type is not a subtype of the
    // record's field type), the RHS promotion is retained.
    var x = expr<(num,)>();
    if (x case (Object _ && int _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // If neither the LHS nor the RHS could promote the record's field type, the
    // record's field type is unchanged. This test case covers the situation
    // where the required type of the LHS is a subtype of the required type of
    // the RHS.
    var x = expr<(int,)>();
    if (x case (num _ && Object _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // And this test case covers the situation where the required type of the
    // RHS is a subtype of the required type of the LHS.
    var x = expr<(int,)>();
    if (x case (Object _ && num _,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
