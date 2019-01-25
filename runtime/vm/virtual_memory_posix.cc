// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_ANDROID) || defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS)

#include "vm/virtual_memory.h"

#include <errno.h>
#include <sys/mman.h>
#include <unistd.h>

#include "platform/assert.h"
#include "platform/utils.h"

#include "vm/isolate.h"

namespace dart {

// standard MAP_FAILED causes "error: use of old-style cast" as it
// defines MAP_FAILED as ((void *) -1)
#undef MAP_FAILED
#define MAP_FAILED reinterpret_cast<void*>(-1)

uword VirtualMemory::page_size_ = 0;

void VirtualMemory::Init() {
  page_size_ = getpagesize();
}

static void unmap(uword start, uword end) {
  ASSERT(start <= end);
  uword size = end - start;
  if (size == 0) {
    return;
  }

  if (munmap(reinterpret_cast<void*>(start), size) != 0) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL2("munmap error: %d (%s)", error,
           Utils::StrError(error, error_buf, kBufferSize));
  }
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              const char* name) {
  ASSERT(Utils::IsAligned(size, page_size_));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, page_size_));
  const intptr_t allocated_size = size + alignment - page_size_;
  const int prot = PROT_READ | PROT_WRITE | (is_executable ? PROT_EXEC : 0);
  void* address =
      mmap(NULL, allocated_size, prot, MAP_PRIVATE | MAP_ANON, -1, 0);
  if (address == MAP_FAILED) {
    return NULL;
  }

  const uword base = reinterpret_cast<uword>(address);
  const uword aligned_base = Utils::RoundUp(base, alignment);

  unmap(base, aligned_base);
  unmap(aligned_base + size, base + allocated_size);

  MemoryRegion region(reinterpret_cast<void*>(aligned_base), size);
  return new VirtualMemory(region, region);
}

VirtualMemory::~VirtualMemory() {
  if (vm_owns_region()) {
    unmap(reserved_.start(), reserved_.end());
  }
}

bool VirtualMemory::FreeSubSegment(void* address,
                                   intptr_t size) {
  const uword start = reinterpret_cast<uword>(address);
  unmap(start, start + size);
  return true;
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT((thread == nullptr) || thread->IsMutatorThread() ||
         thread->isolate()->mutator_thread()->IsAtSafepoint());
#endif
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
  if (mprotect(reinterpret_cast<void*>(page_address),
               end_address - page_address, prot) != 0) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL2("mprotect error: %d (%s)", error,
           Utils::StrError(error, error_buf, kBufferSize));
  }
}

}  // namespace dart

#endif  // defined(HOST_OS_ANDROID) || defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS)
