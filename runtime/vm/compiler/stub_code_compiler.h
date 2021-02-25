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

class StubCodeCompiler : public AllStatic {
 public:
#if !defined(TARGET_ARCH_IA32)
  static void GenerateBuildMethodExtractorStub(
      Assembler* assembler,
      const Object& closure_allocation_stub,
      const Object& context_allocation_stub);
#endif

  static ArrayPtr BuildStaticCallsTable(
      Zone* zone,
      compiler::UnresolvedPcRelativeCalls* unresolved_calls);

#define STUB_CODE_GENERATE(name)                                               \
  static void Generate##name##Stub(Assembler* assembler);
  VM_STUB_CODE_LIST(STUB_CODE_GENERATE)
#undef STUB_CODE_GENERATE

  static void GenerateAllocationStubForClass(
      Assembler* assembler,
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
  static void GenerateNArgsCheckInlineCacheStub(
      Assembler* assembler,
      intptr_t num_args,
      const RuntimeEntry& handle_ic_miss,
      Token::Kind kind,
      Optimized optimized,
      CallType type,
      Exactness exactness);
  static void GenerateNArgsCheckInlineCacheStubForEntryKind(
      Assembler* assembler,
      intptr_t num_args,
      const RuntimeEntry& handle_ic_miss,
      Token::Kind kind,
      Optimized optimized,
      CallType type,
      Exactness exactness,
      CodeEntryKind entry_kind);
  static void GenerateUsageCounterIncrement(Assembler* assembler,
                                            Register temp_reg);
  static void GenerateOptimizedUsageCounterIncrement(Assembler* assembler);

#if defined(TARGET_ARCH_X64)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 10;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 217;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#elif defined(TARGET_ARCH_IA32)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 10;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 134;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 4;
#elif defined(TARGET_ARCH_ARM)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 12;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 140;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 4;
#elif defined(TARGET_ARCH_ARM64)
  static constexpr intptr_t kNativeCallbackTrampolineSize = 12;
  static constexpr intptr_t kNativeCallbackSharedStubSize = 268;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
#endif

  static void GenerateJITCallbackTrampolines(Assembler* assembler,
                                             intptr_t next_callback_id);

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
  // Common function for generating InitLateInstanceField and
  // InitLateFinalInstanceField stubs.
  static void GenerateInitLateInstanceFieldStub(Assembler* assembler,
                                                bool is_final);

  // Common function for generating Allocate<TypedData>Array stubs.
  static void GenerateAllocateTypedDataArrayStub(Assembler* assembler,
                                                 intptr_t cid);

  static void GenerateSharedStubGeneric(
      Assembler* assembler,
      bool save_fpu_registers,
      intptr_t self_code_stub_offset_from_thread,
      bool allow_return,
      std::function<void()> perform_runtime_call);

  // Generates shared slow path stub which saves registers and calls
  // [target] runtime entry.
  // If [store_runtime_result_in_result_register], then stub puts result into
  // SharedSlowPathStubABI::kResultReg.
  static void GenerateSharedStub(
      Assembler* assembler,
      bool save_fpu_registers,
      const RuntimeEntry* target,
      intptr_t self_code_stub_offset_from_thread,
      bool allow_return,
      bool store_runtime_result_in_result_register = false);

  static void GenerateLateInitializationError(Assembler* assembler,
                                              bool with_fpu_regs);

  static void GenerateRangeError(Assembler* assembler, bool with_fpu_regs);
};

}  // namespace compiler

enum DeoptStubKind { kLazyDeoptFromReturn, kLazyDeoptFromThrow, kEagerDeopt };

// Zap value used to indicate unused CODE_REG in deopt.
static const uword kZapCodeReg = 0xf1f1f1f1;

// Zap value used to indicate unused return address in deopt.
static const uword kZapReturnAddress = 0xe1e1e1e1;

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_STUB_CODE_COMPILER_H_
