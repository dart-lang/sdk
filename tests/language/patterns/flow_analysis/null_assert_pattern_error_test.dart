// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // A null-assert pattern cannot fail to match.
    int? reachability0 = 0;
    if (expr<Object?>() case _!) {
    } else {
      reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
  }
  {
    // A scrutinee that has been modified inside a `when` clause is not
    // promoted.
    var x = expr<Object?>();
    switch (x) {
      case _ when pickSecond(x = expr<Object?>(), expr<bool>()):
        break;
      case _!:
        x.expectStaticType<Exactly<Object?>>();
    }
  }
  {
    // A scrutinee that hasn't been modified is promoted.
    var x = expr<Object?>();
    if (x case _!) {
      x.expectStaticType<Exactly<Object>>();
    } else {
      x.expectStaticType<Exactly<Object?>>();
    }
  }
  {
    // If the null-assert is applied to a subpattern, the scrutinee is not
    // promoted.
    var x = expr<Object?>();
    if (x case NullableInt(foo: _!)) {
      x.expectStaticType<Exactly<int?>>();
    }
  }
  {
    // The matched value is promoted.
    if (expr<Object?>() case _! && var x) {
      x.expectStaticType<Exactly<Object>>();
    }
  }
  {
    // If the matched value type is `Null`, then a null-assert pattern is
    // guaranteed not to match.
    int? reachability0 = 0;
    if (expr<bool>()) {
      if (expr<Null>() case _!) {
        reachability0 = null;
      }
    }
    reachability0.expectStaticType<Exactly<int>>();
  }
  {
    // Otherwise, it may match.
    int? reachability0 = 0;
    if (expr<Object?>() case _!) {
      reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
  }
  {
    // If the scrutinee is already promoted, a subsequent null-assert pattern
    // doesn't demote it.
    var x = expr<Object?>();
    if (x case (_ as int? && _!) && var y) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    // Inside a record pattern, a null-assert pattern can promote the record's
    // field type.
    var x = expr<(int?,)>();
    if (x case (_!,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

T pickSecond<T>(dynamic x, T y) => y;

extension on int? {
  dynamic get foo => throw UnimplementedError();
}

typedef NullableInt = int?;

main() {}
