// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';
import 'unicode_tests.dart';

String decode(List<int> bytes) => new Utf8Decoder().convert(bytes);

void main() {
  for (var test in UNICODE_TESTS) {
    List<int> bytes = test[0];
    String expected = test[1];
    Expect.stringEquals(expected, decode(bytes));
  }

  testDecodeSlice();
}

void testDecodeSlice() {
  var decoder = UTF8.decoder;  // Doesn't allow malformed.
  var ascii = [0x41, 0x42, 0x43, 0x44, 0x45];
  Expect.equals("ABCDE", decoder.convert(ascii));
  Expect.equals("ABCDE", decoder.convert(ascii, 0));
  Expect.equals("ABCDE", decoder.convert(ascii, 0, ascii.length));
  Expect.equals("CDE", decoder.convert(ascii, 2));
  Expect.equals("BCD", decoder.convert(ascii, 1, 4));
  Expect.equals("ABCD", decoder.convert(ascii, 0, 4));

  Expect.throws(() => decoder.convert(ascii, -1));    // start < 0.
  Expect.throws(() => decoder.convert(ascii, 6));     // start > length
  Expect.throws(() => decoder.convert(ascii, 0, -1)); // end < 0
  Expect.throws(() => decoder.convert(ascii, 0, 6));  // end > length
  Expect.throws(() => decoder.convert(ascii, 3, 2));  // end < start

  var utf8 = [0xc2, 0x81, 0xc2, 0x82, 0xe1, 0x81, 0x81];
  Expect.equals("\u0081\u0082\u1041", decoder.convert(utf8));
  Expect.equals("\u0082\u1041", decoder.convert(utf8, 2));
  Expect.equals("\u0081\u0082", decoder.convert(utf8, 0, 4));
  Expect.equals("\u0082", decoder.convert(utf8, 2, 4));
  Expect.throws(() => decoder.convert(utf8, 1));
  Expect.throws(() => decoder.convert(utf8, 0, 1));
  Expect.throws(() => decoder.convert(utf8, 2, 5));
}
