// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // When the cast type is a subtype of matched value type, the scrutinee is
    // promoted, and the inner pattern receives the cast type as its matched
    // value type.
    var x = expr<Object?>();
    if (x case var y as String) {
      x.expectStaticType<Exactly<String>>();
      y.expectStaticType<Exactly<String>>();
    }
  }
  {
    // When the cast type is a supertype of matched value type, the type of the
    // scrutinee is unchanged, and the inner pattern receives the cast type as
    // its matched value type.
    var x = expr<num>();
    if (x case var y as Object) {
      x.expectStaticType<Exactly<num>>();
      y.expectStaticType<Exactly<Object>>();
    }
  }
  {
    // When the cast type is unrelated to the matched value type, the type of
    // the scrutinee is unchanged, and the inner pattern receives the cast type
    // as its matched value type.
    var x = expr<num>();
    if (x case var y as String) {
      x.expectStaticType<Exactly<num>>();
      y.expectStaticType<Exactly<String>>();
    }
  }
  {
    // Promotions inside the inner pattern have no effect outside the cast.
    var x = expr<Object?>();
    if (x case int() as num && var y) {
      x.expectStaticType<Exactly<num>>();
      y.expectStaticType<Exactly<num>>();
    }
  }
  {
    // A cast pattern cannot fail to match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Object?>() case _ as int) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int>>();
  }
  {
    // If the scrutinee is already promoted, a subsequent cast pattern doesn't
    // demote it.
    var x = expr<Object?>();
    if (x case (_ as int && _ as num) && var y) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    // Inside a record pattern, if the cast type is a subtype of the record's
    // field type, the record's field type is promoted.
    var x = expr<(num,)>();
    if (x case (_ as int,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // If the cast type is a supertype of the record's field type, the record's
    // field type is not changed.
    var x = expr<(num,)>();
    if (x case (_ as Object,)) {
      x.expectStaticType<Exactly<(num,)>>();
    }
  }
  {
    // If the cast type is unrelated to the record's field type, the record's
    // field type is not changed.
    var x = expr<(num,)>();
    if (x case (_ as String,)) {
      x.expectStaticType<Exactly<(num,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
