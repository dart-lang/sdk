// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ALLOCATION_H_
#define RUNTIME_VM_ALLOCATION_H_

#include "platform/allocation.h"
#include "platform/assert.h"
#include "vm/globals.h"

namespace dart {

// Forward declarations.
class ThreadState;
class Zone;

// Stack resources subclass from this base class. The VM will ensure that the
// destructors of these objects are called before the stack is unwound past the
// objects location on the stack. Use stack resource objects if objects
// need to be destroyed even in the case of exceptions when a Longjump is done
// to a stack frame above the frame where these objects were allocated.
class StackResource {
 public:
  explicit StackResource(ThreadState* thread) : thread_(NULL), previous_(NULL) {
    Init(thread);
  }

  virtual ~StackResource();

  // The thread that owns this resource.
  ThreadState* thread() const { return thread_; }

  // Destroy stack resources of thread until top exit frame.
  static void Unwind(ThreadState* thread) { UnwindAbove(thread, NULL); }
  // Destroy stack resources of thread above new_top, exclusive.
  static void UnwindAbove(ThreadState* thread, StackResource* new_top);

 private:
  void Init(ThreadState* thread);

  ThreadState* thread_;
  StackResource* previous_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(StackResource);
};

// Zone allocated objects cannot be individually deallocated, but have
// to rely on the destructor of Zone which is called when the Zone
// goes out of scope to reclaim memory.
class ZoneAllocated {
 public:
  ZoneAllocated() {}

  // Implicitly allocate the object in the current zone.
  void* operator new(size_t size);

  // Allocate the object in the given zone, which must be the current zone.
  void* operator new(size_t size, Zone* zone);

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

#endif  // RUNTIME_VM_ALLOCATION_H_
