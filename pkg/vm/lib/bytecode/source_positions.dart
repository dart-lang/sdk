// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.source_positions;

import 'bytecode_serialization.dart'
    show
        BufferedWriter,
        BufferedReader,
        BytecodeDeclaration,
        PackedUInt30DeltaEncoder,
        PackedUInt30DeltaDecoder,
        SLEB128DeltaEncoder,
        SLEB128DeltaDecoder;

/// Maintains mapping between bytecode instructions and source positions.
class SourcePositions extends BytecodeDeclaration {
  // Special value of fileOffset which marks synthetic code without source
  // position.
  static const syntheticCodeMarker = -1;
  // Special value of fileOffset which marks yield point.
  static const yieldPointMarker = -2;

  final List<int> _positions = <int>[]; // Pairs (PC, fileOffset).
  int _lastPc = 0;
  int _lastOffset = 0;

  SourcePositions();

  void add(int pc, int fileOffset) {
    assert(pc > _lastPc);
    assert((fileOffset >= 0) || (fileOffset == syntheticCodeMarker));
    if (fileOffset != _lastOffset) {
      _positions.add(pc);
      _positions.add(fileOffset);
      _lastPc = pc;
      _lastOffset = fileOffset;
    }
  }

  void addYieldPoint(int pc, int fileOffset) {
    assert(pc > _lastPc);
    assert((fileOffset >= 0) || (fileOffset == syntheticCodeMarker));
    _positions.add(pc);
    _positions.add(yieldPointMarker);
    _positions.add(pc);
    _positions.add(fileOffset);
    _lastPc = pc;
    _lastOffset = fileOffset;
  }

  bool get isEmpty => _positions.isEmpty;
  bool get isNotEmpty => !isEmpty;

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(_positions.length ~/ 2);
    final encodePC = new PackedUInt30DeltaEncoder();
    final encodeOffset = new SLEB128DeltaEncoder();
    for (int i = 0; i < _positions.length; i += 2) {
      final int pc = _positions[i];
      final int fileOffset = _positions[i + 1];
      encodePC.write(writer, pc);
      encodeOffset.write(writer, fileOffset);
    }
  }

  SourcePositions.read(BufferedReader reader) {
    final int length = reader.readPackedUInt30();
    final decodePC = new PackedUInt30DeltaDecoder();
    final decodeOffset = new SLEB128DeltaDecoder();
    for (int i = 0; i < length; ++i) {
      int pc = decodePC.read(reader);
      int fileOffset = decodeOffset.read(reader);
      _positions.add(pc);
      _positions.add(fileOffset);
    }
  }

  @override
  String toString() => _positions.toString();

  Map<int, String> getBytecodeAnnotations() {
    final map = <int, String>{};
    for (int i = 0; i < _positions.length; i += 2) {
      final int pc = _positions[i];
      final int fileOffset = _positions[i + 1];
      final entry = (fileOffset == yieldPointMarker)
          ? 'yield point'
          : 'source position $fileOffset';
      if (map[pc] == null) {
        map[pc] = entry;
      } else {
        map[pc] = "${map[pc]}; $entry";
      }
    }
    return map;
  }
}

/// Keeps file offsets of line starts. This information is used to
/// decode source positions to line/column.
class LineStarts extends BytecodeDeclaration {
  final List<int> lineStarts;

  LineStarts(this.lineStarts);

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(lineStarts.length);
    final encodeLineStarts = new PackedUInt30DeltaEncoder();
    for (int lineStart in lineStarts) {
      encodeLineStarts.write(writer, lineStart);
    }
  }

  factory LineStarts.read(BufferedReader reader) {
    final decodeLineStarts = new PackedUInt30DeltaDecoder();
    final lineStarts = new List<int>.generate(
        reader.readPackedUInt30(), (_) => decodeLineStarts.read(reader));
    return new LineStarts(lineStarts);
  }

  @override
  String toString() => 'Line starts: $lineStarts';
}
