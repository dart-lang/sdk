// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.source_positions;

import 'bytecode_serialization.dart' show BufferedWriter, BufferedReader;

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

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(mapping.length);
    final encodePC = new PackedUInt30DeltaEncoder();
    final encodeOffset = new SLEB128DeltaEncoder();
    mapping.forEach((int pc, int fileOffset) {
      encodePC.write(writer, pc);
      encodeOffset.write(writer, fileOffset);
    });
  }

  SourcePositions.read(BufferedReader reader) {
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
