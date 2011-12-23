// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/scavenger.h"

#include "vm/dart.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/stack_frame.h"
#include "vm/verifier.h"
#include "vm/visitor.h"

namespace dart {

enum {
  kForwardingMask = 3,
  kNotForwarded = 1,  // Tagged pointer.
  kForwarded = 3,  // Tagged pointer and forwarding bit set.
};


static inline bool IsForwarding(uword header) {
  uword bits = header & kForwardingMask;
  ASSERT((bits == kNotForwarded) || (bits == kForwarded));
  return bits == kForwarded;
}


static inline uword ForwardedAddr(uword header) {
  ASSERT(IsForwarding(header));
  return header & ~kForwardingMask;
}


static inline void ForwardTo(uword orignal, uword target) {
  // Make sure forwarding can be encoded.
  ASSERT((target & kForwardingMask) == 0);
  *reinterpret_cast<uword*>(orignal) = target | kForwarded;
}


class ScavengerVisitor : public ObjectPointerVisitor {
 public:
  explicit ScavengerVisitor(Scavenger* scavenger)
      : scavenger_(scavenger),
        heap_(scavenger->heap_),
        vm_heap_(Dart::vm_isolate()->heap()) {}

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      ScavengePointer(current);
    }
  }

 private:
  void UpdateStoreBuffer(RawObject** p, RawObject* obj) {
    // TODO(iposva): Implement store buffers.
  }

  void ScavengePointer(RawObject** p) {
    RawObject* raw_obj = *p;

    // Fast exit if the raw object is a Smi.
    if (!raw_obj->IsHeapObject()) return;

    uword raw_addr = RawObject::ToAddr(raw_obj);
    // Objects should be contained in the heap.
    // TODO(iposva): Add an appropriate assert here or in the return block
    // below.
    // The scavenger is only interested in objects located in the from space.
    if (!scavenger_->from_->Contains(raw_addr)) {
      return;
    }

    // Read the header word of the object and determine if the object has
    // already been copied.
    uword header = *reinterpret_cast<uword*>(raw_addr);
    uword new_addr = 0;
    if (IsForwarding(header)) {
      // Get the new location of the object.
      new_addr = ForwardedAddr(header);
    } else {
      intptr_t size = raw_obj->Size();
      // Check whether object should be promoted.
      if (scavenger_->survivor_end_ <= raw_addr) {
        // Not a survivor of a previous scavenge. Just copy the object into the
        // to space.
        new_addr = scavenger_->TryAllocate(size);
      } else {
        // TODO(iposva): Experiment with less aggressive promotion. For example
        // a coin toss determines if an object is promoted or whether it should
        // survive in this generation.
        //
        // This object is a survivor of a previous scavenge. Attempt to promote
        // the object.
        new_addr = heap_->TryAllocate(size, Heap::kOld);
        if (new_addr != 0) {
          // If promotion succeeded then we need to remember it so that it can
          // be traversed later.
          scavenger_->PushToPromotedStack(new_addr);
        } else {
          // Promotion did not succeed. Copy into the to space instead.
          scavenger_->had_promotion_failure_ = true;
          new_addr = scavenger_->TryAllocate(size);
        }
      }
      // During a scavenge we always succeed to at least copy all of the
      // current objects to the to space.
      ASSERT(new_addr != 0);
      // Copy the object to the new location.
      memmove(reinterpret_cast<void*>(new_addr),
              reinterpret_cast<void*>(raw_addr),
              size);
      // Remember forwarding address.
      ForwardTo(raw_addr, new_addr);
    }
    // Update the reference.
    RawObject* new_obj = RawObject::FromAddr(new_addr);
    *p = new_obj;
    // Update the store buffer as needed.
    UpdateStoreBuffer(p, new_obj);
  }

  Scavenger* scavenger_;
  Heap* heap_;
  Heap* vm_heap_;

  DISALLOW_COPY_AND_ASSIGN(ScavengerVisitor);
};


class ScavengerWeakVisitor : public ObjectPointerVisitor {
 public:
  explicit ScavengerWeakVisitor(Scavenger* scavenger) : scavenger_(scavenger) {
  }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      RawObject* raw_obj = *current;
      ASSERT(raw_obj->IsHeapObject());
      uword raw_addr = RawObject::ToAddr(raw_obj);
      if (scavenger_->from_->Contains(raw_addr)) {
        uword header = *reinterpret_cast<uword*>(raw_addr);
        if (IsForwarding(header)) {
          *current = RawObject::FromAddr(ForwardedAddr(header));
        } else {
          *current = Object::null();
        }
      }
    }
  }

 private:
  Scavenger* scavenger_;

  DISALLOW_COPY_AND_ASSIGN(ScavengerWeakVisitor);
};


Scavenger::Scavenger(Heap* heap, intptr_t max_capacity, uword object_alignment)
    : heap_(heap),
      object_alignment_(object_alignment),
      count_(0),
      scavenging_(false) {
  // Allocate the virtual memory for this scavenge heap.
  space_ = VirtualMemory::Reserve(max_capacity);
  ASSERT(space_ != NULL);

  // Allocate the entire space at the beginning.
  space_->Commit(false);

  // Setup the semi spaces.
  uword semi_space_size = space_->size() / 2;
  ASSERT((semi_space_size & (VirtualMemory::PageSize() - 1)) == 0);
  to_ = new MemoryRegion(space_->address(), semi_space_size);
  uword middle = space_->start() + semi_space_size;
  from_ = new MemoryRegion(reinterpret_cast<void*>(middle), semi_space_size);

  // Make sure that the two semi-spaces are aligned properly.
  ASSERT(Utils::IsAligned(to_->start(), kObjectAlignment));
  ASSERT(Utils::IsAligned(from_->start(), kObjectAlignment));

  // Setup local fields.
  top_ = FirstObjectStart();
  end_ = to_->end();

  survivor_end_ = FirstObjectStart();

#if defined(DEBUG)
  memset(to_->pointer(), 0xf3, to_->size());
  memset(from_->pointer(), 0xf3, from_->size());
#endif  // defined(DEBUG)
}


Scavenger::~Scavenger() {
  delete to_;
  delete from_;
  delete space_;
}


void Scavenger::Prologue() {
  // Flip the two semi-spaces so that to_ is always the space for allocating
  // objects.
  MemoryRegion* temp = from_;
  from_ = to_;
  to_ = temp;
  top_ = FirstObjectStart();
  end_ = to_->end();
}


void Scavenger::Epilogue() {
  // All objects in the to space have been copied from the from space at this
  // moment.
  survivor_end_ = top_;

#if defined(DEBUG)
  memset(from_->pointer(), 0xf3, from_->size());
#endif  // defined(DEBUG)
}


void Scavenger::IterateRoots(Isolate* isolate, ObjectPointerVisitor* visitor) {
  isolate->VisitStrongObjectPointers(visitor,
                                     StackFrameIterator::kDontValidateFrames);
  heap_->IterateOldPointers(visitor);
}


void Scavenger::IterateWeakRoots(Isolate* isolate,
                                 ObjectPointerVisitor* visitor) {
  isolate->VisitWeakObjectPointers(visitor);
}


void Scavenger::ProcessToSpace(ObjectPointerVisitor* visitor) {
  uword resolved_top = FirstObjectStart();
  // Iterate until all work has been drained.
  while ((resolved_top < top_) || PromotedStackHasMore()) {
    while (resolved_top < top_) {
      RawObject* raw_obj = RawObject::FromAddr(resolved_top);
      resolved_top += raw_obj->VisitPointers(visitor);
    }
    while (PromotedStackHasMore()) {
      RawObject* raw_object = RawObject::FromAddr(PopFromPromotedStack());
      // Resolve or copy all objects referred to by the current object. This
      // can potentially push more objects on this stack as well as add more
      // objects to be resolved in the to space.
      raw_object->VisitPointers(visitor);
    }
  }
}


void Scavenger::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  uword cur = FirstObjectStart();
  while (cur < top_) {
    RawObject* raw_obj = RawObject::FromAddr(cur);
    cur += raw_obj->VisitPointers(visitor);
  }
}


void Scavenger::Scavenge() {
  // Scavenging is not reentrant. Make sure that is the case.
  ASSERT(!scavenging_);
  scavenging_ = true;
  Isolate* isolate = Isolate::Current();
  NoHandleScope no_handles(isolate);

  if (FLAG_verify_before_gc) {
    OS::PrintErr("Verifying before Scavenge... ");
    heap_->Verify();
    OS::PrintErr(" done.\n");
  }

  Timer timer(FLAG_verbose_gc, "Scavenge");
  timer.Start();
  // Setup the visitor and run a scavenge.
  ScavengerVisitor visitor(this);
  Prologue();
  IterateRoots(isolate, &visitor);
  ProcessToSpace(&visitor);
  ScavengerWeakVisitor weak_visitor(this);
  IterateWeakRoots(isolate, &weak_visitor);
  Epilogue();
  timer.Stop();
  if (FLAG_verbose_gc) {
    OS::PrintErr("Scavenge[%d]: %dus\n", count_, timer.TotalElapsedTime());
  }

  if (FLAG_verify_after_gc) {
    OS::PrintErr("Verifying after Scavenge... ");
    heap_->Verify();
    OS::PrintErr(" done.\n");
  }

  count_++;
  // Done scavenging. Reset the marker.
  ASSERT(scavenging_);
  scavenging_ = false;
}

}  // namespace dart
