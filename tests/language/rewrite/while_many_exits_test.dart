// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var baz_clicks = 0;

baz() {
  return ++baz_clicks;
}

var global = 0;

increment_global() {
  ++global;
  return global <= 10;
}

foo(x, y) {
  var n = 0;
  while (true) {
    baz();
    if (n >= x) {
      return n;
    }
    baz();
    if (n >= y) {
      return n;
    }
    n = n + 1;
  }
}

bar() {
  while (increment_global()) {
    baz();
  }
  return baz();
}

main() {
  Expect.equals(10, foo(10, 20));
  Expect.equals(10, foo(20, 10));

  baz_clicks = 0;
  Expect.equals(11, bar());
}
