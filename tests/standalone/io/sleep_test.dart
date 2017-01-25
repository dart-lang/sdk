// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:test/test.dart";

sleepTest(int milliseconds) {
  var watch = new Stopwatch();
  watch.start();
  sleep(new Duration(milliseconds: milliseconds));
  watch.stop();
  expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(milliseconds));
}

main() {
  test("zero", () {
    sleepTest(0);
  });
  test("one", () {
    sleepTest(1);
  });
  test("ten", () {
    sleepTest(10);
  });
  test("100", () {
    sleepTest(100);
  });
  test("error", () {
    bool sawError = false;
    try {
      sleep(new Duration(milliseconds: -1));
      expect(false, isTrue);  // should not reach here.
    } on ArgumentError catch(e) {
      sawError = true;
    }
    expect(sawError, isTrue);
  });
}
