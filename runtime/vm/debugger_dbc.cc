// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/debugger.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"

namespace dart {

#ifndef PRODUCT

RawCode* CodeBreakpoint::OrigStubAddress() const {
  return reinterpret_cast<RawCode*>(static_cast<uintptr_t>(saved_value_));
}


static Instr* CallInstructionFromReturnAddress(uword pc) {
  return reinterpret_cast<Instr*>(pc) - 1;
}


void CodeBreakpoint::PatchCode() {
  ASSERT(!is_enabled_);
  const Code& code = Code::Handle(code_);
  const Instructions& instrs = Instructions::Handle(code.instructions());
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    saved_value_ = *CallInstructionFromReturnAddress(pc_);
    switch (breakpoint_kind_) {
      case RawPcDescriptors::kIcCall:
      case RawPcDescriptors::kUnoptStaticCall: {
        // DebugBreak has an A operand matching the call it replaces.
        // This ensures that Return instructions continue to work - as they
        // look at calls to figure out how many arguments to drop.
        *CallInstructionFromReturnAddress(pc_) =
            Bytecode::Encode(Bytecode::kDebugBreak,
                             Bytecode::DecodeArgc(saved_value_),
                             0,
                             0);
        break;
      }

      case RawPcDescriptors::kRuntimeCall: {
        *CallInstructionFromReturnAddress(pc_) = Bytecode::kDebugBreak;
        break;
      }

      default:
        UNREACHABLE();
    }
  }
  is_enabled_ = true;
}


void CodeBreakpoint::RestoreCode() {
  ASSERT(is_enabled_);
  const Code& code = Code::Handle(code_);
  const Instructions& instrs = Instructions::Handle(code.instructions());
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    switch (breakpoint_kind_) {
      case RawPcDescriptors::kIcCall:
      case RawPcDescriptors::kUnoptStaticCall:
      case RawPcDescriptors::kRuntimeCall: {
        *CallInstructionFromReturnAddress(pc_) = saved_value_;
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  is_enabled_ = false;
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
