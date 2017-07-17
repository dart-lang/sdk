// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/token_position.h"

#include "vm/object.h"

namespace dart {

TokenPosition TokenPosition::SnapshotDecode(int32_t value) {
  return TokenPosition(static_cast<intptr_t>(value));
}

int32_t TokenPosition::SnapshotEncode() {
  return static_cast<int32_t>(value_);
}

bool TokenPosition::IsSynthetic() const {
  if (value_ >= kMinSourcePos) {
    return false;
  }
  if (value_ < kLast.value()) {
    return true;
  }
  return false;
}

#define DEFINE_VALUES(name, value)                                             \
  const TokenPosition TokenPosition::k##name = TokenPosition(value);
SENTINEL_TOKEN_DESCRIPTORS(DEFINE_VALUES);
#undef DEFINE_VALUES
const TokenPosition TokenPosition::kMinSource = TokenPosition(kMinSourcePos);

const TokenPosition TokenPosition::kMaxSource = TokenPosition(kMaxSourcePos);

const char* TokenPosition::ToCString() const {
  switch (value_) {
#define DEFINE_CASE(name, value)                                               \
  case value:                                                                  \
    return #name;
    SENTINEL_TOKEN_DESCRIPTORS(DEFINE_CASE);
#undef DEFINE_CASE
    default: {
      Zone* zone = Thread::Current()->zone();
      ASSERT(zone != NULL);
      if (IsSynthetic()) {
        // TODO(johnmccutchan): Print synthetic positions differently.
        return FromSynthetic().ToCString();
      } else {
        return OS::SCreate(zone, "%d", value_);
      }
    }
  }
}

}  // namespace dart
