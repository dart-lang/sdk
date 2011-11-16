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
      // Addresses being visited cannot point in the to space. As this would
      // either mean the pointer is being visited twice or this pointer has not
      // been evacuated during the last scavenge. Both of these situations are
      // an error.
      ASSERT(!scavenger_->to_->Contains(raw_addr));
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
      // TODO(iposva): Check whether object should be promoted.
      new_addr = scavenger_->TryAllocate(size);
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
#if defined(DEBUG)
  memset(from_->pointer(), 0xf3, from_->size());
#endif  // defined(DEBUG)
}


void Scavenger::IterateRoots(Isolate* isolate, ObjectPointerVisitor* visitor) {
  isolate->VisitObjectPointers(visitor,
                               StackFrameIterator::kDontValidateFrames);
  heap_->IterateOldPointers(visitor);
}


void Scavenger::ProcessToSpace(ObjectPointerVisitor* visitor) {
  uword resolved_top = FirstObjectStart();
  // Iterate until all work has been drained.
  while (resolved_top < top_) {
    RawObject* raw_obj = RawObject::FromAddr(resolved_top);
    resolved_top += raw_obj->VisitPointers(visitor);
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

  Timer timer(FLAG_verbose_gc, "Scavenge");
  timer.Start();
  // Setup the visitor and run a scavenge.
  ScavengerVisitor visitor(this);
  Prologue();
  IterateRoots(isolate, &visitor);
  ProcessToSpace(&visitor);
  Epilogue();
  timer.Stop();
  if (FLAG_verbose_gc) {
    OS::PrintErr("Scavenge[%d]: %dus\n", count_, timer.TotalElapsedTime());
  }

  count_++;
  // Done scavenging. Reset the marker.
  ASSERT(scavenging_);
  scavenging_ = false;
}

}  // namespace dart
