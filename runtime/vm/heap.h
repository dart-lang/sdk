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
class ObjectSet;
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

  enum GCReason {
    kNewSpace,
    kPromotionFailure,
    kOldSpace,
    kCodeSpace,
    kFull,
    kGCAtAlloc,
    kGCTestCase,
  };

  // Default allocation sizes in MB for the old gen and code heaps.
  static const intptr_t kHeapSizeInMB = 512;
  static const intptr_t kCodeHeapSizeInMB = 18;

  ~Heap();

  uword Allocate(intptr_t size, Space space) {
    ASSERT(!read_only_);
    switch (space) {
      case kNew:
        // Do not attempt to allocate very large objects in new space.
        if (!PageSpace::IsPageAllocatableSize(size)) {
          return AllocateOld(size, HeapPage::kData);
        }
        return AllocateNew(size);
      case kOld:
        return AllocateOld(size, HeapPage::kData);
      case kCode:
        return AllocateOld(size, HeapPage::kExecutable);
      default:
        UNREACHABLE();
    }
    return 0;
  }

  uword TryAllocate(intptr_t size, Space space) {
    ASSERT(!read_only_);
    switch (space) {
      case kNew:
        return new_space_->TryAllocate(size);
      case kOld:
        return old_space_->TryAllocate(size, HeapPage::kData);
      case kCode:
        return old_space_->TryAllocate(size, HeapPage::kExecutable);
      default:
        UNREACHABLE();
    }
    return 0;
  }

  // Heap contains the specified address.
  bool Contains(uword addr) const;
  bool NewContains(uword addr) const;
  bool OldContains(uword addr) const;
  bool CodeContains(uword addr) const;
  bool StubCodeContains(uword addr) const;

  // Visit all pointers.
  void IteratePointers(ObjectPointerVisitor* visitor);

  // Visit all pointers in the space.
  void IterateNewPointers(ObjectPointerVisitor* visitor);
  void IterateOldPointers(ObjectPointerVisitor* visitor);

  // Visit all objects.
  void IterateObjects(ObjectVisitor* visitor);

  // Visit all object in the space.
  void IterateNewObjects(ObjectVisitor* visitor);
  void IterateOldObjects(ObjectVisitor* visitor);

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

  // Enables growth control on the page space heaps.  This should be
  // called before any user code is executed.
  void EnableGrowthControl();

  // Protect access to the heap.
  void WriteProtect(bool read_only);

  // Accessors for inlined allocation in generated code.
  uword TopAddress();
  uword EndAddress();
  static intptr_t new_space_offset() { return OFFSET_OF(Heap, new_space_); }

  // Initialize the heap and register it with the isolate.
  static void Init(Isolate* isolate);

  // Verify that all pointers in the heap point to the heap.
  bool Verify() const;

  // Print heap sizes.
  void PrintSizes() const;

  // Returns the [lowest, highest) addresses in the heap.
  void StartEndAddress(uword* start, uword* end) const;

  ObjectSet* CreateAllocatedObjectSet() const;

  // Generates a profile of the current and VM isolate heaps.
  void Profile(Dart_HeapProfileWriteCallback callback, void* stream) const;

  static const char* GCReasonToString(GCReason gc_reason);

  // Associates a peer with an object.  If an object has a peer, it is
  // replaced.  A value of NULL disassociate an object from its peer.
  void SetPeer(RawObject* raw_obj, void* peer);

  // Retrieves the peer associated with an object.  Returns NULL if
  // there is no association.
  void* GetPeer(RawObject* raw_obj);

  // Returns the number of objects with a peer.
  int64_t PeerCount() const;

 private:
  Heap();

  uword AllocateNew(intptr_t size);
  uword AllocateOld(intptr_t size, HeapPage::PageType type);

  // The different spaces used for allocation.
  Scavenger* new_space_;
  PageSpace* old_space_;

  // This heap is in read-only mode: No allocation is allowed.
  bool read_only_;

  friend class GCTestHelper;
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
