// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_UNICODE_H_
#define VM_UNICODE_H_

#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

class String;


class Utf8 : AllStatic {
 public:
  enum Type {
    kLatin1 = 0,  // Latin-1 code point [U+0000, U+00FF].
    kBMP,  // Basic Multilingual Plane code point [U+0000, U+FFFF].
    kSupplementary,  // Supplementary code point [U+010000, U+10FFFF].
  };

  static const intptr_t kMaxOneByteChar   = 0x7F;
  static const intptr_t kMaxTwoByteChar   = 0x7FF;
  static const intptr_t kMaxThreeByteChar = 0xFFFF;
  static const intptr_t kMaxFourByteChar  = 0x10FFFF;

  static const int32_t kInvalidCodePoint = -1;

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
  static bool DecodeCStringToUTF32(const char* str,
                                   int32_t* dst,
                                   intptr_t len) {
    ASSERT(str != NULL);
    intptr_t array_len = strlen(str);
    const uint8_t* utf8_array = reinterpret_cast<const uint8_t*>(str);
    return DecodeToUTF32(utf8_array, array_len, dst, len);
  }
};


class Utf16 : AllStatic {
 public:
  static const int32_t kMaxBmpCodepoint  = 0xFFFF;
  static const int32_t kMaxCodeUnit = 0xFFFF;
  static const int32_t kMaxCodePoint = 0x10FFFF;

  static const int32_t kSurrogateEncodingBase = 0x10000;

  // Returns the length of the code point in UTF-16 code units.
  static intptr_t Length(int32_t ch) {
    return (ch <= kMaxBmpCodepoint) ? 1 : 2;
  }

  // Returns true if ch is a lead or trail surrogate.
  static bool IsSurrogate(int32_t ch) {
    return (ch & 0xFFFFF800) == 0xD800;
  }

  // Returns true if ch is a lead surrogate.
  static bool IsLeadSurrogate(int32_t ch) {
    return (ch & 0xFFFFFC00) == 0xD800;
  }

  // Returns true if ch is a low surrogate.
  static bool IsTrailSurrogate(int32_t ch) {
    return (ch & 0xFFFFFC00) == 0xDC00;
  }

  // Decodes a surrogate pair into a supplementary code point.
  static int32_t Decode(int32_t lead, int32_t trail) {
    ASSERT(IsLeadSurrogate(lead));
    ASSERT(IsTrailSurrogate(trail));
    return kSurrogateEncodingBase +
        ((lead & kSurrogateMask) << 10) + (trail & kSurrogateMask);
  }

  static int32_t LeadFromCodePoint(int32_t code_point) {
    ASSERT(code_point >= kSurrogateEncodingBase);
    return kLeadBase +
           (((code_point - kSurrogateEncodingBase) >> 10) & kSurrogateMask);
  }

  static int32_t TrailFromCodePoint(int32_t code_point) {
    ASSERT(code_point >= kSurrogateEncodingBase);
    return kTrailBase + (code_point & kSurrogateMask);
  }

  // Encodes a single code point.
  static void Encode(int32_t codepoint, uint16_t* dst);

  // Gets the 21 bit Unicode code point at the given index in a string.  If the
  // returned value is greater than kMaxCodePoint then the next position of the
  // string encodes a trail surrogate and should be skipped on iteration.  May
  // return individual surrogate values if they are not part of a pair.
  static int32_t CodePointAt(const String& str, int index);

 private:
  static const int32_t kLeadBase = 0xD800;
  static const int32_t kTrailBase = 0xDC00;
  static const int32_t kSurrogateMask = 0x3FF;
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
  static const int kStage1Size = 261;

  // The size of a stage 2 block in bytes.
  static const int kBlockSizeLog2 = 8;
  static const int kBlockSize = 1 << kBlockSizeLog2;

  static int32_t Convert(int32_t ch, int32_t mapping) {
    if (ch <= 0xFF) {
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

}  // namespace dart

#endif  // VM_UNICODE_H_
