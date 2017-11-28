// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "dart:math" show pow;

var smallNumber = 1234567890; //   is 31-bit integer.
var mediumNumber = 1234567890123456; // is 53-bit integer

testModPow() {
  test(x, e, m, expectedResult) {
    // Check that expected result is correct, using an unoptimized version.
    assert(() {
      if (1 is double) return true; // Don't have bignums.
      slowModPow(x, e, m) {
        var r = 1;
        while (e > 0) {
          if (e.isOdd) r = (r * x) % m;
          e >>= 1;
          x = (x * x) % m;
        }
        return r;
      }

      return slowModPow(x, e, m) == expectedResult;
    });
    var result = x.modPow(e, m);
    Expect.equals(expectedResult, result, "$x.modPow($e, $m)");
  }

  test(10, 20, 1, 0);
  test(1234567890, 1000000001, 19, 11);
  test(1234567890, 19, 1000000001, 122998977);
  test(19, 1234567890, 1000000001, 619059596);
  test(19, 1000000001, 1234567890, 84910879);
  test(1000000001, 19, 1234567890, 872984351);
  test(1000000001, 1234567890, 19, 0);
}

testModInverse() {
  test(x, m, expectedResult) {
    //print("$x op $m == $expectedResult");
    // Check that expectedResult is an inverse.
    assert(expectedResult < m);
    // The 1 % m handles the m = 1 special case.
    // This test may overflow if we don't have bignums, so only run on VM.
    assert(1 is double || (((x % m) * expectedResult) - 1) % m == 0);

    var result = x.modInverse(m);
    Expect.equals(expectedResult, result, "$x modinv $m");

    if (x > m) {
      x = x % m;
      var result = x.modInverse(m);
      Expect.equals(expectedResult, result, "$x modinv $m");
    }
  }

  testThrows(x, m) {
    // Throws if not co-prime, which is a symmetric property.
    Expect.throws(() => x.modInverse(m), null, "$x modinv $m");
    Expect.throws(() => m.modInverse(x), null, "$m modinv $x");
  }

  test(1, 1, 0);

  testThrows(0, 1000000001);
  testThrows(2, 4);
  testThrows(99, 9);
  testThrows(19, 1000000001);

  // Co-prime numbers
  test(1234567890, 19, 11);
  test(1234567890, 1000000001, 189108911);
  test(19, 1234567890, 519818059);
  test(1000000001, 1234567890, 1001100101);

  test(12345, 12346, 12345);
  test(12345, 12346, 12345);

  test(smallNumber, 137, 42);
  test(137, smallNumber, 856087223);
  test(mediumNumber, 137, 77);
  test(137, mediumNumber, 540686667207353);
}

testGcd() {
  // Call testFunc with all combinations and orders of plus/minus
  // value and other.
  callCombos(value, other, testFunc) {
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
  test(value, other, expectedResult) {
    // Check for bug in test.
    assert(expectedResult == 0 || value % expectedResult == 0);
    assert(expectedResult == 0 || other % expectedResult == 0);
    callCombos(value, other, (a, b) {
      var result = a.gcd(b);

      /// Check that the result is a divisor.
      Expect.equals(0, result == 0 ? a : a % result, "$result | $a");
      Expect.equals(0, result == 0 ? b : b % result, "$result | $b");
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

  testThrows(2.5, 5); // Not a method on double.
  testThrows(5, 2.5); // Not accepting non-int arguments.

  // Format:
  //  test(value1, value2, expectedResult);
  test(1, 1, 1); //     both are 1
  test(1, 2, 1); //     one is 1
  test(3, 5, 1); //     coprime.
  test(37, 37, 37); // Same larger prime.

  test(9999, 7272, 909); // Larger numbers

  test(0, 1000, 1000); // One operand is zero.
  test(0, 0, 0); //        Both operands are zero.

  // Multiplying both operands by a number multiplies result by same number.
  test(693, 609, 21);
  test(693 << 5, 609 << 5, 21 << 5);
  test(693 * 937, 609 * 937, 21 * 937);
  test(693 * pow(2, 32), 609 * pow(2, 32), 21 * pow(2, 32));
  test(693 * pow(2, 52), 609 * pow(2, 52), 21 * pow(2, 52));
  test(693 * pow(2, 53), 609 * pow(2, 53), 21 * pow(2, 53)); // Regression.
  test(693 * pow(2, 99), 609 * pow(2, 99), 21 * pow(2, 99));

  test(1234567890, 19, 1);
  test(1234567890, 1000000001, 1);
  test(19, 1000000001, 19);

  test(0x3FFFFFFF, 0x3FFFFFFF, 0x3FFFFFFF);
  test(0x3FFFFFFF, 0x40000000, 1);

  test(pow(2, 54), pow(2, 53), pow(2, 53));

  test((pow(2, 52) - 1) * pow(2, 10), (pow(2, 26) - 1) * pow(2, 22),
      (pow(2, 26) - 1) * pow(2, 10));
}

main() {
  testModPow(); // //# modPow: ok
  testModInverse();
  testGcd();
}
