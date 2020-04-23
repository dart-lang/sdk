// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

String paddedHex(int value, [int bytes = 0]) {
  return value.toRadixString(16).padLeft(2 * bytes, '0');
}

class Reader {
  final ByteData bdata;
  final Endian endian;
  final int wordSize;

  int _offset = 0;

  /// Unless provided, [wordSize] and [endian] are initialized to values that
  /// ensure no reads are made that depend on their value (e.g., readBytes).
  Reader.fromTypedData(TypedData data, {this.wordSize = -1, this.endian})
      : bdata =
            ByteData.view(data.buffer, data.offsetInBytes, data.lengthInBytes);

  Reader.fromFile(String path, {this.wordSize, this.endian})
      // TODO(sstrickl): Once Dart > 2.7.1 has been released, rewrite
      // ByteData.view(<x>.buffer) => ByteData.sublistView(<x>).
      : bdata = ByteData.view(File(path).readAsBytesSync().buffer);

  Reader copy() =>
      Reader.fromTypedData(bdata, wordSize: wordSize, endian: endian);

  Reader shrink(int offset, [int size = -1]) {
    if (size < 0) size = bdata.lengthInBytes - offset;
    assert(offset >= 0 && offset < bdata.lengthInBytes);
    assert(size >= 0 && (offset + size) <= bdata.lengthInBytes);
    return Reader.fromTypedData(
        ByteData.view(bdata.buffer, bdata.offsetInBytes + offset, size),
        wordSize: wordSize,
        endian: endian);
  }

  Reader refocus(int pos, [int size = -1]) {
    if (size < 0) size = bdata.lengthInBytes - pos;
    assert(pos >= 0 && pos < bdata.buffer.lengthInBytes);
    assert(size >= 0 && (pos + size) <= bdata.buffer.lengthInBytes);
    return Reader.fromTypedData(ByteData.view(bdata.buffer, pos, size),
        wordSize: wordSize, endian: endian);
  }

  int get start => bdata.offsetInBytes;
  int get offset => _offset;
  int get length => bdata.lengthInBytes;
  bool get done => _offset >= length;

  void seek(int offset, {bool absolute = false}) {
    final newOffset = (absolute ? 0 : _offset) + offset;
    assert(newOffset >= 0 && newOffset < bdata.lengthInBytes);
    _offset = newOffset;
  }

  void reset() {
    seek(0, absolute: true);
  }

  int readBytes(int size, {bool signed = false}) {
    assert(_offset + size < length);
    int ret;
    switch (size) {
      case 1:
        ret = signed ? bdata.getInt8(_offset) : bdata.getUint8(_offset);
        break;
      case 2:
        ret = signed
            ? bdata.getInt16(_offset, endian)
            : bdata.getUint16(_offset, endian);
        break;
      case 4:
        ret = signed
            ? bdata.getInt32(_offset, endian)
            : bdata.getUint32(_offset, endian);
        break;
      case 8:
        ret = signed
            ? bdata.getInt64(_offset, endian)
            : bdata.getUint64(_offset, endian);
        break;
      default:
        throw ArgumentError("invalid request to read $size bytes");
    }
    _offset += size;
    return ret;
  }

  int readByte({bool signed = false}) => readBytes(1, signed: signed);
  int readWord() => readBytes(wordSize);
  String readNullTerminatedString() {
    final start = bdata.offsetInBytes + _offset;
    for (int i = 0; _offset + i < bdata.lengthInBytes; i++) {
      if (bdata.getUint8(_offset + i) == 0) {
        _offset += i + 1;
        return String.fromCharCodes(bdata.buffer.asUint8List(start, i));
      }
    }
    return String.fromCharCodes(
        bdata.buffer.asUint8List(start, bdata.lengthInBytes - _offset));
  }

  int readLEB128EncodedInteger({bool signed = false}) {
    var ret = 0;
    var shift = 0;
    for (var byte = readByte(); !done; byte = readByte()) {
      ret |= (byte & 0x7f) << shift;
      shift += 7;
      if (byte & 0x80 == 0) {
        if (signed && byte & 0x40 != 0) {
          ret |= -(1 << shift);
        }
        break;
      }
    }
    return ret;
  }

  Iterable<MapEntry<int, S>> readRepeated<S>(
      S Function(Reader) callback) sync* {
    while (!done) {
      yield MapEntry<int, S>(offset, callback(this));
    }
  }

  void writeCurrentReaderPosition(StringBuffer buffer,
      {int maxSize = 0, int bytesPerLine = 16}) {
    var baseData = ByteData.view(bdata.buffer, 0, bdata.buffer.lengthInBytes);
    var startOffset = 0;
    var endOffset = baseData.lengthInBytes;
    final currentOffset = start + _offset;
    if (maxSize != 0 && maxSize < baseData.lengthInBytes) {
      var lowerWindow = currentOffset - (maxSize >> 1);
      // Adjust so that we always start at the beginning of a line.
      lowerWindow -= lowerWindow % bytesPerLine;
      final upperWindow = lowerWindow + maxSize;
      startOffset = max(startOffset, lowerWindow);
      endOffset = min(endOffset, upperWindow);
    }
    for (int i = startOffset; i < endOffset; i += bytesPerLine) {
      buffer..write("0x")..write(paddedHex(i, 8))..write(" ");
      for (int j = 0; j < bytesPerLine && i + j < endOffset; j++) {
        var byte = baseData.getUint8(i + j);
        buffer
          ..write(i + j == currentOffset ? "|" : " ")
          ..write(paddedHex(byte, 1));
      }
      buffer.writeln();
    }
  }

  String toString() {
    final buffer = StringBuffer();
    buffer
      ..write("Start:  0x")
      ..write(paddedHex(start, wordSize))
      ..write(" (")
      ..write(start)
      ..writeln(")");
    buffer
      ..write("Offset: 0x")
      ..write(paddedHex(offset, wordSize))
      ..write(" (")
      ..write(offset)
      ..writeln(")");
    buffer
      ..write("Length: 0x")
      ..write(paddedHex(length, wordSize))
      ..write(" (")
      ..write(length)
      ..writeln(")");
    buffer..writeln("Bytes around current position:");
    writeCurrentReaderPosition(buffer, maxSize: 256);
    return buffer.toString();
  }
}
