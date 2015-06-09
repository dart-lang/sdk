// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library base64;

import 'dart:typed_data';

const _decodeTable =
    const [null, null, null, null, null, null, null, null,
           null, null, null, null, null, null, null, null,
           null, null, null, null, null, null, null, null,
           null, null, null, null, null, null, null, null,
           null, null, null, null, null, null, null, null,
           null, null, null, 62, null, null, null, 63,
           52, 53, 54, 55, 56, 57, 58, 59,
           60, 61, null, null, null, 0, null, null,
           null, 0, 1, 2, 3, 4, 5, 6,
           7, 8, 9, 10, 11, 12, 13, 14,
           15, 16, 17, 18, 19, 20, 21, 22,
           23, 24, 25, null, null, null, null, null,
           null, 26, 27, 28, 29, 30, 31, 32,
           33, 34, 35, 36, 37, 38, 39, 40,
           41, 42, 43, 44, 45, 46, 47, 48,
           49, 50, 51];

Uint8List decodeBase64(String s) {
  if (s.length % 4 != 0) throw "Malformed Base64: $s";

  var odd_bits = 0;
  if (s[s.length - 1] == '=') {
    if (s[s.length - 2] == '=') {
      odd_bits = 2;
    } else {
      odd_bits = 1;
    }
  }

  var decodedByteLength = s.length ~/ 4 * 3 - odd_bits;
  var result = new Uint8List(decodedByteLength);
  var limit = s.length;
  if (odd_bits != 0) {
    limit = limit - 4;
  }

  var i = 0, j = 0;
  while (i < limit) {
    var triple = _decodeTable[s.codeUnitAt(i++)];
    triple = (triple << 6) | _decodeTable[s.codeUnitAt(i++)];
    triple = (triple << 6) | _decodeTable[s.codeUnitAt(i++)];
    triple = (triple << 6) | _decodeTable[s.codeUnitAt(i++)];
    result[j++] = triple >> 16;
    result[j++] = (triple >> 8) & 255;
    result[j++] = triple & 255;
  }

  if (odd_bits != 0) {
    var triple = _decodeTable[s.codeUnitAt(i++)];
    triple = (triple << 6) | _decodeTable[s.codeUnitAt(i++)];
    triple = (triple << 6) | _decodeTable[s.codeUnitAt(i++)];
    triple = (triple << 6) | _decodeTable[s.codeUnitAt(i++)];
    result[j++] = triple >> 16;
    if (odd_bits == 1) {
      result[j++] = (triple >> 8) & 255;
    }
  }
  assert(j == decodedByteLength);
  return result;
}
