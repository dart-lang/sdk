// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

// Test optimization and polymorphic inlining of String.isEmpty.

import "package:expect/expect.dart";

test(s) => s.isEmpty;

main() {
  var x = "abc";
  var y = [123, 12345, 765];
  Expect.equals(false, test(x));
  Expect.equals(false, test(y));
  for (var i = 0; i < 20; i++) test(x);
  Expect.equals(false, test(x));
  Expect.equals(false, test(y));
}
