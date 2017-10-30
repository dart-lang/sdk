// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_ANDROID)

#include "vm/virtual_memory.h"

#include <sys/mman.h>  // NOLINT
#include <unistd.h>    // NOLINT

#include "platform/assert.h"
#include "platform/utils.h"

#include "vm/isolate.h"

namespace dart {

// standard MAP_FAILED causes "error: use of old-style cast" as it
// defines MAP_FAILED as ((void *) -1)
#undef MAP_FAILED
#define MAP_FAILED reinterpret_cast<void*>(-1)

uword VirtualMemory::page_size_ = 0;

void VirtualMemory::InitOnce() {
  page_size_ = getpagesize();
}

static void unmap(void* address, intptr_t size) {
  if (size == 0) {
    return;
  }

  if (munmap(address, size) != 0) {
    FATAL("munmap failed\n");
  }
}

VirtualMemory* VirtualMemory::Allocate(intptr_t size,
                                       bool is_executable,
                                       const char* name) {
  ASSERT(Utils::IsAligned(size, page_size_));
  int prot = PROT_READ | PROT_WRITE | (is_executable ? PROT_EXEC : 0);
  void* address = mmap(NULL, size, prot, MAP_PRIVATE | MAP_ANON, -1, 0);
  if (address == MAP_FAILED) {
    return NULL;
  }
  MemoryRegion region(address, size);
  return new VirtualMemory(region, region);
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              const char* name) {
  ASSERT(Utils::IsAligned(size, page_size_));
  ASSERT(Utils::IsAligned(alignment, page_size_));
  intptr_t allocated_size = size + alignment;
  int prot = PROT_READ | PROT_WRITE | (is_executable ? PROT_EXEC : 0);
  void* address =
      mmap(NULL, allocated_size, prot, MAP_PRIVATE | MAP_ANON, -1, 0);
  if (address == MAP_FAILED) {
    return NULL;
  }

  uword base = reinterpret_cast<uword>(address);
  uword aligned_base = Utils::RoundUp(base, alignment);
  ASSERT(base <= aligned_base);

  if (base != aligned_base) {
    uword extra_leading_size = aligned_base - base;
    unmap(reinterpret_cast<void*>(base), extra_leading_size);
    allocated_size -= extra_leading_size;
  }

  if (allocated_size != size) {
    uword extra_trailing_size = allocated_size - size;
    unmap(reinterpret_cast<void*>(aligned_base + size), extra_trailing_size);
  }

  MemoryRegion region(reinterpret_cast<void*>(aligned_base), size);
  return new VirtualMemory(region, region);
}

VirtualMemory::~VirtualMemory() {
  if (vm_owns_region()) {
    unmap(reserved_.pointer(), reserved_.size());
  }
}

bool VirtualMemory::FreeSubSegment(int32_t handle,
                                   void* address,
                                   intptr_t size) {
  unmap(address, size);
  return true;
}

bool VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
  ASSERT(Thread::Current()->IsMutatorThread() ||
         Isolate::Current()->mutator_thread()->IsAtSafepoint());
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
                   end_address - page_address, prot) == 0);
}

}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)
