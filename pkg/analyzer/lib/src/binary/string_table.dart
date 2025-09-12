// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/src/binary/binary_writer.dart';

class StringIndexer {
  final Map<String, int> _index = {};

  int operator [](String string) {
    var result = _index[string];

    if (result == null) {
      result = _index.length;
      _index[string] = result;
    }

    return result;
  }

  int write(BufferedSink sink) {
    var bytesOffset = sink.offset;

    var length = _index.length;
    var lengths = Uint32List(length);
    var lengthsIndex = 0;
    for (var key in _index.keys) {
      var stringStart = sink.offset;
      _writeWtf8(sink, key);
      lengths[lengthsIndex++] = sink.offset - stringStart;
    }

    var resultOffset = sink.offset;

    var lengthOfBytes = sink.offset - bytesOffset;
    sink.writeUint30(lengthOfBytes);
    sink.writeUint30List(lengths);

    return resultOffset;
  }

  /// Write [source] string into [sink].
  static void _writeWtf8(BufferedSink sink, String source) {
    var end = source.length;
    if (end == 0) {
      return;
    }

    int i = 0;
    do {
      var codeUnit = source.codeUnitAt(i++);
      if (codeUnit < 128) {
        // ASCII.
        sink.writeByte(codeUnit);
      } else if (codeUnit < 0x800) {
        // Two-byte sequence (11-bit unicode value).
        sink.writeByte(0xC0 | (codeUnit >> 6));
        sink.writeByte(0x80 | (codeUnit & 0x3f));
      } else if ((codeUnit & 0xFC00) == 0xD800 &&
          i < end &&
          (source.codeUnitAt(i) & 0xFC00) == 0xDC00) {
        // Surrogate pair -> four-byte sequence (non-BMP unicode value).
        int codeUnit2 = source.codeUnitAt(i++);
        int unicode =
            0x10000 + ((codeUnit & 0x3FF) << 10) + (codeUnit2 & 0x3FF);
        sink.writeByte(0xF0 | (unicode >> 18));
        sink.writeByte(0x80 | ((unicode >> 12) & 0x3F));
        sink.writeByte(0x80 | ((unicode >> 6) & 0x3F));
        sink.writeByte(0x80 | (unicode & 0x3F));
      } else {
        // Three-byte sequence (16-bit unicode value), including lone
        // surrogates.
        sink.writeByte(0xE0 | (codeUnit >> 12));
        sink.writeByte(0x80 | ((codeUnit >> 6) & 0x3f));
        sink.writeByte(0x80 | (codeUnit & 0x3f));
      }
    } while (i < end);
  }
}

class StringTable {
  final Uint8List _bytes;
  int _byteOffset;

  late final Uint32List _offsets;
  late final List<String?> _strings;

  /// The structure of the table:
  ///   - `<bytes with encoded strings>`
  ///   - `<the length of the bytes> <-- [startOffset]`
  ///   - `<the number strings>`
  ///   - `<the array of lengths of individual strings>`
  StringTable({required Uint8List bytes, required int startOffset})
    : _bytes = bytes,
      _byteOffset = startOffset {
    var offset = startOffset - _readUint30();
    var length = _readUint30();

    _offsets = Uint32List(length + 1);
    for (var i = 0; i < length; i++) {
      var stringLength = _readUint30();
      _offsets[i] = offset;
      offset += stringLength;
    }
    _offsets[length] = offset;

    _strings = List.filled(length, null);
  }

  String operator [](int index) {
    var result = _strings[index];

    if (result == null) {
      int start = _offsets[index];
      int end = _offsets[index + 1];
      int length = end - start;
      result = _readStringEntry(_offsets[index], length);
      result = considerCanonicalizeString(result);
      _strings[index] = result;
    }

    return result;
  }

  int _readByte() {
    return _bytes[_byteOffset++];
  }

  String _readStringEntry(int start, int numBytes) {
    var end = start + numBytes;
    for (var i = start; i < end; i++) {
      if (_bytes[i] > 127) {
        return _decodeWtf8(_bytes, start, end);
      }
    }
    return String.fromCharCodes(_bytes, start, end);
  }

  int _readUint30() {
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

  static String _decodeWtf8(Uint8List bytes, int start, int end) {
    // WTF-8 decoder that trusts its input, meaning that the correctness of
    // the code depends on the bytes from start to end being valid and
    // complete WTF-8. Instead of masking off the control bits from every
    // byte, it simply xor's the byte values together at their appropriate
    // bit shifts, and then xor's out all of the control bits at once.
    Uint16List charCodes = Uint16List(end - start);
    int i = start;
    int j = 0;
    while (i < end) {
      int byte = bytes[i++];
      if (byte < 0x80) {
        // ASCII.
        charCodes[j++] = byte;
      } else if (byte < 0xE0) {
        // Two-byte sequence (11-bit unicode value).
        int byte2 = bytes[i++];
        int value = (byte << 6) ^ byte2 ^ 0x3080;
        assert(value >= 0x80 && value < 0x800);
        charCodes[j++] = value;
      } else if (byte < 0xF0) {
        // Three-byte sequence (16-bit unicode value).
        int byte2 = bytes[i++];
        int byte3 = bytes[i++];
        int value = (byte << 12) ^ (byte2 << 6) ^ byte3 ^ 0xE2080;
        assert(value >= 0x800 && value < 0x10000);
        charCodes[j++] = value;
      } else {
        // Four-byte sequence (non-BMP unicode value).
        int byte2 = bytes[i++];
        int byte3 = bytes[i++];
        int byte4 = bytes[i++];
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
}
