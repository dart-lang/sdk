// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for closures.

import "package:expect/expect.dart";

bounce(fn) {
  return fn();
}

demo(s) {
  var i, a = bounce(() => s);
  return a;
}

main() {
  Expect.equals("Bounce!", demo("Bounce!"));
}
