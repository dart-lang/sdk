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

  static void Encode(int32_t ch, char* dst);
  static intptr_t Encode(const String& src, char* dst, intptr_t len);

  static intptr_t Decode(const char*, int32_t* ch);
  static bool Decode(const char* src, uint8_t* dst, intptr_t len);
  static bool Decode(const char* src, uint16_t* dst, intptr_t len);
  static bool Decode(const char* src, uint32_t* dst, intptr_t len);
};

}  // namespace dart

#endif  // VM_UNICODE_H_
