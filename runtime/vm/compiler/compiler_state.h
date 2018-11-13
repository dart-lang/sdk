// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_COMPILER_STATE_H_
#define RUNTIME_VM_COMPILER_COMPILER_STATE_H_

#include "vm/compiler/cha.h"
#include "vm/thread.h"

namespace dart {

// Deoptimization Id logic.
//
// Deoptimization ids are used to refer to deoptimization points, at which
// control can enter unoptimized code from the optimized version of the code.
//
// Note: any instruction that does a call has two deoptimization points,
// one before the call and one after the call - so that we could deoptimize
// to either before or after the call depending on whether the same call
// already occured in the optimized code (and potentially produced
// observable side-effects) or not.
//
// To simplify implementation we always allocate two deopt ids (one for before
// point and one for the after point).
class DeoptId : public AllStatic {
 public:
  static constexpr intptr_t kNone = -1;

  static inline intptr_t Next(intptr_t deopt_id) { return deopt_id + kStep; }

  static inline intptr_t ToDeoptAfter(intptr_t deopt_id) {
    ASSERT(IsDeoptBefore(deopt_id));
    return deopt_id + kAfterOffset;
  }

  static inline bool IsDeoptBefore(intptr_t deopt_id) {
    return (deopt_id % kStep) == kBeforeOffset;
  }

  static inline bool IsDeoptAfter(intptr_t deopt_id) {
    return (deopt_id % kStep) == kAfterOffset;
  }

 private:
  static constexpr intptr_t kStep = 2;
  static constexpr intptr_t kBeforeOffset = 0;
  static constexpr intptr_t kAfterOffset = 1;
};

// Global compiler state attached to the thread.
class CompilerState : public StackResource {
 public:
  explicit CompilerState(Thread* thread) : StackResource(thread), cha_(thread) {
    previous_ = thread->SetCompilerState(this);
  }

  ~CompilerState() {
    ASSERT(&thread()->compiler_state() == this);
    thread()->SetCompilerState(previous_);
  }

  CHA& cha() { return cha_; }

  intptr_t deopt_id() const { return deopt_id_; }
  void set_deopt_id(int value) {
    ASSERT(value >= 0);
    deopt_id_ = value;
  }

  intptr_t GetNextDeoptId() {
    ASSERT(deopt_id_ != DeoptId::kNone);
    const intptr_t id = deopt_id_;
    deopt_id_ = DeoptId::Next(deopt_id_);
    return id;
  }

  static CompilerState& Current() {
    return Thread::Current()->compiler_state();
  }

 private:
  CHA cha_;
  intptr_t deopt_id_ = 0;

  CompilerState* previous_;
};

class DeoptIdScope : public StackResource {
 public:
  DeoptIdScope(Thread* thread, intptr_t deopt_id)
      : StackResource(thread),
        prev_deopt_id_(thread->compiler_state().deopt_id()) {
    thread->compiler_state().set_deopt_id(deopt_id);
  }

  ~DeoptIdScope() { thread()->compiler_state().set_deopt_id(prev_deopt_id_); }

 private:
  const intptr_t prev_deopt_id_;

  DISALLOW_COPY_AND_ASSIGN(DeoptIdScope);
};

/// Ensures that there were no deopt id allocations during the lifetime of this
/// object.
class AssertNoDeoptIdsAllocatedScope : public StackResource {
 public:
  explicit AssertNoDeoptIdsAllocatedScope(Thread* thread)
      : StackResource(thread),
        prev_deopt_id_(thread->compiler_state().deopt_id()) {}

  ~AssertNoDeoptIdsAllocatedScope() {
    ASSERT(thread()->compiler_state().deopt_id() == prev_deopt_id_);
  }

 private:
  const intptr_t prev_deopt_id_;

  DISALLOW_COPY_AND_ASSIGN(AssertNoDeoptIdsAllocatedScope);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_COMPILER_STATE_H_
