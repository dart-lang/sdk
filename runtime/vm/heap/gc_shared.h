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
  V(WeakArray, weak_arrays)                                                    \
  V(WeakReference, weak_references)                                            \
  V(FinalizerEntry, finalizer_entries)

template <typename Type, typename PtrType>
class GCLinkedList {
 public:
  void Enqueue(PtrType ptr) {
    ASSERT(ptr->untag()->next_seen_by_gc().IsRawNull());
    ptr->untag()->next_seen_by_gc_ = head_;
    if (head_ == Type::null()) {
      tail_ = ptr;
    }
    head_ = ptr;
  }

  void FlushInto(GCLinkedList<Type, PtrType>* to) {
    if (to->head_ == Type::null()) {
      ASSERT(to->tail_ == Type::null());
      to->head_ = head_;
      to->tail_ = tail_;
    } else {
      ASSERT(to->tail_ != Type::null());
      ASSERT(to->tail_->untag()->next_seen_by_gc() == Type::null());
      if (head_ != Type::null()) {
        to->tail_->untag()->next_seen_by_gc_ = head_;
        to->tail_ = tail_;
      }
    }
    Release();
  }

  PtrType Release() {
    PtrType return_value = head_;
    head_ = Type::null();
    tail_ = Type::null();
    return return_value;
  }

  bool IsEmpty() { return head_ == Type::null() && tail_ == Type::null(); }

 private:
  PtrType head_ = Type::null();
  PtrType tail_ = Type::null();
};

struct GCLinkedLists {
  void Release();
  bool IsEmpty();
  void FlushInto(GCLinkedLists* to);

#define FOREACH(type, var) GCLinkedList<type, type##Ptr> var;
  GC_LINKED_LIST(FOREACH)
#undef FOREACH
};

#ifdef DEBUG
#define TRACE_FINALIZER(format, ...)                                           \
  if (FLAG_trace_finalizers) {                                                 \
    THR_Print("%s %p " format "\n", GCVisitorType::kName, visitor,             \
              __VA_ARGS__);                                                    \
  }
#else
#define TRACE_FINALIZER(format, ...)
#endif

// The space in which `raw_entry`'s `value` is.
Heap::Space SpaceForExternal(FinalizerEntryPtr raw_entry);

// Runs the finalizer if not detached, detaches the value and set external size
// to 0.
// TODO(http://dartbug.com/47777): Can this be merged with
// NativeFinalizer::RunCallback?
template <typename GCVisitorType>
void RunNativeFinalizerCallback(NativeFinalizerPtr raw_finalizer,
                                FinalizerEntryPtr raw_entry,
                                Heap::Space before_gc_space,
                                GCVisitorType* visitor) {
  PointerPtr callback_pointer = raw_finalizer->untag()->callback();
  const auto callback = reinterpret_cast<NativeFinalizer::Callback>(
      callback_pointer->untag()->data());
  ObjectPtr token_object = raw_entry->untag()->token();
  const bool is_detached = token_object == raw_entry;
  const intptr_t external_size = raw_entry->untag()->external_size();
  if (is_detached) {
    // Detached from Dart code.
    ASSERT(token_object == raw_entry);
    ASSERT(external_size == 0);
    if (FLAG_trace_finalizers) {
      TRACE_FINALIZER("Not running native finalizer %p callback %p, detached",
                      raw_finalizer->untag(), callback);
    }
  } else {
    // TODO(http://dartbug.com/48615): Unbox pointer address in entry.
    ASSERT(token_object.IsPointer());
    PointerPtr token = static_cast<PointerPtr>(token_object);
    void* peer = reinterpret_cast<void*>(token->untag()->data());
    if (FLAG_trace_finalizers) {
      TRACE_FINALIZER("Running native finalizer %p callback %p with token %p",
                      raw_finalizer->untag(), callback, peer);
    }
    raw_entry.untag()->set_token(raw_entry);
    (*callback)(peer);
    if (external_size > 0) {
      if (FLAG_trace_finalizers) {
        TRACE_FINALIZER("Clearing external size %" Pd " bytes in %s space",
                        external_size, before_gc_space == 0 ? "new" : "old");
      }
      visitor->isolate_group()->heap()->FreedExternal(external_size,
                                                      before_gc_space);
      raw_entry->untag()->set_external_size(0);
    }
  }
}

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
// It is expected to provide |ForwardOrSetNullIfCollected| method for clearing
// fields referring to dead objects and |kName| field which contains visitor
// name for tracing output.
template <typename GCVisitorType>
void MournFinalized(GCVisitorType* visitor) {
  FinalizerEntryPtr current_entry =
      visitor->delayed_.finalizer_entries.Release();
  while (current_entry != FinalizerEntry::null()) {
    TRACE_FINALIZER("Processing Entry %p", current_entry->untag());
    FinalizerEntryPtr next_entry =
        current_entry->untag()->next_seen_by_gc_.Decompress(
            current_entry->heap_base());
    current_entry->untag()->next_seen_by_gc_ = FinalizerEntry::null();

    uword heap_base = current_entry->heap_base();
    const Heap::Space before_gc_space = SpaceForExternal(current_entry);
    const bool value_collected_this_gc =
        GCVisitorType::ForwardOrSetNullIfCollected(
            heap_base, &current_entry->untag()->value_);
    if (!value_collected_this_gc && before_gc_space == Heap::kNew) {
      const Heap::Space after_gc_space = SpaceForExternal(current_entry);
      if (after_gc_space == Heap::kOld) {
        const intptr_t external_size = current_entry->untag()->external_size_;
        TRACE_FINALIZER("Promoting external size %" Pd
                        " bytes from new to old space",
                        external_size);
        visitor->isolate_group()->heap()->PromotedExternal(external_size);
      }
    }
    GCVisitorType::ForwardOrSetNullIfCollected(
        heap_base, &current_entry->untag()->detach_);
    GCVisitorType::ForwardOrSetNullIfCollected(
        heap_base, &current_entry->untag()->finalizer_);

    ObjectPtr token_object = current_entry->untag()->token();
    // See sdk/lib/_internal/vm/lib/internal_patch.dart FinalizerBase.detach.
    const bool is_detached = token_object == current_entry;

    if (value_collected_this_gc && !is_detached) {
      FinalizerBasePtr finalizer = current_entry->untag()->finalizer();

      if (finalizer.IsRawNull()) {
        TRACE_FINALIZER("Value collected entry %p finalizer null",
                        current_entry->untag());

        // Do nothing, the finalizer has been GCed.
      } else {
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
        // workers are not, but they bypass safepoint because the main
        // worker is at a safepoint already.
        ASSERT(Thread::Current()->OwnsGCSafepoint() ||
               Thread::Current()->BypassSafepoints());

        if (finalizer.IsNativeFinalizer()) {
          NativeFinalizerPtr native_finalizer =
              static_cast<NativeFinalizerPtr>(finalizer);

          // Immediately call native callback.
          RunNativeFinalizerCallback(native_finalizer, current_entry,
                                     before_gc_space, visitor);

          // Fall-through sending a message to clear the entries and remove
          // from detachments.
        }

        FinalizerEntryPtr previous_head =
            finalizer_dart->untag()->exchange_entries_collected(current_entry);
        current_entry->untag()->set_next(previous_head);
        const bool first_entry = previous_head.IsRawNull();

        // If we're in the marker, we need to ensure that we release the store
        // buffer afterwards.
        // If we're in the scavenger and have the finalizer in old space and
        // a new space entry, we don't need to release the store buffer.
        if (!first_entry && previous_head->IsNewObject() &&
            current_entry->IsOldObject()) {
          TRACE_FINALIZER("Entry %p (old) next is %p (new)",
                          current_entry->untag(), previous_head->untag());
          // We must release the thread's store buffer block.
        }

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
      }
    }

    current_entry = next_entry;
  }
}

#undef TRACE_FINALIZER

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_GC_SHARED_H_
