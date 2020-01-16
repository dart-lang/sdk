// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the fused UTF-8/JSON decoder accepts a leading BOM.
library test;

import "package:expect/expect.dart";
import "dart:convert";

void main() {
  for (var parse in [parseFuse, parseSequence, parseChunked]) {
    // Sanity checks.
    Expect.isTrue(parse('true'.codeUnits.toList()));
    Expect.isFalse(parse('false'.codeUnits.toList()));
    Expect.equals(123, parse('123'.codeUnits.toList()));
    Expect.listEquals([42], parse('[42]'.codeUnits.toList()) as List);
    Expect.mapEquals({"x": 42}, parse('{"x":42}'.codeUnits.toList()) as Map);

    // String (0x22 = ") with UTF-8 encoded Unicode characters.
    Expect.equals(
        "A\xff\u1234\u{65555}",
        parse([
          0x22,
          0x41,
          0xc3,
          0xbf,
          0xe1,
          0x88,
          0xb4,
          0xf1,
          0xa5,
          0x95,
          0x95,
          0x22
        ]));

    // BOM followed by true.
    Expect.isTrue(parse([0xEF, 0xBB, 0xBF, 0x74, 0x72, 0x75, 0x65]));
  }

  // Do not accept BOM in non-UTF-8 decoder.
  Expect.throws<FormatException>(
      () => new JsonDecoder().convert("\xEF\xBB\xBFtrue"));
  Expect.throws<FormatException>(() => new JsonDecoder().convert("\uFEFFtrue"));

  // Only accept BOM first.
  Expect.throws<FormatException>(
      () => parseFuse(" \xEF\xBB\xBFtrue".codeUnits.toList()));
  // Only accept BOM first.
  Expect.throws<FormatException>(
      () => parseFuse(" true\xEF\xBB\xBF".codeUnits.toList()));

  Expect.throws<FormatException>(
      () => parseFuse(" [\xEF\xBB\xBF]".codeUnits.toList()));
}

Object? parseFuse(List<int> text) {
  return new Utf8Decoder().fuse(new JsonDecoder()).convert(text);
}

Object? parseSequence(List<int> text) {
  return new JsonDecoder().convert(new Utf8Decoder().convert(text));
}

Object? parseChunked(List<int> text) {
  var result;
  var sink = new Utf8Decoder().fuse(new JsonDecoder()).startChunkedConversion(
      new ChunkedConversionSink.withCallback((List<Object?> values) {
    result = values[0];
  }));
  for (var i = 0; i < text.length; i++) {
    sink.add([text[i]]);
  }
  sink.close();
  return result;
}
