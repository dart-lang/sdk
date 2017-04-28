// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_REFERENCE_COUNTING_H_
#define RUNTIME_BIN_REFERENCE_COUNTING_H_

#include "vm/atomic.h"

namespace dart {
namespace bin {

// Forward declaration.
template <class Target>
class RefCntReleaseScope;

// Inherit from this class where instances of the derived class should be
// reference counted. Reference counts on instances are incremented and
// decremented explicitly with calls to Retain() and Release(). E.g.:
//
// class Foo : public ReferenceCounted<Foo> {
//  public:
//   Foo() : ReferenceCounted() {}
//   ...
// };
//
// void DoStuffWithAFoo() {
//   Foo* foo = new Foo();  // Reference count starts at 1, so no explicit
//                          // call to Retain is needed after allocation.
//   ...
//   foo->Release();
// }
template <class Derived>
class ReferenceCounted {
 public:
  ReferenceCounted() : ref_count_(1) {
#if defined(DEBUG)
    AtomicOperations::FetchAndIncrement(&instances_);
#endif  // defined(DEBUG)
  }

  virtual ~ReferenceCounted() {
    ASSERT(ref_count_ == 0);
#if defined(DEBUG)
    AtomicOperations::FetchAndDecrement(&instances_);
#endif  // defined(DEBUG)
  }

  void Retain() {
    intptr_t old = AtomicOperations::FetchAndIncrement(&ref_count_);
    ASSERT(old > 0);
  }

  void Release() {
    intptr_t old = AtomicOperations::FetchAndDecrement(&ref_count_);
    ASSERT(old > 0);
    if (old == 1) {
      delete static_cast<Derived*>(this);
    }
  }

#if defined(DEBUG)
  static intptr_t instances() { return instances_; }
#endif  // defined(DEBUG)

 private:
#if defined(DEBUG)
  static intptr_t instances_;
#endif  // defined(DEBUG)

  intptr_t ref_count_;

  // These are used only in the ASSERT below in RefCntReleaseScope.
  intptr_t ref_count() const { return ref_count_; }
  friend class RefCntReleaseScope<Derived>;
  DISALLOW_COPY_AND_ASSIGN(ReferenceCounted);
};

#if defined(DEBUG)
template <class Derived>
intptr_t ReferenceCounted<Derived>::instances_ = 0;
#endif

// Creates a scope at the end of which a reference counted object is
// Released. This is useful for reference counted objects received by the IO
// Service, which have already been Retained E.g.:
//
// CObject* Foo::FooRequest(const CObjectArray& request) {
//   Foo* foo = CObjectToFoo(request[0]);
//   RefCntReleaseScope<Foo> rs(foo);
//   ...
// }
template <class Target>
class RefCntReleaseScope {
 public:
  explicit RefCntReleaseScope(ReferenceCounted<Target>* t) : target_(t) {
    ASSERT(target_ != NULL);
    ASSERT(target_->ref_count() > 0);
  }
  ~RefCntReleaseScope() { target_->Release(); }

 private:
  ReferenceCounted<Target>* target_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(RefCntReleaseScope);
};

// Instances of RetainedPointer manage Retaining and Releasing reference counted
// objects. There are two ways to use it. First, it can be used as a field in
// a class, e.g.:
//
// class Foo {
//  private:
//   RetainedPointer<Bar> bar_;
//  public:
//   explicit Foo(Bar* b) : bar_(b) {}
// }
//
// In this case, b will be Retained in Foo's constructor, and Released
// automatically during Foo's destructor.
//
// RetainedPointer can also be used as a scope, as with RefCntReleaseScope,
// with the difference that entering the scope also Retains the pointer, e.g.:
//
// void RetainAndDoStuffWithFoo(Foo* foo) {
//   RetainedPointer<Foo> retained(foo);
//   ..
// }
//
// This Retains foo on entry and Releases foo at every exit from the scope.
//
// The underlying pointer can be accessed with the get() and set() methods.
// Overwriting a non-NULL pointer with set causes that pointer to be Released.
template <class Target>
class RetainedPointer {
 public:
  RetainedPointer() : target_(NULL) {}

  explicit RetainedPointer(ReferenceCounted<Target>* t) : target_(t) {
    if (target_ != NULL) {
      target_->Retain();
    }
  }

  ~RetainedPointer() {
    if (target_ != NULL) {
      target_->Release();
    }
  }

  void set(ReferenceCounted<Target>* t) {
    if (target_ != NULL) {
      target_->Release();
    }
    target_ = t;
    if (target_ != NULL) {
      target_->Retain();
    }
  }

  Target* get() const { return static_cast<Target*>(target_); }

 private:
  ReferenceCounted<Target>* target_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(RetainedPointer);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_REFERENCE_COUNTING_H_
