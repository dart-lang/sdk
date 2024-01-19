// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
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

  BinaryDataSource(this._bytes, {StringInterner? stringInterner})
      : _stringInterner = stringInterner {
    final deferredDataStart = readAtOffset(_bytes.length - 4, _readUint32);
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
    int length = readInt();
    List<int> bytes = Uint8List(length);
    bytes.setRange(0, bytes.length, _bytes, _byteOffset);
    _byteOffset += bytes.length;
    String string = utf8.decode(bytes);
    if (_stringInterner == null) return string;
    return _stringInterner!.internString(string);
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
  E readEnum<E>(List<E> values) {
    int index = readInt();
    assert(
        0 <= index && index < values.length,
        "Invalid data kind index. "
        "Expected one of $values, found index $index.");
    return values[index];
  }

  @override
  E readAtOffset<E>(int offset, E reader()) {
    final offsetBefore = _byteOffset;
    _byteOffset = offset;
    final value = reader();
    _byteOffset = offsetBefore;
    return value;
  }

  int _readUint32() {
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
  E readDeferredAsEager<E>(E reader()) {
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
