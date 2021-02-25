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

abstract class BI1 {
  int get value;
}

class BI1A implements BI1 {
  final int value;
  BI1A(this.value);
}

class BI1B implements BI1 {
  int get value => null;
}

abstract class BI2 {
  int get value;
}

class BI2A implements BI2 {
  final int value;
  BI2A(this.value);
}

class BI2B implements BI2 {
  int get value => smiOrMint;
}

abstract class BI3 {
  int get value;
  set value(int value);
}

class BI3A implements BI3 {
  int value;
  BI3A(this.value);
}

class BI3B implements BI3 {
  int get value => smiOrMint;
  set value(int v) {}
}

abstract class UBI {
  int value;
}

class UBIA implements UBI {
  int value;
  UBIA(this.value);
}

class UBIB implements UBI {
  int get value => smiOrMint;
  set value(int v) {}
}

main() {
  // Getter return value needs to be boxed due to BI1B.value returning `null`.
  final bi1a = BI1A(smiOrMint);
  final bi1b = BI1B(); // getter returns null
  use((kTrue ? bi1a : bi1b).value);

  // Getter return value needs to be boxed due to BI2A.value returning `null`.
  final bi2a = BI2A(null);
  final bi2b = BI2B(); // getter returns smiOrMint
  use((kTrue ? bi2a : bi2b).value);

  // Getter return value needs to be boxed due to setter being called with
  // `null` value.
  final bi3a = BI3A(smiOrMint);
  final bi3b = BI3B(); // getter returns smiOrMint
  (kTrue ? bi3a : bi3b).value = null;
  use((kTrue ? bi3a : bi3b).value);

  // Getter return value can be unboxed, both UBIA.value / UBIB.value return
  // non-nullable int.
  final ubia = UBIA(smiOrMint);
  final ubib = UBIB(); // getter returns smiOrMint
  use((kTrue ? ubia : ubib).value);
}
