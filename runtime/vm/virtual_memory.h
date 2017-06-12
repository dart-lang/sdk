// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_VIRTUAL_MEMORY_H_
#define RUNTIME_VM_VIRTUAL_MEMORY_H_

#include "platform/utils.h"
#include "vm/globals.h"
#include "vm/memory_region.h"

namespace dart {

class VirtualMemory {
 public:
  enum Protection {
    kNoAccess,
    kReadOnly,
    kReadWrite,
    kReadExecute,
    kReadWriteExecute
  };

  // The reserved memory is unmapped on destruction.
  ~VirtualMemory();

  int32_t handle() const { return handle_; }
  uword start() const { return region_.start(); }
  uword end() const { return region_.end(); }
  void* address() const { return region_.pointer(); }
  intptr_t size() const { return region_.size(); }

  static void InitOnce();

  bool Contains(uword addr) const { return region_.Contains(addr); }

  // Commits the virtual memory area, which is guaranteed to be zeroed. Returns
  // true on success and false on failure (e.g., out-of-memory).
  bool Commit(bool is_executable) {
    return Commit(start(), size(), is_executable);
  }

  // Changes the protection of the virtual memory area.
  static bool Protect(void* address, intptr_t size, Protection mode);
  bool Protect(Protection mode) { return Protect(address(), size(), mode); }

  // Reserves a virtual memory segment with size. If a segment of the requested
  // size cannot be allocated NULL is returned.
  static VirtualMemory* Reserve(intptr_t size) { return ReserveInternal(size); }

  static intptr_t PageSize() {
    ASSERT(page_size_ != 0);
    ASSERT(Utils::IsPowerOfTwo(page_size_));
    return page_size_;
  }

  static bool InSamePage(uword address0, uword address1);

  // Truncate this virtual memory segment. If try_unmap is false, the
  // memory beyond the new end is still accessible, but will be returned
  // upon destruction.
  void Truncate(intptr_t new_size, bool try_unmap = true);

  // Commit a reserved memory area, so that the memory can be accessed.
  bool Commit(uword addr, intptr_t size, bool is_executable);

  bool vm_owns_region() const { return vm_owns_region_; }

  static VirtualMemory* ForImagePage(void* pointer, uword size);

 private:
  static VirtualMemory* ReserveInternal(intptr_t size);

  // Free a sub segment. On operating systems that support it this
  // can give back the virtual memory to the system. Returns true on success.
  static bool FreeSubSegment(int32_t handle, void* address, intptr_t size);

  // This constructor is only used internally when reserving new virtual spaces.
  // It does not reserve any virtual address space on its own.
  explicit VirtualMemory(const MemoryRegion& region, int32_t handle = 0)
      : region_(region.pointer(), region.size()),
        reserved_size_(region.size()),
        handle_(handle),
        vm_owns_region_(true) {}

  MemoryRegion region_;

  // The size of the underlying reservation not yet given back to the OS.
  // Its start coincides with region_, but its size might not, due to Truncate.
  intptr_t reserved_size_;

  int32_t handle_;

  static uword page_size_;

  // False for a part of a snapshot added directly to the Dart heap, which
  // belongs to the embedder and must not be deallocated or have its
  // protection status changed by the VM.
  bool vm_owns_region_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(VirtualMemory);
};

}  // namespace dart

#endif  // RUNTIME_VM_VIRTUAL_MEMORY_H_
