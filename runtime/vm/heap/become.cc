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
  tags = UntaggedObject::SizeTag::update(size, tags);
  tags = UntaggedObject::ClassIdTag::update(kForwardingCorpse, tags);
  bool is_old = (addr & kNewObjectAlignmentOffset) == kOldObjectAlignmentOffset;
  tags = UntaggedObject::OldBit::update(is_old, tags);
  tags = UntaggedObject::OldAndNotMarkedBit::update(is_old, tags);
  tags = UntaggedObject::OldAndNotRememberedBit::update(is_old, tags);
  tags = UntaggedObject::NewBit::update(!is_old, tags);

  result->tags_ = tags;
  if (size > UntaggedObject::SizeTag::kMaxSizeTag) {
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
  const intptr_t size_before = before_obj->untag()->HeapSize();

  uword corpse_addr = static_cast<uword>(before_obj) - kHeapObjectTag;
  ForwardingCorpse* forwarder =
      ForwardingCorpse::AsForwarder(corpse_addr, size_before);
  forwarder->set_target(after_obj);
  if (!IsForwardingObject(before_obj)) {
    FATAL("become: ForwardObjectTo failure.");
  }
  // Still need to be able to iterate over the forwarding corpse.
  const intptr_t size_after = before_obj->untag()->HeapSize();
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

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
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
      } else if (visiting_object_->untag()->IsCardRemembered()) {
        visiting_object_->untag()->StoreArrayPointer(p, new_target, thread_);
      } else {
        visiting_object_->untag()->StorePointer(p, new_target, thread_);
      }
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    for (CompressedObjectPtr* p = first; p <= last; p++) {
      ObjectPtr old_target = p->Decompress(heap_base);
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
      } else if (visiting_object_->untag()->IsCardRemembered()) {
        visiting_object_->untag()->StoreCompressedArrayPointer(p, new_target,
                                                               thread_);
      } else {
        visiting_object_->untag()->StoreCompressedPointer(p, new_target,
                                                          thread_);
      }
    }
  }
#endif

  void VisitingObject(ObjectPtr obj) {
    visiting_object_ = obj;
    // The incoming remembered bit may be unreliable. Clear it so we can
    // consistently reapply the barrier to all slots.
    if ((obj != nullptr) && obj->IsOldObject() &&
        obj->untag()->IsRemembered()) {
      ASSERT(!obj->IsForwardingCorpse());
      ASSERT(!obj->IsFreeListElement());
      obj->untag()->ClearRememberedBit();
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

  void VisitObject(ObjectPtr obj) override {
    pointer_visitor_->VisitingObject(obj);
    obj->untag()->VisitPointers(pointer_visitor_);
  }

 private:
  ForwardPointersVisitor* pointer_visitor_;

  DISALLOW_COPY_AND_ASSIGN(ForwardHeapPointersVisitor);
};

class ForwardHeapPointersHandleVisitor : public HandleVisitor {
 public:
  explicit ForwardHeapPointersHandleVisitor(Thread* thread)
      : HandleVisitor(thread) {}

  void VisitHandle(uword addr) override {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    if (IsForwardingObject(handle->ptr())) {
      *handle->ptr_addr() = GetForwardedObject(handle->ptr());
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

Become::Become() {
  IsolateGroup* group = Thread::Current()->isolate_group();
  ASSERT(group->become() == nullptr);  // Only one outstanding become at a time.
  group->set_become(this);
}

Become::~Become() {
  Thread::Current()->isolate_group()->set_become(nullptr);
}

void Become::Add(const Object& before, const Object& after) {
  pointers_.Add(before.ptr());
  pointers_.Add(after.ptr());
}

void Become::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  if (pointers_.length() != 0) {
    visitor->VisitPointers(&pointers_[0], pointers_.length());
  }
}

void Become::MakeDummyObject(const Instance& instance) {
  // Make the forward pointer point to itself.
  // This is needed to distinguish it from a real forward object.
  ForwardObjectTo(instance.ptr(), instance.ptr());
}

static bool IsDummyObject(ObjectPtr object) {
  if (!object->IsForwardingCorpse()) return false;
  return GetForwardedObject(object) == object;
}

static void CrashDump(ObjectPtr before_obj, ObjectPtr after_obj) {
  OS::PrintErr("DETECTED FATAL ISSUE IN BECOME MAPPINGS\n");

  OS::PrintErr("BEFORE ADDRESS: %#" Px "\n", static_cast<uword>(before_obj));
  OS::PrintErr("BEFORE IS HEAP OBJECT: %s\n",
               before_obj->IsHeapObject() ? "YES" : "NO");
  OS::PrintErr("BEFORE IN VMISOLATE HEAP OBJECT: %s\n",
               before_obj->untag()->InVMIsolateHeap() ? "YES" : "NO");

  OS::PrintErr("AFTER ADDRESS: %#" Px "\n", static_cast<uword>(after_obj));
  OS::PrintErr("AFTER IS HEAP OBJECT: %s\n",
               after_obj->IsHeapObject() ? "YES" : "NO");
  OS::PrintErr("AFTER IN VMISOLATE HEAP OBJECT: %s\n",
               after_obj->untag()->InVMIsolateHeap() ? "YES" : "NO");

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

void Become::Forward() {
  Thread* thread = Thread::Current();
  auto heap = thread->isolate_group()->heap();

  TIMELINE_FUNCTION_GC_DURATION(thread, "Become::ElementsForwardIdentity");
  HeapIterationScope his(thread);

  // Setup forwarding pointers.
  for (intptr_t i = 0; i < pointers_.length(); i += 2) {
    ObjectPtr before_obj = pointers_[i];
    ObjectPtr after_obj = pointers_[i + 1];

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
    if (before_obj->untag()->InVMIsolateHeap()) {
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
    Object::SetCachedHashIfNotSet(after_obj, Object::GetCachedHash(before_obj));
#endif
  }

  FollowForwardingPointers(thread);

#if defined(DEBUG)
  for (intptr_t i = 0; i < pointers_.length(); i += 2) {
    ASSERT(pointers_[i] == pointers_[i + 1]);
  }
#endif
  pointers_.Clear();
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
    pointer_visitor.VisitingObject(nullptr);
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
