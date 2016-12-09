// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const x = true;
const g1 = !true;
const g2 = !g1;

main() {
  Expect.equals(false, g1);
  Expect.equals(true, g2);
}
