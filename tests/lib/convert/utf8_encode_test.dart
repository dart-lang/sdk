// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';
import 'unicode_tests.dart';

List<int> encode(String str) => new Utf8Encoder().convert(str);
List<int> encode2(String str) => UTF8.encode(str);

void main() {
  for (var test in UNICODE_TESTS) {
    List<int> bytes = test[0];
    String string = test[1];
    Expect.listEquals(bytes, encode(string));
    Expect.listEquals(bytes, encode2(string));
  }

  testEncodeSlice();
}

void testEncodeSlice() {
  var encoder = UTF8.encoder;
  String ascii = "ABCDE";
  Expect.listEquals([0x41, 0x42, 0x43, 0x44, 0x45], encoder.convert(ascii));
  Expect.listEquals([0x41, 0x42, 0x43, 0x44, 0x45], encoder.convert(ascii, 0));
  Expect
      .listEquals([0x41, 0x42, 0x43, 0x44, 0x45], encoder.convert(ascii, 0, 5));
  Expect.listEquals([0x42, 0x43, 0x44, 0x45], encoder.convert(ascii, 1));
  Expect.listEquals([0x41, 0x42, 0x43, 0x44], encoder.convert(ascii, 0, 4));
  Expect.listEquals([0x42, 0x43, 0x44], encoder.convert(ascii, 1, 4));

  Expect.throws(() => encoder.convert(ascii, -1)); //    start < 0.
  Expect.throws(() => encoder.convert(ascii, 6)); //     start > length
  Expect.throws(() => encoder.convert(ascii, 0, -1)); // end < 0
  Expect.throws(() => encoder.convert(ascii, 0, 6)); //  end > length
  Expect.throws(() => encoder.convert(ascii, 3, 2)); //  end < start

  var unicode = "\u0081\u0082\u1041\u{10101}";

  Expect.listEquals(
      [0xc2, 0x81, 0xc2, 0x82, 0xe1, 0x81, 0x81, 0xf0, 0x90, 0x84, 0x81],
      encoder.convert(unicode));
  Expect.listEquals(
      [0xc2, 0x81, 0xc2, 0x82, 0xe1, 0x81, 0x81, 0xf0, 0x90, 0x84, 0x81],
      encoder.convert(unicode, 0, unicode.length));
  Expect.listEquals([0xc2, 0x82, 0xe1, 0x81, 0x81, 0xf0, 0x90, 0x84, 0x81],
      encoder.convert(unicode, 1));
  Expect.listEquals(
      [0xc2, 0x82, 0xe1, 0x81, 0x81], encoder.convert(unicode, 1, 3));
  // Split in the middle of a surrogate pair.
  Expect.listEquals([0xc2, 0x82, 0xe1, 0x81, 0x81, 0xed, 0xa0, 0x80],
      encoder.convert(unicode, 1, 4));
}
