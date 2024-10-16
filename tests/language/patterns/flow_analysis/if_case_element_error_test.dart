// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // In an if-case element with a guard, the guard expression can perform
    // promotions.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<int?>();
    <String>[
      if (expr<Object>() case _ when x != null)
        pickSecond(
            <Object?>[reachability0 = null, x.expectStaticType<Exactly<int>>()],
            expr<String>())
      else
        pickSecond(<Object?>[
          reachability1 = null,
          x.expectStaticType<Exactly<int?>>()
        ], expr<String>())
    ];
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // An if-case element can promote its scrutinee.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<num>();
    <String>[
      if (x case int y)
        pickSecond(
            <Object?>[reachability0 = null, x.expectStaticType<Exactly<int>>()],
            expr<String>())
      else
        pickSecond(
            <Object?>[reachability1 = null, x.expectStaticType<Exactly<num>>()],
            expr<String>())
    ];
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
}

T expr<T>() => throw UnimplementedError();

T pickSecond<T>(dynamic x, T y) => y;

main() {}
