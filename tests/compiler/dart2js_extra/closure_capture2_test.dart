// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

closure0() {
  // f and g will both capture a variable named 'x'. If we use the original
  // name in the (shared) box then there will be troubles.
  var f;
  var g;
  {
    var x = 499;
    f = () { return x; };
    x++;
  }
  {
    var x = 42;
    g = () { return x; };
    x++;
  }
  Expect.equals(500, f());
  Expect.equals(43, g());
}

closure1() {
  // f captures variable $0 which once could yield to troubles with HForeign if
  // we did not mangle correctly.
  var $1 = 499;
  var f = () { return $1; };
  $1++;
  Expect.equals(500, f());
}

main() {
  closure0();
  closure1();
}
