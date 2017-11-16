// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';
import 'dart:typed_data' show Uint8List;
import 'unicode_tests.dart';

String decode(List<int> bytes) => new Utf8Decoder().convert(bytes);

void main() {
  for (var test in UNICODE_TESTS) {
    List<int> bytes = test[0];
    String expected = test[1];
    Expect.stringEquals(expected, decode(bytes));
    Expect.stringEquals(expected, decode(new Uint8List.fromList(bytes)));
  }

  testDecodeSlice();
  testErrorOffset();
}

void testDecodeSlice() {
  var decoder = utf8.decoder; // Doesn't allow malformed.

  testAscii(List<int> ascii) {
    Expect.equals("ABCDE", decoder.convert(ascii));
    Expect.equals("ABCDE", decoder.convert(ascii, 0));
    Expect.equals("ABCDE", decoder.convert(ascii, 0, ascii.length));
    Expect.equals("CDE", decoder.convert(ascii, 2));
    Expect.equals("BCD", decoder.convert(ascii, 1, 4));
    Expect.equals("ABCD", decoder.convert(ascii, 0, 4));

    Expect.throws(() => decoder.convert(ascii, -1)); //    start < 0.
    Expect.throws(() => decoder.convert(ascii, 6)); //     start > length
    Expect.throws(() => decoder.convert(ascii, 0, -1)); // end < 0
    Expect.throws(() => decoder.convert(ascii, 0, 6)); // end > length
    Expect.throws(() => decoder.convert(ascii, 3, 2)); // end < start
  }

  var ascii = [0x41, 0x42, 0x43, 0x44, 0x45];
  testAscii(ascii);
  testAscii(new Uint8List.fromList(ascii));

  testUtf8(List<int> utf8) {
    Expect.equals("\u0081\u0082\u1041", decoder.convert(utf8));
    Expect.equals("\u0082\u1041", decoder.convert(utf8, 2));
    Expect.equals("\u0081\u0082", decoder.convert(utf8, 0, 4));
    Expect.equals("\u0082", decoder.convert(utf8, 2, 4));
    Expect.throws(() => decoder.convert(utf8, 1));
    Expect.throws(() => decoder.convert(utf8, 0, 1));
    Expect.throws(() => decoder.convert(utf8, 2, 5));
  }

  var utf8 = [0xc2, 0x81, 0xc2, 0x82, 0xe1, 0x81, 0x81];
  testUtf8(utf8);
  testUtf8(new Uint8List.fromList(utf8));
}

void testErrorOffset() {
  // Test that failed convert calls have an offset in the exception.
  testExn(input, offset) {
    Expect.throws(() {
      utf8.decoder.convert(input);
    }, (e) => e is FormatException && input == e.source && offset == e.offset);

    var typed = new Uint8List.fromList(input);
    Expect.throws(() {
      UTF8.decoder.convert(typed);
    }, (e) => e is FormatException && typed == e.source && offset == e.offset);
  }

  // Bad encoding, points to first bad byte.
  testExn([0x80, 0x00], 0);
  testExn([0xC0, 0x00], 1);
  testExn([0xE0, 0x00], 1);
  testExn([0xE0, 0x80, 0x00], 2);
  testExn([0xF0, 0x00], 1);
  testExn([0xF0, 0x80, 0x00], 2);
  testExn([0xF0, 0x80, 0x80, 0x00], 3);
  testExn([0xF8, 0x00], 0);
  // Short encoding, points to end.
  testExn([0xC0], 1);
  testExn([0xE0], 1);
  testExn([0xE0, 0x80], 2);
  testExn([0xF0], 1);
  testExn([0xF0, 0x80], 2);
  testExn([0xF0, 0x80, 0x80], 3);
  // Overlong encoding, points to start of encoding.
  testExn([0xC0, 0x80], 0);
  testExn([0xC1, 0xBF], 0);
  testExn([0xE0, 0x80, 0x80], 0);
  testExn([0xE0, 0x9F, 0xBF], 0);
  testExn([0xF0, 0x80, 0x80, 0x80], 0);
  testExn([0xF0, 0x8F, 0xBF, 0xBF], 0);
  // Invalid character (value too large, over 0x10FFFF).
  testExn([0xF4, 0x90, 0x80, 0x80], 0);
  testExn([0xF7, 0xBF, 0xBF, 0xBF], 0);
}
