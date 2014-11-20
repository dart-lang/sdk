// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';

var asciiStrings = [
  "pure ascii",
  "\x00 with control characters \n",
  "\x01 edge cases \x7f"
];

var nonAsciiStrings = [
  "\x80 edge case first",
  "Edge case ASCII \u{80}",
  "Edge case byte \u{ff}",
  "Edge case super-BMP \u{10000}"
];

void main() {
  // Build longer versions of the example strings.
  for (int i = 0, n = asciiStrings.length; i < n ; i++) {
    var string = asciiStrings[i];
    while (string.length < 1024) {
      string += string;
    }
    asciiStrings.add(string);
  }
  for (int i = 0, n = nonAsciiStrings.length; i < n ; i++) {
    var string = nonAsciiStrings[i];
    while (string.length < 1024) {
      string += string;
    }
    nonAsciiStrings.add(string);
  }
  testDirectConversions();
  testChunkedConversions();
}

void testDirectConversions() {
  for (var codec in [ASCII, new AsciiCodec()]) {
    for (var asciiString in asciiStrings) {
      List bytes = codec.encoder.convert(asciiString);
      Expect.listEquals(asciiString.codeUnits.toList(), bytes, asciiString);
      String roundTripString = codec.decoder.convert(bytes);
      Expect.equals(asciiString, roundTripString);
      roundTripString = codec.decode(bytes);
      Expect.equals(asciiString, roundTripString);
    }

    for (var nonAsciiString in nonAsciiStrings) {
      Expect.throws(() {
        print(codec.encoder.convert(nonAsciiString));
      }, null, nonAsciiString);
    }

    var encode = codec.encoder.convert;
    Expect.listEquals([0x42, 0x43, 0x44], encode("ABCDE", 1, 4));
    Expect.listEquals([0x42, 0x43, 0x44, 0x45], encode("ABCDE", 1));
    Expect.listEquals([0x42, 0x43, 0x44], encode("\xffBCD\xff", 1, 4));
    Expect.throws(() { encode("\xffBCD\xff", 0, 4); });
    Expect.throws(() { encode("\xffBCD\xff", 1); });
    Expect.throws(() { encode("\xffBCD\xff", 1, 5); });
    Expect.throws(() { encode("\xffBCD\xff", -1, 4); });
    Expect.throws(() { encode("\xffBCD\xff", 1, -1); });
    Expect.throws(() { encode("\xffBCD\xff", 3, 2); });

    var decode = codec.decoder.convert;
    Expect.equals("BCD", decode([0x41, 0x42, 0x43, 0x44, 0x45], 1, 4));
    Expect.equals("BCDE", decode([0x41, 0x42, 0x43, 0x44, 0x45], 1));
    Expect.equals("BCD", decode([0xFF, 0x42, 0x43, 0x44, 0xFF], 1, 4));
    Expect.throws(() { decode([0xFF, 0x42, 0x43, 0x44, 0xFF], 0, 4); });
    Expect.throws(() { decode([0xFF, 0x42, 0x43, 0x44, 0xFF], 1); });
    Expect.throws(() { decode([0xFF, 0x42, 0x43, 0x44, 0xFF], 1, 5); });
    Expect.throws(() { decode([0xFF, 0x42, 0x43, 0x44, 0xFF], -1, 4); });
    Expect.throws(() { decode([0xFF, 0x42, 0x43, 0x44, 0xFF], 1, -1); });
    Expect.throws(() { decode([0xFF, 0x42, 0x43, 0x44, 0xFF], 3, 2); });
  }

  var allowInvalidCodec = new AsciiCodec(allowInvalid: true);
  var invalidBytes = [0, 1, 0xff, 0xdead, 0];
  String decoded = allowInvalidCodec.decode(invalidBytes);
  Expect.equals("\x00\x01\uFFFD\uFFFD\x00", decoded);
  decoded = allowInvalidCodec.decoder.convert(invalidBytes);
  Expect.equals("\x00\x01\uFFFD\uFFFD\x00", decoded);
  decoded = ASCII.decode(invalidBytes, allowInvalid: true);
  Expect.equals("\x00\x01\uFFFD\uFFFD\x00", decoded);
}

List<int> encode(String str, int chunkSize,
                 Converter<String, List<int>> converter) {
  List<int> bytes = <int>[];
  ChunkedConversionSink byteSink =
      new ByteConversionSink.withCallback(bytes.addAll);
  var stringConversionSink = converter.startChunkedConversion(byteSink);
  for (int i = 0; i < str.length; i += chunkSize) {
    if (i + chunkSize <= str.length) {
      stringConversionSink.add(str.substring(i, i + chunkSize));
    } else {
      stringConversionSink.add(str.substring(i));
    }
  }
  stringConversionSink.close();
  return bytes;
}

String decode(List<int> bytes, int chunkSize,
              Converter<List<int>, String> converter) {
  StringBuffer buf = new StringBuffer();
  var stringSink =
      new StringConversionSink.fromStringSink(buf);
  var byteConversionSink = converter.startChunkedConversion(stringSink);
  for (int i = 0; i < bytes.length; i += chunkSize) {
    if (i + chunkSize <= bytes.length) {
      byteConversionSink.add(bytes.sublist(i, i + chunkSize));
    } else {
      byteConversionSink.add(bytes.sublist(i));
    }
  }
  byteConversionSink.close();
  return buf.toString();
}

void testChunkedConversions() {
  // Check encoding.
  for (var converter in [ASCII.encoder,
                         new AsciiCodec().encoder,
                         new AsciiEncoder()]) {
    for (int chunkSize in [1, 2, 5, 50]) {
      for (var asciiString in asciiStrings) {
        var units = asciiString.codeUnits.toList();
        List bytes = encode(asciiString, chunkSize, converter);
        Expect.listEquals(units, bytes);
      }
      for (var nonAsciiString in nonAsciiStrings) {
        Expect.throws(() {
          encode(nonAsciiStrings, chunkSize, converter);
        });
      }
    }
  }
  // Check decoding.
  for (var converter in [ASCII.decoder,
                         new AsciiCodec().decoder,
                         new AsciiDecoder()]) {
    for (int chunkSize in [1, 2, 5, 50]) {
      for (var asciiString in asciiStrings) {
        var units = asciiString.codeUnits.toList();
        Expect.equals(asciiString, decode(units, chunkSize, converter));
      }
      for (var nonAsciiString in nonAsciiStrings) {
        var units = nonAsciiString.codeUnits.toList();
        Expect.throws(() {
          decode(units, chunkSize, converter);
        });
      }
    }
  }
}
