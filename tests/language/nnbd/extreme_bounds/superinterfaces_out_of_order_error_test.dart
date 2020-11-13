// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

// Test that upper bound computations which rely on the computations of the
// cardinality of the superinterface sets define those sets without erasing or
// modifying the superinterfaces.

import 'superinterfaces_legacy_lib.dart';
import 'superinterfaces_null_safe_lib.dart';

/// Test that `Legacy()` has the super-interface sets:
/// {Legacy}, {Generic<int*>}, {Root}
/// and that `NonNullable()` has the super-interface sets:
/// {NonNullable}, {Generic<int>}, {Root}
/// And hence that the highest shared super-interface set of cardinality one
/// is {Root}.
/// As a result, the upper bound of `Legacy()` and `NonNullable()` should
/// be computed as `Root`.
void testLegacyNonNullable(bool b) {
  // Test in the presence of a downward context
  {
    // The type of the conditional is not Generic
    Generic<int> x0 = b ? Legacy() : NonNullable();
    //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                  ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.

    // The type of the conditional is not inferred as Generic
    Generic<int> x1 = (b ? Legacy() : NonNullable())..genericMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                                ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // The type of the conditional not inferred as Legacy, nor dynamic
    Generic<int> x2 = (b ? Legacy() : NonNullable())..legacyMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                                ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'legacyMethod' isn't defined for the class 'Root'.

    // The type of the conditional is not inferred as NonNullable, nor dynamic
    Generic<int> x3 = (b ? Legacy() : NonNullable())..nonNullableMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                                ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nonNullableMethod' isn't defined for the class 'Root'.
  }

  // Test without a context
  {
    var x = b ? Legacy() : NonNullable();

    // x is inferred to be Root
    x.rootMethod();

    // x is not inferred to be Generic
    x.genericMethod();
    //^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // x is not inferred as Legacy, nor dynamic
    x.legacyMethod();
    //^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'legacyMethod' isn't defined for the class 'Root'.

    // x is not inferred as NonNullable, nor dynamic
    x.nonNullableMethod();
    //^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nonNullableMethod' isn't defined for the class 'Root'.
  }

  // Test using instances

  // Test in the presence of a downward context
  {
    // The type of the conditional is not Generic
    Generic<int> x0 = b ? legacy : nonNullable;
    //                ^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                  ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.

    // The type of the conditional is not inferred as Generic
    Generic<int> x1 = (b ? legacy : nonNullable)..genericMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                            ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // The type of the conditional not inferred as Legacy, nor dynamic
    Generic<int> x2 = (b ? legacy : nonNullable)..legacyMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                            ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'legacyMethod' isn't defined for the class 'Root'.

    // The type of the conditional is not inferred as NonNullable, nor dynamic
    Generic<int> x3 = (b ? legacy : nonNullable)..nonNullableMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                            ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nonNullableMethod' isn't defined for the class 'Root'.

  }

  // Test without a context
  {
    var x = b ? legacy : nonNullable;

    // x is inferred to be Root
    x.rootMethod();

    // x is not inferred to be Generic
    x.genericMethod();
    //^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // x is not inferred as Legacy, nor dynamic
    x.legacyMethod();
    //^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'legacyMethod' isn't defined for the class 'Root'.

    // x is not inferred as NonNullable, nor dynamic
    x.nonNullableMethod();
    //^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nonNullableMethod' isn't defined for the class 'Root'.
  }
}

/// Test that `Legacy()` has the super-interface sets:
/// {Legacy}, {Generic<int*>}, {Root}
/// and that `Nullable()` has the super-interface sets:
/// {Nullable}, {Generic<int?>}, {Root}
/// And hence that the highest shared super-interface set of cardinality one
/// is {Root}.
/// As a result, the upper bound of `Legacy()` and `Nullable()` should
/// be computed as `Root`.
void testLegacyNullable(bool b) {
  // Test in the presence of a downward context
  {
    // The type of the conditional is not Generic
    Generic<int> x0 = b ? Legacy() : Nullable();
    //                ^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                  ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.

    // The type of the conditional is not inferred as Generic
    Generic<int> x1 = (b ? Legacy() : Nullable())..genericMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                             ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // The type of the conditional not inferred as Legacy, nor dynamic
    Generic<int> x2 = (b ? Legacy() : Nullable())..legacyMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                             ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'legacyMethod' isn't defined for the class 'Root'.

    // The type of the conditional is not inferred as Nullable, nor dynamic
    Generic<int> x3 = (b ? Legacy() : Nullable())..nullableMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                             ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nullableMethod' isn't defined for the class 'Root'.
  }

  // Test without a context
  {
    var x = b ? Legacy() : Nullable();

    // x is inferred to be Root
    x.rootMethod();

    // x is not inferred to be Generic
    x.genericMethod();
    //^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // x is not inferred as Legacy, nor dynamic
    x.legacyMethod();
    //^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'legacyMethod' isn't defined for the class 'Root'.

    // x is not inferred as Nullable, nor dynamic
    x.nullableMethod();
    //^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nullableMethod' isn't defined for the class 'Root'.
  }

  // Test using instances

  // Test in the presence of a downward context
  {
    // The type of the conditional is not Generic
    Generic<int> x0 = b ? legacy : nullable;
    //                ^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                  ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.

    // The type of the conditional is not inferred as Generic
    Generic<int> x1 = (b ? legacy : nullable)..genericMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                         ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // The type of the conditional not inferred as Legacy, nor dynamic
    Generic<int> x2 = (b ? legacy : nullable)..legacyMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                         ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'legacyMethod' isn't defined for the class 'Root'.

    // The type of the conditional is not inferred as Nullable, nor dynamic
    Generic<int> x3 = (b ? legacy : nullable)..nullableMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                         ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nullableMethod' isn't defined for the class 'Root'.
  }

  // Test without a context
  {
    var x = b ? legacy : nullable;

    // x is inferred to be Root
    x.rootMethod();

    // x is not inferred to be Generic
    x.genericMethod();
    //^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // x is not inferred as Legacy, nor dynamic
    x.legacyMethod();
    //^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'legacyMethod' isn't defined for the class 'Root'.

    // x is not inferred as Nullable, nor dynamic
    x.nullableMethod();
    //^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nullableMethod' isn't defined for the class 'Root'.
  }
}

/// Test that `Nullable()` has the super-interface sets:
/// {Nullable}, {Generic<int?>}, {Root}
/// and that `NonNullable()` has the super-interface sets:
/// {NonNullable}, {Generic<int>}, {Root}
/// And hence that the highest shared super-interface set of cardinality one
/// is {Root}.
/// As a result, the upper bound of `Nullable()` and `NonNullable()` should
/// be computed as `Root`.
void testNullableNonNullable(bool b) {
  // Test in the presence of a downward context
  {
    // The type of the conditional is not Generic
    Generic<int> x0 = b ? Nullable() : NonNullable();
    //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                  ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.

    // The type of the conditional is Generic<int>
    Generic<int> x1 = (b ? Nullable() : NonNullable())..genericMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                                  ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // The type of the conditional not inferred as Nullable, nor dynamic
    Generic<int> x2 = (b ? Nullable() : NonNullable())..nullableMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                                  ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nullableMethod' isn't defined for the class 'Root'.

    // The type of the conditional is not inferred as NonNullable, nor dynamic
    Generic<int> x3 = (b ? Nullable() : NonNullable())..nonNullableMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                                  ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nonNullableMethod' isn't defined for the class 'Root'.

  }

  // Test without a context
  {
    var x = b ? Nullable() : NonNullable();

    // x is inferred to be Root
    x.rootMethod();

    // x is not inferred to be Generic, nor dynamic
    x.genericMethod();
    //^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // x is not inferred as Nullable, nor dynamic
    x.nullableMethod();
    //^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nullableMethod' isn't defined for the class 'Root'.

    // x is not inferred as NonNullable, nor dynamic
    x.nonNullableMethod();
    //^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nonNullableMethod' isn't defined for the class 'Root'.
  }

  // Test using instances

  // Test in the presence of a downward context
  {
    // The type of the conditional is not Generic
    Generic<int> x0 = b ? nullable : nonNullable;
    //                ^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                  ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.

    // The type of the conditional is Generic<int>
    Generic<int> x1 = (b ? nullable : nonNullable)..genericMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                              ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // The type of the conditional not inferred as Nullable, nor dynamic
    Generic<int> x2 = (b ? nullable : nonNullable)..nullableMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                              ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nullableMethod' isn't defined for the class 'Root'.

    // The type of the conditional is not inferred as NonNullable, nor dynamic
    Generic<int> x3 = (b ? nullable : nonNullable)..nonNullableMethod();
    //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                   ^
    // [cfe] A value of type 'Root' can't be assigned to a variable of type 'Generic<int>'.
    //                                              ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nonNullableMethod' isn't defined for the class 'Root'.

  }

  // Test without a context
  {
    var x = b ? nullable : nonNullable;

    // x is inferred to be Root
    x.rootMethod();

    // x is not inferred to be Generic, nor dynamic
    x.genericMethod();
    //^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'genericMethod' isn't defined for the class 'Root'.

    // x is not inferred as Nullable, nor dynamic
    x.nullableMethod();
    //^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nullableMethod' isn't defined for the class 'Root'.

    // x is not inferred as NonNullable, nor dynamic
    x.nonNullableMethod();
    //^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'nonNullableMethod' isn't defined for the class 'Root'.
  }
}

void main() {
  testLegacyNonNullable(true);
  testLegacyNullable(true);
  testNullableNonNullable(true);
}
