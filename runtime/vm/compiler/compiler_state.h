// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_COMPILER_STATE_H_
#define RUNTIME_VM_COMPILER_COMPILER_STATE_H_

#include "vm/compiler/cha.h"
#include "vm/heap/safepoint.h"
#include "vm/thread.h"

namespace dart {

class LocalScope;
class LocalVariable;
class SlotCache;
class Slot;

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
class CompilerState : public ThreadStackResource {
 public:
  CompilerState(Thread* thread, bool is_aot)
      : ThreadStackResource(thread), cha_(thread), is_aot_(is_aot) {
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

  SlotCache* slot_cache() const { return slot_cache_; }
  void set_slot_cache(SlotCache* cache) { slot_cache_ = cache; }

  // Create a dummy list of local variables representing a context object
  // with the given number of captured variables and given ID.
  //
  // Used during bytecode to IL translation because AllocateContext and
  // CloneContext IL instructions need a list of local varaibles and bytecode
  // does not record this information.
  //
  // TODO(vegorov): create context classes for distinct context IDs and
  // populate them with slots without creating variables.
  // Beware that context_id is satured at 8-bits, so multiple contexts may
  // share id 255.
  const ZoneGrowableArray<const Slot*>& GetDummyContextSlots(
      intptr_t context_id,
      intptr_t num_context_slots);

  // Create a dummy LocalVariable that represents a captured local variable
  // at the given index in the context with given ID.
  //
  // Used during bytecode to IL translation because StoreInstanceField and
  // LoadField IL instructions need Slot, which can only be created from a
  // LocalVariable.
  //
  // This function returns the same variable when it is called with the
  // same index.
  //
  // TODO(vegorov): disambiguate slots for different context IDs.
  // Beware that context_id is satured at 8-bits, so multiple contexts may
  // share id 255.
  LocalVariable* GetDummyCapturedVariable(intptr_t context_id, intptr_t index);

  bool is_aot() const { return is_aot_; }

 private:
  CHA cha_;
  intptr_t deopt_id_ = 0;

  // Cache for Slot objects created during compilation (see slot.h).
  SlotCache* slot_cache_ = nullptr;

  // Caches for dummy LocalVariables and context Slots created during bytecode
  // to IL translation.
  ZoneGrowableArray<ZoneGrowableArray<const Slot*>*>* dummy_slots_ = nullptr;
  ZoneGrowableArray<LocalVariable*>* dummy_captured_vars_ = nullptr;

  bool is_aot_;

  CompilerState* previous_;
};

class DeoptIdScope : public ThreadStackResource {
 public:
  DeoptIdScope(Thread* thread, intptr_t deopt_id)
      : ThreadStackResource(thread),
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
class AssertNoDeoptIdsAllocatedScope : public ThreadStackResource {
 public:
  explicit AssertNoDeoptIdsAllocatedScope(Thread* thread)
      : ThreadStackResource(thread),
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
