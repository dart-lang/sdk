// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test range inference for multiplication of two negative values.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import 'package:expect/expect.dart';

test(a) {
  var x = a ? -1 : -2;
  if (0 < (x * x)) {
    return "ok";
  } else {
    return "fail";
  }
}

main() {
  for (var j = 0; j < 20; j++) {
    Expect.equals("ok", test(false));
  }
}
