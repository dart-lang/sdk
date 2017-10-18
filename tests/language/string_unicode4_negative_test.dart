// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringUnicode4NegativeTest {

  static testMain() {
    // Unicode escapes must refer to valid Unicode points.
    String str = "Foo\u{FFFFFF}";
  }
}

main() {
  StringUnicode4NegativeTest.testMain();
}
