// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/virtual_memory.h"

#include "platform/assert.h"
#include "platform/utils.h"

namespace dart {

bool VirtualMemory::InSamePage(uword address0, uword address1) {
  return (Utils::RoundDown(address0, PageSize()) ==
          Utils::RoundDown(address1, PageSize()));
}

void VirtualMemory::Truncate(intptr_t new_size) {
  ASSERT(Utils::IsAligned(new_size, PageSize()));
  ASSERT(new_size <= size());
  if (reserved_.size() ==
      region_.size()) {  // Don't create holes in reservation.
    FreeSubSegment(reinterpret_cast<void*>(start() + new_size),
                   size() - new_size);
    reserved_.set_size(new_size);
    if (AliasOffset() != 0) {
      FreeSubSegment(reinterpret_cast<void*>(alias_.start() + new_size),
                     alias_.size() - new_size);
    }
  }
  region_.Subregion(region_, 0, new_size);
  alias_.Subregion(alias_, 0, new_size);
}

VirtualMemory* VirtualMemory::ForImagePage(void* pointer, uword size) {
  // Memory for precompilated instructions was allocated by the embedder, so
  // create a VirtualMemory without allocating.
  MemoryRegion region(pointer, size);
  MemoryRegion reserved(0, 0);  // NULL reservation indicates VM should not
                                // attempt to free this memory.
  VirtualMemory* memory = new VirtualMemory(region, region, reserved);
  ASSERT(!memory->vm_owns_region());
  return memory;
}

}  // namespace dart
