// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Logic shared between the Scavenger and Marker.

#ifndef RUNTIME_VM_HEAP_GC_SHARED_H_
#define RUNTIME_VM_HEAP_GC_SHARED_H_

#include "vm/compiler/runtime_api.h"
#if defined(SHOULD_NOT_INCLUDE_RUNTIME)
#error "Should not include runtime"
#endif

#include "vm/dart_api_state.h"
#include "vm/heap/scavenger.h"
#include "vm/log.h"
#include "vm/message_handler.h"
#include "vm/object.h"

namespace dart {

// These object types have a linked list chaining all pending objects when
// processing these in the GC.
// The field should not be visited by pointer visitors.
// The field should only be set during a GC.
//
// Macro params:
// - type
// - variable name
#define GC_LINKED_LIST(V)                                                      \
  V(WeakProperty, weak_properties)                                             \
  V(WeakReference, weak_references)                                            \
  V(FinalizerEntry, finalizer_entries)

template <typename Type, typename PtrType>
struct GCLinkedList {
 public:
  void Enqueue(PtrType ptr) {
    ptr->untag()->next_seen_by_gc_ = head;
    if (head == Type::null()) {
      tail = ptr;
    }
    head = ptr;
  }

  void FlushInto(GCLinkedList<Type, PtrType>* to) {
    if (to->head == Type::null()) {
      ASSERT(to->tail == Type::null());
      to->head = head;
      to->tail = tail;
    } else {
      ASSERT(to->tail != Type::null());
      ASSERT(to->tail->untag()->next_seen_by_gc() == Type::null());
      to->tail->untag()->next_seen_by_gc_ = head;
      to->tail = tail;
    }
    Clear();
  }

  PtrType Clear() {
    PtrType return_value = head;
    head = Type::null();
    tail = Type::null();
    return return_value;
  }

  bool IsEmpty() { return head == Type::null() && tail == Type::null(); }

 private:
  PtrType head = Type::null();
  PtrType tail = Type::null();
};

struct GCLinkedLists {
 public:
  void Clear();
  bool IsEmpty();
  void FlushInto(GCLinkedLists* to);

#define FOREACH(type, var) GCLinkedList<type, type##Ptr> var;
  GC_LINKED_LIST(FOREACH)
#undef FOREACH
};

#ifdef DEBUG
#define TRACE_FINALIZER(format, ...)                                           \
  if (FLAG_trace_finalizers) {                                                 \
    THR_Print("%s %p " format "\n", visitor->kName, visitor, __VA_ARGS__);     \
  }
#else
#define TRACE_FINALIZER(format, ...)
#endif

// This function processes all finalizer entries discovered by a scavenger or
// marker. If an entry is referencing an object that is going to die, such entry
// is cleared and enqueued in the respective finalizer.
//
// Finalizer entries belonging to unreachable finalizer entries do not get
// processed, so the callback will not be called for these finalizers.
//
// For more documentation see runtime/docs/gc.md.
//
// |GCVisitorType| is a concrete type implementing either marker or scavenger.
// It is expected to provide |SetNullIfCollected| method for clearing fields
// referring to dead objects and |kName| field which contains visitor name for
// tracing output.
template <typename GCVisitorType>
void MournFinalized(GCVisitorType* visitor) {
  FinalizerEntryPtr current_entry = visitor->delayed_.finalizer_entries.Clear();
  while (current_entry != FinalizerEntry::null()) {
    TRACE_FINALIZER("Processing Entry %p", current_entry->untag());
    FinalizerEntryPtr next_entry =
        current_entry->untag()->next_seen_by_gc_.Decompress(
            current_entry->heap_base());
    current_entry->untag()->next_seen_by_gc_ = FinalizerEntry::null();

    uword heap_base = current_entry->heap_base();
    const bool value_collected_this_gc = GCVisitorType::SetNullIfCollected(
        heap_base, &current_entry->untag()->value_);
    GCVisitorType::SetNullIfCollected(heap_base,
                                      &current_entry->untag()->detach_);
    GCVisitorType::SetNullIfCollected(heap_base,
                                      &current_entry->untag()->finalizer_);

    ObjectPtr token_object = current_entry->untag()->token();
    // See sdk/lib/_internal/vm/lib/internal_patch.dart FinalizerBase.detach.
    const bool is_detached = token_object == current_entry;

    if (value_collected_this_gc && !is_detached) {
      FinalizerBasePtr finalizer = current_entry->untag()->finalizer();

      if (finalizer.IsRawNull()) {
        TRACE_FINALIZER("Value collected entry %p finalizer null",
                        current_entry->untag());

        // Do nothing, the finalizer has been GCed.
      } else if (finalizer.IsFinalizer()) {
        TRACE_FINALIZER("Value collected entry %p finalizer %p",
                        current_entry->untag(), finalizer->untag());

        FinalizerPtr finalizer_dart = static_cast<FinalizerPtr>(finalizer);
        // Move entry to entries collected and current head of that list as
        // the next element. Using a atomic exchange satisfies concurrency
        // between the parallel GC tasks.
        // We rely on the fact that the mutator thread is not running to avoid
        // races between GC and mutator modifying Finalizer.entries_collected.
        //
        // We only run in serial marker or in the finalize step in the marker,
        // both are in safepoint.
        // The main scavenger worker is at safepoint, the other scavenger
        // workers are are not, but they bypass safepoint because the main
        // worker is at a safepoint already.
        ASSERT(Thread::Current()->IsAtSafepoint() ||
               Thread::Current()->BypassSafepoints());

        FinalizerEntryPtr previous_head =
            finalizer_dart->untag()->exchange_entries_collected(current_entry);
        current_entry->untag()->set_next(previous_head);
        const bool first_entry = previous_head.IsRawNull();
        // Schedule calling Dart finalizer.
        if (first_entry) {
          Isolate* isolate = finalizer->untag()->isolate_;
          if (isolate == nullptr) {
            TRACE_FINALIZER(
                "Not scheduling finalizer %p callback on isolate null",
                finalizer->untag());
          } else {
            TRACE_FINALIZER("Scheduling finalizer %p callback on isolate %p",
                            finalizer->untag(), isolate);

            PersistentHandle* handle =
                isolate->group()->api_state()->AllocatePersistentHandle();
            handle->set_ptr(finalizer);
            MessageHandler* message_handler = isolate->message_handler();
            message_handler->PostMessage(
                Message::New(handle, Message::kNormalPriority),
                /*before_events*/ false);
          }
        }
      } else {
        // TODO(http://dartbug.com/47777): Implement NativeFinalizer.
        UNREACHABLE();
      }
    }

    current_entry = next_entry;
  }
}

#undef TRACE_FINALIZER

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_GC_SHARED_H_
