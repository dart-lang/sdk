// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unicode.h"

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/object.h"

namespace dart {

// clang-format off
const int8_t Utf8::kTrailBytes[256] = {
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
// clang-format on

const uint32_t Utf8::kMagicBits[7] = {0,  // Padding.
                                      0x00000000, 0x00003080, 0x000E2080,
                                      0x03C82080, 0xFA082080, 0x82082080};

// Minimum values of code points used to check shortest form.
const uint32_t Utf8::kOverlongMinimum[7] = {0,  // Padding.
                                            0x0,     0x80,       0x800,
                                            0x10000, 0xFFFFFFFF, 0xFFFFFFFF};

// Returns the most restricted coding form in which the sequence of utf8
// characters in 'utf8_array' can be represented in, and the number of
// code units needed in that form.
intptr_t Utf8::CodeUnitCount(const uint8_t* utf8_array,
                             intptr_t array_len,
                             Type* type) {
  intptr_t len = 0;
  Type char_type = kLatin1;
  for (intptr_t i = 0; i < array_len; i++) {
    uint8_t code_unit = utf8_array[i];
    if (!IsTrailByte(code_unit)) {
      ++len;
      if (!IsLatin1SequenceStart(code_unit)) {          // > U+00FF
        if (IsSupplementarySequenceStart(code_unit)) {  // >= U+10000
          char_type = kSupplementary;
          ++len;
        } else if (char_type == kLatin1) {
          char_type = kBMP;
        }
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
      if (!((is_malformed == false) && (j == num_trail_bytes) &&
            !Utf::IsOutOfRange(ch) && !IsNonShortestForm(ch, j))) {
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

// A constant mask that can be 'and'ed with a word of data to determine if it
// is all ASCII (with no Latin1 characters).
#if defined(ARCH_IS_64_BIT)
static const uintptr_t kAsciiWordMask = DART_UINT64_C(0x8080808080808080);
#else
static const uintptr_t kAsciiWordMask = 0x80808080u;
#endif

intptr_t Utf8::Length(const String& str) {
  if (str.IsOneByteString() || str.IsExternalOneByteString()) {
    // For 1-byte strings, all code points < 0x80 have single-byte UTF-8
    // encodings and all >= 0x80 have two-byte encodings.  To get the length,
    // start with the number of code points and add the number of high bits in
    // the bytes.
    uintptr_t char_length = str.Length();
    uintptr_t length = char_length;
    const uintptr_t* data;
    NoSafepointScope no_safepoint;
    if (str.IsOneByteString()) {
      data = reinterpret_cast<const uintptr_t*>(OneByteString::DataStart(str));
    } else {
      data = reinterpret_cast<const uintptr_t*>(
          ExternalOneByteString::DataStart(str));
    }
    uintptr_t i;
    for (i = sizeof(uintptr_t); i <= char_length; i += sizeof(uintptr_t)) {
      uintptr_t chunk = *data++;
      chunk &= kAsciiWordMask;
      if (chunk != 0) {
// Shuffle the bits until we have a count of bits in the low nibble.
#if defined(ARCH_IS_64_BIT)
        chunk += chunk >> 32;
#endif
        chunk += chunk >> 16;
        chunk += chunk >> 8;
        length += (chunk >> 7) & 0xf;
      }
    }
    // Take care of the tail of the string, the last length % wordsize chars.
    i -= sizeof(uintptr_t);
    for (; i < char_length; i++) {
      if (str.CharAt(i) > kMaxOneByteChar) length++;
    }
    return length;
  }

  // Slow case for 2-byte strings that handles surrogate pairs and longer UTF-8
  // encodings.
  intptr_t length = 0;
  String::CodePointIterator it(str);
  while (it.Next()) {
    int32_t ch = it.Current();
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
  uintptr_t array_len = len;
  intptr_t pos = 0;
  ASSERT(static_cast<intptr_t>(array_len) >= Length(src));
  if (src.IsOneByteString() || src.IsExternalOneByteString()) {
    // For 1-byte strings, all code points < 0x80 have single-byte UTF-8
    // encodings and all >= 0x80 have two-byte encodings.
    const uintptr_t* data;
    NoSafepointScope scope;
    if (src.IsOneByteString()) {
      data = reinterpret_cast<const uintptr_t*>(OneByteString::DataStart(src));
    } else {
      data = reinterpret_cast<const uintptr_t*>(
          ExternalOneByteString::DataStart(src));
    }
    uintptr_t char_length = src.Length();
    uintptr_t pos = 0;
    ASSERT(kMaxOneByteChar + 1 == 0x80);
    for (uintptr_t i = 0; i < char_length; i += sizeof(uintptr_t)) {
      // Read the input one word at a time and just write it verbatim if it is
      // plain ASCII, as determined by the mask.
      if (i + sizeof(uintptr_t) <= char_length &&
          (*data & kAsciiWordMask) == 0 &&
          pos + sizeof(uintptr_t) <= array_len) {
        StoreUnaligned(reinterpret_cast<uintptr_t*>(dst + pos), *data);
        pos += sizeof(uintptr_t);
      } else {
        // Process up to one word of input that contains non-ASCII Latin1
        // characters.
        const uint8_t* p = reinterpret_cast<const uint8_t*>(data);
        const uint8_t* limit =
            Utils::Minimum(p + sizeof(uintptr_t), p + (char_length - i));
        for (; p < limit; p++) {
          uint8_t c = *p;
          // These calls to Length and Encode get inlined and the cases for 3
          // and 4 byte sequences are removed.
          intptr_t bytes = Length(c);
          if (pos + bytes > array_len) {
            return pos;
          }
          Encode(c, reinterpret_cast<char*>(dst) + pos);
          pos += bytes;
        }
      }
      data++;
    }
  } else {
    // For two-byte strings, which can contain 3 and 4-byte UTF-8 encodings,
    // which can result in surrogate pairs, use the more general code.
    String::CodePointIterator it(src);
    while (it.Next()) {
      int32_t ch = it.Current();
      intptr_t num_bytes = Utf8::Length(ch);
      if (pos + num_bytes > len) {
        break;
      }
      Utf8::Encode(ch, &dst[pos]);
      pos += num_bytes;
    }
  }
  return pos;
}

intptr_t Utf8::Decode(const uint8_t* utf8_array,
                      intptr_t array_len,
                      int32_t* dst) {
  uint32_t ch = utf8_array[0] & 0xFF;
  intptr_t i = 1;
  if (ch >= 0x80) {
    intptr_t num_trail_bytes = kTrailBytes[ch];
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
    if (!((is_malformed == false) && (i == num_trail_bytes) &&
          !Utf::IsOutOfRange(ch) && !IsNonShortestForm(ch, i))) {
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
      return false;  // Invalid input.
    }
    ASSERT(Utf::IsLatin1(ch));
    dst[j] = ch;
  }
  if ((i < array_len) && (j == len)) {
    return false;  // Output overflow.
  }
  return true;  // Success.
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
    bool is_supplementary = IsSupplementarySequenceStart(utf8_array[i]);
    num_bytes = Utf8::Decode(&utf8_array[i], (array_len - i), &ch);
    if (ch == -1) {
      return false;  // Invalid input.
    }
    if (is_supplementary) {
      Utf16::Encode(ch, &dst[j]);
      j = j + 1;
    } else {
      dst[j] = ch;
    }
  }
  if ((i < array_len) && (j == len)) {
    return false;  // Output overflow.
  }
  return true;  // Success.
}

bool Utf8::DecodeToUTF32(const uint8_t* utf8_array,
                         intptr_t array_len,
                         int32_t* dst,
                         intptr_t len) {
  intptr_t i = 0;
  intptr_t j = 0;
  intptr_t num_bytes;
  for (; (i < array_len) && (j < len); i += num_bytes, ++j) {
    int32_t ch;
    num_bytes = Utf8::Decode(&utf8_array[i], (array_len - i), &ch);
    if (ch == -1) {
      return false;  // Invalid input.
    }
    dst[j] = ch;
  }
  if ((i < array_len) && (j == len)) {
    return false;  // Output overflow.
  }
  return true;  // Success.
}

bool Utf8::DecodeCStringToUTF32(const char* str, int32_t* dst, intptr_t len) {
  ASSERT(str != NULL);
  intptr_t array_len = strlen(str);
  const uint8_t* utf8_array = reinterpret_cast<const uint8_t*>(str);
  return Utf8::DecodeToUTF32(utf8_array, array_len, dst, len);
}

void Utf16::Encode(int32_t codepoint, uint16_t* dst) {
  ASSERT(codepoint > Utf16::kMaxCodeUnit);
  ASSERT(dst != NULL);
  dst[0] = (Utf16::kLeadSurrogateOffset + (codepoint >> 10));
  dst[1] = (0xDC00 + (codepoint & 0x3FF));
}

}  // namespace dart
