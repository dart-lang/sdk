// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:test/test.dart';
import 'package:vm_service/src/_stream_helpers.dart';

void main() {
  test('byte', () {
    final write = WriteStream();
    write.writeByte(11);
    write.writeByte(12);

    final read = ReadStream(write.chunks);
    expect(read.readByte(), 11);
    expect(read.readByte(), 12);
  });

  test('float64', () {
    final write = WriteStream();
    write.writeFloat64(-1.0);
    write.writeFloat64(pi);
    write.writeFloat64(10000000000);
    write.writeFloat64(-10000000000);

    final read = ReadStream(write.chunks);
    expect(read.readFloat64(), -1.0);
    expect(read.readFloat64(), pi);
    expect(read.readFloat64(), 10000000000);
    expect(read.readFloat64(), -10000000000);
  });

  test('utf8', () {
    final write = WriteStream(chunkSizeBytes: 2);
    write.writeUtf8('');
    write.writeUtf8('hello!');
    write.writeUtf8('привет!');
    write.writeUtf8('8026221482988239');

    final read = ReadStream(write.chunks);
    expect(read.readUtf8(), '');
    expect(read.readUtf8(), 'hello!');
    expect(read.readUtf8(), 'привет!');
    expect(read.readUtf8(), '8026221482988239');
  });

  test('integer', () {
    const int maxValue = -1 >>> 1;
    const int minValue = -maxValue - 1;

    final write = WriteStream(chunkSizeBytes: 1);
    write.writeInteger(-1000000000);
    write.writeInteger(-1);
    write.writeInteger(0);
    write.writeInteger(1);
    write.writeInteger(10000000000);
    write.writeInteger(20000000000);
    write.writeInteger(1683218);
    write.writeInteger(maxValue);
    write.writeInteger(minValue);

    final read = ReadStream(write.chunks);
    expect(read.readInteger(), -1000000000);
    expect(read.readInteger(), -1);
    expect(read.readInteger(), 0);
    expect(read.readInteger(), 1);
    expect(read.readInteger(), 10000000000);
    expect(read.readInteger(), 20000000000);
    expect(read.readInteger(), 1683218);
    expect(read.readInteger(), maxValue);
    expect(read.readInteger(), minValue);
  });
}
