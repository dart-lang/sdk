// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import 'dart:async';
import "package:expect/expect.dart";

void check(Function f) {
  Expect.isTrue(f());
}

Future doSync() async {
  try {
    await 123;
  } finally {
    var next = 5.0;
    check(() => next == 5.0);
  }
}

main() async {
  for (int i = 0; i < 20; i++) {
    await doSync();
  }
}
