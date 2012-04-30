// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for testing out of range exceptions on arrays.

class IndexOutOfRangeExceptionTest {
  static testRead() {
    testListRead([], 0);
    testListRead([], -1);
    testListRead([], 1);

    var list = [1];
    testListRead(list, -1);
    testListRead(list, 1);

    list = new List(1);
    testListRead(list, -1);
    testListRead(list, 1);

    list = new List();
    testListRead(list, -1);
    testListRead(list, 0);
    testListRead(list, 1);
  }

  static testWrite() {
    testListWrite([], 0);
    testListWrite([], -1);
    testListWrite([], 1);

    var list = [1];
    testListWrite(list, -1);
    testListWrite(list, 1);

    list = new List(1);
    testListWrite(list, -1);
    testListWrite(list, 1);

    list = new List();
    testListWrite(list, -1);
    testListWrite(list, 0);
    testListWrite(list, 1);
  }

  static testMain() {
    testRead();
    testWrite();
  }

  static testListRead(list, index) {
    var exception = null;
    try {
      var e = list[index];
    } catch (IndexOutOfRangeException e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
  }

  static testListWrite(list, index) {
    var exception = null;
    try {
      list[index] = null;
    } catch (IndexOutOfRangeException e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
  }
}

main() {
  IndexOutOfRangeExceptionTest.testMain();
}
