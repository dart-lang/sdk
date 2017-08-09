// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#include "vm/assembler.h"
#include "vm/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/heap.h"
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
DECLARE_FLAG(bool, trace_optimized_ic_calls);

void StubCode::GenerateLazyCompileStub(Assembler* assembler) {
  __ Compile();
}

// Not executed, but used as a stack marker when calling
// DRT_OptimizeInvokedFunction.
void StubCode::GenerateOptimizeFunctionStub(Assembler* assembler) {
  __ Trap();
}

// Not executed, but used as a sentinel in Simulator::JumpToFrame.
void StubCode::GenerateRunExceptionHandlerStub(Assembler* assembler) {
  __ Trap();
}

void StubCode::GenerateDeoptForRewindStub(Assembler* assembler) {
  __ DeoptRewind();
}

// TODO(vegorov) Don't generate this stub.
void StubCode::GenerateFixCallersTargetStub(Assembler* assembler) {
  __ Trap();
}

// TODO(vegorov) Don't generate these stubs.
void StubCode::GenerateAllocationStubForClass(Assembler* assembler,
                                              const Class& cls) {
  __ Trap();
}

// TODO(vegorov) Don't generate this stub.
void StubCode::GenerateMegamorphicMissStub(Assembler* assembler) {
  __ Trap();
}

// These deoptimization stubs are only used to populate stack frames
// with something meaningful to make sure GC can scan the stack during
// the last phase of deoptimization which materializes objects.
void StubCode::GenerateDeoptimizeLazyFromReturnStub(Assembler* assembler) {
  __ Trap();
}

void StubCode::GenerateDeoptimizeLazyFromThrowStub(Assembler* assembler) {
  __ Trap();
}

void StubCode::GenerateDeoptimizeStub(Assembler* assembler) {
  __ Trap();
}

void StubCode::GenerateFrameAwaitingMaterializationStub(Assembler* assembler) {
  __ Trap();
}

void StubCode::GenerateAsynchronousGapMarkerStub(Assembler* assembler) {
  __ Trap();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
