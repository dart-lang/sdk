// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test program testing type checks in list literals.

class ListLiteral1NegativeTest {
  test() {
    try {
      var m = const <String>[0, 1];  // 0 is not a String.
    } catch (TypeError error) {
    }
  }
}

main() {
  var t = new ListLiteral1NegativeTest();
  t.test();
}


