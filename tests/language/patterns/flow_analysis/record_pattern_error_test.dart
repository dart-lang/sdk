// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // A record pattern can promote the scrutinee.
    var x = expr<Object?>();
    if (x case (_,)) {
      x.expectStaticType<Exactly<(Object?,)>>();
    }
  }
  {
    // A more complex promotion example with unnamed fields.
    var x = expr<Object?>();
    if (x case (int _, String _)) {
      x.expectStaticType<Exactly<(int, String)>>();
    }
  }
  {
    // A more complex promotion example with named fields.
    var x = expr<Object?>();
    if (x case (i: int _, s: String _)) {
      x.expectStaticType<Exactly<({int i, String s})>>();
    }
  }
  {
    // A record pattern's required type (formed from the record shape, with the
    // type `Object?` for all fields) is considered a type of interest, even if
    // the record pattern promotes the scrutinee further.
    var x = expr<Object>();
    if (x case (int _,)) {
      x.expectStaticType<Exactly<(int,)>>();
      x = expr<(num,)>();
      x.expectStaticType<Exactly<(Object?,)>>();
    }
  }
  {
    // A record type can only fail if its required type fails to match or if one
    // of its subpattern matches fails; it can't fail to match simply because
    // the final promoted type isn't a supertype of the matched value type.
    int? reachability0 = 0;
    var x = expr<(Object?,)>();
    if (x case (_ as int,)) {
      x.expectStaticType<Exactly<(int,)>>();
    } else {
      reachability0 = null;
    }
    reachability0.expectStaticType<Exactly<int>>();
  }
  {
    // In the general case a record pattern can fail to match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<Object?>() case (_,)) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // If the scrutinee is already promoted, a subsequent record pattern doesn't
    // demote it.
    var x = expr<Object?>();
    if (x case (_ as (int,) && (_,)) && var y) {
      x.expectStaticType<Exactly<(int,)>>();
      y.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // When one record pattern is inside another, if the inner record pattern
    // demonstrates that the outer record's field type has a type that is a
    // subtype of what it had before, the outer record's field type is promoted.
    var x = expr<((num,),)>();
    if (x case ((int _,),)) {
      x.expectStaticType<Exactly<((int,),)>>();
    }
  }
  {
    // If the inner record pattern demonstrates that the outer record's field
    // type has a type that is a supertype of what it had before, the outer
    // record's field type is unchanged.
    var x = expr<Never>();
    if (x case ((num _,),)) {
      x.expectStaticType<Exactly<Never>>();
    }
  }
  {
    // If the inner record pattern demonstrates that the outer record's field
    // type has a type that is unrelated to the type it had before, the outer
    // record's field type is unchanged.
    var x = expr<String>();
    if (x case ((num _,),)) {
      x.expectStaticType<Exactly<String>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
