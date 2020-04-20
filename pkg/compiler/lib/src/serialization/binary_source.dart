// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// [DataSource] that reads data from a sequence of bytes.
///
/// This data source works together with [BinarySink].
class BinarySourceImpl extends AbstractDataSource {
  int _byteOffset = 0;
  final List<int> _bytes;

  BinarySourceImpl(this._bytes, {bool useDataKinds: false})
      : super(useDataKinds: useDataKinds);

  @override
  void _begin(String tag) {}
  @override
  void _end(String tag) {}

  int _readByte() => _bytes[_byteOffset++];

  @override
  String _readStringInternal() {
    int length = _readIntInternal();
    List<int> bytes = new Uint8List(length);
    bytes.setRange(0, bytes.length, _bytes, _byteOffset);
    _byteOffset += bytes.length;
    return utf8.decode(bytes);
  }

  @override
  int _readIntInternal() {
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
  Uri _readUriInternal() {
    String text = _readString();
    return Uri.parse(text);
  }

  @override
  E _readEnumInternal<E>(List<E> values) {
    int index = _readIntInternal();
    assert(
        0 <= index && index < values.length,
        "Invalid data kind index. "
        "Expected one of $values, found index $index.");
    return values[index];
  }

  @override
  String get _errorContext => ' Offset $_byteOffset in ${_bytes.length}.';
}
