// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_MACOS)

#include "vm/virtual_memory.h"

#include <sys/mman.h>  // NOLINT
#include <unistd.h>  // NOLINT

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


VirtualMemory* VirtualMemory::ReserveInternal(intptr_t size) {
  ASSERT((size & (PageSize() - 1)) == 0);
  void* address = mmap(NULL, size, PROT_NONE,
                       MAP_PRIVATE | MAP_ANON | MAP_NORESERVE,
                       -1, 0);
  if (address == MAP_FAILED) {
    return NULL;
  }
  MemoryRegion region(address, size);
  return new VirtualMemory(region);
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
  unmap(address(), reserved_size_);
}


bool VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
  unmap(address, size);
  return true;
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


bool VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
  uword start_address = reinterpret_cast<uword>(address);
  uword end_address = start_address + size;
  uword page_address = Utils::RoundDown(start_address, PageSize());
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
  return (mprotect(reinterpret_cast<void*>(page_address),
                   end_address - page_address,
                   prot) == 0);
}

}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)
