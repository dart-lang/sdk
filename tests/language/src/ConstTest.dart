// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check const classes.

class AConst {
  const AConst() : b_ = 3 ;
  final int b_;
}


class ConstTest {
  static testMain() {
    var o = const AConst();
    Expect.equals(3, o.b_);
  }
}

main() {
  ConstTest.testMain();
}
