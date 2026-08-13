// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class StringTrimTest {
  static testMain() {
    Expect.equals("", " ".trim());
    Expect.equals("", "     ".trim());
    var a = "      lots of space on the left";
    Expect.equals("lots of space on the left", a.trim());
    a = "lots of space on the right           ";
    Expect.equals("lots of space on the right", a.trim());
    a = "         lots of space           ";
    Expect.equals("lots of space", a.trim());
    a = "  x  ";
    Expect.equals("x", a.trim());
    Expect.equals("", " \t \n \r ".trim());
  }
}

main() {
  StringTrimTest.testMain();
}
