// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class Constants {
  static const int FIVE = 5;
}

class InterfaceConstantsTest {
  InterfaceConstantsTest() {}

  static void testMain() {
    Expect.equals(5, Constants.FIVE);
  }
}

main() {
  InterfaceConstantsTest.testMain();
}
