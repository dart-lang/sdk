// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing closures.

import "package:expect/expect.dart";

foo(x) {
  var y = x;
  for (int i = 0; i < 10; i++) x++;
  return y;
}

main() {
  Expect.equals(499, foo(499));
}
