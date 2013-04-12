// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";

void testFailingList(Directory d, var recursive) {
  var port = new ReceivePort();
  int errors = 0;
  d.list(recursive: recursive).listen(
    () => Expect.fail("Unexpected listing result"),
    onError: (error) {
      errors += 1;
    },
    onDone: () {
      port.close();
      Expect.equals(1, errors);
    });
  Expect.equals(0, errors);
}

void testInvalidArguments() {
  Directory d = new Directory(12);
  try {
    d.existsSync();
    Expect.fail("No exception thrown");
  } catch (e) {
    Expect.isTrue(e is ArgumentError);
  }
  try {
    d.deleteSync();
    Expect.fail("No exception thrown");
  } catch (e) {
    Expect.isTrue(e is ArgumentError);
  }
  try {
    d.createSync();
    Expect.fail("No exception thrown");
  } catch (e) {
    Expect.isTrue(e is ArgumentError);
  }
  testFailingList(d, false);
  Expect.throws(() => d.listSync(recursive: true),
                (e) => e is ArgumentError);
  d = new Directory(".");
  testFailingList(d, 1);
  Expect.throws(() => d.listSync(recursive: 1),
                (e) => e is ArgumentError);
}

main() {
  testInvalidArguments();
}
