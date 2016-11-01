// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for elapsed getters in stopwatch support.

import "package:expect/expect.dart";

main() {
  Stopwatch sw = new Stopwatch()..start();
  while (sw.elapsedMilliseconds < 2) {
    /* do nothing. */
  }
  sw.stop();
  Expect.equals(sw.elapsedMicroseconds, sw.elapsed.inMicroseconds);
  Expect.equals(sw.elapsedMilliseconds, sw.elapsed.inMilliseconds);
}
