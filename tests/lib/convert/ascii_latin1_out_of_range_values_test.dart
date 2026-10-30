// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:expect/expect.dart';

const invalidValues = <int>[
  0x100000041, // Low 32 bits are 0x41 ('A').
  -0xFFFFFFBF, // Low 32 bits are 0x41 ('A').
  0x1000000FF, // Low 32 bits are 0xFF.
  0x10000000000, // Low 32 bits are 0.
];

void main() {
  for (var value in invalidValues) {
    var bytes = <int>[0x61, value, 0x62];
    for (var decoder in <Converter<List<int>, String>>[
      const AsciiDecoder(),
      const Latin1Decoder(),
    ]) {
      var name = '${decoder.runtimeType}: $value';
      Expect.throwsFormatException(() => decoder.convert(bytes), name);
      Expect.throwsFormatException(() => decodeChunked(decoder, bytes), name);
      Expect.throwsFormatException(() => decodeSlices(decoder, bytes), name);
    }
    Expect.throwsFormatException(() => ascii.decode(bytes));
    Expect.throwsFormatException(() => latin1.decode(bytes));

    for (var decoder in <Converter<List<int>, String>>[
      const AsciiDecoder(allowInvalid: true),
      const Latin1Decoder(allowInvalid: true),
    ]) {
      var name = '${decoder.runtimeType} allowInvalid: $value';
      Expect.equals('a\uFFFDb', decoder.convert(bytes), name);
      Expect.equals('a\uFFFDb', decodeChunked(decoder, bytes), name);
      Expect.equals('a\uFFFDb', decodeSlices(decoder, bytes), name);
    }
    Expect.equals('a\uFFFDb', ascii.decode(bytes, allowInvalid: true));
    Expect.equals('a\uFFFDb', latin1.decode(bytes, allowInvalid: true));
  }
}

String decodeChunked(Converter<List<int>, String> decoder, List<int> bytes) {
  var result = '';
  decoder.startChunkedConversion(
      StringConversionSink.withCallback((s) => result = s),
    )
    ..add(bytes)
    ..close();
  return result;
}

String decodeSlices(Converter<List<int>, String> decoder, List<int> bytes) {
  var result = '';
  (decoder.startChunkedConversion(
      StringConversionSink.withCallback((s) => result = s),
    ) as ByteConversionSink)
    ..addSlice(bytes, 0, 1, false)
    ..addSlice(bytes, 1, bytes.length, false)
    ..close();
  return result;
}
