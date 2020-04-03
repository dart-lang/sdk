// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test program testing type checks in map literals.

import "package:expect/expect.dart";

class MapLiteral4Test<T> {
  test() {
    int result = 0;
    var m = <String, String>{"a": 0}; //# 01: compile-time error
    var m = <String, int>{"a": 0}; //# 02: ok
    m[2] = 1; //# 02: compile-time error
    var m = <String, T>{"a": "b"}; //# 03: compile-time error
    var m = <String, T>{"a": 0}; //# 04: compile-time error
    var m = <String, T>{"a": 0}; //# 05: continued
    m[2] = 1; //# 05: compile-time error
    var m = const <String, int>{"a": 0}; //# 06: continued
    m[2] = 1; //# 06: compile-time error
  }
}

main() {
  var t = new MapLiteral4Test<int>();
}
