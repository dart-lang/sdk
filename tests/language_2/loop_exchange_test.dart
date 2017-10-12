// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// This program tripped dart2js.
main() {
  var x = 1;
  var y = 2;
  for (int i = 0; i < 2; i++) {
    if (i == 1) Expect.equals(2, x);
    var tmp = x;
    x = y;
    y = tmp;
  }
}
