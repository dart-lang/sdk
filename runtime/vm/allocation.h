// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ALLOCATION_H_
#define VM_ALLOCATION_H_

#include "platform/assert.h"
#include "vm/base_isolate.h"
#include "vm/globals.h"

namespace dart {

// Forward declarations.
class Isolate;

// Stack allocated objects subclass from this base class. Objects of this type
// cannot be allocated on either the C or object heaps. Destructors for objects
// of this type will not be run unless the stack is unwound through normal
// program control flow.
class ValueObject {
 public:
  ValueObject() { }
  ~ValueObject() { }

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ValueObject);
};


// Stack resources subclass from this base class. The VM will ensure that the
// destructors of these objects are called before the stack is unwound past the
// objects location on the stack. Use stack resource objects if objects
// need to be destroyed even in the case of exceptions when a Longjump is done
// to a stack frame above the frame where these objects were allocated.
class StackResource {
 public:
  explicit StackResource(Isolate* isolate)
      : isolate_(reinterpret_cast<BaseIsolate*>(isolate)), previous_(NULL) {
    // We can only have longjumps and exceptions when there is a current
    // isolate.  If there is no current isolate, we don't need to
    // protect this case.
    if (isolate_ != NULL) {
      previous_ = isolate_->top_resource();
      isolate_->set_top_resource(this);
    }
  }

  virtual ~StackResource() {
    if (isolate_ != NULL) {
      StackResource* top = isolate_->top_resource();
      ASSERT(top == this);
      isolate_->set_top_resource(previous_);
    }
#if defined(DEBUG)
    if (isolate_ != NULL) {
      BaseIsolate::AssertCurrent(isolate_);
    }
#endif
  }

  // We can only create StackResources with Isolates, so provide the original
  // isolate to the subclasses. The only reason we have a BaseIsolate in the
  // StackResource is to break the header include cycles.
  Isolate* isolate() const { return reinterpret_cast<Isolate*>(isolate_); }

 private:
  BaseIsolate* const isolate_;  // Current isolate for this stack resource.
  StackResource* previous_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(StackResource);
};


// Static allocated classes only contain static members and can never
// be instantiated in the heap or on the stack.
class AllStatic {
 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(AllStatic);
};


// Zone allocated objects cannot be individually deallocated, but have
// to rely on the destructor of Zone which is called when the Zone
// goes out of scope to reclaim memory.
class ZoneAllocated {
 public:
  ZoneAllocated() { }

  // Implicitly allocate the object in the current zone.
  void* operator new(uword size);

  // Implicitly allocate the object in the current zone given the current
  // isolate.
  void* operator new(uword size, BaseIsolate* isolate);

  // Ideally, the delete operator should be protected instead of
  // public, but unfortunately the compiler sometimes synthesizes
  // (unused) destructors for classes derived from ZoneObject, which
  // require the operator to be visible. MSVC requires the delete
  // operator to be public.

  // Disallow explicit deallocation of nodes. Nodes can only be
  // deallocated by invoking DeleteAll() on the zone they live in.
  void operator delete(void* pointer) { UNREACHABLE(); }

 private:
  DISALLOW_COPY_AND_ASSIGN(ZoneAllocated);
};

}  // namespace dart

#endif  // VM_ALLOCATION_H_
