// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that when `sound-flow-analysis` is enabled, each type in a promotion
// chain is a proper subtype of the previous type (and of the declared type).

// SharedOptions=--enable-experiment=sound-flow-analysis

import '../static_type_helper.dart';

class C {
  final Object? _f;
  C(this._f);
}

// A type cast won't promote to a mutual subtype.
testAs(Object? x, List<Object?> y) {
  x as List<Object?>; // Promotes
  x as List<dynamic>; // Does not promote
  y as List<dynamic>; // Does not promote
  x.expectStaticType<Exactly<List<Object?>>>();
  y.expectStaticType<Exactly<List<Object?>>>();
  // Verify that the types really are `List<Object?>` and not `List<dynamic>`.
  // (This works because applying `!` to a variable of type `Object?` promotes
  // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
  {
    var z = x.first;
    z!;
    [z].expectStaticType<Exactly<List<Object>>>();
  }
  {
    var z = y.first;
    z!;
    [z].expectStaticType<Exactly<List<Object>>>();
  }
}

// A type check (using `is`) won't promote to a mutual subtype.
testIs(Object? x, List<Object?> y) {
  x as List<Object?>; // Promotes
  if (x is List<dynamic>) {
    // Does not promote
    x.expectStaticType<Exactly<List<Object?>>>();
    // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
    // (This works because applying `!` to a variable of type `Object?` promotes
    // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
    {
      var z = x.first;
      z!;
      [z].expectStaticType<Exactly<List<Object>>>();
    }
  }
  if (y is List<dynamic>) {
    // Does not promote
    y.expectStaticType<Exactly<List<Object?>>>();
    // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
    // (This works because applying `!` to a variable of type `Object?` promotes
    // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
    {
      var z = y.first;
      z!;
      [z].expectStaticType<Exactly<List<Object>>>();
    }
  }
}

// A type check (using `is!`) won't promote to a mutual subtype.
testIsNot(Object? x, List<Object?> y) {
  x as List<Object?>; // Promotes
  if (x is! List<dynamic>) {
  } else {
    // Does not promote
    x.expectStaticType<Exactly<List<Object?>>>();
    // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
    // (This works because applying `!` to a variable of type `Object?` promotes
    // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
    {
      var z = x.first;
      z!;
      [z].expectStaticType<Exactly<List<Object>>>();
    }
  }
  if (y is! List<dynamic>) {
  } else {
    // Does not promote
    y.expectStaticType<Exactly<List<Object?>>>();
    // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
    // (This works because applying `!` to a variable of type `Object?` promotes
    // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
    {
      var z = y.first;
      z!;
      [z].expectStaticType<Exactly<List<Object>>>();
    }
  }
}

// Type of interest promotion won't promote to a mutual subtype.
testTypeOfInterest(dynamic x) {
  // Note: to work around the fact that a full demotion clears types of interest
  // (see https://github.com/dart-lang/language/issues/4380), this test starts
  // with a variable of type `dynamic` and promotes it first to `List<Object?>?`
  // and then to `List<dynamic>`. This ensures that the write that follows
  // (which writes a value of type `List<Object?>?`) does not fully demote the
  // variable, so the types of interest will be preserved.
  x as List<Object?>?;
  // `x` is now promoted to `List<Object?>?`, and `List<Object?>` is a type of
  // interest.
  x.expectStaticType<Exactly<List<Object?>?>>();
  x as List<dynamic>;
  // `x` is now promoted to `List<dynamic>`, and `List<dynamic>` is a type of
  // interest.
  x.expectStaticType<Exactly<List<dynamic>>>();
  // Verify that the type really is `List<dynamic>` and not `List<Object?>`.
  x.first.abs();
  x = ([0] as List<Object?>?);
  // `x` is now demoted back to `List<Object?>?`.
  x.expectStaticType<Exactly<List<Object?>?>>();
  x = ([0] as List<Object?>);
  // `x` is now promoted to `List<Object?>`, since `List<Object?>` is a type of
  // interest.
  x.expectStaticType<Exactly<List<Object?>>>();
  // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
  // (This works because applying `!` to a variable of type `Object?` promotes
  // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
  {
    var y = x.first;
    y!;
    [y].expectStaticType<Exactly<List<Object>>>();
  }
  x = ([0] as List<void>);
  // Type of interest promotion rejected `List<Object?>` (because it was the
  // already-promoted type) and `List<dynamic>` (because it is a mutual subtype
  // with the already-promoted type).
  x.expectStaticType<Exactly<List<Object?>>>();
  // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
  // (This works because applying `!` to a variable of type `Object?` promotes
  // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
  {
    var y = x.first;
    y!;
    [y].expectStaticType<Exactly<List<Object>>>();
  }
}

// When promotions from a `try` block and `finally` block are combined, a
// promotion to one type may be layered over a promotion to another type, even
// if the two types are mutual subtypes.
//
// In this test, the two promotions in question are applied to a local variable.
testFinallyClauseVariable(Object? x) {
  try {
    x as List<Object?>;
    x.expectStaticType<Exactly<List<Object?>>>();
    // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
    // (This works because applying `!` to a variable of type `Object?` promotes
    // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
    {
      var y = x.first;
      y!;
      [y].expectStaticType<Exactly<List<Object>>>();
    }
  } finally {
    x.expectStaticType<Exactly<Object?>>();
    x as List<dynamic>;
    x.expectStaticType<Exactly<List<dynamic>>>();
    // Verify that the type really is `List<dynamic>` and not `List<Object?>`.
    x.first.abs();
  }
  // After the try/finally, the promotions in the finally block are layered over
  // the promotions in the try block, so the promotion to `List<dynamic>` layers
  // over the promotion to `List<Object?>`. But since the two types are mutual
  // subtypes, the promotion to `List<dynamic>` is discarded, leaving only the
  // promotion to `List<Object?>`.
  x.expectStaticType<Exactly<List<Object?>>>();
  // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
  {
    var z = x.first;
    z!;
    [z].expectStaticType<Exactly<List<Object>>>();
  }
}

// When promotions from a `try` block and `finally` block are combined, a
// promotion to one type may be layered over a promotion to another type, even
// if the two types are mutual subtypes.
//
// In this test, the two promotions in question are applied to a promotable
// property of a local variable that is _not_ modified in the `try` block.
testFinallyClausePropertyOfUnmodifiedVariable(C x) {
  try {
    x._f as List<Object?>;
    x._f.expectStaticType<Exactly<List<Object?>>>();
    // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
    // (This works because applying `!` to a variable of type `Object?` promotes
    // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
    {
      var y = x._f.first;
      y!;
      [y].expectStaticType<Exactly<List<Object>>>();
    }
  } finally {
    x._f.expectStaticType<Exactly<Object?>>();
    x._f as List<dynamic>;
    x._f.expectStaticType<Exactly<List<dynamic>>>();
    // Verify that the type really is `List<dynamic>` and not `List<Object?>`.
    x._f.first.abs();
  }
  // After the try/finally, the promotions in the finally block are layered over
  // the promotions in the try block, so the promotion to `List<dynamic>` layers
  // over the promotion to `List<Object?>`. But since the two types are mutual
  // subtypes, the promotion to `List<dynamic>` is discarded, leaving only the
  // promotion to `List<Object?>`.
  x._f.expectStaticType<Exactly<List<Object?>>>();
  // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
  // (This works because applying `!` to a variable of type `Object?` promotes
  // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
  {
    var z = x._f.first;
    z!;
    [z].expectStaticType<Exactly<List<Object>>>();
  }
}

// When promotions from a `try` block and `finally` block are combined, a
// promotion to one type may be layered over a promotion to another type, even
// if the two types are mutual subtypes.
//
// In this test, the two promotions in question are applied to a promotable
// property of a local variable that _is_ modified in the `try` block.
testFinallyClausePropertyOfModifiedVariable(C x, C y) {
  try {
    x = y;
    x._f as List<Object?>;
    x._f.expectStaticType<Exactly<List<Object?>>>();
    // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
    // (This works because applying `!` to a variable of type `Object?` promotes
    // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
    {
      var y = x._f.first;
      y!;
      [y].expectStaticType<Exactly<List<Object>>>();
    }
  } finally {
    x._f.expectStaticType<Exactly<Object?>>();
    x._f as List<dynamic>;
    x._f.expectStaticType<Exactly<List<dynamic>>>();
    // Verify that the type really is `List<dynamic>` and not `List<Object?>`.
    x._f.first.abs();
  }
  // After the try/finally, the promotions in the finally block are layered over
  // the promotions in the try block (see
  // https://github.com/dart-lang/language/issues/4382), so the promotion to
  // `List<dynamic>` layers over the promotion to `List<Object?>`. But since the
  // two types are mutual subtypes, the promotion to `List<dynamic>` is
  // discarded, leaving only the promotion to `List<Object?>`.
  x._f.expectStaticType<Exactly<List<Object?>>>();
  // Verify that the type really is `List<Object?>` and not `List<dynamic>`.
  // (This works because applying `!` to a variable of type `Object?` promotes
  // it, but applying `!` to a variable of type `dynamic` doesn't promote it.)
  {
    var y = x._f.first;
    y!;
    [y].expectStaticType<Exactly<List<Object>>>();
  }
}

// When the result of a type test is cached in a boolean variable and later
// recalled, a promotion to one type may be layered over a promotion to another
// type, even if the two types are mutual subtypes.
testBooleanVariable(Object? x) {
  var b = x is List<Object?>;
  x.expectStaticType<Exactly<Object?>>();
  x as List<dynamic>;
  x.expectStaticType<Exactly<List<dynamic>>>();
  // Verify that the type really is `List<dynamic>` and not `List<Object?>`.
  x.first.abs();
  if (b) {
    // The promotion to `List<Object?>`, captured at the declaration site of
    // `b`, is layered over the promotion to `List<dynamic>`. But since the
    // two types are mutual subtypes, the promotion to `List<Object?>` is
    // discarded, leaving only the promotion to `List<dynamic>`.
    x.expectStaticType<Exactly<List<dynamic>>>();
    // Verify that the type really is `List<dynamic>` and not `List<Object?>`.
    x.first.abs();
  }
}

main() {
  testAs([0], [0]);
  testIs([0], [0]);
  testIsNot([0], [0]);
  testTypeOfInterest([0]);
  testFinallyClauseVariable([0]);
  testFinallyClausePropertyOfUnmodifiedVariable(C([0]));
  testFinallyClausePropertyOfModifiedVariable(C([0]), C([0]));
  testBooleanVariable([0]);
}
