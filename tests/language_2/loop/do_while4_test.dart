// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to crash in the presence of
// do/while, break and a local variable declared after the break.

import "package:expect/expect.dart";

var a = false;
main() {
  do {
    if (!a) break;
    var c = main();
    a = true;
  } while (true);
  Expect.isFalse(a);
}
