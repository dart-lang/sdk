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

  // Changes the protection of the virtual memory area.
  static bool Protect(void* address, intptr_t size, Protection mode);
  bool Protect(Protection mode) { return Protect(address(), size(), mode); }

  // Reserves and commits a virtual memory segment with size. If a segment of
  // the requested size cannot be allocated, NULL is returned.
  static VirtualMemory* Allocate(intptr_t size,
                                 bool is_executable,
                                 const char* name);
  static VirtualMemory* AllocateAligned(intptr_t size,
                                        intptr_t alignment,
                                        bool is_executable,
                                        const char* name);

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

  // False for a part of a snapshot added directly to the Dart heap, which
  // belongs to the embedder and must not be deallocated or have its
  // protection status changed by the VM.
  bool vm_owns_region() const { return reserved_.pointer() != NULL; }

  static VirtualMemory* ForImagePage(void* pointer, uword size);

 private:
  // Free a sub segment. On operating systems that support it this
  // can give back the virtual memory to the system. Returns true on success.
  static bool FreeSubSegment(int32_t handle, void* address, intptr_t size);

  // This constructor is only used internally when reserving new virtual spaces.
  // It does not reserve any virtual address space on its own.
  VirtualMemory(const MemoryRegion& region,
                const MemoryRegion& reserved,
                int32_t handle = 0)
      : region_(region), reserved_(reserved), handle_(handle) {}

  MemoryRegion region_;

  // The underlying reservation not yet given back to the OS.
  // Its address might disagree with region_ due to aligned allocations.
  // Its size might disagree with region_ due to Truncate.
  MemoryRegion reserved_;

  int32_t handle_;

  static uword page_size_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(VirtualMemory);
};

}  // namespace dart

#endif  // RUNTIME_VM_VIRTUAL_MEMORY_H_
