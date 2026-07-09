// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/virtual_memory_compressed.h"

#include "platform/utils.h"
#include "vm/flags.h"
#include "vm/lockers.h"
#if defined(DART_HOST_OS_FUCHSIA)
#include <zircon/process.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>
#endif

#if defined(DART_COMPRESSED_POINTERS)

namespace dart {

DEFINE_FLAG(bool,
            pointer_cage,
            false,
            "Pad compressed heaps with guard regions large enough to prevent "
            "any indexed load from reaching outside the compressed heap.");

#if defined(DART_HOST_OS_FUCHSIA)
Cage::Cage() : cache_() {
  const size_t kEffectiveGuardRegionSize =
      FLAG_pointer_cage ? kGuardRegionSize : 0;
  zx_status_t status = zx_vmar_allocate(
      zx_vmar_root_self(),
      ZX_VM_CAN_MAP_READ | ZX_VM_CAN_MAP_WRITE | ZX_VM_CAN_MAP_SPECIFIC |
          ZX_VM_ALIGN_4GB,
      /*offset=*/0,
      /*size=*/kEffectiveGuardRegionSize * 2 + kCompressedHeapSize,
      &outer_vmar_, &outer_addr_);
  if (status != ZX_OK) {
    FATAL("zx_vmar_allocate failed: %s\n", zx_status_get_string(status));
  }
  ASSERT(Utils::IsAligned(outer_addr_, kCompressedHeapAlignment));

  status = zx_vmar_allocate(
      outer_vmar_, ZX_VM_CAN_MAP_READ | ZX_VM_CAN_MAP_WRITE | ZX_VM_SPECIFIC,
      /*offset=*/kEffectiveGuardRegionSize,
      /*size=*/kCompressedHeapSize, &inner_vmar_, &inner_addr_);
  if (status != ZX_OK) {
    FATAL("zx_vmar_allocate failed: %s\n", zx_status_get_string(status));
  }
  ASSERT(Utils::IsAligned(inner_addr_, kCompressedHeapAlignment));
}

Cage::~Cage() {
  cache_.Abandon();
  zx_vmar_destroy(inner_vmar_);
  zx_vmar_destroy(outer_vmar_);
}

VirtualMemory* Cage::Allocate(intptr_t size, intptr_t alignment) {
  const zx_vm_option_t align_flag = Utils::ShiftForPowerOfTwo(alignment)
                                    << ZX_VM_ALIGN_BASE;
  ASSERT((ZX_VM_ALIGN_1KB <= align_flag) && (align_flag <= ZX_VM_ALIGN_4GB));

  zx_handle_t vmo = ZX_HANDLE_INVALID;
  zx_status_t status = zx_vmo_create(size, 0u, &vmo);
  if (status == ZX_ERR_NO_MEMORY) {
    return nullptr;
  } else if (status != ZX_OK) {
    FATAL("zx_vmo_create(0x%lx) failed: %s\n", size,
          zx_status_get_string(status));
  }

  const zx_vm_option_t region_options =
      ZX_VM_PERM_READ | ZX_VM_PERM_WRITE | align_flag;
  uword base;
  status = zx_vmar_map(inner_vmar_, region_options, 0, vmo, 0u, size, &base);
  if (status != ZX_OK) {
    zx_handle_close(vmo);
    return nullptr;
  }
  MemoryRegion region(reinterpret_cast<void*>(base), size);
  VirtualMemory* result = new VirtualMemory(region, region, this);
  zx_handle_close(vmo);
  return result;
}

void Cage::Free(void* address, intptr_t size) {
  zx_status_t status =
      zx_vmar_unmap(inner_vmar_, reinterpret_cast<uword>(address), size);
  if (status != ZX_OK) {
    FATAL("zx_vmar_unmap failed: %s\n", zx_status_get_string(status));
  }
}

void* Cage::GetRegion() {
  return reinterpret_cast<void*>(inner_addr_);
}

#else  // defined(DART_HOST_OS_FUCHSIA)

static uint8_t PageMask(uword page_id) {
  return static_cast<uint8_t>(1 << (page_id % 8));
}

bool Cage::IsPageUsed(uword page_id) {
  if (page_id >= kCompressedHeapNumPages) return false;
  return pages_[page_id / 8] & PageMask(page_id);
}

void Cage::SetPageUsed(uword page_id) {
  ASSERT(page_id < kCompressedHeapNumPages);
  pages_[page_id / 8] |= PageMask(page_id);
}

void Cage::ClearPageUsed(uword page_id) {
  ASSERT(page_id < kCompressedHeapNumPages);
  pages_[page_id / 8] &= ~PageMask(page_id);
}

Cage::Cage() : mutex_(), cache_() {
  const size_t kEffectiveGuardRegionSize =
      FLAG_pointer_cage ? kGuardRegionSize : 0;
  reservation_ = VirtualMemory::Reserve(
      kEffectiveGuardRegionSize * 2 + kCompressedHeapSize,
      kCompressedHeapAlignment);
  if (reservation_ == nullptr) {
#if defined(DART_HOST_OS_WINDOWS)
    int error = GetLastError();
    FATAL("Failed to reserve region for compressed heap: %d", error);
#else
    int error = errno;
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Failed to reserve region for compressed heap: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
#endif
  }
  Init(reinterpret_cast<void*>(reservation_->start() +
                               kEffectiveGuardRegionSize),
       kCompressedHeapSize);
}

void Cage::Init(void* compressed_heap_region, size_t size) {
  pages_ = new uint8_t[kCompressedHeapBitmapSize];
  memset(pages_, 0, kCompressedHeapBitmapSize);
  ASSERT(size > 0);
  ASSERT(size <= kCompressedHeapSize);
  for (intptr_t page_id = size / kCompressedPageSize;
       page_id < kCompressedHeapNumPages; page_id++) {
    SetPageUsed(page_id);
  }
  base_ = reinterpret_cast<uword>(compressed_heap_region);
  size_ = size;
  ASSERT(base_ != 0);
  ASSERT(size_ != 0);
  ASSERT(size_ <= kCompressedHeapSize);
  ASSERT(Utils::IsAligned(base_, kCompressedPageSize));
  ASSERT(Utils::IsAligned(size_, kCompressedPageSize));
  // base_ is not necessarily 4GB-aligned, because on some systems we can't make
  // a large enough reservation to guarantee it. Instead, we have only the
  // weaker property that all addresses in [base_, base_ + size_) have the same
  // same upper 32 bits, which is what we really need for compressed pointers.
  intptr_t mask = ~(kCompressedHeapAlignment - 1);
  ASSERT((base_ & mask) == ((base_ + size_ - 1) & mask));
}

Cage::~Cage() {
  cache_.Clear();
  delete[] pages_;
  base_ = 0;
  size_ = 0;
  pages_ = nullptr;
  minimum_free_page_id_ = 0;
  delete reservation_;
}

void* Cage::GetRegion() {
  return reinterpret_cast<void*>(base_);
}

VirtualMemory* Cage::Allocate(intptr_t size, intptr_t alignment) {
  ASSERT(alignment <= kCompressedHeapAlignment);
  const intptr_t allocated_size = Utils::RoundUp(size, kCompressedPageSize);
  uword pages = allocated_size / kCompressedPageSize;
  uword page_alignment =
      alignment > kCompressedPageSize ? alignment / kCompressedPageSize : 1;
  uword page_id;

  {
    MutexLocker ml(&mutex_);

    // Find a gap with enough empty pages, using the bitmap. Note that reading
    // outside the bitmap range always returns 0, so this loop will terminate.
    page_id = Utils::RoundUp(minimum_free_page_id_, page_alignment);
    for (uword gap = 0;;) {
      if (IsPageUsed(page_id)) {
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
    if (end > kCompressedHeapSize / kCompressedPageSize) {
      return nullptr;
    }

    // Mark all the pages in the bitmap as allocated.
    for (uword i = page_id; i < end; ++i) {
      ASSERT(!IsPageUsed(i));
      SetPageUsed(i);
    }

    // Find the next free page, to speed up subsequent allocations.
    while (IsPageUsed(minimum_free_page_id_)) {
      ++minimum_free_page_id_;
    }
  }

  uword address = base_ + page_id * kCompressedPageSize;
  ASSERT(Utils::IsAligned(address, kCompressedPageSize));
  MemoryRegion region(reinterpret_cast<void*>(address), allocated_size);
  VirtualMemory::Commit(region.pointer(), region.size());
  return new VirtualMemory(region, region, this);
}

void Cage::Free(void* address, intptr_t size) {
  uword start = reinterpret_cast<uword>(address);
  ASSERT(Utils::IsAligned(start, kCompressedPageSize));
  ASSERT(Utils::IsAligned(size, kCompressedPageSize));

  VirtualMemory::Decommit(address, size);

  MutexLocker ml(&mutex_);
  ASSERT(start >= base_);
  uword page_id = (start - base_) / kCompressedPageSize;
  uword end = page_id + size / kCompressedPageSize;
  for (uword i = page_id; i < end; ++i) {
    ClearPageUsed(i);
  }
  if (page_id < minimum_free_page_id_) {
    minimum_free_page_id_ = page_id;
  }
}

#endif  // !defined(DART_HOST_OS_FUCHSIA)

}  // namespace dart

#endif  // defined(DART_COMPRESSED_POINTERS)
