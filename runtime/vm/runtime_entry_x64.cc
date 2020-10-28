// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/runtime_entry.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#include "vm/stub_code.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

#define __ assembler->

uword RuntimeEntry::GetEntryPoint() const {
  return reinterpret_cast<uword>(function());
}

#if !defined(DART_PRECOMPILED_RUNTIME)
// Generate code to call into the stub which will call the runtime
// function. Input for the stub is as follows:
//   RSP : points to the arguments and return value array.
//   RBX : address of the runtime function to call.
//   R10 : number of arguments to the call.
void RuntimeEntry::CallInternal(const RuntimeEntry* runtime_entry,
                                compiler::Assembler* assembler,
                                intptr_t argument_count) {
  if (runtime_entry->is_leaf()) {
    ASSERT(argument_count == runtime_entry->argument_count());
    COMPILE_ASSERT(CallingConventions::kVolatileCpuRegisters & (1 << RAX));
    __ movq(RAX,
            compiler::Address(THR, Thread::OffsetFromThread(runtime_entry)));
    __ movq(compiler::Assembler::VMTagAddress(), RAX);
    __ CallCFunction(RAX);
    __ movq(compiler::Assembler::VMTagAddress(),
            compiler::Immediate(VMTag::kDartTagId));
    ASSERT((CallingConventions::kCalleeSaveCpuRegisters & (1 << THR)) != 0);
    ASSERT((CallingConventions::kCalleeSaveCpuRegisters & (1 << PP)) != 0);
  } else {
    // Argument count is not checked here, but in the runtime entry for a more
    // informative error message.
    __ movq(RBX,
            compiler::Address(THR, Thread::OffsetFromThread(runtime_entry)));
    __ LoadImmediate(R10, compiler::Immediate(argument_count));
    __ CallToRuntime();
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
