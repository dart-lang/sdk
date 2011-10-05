// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we cannot use a pseudo keyword at the class level code.

// Using pseudo kw 'operator' as class name is not allowed.
class operator {
}

class PseudoKWNegativeTest {

  static testMain() {
    return 0;
  }
}


main() {
  PseudoKWNegativeTest.testMain();
}
