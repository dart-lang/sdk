// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_VIRTUAL_MEMORY_H_
#define RUNTIME_VM_VIRTUAL_MEMORY_H_

#include "platform/utils.h"
#include "vm/flags.h"
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
  intptr_t AliasOffset() const { return alias_.start() - region_.start(); }

  static void Init();
  static void Cleanup();

  // Returns true if dual mapping is enabled.
  static bool DualMappingEnabled();

  bool Contains(uword addr) const { return region_.Contains(addr); }
  bool ContainsAlias(uword addr) const {
    return (AliasOffset() != 0) && alias_.Contains(addr);
  }

  // Changes the protection of the virtual memory area.
  static void Protect(void* address, intptr_t size, Protection mode);
  void Protect(Protection mode) { return Protect(address(), size(), mode); }

  static void DontNeed(void* address, intptr_t size);

  // Reserves and commits a virtual memory segment with size. If a segment of
  // the requested size cannot be allocated, nullptr is returned.
  static VirtualMemory* Allocate(intptr_t size,
                                 bool is_executable,
                                 bool is_compressed,
                                 const char* name) {
    return AllocateAligned(size, PageSize(), is_executable, is_compressed,
                           name);
  }
  static VirtualMemory* AllocateAligned(intptr_t size,
                                        intptr_t alignment,
                                        bool is_executable,
                                        bool is_compressed,
                                        const char* name);

  // Duplicates `this` memory into the `target` memory. This is designed to work
  // on all platforms, including iOS, which doesn't allow creating new
  // executable memory.
  //
  // Assumes
  //   * `this` has RX protection.
  //   * `target` has RW protection, and is at least as large as `this`.
#if !defined(DART_TARGET_OS_FUCHSIA)
  bool DuplicateRX(VirtualMemory* target);
#endif  // !defined(DART_TARGET_OS_FUCHSIA)

  // Returns the cached page size. Use only if Init() has been called.
  static intptr_t PageSize() {
    ASSERT(page_size_ != 0);
    return page_size_;
  }

  static bool InSamePage(uword address0, uword address1);

  // Truncate this virtual memory segment.
  void Truncate(intptr_t new_size);

  // False for a part of a snapshot added directly to the Dart heap, which
  // belongs to the embedder and must not be deallocated or have its
  // protection status changed by the VM.
  bool vm_owns_region() const { return reserved_.pointer() != nullptr; }

  static VirtualMemory* ForImagePage(void* pointer, uword size);

 private:
  static intptr_t CalculatePageSize();

  // Free a sub segment. On operating systems that support it this
  // can give back the virtual memory to the system. Returns true on success.
  static bool FreeSubSegment(void* address, intptr_t size);

  static VirtualMemory* Reserve(intptr_t size, intptr_t alignment);
  static void Commit(void* address, intptr_t size);
  static void Decommit(void* address, intptr_t size);

  // These constructors are only used internally when reserving new virtual
  // spaces. They do not reserve any virtual address space on their own.
  VirtualMemory(const MemoryRegion& region,
                const MemoryRegion& alias,
                const MemoryRegion& reserved)
      : region_(region), alias_(alias), reserved_(reserved) {}

  VirtualMemory(const MemoryRegion& region, const MemoryRegion& reserved)
      : region_(region), alias_(region), reserved_(reserved) {}

  MemoryRegion region_;

  // Optional secondary mapping of region_ to a virtual space with different
  // protection, e.g. allowing code execution.
  MemoryRegion alias_;

  // The underlying reservation not yet given back to the OS.
  // Its address might disagree with region_ due to aligned allocations.
  // Its size might disagree with region_ due to Truncate.
  MemoryRegion reserved_;

  static uword page_size_;
  static VirtualMemory* compressed_heap_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(VirtualMemory);
};

}  // namespace dart

#endif  // RUNTIME_VM_VIRTUAL_MEMORY_H_
