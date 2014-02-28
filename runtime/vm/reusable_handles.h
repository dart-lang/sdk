// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_REUSABLE_HANDLES_H_
#define VM_REUSABLE_HANDLES_H_

#include "vm/allocation.h"
#include "vm/handles.h"
#include "vm/object.h"

namespace dart {

// The class ReusableHandleScope is used in regions of the
// virtual machine where isolate specific reusable handles are used.
// This class asserts that we do not add code that will result in recursive
// uses of reusable handles.
// It is used as follows:
// {
//   ReusableHandleScope reused_handles(isolate);
//   ....
//   .....
//   code that uses isolate specific reusable handles.
//   Array& funcs = reused_handles.ArrayHandle();
//   ....
// }
#if defined(DEBUG)
class ReusableObjectHandleScope : public StackResource {
 public:
  explicit ReusableObjectHandleScope(Isolate* isolate)
      : StackResource(isolate), isolate_(isolate) {
    ASSERT(!isolate->reusable_handle_scope_active());
    isolate->set_reusable_handle_scope_active(true);
  }
  ReusableObjectHandleScope()
      : StackResource(Isolate::Current()), isolate_(Isolate::Current()) {
    ASSERT(!isolate()->reusable_handle_scope_active());
    isolate()->set_reusable_handle_scope_active(true);
  }
  ~ReusableObjectHandleScope() {
    ASSERT(isolate()->reusable_handle_scope_active());
    isolate()->set_reusable_handle_scope_active(false);
    Handle().raw_ = Object::null();
  }
  Object& Handle() const {
    ASSERT(isolate_->Object_handle_ != NULL);
    return *isolate_->Object_handle_;
  }

 private:
  Isolate* isolate_;
  DISALLOW_COPY_AND_ASSIGN(ReusableObjectHandleScope);
};


class ReusableHandleScope : public StackResource {
 public:
  explicit ReusableHandleScope(Isolate* isolate)
      : StackResource(isolate), isolate_(isolate) {
    ASSERT(!isolate->reusable_handle_scope_active());
    isolate->set_reusable_handle_scope_active(true);
  }
  ReusableHandleScope()
      : StackResource(Isolate::Current()), isolate_(Isolate::Current()) {
    ASSERT(!isolate()->reusable_handle_scope_active());
    isolate()->set_reusable_handle_scope_active(true);
  }
  ~ReusableHandleScope() {
    ASSERT(isolate()->reusable_handle_scope_active());
    isolate()->set_reusable_handle_scope_active(false);
#define CLEAR_REUSABLE_HANDLE(object)                                          \
    object##Handle().raw_ = Object::null();                                    \

    REUSABLE_HANDLE_LIST(CLEAR_REUSABLE_HANDLE);
  }

#define REUSABLE_HANDLE_ACCESSORS(object)                                      \
  object& object##Handle() const {                                             \
    ASSERT(isolate_->object##_handle_ != NULL);                                \
    return *isolate_->object##_handle_;                                        \
  }                                                                            \

  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_ACCESSORS)
#undef REUSABLE_HANDLE_ACCESSORS

 private:
  void ResetHandles();
  Isolate* isolate_;
  DISALLOW_COPY_AND_ASSIGN(ReusableHandleScope);
};
#else
class ReusableObjectHandleScope : public ValueObject {
 public:
  explicit ReusableObjectHandleScope(Isolate* isolate)
      : handle_(isolate->Object_handle_) {
  }
  ReusableObjectHandleScope() : handle_(Isolate::Current()->Object_handle_) {
  }
  ~ReusableObjectHandleScope() {
    handle_->raw_ = Object::null();
  }
  Object& Handle() const {
    ASSERT(handle_ != NULL);
    return *handle_;
  }

 private:
  Object* handle_;
  DISALLOW_COPY_AND_ASSIGN(ReusableObjectHandleScope);
};


class ReusableHandleScope : public ValueObject {
 public:
  explicit ReusableHandleScope(Isolate* isolate) : isolate_(isolate) {
  }
  ReusableHandleScope() : isolate_(Isolate::Current()) {
  }
  ~ReusableHandleScope() {
#define CLEAR_REUSABLE_HANDLE(object)                                          \
    object##Handle().raw_ = Object::null();                                    \

    REUSABLE_HANDLE_LIST(CLEAR_REUSABLE_HANDLE);
  }

#define REUSABLE_HANDLE_ACCESSORS(object)                                      \
  object& object##Handle() const {                                             \
    ASSERT(isolate_->object##_handle_ != NULL);                                \
    return *isolate_->object##_handle_;                                        \
  }                                                                            \

  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_ACCESSORS)
#undef REUSABLE_HANDLE_ACCESSORS

 private:
  void ResetHandles();
  Isolate* isolate_;
  DISALLOW_COPY_AND_ASSIGN(ReusableHandleScope);
};
#endif  // defined(DEBUG)

}  // namespace dart

#endif  // VM_REUSABLE_HANDLES_H_
