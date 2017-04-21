// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

library Prefix6NegativeTest.dart;

import "library10.dart" as lib10;

class Prefix6NegativeTest {
  static Test1() {
    // Variables in the local scope hide the library prefix.
    var lib10 = 0;
    var result = 0;
    result += lib10.Library10.static_func(); // This should fail.
  }
}

main() {
  Prefix6NegativeTest.Test1();
}
