// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

// Only build the simulator if not compiling for real MIPS hardware.
#if !defined(HOST_ARCH_MIPS)

#include "vm/simulator.h"

#include "vm/assembler.h"
#include "vm/constants_mips.h"
#include "vm/disassembler.h"

namespace dart {

DEFINE_FLAG(int, stop_sim_at, 0, "Address to stop simulator at.");

void Simulator::InitOnce() {
}


Simulator::Simulator() {
  // Setup simulator support first. Some of this information is needed to
  // setup the architecture state.
  // We allocate the stack here, the size is computed as the sum of
  // the size specified by the user and the buffer space needed for
  // handling stack overflow exceptions. To be safe in potential
  // stack underflows we also add some underflow buffer space.
  stack_ = new char[(Isolate::GetSpecifiedStackSize() +
                     Isolate::kStackSizeBuffer +
                     kSimulatorStackUnderflowSize)];
  icount_ = 0;
  delay_slot_ = false;

  // Setup architecture state.
  // All registers are initialized to zero to start with.
  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    registers_[i] = 0;
  }
  pc_ = 0;
  // The sp is initialized to point to the bottom (high address) of the
  // allocated stack area.
  registers_[SP] = StackTop();
}


Simulator::~Simulator() {
  Isolate* isolate = Isolate::Current();
  if (isolate != NULL) {
    isolate->set_simulator(NULL);
  }
}


// Get the active Simulator for the current isolate.
Simulator* Simulator::Current() {
  Simulator* simulator = Isolate::Current()->simulator();
  if (simulator == NULL) {
    simulator = new Simulator();
    Isolate::Current()->set_simulator(simulator);
  }
  return simulator;
}


// Sets the register in the architecture state. It will also deal with updating
// Simulator internal state for special registers such as PC.
void Simulator::set_register(Register reg, int32_t value) {
  if (reg != R0) {
    registers_[reg] = value;
  }
}


// Get the register from the architecture state. This function does handle
// the special case of accessing the PC register.
int32_t Simulator::get_register(Register reg) const {
  if (reg == R0) {
    return 0;
  }
  return registers_[reg];
}


// Returns the top of the stack area to enable checking for stack pointer
// validity.
uword Simulator::StackTop() const {
  // To be safe in potential stack underflows we leave some buffer above and
  // set the stack top.
  return reinterpret_cast<uword>(stack_) +
      (Isolate::GetSpecifiedStackSize() + Isolate::kStackSizeBuffer);
}


void Simulator::Format(Instr* instr, const char* format) {
  OS::PrintErr("Simulator - unknown instruction: %s\n", format);
  UNIMPLEMENTED();
}

void Simulator::DecodeSpecial(Instr* instr) {
  switch (instr->FunctionField()) {
    case SLL: {
      if ((instr->RdField() == R0) &&
          (instr->RtField() == R0) &&
          (instr->SaField() == 0)) {
        // Format(instr, "nop");
        // Nothing to be done for NOP.
      } else {
        Format(instr, "sll 'rd, 'rt, 'sa");
      }
      break;
    }
    case JR: {
      ASSERT(instr->RtField() == R0);
      ASSERT(instr->RdField() == R0);
      ASSERT(!delay_slot_);
      // Format(instr, "jr'hint 'rs");
      uword next_pc = get_register(instr->RsField());
      ExecuteDelaySlot();
      pc_ = next_pc - Instr::kInstrSize;  // Account for regular PC increment.
      break;
    }
    default: {
      OS::PrintErr("DecodeSpecial: 0x%x\n", instr->InstructionBits());
      UNREACHABLE();
      break;
    }
  }
}


void Simulator::InstructionDecode(Instr* instr) {
  switch (instr->OpcodeField()) {
    case SPECIAL: {
      DecodeSpecial(instr);
      break;
    }
    case ORI: {
      // Format(instr, "ori 'rt, 'rs, 'immu");
      int32_t rs_val = get_register(instr->RsField());
      set_register(instr->RtField(), rs_val | instr->UImmField());
      break;
    }
    default: {
      OS::PrintErr("Undecoded instruction: 0x%x\n", instr->InstructionBits());
      UNREACHABLE();
      break;
    }
  }
  pc_ += Instr::kInstrSize;
}


void Simulator::ExecuteDelaySlot() {
  ASSERT(pc_ != kEndSimulatingPC);
  delay_slot_ = true;
  icount_++;
  if (icount_ == FLAG_stop_sim_at) {
    UNIMPLEMENTED();
  }
  Instr* instr = Instr::At(pc_ + Instr::kInstrSize);
  InstructionDecode(instr);
  delay_slot_ = false;
}


void Simulator::Execute() {
  if (FLAG_stop_sim_at == 0) {
    // Fast version of the dispatch loop without checking whether the simulator
    // should be stopping at a particular executed instruction.
    while (pc_ != kEndSimulatingPC) {
      icount_++;
      Instr* instr = Instr::At(pc_);
      InstructionDecode(instr);
    }
  } else {
    // FLAG_stop_sim_at is at the non-default value. Stop in the debugger when
    // we reach the particular instruction count.
    while (pc_ != kEndSimulatingPC) {
      icount_++;
      if (icount_ == FLAG_stop_sim_at) {
        UNIMPLEMENTED();
      } else {
        Instr* instr = Instr::At(pc_);
        InstructionDecode(instr);
      }
    }
  }
}


int64_t Simulator::Call(int32_t entry,
                        int32_t parameter0,
                        int32_t parameter1,
                        int32_t parameter2,
                        int32_t parameter3) {
  // Save the SP register before the call so we can restore it.
  int32_t sp_before_call = get_register(SP);

  // Setup parameters.
  set_register(A0, parameter0);
  set_register(A1, parameter1);
  set_register(A2, parameter2);
  set_register(A3, parameter3);

  // Make sure the activation frames are properly aligned.
  int32_t stack_pointer = sp_before_call;
  static const int kFrameAlignment = OS::ActivationFrameAlignment();
  if (kFrameAlignment > 0) {
    stack_pointer = Utils::RoundDown(stack_pointer, kFrameAlignment);
  }
  set_register(SP, stack_pointer);

  // Prepare to execute the code at entry.
  set_pc(entry);
  // Put down marker for end of simulation. The simulator will stop simulation
  // when the PC reaches this value. By saving the "end simulation" value into
  // RA the simulation stops when returning to this call point.
  set_register(RA, kEndSimulatingPC);

  // Remember the values of callee-saved registers.
  // The code below assumes that r9 is not used as sb (static base) in
  // simulator code and therefore is regarded as a callee-saved register.
  int32_t r16_val = get_register(R16);
  int32_t r17_val = get_register(R17);
  int32_t r18_val = get_register(R18);
  int32_t r19_val = get_register(R19);
  int32_t r20_val = get_register(R20);
  int32_t r21_val = get_register(R21);
  int32_t r22_val = get_register(R22);
  int32_t r23_val = get_register(R23);

  // Setup the callee-saved registers with a known value. To be able to check
  // that they are preserved properly across dart execution.
  int32_t callee_saved_value = icount_;
  set_register(R16, callee_saved_value);
  set_register(R17, callee_saved_value);
  set_register(R18, callee_saved_value);
  set_register(R19, callee_saved_value);
  set_register(R20, callee_saved_value);
  set_register(R21, callee_saved_value);
  set_register(R22, callee_saved_value);
  set_register(R23, callee_saved_value);

  // Start the simulation
  Execute();

  // Check that the callee-saved registers have been preserved.
  ASSERT(callee_saved_value == get_register(R16));
  ASSERT(callee_saved_value == get_register(R17));
  ASSERT(callee_saved_value == get_register(R18));
  ASSERT(callee_saved_value == get_register(R19));
  ASSERT(callee_saved_value == get_register(R20));
  ASSERT(callee_saved_value == get_register(R21));
  ASSERT(callee_saved_value == get_register(R22));
  ASSERT(callee_saved_value == get_register(R23));

  // Restore callee-saved registers with the original value.
  set_register(R16, r16_val);
  set_register(R17, r17_val);
  set_register(R18, r18_val);
  set_register(R19, r19_val);
  set_register(R20, r20_val);
  set_register(R21, r21_val);
  set_register(R22, r22_val);
  set_register(R23, r23_val);

  // Restore the SP register and return R1:R0.
  set_register(SP, sp_before_call);
  return Utils::LowHighTo64Bits(get_register(V0), get_register(V1));
}

}  // namespace dart

#endif  // !defined(HOST_ARCH_MIPS)

#endif  // defined TARGET_ARCH_MIPS
