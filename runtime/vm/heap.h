// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HEAP_H_
#define VM_HEAP_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/globals.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;
class PageSpace;
class Scavenger;
class VirtualMemory;

DECLARE_FLAG(bool, verbose_gc);
DECLARE_FLAG(bool, gc_at_alloc);

class Heap {
 public:
  enum Space {
    kNew,
    kOld,
    kExecutable
  };

  ~Heap();

  uword Allocate(intptr_t size, Space space) {
    switch (space) {
      case kNew:
        return AllocateNew(size);
      case kOld:
        return AllocateOld(size);
      case kExecutable:
        return AllocateCode(size);
      default:
        UNREACHABLE();
    }
    return 0;
  }

  // Heap contains the specified address.
  bool Contains(uword addr) const;
  bool CodeContains(uword addr) const;

  // Initialize the heap and register it with the isolate.
  static void Init(Isolate* isolate);

  // Verify that all pointers in the heap point to the heap.
  bool Verify() const;

  void IterateOldPointers(ObjectPointerVisitor* visitor);

  // Accessors for inlined allocation in generated code.
  uword TopAddress();
  uword EndAddress();
  static intptr_t new_space_offset() { return OFFSET_OF(Heap, new_space_); }

 private:
  Heap();

  uword AllocateNew(intptr_t size);
  uword AllocateOld(intptr_t size);
  uword AllocateCode(intptr_t size);

  // Allocation is limited to the below sizes.
  static const intptr_t kHeapSize = 512 * MB;
  static const intptr_t kCodeHeapSize = 4 * MB;

  // The different spaces used for allocation.
  Scavenger* new_space_;
  PageSpace* old_space_;
  PageSpace* code_space_;

  DISALLOW_COPY_AND_ASSIGN(Heap);
};


#if defined(DEBUG)
class NoGCScope : public StackResource {
 public:
  NoGCScope();
  ~NoGCScope();
 private:
  Isolate* isolate_;

  DISALLOW_COPY_AND_ASSIGN(NoGCScope);
};
#else  // defined(DEBUG)
class NoGCScope : public ValueObject {
 public:
  NoGCScope() {}
 private:
  DISALLOW_COPY_AND_ASSIGN(NoGCScope);
};
#endif  // defined(DEBUG)

}  // namespace dart

#endif  // VM_HEAP_H_
