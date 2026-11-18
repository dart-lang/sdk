// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/// Reader for encoded byte streams.
class BytesReader {
  final Uint8List _bytes;

  int byteOffset = 0;

  BytesReader(this._bytes);

  bool get isAtEnd => byteOffset >= _bytes.length;

  int readByte() => _bytes[byteOffset++];

  int readVarint() {
    int result = 0;
    int shift = 0;
    while (true) {
      final byte = readByte();
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return result;
  }

  int readZigZag() {
    final value = readVarint();
    final result = (value >>> 1) ^ -(value & 1);
    return _jsNumbers ? result.toSigned(32) : result;
  }
}

const bool _jsNumbers = 0x20_0000_0000_0000 == 0x20_0000_0000_0000 + 1;

/// Writer for encoded byte streams.
class BytesWriter {
  static final Uint8List _emptyBuffer = Uint8List(0);
  static const int _initialCapacity = 32;

  Uint8List _buffer = _emptyBuffer;
  int _length = 0;

  Uint8List? _built;

  bool get isEmpty => _built != null ? _built!.isEmpty : _length == 0;

  int get nextOffset => _length;

  void addByte(int byte) {
    if (_length == _buffer.length) {
      if (_buffer.isEmpty) {
        _buffer = Uint8List(_initialCapacity);
      } else {
        _buffer = Uint8List(_buffer.length * 2)..setRange(0, _length, _buffer);
      }
    }
    _buffer[_length++] = byte;
  }

  void writeVarint(int value) {
    assert(value >= 0);
    while (value >= 0x80) {
      addByte((value & 0x7F) | 0x80);
      value >>= 7;
    }
    addByte(value & 0x7F);
  }

  void writeZigZag(int value) {
    final encoded = (value << 1) ^ (value >> (_jsNumbers ? 31 : 63));
    writeVarint(encoded);
  }

  Uint8List build() {
    if (_built != null) {
      assert(_length == 0);
      return _built!;
    }
    if (_length == 0) {
      return _built = _emptyBuffer;
    }
    final result = _buffer.sublist(0, _length);
    _buffer = _emptyBuffer;
    _length = 0;
    return _built = result;
  }
}
