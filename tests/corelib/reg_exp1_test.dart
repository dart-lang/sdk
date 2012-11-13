// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

class RegExp1Test {
  static testMain() {
    RegExp exp1 = const RegExp("bar|foo");
    Expect.equals(true, exp1.hasMatch("foo"));
    Expect.equals(true, exp1.hasMatch("bar"));
    Expect.equals(false, exp1.hasMatch("gim"));
    Expect.equals(true, exp1.hasMatch("just foo"));
    Expect.equals("bar|foo", exp1.pattern);
    Expect.equals(false, exp1.multiLine);
    Expect.equals(false, exp1.ignoreCase);

    RegExp exp2 = const RegExp("o+", ignoreCase: true);
    Expect.equals(true, exp2.hasMatch("this looks good"));
    Expect.equals(true, exp2.hasMatch("fOO"));
    Expect.equals(false, exp2.hasMatch("bar"));
    Expect.equals("o+", exp2.pattern);
    Expect.equals(true, exp2.ignoreCase);
    Expect.equals(false, exp2.multiLine);
  }
}

main() {
  RegExp1Test.testMain();
}
