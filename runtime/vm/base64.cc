// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/base64.h"

#include "platform/allocation.h"
#include "vm/os.h"

namespace dart {

// Taken from lib/_http/crypto.dart

// Lookup table used for finding Base 64 alphabet index of a given byte.
// -2 : Outside Base 64 alphabet.
// -1 : '\r' or '\n'
//  0 : = (Padding character).
// >0 : Base 64 alphabet index of given byte.
static const int8_t decode_table[] = {
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -2, -2, -1, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, 62, -2, 63,  //
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, 00, -2, -2,  //
    -2, 00, 01, 02, 03, 04, 05, 06, 07, 8,  9,  10, 11, 12, 13, 14,  //
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, 63,  //
    -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,  //
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2};

static const char PAD = '=';

uint8_t* DecodeBase64(const char* str, intptr_t* out_decoded_len) {
  intptr_t len = strlen(str);
  if (len == 0 || (len % 4 != 0)) {
    return nullptr;
  }

  int pad_length = 0;
  for (intptr_t i = len - 1; i >= 0; i--) {
    const uint8_t current_code_unit = str[i];
    if (decode_table[current_code_unit] > 0) break;
    if (current_code_unit == PAD) pad_length++;
  }
  intptr_t decoded_en = ((len * 6) >> 3) - pad_length;
  uint8_t* bytes = static_cast<uint8_t*>(malloc(decoded_en));

  for (int i = 0, o = 0; o < decoded_en;) {
    // Accumulate 4 valid 6 bit Base 64 characters into an int.
    int x = 0;
    for (int j = 4; j > 0;) {
      int c = decode_table[(uint8_t)str[i++]];
      if (c >= 0) {
        x = ((x << 6) & 0xFFFFFF) | c;
        j--;
      }
    }
    bytes[o++] = x >> 16;
    if (o < decoded_en) {
      bytes[o++] = (x >> 8) & 0xFF;
      if (o < decoded_en) bytes[o++] = x & 0xFF;
    }
  }
  if (out_decoded_len != nullptr) {
    *out_decoded_len = decoded_en;
  }
  return bytes;
}

}  // namespace dart
