// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/become.h"

#include "platform/assert.h"
#include "platform/utils.h"

#include "vm/dart_api_state.h"
#include "vm/isolate_reload.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/safepoint.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

namespace dart {

ForwardingCorpse* ForwardingCorpse::AsForwarder(uword addr, intptr_t size) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));

  ForwardingCorpse* result = reinterpret_cast<ForwardingCorpse*>(addr);

  uint32_t tags = 0;
  tags = RawObject::SizeTag::update(size, tags);
  tags = RawObject::ClassIdTag::update(kForwardingCorpse, tags);

  result->tags_ = tags;
  if (size > RawObject::SizeTag::kMaxSizeTag) {
    *result->SizeAddress() = size;
  }
  result->set_target(Object::null());
  return result;
}

void ForwardingCorpse::InitOnce() {
  ASSERT(sizeof(ForwardingCorpse) == kObjectAlignment);
  ASSERT(OFFSET_OF(ForwardingCorpse, tags_) == Object::tags_offset());
}

// Free list elements are used as a marker for forwarding objects. This is
// safe because we cannot reach free list elements from live objects. Ideally
// forwarding objects would have their own class id. See TODO below.
static bool IsForwardingObject(RawObject* object) {
  return object->IsHeapObject() && object->IsForwardingCorpse();
}

static RawObject* GetForwardedObject(RawObject* object) {
  ASSERT(IsForwardingObject(object));
  uword addr = reinterpret_cast<uword>(object) - kHeapObjectTag;
  ForwardingCorpse* forwarder = reinterpret_cast<ForwardingCorpse*>(addr);
  return forwarder->target();
}

static void ForwardObjectTo(RawObject* before_obj, RawObject* after_obj) {
  const intptr_t size_before = before_obj->Size();

  uword corpse_addr = reinterpret_cast<uword>(before_obj) - kHeapObjectTag;
  ForwardingCorpse* forwarder =
      ForwardingCorpse::AsForwarder(corpse_addr, size_before);
  forwarder->set_target(after_obj);
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
  explicit ForwardPointersVisitor(Thread* thread)
      : ObjectPointerVisitor(thread->isolate()),
        thread_(thread),
        visiting_object_(NULL),
        count_(0) {}

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

  void VisitingObject(RawObject* obj) {
    visiting_object_ = obj;
    if ((obj != NULL) && obj->IsRemembered()) {
      ASSERT(!obj->IsForwardingCorpse());
      ASSERT(!obj->IsFreeListElement());
      thread_->StoreBufferAddObjectGC(obj);
    }
  }

  intptr_t count() const { return count_; }

 private:
  Thread* thread_;
  RawObject* visiting_object_;
  intptr_t count_;

  DISALLOW_COPY_AND_ASSIGN(ForwardPointersVisitor);
};

class ForwardHeapPointersVisitor : public ObjectVisitor {
 public:
  explicit ForwardHeapPointersVisitor(ForwardPointersVisitor* pointer_visitor)
      : pointer_visitor_(pointer_visitor) {}

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
      : HandleVisitor(Thread::Current()), count_(0) {}

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

static bool IsDummyObject(RawObject* object) {
  if (!object->IsForwardingCorpse()) return false;
  return GetForwardedObject(object) == object;
}

void Become::CrashDump(RawObject* before_obj, RawObject* after_obj) {
  OS::PrintErr("DETECTED FATAL ISSUE IN BECOME MAPPINGS\n");

  OS::PrintErr("BEFORE ADDRESS: %p\n", before_obj);
  OS::PrintErr("BEFORE IS HEAP OBJECT: %s",
               before_obj->IsHeapObject() ? "YES" : "NO");
  OS::PrintErr("BEFORE IS VM HEAP OBJECT: %s",
               before_obj->IsVMHeapObject() ? "YES" : "NO");

  OS::PrintErr("AFTER ADDRESS: %p\n", after_obj);
  OS::PrintErr("AFTER IS HEAP OBJECT: %s",
               after_obj->IsHeapObject() ? "YES" : "NO");
  OS::PrintErr("AFTER IS VM HEAP OBJECT: %s",
               after_obj->IsVMHeapObject() ? "YES" : "NO");

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
  Isolate* isolate = thread->isolate();
  Heap* heap = isolate->heap();

  TIMELINE_FUNCTION_GC_DURATION(thread, "Become::ElementsForwardIdentity");
  HeapIterationScope his(thread);

  // Setup forwarding pointers.
  ASSERT(before.Length() == after.Length());
  for (intptr_t i = 0; i < before.Length(); i++) {
    RawObject* before_obj = before.At(i);
    RawObject* after_obj = after.At(i);

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
    if (before_obj->IsVMHeapObject()) {
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

#if defined(HASH_IN_OBJECT_HEADER)
    Object::SetCachedHash(after_obj, Object::GetCachedHash(before_obj));
#else
    // Forward the identity hash too if it has one.
    intptr_t hash = heap->GetHash(before_obj);
    if (hash != 0) {
      ASSERT(heap->GetHash(after_obj) == 0);
      heap->SetHash(after_obj, hash);
    }
#endif
  }

  {
    // Follow forwarding pointers.

    // Clear the store buffer; will be rebuilt as we forward the heap.
    isolate->PrepareForGC();  // Have all threads flush their store buffers.
    isolate->store_buffer()->Reset();  // Drop all store buffers.

    // C++ pointers
    ForwardPointersVisitor pointer_visitor(thread);
    isolate->VisitObjectPointers(&pointer_visitor, true);

    // Weak persistent handles.
    ForwardHeapPointersHandleVisitor handle_visitor;
    isolate->VisitWeakPersistentHandles(&handle_visitor);

    //   Heap pointers (may require updating the remembered set)
    {
      WritableCodeLiteralsScope writable_code(heap);
      ForwardHeapPointersVisitor object_visitor(&pointer_visitor);
      heap->VisitObjects(&object_visitor);
      pointer_visitor.VisitingObject(NULL);
    }

#if !defined(PRODUCT)
    tds.SetNumArguments(2);
    tds.FormatArgument(0, "Remapped objects", "%" Pd, before.Length());
    tds.FormatArgument(1, "Remapped references", "%" Pd,
                       pointer_visitor.count() + handle_visitor.count());
#endif
  }

#if defined(DEBUG)
  for (intptr_t i = 0; i < before.Length(); i++) {
    ASSERT(before.At(i) == after.At(i));
  }
#endif
}

}  // namespace dart
