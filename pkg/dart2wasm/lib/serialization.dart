// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

class BinaryDataSink {
  static const int _initSinkSize = 50 * 1024;

  Uint8List _data = Uint8List(_initSinkSize);
  int _length = 0;

  BinaryDataSink();

  int get length => _length;

  void _ensure(int size) {
    // Ensure space for at least `size` additional bytes.
    if (_data.length < _length + size) {
      int newLength = _data.length * 2;
      while (newLength < _length + size) {
        newLength *= 2;
      }
      _data = Uint8List(newLength)..setRange(0, _data.length, _data);
    }
  }

  void writeByte(int byte) {
    assert(byte == byte & 0xFF);
    _ensure(1);
    _data[_length++] = byte;
  }

  void writeBytes(Uint8List bytes) {
    _ensure(bytes.length);
    _data.setRange(_length, _length += bytes.length, bytes);
  }

  void writeString(String value) {
    final bytes = utf8.encode(value);
    writeInt(bytes.length);
    writeBytes(bytes);
  }

  void writeBool(bool value) {
    writeByte(value ? 1 : 0);
  }

  void writeInt(int value) {
    assert(value >= 0 && value >> 30 == 0);
    if (value < 0x80) {
      writeByte(value);
    } else if (value < 0x4000) {
      writeByte((value >> 8) | 0x80);
      writeByte(value & 0xFF);
    } else {
      writeByte((value >> 24) | 0xC0);
      writeByte((value >> 16) & 0xFF);
      writeByte((value >> 8) & 0xFF);
      writeByte(value & 0xFF);
    }
  }

  void writeClassId(int value) {
    // Add 1 since some class IDs are -1.
    writeInt(value + 1);
  }

  void writeEnum<E extends Enum>(E value) {
    writeInt(value.index);
  }

  Uint8List takeBytes() {
    final result = Uint8List.sublistView(_data, 0, _length);
    // Free the reference to the large data list so it can potentially be
    // tree-shaken.
    _data = Uint8List(0);
    return result;
  }
}

class BinaryDataSource {
  int _byteOffset = 0;
  final Uint8List _bytes;

  BinaryDataSource(this._bytes);

  void begin(String tag) {}

  void end(String tag) {}

  int _readByte() => _bytes[_byteOffset++];

  String readString() {
    int length = readInt();
    return utf8.decode(
        Uint8List.sublistView(_bytes, _byteOffset, _byteOffset += length));
  }

  bool readBool() {
    return _readByte() != 0;
  }

  int readInt() {
    var byte = _readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | _readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (_readByte() << 16) |
          (_readByte() << 8) |
          _readByte();
    }
  }

  int readClassId() {
    // Subtract 1 since some class IDs are -1.
    return readInt() - 1;
  }

  E readEnum<E extends Enum>(List<E> values) {
    int index = readInt();
    assert(
        0 <= index && index < values.length,
        "Invalid data kind index. "
        "Expected one of $values, found index $index.");
    return values[index];
  }

  int get length => _bytes.length;
  int get currentOffset => _byteOffset;
}
