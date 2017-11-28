// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  test(String s, List<int> expectedRunes) {
    Runes runes = s.runes;
    Expect.identical(s, runes.string);

    // for-in
    var res = [];
    for (int rune in runes) {
      res.add(rune);
    }
    Expect.listEquals(expectedRunes, res);

    // manual iteration, backwards.
    res = [];
    for (var it = runes.iterator..reset(s.length); it.movePrevious();) {
      res.add(it.current);
    }
    Expect.listEquals(expectedRunes.reversed.toList(), res);

    // Setting rawIndex.
    RuneIterator it = runes.iterator;
    it.rawIndex = 1;
    Expect.equals(expectedRunes[1], it.current);

    it = runes.iterator;
    it.moveNext();
    Expect.equals(0, it.rawIndex);
    it.moveNext();
    Expect.equals(1, it.rawIndex);
    it.moveNext();
    Expect.isTrue(1 < it.rawIndex);
    it.rawIndex = 1;
    Expect.equals(1, it.rawIndex);
    Expect.equals(expectedRunes[1], it.current);

    // Reset, moveNext.
    it.reset(1);
    Expect.equals(null, it.rawIndex);
    Expect.equals(null, it.current);
    it.moveNext();
    Expect.equals(1, it.rawIndex);
    Expect.equals(expectedRunes[1], it.current);

    // Reset, movePrevious.
    it.reset(1);
    Expect.equals(null, it.rawIndex);
    Expect.equals(null, it.current);
    it.movePrevious();
    Expect.equals(0, it.rawIndex);
    Expect.equals(expectedRunes[0], it.current);

    // .map
    Expect.listEquals(expectedRunes.map((x) => x.toRadixString(16)).toList(),
        runes.map((x) => x.toRadixString(16)).toList());
  }

  // First character must be single-code-unit for test.
  test("abc", [0x61, 0x62, 0x63]);
  test("\x00\u0000\u{000000}", [0, 0, 0]);
  test("\u{ffff}\u{10000}\u{10ffff}", [0xffff, 0x10000, 0x10ffff]);
  String string = new String.fromCharCodes(
      [0xdc00, 0xd800, 61, 0xd800, 0xdc00, 62, 0xdc00, 0xd800]);
  test(string, [0xdc00, 0xd800, 61, 0x10000, 62, 0xdc00, 0xd800]);

  // Setting position in the middle of a surrogate pair is not allowed.
  var r = new Runes("\u{10000}");
  var it = r.iterator;
  it.moveNext();
  Expect.equals(0x10000, it.current);

  // Setting rawIndex inside surrogate pair.
  Expect.throws(() {
    it.rawIndex = 1;
  }, (e) => e is Error);
  Expect.throws(() {
    it.reset(1);
  }, (e) => e is Error);
}
