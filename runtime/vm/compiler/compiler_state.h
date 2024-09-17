// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_COMPILER_STATE_H_
#define RUNTIME_VM_COMPILER_COMPILER_STATE_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/api/deopt_id.h"
#include "vm/compiler/cha.h"
#include "vm/heap/safepoint.h"
#include "vm/thread.h"
#include "vm/timer.h"

namespace dart {

class CompilerPass;
struct CompilerPassState;
class Function;
class LocalScope;
class LocalVariable;
class SlotCache;
class Slot;

enum class CompilerTracing {
  kOn,
  kOff,
};

struct FunctionPragmas : public ZoneAllocated {
  explicit FunctionPragmas(const Function& function);

  const Function& function;
  const bool unsafe_no_bounds_checks;
};

struct FunctionPragmasTrait {
  typedef FunctionPragmas* Value;
  typedef const Function* Key;
  typedef FunctionPragmas* Pair;

  static Key KeyOf(Pair kv) { return &kv->function; }
  static Value ValueOf(Pair kv) { return kv; }
  static inline uword Hash(Key key) { return key->Hash(); }
  static inline bool IsKeyEqual(Pair kv, Key key) {
    return (kv->function.ptr() == key->ptr());
  }
};
using CachedPragmasMap = ZoneDirectChainedHashMap<FunctionPragmasTrait>;

// Global compiler state attached to the thread.
class CompilerState : public ThreadStackResource {
 public:
  CompilerState(Thread* thread,
                bool is_aot,
                bool is_optimizing,
                CompilerTracing tracing = CompilerTracing::kOn)
      : ThreadStackResource(thread),
        cha_(thread),
        is_aot_(is_aot),
        is_optimizing_(is_optimizing),
        tracing_(tracing) {
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

  bool is_aot() const { return is_aot_; }

  bool is_optimizing() const { return is_optimizing_; }
  bool should_clone_fields() {
    return !is_aot() && (is_optimizing() || FLAG_force_clone_compiler_objects);
  }

  bool should_trace() const { return tracing_ == CompilerTracing::kOn; }

  static bool ShouldTrace() { return Current().should_trace(); }

  static CompilerTracing ShouldTrace(const Function& func);

  // Returns class Comparable<T> from dart:core.
  const Class& ComparableClass();

  // Returns _StringBase._interpolate
  const Function& StringBaseInterpolate();

  // Returns _StringBase._interpolateSingle
  const Function& StringBaseInterpolateSingle();

  const Function& TypedListGetFloat32();
  const Function& TypedListSetFloat32();
  const Function& TypedListGetFloat64();
  const Function& TypedListSetFloat64();
  const Function& TypedListGetFloat32x4();
  const Function& TypedListSetFloat32x4();
  const Function& TypedListGetInt32x4();
  const Function& TypedListSetInt32x4();
  const Function& TypedListGetFloat64x2();
  const Function& TypedListSetFloat64x2();

  const Class& ArrayClass();
  const Class& CompoundClass();
  const Class& StructClass();
  const Class& TypedDataClass();
  const Class& UnionClass();

  const Field& CompoundOffsetInBytesField();
  const Field& CompoundTypedDataBaseField();

  const Function* function() const { return function_; }

  void set_function(const Function& function) { function_ = &function; }
  void set_current_pass(const CompilerPass* pass,
                        const CompilerPassState* pass_state) {
    pass_ = pass;
    pass_state_ = pass_state;
  }

  const CompilerPass* pass() const { return pass_; }
  const CompilerPassState* pass_state() const { return pass_state_; }

  void ReportCrash();

  const FunctionPragmas& PragmasOf(const Function& function);

 private:
  const Class& TypedListClass();

  CHA cha_;
  intptr_t deopt_id_ = 0;

  // Cache for Slot objects created during compilation (see slot.h).
  SlotCache* slot_cache_ = nullptr;

  // Caches for dummy LocalVariables and context Slots.
  ZoneGrowableArray<ZoneGrowableArray<const Slot*>*>* dummy_slots_ = nullptr;
  ZoneGrowableArray<LocalVariable*>* dummy_captured_vars_ = nullptr;

  const bool is_aot_;
  const bool is_optimizing_;

  const CompilerTracing tracing_;

  // Lookup cache for various classes (to avoid polluting object store with
  // compiler specific classes).
  const Class* comparable_class_ = nullptr;
  const Function* interpolate_ = nullptr;
  const Function* interpolate_single_ = nullptr;
  const Class* typed_list_class_ = nullptr;
  const Class* array_class_ = nullptr;
  const Class* compound_class_ = nullptr;
  const Class* struct_class_ = nullptr;
  const Class* typed_data_class_ = nullptr;
  const Class* union_class_ = nullptr;
  const Field* compound_offset_in_bytes_field_ = nullptr;
  const Field* compound_typed_data_base_field_ = nullptr;
  const Function* typed_list_get_float32_ = nullptr;
  const Function* typed_list_set_float32_ = nullptr;
  const Function* typed_list_get_float64_ = nullptr;
  const Function* typed_list_set_float64_ = nullptr;
  const Function* typed_list_get_float32x4_ = nullptr;
  const Function* typed_list_set_float32x4_ = nullptr;
  const Function* typed_list_get_int32x4_ = nullptr;
  const Function* typed_list_set_int32x4_ = nullptr;
  const Function* typed_list_get_float64x2_ = nullptr;
  const Function* typed_list_set_float64x2_ = nullptr;

  const Function* function_ = nullptr;
  const CompilerPass* pass_ = nullptr;
  const CompilerPassState* pass_state_ = nullptr;
  CachedPragmasMap* cached_pragmas_ = nullptr;

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
