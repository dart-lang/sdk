// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HEAP_H_
#define VM_HEAP_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/pages.h"
#include "vm/scavenger.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;
class VirtualMemory;

DECLARE_FLAG(bool, verbose_gc);
DECLARE_FLAG(bool, verify_before_gc);
DECLARE_FLAG(bool, verify_after_gc);
DECLARE_FLAG(bool, gc_at_alloc);

class Heap {
 public:
  enum Space {
    kNew,
    kOld,
    kCode,
  };

  enum ApiCallbacks {
    kIgnoreApiCallbacks,
    kInvokeApiCallbacks
  };

  // Default allocation sizes in MB for the old gen and code heaps.
  static const intptr_t kHeapSizeInMB = 512;
  static const intptr_t kCodeHeapSizeInMB = 10;

  ~Heap();

  uword Allocate(intptr_t size, Space space) {
    switch (space) {
      case kNew:
        // Do not attempt to allocate very large objects in new space.
        if (!PageSpace::IsPageAllocatableSize(size)) {
          return AllocateOld(size);
        }
        return AllocateNew(size);
      case kOld:
        return AllocateOld(size);
      case kCode:
        return AllocateCode(code_space_, size);
      default:
        UNREACHABLE();
    }
    return 0;
  }

  uword TryAllocate(intptr_t size, Space space) {
    switch (space) {
      case kNew:
        return new_space_->TryAllocate(size);
      case kOld:
        return old_space_->TryAllocate(size);
      case kCode:
        return code_space_->TryAllocate(size);
      default:
        UNREACHABLE();
    }
    return 0;
  }

  // Heap contains the specified address.
  bool Contains(uword addr) const;
  bool CodeContains(uword addr) const;
  bool StubCodeContains(uword addr) const;

  // Visit all pointers in the space.
  void IterateNewPointers(ObjectPointerVisitor* visitor);
  void IterateOldPointers(ObjectPointerVisitor* visitor);
  void IterateCodePointers(ObjectPointerVisitor* visitor);
  void IterateStubCodePointers(ObjectPointerVisitor* visitor);

  // Find an object by visiting all pointers in the specified heap space,
  // the 'visitor' is used to determine if an object is found or not.
  // The 'visitor' function should be set up to return true if the
  // object is found, traversal through the heap space stops at that
  // point.
  // The 'visitor' function should return false if the object is not found,
  // traversal through the heap space continues.
  RawInstructions* FindObjectInCodeSpace(FindObjectVisitor* visitor);
  RawInstructions* FindObjectInStubCodeSpace(FindObjectVisitor* visitor);

  void CollectGarbage(Space space);
  void CollectGarbage(Space space, ApiCallbacks api_callbacks);
  void CollectAllGarbage();

  // Accessors for inlined allocation in generated code.
  uword TopAddress();
  uword EndAddress();
  static intptr_t new_space_offset() { return OFFSET_OF(Heap, new_space_); }

  // Initialize the heap and register it with the isolate.
  static void Init(Isolate* isolate);

  // Verify that all pointers in the heap point to the heap.
  bool Verify() const;

 private:
  Heap();

  uword AllocateNew(intptr_t size);
  uword AllocateOld(intptr_t size);
  uword AllocateCode(PageSpace* space, intptr_t size);

  // The different spaces used for allocation.
  Scavenger* new_space_;
  PageSpace* old_space_;
  PageSpace* code_space_;
  PageSpace* stub_code_space_;

  DISALLOW_COPY_AND_ASSIGN(Heap);
};


#if defined(DEBUG)
class NoGCScope : public StackResource {
 public:
  NoGCScope();
  ~NoGCScope();
 private:
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
