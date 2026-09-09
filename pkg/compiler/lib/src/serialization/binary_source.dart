// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'serialization.dart' show StringInterner, DataSource;

/// [DataSource] that reads data from a sequence of bytes.
///
/// This data source works together with [BinaryDataSink].
class BinaryDataSource implements DataSource {
  int _byteOffset = 0;
  final List<int> _bytes;
  final StringInterner? _stringInterner;
  late final Map<int, int> _deferredOffsetToSize;

  BinaryDataSource(this._bytes, {this._stringInterner}) {
    final deferredDataStart = readAtOffset(_bytes.length - 4, readUint32);
    _deferredOffsetToSize = readAtOffset(deferredDataStart, () {
      final deferredSizesCount = readInt();
      final result = <int, int>{};
      for (var i = 0; i < deferredSizesCount; i++) {
        final offset = readInt();
        final size = readInt();
        result[offset] = size;
      }
      return result;
    });
  }

  @override
  void begin(String tag) {}

  @override
  void end(String tag) {}

  int _readByte() => _bytes[_byteOffset++];

  @override
  String readString() {
    int numBytes = readInt();
    if (numBytes == 0) return '';
    String string = _decodeWtf8(_byteOffset, _byteOffset + numBytes);
    _byteOffset += numBytes;
    if (_stringInterner == null) return string;
    return _stringInterner.internString(string);
  }

  /// We use WTF-8 encoding for strings in serialized data to ensure we preserve
  /// Dart strings containing unmatched surrogate pairs and byte order marks.
  /// The dart:convert UTF-8 encoder does not preserve these through a round
  /// trip.
  String _decodeWtf8(int start, int end) {
    // WTF-8 decoder that trusts its input, meaning that the correctness of
    // the code depends on the bytes from start to end being valid and
    // complete WTF-8. Instead of masking off the control bits from every
    // byte, it simply xor's the byte values together at their appropriate
    // bit shifts, and then xor's out all of the control bits at once.
    Uint16List charCodes = Uint16List(end - start);
    int i = start;
    int j = 0;
    while (i < end) {
      int byte = _bytes[i++];
      if (byte < 0x80) {
        // ASCII.
        charCodes[j++] = byte;
      } else if (byte < 0xE0) {
        // Two-byte sequence (11-bit unicode value).
        int byte2 = _bytes[i++];
        int value = (byte << 6) ^ byte2 ^ 0x3080;
        assert(value >= 0x80 && value < 0x800);
        charCodes[j++] = value;
      } else if (byte < 0xF0) {
        // Three-byte sequence (16-bit unicode value).
        int byte2 = _bytes[i++];
        int byte3 = _bytes[i++];
        int value = (byte << 12) ^ (byte2 << 6) ^ byte3 ^ 0xE2080;
        assert(value >= 0x800 && value < 0x10000);
        charCodes[j++] = value;
      } else {
        // Four-byte sequence (non-BMP unicode value).
        int byte2 = _bytes[i++];
        int byte3 = _bytes[i++];
        int byte4 = _bytes[i++];
        int value =
            (byte << 18) ^ (byte2 << 12) ^ (byte3 << 6) ^ byte4 ^ 0x3C82080;
        assert(value >= 0x10000 && value < 0x110000);
        charCodes[j++] = 0xD7C0 + (value >> 10);
        charCodes[j++] = 0xDC00 + (value & 0x3FF);
      }
    }
    assert(i == end);
    return String.fromCharCodes(charCodes, 0, j);
  }

  @override
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

  @override
  E readEnum<E extends Enum>(List<E> values) {
    int index = readInt();
    assert(
      0 <= index && index < values.length,
      "Invalid data kind index. "
      "Expected one of $values, found index $index.",
    );
    return values[index];
  }

  @override
  E readAtOffset<E>(int offset, E Function() reader) {
    final offsetBefore = _byteOffset;
    _byteOffset = offset;
    final value = reader();
    _byteOffset = offsetBefore;
    return value;
  }

  @override
  int readUint32() {
    return (_readByte() << 24) |
        (_readByte() << 16) |
        (_readByte() << 8) |
        _readByte();
  }

  @override
  int readDeferred() {
    final indexOffset = _byteOffset;
    readInt(); // Read collision padding.
    final dataOffset = _byteOffset;
    final dataLength = _deferredOffsetToSize[indexOffset]!;
    _byteOffset += dataLength;
    return dataOffset;
  }

  @override
  E readDeferredAsEager<E>(E Function() reader) {
    readInt(); // Read collision padding.
    return reader();
  }

  @override
  int get length => _bytes.length;
  @override
  int get currentOffset => _byteOffset;

  @override
  String get errorContext => ' Offset $_byteOffset in ${_bytes.length}.';
}
