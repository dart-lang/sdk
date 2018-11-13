// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:math';

final int maxInt32 = 2147483647;
final int minInt32 = -2147483648;

doZeros() {
  Expect.equals(1, pow(0, 0));
  Expect.equals(0, pow(0, 1));
  Expect.equals(0, pow(0, 2));
  Expect.equals(0, pow(0, 3));
  Expect.equals(0, pow(0, 4));
  Expect.equals(0, pow(0, 5));
  Expect.equals(0, pow(0, 45));
  Expect.equals(0, pow(0, maxInt32 - 1));
  Expect.equals(0, pow(0, maxInt32));

  Expect.equals(double.infinity, pow(0, -1));
  Expect.equals(double.infinity, pow(0, -2));
  Expect.equals(double.infinity, pow(0, minInt32));
}

doOnes() {
  Expect.equals(1, pow(1, 0));
  Expect.equals(1, pow(1, 1));
  Expect.equals(1, pow(1, 2));
  Expect.equals(1, pow(1, 3));
  Expect.equals(1, pow(1, 4));
  Expect.equals(1, pow(1, 5));
  Expect.equals(1, pow(1, 45));
  Expect.equals(1, pow(1, maxInt32 - 1));
  Expect.equals(1, pow(1, maxInt32));

  Expect.equals(1.0, pow(1, -1));
  Expect.equals(1.0, pow(1, -2));
  Expect.equals(1.0, pow(1, minInt32));
}

doMinOnes() {
  Expect.equals(1, pow(-1, 0));
  Expect.equals(-1, pow(-1, 1));
  Expect.equals(1, pow(-1, 2));
  Expect.equals(-1, pow(-1, 3));
  Expect.equals(1, pow(-1, 4));
  Expect.equals(-1, pow(-1, 5));
  Expect.equals(-1, pow(-1, 45));
  Expect.equals(1, pow(-1, maxInt32 - 1));
  Expect.equals(-1, pow(-1, maxInt32));

  Expect.equals(-1.0, pow(-1, -1));
  Expect.equals(1.0, pow(-1, -2));
  Expect.equals(1.0, pow(-1, minInt32));
}

doTwos() {
  Expect.equals(1, pow(2, 0));
  Expect.equals(2, pow(2, 1));
  Expect.equals(4, pow(2, 2));
  Expect.equals(8, pow(2, 3));
  Expect.equals(16, pow(2, 4));
  Expect.equals(32, pow(2, 5));
  Expect.equals(32768, pow(2, 15));
  Expect.equals(65536, pow(2, 16));
  Expect.equals(35184372088832, pow(2, 45));
  Expect.equals(0, pow(2, maxInt32 - 1));
  Expect.equals(0, pow(2, maxInt32));

  Expect.equals(0.5, pow(2, -1));
  Expect.equals(0.25, pow(2, -2));
  Expect.equals(0.0, pow(2, minInt32));
}

doMinTwos() {
  Expect.equals(1, pow(-2, 0));
  Expect.equals(-2, pow(-2, 1));
  Expect.equals(4, pow(-2, 2));
  Expect.equals(-8, pow(-2, 3));
  Expect.equals(16, pow(-2, 4));
  Expect.equals(-32, pow(-2, 5));
  Expect.equals(-32768, pow(-2, 15));
  Expect.equals(65536, pow(-2, 16));
  Expect.equals(-35184372088832, pow(-2, 45));
  Expect.equals(0, pow(-2, maxInt32 - 1));
  Expect.equals(0, pow(-2, maxInt32));

  Expect.equals(-0.5, pow(-2, -1));
  Expect.equals(0.25, pow(-2, -2));
  Expect.equals(0.0, pow(-2, minInt32));
}

doVar0() {
  int d = 0;
  for (int i = -10; i < 10; i++) {
    d += pow(i, 0);
  }
  Expect.equals(20, d);
}

doVar1() {
  int d = 0;
  for (int i = -10; i < 10; i++) {
    d += pow(i, 1);
  }
  Expect.equals(-10, d);
}

doVar2() {
  int d = 0;
  for (int i = -10; i < 10; i++) {
    d += pow(i, 2);
  }
  Expect.equals(670, d);
}

doVar3() {
  int d = 0;
  for (int i = -10; i < 10; i++) {
    d += pow(i, 3);
  }
  Expect.equals(-1000, d);
}

doVar4() {
  int d = 0;
  for (int i = -10; i < 10; i++) {
    d += pow(i, 4);
  }
  Expect.equals(40666, d);
}

doVar5() {
  int d = 0;
  for (int i = -10; i < 10; i++) {
    d += pow(i, 5);
  }
  Expect.equals(-100000, d);
}

doVarMax() {
  int d = 0;
  for (int i = -5; i < 10; i++) {
    d += pow(i, maxInt32);
  }
  Expect.equals(1786231423019973616, d);
}

doVarZeroes() {
  int d = 0;
  for (int i = 0; i < 10; i++) {
    d += pow(0, i);
  }
  Expect.equals(1, d);
}

doVarOnes() {
  int d = 0;
  for (int i = 0; i < 10; i++) {
    d += pow(1, i);
  }
  Expect.equals(10, d);
}

doVarTwos() {
  int d = 0;
  for (int i = 0; i < 10; i++) {
    d += pow(2, i);
  }
  Expect.equals(1023, d);
}

main() {
  doZeros();
  doOnes();
  doMinOnes();
  doTwos();
  doMinTwos();
  doVar0();
  doVar1();
  doVar2();
  doVar3();
  doVar4();
  doVar5();
  doVarMax();
  doVarZeroes();
  doVarOnes();
  doVarTwos();
}
