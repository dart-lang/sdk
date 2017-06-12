// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

bar(x, y) {}

foo(b) {
  var x, y;
  if (b) {
    x = 1;
    y = 2;
  } else {
    x = 2;
    y = 1;
  }
  bar(x, y);
  bar(x, y);
  return x;
}

main() {
  Expect.equals(1, foo(true));
  Expect.equals(2, foo(false));
}
