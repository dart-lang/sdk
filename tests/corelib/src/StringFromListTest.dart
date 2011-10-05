// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringFromListTest {
  static testMain() {
    Expect.equals("", new String.fromCharCodes(new List(0)));
    Expect.equals("", new String.fromCharCodes([]));
    Expect.equals("", new String.fromCharCodes(const []));
    Expect.equals("AB", new String.fromCharCodes([65, 66]));
    Expect.equals("AB", new String.fromCharCodes(const [65, 66]));
    Expect.equals("", new String.fromCharCodes(new List()));
    var a = new List();
    a.add(65);
    a.add(66);
    Expect.equals("AB", new String.fromCharCodes(a));
  }
}

main() {
  StringFromListTest.testMain();
}
