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

    Expect.equals("", new String.fromCodeUnits(new List(0)));
    Expect.equals("", new String.fromCodeUnits([]));
    Expect.equals("", new String.fromCodeUnits(const []));
    Expect.equals("AB", new String.fromCodeUnits([65, 66]));
    Expect.equals("AB", new String.fromCodeUnits(const [65, 66]));
    Expect.equals("Ærø", new String.fromCodeUnits(const [0xc6, 0x72, 0xf8]));
    Expect.equals("\u{1234}", new String.fromCodeUnits([0x1234]));
    Expect.equals("\u{12345}*", new String.fromCodeUnits([0xd808, 0xdf45, 42]));
    Expect.equals("", new String.fromCodeUnits(new List()));
    {
      var a = new List();
      a.add(65);
      a.add(66);
      Expect.equals("AB", new String.fromCodeUnits(a));
    }
  }
}

main() {
  StringFromListTest.testMain();
}
