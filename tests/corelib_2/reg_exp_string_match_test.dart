// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for RegExp.stringMatch.

class RegExpStringMatchTest {
  static testMain() {
    Expect.equals('cat', new RegExp("(\\w+)").stringMatch("cat dog"));
    Expect.equals(null, new RegExp("foo").stringMatch("bar"));
  }
}

main() {
  RegExpStringMatchTest.testMain();
}
