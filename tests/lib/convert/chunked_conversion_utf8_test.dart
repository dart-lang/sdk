// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';
import 'unicode_tests.dart';

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

main() {
  for (var test in UNICODE_TESTS) {
    var bytes = test[0];
    var expected = test[1];
    Expect.stringEquals(expected, decode(bytes, 1));
    Expect.stringEquals(expected, decode(bytes, 2));
    Expect.stringEquals(expected, decode(bytes, 3));
    Expect.stringEquals(expected, decode(bytes, 4));
  }
}
