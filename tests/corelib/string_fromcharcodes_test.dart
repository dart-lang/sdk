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
    Expect.equals(expect, new String.fromCharCodes(iter, start, end));
  }
  testThrows(iterable, [start = 0, end]) {
    Expect.throws(() { new String.fromCharCodes(iterable, start, end); });
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
  test("\x00", new List(1)..[0]=0);
  test("\x00", new Uint8List(1));
  test("\x00", new Uint16List(1));
  test("\x00", new Uint32List(1));
  test("\x00", "\x00".codeUnits);

  test("\xff", iter(1, 255));
  test("\xFF", [255]);
  test("\xFF", const [255]);
  test("\xFF", new List(1)..[0]=255);
  test("\xFF", new Uint8List(1)..[0] = 255);
  test("\xFF", new Uint16List(1)..[0] = 255);
  test("\xFF", new Uint32List(1)..[0] = 255);
  test("\xFF", "\xFF".codeUnits);

  test("\u0100", iter(1, 256));
  test("\u0100", [256]);
  test("\u0100", const [256]);
  test("\u0100", new List(1)..[0]=256);
  test("\u0100", new Uint16List(1)..[0] = 256);
  test("\u0100", new Uint32List(1)..[0] = 256);
  test("\u0100", "\u0100".codeUnits);

  test("\uffff", iter(1, 65535));
  test("\uffff", [65535]);
  test("\uffff", const [65535]);
  test("\uffff", new List(1)..[0]=65535);
  test("\uffff", new Uint16List(1)..[0] = 65535);
  test("\uffff", new Uint32List(1)..[0] = 65535);
  test("\uffff", "\uffff".codeUnits);

  test("\u{10000}", iter(1, 65536));
  test("\u{10000}", [65536]);
  test("\u{10000}", const [65536]);
  test("\u{10000}", new List(1)..[0]=65536);
  test("\u{10000}", new Uint32List(1)..[0]=65536);
  test("\u{10000}", "\u{10000}".codeUnits);

  test("\u{10FFFF}", iter(1, 0x10FFFF));
  test("\u{10FFFF}", [0x10FFFF]);
  test("\u{10FFFF}", const [0x10FFFF]);
  test("\u{10FFFF}", new List(1)..[0]=0x10FFFF);
  test("\u{10FFFF}", new Uint32List(1)..[0] = 0x10FFFF);

  test("\u{10ffff}", iter(2, [0xDBFF, 0xDFFF]));
  test("\u{10ffff}", [0xDBFF, 0xDFFF]);
  test("\u{10ffff}", const [0xDBFF, 0xDFFF]);
  test("\u{10ffff}", new List(2)..[0] = 0xDBFF..[1] = 0xDFFF);
  test("\u{10ffff}", new Uint16List(2)..[0] = 0xDBFF..[1] = 0xDFFF);
  test("\u{10ffff}", new Uint32List(2)..[0] = 0xDBFF..[1] = 0xDFFF);
  test("\u{10FFFF}", "\u{10FFFF}".codeUnits);

  var leadSurrogate = "\u{10ffff}"[0];
  test(leadSurrogate, iter(1, 0xDBFF));
  test(leadSurrogate, [0xDBFF]);
  test(leadSurrogate, const [0xDBFF]);
  test(leadSurrogate, new List(1)..[0]=0xDBFF);
  test(leadSurrogate, new Uint16List(1)..[0] = 0xDBFF);
  test(leadSurrogate, new Uint32List(1)..[0] = 0xDBFF);
  test(leadSurrogate, leadSurrogate.codeUnits);

  var tailSurrogate = "\u{10ffff}"[1];
  test(tailSurrogate, iter(1, 0xDFFF));
  test(tailSurrogate, [0xDFFF]);
  test(tailSurrogate, const [0xDFFF]);
  test(tailSurrogate, new List(1)..[0]=0xDFFF);
  test(tailSurrogate, new Uint16List(1)..[0] = 0xDFFF);
  test(tailSurrogate, new Uint32List(1)..[0] = 0xDFFF);
  test(tailSurrogate, tailSurrogate.codeUnits);

  testThrows(null);
  testThrows("not an iterable");
  testThrows(42);
  testThrows([-1]);
  testThrows(new List(1)..[0] = -1);
  testThrows(const [-1]);
  //testThrows(new Int8List(1)..[0] = -1);
  testThrows(new Int16List(1)..[0] = -1);
  testThrows(new Int32List(1)..[0] = -1);
  testThrows([0x110000]);
  testThrows(new List(1)..[0] = 0x110000);
  testThrows(const [0x110000]);
  testThrows(new Int32List(1)..[0] = 0x110000);

  // Check start/end
  var list = const[0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48];
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
    test("", iterable, 9);
    // start = 0, end varies.
    test("ABCDEFGH", iterable, 0);
    test("A", iterable, 0, 1);
    test("AB", iterable, 0, 2);
    test("ABCDEFG", iterable, 0, 7);
    test("ABCDEFGH", iterable, 0, 8);
    test("ABCDEFGH", iterable, 0, 9);
    test("", iterable, 0, 0);
    test("", iterable, 0, -1);
    // Both varying.
    test("ABCDEFGH", iterable, 0, 8);
    test("ABCDEFGH", iterable, 0, 9);
    test("AB", iterable, 0, 2);
    test("GH", iterable, 6, 8);
    test("DE", iterable, 3, 5);
    test("", iterable, 3, 3);
    test("", iterable, 5, 3);
    test("", iterable, 4, -1);
    test("", iterable, 8, -1);
    test("", iterable, 0, -1);
    test("", iterable, 9, 9);
  }
  // Can split surrogates in input, but not a single big code point.
  test(leadSurrogate, [0xDBFF, 0xDFFF], 0, 1);
  test(tailSurrogate, [0xDBFF, 0xDFFF], 1);
  test("\u{10FFFF}", [0x10FFFF], 0, 1);

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
      Expect.equals(string, new String.fromCharCodes(iterable, 0, length + 1));
    }
  }

  testSubstring("");
  testSubstring("ABCDEFGH");
  // length > 128
  testSubstring("ABCDEFGH" * 33);
  testSubstring("\x00" * 357);
  // length > 128 and non-ASCII.
  testSubstring("\uFFFD\uFFFE\u{10000}\u{10ffff}c\x00" * 37);
}
