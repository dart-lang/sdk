// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test program const map literals.

class MapLiteral2NegativeTest<T> {
  test() {
    var m = const <String, T>{"a": 0}; /*@compile-error=unspecified*/
  }
}

main() {
  var t = new MapLiteral2NegativeTest<int>();
  t.test();
}
