// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

/// Puts a buffer in front of a [Sink<List<int>>].
class BufferedSink {
  static const int SIZE = 100000;
  static const int SAFE_SIZE = SIZE - 5;
  static const int SMALL = 10000;

  final Sink<List<int>> _sink;

  int flushedLength = 0;

  Uint8List _buffer = Uint8List(SIZE);
  int length = 0;

  final Float64List _doubleBuffer = Float64List(1);
  Uint8List _doubleBufferUint8;

  BufferedSink(this._sink);

  int get offset => flushedLength + length;

  @pragma("vm:prefer-inline")
  void addByte(int byte) {
    _buffer[length++] = byte;
    if (length == SIZE) {
      _sink.add(_buffer);
      _buffer = Uint8List(SIZE);
      length = 0;
      flushedLength += SIZE;
    }
  }

  @pragma("vm:prefer-inline")
  void addByte2(int byte1, int byte2) {
    if (length < SAFE_SIZE) {
      _buffer[length++] = byte1;
      _buffer[length++] = byte2;
    } else {
      addByte(byte1);
      addByte(byte2);
    }
  }

  @pragma("vm:prefer-inline")
  void addByte4(int byte1, int byte2, int byte3, int byte4) {
    if (length < SAFE_SIZE) {
      _buffer[length++] = byte1;
      _buffer[length++] = byte2;
      _buffer[length++] = byte3;
      _buffer[length++] = byte4;
    } else {
      addByte(byte1);
      addByte(byte2);
      addByte(byte3);
      addByte(byte4);
    }
  }

  void addBytes(Uint8List bytes) {
    // Avoid copying a large buffer into the another large buffer. Also, if
    // the bytes buffer is too large to fit in our own buffer, just emit both.
    if (length + bytes.length < SIZE &&
        (bytes.length < SMALL || length < SMALL)) {
      _buffer.setRange(length, length + bytes.length, bytes);
      length += bytes.length;
    } else if (bytes.length < SMALL) {
      // Flush as much as we can in the current buffer.
      _buffer.setRange(length, SIZE, bytes);
      _sink.add(_buffer);
      // Copy over the remainder into a new buffer. It is guaranteed to fit
      // because the input byte array is small.
      int alreadyEmitted = SIZE - length;
      int remainder = bytes.length - alreadyEmitted;
      _buffer = Uint8List(SIZE);
      _buffer.setRange(0, remainder, bytes, alreadyEmitted);
      length = remainder;
      flushedLength += SIZE;
    } else {
      flush();
      _sink.add(bytes);
      flushedLength += bytes.length;
    }
  }

  void addDouble(double value) {
    _doubleBufferUint8 ??= _doubleBuffer.buffer.asUint8List();
    _doubleBuffer[0] = value;
    addByte4(_doubleBufferUint8[0], _doubleBufferUint8[1],
        _doubleBufferUint8[2], _doubleBufferUint8[3]);
    addByte4(_doubleBufferUint8[4], _doubleBufferUint8[5],
        _doubleBufferUint8[6], _doubleBufferUint8[7]);
  }

  void flush() {
    _sink.add(_buffer.sublist(0, length));
    _buffer = Uint8List(SIZE);
    flushedLength += length;
    length = 0;
  }

  void flushAndDestroy() {
    _sink.add(_buffer.sublist(0, length));
  }

  @pragma("vm:prefer-inline")
  void writeByte(int byte) {
    assert((byte & 0xFF) == byte);
    addByte(byte);
  }

  void writeList<T>(List<T> items, void Function(T x) writeItem) {
    writeUInt30(items.length);
    for (var i = 0; i < items.length; i++) {
      writeItem(items[i]);
    }
  }

  /// Write the [value] as UTF8 encoded byte array.
  void writeStringUtf8(String value) {
    var bytes = utf8.encode(value);
    writeUint8List(bytes);
  }

  @pragma("vm:prefer-inline")
  void writeUInt30(int value) {
    assert(value >= 0 && value >> 30 == 0);
    if (value < 0x80) {
      addByte(value);
    } else if (value < 0x4000) {
      addByte2((value >> 8) | 0x80, value & 0xFF);
    } else {
      addByte4((value >> 24) | 0xC0, (value >> 16) & 0xFF, (value >> 8) & 0xFF,
          value & 0xFF);
    }
  }

  void writeUint30List(List<int> values) {
    var length = values.length;
    writeUInt30(length);
    for (var i = 0; i < length; i++) {
      writeUInt30(values[i]);
    }
  }

  void writeUInt32(int value) {
    addByte4((value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF,
        value & 0xFF);
  }

  void writeUint8List(Uint8List bytes) {
    writeUInt30(bytes.length);
    addBytes(bytes);
  }
}

/// A [Sink] that directly writes data into a byte builder.
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = BytesBuilder(copy: false);

  @override
  void add(List<int> data) {
    builder.add(data);
  }

  @override
  void close() {}
}
