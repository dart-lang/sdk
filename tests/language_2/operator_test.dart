// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class OperatorTest {
  static int i1, i2;

  OperatorTest() {}

  static testMain() {
    var op1 = new Operator(1);
    var op2 = new Operator(2);
    Expect.equals(3, op1 + op2);
    Expect.equals(-1, op1 - op2);
    Expect.equals(0.5, op1 / op2);
    Expect.equals(0, op1 ~/ op2);
    Expect.equals(2, op1 * op2);
    Expect.equals(1, op1 % op2);
    Expect.equals(true, !(op1 == op2));
    Expect.equals(true, op1 < op2);
    Expect.equals(true, !(op1 > op2));
    Expect.equals(true, op1 <= op2);
    Expect.equals(true, !(op1 >= op2));
    Expect.equals(3, (op1 | op2));
    Expect.equals(3, (op1 ^ op2));
    Expect.equals(0, (op1 & op2));
    Expect.equals(4, (op1 << op2));
    Expect.equals(0, (op1 >> op2));
    Expect.equals(-1, -op1);

    op1.value += op2.value;
    Expect.equals(3, op1.value);

    op2.value += (op2.value += op2.value);
    Expect.equals(6, op2.value);

    op2.value -= (op2.value -= op2.value);
    Expect.equals(6, op2.value);

    op1.value = op2.value = 42;
    Expect.equals(42, op1.value);
    Expect.equals(42, op2.value);

    i1 = i2 = 42;
    Expect.equals(42, i1);
    Expect.equals(42, i2);
    i1 += 7;
    Expect.equals(49, i1);
    i1 += (i2 = 17);
    Expect.equals(66, i1);
    Expect.equals(17, i2);

    i1 += i2 += 3;
    Expect.equals(86, i1);
    Expect.equals(20, i2);
  }
}

class Operator {
  int value;

  Operator(int i) {
    value = i;
  }

  operator +(Operator other) {
    return value + other.value;
  }

  operator -(Operator other) {
    return value - other.value;
  }

  operator /(Operator other) {
    return value / other.value;
  }

  operator *(Operator other) {
    return value * other.value;
  }

  operator %(Operator other) {
    return value % other.value;
  }

  operator ==(dynamic other) {
    return value == other.value;
  }

  operator <(Operator other) {
    return value < other.value;
  }

  operator >(Operator other) {
    return value > other.value;
  }

  operator <=(Operator other) {
    return value <= other.value;
  }

  operator >=(Operator other) {
    return value >= other.value;
  }

  operator |(Operator other) {
    return value | other.value;
  }

  operator ^(Operator other) {
    return value ^ other.value;
  }

  operator &(Operator other) {
    return value & other.value;
  }

  operator <<(Operator other) {
    return value << other.value;
  }

  operator >>(Operator other) {
    return value >> other.value;
  }

  operator ~/(Operator other) {
    return value ~/ other.value;
  }

  operator -() {
    return -value;
  }
}

main() {
  OperatorTest.testMain();
}
