// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/57091.
// Verify that bounds checks correctly happen when accessing short ByteData.

import 'dart:typed_data';
import "package:expect/expect.dart";

void testGet(ByteData data) {
  Expect.throws(() => data.getInt8(0));
  Expect.throws(() => data.getUint8(0));
  Expect.throws(() => data.getInt16(0));
  Expect.throws(() => data.getUint16(0));
  Expect.throws(() => data.getInt32(0));
  Expect.throws(() => data.getUint32(0));
  Expect.throws(() => data.getInt64(0));
  Expect.throws(() => data.getUint64(0));
  Expect.throws(() => data.getFloat32(0));
  Expect.throws(() => data.getFloat64(0));
}

void testSet(ByteData data) {
  Expect.throws(() => data.setInt8(0, 0));
  Expect.throws(() => data.setUint8(0, 0));
  Expect.throws(() => data.setInt16(0, 0));
  Expect.throws(() => data.setUint16(0, 0));
  Expect.throws(() => data.setInt32(0, 0));
  Expect.throws(() => data.setUint32(0, 0));
  Expect.throws(() => data.setInt64(0, 0));
  Expect.throws(() => data.setUint64(0, 0));
  Expect.throws(() => data.setFloat32(0, 0));
  Expect.throws(() => data.setFloat64(0, 0));
}

void main() {
  List<int> output = [];
  ByteData bytes = Uint8List.fromList(output).buffer.asByteData();
  testGet(bytes);
  testSet(bytes);
  testGet(bytes.asUnmodifiableView());
}
