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
#include <sys/syscall.h>
#include <unistd.h>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/heap/pages.h"
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

DECLARE_FLAG(bool, dual_map_code);
DECLARE_FLAG(bool, write_protect_code);

#if defined(TARGET_OS_LINUX)
DECLARE_FLAG(bool, generate_perf_events_symbols);
DECLARE_FLAG(bool, generate_perf_jitdump);
#endif

uword VirtualMemory::page_size_ = 0;

static void unmap(uword start, uword end);

#if defined(DART_COMPRESSED_POINTERS)
static uword compressed_heap_base_ = 0;
static uint8_t* compressed_heap_pages_ = nullptr;
static uword compressed_heap_minimum_free_page_id_ = 0;
static Mutex* compressed_heap_mutex_ = nullptr;

static constexpr intptr_t kCompressedHeapSize = 2 * GB;
static constexpr intptr_t kCompressedHeapAlignment = 4 * GB;
static constexpr intptr_t kCompressedHeapPageSize = kOldPageSize;
static constexpr intptr_t kCompressedHeapNumPages =
    kCompressedHeapSize / kOldPageSize;
static constexpr intptr_t kCompressedHeapBitmapSize =
    kCompressedHeapNumPages / 8;
#endif  // defined(DART_COMPRESSED_POINTERS)

static void* GenericMapAligned(int prot,
                               intptr_t size,
                               intptr_t alignment,
                               intptr_t allocated_size,
                               int map_flags) {
  void* address = mmap(nullptr, allocated_size, prot, map_flags, -1, 0);
  LOG_INFO("mmap(nullptr, 0x%" Px ", %u, ...): %p\n", allocated_size, prot,
           address);
  if (address == MAP_FAILED) {
    return nullptr;
  }

  const uword base = reinterpret_cast<uword>(address);
  const uword aligned_base = Utils::RoundUp(base, alignment);

  unmap(base, aligned_base);
  unmap(aligned_base + size, base + allocated_size);
  return reinterpret_cast<void*>(aligned_base);
}

intptr_t VirtualMemory::CalculatePageSize() {
  const intptr_t page_size = getpagesize();
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

void VirtualMemory::Init() {
#if defined(DART_COMPRESSED_POINTERS)
  if (compressed_heap_pages_ == nullptr) {
    compressed_heap_pages_ = new uint8_t[kCompressedHeapBitmapSize];
    memset(compressed_heap_pages_, 0, kCompressedHeapBitmapSize);
    compressed_heap_base_ = reinterpret_cast<uword>(GenericMapAligned(
        PROT_READ | PROT_WRITE, kCompressedHeapSize, kCompressedHeapAlignment,
        kCompressedHeapSize + kCompressedHeapAlignment,
        MAP_PRIVATE | MAP_ANONYMOUS));
    ASSERT(compressed_heap_base_ != 0);
    ASSERT(Utils::IsAligned(compressed_heap_base_, kCompressedHeapAlignment));
    compressed_heap_mutex_ = new Mutex(NOT_IN_PRODUCT("compressed_heap_mutex"));
  }
#endif  // defined(DART_COMPRESSED_POINTERS)

  if (page_size_ != 0) {
    // Already initialized.
    return;
  }

  page_size_ = CalculatePageSize();

#if defined(DUAL_MAPPING_SUPPORTED)
// Perf is Linux-specific and the flags aren't defined in Product.
#if defined(TARGET_OS_LINUX) && !defined(PRODUCT)
  // Perf interacts strangely with memfds, leading it to sometimes collect
  // garbled return addresses.
  if (FLAG_generate_perf_events_symbols || FLAG_generate_perf_jitdump) {
    LOG_INFO(
        "Dual code mapping disabled to generate perf events or jitdump.\n");
    FLAG_dual_map_code = false;
    return;
  }
#endif

  // Detect dual mapping exec permission limitation on some platforms,
  // such as on docker containers, and disable dual mapping in this case.
  // Also detect for missing support of memfd_create syscall.
  if (FLAG_dual_map_code) {
    intptr_t size = PageSize();
    intptr_t alignment = kOldPageSize;
    VirtualMemory* vm = AllocateAligned(size, alignment, true, "memfd-test");
    if (vm == nullptr) {
      LOG_INFO("memfd_create not supported; disabling dual mapping of code.\n");
      FLAG_dual_map_code = false;
      return;
    }
    void* region = reinterpret_cast<void*>(vm->region_.start());
    void* alias = reinterpret_cast<void*>(vm->alias_.start());
    if (region == alias ||
        mprotect(region, size, PROT_READ) != 0 ||  // Remove PROT_WRITE.
        mprotect(alias, size, PROT_READ | PROT_EXEC) != 0) {  // Add PROT_EXEC.
      LOG_INFO("mprotect fails; disabling dual mapping of code.\n");
      FLAG_dual_map_code = false;
    }
    delete vm;
  }
#endif  // defined(DUAL_MAPPING_SUPPORTED)

#if defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
  FILE* fp = fopen("/proc/sys/vm/max_map_count", "r");
  if (fp != nullptr) {
    size_t max_map_count = 0;
    int count = fscanf(fp, "%zu", &max_map_count);
    fclose(fp);
    if (count == 1) {
      size_t max_heap_pages = FLAG_old_gen_heap_size * MB / kOldPageSize;
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
  unmap(compressed_heap_base_, compressed_heap_base_ + kCompressedHeapSize);
  delete[] compressed_heap_pages_;
  delete compressed_heap_mutex_;
  compressed_heap_base_ = 0;
  compressed_heap_pages_ = nullptr;
  compressed_heap_minimum_free_page_id_ = 0;
  compressed_heap_mutex_ = nullptr;
#endif  // defined(DART_COMPRESSED_POINTERS)
}

bool VirtualMemory::DualMappingEnabled() {
  return FLAG_dual_map_code;
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
// Do not leak file descriptors to child processes.
#if !defined(MFD_CLOEXEC)
#define MFD_CLOEXEC 0x0001U
#endif

// Wrapper to call memfd_create syscall.
static inline int memfd_create(const char* name, unsigned int flags) {
#if !defined(__NR_memfd_create)
  errno = ENOSYS;
  return -1;
#else
  return syscall(__NR_memfd_create, name, flags);
#endif
}

static void* MapAligned(int fd,
                        int prot,
                        intptr_t size,
                        intptr_t alignment,
                        intptr_t allocated_size) {
  void* address = mmap(nullptr, allocated_size, PROT_NONE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  LOG_INFO("mmap(nullptr, 0x%" Px ", PROT_NONE, ...): %p\n", allocated_size,
           address);
  if (address == MAP_FAILED) {
    return nullptr;
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
    return nullptr;
  }
  ASSERT(address == reinterpret_cast<void*>(aligned_base));
  unmap(base, aligned_base);
  unmap(aligned_base + size, base + allocated_size);
  return address;
}
#endif  // defined(DUAL_MAPPING_SUPPORTED)

#if defined(DART_COMPRESSED_POINTERS)
uint8_t PageMask(uword page_id) {
  return static_cast<uint8_t>(1 << (page_id % 8));
}
bool IsCompressedHeapPageUsed(uword page_id) {
  if (page_id >= kCompressedHeapNumPages) return false;
  return compressed_heap_pages_[page_id / 8] & PageMask(page_id);
}
void SetCompressedHeapPageUsed(uword page_id) {
  ASSERT(page_id < kCompressedHeapNumPages);
  compressed_heap_pages_[page_id / 8] |= PageMask(page_id);
}
void ClearCompressedHeapPageUsed(uword page_id) {
  ASSERT(page_id < kCompressedHeapNumPages);
  compressed_heap_pages_[page_id / 8] &= ~PageMask(page_id);
}
static MemoryRegion MapInCompressedHeap(intptr_t size, intptr_t alignment) {
  ASSERT(alignment <= kCompressedHeapAlignment);
  const intptr_t allocated_size = Utils::RoundUp(size, kCompressedHeapPageSize);
  uword pages = allocated_size / kCompressedHeapPageSize;
  uword page_alignment = alignment > kCompressedHeapPageSize
                             ? alignment / kCompressedHeapPageSize
                             : 1;
  MutexLocker ml(compressed_heap_mutex_);

  // Find a gap with enough empty pages, using the bitmap. Note that reading
  // outside the bitmap range always returns 0, so this loop will terminate.
  uword page_id =
      Utils::RoundUp(compressed_heap_minimum_free_page_id_, page_alignment);
  for (uword gap = 0;;) {
    if (IsCompressedHeapPageUsed(page_id)) {
      gap = 0;
      page_id = Utils::RoundUp(page_id + 1, page_alignment);
    } else {
      ++gap;
      if (gap >= pages) {
        page_id += 1 - gap;
        break;
      }
      ++page_id;
    }
  }
  ASSERT(page_id % page_alignment == 0);

  // Make sure we're not trying to allocate past the end of the heap.
  uword end = page_id + pages;
  if (end > kCompressedHeapSize / kCompressedHeapPageSize) {
    return MemoryRegion();
  }

  // Mark all the pages in the bitmap as allocated.
  for (uword i = page_id; i < end; ++i) {
    ASSERT(!IsCompressedHeapPageUsed(i));
    SetCompressedHeapPageUsed(i);
  }

  // Find the next free page, to speed up subsequent allocations.
  while (IsCompressedHeapPageUsed(compressed_heap_minimum_free_page_id_)) {
    ++compressed_heap_minimum_free_page_id_;
  }

  uword address = compressed_heap_base_ + page_id * kCompressedHeapPageSize;
  ASSERT(Utils::IsAligned(address, kCompressedHeapPageSize));
  return MemoryRegion(reinterpret_cast<void*>(address), allocated_size);
}

static void UnmapInCompressedHeap(uword start, uword size) {
  ASSERT(Utils::IsAligned(start, kCompressedHeapPageSize));
  ASSERT(Utils::IsAligned(size, kCompressedHeapPageSize));
  MutexLocker ml(compressed_heap_mutex_);
  ASSERT(start >= compressed_heap_base_);
  uword page_id = (start - compressed_heap_base_) / kCompressedHeapPageSize;
  uword end = page_id + size / kCompressedHeapPageSize;
  for (uword i = page_id; i < end; ++i) {
    ClearCompressedHeapPageUsed(i);
  }
  if (page_id < compressed_heap_minimum_free_page_id_) {
    compressed_heap_minimum_free_page_id_ = page_id;
  }
}

static bool IsInCompressedHeap(uword address) {
  return address >= compressed_heap_base_ &&
         address < compressed_heap_base_ + kCompressedHeapSize;
}
#endif  // defined(DART_COMPRESSED_POINTERS)

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              const char* name) {
  // When FLAG_write_protect_code is active, code memory (indicated by
  // is_executable = true) is allocated as non-executable and later
  // changed to executable via VirtualMemory::Protect.
  //
  // If FLAG_dual_map_code is active, the executable mapping will be mapped RX
  // immediately and never changes protection until it is eventually unmapped.
  ASSERT(Utils::IsAligned(size, PageSize()));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, PageSize()));
  ASSERT(name != nullptr);

#if defined(DART_COMPRESSED_POINTERS)
  if (!is_executable) {
    MemoryRegion region = MapInCompressedHeap(size, alignment);
    if (region.pointer() == nullptr) {
      return nullptr;
    }
    mprotect(region.pointer(), region.size(), PROT_READ | PROT_WRITE);
    return new VirtualMemory(region, region);
  }
#endif  // defined(DART_COMPRESSED_POINTERS)

  const intptr_t allocated_size = size + alignment - PageSize();
#if defined(DUAL_MAPPING_SUPPORTED)
  const bool dual_mapping =
      is_executable && FLAG_write_protect_code && FLAG_dual_map_code;
  if (dual_mapping) {
    int fd = memfd_create(name, MFD_CLOEXEC);
    if (fd == -1) {
      return nullptr;
    }
    if (ftruncate(fd, size) == -1) {
      close(fd);
      return nullptr;
    }
    const int region_prot = PROT_READ | PROT_WRITE;
    void* region_ptr =
        MapAligned(fd, region_prot, size, alignment, allocated_size);
    if (region_ptr == nullptr) {
      close(fd);
      return nullptr;
    }
    // The mapping will be RX and stays that way until it will eventually be
    // unmapped.
    MemoryRegion region(region_ptr, size);
    // DUAL_MAPPING_SUPPORTED is false in TARGET_OS_MACOS and hence support
    // for MAP_JIT is not required here.
    const int alias_prot = PROT_READ | PROT_EXEC;
    void* alias_ptr =
        MapAligned(fd, alias_prot, size, alignment, allocated_size);
    close(fd);
    if (alias_ptr == nullptr) {
      const uword region_base = reinterpret_cast<uword>(region_ptr);
      unmap(region_base, region_base + size);
      return nullptr;
    }
    ASSERT(region_ptr != alias_ptr);
    MemoryRegion alias(alias_ptr, size);
    return new VirtualMemory(region, alias, region);
  }
#endif  // defined(DUAL_MAPPING_SUPPORTED)

  const int prot =
      PROT_READ | PROT_WRITE |
      ((is_executable && !FLAG_write_protect_code) ? PROT_EXEC : 0);

#if defined(DUAL_MAPPING_SUPPORTED)
  // Try to use memfd for single-mapped regions too, so they will have an
  // associated name for memory attribution. Skip if FLAG_dual_map_code is
  // false, which happens if we detected memfd wasn't working in Init above.
  if (FLAG_dual_map_code) {
    int fd = memfd_create(name, MFD_CLOEXEC);
    if (fd == -1) {
      return nullptr;
    }
    if (ftruncate(fd, size) == -1) {
      close(fd);
      return nullptr;
    }
    void* region_ptr = MapAligned(fd, prot, size, alignment, allocated_size);
    close(fd);
    if (region_ptr == nullptr) {
      return nullptr;
    }
    MemoryRegion region(region_ptr, size);
    return new VirtualMemory(region, region);
  }
#endif

  int map_flags = MAP_PRIVATE | MAP_ANONYMOUS;
#if (defined(HOST_OS_MACOS) && !defined(HOST_OS_IOS))
  if (is_executable && IsAtLeastOS10_14()) {
    map_flags |= MAP_JIT;
  }
#endif  // defined(HOST_OS_MACOS)
  void* address =
      GenericMapAligned(prot, size, alignment, allocated_size, map_flags);
  if (address == MAP_FAILED) {
    return nullptr;
  }

  MemoryRegion region(reinterpret_cast<void*>(address), size);
  return new VirtualMemory(region, region);
}

VirtualMemory::~VirtualMemory() {
#if defined(DART_COMPRESSED_POINTERS)
  if (IsInCompressedHeap(reserved_.start())) {
    UnmapInCompressedHeap(reserved_.start(), reserved_.size());
    return;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  if (vm_owns_region()) {
    unmap(reserved_.start(), reserved_.end());
    const intptr_t alias_offset = AliasOffset();
    if (alias_offset != 0) {
      unmap(reserved_.start() + alias_offset, reserved_.end() + alias_offset);
    }
  }
}

bool VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
  const uword start = reinterpret_cast<uword>(address);
#if defined(DART_COMPRESSED_POINTERS)
  // Don't free the sub segment if it's managed by the compressed pointer heap.
  if (IsInCompressedHeap(start)) {
    return false;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  unmap(start, start + size);
  return true;
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread == nullptr || thread->IsMutatorThread() ||
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
    FATAL2("mprotect error: %d (%s)", error,
           Utils::StrError(error, error_buf, kBufferSize));
  }
  LOG_INFO("mprotect(0x%" Px ", 0x%" Px ", %u) ok\n", page_address,
           end_address - page_address, prot);
}

}  // namespace dart

#endif  // defined(HOST_OS_ANDROID ... HOST_OS_LINUX ... HOST_OS_MACOS)
