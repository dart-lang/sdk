// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/heap/heap.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/tags.h"

#define __ assembler->

namespace dart {

DEFINE_FLAG(bool, inline_alloc, true, "Inline allocation of objects.");
DEFINE_FLAG(bool,
            use_slow_path,
            false,
            "Set to true for debugging & verifying the slow paths.");

namespace compiler {

void StubCodeCompiler::GenerateLazyCompileStub(Assembler* assembler) {
  __ Compile();
}

void StubCodeCompiler::GenerateCallClosureNoSuchMethodStub(
    Assembler* assembler) {
  __ NoSuchMethod();
}

// Not executed, but used as a stack marker when calling
// DRT_OptimizeInvokedFunction.
void StubCodeCompiler::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ Trap();
}

// Not executed, but used as a sentinel in Simulator::JumpToFrame.
void StubCodeCompiler::GenerateRunExceptionHandlerStub(Assembler* assembler) {
  __ Trap();
}

void StubCodeCompiler::GenerateDeoptForRewindStub(Assembler* assembler) {
  __ DeoptRewind();
}

// TODO(vegorov) Don't generate this stub.
void StubCodeCompiler::GenerateFixCallersTargetStub(Assembler* assembler) {
  __ Trap();
}

// TODO(vegorov) Don't generate these stubs.
void StubCodeCompiler::GenerateAllocationStubForClass(Assembler* assembler,
                                                      const Class& cls) {
  __ Trap();
}

// TODO(vegorov) Don't generate this stub.
void StubCodeCompiler::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ Trap();
}

// These deoptimization stubs are only used to populate stack frames
// with something meaningful to make sure GC can scan the stack during
// the last phase of deoptimization which materializes objects.
void StubCodeCompiler::GenerateDeoptimizeLazyFromReturnStub(
    Assembler* assembler) {
  __ Trap();
}

void StubCodeCompiler::GenerateDeoptimizeLazyFromThrowStub(
    Assembler* assembler) {
  __ Trap();
}

void StubCodeCompiler::GenerateDeoptimizeStub(Assembler* assembler) {
  __ Trap();
}

// TODO(kustermann): Don't generate this stub.
void StubCodeCompiler::GenerateDefaultTypeTestStub(Assembler* assembler) {
  __ Trap();
}

// TODO(kustermann): Don't generate this stub.
void StubCodeCompiler::GenerateTopTypeTypeTestStub(Assembler* assembler) {
  __ Trap();
}

// TODO(kustermann): Don't generate this stub.
void StubCodeCompiler::GenerateTypeRefTypeTestStub(Assembler* assembler) {
  __ Trap();
}

// TODO(kustermann): Don't generate this stub.
void StubCodeCompiler::GenerateUnreachableTypeTestStub(Assembler* assembler) {
  __ Trap();
}

// TODO(kustermann): Don't generate this stub.
void StubCodeCompiler::GenerateLazySpecializeTypeTestStub(
    Assembler* assembler) {
  __ Trap();
}

// TODO(kustermann): Don't generate this stub.
void StubCodeCompiler::GenerateSlowTypeTestStub(Assembler* assembler) {
  __ Trap();
}

void StubCodeCompiler::GenerateFrameAwaitingMaterializationStub(
    Assembler* assembler) {
  __ Trap();
}

void StubCodeCompiler::GenerateAsynchronousGapMarkerStub(Assembler* assembler) {
  __ Trap();
}

void StubCodeCompiler::GenerateInterpretCallStub(Assembler* assembler) {
  __ Trap();
}

void StubCodeCompiler::GenerateInvokeDartCodeFromBytecodeStub(
    Assembler* assembler) {
  __ Trap();
}

}  // namespace compiler

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
