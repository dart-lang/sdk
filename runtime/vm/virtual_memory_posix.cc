// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_ANDROID) || defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS)

#include "vm/virtual_memory.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/isolate.h"

// #define VIRTUAL_MEMORY_LOGGING 1
#if defined(VIRTUAL_MEMORY_LOGGING)
#define LOG_INFO(msg, ...) OS::PrintErr(msg, ##__VA_ARGS__)
#else
#define LOG_INFO(msg, ...)
#endif  // defined(VIRTUAL_MEMORY_LOGGING)

namespace dart {

// standard MAP_FAILED causes "error: use of old-style cast" as it
// defines MAP_FAILED as ((void *) -1)
#undef MAP_FAILED
#define MAP_FAILED reinterpret_cast<void*>(-1)

#define DART_SHM_NAME "/dart_shm"

DECLARE_FLAG(bool, dual_map_code);
DECLARE_FLAG(bool, write_protect_code);

uword VirtualMemory::page_size_ = 0;

void VirtualMemory::Init() {
  page_size_ = getpagesize();

#if defined(DUAL_MAPPING_SUPPORTED)
  shm_unlink(DART_SHM_NAME);  // Could be left over from a previous crash.
#endif                        // defined(DUAL_MAPPING_SUPPORTED)
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

#if defined(DUAL_MAPPING_SUPPORTED)
static void* MapAligned(int fd,
                        int prot,
                        intptr_t size,
                        intptr_t alignment,
                        intptr_t allocated_size) {
  void* address =
      mmap(NULL, allocated_size, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  LOG_INFO("mmap(NULL, 0x%" Px ", PROT_NONE, ...): %p\n", allocated_size,
           address);
  if (address == MAP_FAILED) {
    return NULL;
  }

  const uword base = reinterpret_cast<uword>(address);
  const uword aligned_base = Utils::RoundUp(base, alignment);

  // Guarantee the alignment by mapping at a fixed address inside the above
  // mapping. Overlapping region will be automatically discarded in the above
  // mapping. Manually discard non-overlapping regions.
  address = mmap(reinterpret_cast<void*>(aligned_base), size, prot,
                 MAP_SHARED | MAP_FIXED, fd, 0);
  LOG_INFO("mmap(0x%" Px ", 0x%" Px ", %u, ...): %p\n", aligned_base, size,
           prot, address);
  if (address == MAP_FAILED) {
    unmap(base, base + allocated_size);
    return NULL;
  }
  ASSERT(address == reinterpret_cast<void*>(aligned_base));
  unmap(base, aligned_base);
  unmap(aligned_base + size, base + allocated_size);
  return address;
}
#endif  // defined(DUAL_MAPPING_SUPPORTED)

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              const char* name) {
  // When FLAG_write_protect_code is active, code memory (indicated by
  // is_executable = true) is allocated as non-executable and later
  // changed to executable via VirtualMemory::Protect.
  ASSERT(Utils::IsAligned(size, page_size_));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, page_size_));
  const intptr_t allocated_size = size + alignment - page_size_;
#if defined(DUAL_MAPPING_SUPPORTED)
  int fd = -1;
  const bool dual_mapping =
      is_executable && FLAG_write_protect_code && FLAG_dual_map_code;
  if (dual_mapping) {
    // Create a shared memory object for dual mapping.
    // There is a small conflict window, i.e. another Dart process
    // simultaneously opening an object with the same name.
    do {
      fd = shm_open(DART_SHM_NAME, O_RDWR | O_CREAT | O_EXCL, S_IRWXU);
    } while ((fd == -1) && (errno == EEXIST));
    shm_unlink(DART_SHM_NAME);
    if ((fd == -1) || (ftruncate(fd, size) == -1)) {
      close(fd);
      return NULL;
    }
    const int region_prot = PROT_READ | PROT_WRITE;
    void* region_ptr =
        MapAligned(fd, region_prot, size, alignment, allocated_size);
    if (region_ptr == NULL) {
      close(fd);
      return NULL;
    }
    MemoryRegion region(region_ptr, size);
    // PROT_EXEC is added later via VirtualMemory::Protect.
    const int alias_prot = PROT_READ;
    void* alias_ptr =
        MapAligned(fd, alias_prot, size, alignment, allocated_size);
    close(fd);
    if (alias_ptr == NULL) {
      const uword region_base = reinterpret_cast<uword>(region_ptr);
      unmap(region_base, region_base + size);
      return NULL;
    }
    ASSERT(region_ptr != alias_ptr);
    MemoryRegion alias(alias_ptr, size);
    return new VirtualMemory(region, alias, region);
  }
#endif  // defined(DUAL_MAPPING_SUPPORTED)
  const int prot =
      PROT_READ | PROT_WRITE |
      ((is_executable && !FLAG_write_protect_code) ? PROT_EXEC : 0);
  void* address =
      mmap(NULL, allocated_size, prot, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  LOG_INFO("mmap(NULL, 0x%" Px ", %u, ...): %p\n", allocated_size, prot,
           address);
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
    const intptr_t alias_offset = AliasOffset();
    if (alias_offset != 0) {
      unmap(reserved_.start() + alias_offset, reserved_.end() + alias_offset);
    }
  }
}

void VirtualMemory::FreeSubSegment(void* address,
                                   intptr_t size) {
  const uword start = reinterpret_cast<uword>(address);
  unmap(start, start + size);
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
    LOG_INFO("mprotect(0x%" Px ", 0x%" Px ", %u) failed\n", page_address,
             end_address - page_address, prot);
    FATAL2("mprotect error: %d (%s)", error,
           Utils::StrError(error, error_buf, kBufferSize));
  }
  LOG_INFO("mprotect(0x%" Px ", 0x%" Px ", %u) ok\n", page_address,
           end_address - page_address, prot);
}

}  // namespace dart

#endif  // defined(HOST_OS_ANDROID ... HOST_OS_LINUX ... HOST_OS_MACOS)
