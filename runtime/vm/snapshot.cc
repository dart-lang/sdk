// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/snapshot.h"

#include "platform/assert.h"
#include "vm/dart.h"

namespace dart {

const char* Snapshot::KindToCString(Kind kind) {
  switch (kind) {
    case kFull:
      return "full";
    case kFullCore:
      return "full-core";
    case kFullJIT:
      return "full-jit";
    case kFullAOT:
      return "full-aot";
    case kNone:
      return "none";
    case kInvalid:
    default:
      return "invalid";
  }
}

const Snapshot* Snapshot::SetupFromBuffer(const void* raw_memory) {
  ASSERT(raw_memory != nullptr);
  const Snapshot* snapshot = reinterpret_cast<const Snapshot*>(raw_memory);
  if (!snapshot->check_magic()) {
    return nullptr;
  }
  // If the raw length is negative or greater than what the local machine can
  // handle, then signal an error.
  int64_t length = snapshot->large_length();
  if ((length < 0) || (length > kIntptrMax)) {
    return nullptr;
  }
  return snapshot;
}

}  // namespace dart
