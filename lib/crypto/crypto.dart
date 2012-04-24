// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("crypto");

#source("sha1.dart");

// Helpers used implementing the different crypto algorithms.

final int _BITS_PER_BYTE = 8;
final int _BYTES_PER_WORD = 4;
final int _BITS_PER_WORD = _BITS_PER_BYTE * _BYTES_PER_WORD;
final int _MASK_32 = 0xffffffff;

int _roundUp(int val, int n) {
  return (val + n - 1) & -n;
}

// Rotate left limiting to unsigned 32-bit values.
int _rotl32(int val, int shift) {
  var mod_shift = shift & 31;
  return ((val << mod_shift) & _MASK_32) |
      ((val & _MASK_32) >> (32 - mod_shift));
}

// Add limiting to unsigned 32-bit values.
int _add32(int left, int right) {
  return (left + right) & _MASK_32;
}

void _bytesToWords(List<int> input,
                   int in_offset,
                   int in_len,
                   List<int> output,
                   int out_offset,
                   int out_len) {
  var cur = in_offset;
  var end = in_offset + in_len;
  var cur_out = out_offset;
  var unroll_loop_end = in_len ~/ _BYTES_PER_WORD;

  while (cur_out < unroll_loop_end) {
    var word = (input[cur++] & 0xff) << 24;
    word |= (input[cur++] & 0xff) << 16;
    word |= (input[cur++] & 0xff) << 8;
    word |= (input[cur++] & 0xff);
    output[cur_out++] = word;
  }
  // Fill the rest of the output with the remaining bytes or zeros if no more
  // data is available.
  while (cur_out < (out_offset + out_len)) {
    var word = 0;
    var bit_shift = (_BYTES_PER_WORD - 1) * _BITS_PER_BYTE;
    while (cur < end) {
      word |= (input[cur++] & 0xff) << bit_shift;
      bit_shift -= _BITS_PER_BYTE;
    }
    output[cur_out++] = word;
  }
}

List<int> _wordsToBytes(List<int> input) {
  var len = input.length;
  var output = new List<int>(len * _BYTES_PER_WORD);
  var cur = 0;
  for (var word in input) {
    output[cur++] = word >> 24;
    output[cur++] = (word >> 16) & 0xff;
    output[cur++] = (word >> 8) & 0xff;
    output[cur++] = word & 0xff;
  }
  return output;
}
