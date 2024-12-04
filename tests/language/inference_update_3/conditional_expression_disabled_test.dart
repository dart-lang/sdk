// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the absence of the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494
// when the `inference-update-3` language feature is not enabled, using
// conditional expressions.

// @dart=3.3

import 'package:expect/static_type_helper.dart';

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Object? contextIterable<T>(Iterable<T> x) => x;

test(bool b) {
  // - A conditional expression `e` of the form `b ? e1 : e2` with context type
  //   K is analyzed as follows:
  //
  //   - Let T1 be the type of `e1` inferred with context type K.
  //   - Let T2 be the type of `e2` inferred with context type K.
  {
    // Check the context type of `e1` and `e2`:
    // - Where the context is established using a function call argument.
    context<String>(b
        ? (contextType('')..expectStaticType<Exactly<String>>())
        : (contextType('')..expectStaticType<Exactly<String>>()));

    // - Where the context is established using local variable promotion.
    Object? o;
    o = '' as Object?;
    if (o is String) {
      o = b
          ? (contextType('')..expectStaticType<Exactly<String>>())
          : (contextType('')..expectStaticType<Exactly<String>>());
    }
  }

  //   - Let T be UP(T1, T2).
  //   - Let S be the greatest closure of K.
  //   - If T <: S, then the type of `e` is T.
  //     (Testing this case here. Otherwise continued below.)
  {
    // This example has:
    // - K = Object
    // - T1 = int
    // - T2 = double
    // Which implies:
    // - T = num
    // - S = Object
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = num.
    var i = 1;
    var d = 2.0;
    context<Object>((b ? i : d)..expectStaticType<Exactly<num>>());

    // This example has:
    // - K = Iterable<_>
    // - T1 = Iterable<int>
    // - T2 = Iterable<double>
    // Which implies:
    // - T = Iterable<num>
    // - S = Iterable<Object?>
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = Iterable<num>.
    var iterableInt = <int>[] as Iterable<int>;
    var iterableDouble = <double>[] as Iterable<double>;
    contextIterable((b ? iterableInt : iterableDouble)
      ..expectStaticType<Exactly<Iterable<num>>>());
  }

  //   - Otherwise, if T1 <: S and T2 <: S, and `inference-update-3` is enabled,
  //     then the type of `e` is S.
  {
    // This example has:
    // - K = Iterable<num>
    // - T1 = Iterable<int>
    // - T2 = List<num>
    // Which implies:
    // - T = Object
    // - S = Iterable<num>
    // We have:
    // - T <!: S
    // - T1 <: S
    // - T2 <: S
    // However, inference-update-3 is not enabled.
    // Therefore the type of `e` is T = Object.
    var iterableInt = <int>[] as Iterable<int>;
    var listNum = <num>[];
    Object? o;
    o = [0] as Object?;
    if (o is Iterable<num>) {
      // We avoid having a compile-time error because `o` can be demoted.
      o = (b ? iterableInt : listNum)..expectStaticType<Exactly<Object>>();
    }
  }

  //   - Otherwise, the type of `e` is T.
  {
    var i = 1;
    Object? o;
    var d = 2.0;
    o = '' as Object?;
    if (o is String?) {
      // This example has:
      // - K = String?
      // - T1 = Null
      // - T2 = int
      // Which implies:
      // - T = int?
      // - S = String?
      // We have:
      // - T <!: S
      // - T1 <: S
      // - T2 <!: S
      // The fact that T2 <!: S precludes using S as static type.
      // Therefore the type of `e` is T = int?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (b ? null : i)..expectStaticType<Exactly<int?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // This example has:
      // - K = String?
      // - T1 = int
      // - T2 = Null
      // Which implies:
      // - T = int?
      // - S = String?
      // We have:
      // - T <!: S
      // - T1 <!: S
      // - T2 <: S
      // The fact that T1 <!: S precludes using S as static type.
      // Therefore the type of `e` is T = int?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (b ? i : null)..expectStaticType<Exactly<int?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // This example has:
      // - K = String?
      // - T1 = int
      // - T2 = double
      // Which implies:
      // - T = num
      // - S = String?
      // We have:
      // - T <!: S
      // - T1 <!: S
      // - T2 <!: S
      // The fact that T1 <!: S and T2 <!: S precludes using S as static type.
      // Therefore the type of `e` is T = num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (b ? i : d)..expectStaticType<Exactly<num>>();
    }
  }
}

main() {
  test(true);
  test(false);
}
