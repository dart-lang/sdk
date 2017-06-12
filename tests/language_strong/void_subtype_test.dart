// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for type checks involving the void type.

import "package:expect/expect.dart";

var _str = new StringBuffer();

/*=T*/ run/*<T>*/(/*=T*/ f()) {
  _str.write("+");
  var t = f();
  _str.write("-");
  return t;
}

void writeV() {
  _str.write("V");
}

main() {
  {
    var x = run/*<dynamic>*/(writeV);
    Expect.equals('+V-', _str.toString());
    Expect.equals(null, x);
    _str.clear();

    var y = run(writeV);
    Expect.equals('+V-', _str.toString());
    Expect.equals(null, y);
    _str.clear();
  }

  // implicit cast
  {
    dynamic d = writeV;
    var x = run/*<dynamic>*/(d);
    Expect.equals('+V-', _str.toString());
    Expect.equals(null, x);
    _str.clear();

    var y = run(d);
    Expect.equals('+V-', _str.toString());
    Expect.equals(null, y);
    _str.clear();
  }

  // dynamic dispatch
  {
    dynamic d = run;
    var x = d/*<dynamic>*/(writeV);
    Expect.equals('+V-', _str.toString());
    Expect.equals(null, x);
    _str.clear();

    var y = d(writeV);
    Expect.equals('+V-', _str.toString());
    Expect.equals(null, y);
    _str.clear();
  }
}
