// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_VIRTUAL_MEMORY_H_
#define RUNTIME_VM_VIRTUAL_MEMORY_H_

#include "platform/utils.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/memory_region.h"

#if defined(DART_HOST_OS_FUCHSIA)
#include <zircon/types.h>
#endif

namespace dart {

#if defined(DART_HOST_OS_IOS) && !defined(DART_PRECOMPILED_RUNTIME) &&         \
    !defined(DART_HOST_OS_SIMULATOR)
// We might need RX workarounds to enable JIT on physical iOS devices.
//
// Older iOS versions allow mprotect to flip between RW <-> RX on code
// pages as long as debugger is connected to the process.
//
// Newever iOS versions do not allow that, but we have discovered that
// dual mapping RX mapping as RW mapping via |vm_remap| and touching original RX
// mapping from the debugger allows us to write code via RW page and then
// execute it via original RX page.
//
// Thus our RX workarounds consist of two parts:
//
// * Dual mapping of executable pages (see ShouldDualMapExecutablePages and
//   OffsetToExecutableAlias).
// * Debugger integration point (see NOTIFY_DEBUGGER_ABOUT_RX_PAGES).
//
// Note: we only use this on newer iOS versions because dual mapping causes
// kernel crashes on M4 Mac OS X devices.
#define DART_ENABLE_RX_WORKAROUNDS
#endif

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

  DART_FORCE_INLINE intptr_t OffsetToExecutableAlias() const {
#if defined(DART_ENABLE_RX_WORKAROUNDS)
    return executable_alias_.start() - region_.start();
#else
    return 0;
#endif
  }

#if defined(DART_HOST_OS_FUCHSIA)
  static void Init(zx_handle_t vmex_resource);
#else
  static void Init();
#endif
  static void Cleanup();

  DART_FORCE_INLINE static bool ShouldDualMapExecutablePages() {
#if defined(DART_ENABLE_RX_WORKAROUNDS)
    return should_dual_map_executable_pages_;
#else
    return false;
#endif
  }

  // Write protect a chunk of machine code which is currently writable.
  DART_FORCE_INLINE static void WriteProtectCode(void* address, intptr_t size) {
    Protect(address, size,
            ShouldDualMapExecutablePages() ? kReadOnly : kReadExecute);
  }
  DART_FORCE_INLINE void WriteProtectCode() const {
    WriteProtectCode(address(), size());
  }

  bool Contains(uword addr) const { return region_.Contains(addr); }

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

  // Duplicates `this` memory into the `target` memory using Mach specific
  // vm_remap call.
  //
  // This exists specifically to clone executable pages originating from
  // codesigned binaries on iOS and Mac OS X.
  //
  // IMPORTANT: using this to remap unsigned RX pages results in kernel
  // crashes in certain combinations of hardware and kernel version and thus
  // should be avoided.
  //
  // Assumes
  //   * `this` has RX protection and is codesigned.
  //   * `target` has RW protection, and is at least as large as `this`.
#if defined(DART_HOST_OS_MACOS)
  bool DuplicateRX(VirtualMemory* target);
#endif  // defined(DART_HOST_OS_MACOS)

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

#if defined(DART_ENABLE_RX_WORKAROUNDS)
  // These constructors are only used internally when reserving new virtual
  // spaces. They do not reserve any virtual address space on their own.
  VirtualMemory(const MemoryRegion& region,
                const MemoryRegion& executable_alias,
                const MemoryRegion& reserved)
      : region_(region),
        executable_alias_(executable_alias),
        reserved_(reserved) {}
#endif

  VirtualMemory(const MemoryRegion& region, const MemoryRegion& reserved)
      : region_(region),
#if defined(DART_ENABLE_RX_WORKAROUNDS)
        executable_alias_(region),
#endif
        reserved_(reserved) {
  }

  MemoryRegion region_;

#if defined(DART_ENABLE_RX_WORKAROUNDS)
  // For dual mapped RW+RX pages this will contain address of the executable
  // alias. Objects will be allocated in the writable mapping but entry points
  // will point into executable (RX) alias.
  MemoryRegion executable_alias_;
#endif

  // The underlying reservation not yet given back to the OS.
  // Its address might disagree with region_ due to aligned allocations.
  // Its size might disagree with region_ due to Truncate.
  MemoryRegion reserved_;

  static uword page_size_;
  static VirtualMemory* compressed_heap_;

#if defined(DART_ENABLE_RX_WORKAROUNDS)
  static bool should_dual_map_executable_pages_;
#endif

  DISALLOW_IMPLICIT_CONSTRUCTORS(VirtualMemory);
};

}  // namespace dart

#endif  // RUNTIME_VM_VIRTUAL_MEMORY_H_
