// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class MyAllocate {
  const MyAllocate([int value = 0]) : value_ = value;
  int getValue() {
    return value_;
  }

  final int value_;
}

class AllocateTest {
  static testMain() {
    Expect.equals(900, (new MyAllocate(900)).getValue());
  }
}

main() {
  AllocateTest.testMain();
}
