// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UNICODE_H_
#define RUNTIME_PLATFORM_UNICODE_H_

#include "platform/allocation.h"
#include "platform/globals.h"
#include "platform/unaligned.h"

namespace dart {

class String;

class Utf : AllStatic {
 public:
  static const int32_t kMaxCodePoint = 0x10FFFF;
  static const int32_t kInvalidChar = 0xFFFFFFFF;

  static const int32_t kReplacementChar = 0xFFFD;

  static bool IsLatin1(int32_t code_point) {
    return (code_point >= 0) && (code_point <= 0xFF);
  }

  static bool IsBmp(int32_t code_point) {
    return (code_point >= 0) && (code_point <= 0xFFFF);
  }

  static bool IsSupplementary(int32_t code_point) {
    return (code_point > 0xFFFF) && (code_point <= kMaxCodePoint);
  }

  // Returns true if the code point value is above Plane 17.
  static bool IsOutOfRange(int32_t code_point) {
    return (code_point < 0) || (code_point > kMaxCodePoint);
  }
};

class Utf8 : AllStatic {
 public:
  enum Type {
    kLatin1 = 0,     // Latin-1 code point [U+0000, U+00FF].
    kBMP,            // Basic Multilingual Plane code point [U+0000, U+FFFF].
    kSupplementary,  // Supplementary code point [U+010000, U+10FFFF].
  };

  // Returns the most restricted coding form in which the sequence of utf8
  // characters in 'utf8_array' can be represented in, and the number of
  // code units needed in that form.
  static intptr_t CodeUnitCount(const uint8_t* utf8_array,
                                intptr_t array_len,
                                Type* type);

  // Returns true if 'utf8_array' is a valid UTF-8 string.
  static bool IsValid(const uint8_t* utf8_array, intptr_t array_len);

  static intptr_t Length(int32_t ch);
  static intptr_t Length(const String& str);

  static intptr_t Encode(int32_t ch, char* dst);
  static intptr_t Encode(const String& src, char* dst, intptr_t len);

  static intptr_t Decode(const uint8_t* utf8_array,
                         intptr_t array_len,
                         int32_t* ch);

  static bool DecodeToLatin1(const uint8_t* utf8_array,
                             intptr_t array_len,
                             uint8_t* dst,
                             intptr_t len);
  static bool DecodeToUTF16(const uint8_t* utf8_array,
                            intptr_t array_len,
                            uint16_t* dst,
                            intptr_t len);
  static bool DecodeToUTF32(const uint8_t* utf8_array,
                            intptr_t array_len,
                            int32_t* dst,
                            intptr_t len);
  static intptr_t ReportInvalidByte(const uint8_t* utf8_array,
                                    intptr_t array_len,
                                    intptr_t len);
  static bool DecodeCStringToUTF32(const char* str, int32_t* dst, intptr_t len);

  static const int32_t kMaxOneByteChar = 0x7F;
  static const int32_t kMaxTwoByteChar = 0x7FF;
  static const int32_t kMaxThreeByteChar = 0xFFFF;
  static const int32_t kMaxFourByteChar = Utf::kMaxCodePoint;

 private:
  static bool IsTrailByte(uint8_t code_unit) {
    return (code_unit & 0xC0) == 0x80;
  }

  static bool IsNonShortestForm(uint32_t code_point, size_t num_code_units) {
    return code_point < kOverlongMinimum[num_code_units];
  }

  static bool IsLatin1SequenceStart(uint8_t code_unit) {
    // Check if utf8 sequence is the start of a codepoint <= U+00FF
    return (code_unit <= 0xC3);
  }

  static bool IsSupplementarySequenceStart(uint8_t code_unit) {
    // Check if utf8 sequence is the start of a codepoint >= U+10000.
    return (code_unit >= 0xF0);
  }

  static const int8_t kTrailBytes[];
  static const uint32_t kMagicBits[];
  static const uint32_t kOverlongMinimum[];
};

class Utf16 : AllStatic {
 public:
  // Returns the length of the code point in UTF-16 code units.
  static intptr_t Length(int32_t ch) {
    return (ch <= Utf16::kMaxCodeUnit) ? 1 : 2;
  }

  // Returns true if ch is a lead or trail surrogate.
  static bool IsSurrogate(uint32_t ch) { return (ch & 0xFFFFF800) == 0xD800; }

  // Returns true if ch is a lead surrogate.
  static bool IsLeadSurrogate(uint32_t ch) {
    return (ch & 0xFFFFFC00) == 0xD800;
  }

  // Returns true if ch is a low surrogate.
  static bool IsTrailSurrogate(uint32_t ch) {
    return (ch & 0xFFFFFC00) == 0xDC00;
  }

  // Returns the character at i and advances i to the next character
  // boundary.
  static int32_t Next(const uint16_t* characters, intptr_t* i, intptr_t len) {
    int32_t ch = LoadUnaligned(&characters[*i]);
    if (Utf16::IsLeadSurrogate(ch) && (*i < (len - 1))) {
      int32_t ch2 = LoadUnaligned(&characters[*i + 1]);
      if (Utf16::IsTrailSurrogate(ch2)) {
        ch = Utf16::Decode(ch, ch2);
        *i += 1;
      }
    }
    *i += 1;
    return ch;
  }

  // Decodes a surrogate pair into a supplementary code point.
  static int32_t Decode(uint16_t lead, uint16_t trail) {
    return 0x10000 + ((lead & 0x000003FF) << 10) + (trail & 0x3FF);
  }

  // Encodes a single code point.
  static void Encode(int32_t codepoint, uint16_t* dst);

  static const int32_t kMaxCodeUnit = 0xFFFF;
  static const int32_t kLeadSurrogateStart = 0xD800;
  static const int32_t kLeadSurrogateEnd = 0xDBFF;
  static const int32_t kTrailSurrogateStart = 0xDC00;
  static const int32_t kTrailSurrogateEnd = 0xDFFF;

 private:
  static const int32_t kLeadSurrogateOffset = (0xD800 - (0x10000 >> 10));

  static const int32_t kSurrogateOffset = (0x10000 - (0xD800 << 10) - 0xDC00);
};

class CaseMapping : AllStatic {
 public:
  // Maps a code point to uppercase.
  static int32_t ToUpper(int32_t code_point) {
    return Convert(code_point, kUppercase);
  }

  // Maps a code point to lowercase.
  static int32_t ToLower(int32_t code_point) {
    return Convert(code_point, kLowercase);
  }

 private:
  // Property is a delta to the uppercase mapping.
  static const int32_t kUppercase = 1;

  // Property is a delta to the uppercase mapping.
  static const int32_t kLowercase = 2;

  // Property is an index into the exception table.
  static const int32_t kException = 3;

  // Type bit-field parameters
  static const int32_t kTypeShift = 2;
  static const int32_t kTypeMask = 3;

  // The size of the stage 1 index.
  // TODO(cshapiro): improve indexing so this value is unnecessary.
  static const intptr_t kStage1Size = 261;

  // The size of a stage 2 block in bytes.
  static const intptr_t kBlockSizeLog2 = 8;
  static const intptr_t kBlockSize = 1 << kBlockSizeLog2;

  static int32_t Convert(int32_t ch, int32_t mapping) {
    if (Utf::IsLatin1(ch)) {
      int32_t info = stage2_[ch];
      if ((info & kTypeMask) == mapping) {
        ch += info >> kTypeShift;
      }
    } else if (ch <= (kStage1Size << kBlockSizeLog2)) {
      int16_t offset = stage1_[ch >> kBlockSizeLog2] << kBlockSizeLog2;
      int32_t info = stage2_[offset + (ch & (kBlockSize - 1))];
      int32_t type = info & kTypeMask;
      if (type == mapping) {
        ch += (info >> kTypeShift);
      } else if (type == kException) {
        ch += stage2_exception_[info >> kTypeShift][mapping - 1];
      }
    }
    return ch;
  }

  // Index into the data array.
  static const uint8_t stage1_[];

  // Data for small code points with one mapping
  static const int16_t stage2_[];

  // Data for large code points or code points with both mappings.
  static const int32_t stage2_exception_[][2];
};

class Latin1 {
 public:
  static const int32_t kMaxChar = 0xff;
  // Convert the character to Latin-1 case equivalent if possible.
  static inline uint16_t TryConvertToLatin1(uint16_t c) {
    switch (c) {
      // This are equivalent characters in unicode.
      case 0x39c:
      case 0x3bc:
        return 0xb5;
      // This is an uppercase of a Latin-1 character
      // outside of Latin-1.
      case 0x178:
        return 0xff;
    }
    return c;
  }
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_UNICODE_H_
