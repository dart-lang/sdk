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
    Expect.equals("Ærø", new String.fromCharCodes(const [0xc6, 0x72, 0xf8]));
    Expect.equals("\u{1234}", new String.fromCharCodes([0x1234]));
    Expect.equals("\u{12345}*", new String.fromCharCodes([0x12345, 42]));
    Expect.equals("", new String.fromCharCodes(new List()));
    {
      var a = new List();
      a.add(65);
      a.add(66);
      Expect.equals("AB", new String.fromCharCodes(a));
    }

    // Long list (bug 6919).
    for (int len in [499, 500, 501, 999, 100000]) {
      List<int> list = new List(len);
      for (int i = 0; i < len; i++) {
        list[i] = 65 + (i % 26);
      }
      for (int i = len - 9; i < len; i++) {
        list[i] = 48 + (len - i);
      }
      // We should not throw a stack overflow here.
      String long = new String.fromCharCodes(list);
      // Minimal sanity checking on the string.
      Expect.isTrue(long.startsWith('ABCDE'));
      Expect.isTrue(long.endsWith('987654321'));
      int middle = len ~/ 2;
      middle -= middle % 26;
      Expect.equals('XYZABC', long.substring(middle - 3, middle + 3));
      Expect.equals(len, long.length);
    }
  }
}

main() {
  StringFromListTest.testMain();
}
