// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing integers with and without intrinsics.
// VMOptions=
// VMOptions=--no_intrinsify
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

library integer_arithmetic_test;

import "package:expect/expect.dart";

foo() => 1234567890123456789;

testSmiOverflow() {
  var a = 1073741823;
  var b = 1073741822;
  Expect.equals(2147483645, a + b);
  a = -1000000000;
  b = 1000000001;
  Expect.equals(-2000000001, a - b);
  Expect.equals(-1000000001000000000, a * b);
}

testModPow() {
  var x, e, m;
  x = 1234567890;
  e = 1000000001;
  m = 19;
  Expect.equals(11, x.modPow(e, m));
  x = 1234567890;
  e = 19;
  m = 1000000001;
  Expect.equals(122998977, x.modPow(e, m));
  x = 19;
  e = 1234567890;
  m = 1000000001;
  Expect.equals(619059596, x.modPow(e, m));
  x = 19;
  e = 1000000001;
  m = 1234567890;
  Expect.equals(84910879, x.modPow(e, m));
  x = 1000000001;
  e = 19;
  m = 1234567890;
  Expect.equals(872984351, x.modPow(e, m));
  x = 1000000001;
  e = 1234567890;
  m = 19;
  Expect.equals(0, x.modPow(e, m));
}

testModInverse() {
  var x, m;
  x = 1;
  m = 1;
  Expect.equals(0, x.modInverse(m));
  x = 0;
  m = 1000000001;
  Expect.throws(() => x.modInverse(m), (e) => e is Exception); // Not coprime.
  x = 1234567890;
  m = 19;
  Expect.equals(11, x.modInverse(m));
  x = 1234567890;
  m = 1000000001;
  Expect.equals(189108911, x.modInverse(m));
  x = 19;
  m = 1000000001;
  Expect.throws(() => x.modInverse(m), (e) => e is Exception); // Not coprime.
  x = 19;
  m = 1234567890;
  Expect.equals(519818059, x.modInverse(m));
  x = 1000000001;
  m = 1234567890;
  Expect.equals(1001100101, x.modInverse(m));
  x = 1000000001;
  m = 19;
  Expect.throws(() => x.modInverse(m), (e) => e is Exception); // Not coprime.
}

testGcd() {
  var x, m;
  x = 1;
  m = 1;
  Expect.equals(1, x.gcd(m));
  x = 693;
  m = 609;
  Expect.equals(21, x.gcd(m));
  x = 693 << 40;
  m = 609 << 40;
  Expect.equals(21 << 40, x.gcd(m));
  x = 609 << 40;
  m = 693 << 40;
  Expect.equals(21 << 40, x.gcd(m));
  x = 0;
  m = 1000000001;
  Expect.equals(m, x.gcd(m));
  x = 1000000001;
  m = 0;
  Expect.equals(x, x.gcd(m));
  x = 0;
  m = -1000000001;
  Expect.equals(-m, x.gcd(m));
  x = -1000000001;
  m = 0;
  Expect.equals(-x, x.gcd(m));
  x = 0;
  m = 0;
  Expect.equals(0, x.gcd(m));
  x = 1234567890;
  m = 19;
  Expect.equals(1, x.gcd(m));
  x = 1234567890;
  m = 1000000001;
  Expect.equals(1, x.gcd(m));
  x = 19;
  m = 1000000001;
  Expect.equals(19, x.gcd(m));
  x = 19;
  m = 1234567890;
  Expect.equals(1, x.gcd(m));
  x = 1000000001;
  m = 1234567890;
  Expect.equals(1, x.gcd(m));
  x = 1000000001;
  m = 19;
  Expect.equals(19, x.gcd(m));
}

main() {
  for (int i = 0; i < 10; i++) {
    Expect.equals(1234567890123456789, foo());
    testSmiOverflow();
    testModPow(); // //# modPow: ok
    testModInverse();
    testGcd();
  }
}
