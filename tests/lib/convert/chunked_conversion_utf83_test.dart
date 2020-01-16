// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';

String decode(List<int> bytes, int chunkSize) {
  StringBuffer buffer = new StringBuffer();
  var stringSink = new StringConversionSink.fromStringSink(buffer);
  var byteSink = new Utf8Decoder().startChunkedConversion(stringSink);
  int i = 0;
  while (i < bytes.length) {
    var nextChunk = <int>[];
    for (int j = 0; j < chunkSize; j++) {
      if (i < bytes.length) {
        nextChunk.add(bytes[i]);
        i++;
      }
    }
    byteSink.add(nextChunk);
  }
  byteSink.close();
  return buffer.toString();
}

String decodeAllowMalformed(List<int> bytes, int chunkSize) {
  StringBuffer buffer = new StringBuffer();
  var stringSink = new StringConversionSink.fromStringSink(buffer);
  var decoder = new Utf8Decoder(allowMalformed: true);
  var byteSink = decoder.startChunkedConversion(stringSink);
  int i = 0;
  while (i < bytes.length) {
    var nextChunk = <int>[];
    for (int j = 0; j < chunkSize; j++) {
      if (i < bytes.length) {
        nextChunk.add(bytes[i]);
        i++;
      }
    }
    byteSink.add(nextChunk);
  }
  byteSink.close();
  return buffer.toString();
}

main() {
  // Test that chunked UTF8-decoder removes leading BOM.
  Expect.equals("a", decode([0xEF, 0xBB, 0xBF, 0x61], 1));
  Expect.equals("a", decode([0xEF, 0xBB, 0xBF, 0x61], 2));
  Expect.equals("a", decode([0xEF, 0xBB, 0xBF, 0x61], 3));
  Expect.equals("a", decode([0xEF, 0xBB, 0xBF, 0x61], 4));
  Expect.equals("a", decodeAllowMalformed([0xEF, 0xBB, 0xBF, 0x61], 1));
  Expect.equals("a", decodeAllowMalformed([0xEF, 0xBB, 0xBF, 0x61], 2));
  Expect.equals("a", decodeAllowMalformed([0xEF, 0xBB, 0xBF, 0x61], 3));
  Expect.equals("a", decodeAllowMalformed([0xEF, 0xBB, 0xBF, 0x61], 4));
  Expect.equals("", decode([0xEF, 0xBB, 0xBF], 1));
  Expect.equals("", decode([0xEF, 0xBB, 0xBF], 2));
  Expect.equals("", decode([0xEF, 0xBB, 0xBF], 3));
  Expect.equals("", decode([0xEF, 0xBB, 0xBF], 4));
  Expect.equals("", decodeAllowMalformed([0xEF, 0xBB, 0xBF], 1));
  Expect.equals("", decodeAllowMalformed([0xEF, 0xBB, 0xBF], 2));
  Expect.equals("", decodeAllowMalformed([0xEF, 0xBB, 0xBF], 3));
  Expect.equals("", decodeAllowMalformed([0xEF, 0xBB, 0xBF], 4));
  Expect.equals("a\u{FEFF}", decode([0x61, 0xEF, 0xBB, 0xBF], 1));
  Expect.equals("a\u{FEFF}", decode([0x61, 0xEF, 0xBB, 0xBF], 2));
  Expect.equals("a\u{FEFF}", decode([0x61, 0xEF, 0xBB, 0xBF], 3));
  Expect.equals("a\u{FEFF}", decode([0x61, 0xEF, 0xBB, 0xBF], 4));
  Expect.equals("a\u{FEFF}", decodeAllowMalformed([0x61, 0xEF, 0xBB, 0xBF], 1));
  Expect.equals("a\u{FEFF}", decodeAllowMalformed([0x61, 0xEF, 0xBB, 0xBF], 2));
  Expect.equals("a\u{FEFF}", decodeAllowMalformed([0x61, 0xEF, 0xBB, 0xBF], 3));
  Expect.equals("a\u{FEFF}", decodeAllowMalformed([0x61, 0xEF, 0xBB, 0xBF], 4));
}
