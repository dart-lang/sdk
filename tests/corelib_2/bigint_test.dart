// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=
// VMOptions=--no_intrinsify
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import "package:expect/expect.dart";

import 'dart:math' show pow;

var smallNumber = new BigInt.from(1234567890); //   is 31-bit integer.
var mediumNumber = new BigInt.from(1234567890123456); // is 53-bit integer
var bigNumber = BigInt.parse("590295810358705600000"); // > 64-bit integer

testModPow() {
  void test(BigInt x, BigInt e, BigInt m, BigInt expectedResult) {
    // Check that expected result is correct, using an unoptimized version.
    assert(() {
      slowModPow(BigInt x, BigInt e, BigInt m) {
        var r = BigInt.one;
        while (e > BigInt.zero) {
          if (e.isOdd) r = (r * x) % m;
          e >>= 1;
          x = (x * x) % m;
        }
        return r;
      }

      return slowModPow(x, e, m) == expectedResult;
    }());
    var result = x.modPow(e, m);
    Expect.equals(expectedResult, result, "$x.modPow($e, $m)");
  }

  test(new BigInt.from(10), new BigInt.from(20), BigInt.one, BigInt.zero);
  test(new BigInt.from(1234567890), new BigInt.from(1000000001),
      new BigInt.from(19), new BigInt.from(11));
  test(new BigInt.from(1234567890), new BigInt.from(19),
      new BigInt.from(1000000001), new BigInt.from(122998977));
  test(new BigInt.from(19), new BigInt.from(1234567890),
      new BigInt.from(1000000001), new BigInt.from(619059596));
  test(new BigInt.from(19), new BigInt.from(1000000001),
      new BigInt.from(1234567890), new BigInt.from(84910879));
  test(new BigInt.from(1000000001), new BigInt.from(19),
      new BigInt.from(1234567890), new BigInt.from(872984351));
  test(new BigInt.from(1000000001), new BigInt.from(1234567890),
      new BigInt.from(19), BigInt.zero);
  test(BigInt.parse("12345678901234567890"),
      BigInt.parse("10000000000000000001"), new BigInt.from(19), BigInt.two);
  test(
      BigInt.parse("12345678901234567890"),
      new BigInt.from(19),
      BigInt.parse("10000000000000000001"),
      BigInt.parse("3239137215315834625"));
  test(
      new BigInt.from(19),
      BigInt.parse("12345678901234567890"),
      BigInt.parse("10000000000000000001"),
      BigInt.parse("4544207837373941034"));
  test(
      new BigInt.from(19),
      BigInt.parse("10000000000000000001"),
      BigInt.parse("12345678901234567890"),
      BigInt.parse("11135411705397624859"));
  test(
      BigInt.parse("10000000000000000001"),
      new BigInt.from(19),
      BigInt.parse("12345678901234567890"),
      BigInt.parse("2034013733189773841"));
  test(BigInt.parse("10000000000000000001"),
      BigInt.parse("12345678901234567890"), new BigInt.from(19), BigInt.one);
  test(
      BigInt.parse("12345678901234567890"),
      new BigInt.from(19),
      BigInt.parse("10000000000000000001"),
      BigInt.parse("3239137215315834625"));
  test(BigInt.parse("12345678901234567890"),
      BigInt.parse("10000000000000000001"), new BigInt.from(19), BigInt.two);
  test(
      BigInt.parse("123456789012345678901234567890"),
      BigInt.parse("123456789012345678901234567891"),
      BigInt.parse("123456789012345678901234567899"),
      BigInt.parse("116401406051033429924651549616"));
  test(
      BigInt.parse("123456789012345678901234567890"),
      BigInt.parse("123456789012345678901234567899"),
      BigInt.parse("123456789012345678901234567891"),
      BigInt.parse("123456789012345678901234567890"));
  test(
      BigInt.parse("123456789012345678901234567899"),
      BigInt.parse("123456789012345678901234567890"),
      BigInt.parse("123456789012345678901234567891"),
      BigInt.parse("35088523091000351053091545070"));
  test(
      BigInt.parse("123456789012345678901234567899"),
      BigInt.parse("123456789012345678901234567891"),
      BigInt.parse("123456789012345678901234567890"),
      BigInt.parse("18310047270234132455316941949"));
  test(
      BigInt.parse("123456789012345678901234567891"),
      BigInt.parse("123456789012345678901234567899"),
      BigInt.parse("123456789012345678901234567890"),
      BigInt.one);
  test(
      BigInt.parse("123456789012345678901234567891"),
      BigInt.parse("123456789012345678901234567890"),
      BigInt.parse("123456789012345678901234567899"),
      BigInt.parse("40128068573873018143207285483"));
}

testModInverse() {
  void test(BigInt x, BigInt m, BigInt expectedResult) {
    //print("$x op $m == $expectedResult");
    // Check that expectedResult is an inverse.
    assert(expectedResult < m);
    // The 1 % m handles the m = 1 special case.
    assert((((x % m) * expectedResult) - BigInt.one) % m == BigInt.zero);

    var result = x.modInverse(m);
    Expect.equals(expectedResult, result, "$x modinv $m");

    if (x > m) {
      x = x % m;
      var result = x.modInverse(m);
      Expect.equals(expectedResult, result, "$x modinv $m");
    }
  }

  void testThrows(BigInt x, BigInt m) {
    // Throws if not co-prime, which is a symmetric property.
    Expect.throws(() => x.modInverse(m), null, "$x modinv $m");
    Expect.throws(() => m.modInverse(x), null, "$m modinv $x");
  }

  test(BigInt.one, BigInt.one, BigInt.zero);

  testThrows(BigInt.zero, new BigInt.from(1000000001));
  testThrows(BigInt.two, new BigInt.from(4));
  testThrows(new BigInt.from(99), new BigInt.from(9));
  testThrows(new BigInt.from(19), new BigInt.from(1000000001));
  testThrows(BigInt.parse("123456789012345678901234567890"),
      BigInt.parse("123456789012345678901234567899"));

  // Co-prime numbers
  test(new BigInt.from(1234567890), new BigInt.from(19), new BigInt.from(11));
  test(new BigInt.from(1234567890), new BigInt.from(1000000001),
      new BigInt.from(189108911));
  test(new BigInt.from(19), new BigInt.from(1234567890),
      new BigInt.from(519818059));
  test(new BigInt.from(1000000001), new BigInt.from(1234567890),
      new BigInt.from(1001100101));

  test(new BigInt.from(12345), new BigInt.from(12346), new BigInt.from(12345));
  test(new BigInt.from(12345), new BigInt.from(12346), new BigInt.from(12345));

  test(smallNumber, new BigInt.from(137), new BigInt.from(42));
  test(new BigInt.from(137), smallNumber, new BigInt.from(856087223));
  test(mediumNumber, new BigInt.from(137), new BigInt.from(77));
  test(new BigInt.from(137), mediumNumber, new BigInt.from(540686667207353));
  test(bigNumber, new BigInt.from(137), new BigInt.from(128));
}

testGcd() {
  // Call testFunc with all combinations and orders of plus/minus
  // value and other.
  void callCombos(
      BigInt value, BigInt other, void testFunc(BigInt a, BigInt b)) {
    testFunc(value, other);
    testFunc(value, -other);
    testFunc(-value, other);
    testFunc(-value, -other);
    if (value == other) return;
    testFunc(other, value);
    testFunc(other, -value);
    testFunc(-other, value);
    testFunc(-other, -value);
  }

  // Test that gcd of value and other (non-negative) is expectedResult.
  // Tests all combinations of positive and negative values and order of
  // operands, so use positive values and order is not important.
  void test(BigInt value, BigInt other, BigInt expectedResult) {
    // Check for bug in test.
    assert(
        expectedResult == BigInt.zero || value % expectedResult == BigInt.zero);
    assert(
        expectedResult == BigInt.zero || other % expectedResult == BigInt.zero);

    callCombos(value, other, (BigInt a, BigInt b) {
      var result = a.gcd(b);

      /// Check that the result is a divisor.
      Expect.equals(
          BigInt.zero, result == BigInt.zero ? a : a % result, "$result | $a");
      Expect.equals(
          BigInt.zero, result == BigInt.zero ? b : b % result, "$result | $b");
      // Check for bug in test. If assert fails, the expected value is too low,
      // and the gcd call has found a greater common divisor.
      assert(result >= expectedResult);
      Expect.equals(expectedResult, result, "$a.gcd($b)");
    });
  }

  // Test that gcd of value and other (non-negative) throws.
  testThrows(value, other) {
    callCombos(value, other, (a, b) {
      Expect.throws(() => a.gcd(b), null, "$a.gcd($b)");
    });
  }

  // Format:
  //  test(value1, value2, expectedResult);
  test(BigInt.one, BigInt.one, BigInt.one); //     both are 1
  test(BigInt.one, BigInt.two, BigInt.one); //     one is 1
  test(new BigInt.from(3), new BigInt.from(5), BigInt.one); //     coprime.
  test(new BigInt.from(37), new BigInt.from(37),
      new BigInt.from(37)); // Same larger prime.

  test(new BigInt.from(9999), new BigInt.from(7272),
      new BigInt.from(909)); // Larger numbers

  test(BigInt.zero, new BigInt.from(1000),
      new BigInt.from(1000)); // One operand is zero.
  test(BigInt.zero, BigInt.zero, BigInt.zero); //        Both operands are zero.

  // Multiplying both operands by a number multiplies result by same number.
  test(new BigInt.from(693), new BigInt.from(609), new BigInt.from(21));
  test(new BigInt.from(693) << 5, new BigInt.from(609) << 5,
      new BigInt.from(21) << 5);
  test(
      new BigInt.from(693) * new BigInt.from(937),
      new BigInt.from(609) * new BigInt.from(937),
      new BigInt.from(21) * new BigInt.from(937));
  test(
      new BigInt.from(693) * new BigInt.from(pow(2, 32)),
      new BigInt.from(609) * new BigInt.from(pow(2, 32)),
      new BigInt.from(21) * new BigInt.from(pow(2, 32)));
  test(
      new BigInt.from(693) * BigInt.two.pow(52),
      new BigInt.from(609) * BigInt.two.pow(52),
      new BigInt.from(21) * BigInt.two.pow(52));
  test(
      new BigInt.from(693) * BigInt.two.pow(53),
      new BigInt.from(609) * BigInt.two.pow(53),
      new BigInt.from(21) * BigInt.two.pow(53)); // Regression.
  test(
      new BigInt.from(693) * BigInt.two.pow(99),
      new BigInt.from(609) * BigInt.two.pow(99),
      new BigInt.from(21) * BigInt.two.pow(99));

  test(new BigInt.from(1234567890), new BigInt.from(19), BigInt.one);
  test(new BigInt.from(1234567890), new BigInt.from(1000000001), BigInt.one);
  test(new BigInt.from(19), new BigInt.from(1000000001), new BigInt.from(19));

  test(new BigInt.from(0x3FFFFFFF), new BigInt.from(0x3FFFFFFF),
      new BigInt.from(0x3FFFFFFF));
  test(new BigInt.from(0x3FFFFFFF), new BigInt.from(0x40000000), BigInt.one);

  test(BigInt.two.pow(54), BigInt.two.pow(53), BigInt.two.pow(53));

  test(
      (BigInt.two.pow(52) - BigInt.one) * BigInt.two.pow(14),
      (BigInt.two.pow(26) - BigInt.one) * BigInt.two.pow(22),
      (BigInt.two.pow(26) - BigInt.one) * BigInt.two.pow(14));
}

foo() => BigInt.parse("1234567890123456789");
bar() => BigInt.parse("12345678901234567890");

testSmiOverflow() {
  var a = new BigInt.from(1073741823);
  var b = new BigInt.from(1073741822);
  Expect.equals(new BigInt.from(2147483645), a + b);
  a = -new BigInt.from(1000000000);
  b = new BigInt.from(1000000001);
  Expect.equals(-new BigInt.from(2000000001), a - b);
  Expect.equals(-BigInt.parse("1000000001000000000"), a * b);
}

testBigintAdd() {
  // Bigint and Smi.
  var a = BigInt.parse("12345678901234567890");
  var b = BigInt.two;
  Expect.equals(BigInt.parse("12345678901234567892"), a + b);
  Expect.equals(BigInt.parse("12345678901234567892"), b + a);
  // Bigint and Bigint.
  a = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.parse("20000000000000000002"), a + a);
}

testBigintSub() {
  // Bigint and Smi.
  var a = BigInt.parse("12345678901234567890");
  var b = BigInt.two;
  Expect.equals(BigInt.parse("12345678901234567888"), a - b);
  Expect.equals(-BigInt.parse("12345678901234567888"), b - a);
  // Bigint and Bigint.
  a = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.parse("20000000000000000002"), a + a);
}

testBigintMul() {
  // Bigint and Smi.
  var a = BigInt.parse("12345678901234567890");
  var b = new BigInt.from(10);
  Expect.equals(BigInt.parse("123456789012345678900"), a * b);
  Expect.equals(BigInt.parse("123456789012345678900"), b * a);
  // Bigint and Bigint.
  a = BigInt.parse("12345678901234567890");
  b = BigInt.parse("10000000000000000");
  Expect.equals(BigInt.parse("123456789012345678900000000000000000"), a * b);
}

testBigintTruncDiv() {
  var a = BigInt.parse("12345678901234567890");
  var b = new BigInt.from(10);
  // Bigint and Smi.
  Expect.equals(BigInt.parse("1234567890123456789"), a ~/ b);
  Expect.equals(BigInt.zero, b ~/ a);
  Expect.equals(new BigInt.from(123456789),
      BigInt.parse("123456789012345678") ~/ new BigInt.from(1000000000));
  // Bigint and Bigint.
  a = BigInt.parse("12345678901234567890");
  b = BigInt.parse("10000000000000000");
  Expect.equals(new BigInt.from(1234), a ~/ b);
}

testBigintDiv() {
  // Bigint and Smi.
  Expect.equals(1234567890123456789.1,
      BigInt.parse("12345678901234567891") / new BigInt.from(10));
  Expect.equals(
      0.000000001234, new BigInt.from(1234) / new BigInt.from(1000000000000));
  Expect.equals(12345678901234000000.0,
      BigInt.parse("123456789012340000000") / new BigInt.from(10));
  // Bigint and Bigint.
  var a = BigInt.parse("12345670000000000000");
  var b = BigInt.parse("10000000000000000");
  Expect.equals(1234.567, a / b);
}

testBigintModulo() {
  // Bigint and Smi.
  var a = new BigInt.from(1000000000005);
  var b = new BigInt.from(10);
  Expect.equals(new BigInt.from(5), a % b);
  Expect.equals(new BigInt.from(10), b % a);
  // Bigint & Bigint
  a = BigInt.parse("10000000000000000001");
  b = BigInt.parse("10000000000000000000");
  Expect.equals(BigInt.one, a % b);
  Expect.equals(BigInt.parse("10000000000000000000"), b % a);
}

testBigintModPow() {
  var x, e, m;
  x = new BigInt.from(1234567890);
  e = new BigInt.from(1000000001);
  m = new BigInt.from(19);
  Expect.equals(new BigInt.from(11), x.modPow(e, m));
  x = new BigInt.from(1234567890);
  e = new BigInt.from(19);
  m = new BigInt.from(1000000001);
  Expect.equals(new BigInt.from(122998977), x.modPow(e, m));
  x = new BigInt.from(19);
  e = new BigInt.from(1234567890);
  m = new BigInt.from(1000000001);
  Expect.equals(new BigInt.from(619059596), x.modPow(e, m));
  x = new BigInt.from(19);
  e = new BigInt.from(1000000001);
  m = new BigInt.from(1234567890);
  Expect.equals(new BigInt.from(84910879), x.modPow(e, m));
  x = new BigInt.from(1000000001);
  e = new BigInt.from(19);
  m = new BigInt.from(1234567890);
  Expect.equals(new BigInt.from(872984351), x.modPow(e, m));
  x = new BigInt.from(1000000001);
  e = new BigInt.from(1234567890);
  m = new BigInt.from(19);
  Expect.equals(BigInt.zero, x.modPow(e, m));
  x = BigInt.parse("12345678901234567890");
  e = BigInt.parse("10000000000000000001");
  m = new BigInt.from(19);
  Expect.equals(BigInt.two, x.modPow(e, m));
  x = BigInt.parse("12345678901234567890");
  e = new BigInt.from(19);
  m = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.parse("3239137215315834625"), x.modPow(e, m));
  x = new BigInt.from(19);
  e = BigInt.parse("12345678901234567890");
  m = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.parse("4544207837373941034"), x.modPow(e, m));
  x = new BigInt.from(19);
  e = BigInt.parse("10000000000000000001");
  m = BigInt.parse("12345678901234567890");
  Expect.equals(BigInt.parse("11135411705397624859"), x.modPow(e, m));
  x = BigInt.parse("10000000000000000001");
  e = new BigInt.from(19);
  m = BigInt.parse("12345678901234567890");
  Expect.equals(BigInt.parse("2034013733189773841"), x.modPow(e, m));
  x = BigInt.parse("10000000000000000001");
  e = BigInt.parse("12345678901234567890");
  m = new BigInt.from(19);
  Expect.equals(BigInt.one, x.modPow(e, m));
  x = BigInt.parse("12345678901234567890");
  e = new BigInt.from(19);
  m = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.parse("3239137215315834625"), x.modPow(e, m));
  x = BigInt.parse("12345678901234567890");
  e = BigInt.parse("10000000000000000001");
  m = new BigInt.from(19);
  Expect.equals(BigInt.two, x.modPow(e, m));
  x = BigInt.parse("123456789012345678901234567890");
  e = BigInt.parse("123456789012345678901234567891");
  m = BigInt.parse("123456789012345678901234567899");
  Expect.equals(BigInt.parse("116401406051033429924651549616"), x.modPow(e, m));
  x = BigInt.parse("123456789012345678901234567890");
  e = BigInt.parse("123456789012345678901234567899");
  m = BigInt.parse("123456789012345678901234567891");
  Expect.equals(BigInt.parse("123456789012345678901234567890"), x.modPow(e, m));
  x = BigInt.parse("123456789012345678901234567899");
  e = BigInt.parse("123456789012345678901234567890");
  m = BigInt.parse("123456789012345678901234567891");
  Expect.equals(BigInt.parse("35088523091000351053091545070"), x.modPow(e, m));
  x = BigInt.parse("123456789012345678901234567899");
  e = BigInt.parse("123456789012345678901234567891");
  m = BigInt.parse("123456789012345678901234567890");
  Expect.equals(BigInt.parse("18310047270234132455316941949"), x.modPow(e, m));
  x = BigInt.parse("123456789012345678901234567891");
  e = BigInt.parse("123456789012345678901234567899");
  m = BigInt.parse("123456789012345678901234567890");
  Expect.equals(BigInt.one, x.modPow(e, m));
  x = BigInt.parse("123456789012345678901234567891");
  e = BigInt.parse("123456789012345678901234567890");
  m = BigInt.parse("123456789012345678901234567899");
  Expect.equals(BigInt.parse("40128068573873018143207285483"), x.modPow(e, m));
}

testBigintModInverse() {
  var x, m;
  x = BigInt.one;
  m = BigInt.one;
  Expect.equals(BigInt.zero, x.modInverse(m));
  x = BigInt.zero;
  m = new BigInt.from(1000000001);
  Expect.throws(() => x.modInverse(m), (e) => e is Exception); // Not coprime.
  x = new BigInt.from(1234567890);
  m = new BigInt.from(19);
  Expect.equals(new BigInt.from(11), x.modInverse(m));
  x = new BigInt.from(1234567890);
  m = new BigInt.from(1000000001);
  Expect.equals(new BigInt.from(189108911), x.modInverse(m));
  x = new BigInt.from(19);
  m = new BigInt.from(1000000001);
  Expect.throws(() => x.modInverse(m), (e) => e is Exception); // Not coprime.
  x = new BigInt.from(19);
  m = new BigInt.from(1234567890);
  Expect.equals(new BigInt.from(519818059), x.modInverse(m));
  x = new BigInt.from(1000000001);
  m = new BigInt.from(1234567890);
  Expect.equals(new BigInt.from(1001100101), x.modInverse(m));
  x = new BigInt.from(1000000001);
  m = new BigInt.from(19);
  Expect.throws(() => x.modInverse(m), (e) => e is Exception); // Not coprime.
  x = BigInt.parse("12345678901234567890");
  m = new BigInt.from(19);
  Expect.equals(new BigInt.from(3), x.modInverse(m));
  x = BigInt.parse("12345678901234567890");
  m = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.parse("9736746307686209582"), x.modInverse(m));
  x = new BigInt.from(19);
  m = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.parse("6315789473684210527"), x.modInverse(m));
  x = new BigInt.from(19);
  m = BigInt.parse("12345678901234567890");
  Expect.equals(BigInt.parse("10396361179987004539"), x.modInverse(m));
  x = BigInt.parse("10000000000000000001");
  m = BigInt.parse("12345678901234567890");
  Expect.equals(BigInt.parse("325004555487045911"), x.modInverse(m));
  x = BigInt.parse("10000000000000000001");
  m = new BigInt.from(19);
  Expect.equals(new BigInt.from(7), x.modInverse(m));
  x = BigInt.parse("12345678901234567890");
  m = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.parse("9736746307686209582"), x.modInverse(m));
  x = BigInt.parse("12345678901234567890");
  m = new BigInt.from(19);
  Expect.equals(new BigInt.from(3), x.modInverse(m));
  x = BigInt.parse("123456789012345678901234567890");
  m = BigInt.parse("123456789012345678901234567899");
  Expect.throws(() => x.modInverse(m), (e) => e is Exception); // Not coprime.
  x = BigInt.parse("123456789012345678901234567890");
  m = BigInt.parse("123456789012345678901234567891");
  Expect.equals(
      BigInt.parse("123456789012345678901234567890"), x.modInverse(m));
  x = BigInt.parse("123456789012345678901234567899");
  m = BigInt.parse("123456789012345678901234567891");
  Expect.equals(BigInt.parse("77160493132716049313271604932"), x.modInverse(m));
  x = BigInt.parse("123456789012345678901234567899");
  m = BigInt.parse("123456789012345678901234567890");
  Expect.throws(() => x.modInverse(m), (e) => e is Exception); // Not coprime.
  x = BigInt.parse("123456789012345678901234567891");
  m = BigInt.parse("123456789012345678901234567890");
  Expect.equals(BigInt.one, x.modInverse(m));
  x = BigInt.parse("123456789012345678901234567891");
  m = BigInt.parse("123456789012345678901234567899");
  Expect.equals(BigInt.parse("46296295879629629587962962962"), x.modInverse(m));
}

testBigintGcd() {
  var x, m;
  x = BigInt.one;
  m = BigInt.one;
  Expect.equals(BigInt.one, x.gcd(m));
  x = new BigInt.from(693);
  m = new BigInt.from(609);
  Expect.equals(new BigInt.from(21), x.gcd(m));
  x = new BigInt.from(693) << 40;
  m = new BigInt.from(609) << 40;
  Expect.equals(new BigInt.from(21) << 40, x.gcd(m));
  x = new BigInt.from(609) << 40;
  m = new BigInt.from(693) << 40;
  Expect.equals(new BigInt.from(21) << 40, x.gcd(m));
  x = BigInt.zero;
  m = new BigInt.from(1000000001);
  Expect.equals(m, x.gcd(m));
  x = new BigInt.from(1000000001);
  m = BigInt.zero;
  Expect.equals(x, x.gcd(m));
  x = BigInt.zero;
  m = -new BigInt.from(1000000001);
  Expect.equals(-m, x.gcd(m));
  x = -new BigInt.from(1000000001);
  m = BigInt.zero;
  Expect.equals(-x, x.gcd(m));
  x = BigInt.zero;
  m = BigInt.zero;
  Expect.equals(BigInt.zero, x.gcd(m));
  x = BigInt.zero;
  m = BigInt.parse("123456789012345678901234567890");
  Expect.equals(m, x.gcd(m));
  x = BigInt.parse("123456789012345678901234567890");
  m = BigInt.zero;
  Expect.equals(x, x.gcd(m));
  x = BigInt.zero;
  m = -BigInt.parse("123456789012345678901234567890");
  Expect.equals(-m, x.gcd(m));
  x = -BigInt.parse("123456789012345678901234567890");
  m = BigInt.zero;
  Expect.equals(-x, x.gcd(m));
  x = new BigInt.from(1234567890);
  m = new BigInt.from(19);
  Expect.equals(BigInt.one, x.gcd(m));
  x = new BigInt.from(1234567890);
  m = new BigInt.from(1000000001);
  Expect.equals(BigInt.one, x.gcd(m));
  x = new BigInt.from(19);
  m = new BigInt.from(1000000001);
  Expect.equals(new BigInt.from(19), x.gcd(m));
  x = new BigInt.from(19);
  m = new BigInt.from(1234567890);
  Expect.equals(BigInt.one, x.gcd(m));
  x = new BigInt.from(1000000001);
  m = new BigInt.from(1234567890);
  Expect.equals(BigInt.one, x.gcd(m));
  x = new BigInt.from(1000000001);
  m = new BigInt.from(19);
  Expect.equals(new BigInt.from(19), x.gcd(m));
  x = BigInt.parse("12345678901234567890");
  m = new BigInt.from(19);
  Expect.equals(BigInt.one, x.gcd(m));
  x = BigInt.parse("12345678901234567890");
  m = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.one, x.gcd(m));
  x = new BigInt.from(19);
  m = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.one, x.gcd(m));
  x = new BigInt.from(19);
  m = BigInt.parse("12345678901234567890");
  Expect.equals(BigInt.one, x.gcd(m));
  x = BigInt.parse("10000000000000000001");
  m = BigInt.parse("12345678901234567890");
  Expect.equals(BigInt.one, x.gcd(m));
  x = BigInt.parse("10000000000000000001");
  m = new BigInt.from(19);
  Expect.equals(BigInt.one, x.gcd(m));
  x = BigInt.parse("12345678901234567890");
  m = BigInt.parse("10000000000000000001");
  Expect.equals(BigInt.one, x.gcd(m));
  x = BigInt.parse("12345678901234567890");
  m = new BigInt.from(19);
  Expect.equals(BigInt.one, x.gcd(m));
  x = BigInt.parse("123456789012345678901234567890");
  m = BigInt.parse("123456789012345678901234567899");
  Expect.equals(new BigInt.from(9), x.gcd(m));
  x = BigInt.parse("123456789012345678901234567890");
  m = BigInt.parse("123456789012345678901234567891");
  Expect.equals(BigInt.one, x.gcd(m));
  x = BigInt.parse("123456789012345678901234567899");
  m = BigInt.parse("123456789012345678901234567891");
  Expect.equals(BigInt.one, x.gcd(m));
  x = BigInt.parse("123456789012345678901234567899");
  m = BigInt.parse("123456789012345678901234567890");
  Expect.equals(new BigInt.from(9), x.gcd(m));
  x = BigInt.parse("123456789012345678901234567891");
  m = BigInt.parse("123456789012345678901234567890");
  Expect.equals(BigInt.one, x.gcd(m));
  x = BigInt.parse("123456789012345678901234567891");
  m = BigInt.parse("123456789012345678901234567899");
  Expect.equals(BigInt.one, x.gcd(m));
}

testBigintNegate() {
  var a = BigInt.parse("0xF000000000000000F");
  var b = ~a; // negate.
  Expect.equals(BigInt.parse("-0xF0000000000000010"), b);
  Expect.equals(BigInt.zero, a & b);
  Expect.equals(-BigInt.one, a | b);
}

testShiftAmount() {
  Expect.equals(BigInt.zero, new BigInt.from(12) >> 0x7FFFFFFFFFFFFFFF);
  Expect.equals(-BigInt.one, -new BigInt.from(12) >> 0x7FFFFFFFFFFFFFFF);
  bool exceptionCaught = false;
  try {
    var a = BigInt.one << 0x7FFFFFFFFFFFFFFF;
  } on OutOfMemoryError catch (e) {
    exceptionCaught = true;
  } on ArgumentError catch (e) {
    // In JavaScript the allocation of the internal array throws a range error.
    exceptionCaught = true;
  }
  Expect.equals(true, exceptionCaught);
}

void testPow() {
  Expect.throws(() => BigInt.zero.pow(-1), (e) => e is ArgumentError);
  Expect.throws(() => BigInt.one.pow(-1), (e) => e is ArgumentError);
  Expect.equals(BigInt.one, BigInt.zero.pow(0));
  Expect.equals(BigInt.one, BigInt.one.pow(0));
  Expect.equals(BigInt.one, BigInt.two.pow(0));

  Expect.equals(
      BigInt.parse("6208695403009031808124000434786599466508260573005"
          "3508480680160632742505079094163654310415168343540278191693"
          "5380629274547924077088101599462083663373536705603680787010"
          "0454231036999140164473780469056908670815701571304455697970"
          "9971709527651446612272365411298758026041094781651768636427"
          "4780767345075500515905845436036697865291662016364446907149"
          "5652136304764312997430969058854587555188117728022873502683"
          "6327099687782677885098446991121805146733387058565662606025"
          "2854981418159051193843689364388302820905062090182919338371"
          "8783490348348213313279505263650976040646393394551465619437"
          "7126646818740571207346633109049097273375955956480091920939"
          "5595130499375022416542475049562151695680373438890512164488"
          "6567991220660935537691145761690539808578087290707813875567"
          "9145826183642842261374804672283964244725240865733938342036"
          "1216219271232461693264437901347421563392441043817990067322"
          "88"),
      BigInt.parse("90218646930912603144382974164422").pow(27));
  ;
}

void testToRadixString() {
  // Test that we accept radix 2 to 36 and that we use lower-case
  // letters.
  var expected = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', //
    'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', //
    's', 't', 'u', 'v', 'w', 'x', 'y', 'z' //
  ];
  for (var radix = 2; radix <= 36; radix++) {
    for (var i = 0; i < radix; i++) {
      Expect.equals(expected[i], new BigInt.from(i).toRadixString(radix));
    }
  }

  var illegalRadices = [-1, 0, 1, 37];
  for (var radix in illegalRadices) {
    try {
      new BigInt.from(42).toRadixString(radix);
      Expect.fail("Exception expected");
    } on ArgumentError catch (e) {
      // Nothing to do.
    }
  }

  // Try large numbers (regression test for issue 15316).
  var bignums = [
    BigInt.parse("0x80000000"),
    BigInt.parse("0x100000000"),
    BigInt.parse("0x10000000000000"),
    BigInt.parse("0x10000000000001"), // 53 significant bits.
    BigInt.parse("0x20000000000000"),
    BigInt.parse("0x20000000000002"),
    BigInt.parse("0x1000000000000000"),
    BigInt.parse("0x1000000000000100"),
    BigInt.parse("0x2000000000000000"),
    BigInt.parse("0x2000000000000200"),
    BigInt.parse("0x8000000000000000"),
    BigInt.parse("0x8000000000000800"),
    BigInt.parse("0x10000000000000000"),
    BigInt.parse("0x10000000000001000"),
    BigInt.parse("0x100000000000010000"),
    BigInt.parse("0x1000000000000100000"),
    BigInt.parse("0x10000000000001000000"),
    BigInt.parse("0x100000000000010000000"),
    BigInt.parse("0x1000000000000100000000"),
    BigInt.parse("0x10000000000001000000000"),
  ];
  for (var bignum in bignums) {
    for (int radix = 2; radix <= 36; radix++) {
      String digits = bignum.toRadixString(radix);
      BigInt result = BigInt.parse(digits, radix: radix);
      Expect.equals(
          bignum, result, "${bignum.toRadixString(16)} -> $digits/$radix");
    }
  }
}

testToString() {
  /// Test that converting [value] to a string gives [expect].
  /// Also test that `-value` gives `"-"+expect`.
  test(BigInt value, String expect) {
    Expect.equals(expect, value.toString());
    Expect.equals(expect, "$value");
    Expect.equals(expect, (new StringBuffer()..write(value)).toString());
    if (value == BigInt.zero) return;
    expect = "-$expect";
    value = -value;
    Expect.equals(expect, value.toString());
    Expect.equals(expect, "$value");
    Expect.equals(expect, (new StringBuffer()..write(value)).toString());
  }

  // Very simple tests.
  test(BigInt.zero, "0");
  test(BigInt.one, "1");
  test(BigInt.two, "2");
  test(new BigInt.from(5), "5");

  // Binary special cases.

  // ~2^30.
  test(BigInt.parse("0x3fffffff"), "1073741823");
  test(BigInt.parse("0x40000000"), "1073741824");
  test(BigInt.parse("0x40000001"), "1073741825");
  // ~2^31.
  test(BigInt.parse("0x7fffffff"), "2147483647");
  test(BigInt.parse("0x80000000"), "2147483648");
  test(BigInt.parse("0x80000001"), "2147483649");
  // ~2^32.
  test(BigInt.parse("0xffffffff"), "4294967295");
  test(BigInt.parse("0x100000000"), "4294967296");
  test(BigInt.parse("0x100000001"), "4294967297");

  // ~2^51.
  test(BigInt.parse("0x7ffffffffffff"), "2251799813685247");
  test(BigInt.parse("0x8000000000000"), "2251799813685248");
  test(BigInt.parse("0x8000000000001"), "2251799813685249");
  // ~2^52.
  test(BigInt.parse("0xfffffffffffff"), "4503599627370495");
  test(BigInt.parse("0x10000000000000"), "4503599627370496");
  test(BigInt.parse("0x10000000000001"), "4503599627370497");
  // ~2^53.
  test(BigInt.parse("0x1fffffffffffff"), "9007199254740991");
  test(BigInt.parse("0x20000000000000"), "9007199254740992");
  test(BigInt.parse("0x20000000000001"), "9007199254740993");
  // ~2^62.
  test(BigInt.parse("0x3fffffffffffffff"), "4611686018427387903");
  test(BigInt.parse("0x4000000000000000"), "4611686018427387904");
  test(BigInt.parse("0x4000000000000001"), "4611686018427387905");
  // ~2^63.
  test(BigInt.parse("0x7fffffffffffffff"), "9223372036854775807");
  test(BigInt.parse("0x8000000000000000"), "9223372036854775808");
  test(BigInt.parse("0x8000000000000001"), "9223372036854775809");
  // ~2^64.
  test(BigInt.parse("0xffffffffffffffff"), "18446744073709551615");
  test(BigInt.parse("0x10000000000000000"), "18446744073709551616");
  test(BigInt.parse("0x10000000000000001"), "18446744073709551617");
  // Big bignum.
  test(BigInt.parse("123456789012345678901234567890"),
      "123456789012345678901234567890");

  // Decimal special cases.

  BigInt number = new BigInt.from(10);
  // Numbers 99..99, 100...00, and 100..01 up to 23 digits.
  for (int i = 1; i < 22; i++) {
    test(number - BigInt.one, "9" * i);
    test(number, "1" + "0" * i);
    test(number + BigInt.one, "1" + "0" * (i - 1) + "1");
    number *= new BigInt.from(10);
  }
}

void testFromToInt() {
  void test(int x) {
    var bigFrom = new BigInt.from(x);
    var bigStr = bigFrom.toString();
    Expect.equals(x, bigFrom.toInt());
    Expect.equals(x, int.parse(bigStr));
  }

  for (int i = 0; i < 20; i++) {
    test(i);
    // Dart2js doesn't know that -0 should stay 0.
    if (i != 0) test(-i);
  }

  // For now just test "easy" integers since there is no check yet that clamps
  // the returned integer.
  for (int i = 0; i < 2000000; i += 10000) {
    test(i);
    // Dart2js doesn't know that -0 should stay 0.
    if (i != 0) test(-i);
  }

  const minInt64 = -9223372036854775807 - 1;
  test(minInt64);
}

void testFromToDouble() {
  Expect.equals(-1.0, (-BigInt.one).toDouble());

  Expect.throws(() => new BigInt.from(double.nan));
  Expect.throws(() => new BigInt.from(double.infinity));
  Expect.throws(() => new BigInt.from(-double.infinity));

  const double maxDouble = 1.7976931348623157e+308;
  const String maxDoubleHexStr = "0xfffffffffffff8000000000000000"
      "00000000000000000000000000000000000000000000000000000000000000"
      "00000000000000000000000000000000000000000000000000000000000000"
      "00000000000000000000000000000000000000000000000000000000000000"
      "00000000000000000000000000000000000000000";

  // The following value lies directly on the boundary between max double and
  // infinity. It rounds to infinity. Any value below rounds to a finite double
  // value.
  const String maxDoubleBoundaryStr = "0xfffffffffffffc0000000000"
      "00000000000000000000000000000000000000000000000000000000000000"
      "00000000000000000000000000000000000000000000000000000000000000"
      "00000000000000000000000000000000000000000000000000000000000000"
      "0000000000000000000000000000000000000000000000";

  var bigMax = BigInt.parse(maxDoubleHexStr);
  var bigBoundary = BigInt.parse(maxDoubleBoundaryStr);
  Expect.equals(maxDouble, bigMax.toDouble());
  Expect.equals(bigMax, new BigInt.from(maxDouble));
  Expect.equals(double.infinity, bigBoundary.toDouble());
  Expect.equals(maxDouble, (bigBoundary - BigInt.one).toDouble());

  Expect.equals(-maxDouble, (-bigMax).toDouble());
  Expect.equals(-bigMax, new BigInt.from(-maxDouble));
  Expect.equals(-double.infinity, (-bigBoundary).toDouble());
  Expect.equals(-maxDouble, (-(bigBoundary - BigInt.one)).toDouble());

  void test(int x) {
    var str = x.toString();
    var big = BigInt.parse(str);
    Expect.equals(x, big.toDouble());
  }

  for (int i = 0; i < 20; i++) {
    test(i);
    // Dart2js doesn't know that -0 should stay 0.
    if (i != 0) test(-i);
  }

  for (int i = 0; i < 2000000; i += 10000) {
    test(i);
    // Dart2js doesn't know that -0 should stay 0.
    if (i != 0) test(-i);
  }

  for (int i = 1000; i < 100000; i += 1000) {
    var d = 1 / i;
    Expect.equals(BigInt.zero, new BigInt.from(d));
  }

  // Non-integer values are truncated.
  Expect.equals(BigInt.one, new BigInt.from(1.5));
  Expect.equals(-BigInt.one, new BigInt.from(-1.5));

  Expect.equals(BigInt.zero, new BigInt.from(0.9999999999999999));
  Expect.equals(BigInt.zero, new BigInt.from(-0.9999999999999999));
}

main() {
  for (int i = 0; i < 10; i++) {
    Expect.equals(BigInt.parse("1234567890123456789"), foo());
    Expect.equals(BigInt.parse("12345678901234567890"), bar());
    testModPow();
    testModInverse();
    testGcd();
    testSmiOverflow();
    testBigintAdd();
    testBigintSub();
    testBigintMul();
    testBigintTruncDiv();
    testBigintDiv();
    testBigintModulo();
    testBigintModPow();
    testBigintModInverse();
    testBigintGcd();
    testBigintNegate();
    testShiftAmount();
    testPow();
    testToRadixString();
    testToString();
    testFromToInt();
    testFromToDouble();
    Expect.equals(BigInt.parse("12345678901234567890"),
        BigInt.parse("12345678901234567890").abs());
    Expect.equals(BigInt.parse("12345678901234567890"),
        BigInt.parse("-12345678901234567890").abs());
    var a = BigInt.parse("10000000000000000000");
    var b = BigInt.parse("10000000000000000001");
    Expect.equals(false, a.hashCode == b.hashCode);
    Expect.equals(true, a.hashCode == (b - BigInt.one).hashCode);
  }
}
