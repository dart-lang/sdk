// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BECOME_H_
#define RUNTIME_VM_BECOME_H_

#include "vm/allocation.h"
#include "vm/raw_object.h"

namespace dart {

class Array;

// Objects that are a source in a become are tranformed into forwarding
// corpses pointing to the corresponding target. Forwarding corpses have the
// same heap sizes as the source object to ensure the heap remains walkable.
// If the heap sizes is small enough to be encoded in the size field of the
// header, a forwarding corpse consists only of a header and the target pointer.
// If the heap size is too big to be encoded in the header's size field, the
// word after the target pointer contains the size.  This is the same
// representation as a FreeListElement.
class ForwardingCorpse {
 public:
  RawObject* target() const { return target_; }
  void set_target(RawObject* target) { target_ = target; }

  intptr_t Size() {
    intptr_t size = RawObject::SizeTag::decode(tags_);
    if (size != 0) return size;
    return *SizeAddress();
  }

  static ForwardingCorpse* AsForwarder(uword addr, intptr_t size);

  static void InitOnce();

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
  // This layout mirrors the layout of RawObject.
  uint32_t tags_;
#if defined(HASH_IN_OBJECT_HEADER)
  uint32_t hash_;
#endif
  RawObject* target_;

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

// TODO(johnmccutchan): Refactor this class so that it is not all static and
// provides utility methods for building the mapping of before and after.
class Become : public AllStatic {
 public:
  // Smalltalk's one-way bulk become (Array>>#elementsForwardIdentityTo:).
  // Redirects all pointers to elements of 'before' to the corresponding element
  // in 'after'. Every element in 'before' is guaranteed to be not reachable.
  // Useful for atomically applying behavior and schema changes.
  static void ElementsForwardIdentity(const Array& before, const Array& after);

  // Convert and instance object into a dummy object,
  // making the instance independent of its class.
  // (used for morphic instances during reload).
  static void MakeDummyObject(const Instance& instance);

 private:
  static void CrashDump(RawObject* before_obj, RawObject* after_obj);
};

}  // namespace dart

#endif  // RUNTIME_VM_BECOME_H_
