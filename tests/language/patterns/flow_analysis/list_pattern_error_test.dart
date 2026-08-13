// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // An empty list pattern is not guaranteed to match a list-typed scrutinee.
    int? reachability0 = 0;
    switch (expr<List<Object>>()) {
      case []:
        break;
      default:
        reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
  }
  {
    // A list pattern with a single non-rest element is not guaranteed to match
    // a list-typed scrutinee.
    int? reachability0 = 0;
    switch (expr<List<Object>>()) {
      case [_]:
        break;
      default:
        reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
  }
  {
    // A list pattern with a single rest element is not guaranteed to match a
    // list-typed scrutinee, if the rest element has a subpattern that's not
    // guaranteed to match.
    int? reachability0 = 0;
    switch (expr<List<Object>>()) {
      case [...[]]:
        break;
      default:
        reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
  }
  {
    // A list pattern with a single rest element is guaranteed to match a
    // list-typed scrutinee, if the rest element has no subpattern.
    int? reachability0 = 0;
    switch (expr<List<Object>>()) {
      case [...]:
        break;
      default:
        reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
  }
  {
    // A list pattern with a single rest element is guaranteed to match a
    // list-typed scrutinee, if the rest element has a subpattern that is
    // guaranteed to match.
    int? reachability0 = 0;
    switch (expr<List<Object>>()) {
      case [..._]:
        break;
      default:
        reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
  }
  {
    // A list pattern can promote its scrutinee.
    var x = expr<Object?>();
    if (x case <int>[_]) {
      x.expectStaticType<Exactly<List<int>>>();
    }
  }
  {
    // If the scrutinee is already promoted, a list pattern with a less specific
    // required type doesn't demote it.
    var x = expr<Object?>();
    if (x case (_ as List<int> && <num>[]) && var y) {
      x.expectStaticType<Exactly<List<int>>>();
      y.expectStaticType<Exactly<List<int>>>();
    }
  }
  {
    // In general, a list pattern may or may not match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<List<int>>();
    if (x case <int>[]) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // Inside a record pattern, if the list pattern's required type is a subtype
    // of the record's field type, the record's field type is promoted.
    var x = expr<(Iterable<Object>,)>();
    if (x case (<num>[int _],)) {
      x.expectStaticType<Exactly<(List<num>,)>>();
    }
  }
  {
    // If the list pattern's required type is a supertype of the record's field
    // type, the record's field type is not changed.
    var x = expr<(List<num>,)>();
    if (x case (<Object>[int _],)) {
      x.expectStaticType<Exactly<(List<num>,)>>();
    }
  }
  {
    // If the list pattern's required type is unrelated to the record's field
    // type, the record's field type is not changed.
    var x = expr<(List<int?>,)>();
    if (x case (<num>[int _],)) {
      x.expectStaticType<Exactly<(List<int?>,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
