// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SAFEPOINT_H_
#define RUNTIME_VM_SAFEPOINT_H_

#include "vm/globals.h"
#include "vm/lockers.h"
#include "vm/thread.h"

namespace dart {

// A stack based scope that can be used to perform an operation after getting
// all threads to a safepoint. At the end of the operation all the threads are
// resumed.
class SafepointOperationScope : public StackResource {
 public:
  explicit SafepointOperationScope(Thread* T);
  ~SafepointOperationScope();

 private:
  DISALLOW_COPY_AND_ASSIGN(SafepointOperationScope);
};

// Implements handling of safepoint operations for all threads in an Isolate.
class SafepointHandler {
 public:
  explicit SafepointHandler(Isolate* I);
  ~SafepointHandler();

  void EnterSafepointUsingLock(Thread* T);
  void ExitSafepointUsingLock(Thread* T);

  void BlockForSafepoint(Thread* T);

 private:
  void SafepointThreads(Thread* T);
  void ResumeThreads(Thread* T);

  Isolate* isolate() const { return isolate_; }
  Monitor* threads_lock() const { return isolate_->threads_lock(); }
  bool SafepointInProgress() const {
    ASSERT(threads_lock()->IsOwnedByCurrentThread());
    return ((safepoint_operation_count_ > 0) && (owner_ != NULL));
  }
  void SetSafepointInProgress(Thread* T) {
    ASSERT(threads_lock()->IsOwnedByCurrentThread());
    ASSERT(owner_ == NULL);
    ASSERT(safepoint_operation_count_ == 0);
    safepoint_operation_count_ = 1;
    owner_ = T;
  }
  void ResetSafepointInProgress(Thread* T) {
    ASSERT(threads_lock()->IsOwnedByCurrentThread());
    ASSERT(owner_ == T);
    ASSERT(safepoint_operation_count_ == 1);
    safepoint_operation_count_ = 0;
    owner_ = NULL;
  }
  int32_t safepoint_operation_count() const {
    ASSERT(threads_lock()->IsOwnedByCurrentThread());
    return safepoint_operation_count_;
  }
  void increment_safepoint_operation_count() {
    ASSERT(threads_lock()->IsOwnedByCurrentThread());
    ASSERT(safepoint_operation_count_ < kMaxInt32);
    safepoint_operation_count_ += 1;
  }
  void decrement_safepoint_operation_count() {
    ASSERT(threads_lock()->IsOwnedByCurrentThread());
    ASSERT(safepoint_operation_count_ > 0);
    safepoint_operation_count_ -= 1;
  }

  Isolate* isolate_;

  // Monitor used by thread initiating a safepoint operation to track threads
  // not at a safepoint and wait for these threads to reach a safepoint.
  Monitor* safepoint_lock_;
  int32_t number_threads_not_at_safepoint_;

  // Count that indicates if a safepoint operation is currently in progress
  // and also tracks the number of recursive safepoint operations on the
  // same thread.
  int32_t safepoint_operation_count_;

  // If a safepoint operation is currently in progress, this field contains
  // the thread that initiated the safepoint operation, otherwise it is NULL.
  Thread* owner_;

  friend class Isolate;
  friend class SafepointOperationScope;
  friend class HeapIterationScope;
};

/*
 * Set of StackResource classes to track thread execution state transitions:
 *
 * kThreadInGenerated transitioning to
 *   ==> kThreadInVM:
 *       - set_execution_state(kThreadInVM).
 *       - block if safepoint is requested.
 *   ==> kThreadInNative:
 *       - set_execution_state(kThreadInNative).
 *       - EnterSafepoint().
 *   ==> kThreadInBlockedState:
 *       - Invalid transition
 *
 * kThreadInVM transitioning to
 *   ==> kThreadInGenerated
 *       - set_execution_state(kThreadInGenerated).
 *   ==> kThreadInNative
 *       - set_execution_state(kThreadInNative).
 *       - EnterSafepoint.
 *   ==> kThreadInBlockedState
 *       - set_execution_state(kThreadInBlockedState).
 *       - EnterSafepoint.
 *
 * kThreadInNative transitioning to
 *   ==> kThreadInGenerated
 *       - ExitSafepoint.
 *       - set_execution_state(kThreadInGenerated).
 *   ==> kThreadInVM
 *       - ExitSafepoint.
 *       - set_execution_state(kThreadInVM).
 *   ==> kThreadInBlocked
 *       - Invalid transition.
 *
 * kThreadInBlocked transitioning to
 *   ==> kThreadInVM
 *       - ExitSafepoint.
 *       - set_execution_state(kThreadInVM).
 *   ==> kThreadInNative
 *       - Invalid transition.
 *   ==> kThreadInGenerated
 *       - Invalid transition.
 */
class TransitionSafepointState : public StackResource {
 public:
  explicit TransitionSafepointState(Thread* T) : StackResource(T) {}
  ~TransitionSafepointState() {}

  SafepointHandler* handler() const {
    ASSERT(thread()->isolate() != NULL);
    ASSERT(thread()->isolate()->safepoint_handler() != NULL);
    return thread()->isolate()->safepoint_handler();
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TransitionSafepointState);
};

// TransitionGeneratedToVM is used to transition the safepoint state of a
// thread from "running generated code" to "running vm code" and ensures
// that the state is reverted back to "running generated code" when
// exiting the scope/frame.
class TransitionGeneratedToVM : public TransitionSafepointState {
 public:
  explicit TransitionGeneratedToVM(Thread* T) : TransitionSafepointState(T) {
    ASSERT(T == Thread::Current());
    ASSERT(T->execution_state() == Thread::kThreadInGenerated);
    T->set_execution_state(Thread::kThreadInVM);
    // Fast check to see if a safepoint is requested or not.
    // We do the more expensive operation of blocking the thread
    // only if a safepoint is requested.
    if (T->IsSafepointRequested()) {
      handler()->BlockForSafepoint(T);
    }
  }

  ~TransitionGeneratedToVM() {
    ASSERT(thread()->execution_state() == Thread::kThreadInVM);
    thread()->set_execution_state(Thread::kThreadInGenerated);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TransitionGeneratedToVM);
};

// TransitionGeneratedToNative is used to transition the safepoint state of a
// thread from "running generated code" to "running native code" and ensures
// that the state is reverted back to "running generated code" when
// exiting the scope/frame.
class TransitionGeneratedToNative : public TransitionSafepointState {
 public:
  explicit TransitionGeneratedToNative(Thread* T)
      : TransitionSafepointState(T) {
    // Native code is considered to be at a safepoint and so we mark it
    // accordingly.
    ASSERT(T->execution_state() == Thread::kThreadInGenerated);
    T->set_execution_state(Thread::kThreadInNative);
    T->EnterSafepoint();
  }

  ~TransitionGeneratedToNative() {
    // We are returning to generated code and so we are not at a safepoint
    // anymore.
    ASSERT(thread()->execution_state() == Thread::kThreadInNative);
    thread()->ExitSafepoint();
    thread()->set_execution_state(Thread::kThreadInGenerated);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TransitionGeneratedToNative);
};

// TransitionVMToBlocked is used to transition the safepoint state of a
// thread from "running vm code" to "blocked on a monitor" and ensures
// that the state is reverted back to "running vm code" when
// exiting the scope/frame.
class TransitionVMToBlocked : public TransitionSafepointState {
 public:
  explicit TransitionVMToBlocked(Thread* T) : TransitionSafepointState(T) {
    // A thread blocked on a monitor is considered to be at a safepoint.
    ASSERT(T->execution_state() == Thread::kThreadInVM);
    T->set_execution_state(Thread::kThreadInBlockedState);
    T->EnterSafepoint();
  }

  ~TransitionVMToBlocked() {
    // We are returning to vm code and so we are not at a safepoint anymore.
    ASSERT(thread()->execution_state() == Thread::kThreadInBlockedState);
    thread()->ExitSafepoint();
    thread()->set_execution_state(Thread::kThreadInVM);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TransitionVMToBlocked);
};

// TransitionVMToNative is used to transition the safepoint state of a
// thread from "running vm code" to "running native code" and ensures
// that the state is reverted back to "running vm code" when
// exiting the scope/frame.
class TransitionVMToNative : public TransitionSafepointState {
 public:
  explicit TransitionVMToNative(Thread* T) : TransitionSafepointState(T) {
    // A thread running native code is considered to be at a safepoint.
    ASSERT(T->execution_state() == Thread::kThreadInVM);
    T->set_execution_state(Thread::kThreadInNative);
    T->EnterSafepoint();
  }

  ~TransitionVMToNative() {
    // We are returning to vm code and so we are not at a safepoint anymore.
    ASSERT(thread()->execution_state() == Thread::kThreadInNative);
    thread()->ExitSafepoint();
    thread()->set_execution_state(Thread::kThreadInVM);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TransitionVMToNative);
};

// TransitionVMToGenerated is used to transition the safepoint state of a
// thread from "running vm code" to "running generated code" and ensures
// that the state is reverted back to "running vm code" when
// exiting the scope/frame.
class TransitionVMToGenerated : public TransitionSafepointState {
 public:
  explicit TransitionVMToGenerated(Thread* T) : TransitionSafepointState(T) {
    ASSERT(T == Thread::Current());
    ASSERT(T->execution_state() == Thread::kThreadInVM);
    T->set_execution_state(Thread::kThreadInGenerated);
  }

  ~TransitionVMToGenerated() {
    ASSERT(thread()->execution_state() == Thread::kThreadInGenerated);
    thread()->set_execution_state(Thread::kThreadInVM);
    // Fast check to see if a safepoint is requested or not.
    // We do the more expensive operation of blocking the thread
    // only if a safepoint is requested.
    if (thread()->IsSafepointRequested()) {
      handler()->BlockForSafepoint(thread());
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TransitionVMToGenerated);
};

// TransitionNativeToVM is used to transition the safepoint state of a
// thread from "running native code" to "running vm code" and ensures
// that the state is reverted back to "running native code" when
// exiting the scope/frame.
class TransitionNativeToVM : public TransitionSafepointState {
 public:
  explicit TransitionNativeToVM(Thread* T) : TransitionSafepointState(T) {
    // We are about to execute vm code and so we are not at a safepoint anymore.
    ASSERT(T->execution_state() == Thread::kThreadInNative);
    T->ExitSafepoint();
    T->set_execution_state(Thread::kThreadInVM);
  }

  ~TransitionNativeToVM() {
    // We are returning to native code and so we are at a safepoint.
    ASSERT(thread()->execution_state() == Thread::kThreadInVM);
    thread()->set_execution_state(Thread::kThreadInNative);
    thread()->EnterSafepoint();
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(TransitionNativeToVM);
};

// TransitionToGenerated is used to transition the safepoint state of a
// thread from "running vm code" or "running native code" to
// "running generated code" and ensures that the state is reverted back
// to "running vm code" or "running native code" when exiting the
// scope/frame.
class TransitionToGenerated : public TransitionSafepointState {
 public:
  explicit TransitionToGenerated(Thread* T)
      : TransitionSafepointState(T), execution_state_(T->execution_state()) {
    ASSERT(T == Thread::Current());
    ASSERT((execution_state_ == Thread::kThreadInVM) ||
           (execution_state_ == Thread::kThreadInNative));
    if (execution_state_ == Thread::kThreadInNative) {
      T->ExitSafepoint();
    }
    T->set_execution_state(Thread::kThreadInGenerated);
  }

  ~TransitionToGenerated() {
    ASSERT(thread()->execution_state() == Thread::kThreadInGenerated);
    if (execution_state_ == Thread::kThreadInNative) {
      thread()->set_execution_state(Thread::kThreadInNative);
      thread()->EnterSafepoint();
    } else {
      ASSERT(execution_state_ == Thread::kThreadInVM);
      thread()->set_execution_state(Thread::kThreadInVM);
    }
  }

 private:
  uint32_t execution_state_;
  DISALLOW_COPY_AND_ASSIGN(TransitionToGenerated);
};

// TransitionToVM is used to transition the safepoint state of a
// thread from "running native code" to "running vm code"
// and ensures that the state is reverted back to "running native code"
// when exiting the scope/frame.
// This transition helper is mainly used in the error path of the
// Dart API implementations where we sometimes do not have an explicit
// transition set up.
class TransitionToVM : public TransitionSafepointState {
 public:
  explicit TransitionToVM(Thread* T)
      : TransitionSafepointState(T), execution_state_(T->execution_state()) {
    ASSERT(T == Thread::Current());
    ASSERT((execution_state_ == Thread::kThreadInVM) ||
           (execution_state_ == Thread::kThreadInNative));
    if (execution_state_ == Thread::kThreadInNative) {
      T->ExitSafepoint();
      T->set_execution_state(Thread::kThreadInVM);
    }
    ASSERT(T->execution_state() == Thread::kThreadInVM);
  }

  ~TransitionToVM() {
    ASSERT(thread()->execution_state() == Thread::kThreadInVM);
    if (execution_state_ == Thread::kThreadInNative) {
      thread()->set_execution_state(Thread::kThreadInNative);
      thread()->EnterSafepoint();
    }
  }

 private:
  uint32_t execution_state_;
  DISALLOW_COPY_AND_ASSIGN(TransitionToVM);
};

}  // namespace dart

#endif  // RUNTIME_VM_SAFEPOINT_H_
