// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unicode.h"

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/object.h"

namespace dart {

static const uint8_t kTrailBytes[256] = {
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 0, 0
};


static const uint32_t kMagicBits[7] = {
  0,  // padding
  0x00000000,
  0x00003080,
  0x000E2080,
  0x03C82080,
  0xFA082080,
  0x82082080
};


// Minimum values of code points used to check shortest form.
static const uint32_t kOverlongMinimum[7] = {
  0,  // padding
  0x0,
  0x80,
  0x800,
  0x10000,
  0xFFFFFFFF,
  0xFFFFFFFF
};


static bool IsTrailByte(uint8_t code_unit) {
  return (code_unit & 0xc0) == 0x80;
}


// Returns true if the code point is a high- or low-surrogate.
static bool IsSurrogate(uint32_t code_point) {
  return (code_point & 0xfffff800) == 0xd800;
}


// Returns true if the code point value is above Plane 17.
static bool IsOutOfRange(uint32_t code_point) {
  return code_point > 0x10FFFF;
}


// Returns true if the byte sequence is ill-formed.
static bool IsNonShortestForm(uint32_t code_point, size_t num_bytes) {
  return code_point < kOverlongMinimum[num_bytes];
}


intptr_t Utf8::CodePointCount(const char* str, intptr_t* width) {
  bool is_two_byte_string = false;
  bool is_four_byte_string = false;
  intptr_t len = 0;
  for (; *str != '\0'; ++str) {
    uint8_t code_unit = *str;
    if (!IsTrailByte(code_unit)) {
      ++len;
    }
    if (code_unit > 0xC3) {  // > U+00FF
      if (code_unit < 0xF0) {  // < U+10000
        is_two_byte_string = true;
      } else {
        is_four_byte_string = true;
      }
    }
  }
  if (is_four_byte_string) {
    *width = 4;
  } else if (is_two_byte_string) {
    *width = 2;
  } else {
    *width = 1;
  }
  return len;
}


intptr_t Utf8::Length(int32_t ch) {
  if (ch <= kMaxOneByteChar) {
    return 1;
  } else if (ch <= kMaxTwoByteChar) {
    return 2;
  } else if (ch <= kMaxThreeByteChar) {
    return 3;
  }
  ASSERT(ch <= kMaxFourByteChar);
  return 4;
}


intptr_t Utf8::Length(const String& str) {
  intptr_t length = 0;
  for (intptr_t i = 0; i < str.Length(); ++i) {
    int32_t ch = str.CharAt(i);
    length += Utf8::Length(ch);
  }
  return length;
}


intptr_t Utf8::Encode(int32_t ch, char* dst) {
  static const int kMask = ~(1 << 6);
  if (ch <= kMaxOneByteChar) {
    dst[0] = ch;
    return 1;
  }
  if (ch <= kMaxTwoByteChar) {
    dst[0] = 0xC0 | (ch >> 6);
    dst[1] = 0x80 | (ch & kMask);
    return 2;
  }
  if (ch <= kMaxThreeByteChar) {
    dst[0] = 0xE0 | (ch >> 12);
    dst[1] = 0x80 | ((ch >> 6) & kMask);
    dst[2] = 0x80 | (ch & kMask);
    return 3;
  }
  ASSERT(ch <= kMaxFourByteChar);
  dst[0] = 0xF0 | (ch >> 18);
  dst[1] = 0x80 | ((ch >> 12) & kMask);
  dst[2] = 0x80 | ((ch >> 6) & kMask);
  dst[3] = 0x80 | (ch & kMask);
  return 4;
}


intptr_t Utf8::Encode(const String& src, char* dst, intptr_t len) {
  intptr_t pos = 0;
  for (intptr_t i = 0; i < src.Length(); ++i) {
    intptr_t ch = src.CharAt(i);
    intptr_t num_bytes = Utf8::Length(ch);
    if (pos + num_bytes > len) {
      break;
    }
    Utf8::Encode(ch, &dst[pos]);
    pos += num_bytes;
  }
  return pos;
}


intptr_t Utf8::Decode(const char* src, int32_t* dst) {
  uint32_t ch = src[0] & 0xFF;
  uint32_t i = 1;
  if (ch >= 0x80) {
    uint32_t num_trail_bytes = kTrailBytes[ch];
    bool is_malformed = false;
    for (; i < num_trail_bytes; ++i) {
      if (src[i] != '\0') {
        uint8_t code_unit = src[i];
        is_malformed |= !IsTrailByte(code_unit);
        ch = (ch << 6) + code_unit;
      } else {
        *dst = -1;
        return 0;
      }
    }
    ch -= kMagicBits[num_trail_bytes];
    if (!((is_malformed == false) &&
          (i == num_trail_bytes) &&
          !IsOutOfRange(ch) &&
          !IsNonShortestForm(ch, i) &&
          !IsSurrogate(ch))) {
      *dst = -1;
      return 0;
    }
  }
  *dst = ch;
  return i;
}


template<typename T>
static bool DecodeImpl(const char* src, T* dst, intptr_t len) {
  intptr_t i = 0;
  intptr_t j = 0;
  intptr_t num_bytes;
  for (; src[i] != '\0' && j < len; i += num_bytes, ++j) {
    int32_t ch;
    num_bytes = Utf8::Decode(&src[i], &ch);
    if (ch == -1) {
      return false;  // invalid input
    }
    dst[j] = ch;
  }
  if (src[i] != '\0' && j == len) {
    return false;  // output overflow
  }
  return true;  // success
}


bool Utf8::Decode(const char* src, uint8_t* dst, intptr_t len) {
  return DecodeImpl(src, dst, len);
}


bool Utf8::Decode(const char* src, uint16_t* dst, intptr_t len) {
  return DecodeImpl(src, dst, len);
}


bool Utf8::Decode(const char* src, uint32_t* dst, intptr_t len) {
  return DecodeImpl(src, dst, len);
}

}  // namespace dart
