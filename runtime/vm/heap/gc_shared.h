// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for detail_s. All rights reserved. Use of this source code is governed by a
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
  V(WeakReference, weak_references)

template <typename Type, typename PtrType>
class GCLinkedList {
 public:
  void Enqueue(PtrType ptr) {
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
      to->tail_->untag()->next_seen_by_gc_ = head_;
      to->tail_ = tail_;
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

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_GC_SHARED_H_
