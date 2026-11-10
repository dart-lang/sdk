// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'blake3.dart';

/// Incrementally computes an unkeyed BLAKE3-256 digest using scalar arithmetic.
///
/// Input bytes are consumed synchronously and never retained or modified.
/// [finish] returns independently owned bytes and rejects further input until
/// [reset]. Resetting also permits discarding an unfinished message.
final class ScalarBlake3Sink {
  final _ScalarBlake3 _core = _ScalarBlake3();
  late final Uint8List _block = Uint8List.view(_core._tailWords.buffer);

  // Retain the last block, even when full: its CHUNK_END and ROOT flags depend
  // on whether more input follows. Empty writes must not compress this block.
  int _blockLength = 0;
  int _blocksCompressed = 0;
  int _chunkCounter = 0;
  int _stackLength = 0;
  bool _isFinished = false;

  new() {
    _core._resetCv();
  }

  /// Adds [input] to the current message.
  ///
  /// Arbitrarily offset views are supported. Throws [StateError] after [finish],
  /// including for empty input.
  void add(Uint8List input) {
    if (_isFinished) throw StateError('BLAKE3 input is already finalized.');
    var start = 0;
    var end = input.length;
    while (start < end) {
      if (_blockLength == _Blake3Base._blockSizeInBytes) {
        _compressBlock(_core._tailWords, 0);
        _blockLength = 0;
      }

      // Compress aligned complete blocks directly from typed input. Leave at
      // least one byte unconsumed so the final block is handled by finish().
      if (_blockLength == 0 &&
          end - start > _Blake3Base._blockSizeInBytes &&
          (input.offsetInBytes + start) % 4 == 0) {
        var words = Uint32List.view(
          input.buffer,
          input.offsetInBytes + start,
          (end - start) ~/ 4,
        );
        var offset = 0;
        while (end - start > _Blake3Base._blockSizeInBytes) {
          _compressBlock(words, offset);
          offset += _Blake3Base._blockSizeInWords;
          start += _Blake3Base._blockSizeInBytes;
        }
      }

      var count = end - start;
      var space = _Blake3Base._blockSizeInBytes - _blockLength;
      if (count > space) count = space;
      _block.setRange(_blockLength, _blockLength + count, input, start);
      _blockLength += count;
      start += count;
    }
  }

  /// Finalizes the message and returns its 32-byte digest.
  ///
  /// Repeated calls return the same digest in independent, mutable storage.
  Uint8List finish() {
    if (!_isFinished) {
      _block.fillRange(_blockLength, _Blake3Base._blockSizeInBytes, 0);
      _core._compress(
        _core._chainingValue,
        _core._tailWords,
        0,
        _chunkCounter,
        _blockLength,
        _chunkEnd |
            (_blocksCompressed == 0 ? _chunkStart : 0) |
            (_chunkCounter == 0 ? _rootFlag : 0),
      );
      _core._finishCv(_stackLength);
      _isFinished = true;
    }
    return Uint8List.fromList(Uint8List.view(_core._chainingValue.buffer));
  }

  /// Starts an empty message, reusing scratch storage.
  void reset() {
    _blockLength = 0;
    _blocksCompressed = 0;
    _chunkCounter = 0;
    _stackLength = 0;
    _isFinished = false;
    _core._resetCv();
  }

  void _compressBlock(Uint32List words, int offset) {
    var endsChunk =
        _blocksCompressed ==
        _Blake3Base._chunkSizeInBytes ~/ _Blake3Base._blockSizeInBytes - 1;
    _core._compress(
      _core._chainingValue,
      words,
      offset,
      _chunkCounter,
      _Blake3Base._blockSizeInBytes,
      (_blocksCompressed == 0 ? _chunkStart : 0) | (endsChunk ? _chunkEnd : 0),
    );
    if (endsChunk) {
      _chunkCounter++;
      _stackLength = _core._pushCv(_chunkCounter, _stackLength);
      _blocksCompressed = 0;
      _core._resetCv();
    } else {
      _blocksCompressed++;
    }
  }
}
