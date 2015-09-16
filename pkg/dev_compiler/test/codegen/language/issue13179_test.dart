// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int count = 0;

void f([void f([x]) = f]) {
  count++;
  if (f != null) {
    f(null);
  }
}

main() {
  f();
  Expect.equals(2, count);
}
