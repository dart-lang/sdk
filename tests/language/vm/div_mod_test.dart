// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

// Unit tests on DIV and MOV operations by various constants.

import "package:expect/expect.dart";

import 'dart:core';

int kMin = 0x8000000000000000;
int kMax = 0x7fffffffffffffff;

// The basic DIV operation.
int divme(int? x, int c) {
  return x! ~/ c;
}

// The basic MOD operation.
int modme(int? x, int c) {
  return x! % c;
}

//
// Test several "hidden" DIV constants.
//

@pragma("vm:never-inline")
int div0(int x) {
  return divme(x, 0);
}

@pragma("vm:never-inline")
int div1(int x) {
  return divme(x, 1);
}

@pragma("vm:never-inline")
int divm1(int x) {
  return divme(x, -1);
}

@pragma("vm:never-inline")
int div2(int? x) {
  return divme(x, 2);
}

@pragma("vm:never-inline")
int divm2(int x) {
  return divme(x, -2);
}

@pragma("vm:never-inline")
int div37(int x) {
  return divme(x, 37);
}

@pragma("vm:never-inline")
int div131(int x) {
  return divme(x, 131);
}

@pragma("vm:never-inline")
int divm333(int x) {
  return divme(x, -333);
}

@pragma("vm:never-inline")
int divmin(int x) {
  return divme(x, kMin);
}

@pragma("vm:never-inline")
int divmax(int x) {
  return divme(x, kMax);
}

//
// Test several "hidden" MOD constants.
//

@pragma("vm:never-inline")
int mod0(int x) {
  return modme(x, 0);
}

@pragma("vm:never-inline")
int mod1(int x) {
  return modme(x, 1);
}

@pragma("vm:never-inline")
int modm1(int x) {
  return modme(x, -1);
}

@pragma("vm:never-inline")
int mod2(int? x) {
  return modme(x, 2);
}

@pragma("vm:never-inline")
int modm2(int x) {
  return modme(x, -2);
}

@pragma("vm:never-inline")
int mod37(int x) {
  return modme(x, 37);
}

@pragma("vm:never-inline")
int mod131(int x) {
  return modme(x, 131);
}

@pragma("vm:never-inline")
int modm333(int x) {
  return modme(x, -333);
}

@pragma("vm:never-inline")
int modmin(int x) {
  return modme(x, kMin);
}

@pragma("vm:never-inline")
int modmax(int x) {
  return modme(x, kMax);
}

main() {
  // Exceptional case DIV.
  for (int i = -1; i <= 1; i++) {
    bool threw = false;
    try {
      div0(i);
    } on IntegerDivisionByZeroException catch (e) {
      threw = true;
    }
    Expect.isTrue(threw);
  }

  // Exceptional case MOD.
  for (int i = -1; i <= 1; i++) {
    bool threw = false;
    try {
      mod0(i);
    } on IntegerDivisionByZeroException catch (e) {
      threw = true;
    }
    Expect.isTrue(threw);
  }

  // DIV by +/- 1.
  Expect.equals(kMin, div1(kMin));
  Expect.equals(kMin, divm1(kMin));
  for (int i = -999; i <= 999; i++) {
    Expect.equals(i, div1(i));
    Expect.equals(-i, divm1(i));
  }
  Expect.equals(kMax, div1(kMax));
  Expect.equals(-kMax, divm1(kMax));

  // MOD by +/- 1.
  Expect.equals(0, mod1(kMin));
  Expect.equals(0, modm1(kMin));
  for (int i = -999; i <= 999; i++) {
    Expect.equals(0, mod1(i));
    Expect.equals(0, modm1(i));
  }
  Expect.equals(0, mod1(kMax));
  Expect.equals(0, modm1(kMax));

  // DIV by +/- 2.
  Expect.equals(-4611686018427387904, div2(kMin));
  Expect.equals(-4611686018427387903, div2(kMin + 1));
  Expect.equals(-4611686018427387903, div2(kMin + 2));
  Expect.equals(4611686018427387904, divm2(kMin));
  Expect.equals(4611686018427387903, divm2(kMin + 1));
  Expect.equals(4611686018427387903, divm2(kMin + 2));
  for (int i = -999; i <= 999; i++) {
    int e = (i + ((i < 0) ? 1 : 0)) >> 1;
    Expect.equals(e, div2(i));
    Expect.equals(-e, divm2(i));
  }
  Expect.equals(4611686018427387903, div2(kMax));
  Expect.equals(4611686018427387903, div2(kMax - 1));
  Expect.equals(4611686018427387902, div2(kMax - 2));
  Expect.equals(-4611686018427387903, divm2(kMax));
  Expect.equals(-4611686018427387903, divm2(kMax - 1));
  Expect.equals(-4611686018427387902, divm2(kMax - 2));

  // MOD by +/- 2.
  Expect.equals(0, mod2(kMin));
  Expect.equals(1, mod2(kMin + 1));
  Expect.equals(0, mod2(kMin + 2));
  Expect.equals(0, modm2(kMin));
  Expect.equals(1, modm2(kMin + 1));
  Expect.equals(0, modm2(kMin + 2));
  for (int i = -999; i <= 999; i++) {
    Expect.equals(i & 1, mod2(i));
    Expect.equals(i & 1, modm2(i));
  }
  Expect.equals(1, mod2(kMax));
  Expect.equals(0, mod2(kMax - 1));
  Expect.equals(1, mod2(kMax - 2));
  Expect.equals(1, modm2(kMax));
  Expect.equals(0, modm2(kMax - 1));
  Expect.equals(1, modm2(kMax - 2));

  // DIV/MOD by 37.
  Expect.equals(-249280325320399346, div37(kMin));
  Expect.equals(31, mod37(kMin));
  for (int i = -999; i <= 999; i++) {
    Expect.equals(i, div37(37 * i));
    Expect.equals(i, div37(37 * i + ((i >= 0) ? 36 : -36)));
    Expect.equals(0, mod37(37 * i));
    Expect.equals(1, mod37(37 * i + 1));
    Expect.equals(36, mod37(37 * i + 36));
  }
  for (int i = 1; i < 37; i++) {
    Expect.equals(0, div37(i));
    Expect.equals(i, mod37(i));
    Expect.equals(0, div37(-i));
    Expect.equals(37 - i, mod37(-i));
  }
  Expect.equals(249280325320399346, div37(kMax));
  Expect.equals(5, mod37(kMax));

  // DIV/MOD by 131.
  Expect.equals(-70407420128662410, div131(kMin));
  Expect.equals(33, mod131(kMin));
  for (int i = -999; i <= 999; i++) {
    Expect.equals(i, div131(131 * i));
    Expect.equals(i, div131(131 * i + ((i >= 0) ? 130 : -130)));
    Expect.equals(0, mod131(131 * i));
    Expect.equals(1, mod131(131 * i + 1));
    Expect.equals(130, mod131(131 * i + 130));
  }
  for (int i = 1; i < 131; i++) {
    Expect.equals(0, div131(i));
    Expect.equals(i, mod131(i));
    Expect.equals(0, div131(-i));
    Expect.equals(131 - i, mod131(-i));
  }
  Expect.equals(70407420128662410, div131(kMax));
  Expect.equals(97, mod131(kMax));

  // DIV/MOD by -333.
  Expect.equals(27697813924488816, divm333(kMin));
  Expect.equals(253, modm333(kMin));
  for (int i = -999; i <= 999; i++) {
    Expect.equals(i, divm333(-333 * i));
    Expect.equals(i, divm333(-333 * i + ((i < 0) ? 130 : -130)));
    Expect.equals(0, modm333(-333 * i));
    Expect.equals(1, modm333(-333 * i + 1));
    Expect.equals(130, modm333(-333 * i + 130));
  }
  Expect.equals(-27697813924488816, divm333(kMax));
  Expect.equals(79, modm333(kMax));

  // DIV/MOD by Min.
  Expect.equals(1, divmin(kMin));
  Expect.equals(0, modmin(kMin));
  for (int i = -999; i <= 999; i++) {
    Expect.equals(0, divmin(i));
    Expect.equals(i >= 0 ? i : 1 + kMax + i, modmin(i));
  }
  Expect.equals(0, divmin(kMax));
  Expect.equals(kMax, modmin(kMax));

  // DIV/MOD by Max.
  Expect.equals(-1, divmax(kMin));
  Expect.equals(kMax - 1, modmax(kMin));
  for (int i = -999; i <= 999; i++) {
    Expect.equals(0, divmax(i));
    Expect.equals(i >= 0 ? i : kMax + i, modmax(i));
  }
  Expect.equals(1, divmax(kMax));
  Expect.equals(0, modmax(kMax));

  // Exceptional null value MOD.
  bool threwDiv = false;
  try {
    div2(null);
  } on TypeError catch (e) {
    threwDiv = true;
  }
  Expect.isTrue(threwDiv);

  // Exceptional null value MOD.
  bool threwMod = false;
  try {
    mod2(null);
  } on TypeError catch (e) {
    threwMod = true;
  }
  Expect.isTrue(threwMod);
}
