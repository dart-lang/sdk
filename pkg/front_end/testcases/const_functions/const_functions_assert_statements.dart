// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests assert statements with const functions.

import "package:expect/expect.dart";

const var1 = fn();
int fn() {
  int x = 0;
  assert(x == 0, "fail");
  return x;
}

void main() {
  Expect.equals(var1, 0);
}
