// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

class WriteStream {
  WriteStream({this.chunkSizeBytes = _defaultChunkSizeBytes})
      : assert(chunkSizeBytes > 0);

  final int chunkSizeBytes;

  /// The size copied from chunk size produced by VM for Mac.
  static const int _defaultChunkSizeBytes = 1048055;

  final List<ByteData> chunks = [];
  int _cursor = 0;

  void _writeByte(int value) {
    assert(value >= 0 && value <= 0xFF, value);
    _ensureCapacity();
    final chunk = chunks.last;
    chunk.setUint8(_cursor, value);
    _cursor = _cursor + 1;
  }

  void writeByte(int value) {
    _writeByte(value);
  }

  /// Write one ULEB128 number.
  void writeInteger(int value) {
    // First bit in every byte is a signal if there is more data.
    // So, we split the number into 7-bit parts and write them smaller to larger,
    // prefixing with the signal.

    int bytes = 0;
    for (;;) {
      int part = 0x7F & value;
      value >>= 7;

      if (value != 0) {
        // Signal that there is more data.
        part |= 0x80;
      }
      bytes++;
      _writeByte(part);

      if (value == 0) {
        break;
      }

      if (value == -1) {
        for (var i = 0; i < 9 - bytes; i++) {
          _writeByte(0xFF);
        }
        _writeByte(1);
        break;
      }
    }
  }

  void writeUtf8(String value) {
    final bytes = Utf8Codec(allowMalformed: true).encode(value);
    writeInteger(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      _writeByte(bytes[i]);
    }
  }

  void writeFloat64(double value) {
    var buffer = Float64List(1);
    buffer[0] = value;
    Uint8List bytes = buffer.buffer.asUint8List();
    for (int i = 0; i < 8; i++) {
      _writeByte(bytes[i]);
    }
  }

  /// Verifies there is space for one more byte.
  void _ensureCapacity() {
    if (chunks.isEmpty) {
      chunks.add(ByteData(chunkSizeBytes));
      return;
    }
    if (_cursor >= chunkSizeBytes) {
      chunks.add(ByteData(chunkSizeBytes));
      _cursor = 0;
    }
  }
}

class ReadStream {
  final List<ByteData> _chunks;
  int _chunkIndex = 0;
  int _byteIndex = 0;
  final ByteData _float64Buffer = ByteData(8);

  ReadStream(this._chunks) {
    for (int i = 0; i < _chunks.length; ++i) {
      _chunks[i].lengthInBytes;
    }
  }

  bool get atEnd => ((_byteIndex >= _chunks[_chunkIndex].lengthInBytes) &&
      (_chunkIndex + 1 >= _chunks.length));

  int _readByte() {
    while (_byteIndex >= _chunks[_chunkIndex].lengthInBytes) {
      _chunkIndex++;
      _byteIndex = 0;
    }
    return _chunks[_chunkIndex].getUint8(_byteIndex++);
  }

  bool _currentChunkHasBytes(int len) =>
      _byteIndex + len < _currentChunk.lengthInBytes;

  ByteData get _currentChunk => _chunks[_chunkIndex];

  int readByte() {
    return _readByte();
  }

  /// Read one ULEB128 number.
  ///
  /// The result can be negative.
  int readInteger() {
    int result = 0;
    int shift = 0;
    for (;;) {
      int part = _readByte();
      result |= (part & 0x7F) << shift;
      if ((part & 0x80) == 0) {
        break;
      }
      shift += 7;
    }
    return result;
  }

  /// Read one SLEB128 number.
  int readSigned() {
    int result = 0;
    int shift = 0;
    for (;;) {
      int part = _readByte();
      result |= (part & 0x7F) << shift;
      shift += 7;
      if ((part & 0x80) == 0) {
        if ((part & 0x40) != 0) {
          result |= (-1 << shift);
        }
        break;
      }
    }
    return result;
  }

  double readFloat64() {
    if (_currentChunkHasBytes(8)) {
      final value = _currentChunk.getFloat64(_byteIndex, Endian.little);
      _byteIndex += 8;
      return value;
    }

    for (int i = 0; i < 8; i++) {
      _float64Buffer.setUint8(i, readByte());
    }

    return _float64Buffer.getFloat64(0, Endian.little);
  }

  String readUtf8() {
    final len = readInteger();

    if (_currentChunkHasBytes(len)) {
      final value = const Utf8Codec(allowMalformed: true).decode(
          Uint8List.sublistView(_currentChunk, _byteIndex, _byteIndex + len));
      _byteIndex += len;
      return value;
    }

    final bytes = Uint8List(len);
    for (int i = 0; i < len; i++) {
      bytes[i] = readByte();
    }
    return const Utf8Codec(allowMalformed: true).decode(bytes);
  }

  String readLatin1() {
    final len = readInteger();

    final Uint8List codeUnits;
    if (_currentChunkHasBytes(len)) {
      codeUnits =
          Uint8List.sublistView(_currentChunk, _byteIndex, _byteIndex + len);
      _byteIndex += len;
    } else {
      codeUnits = Uint8List(len);
      for (int i = 0; i < len; i++) {
        codeUnits[i] = readByte();
      }
    }

    return String.fromCharCodes(codeUnits);
  }

  String readUtf16() {
    final len = readInteger();

    final Uint16List codeUnits;
    if (_currentChunkHasBytes(len * 2) &&
        (_currentChunk.offsetInBytes + _byteIndex) & 1 == 0) {
      codeUnits = Uint16List.sublistView(
          _currentChunk, _byteIndex, _byteIndex + len * 2);
      _byteIndex += len * 2;
    } else {
      codeUnits = Uint16List(len);
      for (int i = 0; i < len; i++) {
        codeUnits[i] = readByte() | (readByte() << 8);
      }
    }

    return String.fromCharCodes(codeUnits);
  }
}
