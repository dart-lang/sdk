// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/scavenger.h"

#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/flag_list.h"
#include "vm/heap/become.h"
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
#include "vm/thread_barrier.h"
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

// Scavenger uses ObjectLayout::kMarkBit to distinguish forwarded and
// non-forwarded objects. The kMarkBit does not intersect with the target
// address because of object alignment.
enum {
  kForwardingMask = 1 << ObjectLayout::kOldAndNotMarkedBit,
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

static inline uword ForwardingHeader(uword target) {
  // Make sure forwarding can be encoded.
  ASSERT((target & kForwardingMask) == 0);
  return target | kForwarded;
}

// Races: The first word in the copied region is a header word that may be
// updated by the scavenger worker in another thread, so we might copy either
// the original object header or an installed forwarding pointer. This race is
// harmless because if we copy the installed forwarding pointer, the scavenge
// worker in the current thread will abandon this copy. We do not mark the loads
// here as relaxed so the C++ compiler still has the freedom to reorder them.
NO_SANITIZE_THREAD
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

template <bool parallel>
class ScavengerVisitorBase : public ObjectPointerVisitor {
 public:
  explicit ScavengerVisitorBase(IsolateGroup* isolate_group,
                                Scavenger* scavenger,
                                SemiSpace* from,
                                FreeList* freelist,
                                PromotionStack* promotion_stack)
      : ObjectPointerVisitor(isolate_group),
        thread_(nullptr),
        scavenger_(scavenger),
        from_(from),
        page_space_(scavenger->heap_->old_space()),
        freelist_(freelist),
        bytes_promoted_(0),
        visiting_old_object_(nullptr),
        promoted_list_(promotion_stack),
        labs_(8) {
    ASSERT(labs_.length() == 0);
    labs_.Add({0, 0, 0});
    ASSERT(labs_.length() == 1);
  }

  virtual void VisitTypedDataViewPointers(TypedDataViewPtr view,
                                          ObjectPtr* first,
                                          ObjectPtr* last) {
    // First we forward all fields of the typed data view.
    VisitPointers(first, last);

    if (view->ptr()->data_ == nullptr) {
      ASSERT(RawSmiValue(view->ptr()->offset_in_bytes_) == 0 &&
             RawSmiValue(view->ptr()->length_) == 0);
      return;
    }

    // Validate 'this' is a typed data view.
    const uword view_header =
        *reinterpret_cast<uword*>(ObjectLayout::ToAddr(view));
    ASSERT(!IsForwarding(view_header) || view->IsOldObject());
    ASSERT(IsTypedDataViewClassId(view->GetClassIdMayBeSmi()));

    // Validate that the backing store is not a forwarding word.
    TypedDataBasePtr td = view->ptr()->typed_data_;
    ASSERT(td->IsHeapObject());
    const uword td_header = *reinterpret_cast<uword*>(ObjectLayout::ToAddr(td));
    ASSERT(!IsForwarding(td_header) || td->IsOldObject());

    // We can always obtain the class id from the forwarded backing store.
    const classid_t cid = td->GetClassId();

    // If we have external typed data we can simply return since the backing
    // store lives in C-heap and will not move.
    if (IsExternalTypedDataClassId(cid)) {
      return;
    }

    // Now we update the inner pointer.
    ASSERT(IsTypedDataClassId(cid));
    view->ptr()->RecomputeDataFieldForInternalTypedData();
  }

  virtual void VisitPointers(ObjectPtr* first, ObjectPtr* last) {
    ASSERT(Utils::IsAligned(first, sizeof(*first)));
    ASSERT(Utils::IsAligned(last, sizeof(*last)));
    for (ObjectPtr* current = first; current <= last; current++) {
      ScavengePointer(current);
    }
  }

  void VisitingOldObject(ObjectPtr obj) {
    ASSERT((obj == nullptr) || obj->IsOldObject());
    visiting_old_object_ = obj;
    if (obj != nullptr) {
      // Card update happens in HeapPage::VisitRememberedCards.
      ASSERT(!obj->ptr()->IsCardRemembered());
    }
  }

  intptr_t bytes_promoted() const { return bytes_promoted_; }

  void AddNewTLAB(uword top, uword end) {
    producer_index_++;
    ScavengerLAB lab;
    lab.top = top;
    lab.end = end;
    lab.resolved_top = top;
    labs_.Add(lab);
  }

  void ProcessRoots() {
    thread_ = Thread::Current();
    page_space_->AcquireLock(freelist_);
    scavenger_->IterateRoots(this);
  }

  void ProcessSurvivors() {
    // Iterate until all work has been drained.
    do {
      ProcessToSpace();
      ProcessPromotedList();
    } while (HasWork());
  }

  void ProcessAll() {
    do {
      ProcessSurvivors();
      ProcessWeakProperties();
    } while (HasWork());
  }

  inline void ProcessWeakProperties();

  bool HasWork() {
    // N.B.: Normally if any TLABs have things left to resolve, then the
    // TLAB we are allocating from (producer_index_) will too because we
    // always immediately allocate when we switch to a new TLAB. However,
    // this first allocation may be undone if we lose the race to install
    // the forwarding pointer, so we must also check that there aren't
    // any TLABs after the resolution cursor.
    return (consumer_index_ < producer_index_) ||
           (labs_[producer_index_].top !=
            labs_[producer_index_].resolved_top) ||
           !promoted_list_.IsEmpty();
  }

  void Finalize() {
    ASSERT(!HasWork());

    for (intptr_t i = 0; i <= producer_index_; i++) {
      ASSERT(labs_[i].top <= labs_[i].end);
      ASSERT(labs_[i].resolved_top == labs_[i].top);
    }

    MakeProducerTLABIterable();

    promoted_list_.Finalize();

    MournWeakProperties();

    page_space_->ReleaseLock(freelist_);
    thread_ = nullptr;
  }

  void DonateTLABs() {
    MutexLocker ml(&scavenger_->space_lock_);
    // NOTE: We could make all [labs_] re-usable after a scavenge if we remember
    // the promotion pointer of each TLAB.
    const auto& lab = labs_[producer_index_];
    if (lab.end == scavenger_->top_) {
      scavenger_->top_ = lab.top;
    }
  }

 private:
  void UpdateStoreBuffer(ObjectPtr* p, ObjectPtr obj) {
    ASSERT(obj->IsHeapObject());
    // If the newly written object is not a new object, drop it immediately.
    if (!obj->IsNewObject() || visiting_old_object_->ptr()->IsRemembered()) {
      return;
    }
    visiting_old_object_->ptr()->SetRememberedBit();
    thread_->StoreBufferAddObjectGC(visiting_old_object_);
  }

  DART_FORCE_INLINE
  void ScavengePointer(ObjectPtr* p) {
    // ScavengePointer cannot be called recursively.
    ObjectPtr raw_obj = *p;

    if (raw_obj->IsSmiOrOldObject()) {
      return;
    }

    uword raw_addr = ObjectLayout::ToAddr(raw_obj);
    // The scavenger is only expects objects located in the from space.
    ASSERT(from_->Contains(raw_addr));
    // Read the header word of the object and determine if the object has
    // already been copied.
    uword header = reinterpret_cast<std::atomic<uword>*>(raw_addr)->load(
        std::memory_order_relaxed);
    uword new_addr = 0;
    if (IsForwarding(header)) {
      // Get the new location of the object.
      new_addr = ForwardedAddr(header);
    } else {
      intptr_t size = raw_obj->ptr()->HeapSize(header);
      // Check whether object should be promoted.
      if (raw_addr >= scavenger_->survivor_end_) {
        // Not a survivor of a previous scavenge. Just copy the object into the
        // to space.
        new_addr = TryAllocateCopy(size);
      }
      if (new_addr == 0) {
        // This object is a survivor of a previous scavenge. Attempt to promote
        // the object. (Or, unlikely, to-space was exhausted by fragmentation.)
        new_addr = page_space_->TryAllocatePromoLocked(freelist_, size);
        if (LIKELY(new_addr != 0)) {
          // If promotion succeeded then we need to remember it so that it can
          // be traversed later.
          promoted_list_.Push(ObjectLayout::FromAddr(new_addr));
          bytes_promoted_ += size;
        } else {
          // Promotion did not succeed. Copy into the to space instead.
          scavenger_->failed_to_promote_ = true;
          new_addr = TryAllocateCopy(size);
          // To-space was exhausted by fragmentation and old-space could not
          // grow.
          if (UNLIKELY(new_addr == 0)) {
            FATAL("Failed to allocate during scavenge");
          }
        }
      }
      ASSERT(new_addr != 0);
      // Copy the object to the new location.
      objcpy(reinterpret_cast<void*>(new_addr),
             reinterpret_cast<void*>(raw_addr), size);

      ObjectPtr new_obj = ObjectLayout::FromAddr(new_addr);
      if (new_obj->IsOldObject()) {
        // Promoted: update age/barrier tags.
        uint32_t tags = static_cast<uint32_t>(header);
        tags = ObjectLayout::OldBit::update(true, tags);
        tags = ObjectLayout::OldAndNotRememberedBit::update(true, tags);
        tags = ObjectLayout::NewBit::update(false, tags);
        // Setting the forwarding pointer below will make this tenured object
        // visible to the concurrent marker, but we haven't visited its slots
        // yet. We mark the object here to prevent the concurrent marker from
        // adding it to the mark stack and visiting its unprocessed slots. We
        // push it to the mark stack after forwarding its slots.
        tags = ObjectLayout::OldAndNotMarkedBit::update(!thread_->is_marking(),
                                                        tags);
        new_obj->ptr()->tags_ = tags;
      } else {
        ASSERT(scavenger_->to_->Contains(new_addr));
      }

      intptr_t cid = ObjectLayout::ClassIdTag::decode(header);
      if (IsTypedDataClassId(cid)) {
        static_cast<TypedDataPtr>(new_obj)->ptr()->RecomputeDataField();
      }

      // Try to install forwarding address.
      uword forwarding_header = ForwardingHeader(new_addr);
      if (!InstallForwardingPointer(raw_addr, &header, forwarding_header)) {
        ASSERT(IsForwarding(header));
        if (new_obj->IsOldObject()) {
          // Abandon as a free list element.
          FreeListElement::AsElement(new_addr, size);
          bytes_promoted_ -= size;
        } else {
          // Undo to-space allocation.
          ASSERT(labs_[producer_index_].top == (new_addr + size));
          labs_[producer_index_].top = new_addr;
        }
        // Use the winner's forwarding target.
        new_addr = ForwardedAddr(header);
        if (ObjectLayout::FromAddr(new_addr)->IsNewObject()) {
          ASSERT(scavenger_->to_->Contains(new_addr));
        }
      }
    }

    // Update the reference.
    ObjectPtr new_obj = ObjectLayout::FromAddr(new_addr);
    if (!new_obj->IsNewObject()) {
      // Setting the mark bit above must not be ordered after a publishing store
      // of this object. Note this could be a publishing store even if the
      // object was promoted by an early invocation of ScavengePointer. Compare
      // Object::Allocate.
      reinterpret_cast<std::atomic<ObjectPtr>*>(p)->store(
          new_obj, std::memory_order_release);
    } else {
      ASSERT(scavenger_->to_->Contains(ObjectLayout::ToAddr(new_obj)));
      *p = new_obj;
    }
    // Update the store buffer as needed.
    if (visiting_old_object_ != nullptr) {
      UpdateStoreBuffer(p, new_obj);
    }
  }

  DART_FORCE_INLINE
  bool InstallForwardingPointer(uword addr,
                                uword* old_header,
                                uword new_header) {
    if (parallel) {
      return reinterpret_cast<std::atomic<uword>*>(addr)
          ->compare_exchange_strong(*old_header, new_header,
                                    std::memory_order_relaxed);
    } else {
      *reinterpret_cast<uword*>(addr) = new_header;
      return true;
    }
  }

  DART_FORCE_INLINE
  uword TryAllocateCopy(intptr_t size) {
    ASSERT(Utils::IsAligned(size, kObjectAlignment));
    ScavengerLAB& lab = labs_[producer_index_];
    uword result = lab.top;
    uword new_top = result + size;
    if (LIKELY(new_top <= lab.end)) {
      ASSERT(scavenger_->to_->Contains(result));
      ASSERT((result & kObjectAlignmentMask) == kNewObjectAlignmentOffset);
      lab.top = new_top;
      ASSERT((scavenger_->to_->Contains(new_top)) ||
             (new_top == scavenger_->to_->end()));
      return result;
    }
    return TryAllocateCopySlow(size);
  }

  DART_NOINLINE inline uword TryAllocateCopySlow(intptr_t size);

  void MakeProducerTLABIterable() {
    uword top = labs_[producer_index_].top;
    uword end = labs_[producer_index_].end;
    intptr_t size = end - top;
    if (size != 0) {
      ASSERT(Utils::IsAligned(size, kObjectAlignment));
      ForwardingCorpse::AsForwarder(top, size);
      ASSERT(ObjectLayout::FromAddr(top)->ptr()->HeapSize() == size);
    }
  }

  inline void ProcessToSpace();
  DART_FORCE_INLINE intptr_t ProcessCopied(ObjectPtr raw_obj);
  inline void ProcessPromotedList();
  inline void EnqueueWeakProperty(WeakPropertyPtr raw_weak);
  inline void MournWeakProperties();

  Thread* thread_;
  Scavenger* scavenger_;
  SemiSpace* from_;
  PageSpace* page_space_;
  FreeList* freelist_;
  intptr_t bytes_promoted_;
  ObjectPtr visiting_old_object_;

  PromotionWorkList promoted_list_;
  WeakPropertyPtr delayed_weak_properties_ = nullptr;

  struct ScavengerLAB {
    uword top;
    uword end;
    uword resolved_top;
  };
  MallocGrowableArray<ScavengerLAB> labs_;
  intptr_t consumer_index_ = 1;
  intptr_t producer_index_ = 0;

  DISALLOW_COPY_AND_ASSIGN(ScavengerVisitorBase);
};

typedef ScavengerVisitorBase<false> SerialScavengerVisitor;
typedef ScavengerVisitorBase<true> ParallelScavengerVisitor;

class ScavengerWeakVisitor : public HandleVisitor {
 public:
  ScavengerWeakVisitor(Thread* thread, Scavenger* scavenger)
      : HandleVisitor(thread),
        scavenger_(scavenger),
        class_table_(thread->isolate_group()->shared_class_table()) {
    ASSERT(scavenger->heap_->isolate_group() == thread->isolate_group());
  }

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    ObjectPtr* p = handle->raw_addr();
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

class ParallelScavengerTask : public ThreadPool::Task {
 public:
  ParallelScavengerTask(IsolateGroup* isolate_group,
                        ThreadBarrier* barrier,
                        ParallelScavengerVisitor* visitor,
                        RelaxedAtomic<uintptr_t>* num_busy)
      : isolate_group_(isolate_group),
        barrier_(barrier),
        visitor_(visitor),
        num_busy_(num_busy) {}

  virtual void Run() {
    bool result = Thread::EnterIsolateGroupAsHelper(
        isolate_group_, Thread::kScavengerTask, /*bypass_safepoint=*/true);
    ASSERT(result);

    RunEnteredIsolateGroup();

    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);

    // This task is done. Notify the original thread.
    barrier_->Exit();
  }

  void RunEnteredIsolateGroup() {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ParallelScavenge");

    visitor_->ProcessRoots();

    // Phase 1: Copying.
    bool more_to_scavenge = false;
    do {
      do {
        visitor_->ProcessSurvivors();

        // I can't find more work right now. If no other task is busy,
        // then there will never be more work (NB: 1 is *before* decrement).
        if (num_busy_->fetch_sub(1u) == 1) break;

        // Wait for some work to appear.
        // TODO(iposva): Replace busy-waiting with a solution using Monitor,
        // and redraw the boundaries between stack/visitor/task as needed.
        while (!visitor_->HasWork() && num_busy_->load() > 0) {
        }

        // If no tasks are busy, there will never be more work.
        if (num_busy_->load() == 0) break;

        // I saw some work; get busy and compete for it.
        num_busy_->fetch_add(1u);
      } while (true);
      // Wait for all scavengers to stop.
      barrier_->Sync();
#if defined(DEBUG)
      ASSERT(num_busy_->load() == 0);
      // Caveat: must not allow any marker to continue past the barrier
      // before we checked num_busy, otherwise one of them might rush
      // ahead and increment it.
      barrier_->Sync();
#endif
      // Check if we have any pending properties with marked keys.
      // Those might have been marked by another marker.
      visitor_->ProcessWeakProperties();
      more_to_scavenge = visitor_->HasWork();
      if (more_to_scavenge) {
        // We have more work to do. Notify others.
        num_busy_->fetch_add(1u);
      }

      // Wait for all other scavengers to finish processing their pending
      // weak properties and decide if they need to continue marking.
      // Caveat: we need two barriers here to make this decision in lock step
      // between all scavengers and the main thread.
      barrier_->Sync();
      if (!more_to_scavenge && (num_busy_->load() > 0)) {
        // All scavengers continue to mark as long as any single marker has
        // some work to do.
        num_busy_->fetch_add(1u);
        more_to_scavenge = true;
      }
      barrier_->Sync();
    } while (more_to_scavenge);

    // Phase 2: Weak processing, statistics.
    visitor_->Finalize();
    barrier_->Sync();
  }

 private:
  IsolateGroup* isolate_group_;
  ThreadBarrier* barrier_;
  ParallelScavengerVisitor* visitor_;
  RelaxedAtomic<uintptr_t>* num_busy_;

  DISALLOW_COPY_AND_ASSIGN(ParallelScavengerTask);
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
  // TODO(rmacnak): This can take an order of magnitude longer the rest of
  // a scavenge. Consider moving it to another thread, perhaps the idle
  // notifier.
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

class CollectStoreBufferVisitor : public ObjectPointerVisitor {
 public:
  explicit CollectStoreBufferVisitor(ObjectSet* in_store_buffer)
      : ObjectPointerVisitor(IsolateGroup::Current()),
        in_store_buffer_(in_store_buffer) {}

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr raw_obj = *ptr;
      RELEASE_ASSERT(!raw_obj->ptr()->IsCardRemembered());
      RELEASE_ASSERT(raw_obj->ptr()->IsRemembered());
      RELEASE_ASSERT(raw_obj->IsOldObject());
      in_store_buffer_->Add(raw_obj);
    }
  }

 private:
  ObjectSet* const in_store_buffer_;
};

class CheckStoreBufferVisitor : public ObjectVisitor,
                                public ObjectPointerVisitor {
 public:
  CheckStoreBufferVisitor(ObjectSet* in_store_buffer, const SemiSpace* to)
      : ObjectVisitor(),
        ObjectPointerVisitor(IsolateGroup::Current()),
        in_store_buffer_(in_store_buffer),
        to_(to) {}

  void VisitObject(ObjectPtr raw_obj) {
    if (raw_obj->IsPseudoObject()) return;
    RELEASE_ASSERT(raw_obj->IsOldObject());

    if (raw_obj->ptr()->IsCardRemembered()) {
      RELEASE_ASSERT(!raw_obj->ptr()->IsRemembered());
      // TODO(rmacnak): Verify card tables.
      return;
    }

    RELEASE_ASSERT(raw_obj->ptr()->IsRemembered() ==
                   in_store_buffer_->Contains(raw_obj));

    visiting_ = raw_obj;
    is_remembered_ = raw_obj->ptr()->IsRemembered();
    raw_obj->ptr()->VisitPointers(this);
  }

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr raw_obj = *ptr;
      if (raw_obj->IsHeapObject() && raw_obj->IsNewObject()) {
        if (!is_remembered_) {
          FATAL3(
              "Old object %#" Px "references new object %#" Px
              ", but it is not"
              " in any store buffer. Consider using rr to watch the slot %p and"
              " reverse-continue to find the store with a missing barrier.\n",
              static_cast<uword>(visiting_), static_cast<uword>(raw_obj), ptr);
        }
        RELEASE_ASSERT(to_->Contains(ObjectLayout::ToAddr(raw_obj)));
      }
    }
  }

 private:
  const ObjectSet* const in_store_buffer_;
  const SemiSpace* const to_;
  ObjectPtr visiting_;
  bool is_remembered_;
};

void Scavenger::VerifyStoreBuffers() {
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();

  ObjectSet* in_store_buffer = new (zone) ObjectSet(zone);
  heap_->AddRegionsToObjectSet(in_store_buffer);

  {
    CollectStoreBufferVisitor visitor(in_store_buffer);
    heap_->isolate_group()->store_buffer()->VisitObjectPointers(&visitor);
  }

  {
    CheckStoreBufferVisitor visitor(in_store_buffer, to_);
    heap_->old_space()->VisitObjects(&visitor);
  }
}

SemiSpace* Scavenger::Prologue() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "Prologue");

  heap_->isolate_group()->ReleaseStoreBuffers();

  if (FLAG_verify_store_buffer) {
    OS::PrintErr("Verifying remembered set before Scavenge...");
    heap_->WaitForSweeperTasksAtSafepoint(Thread::Current());
    VerifyStoreBuffers();
    OS::PrintErr(" done.\n");
  }

  // Need to stash the old remembered set before any worker begins adding to the
  // new remembered set.
  blocks_ = heap_->isolate_group()->store_buffer()->TakeBlocks();

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
  {
    MutexLocker ml(&space_lock_);
    top_ = FirstObjectStart();
    resolved_top_ = top_;
    end_ = to_->end();
  }

  return from;
}

void Scavenger::Epilogue(SemiSpace* from) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "Epilogue");

  // All objects in the to space have been copied from the from space at this
  // moment.

  // Ensure the mutator thread will fail the next allocation. This will force
  // mutator to allocate a new TLAB
  heap_->isolate_group()->ForEachIsolate(
      [&](Isolate* isolate) {
        Thread* mutator_thread = isolate->mutator_thread();
        ASSERT(mutator_thread == nullptr ||
               mutator_thread->tlab().IsAbandoned());
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

  if (FLAG_verify_store_buffer) {
    // Scavenging will insert into the store buffer block on the current
    // thread (later will parallel scavenge, the worker's threads). We need to
    // flush this thread-local block to the isolate group or we will incorrectly
    // report some objects as absent from the store buffer. This might cause
    // a program to hit a store buffer overflow a bit sooner than it might
    // otherwise, since overflow is measured in blocks. Store buffer overflows
    // are very rare.
    heap_->isolate_group()->ReleaseStoreBuffers();

    OS::PrintErr("Verifying remembered set after Scavenge...");
    heap_->WaitForSweeperTasksAtSafepoint(Thread::Current());
    VerifyStoreBuffers();
    OS::PrintErr(" done.\n");
  }

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

void Scavenger::IterateIsolateRoots(ObjectPointerVisitor* visitor) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "IterateIsolateRoots");
  heap_->isolate_group()->VisitObjectPointers(
      visitor, ValidationPolicy::kDontValidateFrames);
}

template <bool parallel>
void Scavenger::IterateStoreBuffers(ScavengerVisitorBase<parallel>* visitor) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "IterateStoreBuffers");

  // Iterating through the store buffers.
  // Grab the deduplication sets out of the isolate's consolidated store buffer.
  StoreBuffer* store_buffer = heap_->isolate_group()->store_buffer();
  StoreBufferBlock* pending = blocks_;
  blocks_ = nullptr;
  intptr_t total_count = 0;
  while (pending != NULL) {
    StoreBufferBlock* next = pending->next();
    // Generated code appends to store buffers; tell MemorySanitizer.
    MSAN_UNPOISON(pending, sizeof(*pending));
    intptr_t count = pending->Count();
    total_count += count;
    while (!pending->IsEmpty()) {
      ObjectPtr raw_object = pending->Pop();
      ASSERT(!raw_object->IsForwardingCorpse());
      ASSERT(raw_object->ptr()->IsRemembered());
      raw_object->ptr()->ClearRememberedBit();
      visitor->VisitingOldObject(raw_object);
      // Note that this treats old-space WeakProperties as strong. A dead key
      // won't be reclaimed until after the key is promoted.
      raw_object->ptr()->VisitPointersNonvirtual(visitor);
    }
    pending->Reset();
    // Return the emptied block for recycling (no need to check threshold).
    store_buffer->PushBlock(pending, StoreBuffer::kIgnoreThreshold);
    pending = next;
  }
  // Done iterating through old objects remembered in the store buffers.
  visitor->VisitingOldObject(NULL);

  heap_->RecordData(kStoreBufferEntries, total_count);
  heap_->RecordData(kDataUnused1, 0);
  heap_->RecordData(kDataUnused2, 0);
}

template <bool parallel>
void Scavenger::IterateRememberedCards(
    ScavengerVisitorBase<parallel>* visitor) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "IterateRememberedCards");
  heap_->old_space()->VisitRememberedCards(visitor);
  visitor->VisitingOldObject(NULL);
}

void Scavenger::IterateObjectIdTable(ObjectPointerVisitor* visitor) {
#ifndef PRODUCT
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "IterateObjectIdTable");
  heap_->isolate_group()->ForEachIsolate(
      [&](Isolate* isolate) {
        isolate->object_id_ring()->VisitPointers(visitor);
      },
      /*at_safepoint=*/true);
#endif  // !PRODUCT
}

enum RootSlices {
  kIsolate = 0,
  kObjectIdRing,
  kCards,
  kStoreBuffer,
  kNumRootSlices,
};

template <bool parallel>
void Scavenger::IterateRoots(ScavengerVisitorBase<parallel>* visitor) {
  for (;;) {
    intptr_t slice = root_slices_started_.fetch_add(1);
    if (slice >= kNumRootSlices) {
      return;  // No more slices.
    }

    switch (slice) {
      case kIsolate:
        IterateIsolateRoots(visitor);
        break;
      case kObjectIdRing:
        IterateObjectIdTable(visitor);
        break;
      case kCards:
        IterateRememberedCards(visitor);
        break;
      case kStoreBuffer:
        IterateStoreBuffers(visitor);
        break;
      default:
        UNREACHABLE();
    }
  }
}

bool Scavenger::IsUnreachable(ObjectPtr* p) {
  ObjectPtr raw_obj = *p;
  if (!raw_obj->IsHeapObject()) {
    return false;
  }
  if (!raw_obj->IsNewObject()) {
    return false;
  }
  uword raw_addr = ObjectLayout::ToAddr(raw_obj);
  if (to_->Contains(raw_addr)) {
    return false;
  }
  uword header = *reinterpret_cast<uword*>(raw_addr);
  if (IsForwarding(header)) {
    uword new_addr = ForwardedAddr(header);
    *p = ObjectLayout::FromAddr(new_addr);
    return false;
  }
  return true;
}

void Scavenger::MournWeakHandles() {
  Thread* thread = Thread::Current();
  TIMELINE_FUNCTION_GC_DURATION(thread, "MournWeakHandles");
  ScavengerWeakVisitor weak_visitor(thread, this);
  heap_->isolate_group()->VisitWeakPersistentHandles(&weak_visitor);
}

template <bool parallel>
void ScavengerVisitorBase<parallel>::ProcessToSpace() {
  intptr_t i = consumer_index_;
  while (i <= producer_index_) {
    uword resolved_top = labs_[i].resolved_top;
    while (resolved_top < labs_[i].top) {
      ObjectPtr raw_obj = ObjectLayout::FromAddr(resolved_top);
      resolved_top += ProcessCopied(raw_obj);
    }
    labs_[i].resolved_top = resolved_top;

    if (i == producer_index_) {
      return;  // More objects may yet be copied to this TLAB.
    }

    i++;
    consumer_index_ = i;
    ASSERT(consumer_index_ < labs_.length());
  }
}

template <bool parallel>
void ScavengerVisitorBase<parallel>::ProcessPromotedList() {
  ObjectPtr raw_object;
  while ((raw_object = promoted_list_.Pop()) != nullptr) {
    // Resolve or copy all objects referred to by the current object. This
    // can potentially push more objects on this stack as well as add more
    // objects to be resolved in the to space.
    ASSERT(!raw_object->ptr()->IsRemembered());
    VisitingOldObject(raw_object);
    raw_object->ptr()->VisitPointersNonvirtual(this);
    if (raw_object->ptr()->IsMarked()) {
      // Complete our promise from ScavengePointer. Note that marker cannot
      // visit this object until it pops a block from the mark stack, which
      // involves a memory fence from the mutex, so even on architectures
      // with a relaxed memory model, the marker will see the fully
      // forwarded contents of this object.
      thread_->MarkingStackAddObject(raw_object);
    }
  }
  VisitingOldObject(NULL);
}

template <bool parallel>
void ScavengerVisitorBase<parallel>::ProcessWeakProperties() {
  // Finished this round of scavenging. Process the pending weak properties
  // for which the keys have become reachable. Potentially this adds more
  // objects to the to space.
  WeakPropertyPtr cur_weak = delayed_weak_properties_;
  delayed_weak_properties_ = nullptr;
  while (cur_weak != nullptr) {
    uword next_weak = cur_weak->ptr()->next_;
    // Promoted weak properties are not enqueued. So we can guarantee that
    // we do not need to think about store barriers here.
    ASSERT(cur_weak->IsNewObject());
    ObjectPtr raw_key = cur_weak->ptr()->key_;
    ASSERT(raw_key->IsHeapObject());
    // Key still points into from space even if the object has been
    // promoted to old space by now. The key will be updated accordingly
    // below when VisitPointers is run.
    ASSERT(raw_key->IsNewObject());
    uword raw_addr = ObjectLayout::ToAddr(raw_key);
    ASSERT(from_->Contains(raw_addr));
    uword header = *reinterpret_cast<uword*>(raw_addr);
    // Reset the next pointer in the weak property.
    cur_weak->ptr()->next_ = 0;
    if (IsForwarding(header)) {
      cur_weak->ptr()->VisitPointersNonvirtual(this);
    } else {
      EnqueueWeakProperty(cur_weak);
    }
    // Advance to next weak property in the queue.
    cur_weak = static_cast<WeakPropertyPtr>(next_weak);
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

template <bool parallel>
void ScavengerVisitorBase<parallel>::EnqueueWeakProperty(
    WeakPropertyPtr raw_weak) {
  ASSERT(raw_weak->IsHeapObject());
  ASSERT(raw_weak->IsNewObject());
  ASSERT(raw_weak->IsWeakProperty());
#if defined(DEBUG)
  uword raw_addr = ObjectLayout::ToAddr(raw_weak);
  uword header = *reinterpret_cast<uword*>(raw_addr);
  ASSERT(!IsForwarding(header));
#endif  // defined(DEBUG)
  ASSERT(raw_weak->ptr()->next_ == 0);
  raw_weak->ptr()->next_ = static_cast<uword>(delayed_weak_properties_);
  delayed_weak_properties_ = raw_weak;
}

template <bool parallel>
intptr_t ScavengerVisitorBase<parallel>::ProcessCopied(ObjectPtr raw_obj) {
  intptr_t class_id = raw_obj->GetClassId();
  if (UNLIKELY(class_id == kWeakPropertyCid)) {
    WeakPropertyPtr raw_weak = static_cast<WeakPropertyPtr>(raw_obj);
    // The fate of the weak property is determined by its key.
    ObjectPtr raw_key = raw_weak->ptr()->key_;
    if (raw_key->IsHeapObject() && raw_key->IsNewObject()) {
      uword raw_addr = ObjectLayout::ToAddr(raw_key);
      uword header = *reinterpret_cast<uword*>(raw_addr);
      if (!IsForwarding(header)) {
        // Key is white.  Enqueue the weak property.
        EnqueueWeakProperty(raw_weak);
        return raw_weak->ptr()->HeapSize();
      }
    }
    // Key is gray or black.  Make the weak property black.
  }
  return raw_obj->ptr()->VisitPointersNonvirtual(this);
}

void Scavenger::MournWeakTables() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "MournWeakTables");

  auto rehash_weak_table = [](WeakTable* table, WeakTable* replacement_new,
                              WeakTable* replacement_old) {
    intptr_t size = table->size();
    for (intptr_t i = 0; i < size; i++) {
      if (table->IsValidEntryAtExclusive(i)) {
        ObjectPtr raw_obj = table->ObjectAtExclusive(i);
        ASSERT(raw_obj->IsHeapObject());
        uword raw_addr = ObjectLayout::ToAddr(raw_obj);
        uword header = *reinterpret_cast<uword*>(raw_addr);
        if (IsForwarding(header)) {
          // The object has survived.  Preserve its record.
          uword new_addr = ForwardedAddr(header);
          raw_obj = ObjectLayout::FromAddr(new_addr);
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
}

template <bool parallel>
void ScavengerVisitorBase<parallel>::MournWeakProperties() {
  // The queued weak properties at this point do not refer to reachable keys,
  // so we clear their key and value fields.
  WeakPropertyPtr cur_weak = delayed_weak_properties_;
  delayed_weak_properties_ = nullptr;
  while (cur_weak != nullptr) {
    uword next_weak = cur_weak->ptr()->next_;
    // Reset the next pointer in the weak property.
    cur_weak->ptr()->next_ = 0;

#if defined(DEBUG)
    ObjectPtr raw_key = cur_weak->ptr()->key_;
    uword raw_addr = ObjectLayout::ToAddr(raw_key);
    uword header = *reinterpret_cast<uword*>(raw_addr);
    ASSERT(!IsForwarding(header));
    ASSERT(raw_key->IsHeapObject());
    ASSERT(raw_key->IsNewObject());  // Key still points into from space.
#endif                               // defined(DEBUG)

    WeakProperty::Clear(cur_weak);

    // Advance to next weak property in the queue.
    cur_weak = static_cast<WeakPropertyPtr>(next_weak);
  }
}

void Scavenger::MakeNewSpaceIterable() {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask) ||
         (Thread::Current()->task_kind() == Thread::kCompactorTask));
  auto isolate_group = heap_->isolate_group();
  MonitorLocker ml(isolate_group->threads_lock(), false);

  // Make all scheduled thread's TLABs iterable.
  Thread* current = heap_->isolate_group()->thread_registry()->active_list();
  while (current != NULL) {
    const TLAB tlab = current->tlab();
    if (!tlab.IsAbandoned()) {
      MakeTLABIterable(tlab);
    }
    current = current->next();
  }

  // All unscheduled mutator threads should have already abnadoned their TLABs.
  isolate_group->ForEachIsolate(
      [&](Isolate* isolate) {
        Thread* mutator_thread = isolate->mutator_thread();
        if (mutator_thread != NULL) {
          if (isolate->scheduled_mutator_thread_ == nullptr) {
            RELEASE_ASSERT(mutator_thread->tlab().IsAbandoned());
          }
        }
      },
      /*at_safepoint=*/true);

  for (intptr_t i = 0; i < free_tlabs_.length(); ++i) {
    MakeTLABIterable(free_tlabs_[i]);
  }
}

void Scavenger::AbandonTLABsLocked() {
  ASSERT(Thread::Current()->IsAtSafepoint());
  IsolateGroup* isolate_group = heap_->isolate_group();
  MonitorLocker ml(isolate_group->threads_lock(), false);

  // Abandon TLABs of all scheduled threads.
  Thread* current = isolate_group->thread_registry()->active_list();
  while (current != NULL) {
    const TLAB tlab = current->tlab();
    AddAbandonedInBytesLocked(tlab.RemainingSize());
    current->set_tlab(TLAB());
    current = current->next();
  }
  // All unscheduled mutator threads should have already abandoned their TLAB.
  isolate_group->ForEachIsolate(
      [&](Isolate* isolate) {
        Thread* mutator_thread = isolate->mutator_thread();
        if (mutator_thread != NULL) {
          if (isolate->scheduled_mutator_thread_ == nullptr) {
            RELEASE_ASSERT(mutator_thread->tlab().IsAbandoned());
          }
        }
      },
      /*at_safepoint=*/true);

  while (free_tlabs_.length() > 0) {
    const TLAB tlab = free_tlabs_.RemoveLast();
    AddAbandonedInBytesLocked(tlab.RemainingSize());
  }
}

void Scavenger::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask) ||
         (Thread::Current()->task_kind() == Thread::kCompactorTask));
  MakeNewSpaceIterable();
  uword cur = FirstObjectStart();
  while (cur < top_) {
    ObjectPtr raw_obj = ObjectLayout::FromAddr(cur);
    cur += raw_obj->ptr()->VisitPointers(visitor);
  }
}

void Scavenger::VisitObjects(ObjectVisitor* visitor) {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask));
  MakeNewSpaceIterable();
  uword cur = FirstObjectStart();
  while (cur < top_) {
    ObjectPtr raw_obj = ObjectLayout::FromAddr(cur);
    visitor->VisitObject(raw_obj);
    cur += raw_obj->ptr()->HeapSize();
  }
}

void Scavenger::AddRegionsToObjectSet(ObjectSet* set) const {
  set->AddRegion(to_->start(), to_->end());
}

ObjectPtr Scavenger::FindObject(FindObjectVisitor* visitor) {
  ASSERT(!scavenging_);
  MakeNewSpaceIterable();
  uword cur = FirstObjectStart();
  if (visitor->VisitRange(cur, top_)) {
    while (cur < top_) {
      ObjectPtr raw_obj = ObjectLayout::FromAddr(cur);
      uword next = cur + raw_obj->ptr()->HeapSize();
      if (visitor->VisitRange(cur, next) &&
          raw_obj->ptr()->FindObject(visitor)) {
        return raw_obj;  // Found object, return it.
      }
      cur = next;
    }
    ASSERT(cur == top_);
  }
  return Object::null();
}

void Scavenger::TryAllocateNewTLAB(Thread* thread) {
  ASSERT(heap_ != Dart::vm_isolate()->heap());
  ASSERT(!scavenging_);
  MutexLocker ml(&space_lock_);

  // We might need a new TLAB not because the current TLAB is empty but because
  // we failed to allocate alarge object in new space.  So in case the remaining
  // TLAB is still big enough to be useful we cache it.
  CacheTLABLocked(thread->tlab());
  thread->set_tlab(TLAB());

  uword result = top_;
  intptr_t remaining = end_ - top_;
  intptr_t size = kTLABSize;
  if (remaining < size) {
    // Grab whatever is remaining
    size = Utils::RoundDown(remaining, kObjectAlignment);
  }
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  if (size == 0) {
    thread->set_tlab(TryAcquireCachedTLABLocked());
    return;
  }
  ASSERT(to_->Contains(result));
  ASSERT((result & kObjectAlignmentMask) == kNewObjectAlignmentOffset);
  top_ += size;
  ASSERT(to_->Contains(top_) || (top_ == to_->end()));
  ASSERT(result < top_);
  thread->set_tlab(TLAB(result, top_));
}

void Scavenger::MakeTLABIterable(const TLAB& tlab) {
  ASSERT(tlab.end >= tlab.top);
  const intptr_t size = tlab.RemainingSize();
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  if (size >= kObjectAlignment) {
    // ForwardingCorpse(forwarding to default null) will work as filler.
    ForwardingCorpse::AsForwarder(tlab.top, size);
    ASSERT(ObjectLayout::FromAddr(tlab.top)->ptr()->HeapSize() == size);
  }
}

void Scavenger::AbandonRemainingTLABForDebugging(Thread* thread) {
  MutexLocker ml(&space_lock_);
  const TLAB tlab = thread->tlab();
  MakeTLABIterable(tlab);
  AddAbandonedInBytesLocked(tlab.RemainingSize());
  thread->set_tlab(TLAB());
}

template <bool parallel>
uword ScavengerVisitorBase<parallel>::TryAllocateCopySlow(intptr_t size) {
  MakeProducerTLABIterable();

  if (!scavenger_->TryAllocateNewTLAB(this)) {
    return 0;
  }

  const uword result = labs_[producer_index_].top;
  const intptr_t remaining =
      labs_[producer_index_].end - labs_[producer_index_].top;
  ASSERT(size <= remaining);
  ASSERT(scavenger_->to_->Contains(result));
  ASSERT((result & kObjectAlignmentMask) == kNewObjectAlignmentOffset);
  labs_[producer_index_].top = result + size;
  return result;
}

template <bool parallel>
bool Scavenger::TryAllocateNewTLAB(ScavengerVisitorBase<parallel>* visitor) {
  intptr_t size = kTLABSize;
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  ASSERT(heap_ != Dart::vm_isolate()->heap());
  ASSERT(scavenging_);
  MutexLocker ml(&space_lock_);
  const uword result = top_;
  const intptr_t remaining = end_ - top_;
  if (remaining < size) {
    // Grab whatever is remaining
    size = Utils::RoundDown(remaining, kObjectAlignment);
  }
  if (size == 0) {
    return false;
  }
  ASSERT(to_->Contains(result));
  ASSERT((result & kObjectAlignmentMask) == kNewObjectAlignmentOffset);
  top_ += size;
  ASSERT(to_->Contains(top_) || (top_ == to_->end()));
  ASSERT(result < top_);
  visitor->AddNewTLAB(result, top_);
  return true;
}

TLAB Scavenger::TryAcquireCachedTLABLocked() {
  if (free_tlabs_.length() == 0) {
    return TLAB();
  }
  return free_tlabs_.RemoveLast();
}

void Scavenger::CacheTLABLocked(TLAB tlab) {
  // If the memory following this TLAB is the unused new space, we'll merge the
  // bytes into there.
  if (tlab.end == top_) {
    top_ = tlab.top;
    return;
  }

  MakeTLABIterable(tlab);

  // If this TLAB is lare enough to be useful in the future, we'll make it
  // reusable, otherwise we abandon it.
  const uword size = tlab.RemainingSize();
  if (size > (50 * KB)) {
    free_tlabs_.Add(tlab);
    return;
  }

  // Else we discard the memory.
  AddAbandonedInBytesLocked(size);
}

void Scavenger::Scavenge() {
  int64_t start = OS::GetCurrentMonotonicMicros();

  // Ensure that all threads for this isolate are at a safepoint (either stopped
  // or in native code). If two threads are racing at this point, the loser
  // will continue with its scavenge after waiting for the winner to complete.
  // TODO(koda): Consider moving SafepointThreads into allocation failure/retry
  // logic to avoid needless collections.
  Thread* thread = Thread::Current();
  SafepointOperationScope safepoint_scope(thread);

  int64_t safe_point = OS::GetCurrentMonotonicMicros();
  heap_->RecordTime(kSafePoint, safe_point - start);

  // Scavenging is not reentrant. Make sure that is the case.
  ASSERT(!scavenging_);
  scavenging_ = true;

  if (FLAG_verify_before_gc) {
    OS::PrintErr("Verifying before Scavenge...");
    heap_->WaitForSweeperTasksAtSafepoint(thread);
    heap_->VerifyGC(thread->is_marking() ? kAllowMarked : kForbidMarked);
    OS::PrintErr(" done.\n");
  }

  // Prepare for a scavenge.
  AbandonTLABsLocked();
  failed_to_promote_ = false;
  root_slices_started_ = 0;
  intptr_t abandoned_bytes = GetAndResetAbandonedInBytes();
  SpaceUsage usage_before = GetCurrentUsage();
  intptr_t promo_candidate_words =
      (survivor_end_ - FirstObjectStart()) / kWordSize;
  SemiSpace* from = Prologue();

  intptr_t bytes_promoted;
  if (FLAG_scavenger_tasks == 0) {
    bytes_promoted = SerialScavenge(from);
  } else {
    bytes_promoted = ParallelScavenge(from);
  }
  MournWeakHandles();
  MournWeakTables();

  // Restore write-barrier assumptions.
  heap_->isolate_group()->RememberLiveTemporaries();

  // Scavenge finished. Run accounting.
  int64_t end = OS::GetCurrentMonotonicMicros();
  stats_history_.Add(ScavengeStats(
      start, end, usage_before, GetCurrentUsage(), promo_candidate_words,
      bytes_promoted >> kWordSizeLog2, abandoned_bytes >> kWordSizeLog2));
  Epilogue(from);

  if (FLAG_verify_after_gc) {
    OS::PrintErr("Verifying after Scavenge...");
    heap_->WaitForSweeperTasksAtSafepoint(thread);
    heap_->VerifyGC(thread->is_marking() ? kAllowMarked : kForbidMarked);
    OS::PrintErr(" done.\n");
  }

  // Done scavenging. Reset the marker.
  ASSERT(scavenging_);
  scavenging_ = false;
}

intptr_t Scavenger::SerialScavenge(SemiSpace* from) {
  FreeList* freelist = heap_->old_space()->DataFreeList(0);
  SerialScavengerVisitor visitor(heap_->isolate_group(), this, from, freelist,
                                 &promotion_stack_);
  visitor.ProcessRoots();
  {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ProcessToSpace");
    visitor.ProcessAll();
  }
  visitor.Finalize();
  visitor.DonateTLABs();

  return visitor.bytes_promoted();
}

intptr_t Scavenger::ParallelScavenge(SemiSpace* from) {
  intptr_t bytes_promoted = 0;
  const intptr_t num_tasks = FLAG_scavenger_tasks;
  ASSERT(num_tasks > 0);

  ThreadBarrier barrier(num_tasks, heap_->barrier(), heap_->barrier_done());
  RelaxedAtomic<uintptr_t> num_busy = num_tasks;

  ParallelScavengerVisitor** visitors =
      new ParallelScavengerVisitor*[num_tasks];
  for (intptr_t i = 0; i < num_tasks; i++) {
    FreeList* freelist = heap_->old_space()->DataFreeList(i);
    visitors[i] = new ParallelScavengerVisitor(
        heap_->isolate_group(), this, from, freelist, &promotion_stack_);
    if (i < (num_tasks - 1)) {
      // Begin scavenging on a helper thread.
      bool result = Dart::thread_pool()->Run<ParallelScavengerTask>(
          heap_->isolate_group(), &barrier, visitors[i], &num_busy);
      ASSERT(result);
    } else {
      // Last worker is the main thread.
      ParallelScavengerTask task(heap_->isolate_group(), &barrier, visitors[i],
                                 &num_busy);
      task.RunEnteredIsolateGroup();
      barrier.Exit();
    }
  }

  for (intptr_t i = 0; i < num_tasks; i++) {
    bytes_promoted += visitors[i]->bytes_promoted();
    visitors[i]->DonateTLABs();
    delete visitors[i];
  }

  delete[] visitors;
  return bytes_promoted;
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
