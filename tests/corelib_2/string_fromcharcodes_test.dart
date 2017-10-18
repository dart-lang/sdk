// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:typed_data";

main() {
  iter(count, [values]) => values is List
      ? new Iterable.generate(count, (x) => values[x])
      : new Iterable.generate(count, (x) => values);
  test(expect, iter, [start = 0, end]) {
    var actual = new String.fromCharCodes(iter, start, end);
    Expect.equals(expect, actual);
  }

  testThrows(iterable, [start = 0, end]) {
    Expect.throws(() {
      new String.fromCharCodes(iterable, start, end);
    });
  }

  test("", iter(0));
  test("", []);
  test("", const []);
  test("", new List(0));
  test("", new Uint8List(0));
  test("", new Uint16List(0));
  test("", new Uint32List(0));
  test("", "".codeUnits);

  test("\x00", iter(1, 0));
  test("\x00", [0]);
  test("\x00", const [0]);
  test("\x00", new List(1)..[0] = 0);
  test("\x00", new Uint8List(1));
  test("\x00", new Uint16List(1));
  test("\x00", new Uint32List(1));
  test("\x00", "\x00".codeUnits);

  test("\xff", iter(1, 255));
  test("\xFF", [255]);
  test("\xFF", const [255]);
  test("\xFF", new List(1)..[0] = 255);
  test("\xFF", new Uint8List(1)..[0] = 255);
  test("\xFF", new Uint16List(1)..[0] = 255);
  test("\xFF", new Uint32List(1)..[0] = 255);
  test("\xFF", "\xFF".codeUnits);

  test("\u0100", iter(1, 256));
  test("\u0100", [256]);
  test("\u0100", const [256]);
  test("\u0100", new List(1)..[0] = 256);
  test("\u0100", new Uint16List(1)..[0] = 256);
  test("\u0100", new Uint32List(1)..[0] = 256);
  test("\u0100", "\u0100".codeUnits);

  test("\uffff", iter(1, 65535));
  test("\uffff", [65535]);
  test("\uffff", const [65535]);
  test("\uffff", new List(1)..[0] = 65535);
  test("\uffff", new Uint16List(1)..[0] = 65535);
  test("\uffff", new Uint32List(1)..[0] = 65535);
  test("\uffff", "\uffff".codeUnits);

  test("\u{10000}", iter(1, 65536));
  test("\u{10000}", [65536]);
  test("\u{10000}", const [65536]);
  test("\u{10000}", new List(1)..[0] = 65536);
  test("\u{10000}", new Uint32List(1)..[0] = 65536);
  test("\u{10000}", "\u{10000}".codeUnits);

  test("\u{10FFFF}", iter(1, 0x10FFFF));
  test("\u{10FFFF}", [0x10FFFF]);
  test("\u{10FFFF}", const [0x10FFFF]);
  test("\u{10FFFF}", new List(1)..[0] = 0x10FFFF);
  test("\u{10FFFF}", new Uint32List(1)..[0] = 0x10FFFF);

  test("\u{10ffff}", iter(2, [0xDBFF, 0xDFFF]));
  test("\u{10ffff}", [0xDBFF, 0xDFFF]);
  test("\u{10ffff}", const [0xDBFF, 0xDFFF]);
  test(
      "\u{10ffff}",
      new List(2)
        ..[0] = 0xDBFF
        ..[1] = 0xDFFF);
  test(
      "\u{10ffff}",
      new Uint16List(2)
        ..[0] = 0xDBFF
        ..[1] = 0xDFFF);
  test(
      "\u{10ffff}",
      new Uint32List(2)
        ..[0] = 0xDBFF
        ..[1] = 0xDFFF);
  test("\u{10FFFF}", "\u{10FFFF}".codeUnits);

  var leadSurrogate = "\u{10ffff}"[0];
  test(leadSurrogate, iter(1, 0xDBFF));
  test(leadSurrogate, [0xDBFF]);
  test(leadSurrogate, const [0xDBFF]);
  test(leadSurrogate, new List(1)..[0] = 0xDBFF);
  test(leadSurrogate, new Uint16List(1)..[0] = 0xDBFF);
  test(leadSurrogate, new Uint32List(1)..[0] = 0xDBFF);
  test(leadSurrogate, leadSurrogate.codeUnits);

  var tailSurrogate = "\u{10ffff}"[1];
  test(tailSurrogate, iter(1, 0xDFFF));
  test(tailSurrogate, [0xDFFF]);
  test(tailSurrogate, const [0xDFFF]);
  test(tailSurrogate, new List(1)..[0] = 0xDFFF);
  test(tailSurrogate, new Uint16List(1)..[0] = 0xDFFF);
  test(tailSurrogate, new Uint32List(1)..[0] = 0xDFFF);
  test(tailSurrogate, tailSurrogate.codeUnits);

  testThrows(null);
  testThrows("not an iterable");
  testThrows(42);
  testThrows([-1]);
  testThrows(new List(1)..[0] = -1);
  testThrows(const [-1]);
  testThrows(new Int8List(1)..[0] = -1);
  testThrows(new Int16List(1)..[0] = -1);
  testThrows(new Int32List(1)..[0] = -1);
  testThrows([0x110000]);
  testThrows(new List(1)..[0] = 0x110000);
  testThrows(const [0x110000]);
  testThrows(new Int32List(1)..[0] = 0x110000);

  // Check start/end
  var list = const [0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48];
  for (var iterable in [
    iter(list.length, list),
    list.toList(growable: true),
    list.toList(growable: false),
    list,
    new Uint8List(8)..setRange(0, 8, list),
    new Uint16List(8)..setRange(0, 8, list),
    new Uint32List(8)..setRange(0, 8, list),
    "ABCDEFGH".codeUnits,
  ]) {
    test("ABCDEFGH", iterable);
    // start varies, end is null.
    test("ABCDEFGH", iterable, 0);
    test("BCDEFGH", iterable, 1);
    test("H", iterable, 7);
    test("", iterable, 8);
    // start = 0, end varies.
    test("ABCDEFGH", iterable, 0);
    test("A", iterable, 0, 1);
    test("AB", iterable, 0, 2);
    test("ABCDEFG", iterable, 0, 7);
    test("ABCDEFGH", iterable, 0, 8);
    test("", iterable, 0, 0);
    // Both varying.
    test("ABCDEFGH", iterable, 0, 8);
    test("AB", iterable, 0, 2);
    test("GH", iterable, 6, 8);
    test("DE", iterable, 3, 5);
    test("", iterable, 3, 3);
  }
  // Can split surrogates in input, but not a single big code point.
  test(leadSurrogate, [0xDBFF, 0xDFFF], 0, 1);
  test(tailSurrogate, [0xDBFF, 0xDFFF], 1);
  test("\u{10FFFF}", [0x10FFFF], 0, 1);

  void testThrowsRange(iterable, [start = 0, end]) {
    Expect.throwsRangeError(
        () => new String.fromCharCodes(iterable, start, end));
  }

  // Test varying slices of the code units of a string.
  testSubstring(string) {
    var codes = string.codeUnits;
    int length = string.length;
    for (var iterable in [
      iter(length, codes),
      codes.toList(growable: true),
      codes.toList(growable: false),
      new Uint16List(length)..setRange(0, length, codes),
      new Int32List(length)..setRange(0, length, codes),
      new Uint32List(length)..setRange(0, length, codes),
      codes,
    ]) {
      var newString = new String.fromCharCodes(iterable);
      Expect.equals(string, newString);
      for (int i = 0; i < length; i = i * 2 + 1) {
        test(string.substring(i), iterable, i);
        test(string.substring(0, i), iterable, 0, i);
        for (int j = 0; i + j < length; j = j * 2 + 1) {
          test(string.substring(i, i + j), iterable, i, i + j);
        }
      }

      testThrowsRange(iterable, -1);
      testThrowsRange(iterable, 0, -1);
      testThrowsRange(iterable, 2, 1);
      testThrowsRange(iterable, 0, length + 1);
      testThrowsRange(iterable, length + 1);
      testThrowsRange(iterable, length + 1, length + 2);
    }
  }

  testSubstring("");
  testSubstring("ABCDEFGH");
  // length > 128
  testSubstring("ABCDEFGH" * 33);
  testSubstring("\x00" * 357);
  // length > 128 and non-ASCII.
  testSubstring("\uFFFD\uFFFE\u{10000}\u{10ffff}c\x00" * 37);

  // Large List.
  var megaList = ("abcde" * 200000).codeUnits.toList();
  test("abcde" * 199998, megaList, 5, 999995);
  // Large Uint8List.
  test("abcde" * 199998, new Uint8List.fromList(megaList), 5, 999995);

  const cLatin1 = const [0x00, 0xff];
  const cUtf16 = const [0x00, 0xffff, 0xdfff, 0xdbff, 0xdfff, 0xdbff];
  const cCodepoints = const [0x00, 0xffff, 0xdfff, 0x10ffff, 0xdbff];
  List gLatin1 = cLatin1.toList(growable: true);
  List gUtf16 = cUtf16.toList(growable: true);
  List gCodepoints = cCodepoints.toList(growable: true);
  List fLatin1 = cLatin1.toList(growable: false);
  List fUtf16 = cUtf16.toList(growable: false);
  List fCodepoints = cCodepoints.toList(growable: false);
  Uint8List bLatin1 = new Uint8List(2)..setRange(0, 2, cLatin1);
  Uint16List wLatin1 = new Uint16List(2)..setRange(0, 2, cLatin1);
  Uint16List wUtf16 = new Uint16List(6)..setRange(0, 6, cUtf16);
  Uint32List lLatin1 = new Uint32List(2)..setRange(0, 2, cLatin1);
  Uint32List lUtf16 = new Uint32List(6)..setRange(0, 6, cUtf16);
  Uint32List lCodepoints = new Uint32List(5)..setRange(0, 5, cCodepoints);
  Uint8List bvLatin1 = new Uint8List.view(bLatin1.buffer);
  Uint16List wvLatin1 = new Uint16List.view(wLatin1.buffer);
  Uint16List wvUtf16 = new Uint16List.view(wUtf16.buffer);
  Uint32List lvLatin1 = new Uint32List.view(lLatin1.buffer);
  Uint32List lvUtf16 = new Uint32List.view(lUtf16.buffer);
  Uint32List lvCodepoints = new Uint32List.view(lCodepoints.buffer);
  var buffer = new Uint8List(200).buffer;
  Uint8List bbLatin1 = new Uint8List.view(buffer, 3, 2)..setAll(0, bLatin1);
  Uint16List wbLatin1 = new Uint16List.view(buffer, 8, 2)..setAll(0, wLatin1);
  Uint16List wbUtf16 = new Uint16List.view(buffer, 16, 6)..setAll(0, wUtf16);
  Uint32List lbLatin1 = new Uint32List.view(buffer, 32, 2)..setAll(0, lLatin1);
  Uint32List lbUtf16 = new Uint32List.view(buffer, 64, 6)..setAll(0, lUtf16);
  Uint32List lbCodepoints = new Uint32List.view(buffer, 128, 5)
    ..setAll(0, lCodepoints);

  String sLatin1 = "\x00\xff";
  String sUnicode =
      "\x00\uffff$tailSurrogate$leadSurrogate$tailSurrogate$leadSurrogate";
  for (int i = 0; i < 2; i++) {
    for (int j = i + 1; j < 2; j++) {
      test(sLatin1.substring(i, j), cLatin1, i, j);
      test(sLatin1.substring(i, j), gLatin1, i, j);
      test(sLatin1.substring(i, j), fLatin1, i, j);
      test(sLatin1.substring(i, j), bLatin1, i, j);
      test(sLatin1.substring(i, j), wLatin1, i, j);
      test(sLatin1.substring(i, j), lLatin1, i, j);
      test(sLatin1.substring(i, j), bvLatin1, i, j);
      test(sLatin1.substring(i, j), wvLatin1, i, j);
      test(sLatin1.substring(i, j), lvLatin1, i, j);
      test(sLatin1.substring(i, j), bbLatin1, i, j);
      test(sLatin1.substring(i, j), wbLatin1, i, j);
      test(sLatin1.substring(i, j), lbLatin1, i, j);
    }
  }
  for (int i = 0; i < 6; i++) {
    for (int j = i + 1; j < 6; j++) {
      test(sUnicode.substring(i, j), cUtf16, i, j);
      test(sUnicode.substring(i, j), gUtf16, i, j);
      test(sUnicode.substring(i, j), fUtf16, i, j);
      test(sUnicode.substring(i, j), wUtf16, i, j);
      test(sUnicode.substring(i, j), lUtf16, i, j);
      test(sUnicode.substring(i, j), wvUtf16, i, j);
      test(sUnicode.substring(i, j), lvUtf16, i, j);
      test(sUnicode.substring(i, j), wbUtf16, i, j);
      test(sUnicode.substring(i, j), lbUtf16, i, j);
    }
  }
  for (int i = 0; i < 5; i++) {
    for (int j = i + 1; j < 5; j++) {
      int stringEnd = j < 4 ? j : j + 1;
      test(sUnicode.substring(i, stringEnd), cCodepoints, i, j);
      test(sUnicode.substring(i, stringEnd), gCodepoints, i, j);
      test(sUnicode.substring(i, stringEnd), fCodepoints, i, j);
      test(sUnicode.substring(i, stringEnd), lCodepoints, i, j);
      test(sUnicode.substring(i, stringEnd), lvCodepoints, i, j);
      test(sUnicode.substring(i, stringEnd), lbCodepoints, i, j);
    }
  }
}
