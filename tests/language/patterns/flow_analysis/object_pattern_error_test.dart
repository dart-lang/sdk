// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // An object pattern can promote the scrutinee.
    var x = expr<Object?>();
    if (x case int()) {
      x.expectStaticType<Exactly<int>>();
    }
  }
  {
    // If the scrutinee is already promoted, a subsequente object pattern
    // doesn't demote it.
    var x = expr<Object?>();
    if (x case (_ as int && num()) && var y) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    // Inside a record pattern, if the required type is a subtype of the
    // record's field type, the record's field type is promoted.
    var x = expr<(num,)>();
    if (x case (int(),)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // If the required type is a supertype of the record's field type, the
    // record's field type is unchanged.
    var x = expr<(num,)>();
    if (x case (Object(),)) {
      x.expectStaticType<Exactly<(num,)>>();
    }
  }
  {
    // If the required type is unrelated to the record's field type, the
    // record's field type is unchanged.
    var x = expr<(num,)>();
    if (x case (String(),)) {
      x.expectStaticType<Exactly<(num,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
