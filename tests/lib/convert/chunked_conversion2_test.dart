// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:expect/expect.dart';

// Test that the String and ByteConversionSinks make a copy when they need to
// adapt.

class MyByteSink extends ByteConversionSinkBase {
  var accumulator = [];
  add(List<int> bytes) {
    accumulator.add(bytes);
  }

  close() {}
}

void testBase() {
  var byteSink = new MyByteSink();
  var bytes = [1];
  byteSink.addSlice(bytes, 0, 1, false);
  bytes[0] = 2;
  byteSink.addSlice(bytes, 0, 1, true);
  Expect.equals(1, byteSink.accumulator[0][0]);
  Expect.equals(2, byteSink.accumulator[1][0]);
}

class MyChunkedSink extends ChunkedConversionSink {
  var accumulator = [];
  add(List<int> bytes) {
    accumulator.add(bytes);
  }

  close() {}
}

void testAdapter() {
  var chunkedSink = new MyChunkedSink();
  var byteSink = new ByteConversionSink.from(chunkedSink);
  var bytes = [1];
  byteSink.addSlice(bytes, 0, 1, false);
  bytes[0] = 2;
  byteSink.addSlice(bytes, 0, 1, true);
  Expect.equals(1, chunkedSink.accumulator[0][0]);
  Expect.equals(2, chunkedSink.accumulator[1][0]);
}

void main() {
  testBase();
  testAdapter();
}
