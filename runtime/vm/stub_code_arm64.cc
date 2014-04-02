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
  UNIMPLEMENTED();
}


void StubCode::GeneratePrintStopMessageStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateCallNativeCFunctionStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateCallBootstrapCFunctionStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateCallStaticFunctionStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateInstanceFunctionLookupStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateDeoptimizeLazyStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateAllocateArrayStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateCallClosureFunctionStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateInvokeDartCodeStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateAllocateContextStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateUpdateStoreBufferStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  UNIMPLEMENTED();
}


void StubCode::GenerateCallNoSuchMethodFunctionStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateOptimizedUsageCounterIncrement(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateUsageCounterIncrement(Assembler* assembler,
                                             Register temp_reg) {
  UNIMPLEMENTED();
}


void StubCode::GenerateNArgsCheckInlineCacheStub(
    Assembler* assembler,
    intptr_t num_args,
    const RuntimeEntry& handle_ic_miss) {
  UNIMPLEMENTED();
}


void StubCode::GenerateOneArgCheckInlineCacheStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateTwoArgsCheckInlineCacheStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateThreeArgsCheckInlineCacheStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateOneArgOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateTwoArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateThreeArgsOptimizedCheckInlineCacheStub(
    Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateClosureCallInlineCacheStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateMegamorphicCallStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateZeroArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateTwoArgsUnoptimizedStaticCallStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateLazyCompileStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateBreakpointRuntimeStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateDebugStepCheckStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateSubtype1TestCacheStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateSubtype2TestCacheStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateSubtype3TestCacheStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateGetStackPointerStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateJumpToExceptionHandlerStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateIdenticalWithNumberCheckStub(Assembler* assembler,
                                                    const Register left,
                                                    const Register right,
                                                    const Register temp,
                                                    const Register unused) {
  UNIMPLEMENTED();
}


void StubCode::GenerateUnoptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  UNIMPLEMENTED();
}


void StubCode::GenerateOptimizedIdenticalWithNumberCheckStub(
    Assembler* assembler) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
