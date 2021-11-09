// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/virtual_memory_compressed.h"

#include "platform/utils.h"

#if defined(DART_COMPRESSED_HEAP)

namespace dart {

uword VirtualMemoryCompressedHeap::base_ = 0;
uword VirtualMemoryCompressedHeap::size_ = 0;
uint8_t* VirtualMemoryCompressedHeap::pages_ = nullptr;
uword VirtualMemoryCompressedHeap::minimum_free_page_id_ = 0;
Mutex* VirtualMemoryCompressedHeap::mutex_ = nullptr;

uint8_t PageMask(uword page_id) {
  return static_cast<uint8_t>(1 << (page_id % 8));
}

bool VirtualMemoryCompressedHeap::IsPageUsed(uword page_id) {
  if (page_id >= kCompressedHeapNumPages) return false;
  return pages_[page_id / 8] & PageMask(page_id);
}

void VirtualMemoryCompressedHeap::SetPageUsed(uword page_id) {
  ASSERT(page_id < kCompressedHeapNumPages);
  pages_[page_id / 8] |= PageMask(page_id);
}

void VirtualMemoryCompressedHeap::ClearPageUsed(uword page_id) {
  ASSERT(page_id < kCompressedHeapNumPages);
  pages_[page_id / 8] &= ~PageMask(page_id);
}

void VirtualMemoryCompressedHeap::Init(void* compressed_heap_region,
                                       size_t size) {
  pages_ = new uint8_t[kCompressedHeapBitmapSize];
  memset(pages_, 0, kCompressedHeapBitmapSize);
  ASSERT(size > 0);
  ASSERT(size <= kCompressedHeapSize);
  for (intptr_t page_id = size / kCompressedHeapPageSize;
       page_id < kCompressedHeapNumPages; page_id++) {
    SetPageUsed(page_id);
  }
  base_ = reinterpret_cast<uword>(compressed_heap_region);
  size_ = size;
  ASSERT(base_ != 0);
  ASSERT(size_ != 0);
  ASSERT(size_ <= kCompressedHeapSize);
  ASSERT(Utils::IsAligned(base_, kCompressedHeapPageSize));
  ASSERT(Utils::IsAligned(size_, kCompressedHeapPageSize));
  // base_ is not necessarily 4GB-aligned, because on some systems we can't make
  // a large enough reservation to guarantee it. Instead, we have only the
  // weaker property that all addresses in [base_, base_ + size_) have the same
  // same upper 32 bits, which is what we really need for compressed pointers.
  intptr_t mask = ~(kCompressedHeapAlignment - 1);
  ASSERT((base_ & mask) == ((base_ + size_ - 1) & mask));
  mutex_ = new Mutex(NOT_IN_PRODUCT("compressed_heap_mutex"));
}

void VirtualMemoryCompressedHeap::Cleanup() {
  delete[] pages_;
  delete mutex_;
  base_ = 0;
  size_ = 0;
  pages_ = nullptr;
  minimum_free_page_id_ = 0;
  mutex_ = nullptr;
}

void* VirtualMemoryCompressedHeap::GetRegion() {
  return reinterpret_cast<void*>(base_);
}

MemoryRegion VirtualMemoryCompressedHeap::Allocate(intptr_t size,
                                                   intptr_t alignment) {
  ASSERT(alignment <= kCompressedHeapAlignment);
  const intptr_t allocated_size = Utils::RoundUp(size, kCompressedHeapPageSize);
  uword pages = allocated_size / kCompressedHeapPageSize;
  uword page_alignment = alignment > kCompressedHeapPageSize
                             ? alignment / kCompressedHeapPageSize
                             : 1;
  MutexLocker ml(mutex_);

  // Find a gap with enough empty pages, using the bitmap. Note that reading
  // outside the bitmap range always returns 0, so this loop will terminate.
  uword page_id = Utils::RoundUp(minimum_free_page_id_, page_alignment);
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
  if (end > kCompressedHeapSize / kCompressedHeapPageSize) {
    return MemoryRegion();
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

  uword address = base_ + page_id * kCompressedHeapPageSize;
  ASSERT(Utils::IsAligned(address, kCompressedHeapPageSize));
  return MemoryRegion(reinterpret_cast<void*>(address), allocated_size);
}

void VirtualMemoryCompressedHeap::Free(void* address, intptr_t size) {
  uword start = reinterpret_cast<uword>(address);
  ASSERT(Utils::IsAligned(start, kCompressedHeapPageSize));
  ASSERT(Utils::IsAligned(size, kCompressedHeapPageSize));
  MutexLocker ml(mutex_);
  ASSERT(start >= base_);
  uword page_id = (start - base_) / kCompressedHeapPageSize;
  uword end = page_id + size / kCompressedHeapPageSize;
  for (uword i = page_id; i < end; ++i) {
    ClearPageUsed(i);
  }
  if (page_id < minimum_free_page_id_) {
    minimum_free_page_id_ = page_id;
  }
}

bool VirtualMemoryCompressedHeap::Contains(void* address) {
  return (reinterpret_cast<uword>(address) - base_) < size_;
}

}  // namespace dart

#endif  // defined(DART_COMPRESSED_HEAP)
