// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Smi
  var i = 1 << 30;
  var j = -i;
  Expect.equals(0, i >> 37);
  Expect.equals(-1, j >> 37);
  // Mint
  i = 1 << 50;
  j = -i;
  Expect.equals(0, i >> 67);
  Expect.equals(-1, j >> 67);
}
