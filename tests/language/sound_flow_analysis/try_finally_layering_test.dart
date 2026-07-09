// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests how flow analysis layers promotions from `try` and `finally` blocks
// when `sound-flow-analysis` is enabled.

import '../static_type_helper.dart';

class C {
  final Object _f;
  C(this._f);
}

// For local variables that are not assigned in the `try` block, promotions in
// the `finally` block are layered over promotions in the `try` block.
void testUnassignedLocal(bool b, Object x, Object y) {
  if (b) {
    x as num;
    y as num;
    // The promotion chains for `x` and `y` are both `[num]`.
    x.expectStaticType<Exactly<num>>();
    y.expectStaticType<Exactly<num>>();
  } else {
    try {
      x as num;
      y as int;
      x.expectStaticType<Exactly<num>>();
      y.expectStaticType<Exactly<int>>();
    } finally {
      // Neither `x` nor `y` is promoted at this point, because in principle an
      // exception could have occurred at any point in the `try` block.
      x.expectStaticType<Exactly<Object>>();
      y.expectStaticType<Exactly<Object>>();
      x as int;
      y as num;
    }
    // After the try/finally, both `x` and `y` are fully promoted to `int`.
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    // But since the promotions from the `finally` block are layered over the
    // promotions from the `try` block, `x` has promotion chain `[num, int]`,
    // whereas `y` has promotion chain `[int]`. Therefore, after the `if` and
    // `else` control flow paths are joined...
  }
  // `x` is promoted to `num` (since `[num]` and `[num, int]` both contain the
  // type `num`), whereas `y` is no longer promoted at all (since `[num]` and
  // `[int]` have no types in common).
  x.expectStaticType<Exactly<num>>();
  y.expectStaticType<Exactly<Object>>();
}

// For local variables that are assigned in the `try` block, promotions in the
// `finally` block are layered over promotions in the `try` block.
void testAssignedLocal(bool b, Object x, Object y) {
  if (b) {
    x as num;
    y as num;
    // The promotion chains for `x` and `y` are both `[num]`.
    x.expectStaticType<Exactly<num>>();
    y.expectStaticType<Exactly<num>>();
  } else {
    try {
      (x, y) = (y, x);
      x as num;
      y as int;
      x.expectStaticType<Exactly<num>>();
      y.expectStaticType<Exactly<int>>();
    } finally {
      // Neither `x` nor `y` is promoted at this point, because in principle an
      // exception could have occurred at any point in the `try` block.
      x.expectStaticType<Exactly<Object>>();
      y.expectStaticType<Exactly<Object>>();
      x as int;
      y as num;
    }
    // After the try/finally, both `x` and `y` are fully promoted to `int`.
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    // But since the promotions from the `finally` block are layered over the
    // promotions from the `try` block, `x` has promotion chain `[num, int]`,
    // whereas `y` has promotion chain `[int]`. Therefore, after the `if` and
    // `else` control flow paths are joined...
  }
  // `x` is promoted to `num` (since `[num]` and `[num, int]` both contain the
  // type `num`), whereas `y` is no longer promoted at all (since `[num]` and
  // `[int]` have no types in common).
  x.expectStaticType<Exactly<num>>();
  y.expectStaticType<Exactly<Object>>();
}

// For fields of local variables that are not assigned in the `try` block,
// promotions in the `finally` block are layered over promotions in the `try`
// block.
void testUnassignedField(bool b, C x, C y) {
  if (b) {
    x._f as num;
    y._f as num;
    // The promotion chains for `x._f` and `y._f` are both `[num]`.
    x._f.expectStaticType<Exactly<num>>();
    y._f.expectStaticType<Exactly<num>>();
  } else {
    try {
      x._f as num;
      y._f as int;
      x._f.expectStaticType<Exactly<num>>();
      y._f.expectStaticType<Exactly<int>>();
    } finally {
      // Neither `x._f` nor `y._f` is promoted at this point, because in
      // principle an exception could have occurred at any point in the `try`
      // block.
      x._f.expectStaticType<Exactly<Object>>();
      y._f.expectStaticType<Exactly<Object>>();
      x._f as int;
      y._f as num;
    }
    // After the try/finally, both `x._f` and `y._f` are fully promoted to
    // `int`.
    x._f.expectStaticType<Exactly<int>>();
    y._f.expectStaticType<Exactly<int>>();
    // But since the promotions from the `finally` block are layered over the
    // promotions from the `try` block, `x._f` has promotion chain `[num, int]`,
    // whereas `y._f` has promotion chain `[int]`. Therefore, after the `if` and
    // `else` control flow paths are joined...
  }
  // `x._f` is promoted to `num` (since `[num]` and `[num, int]` both contain
  // the type `num`), whereas `y._f` is no longer promoted at all (since `[num]`
  // and `[int]` have no types in common).
  x._f.expectStaticType<Exactly<num>>();
  y._f.expectStaticType<Exactly<Object>>();
}

// For fields of local variables that are assigned in the `try` block,
// promotions in the `finally` block are layered over promotions in the `try`
// block.
void testAssignedField(bool b, C x, C y) {
  if (b) {
    x._f as num;
    y._f as num;
    // The promotion chains for `x._f` and `y._f` are both `[num]`.
    x._f.expectStaticType<Exactly<num>>();
    y._f.expectStaticType<Exactly<num>>();
  } else {
    try {
      (x, y) = (y, x);
      x._f as num;
      y._f as int;
      x._f.expectStaticType<Exactly<num>>();
      y._f.expectStaticType<Exactly<int>>();
    } finally {
      // Neither `x._f` nor `y._f` is promoted at this point, because in
      // principle an exception could have occurred at any point in the `try`
      // block.
      x._f.expectStaticType<Exactly<Object>>();
      y._f.expectStaticType<Exactly<Object>>();
      x._f as int;
      y._f as num;
    }
    // After the try/finally, both `x._f` and `y._f` are fully promoted to
    // `int`.
    x._f.expectStaticType<Exactly<int>>();
    y._f.expectStaticType<Exactly<int>>();
    // But since the promotions from the `finally` block are layered over the
    // promotions from the `try` block, `x._f` has promotion chain `[num, int]`,
    // whereas `y._f` has promotion chain `[int]`. Therefore, after the `if` and
    // `else` control flow paths are joined...
  }
  // `x._f` is promoted to `num` (since `[num]` and `[num, int]` both contain
  // the type `num`), whereas `y._f` is no longer promoted at all (since `[num]`
  // and `[int]` have no types in common).
  x._f.expectStaticType<Exactly<num>>();
  y._f.expectStaticType<Exactly<Object>>();
}

main() {
  for (var b in [false, true]) {
    testUnassignedLocal(b, 0, 0);
    testAssignedLocal(b, 0, 0);
    testUnassignedField(b, C(0), C(0));
    testAssignedField(b, C(0), C(0));
  }
}
