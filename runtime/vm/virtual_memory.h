// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_VIRTUAL_MEMORY_H_
#define VM_VIRTUAL_MEMORY_H_

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

  uword start() const { return region_.start(); }
  uword end() const { return region_.end(); }
  void* address() const { return region_.pointer(); }
  intptr_t size() const { return region_.size(); }

  static void InitOnce();

  bool Contains(uword addr) const {
    return region_.Contains(addr);
  }

  // Commits the virtual memory area.
  bool Commit(bool is_executable) {
    return Commit(start(), size(), is_executable);
  }

  // Changes the protection of the virtual memory area.
  static bool Protect(void* address, intptr_t size, Protection mode);
  bool Protect(Protection mode) {
    return Protect(address(), size(), mode);
  }

  // Reserves a virtual memory segment with size. If a segment of the requested
  // size cannot be allocated NULL is returned.
  static VirtualMemory* Reserve(intptr_t size);

  // Reserves a virtual memory segment with the start address being aligned to
  // the requested power of two.
  static VirtualMemory* ReserveAligned(intptr_t size, intptr_t alignment);

  static intptr_t PageSize() {
    ASSERT(page_size_ != 0);
    ASSERT(Utils::IsPowerOfTwo(page_size_));
    return page_size_;
  }

  static bool InSamePage(uword address0, uword address1);

  // Truncate this virtual memory segment.
  void Truncate(uword new_start, intptr_t size);

 private:
  // Free a sub segment. On operating systems that support it this
  // can give back the virtual memory to the system.
  void FreeSubSegment(void* address, intptr_t size);

  // This constructor is only used internally when reserving new virtual spaces.
  // It does not reserve any virtual address space on its own.
  VirtualMemory(const MemoryRegion& region, void* reserved_pointer) :
      region_(region.pointer(), region.size()),
      reserved_pointer_(reserved_pointer) { }

  // Commit a reserved memory area, so that the memory can be accessed.
  bool Commit(uword addr, intptr_t size, bool is_executable);

  MemoryRegion region_;

  // The original pointer returned by the OS for this virtual memory
  // allocation or NULL. reserved_pointer_ is non-NULL only for
  // platforms where virtual memory subregions cannot be given back to
  // the OS. When non-null it might not coincide with
  // region_.pointer() if the virtual memory region has been
  // truncated.
  void* reserved_pointer_;

  static uword page_size_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(VirtualMemory);
};

}  // namespace dart

#endif  // VM_VIRTUAL_MEMORY_H_
