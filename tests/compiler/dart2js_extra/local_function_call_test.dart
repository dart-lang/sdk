// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that global type inference computes the correct type for .call on
// a closure.

import "package:expect/expect.dart";

main() {
  var f = (int n) => n + 1;
  f.call(0);
  Expect.equals(true, f.toString().startsWith("Closure"));
}
