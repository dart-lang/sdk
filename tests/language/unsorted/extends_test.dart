// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ExtendsTestMain;

import "extends_test_lib.dart";
import "package:expect/expect.dart";

// S should extend class A from below, not the one imported
// from the library.
class S extends A {}

class A {
  var y = "class A from main script";
}

main() {
  var s = new S();
  Expect.equals("class A from main script", s.y);
}
