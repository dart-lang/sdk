// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/token_position.h"

#include "vm/hash.h"
#include "vm/object.h"
#include "vm/zone_text_buffer.h"

namespace dart {

intptr_t TokenPosition::Hash() const {
  return FinalizeHash(value_, 31);
}

TokenPosition TokenPosition::Deserialize(int32_t value) {
  return TokenPosition(value);
}

int32_t TokenPosition::Serialize() const {
  return static_cast<int32_t>(value_);
}

#define DEFINE_VALUES(name, value)                                             \
  const TokenPosition TokenPosition::k##name(value);
SENTINEL_TOKEN_DESCRIPTORS(DEFINE_VALUES);
#undef DEFINE_VALUES
const TokenPosition TokenPosition::kMinSource(kMinSourcePos);
const TokenPosition TokenPosition::kMaxSource(kMaxSourcePos);

const char* TokenPosition::ToCString() const {
  switch (value_) {
#define DEFINE_CASE(name, value)                                               \
  case value:                                                                  \
    return #name;
    SENTINEL_TOKEN_DESCRIPTORS(DEFINE_CASE);
#undef DEFINE_CASE
    default:
      break;
  }
  ASSERT(IsReal() || IsSynthetic());
  ZoneTextBuffer buffer(Thread::Current()->zone());
  if (IsSynthetic()) {
    buffer.AddString("syn:");
  }
  buffer.Printf("%" Pd32 "", value_);
  return buffer.buffer();
}

}  // namespace dart
