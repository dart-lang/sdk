// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf8_test;

import "package:expect/expect.dart";
import 'dart:convert';
import 'dart:typed_data' show Uint8List;

/// [bytes] transforms the input into some representation (eg. plain list,
/// Uint8List).
test(List<int> bytes(List<int> input)) {
  // Test that UTF8-decoder removes leading BOM.
  Expect.equals("a", utf8.decode(bytes([0xEF, 0xBB, 0xBF, 0x61])));
  Expect.equals("a", utf8.decoder.convert(bytes([0xEF, 0xBB, 0xBF, 0x61])));
  Expect.equals(
      "a", new Utf8Decoder().convert(bytes([0xEF, 0xBB, 0xBF, 0x61])));
  Expect.equals(
      "a", utf8.decode(bytes([0xEF, 0xBB, 0xBF, 0x61]), allowMalformed: true));
  Expect.equals(
      "a",
      new Utf8Codec(allowMalformed: true)
          .decode(bytes([0xEF, 0xBB, 0xBF, 0x61])));
  Expect.equals(
      "a",
      new Utf8Codec(allowMalformed: true)
          .decoder
          .convert(bytes([0xEF, 0xBB, 0xBF, 0x61])));
  Expect.equals(
      "a",
      new Utf8Decoder(allowMalformed: true)
          .convert(bytes([0xEF, 0xBB, 0xBF, 0x61])));
  Expect.equals("", utf8.decode(bytes([0xEF, 0xBB, 0xBF])));
  Expect.equals("", utf8.decoder.convert(bytes([0xEF, 0xBB, 0xBF])));
  Expect.equals("", new Utf8Decoder().convert(bytes([0xEF, 0xBB, 0xBF])));
  Expect.equals(
      "", utf8.decode(bytes([0xEF, 0xBB, 0xBF]), allowMalformed: true));
  Expect.equals("",
      new Utf8Codec(allowMalformed: true).decode(bytes([0xEF, 0xBB, 0xBF])));
  Expect.equals(
      "",
      new Utf8Codec(allowMalformed: true)
          .decoder
          .convert(bytes([0xEF, 0xBB, 0xBF])));
  Expect.equals("",
      new Utf8Decoder(allowMalformed: true).convert(bytes([0xEF, 0xBB, 0xBF])));
  Expect.equals("a\u{FEFF}", utf8.decode(bytes([0x61, 0xEF, 0xBB, 0xBF])));
  Expect.equals(
      "a\u{FEFF}", utf8.decoder.convert(bytes([0x61, 0xEF, 0xBB, 0xBF])));
  Expect.equals(
      "a\u{FEFF}", new Utf8Decoder().convert(bytes([0x61, 0xEF, 0xBB, 0xBF])));
  Expect.equals("a\u{FEFF}",
      utf8.decode(bytes([0x61, 0xEF, 0xBB, 0xBF]), allowMalformed: true));
  Expect.equals(
      "a\u{FEFF}",
      new Utf8Codec(allowMalformed: true)
          .decode(bytes([0x61, 0xEF, 0xBB, 0xBF])));
  Expect.equals(
      "a\u{FEFF}",
      new Utf8Codec(allowMalformed: true)
          .decoder
          .convert(bytes([0x61, 0xEF, 0xBB, 0xBF])));
  Expect.equals(
      "a\u{FEFF}",
      new Utf8Decoder(allowMalformed: true)
          .convert(bytes([0x61, 0xEF, 0xBB, 0xBF])));
}

main() {
  test((list) => list);
  test((list) => new Uint8List.fromList(list));
}
