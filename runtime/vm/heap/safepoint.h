// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_SAFEPOINT_H_
#define RUNTIME_VM_HEAP_SAFEPOINT_H_

#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/thread.h"
#include "vm/thread_registry.h"
#include "vm/thread_stack_resource.h"

namespace dart {

// A stack based scope that can be used to perform an operation after getting
// all threads to a safepoint. At the end of the operation all the threads are
// resumed.
class SafepointOperationScope : public ThreadStackResource {
 protected:
  SafepointOperationScope(Thread* T, SafepointLevel level);
  ~SafepointOperationScope();

 private:
  SafepointLevel level_;

  DISALLOW_COPY_AND_ASSIGN(SafepointOperationScope);
};

// Gets all mutators to a safepoint where GC is allowed.
class GcSafepointOperationScope : public SafepointOperationScope {
 public:
  explicit GcSafepointOperationScope(Thread* T)
      : SafepointOperationScope(T, SafepointLevel::kGC) {}
  ~GcSafepointOperationScope() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(GcSafepointOperationScope);
};

// Gets all mutators to a safepoint where GC and Deopt is allowed.
class DeoptSafepointOperationScope : public SafepointOperationScope {
 public:
  explicit DeoptSafepointOperationScope(Thread* T)
      : SafepointOperationScope(T, SafepointLevel::kGCAndDeopt) {}
  ~DeoptSafepointOperationScope() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(DeoptSafepointOperationScope);
};

// Gets all mutators to a safepoint where GC, Deopt and Reload is allowed.
class ReloadSafepointOperationScope : public SafepointOperationScope {
 public:
  explicit ReloadSafepointOperationScope(Thread* T)
      : SafepointOperationScope(T, SafepointLevel::kGCAndDeoptAndReload) {}
  ~ReloadSafepointOperationScope() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(ReloadSafepointOperationScope);
};

// A stack based scope that can be used to perform an operation after getting
// all threads to a safepoint. At the end of the operation all the threads are
// resumed. Allocations in the scope will force heap growth.
class ForceGrowthSafepointOperationScope : public ThreadStackResource {
 public:
  ForceGrowthSafepointOperationScope(Thread* T, SafepointLevel level);
  ~ForceGrowthSafepointOperationScope();

 private:
  SafepointLevel level_;
  bool current_growth_controller_state_;

  DISALLOW_COPY_AND_ASSIGN(ForceGrowthSafepointOperationScope);
};

// Implements handling of safepoint operations for all threads in an
// IsolateGroup.
class SafepointHandler {
 public:
  explicit SafepointHandler(IsolateGroup* I);
  ~SafepointHandler();

  void EnterSafepointUsingLock(Thread* T);
  void ExitSafepointUsingLock(Thread* T);
  void BlockForSafepoint(Thread* T);

  // The innermost safepoint operation this thread owns
  //
  // Returns `SafepointLevel::kNone` if the current thread doesn't own any
  // safepoint. Otherwise returns the innermost safepoint level of the current
  // thread.
  //
  // * Will return SafepointLevel::kDeoptAndGC for
  //
  //   DeoptSafepointOperationScope sp;
  //
  // * Will return SafepointLevel::kGC for
  //
  //   DeoptSafepointOperationScope sp1;
  //   GcSafepointOperationScope sp2;
  //
  SafepointLevel InnermostSafepointOperation(
      const Thread* current_thread) const;

  bool AnySafepointInProgressLocked() {
    for (intptr_t level = 0; level < SafepointLevel::kNumLevels; ++level) {
      if (handlers_[level]->SafepointInProgress()) {
        return true;
      }
    }
    return false;
  }

 private:
  class LevelHandler {
   public:
    LevelHandler(IsolateGroup* isolate_group, SafepointLevel level)
        : isolate_group_(isolate_group), level_(level) {}

    bool SafepointInProgress() const {
      ASSERT(threads_lock()->IsOwnedByCurrentThread());
      ASSERT((operation_count_ > 0) == (owner_ != nullptr));
      return ((operation_count_ > 0) && (owner_ != nullptr));
    }
    void SetSafepointInProgress(Thread* T) {
      ASSERT(threads_lock()->IsOwnedByCurrentThread());
      ASSERT(owner_ == nullptr);
      ASSERT(operation_count_ == 0);
      operation_count_ = 1;
      owner_ = T;
    }
    void ResetSafepointInProgress(Thread* T) {
      ASSERT(threads_lock()->IsOwnedByCurrentThread());
      ASSERT(owner_ == T);
      ASSERT(operation_count_ == 1);
      ASSERT(num_threads_not_parked_ == 0);
      operation_count_ = 0;
      owner_ = nullptr;
    }
    void NotifyWeAreParked(Thread* T);

    IsolateGroup* isolate_group() const { return isolate_group_; }
    Monitor* threads_lock() const {
      return isolate_group_->thread_registry()->threads_lock();
    }

   private:
    friend class SafepointHandler;

    // Helper methods for [SafepointThreads]
    void NotifyThreadsToGetToSafepointLevel(
        Thread* T,
        MallocGrowableArray<Dart_Port>* oob_isolates);
    void WaitUntilThreadsReachedSafepointLevel();

    // Helper methods for [ResumeThreads]
    void NotifyThreadsToContinue(Thread* T);

    IsolateGroup* isolate_group_;
    SafepointLevel level_;

    // Monitor used by thread initiating a safepoint operation to track threads
    // not at a safepoint and wait for these threads to reach a safepoint.
    Monitor parked_lock_;

    // If a safepoint operation is currently in progress, this field contains
    // the thread that initiated the safepoint operation, otherwise it is
    // nullptr.
    std::atomic<Thread*> owner_ = nullptr;

    // The number of nested safepoint operations currently held.
    std::atomic<int32_t> operation_count_ = 0;

    // Count the number of threads the currently in-progress safepoint operation
    // is waiting for to check-in.
    int32_t num_threads_not_parked_ = 0;
  };

  void SafepointThreads(Thread* T, SafepointLevel level);
  void ResumeThreads(Thread* T, SafepointLevel level);

  // Helper methods for [SafepointThreads]
  void AssertWeOwnLowerLevelSafepoints(Thread* T, SafepointLevel level);
  void AssertWeDoNotOwnLowerLevelSafepoints(Thread* T, SafepointLevel level);
  void AcquireLowerLevelSafepoints(Thread* T, SafepointLevel level);

  // Helper methods for [ResumeThreads]
  void ReleaseLowerLevelSafepoints(Thread* T, SafepointLevel level);

  void EnterSafepointLocked(Thread* T, MonitorLocker* tl, SafepointLevel level);
  void ExitSafepointLocked(Thread* T, MonitorLocker* tl, SafepointLevel level);

  IsolateGroup* isolate_group() const { return isolate_group_; }
  Monitor* threads_lock() const {
    return isolate_group_->thread_registry()->threads_lock();
  }

  IsolateGroup* isolate_group_;

  LevelHandler* handlers_[SafepointLevel::kNumLevels];

  friend class Isolate;
  friend class IsolateGroup;
  friend class SafepointOperationScope;
  friend class ForceGrowthSafepointOperationScope;
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
class TransitionSafepointState : public ThreadStackResource {
 public:
  explicit TransitionSafepointState(Thread* T) : ThreadStackResource(T) {}
  ~TransitionSafepointState() {}

  SafepointHandler* handler() const {
    ASSERT(thread()->isolate() != nullptr);
    ASSERT(thread()->isolate()->safepoint_handler() != nullptr);
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
      T->BlockForSafepoint();
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
    ASSERT(T->CanAcquireSafepointLocks());
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
    if (thread()->IsSafepointRequested()) {
      thread()->BlockForSafepoint();
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
    if (T->no_callback_scope_depth() == 0) {
      T->ExitSafepoint();
    }
    T->set_execution_state(Thread::kThreadInVM);
  }

  ~TransitionNativeToVM() {
    // We are returning to native code and so we are at a safepoint.
    ASSERT(thread()->execution_state() == Thread::kThreadInVM);
    thread()->set_execution_state(Thread::kThreadInNative);
    if (thread()->no_callback_scope_depth() == 0) {
      thread()->EnterSafepoint();
    }
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

// TransitionToNative is used to transition the safepoint state of a
// thread from "running VM code" to "running native code"
// and ensures that the state is reverted back to the initial state
// when exiting the scope/frame.
class TransitionToNative : public TransitionSafepointState {
 public:
  explicit TransitionToNative(Thread* T)
      : TransitionSafepointState(T), execution_state_(T->execution_state()) {
    ASSERT(T == Thread::Current());
    ASSERT((execution_state_ == Thread::kThreadInVM) ||
           (execution_state_ == Thread::kThreadInNative));
    if (execution_state_ == Thread::kThreadInVM) {
      T->set_execution_state(Thread::kThreadInNative);
      T->EnterSafepoint();
    }
    ASSERT(T->execution_state() == Thread::kThreadInNative);
  }

  ~TransitionToNative() {
    ASSERT(thread()->execution_state() == Thread::kThreadInNative);
    if (execution_state_ == Thread::kThreadInVM) {
      thread()->ExitSafepoint();
      thread()->set_execution_state(Thread::kThreadInVM);
    }
  }

 private:
  uint32_t execution_state_;
  DISALLOW_COPY_AND_ASSIGN(TransitionToNative);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_SAFEPOINT_H_
