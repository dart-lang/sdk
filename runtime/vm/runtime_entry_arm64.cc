// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/runtime_entry.h"

#include "vm/assembler.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"

namespace dart {

#define __ assembler->

// Generate code to call into the stub which will call the runtime
// function. Input for the stub is as follows:
//   SP : points to the arguments and return value array.
//   R5 : address of the runtime function to call.
//   R4 : number of arguments to the call as Smi.
void RuntimeEntry::Call(Assembler* assembler, intptr_t argument_count) const {
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry = GetEntryPoint();
#if defined(USING_SIMULATOR)
  // Redirection to leaf runtime calls supports a maximum of 8 arguments passed
  // in registers.
  ASSERT(argument_count >= 0);
  ASSERT(!is_leaf() || (argument_count <= 8));
  Simulator::CallKind call_kind =
      is_leaf() ? (is_float() ? Simulator::kLeafFloatRuntimeCall
                              : Simulator::kLeafRuntimeCall)
                : Simulator::kRuntimeCall;
  entry =
      Simulator::RedirectExternalReference(entry, call_kind, argument_count);
#endif
  if (is_leaf()) {
    ASSERT(argument_count == this->argument_count());
    ExternalLabel label(entry);
    // Since we are entering C++ code, we must restore the C stack pointer from
    // the stack limit to an aligned value nearer to the top of the stack.
    // We cache the Dart stack pointer and the stack limit in callee-saved
    // registers, then align and call, restoring CSP and SP on return from the
    // call.
    __ mov(R25, CSP);
    __ mov(R26, SP);
    __ ReserveAlignedFrameSpace(0);
    __ mov(CSP, SP);
    __ BranchLink(&label, kNoPP);
    __ mov(SP, R26);
    __ mov(CSP, R25);
  } else {
    // Argument count is not checked here, but in the runtime entry for a more
    // informative error message.
    __ LoadImmediate(R5, entry, kNoPP);
    __ LoadImmediate(R4, Smi::RawValue(argument_count), kNoPP);
    __ BranchLink(&StubCode::CallToRuntimeLabel(), PP);
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
