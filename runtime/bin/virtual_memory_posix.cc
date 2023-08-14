// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX) ||            \
    defined(DART_HOST_OS_MACOS)

#include "bin/virtual_memory.h"

#include <errno.h>
#include <sys/mman.h>
#include <unistd.h>

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
#include <sys/prctl.h>
#endif

#include "platform/assert.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

// standard MAP_FAILED causes "error: use of old-style cast" as it
// defines MAP_FAILED as ((void *) -1)
#undef MAP_FAILED
#define MAP_FAILED reinterpret_cast<void*>(-1)

uword VirtualMemory::page_size_ = 0;

intptr_t VirtualMemory::CalculatePageSize() {
  const intptr_t page_size = getpagesize();
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

VirtualMemory* VirtualMemory::Allocate(intptr_t size,
                                       bool is_executable,
                                       const char* name) {
  ASSERT(Utils::IsAligned(size, PageSize()));

  const int prot = PROT_READ | PROT_WRITE | (is_executable ? PROT_EXEC : 0);

  int map_flags = MAP_PRIVATE | MAP_ANONYMOUS;
#if (defined(DART_HOST_OS_MACOS) && !defined(DART_HOST_OS_IOS))
  if (is_executable && IsAtLeastOS10_14()) {
    map_flags |= MAP_JIT;
  }
#endif  // defined(DART_HOST_OS_MACOS)

  // Some 64-bit microarchitectures store only the low 32-bits of targets as
  // part of indirect branch prediction, predicting that the target's upper bits
  // will be same as the call instruction's address. This leads to misprediction
  // for indirect calls crossing a 4GB boundary. We ask mmap to place our
  // generated code near the VM binary to avoid this.
  void* hint = is_executable ? reinterpret_cast<void*>(&Allocate) : nullptr;
  void* address = mmap(hint, size, prot, map_flags, -1, 0);
  if (address == MAP_FAILED) {
    return nullptr;
  }

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  // PR_SET_VMA was only added to mainline Linux in 5.17, and some versions of
  // the Android NDK have incorrect headers, so we manually define it if absent.
#if !defined(PR_SET_VMA)
#define PR_SET_VMA 0x53564d41
#endif
#if !defined(PR_SET_VMA_ANON_NAME)
#define PR_SET_VMA_ANON_NAME 0
#endif
  prctl(PR_SET_VMA, PR_SET_VMA_ANON_NAME, address, size, name);
#endif

  return new VirtualMemory(address, size);
}

VirtualMemory::~VirtualMemory() {
  if (address_ != nullptr) {
    if (munmap(address_, size_) != 0) {
      int error = errno;
      const int kBufferSize = 1024;
      char error_buf[kBufferSize];
      FATAL("munmap error: %d (%s)", error,
            Utils::StrError(error, error_buf, kBufferSize));
    }
  }
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
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
    FATAL("mprotect error: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX) ||     \
        // defined(DART_HOST_OS_MACOS)
