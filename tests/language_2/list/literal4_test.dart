// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ListLiteral4Test<T> {
  void test() {
    int result = 0;
    {
      var m = <String>[0, 1]; //# 00: compile-time error
    }
    {
      var m = <int>[0, 1];
      m["0"] = 1; //# 01: compile-time error
    }
    {
      var m = <T>["a" as T, "b" as T]; //# 02: runtime error
    }
    var m = <T>[0 as T, 1 as T]; // OK.
    {
      var m = <T>[0 as T, 1 as T];
      m["0"] = 1; //# 03: compile-time error
    }
    {
      var m = const <int>[0, 1];
      m["0"] = 1; //# 04: compile-time error
    }
    {
      var m = <T>[0 as T, 1 as T]; // OK. Tested above.
      List<String> ls = m; //# 05: compile-time error
    }
  }
}

main() {
  var t = new ListLiteral4Test<int>();
  t.test();
}
