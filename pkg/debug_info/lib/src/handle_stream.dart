// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'bytes.dart';
import 'handles.dart';

/// Mapping of instruction or byte offsets to [DebugInfo] handles.
class DebugInfoHandleReader extends BytesReader {
  int _offset = 0;
  int _handleIndex = 0;

  DebugInfo _handle = DebugInfo.none;

  DebugInfoHandleReader(super._bytes);

  int get offset => _offset;

  DebugInfo get handle => _handle;

  /// Advances to the last handle mapping with an offset `<= [targetOffset]`.
  ///
  /// Returns `true` if the reader advanced to a new handle.
  bool moveUntil(int targetOffset) {
    bool moved = false;
    while (true) {
      final savedByteOffset = byteOffset;
      final offset = _offset;
      final handleIndex = _handleIndex;
      final handle = _handle;

      if (!moveNext()) return moved;
      if (_offset > targetOffset) {
        byteOffset = savedByteOffset;
        _offset = offset;
        _handleIndex = handleIndex;
        _handle = handle;
        return moved;
      }
      moved = true;
    }
  }

  /// Advances to the next handle. Returns `false` if there are no more handles.
  bool moveNext() {
    if (isAtEnd) return false;

    final op = readByte();

    if (op < _HandleOpcode.moveShortMax) {
      _offset += (op >> 4) + _HandleSpecialOp.moveShortOffsetMin;
      _handleIndex += op & 0x0F;
      _handle = DebugItemInternalMethods.makeDebugInfoHandle(_handleIndex);
      return true;
    }

    if (op < _HandleOpcode.moveByteMax) {
      _offset += op & 0x0F;
      _handleIndex += readByte().toSigned(8);
      _handle = DebugItemInternalMethods.makeDebugInfoHandle(_handleIndex);
      return true;
    }

    switch (op) {
      case _HandleOpcode.move:
        _offset += readVarint();
        _handleIndex += readZigZag();
        _handle = DebugItemInternalMethods.makeDebugInfoHandle(_handleIndex);
        return true;
      case _HandleOpcode.setUnmapped:
        _offset += readVarint();
        _handle = DebugInfo.none;
        return true;
      case _HandleOpcode.setAll:
        _offset += readVarint();
        _handleIndex = readVarint();
        _handle = DebugItemInternalMethods.makeDebugInfoHandle(_handleIndex);
        return true;
      default:
        throw StateError('Invalid debug info bytecode opcode: $op');
    }
  }
}

/// Mapping of instruction or byte offsets to [DebugInfo] handles.
class DebugInfoHandleWriter extends BytesWriter {
  // Last flushed entry used as the baseline for delta encoding.
  int _lastOffset = -1;
  int _lastHandleIndex = 0;
  bool _lastHasHandle = false;

  // Pending entry not yet encoded.
  bool _hasPending = false;
  int _pendingOffset = -1;
  int _pendingHandleIndex = 0;
  bool _pendingHasHandle = false;

  DebugInfoHandleWriter();

  @override
  bool get isEmpty => super.isEmpty && !_hasPending;

  /// Sets the handle for the code at [offset].
  ///
  /// During IR construction, [offset] is the 0-based instruction index in the
  /// instruction sequence. During serialization, [offset] is the byte offset
  /// in the serializer / section / Wasm module.
  void setInfo(int offset, DebugInfo info) {
    if (info == DebugInfo.none) {
      clearInfo(offset);
      return;
    }
    if (_hasPending) {
      if (offset == _pendingOffset) {
        // Overwrite pending entry at the same offset.
        _pendingHandleIndex = info.index;
        _pendingHasHandle = true;
        return;
      }
      assert(offset > _pendingOffset);
      _flushPending();
    }

    _hasPending = true;
    _pendingOffset = offset;
    _pendingHandleIndex = info.index;
    _pendingHasHandle = true;
  }

  /// Clears the debug handle for the code at [offset], marking it unmapped.
  ///
  /// During IR construction, [offset] is the 0-based instruction index in the
  /// instruction sequence. During serialization, [offset] is the byte offset
  /// in the serializer / section / Wasm module.
  void clearInfo(int offset) {
    if (_hasPending) {
      if (offset == _pendingOffset) {
        _pendingHasHandle = false;
        return;
      }
      assert(offset > _pendingOffset);
      _flushPending();
    }

    _hasPending = true;
    _pendingOffset = offset;
    _pendingHasHandle = false;
  }

  void _flushPending() {
    if (!_hasPending) return;
    _hasPending = false;

    // Check if this pending entry is redundant compared to last flushed entry.
    if (_lastOffset != -1) {
      if (_lastHasHandle == _pendingHasHandle) {
        if (!_pendingHasHandle) return; // Both unmapped.
        if (_lastHandleIndex == _pendingHandleIndex) {
          return; // Identical handle.
        }
      }
    }

    final deltaOffset = _lastOffset == -1
        ? _pendingOffset
        : _pendingOffset - _lastOffset;
    assert(deltaOffset >= 0);

    if (!_pendingHasHandle) {
      addByte(_HandleOpcode.setUnmapped);
      writeVarint(deltaOffset);
    } else if (_lastOffset == -1) {
      addByte(_HandleOpcode.setAll);
      writeVarint(deltaOffset);
      writeVarint(_pendingHandleIndex);
    } else {
      final deltaHandle = _pendingHandleIndex - _lastHandleIndex;

      if (deltaOffset >= _HandleSpecialOp.moveShortOffsetMin &&
          deltaOffset <= _HandleSpecialOp.moveShortOffsetMax &&
          deltaHandle >= 0 &&
          deltaHandle <= _HandleSpecialOp.moveShortHandleMax) {
        addByte(
          ((deltaOffset - _HandleSpecialOp.moveShortOffsetMin) << 4) |
              deltaHandle,
        );
      } else if (deltaOffset <= _HandleSpecialOp.moveByteOffsetMax &&
          deltaHandle >= _HandleSpecialOp.moveByteHandleMin &&
          deltaHandle <= _HandleSpecialOp.moveByteHandleMax) {
        addByte(_HandleOpcode.moveByte | deltaOffset);
        addByte(deltaHandle & 0xFF);
      } else {
        addByte(_HandleOpcode.move);
        writeVarint(deltaOffset);
        writeZigZag(deltaHandle);
      }
    }

    _lastOffset = _pendingOffset;
    _lastHasHandle = _pendingHasHandle;
    // An unmapped entry keeps the last handle, which the next move is relative
    // to, as in the reader.
    if (_pendingHasHandle) {
      _lastHandleIndex = _pendingHandleIndex;
    }
  }

  @override
  Uint8List build() {
    _flushPending();
    return super.build();
  }

  DebugInfoHandleReader get reader => DebugInfoHandleReader(build());
}

/// Bytecode opcodes for delta-encoded [DebugInfo] handles.
abstract final class _HandleOpcode {
  /// Opcodes `0x00..0x7F`: 1-byte encoding for short delta.
  ///     0xxxyyyy: xxx is deltaOffset - 1, yyyy is deltaHandle
  static const int moveShortMax = 0x80;

  /// Opcodes `0x80..0x8F`: 2-byte encoding for medium delta.
  ///     1000xxxx yyyyyyyy: xxxx is deltaOffset, yyyyyyyy is deltaHandle as a
  ///     signed byte
  static const int moveByte = 0x80;
  static const int moveByteMax = 0x90;

  /// Multibyte opcode with `deltaOffset` varint and `deltaHandle` zigzag.
  static const int move = 0xC0;

  /// Multibyte opcode with `deltaOffset` varint. Marks subsequent code
  /// unmapped. The next move is relative to the handle before the unmapped
  /// code.
  static const int setUnmapped = 0xC4;

  /// Multibyte opcode with `deltaOffset` varint and `handleIndex` varint, for
  /// the first handle.
  static const int setAll = 0xC5;
}

/// Encoding parameters for the short and medium deltas.
abstract final class _HandleSpecialOp {
  // moveShort: 3 bits offset from 1 to 8 stored minus 1, 4 bits handle delta
  // from 0 to 15. The offset delta is never 0, since a handle at the pending
  // offset replaces the pending entry.
  static const int moveShortOffsetMin = 1;
  static const int moveShortOffsetMax = 8;
  static const int moveShortHandleMax = 15;

  // moveByte: 4 bits offset from 0 to 15, and a signed byte handle delta.
  static const int moveByteOffsetMax = 15;
  static const int moveByteHandleMin = -128;
  static const int moveByteHandleMax = 127;
}
