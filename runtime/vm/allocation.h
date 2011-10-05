// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ALLOCATION_H_
#define VM_ALLOCATION_H_

#include "vm/assert.h"

namespace dart {

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
  // TODO(5411081): Add DISALLOW_COPY_AND_ASSIGN(ValueObject) once the mac
  // build issue is resolved.
};


// Stack resources subclass from this base class. The VM will ensure that the
// destructors of these objects are called before the stack is unwound past the
// objects location on the stack. Use stack resource objects if objects
// need to be destroyed even in the case of exceptions when a Longjump is done
// to a stack frame above the frame where these objects were allocated.
class StackResource {
 public:
  StackResource();
  virtual ~StackResource();

  // The delete operator should be private instead of public, but unfortunately
  // the compiler complains when compiling the destructors for subclasses.
  void operator delete(void* pointer) { UNREACHABLE(); }

 private:
  StackResource* previous_;

  void* operator new(uword size);

  DISALLOW_COPY_AND_ASSIGN(StackResource);
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
  // It would be ideal if the destructor method could be made private,
  // but the g++ compiler complains when this is subclassed.
  virtual ~ZoneAllocated();

  // Implicitly allocate the object in the current zone.
  void* operator new(uword size);

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
