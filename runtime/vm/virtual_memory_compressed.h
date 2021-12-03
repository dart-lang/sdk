// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_VIRTUAL_MEMORY_COMPRESSED_H_
#define RUNTIME_VM_VIRTUAL_MEMORY_COMPRESSED_H_

#include "vm/globals.h"
#include "vm/heap/pages.h"
#include "vm/memory_region.h"

namespace dart {

#if defined(DART_COMPRESSED_POINTERS)
static constexpr intptr_t kCompressedHeapSize = 4 * GB;
static constexpr intptr_t kCompressedHeapAlignment = 4 * GB;
static constexpr intptr_t kCompressedHeapPageSize = kOldPageSize;
static constexpr intptr_t kCompressedHeapNumPages =
    kCompressedHeapSize / kOldPageSize;
static constexpr intptr_t kCompressedHeapBitmapSize =
    kCompressedHeapNumPages / 8;

#if !defined(DART_HOST_OS_FUCHSIA)
#define DART_COMPRESSED_HEAP
#endif  // !defined(DART_HOST_OS_FUCHSIA)
#endif  // defined(DART_COMPRESSED_POINTERS)

#if defined(DART_COMPRESSED_HEAP)

// Utilities for allocating memory within a contiguous region of memory, for use
// with compressed pointers.
class VirtualMemoryCompressedHeap : public AllStatic {
 public:
  // Initializes the compressed heap. The callee must allocate a region of
  // kCompressedHeapSize bytes, aligned to kCompressedHeapSize.
  static void Init(void* compressed_heap_region, size_t size);

  // Cleans up the compressed heap. The callee is responsible for freeing the
  // region's memory.
  static void Cleanup();

  // Allocates a segment of the compressed heap with the given size. Returns a
  // heap memory region if a large enough free segment can't be found.
  static MemoryRegion Allocate(intptr_t size, intptr_t alignment);

  // Frees a segment.
  static void Free(void* address, intptr_t size);

  // Returns whether the address is within the compressed heap.
  static bool Contains(void* address);

  // Returns a pointer to the compressed heap region.
  static void* GetRegion();

 private:
  static bool IsPageUsed(uword page_id);
  static void SetPageUsed(uword page_id);
  static void ClearPageUsed(uword page_id);

  static uword base_;
  static uword size_;
  static uint8_t* pages_;
  static uword minimum_free_page_id_;
  static Mutex* mutex_;
};

#endif  // defined(DART_COMPRESSED_HEAP)

}  // namespace dart

#endif  // RUNTIME_VM_VIRTUAL_MEMORY_COMPRESSED_H_
