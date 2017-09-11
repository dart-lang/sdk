// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: This test relies on LF line endings in the source file.
// It requires an entry in the .gitattributes file.

import "package:expect/expect.dart";

class RawStringTest {
  static testMain() {
    Expect.equals("abcd", r"abcd");
    Expect.equals("", r"");
    Expect.equals("", r'');
    Expect.equals("", r"""""");
    Expect.equals("", r'''''');
    Expect.equals("''''", r"''''");
    Expect.equals('""""', r'""""');
    Expect.equals(
        "1\n2\n3",
        r"""1
2
3""");
    Expect.equals(
        "1\n2\n3",
        r'''1
2
3''');
    Expect.equals(
        "1",
        r"""
1""");
    Expect.equals(
        "1",
        r'''
1''');
    Expect.equals("'", r"'");
    Expect.equals('"', r'"');
    Expect.equals("1", r"1");
    Expect.equals("1", r"1");
    Expect.equals("\$", r"$");
    Expect.equals("\\", r"\");
    Expect.equals("\\", r'\');
    Expect.equals("\${12}", r"${12}");
    Expect.equals("\\a\\b\\c\\d\\e\\f\\g\\h\\i\\j\\k\\l\\m",
        r"\a\b\c\d\e\f\g\h\i\j\k\l\m");
    Expect.equals("\\n\\o\\p\\q\\r\\s\\t\\u\\v\\w\\x\\y\\z",
        r"\n\o\p\q\r\s\t\u\v\w\x\y\z");
  }
}

main() {
  RawStringTest.testMain();
}
