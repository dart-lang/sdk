// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for RegExp.firstMatch.

class RegExpFirstMatchTest {
  static testMain() {
    Expect.equals('cat', new RegExp("(\\w+)").firstMatch("cat dog")[0]);
    Expect.equals(null, new RegExp("foo").firstMatch("bar"));
  }
}

main() {
  RegExpFirstMatchTest.testMain();
}
