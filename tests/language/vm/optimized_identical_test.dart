// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test various optimizations and deoptimizations of optimizing compiler..
// VMOptions=--optimization-counter-threshold=10 --no-constant-propagation

import "package:expect/expect.dart";

// Test canonicalization of identical with double input.
// Constant propagation is disabled so that canonicalization is run
// one time less than usual.

test(a) {
  var dbl = a + 1.0;
  if (!identical(dbl, true)) {
    return "ok"; 
  }
  throw "fail";
}

main() {
  for (var i = 0; i < 20; i++) test(0);
  Expect.equals("ok", test(0));
}

