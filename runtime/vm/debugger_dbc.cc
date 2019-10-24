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

static Instr* FastSmiInstructionFromReturnAddress(uword pc) {
  return reinterpret_cast<Instr*>(pc) - 2;
}

void CodeBreakpoint::PatchCode() {
  ASSERT(!is_enabled_);
  auto thread = Thread::Current();
  auto zone = thread->zone();
  const Code& code = Code::Handle(zone, code_);
  const Instructions& instrs = Instructions::Handle(zone, code.instructions());
  thread->isolate_group()->RunWithStoppedMutators([&]() {
    WritableInstructionsScope writable(instrs.PayloadStart(), instrs.Size());
    saved_value_ = *CallInstructionFromReturnAddress(pc_);
    switch (breakpoint_kind_) {
      case RawPcDescriptors::kIcCall:
      case RawPcDescriptors::kUnoptStaticCall: {
        // DebugBreak has an A operand matching the call it replaces.
        // This ensures that Return instructions continue to work - as they
        // look at calls to figure out how many arguments to drop.
        *CallInstructionFromReturnAddress(pc_) = SimulatorBytecode::Encode(
            SimulatorBytecode::kDebugBreak,
            SimulatorBytecode::DecodeArgc(saved_value_), 0, 0);
        break;
      }

      case RawPcDescriptors::kRuntimeCall: {
        *CallInstructionFromReturnAddress(pc_) = SimulatorBytecode::kDebugBreak;
        break;
      }

      default:
        UNREACHABLE();
    }

    // If this call is the fall-through for a fast Smi op, also disable the fast
    // Smi op.
    if ((SimulatorBytecode::DecodeOpcode(saved_value_) ==
         SimulatorBytecode::kInstanceCall2) &&
        SimulatorBytecode::IsFastSmiOpcode(
            *FastSmiInstructionFromReturnAddress(pc_))) {
      saved_value_fastsmi_ = *FastSmiInstructionFromReturnAddress(pc_);
      *FastSmiInstructionFromReturnAddress(pc_) =
          SimulatorBytecode::Encode(SimulatorBytecode::kNop, 0, 0, 0);
    } else {
      saved_value_fastsmi_ = SimulatorBytecode::kTrap;
    }
  });
  is_enabled_ = true;
}

void CodeBreakpoint::RestoreCode() {
  ASSERT(is_enabled_);
  auto thread = Thread::Current();
  auto zone = thread->zone();
  const Code& code = Code::Handle(zone, code_);
  const Instructions& instrs = Instructions::Handle(zone, code.instructions());
  thread->isolate_group()->RunWithStoppedMutators([&]() {
    WritableInstructionsScope writable(instrs.PayloadStart(), instrs.Size());
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

    if (saved_value_fastsmi_ != SimulatorBytecode::kTrap) {
      Instr current_instr = *FastSmiInstructionFromReturnAddress(pc_);
      ASSERT(SimulatorBytecode::DecodeOpcode(current_instr) ==
             SimulatorBytecode::kNop);
      *FastSmiInstructionFromReturnAddress(pc_) = saved_value_fastsmi_;
    }
  });
  is_enabled_ = false;
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
