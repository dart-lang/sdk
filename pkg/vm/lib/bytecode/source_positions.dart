// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.source_positions;

import 'dart:io' show BytesBuilder;

/// Maintains mapping between bytecode instructions and source positions.
class SourcePositions {
  final Map<int, int> mapping = <int, int>{}; // PC -> fileOffset
  int _lastPc = 0;
  int _lastOffset = 0;

  SourcePositions();

  void add(int pc, int fileOffset) {
    assert(pc > _lastPc);
    assert(fileOffset >= 0);
    if (fileOffset != _lastOffset) {
      mapping[pc] = fileOffset;
      _lastPc = pc;
      _lastOffset = fileOffset;
    }
  }

  List<int> toBytes() {
    final write = new BufferedWriter();
    write.writePackedUInt30(mapping.length);
    final encodePC = new PackedUInt30DeltaEncoder();
    final encodeOffset = new SLEB128DeltaEncoder();
    mapping.forEach((int pc, int fileOffset) {
      encodePC.write(write, pc);
      encodeOffset.write(write, fileOffset);
    });
    return write.buffer.takeBytes();
  }

  SourcePositions.fromBytes(List<int> bytes) {
    final reader = new BufferedReader(bytes);
    final int length = reader.readPackedUInt30();
    final decodePC = new PackedUInt30DeltaDecoder();
    final decodeOffset = new SLEB128DeltaDecoder();
    for (int i = 0; i < length; ++i) {
      int pc = decodePC.read(reader);
      int fileOffset = decodeOffset.read(reader);
      add(pc, fileOffset);
    }
  }

  @override
  String toString() => mapping.toString();

  Map<int, String> getBytecodeAnnotations() {
    return mapping.map((int pc, int fileOffset) =>
        new MapEntry(pc, 'source position $fileOffset'));
  }
}

class BufferedWriter {
  final BytesBuilder buffer = new BytesBuilder();

  void writePackedUInt30(int value) {
    if ((value >> 30) != 0) {
      throw 'Value $value is out of range';
    }
    if (value < 0x80) {
      buffer.addByte(value);
    } else if (value < 0x4000) {
      buffer.addByte((value >> 8) | 0x80);
      buffer.addByte(value & 0xFF);
    } else {
      buffer.addByte((value >> 24) | 0xC0);
      buffer.addByte((value >> 16) & 0xFF);
      buffer.addByte((value >> 8) & 0xFF);
      buffer.addByte(value & 0xFF);
    }
  }

  void writeSLEB128(int value) {
    bool last = false;
    do {
      int part = value & 0x7f;
      value >>= 7;
      if ((value == 0 && (part & 0x40) == 0) ||
          (value == -1 && (part & 0x40) != 0)) {
        last = true;
      } else {
        part |= 0x80;
      }
      buffer.addByte(part);
    } while (!last);
  }
}

class BufferedReader {
  final List<int> _buffer;
  int _pos = 0;

  BufferedReader(this._buffer);

  int readByte() => _buffer[_pos++];

  int readPackedUInt30() {
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

  int readSLEB128() {
    int value = 0;
    int shift = 0;
    int part = 0;
    do {
      part = readByte();
      value |= (part & 0x7f) << shift;
      shift += 7;
    } while ((part & 0x80) != 0);
    const int kBitsPerInt = 64;
    if ((shift < kBitsPerInt) && ((part & 0x40) != 0)) {
      value |= (-1) << shift;
    }
    return value;
  }
}

class PackedUInt30DeltaEncoder {
  int _last = 0;

  void write(BufferedWriter write, int value) {
    write.writePackedUInt30(value - _last);
    _last = value;
  }
}

class PackedUInt30DeltaDecoder {
  int _last = 0;

  int read(BufferedReader reader) {
    int value = reader.readPackedUInt30() + _last;
    _last = value;
    return value;
  }
}

class SLEB128DeltaEncoder {
  int _last = 0;

  void write(BufferedWriter writer, int value) {
    writer.writeSLEB128(value - _last);
    _last = value;
  }
}

class SLEB128DeltaDecoder {
  int _last = 0;

  int read(BufferedReader reader) {
    int value = reader.readSLEB128() + _last;
    _last = value;
    return value;
  }
}
