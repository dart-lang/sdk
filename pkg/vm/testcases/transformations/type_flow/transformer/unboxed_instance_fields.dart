// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool kTrue = int.parse('1') == 1 ? true : false;
final bool kFalse = int.parse('1') == 2 ? true : false;
int get mint => 0xaabbccddaabbccdd;
int get smiOrMint => kTrue ? 1 : mint;
dynamic usedObject;

void use(dynamic object) {
  usedObject ??= object;
}

class X {}

class A {
  dynamic unboxedSmi;
  dynamic unboxedInt;
  dynamic unboxedDouble;
  dynamic boxedNullableInt;
  dynamic boxedNullableDouble;
  dynamic boxedNonNullableIntOrDouble;
  dynamic boxedNullableIntOrDouble;
  dynamic boxedNullableX;
  dynamic boxedX;

  A(
      this.unboxedSmi,
      this.unboxedInt,
      this.unboxedDouble,
      this.boxedNullableInt,
      this.boxedNullableDouble,
      this.boxedNonNullableIntOrDouble,
      this.boxedNullableIntOrDouble,
      this.boxedNullableX,
      this.boxedX);
}

main() {
  final a = A(
      kTrue ? 1 : 2,
      kTrue ? smiOrMint : 2,
      kTrue ? 1.1 : 2.2,
      kTrue ? smiOrMint : null,
      kTrue ? 1.1 : null,
      kTrue ? smiOrMint : 1.1,
      kTrue ? (kFalse ? smiOrMint : 1.1) : null,
      kTrue ? X() : null,
      X());

  a.unboxedSmi = kTrue ? 1 : 2;
  a.unboxedInt = kTrue ? smiOrMint : 2;
  a.unboxedDouble = kTrue ? 1.1 : 2.2;
  a.boxedNullableInt = kTrue ? smiOrMint : null;
  a.boxedNullableDouble = kTrue ? 1.1 : null;
  a.boxedNonNullableIntOrDouble = kTrue ? smiOrMint : 1.1;
  a.boxedNullableIntOrDouble = kTrue ? (kFalse ? smiOrMint : 1.1) : null;
  a.boxedNullableX = kTrue ? X() : null;
  a.boxedX = X();

  use(a.unboxedSmi);
  use(a.unboxedInt);
  use(a.unboxedDouble);
  use(a.boxedNullableInt);
  use(a.boxedNullableDouble);
  use(a.boxedNonNullableIntOrDouble);
  use(a.boxedNullableIntOrDouble);
  use(a.boxedNullableX);
  use(a.boxedX);
}
