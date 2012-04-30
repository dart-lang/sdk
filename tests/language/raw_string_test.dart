// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class RawStringTest {
  static testMain() {
    Expect.equals("abcd", @"abcd");
    Expect.equals("", @"");
    Expect.equals("", @'');
    Expect.equals("", @"""""");
    Expect.equals("", @'''''');
    Expect.equals("''''", @"''''");
    Expect.equals('""""', @'""""');
    Expect.equals("1\n2\n3", @"""1
2
3""");
    Expect.equals("1\n2\n3", @'''1
2
3''');
    Expect.equals("1", @"""
1""");
    Expect.equals("1", @'''
1''');
    Expect.equals("'", @"'");
    Expect.equals('"', @'"');
    Expect.equals("1", @"1");
    Expect.equals("1", @"1");
    Expect.equals("\$", @"$");
    Expect.equals("\\", @"\");
    Expect.equals("\\", @'\');
    Expect.equals("\${12}", @"${12}");
    Expect.equals("\\a\\b\\c\\d\\e\\f\\g\\h\\i\\j\\k\\l\\m",
                  @"\a\b\c\d\e\f\g\h\i\j\k\l\m");
    Expect.equals("\\n\\o\\p\\q\\r\\s\\t\\u\\v\\w\\x\\y\\z",
                  @"\n\o\p\q\r\s\t\u\v\w\x\y\z");
  }
}
main() {
  RawStringTest.testMain();
}
