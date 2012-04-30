// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringUnicode1NegativeTest {

  static testMain() {
    // (backslash) uXXXX must have exactly 4 hex digits
    String str = "Foo\u00";
    str = "Foo\uDEEMBar";
  }
}

main() {
  StringUnicode1NegativeTest.testMain();
}
