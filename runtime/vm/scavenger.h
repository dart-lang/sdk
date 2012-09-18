// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SCAVENGER_H_
#define VM_SCAVENGER_H_

#include <map>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/raw_object.h"
#include "vm/virtual_memory.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class Heap;
class Isolate;
class ScavengerVisitor;

DECLARE_FLAG(bool, gc_at_alloc);

class Scavenger {
 public:
  Scavenger(Heap* heap, intptr_t max_capacity, uword object_alignment);
  ~Scavenger();

  // Check whether this Scavenger contains this address.
  // During scavenging both the to and from spaces contain "legal" objects.
  // During a scavenge this function only returns true for addresses that will
  // be part of the surviving objects.
  bool Contains(uword addr) const {
    // No reasonable algorithm should be checking for objects in from space. At
    // least unless it is debugging code. This might need to be relaxed later,
    // but currently it helps prevent dumb bugs.
    ASSERT(!from_->Contains(addr));
    return to_->Contains(addr);
  }

  uword TryAllocate(intptr_t size) {
    ASSERT(Utils::IsAligned(size, kObjectAlignment));
#if defined(DEBUG)
    if (FLAG_gc_at_alloc && !scavenging_) {
      Scavenge("debugging");
    }
#endif
    uword result = top_;
    intptr_t remaining = end_ - top_;
    if (remaining < size) {
      return 0;
    }
    ASSERT(to_->Contains(result));
    ASSERT((result & kObjectAlignmentMask) == object_alignment_);

    top_ += size;
    ASSERT(to_->Contains(top_) || (top_ == to_->end()));
    return result;
  }

  // Collect the garbage in this scavenger.
  void Scavenge(const char* gc_reason);
  void Scavenge(bool invoke_api_callbacks, const char* gc_reason);

  // Accessors to generate code for inlined allocation.
  uword* TopAddress() { return &top_; }
  uword* EndAddress() { return &end_; }
  static intptr_t top_offset() { return OFFSET_OF(Scavenger, top_); }
  static intptr_t end_offset() { return OFFSET_OF(Scavenger, end_); }

  intptr_t in_use() const { return (top_ - FirstObjectStart()); }
  intptr_t capacity() const { return space_->size(); }

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  void StartEndAddress(uword* start, uword* end) const {
    *start = to_->start();
    *end = to_->end();
  }

  // Returns true if the last scavenge had a promotion failure.
  bool HadPromotionFailure() {
    return had_promotion_failure_;
  }

  void WriteProtect(bool read_only);

  void SetPeer(RawObject* raw_obj, void* peer);

  void* GetPeer(RawObject* raw_obj);

  int64_t PeerCount() const;

 private:
  uword FirstObjectStart() const { return to_->start() | object_alignment_; }
  void Prologue(Isolate* isolate, bool invoke_api_callbacks);
  void IterateStoreBuffers(Isolate* isolate, ScavengerVisitor* visitor);
  void IterateRoots(Isolate* isolate,
                    ScavengerVisitor* visitor,
                    bool visit_prologue_weak_persistent_handles);
  void IterateWeakProperties(Isolate* isolate, ScavengerVisitor* visitor);
  void IterateWeakReferences(Isolate* isolate, ScavengerVisitor* visitor);
  void IterateWeakRoots(Isolate* isolate,
                        HandleVisitor* visitor,
                        bool visit_prologue_weak_persistent_handles);
  void ProcessToSpace(ScavengerVisitor* visitor);
  uword ProcessWeakProperty(RawWeakProperty* raw_weak,
                            ScavengerVisitor* visitor);
  void Epilogue(Isolate* isolate, bool invoke_api_callbacks);

  bool IsUnreachable(RawObject** p);

  // During a scavenge we need to remember the promoted objects.
  // This is implemented as a stack of objects at the end of the to space. As
  // object sizes are always greater than sizeof(uword) and promoted objects do
  // not consume space in the to space they leave enough room for this stack.
  void PushToPromotedStack(uword addr) {
    end_ -= sizeof(addr);
    ASSERT(end_ > top_);
    *reinterpret_cast<uword*>(end_) = addr;
  }
  uword PopFromPromotedStack() {
    uword result = *reinterpret_cast<uword*>(end_);
    end_ += sizeof(result);
    ASSERT(end_ <= to_->end());
    return result;
  }
  bool PromotedStackHasMore() const {
    return end_ < to_->end();
  }

  void ProcessPeerReferents();

  VirtualMemory* space_;
  MemoryRegion* to_;
  MemoryRegion* from_;

  Heap* heap_;

  typedef std::map<RawObject*, void*> PeerTable;
  PeerTable peer_table_;

  // Current allocation top and end. These values are being accessed directly
  // from generated code.
  uword top_;
  uword end_;

  // A pointer to the first unscanned object.  Scanning completes when
  // this value meets the allocation top.
  uword resolved_top_;

  // Objects below this address have survived a scavenge.
  uword survivor_end_;

  // All object are aligned to this value.
  uword object_alignment_;

  // Scavenge cycle count.
  int count_;
  // Keep track whether a scavenge is currently running.
  bool scavenging_;
  // Keep track whether the scavenge had a promotion failure.
  bool had_promotion_failure_;

  friend class ScavengerVisitor;
  friend class ScavengerWeakVisitor;

  DISALLOW_COPY_AND_ASSIGN(Scavenger);
};

}  // namespace dart

#endif  // VM_SCAVENGER_H_
