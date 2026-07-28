// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_VIRTUAL_MEMORY_COMPRESSED_H_
#define RUNTIME_VM_VIRTUAL_MEMORY_COMPRESSED_H_

#include "vm/globals.h"
#include "vm/heap/page.h"
#include "vm/memory_region.h"

namespace dart {

#if defined(DART_COMPRESSED_POINTERS)
// int32 index + Simd128 element type -> 32 GB reach from base pointer.
static constexpr intptr_t kGuardRegionSize = 32 * GB;
static constexpr intptr_t kCompressedHeapSize = 4 * GB;
static constexpr intptr_t kCompressedHeapAlignment = 4 * GB;
static constexpr intptr_t kCompressedPageSize = Page::kPageSize;
static constexpr intptr_t kCompressedHeapNumPages =
    kCompressedHeapSize / Page::kPageSize;
static constexpr intptr_t kCompressedHeapBitmapSize =
    kCompressedHeapNumPages / 8;

DECLARE_FLAG(bool, pointer_cage);

// |-----------------------| <- outer_vmar_, reservation_
// | Lower guard, 32 GB    |
// |-----------------------| <- inner_vmar_, base_
// | Compressed heap, 4 GB |
// |-----------------------|
// | Upper guard, 32 GB    |
// |-----------------------|
class Cage : public MallocAllocated {
 public:
  Cage();
  ~Cage();

  VirtualMemory* Allocate(intptr_t size, intptr_t alignment);
  void Free(void* address, intptr_t size);

  void* GetRegion();

  PageCache* cache() { return &cache_; }

 private:
  void Init(void* compressed_heap_region, size_t size);
  bool IsPageUsed(uword page_id);
  void SetPageUsed(uword page_id);
  void ClearPageUsed(uword page_id);

#if defined(DART_HOST_OS_FUCHSIA)
  zx_handle_t outer_vmar_ = ZX_HANDLE_INVALID;
  zx_handle_t inner_vmar_ = ZX_HANDLE_INVALID;
  uword outer_addr_ = 0;
  uword inner_addr_ = 0;
#else
  VirtualMemory* reservation_ = nullptr;
  uword base_ = 0;
  uword size_ = 0;
  uint8_t* pages_ = nullptr;
  uword minimum_free_page_id_ = 0;
  Mutex mutex_;
#endif
  PageCache cache_;
};

#endif  // defined(DART_COMPRESSED_POINTERS)

}  // namespace dart

#endif  // RUNTIME_VM_VIRTUAL_MEMORY_COMPRESSED_H_
