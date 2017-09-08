// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf8_test;

import "package:expect/expect.dart";
import 'dart:convert';

main() {
  // Test that UTF8-decoder removes leading BOM.
  Expect.equals("a", UTF8.decode([0xEF, 0xBB, 0xBF, 0x61]));
  Expect.equals("a", UTF8.decoder.convert([0xEF, 0xBB, 0xBF, 0x61]));
  Expect.equals("a", new Utf8Decoder().convert([0xEF, 0xBB, 0xBF, 0x61]));
  Expect.equals(
      "a", UTF8.decode([0xEF, 0xBB, 0xBF, 0x61], allowMalformed: true));
  Expect.equals("a",
      new Utf8Codec(allowMalformed: true).decode([0xEF, 0xBB, 0xBF, 0x61]));
  Expect.equals(
      "a",
      new Utf8Codec(allowMalformed: true)
          .decoder
          .convert([0xEF, 0xBB, 0xBF, 0x61]));
  Expect.equals("a",
      new Utf8Decoder(allowMalformed: true).convert([0xEF, 0xBB, 0xBF, 0x61]));
  Expect.equals("", UTF8.decode([0xEF, 0xBB, 0xBF]));
  Expect.equals("", UTF8.decoder.convert([0xEF, 0xBB, 0xBF]));
  Expect.equals("", new Utf8Decoder().convert([0xEF, 0xBB, 0xBF]));
  Expect.equals("", UTF8.decode([0xEF, 0xBB, 0xBF], allowMalformed: true));
  Expect.equals(
      "", new Utf8Codec(allowMalformed: true).decode([0xEF, 0xBB, 0xBF]));
  Expect.equals("",
      new Utf8Codec(allowMalformed: true).decoder.convert([0xEF, 0xBB, 0xBF]));
  Expect.equals(
      "", new Utf8Decoder(allowMalformed: true).convert([0xEF, 0xBB, 0xBF]));
  Expect.equals("a\u{FEFF}", UTF8.decode([0x61, 0xEF, 0xBB, 0xBF]));
  Expect.equals("a\u{FEFF}", UTF8.decoder.convert([0x61, 0xEF, 0xBB, 0xBF]));
  Expect.equals(
      "a\u{FEFF}", new Utf8Decoder().convert([0x61, 0xEF, 0xBB, 0xBF]));
  Expect.equals(
      "a\u{FEFF}", UTF8.decode([0x61, 0xEF, 0xBB, 0xBF], allowMalformed: true));
  Expect.equals("a\u{FEFF}",
      new Utf8Codec(allowMalformed: true).decode([0x61, 0xEF, 0xBB, 0xBF]));
  Expect.equals(
      "a\u{FEFF}",
      new Utf8Codec(allowMalformed: true)
          .decoder
          .convert([0x61, 0xEF, 0xBB, 0xBF]));
  Expect.equals("a\u{FEFF}",
      new Utf8Decoder(allowMalformed: true).convert([0x61, 0xEF, 0xBB, 0xBF]));
}
