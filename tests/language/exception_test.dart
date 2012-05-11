// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
class ExceptionTest {
  static testMain() {
    int i = 0;
    try {
      throw "Hello";
    } catch (String s) {
      print(s);
      i += 10;
    }

    try {
      throw "bye";
    } catch (String s) {
      print(s);
      i += 10;
    }
    Expect.equals(20, i);

    bool correctCatch = false;
    try {
      // This throws NullPointerException.
      throw null;
    } catch (String s) {
      correctCatch = false;
    } catch (NullPointerException e) {
      correctCatch = true;
    } catch (var x) {
      correctCatch = false;
    }
    Expect.isTrue(correctCatch);
  }
}

main() {
  ExceptionTest.testMain();
}
