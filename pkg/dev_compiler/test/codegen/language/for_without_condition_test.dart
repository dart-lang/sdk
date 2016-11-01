// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  int i = 0;
  for (;; i++) {
    if (i == 0) break;
    Expect.fail("Should not enter here");
  }
  Expect.equals(0, i);
}
