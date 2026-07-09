// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // A map pattern can promote its scrutinee.
    var x = expr<Object?>();
    if (x case <int, String>{0: _}) {
      x.expectStaticType<Exactly<Map<int, String>>>();
    }
  }
  {
    // In general, a map pattern may or may not match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Object?>() case {const Object(): _}) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // If the scrutinee is already promoted, a map pattern with a less specific
    // required type doesn't demote it.
    var x = expr<Object?>();
    if (x case (_ as Map<int, int> && <num, num>{const Object(): _}) && var y) {
      x.expectStaticType<Exactly<Map<int, int>>>();
      y.expectStaticType<Exactly<Map<int, int>>>();
    }
  }
  {
    // Even if the required type of the map pattern is exactly the same as the
    // matched value type, the map pattern may or may not match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<Map<int, int>>();
    if (x case <int, int>{const Object(): _}) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // Inside a record pattern, if the map pattern's required type is a subtype
    // of the record's field type, the record's field type is promoted.
    var x = expr<(Map<num?, Object>?,)>();
    if (x case (<int?, num>{0: int _},)) {
      x.expectStaticType<Exactly<(Map<int?, num>,)>>();
    }
  }
  {
    // If the map pattern's required type is a supertype of the record's field
    // type, the record's field type is not changed.
    var x = expr<(Map<int, num>,)>();
    if (x case (<int, Object>{0: int _},)) {
      x.expectStaticType<Exactly<(Map<int, num>,)>>();
    }
  }
  {
    // If the map pattern's required type is unrelated to the record's field
    // type, the record's field type is not changed.
    var x = expr<(Map<int, int?>,)>();
    if (x case (<int, num>{0: int _},)) {
      x.expectStaticType<Exactly<(Map<int, int?>,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
