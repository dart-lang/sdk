// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

library Prefix1NegativeTest.dart;

import "library1.dart";

class Prefix1NegativeTest {
  static Main() {
    // This is a syntax error as library1 was not imported with a prefix.
    return library1.foo;
  }
}

main() {
  Prefix1NegativeTest.Main();
}
