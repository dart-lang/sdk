// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/scavenger.h"

#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/flag_list.h"
#include "vm/heap/pointer_block.h"
#include "vm/heap/safepoint.h"
#include "vm/heap/verifier.h"
#include "vm/heap/weak_table.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_set.h"
#include "vm/stack_frame.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

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
DEFINE_FLAG(int, new_gen_growth_factor, 2, "Grow new gen by this factor.");

// Scavenger uses RawObject::kMarkBit to distinguish forwarded and non-forwarded
// objects. The kMarkBit does not intersect with the target address because of
// object alignment.
enum {
  kForwardingMask = 1 << RawObject::kOldAndNotMarkedBit,
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

static inline void objcpy(void* dst, const void* src, size_t size) {
  // A memcopy specialized for objects. We can assume:
  //  - dst and src do not overlap
  ASSERT(
      (reinterpret_cast<uword>(dst) + size <= reinterpret_cast<uword>(src)) ||
      (reinterpret_cast<uword>(src) + size <= reinterpret_cast<uword>(dst)));
  //  - dst and src are word aligned
  ASSERT(Utils::IsAligned(reinterpret_cast<uword>(dst), sizeof(uword)));
  ASSERT(Utils::IsAligned(reinterpret_cast<uword>(src), sizeof(uword)));
  //  - size is strictly positive
  ASSERT(size > 0);
  //  - size is a multiple of double words
  ASSERT(Utils::IsAligned(size, 2 * sizeof(uword)));

  uword* __restrict dst_cursor = reinterpret_cast<uword*>(dst);
  const uword* __restrict src_cursor = reinterpret_cast<const uword*>(src);
  do {
    uword a = *src_cursor++;
    uword b = *src_cursor++;
    *dst_cursor++ = a;
    *dst_cursor++ = b;
    size -= (2 * sizeof(uword));
  } while (size > 0);
}

class ScavengerVisitor : public ObjectPointerVisitor {
 public:
  explicit ScavengerVisitor(IsolateGroup* isolate_group,
                            Scavenger* scavenger,
                            SemiSpace* from)
      : ObjectPointerVisitor(isolate_group),
        thread_(Thread::Current()),
        scavenger_(scavenger),
        from_(from),
        heap_(scavenger->heap_),
        page_space_(scavenger->heap_->old_space()),
        bytes_promoted_(0),
        visiting_old_object_(NULL) {}

  virtual void VisitTypedDataViewPointers(RawTypedDataView* view,
                                          RawObject** first,
                                          RawObject** last) {
    // First we forward all fields of the typed data view.
    VisitPointers(first, last);

    if (view->ptr()->data_ == nullptr) {
      ASSERT(ValueFromRawSmi(view->ptr()->offset_in_bytes_) == 0 &&
             ValueFromRawSmi(view->ptr()->length_) == 0);
      return;
    }

    // Validate 'this' is a typed data view.
    const uword view_header =
        *reinterpret_cast<uword*>(RawObject::ToAddr(view));
    ASSERT(!IsForwarding(view_header) || view->IsOldObject());
    ASSERT(RawObject::IsTypedDataViewClassId(view->GetClassIdMayBeSmi()));

    // Validate that the backing store is not a forwarding word.
    RawTypedDataBase* td = view->ptr()->typed_data_;
    ASSERT(td->IsHeapObject());
    const uword td_header = *reinterpret_cast<uword*>(RawObject::ToAddr(td));
    ASSERT(!IsForwarding(td_header) || td->IsOldObject());

    // We can always obtain the class id from the forwarded backing store.
    const classid_t cid = td->GetClassId();

    // If we have external typed data we can simply return since the backing
    // store lives in C-heap and will not move.
    if (RawObject::IsExternalTypedDataClassId(cid)) {
      return;
    }

    // Now we update the inner pointer.
    ASSERT(RawObject::IsTypedDataClassId(cid));
    view->RecomputeDataFieldForInternalTypedData();
  }

  virtual void VisitPointers(RawObject** first, RawObject** last) {
    ASSERT(Utils::IsAligned(first, sizeof(*first)));
    ASSERT(Utils::IsAligned(last, sizeof(*last)));
    for (RawObject** current = first; current <= last; current++) {
      ScavengePointer(current);
    }
  }

  void VisitingOldObject(RawObject* obj) {
    ASSERT((obj == NULL) || obj->IsOldObject());
    visiting_old_object_ = obj;
    if (obj != NULL) {
      // Card update happens in HeapPage::VisitRememberedCards.
      ASSERT(!obj->IsCardRemembered());
    }
  }

  intptr_t bytes_promoted() const { return bytes_promoted_; }

 private:
  void UpdateStoreBuffer(RawObject** p, RawObject* obj) {
    ASSERT(obj->IsHeapObject());
    // If the newly written object is not a new object, drop it immediately.
    if (!obj->IsNewObject() || visiting_old_object_->IsRemembered()) {
      return;
    }
    visiting_old_object_->SetRememberedBit();
    thread_->StoreBufferAddObjectGC(visiting_old_object_);
  }

  DART_FORCE_INLINE
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
      intptr_t size = raw_obj->HeapSize();
      // Check whether object should be promoted.
      if (scavenger_->survivor_end_ <= raw_addr) {
        // Not a survivor of a previous scavenge. Just copy the object into the
        // to space.
        new_addr = scavenger_->AllocateGC(size);
      } else {
        // TODO(iposva): Experiment with less aggressive promotion. For example
        // a coin toss determines if an object is promoted or whether it should
        // survive in this generation.
        //
        // This object is a survivor of a previous scavenge. Attempt to promote
        // the object.
        new_addr = page_space_->TryAllocatePromoLocked(size);
        if (new_addr != 0) {
          // If promotion succeeded then we need to remember it so that it can
          // be traversed later.
          scavenger_->PushToPromotedStack(new_addr);
          bytes_promoted_ += size;
        } else {
          // Promotion did not succeed. Copy into the to space instead.
          scavenger_->failed_to_promote_ = true;
          new_addr = scavenger_->AllocateGC(size);
        }
      }
      // During a scavenge we always succeed to at least copy all of the
      // current objects to the to space.
      ASSERT(new_addr != 0);
      // Copy the object to the new location.
      objcpy(reinterpret_cast<void*>(new_addr),
             reinterpret_cast<void*>(raw_addr), size);

      RawObject* new_obj = RawObject::FromAddr(new_addr);
      if (new_obj->IsOldObject()) {
        // Promoted: update age/barrier tags.
        uint32_t tags = new_obj->ptr()->tags_;
        tags = RawObject::OldBit::update(true, tags);
        tags = RawObject::OldAndNotRememberedBit::update(true, tags);
        tags = RawObject::NewBit::update(false, tags);
        // Setting the forwarding pointer below will make this tenured object
        // visible to the concurrent marker, but we haven't visited its slots
        // yet. We mark the object here to prevent the concurrent marker from
        // adding it to the mark stack and visiting its unprocessed slots. We
        // push it to the mark stack after forwarding its slots.
        tags =
            RawObject::OldAndNotMarkedBit::update(!thread_->is_marking(), tags);
        new_obj->ptr()->tags_ = tags;
      }

      if (RawObject::IsTypedDataClassId(new_obj->GetClassId())) {
        reinterpret_cast<RawTypedData*>(new_obj)->RecomputeDataField();
      }

      // Remember forwarding address.
      ForwardTo(raw_addr, new_addr);
    }
    // Update the reference.
    RawObject* new_obj = RawObject::FromAddr(new_addr);
    if (new_obj->IsOldObject()) {
      // Setting the mark bit above must not be ordered after a publishing store
      // of this object. Note this could be a publishing store even if the
      // object was promoted by an early invocation of ScavengePointer. Compare
      // Object::Allocate.
      reinterpret_cast<std::atomic<RawObject*>*>(p)->store(
          new_obj, std::memory_order_release);
    } else {
      *p = new_obj;
    }
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
      : HandleVisitor(thread),
        scavenger_(scavenger),
        class_table_(thread->isolate_group()->class_table()) {
    ASSERT(scavenger->heap_->isolate_group() == thread->isolate_group());
  }

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    RawObject** p = handle->raw_addr();
    if (scavenger_->IsUnreachable(p)) {
      handle->UpdateUnreachable(thread()->isolate_group());
    } else {
      handle->UpdateRelocated(thread()->isolate_group());
    }
  }

 private:
  Scavenger* scavenger_;
  SharedClassTable* class_table_;

  DISALLOW_COPY_AND_ASSIGN(ScavengerWeakVisitor);
};

// Visitor used to verify that all old->new references have been added to the
// StoreBuffers.
class VerifyStoreBufferPointerVisitor : public ObjectPointerVisitor {
 public:
  VerifyStoreBufferPointerVisitor(IsolateGroup* isolate_group,
                                  const SemiSpace* to)
      : ObjectPointerVisitor(isolate_group), to_(to) {}

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
  delete reserved_;
}

Mutex* SemiSpace::mutex_ = NULL;
SemiSpace* SemiSpace::cache_ = NULL;

void SemiSpace::Init() {
  if (mutex_ == NULL) {
    mutex_ = new Mutex();
  }
  ASSERT(mutex_ != NULL);
}

void SemiSpace::Cleanup() {
  MutexLocker locker(mutex_);
  delete cache_;
  cache_ = NULL;
}

SemiSpace* SemiSpace::New(intptr_t size_in_words, const char* name) {
  SemiSpace* result = nullptr;
  {
    MutexLocker locker(mutex_);
    // TODO(koda): Cache one entry per size.
    if (cache_ != nullptr && cache_->size_in_words() == size_in_words) {
      result = cache_;
      cache_ = nullptr;
    }
  }
  if (result != nullptr) {
#ifdef DEBUG
    result->reserved_->Protect(VirtualMemory::kReadWrite);
#endif
    // Initialized by generated code.
    MSAN_UNPOISON(result->reserved_->address(), size_in_words << kWordSizeLog2);
    return result;
  }

  if (size_in_words == 0) {
    return new SemiSpace(nullptr);
  } else {
    intptr_t size_in_bytes = size_in_words << kWordSizeLog2;
    const bool kExecutable = false;
    VirtualMemory* memory =
        VirtualMemory::Allocate(size_in_bytes, kExecutable, name);
    if (memory == nullptr) {
      // TODO(koda): If cache_ is not empty, we could try to delete it.
      return nullptr;
    }
#if defined(DEBUG)
    memset(memory->address(), Heap::kZapByte, size_in_bytes);
#endif  // defined(DEBUG)
    // Initialized by generated code.
    MSAN_UNPOISON(memory->address(), size_in_bytes);
    return new SemiSpace(memory);
  }
}

void SemiSpace::Delete() {
  if (reserved_ != nullptr) {
    const intptr_t size_in_bytes = size_in_words() << kWordSizeLog2;
#ifdef DEBUG
    memset(reserved_->address(), Heap::kZapByte, size_in_bytes);
    reserved_->Protect(VirtualMemory::kNoAccess);
#endif
    MSAN_POISON(reserved_->address(), size_in_bytes);
  }
  SemiSpace* old_cache = nullptr;
  {
    MutexLocker locker(mutex_);
    old_cache = cache_;
    cache_ = this;
  }
  delete old_cache;
}

void SemiSpace::WriteProtect(bool read_only) {
  if (reserved_ != NULL) {
    reserved_->Protect(read_only ? VirtualMemory::kReadOnly
                                 : VirtualMemory::kReadWrite);
  }
}

// The initial estimate of how many words we can scavenge per microsecond (usage
// before / scavenge time). This is a conservative value observed running
// Flutter on a Nexus 4. After the first scavenge, we instead use a value based
// on the device's actual speed.
static const intptr_t kConservativeInitialScavengeSpeed = 40;

Scavenger::Scavenger(Heap* heap, intptr_t max_semi_capacity_in_words)
    : heap_(heap),
      max_semi_capacity_in_words_(max_semi_capacity_in_words),
      scavenging_(false),
      delayed_weak_properties_(NULL),
      gc_time_micros_(0),
      collections_(0),
      scavenge_words_per_micro_(kConservativeInitialScavengeSpeed),
      idle_scavenge_threshold_in_words_(0),
      external_size_(0),
      failed_to_promote_(false) {
  // Verify assumptions about the first word in objects which the scavenger is
  // going to use for forwarding pointers.
  ASSERT(Object::tags_offset() == 0);

  // Set initial semi space size in words.
  const intptr_t initial_semi_capacity_in_words = Utils::Minimum(
      max_semi_capacity_in_words, FLAG_new_gen_semi_initial_size * MBInWords);

  const char* name = Heap::RegionName(Heap::kNew);
  to_ = SemiSpace::New(initial_semi_capacity_in_words, name);
  if (to_ == NULL) {
    OUT_OF_MEMORY();
  }
  // Setup local fields.
  top_ = FirstObjectStart();
  resolved_top_ = top_;
  end_ = to_->end();

  survivor_end_ = FirstObjectStart();
  idle_scavenge_threshold_in_words_ = initial_semi_capacity_in_words;

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
  double garbage = stats_history_.Get(0).ExpectedGarbageFraction();
  if (garbage < (FLAG_new_gen_garbage_threshold / 100.0)) {
    return Utils::Minimum(max_semi_capacity_in_words_,
                          old_size_in_words * FLAG_new_gen_growth_factor);
  } else {
    return old_size_in_words;
  }
}

SemiSpace* Scavenger::Prologue(IsolateGroup* isolate_group) {
  isolate_group->ReleaseStoreBuffers();

  // Flip the two semi-spaces so that to_ is always the space for allocating
  // objects.
  SemiSpace* from = to_;

  const char* name = Heap::RegionName(Heap::kNew);
  to_ = SemiSpace::New(NewSizeInWords(from->size_in_words()), name);
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

void Scavenger::Epilogue(IsolateGroup* isolate_group, SemiSpace* from) {
  // All objects in the to space have been copied from the from space at this
  // moment.

  // Ensure the mutator thread will fail the next allocation. This will force
  // mutator to allocate a new TLAB
  isolate_group->ForEachIsolate(
      [&](Isolate* isolate) {
        Thread* mutator_thread = isolate->mutator_thread();
        ASSERT((mutator_thread == NULL) || (!mutator_thread->HasActiveTLAB()));
      },
      /*at_safepoint=*/true);

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

  // Update estimate of scavenger speed. This statistic assumes survivorship
  // rates don't change much.
  intptr_t history_used = 0;
  intptr_t history_micros = 0;
  ASSERT(stats_history_.Size() > 0);
  for (intptr_t i = 0; i < stats_history_.Size(); i++) {
    history_used += stats_history_.Get(i).UsedBeforeInWords();
    history_micros += stats_history_.Get(i).DurationMicros();
  }
  if (history_micros == 0) {
    history_micros = 1;
  }
  scavenge_words_per_micro_ = history_used / history_micros;
  if (scavenge_words_per_micro_ == 0) {
    scavenge_words_per_micro_ = 1;
  }

  // Update amount of new-space we must allocate before performing an idle
  // scavenge. This is based on the amount of work we expect to be able to
  // complete in a typical idle period.
  intptr_t average_idle_task_micros = 6000;
  idle_scavenge_threshold_in_words_ =
      scavenge_words_per_micro_ * average_idle_task_micros;
  // Even if the scavenge speed is slow, make sure we don't scavenge too
  // frequently, which just wastes power and falsely increases the promotion
  // rate.
  intptr_t lower_bound = 512 * KBInWords;
  if (idle_scavenge_threshold_in_words_ < lower_bound) {
    idle_scavenge_threshold_in_words_ = lower_bound;
  }
  // Even if the scavenge speed is very high, make sure we start considering
  // idle scavenges before new space is full to avoid requiring a scavenge in
  // the middle of a frame.
  intptr_t upper_bound = 8 * CapacityInWords() / 10;
  if (idle_scavenge_threshold_in_words_ > upper_bound) {
    idle_scavenge_threshold_in_words_ = upper_bound;
  }

#if defined(DEBUG)
  // We can only safely verify the store buffers from old space if there is no
  // concurrent old space task. At the same time we prevent new tasks from
  // being spawned.
  {
    PageSpace* page_space = heap_->old_space();
    MonitorLocker ml(page_space->tasks_lock());
    if (page_space->tasks() == 0) {
      VerifyStoreBufferPointerVisitor verify_store_buffer_visitor(isolate_group,
                                                                  to_);
      heap_->old_space()->VisitObjectPointers(&verify_store_buffer_visitor);
    }
  }
#endif  // defined(DEBUG)
  from->Delete();
  UpdateMaxHeapUsage();
  if (heap_ != NULL) {
    heap_->UpdateGlobalMaxUsed();
  }
}

bool Scavenger::ShouldPerformIdleScavenge(int64_t deadline) {
  // To make a consistent decision, we should not yield for a safepoint in the
  // middle of deciding whether to perform an idle GC.
  NoSafepointScope no_safepoint;

  // TODO(rmacnak): Investigate collecting a history of idle period durations.
  intptr_t used_in_words = UsedInWords();
  if (used_in_words < idle_scavenge_threshold_in_words_) {
    return false;
  }
  int64_t estimated_scavenge_completion =
      OS::GetCurrentMonotonicMicros() +
      used_in_words / scavenge_words_per_micro_;
  return estimated_scavenge_completion <= deadline;
}

void Scavenger::IterateStoreBuffers(IsolateGroup* isolate_group,
                                    ScavengerVisitor* visitor) {
  // Iterating through the store buffers.
  // Grab the deduplication sets out of the isolate's consolidated store buffer.
  StoreBufferBlock* pending = isolate_group->store_buffer()->Blocks();
  intptr_t total_count = 0;
  while (pending != NULL) {
    StoreBufferBlock* next = pending->next();
    // Generated code appends to store buffers; tell MemorySanitizer.
    MSAN_UNPOISON(pending, sizeof(*pending));
    intptr_t count = pending->Count();
    total_count += count;
    while (!pending->IsEmpty()) {
      RawObject* raw_object = pending->Pop();
      ASSERT(!raw_object->IsForwardingCorpse());
      ASSERT(raw_object->IsRemembered());
      raw_object->ClearRememberedBit();
      visitor->VisitingOldObject(raw_object);
      raw_object->VisitPointersNonvirtual(visitor);
    }
    pending->Reset();
    // Return the emptied block for recycling (no need to check threshold).
    isolate_group->store_buffer()->PushBlock(pending,
                                             StoreBuffer::kIgnoreThreshold);
    pending = next;
  }

  visitor->VisitingOldObject(NULL);
  heap_->old_space()->VisitRememberedCards(visitor);

  heap_->RecordData(kStoreBufferEntries, total_count);
  heap_->RecordData(kDataUnused1, 0);
  heap_->RecordData(kDataUnused2, 0);
  // Done iterating through old objects remembered in the store buffers.
  visitor->VisitingOldObject(NULL);
}

void Scavenger::IterateObjectIdTable(IsolateGroup* isolate_group,
                                     ScavengerVisitor* visitor) {
#ifndef PRODUCT
  isolate_group->ForEachIsolate(
      [&](Isolate* isolate) {
        isolate->object_id_ring()->VisitPointers(visitor);
      },
      /*at_safepoint=*/true);
#endif  // !PRODUCT
}

void Scavenger::IterateRoots(IsolateGroup* isolate_group,
                             ScavengerVisitor* visitor) {
#ifdef SUPPORT_TIMELINE
  Thread* thread = Thread::Current();
#endif
  int64_t start = OS::GetCurrentMonotonicMicros();
  {
    TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessRoots");
    isolate_group->VisitObjectPointers(visitor,
                                       ValidationPolicy::kDontValidateFrames);
  }
  int64_t middle = OS::GetCurrentMonotonicMicros();
  {
    TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessRememberedSet");
    IterateStoreBuffers(isolate_group, visitor);
  }
  IterateObjectIdTable(isolate_group, visitor);
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

void Scavenger::IterateWeakRoots(IsolateGroup* isolate_group,
                                 HandleVisitor* visitor) {
  isolate_group->VisitWeakPersistentHandles(visitor);
}

void Scavenger::ProcessToSpace(ScavengerVisitor* visitor) {
  Thread* thread = Thread::Current();

  // Iterate until all work has been drained.
  while ((resolved_top_ < top_) || PromotedStackHasMore()) {
    while (resolved_top_ < top_) {
      RawObject* raw_obj = RawObject::FromAddr(resolved_top_);
      intptr_t class_id = raw_obj->GetClassId();
      intptr_t size;
      if (class_id != kWeakPropertyCid) {
        size = raw_obj->VisitPointersNonvirtual(visitor);
      } else {
        RawWeakProperty* raw_weak = reinterpret_cast<RawWeakProperty*>(raw_obj);
        size = ProcessWeakProperty(raw_weak, visitor);
      }
      resolved_top_ += size;
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
        if (raw_object->IsMarked()) {
          // Complete our promise from ScavengePointer. Note that marker cannot
          // visit this object until it pops a block from the mark stack, which
          // involves a memory fence from the mutex, so even on architectures
          // with a relaxed memory model, the marker will see the fully
          // forwarded contents of this object.
          thread->MarkingStackAddObject(raw_object);
        }
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
  auto isolate_group = heap_->isolate_group();
  ASSERT(isolate_group != NULL);
  isolate_group->GetHeapNewCapacityMaxMetric()->SetValue(to_->size_in_words() *
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
  auto isolate_group = heap_->isolate_group();
  ASSERT(isolate_group != NULL);
  isolate_group->GetHeapNewUsedMaxMetric()->SetValue(UsedInWords() * kWordSize);
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
      return raw_weak->HeapSize();
    }
  }
  // Key is gray or black.  Make the weak property black.
  return raw_weak->VisitPointersNonvirtual(visitor);
}

void Scavenger::ProcessWeakReferences() {
  auto rehash_weak_table = [](WeakTable* table, WeakTable* replacement_new,
                              WeakTable* replacement_old) {
    intptr_t size = table->size();
    for (intptr_t i = 0; i < size; i++) {
      if (table->IsValidEntryAtExclusive(i)) {
        RawObject* raw_obj = table->ObjectAtExclusive(i);
        ASSERT(raw_obj->IsHeapObject());
        uword raw_addr = RawObject::ToAddr(raw_obj);
        uword header = *reinterpret_cast<uword*>(raw_addr);
        if (IsForwarding(header)) {
          // The object has survived.  Preserve its record.
          uword new_addr = ForwardedAddr(header);
          raw_obj = RawObject::FromAddr(new_addr);
          auto replacement =
              raw_obj->IsNewObject() ? replacement_new : replacement_old;
          replacement->SetValueExclusive(raw_obj, table->ValueAtExclusive(i));
        }
      }
    }
  };

  // Rehash the weak tables now that we know which objects survive this cycle.
  for (int sel = 0; sel < Heap::kNumWeakSelectors; sel++) {
    const auto selector = static_cast<Heap::WeakSelector>(sel);
    auto table = heap_->GetWeakTable(Heap::kNew, selector);
    auto table_old = heap_->GetWeakTable(Heap::kOld, selector);

    // Create a new weak table for the new-space.
    auto table_new = WeakTable::NewFrom(table);
    rehash_weak_table(table, table_new, table_old);
    heap_->SetWeakTable(Heap::kNew, selector, table_new);

    // Remove the old table as it has been replaced with the newly allocated
    // table above.
    delete table;
  }

  // Each isolate might have a weak table used for fast snapshot writing (i.e.
  // isolate communication). Rehash those tables if need be.
  heap_->isolate_group()->ForEachIsolate(
      [&](Isolate* isolate) {
        auto table = isolate->forward_table_new();
        if (table != nullptr) {
          auto replacement = WeakTable::NewFrom(table);
          rehash_weak_table(table, replacement, isolate->forward_table_old());
          isolate->set_forward_table_new(replacement);
        }
      },
      /*at_safepoint=*/true);

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
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask) ||
         (Thread::Current()->task_kind() == Thread::kCompactorTask));
  auto isolate_group = heap_->isolate_group();
  MonitorLocker ml(isolate_group->threads_lock(), false);
  Thread* current = heap_->isolate_group()->thread_registry()->active_list();
  while (current != NULL) {
    if (current->HasActiveTLAB()) {
      heap_->MakeTLABIterable(current);
    }
    current = current->next();
  }
  isolate_group->ForEachIsolate(
      [&](Isolate* isolate) {
        Thread* mutator_thread = isolate->mutator_thread();
        if (mutator_thread != NULL) {
          heap_->MakeTLABIterable(mutator_thread);
        }
      },
      /*at_safepoint=*/true);
}

void Scavenger::AbandonTLABs(IsolateGroup* isolate_group) {
  ASSERT(Thread::Current()->IsAtSafepoint());
  MonitorLocker ml(isolate_group->threads_lock(), false);
  Thread* current = isolate_group->thread_registry()->active_list();
  while (current != NULL) {
    heap_->AbandonRemainingTLAB(current);
    current = current->next();
  }
  isolate_group->ForEachIsolate(
      [&](Isolate* isolate) {
        Thread* mutator_thread = isolate->mutator_thread();
        if (mutator_thread != NULL) {
          heap_->AbandonRemainingTLAB(mutator_thread);
        }
      },
      /*at_safepoint=*/true);
}

void Scavenger::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask) ||
         (Thread::Current()->task_kind() == Thread::kCompactorTask));
  MakeNewSpaceIterable();
  uword cur = FirstObjectStart();
  while (cur < top_) {
    RawObject* raw_obj = RawObject::FromAddr(cur);
    cur += raw_obj->VisitPointers(visitor);
  }
}

void Scavenger::VisitObjects(ObjectVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask));
  MakeNewSpaceIterable();
  uword cur = FirstObjectStart();
  while (cur < top_) {
    RawObject* raw_obj = RawObject::FromAddr(cur);
    visitor->VisitObject(raw_obj);
    cur += raw_obj->HeapSize();
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
      uword next = cur + raw_obj->HeapSize();
      if (visitor->VisitRange(cur, next) && raw_obj->FindObject(visitor)) {
        return raw_obj;  // Found object, return it.
      }
      cur = next;
    }
    ASSERT(cur == top_);
  }
  return Object::null();
}

uword Scavenger::TryAllocateNewTLAB(Thread* thread, intptr_t size) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  ASSERT(heap_ != Dart::vm_isolate()->heap());
  ASSERT(!scavenging_);
  MutexLocker ml(&space_lock_);
  uword result = top_;
  intptr_t remaining = end_ - top_;
  if (remaining < size) {
    // Grab whatever is remaining
    size = remaining;
  } else {
    // Reduce TLAB size so we land at even TLAB size for future TLABs.
    intptr_t survived_size = UsedInWords() * kWordSize;
    size -= survived_size % size;
  }
  size = Utils::RoundDown(size, kObjectAlignment);
  if (size == 0) {
    return 0;
  }
  ASSERT(to_->Contains(result));
  ASSERT((result & kObjectAlignmentMask) == kNewObjectAlignmentOffset);
  top_ += size;
  ASSERT(to_->Contains(top_) || (top_ == to_->end()));
  ASSERT(result < top_);
  thread->set_top(result);
  thread->set_end(top_);
  return result;
}

void Scavenger::Scavenge() {
  auto isolate_group = heap_->isolate_group();
  // Ensure that all threads for this isolate are at a safepoint (either stopped
  // or in native code). If two threads are racing at this point, the loser
  // will continue with its scavenge after waiting for the winner to complete.
  // TODO(koda): Consider moving SafepointThreads into allocation failure/retry
  // logic to avoid needless collections.

  int64_t start = OS::GetCurrentMonotonicMicros();

  Thread* thread = Thread::Current();
  SafepointOperationScope safepoint_scope(thread);

  // Scavenging is not reentrant. Make sure that is the case.
  ASSERT(!scavenging_);
  scavenging_ = true;

  failed_to_promote_ = false;

  PageSpace* page_space = heap_->old_space();
  NoSafepointScope no_safepoints;

  int64_t safe_point = OS::GetCurrentMonotonicMicros();
  heap_->RecordTime(kSafePoint, safe_point - start);

  // TODO(koda): Make verification more compatible with concurrent sweep.
  if (FLAG_verify_before_gc && !FLAG_concurrent_sweep) {
    OS::PrintErr("Verifying before Scavenge...");
    heap_->VerifyGC(kForbidMarked);
    OS::PrintErr(" done.\n");
  }

  // Prepare for a scavenge.
  AbandonTLABs(isolate_group);
  intptr_t abandoned_bytes = GetAndResetAbandonedInBytes();

  SpaceUsage usage_before = GetCurrentUsage();
  intptr_t promo_candidate_words =
      (survivor_end_ - FirstObjectStart()) / kWordSize;
  SemiSpace* from = Prologue(isolate_group);
  // The API prologue/epilogue may create/destroy zones, so we must not
  // depend on zone allocations surviving beyond the epilogue callback.
  {
    StackZone zone(thread);
    // Setup the visitor and run the scavenge.
    ScavengerVisitor visitor(isolate_group, this, from);
    page_space->AcquireDataLock();
    IterateRoots(isolate_group, &visitor);
    int64_t iterate_roots = OS::GetCurrentMonotonicMicros();
    {
      TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessToSpace");
      ProcessToSpace(&visitor);
    }
    int64_t process_to_space = OS::GetCurrentMonotonicMicros();
    {
      TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessWeakHandles");
      ScavengerWeakVisitor weak_visitor(thread, this);
      IterateWeakRoots(isolate_group, &weak_visitor);
    }
    ProcessWeakReferences();
    page_space->ReleaseDataLock();

    // Scavenge finished. Run accounting.
    int64_t end = OS::GetCurrentMonotonicMicros();
    heap_->RecordTime(kProcessToSpace, process_to_space - iterate_roots);
    heap_->RecordTime(kIterateWeaks, end - process_to_space);
    stats_history_.Add(ScavengeStats(start, end, usage_before,
                                     GetCurrentUsage(), promo_candidate_words,
                                     visitor.bytes_promoted() >> kWordSizeLog2,
                                     abandoned_bytes >> kWordSizeLog2));
  }
  Epilogue(isolate_group, from);

  // TODO(koda): Make verification more compatible with concurrent sweep.
  if (FLAG_verify_after_gc && !FLAG_concurrent_sweep) {
    OS::PrintErr("Verifying after Scavenge...");
    heap_->VerifyGC(kForbidMarked);
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
  auto isolate_group = IsolateGroup::Current();
  ASSERT(isolate_group != nullptr);
  JSONObject space(object, "new");
  space.AddProperty("type", "HeapSpace");
  space.AddProperty("name", "new");
  space.AddProperty("vmName", "Scavenger");
  space.AddProperty("collections", collections());
  if (collections() > 0) {
    int64_t run_time = isolate_group->UptimeMicros();
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

void Scavenger::AllocateExternal(intptr_t cid, intptr_t size) {
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

}  // namespace dart
