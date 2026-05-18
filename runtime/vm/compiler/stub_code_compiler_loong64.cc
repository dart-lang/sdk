// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/stub_code_compiler.h"

namespace dart {
namespace compiler {

void StubCodeCompiler::EnsureIsNewOrRemembered() {}

void StubCodeCompiler::GenerateAllocateArrayStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateAllocateContextStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateAllocateMintSharedWithFPURegsStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateAllocateMintSharedWithoutFPURegsStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateAllocateObjectParameterizedStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateAllocateObjectSlowStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateAllocateObjectStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateArrayWriteBarrierStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateCallAutoScopeNativeStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateCallBootstrapNativeStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateCallClosureNoSuchMethodStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateCallNativeThroughSafepointStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateCallNoScopeNativeStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateCallStaticFunctionStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateCallToRuntimeStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateCloneContextStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateDebugStepCheckStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateDeoptForRewindStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateDeoptimizeLazyFromReturnStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateDeoptimizeLazyFromThrowStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateDeoptimizeStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateDispatchTableNullErrorStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateEnterSafepointStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateExitSafepointStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateFfiCallbackTrampolineStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateFfiCallTrampolineStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateFixAllocationStubTargetStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateFixCallersTargetStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateFixParameterizedAllocationStubTargetStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateICCallBreakpointStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateICCallThroughCodeStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateInterpretCallStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateInvokeDartCodeFromBytecodeStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateInvokeDartCodeStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateJumpToFrameStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateLazyCompileStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateMegamorphicCallStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateMonomorphicSmiableCheckStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateNoSuchMethodDispatcherStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateOneArgCheckInlineCacheStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateOneArgCheckInlineCacheWithExactnessCheckStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateOneArgOptimizedCheckInlineCacheStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateOneArgOptimizedCheckInlineCacheWithExactnessCheckStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateOneArgUnoptimizedStaticCallStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateOptimizedIdenticalWithNumberCheckStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateOptimizeFunctionStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateRunExceptionHandlerStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateRunExceptionHandlerUnboxStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateRuntimeCallBreakpointStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSingleTargetCallStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSmiAddInlineCacheStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSmiEqualInlineCacheStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSmiLessInlineCacheStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSwitchableCallMissStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateTwoArgsCheckInlineCacheStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateTwoArgsOptimizedCheckInlineCacheStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateTwoArgsUnoptimizedStaticCallStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateUnoptimizedIdenticalWithNumberCheckStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateUnoptStaticCallBreakpointStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateWriteBarrierStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateWriteBarrierWrappersStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateZeroArgsUnoptimizedStaticCallStub() {
  assembler->Ret();
}

void StubCodeCompiler::GenerateAllocateTypedDataArrayStub(intptr_t) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateAllocationStubForClass(
    UnresolvedPcRelativeCalls*,
    const Class&,
    const dart::Code&,
    const dart::Code&) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateRangeError(bool) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateWriteError(bool) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSharedStubGeneric(bool,
                                                 intptr_t,
                                                 bool,
                                                 std::function<void()>) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSharedStub(bool,
                                          const RuntimeEntry*,
                                          intptr_t,
                                          bool,
                                          bool) {
  assembler->Ret();
}

void StubCodeCompiler::GenerateSubtypeNTestCacheStub(Assembler* assembler,
                                                     int) {
  assembler->Ret();
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
