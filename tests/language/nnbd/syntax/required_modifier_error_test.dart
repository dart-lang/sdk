// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Invalid uses of "required" modifier.

// Use a language version pre-primary constructors to allow `final` parameter.
// @dart = 3.11

required int f1(
  // [error column 1, length 8]
  // [cfe] Can't have modifier 'required' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  required int x,
  // [error column 3, length 8]
  // [cfe] Can't have modifier 'required' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
) => throw 0;

required class C1 {
  // [error column 1, length 8]
  // [cfe] Can't have modifier 'required' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  required int f2 = 0;
  // [error column 3, length 8]
  // [cfe] Can't have modifier 'required' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
}

// Duplicate modifier
void f2({
  required required int i,
  // [error column 3, length 8]
  // [cfe] Can't have modifier 'required' here.
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  //       ^^^^^^^^
  // [cfe] The modifier 'required' was already specified.
  // [analyzer] SYNTACTIC_ERROR.DUPLICATED_MODIFIER
}) {}

// Out of order modifiers
class C2 {
  void m({
    required int i1,
    covariant required int? i2,
    //        ^^^^^^^^
    // [cfe] The modifier 'required' should be before the modifier 'covariant'.
    // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
    final required int? i3,
    //    ^^^^^^^^
    // [cfe] The modifier 'required' should be before the modifier 'final'.
    // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  }) {}
}

main() {}
