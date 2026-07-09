// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_VIRTUAL_MEMORY_H_
#define RUNTIME_BIN_VIRTUAL_MEMORY_H_

#include "platform/allocation.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

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

  void release() {
    address_ = nullptr;
    size_ = 0;
  }

  uword start() const { return reinterpret_cast<uword>(address_); }
  uword end() const { return reinterpret_cast<uword>(address_) + size_; }
  void* address() const { return address_; }
  intptr_t size() const { return size_; }

  // Changes the protection of the virtual memory area.
  static void Protect(void* address, intptr_t size, Protection mode);
  void Protect(Protection mode) { return Protect(address(), size(), mode); }

  // Reserves and commits a virtual memory segment with size. If a segment of
  // the requested size cannot be allocated, nullptr is returned.
  static VirtualMemory* Allocate(intptr_t size,
                                 bool is_executable,
                                 const char* name);

  static void Init() { page_size_ = CalculatePageSize(); }

  // Returns the cached page size. Use only if Init() has been called.
  static intptr_t PageSize() {
    ASSERT(page_size_ != 0);
    return page_size_;
  }

 private:
  static intptr_t CalculatePageSize();

  // These constructors are only used internally when reserving new virtual
  // spaces. They do not reserve any virtual address space on their own.
  VirtualMemory(void* address, size_t size) : address_(address), size_(size) {}

  void* address_;
  size_t size_;

  static uword page_size_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(VirtualMemory);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_VIRTUAL_MEMORY_H_
