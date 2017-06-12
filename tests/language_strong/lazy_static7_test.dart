// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var sideEffect = 0;
int x = (() {
  sideEffect++;
  return 499;
})();

main() {
  if (new DateTime.now().day >= -1) {
    x = 42;
  }
  Expect.equals(42, x);
  Expect.equals(0, sideEffect);
}
