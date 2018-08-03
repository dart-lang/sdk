// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';
import 'unicode_tests.dart';

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

main() {
  for (var test in UNICODE_TESTS) {
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
}
