// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ExceptionTest {
  static testMain() {
    int i = 0;
    try {
      throw "Hello";
    } on String catch (s) {
      print(s);
      i += 10;
    }

    try {
      throw "bye";
    } on String catch (s) {
      print(s);
      i += 10;
    }
    Expect.equals(20, i);

    bool correctCatch = false;
    try {
      // This throws NullThrownError
      throw null;
    } on String catch (s) {
      correctCatch = false;
    } on NullThrownError catch (e) {
      correctCatch = true;
    } catch (x) {
      correctCatch = false;
    }
    Expect.isTrue(correctCatch);
  }
}

main() {
  ExceptionTest.testMain();
}
