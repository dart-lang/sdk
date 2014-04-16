// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/heap.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/tags.h"

#define __ assembler->

namespace dart {

void StubCode::GenerateCallToRuntimeStub(Assembler* assembler) {
  __ Stop("GenerateCallToRuntimeStub");
}


void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  __ Stop("GeneratePrintStopMessageStub");
}


void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  __ Stop("GenerateCallNativeCFunctionStub");
}


void StubCode::GenerateCallBootstrapCFunctionStub(Assembler* assembler) {
  __ Stop("GenerateCallBootstrapCFunctionStub");
}


void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  __ Stop("GenerateCallStaticFunctionStub");
}


void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  __ Stop("GenerateFixCallersTargetStub");
}


void StubCode::GenerateDeoptimizeLazyStub(Assembler* assembler) {
  __ Stop("GenerateDeoptimizeLazyStub");
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  __ Stop("GenerateDeoptimizeStub");
}


void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ Stop("GenerateMegamorphicMissStub");
}


void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  __ Stop("GenerateAllocateArrayStub");
}


void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  __ Stop("GenerateInvokeDartCodeStub");
}


void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  __ Stop("GenerateAllocateContextStub");
}


void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  __ Stop("GenerateUpdateStoreBufferStub");
}


void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  __ Stop("GenerateAllocationStubForClass");
}


void StubCode::GenerateCallNoSuchMethodFunctionStub(Assembler* assembler) {
  __ Stop("GenerateCallNoSuchMethodFunctionStub");
}


void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  __ Stop("GenerateOptimizedUsageCounterIncrement");
}


void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  __ Stop("GenerateUsageCounterIncrement");
}


void StubCode::GenerateNArgsCheckInlineCacheStub(
    Assembler* assembler,
    intptr_t num_args,
    const RuntimeEntry& handle_ic_miss) {
  __ Stop("GenerateNArgsCheckInlineCacheStub");
}


void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  __ Stop("GenerateOneArgCheckInlineCacheStub");
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  __ Stop("GenerateTwoArgsCheckInlineCacheStub");
}


void StubCode::GenerateThreeArgsCheckInlineCacheStub(Assembler* assembler) {
  __ Stop("GenerateThreeArgsCheckInlineCacheStub");
}


void StubCode::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  __ Stop("GenerateOneArgOptimizedCheckInlineCacheStub");
}


void StubCode::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  __ Stop("GenerateTwoArgsOptimizedCheckInlineCacheStub");
}


void StubCode::GenerateThreeArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  __ Stop("GenerateThreeArgsOptimizedCheckInlineCacheStub");
}


void StubCode::GenerateClosureCallInlineCacheStub(Assembler* assembler) {
  __ Stop("GenerateClosureCallInlineCacheStub");
}


void StubCode::GenerateMegamorphicCallStub(Assembler* assembler) {
  __ Stop("GenerateMegamorphicCallStub");
}


void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  __ Stop("GenerateZeroArgsUnoptimizedStaticCallStub");
}


void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  __ Stop("GenerateTwoArgsUnoptimizedStaticCallStub");
}


void StubCode::GenerateLazyCompileStub(Assembler* assembler) {
  __ Stop("GenerateLazyCompileStub");
}


void StubCode::GenerateBreakpointRuntimeStub(Assembler* assembler) {
  __ Stop("GenerateBreakpointRuntimeStub");
}


void StubCode::GenerateDebugStepCheckStub(Assembler* assembler) {
  __ Stop("GenerateDebugStepCheckStub");
}


void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  __ Stop("GenerateSubtype1TestCacheStub");
}


void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  __ Stop("GenerateSubtype2TestCacheStub");
}


void StubCode::GenerateSubtype3TestCacheStub(Assembler* assembler) {
  __ Stop("GenerateSubtype3TestCacheStub");
}


void StubCode::GenerateGetStackPointerStub(Assembler* assembler) {
  __ Stop("GenerateGetStackPointerStub");
}


void StubCode::GenerateJumpToExceptionHandlerStub(Assembler* assembler) {
  __ Stop("GenerateJumpToExceptionHandlerStub");
}


void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ Stop("GenerateOptimizeFunctionStub");
}


void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                    const Register left,
                                                    const Register right,
                                                    const Register temp,
                                                    const Register unused) {
  __ Stop("GenerateIdenticalWithNumberCheckStub");
}


void StubCode::GenerateUnoptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  __ Stop("GenerateUnoptimizedIdenticalWithNumberCheckStub");
}


void StubCode::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  __ Stop("GenerateOptimizedIdenticalWithNumberCheckStub");
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
