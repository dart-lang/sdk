// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:expect/expect.dart';

const invalidValues = <int>[
  0x100000041, // Low 32 bits are 0x41.
  -0xFFFFFFBF, // Low 32 bits are 0x41.
  0x1000000FF, // Low 32 bits are 0xFF.
  0x10000000000, // Low 32 bits are 0.
];

void main() {
  for (var value in invalidValues) {
    // Vary the position of the invalid value within a 3-byte group.
    for (var bytes in [
      [value],
      [0x61, value],
      [0x61, 0x62, value],
      [0x61, 0x62, 0x63, value, 0x64],
    ]) {
      for (var codec in [base64, base64Url]) {
        Expect.throwsArgumentError(() => codec.encode(bytes), '$bytes');
        Expect.throwsArgumentError(
          () => encodeChunked(codec.encoder, bytes),
          '$bytes',
        );
      }
      Expect.throwsArgumentError(() => base64Encode(bytes), '$bytes');
    }
  }
  Expect.equals('YUE=', base64.encode([0x61, 0x41]));
  Expect.equals('_w==', base64Url.encode([0xFF]));
}

String encodeChunked(Base64Encoder encoder, List<int> bytes) {
  var buffer = StringBuffer();
  encoder.startChunkedConversion(StringConversionSink.fromStringSink(buffer))
    ..add(bytes)
    ..close();
  return buffer.toString();
}
