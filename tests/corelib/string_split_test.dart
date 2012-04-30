// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringSplitTest {
  static testMain() {
    var list = "a b c".split(" ");
    Expect.equals(3, list.length);
    Expect.equals("a", list[0]);
    Expect.equals("b", list[1]);
    Expect.equals("c", list[2]);

    list = "adbdc".split("d");
    Expect.equals(3, list.length);
    Expect.equals("a", list[0]);
    Expect.equals("b", list[1]);
    Expect.equals("c", list[2]);

    list = "addbddc".split("dd");
    Expect.equals(3, list.length);
    Expect.equals("a", list[0]);
    Expect.equals("b", list[1]);
    Expect.equals("c", list[2]);

    list = "abc".split(" ");
    Expect.equals(1, list.length);
    Expect.equals("abc", list[0]);

    list = "abc".split("");
    Expect.equals(3, list.length);
    Expect.equals("a", list[0]);
    Expect.equals("b", list[1]);
    Expect.equals("c", list[2]);

    list = "   ".split(" ");
    Expect.equals(4, list.length);
    Expect.equals("", list[0]);
    Expect.equals("", list[1]);
    Expect.equals("", list[2]);
    Expect.equals("", list[3]);
  }
}

main() {
  StringSplitTest.testMain();
}
