// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_STUB_CODE_COMPILER_H_
#define RUNTIME_VM_COMPILER_STUB_CODE_COMPILER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <functional>

#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/constants.h"
#include "vm/growable_array.h"
#include "vm/stub_code_list.h"
#include "vm/tagged_pointer.h"

namespace dart {

// Forward declarations.
class Code;

namespace compiler {

// Forward declarations.
class Assembler;

// Represents an unresolved PC-relative Call/TailCall.
class UnresolvedPcRelativeCall : public ZoneAllocated {
 public:
  UnresolvedPcRelativeCall(intptr_t offset,
                           const dart::Code& target,
                           bool is_tail_call)
      : offset_(offset), target_(target), is_tail_call_(is_tail_call) {}

  intptr_t offset() const { return offset_; }
  const dart::Code& target() const { return target_; }
  bool is_tail_call() const { return is_tail_call_; }

 private:
  const intptr_t offset_;
  const dart::Code& target_;
  const bool is_tail_call_;
};

using UnresolvedPcRelativeCalls = GrowableArray<UnresolvedPcRelativeCall*>;

class StubCodeCompiler {
 public:
  explicit StubCodeCompiler(Assembler* assembler_) : assembler(assembler_) {}

  Assembler* assembler;

#if !defined(TARGET_ARCH_IA32)
  void GenerateBuildMethodExtractorStub(const Code& closure_allocation_stub,
                                        const Code& context_allocation_stub,
                                        bool generic);
#endif

  void EnsureIsNewOrRemembered(bool preserve_registers = true);
  static ArrayPtr BuildStaticCallsTable(
      Zone* zone,
      compiler::UnresolvedPcRelativeCalls* unresolved_calls);

#define STUB_CODE_GENERATE(name) void Generate##name##Stub();
  VM_STUB_CODE_LIST(STUB_CODE_GENERATE)
#undef STUB_CODE_GENERATE

  void GenerateAllocationStubForClass(
      UnresolvedPcRelativeCalls* unresolved_calls,
      const Class& cls,
      const dart::Code& allocate_object,
      const dart::Code& allocat_object_parametrized);

  enum Optimized {
    kUnoptimized,
    kOptimized,
  };
  enum CallType {
    kInstanceCall,
    kStaticCall,
  };
  enum Exactness {
    kCheckExactness,
    kIgnoreExactness,
  };
  void GenerateNArgsCheckInlineCacheStub(intptr_t num_args,
                                         const RuntimeEntry& handle_ic_miss,
                                         Token::Kind kind,
                                         Optimized optimized,
                                         CallType type,
                                         Exactness exactness);
  void GenerateNArgsCheckInlineCacheStubForEntryKind(
      intptr_t num_args,
      const RuntimeEntry& handle_ic_miss,
      Token::Kind kind,
      Optimized optimized,
      CallType type,
      Exactness exactness,
      CodeEntryKind entry_kind);
  void GenerateUsageCounterIncrement(Register temp_reg);
  void GenerateOptimizedUsageCounterIncrement();

  // Calculates the offset (in words) from FP to the provided [cpu_register].
  //
  // Assumes
  //   * all [kDartAvailableCpuRegs] followed by saved-PC, saved-FP were
  //     pushed on the stack
  //   * [cpu_register] is in [kDartAvailableCpuRegs]
  //
  // The intended use of this function is to find registers on the stack which
  // were spilled in the
  // `StubCode::*<stub-name>Shared{With,Without}FpuRegsStub()`
  static intptr_t WordOffsetFromFpToCpuRegister(Register cpu_register);

 private:
  // Common function for generating InitLateStaticField and
  // InitLateFinalStaticField stubs.
  void GenerateInitLateStaticFieldStub(bool is_final);

  // Common function for generating InitLateInstanceField and
  // InitLateFinalInstanceField stubs.
  void GenerateInitLateInstanceFieldStub(bool is_final);

  // Common function for generating Allocate<TypedData>Array stubs.
  void GenerateAllocateTypedDataArrayStub(intptr_t cid);

  void GenerateAllocateSmallRecordStub(intptr_t num_fields,
                                       bool has_named_fields);

  void GenerateSharedStubGeneric(bool save_fpu_registers,
                                 intptr_t self_code_stub_offset_from_thread,
                                 bool allow_return,
                                 std::function<void()> perform_runtime_call);

  // Generates shared slow path stub which saves registers and calls
  // [target] runtime entry.
  // If [store_runtime_result_in_result_register], then stub puts result into
  // SharedSlowPathStubABI::kResultReg.
  void GenerateSharedStub(bool save_fpu_registers,
                          const RuntimeEntry* target,
                          intptr_t self_code_stub_offset_from_thread,
                          bool allow_return,
                          bool store_runtime_result_in_result_register = false);

  void GenerateLateInitializationError(bool with_fpu_regs);

  void GenerateRangeError(bool with_fpu_regs);
  void GenerateWriteError(bool with_fpu_regs);

  void GenerateSuspendStub(bool call_suspend_function,
                           bool pass_type_arguments,
                           intptr_t suspend_entry_point_offset_in_thread,
                           intptr_t suspend_function_offset_in_object_store);
  void GenerateInitSuspendableFunctionStub(
      intptr_t init_entry_point_offset_in_thread,
      intptr_t init_function_offset_in_object_store);
  void GenerateReturnStub(intptr_t return_entry_point_offset_in_thread,
                          intptr_t return_function_offset_in_object_store,
                          intptr_t return_stub_offset_in_thread);

  void GenerateLoadFfiCallbackMetadataRuntimeFunction(uword function_index,
                                                      Register dst);

  DISALLOW_COPY_AND_ASSIGN(StubCodeCompiler);
};

}  // namespace compiler

enum DeoptStubKind { kLazyDeoptFromReturn, kLazyDeoptFromThrow, kEagerDeopt };

// Zap value used to indicate unused CODE_REG in deopt.
static constexpr uword kZapCodeReg = 0xf1f1f1f1;

// Zap value used to indicate unused return address in deopt.
static constexpr uword kZapReturnAddress = 0xe1e1e1e1;

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_STUB_CODE_COMPILER_H_
