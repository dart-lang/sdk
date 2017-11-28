// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
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

  // Should work with iterables and non-default-lists (http://dartbug.com/8922)
  Expect.equals("CBA", new String.fromCharCodes([65, 66, 67].reversed));
  Expect.equals(
      "BCD", new String.fromCharCodes([65, 66, 67].map((x) => x + 1)));
  Expect.equals(
      "AC", new String.fromCharCodes([0x41, 0x42, 0x43].where((x) => x.isOdd)));
  Expect.equals(
      "CE",
      new String.fromCharCodes(
          [0x41, 0x42, 0x43].where((x) => x.isOdd).map((x) => x + 2)));
  Expect.equals(
      "ABC", new String.fromCharCodes(new Iterable.generate(3, (x) => 65 + x)));
  Expect.equals("ABC", new String.fromCharCodes("ABC".codeUnits));
  Expect.equals(
      "BCD", new String.fromCharCodes("ABC".codeUnits.map((x) => x + 1)));
  Expect.equals("BCD", new String.fromCharCodes("ABC".runes.map((x) => x + 1)));

  var nonBmpCharCodes = [0, 0xD812, 0xDC34, 0x14834, 0xDC34, 0xD812];
  var nonBmp = new String.fromCharCodes(nonBmpCharCodes);
  Expect.equals(7, nonBmp.length);
  Expect.equals(0, nonBmp.codeUnitAt(0));
  Expect.equals(0xD812, nonBmp.codeUnitAt(1)); // Separated surrogate pair
  Expect.equals(0xDC34, nonBmp.codeUnitAt(2));
  Expect.equals(0xD812, nonBmp.codeUnitAt(3)); // Single non-BMP code point.
  Expect.equals(0xDC34, nonBmp.codeUnitAt(4));
  Expect.equals(0xDC34, nonBmp.codeUnitAt(5)); // Unmatched surrogate.
  Expect.equals(0xD812, nonBmp.codeUnitAt(6)); // Unmatched surrogate.

  var reversedNonBmp = new String.fromCharCodes(nonBmpCharCodes.reversed);
  Expect.equals(7, reversedNonBmp.length);
  Expect.equals(0, reversedNonBmp.codeUnitAt(6));
  Expect.equals(0xD812, reversedNonBmp.codeUnitAt(5));
  Expect.equals(0xDC34, reversedNonBmp.codeUnitAt(4));
  Expect.equals(0xDC34, reversedNonBmp.codeUnitAt(3));
  Expect.equals(0xD812, reversedNonBmp.codeUnitAt(2));
  Expect.equals(0xDC34, reversedNonBmp.codeUnitAt(1));
  Expect.equals(0xD812, reversedNonBmp.codeUnitAt(0));

  Expect.equals(nonBmp, new String.fromCharCodes(nonBmp.codeUnits));
  Expect.equals(nonBmp, new String.fromCharCodes(nonBmp.runes));
}
