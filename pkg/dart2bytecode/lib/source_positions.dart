// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  // Special value of fileOffset which marks synthetic code without a source
  // position.
  static const noSourcePosition = -1;
  // The flags encoded into the low bits of the source position.
  static const syntheticFlag = 1 << 0;
  static const yieldPointFlag = 1 << 1;
  static const _numFlags = 2;
  static const _flagMask = (1 << _numFlags) - 1;

  final _positions = <int>[]; // Pairs (PC, fileOffset).
  // Stored separately just to make sure no call to add uses a smaller
  // PC offset than the previous call, even if the previous call didn't
  // add an entry to the list because the last entry covers it.
  int _lastPcAdded = 0;

  SourcePositions();

  int _encode(int fileOffset, int flags) =>
      (flags == 0 || fileOffset == noSourcePosition)
          ? fileOffset
          : -((fileOffset << _numFlags) | flags) - 1;

  (int, int) _decode(int encoded) {
    if (encoded >= 0 || encoded == noSourcePosition) {
      return (encoded, 0);
    }
    final value = -encoded - 1;
    return (value >> _numFlags, value & _flagMask);
  }

  // Adds a mapping from the PC to the given file offset as long as there's
  // no mapping for that PC already, otherwise no change is made. Returns
  // whether the requested mapping exists, which can be either because a new
  // mapping was created or the mapping already existed before the request.
  //
  // Marks the source position as synthetic (not to be used by the debugger
  // or coverage calculations) if [(flags & syntheticFlag) != 0].
  //
  // Marks the pc as within a yield point if [(flags & yieldPointFlag) != 0].
  //
  // Assumes that the pc is greater than or equal to the pc used in the most
  // recent call to add, if any.
  bool add(int pc, int fileOffset, int flags) {
    assert(fileOffset >= 0 || fileOffset == noSourcePosition);
    assert((flags & ~_flagMask) == 0);
    if (_lastPcAdded > pc) {
      throw ArgumentError('Attempt to add entry for $pc after $_lastPcAdded');
    }
    _lastPcAdded = pc;
    final encodedFileOffset = _encode(fileOffset, flags);
    if (_positions.isNotEmpty) {
      final i = _positions.length - 2;
      final lastPc = _positions[i];
      final lastFileOffset = _positions[i + 1];
      if (lastFileOffset == encodedFileOffset) {
        // The last entry covers this PC offset as well, or this is a repeated
        // request for the same (pc, offset) mapping.
        return true;
      }
      if (lastPc == pc) {
        // There's already a mapping for (pc, lastFileOffset).
        return false;
      }
    }
    _positions.add(pc);
    _positions.add(encodedFileOffset);
    return true;
  }

  bool get isEmpty => _positions.isEmpty;
  bool get isNotEmpty => !isEmpty;

  void write(BufferedWriter writer) {
    final pairs = _positions.length ~/ 2;
    writer.writePackedUInt30(pairs);
    final encodePC = new PackedUInt30DeltaEncoder();
    final encodeOffset = new SLEB128DeltaEncoder();
    for (int i = 0; i < pairs; i++) {
      encodePC.write(writer, _positions[2 * i]);
      encodeOffset.write(writer, _positions[2 * i + 1]);
    }
  }

  SourcePositions.read(BufferedReader reader) {
    final int pairs = reader.readPackedUInt30();
    final decodePC = new PackedUInt30DeltaDecoder();
    final decodeOffset = new SLEB128DeltaDecoder();
    for (int i = 0; i < pairs; i++) {
      _positions.add(decodePC.read(reader));
      _positions.add(decodeOffset.read(reader));
    }
    _lastPcAdded = _positions.isEmpty ? 0 : _positions[_positions.length - 2];
  }

  @override
  String toString() => _positions.toString();

  Map<int, String> getBytecodeAnnotations() {
    final map = <int, String>{};
    for (int i = 0; i < _positions.length; i += 2) {
      final pc = _positions[i];
      final (fileOffset, flags) = _decode(_positions[i + 1]);
      String annotation = '';
      if ((flags & syntheticFlag) != 0) {
        annotation += 'synthetic ';
      }
      if ((flags & yieldPointFlag) != 0) {
        annotation += 'yield point @ ';
      }
      annotation += 'source position $fileOffset';
      // There is at most one entry per PC offset.
      assert(map[pc] == null);
      map[pc] = annotation;
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
