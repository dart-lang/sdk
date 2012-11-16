// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unicode.h"

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/object.h"

namespace dart {

static const int8_t kTrailBytes[256] = {
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


static bool IsLatin1SequenceStart(uint8_t code_unit) {
  // Check is codepoint is <= U+00FF
  return (code_unit <= Utf8::kMaxOneByteChar);
}


static bool IsSmpSequenceStart(uint8_t code_unit) {
  // Check is codepoint is >= U+10000.
  return (code_unit >= 0xF0);
}


// Returns true if the code point is a high- or low-surrogate.
static bool IsSurrogate(uint32_t code_point) {
  return (code_point & 0xfffff800) == 0xd800;
}


// Returns true if the code point value is above Plane 17.
static bool IsOutOfRange(uint32_t code_point) {
  return (code_point > 0x10FFFF);
}


// Returns true if the byte sequence is ill-formed.
static bool IsNonShortestForm(uint32_t code_point, size_t num_bytes) {
  return code_point < kOverlongMinimum[num_bytes];
}


void Utf8::ConvertUTF32ToUTF16(int32_t codepoint, uint16_t* dst) {
  ASSERT(codepoint > kMaxBmpCodepoint);
  ASSERT(dst != NULL);
  dst[0] = (Utf8::kLeadOffset + (codepoint >> 10));
  dst[1] = (0xDC00 + (codepoint & 0x3FF));
}


// Returns a count of the number of UTF-8 trail bytes.
intptr_t Utf8::CodePointCount(const uint8_t* utf8_array,
                              intptr_t array_len,
                              Type* type) {
  intptr_t len = 0;
  Type char_type = kLatin1;
  for (intptr_t i = 0; i < array_len; i++) {
    uint8_t code_unit = utf8_array[i];
    if (!IsTrailByte(code_unit)) {
      ++len;
    }
    if (!IsLatin1SequenceStart(code_unit)) {  // > U+00FF
      if (IsSmpSequenceStart(code_unit)) {  // >= U+10000
        char_type = kSMP;
        ++len;
      } else if (char_type == kLatin1) {
        char_type = kBMP;
      }
    }
  }
  *type = char_type;
  return len;
}


// Returns true if str is a valid NUL-terminated UTF-8 string.
bool Utf8::IsValid(const uint8_t* utf8_array, intptr_t array_len) {
  intptr_t i = 0;
  while (i < array_len) {
    uint32_t ch = utf8_array[i] & 0xFF;
    intptr_t j = 1;
    if (ch >= 0x80) {
      int8_t num_trail_bytes = kTrailBytes[ch];
      bool is_malformed = false;
      for (; j < num_trail_bytes; ++j) {
        if ((i + j) < array_len) {
          uint8_t code_unit = utf8_array[i + j];
          is_malformed |= !IsTrailByte(code_unit);
          ch = (ch << 6) + code_unit;
        } else {
          return false;
        }
      }
      ch -= kMagicBits[num_trail_bytes];
      if (!((is_malformed == false) &&
            (j == num_trail_bytes) &&
            !IsOutOfRange(ch) &&
            !IsNonShortestForm(ch, j) &&
            !IsSurrogate(ch))) {
        return false;
      }
    }
    i += j;
  }
  return true;
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


intptr_t Utf8::Decode(const uint8_t* utf8_array,
                      intptr_t array_len,
                      int32_t* dst) {
  uint32_t ch = utf8_array[0] & 0xFF;
  intptr_t i = 1;
  if (ch >= 0x80) {
    int32_t num_trail_bytes = kTrailBytes[ch];
    bool is_malformed = false;
    for (; i < num_trail_bytes; ++i) {
      if (i < array_len) {
        uint8_t code_unit = utf8_array[i];
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


bool Utf8::DecodeToLatin1(const uint8_t* utf8_array,
                          intptr_t array_len,
                          uint8_t* dst,
                          intptr_t len) {
  intptr_t i = 0;
  intptr_t j = 0;
  intptr_t num_bytes;
  for (; (i < array_len) && (j < len); i += num_bytes, ++j) {
    int32_t ch;
    ASSERT(IsLatin1SequenceStart(utf8_array[i]));
    num_bytes = Utf8::Decode(&utf8_array[i], (array_len - i), &ch);
    if (ch == -1) {
      return false;  // invalid input
    }
    ASSERT(ch <= 0xff);
    dst[j] = ch;
  }
  if ((i < array_len) && (j == len)) {
    return false;  // output overflow
  }
  return true;  // success
}


bool Utf8::DecodeToUTF16(const uint8_t* utf8_array,
                         intptr_t array_len,
                         uint16_t* dst,
                         intptr_t len) {
  intptr_t i = 0;
  intptr_t j = 0;
  intptr_t num_bytes;
  for (; (i < array_len) && (j < len); i += num_bytes, ++j) {
    int32_t ch;
    bool is_smp = IsSmpSequenceStart(utf8_array[i]);
    num_bytes = Utf8::Decode(&utf8_array[i], (array_len - i), &ch);
    if (ch == -1) {
      return false;  // invalid input
    }
    if (is_smp) {
      ConvertUTF32ToUTF16(ch, &(dst[j]));
      j = j + 1;
    } else {
      dst[j] = ch;
    }
  }
  if ((i < array_len) && (j == len)) {
    return false;  // output overflow
  }
  return true;  // success
}


bool Utf8::DecodeToUTF32(const uint8_t* utf8_array,
                         intptr_t array_len,
                         uint32_t* dst,
                         intptr_t len) {
  intptr_t i = 0;
  intptr_t j = 0;
  intptr_t num_bytes;
  for (; (i < array_len) && (j < len); i += num_bytes, ++j) {
    int32_t ch;
    num_bytes = Utf8::Decode(&utf8_array[i], (array_len - i), &ch);
    if (ch == -1) {
      return false;  // invalid input
    }
    dst[j] = ch;
  }
  if ((i < array_len) && (j == len)) {
    return false;  // output overflow
  }
  return true;  // success
}

}  // namespace dart
