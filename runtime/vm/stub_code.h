// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STUB_CODE_H_
#define RUNTIME_VM_STUB_CODE_H_

#include "vm/allocation.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/object.h"

namespace dart {

// Forward declarations.
class Code;
class Isolate;
class ObjectPointerVisitor;
class RawCode;
class SnapshotReader;
class SnapshotWriter;

// List of stubs created in the VM isolate, these stubs are shared by different
// isolates running in this dart process.
#if !defined(TARGET_ARCH_DBC)
#define VM_STUB_CODE_LIST(V)                                                   \
  V(GetCStackPointer)                                                          \
  V(JumpToFrame)                                                               \
  V(RunExceptionHandler)                                                       \
  V(DeoptForRewind)                                                            \
  V(WriteBarrier)                                                              \
  V(WriteBarrierWrappers)                                                      \
  V(ArrayWriteBarrier)                                                         \
  V(PrintStopMessage)                                                          \
  V(AllocateArray)                                                             \
  V(AllocateContext)                                                           \
  V(CallToRuntime)                                                             \
  V(LazyCompile)                                                               \
  V(InterpretCall)                                                             \
  V(CallBootstrapNative)                                                       \
  V(CallNoScopeNative)                                                         \
  V(CallAutoScopeNative)                                                       \
  V(FixCallersTarget)                                                          \
  V(CallStaticFunction)                                                        \
  V(OptimizeFunction)                                                          \
  V(InvokeDartCode)                                                            \
  V(InvokeDartCodeFromBytecode)                                                \
  V(DebugStepCheck)                                                            \
  V(UnlinkedCall)                                                              \
  V(MonomorphicMiss)                                                           \
  V(SingleTargetCall)                                                          \
  V(ICCallThroughFunction)                                                     \
  V(ICCallThroughCode)                                                         \
  V(MegamorphicCall)                                                           \
  V(FixAllocationStubTarget)                                                   \
  V(Deoptimize)                                                                \
  V(DeoptimizeLazyFromReturn)                                                  \
  V(DeoptimizeLazyFromThrow)                                                   \
  V(UnoptimizedIdenticalWithNumberCheck)                                       \
  V(OptimizedIdenticalWithNumberCheck)                                         \
  V(ICCallBreakpoint)                                                          \
  V(RuntimeCallBreakpoint)                                                     \
  V(OneArgCheckInlineCache)                                                    \
  V(TwoArgsCheckInlineCache)                                                   \
  V(SmiAddInlineCache)                                                         \
  V(SmiSubInlineCache)                                                         \
  V(SmiEqualInlineCache)                                                       \
  V(OneArgOptimizedCheckInlineCache)                                           \
  V(TwoArgsOptimizedCheckInlineCache)                                          \
  V(ZeroArgsUnoptimizedStaticCall)                                             \
  V(OneArgUnoptimizedStaticCall)                                               \
  V(TwoArgsUnoptimizedStaticCall)                                              \
  V(Subtype1TestCache)                                                         \
  V(Subtype2TestCache)                                                         \
  V(Subtype4TestCache)                                                         \
  V(Subtype6TestCache)                                                         \
  V(DefaultTypeTest)                                                           \
  V(TopTypeTypeTest)                                                           \
  V(TypeRefTypeTest)                                                           \
  V(UnreachableTypeTest)                                                       \
  V(SlowTypeTest)                                                              \
  V(LazySpecializeTypeTest)                                                    \
  V(CallClosureNoSuchMethod)                                                   \
  V(FrameAwaitingMaterialization)                                              \
  V(AsynchronousGapMarker)                                                     \
  V(NullErrorSharedWithFPURegs)                                                \
  V(NullErrorSharedWithoutFPURegs)                                             \
  V(StackOverflowSharedWithFPURegs)                                            \
  V(StackOverflowSharedWithoutFPURegs)                                         \
  V(OneArgCheckInlineCacheWithExactnessCheck)                                  \
  V(OneArgOptimizedCheckInlineCacheWithExactnessCheck)

#else
#define VM_STUB_CODE_LIST(V)                                                   \
  V(LazyCompile)                                                               \
  V(OptimizeFunction)                                                          \
  V(CallClosureNoSuchMethod)                                                   \
  V(RunExceptionHandler)                                                       \
  V(DeoptForRewind)                                                            \
  V(FixCallersTarget)                                                          \
  V(Deoptimize)                                                                \
  V(DeoptimizeLazyFromReturn)                                                  \
  V(DeoptimizeLazyFromThrow)                                                   \
  V(DefaultTypeTest)                                                           \
  V(TopTypeTypeTest)                                                           \
  V(TypeRefTypeTest)                                                           \
  V(UnreachableTypeTest)                                                       \
  V(SlowTypeTest)                                                              \
  V(LazySpecializeTypeTest)                                                    \
  V(FrameAwaitingMaterialization)                                              \
  V(AsynchronousGapMarker)                                                     \
  V(InvokeDartCodeFromBytecode)                                                \
  V(InterpretCall)

#endif  // !defined(TARGET_ARCH_DBC)

// Is it permitted for the stubs above to refer to Object::null(), which is
// allocated in the VM isolate and shared across all isolates.
// However, in cases where a simple GC-safe placeholder is needed on the stack,
// using Smi 0 instead of Object::null() is slightly more efficient, since a Smi
// does not require relocation.

// class StubCode is used to maintain the lifecycle of stubs.
class StubCode : public AllStatic {
 public:
  // Generate all stubs which are shared across all isolates, this is done
  // only once and the stub code resides in the vm_isolate heap.
  static void Init();

  static void Cleanup();
  static void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Returns true if stub code has been initialized.
  static bool HasBeenInitialized();

  // Check if specified pc is in the dart invocation stub used for
  // transitioning into dart code.
  static bool InInvocationStub(uword pc, bool is_interpreted_frame);

  // Check if the specified pc is in the jump to frame stub.
  static bool InJumpToFrameStub(uword pc);

  // Returns NULL if no stub found.
  static const char* NameOfStub(uword entry_point);

// Define the shared stub code accessors.
#define STUB_CODE_ACCESSOR(name)                                               \
  static const Code& name() { return *entries_[k##name##Index]; }              \
  static intptr_t name##Size() { return name().Size(); }
  VM_STUB_CODE_LIST(STUB_CODE_ACCESSOR);
#undef STUB_CODE_ACCESSOR

  static RawCode* GetAllocationStubForClass(const Class& cls);

#if !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)
  static RawCode* GetBuildMethodExtractorStub(ObjectPoolBuilder* pool);
  static void GenerateBuildMethodExtractorStub(compiler::Assembler* assembler);
#endif

  static const Code& UnoptimizedStaticCallEntry(intptr_t num_args_tested);

  static const intptr_t kNoInstantiator = 0;
  static const intptr_t kInstantiationSizeInWords = 3;

  static const Code& EntryAt(intptr_t index) { return *entries_[index]; }
  static void EntryAtPut(intptr_t index, Code* entry) {
    ASSERT(entry->IsReadOnlyHandle());
    ASSERT(entries_[index] == nullptr);
    entries_[index] = entry;
  }
  static intptr_t NumEntries() { return kNumStubEntries; }

#if !defined(DART_PRECOMPILED_RUNTIME)
#define GENERATE_STUB(name)                                                    \
  static RawCode* BuildIsolateSpecific##name##Stub(ObjectPoolBuilder* opw) {   \
    return StubCode::Generate("_iso_stub_" #name, opw,                         \
                              StubCode::Generate##name##Stub);                 \
  }
  VM_STUB_CODE_LIST(GENERATE_STUB);
#undef GENERATE_STUB
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

 private:
  friend class MegamorphicCacheTable;

  enum {
#define STUB_CODE_ENTRY(name) k##name##Index,
    VM_STUB_CODE_LIST(STUB_CODE_ENTRY)
#undef STUB_CODE_ENTRY
        kNumStubEntries
  };

  static Code* entries_[kNumStubEntries];

#if !defined(DART_PRECOMPILED_RUNTIME)
#define STUB_CODE_GENERATE(name)                                               \
  static void Generate##name##Stub(compiler::Assembler* assembler);
  VM_STUB_CODE_LIST(STUB_CODE_GENERATE)
#undef STUB_CODE_GENERATE

  // Generate the stub and finalize the generated code into the stub
  // code executable area.
  static RawCode* Generate(
      const char* name,
      ObjectPoolBuilder* object_pool_builder,
      void (*GenerateStub)(compiler::Assembler* assembler));

  static void GenerateSharedStub(compiler::Assembler* assembler,
                                 bool save_fpu_registers,
                                 const RuntimeEntry* target,
                                 intptr_t self_code_stub_offset_from_thread,
                                 bool allow_return);

  static void GenerateMegamorphicMissStub(compiler::Assembler* assembler);
  static void GenerateAllocationStubForClass(compiler::Assembler* assembler,
                                             const Class& cls);
  static void GenerateNArgsCheckInlineCacheStub(
      compiler::Assembler* assembler,
      intptr_t num_args,
      const RuntimeEntry& handle_ic_miss,
      Token::Kind kind,
      bool optimized = false,
      bool exactness_check = false);
  static void GenerateUsageCounterIncrement(compiler::Assembler* assembler,
                                            Register temp_reg);
  static void GenerateOptimizedUsageCounterIncrement(
      compiler::Assembler* assembler);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};

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

#endif  // RUNTIME_VM_STUB_CODE_H_
