// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import "package:expect/expect.dart";

// Test correct polymorphic inlining of recognized methods like list access.

test(arr) {
  var r = 0;
  for (var i = 0; i < 1; ++i) {
    r += arr[0];
  }
  return r;
}

main() {
  var a = new List<int>(1);
  a[0] = 0;
  var b = <int>[0];
  Expect.equals(0, test(a));
  Expect.equals(0, test(b));
  for (var i = 0; i < 20; ++i) test(a);
  Expect.equals(0, test(a));
  Expect.equals(0, test(b));
}
