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
#include "vm/weak_table.h"
#include "vm/object_id_ring.h"

namespace dart {

  DEFINE_FLAG(int, early_tenuring_threshold, 66, "Skip TO space when promoting"
                                                 " above this percentage.");

// Scavenger uses RawObject::kMarkBit to distinguish forwaded and non-forwarded
// objects. The kMarkBit does not intersect with the target address because of
// object alignment.
enum {
  kForwardingMask = 1 << RawObject::kMarkBit,
  kNotForwarded = 0,
  kForwarded = kForwardingMask,
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


class BoolScope : public ValueObject {
 public:
  BoolScope(bool* addr, bool value) : _addr(addr), _value(*addr) {
    *_addr = value;
  }
  ~BoolScope() {
    *_addr = _value;
  }

 private:
  bool* _addr;
  bool _value;
};


class ScavengerVisitor : public ObjectPointerVisitor {
 public:
  explicit ScavengerVisitor(Isolate* isolate, Scavenger* scavenger)
      : ObjectPointerVisitor(isolate),
        scavenger_(scavenger),
        heap_(scavenger->heap_),
        vm_heap_(Dart::vm_isolate()->heap()),
        visited_count_(0),
        handled_count_(0),
        delayed_weak_stack_(),
        growth_policy_(PageSpace::kControlGrowth),
        bytes_promoted_(0),
        visiting_old_object_(NULL),
        in_scavenge_pointer_(false) { }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      ScavengePointer(current);
    }
  }

  GrowableArray<RawObject*>* DelayedWeakStack() {
    return &delayed_weak_stack_;
  }

  void VisitingOldObject(RawObject* obj) {
    ASSERT((obj == NULL) || obj->IsOldObject());
    visiting_old_object_ = obj;
  }

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

  intptr_t visited_count() const { return visited_count_; }
  intptr_t handled_count() const { return handled_count_; }
  intptr_t bytes_promoted() const { return bytes_promoted_; }

 private:
  void UpdateStoreBuffer(RawObject** p, RawObject* obj) {
    uword ptr = reinterpret_cast<uword>(p);
    ASSERT(obj->IsHeapObject());
    ASSERT(!scavenger_->Contains(ptr));
    ASSERT(!heap_->CodeContains(ptr));
    ASSERT(heap_->Contains(ptr));
    // If the newly written object is not a new object, drop it immediately.
    if (!obj->IsNewObject() || visiting_old_object_->IsRemembered()) {
      return;
    }
    visiting_old_object_->SetRememberedBit();
    isolate()->store_buffer()->AddObjectGC(visiting_old_object_);
  }

  void ScavengePointer(RawObject** p) {
    // ScavengePointer cannot be called recursively.
#ifdef DEBUG
    ASSERT(!in_scavenge_pointer_);
    BoolScope bs(&in_scavenge_pointer_, true);
#endif

    visited_count_++;
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

    handled_count_++;
    // Read the header word of the object and determine if the object has
    // already been copied.
    uword header = *reinterpret_cast<uword*>(raw_addr);
    uword new_addr = 0;
    if (IsForwarding(header)) {
      // Get the new location of the object.
      new_addr = ForwardedAddr(header);
    } else {
      if (raw_obj->IsWatched()) {
        raw_obj->ClearWatchedBit();
        std::pair<DelaySet::iterator, DelaySet::iterator> ret;
        // Visit all elements with a key equal to this raw_obj.
        ret = delay_set_.equal_range(raw_obj);
        for (DelaySet::iterator it = ret.first; it != ret.second; ++it) {
          // Remember the delayed WeakProperty. These objects have been
          // forwarded, but have not been scavenged because their key was not
          // known to be reachable. Now that the key object is known to be
          // reachable, we need to visit its key and value pointers.
          delayed_weak_stack_.Add(it->second);
        }
        delay_set_.erase(ret.first, ret.second);
      }
      intptr_t size = raw_obj->Size();
      intptr_t cid = raw_obj->GetClassId();
      ClassTable* class_table = isolate()->class_table();
      // Check whether object should be promoted.
      if (scavenger_->survivor_end_ <= raw_addr) {
        // Not a survivor of a previous scavenge. Just copy the object into the
        // to space.
        new_addr = scavenger_->TryAllocate(size);
        class_table->UpdateLiveNew(cid, size);
      } else {
        // TODO(iposva): Experiment with less aggressive promotion. For example
        // a coin toss determines if an object is promoted or whether it should
        // survive in this generation.
        //
        // This object is a survivor of a previous scavenge. Attempt to promote
        // the object.
        new_addr = heap_->TryAllocate(size, Heap::kOld, growth_policy_);
        if (new_addr != 0) {
          // If promotion succeeded then we need to remember it so that it can
          // be traversed later.
          scavenger_->PushToPromotedStack(new_addr);
          bytes_promoted_ += size;
          class_table->UpdateAllocatedOld(cid, size);
        } else if (!scavenger_->had_promotion_failure_) {
          // Signal a promotion failure and set the growth policy for
          // this, and all subsequent promotion allocations, to force
          // growth.
          scavenger_->had_promotion_failure_ = true;
          growth_policy_ = PageSpace::kForceGrowth;
          new_addr = heap_->TryAllocate(size, Heap::kOld, growth_policy_);
          if (new_addr != 0) {
            scavenger_->PushToPromotedStack(new_addr);
            bytes_promoted_ += size;
            class_table->UpdateAllocatedOld(cid, size);
          } else {
            // Promotion did not succeed. Copy into the to space
            // instead.
            new_addr = scavenger_->TryAllocate(size);
            class_table->UpdateLiveNew(cid, size);
          }
        } else {
          ASSERT(growth_policy_ == PageSpace::kForceGrowth);
          // Promotion did not succeed. Copy into the to space instead.
          new_addr = scavenger_->TryAllocate(size);
          class_table->UpdateLiveNew(cid, size);
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
    if (visiting_old_object_ != NULL) {
      UpdateStoreBuffer(p, new_obj);
    }
  }

  Scavenger* scavenger_;
  Heap* heap_;
  Heap* vm_heap_;
  intptr_t visited_count_;
  intptr_t handled_count_;
  typedef std::multimap<RawObject*, RawWeakProperty*> DelaySet;
  DelaySet delay_set_;
  GrowableArray<RawObject*> delayed_weak_stack_;
  PageSpace::GrowthPolicy growth_policy_;
  // TODO(cshapiro): use this value to compute survival statistics for
  // new space growth policy.
  intptr_t bytes_promoted_;
  RawObject* visiting_old_object_;
  bool in_scavenge_pointer_;

  DISALLOW_COPY_AND_ASSIGN(ScavengerVisitor);
};


class ScavengerWeakVisitor : public HandleVisitor {
 public:
  explicit ScavengerWeakVisitor(Scavenger* scavenger)
      :  HandleVisitor(Isolate::Current()),
         scavenger_(scavenger) {
  }

  void VisitHandle(uword addr, bool is_prologue_weak) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    RawObject** p = handle->raw_addr();
    if (scavenger_->IsUnreachable(p)) {
      FinalizablePersistentHandle::Finalize(isolate(),
                                            handle,
                                            is_prologue_weak);
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


Scavenger::Scavenger(Heap* heap,
                     intptr_t max_capacity_in_words,
                     uword object_alignment)
    : heap_(heap),
      object_alignment_(object_alignment),
      scavenging_(false),
      gc_time_micros_(0),
      collections_(0) {
  // Verify assumptions about the first word in objects which the scavenger is
  // going to use for forwarding pointers.
  ASSERT(Object::tags_offset() == 0);

  // Allocate the virtual memory for this scavenge heap.
  space_ = VirtualMemory::Reserve(max_capacity_in_words << kWordSizeLog2);
  if (space_ == NULL) {
    FATAL("Out of memory.\n");
  }

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


void Scavenger::Epilogue(Isolate* isolate,
                         ScavengerVisitor* visitor,
                         bool invoke_api_callbacks) {
  // All objects in the to space have been copied from the from space at this
  // moment.
  int promotion_ratio = static_cast<int>(
      (static_cast<double>(visitor->bytes_promoted()) /
       static_cast<double>(to_->size())) * 100.0);
  if (promotion_ratio < FLAG_early_tenuring_threshold) {
    // Remember the limit to which objects have been copied.
    survivor_end_ = top_;
  } else {
    // Move survivor end to the end of the to_ space, making all surviving
    // objects candidates for promotion.
    survivor_end_ = end_;
  }

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
  StoreBuffer* buffer = isolate->store_buffer();
  heap_->RecordData(kStoreBufferEntries, buffer->Count());

  // Iterating through the store buffers.
  // Grab the deduplication sets out of the store buffer.
  StoreBufferBlock* pending = isolate->store_buffer()->Blocks();
  intptr_t visited_count_before = visitor->visited_count();
  intptr_t handled_count_before = visitor->handled_count();
  while (pending != NULL) {
    StoreBufferBlock* next = pending->next();
    intptr_t count = pending->Count();
    for (intptr_t i = 0; i < count; i++) {
      RawObject* raw_object = pending->At(i);
      ASSERT(raw_object->IsRemembered());
      raw_object->ClearRememberedBit();
      visitor->VisitingOldObject(raw_object);
      raw_object->VisitPointers(visitor);
    }
    delete pending;
    pending = next;
  }
  heap_->RecordData(kStoreBufferVisited,
                    visitor->visited_count() - visited_count_before);
  heap_->RecordData(kStoreBufferPointers,
                    visitor->handled_count() - handled_count_before);
  // Done iterating through old objects remembered in the store buffers.
  visitor->VisitingOldObject(NULL);
}


void Scavenger::IterateObjectIdTable(Isolate* isolate,
                                     ScavengerVisitor* visitor) {
  ObjectIdRing* ring = isolate->object_id_ring();
  if (ring == NULL) {
    // --gc_at_alloc can get us here before the ring has been initialized.
    ASSERT(FLAG_gc_at_alloc);
    return;
  }
  ring->VisitPointers(visitor);
}


void Scavenger::IterateRoots(Isolate* isolate,
                             ScavengerVisitor* visitor,
                             bool visit_prologue_weak_persistent_handles) {
  int64_t start = OS::GetCurrentTimeMicros();
  isolate->VisitObjectPointers(visitor,
                               visit_prologue_weak_persistent_handles,
                               StackFrameIterator::kDontValidateFrames);
  int64_t middle = OS::GetCurrentTimeMicros();
  IterateStoreBuffers(isolate, visitor);
  IterateObjectIdTable(isolate, visitor);
  int64_t end = OS::GetCurrentTimeMicros();
  heap_->RecordData(kToKBAfterStoreBuffer, RoundWordsToKB(UsedInWords()));
  heap_->RecordTime(kVisitIsolateRoots, middle - start);
  heap_->RecordTime(kIterateStoreBuffers, end - middle);
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
  GrowableArray<RawObject*>* delayed_weak_stack = visitor->DelayedWeakStack();

  // Iterate until all work has been drained.
  while ((resolved_top_ < top_) ||
         PromotedStackHasMore() ||
         !delayed_weak_stack->is_empty()) {
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
    {
      while (PromotedStackHasMore()) {
        RawObject* raw_object = RawObject::FromAddr(PopFromPromotedStack());
        // Resolve or copy all objects referred to by the current object. This
        // can potentially push more objects on this stack as well as add more
        // objects to be resolved in the to space.
        ASSERT(!raw_object->IsRemembered());
        visitor->VisitingOldObject(raw_object);
        raw_object->VisitPointers(visitor);
      }
      visitor->VisitingOldObject(NULL);
    }
    while (!delayed_weak_stack->is_empty()) {
      // Pop the delayed weak object from the stack and visit its pointers.
      RawObject* weak_property = delayed_weak_stack->RemoveLast();
      weak_property->VisitPointers(visitor);
    }
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


void Scavenger::ProcessWeakTables() {
  for (int sel = 0;
       sel < Heap::kNumWeakSelectors;
       sel++) {
    WeakTable* table = heap_->GetWeakTable(
        Heap::kNew, static_cast<Heap::WeakSelector>(sel));
    heap_->SetWeakTable(Heap::kNew,
                        static_cast<Heap::WeakSelector>(sel),
                        WeakTable::NewFrom(table));
    intptr_t size = table->size();
    for (intptr_t i = 0; i < size; i++) {
      if (table->IsValidEntryAt(i)) {
        RawObject* raw_obj = table->ObjectAt(i);
        ASSERT(raw_obj->IsHeapObject());
        uword raw_addr = RawObject::ToAddr(raw_obj);
        uword header = *reinterpret_cast<uword*>(raw_addr);
        if (IsForwarding(header)) {
          // The object has survived.  Preserve its record.
          uword new_addr = ForwardedAddr(header);
          raw_obj = RawObject::FromAddr(new_addr);
          heap_->SetWeakEntry(raw_obj,
                              static_cast<Heap::WeakSelector>(sel),
                              table->ValueAt(i));
        }
      }
    }
    // Remove the old table as it has been replaced with the newly allocated
    // table above.
    delete table;
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


void Scavenger::Scavenge() {
  // TODO(cshapiro): Add a decision procedure for determining when the
  // the API callbacks should be invoked.
  Scavenge(false);
}


void Scavenger::Scavenge(bool invoke_api_callbacks) {
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

  // Setup the visitor and run a scavenge.
  ScavengerVisitor visitor(isolate, this);
  Prologue(isolate, invoke_api_callbacks);
  IterateRoots(isolate, &visitor, !invoke_api_callbacks);
  int64_t start = OS::GetCurrentTimeMicros();
  ProcessToSpace(&visitor);
  int64_t middle = OS::GetCurrentTimeMicros();
  IterateWeakReferences(isolate, &visitor);
  ScavengerWeakVisitor weak_visitor(this);
  IterateWeakRoots(isolate, &weak_visitor, invoke_api_callbacks);
  visitor.Finalize();
  ProcessWeakTables();
  int64_t end = OS::GetCurrentTimeMicros();
  heap_->RecordTime(kProcessToSpace, middle - start);
  heap_->RecordTime(kIterateWeaks, end - middle);
  Epilogue(isolate, &visitor, invoke_api_callbacks);

  if (FLAG_verify_after_gc) {
    OS::PrintErr("Verifying after Scavenge...");
    heap_->Verify();
    OS::PrintErr(" done.\n");
  }

  // Done scavenging. Reset the marker.
  ASSERT(scavenging_);
  scavenging_ = false;
}


void Scavenger::WriteProtect(bool read_only) {
  space_->Protect(
      read_only ? VirtualMemory::kReadOnly : VirtualMemory::kReadWrite);
}


void Scavenger::PrintToJSONObject(JSONObject* object) {
  JSONObject space(object, "new");
  space.AddProperty("type", "@Scavenger");
  space.AddProperty("id", "heaps/new");
  space.AddProperty("name", "Scavenger");
  space.AddProperty("user_name", "new");
  space.AddProperty("collections", collections());
  space.AddProperty("used", UsedInWords() * kWordSize);
  space.AddProperty("capacity", CapacityInWords() * kWordSize);
  space.AddProperty("time", RoundMicrosecondsToSeconds(gc_time_micros()));
}


}  // namespace dart
