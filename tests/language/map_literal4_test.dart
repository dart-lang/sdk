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
    try {
      var m = <String, String>{"a": 0}; // 0 is not a String.
    } on TypeError catch (error) {
      result += 1;
    }
    try {
      var m = <String, int>{"a": 0};
      m[2] = 1; // 2 is not a String.
    } on TypeError catch (error) {
      result += 10;
    }
    try {
      var m = <String, T>{"a": "b"}; // "b" is not an int.
    } on TypeError catch (error) {
      result += 100;
    }
    try {
      var m = <String, T>{"a": 0}; // OK.
    } on TypeError catch (error) {
      result += 1000;
    }
    try {
      var m = <String, T>{"a": 0};
      m[2] = 1; // 2 is not a String.
    } on TypeError catch (error) {
      result += 10000;
    }
    try {
      var m = const <String, int>{"a": 0};
      m[2] = 1; // 2 is not a String.
    } on TypeError catch (error) {
      result += 100000;
    }
    return result;
  }
}

main() {
  var t = new MapLiteral4Test<int>();
  Expect.equals(110111, t.test());
}
