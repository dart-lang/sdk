// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // A variable pattern whose type fully covers the matched value type always
    // matches.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<int>() case num x) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int>>();
  }
  {
    // The same reachability analysis applies even if the scrutinee is a
    // promotion candidate.
    int? reachability0 = 0;
    int? reachability1 = 0;
    var x = expr<int>();
    if (x case num y) {
      reachability0 = null;
      x.expectStaticType<Exactly<int>>();
    } else {
      reachability1 = null;
      x.expectStaticType<Exactly<int>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int>>();
  }
  {
    // A variable pattern whose type does not cover the matched value type may
    // or may not match.
    int? reachability0 = 0;
    int? reachability1 = 0;
    if (expr<num>() case int x) {
      reachability0 = null;
    } else {
      reachability1 = null;
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // The same reachability analysis applies even if the scrutinee is a
    // promotion candidate.
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
    // If the variable's type does not fully cover the matched value type, and
    // the `factor` algorithm produces a nontrivial result (see
    // https://github.com/dart-lang/language/blob/main/resources/type-system/flow-analysis.md#promotion),
    // the matched value is promoted in the non-matching code path.
    int? reachability0 = 0;
    int? reachability1 = 0;
    int? x;
    if (x case Null y) {
      reachability0 = null;
      x.expectStaticType<Exactly<Null>>();
    } else {
      reachability1 = null;
      x.expectStaticType<Exactly<int>>();
    }
    reachability0.expectStaticType<Exactly<int?>>();
    reachability1.expectStaticType<Exactly<int?>>();
  }
  {
    // A variable pattern does not promote the scrutinee if it's a subpattern.
    var x = expr<Object>();
    if (x case num(sign: int y)) {
      x.expectStaticType<Exactly<num>>();
    }
  }
  {
    // If the scrutinee is already promoted, a subsequent variable pattern
    // doesn't demote it.
    var x = expr<Object?>();
    if (x case (_ as int && num y) && var z) {
      x.expectStaticType<Exactly<int>>();
      z.expectStaticType<Exactly<int>>();
    }
  }
  {
    // If a variable pattern with a nullable type is matched against a matched
    // value with a non-nullable type, the variable is automatically promoted at
    // the declaration site (this matches the behavior of ordinary variable
    // declarations).
    if (expr<Object>() case int? x) {
      x.expectStaticType<Exactly<int>>();
    }
  }
  {
    // However, if a variable pattern with a nullable type is matched against a
    // matched value with a type of `Null`, the variable is *not* automatically
    // promoted to `Null` (this matches the behavior of ordinary variable
    // declarations).
    if (expr<Null>() case int? x) {
      x.expectStaticType<Exactly<int?>>();
    }
  }
  {
    // Inside a record pattern, if the variable type is a subtype of the
    // record's field type, the record's field type is promoted.
    var x = expr<(num,)>();
    if (x case (int y,)) {
      x.expectStaticType<Exactly<(int,)>>();
    }
  }
  {
    // If the variable type is a supertype of the record's field type, the
    // record's field type is not changed.
    var x = expr<(num,)>();
    if (x case (Object y,)) {
      x.expectStaticType<Exactly<(num,)>>();
    }
  }
  {
    // If the variable type is unrelated to the record's field type, the
    // record's field type is not changed.
    var x = expr<(num,)>();
    if (x case (String y,)) {
      x.expectStaticType<Exactly<(num,)>>();
    }
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
