// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/become.h"

#include "platform/assert.h"
#include "platform/utils.h"

#include "vm/dart_api_state.h"
#include "vm/freelist.h"
#include "vm/isolate_reload.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/safepoint.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

namespace dart {

DECLARE_FLAG(bool, trace_reload);

// Free list elements are used as a marker for forwarding objects. This is
// safe because we cannot reach free list elements from live objects. Ideally
// forwarding objects would have their own class id. See TODO below.
static bool IsForwardingObject(RawObject* object) {
  return object->IsHeapObject() && object->IsFreeListElement();
}


static RawObject* GetForwardedObject(RawObject* object) {
  ASSERT(IsForwardingObject(object));
  uword addr = reinterpret_cast<uword>(object) - kHeapObjectTag;
  FreeListElement* forwarder = reinterpret_cast<FreeListElement*>(addr);
  RawObject* new_target = reinterpret_cast<RawObject*>(forwarder->next());
  return new_target;
}


static void ForwardObjectTo(RawObject* before_obj, RawObject* after_obj) {
  const intptr_t size_before = before_obj->Size();

  // TODO(rmacnak): We should use different cids for forwarding corpses and
  // free list elements.
  uword corpse_addr = reinterpret_cast<uword>(before_obj) - kHeapObjectTag;
  FreeListElement* forwarder = FreeListElement::AsElement(corpse_addr,
                                                          size_before);
  forwarder->set_next(reinterpret_cast<FreeListElement*>(after_obj));
  if (!IsForwardingObject(before_obj)) {
    FATAL("become: ForwardObjectTo failure.");
  }
  // Still need to be able to iterate over the forwarding corpse.
  const intptr_t size_after = before_obj->Size();
  if (size_before != size_after) {
    FATAL("become: Before and after sizes do not match.");
  }
}


class ForwardPointersVisitor : public ObjectPointerVisitor {
 public:
  explicit ForwardPointersVisitor(Isolate* isolate)
      : ObjectPointerVisitor(isolate), visiting_object_(NULL), count_(0) { }

  virtual void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** p = first; p <= last; p++) {
      RawObject* old_target = *p;
      if (IsForwardingObject(old_target)) {
        RawObject* new_target = GetForwardedObject(old_target);
        if (visiting_object_ == NULL) {
          *p = new_target;
        } else {
          visiting_object_->StorePointer(p, new_target);
        }
        count_++;
      }
    }
  }

  void VisitingObject(RawObject* obj) { visiting_object_ = obj; }

  intptr_t count() const { return count_; }

 private:
  RawObject* visiting_object_;
  intptr_t count_;

  DISALLOW_COPY_AND_ASSIGN(ForwardPointersVisitor);
};


class ForwardHeapPointersVisitor : public ObjectVisitor {
 public:
  explicit ForwardHeapPointersVisitor(ForwardPointersVisitor* pointer_visitor)
      : pointer_visitor_(pointer_visitor) { }

  virtual void VisitObject(RawObject* obj) {
    pointer_visitor_->VisitingObject(obj);
    obj->VisitPointers(pointer_visitor_);
  }

 private:
  ForwardPointersVisitor* pointer_visitor_;

  DISALLOW_COPY_AND_ASSIGN(ForwardHeapPointersVisitor);
};


class ForwardHeapPointersHandleVisitor : public HandleVisitor {
 public:
  ForwardHeapPointersHandleVisitor()
      : HandleVisitor(Thread::Current()), count_(0) { }

  virtual void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    if (IsForwardingObject(handle->raw())) {
      *handle->raw_addr() = GetForwardedObject(handle->raw());
      count_++;
    }
  }

  intptr_t count() const { return count_; }

 private:
  int count_;

  DISALLOW_COPY_AND_ASSIGN(ForwardHeapPointersHandleVisitor);
};


#if defined(DEBUG)
class NoFreeListTargetsVisitor : public ObjectPointerVisitor {
 public:
  explicit NoFreeListTargetsVisitor(Isolate* isolate)
      : ObjectPointerVisitor(isolate) { }

  virtual void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** p = first; p <= last; p++) {
      RawObject* target = *p;
      if (target->IsHeapObject()) {
        ASSERT(!target->IsFreeListElement());
      }
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(NoFreeListTargetsVisitor);
};
#endif


void Become::ElementsForwardIdentity(const Array& before, const Array& after) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Heap* heap = isolate->heap();

  {
    // TODO(rmacnak): Investigate why this is necessary.
    heap->CollectGarbage(Heap::kNew);
  }

  TIMELINE_FUNCTION_GC_DURATION(thread, "Become::ElementsForwardIdentity");
  HeapIterationScope his;

#if defined(DEBUG)
  {
    // There should be no pointers to free list elements / forwarding corpses.
    NoFreeListTargetsVisitor visitor(isolate);
    isolate->VisitObjectPointers(&visitor, true);
    heap->VisitObjectPointers(&visitor);
  }
#endif

  // Setup forwarding pointers.
  ASSERT(before.Length() == after.Length());
  for (intptr_t i = 0; i < before.Length(); i++) {
    RawObject* before_obj = before.At(i);
    RawObject* after_obj = after.At(i);

    if (before_obj == after_obj) {
      FATAL("become: Cannot self-forward");
    }
    if (!before_obj->IsHeapObject()) {
      FATAL("become: Cannot forward immediates");
    }
    if (!after_obj->IsHeapObject()) {
      FATAL("become: Cannot become an immediates");
    }
    if (before_obj->IsVMHeapObject()) {
      FATAL("become: Cannot forward VM heap objects");
    }
    if (after_obj->IsFreeListElement()) {
      // The Smalltalk become does allow this, and for very special cases
      // it is important (shape changes to Class or Mixin), but as these
      // cases do not arise in Dart, better to prohibit it.
      FATAL("become: No indirect chains of forwarding");
    }

    ForwardObjectTo(before_obj, after_obj);
  }

  {
    // Follow forwarding pointers.

    // C++ pointers
    ForwardPointersVisitor pointer_visitor(isolate);
    isolate->VisitObjectPointers(&pointer_visitor, true);

    // Weak persistent handles.
    ForwardHeapPointersHandleVisitor handle_visitor;
    isolate->VisitWeakPersistentHandles(&handle_visitor);

    //   Heap pointers (may require updating the remembered set)
    ForwardHeapPointersVisitor object_visitor(&pointer_visitor);
    heap->VisitObjects(&object_visitor);
    pointer_visitor.VisitingObject(NULL);

    TIR_Print("Performed %" Pd " heap and %" Pd " handle replacements\n",
              pointer_visitor.count(),
              handle_visitor.count());
  }

#if defined(DEBUG)
  for (intptr_t i = 0; i < before.Length(); i++) {
    ASSERT(before.At(i) == after.At(i));
  }

  {
    // There should be no pointers to forwarding corpses.
    NoFreeListTargetsVisitor visitor(isolate);
    isolate->VisitObjectPointers(&visitor, true);
    heap->VisitObjectPointers(&visitor);
  }
#endif
}

}  // namespace dart
