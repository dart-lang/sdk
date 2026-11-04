// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'blake3.dart';

const _blake3Iv = [
  0x6a09e667,
  0xbb67ae85,
  0x3c6ef372,
  0xa54ff53a,
  0x510e527f,
  0x9b05688c,
  0x1f83d9ab,
  0x5be0cd19,
];
const _chunkEnd = 2;
const _chunkStart = 1;
const _parentFlag = 4;
const _rootFlag = 8;

/// Chunk processing, tree traversal, and reusable scratch storage.
///
/// See the [BLAKE3 project](https://github.com/BLAKE3-team/BLAKE3) for the
/// specification and reference implementation.
abstract class _Blake3Base {
  static const int _blockSizeInBytes = 64;
  static const int _blockSizeInWords = 16;
  static const int _chunkSizeInBytes = 1024;

  final Uint32List _chainingValue = Uint32List(8);
  final Uint32List _parentBlock = Uint32List(_blockSizeInWords);
  final Uint32List _tailWords = Uint32List(_blockSizeInWords);
  final Uint32List _cvStack = Uint32List(54 * 8);

  /// Returns the 32-byte digest of precisely the bytes in [input].
  ///
  /// Arbitrarily offset views and unmodifiable inputs are supported. Output
  /// does not alias [input] or the output of any previous call.
  Uint8List hash(Uint8List input) {
    // Normalize subviews once for aligned word loads. Ordinary Uint8List
    // inputs need no copy.
    if (input.offsetInBytes % 4 != 0) {
      input = Uint8List.fromList(input);
    }
    var words = Uint32List.view(
      input.buffer,
      input.offsetInBytes,
      input.length ~/ 4,
    );
    var stackLength = 0;
    var chunkCount =
        (input.length + _chunkSizeInBytes - 1) ~/ _chunkSizeInBytes;
    var chunks = chunkCount == 0 ? 1 : chunkCount;
    for (var chunk = 0; chunk < chunks; chunk++) {
      var start = chunk * _chunkSizeInBytes;
      var remaining = input.length - start;
      var chunkLength = remaining < _chunkSizeInBytes
          ? remaining
          : _chunkSizeInBytes;
      var fullBlocks = chunkLength ~/ _blockSizeInBytes;
      var tailLength = chunkLength % _blockSizeInBytes;
      var endFlags = _chunkEnd | (chunks == 1 ? _rootFlag : 0);
      if (fullBlocks > 0) {
        _compressChunkBlocks(
          words,
          start ~/ 4,
          chunk,
          fullBlocks,
          tailLength == 0 ? endFlags : 0,
        );
      } else {
        _resetCv();
      }
      if (tailLength != 0 || chunkLength == 0) {
        _tailWords.fillRange(0, _blockSizeInWords, 0);
        Uint8List.view(_tailWords.buffer).setRange(
          0,
          tailLength,
          input,
          start + fullBlocks * _blockSizeInBytes,
        );
        _compress(
          _chainingValue,
          _tailWords,
          0,
          chunk,
          tailLength,
          endFlags | (fullBlocks == 0 ? _chunkStart : 0),
        );
      }
      if (chunk == chunks - 1) {
        _finishCv(stackLength);
      } else {
        stackLength = _pushCv(chunk + 1, stackLength);
      }
    }
    return Uint8List.fromList(Uint8List.view(_chainingValue.buffer));
  }

  void _compress(
    Uint32List cv,
    Uint32List words,
    int offset,
    int counter,
    int blockLength,
    int flags,
  );

  /// Starts a chunk and consumes its complete blocks.
  ///
  /// Only the last block may receive CHUNK_END/ROOT; a partial final block is
  /// handled by [hash] afterward.
  void _compressChunkBlocks(
    Uint32List words,
    int offset,
    int counter,
    int blocks,
    int lastFlags,
  ) {
    _resetCv();
    for (var block = 0; block < blocks; block++) {
      _compress(
        _chainingValue,
        words,
        offset + block * _blockSizeInWords,
        counter,
        _blockSizeInBytes,
        (block == 0 ? _chunkStart : 0) | (block == blocks - 1 ? lastFlags : 0),
      );
    }
  }

  /// Combines a stacked left child with the current right child, replacing
  /// [_chainingValue].
  void _compressStackParent(int offset, int flags) {
    _parentBlock.setRange(0, 8, _cvStack, offset);
    _parentBlock.setRange(8, _blockSizeInWords, _chainingValue);
    _resetCv();
    _compress(_chainingValue, _parentBlock, 0, 0, _blockSizeInBytes, flags);
  }

  void _finishCv(int stackLength) {
    while (stackLength > 0) {
      stackLength--;
      _compressStackParent(
        stackLength * 8,
        _parentFlag | (stackLength == 0 ? _rootFlag : 0),
      );
    }
  }

  int _pushCv(int count, int stackLength) {
    while (count.isEven) {
      stackLength--;
      _compressStackParent(stackLength * 8, _parentFlag);
      count >>= 1;
    }
    _cvStack.setRange(stackLength * 8, (stackLength + 1) * 8, _chainingValue);
    return stackLength + 1;
  }

  /// Resets the chaining value to the initialization vector.
  ///
  /// Direct stores avoid a generic `List<int>`-to-typed-data copy in this hot
  /// operation.
  @pragma('vm:prefer-inline')
  void _resetCv() {
    // Write the highest index first to eliminate subsequent bounds checks.
    _chainingValue[7] = _blake3Iv[7];
    _chainingValue[0] = _blake3Iv[0];
    _chainingValue[1] = _blake3Iv[1];
    _chainingValue[2] = _blake3Iv[2];
    _chainingValue[3] = _blake3Iv[3];
    _chainingValue[4] = _blake3Iv[4];
    _chainingValue[5] = _blake3Iv[5];
    _chainingValue[6] = _blake3Iv[6];
  }
}
