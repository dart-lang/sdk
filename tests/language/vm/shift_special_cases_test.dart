// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Test for special cases of << and >> integer operations with int64.

import "package:expect/expect.dart";

// int64 value, does not fit to smi
int v1 = 0x778899aabbccddee;
int v2 = 0x6000000000000000;
int v3 = -0x778899aabbccddee;
int negativeInt64 = -0x7000000000000000;
int smi = 128;
int negativeSmi = -3;

int shl(int a, int b) => a << b;
int shr(int a, int b) => a >> b;

int shlUint32(int a, int b) => ((a & 0xffff) << b) & 0xffff;
int shrUint32(int a, int b) => (a & 0xffff) >> b;

void testInt64ShlByNegative1(int a, int b) {
  int x = a + 1;
  int y = a - 2;
  try {
    x = a << b;
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0x778899aabbccddef, x);
    Expect.equals(0x778899aabbccddec, y);
  }
}

void testInt64ShlByNegative2(int a, int b) {
  int x = a + 1;
  int y = a - 2;
  try {
    x = shl(a, b);
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0x778899aabbccddef, x);
    Expect.equals(0x778899aabbccddec, y);
  }
}

void testInt64ShlByNegative3(int a) {
  int x = a + 1;
  int y = a - 2;
  try {
    int i = -64;
    x = a << i;
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0x778899aabbccddef, x);
    Expect.equals(0x778899aabbccddec, y);
  }
}

void testInt64ShrByNegative1(int a, int b) {
  int x = a + 1;
  int y = a - 2;
  try {
    x = a >> b;
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0x778899aabbccddef, x);
    Expect.equals(0x778899aabbccddec, y);
  }
}

void testInt64ShrByNegative2(int a, int b) {
  int x = a + 1;
  int y = a - 2;
  try {
    x = shr(a, b);
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0x778899aabbccddef, x);
    Expect.equals(0x778899aabbccddec, y);
  }
}

void testInt64ShrByNegative3(int a) {
  int x = a + 1;
  int y = a - 2;
  try {
    int i = -64;
    x = a >> i;
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0x778899aabbccddef, x);
    Expect.equals(0x778899aabbccddec, y);
  }
}

void testInt64ShlByLarge1(int a, int b) {
  int x = a << b;
  Expect.equals(0, x);
}

void testInt64ShlByLarge2(int a) {
  int i = 64;
  int x = a << i;
  Expect.equals(0, x);
}

void testInt64ShlByLarge3(int a) {
  int i = 0x7fffffffffffffff;
  int x = a << i;
  Expect.equals(0, x);
}

void testInt64ShrByLarge1a(int a, int b) {
  int x = a >> b;
  Expect.equals(0, x);
}

void testInt64ShrByLarge1b(int a, int b) {
  int x = a >> b;
  Expect.equals(-1, x);
}

void testInt64ShrByLarge2a(int a) {
  int i = 64;
  int x = a >> i;
  Expect.equals(0, x);
}

void testInt64ShrByLarge2b(int a) {
  int i = 64;
  int x = a >> i;
  Expect.equals(-1, x);
}

void testInt64ShrByLarge3a(int a) {
  int i = 0x7fffffffffffffff;
  int x = a >> i;
  Expect.equals(0, x);
}

void testInt64ShrByLarge3b(int a) {
  int i = 0x7fffffffffffffff;
  int x = a >> i;
  Expect.equals(-1, x);
}

void testUint32ShlByNegative1(int a, int b) {
  int x = (a & 0xfff) + 1;
  int y = (a & 0xfff) - 2;
  try {
    x = ((a & 0xffff) << b) & 0xffff;
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0xdef, x);
    Expect.equals(0xdec, y);
  }
}

void testUint32ShlByNegative2(int a, int b) {
  int x = (a & 0xfff) + 1;
  int y = (a & 0xfff) - 2;
  try {
    x = shlUint32(a, b);
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0xdef, x);
    Expect.equals(0xdec, y);
  }
}

void testUint32ShlByNegative3(int a) {
  int x = (a & 0xfff) + 1;
  int y = (a & 0xfff) - 2;
  try {
    int i = -64;
    x = ((a & 0xffff) << i) & 0xffff;
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0xdef, x);
    Expect.equals(0xdec, y);
  }
}

void testUint32ShrByNegative1(int a, int b) {
  int x = (a & 0xfff) + 1;
  int y = (a & 0xfff) - 2;
  try {
    x = ((a & 0xffff) >> b) & 0xffff;
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0xdef, x);
    Expect.equals(0xdec, y);
  }
}

void testUint32ShrByNegative2(int a, int b) {
  int x = (a & 0xfff) + 1;
  int y = (a & 0xfff) - 2;
  try {
    x = shrUint32(a, b);
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0xdef, x);
    Expect.equals(0xdec, y);
  }
}

void testUint32ShrByNegative3(int a) {
  int x = (a & 0xfff) + 1;
  int y = (a & 0xfff) - 2;
  try {
    int i = -64;
    x = ((a & 0xffff) >> i) & 0xffff;
    Expect.fail('Shift by negative count should throw an error');
  } on ArgumentError {
    Expect.equals(0xdef, x);
    Expect.equals(0xdec, y);
  }
}

void testUint32ShlByLarge1(int a, int b) {
  int x = ((a & 0xffff) << b) & 0xffff;
  Expect.equals(0, x);
}

void testUint32ShlByLarge2(int a) {
  int i = 64;
  int x = ((a & 0xffff) << i) & 0xffff;
  Expect.equals(0, x);
}

void testUint32ShlByLarge3(int a) {
  int i = 0x7fffffffffffffff;
  int x = ((a & 0xffff) << i) & 0xffff;
  Expect.equals(0, x);
}

void testUint32ShrByLarge1(int a, int b) {
  int x = ((a & 0xffff) >> b) & 0xffff;
  Expect.equals(0, x);
}

void testUint32ShrByLarge2(int a) {
  int i = 64;
  int x = ((a & 0xffff) >> i) & 0xffff;
  Expect.equals(0, x);
}

void testUint32ShrByLarge3(int a) {
  int i = 0x7fffffffffffffff;
  int x = ((a & 0xffff) >> i) & 0xffff;
  Expect.equals(0, x);
}

doTests1() {
  testInt64ShlByNegative1(v1, negativeSmi);
  testInt64ShlByNegative2(v1, negativeSmi);
  testInt64ShlByNegative3(v1);

  testInt64ShrByNegative1(v1, negativeSmi);
  testInt64ShrByNegative2(v1, negativeSmi);
  testInt64ShrByNegative3(v1);

  testInt64ShlByLarge1(v1, smi);
  testInt64ShlByLarge1(v3, smi);

  testInt64ShlByLarge2(v1);
  testInt64ShlByLarge2(v3);

  testInt64ShlByLarge3(v1);
  testInt64ShlByLarge3(v3);

  testInt64ShrByLarge1a(v1, smi);
  testInt64ShrByLarge1b(v3, smi);

  testInt64ShrByLarge2a(v1);
  testInt64ShrByLarge2b(v3);

  testInt64ShrByLarge3a(v1);
  testInt64ShrByLarge3b(v3);

  testUint32ShlByNegative1(v1, negativeSmi);
  testUint32ShlByNegative2(v1, negativeSmi);
  testUint32ShlByNegative3(v1);

  testUint32ShrByNegative1(v1, negativeSmi);
  testUint32ShrByNegative2(v1, negativeSmi);
  testUint32ShrByNegative3(v1);

  testUint32ShlByLarge1(v1, smi);
  testUint32ShlByLarge1(v3, smi);

  testUint32ShlByLarge2(v1);
  testUint32ShlByLarge2(v3);

  testUint32ShlByLarge3(v1);
  testUint32ShlByLarge3(v3);

  testUint32ShrByLarge1(v1, smi);
  testUint32ShrByLarge1(v3, smi);

  testUint32ShrByLarge2(v1);
  testUint32ShrByLarge2(v3);

  testUint32ShrByLarge3(v1);
  testUint32ShrByLarge3(v3);
}

doTests2() {
  testInt64ShlByNegative1(v1, negativeInt64);
  testInt64ShlByNegative2(v1, negativeInt64);

  testInt64ShrByNegative1(v1, negativeInt64);
  testInt64ShrByNegative2(v1, negativeInt64);

  testInt64ShlByLarge1(v1, v2);
  testInt64ShlByLarge1(v3, v2);

  testInt64ShrByLarge1a(v1, v2);
  testInt64ShrByLarge1b(v3, v2);

  testUint32ShlByNegative1(v1, negativeInt64);
  testUint32ShlByNegative2(v1, negativeInt64);

  testUint32ShrByNegative1(v1, negativeInt64);
  testUint32ShrByNegative2(v1, negativeInt64);

  testUint32ShlByLarge1(v1, v2);
  testUint32ShlByLarge1(v3, v2);

  testUint32ShrByLarge1(v1, v2);
  testUint32ShrByLarge1(v3, v2);
}

main() {
  for (var i = 0; i < 20; ++i) {
    doTests1();
  }
  for (var i = 0; i < 50; ++i) {
    doTests2();
  }
}
