// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

class DirectoryInvalidArgumentsTest {
  static void testFailingList(Directory d, var recursive) {
    int errors = 0;
    d.onError = (error) {
      errors += 1;
    };
    d.onDone = (completed) {
      Expect.equals(1, errors);
      Expect.isFalse(completed);
    };
    Expect.equals(0, errors);
    d.list(recursive);
  }

  static void testInvalidArguments() {
    Directory d = new Directory(12);
    Expect.isFalse(d.existsSync());
    try {
      d.deleteSync();
      Expect.fail("No exception thrown");
    } catch (var e) {
      Expect.isTrue(e is DirectoryIOException);
    }
    try {
      d.createSync();
      Expect.fail("No exception thrown");
    } catch (var e) {
      Expect.isTrue(e is DirectoryIOException);
    }
    testFailingList(d, false);
    d = new Directory(".");
    testFailingList(d, 1);
  }

  static void testMain() {
    testInvalidArguments();
  }
}

main() {
  DirectoryInvalidArgumentsTest.testMain();
}
