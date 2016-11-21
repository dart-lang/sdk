// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/runtime_entry.h"

#include "vm/assembler.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"

namespace dart {

#define __ assembler->


uword RuntimeEntry::GetEntryPoint() const {
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry = reinterpret_cast<uword>(function());
#if defined(USING_SIMULATOR)
  // Redirection to leaf runtime calls supports a maximum of 4 arguments passed
  // in registers (maximum 2 double arguments for leaf float runtime calls).
  ASSERT(argument_count() >= 0);
  ASSERT(!is_leaf() || (!is_float() && (argument_count() <= 4)) ||
         (argument_count() <= 2));
  Simulator::CallKind call_kind =
      is_leaf() ? (is_float() ? Simulator::kLeafFloatRuntimeCall
                              : Simulator::kLeafRuntimeCall)
                : Simulator::kRuntimeCall;
  entry =
      Simulator::RedirectExternalReference(entry, call_kind, argument_count());
#endif
  return entry;
}


// Generate code to call into the stub which will call the runtime
// function. Input for the stub is as follows:
//   SP : points to the arguments and return value array.
//   S5 : address of the runtime function to call.
//   S4 : number of arguments to the call.
void RuntimeEntry::Call(Assembler* assembler, intptr_t argument_count) const {
  if (is_leaf()) {
    ASSERT(argument_count == this->argument_count());
    __ lw(T9, Address(THR, Thread::OffsetFromThread(this)));
    __ jalr(T9);
  } else {
    // Argument count is not checked here, but in the runtime entry for a more
    // informative error message.
    __ lw(S5, Address(THR, Thread::OffsetFromThread(this)));
    __ LoadImmediate(S4, argument_count);
    __ BranchLinkToRuntime();
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
