// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringUnicode3NegativeTest {

  static testMain() {
    // (backslash) xXX must have exactly 2 hex digits
    String str = "Foo\x0";
    str = "Foo\xF Bar";
  }
}

main() {
  StringUnicode3NegativeTest.testMain();
}
