// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/scavenger.h"

#include "platform/assert.h"
#include "platform/leak_sanitizer.h"
#include "vm/class_id.h"
#include "vm/compiler/runtime_api.h"
#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/flag_list.h"
#include "vm/flags.h"
#include "vm/heap/become.h"
#include "vm/heap/gc_shared.h"
#include "vm/heap/pages.h"
#include "vm/heap/pointer_block.h"
#include "vm/heap/safepoint.h"
#include "vm/heap/verifier.h"
#include "vm/heap/weak_table.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_set.h"
#include "vm/port.h"
#include "vm/stack_frame.h"
#include "vm/tagged_pointer.h"
#include "vm/thread_barrier.h"
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
  kForwardingMask = 1 << UntaggedObject::kCardRememberedBit,
  kNotForwarded = 0,
  kForwarded = kForwardingMask,
};

// If the forwarded bit and pointer tag bit are the same, we can avoid a few
// conversions.
COMPILE_ASSERT(static_cast<uword>(kForwarded) ==
               static_cast<uword>(kHeapObjectTag));

DART_FORCE_INLINE
static bool IsForwarding(uword header) {
  uword bits = header & kForwardingMask;
  ASSERT((bits == kNotForwarded) || (bits == kForwarded));
  return bits == kForwarded;
}

DART_FORCE_INLINE
static ObjectPtr ForwardedObj(uword header) {
  ASSERT(IsForwarding(header));
  return static_cast<ObjectPtr>(header);
}

DART_FORCE_INLINE
static uword ForwardingHeader(ObjectPtr target) {
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
static void objcpy(void* dst, const void* src, size_t size) {
  // A mem copy specialized for objects. We can assume:
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

DART_FORCE_INLINE
static uword ReadHeaderRelaxed(ObjectPtr raw_obj) {
  return reinterpret_cast<std::atomic<uword>*>(UntaggedObject::ToAddr(raw_obj))
      ->load(std::memory_order_relaxed);
}

DART_FORCE_INLINE
static void WriteHeaderRelaxed(ObjectPtr raw_obj, uword header) {
  reinterpret_cast<std::atomic<uword>*>(UntaggedObject::ToAddr(raw_obj))
      ->store(header, std::memory_order_relaxed);
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
        promoted_list_(promotion_stack) {}
  ~ScavengerVisitorBase() { ASSERT(delayed_.IsEmpty()); }

#ifdef DEBUG
  constexpr static const char* const kName = "Scavenger";
#endif

  void VisitTypedDataViewPointers(TypedDataViewPtr view,
                                  CompressedObjectPtr* first,
                                  CompressedObjectPtr* last) override {
    // TypedDataViews require extra processing to update their
    // PointerBase::data_ pointer. If the underlying typed data is external, no
    // update is needed. If the underlying typed data is internal, the pointer
    // must be updated if the typed data was copied or promoted. We cannot
    // safely dereference the underlying typed data to make this distinction.
    // It may have been forwarded by a different scavenger worker, so the access
    // could have a data race. Rather than checking the CID of the underlying
    // typed data, which requires dereferencing the copied/promoted header, we
    // compare the view's internal pointer to what it should be if the
    // underlying typed data was internal, and assume that external typed data
    // never points into the Dart heap. We must do this before VisitPointers
    // because we want to compare the old pointer and old typed data.
    const bool is_external =
        view->untag()->data_ != view->untag()->DataFieldForInternalTypedData();

    // Forward all fields of the typed data view.
    VisitCompressedPointers(view->heap_base(), first, last);

    if (view->untag()->data_ == nullptr) {
      ASSERT(RawSmiValue(view->untag()->offset_in_bytes()) == 0 &&
             RawSmiValue(view->untag()->length()) == 0);
      ASSERT(is_external);
      return;
    }

    // Explicit ifdefs because the compiler does not eliminate the unused
    // relaxed load.
#if defined(DEBUG)
    // Validate 'this' is a typed data view.
    const uword view_header = ReadHeaderRelaxed(view);
    ASSERT(!IsForwarding(view_header) || view->IsOldObject());
    ASSERT(IsTypedDataViewClassId(view->GetClassIdMayBeSmi()) ||
           IsUnmodifiableTypedDataViewClassId(view->GetClassIdMayBeSmi()));

    // Validate that the backing store is not a forwarding word. There is a data
    // race reader the backing store's header unless there is only one worker.
    TypedDataBasePtr td = view->untag()->typed_data();
    ASSERT(td->IsHeapObject());
    if (!parallel) {
      const uword td_header = ReadHeaderRelaxed(td);
      ASSERT(!IsForwarding(td_header) || td->IsOldObject());
      if (td != Object::null()) {
        // Fast object copy temporarily stores null in the typed_data field of
        // views. This can cause the RecomputeDataFieldForInternalTypedData to
        // run inappropriately, but when the object copy continues it will fix
        // the data_ pointer.
        ASSERT_EQUAL(IsExternalTypedDataClassId(td->GetClassId()), is_external);
      }
    }
#endif

    // If we have external typed data we can simply return since the backing
    // store lives in C-heap and will not move.
    if (is_external) {
      return;
    }

    // Now we update the inner pointer.
#if defined(DEBUG)
    if (!parallel) {
      ASSERT(IsTypedDataClassId(td->GetClassId()));
    }
#endif
    view->untag()->RecomputeDataFieldForInternalTypedData();
  }

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    ASSERT(Utils::IsAligned(first, sizeof(*first)));
    ASSERT(Utils::IsAligned(last, sizeof(*last)));
    for (ObjectPtr* current = first; current <= last; current++) {
      ScavengePointer(current);
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    ASSERT(Utils::IsAligned(first, sizeof(*first)));
    ASSERT(Utils::IsAligned(last, sizeof(*last)));
    for (CompressedObjectPtr* current = first; current <= last; current++) {
      ScavengeCompressedPointer(heap_base, current);
    }
  }
#endif

  void VisitingOldObject(ObjectPtr obj) {
    ASSERT((obj == nullptr) || obj->IsOldObject());
    visiting_old_object_ = obj;
    if (obj != nullptr) {
      // Card update happens in Page::VisitRememberedCards.
      ASSERT(!obj->untag()->IsCardRemembered());
    }
  }

  intptr_t bytes_promoted() const { return bytes_promoted_; }

  void ProcessRoots() {
    thread_ = Thread::Current();
    page_space_->AcquireLock(freelist_);

    LongJumpScope jump(thread_);
    if (setjmp(*jump.Set()) == 0) {
      scavenger_->IterateRoots(this);
    } else {
      ASSERT(scavenger_->abort_);
    }
  }

  void ProcessSurvivors() {
    LongJumpScope jump(thread_);
    if (setjmp(*jump.Set()) == 0) {
      // Iterate until all work has been drained.
      do {
        ProcessToSpace();
        ProcessPromotedList();
      } while (HasWork());
    } else {
      ASSERT(scavenger_->abort_);
    }
  }

  void ProcessAll() {
    LongJumpScope jump(thread_);
    if (setjmp(*jump.Set()) == 0) {
      do {
        do {
          ProcessToSpace();
          ProcessPromotedList();
        } while (HasWork());
        ProcessWeakPropertiesScoped();
      } while (HasWork());
    } else {
      ASSERT(scavenger_->abort_);
    }
  }

  void ProcessWeakProperties() {
    LongJumpScope jump(thread_);
    if (setjmp(*jump.Set()) == 0) {
      ProcessWeakPropertiesScoped();
    } else {
      ASSERT(scavenger_->abort_);
    }
  }

  void ProcessWeakPropertiesScoped();

  bool HasWork() {
    if (scavenger_->abort_) return false;
    return (scan_ != tail_) || (scan_ != nullptr && !scan_->IsResolved()) ||
           !promoted_list_.IsEmpty();
  }

  bool WaitForWork(RelaxedAtomic<uintptr_t>* num_busy) {
    return promoted_list_.WaitForWork(num_busy);
  }

  void Finalize() {
    if (!scavenger_->abort_) {
      ASSERT(!HasWork());

      for (Page* page = head_; page != nullptr; page = page->next()) {
        ASSERT(page->IsResolved());
        page->RecordSurvivors();
      }

      MournWeakProperties();
      MournWeakReferences();
      MournWeakArrays();
      MournFinalizerEntries();
    }
    page_space_->ReleaseLock(freelist_);
    thread_ = nullptr;
  }

  void FinalizePromotion() { promoted_list_.Finalize(); }

  void AbandonWork() {
    promoted_list_.AbandonWork();
    delayed_.Release();
  }

  Page* head() const {
    return head_;
  }
  Page* tail() const {
    return tail_;
  }

  static bool ForwardOrSetNullIfCollected(uword heap_base,
                                          CompressedObjectPtr* ptr_address);

  void ProcessOldFinalizerEntry(FinalizerEntryPtr entry);

 private:
  DART_FORCE_INLINE
  void ScavengePointer(ObjectPtr* p) {
    // ScavengePointer cannot be called recursively.
    ObjectPtr raw_obj = *p;

    if (raw_obj->IsImmediateOrOldObject()) {
      return;
    }

    ObjectPtr new_obj = ScavengeObject(raw_obj);

    // Update the reference.
    if (!new_obj->IsNewObject()) {
      // Setting the mark bit above must not be ordered after a publishing store
      // of this object. Note this could be a publishing store even if the
      // object was promoted by an early invocation of ScavengePointer. Compare
      // Object::Allocate.
      reinterpret_cast<std::atomic<ObjectPtr>*>(p)->store(
          static_cast<ObjectPtr>(new_obj), std::memory_order_release);
    } else {
      *p = new_obj;
      // Update the store buffer as needed.
      ObjectPtr visiting_object = visiting_old_object_;
      if (visiting_object != nullptr &&
          visiting_object->untag()->TryAcquireRememberedBit()) {
        thread_->StoreBufferAddObjectGC(visiting_object);
      }
    }
  }

  DART_FORCE_INLINE
  void ScavengeCompressedPointer(uword heap_base, CompressedObjectPtr* p) {
    // ScavengePointer cannot be called recursively.
    ObjectPtr raw_obj = p->Decompress(heap_base);

    // Could be tested without decompression.
    if (raw_obj->IsImmediateOrOldObject()) {
      return;
    }

    ObjectPtr new_obj = ScavengeObject(raw_obj);

    // Update the reference.
    if (!new_obj->IsNewObject()) {
      // Setting the mark bit above must not be ordered after a publishing store
      // of this object. Note this could be a publishing store even if the
      // object was promoted by an early invocation of ScavengePointer. Compare
      // Object::Allocate.
      reinterpret_cast<std::atomic<CompressedObjectPtr>*>(p)->store(
          static_cast<CompressedObjectPtr>(new_obj), std::memory_order_release);
    } else {
      *p = new_obj;
      // Update the store buffer as needed.
      ObjectPtr visiting_object = visiting_old_object_;
      if (visiting_object != nullptr &&
          visiting_object->untag()->TryAcquireRememberedBit()) {
        thread_->StoreBufferAddObjectGC(visiting_object);
      }
    }
  }

  DART_FORCE_INLINE
  ObjectPtr ScavengeObject(ObjectPtr raw_obj) {
    // Fragmentation might cause the scavenge to fail. Ensure we always have
    // somewhere to bail out to.
    ASSERT(thread_->long_jump_base() != nullptr);

    uword raw_addr = UntaggedObject::ToAddr(raw_obj);
    // The scavenger is only expects objects located in the from space.
    ASSERT(from_->Contains(raw_addr));
    // Read the header word of the object and determine if the object has
    // already been copied.
    uword header = ReadHeaderRelaxed(raw_obj);
    ObjectPtr new_obj;
    if (IsForwarding(header)) {
      // Get the new location of the object.
      new_obj = ForwardedObj(header);
    } else {
      intptr_t size = raw_obj->untag()->HeapSize(header);
      ASSERT(IsAllocatableInNewSpace(size));
      uword new_addr = 0;
      // Check whether object should be promoted.
      if (!Page::Of(raw_obj)->IsSurvivor(raw_addr)) {
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
          promoted_list_.Push(UntaggedObject::FromAddr(new_addr));
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

      new_obj = UntaggedObject::FromAddr(new_addr);
      if (new_obj->IsOldObject()) {
        // Promoted: update age/barrier tags.
        uword tags = static_cast<uword>(header);
        tags = UntaggedObject::OldBit::update(true, tags);
        tags = UntaggedObject::OldAndNotRememberedBit::update(true, tags);
        tags = UntaggedObject::NewBit::update(false, tags);
        // Setting the forwarding pointer below will make this tenured object
        // visible to the concurrent marker, but we haven't visited its slots
        // yet. We mark the object here to prevent the concurrent marker from
        // adding it to the mark stack and visiting its unprocessed slots. We
        // push it to the mark stack after forwarding its slots.
        tags = UntaggedObject::OldAndNotMarkedBit::update(
            !thread_->is_marking(), tags);
        // release: Setting the mark bit above must not be ordered after a
        // publishing store of this object. Compare Object::Allocate.
        new_obj->untag()->tags_.store(tags, std::memory_order_release);
      }

      intptr_t cid = UntaggedObject::ClassIdTag::decode(header);
      if (IsTypedDataClassId(cid)) {
        static_cast<TypedDataPtr>(new_obj)->untag()->RecomputeDataField();
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

    return new_obj;
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

  DART_NOINLINE uword TryAllocateCopySlow(intptr_t size);

  DART_NOINLINE DART_NORETURN void AbortScavenge() {
    if (FLAG_verbose_gc) {
      OS::PrintErr("Aborting scavenge\n");
    }
    scavenger_->abort_ = true;
    // N.B. We must not set the sticky error, which may be a data race if
    // that root slot was processed by a different worker.
    thread_->long_jump_base()->Jump(1);
  }

  void ProcessToSpace();
  DART_FORCE_INLINE intptr_t ProcessCopied(ObjectPtr raw_obj);
  void ProcessPromotedList();

  bool IsNotForwarding(ObjectPtr raw) {
    ASSERT(raw->IsHeapObject());
    ASSERT(raw->IsNewObject());
    return !IsForwarding(ReadHeaderRelaxed(raw));
  }

  void MournWeakProperties() {
    WeakPropertyPtr current = delayed_.weak_properties.Release();
    while (current != WeakProperty::null()) {
      WeakPropertyPtr next = current->untag()->next_seen_by_gc();
      current->untag()->next_seen_by_gc_ = WeakProperty::null();
      current->untag()->key_ = Object::null();
      current->untag()->value_ = Object::null();
      current = next;
    }
  }

  void MournWeakReferences() {
    WeakReferencePtr current = delayed_.weak_references.Release();
    while (current != WeakReference::null()) {
      WeakReferencePtr next = current->untag()->next_seen_by_gc();
      current->untag()->next_seen_by_gc_ = WeakReference::null();
      ForwardOrSetNullIfCollected(current->heap_base(),
                                  &current->untag()->target_);
      current = next;
    }
  }

  void MournWeakArrays() {
    WeakArrayPtr current = delayed_.weak_arrays.Release();
    while (current != WeakArray::null()) {
      WeakArrayPtr next = current->untag()->next_seen_by_gc();
      current->untag()->next_seen_by_gc_ = WeakArray::null();
      intptr_t length = Smi::Value(current->untag()->length());
      for (intptr_t i = 0; i < length; i++) {
        ForwardOrSetNullIfCollected(current->heap_base(),
                                    &(current->untag()->data()[i]));
      }
      current = next;
    }
  }

  void MournFinalizerEntries() {
    FinalizerEntryPtr current = delayed_.finalizer_entries.Release();
    while (current != FinalizerEntry::null()) {
      FinalizerEntryPtr next = current->untag()->next_seen_by_gc();
      current->untag()->next_seen_by_gc_ = FinalizerEntry::null();
      MournFinalizerEntry(this, current);
      current = next;
    }
  }

  Thread* thread_;
  Scavenger* scavenger_;
  SemiSpace* from_;
  PageSpace* page_space_;
  FreeList* freelist_;
  intptr_t bytes_promoted_;
  ObjectPtr visiting_old_object_;
  PromotionWorkList promoted_list_;
  GCLinkedLists delayed_;

  Page* head_ = nullptr;
  Page* tail_ = nullptr;  // Allocating from here.
  Page* scan_ = nullptr;  // Resolving from here.

  DISALLOW_COPY_AND_ASSIGN(ScavengerVisitorBase);
};

typedef ScavengerVisitorBase<false> SerialScavengerVisitor;
typedef ScavengerVisitorBase<true> ParallelScavengerVisitor;

static bool IsUnreachable(ObjectPtr* ptr) {
  ObjectPtr raw_obj = *ptr;
  if (raw_obj->IsImmediateOrOldObject()) {
    return false;
  }
  uword raw_addr = UntaggedObject::ToAddr(raw_obj);
  uword header = *reinterpret_cast<uword*>(raw_addr);
  if (IsForwarding(header)) {
    *ptr = ForwardedObj(header);
    return false;
  }
  return true;
}

class ScavengerWeakVisitor : public HandleVisitor {
 public:
  explicit ScavengerWeakVisitor(Thread* thread) : HandleVisitor(thread) {}

  void VisitHandle(uword addr) override {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    ObjectPtr* p = handle->ptr_addr();
    if (IsUnreachable(p)) {
      handle->UpdateUnreachable(thread()->isolate_group());
    } else {
      handle->UpdateRelocated(thread()->isolate_group());
    }
  }

 private:
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
    if (!barrier_->TryEnter()) {
      barrier_->Release();
      return;
    }

    bool result = Thread::EnterIsolateGroupAsHelper(
        isolate_group_, Thread::kScavengerTask, /*bypass_safepoint=*/true);
    ASSERT(result);

    RunEnteredIsolateGroup();

    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);

    barrier_->Sync();
    barrier_->Release();
  }

  void RunEnteredIsolateGroup() {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ParallelScavenge");

    num_busy_->fetch_add(1u);
    visitor_->ProcessRoots();

    // Phase 1: Copying.
    bool more_to_scavenge = false;
    do {
      do {
        visitor_->ProcessSurvivors();
      } while (visitor_->WaitForWork(num_busy_));
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

    ASSERT(!visitor_->HasWork());

    // Phase 2: Weak processing, statistics.
    visitor_->Finalize();
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
  Page* page = head_;
  while (page != nullptr) {
    Page* next = page->next();
    page->Deallocate();
    page = next;
  }
}

Page* SemiSpace::TryAllocatePageLocked(bool link) {
  if (capacity_in_words_ >= max_capacity_in_words_) {
    return nullptr;  // Full.
  }
  Page* page = Page::Allocate(kPageSize, Page::kNew);
  if (page == nullptr) {
    return nullptr;  // Out of memory;
  }
  capacity_in_words_ += kPageSizeInWords;
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
  for (Page* page = head_; page != nullptr; page = page->next()) {
    if (page->Contains(addr)) return true;
  }
  return false;
}

void SemiSpace::WriteProtect(bool read_only) {
  for (Page* page = head_; page != nullptr; page = page->next()) {
    page->WriteProtect(read_only);
  }
}

void SemiSpace::AddList(Page* head, Page* tail) {
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
static constexpr intptr_t kConservativeInitialScavengeSpeed = 40;

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

intptr_t Scavenger::NewSizeInWords(intptr_t old_size_in_words,
                                   GCReason reason) const {
  bool grow = false;
  if (2 * heap_->isolate_group()->MutatorCount() >
      (old_size_in_words / kPageSizeInWords)) {
    // Not enough TLABs to give two to each mutator.
    grow = true;
  }

  if (reason == GCReason::kNewSpace) {
    // If we GC for a reason other than new-space being full (i.e., full
    // collection for old-space or store-buffer overflow), that's not an
    // indication that new-space is too small.
    if (stats_history_.Size() != 0) {
      double garbage = stats_history_.Get(0).ExpectedGarbageFraction();
      if (garbage < (FLAG_new_gen_garbage_threshold / 100.0)) {
        // Too much survived last time; grow new-space in the hope that a
        // greater fraction of objects will become unreachable before new-space
        // becomes full.
        grow = true;
      }
    }
  }

  if (grow) {
    return Utils::Minimum(max_semi_capacity_in_words_,
                          old_size_in_words * FLAG_new_gen_growth_factor);
  }
  return old_size_in_words;
}

class CollectStoreBufferVisitor : public ObjectPointerVisitor {
 public:
  CollectStoreBufferVisitor(ObjectSet* in_store_buffer, const char* msg)
      : ObjectPointerVisitor(IsolateGroup::Current()),
        in_store_buffer_(in_store_buffer),
        msg_(msg) {}

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr raw_obj = *ptr;
      RELEASE_ASSERT_WITH_MSG(raw_obj->untag()->IsRemembered(), msg_);
      RELEASE_ASSERT_WITH_MSG(raw_obj->IsOldObject(), msg_);

      RELEASE_ASSERT_WITH_MSG(!raw_obj->untag()->IsCardRemembered(), msg_);
      if (raw_obj.GetClassId() == kArrayCid) {
        const uword length =
            Smi::Value(static_cast<UntaggedArray*>(raw_obj.untag())->length());
        RELEASE_ASSERT_WITH_MSG(!Array::UseCardMarkingForAllocation(length),
                                msg_);
      }
      in_store_buffer_->Add(raw_obj);
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* from,
                               CompressedObjectPtr* to) override {
    UNREACHABLE();  // Store buffer blocks are not compressed.
  }
#endif

 private:
  ObjectSet* const in_store_buffer_;
  const char* msg_;
};

class CheckStoreBufferVisitor : public ObjectVisitor,
                                public ObjectPointerVisitor {
 public:
  CheckStoreBufferVisitor(ObjectSet* in_store_buffer,
                          const SemiSpace* to,
                          const char* msg)
      : ObjectVisitor(),
        ObjectPointerVisitor(IsolateGroup::Current()),
        in_store_buffer_(in_store_buffer),
        to_(to),
        msg_(msg) {}

  void VisitObject(ObjectPtr raw_obj) override {
    if (raw_obj->IsPseudoObject()) return;
    RELEASE_ASSERT_WITH_MSG(raw_obj->IsOldObject(), msg_);

    RELEASE_ASSERT_WITH_MSG(
        raw_obj->untag()->IsRemembered() == in_store_buffer_->Contains(raw_obj),
        msg_);

    visiting_ = raw_obj;
    is_remembered_ = raw_obj->untag()->IsRemembered();
    is_card_remembered_ = raw_obj->untag()->IsCardRemembered();
    if (is_card_remembered_) {
      RELEASE_ASSERT_WITH_MSG(!is_remembered_, msg_);
    }
    raw_obj->untag()->VisitPointers(this);
  }

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr raw_obj = *ptr;
      if (raw_obj->IsHeapObject() && raw_obj->IsNewObject()) {
        if (is_card_remembered_) {
          if (!Page::Of(visiting_)->IsCardRemembered(ptr)) {
            FATAL(
                "%s: Old object %#" Px " references new object %#" Px
                ", but the "
                "slot's card is not remembered. Consider using rr to watch the "
                "slot %p and reverse-continue to find the store with a missing "
                "barrier.\n",
                msg_, static_cast<uword>(visiting_),
                static_cast<uword>(raw_obj), ptr);
          }
        } else if (!is_remembered_) {
          FATAL("%s: Old object %#" Px " references new object %#" Px
                ", but it is "
                "not in any store buffer. Consider using rr to watch the "
                "slot %p and reverse-continue to find the store with a missing "
                "barrier.\n",
                msg_, static_cast<uword>(visiting_),
                static_cast<uword>(raw_obj), ptr);
        }
        RELEASE_ASSERT_WITH_MSG(to_->Contains(UntaggedObject::ToAddr(raw_obj)),
                                msg_);
      }
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* from,
                               CompressedObjectPtr* to) override {
    for (CompressedObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr raw_obj = ptr->Decompress(heap_base);
      if (raw_obj->IsHeapObject() && raw_obj->IsNewObject()) {
        if (is_card_remembered_) {
          if (!Page::Of(visiting_)->IsCardRemembered(ptr)) {
            FATAL(
                "%s: Old object %#" Px " references new object %#" Px
                ", but the "
                "slot's card is not remembered. Consider using rr to watch the "
                "slot %p and reverse-continue to find the store with a missing "
                "barrier.\n",
                msg_, static_cast<uword>(visiting_),
                static_cast<uword>(raw_obj), ptr);
          }
        } else if (!is_remembered_) {
          FATAL("%s: Old object %#" Px " references new object %#" Px
                ", but it is "
                "not in any store buffer. Consider using rr to watch the "
                "slot %p and reverse-continue to find the store with a missing "
                "barrier.\n",
                msg_, static_cast<uword>(visiting_),
                static_cast<uword>(raw_obj), ptr);
        }
        RELEASE_ASSERT_WITH_MSG(to_->Contains(UntaggedObject::ToAddr(raw_obj)),
                                msg_);
      }
    }
  }
#endif

 private:
  const ObjectSet* const in_store_buffer_;
  const SemiSpace* const to_;
  ObjectPtr visiting_;
  bool is_remembered_;
  bool is_card_remembered_;
  const char* msg_;
};

void Scavenger::VerifyStoreBuffers(const char* msg) {
  ASSERT(msg != nullptr);
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();

  ObjectSet* in_store_buffer = new (zone) ObjectSet(zone);
  heap_->AddRegionsToObjectSet(in_store_buffer);

  {
    CollectStoreBufferVisitor visitor(in_store_buffer, msg);
    heap_->isolate_group()->store_buffer()->VisitObjectPointers(&visitor);
  }

  {
    CheckStoreBufferVisitor visitor(in_store_buffer, to_, msg);
    heap_->old_space()->VisitObjects(&visitor);
  }
}

SemiSpace* Scavenger::Prologue(GCReason reason) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "Prologue");

  heap_->isolate_group()->ReleaseStoreBuffers();

  if (FLAG_verify_store_buffer) {
    heap_->WaitForSweeperTasksAtSafepoint(Thread::Current());
    VerifyStoreBuffers("Verifying remembered set before Scavenge");
  }

  // Need to stash the old remembered set before any worker begins adding to the
  // new remembered set.
  blocks_ = heap_->isolate_group()->store_buffer()->TakeBlocks();

  // Flip the two semi-spaces so that to_ is always the space for allocating
  // objects.
  SemiSpace* from;
  {
    MutexLocker ml(&space_lock_);
    from = to_;
    to_ = new SemiSpace(NewSizeInWords(from->max_capacity_in_words(), reason));
  }
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

    heap_->WaitForSweeperTasksAtSafepoint(Thread::Current());
    VerifyStoreBuffers("Verifying remembered set after Scavenge");
  }

  delete from;
  UpdateMaxHeapUsage();
  if (heap_ != nullptr) {
    heap_->UpdateGlobalMaxUsed();
  }
}

bool Scavenger::ShouldPerformIdleScavenge(int64_t deadline) {
  // To make a consistent decision, we should not yield for a safepoint in the
  // middle of deciding whether to perform an idle GC.
  NoSafepointScope no_safepoint;

  // TODO(rmacnak): Investigate collecting a history of idle period durations.
  intptr_t used_in_words = UsedInWords();
  intptr_t external_in_words = ExternalInWords();
  // Normal reason: new space is getting full.
  bool for_new_space = (used_in_words >= idle_scavenge_threshold_in_words_) ||
                       (external_in_words >= idle_scavenge_threshold_in_words_);
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
  while (pending != nullptr) {
    StoreBufferBlock* next = pending->next();
    // Generated code appends to store buffers; tell MemorySanitizer.
    MSAN_UNPOISON(pending, sizeof(*pending));
    while (!pending->IsEmpty()) {
      ObjectPtr raw_object = pending->Pop();
      ASSERT(!raw_object->IsForwardingCorpse());
      ASSERT(raw_object->untag()->IsRemembered());
      raw_object->untag()->ClearRememberedBit();
      visitor->VisitingOldObject(raw_object);
      // This treats old-space weak references in WeakProperty, WeakReference,
      // and FinalizerEntry as strong references. This prevents us from having
      // to enqueue them in `visitor->delayed_`. Enqueuing them in the delayed
      // would require having two `next_seen_by_gc` fields. One for used during
      // marking and one for the objects seen in the store buffers + new space.
      // Treating the weak references as strong here means we can have a single
      // `next_seen_by_gc` field.
      if (UNLIKELY(raw_object->GetClassId() == kFinalizerEntryCid)) {
        visitor->ProcessOldFinalizerEntry(
            static_cast<FinalizerEntryPtr>(raw_object));
      } else {
        // This treats old-space WeakProperties and WeakReferences as strong. A
        // dead key or target won't be reclaimed until after it is promoted.
        raw_object->untag()->VisitPointersNonvirtual(visitor);
      }
    }
    pending->Reset();
    // Return the emptied block for recycling (no need to check threshold).
    store_buffer->PushBlock(pending, StoreBuffer::kIgnoreThreshold);
    blocks_ = pending = next;
  }
  // Done iterating through old objects remembered in the store buffers.
  visitor->VisitingOldObject(nullptr);
}

template <bool parallel>
void Scavenger::IterateRememberedCards(
    ScavengerVisitorBase<parallel>* visitor) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "IterateRememberedCards");
  heap_->old_space()->VisitRememberedCards(visitor);
  visitor->VisitingOldObject(nullptr);
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
  kStoreBuffer,
  kNumRootSlices,
};

template <bool parallel>
void Scavenger::IterateRoots(ScavengerVisitorBase<parallel>* visitor) {
  for (;;) {
    intptr_t slice = root_slices_started_.fetch_add(1);
    if (slice >= kNumRootSlices) {
      break;  // No more slices.
    }

    switch (slice) {
      case kIsolate:
        IterateIsolateRoots(visitor);
        break;
      case kObjectIdRing:
        IterateObjectIdTable(visitor);
        break;
      case kStoreBuffer:
        IterateStoreBuffers(visitor);
        break;
      default:
        UNREACHABLE();
    }
  }

  IterateRememberedCards(visitor);
}

void Scavenger::MournWeakHandles() {
  Thread* thread = Thread::Current();
  TIMELINE_FUNCTION_GC_DURATION(thread, "MournWeakHandles");
  ScavengerWeakVisitor weak_visitor(thread);
  heap_->isolate_group()->VisitWeakPersistentHandles(&weak_visitor);
}

template <bool parallel>
void ScavengerVisitorBase<parallel>::ProcessToSpace() {
  while (scan_ != nullptr) {
    uword resolved_top = scan_->resolved_top_;
    while (resolved_top < scan_->top_) {
      ObjectPtr raw_obj = UntaggedObject::FromAddr(resolved_top);
      resolved_top += ProcessCopied(raw_obj);
    }
    scan_->resolved_top_ = resolved_top;

    Page* next = scan_->next();
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
  while (promoted_list_.Pop(&raw_object)) {
    // Resolve or copy all objects referred to by the current object. This
    // can potentially push more objects on this stack as well as add more
    // objects to be resolved in the to space.
    ASSERT(!raw_object->untag()->IsRemembered());
    VisitingOldObject(raw_object);
    if (UNLIKELY(raw_object->GetClassId() == kFinalizerEntryCid)) {
      ProcessOldFinalizerEntry(static_cast<FinalizerEntryPtr>(raw_object));
    } else {
      raw_object->untag()->VisitPointersNonvirtual(this);
    }
    if (raw_object->untag()->IsMarked()) {
      // Complete our promise from ScavengePointer. Note that marker cannot
      // visit this object until it pops a block from the mark stack, which
      // involves a memory fence from the mutex, so even on architectures
      // with a relaxed memory model, the marker will see the fully
      // forwarded contents of this object.
      thread_->MarkingStackAddObject(raw_object);
    }
  }
  VisitingOldObject(nullptr);
}

template <bool parallel>
void ScavengerVisitorBase<parallel>::ProcessWeakPropertiesScoped() {
  if (scavenger_->abort_) return;

  // Finished this round of scavenging. Process the pending weak properties
  // for which the keys have become reachable. Potentially this adds more
  // objects to the to space.
  WeakPropertyPtr cur_weak = delayed_.weak_properties.Release();
  while (cur_weak != WeakProperty::null()) {
    WeakPropertyPtr next_weak =
        cur_weak->untag()->next_seen_by_gc_.Decompress(cur_weak->heap_base());
    // Promoted weak properties are not enqueued. So we can guarantee that
    // we do not need to think about store barriers here.
    ASSERT(cur_weak->IsNewObject());
    ObjectPtr raw_key = cur_weak->untag()->key();
    ASSERT(raw_key->IsHeapObject());
    // Key still points into from space even if the object has been
    // promoted to old space by now. The key will be updated accordingly
    // below when VisitPointers is run.
    ASSERT(raw_key->IsNewObject());
    uword raw_addr = UntaggedObject::ToAddr(raw_key);
    ASSERT(from_->Contains(raw_addr));
    uword header = ReadHeaderRelaxed(raw_key);
    // Reset the next pointer in the weak property.
    cur_weak->untag()->next_seen_by_gc_ = WeakProperty::null();
    if (IsForwarding(header)) {
      cur_weak->untag()->VisitPointersNonvirtual(this);
    } else {
      ASSERT(IsNotForwarding(cur_weak));
      delayed_.weak_properties.Enqueue(cur_weak);
    }
    // Advance to next weak property in the queue.
    cur_weak = next_weak;
  }
}

void Scavenger::UpdateMaxHeapCapacity() {
  if (heap_ == nullptr) {
    // Some unit tests.
    return;
  }
  ASSERT(to_ != nullptr);
  ASSERT(heap_ != nullptr);
  auto isolate_group = heap_->isolate_group();
  ASSERT(isolate_group != nullptr);
  isolate_group->GetHeapNewCapacityMaxMetric()->SetValue(
      to_->max_capacity_in_words() * kWordSize);
}

void Scavenger::UpdateMaxHeapUsage() {
  if (heap_ == nullptr) {
    // Some unit tests.
    return;
  }
  ASSERT(to_ != nullptr);
  ASSERT(heap_ != nullptr);
  auto isolate_group = heap_->isolate_group();
  ASSERT(isolate_group != nullptr);
  isolate_group->GetHeapNewUsedMaxMetric()->SetValue(UsedInWords() * kWordSize);
}

template <bool parallel>
intptr_t ScavengerVisitorBase<parallel>::ProcessCopied(ObjectPtr raw_obj) {
  intptr_t class_id = raw_obj->GetClassId();
  if (UNLIKELY(class_id == kWeakPropertyCid)) {
    WeakPropertyPtr raw_weak = static_cast<WeakPropertyPtr>(raw_obj);
    // The fate of the weak property is determined by its key.
    ObjectPtr raw_key = raw_weak->untag()->key();
    if (!raw_key->IsImmediateOrOldObject()) {
      uword header = ReadHeaderRelaxed(raw_key);
      if (!IsForwarding(header)) {
        // Key is white.  Enqueue the weak property.
        ASSERT(IsNotForwarding(raw_weak));
        delayed_.weak_properties.Enqueue(raw_weak);
        return raw_weak->untag()->HeapSize();
      }
    }
    // Key is gray or black.  Make the weak property black.
  } else if (UNLIKELY(class_id == kWeakReferenceCid)) {
    WeakReferencePtr raw_weak = static_cast<WeakReferencePtr>(raw_obj);
    // The fate of the weak reference target is determined by its target.
    ObjectPtr raw_target = raw_weak->untag()->target();
    if (!raw_target->IsImmediateOrOldObject()) {
      uword header = ReadHeaderRelaxed(raw_target);
      if (!IsForwarding(header)) {
        // Target is white. Enqueue the weak reference. Always visit type
        // arguments.
        ASSERT(IsNotForwarding(raw_weak));
        delayed_.weak_references.Enqueue(raw_weak);
#if !defined(DART_COMPRESSED_POINTERS)
        ScavengePointer(&raw_weak->untag()->type_arguments_);
#else
        ScavengeCompressedPointer(raw_weak->heap_base(),
                                  &raw_weak->untag()->type_arguments_);
#endif
        return raw_weak->untag()->HeapSize();
      }
    }
  } else if (UNLIKELY(class_id == kWeakArrayCid)) {
    WeakArrayPtr raw_weak = static_cast<WeakArrayPtr>(raw_obj);
    delayed_.weak_arrays.Enqueue(raw_weak);
    return raw_weak->untag()->HeapSize();
  } else if (UNLIKELY(class_id == kFinalizerEntryCid)) {
    FinalizerEntryPtr raw_entry = static_cast<FinalizerEntryPtr>(raw_obj);
    ASSERT(IsNotForwarding(raw_entry));
    delayed_.finalizer_entries.Enqueue(raw_entry);
    // Only visit token and next.
#if !defined(DART_COMPRESSED_POINTERS)
    ScavengePointer(&raw_entry->untag()->token_);
    ScavengePointer(&raw_entry->untag()->next_);
#else
    ScavengeCompressedPointer(raw_entry->heap_base(),
                              &raw_entry->untag()->token_);
    ScavengeCompressedPointer(raw_entry->heap_base(),
                              &raw_entry->untag()->next_);
#endif
    return raw_entry->untag()->HeapSize();
  }
  return raw_obj->untag()->VisitPointersNonvirtual(this);
}

template <bool parallel>
void ScavengerVisitorBase<parallel>::ProcessOldFinalizerEntry(
    FinalizerEntryPtr raw_entry) {
  if (FLAG_trace_finalizers) {
    THR_Print("Scavenger::ProcessOldFinalizerEntry %p\n", raw_entry->untag());
  }
  // Detect `FinalizerEntry::value` promotion to update external space.
  //
  // This treats old-space FinalizerEntry fields as strong. Values, detach
  // keys, and finalizers in new space won't be reclaimed until after they
  // are promoted.
  // This will only visit the strong references, end enqueue the entry.
  // This enables us to update external space in MournFinalizerEntries.
  const Heap::Space before_gc_space = SpaceForExternal(raw_entry);
  UntaggedFinalizerEntry::VisitFinalizerEntryPointers(raw_entry, this);
  if (before_gc_space == Heap::kNew) {
    const Heap::Space after_gc_space = SpaceForExternal(raw_entry);
    if (after_gc_space == Heap::kOld) {
      const intptr_t external_size = raw_entry->untag()->external_size_;
      if (external_size > 0) {
        if (FLAG_trace_finalizers) {
          THR_Print("Scavenger %p, promoting external size %" Pd
                    " bytes from new to old space\n",
                    this, external_size);
        }
        isolate_group()->heap()->PromotedExternal(external_size);
      }
    }
  }
}

void Scavenger::MournWeakTables() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "MournWeakTables");

  auto rehash_weak_table = [](WeakTable* table, WeakTable* replacement_new,
                              WeakTable* replacement_old,
                              Dart_HeapSamplingDeleteCallback cleanup) {
    intptr_t size = table->size();
    for (intptr_t i = 0; i < size; i++) {
      if (table->IsValidEntryAtExclusive(i)) {
        ObjectPtr raw_obj = table->ObjectAtExclusive(i);
        ASSERT(raw_obj->IsHeapObject());
        uword raw_addr = UntaggedObject::ToAddr(raw_obj);
        uword header = *reinterpret_cast<uword*>(raw_addr);
        if (IsForwarding(header)) {
          // The object has survived.  Preserve its record.
          raw_obj = ForwardedObj(header);
          auto replacement =
              raw_obj->IsNewObject() ? replacement_new : replacement_old;
          replacement->SetValueExclusive(raw_obj, table->ValueAtExclusive(i));
        } else {
          // The object has been collected.
          if (cleanup != nullptr) {
            cleanup(reinterpret_cast<void*>(table->ValueAtExclusive(i)));
          }
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

    Dart_HeapSamplingDeleteCallback cleanup = nullptr;
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
    if (sel == Heap::kHeapSamplingData) {
      cleanup = HeapProfileSampler::delete_callback();
    }
#endif
    rehash_weak_table(table, table_new, table_old, cleanup);
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
          rehash_weak_table(table, replacement, isolate->forward_table_old(),
                            nullptr);
          isolate->set_forward_table_new(replacement);
        }
      },
      /*at_safepoint=*/true);
}

// Returns whether the object referred to in `ptr_address` was GCed this GC.
template <bool parallel>
bool ScavengerVisitorBase<parallel>::ForwardOrSetNullIfCollected(
    uword heap_base,
    CompressedObjectPtr* ptr_address) {
  ObjectPtr raw = ptr_address->Decompress(heap_base);
  if (raw->IsImmediateOrOldObject()) {
    // Object already null (which is old) or not touched during this GC.
    return false;
  }
  uword header = *reinterpret_cast<uword*>(UntaggedObject::ToAddr(raw));
  if (IsForwarding(header)) {
    // Get the new location of the object.
    *ptr_address = ForwardedObj(header);
    return false;
  }
  ASSERT(raw->IsHeapObject());
  ASSERT(raw->IsNewObject());
  *ptr_address = Object::null();
  return true;
}

void Scavenger::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  ASSERT(Thread::Current()->OwnsGCSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask) ||
         (Thread::Current()->task_kind() == Thread::kCompactorTask));
  for (Page* page = to_->head(); page != nullptr; page = page->next()) {
    page->VisitObjectPointers(visitor);
  }
}

void Scavenger::VisitObjects(ObjectVisitor* visitor) const {
  ASSERT(Thread::Current()->OwnsGCSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask));
  for (Page* page = to_->head(); page != nullptr; page = page->next()) {
    page->VisitObjects(visitor);
  }
}

void Scavenger::AddRegionsToObjectSet(ObjectSet* set) const {
  for (Page* page = to_->head(); page != nullptr; page = page->next()) {
    set->AddRegion(page->start(), page->end());
  }
}

void Scavenger::TryAllocateNewTLAB(Thread* thread,
                                   intptr_t min_size,
                                   bool can_safepoint) {
  ASSERT(heap_ != Dart::vm_isolate_group()->heap());
  ASSERT(!scavenging_);

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  // Find the remaining space available in the TLAB before abandoning it so we
  // can reset the heap sampling offset in the new TLAB.
  intptr_t remaining = thread->true_end() - thread->top();
  const bool heap_sampling_enabled = thread->end() != thread->true_end();
  const bool is_first_tlab = thread->true_end() == 0;
  if (heap_sampling_enabled && remaining > min_size) {
    // This is a sampling point and the TLAB isn't actually full.
    thread->heap_sampler().SampleNewSpaceAllocation(min_size);
    return;
  }
#endif

  AbandonRemainingTLAB(thread);
  if (can_safepoint && !thread->force_growth()) {
    ASSERT(thread->no_safepoint_scope_depth() == 0);
    heap_->CheckConcurrentMarking(thread, GCReason::kNewSpace, kPageSize);
  }

  MutexLocker ml(&space_lock_);
  for (Page* page = to_->head(); page != nullptr; page = page->next()) {
    if (page->owner() != nullptr) continue;
    intptr_t available =
        (page->end() - kAllocationRedZoneSize) - page->object_end();
    if (available >= min_size) {
      page->Acquire(thread);
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
      thread->heap_sampler().HandleNewTLAB(remaining, /*is_first_tlab=*/false);
#endif
      return;
    }
  }

  Page* page = to_->TryAllocatePageLocked(true);
  if (page == nullptr) {
    return;
  }
  page->Acquire(thread);
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  thread->heap_sampler().HandleNewTLAB(remaining, is_first_tlab);
#endif
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
  Page* page = Page::Of(thread->top() - 1);
  {
    MutexLocker ml(&space_lock_);
    page->Release(thread);
  }
  ASSERT(thread->top() == 0);
}

template <bool parallel>
uword ScavengerVisitorBase<parallel>::TryAllocateCopySlow(intptr_t size) {
  Page* page;
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

void Scavenger::Scavenge(Thread* thread, GCType type, GCReason reason) {
  int64_t start = OS::GetCurrentMonotonicMicros();

  ASSERT(thread->OwnsGCSafepoint());

  // Scavenging is not reentrant. Make sure that is the case.
  ASSERT(!scavenging_);
  scavenging_ = true;

  if (type == GCType::kEvacuate) {
    // Forces the next scavenge to promote all the objects in the new space.
    early_tenure_ = true;
  }

  if (FLAG_verify_before_gc) {
    heap_->WaitForSweeperTasksAtSafepoint(thread);
    heap_->VerifyGC("Verifying before Scavenge",
                    thread->is_marking() ? kAllowMarked : kForbidMarked);
  }

  // Prepare for a scavenge.
  failed_to_promote_ = false;
  abort_ = false;
  root_slices_started_ = 0;
  intptr_t abandoned_bytes = 0;  // TODO(rmacnak): Count fragmentation?
  SpaceUsage usage_before = GetCurrentUsage();
  intptr_t promo_candidate_words = 0;
  for (Page* page = to_->head(); page != nullptr; page = page->next()) {
    page->Release();
    if (early_tenure_) {
      page->EarlyTenure();
    }
    promo_candidate_words += page->promo_candidate_words();
  }
  heap_->old_space()->PauseConcurrentMarking();
  SemiSpace* from = Prologue(reason);

  intptr_t bytes_promoted;
  if (FLAG_scavenger_tasks == 0) {
    bytes_promoted = SerialScavenge(from);
  } else {
    bytes_promoted = ParallelScavenge(from);
  }
  if (abort_) {
    ReverseScavenge(&from);
    bytes_promoted = 0;
  } else {
    if (type == GCType::kEvacuate) {
      if (heap_->stats_.state_ == Heap::kInitial ||
          heap_->stats_.state_ == Heap::kFirstScavenge) {
        heap_->stats_.state_ = Heap::kSecondScavenge;
      }
    } else {
      if (heap_->stats_.state_ == Heap::kInitial) {
        heap_->stats_.state_ = Heap::kFirstScavenge;
      } else if (heap_->stats_.state_ == Heap::kFirstScavenge) {
        heap_->stats_.state_ = Heap::kSecondScavenge;
      }
    }
    if ((CapacityInWords() - UsedInWords()) < KBInWords) {
      // Don't scavenge again until the next old-space GC has occurred. Prevents
      // performing one scavenge per allocation as the heap limit is approached.
      heap_->assume_scavenge_will_fail_ = true;
    }
  }
  ASSERT(promotion_stack_.IsEmpty());
  MournWeakHandles();
  MournWeakTables();
  heap_->old_space()->ResetProgressBars();
  heap_->old_space()->ResumeConcurrentMarking();

  // Restore write-barrier assumptions.
  heap_->isolate_group()->RememberLiveTemporaries();

  // Scavenge finished. Run accounting.
  int64_t end = OS::GetCurrentMonotonicMicros();
  stats_history_.Add(ScavengeStats(
      start, end, usage_before, GetCurrentUsage(), promo_candidate_words,
      bytes_promoted >> kWordSizeLog2, abandoned_bytes >> kWordSizeLog2));
  Epilogue(from);

  if (FLAG_verify_after_gc) {
    heap_->WaitForSweeperTasksAtSafepoint(thread);
    heap_->VerifyGC("Verifying after Scavenge...",
                    thread->is_marking() ? kAllowMarked : kForbidMarked);
  }

  // Done scavenging. Reset the marker.
  ASSERT(scavenging_);
  scavenging_ = false;

  // It is possible for objects to stay in the new space
  // if the VM cannot create more pages for these objects.
  ASSERT((type != GCType::kEvacuate) || (UsedInWords() == 0) ||
         failed_to_promote_);
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

  visitor.FinalizePromotion();
  to_->AddList(visitor.head(), visitor.tail());
  return visitor.bytes_promoted();
}

intptr_t Scavenger::ParallelScavenge(SemiSpace* from) {
  intptr_t bytes_promoted = 0;
  const intptr_t num_tasks = FLAG_scavenger_tasks;
  ASSERT(num_tasks > 0);

  ThreadBarrier* barrier = new ThreadBarrier(num_tasks, 1);
  RelaxedAtomic<uintptr_t> num_busy = 0;

  ParallelScavengerVisitor** visitors =
      new ParallelScavengerVisitor*[num_tasks];
  for (intptr_t i = 0; i < num_tasks; i++) {
    FreeList* freelist = heap_->old_space()->DataFreeList(i);
    visitors[i] = new ParallelScavengerVisitor(
        heap_->isolate_group(), this, from, freelist, &promotion_stack_);
    if (i < (num_tasks - 1)) {
      // Begin scavenging on a helper thread.
      bool result = Dart::thread_pool()->Run<ParallelScavengerTask>(
          heap_->isolate_group(), barrier, visitors[i], &num_busy);
      ASSERT(result);
    } else {
      // Last worker is the main thread.
      ParallelScavengerTask task(heap_->isolate_group(), barrier, visitors[i],
                                 &num_busy);
      task.RunEnteredIsolateGroup();
      barrier->Sync();
      barrier->Release();
    }
  }

  for (intptr_t i = 0; i < num_tasks; i++) {
    ParallelScavengerVisitor* visitor = visitors[i];
    if (abort_) {
      visitor->AbandonWork();
    } else {
      visitor->FinalizePromotion();
    }
    to_->AddList(visitor->head(), visitor->tail());
    bytes_promoted += visitor->bytes_promoted();
    delete visitor;
  }

  delete[] visitors;
  return bytes_promoted;
}

void Scavenger::ReverseScavenge(SemiSpace** from) {
  Thread* thread = Thread::Current();
  TIMELINE_FUNCTION_GC_DURATION(thread, "ReverseScavenge");

  class ReverseFromForwardingVisitor : public ObjectVisitor {
    void VisitObject(ObjectPtr from_obj) override {
      uword from_header = ReadHeaderRelaxed(from_obj);
      if (IsForwarding(from_header)) {
        ObjectPtr to_obj = ForwardedObj(from_header);
        uword to_header = ReadHeaderRelaxed(to_obj);
        intptr_t size = to_obj->untag()->HeapSize();

        // Reset the ages bits in case this was a promotion.
        uword from_header = static_cast<uword>(to_header);
        from_header = UntaggedObject::OldBit::update(false, from_header);
        from_header =
            UntaggedObject::OldAndNotRememberedBit::update(false, from_header);
        from_header = UntaggedObject::NewBit::update(true, from_header);
        from_header =
            UntaggedObject::OldAndNotMarkedBit::update(false, from_header);

        WriteHeaderRelaxed(from_obj, from_header);

        ForwardingCorpse::AsForwarder(UntaggedObject::ToAddr(to_obj), size)
            ->set_target(from_obj);
      }
    }
  };

  ReverseFromForwardingVisitor visitor;
  for (Page* page = (*from)->head(); page != nullptr; page = page->next()) {
    page->VisitObjects(&visitor);
  }

  // Swap from-space and to-space. The abandoned to-space will be deleted in
  // the epilogue.
  {
    MutexLocker ml(&space_lock_);
    SemiSpace* temp = to_;
    to_ = *from;
    *from = temp;
  }

  // Release any remaining part of the promotion worklist that wasn't completed.
  promotion_stack_.Reset();

  // Release any remaining part of the remembered set that wasn't completed.
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
  heap_->WaitForSweeperTasksAtSafepoint(thread);
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

}  // namespace dart
