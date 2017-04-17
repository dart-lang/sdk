// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library LibraryPrefixesTest.dart;

import "package:expect/expect.dart";
import "library_prefixes.lib";

class LibraryPrefixesTest {
  static testMain() {
    LibraryPrefixes.main((a, b) {
      Expect.equals(a, b);
    });
  }
}

main() {
  LibraryPrefixesTest.testMain();
}
