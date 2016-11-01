// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for RegExp.group.

class RegExpGroupTest {
  static testMain() {
    var match = new RegExp("(a(b)((c|de)+))").firstMatch("abcde");
    Expect.equals('abcde', match.group(0));
    Expect.equals('abcde', match.group(1));
    Expect.equals('b', match.group(2));
    Expect.equals('cde', match[3]);
    Expect.equals('de', match[4]);
  }
}

main() {
  RegExpGroupTest.testMain();
}
