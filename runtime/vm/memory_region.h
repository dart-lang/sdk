// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_MEMORY_REGION_H_
#define VM_MEMORY_REGION_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

// Memory regions are useful for accessing memory with bounds check in
// debug mode. They can be safely passed by value and do not assume ownership
// of the region.
class MemoryRegion : public ValueObject {
 public:
  MemoryRegion() : pointer_(NULL), size_(0) { }
  MemoryRegion(void* pointer, uword size) : pointer_(pointer), size_(size) { }
  MemoryRegion(const MemoryRegion& other) : ValueObject() { *this = other; }
  MemoryRegion& operator=(const MemoryRegion& other) {
    pointer_ = other.pointer_;
    size_ = other.size_;
    return *this;
  }

  void* pointer() const { return pointer_; }
  uword size() const { return size_; }
  uword size_in_bits() const { return size_ * kBitsPerByte; }

  static uword pointer_offset() { return OFFSET_OF(MemoryRegion, pointer_); }

  uword start() const { return reinterpret_cast<uword>(pointer_); }
  uword end() const { return start() + size_; }

  template<typename T> T Load(uword offset) const {
    return *ComputeInternalPointer<T>(offset);
  }

  template<typename T> void Store(uword offset, T value) const {
    *ComputeInternalPointer<T>(offset) = value;
  }

  template<typename T> T* PointerTo(uword offset) const {
    return ComputeInternalPointer<T>(offset);
  }

  bool Contains(uword address) const {
    return (address >= start()) && (address < end());
  }

  void CopyFrom(uword offset, const MemoryRegion& from) const;

  // Compute a sub memory region based on an existing one.
  void Subregion(const MemoryRegion& from, uword offset, uword size) {
    ASSERT(from.size() >= size);
    ASSERT(offset <= (from.size() - size));
    pointer_ = reinterpret_cast<void*>(from.start() + offset);
    size_ = size;
  }

  // Compute an extended memory region based on an existing one.
  void Extend(const MemoryRegion& region, uword extra) {
    pointer_ = region.pointer();
    size_ = (region.size() + extra);
  }

 private:
  template<typename T> T* ComputeInternalPointer(uword offset) const {
    ASSERT(size() >= sizeof(T));
    ASSERT(offset <= size() - sizeof(T));
    return reinterpret_cast<T*>(start() + offset);
  }

  void* pointer_;
  uword size_;
};

}  // namespace dart

#endif  // VM_MEMORY_REGION_H_
