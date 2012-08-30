// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A test to compare the results of the fixnum library with the Dart VM

#library('int64vmtest');
#import('dart:math', prefix: 'Math');
#source('../intx.dart');
#source('../int32.dart');
#source('../int64.dart');

void main() {
  int64VMTest test = new int64VMTest();
  test.doTestBinary(new BinaryOp("&", (a, b) => a & b));
  test.doTestBinary(new BinaryOp("|", (a, b) => a | b));
  test.doTestBinary(new BinaryOp("^", (a, b) => a ^ b));
  test.doTestBinary(new BinaryOp("+", (a, b) => a + b));
  test.doTestBinary(new BinaryOp("-", (a, b) => a - b));
  test.doTestBinary(new BinaryOp("*", (a, b) => a * b));
  test.doTestUnary(new UnaryOp("-", (a) => -a));
  test.doTestUnary(new UnaryOp("~", (a) => ~a));
  test.doTestShift(new ShiftOp("<<", (a, n) => a << (n & 63)));
  test.doTestShift(new ShiftOp(">>", (a, n) => a >> (n & 63)));
  test.doTestBoolean(new BooleanOp("compareTo", (a, b) => a.compareTo(b)));
  test.doTestBoolean(new BooleanOp("==", (a, b) => a == b));
  test.doTestBoolean(new BooleanOp("!=", (a, b) => a != b));
  test.doTestBoolean(new BooleanOp("<", (a, b) => a < b));
  test.doTestBoolean(new BooleanOp("<=", (a, b) => a <= b));
  test.doTestBoolean(new BooleanOp(">", (a, b) => a > b));
  test.doTestBoolean(new BooleanOp(">=", (a, b) => a >= b));
  test.doTestBinary(new BinaryOp("%", (a, b) => a % b));
  test.doTestBinary(new BinaryOp("~/", (a, b) => a ~/ b));
  test.doTestBinary(new BinaryOp("remainder", (a, b) => a.remainder(b)));
}

final int DISCARD = 0;

int64 _randomInt64() {
  int i = 0;
  for (int b = 0; b < 64; b++) {
      double rand = Math.random();
      for (int j = 0; j < DISCARD; j++) {
        rand = Math.random();
      }
      i = (i << 1) | ((rand > 0.5) ? 1 : 0);
  }
  return new int64.fromInt(i);
}

int _randomInt(int n) {
  double rand = Math.random();
  for (int i = 0; i < DISCARD; i++) {
    rand = Math.random();
  }
  return (rand * n).floor().toInt();
}

class Op {
  String name;
  Function op;

  Op(String this.name, Function this.op);

  // Truncate x to a value in the range [-2^63, 2^63 - 1]
  int trunc64(int x) {
    int trunc = x & 0xffffffffffffffff;
    if ((trunc & 0x8000000000000000) != 0) {
      trunc -= 18446744073709551616; // 2^64
    }
    return trunc;
  }
}

class UnaryOp extends Op {
  UnaryOp(String name, Function op) : super(name, op);
  int ref(int val) => trunc64(op(val));
  int64 test(int64 val) => op(val);
}

class BinaryOp extends Op {
  BinaryOp(String name, Function op) : super(name, op);
  int ref(int val0, int val1) => trunc64(op(val0, val1));
  int64 test(int64 val0, int64 val1) => op(val0, val1);
}

class BooleanOp extends Op {
  BooleanOp(String name, Function op) : super(name, op);
  bool ref(int val0, int val1) => op(val0, val1);
  bool test(int64 val0, int64 val1) => op(val0, val1);
}

class ShiftOp extends Op {
  ShiftOp(String name, Function op) : super(name, op);
  int ref(int val0, int shift) => trunc64(op(val0, shift));
  int64 test(int64 val0, int shift) => op(val0, shift);
}

class int64VMTest {
  static final int BASE_VALUES = 32;
  static final int RANDOM_TESTS = 32;
  List<int64> TEST_VALUES;
  
  int64VMTest() {
    Set<int64> testSet = new Set<int64>();
    for (int i = 0; i < BASE_VALUES; i++) {
      testSet.add(new int64.fromInt(i));
      testSet.add(new int64.fromInt(-i));

      testSet.add(int64.MIN_VALUE + i);
      testSet.add(int64.MAX_VALUE - i);

      testSet.add(new int64.fromInt(i << int64._BITS ~/ 2));
      testSet.add(new int64.fromInt(i << int64._BITS));
      testSet.add(new int64.fromInt(i << (3 * int64._BITS) ~/ 2));
      testSet.add(new int64.fromInt(i << 2 * int64._BITS));
      testSet.add(new int64.fromInt(i << (5 * int64._BITS) ~/ 2));
    }

    int64 one = new int64.fromInt(1);
    int64 three = new int64.fromInt(3);
    int64 ones = int64.parseHex("1111111111111111");
    int64 tens = int64.parseHex("1010101010101010");
    int64 oh_ones = int64.parseHex("0101010101010101");
    int64 digits = int64.parseHex("123456789ABCDEFF");
    for (int i = 0; i < 16; i++) {
      testSet.add(ones * i);
      testSet.add(~(ones * i));
      testSet.add(-(ones * i));
      testSet.add(tens * i);
      testSet.add(~(tens * i));
      testSet.add(-(tens * i));
      testSet.add(oh_ones * i);
      testSet.add(~(oh_ones * i));
      testSet.add(-(oh_ones * i));
      testSet.add(digits * i);
      testSet.add(~(digits * i));
      testSet.add(-(digits * i));
    }

    for (int i = 0; i < 64; i += 4) {
      testSet.add(one << i);
      testSet.add(~(one << i));
      testSet.add(digits >> i);
      testSet.add(-(digits >> i));

      // Powers of two and nearby numbers
      testSet.add(one << i);
      for (int j = 1; j <= 16; j++) {
        testSet.add((one << i) + j);
        testSet.add(-((one << i) + j));
        testSet.add(~((one << i) + j));
        testSet.add((one << i) - j);
        testSet.add(-((one << i) - j));
        testSet.add(~((one << i) - j));
        testSet.add((three << i) + j);
        testSet.add(-((three << i) + j));
        testSet.add(~((three << i) + j));
        testSet.add((three << i) - j);
        testSet.add(-((three << i) - j));
        testSet.add(~((three << i) - j));
      }
    }

    for (int a = 0; a < 19; a++) {
      // Math.pow(10, a)
      int pow = 1;
      for (int j = 0; j < a; j++) {
        pow *= 10;
      }
      testSet.add(new int64.fromInt(pow));
    }

    TEST_VALUES = new List<int64>(testSet.length);
    int index = 0;
    for (int64 val in testSet) {
      TEST_VALUES[index++] = val;
    }

    print("VALUES.length = $index");
  }

  void _doTestUnary(UnaryOp op, int64 val) {
    int ref = op.ref(val.toInt());
    int64 result64 = op.test(val);
    int result = result64.toInt();
    if (ref != result) {
      Expect.fail("${op.name}: val = $val");
    }
  }

  void doTestUnary(UnaryOp op) {
    print("Testing operator ${op.name}");
    for (int i = 0; i < TEST_VALUES.length; i++) {
      _doTestUnary(op, TEST_VALUES[i]);
    }
    for (int i = 0; i < RANDOM_TESTS; i++) {
      int64 randomLong = _randomInt64();
      _doTestUnary(op, randomLong);
    }
  }

  void _doTestBinary(BinaryOp op, int64 val0, int64 val1) {
    // print("Test val0 = $val0, val1 = $val1");
    var refException = null;
    int ref = -1;
    try {
      ref = op.ref(val0.toInt(), val1.toInt());
    } on Exception catch (e) {
      refException = e;
    }
    var testException = null;
    int result = -2;
    int64 result64;
    try {
      int64 val0_save = new int64._copy(val0);
      int64 val1_save = new int64._copy(val1);
      result64 = op.test(val0, val1);
      result = result64.toInt();
      if (val0 != val0_save) {
        print(
            "Test altered first argument val0 = $val0, val0_save = $val0_save");
      }
      if (val1 != val1_save) {
        print("Test altered second argument");
      }
    } on Exception catch (e) {
      testException = e;
    }
    if (testException is IntegerDivisionByZeroException &&
        refException is IntegerDivisionByZeroException) {
    } else if (testException != null || refException != null) {
      Expect.fail("${op.name}: val0 = $val0, val1 = $val1, "
          "testException = $testException, refException = $refException");
      return;
    } else if (ref != result) {
      if ("%" == op.name && ref < 0) {
        // print("Dart VM bug: ${op.name}: val0 = $val0, val1 = $val1, "
        //    "ref = $ref, result64 = $result64, result = $result");
      } else {
        Expect.fail("${op.name}: val0 = $val0, val1 = $val1, "
            "ref = $ref, result64 = $result64, result = $result");
      }
    }
  }

  void doTestBinary(BinaryOp op) {
    print("Testing operator ${op.name}");
    for (int i = 0; i < TEST_VALUES.length; i++) {
      int64 randomLong = _randomInt64();
      _doTestBinary(op, TEST_VALUES[i], randomLong);
      _doTestBinary(op, randomLong, TEST_VALUES[i]);
      for (int j = 0; j < TEST_VALUES.length; j++) {
        _doTestBinary(op, TEST_VALUES[i], TEST_VALUES[j]);
      }
    }
    for (int i = 0; i < RANDOM_TESTS; i++) {
      int64 longVal0 = _randomInt64();
      int64 longVal1 = _randomInt64();
      if (_randomInt(20) == 0) {
        if (_randomInt(2) == 0) {
          longVal1 = longVal0;
        } else {
          longVal1 = -longVal0;
        }
      }
      _doTestBinary(op, longVal0, longVal1);
    }
  }

  void _doTestBoolean(BooleanOp op, int64 val0, int64 val1) {
    bool ref = op.ref(val0.toInt(), val1.toInt());
    bool result = op.test(val0, val1);
    if (ref != result) {
      Expect.fail("${op.name}: val0 = $val0, val1 = $val1");
    }
  }
  
  void doTestBoolean(BooleanOp op) {
    print("Testing operator ${op.name}");
    for (int i = 0; i < TEST_VALUES.length; i++) {
      int64 randomLong = _randomInt64();
      _doTestBoolean(op, TEST_VALUES[i], randomLong);
      _doTestBoolean(op, randomLong, TEST_VALUES[i]);
      for (int j = 0; j < TEST_VALUES.length; j++) {
        _doTestBoolean(op, TEST_VALUES[i], TEST_VALUES[j]);
      }
    }
    for (int i = 0; i < RANDOM_TESTS; i++) {
      int64 longVal0 = _randomInt64();
      int64 longVal1 = _randomInt64();
      if (_randomInt(20) == 0) {
        if (_randomInt(2) == 0) {
          longVal1 = longVal0;
        } else {
          longVal1 = -longVal0;
        }
      }
      _doTestBoolean(op, longVal0, longVal1);
    }
  }

  void _doTestShift(ShiftOp op, int64 val, int shift) {
    int ref = op.ref(val.toInt(), shift);
    int64 result64 = op.test(val, shift);
    int result = result64.toInt();
    if (ref != result) {
      Expect.fail("${op.name}: val = $val, shift = $shift");
    }
  }
 
  void doTestShift(ShiftOp op) {
    print("Testing operator ${op.name}");
    for (int i = 0; i < TEST_VALUES.length; i++) {
      for (int shift = -64; shift <= 64; shift++) {
        _doTestShift(op, TEST_VALUES[i], shift);
      }
    }
    for (int i = 0; i < RANDOM_TESTS; i++) {
      int64 randomLong = _randomInt64();
      for (int shift = -64; shift <= 64; shift++) {
        _doTestShift(op, randomLong, shift);
      }
    }
  }
}
