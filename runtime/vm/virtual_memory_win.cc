// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/virtual_memory.h"
#include "vm/assert.h"

namespace dart {

uword VirtualMemory::page_size_ = 0;


void VirtualMemory::InitOnce() {
  SYSTEM_INFO info;
  GetSystemInfo(&info);
  page_size_ = info.dwPageSize;
}


VirtualMemory* VirtualMemory::Reserve(intptr_t size) {
  void* address = VirtualAlloc(NULL, size, MEM_RESERVE, PAGE_NOACCESS);
  if (address == NULL) {
    return NULL;
  }
  MemoryRegion region(address, size);
  return new VirtualMemory(region, address);
}


VirtualMemory::~VirtualMemory() {
  if (size() == 0) {
    return;
  }

  // Since sub-segments are not freed, free the entire virtual segment
  // here by passing the originally reserved pointer to VirtualFree.
  ASSERT(reserved_pointer_ != NULL);
  if (VirtualFree(reserved_pointer_, 0, MEM_RELEASE) == 0) {
    FATAL("VirtualFree failed");
  }
}


void VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
  // On Windows only the entire segment returned by VirtualAlloc
  // can be freed. Therefore we will have to waste these unused
  // virtual memory sub-segments.
}


bool VirtualMemory::Commit(uword addr, intptr_t size, bool executable) {
  ASSERT(Contains(addr));
  ASSERT(Contains(addr + size) || (addr + size == end()));
  int prot = executable ? PAGE_EXECUTE_READWRITE : PAGE_READWRITE;
  if (VirtualAlloc(address(), size, MEM_COMMIT, prot) == NULL) {
    return false;
  }
  return true;
}

}  // namespace dart
