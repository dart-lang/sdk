// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

const int _prime1 = 0x9E3779B185EBCA87;
const int _prime2 = 0xC2B2AE3D27D4EB4F;
const int _prime3 = 0x165667B19E3779F9;
const int _prime4 = 0x85EBCA77C2B2AE63;
const int _prime5 = 0x27D4EB2F165667C5;

/// Computes XXH64 with seed zero, returning its bits as a signed 64-bit integer.
///
/// Follows https://github.com/Cyan4973/xxHash/blob/v0.8.3/doc/xxhash_spec.md.
/// Arithmetic relies on the Dart VM's wrapping 64-bit integers. Words are read
/// in little-endian order, independently of the host byte order and alignment.
int xxh64(Uint8List bytes) {
  var wordCount = bytes.length >> 3;
  Uint64List words;
  if (Endian.host == Endian.little && bytes.offsetInBytes % 8 == 0) {
    words = Uint64List.view(bytes.buffer, bytes.offsetInBytes, wordCount);
  } else {
    // Normalize unaligned views or big-endian words. Ordinary page buffers and
    // values use the direct view above without copying their contents.
    words = Uint64List(wordCount);
    var data = ByteData.sublistView(bytes);
    for (var i = 0; i < wordCount; i++) {
      words[i] = data.getUint64(i * 8, Endian.little);
    }
  }

  var i = 0;
  int hash;
  if (wordCount >= 4) {
    var v1 = _prime1 + _prime2;
    var v2 = _prime2;
    var v3 = 0;
    var v4 = -_prime1;
    for (; i + 4 <= wordCount; i += 4) {
      v1 = _round(v1, words[i]);
      v2 = _round(v2, words[i + 1]);
      v3 = _round(v3, words[i + 2]);
      v4 = _round(v4, words[i + 3]);
    }
    hash =
        _rotateLeft(v1, 1) +
        _rotateLeft(v2, 7) +
        _rotateLeft(v3, 12) +
        _rotateLeft(v4, 18);
    hash = _mergeRound(hash, v1);
    hash = _mergeRound(hash, v2);
    hash = _mergeRound(hash, v3);
    hash = _mergeRound(hash, v4);
  } else {
    hash = _prime5;
  }
  hash += bytes.length;

  for (; i < wordCount; i++) {
    hash ^= _round(0, words[i]);
    hash = _rotateLeft(hash, 27) * _prime1 + _prime4;
  }
  var offset = wordCount << 3;
  if (offset + 4 <= bytes.length) {
    var word =
        bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
    hash ^= word * _prime1;
    hash = _rotateLeft(hash, 23) * _prime2 + _prime3;
    offset += 4;
  }
  for (; offset < bytes.length; offset++) {
    hash ^= bytes[offset] * _prime5;
    hash = _rotateLeft(hash, 11) * _prime1;
  }

  hash ^= hash >>> 33;
  hash *= _prime2;
  hash ^= hash >>> 29;
  hash *= _prime3;
  return hash ^ (hash >>> 32);
}

@pragma('vm:prefer-inline')
int _mergeRound(int hash, int value) =>
    (hash ^ _round(0, value)) * _prime1 + _prime4;

@pragma('vm:prefer-inline')
int _rotateLeft(int value, int count) =>
    (value << count) | (value >>> (64 - count));

@pragma('vm:prefer-inline')
int _round(int accumulator, int word) =>
    _rotateLeft(accumulator + word * _prime2, 31) * _prime1;
