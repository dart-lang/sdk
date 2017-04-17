// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// This test should fail to load because the app file references a
// library spec file that does not exist.

library LibraryNegativeTest.dart;

import "nonexisting_library.lib";

main(args) {
  LibraryNegativeTest.testMain(args);
}

class LibraryNegativeTest {
  static testMain() {
    print("Er, hello world? This should not be printed!");
  }
}

main() {
  LibraryNegativeTest.testMain();
}
