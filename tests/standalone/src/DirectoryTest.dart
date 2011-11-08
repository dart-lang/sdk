// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory listing test.

class DirectoryTest {
  static void testListing() {
    bool listedSomething = false;
    Directory directory = new Directory(".");

    directory.dirHandler = (dir) {
      listedSomething = true;
    };

    directory.fileHandler = (f) {
      listedSomething = true;
    };

    directory.doneHandler = (completed) {
      Expect.isTrue(completed, "directory listing did not complete");
      Expect.isTrue(listedSomething, "empty directory");
    };

    directory.errorHandler = (error) {
      Expect.fail("error listing directory: $error");
    };

    directory.list();

    // Listing is asynchronous, so nothing should be listed at this
    // point.
    Expect.isFalse(listedSomething);
  }

  static void testExistsCreateDelete() {
    // TODO(ager): This should be creating temporary directories.
    Directory d = new Directory("____DIRECTORY_TEST_DIRECTORY____");
    Expect.isFalse(d.existsSync());
    d.createSync();
    Expect.isTrue(d.existsSync());
    d.deleteSync();
    Expect.isFalse(d.existsSync());
  }

  static void testMain() {
    testListing();
    testExistsCreateDelete();
  }
}

main() {
  DirectoryTest.testMain();
}
