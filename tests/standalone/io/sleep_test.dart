// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

test(int milliseconds) {
  var watch = new Stopwatch();
  watch.start();
  sleep(new Duration(milliseconds: milliseconds));
  watch.stop();
  Expect.isTrue(watch.elapsedMilliseconds + 1 >= milliseconds);
}

main() {
  test(0);
  test(1);
  test(10);
  test(100);
  Expect.throws(() => sleep(new Duration(milliseconds: -1)),
                (e) => e is ArgumentError);
}
