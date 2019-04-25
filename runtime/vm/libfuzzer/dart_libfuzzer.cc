// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stddef.h>
#include <stdint.h>

#include "platform/unicode.h"

// Libfuzzer target function.
extern "C" int LLVMFuzzerTestOneInput(const uint8_t* Data, size_t Size) {
  // Proof-of-concept: stresses unicode methods.
  // NOTE: already found http://dartbug.com/36235
  dart::Utf8::Type type = dart::Utf8::kLatin1;
  dart::Utf8::CodeUnitCount(Data, Size, &type);
  dart::Utf8::IsValid(Data, Size);
  int32_t dst = 0;
  dart::Utf8::Decode(Data, Size, &dst);
  uint16_t dst16[1024];
  dart::Utf8::DecodeToUTF16(Data, Size, dst16, 1024);
  int32_t dst32[1024];
  dart::Utf8::DecodeToUTF32(Data, Size, dst32, 1024);
  return 0;
}
