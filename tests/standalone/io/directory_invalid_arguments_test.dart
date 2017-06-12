// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testFailingList(Directory d, var recursive) {
  asyncStart();
  int errors = 0;
  d
      .list(recursive: recursive)
      .listen(() => Expect.fail("Unexpected listing result"), onError: (error) {
    errors += 1;
  }, onDone: () {
    Expect.equals(1, errors);
    asyncEnd();
  });
  Expect.equals(0, errors);
}

void testInvalidArguments() {
  try {
    Directory d = new Directory(12);
    Expect.fail("No exception thrown");
  } catch (e) {
    Expect.isTrue(e is ArgumentError);
  }
  Directory d = new Directory(".");
  testFailingList(d, 1);
  Expect.throws(() => d.listSync(recursive: 1), (e) => e is ArgumentError);
}

main() {
  testInvalidArguments();
}
