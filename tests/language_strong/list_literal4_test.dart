// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test program testing type checks in list literals.

import "package:expect/expect.dart";

class ListLiteral4Test<T> {
  test() {
    int result = 0;
    try {
      var m = <String>[0, 1]; // 0 is not a String.
    } on TypeError catch (error) {
      result += 1;
    }
    try {
      var m = <int>[0, 1];
      m["0"] = 1; // "0" is not an int.
    } on TypeError catch (error) {
      result += 10;
    }
    try {
      var m = <T>["a", "b"]; // "b" is not an int.
    } on TypeError catch (error) {
      result += 100;
    }
    try {
      var m = <T>[0, 1]; // OK.
    } on TypeError catch (error) {
      result += 1000;
    }
    try {
      var m = <T>[0, 1];
      m["0"] = 1; // "0" is not an int.
    } on TypeError catch (error) {
      result += 10000;
    }
    try {
      var m = const <int>[0, 1];
      m["0"] = 1; // "0" is not an int.
    } on TypeError catch (error) {
      result += 100000;
    }
    try {
      var m = <T>[0, 1]; // OK. Tested above.
      List<String> ls = m; // m is a List<int>, not a List<String>.
    } on TypeError catch (error) {
      result += 1000000;
    }

    return result;
  }
}

main() {
  var t = new ListLiteral4Test<int>();
  Expect.equals(1110111, t.test());
}
