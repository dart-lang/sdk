// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data' show ByteData, Uint16List;

import 'package:test/test.dart';
import 'package:vm_service/src/_stream_helpers.dart';

/// Writes the UTF-16 representation of [value] to [writeStream].
void _writeUtf16(
  WriteStream writeStream,
  String value,
) {
  final codeUnits = value.codeUnits;
  final bytesOfUtf16String =
      Uint16List.fromList(codeUnits).buffer.asUint8List();

  writeStream.writeInteger(codeUnits.length);
  for (final byte in bytesOfUtf16String) {
    writeStream.writeByte(byte);
  }
}

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

  test('utf16', () {
    // We previously had an alignment error involving the mishandling of
    // [ByteData.offsetInBytes], so we want this test to act as a regression
    // test against that. To accomplish this, we write two padding integers at
    // the start of each [WriteStream]. We later trim the first padding integer
    // away using [ByteData.sublistView] whenever we create a [ReadStream], and
    // we read the second padding integer using the created [ReadStream].
    // Performing these operations puts the created [ReadStream] into a state
    // in which the regression we want to avoid used to manifest.
    final padding = 123;
    WriteStream write = WriteStream(chunkSizeBytes: 32);
    write.writeInteger(padding);
    write.writeInteger(padding);
    _writeUtf16(write, 'hello!');
    ReadStream read = ReadStream([ByteData.sublistView(write.chunks.first, 1)]);
    expect(read.readInteger(), padding);
    expect(read.readUtf16(), 'hello!');

    write = WriteStream(chunkSizeBytes: 32);
    write.writeInteger(padding);
    write.writeInteger(padding);
    _writeUtf16(write, 'привет!');
    read = ReadStream([ByteData.sublistView(write.chunks.first, 1)]);
    expect(read.readInteger(), padding);
    expect(read.readUtf16(), 'привет!');

    write = WriteStream(chunkSizeBytes: 64);
    write.writeInteger(padding);
    write.writeInteger(padding);
    _writeUtf16(write, '8026221482988239');
    read = ReadStream([ByteData.sublistView(write.chunks.first, 1)]);
    expect(read.readInteger(), padding);
    expect(read.readUtf16(), '8026221482988239');
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
