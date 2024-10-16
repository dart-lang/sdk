// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // A pattern assignment can demote an assigned variable.
    var x = expr<int?>();
    x!;
    x.expectStaticType<Exactly<int>>();
    (x) = expr<int?>();
    x.expectStaticType<Exactly<int?>>();
  }
  {
    // But it won't demote an assigned variable if it's not necessary.
    var x = expr<num?>();
    x!;
    x.expectStaticType<Exactly<num>>();
    (x) = expr<int>();
    x.expectStaticType<Exactly<num>>();
  }
  {
    // Inside a pattern assignment, the type schema of a reference to an
    // unpromoted variable is that variable's unpromoted type.
    var x = expr<int?>();
    (x) = contextType(expr<int>())..expectStaticType<Exactly<int?>>();
  }
  {
    // But the type schema of a reference to a promoted variable is that
    // variable's promoted type.
    var x = expr<int?>();
    x!;
    x.expectStaticType<Exactly<int>>();
    (x) = contextType(expr<int>())..expectStaticType<Exactly<int>>();
  }
  {
    // A pattern assignment can promote a variable to a type of interest.
    var x = expr<num>();
    if (x is int) {}
    x.expectStaticType<Exactly<num>>();
    (x) = expr<int>();
    x.expectStaticType<Exactly<int>>();
  }
  {
    // But it won't promote a variable to a type that is not a type of interest.
    var x = expr<num>();
    (x) = expr<int>();
    x.expectStaticType<Exactly<num>>();
  }
  {
    // Assignment to a variable promotes the matched value, in the same way that
    // matching a variable pattern promotes the matched value. In this example,
    // assignment to `x` promotes the matched value from `dynamic` to `int`,
    // therefore attempting to also assign the matched value to the double `y`
    // produces an error.
    int x;
    double y;
    (x && y) = expr<dynamic>();
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT
    // [cfe] The matched value of type 'int' isn't assignable to the required type 'double'.
  }
  {
    // Assignment to a variable doesn't promote the RHS.
    int x;
    var y = expr<dynamic>();
    (x) = y;
    y.expectStaticType<Exactly<dynamic>>();
  }
  {
    // Assignment to a variable makes it definitely assigned.
    int x;
    x; // Definitely not assigned
//  ^
// [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
// [cfe] Non-nullable variable 'x' must be assigned before it can be used.
    (x) = expr<int>();
    x; // Definitely assigned
  }
  {
    // A pattern assignment that assigns to a boolean variable can capture
    // promotions of other variables (just as an ordinary assignment can).
    var x = expr<int?>();
    bool b;
    (b) = x != null;
    if (b) {
      x.expectStaticType<Exactly<int>>();
    }
  }
  {
    // But assignment to a boolean variable in a subpattern does not capture
    // promotions (since this would be unsound).
    var x = expr<int?>();
    bool b;
    bool(foo: b) = x != null;
    if (b) {
      x.expectStaticType<Exactly<int?>>();
    }
  }
  {
    // Inside a record pattern, if a record's field is assigned to a variable,
    // and the type of the variable is a subtype of the record's field type, the
    // record's field type is promoted (but only within the match; the RHS is
    // not promoted).
    var x = expr<(dynamic,)>();
    int y;
    var z = expr<Object?>();
    z as (int,);
    z.expectStaticType<Exactly<(int,)>>();
    ((y,) && z) = x;
    x.expectStaticType<Exactly<(dynamic,)>>();
    // Assignment to `y` demonstrated that the matched value had type `int`, so
    // `z` was not demoted
    z.expectStaticType<Exactly<(int,)>>();
  }
  {
    // If a record's field is assigned to a variable and the type of the
    // variable is a supertype of the record's field type, the record's field
    // type is unchanged.
    var x = expr<(int,)>();
    num y;
    var z = expr<Object?>();
    z as (int,);
    ((y,) && z) = x;
    x.expectStaticType<Exactly<(int,)>>();
    // Assignment to `y` demonstrated that the matched value had type `int`, so
    // `z` was not demoted
    z.expectStaticType<Exactly<(int,)>>();
  }
  {
    // A simple case to verify that pattern assignments don't promote the RHS.
    var x = expr<num>();
    (_ as int) = x;
    x.expectStaticType<Exactly<num>>();
  }
}

T expr<T>() => throw UnimplementedError();

extension on bool {
  bool get foo => throw UnimplementedError();
}

main() {}
