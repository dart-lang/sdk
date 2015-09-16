// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int calls = 0;

void callMeOnce() {
  Expect.equals(0, calls);
  calls++;
}

main() {
  int i = 0;
  do {
    i++;
    if (i > 3) break;
  } while (i < 10);

  callMeOnce();
  Expect.equals(4, i);
}
