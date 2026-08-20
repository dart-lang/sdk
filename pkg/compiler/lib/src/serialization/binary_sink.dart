// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:kernel/binary/ast_to_binary.dart';

import 'serialization.dart' show DataSink;

/// [DataSink] that writes data as a sequence of bytes.
///
/// This data sink works together with [BinarySourceWriter].
class BinaryDataSink implements DataSink {
  final Sink<List<int>> sink;
  // Nullable and non-final to allow storage to be released.
  BufferedSink? _bufferedSink;
  final Map<int, int> _deferredOffsetToSize = {};
  int _length = 0;

  BinaryDataSink(this.sink) : _bufferedSink = BufferedSink(sink);

  @override
  int get length => _length;

  @override
  void beginTag(String tag) {
    // TODO(johnniwinther): Support tags in binary serialization?
  }

  @override
  void endTag(String tag) {
    // TODO(johnniwinther): Support tags in binary serialization?
  }

  @override
  void writeString(String value) {
    final bytes = _encodeWtf8(value);
    writeInt(bytes.length);
    _bufferedSink!.addBytes(bytes);
    _length += bytes.length;
  }

  /// We use WTF-8 encoding for strings in serialized data to ensure we preserve
  /// Dart strings containing unmatched surrogate pairs and byte order marks.
  /// The dart:convert UTF-8 encoder does not preserve these through a round
  /// trip.
  Uint8List _encodeWtf8(String source) {
    int end = source.length;
    if (end == 0) return Uint8List(0);
    final target = Uint8List(source.length * 4);
    int i = 0;
    int index = 0;
    do {
      int codeUnit = source.codeUnitAt(i++);
      while (codeUnit < 128) {
        // ASCII.
        target[index++] = codeUnit;
        if (i >= end) return Uint8List.sublistView(target, 0, index);
        codeUnit = source.codeUnitAt(i++);
      }
      if (codeUnit < 0x800) {
        // Two-byte sequence (11-bit unicode value).
        index += 2;
        target[index - 2] = 0xC0 | (codeUnit >> 6);
        target[index - 1] = 0x80 | (codeUnit & 0x3F);
      } else if ((codeUnit & 0xFC00) == 0xD800 &&
          i < end &&
          (source.codeUnitAt(i) & 0xFC00) == 0xDC00) {
        // Surrogate pair -> four-byte sequence (non-BMP unicode value).
        index += 4;
        int codeUnit2 = source.codeUnitAt(i++);
        int unicode =
            0x10000 + ((codeUnit & 0x3FF) << 10) + (codeUnit2 & 0x3FF);
        target[index - 4] = 0xF0 | (unicode >> 18);
        target[index - 3] = 0x80 | ((unicode >> 12) & 0x3F);
        target[index - 2] = 0x80 | ((unicode >> 6) & 0x3F);
        target[index - 1] = 0x80 | (unicode & 0x3F);
      } else {
        // Three-byte sequence (16-bit unicode value), including lone
        // surrogates.
        index += 3;
        target[index - 3] = 0xE0 | (codeUnit >> 12);
        target[index - 2] = 0x80 | ((codeUnit >> 6) & 0x3F);
        target[index - 1] = 0x80 | (codeUnit & 0x3F);
      }
    } while (i < end);
    return Uint8List.sublistView(target, 0, index);
  }

  /// In order to compactly represent ints we only support up to 30 bit values.
  static const int maxIntValue = 1 << 30;

  @override
  void writeInt(int value) {
    assert(value >= 0 && value >> 30 == 0);
    if (value < 0x80) {
      _bufferedSink!.addByte(value);
      _length += 1;
    } else if (value < 0x4000) {
      _bufferedSink!.addByte2((value >> 8) | 0x80, value & 0xFF);
      _length += 2;
    } else {
      _bufferedSink!.addByte4(
        (value >> 24) | 0xC0,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      );
      _length += 4;
    }
  }

  @override
  void writeUint32(int value) {
    _length += 4;
    _bufferedSink!.addByte4(
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    );
  }

  @override
  void writeDeferred(void Function() writer) {
    final indexOffset = _length;
    writeInt(0); // Padding so the offset won't collide with a nested write.
    final dataStartOffset = _length;
    writer();
    _deferredOffsetToSize[indexOffset] = _length - dataStartOffset;
  }

  final List<(int, int)> _deferredOffsets = [];

  @override
  void startDeferred() {
    final indexOffset = _length;
    writeInt(0); // Padding so the offset won't collide with a nested write.
    final dataStartOffset = _length;
    _deferredOffsets.add((indexOffset, dataStartOffset));
  }

  @override
  void endDeferred() {
    final (indexOffset, dataStartOffset) = _deferredOffsets.removeLast();
    _deferredOffsetToSize[indexOffset] = _length - dataStartOffset;
  }

  @override
  void writeEnum<E extends Enum>(E value) {
    writeInt(value.index);
  }

  @override
  void close() {
    final deferredDataStart = _length;
    writeInt(_deferredOffsetToSize.length);
    for (final entry in _deferredOffsetToSize.entries) {
      writeInt(entry.key);
      writeInt(entry.value);
    }
    writeUint32(deferredDataStart);
    _bufferedSink!.flushAndDestroy();
    _bufferedSink = null;
    _deferredOffsetToSize.clear();
    sink.close();
  }
}
