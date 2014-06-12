// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/runtime_entry.h"

#include "vm/assembler.h"
#include "vm/stub_code.h"

namespace dart {

#define __ assembler->


// Generate code to call into the stub which will call the runtime
// function. Input for the stub is as follows:
// For regular runtime calls -
//   ESP : points to the arguments and return value array.
//   ECX : address of the runtime function to call.
//   EDX : number of arguments to the call as Smi.
// For leaf calls the caller is responsible to setup the arguments
// and look for return values based on the C calling convention.
void RuntimeEntry::Call(Assembler* assembler, intptr_t argument_count) const {
  if (is_leaf()) {
    ASSERT(argument_count == this->argument_count());
    ExternalLabel label(GetEntryPoint());
    __ call(&label);
  } else {
    // Argument count is not checked here, but in the runtime entry for a more
    // informative error message.
    __ movl(ECX, Immediate(GetEntryPoint()));
    __ movl(EDX, Immediate(Smi::RawValue(argument_count)));
    __ call(&StubCode::CallToRuntimeLabel());
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
