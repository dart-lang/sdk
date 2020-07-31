// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=--intrinsify --no-enable-asserts
// VMOptions=--intrinsify --enable-asserts
// VMOptions=--no-intrinsify --enable-asserts
// VMOptions=--optimization-counter-threshold=5 --no-background-compilation

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
  test(
      BigInt.parse(
          "-7003a3cac2bac4e494d749ae101f7ede8f11dac594fea5f51e15826021d734df6ec"
          "b6f67d74e2bb0f47ee39cb79fae059734c95d1eacb0340af64c05b83a4f70a737363"
          "c3799d38c23b7833622d89036b4649bcc7b749037f4954dac6abe5566c97cb6ac81f"
          "f8a09f8c71c7f08061720483b592517a608088ddb4c2e460ad1a73abbadbda077922"
          "1751cf22f1191e3be531505c833fede908a17581a9ae96f3c0258edcfe71786b7cf3"
          "07f67eb9ecd8656d0fd397b0215bfb79efb314299d3e9db70b31a34f5f67e6c5e166"
          "cfa3e0bf45837c5d64fa3930a91a06b94840b4773d81280ed2af141747a6ac99d882"
          "a59f47b15ce8c1d716ead646b139b928869902225c85ea220b90e290181f271ed087"
          "bb6972dfe7d674b09e44c268128340d9172182732990a70af51d589c89f39d8f5dac"
          "659161aa0a32774728e15e25bad2960b4eacb8b670581b1c431201192c8bdbcc9256"
          "ef9e863b589f22813158050cdaf5da69f83819639f5a183c7ffe61ba1582d6ace35c"
          "8318dfdc597d016e70b7bb115fc1a7a3481c3a6296f1504e5ccd9b14e641acb2aa32"
          "9c3d69b5e8f1609eec8b5b5a2b0192e9f21e7e3960c52975a70cf934c32e67799c40"
          "863b23c9579a551df4b179e6e2094f86c9fffa4bb5634202e094d380565b44cec833"
          "db25721010dd5df766204ae8d1e8680075f261801aee047d0ac576b9b10710de54e6"
          "eaa94648a7fba1576e66ea44f4bb7f6b941268a8d920bfc2727f82457f92cc2a016c"
          "b",
          radix: 16),
      BigInt.parse(
          "73ac14b30fe9cb8275a7410a06ce5de8a60fe0a02e236197182996ca5886fd4e6937"
          "555f1f02ed4183ff7f097f76051f286dbb1b24751795cb793b1b81ac259",
          radix: 16),
      BigInt.parse(
          "ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020b"
          "bea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d"
          "6d51c245e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7edee386bfb5a89"
          "9fa5ae9f24117c4b1fe649286651ece45b3dc2007cb8a163bf0598da48361c55d39a"
          "69163fa8fd24cf5f83655d23dca3ad961c62f356208552bb9ed529077096966d670c"
          "354e4abc9804f1746c08ca18217c32905e462e36ce3be39e772c180e86039b2783a2"
          "ec07a28fb5c55df06f4c52c9de2bcbf6955817183995497cea956ae515d2261898fa"
          "051015728e5a8aaac42dad33170d04507a33a85521abdf1cba64ecfb850458dbef0a"
          "8aea71575d060c7db3970f85a6e1e4c7abf5ae8cdb0933d71e8c94e04a25619dcee3"
          "d2261ad2ee6bf12ffa06d98a0864d87602733ec86a64521f2b18177b200cbbe11757"
          "7a615d6c770988c0bad946e208e24fa074e5ab3143db5bfce0fd108e4b82d120a921"
          "08011a723c12a787e6d788719a10bdba5b2699c327186af4e23c1a946834b6150bda"
          "2583e9ca2ad44ce8dbbbc2db04de8ef92e8efc141fbecaa6287c59474e6bc05d99b2"
          "964fa090c3a2233ba186515be7ed1f612970cee2d7afb81bdd762170481cd0069127"
          "d5b05aa993b4ea988d8fddc186ffb7dc90a6c08f4df435c934063199ffffffffffff"
          "ffff",
          radix: 16),
      BigInt.parse(
          "b1b35af289290c92fcd3d22fca66016f6db7aa21508991c97f0e53fddc2f7ece7088"
          "5e935259c28d317be14c0378e2ebd103600e2e1f55b111703fc75217836e24f9bfd8"
          "63d47cdb26882f491949b1906c2cb016c0e9e9d77c3a9c4a3e85b9ac34057eeb993d"
          "d048d8ed90b1eea78f84ee48febb1281384c739b1c60dda475395e3928b7081af890"
          "d2c58eac70d11d7f14c0e98fd168735425d233b7c07506b54149482261067079f82a"
          "b531a072ede523aca1765c1a587c160f638aa3ccab8cd1f3358c5bac3ed0a6062e92"
          "94df2322864f6a8e58b4a2d40b600a0f09065d34bd49e60b5656d2c6dcb3af751f4a"
          "9c10dc7df46215f3043b4077fc2be7f648d388843db9cf94f31b2eb376cf22033a23"
          "e8984b5b1702f9e5af99507ad3d8d624a104c18af275949e7e88c16651103a2a7620"
          "c5c8356f1f2311a9cab2c61d30b0af22d7961e42cb13679bf0d52f35b41a0f7c341a"
          "c414a76a9a85408c39836657594180ffbb4d5a38e4b6eeea125fcde370478f6b7cd8"
          "903fc8a822075f6e766d83337e6db2eb6605d514327294ec1e076d576eee08220acd"
          "f4f9ffa31f1aa7b4639eb11797c8f39956b5e4dbca98a0a15eb29136b66917cfdbfb"
          "dd8ba20475ad401a6f1022a04bed3c8d5227cd7385e9b67096261fcc2ccf2632a4c2"
          "f5ef640b1f37966f855f8314c97c8ef7a136e54565e95bfe253e579753f5a14c2a01"
          "6c1",
          radix: 16));
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
  var x = BigInt.parse(
      "28ea16430c1f1072754aa5ebbfda0d790605a507c6c9758e88697b0b5dd9e74c",
      radix: 16);
  var m = BigInt.parse(
      "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f",
      radix: 16);
  var r = BigInt.parse("95929095851002583825372225918533539673793386278"
                       "360575987103577151530201707061", radix: 10);
  test(x, m, r);
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

testBigintAnd() {
  var a = BigInt.parse("0x55555555555555555555");
  var b = BigInt.parse("0x33333333333333333333");
  var c = BigInt.parse("0x11111111111111111111");
  Expect.equals(BigInt.zero, BigInt.zero & a);
  Expect.equals(BigInt.zero, a & BigInt.zero);
  Expect.equals(c, a & b);
}

testBigintOr() {
  var a = BigInt.parse("0x33333333333333333333");
  var b = BigInt.parse("0x55555555555555555555");
  var c = BigInt.parse("0x77777777777777777777");
  Expect.equals(a, BigInt.zero | a);
  Expect.equals(a, a | BigInt.zero);
  Expect.equals(c, a | b);
}

testBigintXor() {
  var a = BigInt.parse("0x33333333333333333333");
  var b = BigInt.parse("0x55555555555555555555");
  var c = BigInt.parse("0x66666666666666666666");
  Expect.equals(a, BigInt.zero ^ a);
  Expect.equals(a, a ^ BigInt.zero);
  Expect.equals(c, a ^ b);
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
  Expect.equals(a, BigInt.zero + a);
  Expect.equals(a, a + BigInt.zero);
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
  Expect.equals(-a, BigInt.zero - a);
  Expect.equals(a, a - BigInt.zero);
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
  // TruncDiv as used in toString().
  a = BigInt.parse("4503599627370496"); // 0x10000000000000
  b = new BigInt.from(10000);
  Expect.equals(new BigInt.from(450359962737), a ~/ b);
  b = new BigInt.from(1000000000);
  Expect.equals(new BigInt.from(4503599), a ~/ b);
  // Bigint and Bigint.
  a = BigInt.parse("12345678901234567890");
  b = BigInt.parse("10000000000000000");
  Expect.equals(new BigInt.from(1234), a ~/ b);
  a = BigInt.parse("9173112362840293939050000000000000000");
  b = BigInt.parse("50000000000000000");
  Expect.equals(BigInt.parse("183462247256805878781"), a ~/ b);
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
  // Modulo as used in toString().
  a = BigInt.parse("4503599627370496"); // 0x10000000000000
  b = new BigInt.from(10000);
  Expect.equals(new BigInt.from(496), a % b);
  b = new BigInt.from(1000000000);
  Expect.equals(new BigInt.from(627370496), a % b);
  // Bigint & Bigint
  a = BigInt.parse("10000000000000000001");
  b = BigInt.parse("10000000000000000000");
  Expect.equals(BigInt.one, a % b);
  Expect.equals(BigInt.parse("10000000000000000000"), b % a);
  a = BigInt.parse("2432363650");
  b = BigInt.parse("2201792050");
  Expect.equals(BigInt.parse("230571600"), a % b);
  Expect.equals(BigInt.parse("2201792050"), b % a);
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
  x = BigInt.parse(
      "142223781135477974841804437037182877109549636480215350570761436386728140"
      "00321219503871352719175100865184619168128345594681547640115731246638");
  e = BigInt.parse(
      "688057170495263083245752731085731160016625265771524738691797062279575950"
      "919479651156310413084174304361991240273181430924411258203766946639349880"
      "404106504114953688890200429043051936362182997575167191584461538746041795"
      "019663740246921124383173799957296515067912829778249931473903780958741032"
      "64534184571632120755");
  m = BigInt.parse(
      "144173682842817587002196172066264549138375068078359231382946906898412792"
      "452632726597279520229873489736777248181678202636100459215718497240474064"
      "366927544074501134727745837254834206456400508719134610847814227274992298"
      "238973375146473350157304285346424982280927848339601514720098577525635486"
      "320547905945936448443");
  Expect.equals(
      BigInt.parse(
          "41228476947144730491819644448449646627743926889389391986712371102685"
          "14984467753960109321610008533258676279344318597060690521027646613453"
          "25674994677820913027869835916005689276806408148698486814119894325284"
          "18918299321385420296108046942018595594076729397423805685944237555128"
          "652606412065971965116137839721723231"),
      x.modPow(e, m));
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
  Expect.equals(BigInt.zero, BigInt.zero << 0);
  Expect.equals(BigInt.zero, BigInt.zero >> 0);
  Expect.equals(BigInt.zero, BigInt.zero << 1234567890);
  Expect.equals(BigInt.zero, BigInt.zero >> 1234567890);
  Expect.equals(BigInt.two.pow(999), BigInt.one << 999);
  Expect.equals(BigInt.one, BigInt.two.pow(999) >> 999);
  // 0x7FFFFFFFFFFFFFFF on VM, slightly rounded up on web platform.
  const int maxInt64 = 0x7FFFFFFFFFFFF000 + 0xFFF;
  Expect.equals(BigInt.zero, new BigInt.from(12) >> maxInt64);
  Expect.equals(-BigInt.one, -new BigInt.from(12) >> maxInt64);
  bool exceptionCaught = false;
  try {
    var a = BigInt.one << maxInt64;
  } on OutOfMemoryError catch (e) {
    exceptionCaught = true;
  } catch (e) {
    // In JavaScript the allocation of the internal array throws different
    // kind of errors. Just assume it's the right one.
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

  const minInt64 = -0x80000000 * 0x100000000;
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

  // Regression test for http://dartbug.com/41819
  // Rounding edge case where last digit causes rounding.
  Expect.equals(-3.69616463331328e+27,
      BigInt.parse("-3696164633313280000000000000").toDouble());
  Expect.equals(-3.6961646333132803e+27,
      BigInt.parse("-3696164633313280000000000001").toDouble());
}

main() {
  for (int i = 0; i < 8; i++) {
    Expect.equals(BigInt.parse("1234567890123456789"), foo()); //# 01: ok
    Expect.equals(BigInt.parse("12345678901234567890"), bar()); //# 02: ok
    testModPow(); //# 03: ok
    testModInverse(); //# 04: ok
    testGcd(); //# 05: ok
    testSmiOverflow(); //# 06: ok
    testBigintAnd(); //# 07: ok
    testBigintOr(); //# 08: ok
    testBigintXor(); //# 09: ok
    testBigintAdd(); //# 10: ok
    testBigintSub(); //# 11: ok
    testBigintMul(); //# 12: ok
    testBigintTruncDiv(); //# 12: ok
    testBigintDiv(); //# 13: ok
    testBigintModulo(); //# 14: ok
    testBigintModPow(); //# 15: ok
    testBigintModInverse(); //# 16: ok
    testBigintGcd(); //# 17: ok
    testBigintNegate(); //# 18: ok
    testShiftAmount(); //# 19: ok
    testPow(); //# 20: ok
    testToRadixString(); //# 21: ok
    testToString(); //# 22: ok
    testFromToInt(); //# 23: ok
    testFromToDouble(); //# 24: ok
    Expect.equals(BigInt.parse("12345678901234567890"), //# 25: ok
        BigInt.parse("12345678901234567890").abs()); //# 25: ok
    Expect.equals(BigInt.parse("12345678901234567890"), //# 26: ok
        BigInt.parse("-12345678901234567890").abs()); //# 26: ok
    var a = BigInt.parse("10000000000000000000"); //# 27: ok
    var b = BigInt.parse("10000000000000000001"); //# 27: ok
    Expect.equals(false, a.hashCode == b.hashCode); //# 27: ok
    Expect.equals(true, a.hashCode == (b - BigInt.one).hashCode); //# 27: ok

    // Regression test for http://dartbug.com/36105
    var overbig = -BigInt.from(10).pow(309);
    Expect.equals(overbig.toDouble(), double.negativeInfinity);
  }
}
