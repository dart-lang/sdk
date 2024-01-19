// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX) ||            \
    defined(DART_HOST_OS_MACOS)

#include "vm/virtual_memory.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
#include <sys/prctl.h>
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/heap/pages.h"
#include "vm/isolate.h"
#include "vm/virtual_memory_compressed.h"

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

#if defined(DART_HOST_OS_IOS)
#define LARGE_RESERVATIONS_MAY_FAIL
#endif

DECLARE_FLAG(bool, write_protect_code);

#if defined(DART_TARGET_OS_LINUX)
DECLARE_FLAG(bool, generate_perf_events_symbols);
DECLARE_FLAG(bool, generate_perf_jitdump);
#endif

uword VirtualMemory::page_size_ = 0;
VirtualMemory* VirtualMemory::compressed_heap_ = nullptr;

static void* Map(void* addr,
                 size_t length,
                 int prot,
                 int flags,
                 int fd,
                 off_t offset) {
  void* result = mmap(addr, length, prot, flags, fd, offset);
  int error = errno;
  LOG_INFO("mmap(%p, 0x%" Px ", %u, ...): %p\n", addr, length, prot, result);
  if ((result == MAP_FAILED) && (error != ENOMEM)) {
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("mmap failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  return result;
}

static void Unmap(uword start, uword end) {
  ASSERT(start <= end);
  uword size = end - start;
  if (size == 0) {
    return;
  }

  if (munmap(reinterpret_cast<void*>(start), size) != 0) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("munmap failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
}

static void* GenericMapAligned(void* hint,
                               int prot,
                               intptr_t size,
                               intptr_t alignment,
                               intptr_t allocated_size,
                               int map_flags) {
  void* address = Map(hint, allocated_size, prot, map_flags, -1, 0);
  if (address == MAP_FAILED) {
    return nullptr;
  }

  const uword base = reinterpret_cast<uword>(address);
  const uword aligned_base = Utils::RoundUp(base, alignment);

  Unmap(base, aligned_base);
  Unmap(aligned_base + size, base + allocated_size);
  return reinterpret_cast<void*>(aligned_base);
}

intptr_t VirtualMemory::CalculatePageSize() {
  const intptr_t page_size = getpagesize();
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

#if defined(DART_COMPRESSED_POINTERS) && defined(LARGE_RESERVATIONS_MAY_FAIL)
// Truncate to the largest subregion in [region] that doesn't cross an
// [alignment] boundary.
static MemoryRegion ClipToAlignedRegion(MemoryRegion region, size_t alignment) {
  uword base = region.start();
  uword aligned_base = Utils::RoundUp(base, alignment);
  uword size_below =
      region.end() >= aligned_base ? aligned_base - base : region.size();
  uword size_above =
      region.end() >= aligned_base ? region.end() - aligned_base : 0;
  ASSERT(size_below + size_above == region.size());
  if (size_below >= size_above) {
    Unmap(aligned_base, aligned_base + size_above);
    return MemoryRegion(reinterpret_cast<void*>(base), size_below);
  }
  Unmap(base, base + size_below);
  if (size_above > alignment) {
    Unmap(aligned_base + alignment, aligned_base + size_above);
    size_above = alignment;
  }
  return MemoryRegion(reinterpret_cast<void*>(aligned_base), size_above);
}
#endif  // LARGE_RESERVATIONS_MAY_FAIL

void VirtualMemory::Init() {
  if (FLAG_old_gen_heap_size < 0 || FLAG_old_gen_heap_size > kMaxAddrSpaceMB) {
    OS::PrintErr(
        "warning: value specified for --old_gen_heap_size %d is larger than"
        " the physically addressable range, using 0(unlimited) instead.`\n",
        FLAG_old_gen_heap_size);
    FLAG_old_gen_heap_size = 0;
  }
  if (FLAG_new_gen_semi_max_size < 0 ||
      FLAG_new_gen_semi_max_size > kMaxAddrSpaceMB) {
    OS::PrintErr(
        "warning: value specified for --new_gen_semi_max_size %d is larger"
        " than the physically addressable range, using %" Pd " instead.`\n",
        FLAG_new_gen_semi_max_size, kDefaultNewGenSemiMaxSize);
    FLAG_new_gen_semi_max_size = kDefaultNewGenSemiMaxSize;
  }
  page_size_ = CalculatePageSize();
#if defined(DART_COMPRESSED_POINTERS)
  ASSERT(compressed_heap_ == nullptr);
#if defined(LARGE_RESERVATIONS_MAY_FAIL)
  // Try to reserve a region for the compressed heap by requesting decreasing
  // powers-of-two until one succeeds, and use the largest subregion that does
  // not cross a 4GB boundary. The subregion itself is not necessarily
  // 4GB-aligned.
  for (size_t allocated_size = kCompressedHeapSize + kCompressedHeapAlignment;
       allocated_size >= kCompressedPageSize; allocated_size >>= 1) {
    void* address = GenericMapAligned(
        nullptr, PROT_NONE, allocated_size, kCompressedPageSize,
        allocated_size + kCompressedPageSize,
        MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE);
    if (address == nullptr) continue;

    MemoryRegion region(address, allocated_size);
    region = ClipToAlignedRegion(region, kCompressedHeapAlignment);
    compressed_heap_ = new VirtualMemory(region, region);
    break;
  }
#else
  compressed_heap_ = Reserve(kCompressedHeapSize, kCompressedHeapAlignment);
#endif
  if (compressed_heap_ == nullptr) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Failed to reserve region for compressed heap: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  VirtualMemoryCompressedHeap::Init(compressed_heap_->address(),
                                    compressed_heap_->size());
#endif  // defined(DART_COMPRESSED_POINTERS)

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
  FILE* fp = fopen("/proc/sys/vm/max_map_count", "r");
  if (fp != nullptr) {
    size_t max_map_count = 0;
    int count = fscanf(fp, "%zu", &max_map_count);
    fclose(fp);
    if (count == 1) {
      size_t max_heap_pages = FLAG_old_gen_heap_size * MB / kPageSize;
      if (max_map_count < max_heap_pages) {
        OS::PrintErr(
            "warning: vm.max_map_count (%zu) is not large enough to support "
            "--old_gen_heap_size=%d. Consider increasing it with `sysctl -w "
            "vm.max_map_count=%zu`\n",
            max_map_count, FLAG_old_gen_heap_size, max_heap_pages);
      }
    }
  }
#endif
}

void VirtualMemory::Cleanup() {
#if defined(DART_COMPRESSED_POINTERS)
  delete compressed_heap_;
#endif  // defined(DART_COMPRESSED_POINTERS)
  page_size_ = 0;
#if defined(DART_COMPRESSED_POINTERS)
  compressed_heap_ = nullptr;
  VirtualMemoryCompressedHeap::Cleanup();
#endif  // defined(DART_COMPRESSED_POINTERS)
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              bool is_compressed,
                                              const char* name) {
  // When FLAG_write_protect_code is active, code memory (indicated by
  // is_executable = true) is allocated as non-executable and later
  // changed to executable via VirtualMemory::Protect.
  ASSERT(Utils::IsAligned(size, PageSize()));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, PageSize()));
  ASSERT(name != nullptr);

#if defined(DART_COMPRESSED_POINTERS)
  if (is_compressed) {
    RELEASE_ASSERT(!is_executable);
    MemoryRegion region =
        VirtualMemoryCompressedHeap::Allocate(size, alignment);
    if (region.pointer() == nullptr) {
#if defined(LARGE_RESERVATIONS_MAY_FAIL)
      // Try a fresh allocation and hope it ends up in the right region. On
      // macOS/iOS, this works surprisingly often.
      void* address =
          GenericMapAligned(nullptr, PROT_READ | PROT_WRITE, size, alignment,
                            size + alignment, MAP_PRIVATE | MAP_ANONYMOUS);
      if (address != nullptr) {
        uword ok_start = Utils::RoundDown(compressed_heap_->start(),
                                          kCompressedHeapAlignment);
        uword ok_end = ok_start + kCompressedHeapSize;
        uword start = reinterpret_cast<uword>(address);
        uword end = start + size;
        if ((start >= ok_start) && (end <= ok_end)) {
          MemoryRegion region(address, size);
          return new VirtualMemory(region, region);
        }
        munmap(address, size);
      }
#endif
      return nullptr;
    }
    Commit(region.pointer(), region.size());
    return new VirtualMemory(region, region);
  }
#endif  // defined(DART_COMPRESSED_POINTERS)

  const intptr_t allocated_size = size + alignment - PageSize();
  const int prot =
      PROT_READ | PROT_WRITE |
      ((is_executable && !FLAG_write_protect_code) ? PROT_EXEC : 0);

  int map_flags = MAP_PRIVATE | MAP_ANONYMOUS;
#if (defined(DART_HOST_OS_MACOS) && !defined(DART_HOST_OS_IOS))
  if (is_executable && IsAtLeastOS10_14()) {
    map_flags |= MAP_JIT;
  }
#endif  // defined(DART_HOST_OS_MACOS)

  void* hint = nullptr;
  // Some 64-bit microarchitectures store only the low 32-bits of targets as
  // part of indirect branch prediction, predicting that the target's upper bits
  // will be same as the call instruction's address. This leads to misprediction
  // for indirect calls crossing a 4GB boundary. We ask mmap to place our
  // generated code near the VM binary to avoid this.
  if (is_executable) {
    hint = reinterpret_cast<void*>(&Dart_Initialize);
  }
  void* address =
      GenericMapAligned(hint, prot, size, alignment, allocated_size, map_flags);
#if defined(DART_HOST_OS_LINUX)
  // On WSL 1 trying to allocate memory close to the binary by supplying a hint
  // fails with ENOMEM for unclear reason. Some reports suggest that this might
  // be related to the alignment of the hint but aligning it by 64Kb does not
  // make the issue go away in our experiments. Instead just retry without any
  // hint.
  if (address == nullptr && hint != nullptr &&
      Utils::IsWindowsSubsystemForLinux()) {
    address = GenericMapAligned(nullptr, prot, size, alignment, allocated_size,
                                map_flags);
  }
#endif
  if (address == nullptr) {
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

  MemoryRegion region(reinterpret_cast<void*>(address), size);
  return new VirtualMemory(region, region);
}

VirtualMemory* VirtualMemory::Reserve(intptr_t size, intptr_t alignment) {
  ASSERT(Utils::IsAligned(size, PageSize()));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, PageSize()));
  intptr_t allocated_size = size + alignment - PageSize();
  void* address =
      GenericMapAligned(nullptr, PROT_NONE, size, alignment, allocated_size,
                        MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE);
  if (address == nullptr) {
    return nullptr;
  }
  MemoryRegion region(address, size);
  return new VirtualMemory(region, region);
}

void VirtualMemory::Commit(void* address, intptr_t size) {
  ASSERT(Utils::IsAligned(address, PageSize()));
  ASSERT(Utils::IsAligned(size, PageSize()));
  void* result = mmap(address, size, PROT_READ | PROT_WRITE,
                      MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
  if (result == MAP_FAILED) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Failed to commit: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
}

void VirtualMemory::Decommit(void* address, intptr_t size) {
  ASSERT(Utils::IsAligned(address, PageSize()));
  ASSERT(Utils::IsAligned(size, PageSize()));
  void* result =
      mmap(address, size, PROT_NONE,
           MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED, -1, 0);
  if (result == MAP_FAILED) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Failed to decommit: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
}

VirtualMemory::~VirtualMemory() {
#if defined(DART_COMPRESSED_POINTERS)
  if (VirtualMemoryCompressedHeap::Contains(reserved_.pointer())) {
    Decommit(reserved_.pointer(), reserved_.size());
    VirtualMemoryCompressedHeap::Free(reserved_.pointer(), reserved_.size());
    return;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  if (vm_owns_region()) {
    Unmap(reserved_.start(), reserved_.end());
  }
}

bool VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
#if defined(DART_COMPRESSED_POINTERS)
  // Don't free the sub segment if it's managed by the compressed pointer heap.
  if (VirtualMemoryCompressedHeap::Contains(address)) {
    return false;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  const uword start = reinterpret_cast<uword>(address);
  Unmap(start, start + size);
  return true;
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread == nullptr || thread->IsDartMutatorThread() ||
         thread->isolate() == nullptr ||
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
    FATAL("mprotect failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  LOG_INFO("mprotect(0x%" Px ", 0x%" Px ", %u) ok\n", page_address,
           end_address - page_address, prot);
}

void VirtualMemory::DontNeed(void* address, intptr_t size) {
  uword start_address = reinterpret_cast<uword>(address);
  uword end_address = start_address + size;
  uword page_address = Utils::RoundDown(start_address, PageSize());
#if defined(DART_HOST_OS_MACOS)
  int advice = MADV_FREE;
#else
  int advice = MADV_DONTNEED;
#endif
  if (madvise(reinterpret_cast<void*>(page_address), end_address - page_address,
              advice) != 0) {
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("madvise failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX) ||     \
        // defined(DART_HOST_OS_MACOS)
