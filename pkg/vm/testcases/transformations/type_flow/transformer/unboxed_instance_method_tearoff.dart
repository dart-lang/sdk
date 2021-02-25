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

abstract class Interface {
  void takePositional(
      int unboxedSmi,
      dynamic unboxedInt,
      dynamic unboxedDouble,
      dynamic boxedNullableInt,
      dynamic boxedNullableDouble,
      dynamic boxedNonNullableIntOrDouble,
      dynamic boxedNullableIntOrDouble,
      dynamic boxedNullableX,
      dynamic boxedX);

  dynamic returnUnboxedSmi(X ignored);
  dynamic returnUnboxedInt(X ignored);
  dynamic returnUnboxedDouble(X ignored);
  dynamic returnBoxedNullableInt(X ignored);
  dynamic returnBoxedNullableDouble(X ignored);
  dynamic returnBoxedIntOrDouble(X ignored);
  dynamic returnBoxedNullableIntOrDouble(X ignored);
  dynamic returnBoxedNullableX(X ignored);
  dynamic returnBoxedX(X ignored);
}

class Impl1 implements Interface {
  void takePositional(
      int unboxedSmi,
      dynamic unboxedInt,
      dynamic unboxedDouble,
      dynamic boxedNullableInt,
      dynamic boxedNullableDouble,
      dynamic boxedNonNullableIntOrDouble,
      dynamic boxedNullableIntOrDouble,
      dynamic boxedNullableX,
      dynamic boxedX) {
    use(unboxedInt);
    use(unboxedDouble);
    use(boxedNullableInt);
    use(boxedNullableDouble);
    use(boxedNonNullableIntOrDouble);
    use(boxedNullableIntOrDouble);
    use(boxedNullableX);
    use(boxedX);
  }

  dynamic returnUnboxedSmi(X ignored) => 1;
  dynamic returnUnboxedInt(X ignored) => 1;
  dynamic returnUnboxedDouble(X ignored) => 1.1;
  dynamic returnBoxedNullableInt(X ignored) => null;
  dynamic returnBoxedNullableDouble(X ignored) => null;
  dynamic returnBoxedIntOrDouble(X ignored) => 1;
  dynamic returnBoxedNullableIntOrDouble(X ignored) => null;
  dynamic returnBoxedNullableX(X ignored) => null;
  dynamic returnBoxedX(X ignored) => X();
}

class BaseImpl2 {
  void takePositional(
      int unboxedSmi,
      dynamic unboxedInt,
      dynamic unboxedDouble,
      dynamic boxedNullableInt,
      dynamic boxedNullableDouble,
      dynamic boxedNonNullableIntOrDouble,
      dynamic boxedNullableIntOrDouble,
      dynamic boxedNullableX,
      dynamic boxedX) {
    use(unboxedInt);
    use(unboxedDouble);
    use(boxedNullableInt);
    use(boxedNullableDouble);
    use(boxedNonNullableIntOrDouble);
    use(boxedNullableIntOrDouble);
    use(boxedNullableX);
    use(boxedX);
  }

  dynamic returnUnboxedSmi(X ignored) => 2;
  dynamic returnUnboxedInt(X ignored) => mint;
  dynamic returnUnboxedDouble(X ignored) => 2.2;
  dynamic returnBoxedNullableInt(X ignored) => 2;
  dynamic returnBoxedNullableDouble(X ignored) => 2.2;
  dynamic returnBoxedIntOrDouble(X ignored) => 2.2;
  dynamic returnBoxedNullableIntOrDouble(X ignored) => 2;
  dynamic returnBoxedNullableX(X ignored) => X();
  dynamic returnBoxedX(X ignored) => X();
}

class SubImpl3 extends BaseImpl2 implements Interface {
  void takePositional(
      int unboxedSmi,
      dynamic unboxedInt,
      dynamic unboxedDouble,
      dynamic boxedNullableInt,
      dynamic boxedNullableDouble,
      dynamic boxedNonNullableIntOrDouble,
      dynamic boxedNullableIntOrDouble,
      dynamic boxedNullableX,
      dynamic boxedX) {
    use(unboxedInt);
    use(unboxedDouble);
    use(boxedNullableInt);
    use(boxedNullableDouble);
    use(boxedNonNullableIntOrDouble);
    use(boxedNullableIntOrDouble);
    use(boxedNullableX);
    use(boxedX);
  }

  dynamic returnUnboxedSmi(X ignored) => 3;
  dynamic returnUnboxedInt(X ignored) => mint;
  dynamic returnUnboxedDouble(X ignored) => 3.3;
  dynamic returnBoxedNullableInt(X ignored) => mint;
  dynamic returnBoxedNullableDouble(X ignored) => 3.3;
  dynamic returnBoxedIntOrDouble(X ignored) => 3.3;
  dynamic returnBoxedNullableIntOrDouble(X ignored) => 3.3;
  dynamic returnBoxedNullableX(X ignored) => X();
  dynamic returnBoxedX(X ignored) => X();
}

main() {
  final values = [Impl1(), BaseImpl2(), SubImpl3()];

  final a = values[int.parse('0')] as Impl1;
  final b = values[int.parse('1')] as BaseImpl2;
  final c = values[int.parse('2')] as SubImpl3;
  final d = values[int.parse('2')] as Interface;

  a.takePositional(1, 1, 1.1, null, null, 1, null, null, X());
  b.takePositional(2, 2, 2.2, 2, 2.2, 2.2, 2, X(), X());
  c.takePositional(3, mint, 3.3, mint, 3.3, 3.3, 3.3, X(), X());
  d.takePositional(3, mint, 3.3, mint, 3.3, 3.3, 3.3, X(), X());

  use(a.returnUnboxedSmi(null));
  use(a.returnUnboxedInt(null));
  use(a.returnUnboxedDouble(null));
  use(a.returnBoxedNullableInt(null));
  use(a.returnBoxedNullableDouble(null));
  use(a.returnBoxedIntOrDouble(null));
  use(a.returnBoxedNullableIntOrDouble(null));
  use(a.returnBoxedNullableX(null));
  use(a.returnBoxedX(null));

  use(b.returnUnboxedSmi(null));
  use(b.returnUnboxedInt(null));
  use(b.returnUnboxedDouble(null));
  use(b.returnBoxedNullableInt(null));
  use(b.returnBoxedNullableDouble(null));
  use(b.returnBoxedIntOrDouble(null));
  use(b.returnBoxedNullableIntOrDouble(null));
  use(b.returnBoxedNullableX(null));
  use(b.returnBoxedX(null));

  use(c.returnUnboxedSmi(null));
  use(c.returnUnboxedInt(null));
  use(c.returnUnboxedDouble(null));
  use(c.returnBoxedNullableInt(null));
  use(c.returnBoxedNullableDouble(null));
  use(c.returnBoxedIntOrDouble(null));
  use(c.returnBoxedNullableIntOrDouble(null));
  use(c.returnBoxedNullableX(null));
  use(c.returnBoxedX(null));

  use(d.returnUnboxedSmi(null));
  use(d.returnUnboxedInt(null));
  use(d.returnUnboxedDouble(null));
  use(d.returnBoxedNullableInt(null));
  use(d.returnBoxedNullableDouble(null));
  use(d.returnBoxedIntOrDouble(null));
  use(d.returnBoxedNullableIntOrDouble(null));
  use(d.returnBoxedNullableX(null));
  use(d.returnBoxedX(null));

  // Use as tear-offs.
  use(d.takePositional);
  use(d.returnUnboxedSmi);
  use(d.returnUnboxedInt);
  use(d.returnUnboxedDouble);
  use(d.returnBoxedNullableInt);
  use(d.returnBoxedNullableDouble);
  use(d.returnBoxedIntOrDouble);
  use(d.returnBoxedNullableIntOrDouble);
  use(d.returnBoxedNullableX);
  use(d.returnBoxedX);
}
