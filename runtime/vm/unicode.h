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
  static const intptr_t kMaxOneByteChar   = 0x7F;
  static const intptr_t kMaxTwoByteChar   = 0x7FF;
  static const intptr_t kMaxThreeByteChar = 0xFFFF;
  static const intptr_t kMaxFourByteChar  = 0x10FFFF;

  static intptr_t CodePointCount(const char* str, intptr_t* width);

  static intptr_t Length(int32_t ch);
  static intptr_t Length(const String& str);

  static intptr_t Encode(int32_t ch, char* dst);
  static intptr_t Encode(const String& src, char* dst, intptr_t len);

  static intptr_t Decode(const char*, int32_t* ch);
  static bool Decode(const char* src, uint8_t* dst, intptr_t len);
  static bool Decode(const char* src, uint16_t* dst, intptr_t len);
  static bool Decode(const char* src, uint32_t* dst, intptr_t len);
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
