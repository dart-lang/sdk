// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/runtime_entry.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/stub_code.h"

namespace dart {

#define __ assembler->

uword RuntimeEntry::GetEntryPoint() const {
  return reinterpret_cast<uword>(function());
}

#if !defined(DART_PRECOMPILED_RUNTIME)
// Generate code to call into the stub which will call the runtime
// function. Input for the stub is as follows:
// For regular runtime calls -
//   ESP : points to the arguments and return value array.
//   ECX : address of the runtime function to call.
//   EDX : number of arguments to the call as Smi.
// For leaf calls the caller is responsible to setup the arguments
// and look for return values based on the C calling convention.
void RuntimeEntry::CallInternal(const RuntimeEntry* runtime_entry,
                                compiler::Assembler* assembler,
                                intptr_t argument_count) {
  if (runtime_entry->is_leaf()) {
    ASSERT(argument_count == runtime_entry->argument_count());
    __ movl(EAX, compiler::Immediate(runtime_entry->GetEntryPoint()));
    __ movl(compiler::Assembler::VMTagAddress(), EAX);
    __ call(EAX);
    __ movl(compiler::Assembler::VMTagAddress(),
            compiler::Immediate(VMTag::kDartCompiledTagId));
  } else {
    // Argument count is not checked here, but in the runtime entry for a more
    // informative error message.
    __ movl(ECX, compiler::Immediate(runtime_entry->GetEntryPoint()));
    __ movl(EDX, compiler::Immediate(argument_count));
    __ CallToRuntime();
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
