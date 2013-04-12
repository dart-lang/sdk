// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

import "package:expect/expect.dart";

class RegExp1Test {
  static testMain() {
    RegExp exp1 = new RegExp("bar|foo");
    Expect.equals(true, exp1.hasMatch("foo"));
    Expect.equals(true, exp1.hasMatch("bar"));
    Expect.equals(false, exp1.hasMatch("gim"));
    Expect.equals(true, exp1.hasMatch("just foo"));
    Expect.equals("bar|foo", exp1.pattern);
    Expect.equals(false, exp1.isMultiLine);
    Expect.equals(true, exp1.isCaseSensitive);

    RegExp exp2 = new RegExp("o+", caseSensitive: false);
    Expect.equals(true, exp2.hasMatch("this looks good"));
    Expect.equals(true, exp2.hasMatch("fOO"));
    Expect.equals(false, exp2.hasMatch("bar"));
    Expect.equals("o+", exp2.pattern);
    Expect.equals(false, exp2.isCaseSensitive);
    Expect.equals(false, exp2.isMultiLine);
  }
}

main() {
  RegExp1Test.testMain();
}
