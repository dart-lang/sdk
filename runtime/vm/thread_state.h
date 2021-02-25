// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_STATE_H_
#define RUNTIME_VM_THREAD_STATE_H_

#include "include/dart_api.h"
#include "vm/os_thread.h"

namespace dart {

class HandleScope;
class LongJumpScope;
class Zone;

// ThreadState is a container for auxiliary thread-local state: e.g. it
// owns a stack of Zones for allocation and a stack of StackResources
// for stack unwinding.
//
// Important: this class is shared between compiler and runtime and
// as such it should not expose any runtime internals due to layering
// restrictions.
class ThreadState : public BaseThread {
 public:
  // The currently executing thread, or NULL if not yet initialized.
  static ThreadState* Current() {
#if defined(HAS_C11_THREAD_LOCAL)
    return OSThread::CurrentVMThread();
#else
    BaseThread* thread = OSThread::GetCurrentTLS();
    if (thread == NULL || thread->is_os_thread()) {
      return NULL;
    }
    return static_cast<ThreadState*>(thread);
#endif
  }

  explicit ThreadState(bool is_os_thread);
  virtual ~ThreadState();

  // OSThread corresponding to this thread.
  OSThread* os_thread() const { return os_thread_; }
  void set_os_thread(OSThread* os_thread) { os_thread_ = os_thread; }

  // The topmost zone used for allocation in this thread.
  Zone* zone() const { return zone_; }

  bool ZoneIsOwnedByThread(Zone* zone) const;

  void IncrementMemoryCapacity(uintptr_t value) {
    current_zone_capacity_ += value;
  }

  void DecrementMemoryCapacity(uintptr_t value) {
    ASSERT(current_zone_capacity_ >= value);
    current_zone_capacity_ -= value;
  }

  uintptr_t current_zone_capacity() const { return current_zone_capacity_; }

  StackResource* top_resource() const { return top_resource_; }
  void set_top_resource(StackResource* value) { top_resource_ = value; }
  static intptr_t top_resource_offset() {
    return OFFSET_OF(ThreadState, top_resource_);
  }

  LongJumpScope* long_jump_base() const { return long_jump_base_; }
  void set_long_jump_base(LongJumpScope* value) { long_jump_base_ = value; }

  bool IsValidZoneHandle(Dart_Handle object) const;
  intptr_t CountZoneHandles() const;
  bool IsValidScopedHandle(Dart_Handle object) const;
  intptr_t CountScopedHandles() const;

  virtual bool MayAllocateHandles() = 0;

  HandleScope* top_handle_scope() const {
#if defined(DEBUG)
    return top_handle_scope_;
#else
    return 0;
#endif
  }

  void set_top_handle_scope(HandleScope* handle_scope) {
#if defined(DEBUG)
    top_handle_scope_ = handle_scope;
#endif
  }

 private:
  void set_zone(Zone* zone) { zone_ = zone; }

  OSThread* os_thread_ = nullptr;
  Zone* zone_ = nullptr;
  uintptr_t current_zone_capacity_ = 0;
  StackResource* top_resource_ = nullptr;
  LongJumpScope* long_jump_base_ = nullptr;

  // This field is only used in the DEBUG builds, but we don't exclude it
  // because it would cause RELEASE and DEBUG builds to have different
  // offsets for various Thread fields that are used from generated code.
  HandleScope* top_handle_scope_ = nullptr;

  friend class ApiZone;
  friend class StackZone;
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_STATE_H_
