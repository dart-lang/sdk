// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory listing test.

class DirectoryTest {
  static void testListing() {
    bool listedSomething = false;
    Directory directory = new Directory(".");

    directory.setDirHandler((dir) {
      listedSomething = true;
    });

    directory.setFileHandler((f) {
      listedSomething = true;
    });

    directory.setDoneHandler((completed) {
      Expect.isTrue(completed, "directory listing did not complete");
      Expect.isTrue(listedSomething, "empty directory");
    });

    directory.setErrorHandler((error) {
      Expect.fail("error listing directory: $error");
    });

    directory.list();

    // Listing is asynchronous, so nothing should be listed at this
    // point.
    Expect.isFalse(listedSomething);
  }

  static void testMain() {
    testListing();
  }
}

main() {
  DirectoryTest.testMain();
}
