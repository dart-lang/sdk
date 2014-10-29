// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_VERIFIED_MEMORY_H_
#define VM_VERIFIED_MEMORY_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/virtual_memory.h"

namespace dart {

#if defined(DEBUG)
DECLARE_FLAG(bool, verified_mem);
DECLARE_FLAG(int, verified_mem_max_reserve_mb);
#endif


// A wrapper around VirtualMemory for verifying that a particular class of
// memory writes are only performed through a particular interface.
//
// The main use case is verifying that storing pointers into objects is only
// performed by code aware of the GC write barrier.
//
// NOTE: Verification is enabled only if 'verified_mem' is true, and this flag
// only exists in DEBUG builds.
class VerifiedMemory : public AllStatic {
 public:
  // Reserves a block of memory for which all methods in this class may
  // be called. Returns NULL if out of memory.
  static VirtualMemory* Reserve(intptr_t size) {
    return enabled() ? ReserveInternal(size) : VirtualMemory::Reserve(size);
  }

  // Verifies that [start, start + size) has only been mutated through
  // methods in this class (or explicitly accepted by calling Accept).
  static void Verify(uword start, intptr_t size) {
    if (!enabled()) return;
    ASSERT(size <= offset());
    ASSERT(memcmp(reinterpret_cast<void*>(start + offset()),
                  reinterpret_cast<void*>(start),
                  size) == 0);
  }

  // Assigns value to *ptr after verifying previous content at that location.
  template<typename T>
  static void Write(T* ptr, const T& value) {
    if (enabled()) {
      uword addr = reinterpret_cast<uword>(ptr);
      Verify(addr, sizeof(T));
      T* offset_ptr = reinterpret_cast<T*>(addr + offset());
      *offset_ptr = value;
    }
    *ptr = value;
  }

  // Accepts the current state of [start, start + size), even if it has been
  // mutated by other means.
  static void Accept(uword start, intptr_t size) {
    if (!enabled()) return;
    ASSERT(size <= offset());
    memmove(reinterpret_cast<void*>(start + offset()),
            reinterpret_cast<void*>(start),
            size);
  }

 private:
#if defined(DEBUG)
  static bool enabled() { return FLAG_verified_mem; }
  static intptr_t offset() { return FLAG_verified_mem_max_reserve_mb * MB; }
  static VirtualMemory* ReserveInternal(intptr_t size);
#else
  // In release mode, most code in this class is optimized away.
  static bool enabled() { return false; }
  static intptr_t offset() { UNREACHABLE(); return -1; }
  static VirtualMemory* ReserveInternal(intptr_t size) {
    UNREACHABLE();
    return NULL;
  }
#endif

  friend class Assembler;  // To use enabled/offset when generating code.
};

}  // namespace dart

#endif  // VM_VERIFIED_MEMORY_H_
