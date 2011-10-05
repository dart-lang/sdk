// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <sys/mman.h>
#include <unistd.h>

#include "vm/virtual_memory.h"
#include "vm/assert.h"
#include "vm/utils.h"

namespace dart {

// standard MAP_FAILED causes "error: use of old-style cast" as it
// defines MAP_FAILED as ((void *) -1)
#undef MAP_FAILED
#define MAP_FAILED reinterpret_cast<void*>(-1)

uword VirtualMemory::page_size_ = 0;


void VirtualMemory::InitOnce() {
  page_size_ = getpagesize();
}


VirtualMemory* VirtualMemory::Reserve(intptr_t size) {
  ASSERT((size & (PageSize() - 1)) == 0);
  void* address = mmap(NULL, size, PROT_NONE,
                       MAP_PRIVATE | MAP_ANON | MAP_NORESERVE,
                       -1, 0);
  if (address == MAP_FAILED) {
    return NULL;
  }
  MemoryRegion region(address, size);
  return new VirtualMemory(region, NULL);
}


static void unmap(void* address, intptr_t size) {
  if (size == 0) {
    return;
  }

  if (munmap(address, size) != 0) {
    FATAL("munmap failed\n");
  }
}


VirtualMemory::~VirtualMemory() {
  unmap(address(), size());
}


void VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
  unmap(address, size);
}


bool VirtualMemory::Commit(uword addr, intptr_t size, bool executable) {
  ASSERT(Contains(addr));
  ASSERT(Contains(addr + size) || (addr + size == end()));
  int prot = PROT_READ | PROT_WRITE | (executable ? PROT_EXEC : 0);
  void* address = mmap(reinterpret_cast<void*>(addr), size, prot,
                       MAP_PRIVATE | MAP_ANON | MAP_FIXED,
                       -1, 0);
  if (address == MAP_FAILED) {
    return false;
  }
  return true;
}

}  // namespace dart
