// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/marker.h"

#include "platform/assert.h"
#include "platform/atomic.h"
#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/heap/gc_shared.h"
#include "vm/heap/pages.h"
#include "vm/heap/pointer_block.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/object_id_ring.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/tagged_pointer.h"
#include "vm/thread_barrier.h"
#include "vm/thread_pool.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

namespace dart {

template <bool sync>
class MarkingVisitorBase : public ObjectPointerVisitor {
 public:
  MarkingVisitorBase(IsolateGroup* isolate_group,
                     PageSpace* page_space,
                     MarkingStack* old_marking_stack,
                     MarkingStack* new_marking_stack,
                     MarkingStack* tlab_deferred_marking_stack,
                     MarkingStack* deferred_marking_stack)
      : ObjectPointerVisitor(isolate_group),
        page_space_(page_space),
        old_work_list_(old_marking_stack),
        new_work_list_(new_marking_stack),
        tlab_deferred_work_list_(tlab_deferred_marking_stack),
        deferred_work_list_(deferred_marking_stack),
        marked_bytes_(0),
        marked_micros_(0),
        concurrent_(true),
        has_evacuation_candidate_(false) {}
  ~MarkingVisitorBase() { ASSERT(delayed_.IsEmpty()); }

  uintptr_t marked_bytes() const { return marked_bytes_; }
  int64_t marked_micros() const { return marked_micros_; }
  void AddMicros(int64_t micros) { marked_micros_ += micros; }
  void set_concurrent(bool value) { concurrent_ = value; }

#ifdef DEBUG
  constexpr static const char* const kName = "Marker";
#endif

  static bool IsMarked(ObjectPtr raw) {
    ASSERT(raw->IsHeapObject());
    return raw->untag()->IsMarked();
  }

  void FinishedRoots() {
    // Nothing to remember for roots. Don't carry over to objects.
    has_evacuation_candidate_ = false;
  }

  bool ProcessPendingWeakProperties() {
    bool more_to_mark = false;
    WeakPropertyPtr cur_weak = delayed_.weak_properties.Release();
    while (cur_weak != WeakProperty::null()) {
      WeakPropertyPtr next_weak =
          cur_weak->untag()->next_seen_by_gc_.Decompress(cur_weak->heap_base());
      ObjectPtr raw_key = cur_weak->untag()->key();
      // Reset the next pointer in the weak property.
      cur_weak->untag()->next_seen_by_gc_ = WeakProperty::null();
      if (raw_key->IsImmediateObject() || raw_key->untag()->IsMarked()) {
        ObjectPtr raw_val = cur_weak->untag()->value();
        if (!raw_val->IsImmediateObject() && !raw_val->untag()->IsMarked()) {
          more_to_mark = true;
        }

        // The key is marked so we make sure to properly visit all pointers
        // originating from this weak property.
        cur_weak->untag()->VisitPointersNonvirtual(this);
        if (has_evacuation_candidate_) {
          has_evacuation_candidate_ = false;
          if (!cur_weak->untag()->IsCardRemembered()) {
            if (cur_weak->untag()->TryAcquireRememberedBit()) {
              Thread::Current()->StoreBufferAddObjectGC(cur_weak);
            }
          }
        }

      } else {
        // Requeue this weak property to be handled later.
        ASSERT(IsMarked(cur_weak));
        delayed_.weak_properties.Enqueue(cur_weak);
      }
      // Advance to next weak property in the queue.
      cur_weak = next_weak;
    }
    return more_to_mark;
  }

  DART_NOINLINE
  void YieldConcurrentMarking() {
    old_work_list_.Flush();
    new_work_list_.Flush();
    tlab_deferred_work_list_.Flush();
    deferred_work_list_.Flush();
    Thread* thread = Thread::Current();
    thread->StoreBufferReleaseGC();
    page_space_->YieldConcurrentMarking();
    thread->StoreBufferAcquireGC();
  }

  void DrainMarkingStackWithPauseChecks() {
    ASSERT(concurrent_);
    Thread* thread = Thread::Current();
    do {
      ObjectPtr obj;
      while (MarkerWorkList::Pop(&old_work_list_, &new_work_list_, &obj)) {
        ASSERT(!has_evacuation_candidate_);

        if (obj->IsNewObject()) {
          Page* page = Page::Of(obj);
          uword top = page->original_top();
          uword end = page->original_end();
          uword addr = static_cast<uword>(obj);
          if (top <= addr && addr < end) {
            // New-space objects still in a TLAB are deferred. This allows the
            // compiler to remove write barriers for freshly allocated objects.
            tlab_deferred_work_list_.Push(obj);
            if (UNLIKELY(page_space_->pause_concurrent_marking())) {
              YieldConcurrentMarking();
            }
            continue;
          }
        }

        const intptr_t class_id = obj->GetClassIdOfHeapObject();
        ASSERT(class_id != kIllegalCid);
        ASSERT(class_id != kFreeListElement);
        ASSERT(class_id != kForwardingCorpse);

        intptr_t size;
        if (class_id == kWeakPropertyCid) {
          size = ProcessWeakProperty(static_cast<WeakPropertyPtr>(obj));
        } else if (class_id == kWeakReferenceCid) {
          size = ProcessWeakReference(static_cast<WeakReferencePtr>(obj));
        } else if (class_id == kWeakArrayCid) {
          size = ProcessWeakArray(static_cast<WeakArrayPtr>(obj));
        } else if (class_id == kFinalizerEntryCid) {
          size = ProcessFinalizerEntry(static_cast<FinalizerEntryPtr>(obj));
        } else if (class_id == kSuspendStateCid) {
          // Shape changing is not compatible with concurrent marking.
          deferred_work_list_.Push(obj);
          size = obj->untag()->HeapSize();
        } else if (obj->untag()->IsCardRemembered()) {
          ASSERT((class_id == kArrayCid) || (class_id == kImmutableArrayCid));
          size = VisitCards(static_cast<ArrayPtr>(obj));
        } else {
          size = obj->untag()->VisitPointersNonvirtual(this);
        }
        if (has_evacuation_candidate_) {
          has_evacuation_candidate_ = false;
          if (!obj->untag()->IsCardRemembered()) {
            if (obj->untag()->TryAcquireRememberedBit()) {
              thread->StoreBufferAddObjectGC(obj);
            }
          }
        }
        if (!obj->IsNewObject()) {
          marked_bytes_ += size;
        }

        if (UNLIKELY(page_space_->pause_concurrent_marking())) {
          YieldConcurrentMarking();
        }
      }
    } while (ProcessPendingWeakProperties());

    ASSERT(old_work_list_.IsLocalEmpty());
    // In case of scavenge before final marking.
    new_work_list_.Flush();
    tlab_deferred_work_list_.Flush();
    deferred_work_list_.Flush();
  }

  intptr_t VisitCards(ArrayPtr obj) {
    ASSERT(obj->IsArray() || obj->IsImmutableArray());
    ASSERT(obj->untag()->IsCardRemembered());
    CompressedObjectPtr* obj_from = obj->untag()->from();
    CompressedObjectPtr* obj_to =
        obj->untag()->to(Smi::Value(obj->untag()->length()));
    uword heap_base = obj.heap_base();

    Page* page = Page::Of(obj);
    for (intptr_t i = 0, n = page->card_table_size(); i < n; i++) {
      CompressedObjectPtr* card_from =
          reinterpret_cast<CompressedObjectPtr*>(page) +
          (i << Page::kSlotsPerCardLog2);
      CompressedObjectPtr* card_to =
          reinterpret_cast<CompressedObjectPtr*>(card_from) +
          (1 << Page::kSlotsPerCardLog2) - 1;
      // Minus 1 because to is inclusive.

      if (card_from < obj_from) {
        // First card overlaps with header.
        card_from = obj_from;
      }
      if (card_to > obj_to) {
        // Last card(s) may extend past the object. Array truncation can make
        // this happen for more than one card.
        card_to = obj_to;
      }

      VisitCompressedPointers(heap_base, card_from, card_to);
      if (has_evacuation_candidate_) {
        has_evacuation_candidate_ = false;
        page->RememberCard(card_from);
      }

      if (((i + 1) % kCardsPerInterruptCheck) == 0) {
        if (UNLIKELY(page_space_->pause_concurrent_marking())) {
          YieldConcurrentMarking();
        }
      }
    }

    return obj->untag()->HeapSize();
  }

  void DrainMarkingStack() {
    ASSERT(!concurrent_);
    Thread* thread = Thread::Current();
    do {
      ObjectPtr obj;
      while (MarkerWorkList::Pop(&old_work_list_, &new_work_list_, &obj)) {
        ASSERT(!has_evacuation_candidate_);

        const intptr_t class_id = obj->GetClassIdOfHeapObject();
        ASSERT(class_id != kIllegalCid);
        ASSERT(class_id != kFreeListElement);
        ASSERT(class_id != kForwardingCorpse);

        intptr_t size;
        if (class_id == kWeakPropertyCid) {
          size = ProcessWeakProperty(static_cast<WeakPropertyPtr>(obj));
        } else if (class_id == kWeakReferenceCid) {
          size = ProcessWeakReference(static_cast<WeakReferencePtr>(obj));
        } else if (class_id == kWeakArrayCid) {
          size = ProcessWeakArray(static_cast<WeakArrayPtr>(obj));
        } else if (class_id == kFinalizerEntryCid) {
          size = ProcessFinalizerEntry(static_cast<FinalizerEntryPtr>(obj));
        } else {
          if (obj->untag()->IsCardRemembered()) {
            ASSERT((class_id == kArrayCid) || (class_id == kImmutableArrayCid));
            size = VisitCards(static_cast<ArrayPtr>(obj));
          } else {
            size = obj->untag()->VisitPointersNonvirtual(this);
          }
        }
        if (has_evacuation_candidate_) {
          has_evacuation_candidate_ = false;
          if (!obj->untag()->IsCardRemembered() &&
              obj->untag()->TryAcquireRememberedBit()) {
            thread->StoreBufferAddObjectGC(obj);
          }
        }
        if (!obj->IsNewObject()) {
          marked_bytes_ += size;
        }
      }
    } while (ProcessPendingWeakProperties());
  }

  void ProcessOldMarkingStackUntil(int64_t deadline) {
    // We check the clock *before* starting a batch of work, but we want to
    // *end* work before the deadline. So we compare to the deadline adjusted
    // by a conservative estimate of the duration of one batch of work.
    deadline -= 1500;

    // A 512kB budget is chosen to be large enough that we don't waste too much
    // time on the overhead of exiting ProcessMarkingStack, querying the clock,
    // and re-entering, and small enough that a few batches can fit in the idle
    // time between animation frames. This amount of marking takes ~1ms on a
    // Pixel phone.
    constexpr intptr_t kBudget = 512 * KB;

    while ((OS::GetCurrentMonotonicMicros() < deadline) &&
           ProcessOldMarkingStack(kBudget)) {
    }
  }

  bool ProcessOldMarkingStack(intptr_t remaining_budget) {
    Thread* thread = Thread::Current();
    do {
      // First drain the marking stacks.
      ObjectPtr obj;
      while (old_work_list_.Pop(&obj)) {
        ASSERT(!has_evacuation_candidate_);

        const intptr_t class_id = obj->GetClassIdOfHeapObject();
        ASSERT(class_id != kIllegalCid);
        ASSERT(class_id != kFreeListElement);
        ASSERT(class_id != kForwardingCorpse);

        intptr_t size;
        if (class_id == kWeakPropertyCid) {
          size = ProcessWeakProperty(static_cast<WeakPropertyPtr>(obj));
        } else if (class_id == kWeakReferenceCid) {
          size = ProcessWeakReference(static_cast<WeakReferencePtr>(obj));
        } else if (class_id == kWeakArrayCid) {
          size = ProcessWeakArray(static_cast<WeakArrayPtr>(obj));
        } else if (class_id == kFinalizerEntryCid) {
          size = ProcessFinalizerEntry(static_cast<FinalizerEntryPtr>(obj));
        } else if (sync && concurrent_ && class_id == kSuspendStateCid) {
          // Shape changing is not compatible with concurrent marking.
          deferred_work_list_.Push(obj);
          size = obj->untag()->HeapSize();
        } else {
          if ((class_id == kArrayCid) || (class_id == kImmutableArrayCid)) {
            size = obj->untag()->HeapSize();
            if (size > remaining_budget) {
              old_work_list_.Push(obj);
              return true;  // More to mark.
            }
          }
          if (obj->untag()->IsCardRemembered()) {
            ASSERT((class_id == kArrayCid) || (class_id == kImmutableArrayCid));
            size = VisitCards(static_cast<ArrayPtr>(obj));
          } else {
            size = obj->untag()->VisitPointersNonvirtual(this);
          }
        }
        if (has_evacuation_candidate_) {
          has_evacuation_candidate_ = false;
          if (!obj->untag()->IsCardRemembered() &&
              obj->untag()->TryAcquireRememberedBit()) {
            thread->StoreBufferAddObjectGC(obj);
          }
        }
        marked_bytes_ += size;
        remaining_budget -= size;
        if (remaining_budget < 0) {
          return true;  // More to mark.
        }
      }
      // Marking stack is empty.
    } while (ProcessPendingWeakProperties());

    return false;  // No more work.
  }

  // Races: The concurrent marker is racing with the mutator, but this race is
  // harmless. The concurrent marker will only visit objects that were created
  // before the marker started. It will ignore all new-space objects based on
  // pointer alignment, and it will ignore old-space objects created after the
  // marker started because old-space objects allocated while marking is in
  // progress are allocated black (mark bit set). When visiting object slots,
  // the marker can see either the value it had when marking started (because
  // spawning the marker task creates acq-rel ordering) or any value later
  // stored into that slot. Because pointer slots always contain pointers (i.e.,
  // we don't do any in-place unboxing like V8), any value we read from the slot
  // is safe.
  NO_SANITIZE_THREAD
  ObjectPtr LoadPointerIgnoreRace(ObjectPtr* ptr) { return *ptr; }
  NO_SANITIZE_THREAD
  CompressedObjectPtr LoadCompressedPointerIgnoreRace(
      CompressedObjectPtr* ptr) {
    return *ptr;
  }

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    bool has_evacuation_candidate = false;
    for (ObjectPtr* current = first; current <= last; current++) {
      has_evacuation_candidate |= MarkObject(LoadPointerIgnoreRace(current));
    }
    has_evacuation_candidate_ |= has_evacuation_candidate;
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    bool has_evacuation_candidate = false;
    for (CompressedObjectPtr* current = first; current <= last; current++) {
      has_evacuation_candidate |= MarkObject(
          LoadCompressedPointerIgnoreRace(current).Decompress(heap_base));
    }
    has_evacuation_candidate_ |= has_evacuation_candidate;
  }
#endif

  intptr_t ProcessWeakProperty(WeakPropertyPtr raw_weak) {
    // The fate of the weak property is determined by its key.
    ObjectPtr raw_key =
        LoadCompressedPointerIgnoreRace(&raw_weak->untag()->key_)
            .Decompress(raw_weak->heap_base());
    if (raw_key->IsHeapObject() && !raw_key->untag()->IsMarked()) {
      // Key was white. Enqueue the weak property.
      ASSERT(IsMarked(raw_weak));
      delayed_.weak_properties.Enqueue(raw_weak);
      return raw_weak->untag()->HeapSize();
    }
    // Key is gray or black. Make the weak property black.
    return raw_weak->untag()->VisitPointersNonvirtual(this);
  }

  intptr_t ProcessWeakReference(WeakReferencePtr raw_weak) {
    // The fate of the target field is determined by the target.
    // The type arguments always stay alive.
    ObjectPtr raw_target =
        LoadCompressedPointerIgnoreRace(&raw_weak->untag()->target_)
            .Decompress(raw_weak->heap_base());
    if (raw_target->IsHeapObject()) {
      if (!raw_target->untag()->IsMarked()) {
        // Target was white. Enqueue the weak reference. It is potentially dead.
        // It might still be made alive by weak properties in next rounds.
        ASSERT(IsMarked(raw_weak));
        delayed_.weak_references.Enqueue(raw_weak);
      } else {
        if (raw_target->untag()->IsEvacuationCandidate()) {
          has_evacuation_candidate_ = true;
        }
      }
    }
    // Always visit the type argument.
    ObjectPtr raw_type_arguments =
        LoadCompressedPointerIgnoreRace(&raw_weak->untag()->type_arguments_)
            .Decompress(raw_weak->heap_base());
    if (MarkObject(raw_type_arguments)) {
      has_evacuation_candidate_ = true;
    }
    return raw_weak->untag()->HeapSize();
  }

  intptr_t ProcessWeakArray(WeakArrayPtr raw_weak) {
    delayed_.weak_arrays.Enqueue(raw_weak);
    return raw_weak->untag()->HeapSize();
  }

  intptr_t ProcessFinalizerEntry(FinalizerEntryPtr raw_entry) {
    ASSERT(IsMarked(raw_entry));
    delayed_.finalizer_entries.Enqueue(raw_entry);
    // Only visit token and next.
    if (MarkObject(LoadCompressedPointerIgnoreRace(&raw_entry->untag()->token_)
                       .Decompress(raw_entry->heap_base()))) {
      has_evacuation_candidate_ = true;
    }
    if (MarkObject(LoadCompressedPointerIgnoreRace(&raw_entry->untag()->next_)
                       .Decompress(raw_entry->heap_base()))) {
      has_evacuation_candidate_ = true;
    }
    return raw_entry->untag()->HeapSize();
  }

  void ProcessDeferredMarking() {
    Thread* thread = Thread::Current();
    TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessDeferredMarking");

    ObjectPtr obj;
    while (deferred_work_list_.Pop(&obj)) {
      ASSERT(!has_evacuation_candidate_);
      ASSERT(obj->IsHeapObject());
      // We need to scan objects even if they were already scanned via ordinary
      // marking. An object may have changed since its ordinary scan and been
      // added to deferred marking stack to compensate for write-barrier
      // elimination.
      // A given object may be included in the deferred marking stack multiple
      // times. It may or may not also be in the ordinary marking stack, so
      // failing to acquire the mark bit here doesn't reliably indicate the
      // object was already encountered through the deferred marking stack. Our
      // processing here is idempotent, so repeated visits only hurt performance
      // but not correctness. Duplication is expected to be low.
      // By the absence of a special case, we are treating WeakProperties as
      // strong references here. This guarantees a WeakProperty will only be
      // added to the delayed_weak_properties_ list of the worker that
      // encounters it during ordinary marking. This is in the same spirit as
      // the eliminated write barrier, which would have added the newly written
      // key and value to the ordinary marking stack.
      intptr_t size = obj->untag()->VisitPointersNonvirtual(this);
      // Add the size only if we win the marking race to prevent
      // double-counting.
      if (TryAcquireMarkBit(obj)) {
        if (!obj->IsNewObject()) {
          marked_bytes_ += size;
        }
      }
      if (has_evacuation_candidate_) {
        has_evacuation_candidate_ = false;
        if (!obj->untag()->IsCardRemembered() &&
            obj->untag()->TryAcquireRememberedBit()) {
          thread->StoreBufferAddObjectGC(obj);
        }
      }
    }
  }

  // Called when all marking is complete. Any attempt to push to the mark stack
  // after this will trigger an error.
  void FinalizeMarking() {
    old_work_list_.Finalize();
    new_work_list_.Finalize();
    tlab_deferred_work_list_.Finalize();
    deferred_work_list_.Finalize();
    MournFinalizerEntries();
    // MournFinalizerEntries inserts newly discovered dead entries into the
    // linked list attached to the Finalizer. This might create
    // cross-generational references which might be added to the store
    // buffer. Release the store buffer to satisfy the invariant that
    // thread local store buffer is empty after marking and all references
    // are processed.
    Thread::Current()->ReleaseStoreBuffer();
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
      ForwardOrSetNullIfCollected(current, &current->untag()->target_);
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
        ForwardOrSetNullIfCollected(current, &current->untag()->data()[i]);
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

  // Returns whether the object referred to in `slot` was GCed this GC.
  static bool ForwardOrSetNullIfCollected(ObjectPtr parent,
                                          CompressedObjectPtr* slot) {
    ObjectPtr target = slot->Decompress(parent->heap_base());
    if (target->IsImmediateObject()) {
      // Object not touched during this GC.
      return false;
    }
    if (target->untag()->IsMarked()) {
      // Object already null (which is permanently marked) or has survived this
      // GC.
      if (target->untag()->IsEvacuationCandidate()) {
        if (parent->untag()->IsCardRemembered()) {
          Page::Of(parent)->RememberCard(slot);
        } else {
          if (parent->untag()->TryAcquireRememberedBit()) {
            Thread::Current()->StoreBufferAddObjectGC(parent);
          }
        }
      }
      return false;
    }
    *slot = Object::null();
    return true;
  }

  bool WaitForWork(RelaxedAtomic<uintptr_t>* num_busy) {
    return old_work_list_.WaitForWork(num_busy);
  }

  void Flush(GCLinkedLists* global_list) {
    old_work_list_.Flush();
    new_work_list_.Flush();
    tlab_deferred_work_list_.Flush();
    deferred_work_list_.Flush();
    delayed_.FlushInto(global_list);
  }

  void Adopt(GCLinkedLists* other) {
    ASSERT(delayed_.IsEmpty());
    other->FlushInto(&delayed_);
  }

  void AbandonWork() {
    old_work_list_.AbandonWork();
    new_work_list_.AbandonWork();
    tlab_deferred_work_list_.AbandonWork();
    deferred_work_list_.AbandonWork();
    delayed_.Release();
  }

  void FinalizeIncremental(GCLinkedLists* global_list) {
    old_work_list_.Flush();
    old_work_list_.Finalize();
    new_work_list_.Flush();
    new_work_list_.Finalize();
    tlab_deferred_work_list_.Flush();
    tlab_deferred_work_list_.Finalize();
    deferred_work_list_.Flush();
    deferred_work_list_.Finalize();
    delayed_.FlushInto(global_list);
  }

  GCLinkedLists* delayed() { return &delayed_; }

 private:
  static bool TryAcquireMarkBit(ObjectPtr obj) {
    if constexpr (!sync) {
      if (!obj->untag()->IsMarked()) {
        obj->untag()->SetMarkBitUnsynchronized();
        return true;
      }
      return false;
    } else {
      return obj->untag()->TryAcquireMarkBit();
    }
  }

  DART_FORCE_INLINE
  bool MarkObject(ObjectPtr obj) {
    if (obj->IsImmediateObject()) {
      return false;
    }

    if (obj->IsNewObject()) {
      if (TryAcquireMarkBit(obj)) {
        new_work_list_.Push(obj);
      }
      return false;
    }

    // While it might seem this is redundant with TryAcquireMarkBit, we must
    // do this check first to avoid attempting an atomic::fetch_and on the
    // read-only vm-isolate or image pages, which can fault even if there is no
    // change in the value.
    // Doing this before checking for an Instructions object avoids
    // unnecessary queueing of pre-marked objects.
    // Race: The concurrent marker may observe a pointer into a heap page that
    // was allocated after the concurrent marker started. It can read either a
    // zero or the header of an object allocated black, both of which appear
    // marked.
    uword tags = obj->untag()->tags_ignore_race();
    if (UntaggedObject::IsMarked(tags)) {
      return UntaggedObject::IsEvacuationCandidate(tags);
    }

    intptr_t class_id = UntaggedObject::ClassIdTag::decode(tags);
    ASSERT(class_id != kFreeListElement);

    if (sync && UNLIKELY(class_id == kInstructionsCid)) {
      // If this is the concurrent marker, this object may be non-writable due
      // to W^X (--write-protect-code).
      deferred_work_list_.Push(obj);
      return false;
    }

    if (TryAcquireMarkBit(obj)) {
      old_work_list_.Push(obj);
    }

    return UntaggedObject::IsEvacuationCandidate(tags);
  }

  PageSpace* page_space_;
  MarkerWorkList old_work_list_;
  MarkerWorkList new_work_list_;
  MarkerWorkList tlab_deferred_work_list_;
  MarkerWorkList deferred_work_list_;
  GCLinkedLists delayed_;
  uintptr_t marked_bytes_;
  int64_t marked_micros_;
  bool concurrent_;
  bool has_evacuation_candidate_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(MarkingVisitorBase);
};

typedef MarkingVisitorBase<false> UnsyncMarkingVisitor;
typedef MarkingVisitorBase<true> SyncMarkingVisitor;

static bool IsUnreachable(const ObjectPtr obj) {
  if (obj->IsImmediateObject()) {
    return false;
  }
  return !obj->untag()->IsMarked();
}

class MarkingWeakVisitor : public HandleVisitor {
 public:
  explicit MarkingWeakVisitor(Thread* thread) : HandleVisitor(thread) {}

  void VisitHandle(uword addr) override {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    ObjectPtr obj = handle->ptr();
    if (IsUnreachable(obj)) {
      handle->UpdateUnreachable(thread()->isolate_group());
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(MarkingWeakVisitor);
};

void GCMarker::Prologue() {
  isolate_group_->ReleaseStoreBuffers();
  new_marking_stack_.PushAll(tlab_deferred_marking_stack_.PopAll());

#if defined(DART_DYNAMIC_MODULES)
  isolate_group_->ForEachIsolate(
      [&](Isolate* isolate) {
        Thread* mutator_thread = isolate->mutator_thread();
        if (mutator_thread != nullptr) {
          Interpreter* interpreter = mutator_thread->interpreter();
          if (interpreter != nullptr) {
            interpreter->ClearLookupCache();
          }
        }
      },
      /*at_safepoint=*/true);
#endif  // defined(DART_DYNAMIC_MODULES)
}

void GCMarker::Epilogue() {}

enum RootSlices {
  kIsolate = 0,
  kObjectIdRing = 1,
  kNumFixedRootSlices = 2,
};

void GCMarker::ResetSlices() {
  ASSERT(Thread::Current()->OwnsGCSafepoint());

  root_slices_started_ = 0;
  root_slices_finished_ = 0;
  root_slices_count_ = kNumFixedRootSlices;

  weak_slices_started_ = 0;
}

void GCMarker::IterateRoots(ObjectPointerVisitor* visitor) {
  for (;;) {
    intptr_t slice = root_slices_started_.fetch_add(1);
    if (slice >= root_slices_count_) {
      break;  // No more slices.
    }

    switch (slice) {
      case kIsolate: {
        TIMELINE_FUNCTION_GC_DURATION(Thread::Current(),
                                      "ProcessIsolateGroupRoots");
        isolate_group_->VisitObjectPointers(
            visitor, ValidationPolicy::kDontValidateFrames);
        break;
      }
      case kObjectIdRing: {
        TIMELINE_FUNCTION_GC_DURATION(Thread::Current(),
                                      "ProcessObjectIdTable");
        isolate_group_->VisitPointersInAllServiceIdZones(*visitor);
        break;
      }
    }

    MonitorLocker ml(&root_slices_monitor_);
    root_slices_finished_++;
    if (root_slices_finished_ == root_slices_count_) {
      ml.Notify();
    }
  }
}

enum WeakSlices {
  kWeakHandles = 0,
  kWeakTables,
  kRememberedSet,
  kNumWeakSlices,
};

void GCMarker::IterateWeakRoots(Thread* thread) {
  for (;;) {
    intptr_t slice = weak_slices_started_.fetch_add(1);
    if (slice >= kNumWeakSlices) {
      return;  // No more slices.
    }

    switch (slice) {
      case kWeakHandles:
        ProcessWeakHandles(thread);
        break;
      case kWeakTables:
        ProcessWeakTables(thread);
        break;
      case kRememberedSet:
        ProcessRememberedSet(thread);
        break;
      default:
        UNREACHABLE();
    }
  }
}

void GCMarker::ProcessWeakHandles(Thread* thread) {
  TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessWeakHandles");
  MarkingWeakVisitor visitor(thread);
  ApiState* state = isolate_group_->api_state();
  ASSERT(state != nullptr);
  isolate_group_->VisitWeakPersistentHandles(&visitor);
}

void GCMarker::ProcessWeakTables(Thread* thread) {
  TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessWeakTables");
  for (int sel = 0; sel < Heap::kNumWeakSelectors; sel++) {
    Dart_HeapSamplingDeleteCallback cleanup = nullptr;
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
    if (sel == Heap::kHeapSamplingData) {
      cleanup = HeapProfileSampler::delete_callback();
    }
#endif
    WeakTable* table =
        heap_->GetWeakTable(Heap::kOld, static_cast<Heap::WeakSelector>(sel));
    intptr_t size = table->size();
    for (intptr_t i = 0; i < size; i++) {
      if (table->IsValidEntryAtExclusive(i)) {
        // The object has been collected.
        ObjectPtr obj = table->ObjectAtExclusive(i);
        if (obj->IsHeapObject() && !obj->untag()->IsMarked()) {
          if (cleanup != nullptr) {
            cleanup(reinterpret_cast<void*>(table->ValueAtExclusive(i)));
          }
          table->InvalidateAtExclusive(i);
        }
      }
    }
    table =
        heap_->GetWeakTable(Heap::kNew, static_cast<Heap::WeakSelector>(sel));
    size = table->size();
    for (intptr_t i = 0; i < size; i++) {
      if (table->IsValidEntryAtExclusive(i)) {
        // The object has been collected.
        ObjectPtr obj = table->ObjectAtExclusive(i);
        if (obj->IsHeapObject() && !obj->untag()->IsMarked()) {
          if (cleanup != nullptr) {
            cleanup(reinterpret_cast<void*>(table->ValueAtExclusive(i)));
          }
          table->InvalidateAtExclusive(i);
        }
      }
    }
  }
}

void GCMarker::ProcessRememberedSet(Thread* thread) {
  TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessRememberedSet");
  // Filter collected objects from the remembered set.
  StoreBuffer* store_buffer = isolate_group_->store_buffer();
  StoreBufferBlock* reading = store_buffer->PopAll();
  StoreBufferBlock* writing = store_buffer->PopNonFullBlock();
  while (reading != nullptr) {
    StoreBufferBlock* next = reading->next();
    // Generated code appends to store buffers; tell MemorySanitizer.
    MSAN_UNPOISON(reading, sizeof(*reading));
    while (!reading->IsEmpty()) {
      ObjectPtr obj = reading->Pop();
      ASSERT(!obj->IsForwardingCorpse());
      ASSERT(obj->untag()->IsRemembered());
      if (obj->untag()->IsMarked()) {
        writing->Push(obj);
        if (writing->IsFull()) {
          store_buffer->PushBlock(writing, StoreBuffer::kIgnoreThreshold);
          writing = store_buffer->PopNonFullBlock();
        }
      }
    }
    reading->Reset();
    // Return the emptied block for recycling (no need to check threshold).
    store_buffer->PushBlock(reading, StoreBuffer::kIgnoreThreshold);
    reading = next;
  }
  store_buffer->PushBlock(writing, StoreBuffer::kIgnoreThreshold);
}

class ParallelMarkTask : public SafepointTask {
 public:
  ParallelMarkTask(GCMarker* marker,
                   IsolateGroup* isolate_group,
                   MarkingStack* marking_stack,
                   ThreadBarrier* barrier,
                   SyncMarkingVisitor* visitor,
                   RelaxedAtomic<uintptr_t>* num_busy)
      : marker_(marker),
        isolate_group_(isolate_group),
        marking_stack_(marking_stack),
        barrier_(barrier),
        visitor_(visitor),
        num_busy_(num_busy) {}
  ~ParallelMarkTask() { barrier_->Release(); }

  void Run() override {
    if (!barrier_->TryEnter()) {
      return;
    }

    bool result = Thread::EnterIsolateGroupAsHelper(
        isolate_group_, Thread::kMarkerTask, /*bypass_safepoint=*/true);
    ASSERT(result);

    RunEnteredIsolateGroup();

    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);

    barrier_->Sync();
  }

  void RunBlockedAtSafepoint() override {
    if (!barrier_->TryEnter()) {
      return;
    }

    Thread* thread = Thread::Current();
    Thread::TaskKind saved_task_kind = thread->task_kind();
    thread->set_task_kind(Thread::kMarkerTask);

    RunEnteredIsolateGroup();

    thread->set_task_kind(saved_task_kind);

    barrier_->Sync();
  }

  void RunMain() override {
    RunEnteredIsolateGroup();

    barrier_->Sync();
  }

  void RunEnteredIsolateGroup() {
    {
      Thread* thread = Thread::Current();
      TIMELINE_FUNCTION_GC_DURATION(thread, "ParallelMark");
      int64_t start = OS::GetCurrentMonotonicMicros();

      // Phase 1: Iterate over roots and drain marking stack in tasks.
      num_busy_->fetch_add(1u);
      visitor_->set_concurrent(false);
      marker_->IterateRoots(visitor_);
      visitor_->FinishedRoots();

      visitor_->ProcessDeferredMarking();

      bool more_to_mark = false;
      do {
        do {
          visitor_->DrainMarkingStack();
        } while (visitor_->WaitForWork(num_busy_));
        // Wait for all markers to stop.
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
        more_to_mark = visitor_->ProcessPendingWeakProperties();
        if (more_to_mark) {
          // We have more work to do. Notify others.
          num_busy_->fetch_add(1u);
        }

        // Wait for all other markers to finish processing their pending
        // weak properties and decide if they need to continue marking.
        // Caveat: we need two barriers here to make this decision in lock step
        // between all markers and the main thread.
        barrier_->Sync();
        if (!more_to_mark && (num_busy_->load() > 0)) {
          // All markers continue to mark as long as any single marker has
          // some work to do.
          num_busy_->fetch_add(1u);
          more_to_mark = true;
        }
        barrier_->Sync();
      } while (more_to_mark);

      // Phase 2: deferred marking.
      visitor_->ProcessDeferredMarking();
      barrier_->Sync();

      // Phase 3: Weak processing and statistics.
      visitor_->MournWeakProperties();
      visitor_->MournWeakReferences();
      visitor_->MournWeakArrays();
      // Don't MournFinalizerEntries here, do it on main thread, so that we
      // don't have to coordinate workers.

      thread->ReleaseStoreBuffer();  // Ahead of IterateWeak
      barrier_->Sync();
      marker_->IterateWeakRoots(thread);
      int64_t stop = OS::GetCurrentMonotonicMicros();
      visitor_->AddMicros(stop - start);
      if (FLAG_log_marker_tasks) {
        THR_Print("Task marked %" Pd " bytes in %" Pd64 " micros.\n",
                  visitor_->marked_bytes(), visitor_->marked_micros());
      }
    }
  }

 private:
  GCMarker* marker_;
  IsolateGroup* isolate_group_;
  MarkingStack* marking_stack_;
  ThreadBarrier* barrier_;
  SyncMarkingVisitor* visitor_;
  RelaxedAtomic<uintptr_t>* num_busy_;

  DISALLOW_COPY_AND_ASSIGN(ParallelMarkTask);
};

class ConcurrentMarkTask : public ThreadPool::Task {
 public:
  ConcurrentMarkTask(GCMarker* marker,
                     IsolateGroup* isolate_group,
                     PageSpace* page_space,
                     SyncMarkingVisitor* visitor)
      : marker_(marker),
        isolate_group_(isolate_group),
        page_space_(page_space),
        visitor_(visitor) {
#if defined(DEBUG)
    MonitorLocker ml(page_space_->tasks_lock());
    ASSERT(page_space_->phase() == PageSpace::kMarking);
#endif
  }

  virtual void Run() {
    bool result = Thread::EnterIsolateGroupAsHelper(
        isolate_group_, Thread::kMarkerTask, /*bypass_safepoint=*/true);
    ASSERT(result);
    {
      TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ConcurrentMark");
      int64_t start = OS::GetCurrentMonotonicMicros();

      marker_->IterateRoots(visitor_);
      visitor_->FinishedRoots();

      visitor_->DrainMarkingStackWithPauseChecks();
      int64_t stop = OS::GetCurrentMonotonicMicros();
      visitor_->AddMicros(stop - start);
      if (FLAG_log_marker_tasks) {
        THR_Print("Task marked %" Pd " bytes in %" Pd64 " micros.\n",
                  visitor_->marked_bytes(), visitor_->marked_micros());
      }
    }

    // Exit isolate cleanly *before* notifying it, to avoid shutdown race.
    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);
    // This marker task is done. Notify the original isolate.
    {
      MonitorLocker ml(page_space_->tasks_lock());
      page_space_->set_tasks(page_space_->tasks() - 1);
      page_space_->set_concurrent_marker_tasks(
          page_space_->concurrent_marker_tasks() - 1);
      page_space_->set_concurrent_marker_tasks_active(
          page_space_->concurrent_marker_tasks_active() - 1);
      ASSERT(page_space_->phase() == PageSpace::kMarking);
      if (page_space_->concurrent_marker_tasks() == 0) {
        page_space_->set_phase(PageSpace::kAwaitingFinalization);
        isolate_group_->ScheduleInterrupts(Thread::kVMInterrupt);
      }
      ml.NotifyAll();
    }
  }

 private:
  GCMarker* marker_;
  IsolateGroup* isolate_group_;
  PageSpace* page_space_;
  SyncMarkingVisitor* visitor_;

  DISALLOW_COPY_AND_ASSIGN(ConcurrentMarkTask);
};

intptr_t GCMarker::MarkedWordsPerMicro() const {
  intptr_t marked_words_per_job_micro;
  if (marked_micros_ == 0) {
    marked_words_per_job_micro = marked_words();  // Prevent division by zero.
  } else {
    marked_words_per_job_micro = marked_words() / marked_micros_;
  }
  if (marked_words_per_job_micro == 0) {
    marked_words_per_job_micro = 1;  // Prevent division by zero.
  }
  intptr_t jobs = FLAG_marker_tasks;
  if (jobs == 0) {
    jobs = 1;  // Marking on main thread is still one job.
  }
  return marked_words_per_job_micro * jobs;
}

GCMarker::GCMarker(IsolateGroup* isolate_group, Heap* heap)
    : isolate_group_(isolate_group),
      heap_(heap),
      old_marking_stack_(),
      new_marking_stack_(),
      tlab_deferred_marking_stack_(),
      deferred_marking_stack_(),
      global_list_(),
      visitors_(),
      marked_bytes_(0),
      marked_micros_(0) {
  visitors_ = new SyncMarkingVisitor*[FLAG_marker_tasks];
  for (intptr_t i = 0; i < FLAG_marker_tasks; i++) {
    visitors_[i] = nullptr;
  }
}

GCMarker::~GCMarker() {
  // Cleanup in case isolate shutdown happens after starting the concurrent
  // marker and before finalizing.
  if (isolate_group_->old_marking_stack() != nullptr) {
    isolate_group_->DisableIncrementalBarrier();
    for (intptr_t i = 0; i < FLAG_marker_tasks; i++) {
      visitors_[i]->AbandonWork();
      delete visitors_[i];
    }
  }
  delete[] visitors_;
}

void GCMarker::StartConcurrentMark(PageSpace* page_space) {
  isolate_group_->EnableIncrementalBarrier(
      &old_marking_stack_, &new_marking_stack_, &deferred_marking_stack_);

  const intptr_t num_tasks = FLAG_marker_tasks;

  {
    // Bulk increase task count before starting any task, instead of
    // incrementing as each task is started, to prevent a task which
    // races ahead from falsely believing it was the last task to complete.
    MonitorLocker ml(page_space->tasks_lock());
    ASSERT(page_space->phase() == PageSpace::kDone);
    page_space->set_phase(PageSpace::kMarking);
    page_space->set_tasks(page_space->tasks() + num_tasks);
    page_space->set_concurrent_marker_tasks(
        page_space->concurrent_marker_tasks() + num_tasks);
    page_space->set_concurrent_marker_tasks_active(
        page_space->concurrent_marker_tasks_active() + num_tasks);
  }

  ResetSlices();
  for (intptr_t i = 0; i < num_tasks; i++) {
    ASSERT(visitors_[i] == nullptr);
    SyncMarkingVisitor* visitor = new SyncMarkingVisitor(
        isolate_group_, page_space, &old_marking_stack_, &new_marking_stack_,
        &tlab_deferred_marking_stack_, &deferred_marking_stack_);
    visitors_[i] = visitor;

    if (i < (num_tasks - 1)) {
      // Begin marking on a helper thread.
      bool result = Dart::thread_pool()->Run<ConcurrentMarkTask>(
          this, isolate_group_, page_space, visitor);
      ASSERT(result);
    } else {
      // For the last visitor, mark roots on the main thread.
      TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ConcurrentMark");
      int64_t start = OS::GetCurrentMonotonicMicros();
      IterateRoots(visitor);
      visitor->FinishedRoots();
      int64_t stop = OS::GetCurrentMonotonicMicros();
      visitor->AddMicros(stop - start);
      if (FLAG_log_marker_tasks) {
        THR_Print("Task marked %" Pd " bytes in %" Pd64 " micros.\n",
                  visitor->marked_bytes(), visitor->marked_micros());
      }
      // Continue non-root marking concurrently.
      bool result = Dart::thread_pool()->Run<ConcurrentMarkTask>(
          this, isolate_group_, page_space, visitor);
      ASSERT(result);
    }
  }

  isolate_group_->DeferredMarkLiveTemporaries();

  // Wait for roots to be marked before exiting safepoint.
  MonitorLocker ml(&root_slices_monitor_);
  while (root_slices_finished_ != root_slices_count_) {
    ml.Wait();
  }
}

void GCMarker::IncrementalMarkWithUnlimitedBudget(PageSpace* page_space) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(),
                                "IncrementalMarkWithUnlimitedBudget");

  SyncMarkingVisitor visitor(isolate_group_, page_space, &old_marking_stack_,
                             &new_marking_stack_, &tlab_deferred_marking_stack_,
                             &deferred_marking_stack_);
  int64_t start = OS::GetCurrentMonotonicMicros();
  visitor.ProcessOldMarkingStack(kIntptrMax);
  int64_t stop = OS::GetCurrentMonotonicMicros();
  visitor.AddMicros(stop - start);
  {
    MonitorLocker ml(page_space->tasks_lock());
    visitor.FinalizeIncremental(&global_list_);
    marked_bytes_ += visitor.marked_bytes();
    marked_micros_ += visitor.marked_micros();
  }
}

void GCMarker::IncrementalMarkWithSizeBudget(PageSpace* page_space,
                                             intptr_t size) {
  // Avoid setup overhead for tiny amounts of marking as the last bits of TLABs
  // get filled in.
  const intptr_t kMinimumMarkingStep = KB;
  if (size < kMinimumMarkingStep) return;

  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(),
                                "IncrementalMarkWithSizeBudget");

  SyncMarkingVisitor visitor(isolate_group_, page_space, &old_marking_stack_,
                             &new_marking_stack_, &tlab_deferred_marking_stack_,
                             &deferred_marking_stack_);
  int64_t start = OS::GetCurrentMonotonicMicros();
  visitor.ProcessOldMarkingStack(size);
  int64_t stop = OS::GetCurrentMonotonicMicros();
  visitor.AddMicros(stop - start);
  {
    MonitorLocker ml(page_space->tasks_lock());
    visitor.FinalizeIncremental(&global_list_);
    marked_bytes_ += visitor.marked_bytes();
    marked_micros_ += visitor.marked_micros();
  }
}

void GCMarker::IncrementalMarkWithTimeBudget(PageSpace* page_space,
                                             int64_t deadline) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(),
                                "IncrementalMarkWithTimeBudget");

  SyncMarkingVisitor visitor(isolate_group_, page_space, &old_marking_stack_,
                             &new_marking_stack_, &tlab_deferred_marking_stack_,
                             &deferred_marking_stack_);
  int64_t start = OS::GetCurrentMonotonicMicros();
  visitor.ProcessOldMarkingStackUntil(deadline);
  int64_t stop = OS::GetCurrentMonotonicMicros();
  visitor.AddMicros(stop - start);
  {
    MonitorLocker ml(page_space->tasks_lock());
    visitor.FinalizeIncremental(&global_list_);
    marked_bytes_ += visitor.marked_bytes();
    marked_micros_ += visitor.marked_micros();
  }
}

class VerifyAfterMarkingVisitor : public ObjectVisitor,
                                  public ObjectPointerVisitor {
 public:
  VerifyAfterMarkingVisitor()
      : ObjectVisitor(), ObjectPointerVisitor(IsolateGroup::Current()) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->untag()->IsMarked()) {
      current_ = obj;
      obj->untag()->VisitPointers(this);
    }
  }

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr obj = *ptr;
      if (obj->IsHeapObject() && !obj->untag()->IsMarked()) {
        OS::PrintErr("object=0x%" Px ", slot=0x%" Px ", value=0x%" Px "\n",
                     static_cast<uword>(current_), reinterpret_cast<uword>(ptr),
                     static_cast<uword>(obj));
        failed_ = true;
      }
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* from,
                               CompressedObjectPtr* to) override {
    for (CompressedObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr obj = ptr->Decompress(heap_base);
      if (obj->IsHeapObject() && !obj->untag()->IsMarked()) {
        OS::PrintErr("object=0x%" Px ", slot=0x%" Px ", value=0x%" Px "\n",
                     static_cast<uword>(current_), reinterpret_cast<uword>(ptr),
                     static_cast<uword>(obj));
        failed_ = true;
      }
    }
  }
#endif

  bool failed() const { return failed_; }

 private:
  ObjectPtr current_;
  bool failed_ = false;
};

void GCMarker::MarkObjects(PageSpace* page_space) {
  if (isolate_group_->old_marking_stack() != nullptr) {
    isolate_group_->DisableIncrementalBarrier();
  }

  Prologue();
  {
    Thread* thread = Thread::Current();
    const int num_tasks = FLAG_marker_tasks;
    if (num_tasks == 0) {
      TIMELINE_FUNCTION_GC_DURATION(thread, "Mark");
      int64_t start = OS::GetCurrentMonotonicMicros();
      // Mark everything on main thread.
      UnsyncMarkingVisitor visitor(
          isolate_group_, page_space, &old_marking_stack_, &new_marking_stack_,
          &tlab_deferred_marking_stack_, &deferred_marking_stack_);
      visitor.set_concurrent(false);
      ResetSlices();
      IterateRoots(&visitor);
      visitor.FinishedRoots();
      visitor.ProcessDeferredMarking();
      visitor.DrainMarkingStack();
      visitor.ProcessDeferredMarking();
      visitor.FinalizeMarking();
      visitor.MournWeakProperties();
      visitor.MournWeakReferences();
      visitor.MournWeakArrays();
      visitor.MournFinalizerEntries();
      thread->ReleaseStoreBuffer();  // Ahead of IterateWeak
      IterateWeakRoots(thread);
      // All marking done; detach code, etc.
      int64_t stop = OS::GetCurrentMonotonicMicros();
      visitor.AddMicros(stop - start);
      marked_bytes_ += visitor.marked_bytes();
      marked_micros_ += visitor.marked_micros();
    } else {
      ThreadBarrier* barrier = new ThreadBarrier(num_tasks, 1);

      ResetSlices();
      // Used to coordinate draining among tasks; all start out as 'busy'.
      RelaxedAtomic<uintptr_t> num_busy = 0;

      IntrusiveDList<SafepointTask> tasks;
      for (intptr_t i = 0; i < num_tasks; ++i) {
        SyncMarkingVisitor* visitor = visitors_[i];
        // Visitors may or may not have already been created depending on
        // whether we did some concurrent marking.
        if (visitor == nullptr) {
          visitor = new SyncMarkingVisitor(
              isolate_group_, page_space, &old_marking_stack_,
              &new_marking_stack_, &tlab_deferred_marking_stack_,
              &deferred_marking_stack_);
          visitors_[i] = visitor;
        }

        // Move all work from local blocks to the global list. Any given
        // visitor might not get to run if it fails to reach TryEnter soon
        // enough, and we must fail to visit objects but they're sitting in
        // such a visitor's local blocks.
        visitor->Flush(&global_list_);
        // Need to move weak property list too.
        tasks.Append(new ParallelMarkTask(this, isolate_group_,
                                          &old_marking_stack_, barrier, visitor,
                                          &num_busy));
      }
      visitors_[0]->Adopt(&global_list_);
      isolate_group_->safepoint_handler()->RunTasks(&tasks);

      for (intptr_t i = 0; i < num_tasks; i++) {
        SyncMarkingVisitor* visitor = visitors_[i];
        visitor->FinalizeMarking();
        marked_bytes_ += visitor->marked_bytes();
        marked_micros_ += visitor->marked_micros();
        delete visitor;
        visitors_[i] = nullptr;
      }

      ASSERT(global_list_.IsEmpty());
    }
  }

  // Separate from verify_after_gc because that verification interferes with
  // concurrent marking.
  if (FLAG_verify_after_marking) {
    VerifyAfterMarkingVisitor visitor;
    heap_->VisitObjects(&visitor);
    if (visitor.failed()) {
      FATAL("verify after marking");
    }
  }

  Epilogue();
}

void GCMarker::PruneWeak(Scavenger* scavenger) {
  scavenger->PruneWeak(&global_list_);
  for (intptr_t i = 0, n = FLAG_marker_tasks; i < n; i++) {
    scavenger->PruneWeak(visitors_[i]->delayed());
  }
}

}  // namespace dart
