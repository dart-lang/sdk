// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-filter=foo --deoptimize_every=10 --optimization-counter-threshold=10  --no-background-compilation

// Test that lazy deoptimization on stack checks does not damage unoptimized
// frame.

import 'package:expect/expect.dart';

foo() {
  var a = 0;
  var b = 1;
  var c = 2;
  var d = 3;
  var e = 4;
  for (var i = 0; i < 10; i++) {
    a++;
    b++;
    c++;
    d++;
    e++;
  }
  Expect.equals(10, a);
  Expect.equals(11, b);
  Expect.equals(12, c);
  Expect.equals(13, d);
  Expect.equals(14, e);
}

main() {
  for (var i = 0; i < 10; ++i) {
    foo();
  }
}
