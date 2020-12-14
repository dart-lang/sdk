// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/become.h"

#include "platform/assert.h"
#include "platform/utils.h"

#include "vm/dart_api_state.h"
#include "vm/heap/safepoint.h"
#include "vm/isolate_reload.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

namespace dart {

ForwardingCorpse* ForwardingCorpse::AsForwarder(uword addr, intptr_t size) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));

  ForwardingCorpse* result = reinterpret_cast<ForwardingCorpse*>(addr);

  uword tags = result->tags_;  // Carry-over any identity hash.
  tags = ObjectLayout::SizeTag::update(size, tags);
  tags = ObjectLayout::ClassIdTag::update(kForwardingCorpse, tags);
  bool is_old = (addr & kNewObjectAlignmentOffset) == kOldObjectAlignmentOffset;
  tags = ObjectLayout::OldBit::update(is_old, tags);
  tags = ObjectLayout::OldAndNotMarkedBit::update(is_old, tags);
  tags = ObjectLayout::OldAndNotRememberedBit::update(is_old, tags);
  tags = ObjectLayout::NewBit::update(!is_old, tags);

  result->tags_ = tags;
  if (size > ObjectLayout::SizeTag::kMaxSizeTag) {
    *result->SizeAddress() = size;
  }
  result->set_target(Object::null());
  return result;
}

void ForwardingCorpse::Init() {
  ASSERT(sizeof(ForwardingCorpse) == kObjectAlignment);
  ASSERT(OFFSET_OF(ForwardingCorpse, tags_) == Object::tags_offset());
}

// Free list elements are used as a marker for forwarding objects. This is
// safe because we cannot reach free list elements from live objects. Ideally
// forwarding objects would have their own class id. See TODO below.
static bool IsForwardingObject(ObjectPtr object) {
  return object->IsHeapObject() && object->IsForwardingCorpse();
}

static ObjectPtr GetForwardedObject(ObjectPtr object) {
  ASSERT(IsForwardingObject(object));
  uword addr = static_cast<uword>(object) - kHeapObjectTag;
  ForwardingCorpse* forwarder = reinterpret_cast<ForwardingCorpse*>(addr);
  return forwarder->target();
}

static void ForwardObjectTo(ObjectPtr before_obj, ObjectPtr after_obj) {
  const intptr_t size_before = before_obj->ptr()->HeapSize();

  uword corpse_addr = static_cast<uword>(before_obj) - kHeapObjectTag;
  ForwardingCorpse* forwarder =
      ForwardingCorpse::AsForwarder(corpse_addr, size_before);
  forwarder->set_target(after_obj);
  if (!IsForwardingObject(before_obj)) {
    FATAL("become: ForwardObjectTo failure.");
  }
  // Still need to be able to iterate over the forwarding corpse.
  const intptr_t size_after = before_obj->ptr()->HeapSize();
  if (size_before != size_after) {
    FATAL("become: Before and after sizes do not match.");
  }
}

class ForwardPointersVisitor : public ObjectPointerVisitor {
 public:
  explicit ForwardPointersVisitor(Thread* thread)
      : ObjectPointerVisitor(thread->isolate_group()),
        thread_(thread),
        visiting_object_(nullptr) {}

  virtual void VisitPointers(ObjectPtr* first, ObjectPtr* last) {
    for (ObjectPtr* p = first; p <= last; p++) {
      ObjectPtr old_target = *p;
      ObjectPtr new_target;
      if (IsForwardingObject(old_target)) {
        new_target = GetForwardedObject(old_target);
      } else {
        // Though we do not need to update the slot's value when it is not
        // forwarded, we do need to recheck the generational barrier. In
        // particular, the remembered bit may be incorrectly false if this
        // become was the result of aborting a scavenge while visiting the
        // remembered set.
        new_target = old_target;
      }
      if (visiting_object_ == nullptr) {
        *p = new_target;
      } else if (visiting_object_->ptr()->IsCardRemembered()) {
        visiting_object_->ptr()->StoreArrayPointer(p, new_target, thread_);
      } else {
        visiting_object_->ptr()->StorePointer(p, new_target, thread_);
      }
    }
  }

  void VisitingObject(ObjectPtr obj) {
    visiting_object_ = obj;
    // The incoming remembered bit may be unreliable. Clear it so we can
    // consistently reapply the barrier to all slots.
    if ((obj != nullptr) && obj->IsOldObject() && obj->ptr()->IsRemembered()) {
      ASSERT(!obj->IsForwardingCorpse());
      ASSERT(!obj->IsFreeListElement());
      obj->ptr()->ClearRememberedBit();
    }
  }

 private:
  Thread* thread_;
  ObjectPtr visiting_object_;

  DISALLOW_COPY_AND_ASSIGN(ForwardPointersVisitor);
};

class ForwardHeapPointersVisitor : public ObjectVisitor {
 public:
  explicit ForwardHeapPointersVisitor(ForwardPointersVisitor* pointer_visitor)
      : pointer_visitor_(pointer_visitor) {}

  virtual void VisitObject(ObjectPtr obj) {
    pointer_visitor_->VisitingObject(obj);
    obj->ptr()->VisitPointers(pointer_visitor_);
  }

 private:
  ForwardPointersVisitor* pointer_visitor_;

  DISALLOW_COPY_AND_ASSIGN(ForwardHeapPointersVisitor);
};

class ForwardHeapPointersHandleVisitor : public HandleVisitor {
 public:
  explicit ForwardHeapPointersHandleVisitor(Thread* thread)
      : HandleVisitor(thread) {}

  virtual void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    if (IsForwardingObject(handle->raw())) {
      *handle->raw_addr() = GetForwardedObject(handle->raw());
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(ForwardHeapPointersHandleVisitor);
};

// On IA32, object pointers are embedded directly in the instruction stream,
// which is normally write-protected, so we need to make it temporarily writable
// to forward the pointers. On all other architectures, object pointers are
// accessed through ObjectPools.
#if defined(TARGET_ARCH_IA32)
class WritableCodeLiteralsScope : public ValueObject {
 public:
  explicit WritableCodeLiteralsScope(Heap* heap) : heap_(heap) {
    if (FLAG_write_protect_code) {
      heap_->WriteProtectCode(false);
    }
  }

  ~WritableCodeLiteralsScope() {
    if (FLAG_write_protect_code) {
      heap_->WriteProtectCode(true);
    }
  }

 private:
  Heap* heap_;
};
#else
class WritableCodeLiteralsScope : public ValueObject {
 public:
  explicit WritableCodeLiteralsScope(Heap* heap) {}
  ~WritableCodeLiteralsScope() {}
};
#endif

void Become::MakeDummyObject(const Instance& instance) {
  // Make the forward pointer point to itself.
  // This is needed to distinguish it from a real forward object.
  ForwardObjectTo(instance.raw(), instance.raw());
}

static bool IsDummyObject(ObjectPtr object) {
  if (!object->IsForwardingCorpse()) return false;
  return GetForwardedObject(object) == object;
}

void Become::CrashDump(ObjectPtr before_obj, ObjectPtr after_obj) {
  OS::PrintErr("DETECTED FATAL ISSUE IN BECOME MAPPINGS\n");

  OS::PrintErr("BEFORE ADDRESS: %#" Px "\n", static_cast<uword>(before_obj));
  OS::PrintErr("BEFORE IS HEAP OBJECT: %s\n",
               before_obj->IsHeapObject() ? "YES" : "NO");
  OS::PrintErr("BEFORE IN VMISOLATE HEAP OBJECT: %s\n",
               before_obj->ptr()->InVMIsolateHeap() ? "YES" : "NO");

  OS::PrintErr("AFTER ADDRESS: %#" Px "\n", static_cast<uword>(after_obj));
  OS::PrintErr("AFTER IS HEAP OBJECT: %s\n",
               after_obj->IsHeapObject() ? "YES" : "NO");
  OS::PrintErr("AFTER IN VMISOLATE HEAP OBJECT: %s\n",
               after_obj->ptr()->InVMIsolateHeap() ? "YES" : "NO");

  if (before_obj->IsHeapObject()) {
    OS::PrintErr("BEFORE OBJECT CLASS ID=%" Pd "\n", before_obj->GetClassId());
    const Object& obj = Object::Handle(before_obj);
    OS::PrintErr("BEFORE OBJECT AS STRING=%s\n", obj.ToCString());
  }

  if (after_obj->IsHeapObject()) {
    OS::PrintErr("AFTER OBJECT CLASS ID=%" Pd "\n", after_obj->GetClassId());
    const Object& obj = Object::Handle(after_obj);
    OS::PrintErr("AFTER OBJECT AS STRING=%s\n", obj.ToCString());
  }
}

void Become::ElementsForwardIdentity(const Array& before, const Array& after) {
  Thread* thread = Thread::Current();
  auto heap = thread->isolate_group()->heap();

  TIMELINE_FUNCTION_GC_DURATION(thread, "Become::ElementsForwardIdentity");
  HeapIterationScope his(thread);

  // Setup forwarding pointers.
  ASSERT(before.Length() == after.Length());
  for (intptr_t i = 0; i < before.Length(); i++) {
    ObjectPtr before_obj = before.At(i);
    ObjectPtr after_obj = after.At(i);

    if (before_obj == after_obj) {
      FATAL("become: Cannot self-forward");
    }
    if (!before_obj->IsHeapObject()) {
      CrashDump(before_obj, after_obj);
      FATAL("become: Cannot forward immediates");
    }
    if (!after_obj->IsHeapObject()) {
      CrashDump(before_obj, after_obj);
      FATAL("become: Cannot become immediates");
    }
    if (before_obj->ptr()->InVMIsolateHeap()) {
      CrashDump(before_obj, after_obj);
      FATAL("become: Cannot forward VM heap objects");
    }
    if (before_obj->IsForwardingCorpse() && !IsDummyObject(before_obj)) {
      FATAL("become: Cannot forward to multiple targets");
    }
    if (after_obj->IsForwardingCorpse()) {
      // The Smalltalk become does allow this, and for very special cases
      // it is important (shape changes to Class or Mixin), but as these
      // cases do not arise in Dart, better to prohibit it.
      FATAL("become: No indirect chains of forwarding");
    }

    ForwardObjectTo(before_obj, after_obj);
    heap->ForwardWeakEntries(before_obj, after_obj);
#if defined(HASH_IN_OBJECT_HEADER)
    Object::SetCachedHash(after_obj, Object::GetCachedHash(before_obj));
#endif
  }

  FollowForwardingPointers(thread);

#if defined(DEBUG)
  for (intptr_t i = 0; i < before.Length(); i++) {
    ASSERT(before.At(i) == after.At(i));
  }
#endif
}

void Become::FollowForwardingPointers(Thread* thread) {
  // N.B.: We forward the heap before forwarding the stack. This limits the
  // amount of following of forwarding pointers needed to get at stack maps.
  auto isolate_group = thread->isolate_group();
  Heap* heap = isolate_group->heap();

  // Clear the store buffer; will be rebuilt as we forward the heap.
  isolate_group->ReleaseStoreBuffers();
  isolate_group->store_buffer()->Reset();

  ForwardPointersVisitor pointer_visitor(thread);

  {
    // Heap pointers.
    WritableCodeLiteralsScope writable_code(heap);
    ForwardHeapPointersVisitor object_visitor(&pointer_visitor);
    heap->VisitObjects(&object_visitor);
    pointer_visitor.VisitingObject(NULL);
  }

  // C++ pointers.
  isolate_group->VisitObjectPointers(&pointer_visitor,
                                     ValidationPolicy::kValidateFrames);
#ifndef PRODUCT
  isolate_group->ForEachIsolate(
      [&](Isolate* isolate) {
        ObjectIdRing* ring = isolate->object_id_ring();
        if (ring != nullptr) {
          ring->VisitPointers(&pointer_visitor);
        }
      },
      /*at_safepoint=*/true);
#endif  // !PRODUCT

  // Weak persistent handles.
  ForwardHeapPointersHandleVisitor handle_visitor(thread);
  isolate_group->VisitWeakPersistentHandles(&handle_visitor);
}

}  // namespace dart
