// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/scavenger.h"

#include <algorithm>
#include <map>
#include <utility>

#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/stack_frame.h"
#include "vm/store_buffer.h"
#include "vm/verifier.h"
#include "vm/visitor.h"

namespace dart {

// Scavenger uses RawObject::kFreeBit to distinguish forwaded and non-forwarded
// objects because scavenger can never encounter free list element during
// evacuation and thus all objects scavenger encounters have
// kFreeBit cleared.
enum {
  kForwardingMask = 1,
  kNotForwarded = 0,
  kForwarded = 1,
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
  explicit ScavengerVisitor(Isolate* isolate, Scavenger* scavenger)
      : ObjectPointerVisitor(isolate),
        scavenger_(scavenger),
        heap_(scavenger->heap_),
        vm_heap_(Dart::vm_isolate()->heap()),
        visiting_old_pointers_(false) {}

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      ScavengePointer(current);
    }
  }

  void VisitingOldPointers(bool value) { visiting_old_pointers_ = value; }

  void DelayWeakProperty(RawWeakProperty* raw_weak) {
    RawObject* raw_key = raw_weak->ptr()->key_;
    DelaySet::iterator it = delay_set_.find(raw_key);
    if (it != delay_set_.end()) {
      ASSERT(raw_key->IsWatched());
    } else {
      ASSERT(!raw_key->IsWatched());
      raw_key->SetWatchedBit();
    }
    delay_set_.insert(std::make_pair(raw_key, raw_weak));
  }

  void Finalize() {
    DelaySet::iterator it = delay_set_.begin();
    for (; it != delay_set_.end(); ++it) {
      WeakProperty::Clear(it->second);
    }
  }

 private:
  void UpdateStoreBuffer(RawObject** p, RawObject* obj) {
    uword ptr = reinterpret_cast<uword>(p);
    ASSERT(obj->IsHeapObject());
    ASSERT(!scavenger_->Contains(ptr));
    ASSERT(!heap_->CodeContains(ptr));
    ASSERT(heap_->Contains(ptr));
    // If the newly written object is not a new object, drop it immediately.
    if (!obj->IsNewObject()) return;
    isolate()->store_buffer()->AddPointer(ptr);
  }

  void ScavengePointer(RawObject** p) {
    RawObject* raw_obj = *p;

    // Fast exit if the raw object is a Smi or an old object.
    if (!raw_obj->IsHeapObject() || raw_obj->IsOldObject()) {
      return;
    }

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
      if (raw_obj->IsWatched()) {
        std::pair<DelaySet::iterator, DelaySet::iterator> ret;
        // Visit all elements with a key equal to raw_obj.
        ret = delay_set_.equal_range(raw_obj);
        for (DelaySet::iterator it = ret.first; it != ret.second; ++it) {
          // Visit through the associated WeakProperty at this time.
          it->second->VisitPointers(this);
        }
        delay_set_.erase(ret.first, ret.second);
        raw_obj->ClearWatchedBit();
      }
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
    if (visiting_old_pointers_) {
      UpdateStoreBuffer(p, new_obj);
    }
  }

  Scavenger* scavenger_;
  Heap* heap_;
  Heap* vm_heap_;
  typedef std::multimap<RawObject*, RawWeakProperty*> DelaySet;
  DelaySet delay_set_;

  bool visiting_old_pointers_;

  DISALLOW_COPY_AND_ASSIGN(ScavengerVisitor);
};


class ScavengerWeakVisitor : public HandleVisitor {
 public:
  explicit ScavengerWeakVisitor(Scavenger* scavenger) : scavenger_(scavenger) {
  }

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    RawObject** p = handle->raw_addr();
    if (scavenger_->IsUnreachable(p)) {
      FinalizablePersistentHandle::Finalize(handle);
    }
  }

 private:
  Scavenger* scavenger_;

  DISALLOW_COPY_AND_ASSIGN(ScavengerWeakVisitor);
};


// Visitor used to verify that all old->new references have been added to the
// StoreBuffers.
class VerifyStoreBufferPointerVisitor : public ObjectPointerVisitor {
 public:
  VerifyStoreBufferPointerVisitor(Isolate* isolate, MemoryRegion* to)
      : ObjectPointerVisitor(isolate), to_(to) {}

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      RawObject* obj = *current;
      if (obj->IsHeapObject() && obj->IsNewObject()) {
        ASSERT(to_->Contains(RawObject::ToAddr(obj)));
      }
    }
  }

 private:
  MemoryRegion* to_;

  DISALLOW_COPY_AND_ASSIGN(VerifyStoreBufferPointerVisitor);
};


Scavenger::Scavenger(Heap* heap, intptr_t max_capacity, uword object_alignment)
    : heap_(heap),
      object_alignment_(object_alignment),
      count_(0),
      scavenging_(false) {
  // Verify assumptions about the first word in objects which the scavenger is
  // going to use for forwarding pointers.
  ASSERT(Object::tags_offset() == 0);
  ASSERT(kForwardingMask == (1 << RawObject::kFreeBit));

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
  resolved_top_ = top_;
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


void Scavenger::Prologue(Isolate* isolate, bool invoke_api_callbacks) {
  if (invoke_api_callbacks) {
    isolate->gc_prologue_callbacks().Invoke();
  }
  // Flip the two semi-spaces so that to_ is always the space for allocating
  // objects.
  MemoryRegion* temp = from_;
  from_ = to_;
  to_ = temp;
  top_ = FirstObjectStart();
  resolved_top_ = top_;
  end_ = to_->end();
}


void Scavenger::Epilogue(Isolate* isolate, bool invoke_api_callbacks) {
  // All objects in the to space have been copied from the from space at this
  // moment.
  survivor_end_ = top_;

#if defined(DEBUG)
  VerifyStoreBufferPointerVisitor verify_store_buffer_visitor(isolate, to_);
  heap_->IterateOldPointers(&verify_store_buffer_visitor);

  memset(from_->pointer(), 0xf3, from_->size());
#endif  // defined(DEBUG)
  if (invoke_api_callbacks) {
    isolate->gc_epilogue_callbacks().Invoke();
  }
}


void Scavenger::IterateStoreBuffers(Isolate* isolate,
                                    ScavengerVisitor* visitor) {
  // Iterating through the store buffers.
  visitor->VisitingOldPointers(true);
  // Grab the deduplication sets out of the store buffer.
  StoreBuffer::DedupSet* pending = isolate->store_buffer()->DedupSets();
  intptr_t entries = 0;
  intptr_t duplicates = 0;
  while (pending != NULL) {
    StoreBuffer::DedupSet* next = pending->next();
    HashSet* set = pending->set();
    intptr_t count = set->Count();
    intptr_t size = set->Size();
    intptr_t handled = 0;
    entries += count;
    for (intptr_t i = 0; i < size; i++) {
      RawObject** pointer = reinterpret_cast<RawObject**>(set->At(i));
      if (pointer != NULL) {
        RawObject* value = *pointer;
        // Skip entries that have been overwritten with Smis.
        if (value->IsHeapObject()) {
          if (from_->Contains(RawObject::ToAddr(value))) {
            visitor->VisitPointer(pointer);
          } else {
            duplicates++;
          }
        }
        handled++;
        if (handled == count) {
          break;
        }
      }
    }
    delete pending;
    pending = next;
  }
  if (FLAG_verbose_gc) {
    OS::PrintErr("StoreBuffer: %"Pd", %"Pd" (entries, dups)\n",
                 entries, duplicates);
  }
  StoreBufferBlock* block = isolate->store_buffer_block();
  entries = block->Count();
  duplicates = 0;
  for (intptr_t i = 0; i < entries; i++) {
    RawObject** pointer = reinterpret_cast<RawObject**>(block->At(i));
    RawObject* value = *pointer;
    if (value->IsHeapObject()) {
      if (from_->Contains(RawObject::ToAddr(value))) {
        visitor->VisitPointer(pointer);
      } else {
        duplicates++;
      }
    }
  }
  block->Reset();
  if (FLAG_verbose_gc) {
    OS::PrintErr("StoreBufferBlock: %"Pd", %"Pd" (entries, dups)\n",
                 entries, duplicates);
  }
  // Done iterating through the store buffers.
  visitor->VisitingOldPointers(false);
}


void Scavenger::IterateRoots(Isolate* isolate,
                             ScavengerVisitor* visitor,
                             bool visit_prologue_weak_persistent_handles) {
  IterateStoreBuffers(isolate, visitor);
  isolate->VisitObjectPointers(visitor,
                               visit_prologue_weak_persistent_handles,
                               StackFrameIterator::kDontValidateFrames);
}


bool Scavenger::IsUnreachable(RawObject** p) {
  RawObject* raw_obj = *p;
  if (!raw_obj->IsHeapObject()) {
    return false;
  }
  if (!raw_obj->IsNewObject()) {
    return false;
  }
  uword raw_addr = RawObject::ToAddr(raw_obj);
  if (!from_->Contains(raw_addr)) {
    return false;
  }
  uword header = *reinterpret_cast<uword*>(raw_addr);
  if (IsForwarding(header)) {
    uword new_addr = ForwardedAddr(header);
    *p = RawObject::FromAddr(new_addr);
    return false;
  }
  return true;
}


void Scavenger::IterateWeakReferences(Isolate* isolate,
                                      ScavengerVisitor* visitor) {
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  while (true) {
    WeakReferenceSet* queue = state->delayed_weak_reference_sets();
    if (queue == NULL) {
      // The delay queue is empty therefore no clean-up is required.
      return;
    }
    state->set_delayed_weak_reference_sets(NULL);
    while (queue != NULL) {
      WeakReferenceSet* reference_set = WeakReferenceSet::Pop(&queue);
      ASSERT(reference_set != NULL);
      bool is_unreachable = true;
      // Test each key object for reachability.  If a key object is
      // reachable, all value objects should be scavenged.
      for (intptr_t k = 0; k < reference_set->num_keys(); ++k) {
        if (!IsUnreachable(reference_set->get_key(k))) {
          for (intptr_t v = 0; v < reference_set->num_values(); ++v) {
            visitor->VisitPointer(reference_set->get_value(v));
          }
          is_unreachable = false;
          delete reference_set;
          break;
        }
      }
      // If all key objects are unreachable put the reference on a
      // delay queue.  This reference will be revisited if another
      // reference is scavenged.
      if (is_unreachable) {
        state->DelayWeakReferenceSet(reference_set);
      }
    }
    if ((resolved_top_ < top_) || PromotedStackHasMore()) {
      ProcessToSpace(visitor);
    } else {
      // Break out of the loop if there has been no forward process.
      break;
    }
  }
  // Deallocate any unreachable references on the delay queue.
  if (state->delayed_weak_reference_sets() != NULL) {
    WeakReferenceSet* queue = state->delayed_weak_reference_sets();
    state->set_delayed_weak_reference_sets(NULL);
    while (queue != NULL) {
      delete WeakReferenceSet::Pop(&queue);
    }
  }
}


void Scavenger::IterateWeakRoots(Isolate* isolate,
                                 HandleVisitor* visitor,
                                 bool visit_prologue_weak_persistent_handles) {
  isolate->VisitWeakPersistentHandles(visitor,
                                      visit_prologue_weak_persistent_handles);
}


void Scavenger::ProcessToSpace(ScavengerVisitor* visitor) {
  // Iterate until all work has been drained.
  while ((resolved_top_ < top_) || PromotedStackHasMore()) {
    while (resolved_top_ < top_) {
      RawObject* raw_obj = RawObject::FromAddr(resolved_top_);
      intptr_t class_id = raw_obj->GetClassId();
      if (class_id != kWeakPropertyCid) {
        resolved_top_ += raw_obj->VisitPointers(visitor);
      } else {
        RawWeakProperty* raw_weak = reinterpret_cast<RawWeakProperty*>(raw_obj);
        resolved_top_ += ProcessWeakProperty(raw_weak, visitor);
      }
    }
    visitor->VisitingOldPointers(true);
    while (PromotedStackHasMore()) {
      RawObject* raw_object = RawObject::FromAddr(PopFromPromotedStack());
      // Resolve or copy all objects referred to by the current object. This
      // can potentially push more objects on this stack as well as add more
      // objects to be resolved in the to space.
      raw_object->VisitPointers(visitor);
    }
    visitor->VisitingOldPointers(false);
  }
}


uword Scavenger::ProcessWeakProperty(RawWeakProperty* raw_weak,
                                     ScavengerVisitor* visitor) {
  // The fate of the weak property is determined by its key.
  RawObject* raw_key = raw_weak->ptr()->key_;
  if (raw_key->IsHeapObject() && raw_key->IsNewObject()) {
    uword raw_addr = RawObject::ToAddr(raw_key);
    uword header = *reinterpret_cast<uword*>(raw_addr);
    if (!IsForwarding(header)) {
      // Key is white.  Delay the weak property.
      visitor->DelayWeakProperty(raw_weak);
      return raw_weak->Size();
    }
  }
  // Key is gray or black.  Make the weak property black.
  return raw_weak->VisitPointers(visitor);
}


void Scavenger::ProcessPeerReferents() {
  PeerTable prev;
  std::swap(prev, peer_table_);
  for (PeerTable::iterator it = prev.begin(); it != prev.end(); ++it) {
    RawObject* raw_obj = it->first;
    ASSERT(raw_obj->IsHeapObject());
    uword raw_addr = RawObject::ToAddr(raw_obj);
    uword header = *reinterpret_cast<uword*>(raw_addr);
    if (IsForwarding(header)) {
      // The object has survived.  Preserve its record.
      uword new_addr = ForwardedAddr(header);
      raw_obj = RawObject::FromAddr(new_addr);
      heap_->SetPeer(raw_obj, it->second);
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


void Scavenger::VisitObjects(ObjectVisitor* visitor) const {
  uword cur = FirstObjectStart();
  while (cur < top_) {
    RawObject* raw_obj = RawObject::FromAddr(cur);
    visitor->VisitObject(raw_obj);
    cur += raw_obj->Size();
  }
}


void Scavenger::Scavenge(const char* gc_reason) {
  // TODO(cshapiro): Add a decision procedure for determining when the
  // the API callbacks should be invoked.
  Scavenge(false, gc_reason);
}


void Scavenger::Scavenge(bool invoke_api_callbacks, const char* gc_reason) {
  // Scavenging is not reentrant. Make sure that is the case.
  ASSERT(!scavenging_);
  scavenging_ = true;
  had_promotion_failure_ = false;
  Isolate* isolate = Isolate::Current();
  NoHandleScope no_handles(isolate);

  if (FLAG_verify_before_gc) {
    OS::PrintErr("Verifying before Scavenge...");
    heap_->Verify();
    OS::PrintErr(" done.\n");
  }

  if (FLAG_verbose_gc) {
    OS::PrintErr("Start scavenge for %s collection\n", gc_reason);
  }
  Timer timer(FLAG_verbose_gc, "Scavenge");
  timer.Start();
  // Setup the visitor and run a scavenge.
  ScavengerVisitor visitor(isolate, this);
  Prologue(isolate, invoke_api_callbacks);
  IterateRoots(isolate, &visitor, !invoke_api_callbacks);
  ProcessToSpace(&visitor);
  IterateWeakReferences(isolate, &visitor);
  ScavengerWeakVisitor weak_visitor(this);
  IterateWeakRoots(isolate, &weak_visitor, invoke_api_callbacks);
  visitor.Finalize();
  ProcessPeerReferents();
  Epilogue(isolate, invoke_api_callbacks);
  timer.Stop();
  if (FLAG_verbose_gc) {
    OS::PrintErr("Scavenge[%d]: %"Pd64"us\n",
                 count_,
                 timer.TotalElapsedTime());
  }

  if (FLAG_verify_after_gc) {
    OS::PrintErr("Verifying after Scavenge...");
    heap_->Verify();
    OS::PrintErr(" done.\n");
  }

  count_++;
  // Done scavenging. Reset the marker.
  ASSERT(scavenging_);
  scavenging_ = false;
}


void Scavenger::WriteProtect(bool read_only) {
  space_->Protect(
      read_only ? VirtualMemory::kReadOnly : VirtualMemory::kReadWrite);
}


void Scavenger::SetPeer(RawObject* raw_obj, void* peer) {
  if (peer == NULL) {
    peer_table_.erase(raw_obj);
  } else {
    peer_table_[raw_obj] = peer;
  }
}


void* Scavenger::GetPeer(RawObject* raw_obj) {
  PeerTable::iterator it = peer_table_.find(raw_obj);
  return (it == peer_table_.end()) ? NULL : it->second;
}


int64_t Scavenger::PeerCount() const {
  return static_cast<int64_t>(peer_table_.size());
}

}  // namespace dart
