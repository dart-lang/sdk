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


void VirtualMemory::Truncate(intptr_t new_size, bool try_unmap) {
  ASSERT((new_size & (PageSize() - 1)) == 0);
  ASSERT(new_size <= size());
  if (try_unmap &&
      (reserved_size_ == size()) &&  /* Don't create holes in reservation. */
      FreeSubSegment(reinterpret_cast<void*>(start() + new_size),
                     size() - new_size)) {
    reserved_size_ = new_size;
  }
  region_.Subregion(region_, 0, new_size);
}

}  // namespace dart
