// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var sum = 0;
var foo = 0;
var bar = 1;

test() {
  while (true) {
    if (0 == foo) {
      sum += 2;
      if (1 == bar) {
        sum += 3;
        break;
      }
      break;
    }
  }
}

main() {
  test();
  Expect.equals(5, sum);
}
