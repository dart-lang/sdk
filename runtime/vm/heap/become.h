// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_BECOME_H_
#define RUNTIME_VM_HEAP_BECOME_H_

#include "platform/atomic.h"
#include "platform/growable_array.h"
#include "vm/allocation.h"
#include "vm/raw_object.h"

namespace dart {

class Array;

// Objects that are a source in a become are transformed into forwarding
// corpses pointing to the corresponding target. Forwarding corpses have the
// same heap sizes as the source object to ensure the heap remains walkable.
// If the heap sizes is small enough to be encoded in the size field of the
// header, a forwarding corpse consists only of a header and the target pointer.
// If the heap size is too big to be encoded in the header's size field, the
// word after the target pointer contains the size.  This is the same
// representation as a FreeListElement.
class ForwardingCorpse {
 public:
  ObjectPtr target() const { return target_; }
  void set_target(ObjectPtr target) { target_ = target; }

  intptr_t HeapSize() { return HeapSize(tags_); }
  intptr_t HeapSize(uword tags) {
    intptr_t size = UntaggedObject::SizeTag::decode(tags);
    if (size != 0) return size;
    return *SizeAddress();
  }

  static ForwardingCorpse* AsForwarder(uword addr, intptr_t size);

  static void Init();

  // Used to allocate class for forwarding corpses in Object::InitOnce.
  class FakeInstance {
   public:
    FakeInstance() {}
    static cpp_vtable vtable() { return 0; }
    static intptr_t InstanceSize() { return 0; }
    static intptr_t NextFieldOffset() { return -kWordSize; }
    static const ClassId kClassId = kForwardingCorpse;
    static bool IsInstance() { return true; }

   private:
    DISALLOW_ALLOCATION();
    DISALLOW_COPY_AND_ASSIGN(FakeInstance);
  };

 private:
  // This layout mirrors the layout of UntaggedObject.
  RelaxedAtomic<uword> tags_;
  RelaxedAtomic<ObjectPtr> target_;

  // Returns the address of the embedded size.
  intptr_t* SizeAddress() const {
    uword addr = reinterpret_cast<uword>(&target_) + kWordSize;
    return reinterpret_cast<intptr_t*>(addr);
  }

  // ForwardingCorpses cannot be allocated. Instead references to them are
  // created using the AsForwarder factory method.
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ForwardingCorpse);
};

// Forward/exchange object identity within pairs of objects.
//
// Forward: Redirects all pointers to each 'before' object to the corresponding
// 'after' object. Every 'before' object is guaranteed to be unreachable after
// the operation. The identity hash of the 'before' object is retained.
//
// This is useful for atomically applying behavior and schema changes, which can
// be done by allocating fresh objects with the new schema and forwarding the
// identity of the old objects to the new objects.
//
// Exchange: Redirect all pointers to each 'before' object to the corresponding
// 'after' object and vice versa. Both objects remain reachable after the
// operation.
//
// This is useful for implementing certain types of proxies. For example, an
// infrequently accessed object may be written to disk and swapped with a
// so-called "husk", and swapped back when it is later accessed.
//
// This operation is named 'become' after its original in Smalltalk:
//   x become: y             "exchange identity for one pair"
//   x becomeForward: y      "forward identity for one pair"
//   #(x ...) elementsExchangeIdentityWith: #(y ...)
//   #(x ...) elementsForwardIdentityTo: #(y ...)
class Become {
 public:
  Become();
  ~Become();

  void Add(const Object& before, const Object& after);
  void Forward();
  void Exchange() { UNIMPLEMENTED(); }

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Convert and instance object into a dummy object,
  // making the instance independent of its class.
  // (used for morphic instances during reload).
  static void MakeDummyObject(const Instance& instance);

  // Update any references pointing to forwarding objects to point the
  // forwarding objects' targets.
  static void FollowForwardingPointers(Thread* thread);

 private:
  MallocGrowableArray<ObjectPtr> pointers_;
  DISALLOW_COPY_AND_ASSIGN(Become);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_BECOME_H_
