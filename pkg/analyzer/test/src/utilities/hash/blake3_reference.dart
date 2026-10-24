// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

const _iv = [
  0x6a09e667,
  0xbb67ae85,
  0x3c6ef372,
  0xa54ff53a,
  0x510e527f,
  0x9b05688c,
  0x1f83d9ab,
  0x5be0cd19,
];

const _permutation = [2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8];

/// Test-only, deliberately direct implementation of unkeyed BLAKE3-256.
///
/// Algorithm: https://github.com/BLAKE3-team/BLAKE3-specs/blob/master/blake3.pdf
///
/// This uses recursive tree construction, byte-wise input/output, and looped
/// compression. It shares no code, generated schedules, or tree machinery with
/// the optimized implementations. Official vectors validate this oracle too.
Uint8List referenceBlake3(Uint8List input) {
  var output = _subtree(input, 0, input.length);
  var words = _compress(
    output.cv,
    output.block,
    0,
    output.length,
    output.flags | 8, // ROOT uses output-block counter zero.
  );
  return Uint8List.fromList([
    for (var i = 0; i < 32; i++) (words[i ~/ 4] >>> (8 * (i % 4))) & 255,
  ]);
}

List<int> _compress(
  List<int> cv,
  List<int> block,
  int counter,
  int length,
  int flags,
) {
  var state = [
    ...cv,
    ..._iv.take(4),
    counter & 0xffffffff,
    counter ~/ 0x100000000,
    length,
    flags,
  ];
  var message = block;
  for (var round = 0; round < 7; round++) {
    for (var column = 0; column < 4; column++) {
      _mix(
        state,
        column,
        column + 4,
        column + 8,
        column + 12,
        message[column * 2],
        message[column * 2 + 1],
      );
    }
    for (var diagonal = 0; diagonal < 4; diagonal++) {
      _mix(
        state,
        diagonal,
        4 + (diagonal + 1) % 4,
        8 + (diagonal + 2) % 4,
        12 + (diagonal + 3) % 4,
        message[8 + diagonal * 2],
        message[9 + diagonal * 2],
      );
    }
    message = [for (var index in _permutation) message[index]];
  }
  return [
    for (var i = 0; i < 8; i++) state[i] ^ state[i + 8],
    for (var i = 0; i < 8; i++) state[i + 8] ^ cv[i],
  ];
}

void _mix(List<int> v, int a, int b, int c, int d, int x, int y) {
  v[a] = (v[a] + v[b] + x) & 0xffffffff;
  v[d] = _rotate(v[d] ^ v[a], 16);
  v[c] = (v[c] + v[d]) & 0xffffffff;
  v[b] = _rotate(v[b] ^ v[c], 12);
  v[a] = (v[a] + v[b] + y) & 0xffffffff;
  v[d] = _rotate(v[d] ^ v[a], 8);
  v[c] = (v[c] + v[d]) & 0xffffffff;
  v[b] = _rotate(v[b] ^ v[c], 7);
}

int _rotate(int value, int amount) =>
    ((value >>> amount) | (value << (32 - amount))) & 0xffffffff;

_Output _subtree(Uint8List bytes, int start, int end) {
  var length = end - start;
  if (length > 1024) {
    // The left child is the largest complete power-of-two subtree strictly
    // smaller than this tree. This also handles an incomplete rightmost chunk.
    var leftLength = 1024;
    while (leftLength * 2 < length) {
      leftLength *= 2;
    }
    var left = _subtree(bytes, start, start + leftLength).chainingValue();
    var right = _subtree(bytes, start + leftLength, end).chainingValue();
    return _Output(_iv, [...left, ...right], 0, 64, 4); // PARENT
  }
  var cv = _iv;
  var offset = start;
  while (true) {
    var count = end - offset < 64 ? end - offset : 64;
    var block = List<int>.filled(16, 0);
    for (var i = 0; i < count; i++) {
      block[i ~/ 4] |= bytes[offset + i] << (8 * (i % 4));
    }
    var last = offset + count == end;
    var flags = (offset == start ? 1 : 0) | (last ? 2 : 0);
    var output = _Output(cv, block, start ~/ 1024, count, flags);
    if (last) return output;
    cv = output.chainingValue();
    offset += count;
  }
}

class _Output {
  final List<int> cv;
  final List<int> block;
  final int counter;
  final int length;
  final int flags;

  new(this.cv, this.block, this.counter, this.length, this.flags);

  List<int> chainingValue() =>
      _compress(cv, block, counter, length, flags).sublist(0, 8);
}
