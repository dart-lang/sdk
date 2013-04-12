// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for RegExp.hasMatch.

class RegExpHasMatchTest {
  static testMain() {
    Expect.equals(false, new RegExp("bar").hasMatch("foo"));
    Expect.equals(true, new RegExp("bar|foo").hasMatch("foo"));
    Expect.equals(true, new RegExp("o+").hasMatch("foo"));
  }
}

main() {
  RegExpHasMatchTest.testMain();
}
