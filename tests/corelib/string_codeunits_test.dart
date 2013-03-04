// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  test(String s) {
    Iterable<int> units = s.codeUnits;
    List<int> expectedUnits = <int>[];
    for (int i = 0; i < s.length; i++) {
      expectedUnits.add(s.codeUnitAt(i));
    }

    Expect.equals(s.length, units.length);
    for (int i = 0; i < s.length; i++) {
      Expect.equals(s.codeUnitAt(i), units.elementAt(i));
    }

    // for-in
    var res = [];
    for (int unit in units) {
      res.add(unit);
    }
    Expect.listEquals(expectedUnits, res);

    // .map
    Expect.listEquals(expectedUnits.map((x) => x.toRadixString(16)).toList(),
                      units.map((x) => x.toRadixString(16)).toList());
  }

  test("abc");
  test("\x00\u0000\u{000000}");
  test("\u{ffff}\u{10000}\u{10ffff}");
  String string = new String.fromCharCodes(
      [0xdc00, 0xd800, 61, 0xd9ab, 0xd9ab, 0xddef, 0xddef, 62, 0xdc00, 0xd800]);
  test(string);
  string = "\x00\x7f\xff\u0100\ufeff\uffef\uffff"
           "\u{10000}\u{12345}\u{1d800}\u{1dc00}\u{1ffef}\u{1ffff}";
  test(string);

  // Reading each unit of a surrogate pair works.
  var r = "\u{10000}".codeUnits;
  var it = r.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(0xD800, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(0xDC00, it.current);
}
