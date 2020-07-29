// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

// @dart = 2.8

// Test that upper bound computations which rely on the computations of the
// cardinality of the superinterface sets define those sets using
// `LEGACY_ERASURE` when called from an opted out library.

import 'superinterfaces_null_safe_lib.dart';
import 'superinterfaces_legacy_lib.dart';

/// Test that `Legacy()` has the super-interface sets:
/// {Legacy}, {Generic<int*>}, {Root}
/// and that `NonNullable()` has the super-interface sets:
/// {NonNullable}, {Generic<int*>}, {Root} (due to LEGACY_ERASURE)
/// And hence that the highest shared super-interface set of cardinality one
/// is {Generic<int*>}.
/// As a result, the upper bound of `Legacy()` and `NonNullable()` should
/// be computed as `Generic<int*>`.
void testLegacyNonNullable(bool b) {
  // Test in the presence of a downward context
  {
    Generic<int> x0 = b ? Legacy() : NonNullable();

    // The type of the conditional is Generic<int>
    Generic<int> x1 = (b ? Legacy() : NonNullable())..genericMethod();

    // The type of the conditional not inferred as Legacy, nor dynamic
    Generic<int> x2 = (b ? Legacy() : NonNullable())..legacyMethod();
    //                                                ^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // The type of the conditional is not inferred as NonNullable, nor dynamic
    Generic<int> x3 = (b ? Legacy() : NonNullable())..nonNullableMethod();
    //                                                ^^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Test without a context
  {
    var x = b ? Legacy() : NonNullable();

    // x is inferred to be Generic<int>
    x.genericMethod().isEven;

    // x is not inferred to be Generic<dynamic>
    x.genericMethod().isVeryOdd;
    //                ^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as Legacy, nor dynamic
    x.legacyMethod();
    //^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as NonNullable, nor dynamic
    x.nonNullableMethod();
    //^^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Test using instances

  // Test in the presence of a downward context
  {
    Generic<int> x0 = b ? legacy : nonNullable;

    // The type of the conditional is Generic<int>
    Generic<int> x1 = (b ? legacy : nonNullable)..genericMethod();

    // The type of the conditional not inferred as Legacy, nor dynamic
    Generic<int> x2 = (b ? legacy : nonNullable)..legacyMethod();
    //  ^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // The type of the conditional is not inferred as NonNullable, nor dynamic
    Generic<int> x3 = (b ? legacy : nonNullable)..nonNullableMethod();
    //  ^^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Test without a context
  {
    var x = b ? legacy : nonNullable;

    // x is inferred to be Generic<int>
    x.genericMethod().isEven;

    // x is not inferred to be Generic<dynamic>
    x.genericMethod().isVeryOdd;
    //                ^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as Legacy, nor dynamic
    x.legacyMethod();
    //^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as NonNullable, nor dynamic
    x.nonNullableMethod();
    //^^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

/// Test that `Legacy()` has the super-interface sets:
/// {Legacy}, {Generic<int*>}, {Root}
/// and that `Nullable()` has the super-interface sets:
/// {Nullable}, {Generic<int*>}, {Root} (due to LEGACY_ERASURE)
/// And hence that the highest shared super-interface set of cardinality one
/// is {Generic<int*>}.
/// As a result, the upper bound of `Legacy()` and `Nullable()` should
/// be computed as `Generic<int*>`.
void testLegacyNullable(bool b) {
  // Test in the presence of a downward context
  {
    Generic<int> x0 = b ? Legacy() : Nullable();

    // The type of the conditional is Generic<int>
    Generic<int> x1 = (b ? Legacy() : Nullable())..genericMethod();

    // The type of the conditional not inferred as Legacy, nor dynamic
    Generic<int> x2 = (b ? Legacy() : Nullable())..legacyMethod();
    //                                             ^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // The type of the conditional is not inferred as Nullable, nor dynamic
    Generic<int> x3 = (b ? Legacy() : Nullable())..nullableMethod();
    //                                             ^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Test without a context
  {
    var x = b ? Legacy() : Nullable();

    // x is inferred to be Generic<int>
    x.genericMethod().isEven;

    // x is not inferred to be Generic<dynamic>
    x.genericMethod().isVeryOdd;
    //                ^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as Legacy, nor dynamic
    x.legacyMethod();
    //^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as Nullable, nor dynamic
    x.nullableMethod();
    //^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Test using instances

  // Test in the presence of a downward context
  {
    Generic<int> x0 = b ? legacy : nullable;

    // The type of the conditional is Generic<int>
    Generic<int> x1 = (b ? legacy : nullable)..genericMethod();

    // The type of the conditional not inferred as Legacy, nor dynamic
    Generic<int> x2 = (b ? legacy : nullable)..legacyMethod();
    //                                                         ^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // The type of the conditional is not inferred as Nullable, nor dynamic
    Generic<int> x3 = (b ? legacy : nullable)..nullableMethod();
    //                                                         ^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Test without a context
  {
    var x = b ? legacy : nullable;

    // x is inferred to be Generic<int>
    x.genericMethod().isEven;

    // x is not inferred to be Generic<dynamic>
    x.genericMethod().isVeryOdd;
    //                ^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as Legacy, nor dynamic
    x.legacyMethod();
    //^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as Nullable, nor dynamic
    x.nullableMethod();
    //^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

/// Test that `Nullable()` has the super-interface sets:
/// {Nullable}, {Generic<int*>}, {Root} (due to LEGACY_ERASURE)
/// and that `NonNullable()` has the super-interface sets:
/// {NonNullable}, {Generic<int>}, {Root}
/// And hence that the highest shared super-interface set of cardinality one
/// is {Generic<int*>}.
/// As a result, the upper bound of `Nullable()` and `NonNullable()` should
/// be computed as `Generic<int*>`.
void testNullableNonNullable(bool b) {
  // Test in the presence of a downward context
  {
    Generic<int> x0 = b ? Nullable() : NonNullable();

    // The type of the conditional is Generic<int>
    Generic<int> x1 = (b ? Nullable() : NonNullable())..genericMethod();

    // The type of the conditional not inferred as Nullable, nor dynamic
    Generic<int> x2 = (b ? Nullable() : NonNullable())..nullableMethod();
    //                                                  ^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // The type of the conditional is not inferred as NonNullable, nor dynamic
    Generic<int> x3 = (b ? Nullable() : NonNullable())..nonNullableMethod();
    //                                                  ^^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Test without a context
  {
    var x = b ? Nullable() : NonNullable();

    // x is inferred to be Generic<int>
    x.genericMethod().isEven;

    // x is not inferred to be Generic<dynamic>
    x.genericMethod().isVeryOdd;
    //                ^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as Nullable, nor dynamic
    x.nullableMethod();
    //^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as NonNullable, nor dynamic
    x.nonNullableMethod();
    //^^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Test using instances

  // Test in the presence of a downward context
  {
    Generic<int> x0 = b ? nullable : nonNullable;

    // The type of the conditional is Generic<int>
    Generic<int> x1 = (b ? nullable : nonNullable)..genericMethod();

    // The type of the conditional not inferred as Nullable, nor dynamic
    Generic<int> x2 = (b ? nullable : nonNullable)..nullableMethod();
    //  ^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // The type of the conditional is not inferred as NonNullable, nor dynamic
    Generic<int> x3 = (b ? nullable : nonNullable)..nonNullableMethod();
    //  ^^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // Test without a context
  {
    var x = b ? nullable : nonNullable;

    // x is inferred to be Generic<int>
    x.genericMethod().isEven;

    // x is not inferred to be Generic<dynamic>
    x.genericMethod().isVeryOdd;
    //                ^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as Nullable, nor dynamic
    x.nullableMethod();
    //^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // x is not inferred as NonNullable, nor dynamic
    x.nonNullableMethod();
    //^^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

void main() {
  testLegacyNonNullable(true);
  testLegacyNullable(true);
  testNullableNonNullable(true);
}
