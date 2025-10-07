// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

class Deserializer {
  final Uint8List _data;
  int offset = 0;

  Deserializer(this._data);

  int get length => _data.length;

  bool get isAtEnd => offset >= _data.length;

  int readByte() {
    return _data[offset++];
  }

  int peekByte() {
    return _data[offset];
  }

  Uint8List readBytes(int length) {
    final bytes = Uint8List.sublistView(_data, offset, offset + length);
    offset += length;
    return bytes;
  }

  int readSigned() {
    int result = 0;
    int shift = 0;
    int byte;
    do {
      byte = readByte();
      result |= (byte & 0x7F) << shift;
      shift += 7;
    } while ((byte & 0x80) != 0);

    if ((shift < 64) && ((byte & 0x40) != 0)) {
      result |= (~0 << shift);
    }

    return result;
  }

  int readUnsigned() {
    int result = 0;
    int shift = 0;
    int byte;
    do {
      byte = readByte();
      result |= (byte & 0x7F) << shift;
      shift += 7;
    } while ((byte & 0x80) != 0);
    return result;
  }

  double readF32() {
    final bd = ByteData.sublistView(_data, offset, offset + 4);
    offset += 4;
    return bd.getFloat32(0, Endian.little);
  }

  double readF64() {
    final bd = ByteData.sublistView(_data, offset, offset + 8);
    offset += 8;
    return bd.getFloat64(0, Endian.little);
  }

  String readName() {
    final length = readUnsigned();
    return utf8.decode(readBytes(length));
  }

  List<T> readList<T>(T Function(Deserializer) fun) {
    final length = readUnsigned();
    final list = <T>[];
    for (int i = 0; i < length; i++) {
      list.add(fun(this));
    }
    return list;
  }
}
