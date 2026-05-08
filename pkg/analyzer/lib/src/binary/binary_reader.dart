// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/binary/string_table.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';

/// Reader for binary formats.
class BinaryReader {
  final Uint8List bytes;
  int offset = 0;

  final Int64List _int64Buffer = Int64List(1);
  late final Uint8List _int64BufferUint8 = _int64Buffer.buffer.asUint8List();

  final Float64List _doubleBuffer = Float64List(1);
  late final Uint8List _doubleBufferUint8 = _doubleBuffer.buffer.asUint8List();

  List<ManifestItemId>? _manifestIdTable;
  StringTable? _stringTable;

  BinaryReader(this.bytes);

  /// Create a new instance with the given [offset].
  /// It shares the same bytes and string reader.
  BinaryReader fork(int offset) {
    var result = BinaryReader(bytes);
    result.offset = offset;
    result._manifestIdTable = _manifestIdTable;
    result._stringTable = _stringTable;
    return result;
  }

  /// Initializes the manifest-ID and string tables by reading their start
  /// offsets from two `uint32` values trailer at the end of the buffer.
  /// The reader's current offset is preserved.
  ///
  /// Layout (BOF -> EOF):
  /// ```text
  /// <payload>
  /// <manifest_id_table>
  /// <string_table>
  /// <manifestIdTableOffset:u32>
  /// <stringTableOffset:u32>
  /// ```
  ///
  /// This is the counterpart to [BinaryWriter.writeTableTrailer].
  void initFromTableTrailer() {
    runAtOffset(bytes.length - 4 * 2, () {
      var manifestIdTableOffset = readUint32();
      var stringTableOffset = readUint32();
      _initManifestIdTableAt(manifestIdTableOffset);
      initStringTableAt(stringTableOffset);
    });
  }

  void initStringTableAt(int offset) {
    _stringTable = StringTable(bytes: bytes, startOffset: offset);
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

  ManifestItemId readManifestItemId() {
    var table = _manifestIdTable;
    if (table == null) {
      throw StateError('Manifest ID table not initialized.');
    }
    var index = readUint30();
    return table[index];
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

  /// Same as [readTypedList] but with the given function taking [BinaryReader]
  /// which can sometimes avoid the allocation of a context and a closure in the
  /// VM.
  List<T> readTypedListFromBinaryReader<T>(T Function(BinaryReader) read) {
    var length = readUint30();
    if (length == 0) {
      return const <Never>[];
    }
    return List<T>.generate(length, (_) {
      return read(this);
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
    var uriStr = readStringReference();
    return uriCache.parse(uriStr);
  }

  List<Uri> readUriList() {
    return readTypedList(readUri);
  }

  /// Temporary move to [offset] and run [operation].
  void runAtOffset(int offset, void Function() operation) {
    var oldOffset = this.offset;
    this.offset = offset;
    try {
      operation();
    } finally {
      this.offset = oldOffset;
    }
  }

  String stringOfIndex(int index) {
    var table = _stringTable;
    if (table == null) {
      throw StateError('String table not initialized.');
    }
    return table[index];
  }

  void _initManifestIdTableAt(int offset) {
    runAtOffset(offset, () {
      _manifestIdTable = ManifestIdTableBuilder.readTable(this);
    });
  }
}
