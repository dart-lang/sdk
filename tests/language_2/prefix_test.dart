// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library PrefixTest.dart;

import "package:expect/expect.dart";
import "prefix_test1.dart";

class PrefixTest {
  static testMain() {
    Expect.equals(Prefix.getSource(), Prefix.getImport() + 1);
  }
}

main() {
  PrefixTest.testMain();
}
