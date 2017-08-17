// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/runtime_entry.h"

#include "vm/assembler.h"
#include "vm/stub_code.h"

namespace dart {

#define __ assembler->

uword RuntimeEntry::GetEntryPoint() const {
  return reinterpret_cast<uword>(function());
}

// Generate code to call into the stub which will call the runtime
// function. Input for the stub is as follows:
//   RSP : points to the arguments and return value array.
//   RBX : address of the runtime function to call.
//   R10 : number of arguments to the call.
void RuntimeEntry::Call(Assembler* assembler, intptr_t argument_count) const {
  if (is_leaf()) {
    ASSERT(argument_count == this->argument_count());
    COMPILE_ASSERT(CallingConventions::kVolatileCpuRegisters & (1 << RAX));
    __ movq(RAX, Address(THR, Thread::OffsetFromThread(this)));
    __ CallCFunction(RAX);
  } else {
    // Argument count is not checked here, but in the runtime entry for a more
    // informative error message.
    __ movq(RBX, Address(THR, Thread::OffsetFromThread(this)));
    __ movq(R10, Immediate(argument_count));
    __ CallToRuntime();
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
