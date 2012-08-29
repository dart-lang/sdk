// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

class DirectoryInvalidArgumentsTest {
  static void testFailingList(Directory d, var recursive) {
    int errors = 0;
    var lister = d.list(recursive);
    lister.onError = (error) {
      errors += 1;
    };
    lister.onDone = (completed) {
      Expect.equals(1, errors);
      Expect.isFalse(completed);
    };
    Expect.equals(0, errors);
  }

  static void testInvalidArguments() {
    Directory d = new Directory(12);
    try {
      d.existsSync();
      Expect.fail("No exception thrown");
    } catch (e) {
      Expect.isTrue(e is IllegalArgumentException);
    }
    try {
      d.deleteSync();
      Expect.fail("No exception thrown");
    } catch (e) {
      Expect.isTrue(e is IllegalArgumentException);
    }
    try {
      d.createSync();
      Expect.fail("No exception thrown");
    } catch (e) {
      Expect.isTrue(e is IllegalArgumentException);
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
