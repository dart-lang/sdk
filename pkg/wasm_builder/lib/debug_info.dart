// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Each wasm module is represented by a `ir.Module` instance which refers to
/// everything in it, including `ir.Instructions` that represent bodies of
/// functions (as well as initializer expressions for globals and tables).
///
/// The `ir.Instructions` include debug information that allows one to map each
/// wasm instruction to a source file, line and column (and possibly other state
/// in the future).
///
/// To represent this in a memory efficient way, we use a compact bytecode-like
/// encoding of this debug information in a `Uint8List` next to the main
/// instruction stream.
///
/// One can read the instruction stream and the debug information in parallel to
/// obtain debug info for a particular instruction (the [DebugInfoReader] can be
/// andvanced until the corresponding offset of the instruction of interest).
///
/// When serializing the `ir.Module` and it's `ir.Instructions` to a binary we
/// inform a [DebugInfoSerializer] about offsets of the instructions as well as
/// the debug info where offsets are byte offsets (rather than instruction
/// offsets).
///
/// When deserializing into an `ir.Module` we inform a [DebugInfoDeserializer]
/// about function and instruction offsets, allowing it to build debug info
/// while decoding the binary which will then be attached to the corresponding
/// `ir.Instructions` object.
library;

import 'dart:typed_data';

/// Information about source files and symbol names referenced in a Wasm module.
class DebugInfoTables {
  final Map<Uri, int> _fileIndices = {};
  final List<Uri> files = [];

  final Map<String, int> _nameIndices = {};
  final List<String> names = [];

  int getFileIndex(Uri uri) =>
      _fileIndices[uri] ??= (files..add(uri)).length - 1;

  int getNameIndex(String name) =>
      _nameIndices[name] ??= (names..add(name)).length - 1;
}

/// Interface for streaming debug info decoders used during module deserialization.
abstract interface class DebugInfoDeserializer {
  DebugInfoTables? get debugInfoTables;

  /// Called before deserializing instructions of a function.
  /// [fileOffset] is the file offset where the function's instructions begin.
  void startFunction(int fileOffset);

  /// Called when an instruction is about to be deserialized.
  /// [instructionIndex] is the 0-based index of this instruction in the function.
  /// [fileOffset] is the exact file offset of this instruction in the Wasm binary.
  void onInstruction(int instructionIndex, int fileOffset);

  /// Called when instruction deserialization for the current function ends.
  /// [fileOffset] is the file offset where the function's instructions end.
  /// Returns the instruction-offset based bytecode for `ir.Instructions.debugInfo`.
  Uint8List? endFunction(int fileOffset);
}

/// Interface for building debug info during module serialization.
abstract interface class DebugInfoSerializer {
  /// Adds function debug info with byte offsets relative to the start of the
  /// function's instructions.
  /// [functionCodeOffset] is the byte offset of the function's instructions
  /// within the Code section payload.
  /// [byteDebugInfo] is the byte-offset based bytecode for the function.
  void addFunction(int functionCodeOffset, Uint8List byteDebugInfo);

  /// Called after the Code section is serialized and its payload [fileOffset]
  /// in the Wasm binary is known.
  void setCodeSectionFileOffset(int fileOffset);
}

/// Compact mapping of wasm instruction or byte offsets to debug information.
///
/// The `offset`s are
///
/// * instruction offsets for debug infos installed on the in-memory wasm module
///   representation (i.e. `ir.Instructions` of the `ir.Module`s).
///
/// * byte offsets for debug infos during serialization when given to
///   [DebugInfoSerializer].
///
/// For more details, see library documentation.
class DebugInfoReader {
  final Uint8List _bytes;
  final DebugInfoTables? _debugInfoTables;

  int _byteOffset = 0;
  int _offset = 0;
  int _fileIndex = 0;
  int _line = 0;
  int _col = 0;
  int _nameIndex = -1;
  bool _hasSourcePosition = false;

  DebugInfoReader(this._bytes, [this._debugInfoTables]);

  /// The offset of the current mapping.
  ///
  /// The offset may represent an instruction offset in the body of a function
  /// or a byte offset (depending on usage).
  int get offset => _offset;

  /// Whether the code at [offset] has a source position.
  bool get hasSourcePosition => _hasSourcePosition;

  /// File URI of the mapped source, or `null` if unmapped or `debugInfoTables` was not provided.
  Uri? get fileUri {
    if (!_hasSourcePosition || _debugInfoTables == null) return null;
    final files = _debugInfoTables.files;
    return _fileIndex < files.length ? files[_fileIndex] : null;
  }

  /// 0-based line number in the source file.
  int get line => _line;

  /// 0-based column number in the source file.
  int get col => _col;

  /// Index of the source file in `DebugInfoTables.files`.
  int get fileIndex => _fileIndex;

  /// Index of the name in `DebugInfoTables.names`, or `-1` if unnamed.
  int get nameIndex => _nameIndex;

  /// Name of the mapped code (e.g. member name), or `null` if unnamed or `debugInfoTables` was not provided.
  String? get name {
    if (!_hasSourcePosition || _nameIndex < 0 || _debugInfoTables == null) {
      return null;
    }
    final names = _debugInfoTables.names;
    return _nameIndex < names.length ? names[_nameIndex] : null;
  }

  /// Advances to the next source mapping. Returns `false` if there are no more
  /// mappings.
  bool moveNext() {
    if (_byteOffset >= _bytes.length) return false;
    final op = _bytes[_byteOffset++];

    if (op < _Opcode.specialSameLineMax) {
      final deltaOffset = op >> 4;
      final deltaCol = (op & 0x0F) - _SpecialOp.sameLineColBias;
      _offset += deltaOffset;
      _col += deltaCol;
      _hasSourcePosition = true;
      return true;
    } else if (op < _Opcode.specialNextLineMax) {
      final adj = op - _Opcode.specialNextLineBase;
      final deltaOffset = adj >> 3;
      final deltaCol = (adj & 0x07) - _SpecialOp.nextLineColBias;
      _offset += deltaOffset;
      _line += 1;
      _col += deltaCol;
      _hasSourcePosition = true;
      return true;
    }

    switch (op) {
      case _Opcode.changeLineCol:
        _offset += _readVarint();
        _line += _readZigZag();
        _col += _readZigZag();
        _hasSourcePosition = true;
        return true;
      case _Opcode.setUnmapped:
        _offset += _readVarint();
        _hasSourcePosition = false;
        return true;
      case _Opcode.setAll:
        _offset += _readVarint();
        _fileIndex = _readVarint();
        _line = _readVarint();
        _col = _readVarint();
        final rawName = _readVarint();
        _nameIndex = rawName == 0 ? -1 : rawName - 1;
        _hasSourcePosition = true;
        return true;
      default:
        throw StateError('Invalid debug info bytecode opcode: $op');
    }
  }

  int _readVarint() {
    int result = 0;
    int shift = 0;
    while (true) {
      final byte = _bytes[_byteOffset++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return result;
  }

  int _readZigZag() {
    final value = _readVarint();
    return (value >>> 1) ^ -(value & 1);
  }
}

/// Compact mapping of wasm instructions to debug information.
class DebugInfoWriter {
  static final Uint8List _emptyBuffer = Uint8List(0);
  static const int _initialCapacity = 32;

  final DebugInfoTables? debugInfoTables;

  Uint8List _buffer = _emptyBuffer;
  int _length = 0;

  // Last flushed entry (baseline for delta encoding).
  int _lastOffset = -1;
  int _lastFileIndex = 0;
  int _lastLine = 0;
  int _lastCol = 0;
  int _lastNameIndex = -1;
  bool _lastHasSourcePosition = false;

  // Pending entry (not yet encoded).
  bool _hasPending = false;
  int _pendingOffset = -1;
  int _pendingFileIndex = 0;
  int _pendingLine = 0;
  int _pendingCol = 0;
  int _pendingNameIndex = -1;
  bool _pendingHasSourcePosition = false;

  Uint8List? _built;

  DebugInfoWriter([this.debugInfoTables]);

  bool get isEmpty =>
      _built != null ? _built!.isEmpty : (_length == 0 && !_hasPending);

  void _addByte(int byte) {
    if (_length == _buffer.length) {
      final newCapacity = _buffer.isEmpty
          ? _initialCapacity
          : _buffer.length * 2;
      final newBuffer = Uint8List(newCapacity);
      if (_length > 0) {
        newBuffer.setRange(0, _length, _buffer);
      }
      _buffer = newBuffer;
    }
    _buffer[_length++] = byte;
  }

  /// Sets the source position for the code at [offset].
  ///
  /// During IR construction, [offset] is the 0-based instruction index in the
  /// instruction sequence. During serialization, [offset] is the byte offset
  /// in the serializer / section / Wasm module.
  void setSourcePosition(
    int offset,
    Uri fileUri,
    int line,
    int col,
    String? name,
  ) {
    final int fileIndex = debugInfoTables!.getFileIndex(fileUri);
    final int nameIndex = name != null
        ? debugInfoTables!.getNameIndex(name)
        : -1;
    setSourcePositionWithIndices(offset, fileIndex, line, col, nameIndex);
  }

  /// Sets the source position for the code at [offset] using table indices.
  ///
  /// During IR construction, [offset] is the 0-based instruction index in the
  /// instruction sequence. During serialization, [offset] is the byte offset
  /// in the serializer / section / Wasm module.
  void setSourcePositionWithIndices(
    int offset,
    int fileIndex,
    int line,
    int col,
    int nameIndex,
  ) {
    if (_hasPending) {
      if (offset == _pendingOffset) {
        // Overwrite pending entry at the same offset.
        _pendingFileIndex = fileIndex;
        _pendingLine = line;
        _pendingCol = col;
        _pendingNameIndex = nameIndex;
        _pendingHasSourcePosition = true;
        return;
      }
      assert(offset > _pendingOffset);
      _flushPending();
    }

    _hasPending = true;
    _pendingOffset = offset;
    _pendingFileIndex = fileIndex;
    _pendingLine = line;
    _pendingCol = col;
    _pendingNameIndex = nameIndex;
    _pendingHasSourcePosition = true;
  }

  /// Clears the source position for the code at [offset], marking it unmapped.
  ///
  /// During IR construction, [offset] is the 0-based instruction index in the
  /// instruction sequence. During serialization, [offset] is the byte offset
  /// in the serializer / section / Wasm module.
  void clearSourcePosition(int offset) {
    if (_hasPending) {
      if (offset == _pendingOffset) {
        _pendingHasSourcePosition = false;
        return;
      }
      assert(offset > _pendingOffset);
      _flushPending();
    }

    _hasPending = true;
    _pendingOffset = offset;
    _pendingHasSourcePosition = false;
  }

  void _flushPending() {
    if (!_hasPending) return;
    _hasPending = false;

    // Check if this pending entry is redundant compared to last flushed entry.
    if (_lastOffset != -1) {
      if (_lastHasSourcePosition == _pendingHasSourcePosition) {
        if (!_pendingHasSourcePosition) return; // Both unmapped.
        if (_lastFileIndex == _pendingFileIndex &&
            _lastLine == _pendingLine &&
            _lastCol == _pendingCol &&
            _lastNameIndex == _pendingNameIndex) {
          return; // Identical source location.
        }
      }
    }

    final deltaOffset = _lastOffset == -1
        ? _pendingOffset
        : _pendingOffset - _lastOffset;
    assert(deltaOffset >= 0);

    if (!_pendingHasSourcePosition) {
      _addByte(_Opcode.setUnmapped);
      _writeVarint(deltaOffset);
    } else if (_lastOffset == -1 ||
        !_lastHasSourcePosition ||
        _lastFileIndex != _pendingFileIndex ||
        _lastNameIndex != _pendingNameIndex) {
      _addByte(_Opcode.setAll);
      _writeVarint(deltaOffset);
      _writeVarint(_pendingFileIndex);
      _writeVarint(_pendingLine);
      _writeVarint(_pendingCol);
      _writeVarint(_pendingNameIndex == -1 ? 0 : _pendingNameIndex + 1);
    } else {
      final deltaLine = _pendingLine - _lastLine;
      final deltaCol = _pendingCol - _lastCol;

      if (deltaLine == 0 &&
          deltaOffset <= _SpecialOp.sameLineOffsetMax &&
          deltaCol >= _SpecialOp.sameLineColMin &&
          deltaCol <= _SpecialOp.sameLineColMax) {
        _addByte((deltaOffset << 4) | (deltaCol + _SpecialOp.sameLineColBias));
      } else if (deltaLine == 1 &&
          deltaOffset <= _SpecialOp.nextLineOffsetMax &&
          deltaCol >= _SpecialOp.nextLineColMin &&
          deltaCol <= _SpecialOp.nextLineColMax) {
        _addByte(
          _Opcode.specialNextLineBase |
              (deltaOffset << 3) |
              (deltaCol + _SpecialOp.nextLineColBias),
        );
      } else {
        _addByte(_Opcode.changeLineCol);
        _writeVarint(deltaOffset);
        _writeZigZag(deltaLine);
        _writeZigZag(deltaCol);
      }
    }

    _lastOffset = _pendingOffset;
    _lastFileIndex = _pendingFileIndex;
    _lastLine = _pendingLine;
    _lastCol = _pendingCol;
    _lastNameIndex = _pendingNameIndex;
    _lastHasSourcePosition = _pendingHasSourcePosition;
  }

  void _writeVarint(int value) {
    assert(value >= 0);
    while (value >= 0x80) {
      _addByte((value & 0x7F) | 0x80);
      value >>= 7;
    }
    _addByte(value & 0x7F);
  }

  void _writeZigZag(int value) {
    final encoded = (value << 1) ^ (value >> 63);
    _writeVarint(encoded);
  }

  Uint8List build() {
    if (_built != null) return _built!;
    _flushPending();
    if (_length == 0) {
      return _built = _emptyBuffer;
    }
    final result = Uint8List(_length);
    result.setRange(0, _length, _buffer);
    _buffer = _emptyBuffer;
    _length = 0;
    return _built = result;
  }

  DebugInfoReader get reader => DebugInfoReader(build(), debugInfoTables);
}

/// Bytecode opcodes for delta-encoded debug information.
abstract final class _Opcode {
  /// Opcodes `0x00..0x7F`: 1-byte encoding for `deltaLine == 0`.
  static const int specialSameLineMax = 0x80;

  /// Opcodes `0x80..0xBF`: 1-byte encoding for `deltaLine == 1`.
  static const int specialNextLineBase = 0x80;
  static const int specialNextLineMax = 0xC0;

  /// Multibyte opcode: `deltaOffset` (varint), `deltaLine` (zigzag), `deltaCol` (zigzag).
  static const int changeLineCol = 0xC0;

  /// Multibyte opcode: `deltaOffset` (varint). Marks subsequent code unmapped.
  static const int setUnmapped = 0xC4;

  /// Multibyte opcode: `deltaOffset` (varint), `fileIndex` (varint), `line` (varint),
  /// `col` (varint), `nameIndex + 1` (varint, 0 means unnamed).
  static const int setAll = 0xC5;
}

/// Encoding parameters and bit layout for 1-byte special opcodes.
abstract final class _SpecialOp {
  // deltaLine == 0: 3 bits offset (0..7), 4 bits col (-8..7, biased by +8)
  static const int sameLineOffsetMax = 7;
  static const int sameLineColBias = 8;
  static const int sameLineColMin = -8;
  static const int sameLineColMax = 7;

  // deltaLine == 1: 3 bits offset (0..7), 3 bits col (-4..3, biased by +4)
  static const int nextLineOffsetMax = 7;
  static const int nextLineColBias = 4;
  static const int nextLineColMin = -4;
  static const int nextLineColMax = 3;
}
