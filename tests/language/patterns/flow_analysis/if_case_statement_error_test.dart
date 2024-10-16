// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // In an if-case statement with a guard, the guard expression can perform
    // promotions.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<int?>();
    if (expr<Object>() case _ when x != null) {
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
    // An if-case statement can promote its scrutinee.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<num>();
    if (x case int y) {
      reachability0 = null;
      x.expectStaticType<Exactly<int>>();
    } else {
      reachability1 = null;
      x.expectStaticType<Exactly<num>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // It's possible for a promotion to occur in both the pattern and the guard.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<int?>();
    var y = expr<String?>();
    if (x case int _ when y != null) {
      reachability0 = null;
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<String>>();
    } else {
      reachability1 = null;
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<String?>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
