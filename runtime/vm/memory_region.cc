// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/memory_region.h"

namespace dart {

void MemoryRegion::CopyFrom(uword offset, const MemoryRegion& from) const {
  ASSERT(from.pointer() != NULL && from.size() > 0);
  ASSERT(this->size() >= from.size());
  ASSERT(offset <= this->size() - from.size());
  memmove(reinterpret_cast<void*>(start() + offset), from.pointer(),
          from.size());
}

}  // namespace dart
