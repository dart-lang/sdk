// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for RegExp.groups.

class RegExpGroupsTest {
  static testMain() {
    var match = new RegExp("(a(b)((c|de)+))").firstMatch("abcde");
    var groups = match.groups([0, 4, 2, 3]);
    Expect.equals('abcde', groups[0]);
    Expect.equals('de', groups[1]);
    Expect.equals('b', groups[2]);
    Expect.equals('cde', groups[3]);
  }
}

main() {
  RegExpGroupsTest.testMain();
}
