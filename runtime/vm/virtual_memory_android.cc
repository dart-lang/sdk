// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/virtual_memory.h"

#include <sys/mman.h>
#include <unistd.h>

#include "platform/assert.h"
#include "platform/utils.h"

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
  // TODO(4408): use ashmem instead of anonymous memory.
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


bool VirtualMemory::Protect(Protection mode) {
  int prot = 0;
  switch (mode) {
    case kNoAccess:
      prot = PROT_NONE;
      break;
    case kReadOnly:
      prot = PROT_READ;
      break;
    case kReadWrite:
      prot = PROT_READ | PROT_WRITE;
      break;
    case kReadExecute:
      prot = PROT_READ | PROT_EXEC;
      break;
    case kReadWriteExecute:
      prot = PROT_READ | PROT_WRITE | PROT_EXEC;
      break;
  }
  return (mprotect(address(), size(), prot) == 0);
}

}  // namespace dart
