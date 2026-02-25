// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/unicode.h"

#include <cstring>

#include "platform/allocation.h"
#include "platform/globals.h"
#include "platform/syslog.h"

namespace dart {

namespace {
#if defined(ARCH_IS_64_BIT)
static constexpr uintptr_t kAsciiWordMask = DART_UINT64_C(0x8080808080808080);
#else
static constexpr uintptr_t kAsciiWordMask = 0x80808080u;
#endif

inline intptr_t AsciiRunLength(const uint8_t* data, intptr_t len) {
  intptr_t i = 0;
  const intptr_t word_size = sizeof(uintptr_t);
  while (i + word_size <= len) {
    const uintptr_t chunk = LoadUnaligned(
        reinterpret_cast<const uintptr_t*>(data + i));
    if ((chunk & kAsciiWordMask) != 0) {
      break;
    }
    i += word_size;
  }
  while (i < len && data[i] < 0x80) {
    i++;
  }
  return i;
}
}  // namespace

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

intptr_t Utf8::Encode(int32_t ch, char* dst) {
  constexpr int kMask = ~(1 << 6);
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
intptr_t Utf8::ReportInvalidByte(const uint8_t* utf8_array,
                                 intptr_t array_len,
                                 intptr_t len) {
  intptr_t i = 0;
  intptr_t j = 0;
  intptr_t num_bytes;
  for (; (i < array_len) && (j < len); i += num_bytes, ++j) {
    int32_t ch;
    bool is_supplementary = IsSupplementarySequenceStart(utf8_array[i]);
    num_bytes = Utf8::Decode(&utf8_array[i], (array_len - i), &ch);
    if (ch == -1) {
      break;  // Invalid input.
    }
    if (is_supplementary) {
      j = j + 1;
    }
  }
#ifdef FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION
  // Remain silent while libFuzzer is active, since
  // the output only slows down the in-process fuzzing.
#else
  Syslog::PrintErr("Invalid UTF8 sequence encountered, ");
  for (intptr_t idx = 0; idx < 10 && (i + idx) < array_len; idx++) {
    Syslog::PrintErr("(Error Code: %X + idx: %" Pd " )", utf8_array[idx + i],
                     (idx + i));
  }
  Syslog::PrintErr("\n");
#endif
  return i;
}

bool Utf8::DecodeToLatin1(const uint8_t* utf8_array,
                          intptr_t array_len,
                          uint8_t* dst,
                          intptr_t len) {
  intptr_t i = 0;
  intptr_t j = 0;
  while ((i < array_len) && (j < len)) {
    const uint8_t byte = utf8_array[i];
    if (byte < 0x80) {
      const intptr_t run_len = AsciiRunLength(utf8_array + i, array_len - i);
      if (j + run_len > len) {
        return false;  // Output overflow.
      }
      memcpy(dst + j, utf8_array + i, run_len);
      i += run_len;
      j += run_len;
      continue;
    }
    if (!IsLatin1SequenceStart(byte)) {
      return false;  // Invalid input.
    }
    if (byte < 0xC2) {
      return false;  // Invalid or overlong sequence.
    }
    if (i + 1 >= array_len) {
      return false;  // Incomplete sequence.
    }
    const uint8_t b1 = utf8_array[i + 1];
    if (!IsTrailByte(b1)) {
      return false;  // Invalid input.
    }
    dst[j++] = ((byte & 0x1F) << 6) | (b1 & 0x3F);
    i += 2;
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
  while ((i < array_len) && (j < len)) {
    const uint8_t byte = utf8_array[i];
    if (byte < 0x80) {
      const intptr_t run_len = AsciiRunLength(utf8_array + i, array_len - i);
      if (j + run_len > len) {
        return false;  // Output overflow.
      }
      for (intptr_t k = 0; k < run_len; k++) {
        dst[j + k] = utf8_array[i + k];
      }
      i += run_len;
      j += run_len;
      continue;
    }
    if (byte < 0xC2) {
      return false;  // Invalid or overlong sequence.
    }
    if (byte < 0xE0) {
      if (i + 1 >= array_len) return false;  // Incomplete sequence.
      intptr_t remaining = len - j;
      while (remaining > 0 && i + 1 < array_len) {
        const uint8_t b0 = utf8_array[i];
        if (b0 < 0xC2 || b0 >= 0xE0) {
          break;
        }
        const uint8_t b1 = utf8_array[i + 1];
        if (!IsTrailByte(b1)) return false;
        dst[j++] = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
        i += 2;
        remaining--;
      }
      continue;
    }
    if (byte < 0xF0) {
      if (i + 2 >= array_len) return false;  // Incomplete sequence.
      intptr_t remaining = len - j;
      while (remaining > 0 && i + 2 < array_len) {
        const uint8_t b0 = utf8_array[i];
        if (b0 < 0xE0 || b0 >= 0xF0) {
          break;
        }
        const uint8_t b1 = utf8_array[i + 1];
        const uint8_t b2 = utf8_array[i + 2];
        if (!IsTrailByte(b1) || !IsTrailByte(b2)) return false;
        if ((b0 == 0xE0) && (b1 < 0xA0)) return false;  // Overlong.
        if ((b0 == 0xED) && (b1 >= 0xA0)) return false;  // Surrogate.
        dst[j++] = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
        i += 3;
        remaining--;
      }
      continue;
    }
    if (byte < 0xF5) {
      if (i + 3 >= array_len) return false;  // Incomplete sequence.
      const uint8_t b1 = utf8_array[i + 1];
      const uint8_t b2 = utf8_array[i + 2];
      const uint8_t b3 = utf8_array[i + 3];
      if (!IsTrailByte(b1) || !IsTrailByte(b2) || !IsTrailByte(b3)) {
        return false;
      }
      if ((byte == 0xF0) && (b1 < 0x90)) return false;  // Overlong.
      if ((byte == 0xF4) && (b1 >= 0x90)) return false;  // Out of range.
      if (j >= (len - 1)) return false;  // Output overflow.
      uint32_t ch = ((byte & 0x07) << 18) | ((b1 & 0x3F) << 12) |
                    ((b2 & 0x3F) << 6) | (b3 & 0x3F);
      ch -= 0x10000;
      dst[j++] = 0xD800 + (ch >> 10);
      dst[j++] = 0xDC00 + (ch & 0x3FF);
      i += 4;
      continue;
    }
    return false;  // Invalid input.
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
  ASSERT(str != nullptr);
  intptr_t array_len = strlen(str);
  const uint8_t* utf8_array = reinterpret_cast<const uint8_t*>(str);
  return Utf8::DecodeToUTF32(utf8_array, array_len, dst, len);
}

void Utf16::Encode(int32_t codepoint, uint16_t* dst) {
  ASSERT(codepoint > Utf16::kMaxCodeUnit);
  ASSERT(dst != nullptr);
  dst[0] = (Utf16::kLeadSurrogateOffset + (codepoint >> 10));
  dst[1] = (0xDC00 + (codepoint & 0x3FF));
}

}  // namespace dart
