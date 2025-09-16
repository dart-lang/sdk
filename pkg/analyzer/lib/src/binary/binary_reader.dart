// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/src/binary/string_table.dart';

/// Helper for reading primitive types from bytes.
class SummaryDataReader {
  final Uint8List bytes;
  int offset = 0;

  late final StringTable _stringTable;

  final Int64List _int64Buffer = Int64List(1);
  late final Uint8List _int64BufferUint8 = _int64Buffer.buffer.asUint8List();

  final Float64List _doubleBuffer = Float64List(1);
  late final Uint8List _doubleBufferUint8 = _doubleBuffer.buffer.asUint8List();

  SummaryDataReader(this.bytes);

  void createStringTable(int offset) {
    _stringTable = StringTable(bytes: bytes, startOffset: offset);
  }

  /// Create a new instance with the given [offset].
  /// It shares the same bytes and string reader.
  SummaryDataReader fork(int offset) {
    var result = SummaryDataReader(bytes);
    result.offset = offset;
    result._stringTable = _stringTable;
    return result;
  }

  @pragma("vm:prefer-inline")
  bool readBool() {
    return readByte() != 0;
  }

  @pragma("vm:prefer-inline")
  int readByte() {
    return bytes[offset++];
  }

  double readDouble() {
    _doubleBufferUint8[0] = readByte();
    _doubleBufferUint8[1] = readByte();
    _doubleBufferUint8[2] = readByte();
    _doubleBufferUint8[3] = readByte();
    _doubleBufferUint8[4] = readByte();
    _doubleBufferUint8[5] = readByte();
    _doubleBufferUint8[6] = readByte();
    _doubleBufferUint8[7] = readByte();
    return _doubleBuffer[0];
  }

  T readEnum<T extends Enum>(List<T> values) {
    var index = readByte();
    return values[index];
  }

  int readInt64() {
    _int64BufferUint8[0] = readByte();
    _int64BufferUint8[1] = readByte();
    _int64BufferUint8[2] = readByte();
    _int64BufferUint8[3] = readByte();
    _int64BufferUint8[4] = readByte();
    _int64BufferUint8[5] = readByte();
    _int64BufferUint8[6] = readByte();
    _int64BufferUint8[7] = readByte();
    return _int64Buffer[0];
  }

  Map<K, V> readMap<K, V>({
    required K Function() readKey,
    required V Function() readValue,
  }) {
    var length = readUint30();
    if (length == 0) {
      return const {};
    }

    return {for (var i = 0; i < length; i++) readKey(): readValue()};
  }

  int? readOptionalInt64() {
    if (readBool()) {
      return readInt64();
    } else {
      return null;
    }
  }

  T? readOptionalObject<T>(T Function() read) {
    if (readBool()) {
      return read();
    } else {
      return null;
    }
  }

  String? readOptionalStringReference() {
    if (readBool()) {
      return readStringReference();
    } else {
      return null;
    }
  }

  String? readOptionalStringUtf8() {
    if (readBool()) {
      return readStringUtf8();
    } else {
      return null;
    }
  }

  int? readOptionalUint30() {
    if (readBool()) {
      return readUint30();
    } else {
      return null;
    }
  }

  Uint8List? readOptionalUint8List() {
    if (readBool()) {
      return readUint8List();
    } else {
      return null;
    }
  }

  List<Uri>? readOptionalUriList() {
    if (readBool()) {
      return readUriList();
    } else {
      return null;
    }
  }

  String readStringReference() {
    var index = readUint30();
    return stringOfIndex(index);
  }

  List<String> readStringReferenceList() {
    return readTypedList(readStringReference);
  }

  String readStringUtf8() {
    var bytes = readUint8List();
    return considerCanonicalizeString(utf8.decode(bytes));
  }

  List<String> readStringUtf8List() {
    return readTypedList(readStringUtf8);
  }

  Set<String> readStringUtf8Set() {
    var length = readUint30();
    var result = <String>{};
    for (var i = 0; i < length; i++) {
      var item = readStringUtf8();
      result.add(item);
    }
    return result;
  }

  List<T> readTypedList<T>(T Function() read) {
    var length = readUint30();
    if (length == 0) {
      return const <Never>[];
    }
    return List<T>.generate(length, (_) {
      return read();
    }, growable: false);
  }

  List<T> readTypedListCast<T>(Object? Function() read) {
    var length = readUint30();
    if (length == 0) {
      return const <Never>[];
    }
    return List<T>.generate(length, (_) {
      return read() as T;
    }, growable: false);
  }

  int readUint30() {
    var byte = readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (readByte() << 16) |
          (readByte() << 8) |
          readByte();
    }
  }

  Uint32List readUint30List() {
    var length = readUint30();
    var result = Uint32List(length);
    for (var i = 0; i < length; ++i) {
      result[i] = readUint30();
    }
    return result;
  }

  int readUint32() {
    return (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
  }

  Uint32List readUint32List() {
    var length = readUint32();
    var result = Uint32List(length);
    for (var i = 0; i < length; ++i) {
      result[i] = readUint32();
    }
    return result;
  }

  Uint8List readUint8List() {
    var length = readUint30();
    var result = Uint8List.sublistView(bytes, offset, offset + length);
    offset += length;
    return result;
  }

  Uri readUri() {
    var uriStr = readStringUtf8();
    return Uri.parse(uriStr);
  }

  List<Uri> readUriList() {
    return readTypedList(readUri);
  }

  /// Temporary move to [offset] and run [operation].
  void runAtOffset(int offset, void Function() operation) {
    var oldOffset = this.offset;
    this.offset = offset;
    operation();
    this.offset = oldOffset;
  }

  String stringOfIndex(int index) {
    return _stringTable[index];
  }
}
