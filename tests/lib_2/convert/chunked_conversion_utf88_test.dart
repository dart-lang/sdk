// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf8_test;

import "package:expect/expect.dart";
import 'dart:convert';

List<int> encode(String str) {
  List<int> bytes;
  var byteSink =
      new ByteConversionSink.withCallback((result) => bytes = result);
  var stringConversionSink = new Utf8Encoder().startChunkedConversion(byteSink);
  stringConversionSink.add(str);
  stringConversionSink.close();
  return bytes;
}

List<int> encode2(String str) {
  List<int> bytes;
  var byteSink =
      new ByteConversionSink.withCallback((result) => bytes = result);
  var stringConversionSink = new Utf8Encoder().startChunkedConversion(byteSink);
  ClosableStringSink stringSink = stringConversionSink.asStringSink();
  stringSink.write(str);
  stringSink.close();
  return bytes;
}

List<int> encode3(String str) {
  List<int> bytes;
  var byteSink =
      new ByteConversionSink.withCallback((result) => bytes = result);
  var stringConversionSink = new Utf8Encoder().startChunkedConversion(byteSink);
  ClosableStringSink stringSink = stringConversionSink.asStringSink();
  str.codeUnits.forEach(stringSink.writeCharCode);
  stringSink.close();
  return bytes;
}

List<int> encode4(String str) {
  List<int> bytes;
  var byteSink =
      new ByteConversionSink.withCallback((result) => bytes = result);
  var stringConversionSink = new Utf8Encoder().startChunkedConversion(byteSink);
  ClosableStringSink stringSink = stringConversionSink.asStringSink();
  str.runes.forEach(stringSink.writeCharCode);
  stringSink.close();
  return bytes;
}

List<int> encode5(String str) {
  List<int> bytes;
  var byteSink =
      new ByteConversionSink.withCallback((result) => bytes = result);
  var stringConversionSink = new Utf8Encoder().startChunkedConversion(byteSink);
  ByteConversionSink inputByteSink = stringConversionSink.asUtf8Sink(false);
  List<int> tmpBytes = utf8.encode(str);
  inputByteSink.add(tmpBytes);
  inputByteSink.close();
  return bytes;
}

List<int> encode6(String str) {
  List<int> bytes;
  var byteSink =
      new ByteConversionSink.withCallback((result) => bytes = result);
  var stringConversionSink = new Utf8Encoder().startChunkedConversion(byteSink);
  ByteConversionSink inputByteSink = stringConversionSink.asUtf8Sink(false);
  List<int> tmpBytes = utf8.encode(str);
  tmpBytes.forEach((b) => inputByteSink.addSlice([0, b, 1], 1, 2, false));
  inputByteSink.close();
  return bytes;
}

List<int> encode7(String str) {
  List<int> bytes;
  var byteSink =
      new ByteConversionSink.withCallback((result) => bytes = result);
  var stringConversionSink = new Utf8Encoder().startChunkedConversion(byteSink);
  stringConversionSink.addSlice("1" + str + "2", 1, str.length + 1, false);
  stringConversionSink.close();
  return bytes;
}

int _nextPowerOf2(v) {
  assert(v > 0);
  v--;
  v |= v >> 1;
  v |= v >> 2;
  v |= v >> 4;
  v |= v >> 8;
  v |= v >> 16;
  v++;
  return v;
}

runTest(test) {
  List<int> bytes = test[0];
  String string = test[1];
  Expect.listEquals(bytes, encode(string));
  Expect.listEquals(bytes, encode2(string));
  Expect.listEquals(bytes, encode3(string));
  Expect.listEquals(bytes, encode4(string));
  Expect.listEquals(bytes, encode5(string));
  Expect.listEquals(bytes, encode6(string));
  Expect.listEquals(bytes, encode7(string));
}

main() {
  const LEADING_SURROGATE = 0xd801;
  const TRAILING_SURROGATE = 0xdc12;
  const UTF8_ENCODING = const [0xf0, 0x90, 0x90, 0x92];
  const UTF8_LEADING = const [0xed, 0xa0, 0x81];
  const UTF8_TRAILING = const [0xed, 0xb0, 0x92];
  const CHAR_A = 0x61;

  // Test surrogates at all kinds of locations.
  var tests = [];
  var codeUnits = <int>[];
  for (int i = 0; i < 2049; i++) {
    // Invariant: codeUnits[0..i - 1] is filled with CHAR_A (character 'a').
    codeUnits.length = i + 1;
    codeUnits[i] = CHAR_A;

    // Only test for problem zones, close to powers of two.
    if (i > 20 && _nextPowerOf2(i - 2) - i > 10) continue;

    codeUnits[i] = LEADING_SURROGATE;
    var str = new String.fromCharCodes(codeUnits);
    var bytes = new List.filled(i + 3, CHAR_A);
    bytes[i] = UTF8_LEADING[0];
    bytes[i + 1] = UTF8_LEADING[1];
    bytes[i + 2] = UTF8_LEADING[2];
    runTest([bytes, str]);

    codeUnits[i] = TRAILING_SURROGATE;
    str = new String.fromCharCodes(codeUnits);
    bytes = new List.filled(i + 3, CHAR_A);
    bytes[i] = UTF8_TRAILING[0];
    bytes[i + 1] = UTF8_TRAILING[1];
    bytes[i + 2] = UTF8_TRAILING[2];
    runTest([bytes, str]);

    codeUnits.length = i + 2;
    codeUnits[i] = LEADING_SURROGATE;
    codeUnits[i + 1] = TRAILING_SURROGATE;
    str = new String.fromCharCodes(codeUnits);
    bytes = new List.filled(i + 4, CHAR_A);
    bytes[i] = UTF8_ENCODING[0];
    bytes[i + 1] = UTF8_ENCODING[1];
    bytes[i + 2] = UTF8_ENCODING[2];
    bytes[i + 3] = UTF8_ENCODING[3];
    runTest([bytes, str]);

    codeUnits[i] = TRAILING_SURROGATE;
    codeUnits[i + 1] = TRAILING_SURROGATE;
    str = new String.fromCharCodes(codeUnits);
    bytes = new List.filled(i + 6, CHAR_A);
    bytes[i] = UTF8_TRAILING[0];
    bytes[i + 1] = UTF8_TRAILING[1];
    bytes[i + 2] = UTF8_TRAILING[2];
    bytes[i + 3] = UTF8_TRAILING[0];
    bytes[i + 4] = UTF8_TRAILING[1];
    bytes[i + 5] = UTF8_TRAILING[2];
    runTest([bytes, str]);

    codeUnits[i] = LEADING_SURROGATE;
    codeUnits[i + 1] = LEADING_SURROGATE;
    str = new String.fromCharCodes(codeUnits);
    bytes = new List.filled(i + 6, CHAR_A);
    bytes[i] = UTF8_LEADING[0];
    bytes[i + 1] = UTF8_LEADING[1];
    bytes[i + 2] = UTF8_LEADING[2];
    bytes[i + 3] = UTF8_LEADING[0];
    bytes[i + 4] = UTF8_LEADING[1];
    bytes[i + 5] = UTF8_LEADING[2];
    runTest([bytes, str]);

    codeUnits[i] = TRAILING_SURROGATE;
    codeUnits[i + 1] = LEADING_SURROGATE;
    str = new String.fromCharCodes(codeUnits);
    bytes = new List.filled(i + 6, CHAR_A);
    bytes[i] = UTF8_TRAILING[0];
    bytes[i + 1] = UTF8_TRAILING[1];
    bytes[i + 2] = UTF8_TRAILING[2];
    bytes[i + 3] = UTF8_LEADING[0];
    bytes[i + 4] = UTF8_LEADING[1];
    bytes[i + 5] = UTF8_LEADING[2];
    runTest([bytes, str]);

    codeUnits.length = i + 3;
    codeUnits[i] = LEADING_SURROGATE;
    codeUnits[i + 1] = TRAILING_SURROGATE;
    codeUnits[i + 2] = CHAR_A; // Add trailing 'a'.
    str = new String.fromCharCodes(codeUnits);
    bytes = new List.filled(i + 5, CHAR_A);
    bytes[i] = UTF8_ENCODING[0];
    bytes[i + 1] = UTF8_ENCODING[1];
    bytes[i + 2] = UTF8_ENCODING[2];
    bytes[i + 3] = UTF8_ENCODING[3];
    // No need to assign the 'a' character. The whole list is already filled
    // with it.
    runTest([bytes, str]);

    codeUnits[i] = TRAILING_SURROGATE;
    codeUnits[i + 1] = TRAILING_SURROGATE;
    codeUnits[i + 2] = CHAR_A; // Add trailing 'a'.
    str = new String.fromCharCodes(codeUnits);
    bytes = new List.filled(i + 7, CHAR_A);
    bytes[i] = UTF8_TRAILING[0];
    bytes[i + 1] = UTF8_TRAILING[1];
    bytes[i + 2] = UTF8_TRAILING[2];
    bytes[i + 3] = UTF8_TRAILING[0];
    bytes[i + 4] = UTF8_TRAILING[1];
    bytes[i + 5] = UTF8_TRAILING[2];
    runTest([bytes, str]);

    codeUnits[i] = LEADING_SURROGATE;
    codeUnits[i + 1] = LEADING_SURROGATE;
    codeUnits[i + 2] = CHAR_A; // Add trailing 'a'.
    str = new String.fromCharCodes(codeUnits);
    bytes = new List.filled(i + 7, CHAR_A);
    bytes[i] = UTF8_LEADING[0];
    bytes[i + 1] = UTF8_LEADING[1];
    bytes[i + 2] = UTF8_LEADING[2];
    bytes[i + 3] = UTF8_LEADING[0];
    bytes[i + 4] = UTF8_LEADING[1];
    bytes[i + 5] = UTF8_LEADING[2];
    runTest([bytes, str]);

    codeUnits[i] = TRAILING_SURROGATE;
    codeUnits[i + 1] = LEADING_SURROGATE;
    codeUnits[i + 2] = CHAR_A; // Add trailing 'a'.
    str = new String.fromCharCodes(codeUnits);
    bytes = new List.filled(i + 7, CHAR_A);
    bytes[i] = UTF8_TRAILING[0];
    bytes[i + 1] = UTF8_TRAILING[1];
    bytes[i + 2] = UTF8_TRAILING[2];
    bytes[i + 3] = UTF8_LEADING[0];
    bytes[i + 4] = UTF8_LEADING[1];
    bytes[i + 5] = UTF8_LEADING[2];
    runTest([bytes, str]);

    // Make sure the invariant is correct.
    codeUnits[i] = CHAR_A;
  }
}
