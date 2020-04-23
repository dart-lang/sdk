// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class StringEscapesTest {
  static testMain() {
    testDelimited();
    testFixed2();
    testFixed4();
    testEscapes();
    testLiteral();
  }

  static testDelimited() {
    String str = "Foo\u{1}Bar\u{000001}Baz\u{D7FF}Boo";
    Expect.equals(15, str.length);
    Expect.equals(1, str.codeUnitAt(3));
    Expect.equals(1, str.codeUnitAt(7));
    Expect.equals(0xD7FF, str.codeUnitAt(11));
    Expect.equals('B'.codeUnitAt(0), str.codeUnitAt(12));
  }

  static testEscapes() {
    String str = "Foo\fBar\vBaz\bBoo";
    Expect.equals(15, str.length);
    Expect.equals(12, str.codeUnitAt(3));
    Expect.equals('B'.codeUnitAt(0), str.codeUnitAt(4));
    Expect.equals(11, str.codeUnitAt(7));
    Expect.equals('z'.codeUnitAt(0), str.codeUnitAt(10));
    Expect.equals(8, str.codeUnitAt(11));
    Expect.equals('o'.codeUnitAt(0), str.codeUnitAt(14));
    str = "Abc\rDef\nGhi\tJkl";
    Expect.equals(15, str.length);
    Expect.equals(13, str.codeUnitAt(3));
    Expect.equals('D'.codeUnitAt(0), str.codeUnitAt(4));
    Expect.equals(10, str.codeUnitAt(7));
    Expect.equals('G'.codeUnitAt(0), str.codeUnitAt(8));
    Expect.equals(9, str.codeUnitAt(11));
    Expect.equals('J'.codeUnitAt(0), str.codeUnitAt(12));
  }

  static testFixed2() {
    String str = "Foo\xFFBar";
    Expect.equals(7, str.length);
    Expect.equals(255, str.codeUnitAt(3));
    Expect.equals('B'.codeUnitAt(0), str.codeUnitAt(4));
  }

  static testFixed4() {
    String str = "Foo\u0001Bar";
    Expect.equals(7, str.length);
    Expect.equals(1, str.codeUnitAt(3));
    Expect.equals('B'.codeUnitAt(0), str.codeUnitAt(4));
  }

  static testLiteral() {
    String str = "\a\c\d\e\g\h\i\j\k\l\$\{\}\"";
    Expect.equals(r'acdeghijkl${}"', str);
  }
}

main() {
  StringEscapesTest.testMain();
}
