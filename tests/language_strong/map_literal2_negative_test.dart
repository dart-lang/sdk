// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test program const map literals.

class MapLiteral2NegativeTest<T> {
  test() {
    try {
      var m = const <String, T>{"a": 0}; // Type parameter is not allowed with
      // const.
    } on TypeError catch (error) {}
  }
}

main() {
  var t = new MapLiteral2NegativeTest<int>();
  t.test();
}
