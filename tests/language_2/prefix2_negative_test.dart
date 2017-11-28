// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

library Prefix2NegativeTest.dart;

import "library2.dart" as lib2;

class Prefix2NegativeTest {
  static Main() {
    // This is a syntax error as multiple prefixes are not possible.
    return lib2.Library2.main() + lib2.lib1.foo;
  }
}

main() {
  Prefix2NegativeTest.Main();
}
