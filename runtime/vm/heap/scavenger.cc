// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/scavenger.h"

#include "platform/leak_sanitizer.h"
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
#include "vm/longjump.h"
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

// Scavenger uses the kCardRememberedBit to distinguish forwarded and
// non-forwarded objects. We must choose a bit that is clear for all new-space
// object headers, and which doesn't intersect with the target address because
// of object alignment.
enum {
  kForwardingMask = 1 << ObjectLayout::kCardRememberedBit,
  kNotForwarded = 0,
  kForwarded = kForwardingMask,
};

// If the forwarded bit and pointer tag bit are the same, we can avoid a few
// conversions.
COMPILE_ASSERT(static_cast<uword>(kForwarded) ==
               static_cast<uword>(kHeapObjectTag));

static inline bool IsForwarding(uword header) {
  uword bits = header & kForwardingMask;
  ASSERT((bits == kNotForwarded) || (bits == kForwarded));
  return bits == kForwarded;
}

static inline ObjectPtr ForwardedObj(uword header) {
  ASSERT(IsForwarding(header));
  return static_cast<ObjectPtr>(header);
}

static inline uword ForwardingHeader(ObjectPtr target) {
  uword result = static_cast<uword>(target);
  ASSERT(IsForwarding(result));
  return result;
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
        delayed_weak_properties_(WeakProperty::null()) {}

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
      // Card update happens in OldPage::VisitRememberedCards.
      ASSERT(!obj->ptr()->IsCardRemembered());
    }
  }

  intptr_t bytes_promoted() const { return bytes_promoted_; }

  void ProcessRoots() {
    thread_ = Thread::Current();
    page_space_->AcquireLock(freelist_);

    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      scavenger_->IterateRoots(this);
    } else {
      ASSERT(scavenger_->abort_);
      thread_->ClearStickyError();
    }
  }

  void ProcessSurvivors() {
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      // Iterate until all work has been drained.
      do {
        ProcessToSpace();
        ProcessPromotedList();
      } while (HasWork());
    } else {
      ASSERT(scavenger_->abort_);
      thread_->ClearStickyError();
    }
  }

  void ProcessAll() {
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      do {
        do {
          ProcessToSpace();
          ProcessPromotedList();
        } while (HasWork());
        ProcessWeakProperties();
      } while (HasWork());
    } else {
      ASSERT(scavenger_->abort_);
      thread_->ClearStickyError();
    }
  }

  inline void ProcessWeakProperties();

  bool HasWork() {
    if (scavenger_->abort_) return false;
    return (scan_ != tail_) || (scan_ != nullptr && !scan_->IsResolved()) ||
           !promoted_list_.IsEmpty();
  }

  void Finalize() {
    if (scavenger_->abort_) {
      promoted_list_.AbandonWork();
    } else {
      ASSERT(!HasWork());

      for (NewPage* page = head_; page != nullptr; page = page->next()) {
        ASSERT(page->IsResolved());
        page->RecordSurvivors();
      }

      promoted_list_.Finalize();

      MournWeakProperties();
    }
    page_space_->ReleaseLock(freelist_);
    thread_ = nullptr;
  }

  NewPage* head() const { return head_; }
  NewPage* tail() const { return tail_; }

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
    ObjectPtr new_obj;
    if (IsForwarding(header)) {
      // Get the new location of the object.
      new_obj = ForwardedObj(header);
    } else {
      intptr_t size = raw_obj->ptr()->HeapSize(header);
      uword new_addr = 0;
      // Check whether object should be promoted.
      if (!NewPage::Of(raw_obj)->IsSurvivor(raw_addr)) {
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
            AbortScavenge();
          }
        }
      }
      ASSERT(new_addr != 0);
      // Copy the object to the new location.
      objcpy(reinterpret_cast<void*>(new_addr),
             reinterpret_cast<void*>(raw_addr), size);

      new_obj = ObjectLayout::FromAddr(new_addr);
      if (new_obj->IsOldObject()) {
        // Promoted: update age/barrier tags.
        uword tags = static_cast<uword>(header);
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
      }

      intptr_t cid = ObjectLayout::ClassIdTag::decode(header);
      if (IsTypedDataClassId(cid)) {
        static_cast<TypedDataPtr>(new_obj)->ptr()->RecomputeDataField();
      }

      // Try to install forwarding address.
      uword forwarding_header = ForwardingHeader(new_obj);
      if (!InstallForwardingPointer(raw_addr, &header, forwarding_header)) {
        ASSERT(IsForwarding(header));
        if (new_obj->IsOldObject()) {
          // Abandon as a free list element.
          FreeListElement::AsElement(new_addr, size);
          bytes_promoted_ -= size;
        } else {
          // Undo to-space allocation.
          tail_->Unallocate(new_addr, size);
        }
        // Use the winner's forwarding target.
        new_obj = ForwardedObj(header);
      }
    }

    // Update the reference.
    if (!new_obj->IsNewObject()) {
      // Setting the mark bit above must not be ordered after a publishing store
      // of this object. Note this could be a publishing store even if the
      // object was promoted by an early invocation of ScavengePointer. Compare
      // Object::Allocate.
      reinterpret_cast<std::atomic<ObjectPtr>*>(p)->store(
          new_obj, std::memory_order_release);
    } else {
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
    // TODO(rmacnak): Allocate one to start?
    if (tail_ != nullptr) {
      uword result = tail_->top_;
      ASSERT((result & kObjectAlignmentMask) == kNewObjectAlignmentOffset);
      uword new_top = result + size;
      if (LIKELY(new_top <= tail_->end_)) {
        tail_->top_ = new_top;
        return result;
      }
    }
    return TryAllocateCopySlow(size);
  }

  DART_NOINLINE inline uword TryAllocateCopySlow(intptr_t size);

  DART_NOINLINE DART_NORETURN void AbortScavenge() {
    if (FLAG_verbose_gc) {
      OS::PrintErr("Aborting scavenge\n");
    }
    scavenger_->abort_ = true;
    thread_->long_jump_base()->Jump(1, Object::out_of_memory_error());
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
  WeakPropertyPtr delayed_weak_properties_;

  NewPage* head_ = nullptr;
  NewPage* tail_ = nullptr;  // Allocating from here.
  NewPage* scan_ = nullptr;  // Resolving from here.

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

SemiSpace::SemiSpace(intptr_t max_capacity_in_words)
    : max_capacity_in_words_(max_capacity_in_words), head_(nullptr) {}

SemiSpace::~SemiSpace() {
  NewPage* page = head_;
  while (page != nullptr) {
    NewPage* next = page->next();
    page->Deallocate();
    page = next;
  }
}

// TODO(rmacnak): Unify this with old-space pages, and possibly zone segments.
// This cache needs to be at least as big as FLAG_new_gen_semi_max_size or
// munmap will noticably impact performance.
static constexpr intptr_t kPageCacheCapacity = 8 * kWordSize;
static Mutex* page_cache_mutex = nullptr;
static VirtualMemory* page_cache[kPageCacheCapacity] = {nullptr};
static intptr_t page_cache_size = 0;

void SemiSpace::Init() {
  ASSERT(page_cache_mutex == nullptr);
  page_cache_mutex = new Mutex(NOT_IN_PRODUCT("page_cache_mutex"));
}

void SemiSpace::Cleanup() {
  {
    MutexLocker ml(page_cache_mutex);
    ASSERT(page_cache_size >= 0);
    ASSERT(page_cache_size <= kPageCacheCapacity);
    while (page_cache_size > 0) {
      delete page_cache[--page_cache_size];
    }
  }
  delete page_cache_mutex;
  page_cache_mutex = nullptr;
}

intptr_t SemiSpace::CachedSize() {
  return page_cache_size * kNewPageSize;
}

NewPage* NewPage::Allocate() {
  const intptr_t size = kNewPageSize;
  VirtualMemory* memory = nullptr;
  {
    MutexLocker ml(page_cache_mutex);
    ASSERT(page_cache_size >= 0);
    ASSERT(page_cache_size <= kPageCacheCapacity);
    if (page_cache_size > 0) {
      memory = page_cache[--page_cache_size];
    }
  }
  if (memory == nullptr) {
    const intptr_t alignment = kNewPageSize;
    const bool is_executable = false;
    const char* const name = Heap::RegionName(Heap::kNew);
    memory =
        VirtualMemory::AllocateAligned(size, alignment, is_executable, name);
  }
  if (memory == nullptr) {
    return nullptr;  // Out of memory.
  }

#if defined(DEBUG)
  memset(memory->address(), Heap::kZapByte, size);
#endif
  // Initialized by generated code.
  MSAN_UNPOISON(memory->address(), size);

  NewPage* result = reinterpret_cast<NewPage*>(memory->address());
  result->memory_ = memory;
  result->next_ = nullptr;
  result->owner_ = nullptr;
  uword top = result->object_start();
  result->top_ = top;
  result->end_ = memory->end() - kNewObjectAlignmentOffset;
  result->survivor_end_ = top;
  result->resolved_top_ = top;

  LSAN_REGISTER_ROOT_REGION(result, sizeof(*result));

  return result;
}

void NewPage::Deallocate() {
  LSAN_UNREGISTER_ROOT_REGION(this, sizeof(*this));

  VirtualMemory* memory = memory_;
  {
    MutexLocker ml(page_cache_mutex);
    ASSERT(page_cache_size >= 0);
    ASSERT(page_cache_size <= kPageCacheCapacity);
    if (page_cache_size < kPageCacheCapacity) {
      intptr_t size = memory->size();
#if defined(DEBUG)
      memset(memory->address(), Heap::kZapByte, size);
#endif
      MSAN_POISON(memory->address(), size);
      page_cache[page_cache_size++] = memory;
      memory = nullptr;
    }
  }
  delete memory;
}

NewPage* SemiSpace::TryAllocatePageLocked(bool link) {
  if (capacity_in_words_ >= max_capacity_in_words_) {
    return nullptr;  // Full.
  }
  NewPage* page = NewPage::Allocate();
  if (page == nullptr) {
    return nullptr;  // Out of memory;
  }
  capacity_in_words_ += kNewPageSizeInWords;
  if (link) {
    if (head_ == nullptr) {
      head_ = tail_ = page;
    } else {
      tail_->set_next(page);
      tail_ = page;
    }
  }
  return page;
}

bool SemiSpace::Contains(uword addr) const {
  for (NewPage* page = head_; page != nullptr; page = page->next()) {
    if (page->Contains(addr)) return true;
  }
  return false;
}

void SemiSpace::WriteProtect(bool read_only) {
  for (NewPage* page = head_; page != nullptr; page = page->next()) {
    page->WriteProtect(read_only);
  }
}

void SemiSpace::AddList(NewPage* head, NewPage* tail) {
  if (head == nullptr) {
    return;
  }
  if (head_ == nullptr) {
    head_ = head;
    tail_ = tail;
    return;
  }
  tail_->set_next(head);
  tail_ = tail;
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
      failed_to_promote_(false),
      abort_(false) {
  // Verify assumptions about the first word in objects which the scavenger is
  // going to use for forwarding pointers.
  ASSERT(Object::tags_offset() == 0);

  // Set initial semi space size in words.
  const intptr_t initial_semi_capacity_in_words = Utils::Minimum(
      max_semi_capacity_in_words, FLAG_new_gen_semi_initial_size * MBInWords);

  to_ = new SemiSpace(initial_semi_capacity_in_words);
  idle_scavenge_threshold_in_words_ = initial_semi_capacity_in_words;

  UpdateMaxHeapCapacity();
  UpdateMaxHeapUsage();
}

Scavenger::~Scavenger() {
  ASSERT(!scavenging_);
  delete to_;
  ASSERT(blocks_ == nullptr);
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
              "Old object %#" Px " references new object %#" Px
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

  to_ = new SemiSpace(NewSizeInWords(from->max_capacity_in_words()));
  UpdateMaxHeapCapacity();

  return from;
}

void Scavenger::Epilogue(SemiSpace* from) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "Epilogue");

  // All objects in the to space have been copied from the from space at this
  // moment.

  // Ensure the mutator thread will fail the next allocation. This will force
  // mutator to allocate a new TLAB
#if defined(DEBUG)
  heap_->isolate_group()->ForEachIsolate(
      [&](Isolate* isolate) {
        Thread* mutator_thread = isolate->mutator_thread();
        ASSERT(mutator_thread == nullptr || mutator_thread->top() == 0);
      },
      /*at_safepoint=*/true);
#endif  // DEBUG

  double avg_frac = stats_history_.Get(0).PromoCandidatesSuccessFraction();
  if (stats_history_.Size() >= 2) {
    // Previous scavenge is only given half as much weight.
    avg_frac += 0.5 * stats_history_.Get(1).PromoCandidatesSuccessFraction();
    avg_frac /= 1.0 + 0.5;  // Normalize.
  }

  early_tenure_ = avg_frac >= (FLAG_early_tenuring_threshold / 100.0);

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

  delete from;
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
  // Normal reason: new space is getting full.
  bool for_new_space = used_in_words >= idle_scavenge_threshold_in_words_;
  // New-space objects are roots during old-space GC. This means that even
  // unreachable new-space objects prevent old-space objects they reference
  // from being collected during an old-space GC. Normally this is not an
  // issue because new-space GCs run much more frequently than old-space GCs.
  // If new-space allocation is low and direct old-space allocation is high,
  // which can happen in a program that allocates large objects and little
  // else, old-space can fill up with unreachable objects until the next
  // new-space GC. This check is the idle equivalent to the
  // new-space GC before synchronous-marking in CollectMostGarbage.
  bool for_old_space = heap_->last_gc_was_old_space_ &&
                       heap_->old_space()->ReachedIdleThreshold();
  if (!for_new_space && !for_old_space) {
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
  intptr_t total_count = 0;
  while (pending != nullptr) {
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
    blocks_ = pending = next;
  }
  // Done iterating through old objects remembered in the store buffers.
  visitor->VisitingOldObject(nullptr);

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
  heap_->isolate_group()->VisitObjectIdRingPointers(visitor);
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
    *p = ForwardedObj(header);
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
  while (scan_ != nullptr) {
    uword resolved_top = scan_->resolved_top_;
    while (resolved_top < scan_->top_) {
      ObjectPtr raw_obj = ObjectLayout::FromAddr(resolved_top);
      resolved_top += ProcessCopied(raw_obj);
    }
    scan_->resolved_top_ = resolved_top;

    NewPage* next = scan_->next();
    if (next == nullptr) {
      // Don't update scan_. More objects may yet be copied to this TLAB.
      return;
    }
    scan_ = next;
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
  if (scavenger_->abort_) return;

  // Finished this round of scavenging. Process the pending weak properties
  // for which the keys have become reachable. Potentially this adds more
  // objects to the to space.
  WeakPropertyPtr cur_weak = delayed_weak_properties_;
  delayed_weak_properties_ = WeakProperty::null();
  while (cur_weak != WeakProperty::null()) {
    WeakPropertyPtr next_weak = cur_weak->ptr()->next_;
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
    cur_weak->ptr()->next_ = WeakProperty::null();
    if (IsForwarding(header)) {
      cur_weak->ptr()->VisitPointersNonvirtual(this);
    } else {
      EnqueueWeakProperty(cur_weak);
    }
    // Advance to next weak property in the queue.
    cur_weak = next_weak;
  }
}

void Scavenger::UpdateMaxHeapCapacity() {
  if (heap_ == NULL) {
    // Some unit tests.
    return;
  }
  ASSERT(to_ != NULL);
  ASSERT(heap_ != NULL);
  auto isolate_group = heap_->isolate_group();
  ASSERT(isolate_group != NULL);
  isolate_group->GetHeapNewCapacityMaxMetric()->SetValue(
      to_->max_capacity_in_words() * kWordSize);
}

void Scavenger::UpdateMaxHeapUsage() {
  if (heap_ == NULL) {
    // Some unit tests.
    return;
  }
  ASSERT(to_ != NULL);
  ASSERT(heap_ != NULL);
  auto isolate_group = heap_->isolate_group();
  ASSERT(isolate_group != NULL);
  isolate_group->GetHeapNewUsedMaxMetric()->SetValue(UsedInWords() * kWordSize);
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
  ASSERT(raw_weak->ptr()->next_ == WeakProperty::null());
  raw_weak->ptr()->next_ = delayed_weak_properties_;
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
          raw_obj = ForwardedObj(header);
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
  ASSERT(!scavenger_->abort_);

  // The queued weak properties at this point do not refer to reachable keys,
  // so we clear their key and value fields.
  WeakPropertyPtr cur_weak = delayed_weak_properties_;
  delayed_weak_properties_ = WeakProperty::null();
  while (cur_weak != WeakProperty::null()) {
    WeakPropertyPtr next_weak = cur_weak->ptr()->next_;
    // Reset the next pointer in the weak property.
    cur_weak->ptr()->next_ = WeakProperty::null();

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
    cur_weak = next_weak;
  }
}

void Scavenger::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask) ||
         (Thread::Current()->task_kind() == Thread::kCompactorTask));
  for (NewPage* page = to_->head(); page != nullptr; page = page->next()) {
    page->VisitObjectPointers(visitor);
  }
}

void Scavenger::VisitObjects(ObjectVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask));
  for (NewPage* page = to_->head(); page != nullptr; page = page->next()) {
    page->VisitObjects(visitor);
  }
}

void Scavenger::AddRegionsToObjectSet(ObjectSet* set) const {
  for (NewPage* page = to_->head(); page != nullptr; page = page->next()) {
    set->AddRegion(page->start(), page->end());
  }
}

ObjectPtr Scavenger::FindObject(FindObjectVisitor* visitor) {
  ASSERT(!scavenging_);
  for (NewPage* page = to_->head(); page != nullptr; page = page->next()) {
    uword cur = page->object_start();
    if (!visitor->VisitRange(cur, page->object_end())) continue;
    while (cur < page->object_end()) {
      ObjectPtr raw_obj = ObjectLayout::FromAddr(cur);
      uword next = cur + raw_obj->ptr()->HeapSize();
      if (visitor->VisitRange(cur, next) &&
          raw_obj->ptr()->FindObject(visitor)) {
        return raw_obj;  // Found object, return it.
      }
      cur = next;
    }
    ASSERT(cur == page->object_end());
  }
  return Object::null();
}

void Scavenger::TryAllocateNewTLAB(Thread* thread, intptr_t min_size) {
  ASSERT(heap_ != Dart::vm_isolate()->heap());
  ASSERT(!scavenging_);

  AbandonRemainingTLAB(thread);

  MutexLocker ml(&space_lock_);
  for (NewPage* page = to_->head(); page != nullptr; page = page->next()) {
    if (page->owner() != nullptr) continue;
    intptr_t available = page->end() - page->object_end();
    if (available >= min_size) {
      page->Acquire(thread);
      return;
    }
  }

  NewPage* page = to_->TryAllocatePageLocked(true);
  if (page == nullptr) {
    return;
  }
  page->Acquire(thread);
}

void Scavenger::AbandonRemainingTLABForDebugging(Thread* thread) {
  // Allocate any remaining space so the TLAB won't be reused. Write a filler
  // object so it remains iterable.
  uword top = thread->top();
  intptr_t size = thread->end() - thread->top();
  if (size > 0) {
    thread->set_top(top + size);
    ForwardingCorpse::AsForwarder(top, size);
  }

  AbandonRemainingTLAB(thread);
}

void Scavenger::AbandonRemainingTLAB(Thread* thread) {
  if (thread->top() == 0) return;
  NewPage* page = NewPage::Of(thread->top() - 1);
  {
    MutexLocker ml(&space_lock_);
    page->Release(thread);
  }
  ASSERT(thread->top() == 0);
}

template <bool parallel>
uword ScavengerVisitorBase<parallel>::TryAllocateCopySlow(intptr_t size) {
  NewPage* page;
  {
    MutexLocker ml(&scavenger_->space_lock_);
    page = scavenger_->to_->TryAllocatePageLocked(false);
  }
  if (page == nullptr) {
    return 0;
  }

  if (head_ == nullptr) {
    head_ = scan_ = page;
  } else {
    ASSERT(scan_ != nullptr);
    tail_->set_next(page);
  }
  tail_ = page;

  return tail_->TryAllocateGC(size);
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
  failed_to_promote_ = false;
  abort_ = false;
  root_slices_started_ = 0;
  intptr_t abandoned_bytes = 0;  // TODO(rmacnak): Count fragmentation?
  SpaceUsage usage_before = GetCurrentUsage();
  intptr_t promo_candidate_words = 0;
  for (NewPage* page = to_->head(); page != nullptr; page = page->next()) {
    page->Release();
    if (early_tenure_) {
      page->EarlyTenure();
    }
    promo_candidate_words += page->promo_candidate_words();
  }
  SemiSpace* from = Prologue();

  intptr_t bytes_promoted;
  if (FLAG_scavenger_tasks == 0) {
    bytes_promoted = SerialScavenge(from);
  } else {
    bytes_promoted = ParallelScavenge(from);
  }
  if (abort_) {
    ReverseScavenge(&from);
    bytes_promoted = 0;
  } else if ((CapacityInWords() - UsedInWords()) < KBInWords) {
    // Don't scavenge again until the next old-space GC has occurred. Prevents
    // performing one scavenge per allocation as the heap limit is approached.
    heap_->assume_scavenge_will_fail_ = true;
  }
  ASSERT(promotion_stack_.IsEmpty());
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

  to_->AddList(visitor.head(), visitor.tail());
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
    to_->AddList(visitors[i]->head(), visitors[i]->tail());
    bytes_promoted += visitors[i]->bytes_promoted();
    delete visitors[i];
  }

  delete[] visitors;
  return bytes_promoted;
}

void Scavenger::ReverseScavenge(SemiSpace** from) {
  Thread* thread = Thread::Current();
  TIMELINE_FUNCTION_GC_DURATION(thread, "ReverseScavenge");

  class ReverseFromForwardingVisitor : public ObjectVisitor {
    uword ReadHeader(ObjectPtr raw_obj) {
      return reinterpret_cast<std::atomic<uword>*>(
                 ObjectLayout::ToAddr(raw_obj))
          ->load(std::memory_order_relaxed);
    }
    void WriteHeader(ObjectPtr raw_obj, uword header) {
      reinterpret_cast<std::atomic<uword>*>(ObjectLayout::ToAddr(raw_obj))
          ->store(header, std::memory_order_relaxed);
    }
    void VisitObject(ObjectPtr from_obj) {
      uword from_header = ReadHeader(from_obj);
      if (IsForwarding(from_header)) {
        ObjectPtr to_obj = ForwardedObj(from_header);
        uword to_header = ReadHeader(to_obj);
        intptr_t size = to_obj->ptr()->HeapSize();

        // Reset the ages bits in case this was a promotion.
        uword from_header = static_cast<uword>(to_header);
        from_header = ObjectLayout::OldBit::update(false, from_header);
        from_header =
            ObjectLayout::OldAndNotRememberedBit::update(false, from_header);
        from_header = ObjectLayout::NewBit::update(true, from_header);
        from_header =
            ObjectLayout::OldAndNotMarkedBit::update(false, from_header);

        WriteHeader(from_obj, from_header);

        ForwardingCorpse::AsForwarder(ObjectLayout::ToAddr(to_obj), size)
            ->set_target(from_obj);
      }
    }
  };

  ReverseFromForwardingVisitor visitor;
  for (NewPage* page = (*from)->head(); page != nullptr; page = page->next()) {
    page->VisitObjects(&visitor);
  }

  // Swap from-space and to-space. The abandoned to-space will be deleted in
  // the epilogue.
  SemiSpace* temp = to_;
  to_ = *from;
  *from = temp;

  // Release any remaining part of the promotion worklist that wasn't completed.
  promotion_stack_.Reset();

  // Release any remaining part of the rememebred set that wasn't completed.
  StoreBuffer* store_buffer = heap_->isolate_group()->store_buffer();
  StoreBufferBlock* pending = blocks_;
  while (pending != nullptr) {
    StoreBufferBlock* next = pending->next();
    pending->Reset();
    // Return the emptied block for recycling (no need to check threshold).
    store_buffer->PushBlock(pending, StoreBuffer::kIgnoreThreshold);
    pending = next;
  }
  blocks_ = nullptr;

  // Reverse the partial forwarding from the aborted scavenge. This also
  // rebuilds the remembered set.
  Become::FollowForwardingPointers(thread);

  // Don't scavenge again until the next old-space GC has occurred. Prevents
  // performing one scavenge per allocation as the heap limit is approached.
  heap_->assume_scavenge_will_fail_ = true;
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

void Scavenger::Evacuate() {
  // We need a safepoint here to prevent allocation right before or right after
  // the scavenge.
  // The former can introduce an object that we might fail to collect.
  // The latter means even if the scavenge promotes every object in the new
  // space, the new allocation means the space is not empty,
  // causing the assertion below to fail.
  SafepointOperationScope scope(Thread::Current());

  // Forces the next scavenge to promote all the objects in the new space.
  early_tenure_ = true;

  Scavenge();

  // It is possible for objects to stay in the new space
  // if the VM cannot create more pages for these objects.
  ASSERT((UsedInWords() == 0) || failed_to_promote_);
}

}  // namespace dart
