// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/string_table.dart';
import 'package:analyzer/src/fine/manifest_id.dart';

/// Buffered writer for binary formats.
class BinaryWriter {
  static const int _SIZE = 128 * 1024;
  static const int _SAFE_LENGTH = _SIZE - 5;

  final BytesBuilder _builder = BytesBuilder(copy: false);

  Uint8List _buffer = Uint8List(_SIZE);
  int _length = 0;

  final Int64List _int64Buffer = Int64List(1);
  late final Uint8List _int64BufferUint8 = _int64Buffer.buffer.asUint8List();

  final Float64List _doubleBuffer = Float64List(1);
  late final Uint8List _doubleBufferUint8 = _doubleBuffer.buffer.asUint8List();

  final ManifestIdTableBuilder _manifestIdTableBuilder;
  final StringTableBuilder _stringTableBuilder;

  BinaryWriter({
    StringTableBuilder? stringTableBuilder,
    ManifestIdTableBuilder? manifestIdTableBuilder,
  }) : _stringTableBuilder = stringTableBuilder ?? StringTableBuilder(),
       _manifestIdTableBuilder =
           manifestIdTableBuilder ?? ManifestIdTableBuilder();

  int get offset => _builder.length + _length;

  BinaryWriter clone() {
    return BinaryWriter(
      stringTableBuilder: _stringTableBuilder,
      manifestIdTableBuilder: _manifestIdTableBuilder,
    );
  }

  Uint8List takeBytes() {
    _builder.add(_buffer.sublist(0, _length));
    return _builder.takeBytes();
  }

  @pragma("vm:prefer-inline")
  void writeBool(bool value) {
    writeByte(value ? 1 : 0);
  }

  @pragma("vm:prefer-inline")
  void writeByte(int byte) {
    assert((byte & 0xFF) == byte);
    _addByte(byte);
  }

  void writeBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return;
    }

    // Usually the bytes is short, and fits the current buffer.
    if (_length + bytes.length < _SIZE) {
      _buffer.setRange(_length, _length + bytes.length, bytes);
      _length += bytes.length;
      return;
    }

    // If the bytes is too long, add separate buffers.
    if (bytes.length >= _SIZE) {
      _builder.add(_buffer.sublist(0, _length));
      _builder.add(bytes);
      // Start a new buffer.
      _buffer = Uint8List(_SIZE);
      _length = 0;
      return;
    }

    // Copy as much as we can into the current buffer.
    _buffer.setRange(_length, _SIZE, bytes);
    _builder.add(_buffer);

    // Copy the remainder into a new buffer.
    var alreadyCopied = _SIZE - _length;
    var remainder = bytes.length - alreadyCopied;
    _buffer = Uint8List(_SIZE);
    _buffer.setRange(0, remainder, bytes, alreadyCopied);
    _length = remainder;
  }

  void writeDouble(double value) {
    _doubleBuffer[0] = value;
    _addByte4(
      _doubleBufferUint8[0],
      _doubleBufferUint8[1],
      _doubleBufferUint8[2],
      _doubleBufferUint8[3],
    );
    _addByte4(
      _doubleBufferUint8[4],
      _doubleBufferUint8[5],
      _doubleBufferUint8[6],
      _doubleBufferUint8[7],
    );
  }

  void writeEnum(Enum e) {
    writeByte(e.index);
  }

  void writeIf<T extends Object>(bool condition, void Function() ifTrue) {
    if (condition) {
      writeBool(true);
      ifTrue();
    } else {
      writeBool(false);
    }
  }

  void writeInt64(int value) {
    _int64Buffer[0] = value;
    _addByte4(
      _int64BufferUint8[0],
      _int64BufferUint8[1],
      _int64BufferUint8[2],
      _int64BufferUint8[3],
    );
    _addByte4(
      _int64BufferUint8[4],
      _int64BufferUint8[5],
      _int64BufferUint8[6],
      _int64BufferUint8[7],
    );
  }

  /// Writes [items], converts to [List] first.
  void writeIterable<T>(Iterable<T> items, void Function(T x) writeItem) {
    writeList(items.toList(), writeItem);
  }

  void writeList<T>(List<T> items, void Function(T x) writeItem) {
    writeUint30(items.length);
    for (var i = 0; i < items.length; i++) {
      writeItem(items[i]);
    }
  }

  void writeManifestItemId(ManifestItemId id) {
    var index = _manifestIdTableBuilder[id];
    writeUint30(index);
  }

  void writeMap<K, V>(
    Map<K, V> map, {
    required void Function(K key) writeKey,
    required void Function(V value) writeValue,
  }) {
    writeUint30(map.length);
    for (var entry in map.entries) {
      writeKey(entry.key);
      writeValue(entry.value);
    }
  }

  void writeOptionalInt64(int? value) {
    if (value != null) {
      writeBool(true);
      writeInt64(value);
    } else {
      writeBool(false);
    }
  }

  void writeOptionalObject<T>(T? object, void Function(T x) write) {
    if (object != null) {
      writeBool(true);
      write(object);
    } else {
      writeBool(false);
    }
  }

  void writeOptionalStringReference(String? value) {
    if (value != null) {
      writeBool(true);
      writeStringReference(value);
    } else {
      writeBool(false);
    }
  }

  void writeOptionalStringUtf8(String? value) {
    if (value != null) {
      writeBool(true);
      writeStringUtf8(value);
    } else {
      writeBool(false);
    }
  }

  void writeOptionalUint30(int? value) {
    if (value != null) {
      writeBool(true);
      writeUint30(value);
    } else {
      writeBool(false);
    }
  }

  void writeOptionalUint8List(Uint8List? value) {
    if (value != null) {
      writeBool(true);
      writeUint8List(value);
    } else {
      writeBool(false);
    }
  }

  void writeOptionalUriList(List<Uri>? value) {
    if (value != null) {
      writeBool(true);
      writeUriList(value);
    } else {
      writeBool(false);
    }
  }

  void writeStringList(List<String> values) {
    writeList(values, writeStringReference);
  }

  void writeStringReference(String value) {
    var index = _stringTableBuilder[value];
    writeUint30(index);
  }

  /// Write the [value] as UTF8 encoded byte array.
  void writeStringUtf8(String value) {
    var bytes = const Utf8Encoder().convert(value);
    writeUint8List(bytes);
  }

  void writeStringUtf8Iterable(Iterable<String> items) {
    writeUint30(items.length);
    for (var item in items) {
      writeStringUtf8(item);
    }
  }

  /// Writes the table trailer, recording the start offsets of the manifest-ID
  /// table and the string table as two `uint32` values.
  ///
  /// Layout (BOF -> EOF):
  ///
  /// ```text
  /// <payload>
  /// <manifest_id_table>
  /// <string_table>
  /// <manifestIdTableOffset:u32>
  /// <stringTableOffset:u32>
  /// ```
  ///
  /// Call this after writing all other data, immediately before [takeBytes].
  ///
  /// This is the counterpart to [BinaryReader.initFromTableTrailer].
  void writeTableTrailer() {
    var manifestIdTableOffset = _manifestIdTableBuilder.write(this);
    var stringTableOffset = _stringTableBuilder.write(this);
    writeUint32(manifestIdTableOffset);
    writeUint32(stringTableOffset);
  }

  @pragma("vm:prefer-inline")
  void writeUint30(int value) {
    assert(value >= 0 && value >> 30 == 0);
    if (value < 0x80) {
      _addByte(value);
    } else if (value < 0x4000) {
      _addByte2((value >> 8) | 0x80, value & 0xFF);
    } else {
      _addByte4(
        (value >> 24) | 0xC0,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      );
    }
  }

  void writeUint30List(List<int> values) {
    var length = values.length;
    writeUint30(length);
    for (var i = 0; i < length; i++) {
      writeUint30(values[i]);
    }
  }

  void writeUint32(int value) {
    _addByte4(
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    );
  }

  void writeUint8List(Uint8List bytes) {
    writeUint30(bytes.length);
    writeBytes(bytes);
  }

  void writeUri(Uri uri) {
    var uriStr = uri.toString();
    writeStringReference(uriStr);
  }

  void writeUriList(List<Uri> uriList) {
    writeList(uriList, writeUri);
  }

  @pragma("vm:prefer-inline")
  void _addByte(int byte) {
    _buffer[_length++] = byte;
    if (_length == _SIZE) {
      _builder.add(_buffer);
      _buffer = Uint8List(_SIZE);
      _length = 0;
    }
  }

  @pragma("vm:prefer-inline")
  void _addByte2(int byte1, int byte2) {
    if (_length < _SAFE_LENGTH) {
      _buffer[_length++] = byte1;
      _buffer[_length++] = byte2;
    } else {
      _addByte(byte1);
      _addByte(byte2);
    }
  }

  @pragma("vm:prefer-inline")
  void _addByte4(int byte1, int byte2, int byte3, int byte4) {
    if (_length < _SAFE_LENGTH) {
      _buffer[_length++] = byte1;
      _buffer[_length++] = byte2;
      _buffer[_length++] = byte3;
      _buffer[_length++] = byte4;
    } else {
      _addByte(byte1);
      _addByte(byte2);
      _addByte(byte3);
      _addByte(byte4);
    }
  }
}
