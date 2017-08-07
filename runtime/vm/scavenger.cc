// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/scavenger.h"

#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_set.h"
#include "vm/safepoint.h"
#include "vm/stack_frame.h"
#include "vm/store_buffer.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/verifier.h"
#include "vm/visitor.h"
#include "vm/weak_table.h"

namespace dart {

DEFINE_FLAG(int,
            early_tenuring_threshold,
            66,
            "When more than this percentage of promotion candidates survive, "
            "promote all survivors of next scavenge.");
DEFINE_FLAG(int,
            new_gen_garbage_threshold,
            90,
            "Grow new gen when less than this percentage is garbage.");
DEFINE_FLAG(int, new_gen_growth_factor, 4, "Grow new gen by this factor.");

// Scavenger uses RawObject::kMarkBit to distinguish forwarded and non-forwarded
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

static inline void ForwardTo(uword original, uword target) {
  // Make sure forwarding can be encoded.
  ASSERT((target & kForwardingMask) == 0);
  *reinterpret_cast<uword*>(original) = target | kForwarded;
}

class ScavengerVisitor : public ObjectPointerVisitor {
 public:
  explicit ScavengerVisitor(Isolate* isolate,
                            Scavenger* scavenger,
                            SemiSpace* from)
      : ObjectPointerVisitor(isolate),
        thread_(Thread::Current()),
        scavenger_(scavenger),
        from_(from),
        heap_(scavenger->heap_),
        page_space_(scavenger->heap_->old_space()),
        bytes_promoted_(0),
        visiting_old_object_(NULL) {}

  void VisitPointers(RawObject** first, RawObject** last) {
    if (FLAG_verify_gc_contains) {
      ASSERT((visiting_old_object_ != NULL) ||
             scavenger_->Contains(reinterpret_cast<uword>(first)) ||
             !heap_->Contains(reinterpret_cast<uword>(first)));
    }
    for (RawObject** current = first; current <= last; current++) {
      ScavengePointer(current);
    }
  }

  void VisitingOldObject(RawObject* obj) {
    ASSERT((obj == NULL) || obj->IsOldObject());
    visiting_old_object_ = obj;
  }

  intptr_t bytes_promoted() const { return bytes_promoted_; }

 private:
  void UpdateStoreBuffer(RawObject** p, RawObject* obj) {
    ASSERT(obj->IsHeapObject());
    if (FLAG_verify_gc_contains) {
      uword ptr = reinterpret_cast<uword>(p);
      ASSERT(!scavenger_->Contains(ptr));
      ASSERT(heap_->DataContains(ptr));
    }
    // If the newly written object is not a new object, drop it immediately.
    if (!obj->IsNewObject() || visiting_old_object_->IsRemembered()) {
      return;
    }
    visiting_old_object_->SetRememberedBit();
    thread_->StoreBufferAddObjectGC(visiting_old_object_);
  }

  void ScavengePointer(RawObject** p) {
    // ScavengePointer cannot be called recursively.
    RawObject* raw_obj = *p;

    if (raw_obj->IsSmiOrOldObject()) {
      return;
    }

    uword raw_addr = RawObject::ToAddr(raw_obj);
    // The scavenger is only expects objects located in the from space.
    ASSERT(from_->Contains(raw_addr));
    // Read the header word of the object and determine if the object has
    // already been copied.
    uword header = *reinterpret_cast<uword*>(raw_addr);
    uword new_addr = 0;
    if (IsForwarding(header)) {
      // Get the new location of the object.
      new_addr = ForwardedAddr(header);
    } else {
      intptr_t size = raw_obj->Size();
      NOT_IN_PRODUCT(intptr_t cid = raw_obj->GetClassId());
      NOT_IN_PRODUCT(ClassTable* class_table = isolate()->class_table());
      // Check whether object should be promoted.
      if (scavenger_->survivor_end_ <= raw_addr) {
        // Not a survivor of a previous scavenge. Just copy the object into the
        // to space.
        new_addr = scavenger_->AllocateGC(size);
        NOT_IN_PRODUCT(class_table->UpdateLiveNew(cid, size));
      } else {
        // TODO(iposva): Experiment with less aggressive promotion. For example
        // a coin toss determines if an object is promoted or whether it should
        // survive in this generation.
        //
        // This object is a survivor of a previous scavenge. Attempt to promote
        // the object.
        new_addr =
            page_space_->TryAllocatePromoLocked(size, PageSpace::kForceGrowth);
        if (new_addr != 0) {
          // If promotion succeeded then we need to remember it so that it can
          // be traversed later.
          scavenger_->PushToPromotedStack(new_addr);
          bytes_promoted_ += size;
          NOT_IN_PRODUCT(class_table->UpdateAllocatedOld(cid, size));
        } else {
          // Promotion did not succeed. Copy into the to space instead.
          scavenger_->failed_to_promote_ = true;
          new_addr = scavenger_->AllocateGC(size);
          NOT_IN_PRODUCT(class_table->UpdateLiveNew(cid, size));
        }
      }
      // During a scavenge we always succeed to at least copy all of the
      // current objects to the to space.
      ASSERT(new_addr != 0);
      // Copy the object to the new location.
      memmove(reinterpret_cast<void*>(new_addr),
              reinterpret_cast<void*>(raw_addr), size);
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

  Thread* thread_;
  Scavenger* scavenger_;
  SemiSpace* from_;
  Heap* heap_;
  PageSpace* page_space_;
  RawWeakProperty* delayed_weak_properties_;
  intptr_t bytes_promoted_;
  RawObject* visiting_old_object_;

  friend class Scavenger;

  DISALLOW_COPY_AND_ASSIGN(ScavengerVisitor);
};

class ScavengerWeakVisitor : public HandleVisitor {
 public:
  ScavengerWeakVisitor(Thread* thread, Scavenger* scavenger)
      : HandleVisitor(thread), scavenger_(scavenger) {
    ASSERT(scavenger->heap_->isolate() == thread->isolate());
  }

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    RawObject** p = handle->raw_addr();
    if (scavenger_->IsUnreachable(p)) {
      handle->UpdateUnreachable(thread()->isolate());
    } else {
      handle->UpdateRelocated(thread()->isolate());
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
  VerifyStoreBufferPointerVisitor(Isolate* isolate, const SemiSpace* to)
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
  const SemiSpace* to_;

  DISALLOW_COPY_AND_ASSIGN(VerifyStoreBufferPointerVisitor);
};

SemiSpace::SemiSpace(VirtualMemory* reserved)
    : reserved_(reserved), region_(NULL, 0) {
  if (reserved != NULL) {
    region_ = MemoryRegion(reserved_->address(), reserved_->size());
  }
}

SemiSpace::~SemiSpace() {
  if (reserved_ != NULL) {
#if defined(DEBUG)
    memset(reserved_->address(), Heap::kZapByte,
           size_in_words() << kWordSizeLog2);
#endif  // defined(DEBUG)
    delete reserved_;
  }
}

Mutex* SemiSpace::mutex_ = NULL;
SemiSpace* SemiSpace::cache_ = NULL;

void SemiSpace::InitOnce() {
  ASSERT(mutex_ == NULL);
  mutex_ = new Mutex();
  ASSERT(mutex_ != NULL);
}

SemiSpace* SemiSpace::New(intptr_t size_in_words, const char* name) {
  {
    MutexLocker locker(mutex_);
    // TODO(koda): Cache one entry per size.
    if (cache_ != NULL && cache_->size_in_words() == size_in_words) {
      SemiSpace* result = cache_;
      cache_ = NULL;
      return result;
    }
  }
  if (size_in_words == 0) {
    return new SemiSpace(NULL);
  } else {
    intptr_t size_in_bytes = size_in_words << kWordSizeLog2;
    VirtualMemory* reserved = VirtualMemory::Reserve(size_in_bytes);
    const bool kExecutable = false;
    if ((reserved == NULL) || !reserved->Commit(kExecutable, name)) {
      // TODO(koda): If cache_ is not empty, we could try to delete it.
      delete reserved;
      return NULL;
    }
#if defined(DEBUG)
    memset(reserved->address(), Heap::kZapByte, size_in_bytes);
#endif  // defined(DEBUG)
    return new SemiSpace(reserved);
  }
}

void SemiSpace::Delete() {
#ifdef DEBUG
  if (reserved_ != NULL) {
    const intptr_t size_in_bytes = size_in_words() << kWordSizeLog2;
    memset(reserved_->address(), Heap::kZapByte, size_in_bytes);
  }
#endif
  SemiSpace* old_cache = NULL;
  {
    MutexLocker locker(mutex_);
    old_cache = cache_;
    cache_ = this;
  }
  delete old_cache;
}

void SemiSpace::WriteProtect(bool read_only) {
  if (reserved_ != NULL) {
    bool success = reserved_->Protect(read_only ? VirtualMemory::kReadOnly
                                                : VirtualMemory::kReadWrite);
    ASSERT(success);
  }
}

Scavenger::Scavenger(Heap* heap,
                     intptr_t max_semi_capacity_in_words,
                     uword object_alignment)
    : heap_(heap),
      max_semi_capacity_in_words_(max_semi_capacity_in_words),
      object_alignment_(object_alignment),
      scavenging_(false),
      delayed_weak_properties_(NULL),
      gc_time_micros_(0),
      collections_(0),
      external_size_(0),
      failed_to_promote_(false) {
  // Verify assumptions about the first word in objects which the scavenger is
  // going to use for forwarding pointers.
  ASSERT(Object::tags_offset() == 0);

  // Set initial size resulting in a total of three different levels.
  const intptr_t initial_semi_capacity_in_words =
      max_semi_capacity_in_words /
      (FLAG_new_gen_growth_factor * FLAG_new_gen_growth_factor);

  const intptr_t kVmNameSize = 128;
  char vm_name[kVmNameSize];
  Heap::RegionName(heap_, Heap::kNew, vm_name, kVmNameSize);
  to_ = SemiSpace::New(initial_semi_capacity_in_words, vm_name);
  if (to_ == NULL) {
    OUT_OF_MEMORY();
  }
  // Setup local fields.
  top_ = FirstObjectStart();
  resolved_top_ = top_;
  end_ = to_->end();

  survivor_end_ = FirstObjectStart();

  UpdateMaxHeapCapacity();
  UpdateMaxHeapUsage();
}

Scavenger::~Scavenger() {
  ASSERT(!scavenging_);
  to_->Delete();
}

intptr_t Scavenger::NewSizeInWords(intptr_t old_size_in_words) const {
  if (stats_history_.Size() == 0) {
    return old_size_in_words;
  }
  double garbage = stats_history_.Get(0).GarbageFraction();
  if (garbage < (FLAG_new_gen_garbage_threshold / 100.0)) {
    return Utils::Minimum(max_semi_capacity_in_words_,
                          old_size_in_words * FLAG_new_gen_growth_factor);
  } else {
    return old_size_in_words;
  }
}

SemiSpace* Scavenger::Prologue(Isolate* isolate, bool invoke_api_callbacks) {
  if (invoke_api_callbacks && (isolate->gc_prologue_callback() != NULL)) {
    (isolate->gc_prologue_callback())();
  }
  isolate->PrepareForGC();

  // Flip the two semi-spaces so that to_ is always the space for allocating
  // objects.
  SemiSpace* from = to_;

  const intptr_t kVmNameSize = 128;
  char vm_name[kVmNameSize];
  Heap::RegionName(heap_, Heap::kNew, vm_name, kVmNameSize);
  to_ = SemiSpace::New(NewSizeInWords(from->size_in_words()), vm_name);
  if (to_ == NULL) {
    // TODO(koda): We could try to recover (collect old space, wait for another
    // isolate to finish scavenge, etc.).
    OUT_OF_MEMORY();
  }
  UpdateMaxHeapCapacity();
  top_ = FirstObjectStart();
  resolved_top_ = top_;
  end_ = to_->end();

  return from;
}

void Scavenger::Epilogue(Isolate* isolate,
                         SemiSpace* from,
                         bool invoke_api_callbacks) {
  // All objects in the to space have been copied from the from space at this
  // moment.

  // Ensure the mutator thread will fail the next allocation. This will force
  // mutator to allocate a new TLAB
  if (isolate->IsMutatorThreadScheduled()) {
    Thread* mutator_thread = isolate->mutator_thread();
    ASSERT(!mutator_thread->HasActiveTLAB());
  }

  double avg_frac = stats_history_.Get(0).PromoCandidatesSuccessFraction();
  if (stats_history_.Size() >= 2) {
    // Previous scavenge is only given half as much weight.
    avg_frac += 0.5 * stats_history_.Get(1).PromoCandidatesSuccessFraction();
    avg_frac /= 1.0 + 0.5;  // Normalize.
  }
  if (avg_frac < (FLAG_early_tenuring_threshold / 100.0)) {
    // Remember the limit to which objects have been copied.
    survivor_end_ = top_;
  } else {
    // Move survivor end to the end of the to_ space, making all surviving
    // objects candidates for promotion next time.
    survivor_end_ = end_;
  }
#if defined(DEBUG)
  // We can only safely verify the store buffers from old space if there is no
  // concurrent old space task. At the same time we prevent new tasks from
  // being spawned.
  {
    PageSpace* page_space = heap_->old_space();
    MonitorLocker ml(page_space->tasks_lock());
    if (page_space->tasks() == 0) {
      VerifyStoreBufferPointerVisitor verify_store_buffer_visitor(isolate, to_);
      heap_->old_space()->VisitObjectPointers(&verify_store_buffer_visitor);
    }
  }
#endif  // defined(DEBUG)
  from->Delete();
  UpdateMaxHeapUsage();
  if (heap_ != NULL) {
    heap_->UpdateGlobalMaxUsed();
  }
  if (invoke_api_callbacks && (isolate->gc_epilogue_callback() != NULL)) {
    (isolate->gc_epilogue_callback())();
  }
}

void Scavenger::IterateStoreBuffers(Isolate* isolate,
                                    ScavengerVisitor* visitor) {
  // Iterating through the store buffers.
  // Grab the deduplication sets out of the isolate's consolidated store buffer.
  StoreBufferBlock* pending = isolate->store_buffer()->Blocks();
  intptr_t total_count = 0;
  while (pending != NULL) {
    StoreBufferBlock* next = pending->next();
    // Generated code appends to store buffers; tell MemorySanitizer.
    MSAN_UNPOISON(pending, sizeof(*pending));
    intptr_t count = pending->Count();
    total_count += count;
    while (!pending->IsEmpty()) {
      RawObject* raw_object = pending->Pop();
      if (raw_object->IsForwardingCorpse()) {
        // A source object in a become was a remembered object, but we do
        // not visit the store buffer during become to remove it.
        continue;
      }
      ASSERT(raw_object->IsRemembered());
      raw_object->ClearRememberedBit();
      visitor->VisitingOldObject(raw_object);
      raw_object->VisitPointersNonvirtual(visitor);
    }
    pending->Reset();
    // Return the emptied block for recycling (no need to check threshold).
    isolate->store_buffer()->PushBlock(pending, StoreBuffer::kIgnoreThreshold);
    pending = next;
  }
  heap_->RecordData(kStoreBufferEntries, total_count);
  heap_->RecordData(kDataUnused1, 0);
  heap_->RecordData(kDataUnused2, 0);
  // Done iterating through old objects remembered in the store buffers.
  visitor->VisitingOldObject(NULL);
}

void Scavenger::IterateObjectIdTable(Isolate* isolate,
                                     ScavengerVisitor* visitor) {
#ifndef PRODUCT
  if (!FLAG_support_service) {
    return;
  }
  ObjectIdRing* ring = isolate->object_id_ring();
  if (ring == NULL) {
    // --gc_at_alloc can get us here before the ring has been initialized.
    ASSERT(FLAG_gc_at_alloc);
    return;
  }
  ring->VisitPointers(visitor);
#endif  // !PRODUCT
}

void Scavenger::IterateRoots(Isolate* isolate, ScavengerVisitor* visitor) {
  int64_t start = OS::GetCurrentMonotonicMicros();
  isolate->VisitObjectPointers(visitor,
                               StackFrameIterator::kDontValidateFrames);
  int64_t middle = OS::GetCurrentMonotonicMicros();
  IterateStoreBuffers(isolate, visitor);
  IterateObjectIdTable(isolate, visitor);
  int64_t end = OS::GetCurrentMonotonicMicros();
  heap_->RecordData(kToKBAfterStoreBuffer, RoundWordsToKB(UsedInWords()));
  heap_->RecordTime(kVisitIsolateRoots, middle - start);
  heap_->RecordTime(kIterateStoreBuffers, end - middle);
  heap_->RecordTime(kDummyScavengeTime, 0);
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
  if (to_->Contains(raw_addr)) {
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

void Scavenger::IterateWeakRoots(Isolate* isolate, HandleVisitor* visitor) {
  isolate->VisitWeakPersistentHandles(visitor);
}

void Scavenger::ProcessToSpace(ScavengerVisitor* visitor) {
  // Iterate until all work has been drained.
  while ((resolved_top_ < top_) || PromotedStackHasMore()) {
    while (resolved_top_ < top_) {
      RawObject* raw_obj = RawObject::FromAddr(resolved_top_);
      intptr_t class_id = raw_obj->GetClassId();
      if (class_id != kWeakPropertyCid) {
        resolved_top_ += raw_obj->VisitPointersNonvirtual(visitor);
      } else {
        RawWeakProperty* raw_weak = reinterpret_cast<RawWeakProperty*>(raw_obj);
        resolved_top_ += ProcessWeakProperty(raw_weak, visitor);
      }
    }
    {
      // Visit all the promoted objects and update/scavenge their internal
      // pointers. Potentially this adds more objects to the to space.
      while (PromotedStackHasMore()) {
        RawObject* raw_object = RawObject::FromAddr(PopFromPromotedStack());
        // Resolve or copy all objects referred to by the current object. This
        // can potentially push more objects on this stack as well as add more
        // objects to be resolved in the to space.
        ASSERT(!raw_object->IsRemembered());
        visitor->VisitingOldObject(raw_object);
        raw_object->VisitPointersNonvirtual(visitor);
      }
      visitor->VisitingOldObject(NULL);
    }
    {
      // Finished this round of scavenging. Process the pending weak properties
      // for which the keys have become reachable. Potentially this adds more
      // objects to the to space.
      RawWeakProperty* cur_weak = delayed_weak_properties_;
      delayed_weak_properties_ = NULL;
      while (cur_weak != NULL) {
        uword next_weak = cur_weak->ptr()->next_;
        // Promoted weak properties are not enqueued. So we can guarantee that
        // we do not need to think about store barriers here.
        ASSERT(cur_weak->IsNewObject());
        RawObject* raw_key = cur_weak->ptr()->key_;
        ASSERT(raw_key->IsHeapObject());
        // Key still points into from space even if the object has been
        // promoted to old space by now. The key will be updated accordingly
        // below when VisitPointers is run.
        ASSERT(raw_key->IsNewObject());
        uword raw_addr = RawObject::ToAddr(raw_key);
        ASSERT(visitor->from_->Contains(raw_addr));
        uword header = *reinterpret_cast<uword*>(raw_addr);
        // Reset the next pointer in the weak property.
        cur_weak->ptr()->next_ = 0;
        if (IsForwarding(header)) {
          cur_weak->VisitPointersNonvirtual(visitor);
        } else {
          EnqueueWeakProperty(cur_weak);
        }
        // Advance to next weak property in the queue.
        cur_weak = reinterpret_cast<RawWeakProperty*>(next_weak);
      }
    }
  }
}

void Scavenger::UpdateMaxHeapCapacity() {
#if !defined(PRODUCT)
  if (heap_ == NULL) {
    // Some unit tests.
    return;
  }
  ASSERT(to_ != NULL);
  ASSERT(heap_ != NULL);
  Isolate* isolate = heap_->isolate();
  ASSERT(isolate != NULL);
  isolate->GetHeapNewCapacityMaxMetric()->SetValue(to_->size_in_words() *
                                                   kWordSize);
#endif  // !defined(PRODUCT)
}

void Scavenger::UpdateMaxHeapUsage() {
#if !defined(PRODUCT)
  if (heap_ == NULL) {
    // Some unit tests.
    return;
  }
  ASSERT(to_ != NULL);
  ASSERT(heap_ != NULL);
  Isolate* isolate = heap_->isolate();
  ASSERT(isolate != NULL);
  isolate->GetHeapNewUsedMaxMetric()->SetValue(UsedInWords() * kWordSize);
#endif  // !defined(PRODUCT)
}

void Scavenger::EnqueueWeakProperty(RawWeakProperty* raw_weak) {
  ASSERT(raw_weak->IsHeapObject());
  ASSERT(raw_weak->IsNewObject());
  ASSERT(raw_weak->IsWeakProperty());
#if defined(DEBUG)
  uword raw_addr = RawObject::ToAddr(raw_weak);
  uword header = *reinterpret_cast<uword*>(raw_addr);
  ASSERT(!IsForwarding(header));
#endif  // defined(DEBUG)
  ASSERT(raw_weak->ptr()->next_ == 0);
  raw_weak->ptr()->next_ = reinterpret_cast<uword>(delayed_weak_properties_);
  delayed_weak_properties_ = raw_weak;
}

uword Scavenger::ProcessWeakProperty(RawWeakProperty* raw_weak,
                                     ScavengerVisitor* visitor) {
  // The fate of the weak property is determined by its key.
  RawObject* raw_key = raw_weak->ptr()->key_;
  if (raw_key->IsHeapObject() && raw_key->IsNewObject()) {
    uword raw_addr = RawObject::ToAddr(raw_key);
    uword header = *reinterpret_cast<uword*>(raw_addr);
    if (!IsForwarding(header)) {
      // Key is white.  Enqueue the weak property.
      EnqueueWeakProperty(raw_weak);
      return raw_weak->Size();
    }
  }
  // Key is gray or black.  Make the weak property black.
  return raw_weak->VisitPointersNonvirtual(visitor);
}

void Scavenger::ProcessWeakReferences() {
  // Rehash the weak tables now that we know which objects survive this cycle.
  for (int sel = 0; sel < Heap::kNumWeakSelectors; sel++) {
    WeakTable* table =
        heap_->GetWeakTable(Heap::kNew, static_cast<Heap::WeakSelector>(sel));
    heap_->SetWeakTable(Heap::kNew, static_cast<Heap::WeakSelector>(sel),
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
          heap_->SetWeakEntry(raw_obj, static_cast<Heap::WeakSelector>(sel),
                              table->ValueAt(i));
        }
      }
    }
    // Remove the old table as it has been replaced with the newly allocated
    // table above.
    delete table;
  }

  // The queued weak properties at this point do not refer to reachable keys,
  // so we clear their key and value fields.
  {
    RawWeakProperty* cur_weak = delayed_weak_properties_;
    delayed_weak_properties_ = NULL;
    while (cur_weak != NULL) {
      uword next_weak = cur_weak->ptr()->next_;
      // Reset the next pointer in the weak property.
      cur_weak->ptr()->next_ = 0;

#if defined(DEBUG)
      RawObject* raw_key = cur_weak->ptr()->key_;
      uword raw_addr = RawObject::ToAddr(raw_key);
      uword header = *reinterpret_cast<uword*>(raw_addr);
      ASSERT(!IsForwarding(header));
      ASSERT(raw_key->IsHeapObject());
      ASSERT(raw_key->IsNewObject());  // Key still points into from space.
#endif                                 // defined(DEBUG)

      WeakProperty::Clear(cur_weak);

      // Advance to next weak property in the queue.
      cur_weak = reinterpret_cast<RawWeakProperty*>(next_weak);
    }
  }
}

void Scavenger::MakeNewSpaceIterable() const {
  ASSERT(heap_ != NULL);
  if (heap_->isolate()->IsMutatorThreadScheduled() && !scavenging_) {
    Thread* mutator_thread = heap_->isolate()->mutator_thread();
    if (mutator_thread->HasActiveTLAB()) {
      ASSERT(mutator_thread->top() <=
             mutator_thread->heap()->new_space()->top());
      heap_->FillRemainingTLAB(mutator_thread);
    }
  }
}

void Scavenger::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  MakeNewSpaceIterable();
  uword cur = FirstObjectStart();
  while (cur < top_) {
    RawObject* raw_obj = RawObject::FromAddr(cur);
    cur += raw_obj->VisitPointers(visitor);
  }
}

void Scavenger::VisitObjects(ObjectVisitor* visitor) const {
  MakeNewSpaceIterable();
  uword cur = FirstObjectStart();
  while (cur < top_) {
    RawObject* raw_obj = RawObject::FromAddr(cur);
    visitor->VisitObject(raw_obj);
    cur += raw_obj->Size();
  }
}

void Scavenger::AddRegionsToObjectSet(ObjectSet* set) const {
  set->AddRegion(to_->start(), to_->end());
}

RawObject* Scavenger::FindObject(FindObjectVisitor* visitor) const {
  ASSERT(!scavenging_);
  MakeNewSpaceIterable();
  uword cur = FirstObjectStart();
  if (visitor->VisitRange(cur, top_)) {
    while (cur < top_) {
      RawObject* raw_obj = RawObject::FromAddr(cur);
      uword next = cur + raw_obj->Size();
      if (visitor->VisitRange(cur, next) && raw_obj->FindObject(visitor)) {
        return raw_obj;  // Found object, return it.
      }
      cur = next;
    }
    ASSERT(cur == top_);
  }
  return Object::null();
}

void Scavenger::Scavenge() {
  // TODO(cshapiro): Add a decision procedure for determining when the
  // the API callbacks should be invoked.
  Scavenge(false);
}

void Scavenger::Scavenge(bool invoke_api_callbacks) {
  Isolate* isolate = heap_->isolate();
  // Ensure that all threads for this isolate are at a safepoint (either stopped
  // or in native code). If two threads are racing at this point, the loser
  // will continue with its scavenge after waiting for the winner to complete.
  // TODO(koda): Consider moving SafepointThreads into allocation failure/retry
  // logic to avoid needless collections.

  int64_t pre_safe_point = OS::GetCurrentMonotonicMicros();

  Thread* thread = Thread::Current();
  SafepointOperationScope safepoint_scope(thread);

  // Scavenging is not reentrant. Make sure that is the case.
  ASSERT(!scavenging_);
  scavenging_ = true;

  failed_to_promote_ = false;

  PageSpace* page_space = heap_->old_space();
  NoSafepointScope no_safepoints;

  int64_t post_safe_point = OS::GetCurrentMonotonicMicros();
  heap_->RecordTime(kSafePoint, post_safe_point - pre_safe_point);

  if (isolate->IsMutatorThreadScheduled()) {
    Thread* mutator_thread = isolate->mutator_thread();
    if (mutator_thread->HasActiveTLAB()) {
      heap_->AbandonRemainingTLAB(mutator_thread);
    }
  }

  // TODO(koda): Make verification more compatible with concurrent sweep.
  if (FLAG_verify_before_gc && !FLAG_concurrent_sweep) {
    OS::PrintErr("Verifying before Scavenge...");
    heap_->Verify(kForbidMarked);
    OS::PrintErr(" done.\n");
  }

  // Prepare for a scavenge.
  SpaceUsage usage_before = GetCurrentUsage();
  intptr_t promo_candidate_words =
      (survivor_end_ - FirstObjectStart()) / kWordSize;
  SemiSpace* from = Prologue(isolate, invoke_api_callbacks);
  // The API prologue/epilogue may create/destroy zones, so we must not
  // depend on zone allocations surviving beyond the epilogue callback.
  {
    StackZone zone(thread);
    // Setup the visitor and run the scavenge.
    ScavengerVisitor visitor(isolate, this, from);
    page_space->AcquireDataLock();
    IterateRoots(isolate, &visitor);
    int64_t start = OS::GetCurrentMonotonicMicros();
    ProcessToSpace(&visitor);
    int64_t middle = OS::GetCurrentMonotonicMicros();
    {
      TIMELINE_FUNCTION_GC_DURATION(thread, "WeakHandleProcessing");
      ScavengerWeakVisitor weak_visitor(thread, this);
      IterateWeakRoots(isolate, &weak_visitor);
    }
    ProcessWeakReferences();
    page_space->ReleaseDataLock();

    // Scavenge finished. Run accounting.
    int64_t end = OS::GetCurrentMonotonicMicros();
    heap_->RecordTime(kProcessToSpace, middle - start);
    heap_->RecordTime(kIterateWeaks, end - middle);
    stats_history_.Add(ScavengeStats(
        start, end, usage_before, GetCurrentUsage(), promo_candidate_words,
        visitor.bytes_promoted() >> kWordSizeLog2));
  }
  Epilogue(isolate, from, invoke_api_callbacks);

  // TODO(koda): Make verification more compatible with concurrent sweep.
  if (FLAG_verify_after_gc && !FLAG_concurrent_sweep) {
    OS::PrintErr("Verifying after Scavenge...");
    heap_->Verify(kForbidMarked);
    OS::PrintErr(" done.\n");
  }

  // Done scavenging. Reset the marker.
  ASSERT(scavenging_);
  scavenging_ = false;
}

void Scavenger::WriteProtect(bool read_only) {
  ASSERT(!scavenging_);
  to_->WriteProtect(read_only);
}

#ifndef PRODUCT
void Scavenger::PrintToJSONObject(JSONObject* object) const {
  if (!FLAG_support_service) {
    return;
  }
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  JSONObject space(object, "new");
  space.AddProperty("type", "HeapSpace");
  space.AddProperty("name", "new");
  space.AddProperty("vmName", "Scavenger");
  space.AddProperty("collections", collections());
  if (collections() > 0) {
    int64_t run_time = isolate->UptimeMicros();
    run_time = Utils::Maximum(run_time, static_cast<int64_t>(0));
    double run_time_millis = MicrosecondsToMilliseconds(run_time);
    double avg_time_between_collections =
        run_time_millis / static_cast<double>(collections());
    space.AddProperty("avgCollectionPeriodMillis",
                      avg_time_between_collections);
  } else {
    space.AddProperty("avgCollectionPeriodMillis", 0.0);
  }
  space.AddProperty64("used", UsedInWords() * kWordSize);
  space.AddProperty64("capacity", CapacityInWords() * kWordSize);
  space.AddProperty64("external", ExternalInWords() * kWordSize);
  space.AddProperty("time", MicrosecondsToSeconds(gc_time_micros()));
}
#endif  // !PRODUCT

void Scavenger::AllocateExternal(intptr_t size) {
  ASSERT(size >= 0);
  external_size_ += size;
}

void Scavenger::FreeExternal(intptr_t size) {
  ASSERT(size >= 0);
  external_size_ -= size;
  ASSERT(external_size_ >= 0);
}

void Scavenger::Evacuate() {
  // We need a safepoint here to prevent allocation right before or right after
  // the scavenge.
  // The former can introduce an object that we might fail to collect.
  // The latter means even if the scavenge promotes every object in the new
  // space, the new allocation means the space is not empty,
  // causing the assertion below to fail.
  SafepointOperationScope scope(Thread::Current());

  // Forces the next scavenge to promote all the objects in the new space.
  survivor_end_ = top_;

  Scavenge();

  // It is possible for objects to stay in the new space
  // if the VM cannot create more pages for these objects.
  ASSERT((UsedInWords() == 0) || failed_to_promote_);
}

int64_t Scavenger::UsedInWords() const {
  int64_t free_space_in_tlab = 0;
  if (heap_->isolate()->IsMutatorThreadScheduled()) {
    Thread* mutator_thread = heap_->isolate()->mutator_thread();
    if (mutator_thread->HasActiveTLAB()) {
      free_space_in_tlab =
          (mutator_thread->end() - mutator_thread->top()) >> kWordSizeLog2;
    }
  }
  int64_t max_space_used = (top_ - FirstObjectStart()) >> kWordSizeLog2;
  return max_space_used - free_space_in_tlab;
}

}  // namespace dart
