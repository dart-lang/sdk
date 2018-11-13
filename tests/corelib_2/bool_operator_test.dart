// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  void test(bool b1, bool b2) {
    var and1 = b1 && b2;
    var and2 = b1 & b2;
    var and3 = b1 ? b2 ? true : false : false;
    var or1 = b1 || b2;
    var or2 = b1 | b2;
    var or3 = b1 ? true : b2 ? true : false;
    var xor1 = b1 != b2;
    var xor2 = b1 ^ b2;
    var xor3 = b1 ? b2 ? false : true : b2 ? true : false;
    var nb1 = !b1;
    var nb2 = !b2;
    Expect.equals(and3, and1);
    Expect.equals(and3, and2);
    Expect.equals(or3, or1);
    Expect.equals(or3, or2);
    Expect.equals(xor3, xor1);
    Expect.equals(xor3, xor2);
    Expect.notEquals(nb1, b1);
    Expect.notEquals(nb2, b2);
  }

  test(true, false);
  test(true, true);
  test(false, true);
  test(false, false);

  Expect.isTrue(true || (throw "unreachable"));
  Expect.throws(() => false || (throw "unreachable"));

  Expect.isFalse(false && (throw "unreachable"));
  Expect.throws(() => true && (throw "unreachable"));

  Expect.throws(() => true | (throw "unreachable"));
  Expect.throws(() => false | (throw "unreachable"));

  Expect.throws(() => true & (throw "unreachable"));
  Expect.throws(() => false & (throw "unreachable"));
}
