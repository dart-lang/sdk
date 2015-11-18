// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/object_graph.dart';
import 'package:unittest/unittest.dart';
import 'dart:typed_data';

testRoundTrip(final int n) {
  var bytes = [];
  var remaining = n;
  while (remaining > 127) {
    bytes.add(remaining & 127);
    remaining = remaining >> 7;
  }
  bytes.add(remaining + 128);

  print("Encoded $n as $bytes");

  var typedBytes = new ByteData.view(new Uint8List.fromList(bytes).buffer);
  var stream = new ReadStream([typedBytes]);
  stream.readUnsigned();

  expect(stream.isZero, equals(n == 0));

  expect(stream.low, equals((n >>  0) & 0xFFFFFFF));
  expect(stream.mid, equals((n >> 28) & 0xFFFFFFF));
  expect(stream.high, equals((n >> 56) & 0xFFFFFFF));

  const kMaxUint32 = (1 << 32) - 1;
  if (n > kMaxUint32) {
    expect(stream.clampedUint32, equals(kMaxUint32));
  } else {
    expect(stream.clampedUint32, equals(n));
  }

  expect(stream.position, equals(bytes.length));
}

main() {
  const kMaxUint64 = (1 << 64) - 1;

  var n = 3;
  while (n < kMaxUint64) {
    testRoundTrip(n);
    n <<= 1;
  }

  n = 5;
  while (n < kMaxUint64) {
    testRoundTrip(n);
    n <<= 1;
  }
}
