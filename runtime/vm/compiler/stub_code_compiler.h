// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_STUB_CODE_COMPILER_H_
#define RUNTIME_VM_COMPILER_STUB_CODE_COMPILER_H_

#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/constants.h"
#include "vm/stub_code_list.h"

namespace dart {

namespace compiler {

// Forward declarations.
class Assembler;

class StubCodeCompiler : public AllStatic {
 public:
#if !defined(TARGET_ARCH_IA32)
  static void GenerateBuildMethodExtractorStub(
      Assembler* assembler,
      const Object& closure_allocation_stub,
      const Object& context_allocation_stub);
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
#define STUB_CODE_GENERATE(name)                                               \
  static void Generate##name##Stub(Assembler* assembler);
  VM_STUB_CODE_LIST(STUB_CODE_GENERATE)
#undef STUB_CODE_GENERATE

  static void GenerateMegamorphicCallMissStub(Assembler* assembler);
  static void GenerateAllocationStubForClass(Assembler* assembler,
                                             const Class& cls);

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
  static constexpr intptr_t kNativeCallbackSharedStubSize = 90;
  static constexpr intptr_t kNativeCallbackTrampolineStackDelta = 2;
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

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};

}  // namespace compiler

enum DeoptStubKind { kLazyDeoptFromReturn, kLazyDeoptFromThrow, kEagerDeopt };

// Invocation mode for TypeCheck runtime entry that describes
// where we are calling it from.
enum TypeCheckMode {
  // TypeCheck is invoked from LazySpecializeTypeTest stub.
  // It should replace stub on the type with a specialized version.
  kTypeCheckFromLazySpecializeStub,

  // TypeCheck is invoked from the SlowTypeTest stub.
  // This means that cache can be lazily created (if needed)
  // and dst_name can be fetched from the pool.
  kTypeCheckFromSlowStub,

  // TypeCheck is invoked from normal inline AssertAssignable.
  // Both cache and dst_name must be already populated.
  kTypeCheckFromInline
};

// Zap value used to indicate unused CODE_REG in deopt.
static const uword kZapCodeReg = 0xf1f1f1f1;

// Zap value used to indicate unused return address in deopt.
static const uword kZapReturnAddress = 0xe1e1e1e1;

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_STUB_CODE_COMPILER_H_
