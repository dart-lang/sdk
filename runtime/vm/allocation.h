// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ALLOCATION_H_
#define VM_ALLOCATION_H_

#include "platform/assert.h"
#include "vm/base_isolate.h"
#include "vm/globals.h"
#include "vm/thread.h"

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
  // DEPRECATED: Use Thread-based interface. During migration, this defaults
  // to using the mutator thread (which must also be the current thread).
  explicit StackResource(Isolate* isolate) : thread_(NULL), previous_(NULL) {
    Init((isolate == NULL) ?
        NULL : reinterpret_cast<BaseIsolate*>(isolate)->mutator_thread_);
  }

  explicit StackResource(Thread* thread) : thread_(NULL), previous_(NULL) {
    Init(thread);
  }

  virtual ~StackResource() {
    if (thread_ != NULL) {
      StackResource* top = thread_->top_resource();
      ASSERT(top == this);
      thread_->set_top_resource(previous_);
    }
#if defined(DEBUG)
    if (thread_ != NULL) {
      ASSERT(Thread::Current() == thread_);
      BaseIsolate::AssertCurrent(reinterpret_cast<BaseIsolate*>(isolate()));
    }
#endif
  }

  // Convenient access to the isolate of the thread of this resource.
  Isolate* isolate() const {
    return thread_ == NULL ? NULL : thread_->isolate();
  }

  // The thread that owns this resource.
  Thread* thread() const { return thread_; }

  // Destroy stack resources of thread until top exit frame.
  static void Unwind(Thread* thread) { UnwindAbove(thread, NULL); }
  // Destroy stack resources of thread above new_top, exclusive.
  static void UnwindAbove(Thread* thread, StackResource* new_top);

 private:
  void Init(Thread* thread) {
    // We can only have longjumps and exceptions when there is a current
    // thread and isolate.  If there is no current thread, we don't need to
    // protect this case.
    // TODO(23807): Eliminate this special case.
    if (thread != NULL) {
      ASSERT(Thread::Current() == thread);
      thread_ = thread;
      previous_ = thread_->top_resource();
      ASSERT((previous_ == NULL) || (previous_->thread_ == thread));
      thread_->set_top_resource(this);
    }
  }

  Thread* thread_;
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

  // Allocate the object in the given zone, which must be the current zone.
  void* operator new(uword size, Zone* zone);

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



// Within a NoSafepointScope, the thread must not reach any safepoint. Used
// around code that manipulates raw object pointers directly without handles.
#if defined(DEBUG)
class NoSafepointScope : public StackResource {
 public:
  NoSafepointScope();
  ~NoSafepointScope();
 private:
  DISALLOW_COPY_AND_ASSIGN(NoSafepointScope);
};
#else  // defined(DEBUG)
class NoSafepointScope : public ValueObject {
 public:
  NoSafepointScope() {}
 private:
  DISALLOW_COPY_AND_ASSIGN(NoSafepointScope);
};
#endif  // defined(DEBUG)

}  // namespace dart

#endif  // VM_ALLOCATION_H_
