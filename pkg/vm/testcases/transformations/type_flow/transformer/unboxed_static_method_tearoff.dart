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

void takePositional(
    int unboxedSmi,
    dynamic unboxedInt,
    dynamic unboxedDouble,
    dynamic boxedNullableInt,
    dynamic boxedNullableDouble,
    dynamic boxedIntOrDouble,
    dynamic boxedNullableIntOrDouble,
    dynamic boxedNullableX,
    dynamic boxedX) {
  use(unboxedInt);
  use(unboxedDouble);
  use(boxedNullableInt);
  use(boxedNullableDouble);
  use(boxedIntOrDouble);
  use(boxedNullableIntOrDouble);
  use(boxedNullableX);
  use(boxedX);
}

void takeOptional(
    [int unboxedSmi,
    dynamic unboxedInt,
    dynamic unboxedDouble,
    dynamic boxedNullableInt,
    dynamic boxedNullableDouble,
    dynamic boxedIntOrDouble,
    dynamic boxedNullableIntOrDouble,
    dynamic boxedNullableX,
    dynamic boxedX]) {
  use(unboxedInt);
  use(unboxedDouble);
  use(boxedNullableInt);
  use(boxedNullableDouble);
  use(boxedIntOrDouble);
  use(boxedNullableIntOrDouble);
  use(boxedNullableX);
  use(boxedX);
}

void takeNamed(
    {int unboxedSmi,
    dynamic unboxedInt,
    dynamic unboxedDouble,
    dynamic boxedNullableInt,
    dynamic boxedNullableDouble,
    dynamic boxedIntOrDouble,
    dynamic boxedNullableIntOrDouble,
    dynamic boxedNullableX,
    dynamic boxedX}) {
  use(unboxedInt);
  use(unboxedDouble);
  use(boxedNullableInt);
  use(boxedNullableDouble);
  use(boxedIntOrDouble);
  use(boxedNullableIntOrDouble);
  use(boxedNullableX);
  use(boxedX);
}

dynamic returnUnboxedSmi() => kTrue ? 1 : 2;
dynamic returnUnboxedInt() => kTrue ? smiOrMint : 2;
dynamic returnUnboxedDouble() => kTrue ? 1.1 : 2.2;
dynamic returnBoxedNullableInt() => kTrue ? smiOrMint : null;
dynamic returnBoxedNullableDouble() => kTrue ? 1.1 : null;
dynamic returnBoxedIntOrDouble() => kTrue ? smiOrMint : 1.1;
dynamic returnBoxedNullableIntOrDouble() =>
    kTrue ? (kFalse ? smiOrMint : 1.1) : null;
dynamic returnBoxedNullableX() => kTrue ? X() : null;
dynamic returnBoxedX() => X();

main() {
  takePositional(
      kTrue ? 1 : 2,
      kTrue ? smiOrMint : 2,
      kTrue ? 1.1 : 2.2,
      kTrue ? smiOrMint : null,
      kTrue ? 1.1 : null,
      kTrue ? smiOrMint : 1.1,
      kTrue ? (kFalse ? smiOrMint : 1.1) : null,
      kTrue ? X() : null,
      X());

  takeOptional(
      kTrue ? 1 : 2,
      kTrue ? smiOrMint : 2,
      kTrue ? 1.1 : 2.2,
      kTrue ? smiOrMint : null,
      kTrue ? 1.1 : null,
      kTrue ? smiOrMint : 1.1,
      kTrue ? (kFalse ? smiOrMint : 1.1) : null,
      kTrue ? X() : null,
      X());

  takeNamed(
      unboxedSmi: kTrue ? 1 : 2,
      unboxedInt: kTrue ? smiOrMint : 2,
      unboxedDouble: kTrue ? 1.1 : 2.2,
      boxedNullableInt: kTrue ? smiOrMint : null,
      boxedNullableDouble: kTrue ? 1.1 : null,
      boxedIntOrDouble: kTrue ? smiOrMint : 1.1,
      boxedNullableIntOrDouble: kTrue ? (kFalse ? smiOrMint : 1.1) : null,
      boxedNullableX: kTrue ? X() : null,
      boxedX: X());

  use(returnUnboxedSmi());
  use(returnUnboxedInt());
  use(returnUnboxedDouble());
  use(returnBoxedNullableInt());
  use(returnBoxedNullableDouble());
  use(returnBoxedIntOrDouble());
  use(returnBoxedNullableIntOrDouble());
  use(returnBoxedNullableX());
  use(returnBoxedX());

  // Use as tear-offs.
  use(takePositional);
  use(takeOptional);
  use(takeNamed);
  use(returnUnboxedSmi);
  use(returnUnboxedInt);
  use(returnUnboxedDouble);
  use(returnBoxedNullableInt);
  use(returnBoxedNullableDouble);
  use(returnBoxedIntOrDouble);
  use(returnBoxedNullableIntOrDouble);
  use(returnBoxedNullableX);
  use(returnBoxedX);
}
