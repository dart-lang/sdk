// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

// Test allocation sinking with optimized try-catch.

bar() {  // Should not be inlined.
  try {
  } finally { }
}

foo(a) {
  var r = 0;
  for (var i in a) {
    r += i;
  }
  try {
    bar();
  } finally {
  }
  return r;
}

main() {
  var a = [1,2,3];
  for (var i = 0; i < 20; i++) foo(a);
  Expect.equals(6, foo(a));
}
