// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <math.h>  // for isnan.
#include <setjmp.h>
#include <stdlib.h>

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

// Only build the simulator if not compiling for real ARM hardware.
#if !defined(HOST_ARCH_ARM64)

#include "vm/simulator.h"

#include "vm/assembler.h"
#include "vm/constants_arm64.h"
#include "vm/cpu.h"
#include "vm/disassembler.h"
#include "vm/native_arguments.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"

namespace dart {

DEFINE_FLAG(bool, trace_sim, false, "Trace simulator execution.");
DEFINE_FLAG(int, stop_sim_at, 0, "Address to stop simulator at.");


// This macro provides a platform independent use of sscanf. The reason for
// SScanF not being implemented in a platform independent way through
// OS in the same way as SNPrint is that the Windows C Run-Time
// Library does not provide vsscanf.
#define SScanF sscanf  // NOLINT


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
  pc_modified_ = false;
  icount_ = 0;
  break_pc_ = NULL;
  break_instr_ = 0;
  top_exit_frame_info_ = 0;

  // Setup architecture state.
  // All registers are initialized to zero to start with.
  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    registers_[i] = 0;
  }
  n_flag_ = false;
  z_flag_ = false;
  c_flag_ = false;
  v_flag_ = false;

  // The sp is initialized to point to the bottom (high address) of the
  // allocated stack area.
  registers_[SP] = StackTop();
  // The lr and pc are initialized to a known bad value that will cause an
  // access violation if the simulator ever tries to execute it.
  registers_[LR] = kBadLR;
  pc_ = kBadLR;
}


Simulator::~Simulator() {
  delete[] stack_;
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


// Sets the register in the architecture state.
void Simulator::set_register(Register reg, int64_t value, R31Type r31t) {
  // register is in range, and if it is R31, a mode is specified.
  ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
  ASSERT((reg != R31) || (r31t != R31IsUndef));
  if ((reg != R31) || (r31t != R31IsZR)) {
    registers_[reg] = value;
  }
}


// Get the register from the architecture state.
int64_t Simulator::get_register(Register reg, R31Type r31t) const {
  ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
  ASSERT((reg != R31) || (r31t != R31IsUndef));
  if ((reg == R31) && (r31t == R31IsZR)) {
    return 0;
  } else {
    return registers_[reg];
  }
}


void Simulator::set_wregister(Register reg, int32_t value, R31Type r31t) {
  ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
  ASSERT((reg != R31) || (r31t != R31IsUndef));
  // When setting in W mode, clear the high bits.
  if ((reg != R31) || (r31t != R31IsZR)) {
    registers_[reg] = Utils::LowHighTo64Bits(static_cast<uint32_t>(value), 0);
  }
}


// Get the register from the architecture state.
int32_t Simulator::get_wregister(Register reg, R31Type r31t) const {
  ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
  ASSERT((reg != R31) || (r31t != R31IsUndef));
  if ((reg == R31) && (r31t == R31IsZR)) {
    return 0;
  } else {
    return registers_[reg];
  }
}


// Raw access to the PC register.
void Simulator::set_pc(int64_t value) {
  pc_modified_ = true;
  pc_ = value;
}


// Raw access to the PC register without the special adjustment when reading.
int64_t Simulator::get_pc() const {
  return pc_;
}


void Simulator::HandleIllegalAccess(uword addr, Instr* instr) {
  uword fault_pc = get_pc();
  // TODO(zra): drop into debugger.
  char buffer[128];
  snprintf(buffer, sizeof(buffer),
           "illegal memory access at 0x%" Px ", pc=0x%" Px "\n",
           addr, fault_pc);
  // The debugger will return control in non-interactive mode.
  FATAL("Cannot continue execution after illegal memory access.");
}


void Simulator::UnimplementedInstruction(Instr* instr) {
  char buffer[64];
  snprintf(buffer, sizeof(buffer), "Unimplemented instruction: pc=%p\n", instr);
  // TODO(zra): drop into debugger.
  FATAL("Cannot continue execution after unimplemented instruction.");
}


// Returns the top of the stack area to enable checking for stack pointer
// validity.
uword Simulator::StackTop() const {
  // To be safe in potential stack underflows we leave some buffer above and
  // set the stack top.
  return reinterpret_cast<uword>(stack_) +
      (Isolate::GetSpecifiedStackSize() + Isolate::kStackSizeBuffer);
}


// Unsupported instructions use Format to print an error and stop execution.
void Simulator::Format(Instr* instr, const char* format) {
  OS::Print("Simulator found unsupported instruction:\n 0x%p: %s\n",
            instr,
            format);
  UNIMPLEMENTED();
}


// Calculate and set the Negative and Zero flags.
void Simulator::SetNZFlagsW(int32_t val) {
  n_flag_ = (val < 0);
  z_flag_ = (val == 0);
}


// Calculate C flag value for additions.
bool Simulator::CarryFromW(int32_t left, int32_t right) {
  uint32_t uleft = static_cast<uint32_t>(left);
  uint32_t uright = static_cast<uint32_t>(right);
  uint32_t urest  = 0xffffffffU - uleft;

  return (uright > urest);
}


// Calculate C flag value for subtractions.
bool Simulator::BorrowFromW(int32_t left, int32_t right) {
  uint32_t uleft = static_cast<uint32_t>(left);
  uint32_t uright = static_cast<uint32_t>(right);

  return (uright > uleft);
}


// Calculate V flag value for additions and subtractions.
bool Simulator::OverflowFromW(int32_t alu_out,
                              int32_t left, int32_t right, bool addition) {
  bool overflow;
  if (addition) {
               // operands have the same sign
    overflow = ((left >= 0 && right >= 0) || (left < 0 && right < 0))
               // and operands and result have different sign
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  } else {
               // operands have different signs
    overflow = ((left < 0 && right >= 0) || (left >= 0 && right < 0))
               // and first operand and result have different signs
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  }
  return overflow;
}


// Calculate and set the Negative and Zero flags.
void Simulator::SetNZFlagsX(int64_t val) {
  n_flag_ = (val < 0);
  z_flag_ = (val == 0);
}


// Calculate C flag value for additions.
bool Simulator::CarryFromX(int64_t left, int64_t right) {
  uint64_t uleft = static_cast<uint64_t>(left);
  uint64_t uright = static_cast<uint64_t>(right);
  uint64_t urest  = 0xffffffffffffffffULL - uleft;

  return (uright > urest);
}


// Calculate C flag value for subtractions.
bool Simulator::BorrowFromX(int64_t left, int64_t right) {
  uint64_t uleft = static_cast<uint64_t>(left);
  uint64_t uright = static_cast<uint64_t>(right);

  return (uright > uleft);
}


// Calculate V flag value for additions and subtractions.
bool Simulator::OverflowFromX(int64_t alu_out,
                              int64_t left, int64_t right, bool addition) {
  bool overflow;
  if (addition) {
               // operands have the same sign
    overflow = ((left >= 0 && right >= 0) || (left < 0 && right < 0))
               // and operands and result have different sign
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  } else {
               // operands have different signs
    overflow = ((left < 0 && right >= 0) || (left >= 0 && right < 0))
               // and first operand and result have different signs
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  }
  return overflow;
}


// Set the Carry flag.
void Simulator::SetCFlag(bool val) {
  c_flag_ = val;
}


// Set the oVerflow flag.
void Simulator::SetVFlag(bool val) {
  v_flag_ = val;
}


void Simulator::DecodeMoveWide(Instr* instr) {
  const Register rd = instr->RdField();
  const int hw = instr->HWField();
  const int64_t shift = hw << 4;
  const int64_t shifted_imm =
      static_cast<uint64_t>(instr->Imm16Field()) << shift;

  if (instr->SFField()) {
    if (instr->Bits(29, 2) == 0) {
      // Format(instr, "movn'sf 'rd, 'imm16 'hw");
      set_register(rd, ~shifted_imm, instr->RdMode());
    } else if (instr->Bits(29, 2) == 2) {
      // Format(instr, "movz'sf 'rd, 'imm16 'hw");
      set_register(rd, shifted_imm, instr->RdMode());
    } else if (instr->Bits(29, 2) == 3) {
      // Format(instr, "movk'sf 'rd, 'imm16 'hw");
      const int64_t rd_val = get_register(rd, instr->RdMode());
      const int64_t result = (rd_val & ~(0xffffL << shift)) | shifted_imm;
      set_register(rd, result, instr->RdMode());
    } else {
      UnimplementedInstruction(instr);
    }
  } else if ((hw & 0x2) == 0) {
    if (instr->Bits(29, 2) == 0) {
      // Format(instr, "movn'sf 'rd, 'imm16 'hw");
      set_wregister(rd, ~shifted_imm & kWRegMask,  instr->RdMode());
    } else if (instr->Bits(29, 2) == 2) {
      // Format(instr, "movz'sf 'rd, 'imm16 'hw");
      set_wregister(rd, shifted_imm & kWRegMask, instr->RdMode());
    } else if (instr->Bits(29, 2) == 3) {
      // Format(instr, "movk'sf 'rd, 'imm16 'hw");
      const int32_t rd_val = get_wregister(rd, instr->RdMode());
      const int32_t result = (rd_val & ~(0xffffL << shift)) | shifted_imm;
      set_wregister(rd, result, instr->RdMode());
    } else {
      UnimplementedInstruction(instr);
    }
  } else {
    // Dest is 32 bits, but shift is more than 32.
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeAddSubImm(Instr* instr) {
  bool addition = (instr->Bit(30) == 0);
  // Format(instr, "addi'sf's 'rd, 'rn, 'imm12s");
  // Format(instr, "subi'sf's 'rd, 'rn, 'imm12s");
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const uint32_t imm = (instr->Bit(22) == 1) ? (instr->Imm12Field() << 12)
                                             : (instr->Imm12Field());
  if (instr->SFField()) {
    // 64-bit add.
    const int64_t rn_val = get_register(rn, instr->RnMode());
    const int64_t alu_out = addition ? (rn_val + imm) : (rn_val - imm);
    set_register(rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsX(alu_out);
      SetCFlag(CarryFromX(rn_val, imm));
      SetVFlag(OverflowFromX(alu_out, rn_val, imm, addition));
    }
  } else {
    // 32-bit add.
    const int32_t rn_val = get_wregister(rn, instr->RnMode());
    const int32_t alu_out = addition ? (rn_val + imm) : (rn_val - imm);
    set_wregister(rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsW(alu_out);
      SetCFlag(CarryFromW(rn_val, imm));
      SetVFlag(OverflowFromW(alu_out, rn_val, imm, addition));
    }
  }
}

void Simulator::DecodeDPImmediate(Instr* instr) {
  if (instr->IsMoveWideOp()) {
    DecodeMoveWide(instr);
  } else if (instr->IsAddSubImmOp()) {
    DecodeAddSubImm(instr);
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeExceptionGen(Instr* instr) {
  UnimplementedInstruction(instr);
}


void Simulator::DecodeSystem(Instr* instr) {
  if ((instr->Bits(0, 8) == 0x5f) && (instr->Bits(12, 4) == 2) &&
      (instr->Bits(16, 3) == 3) && (instr->Bits(19, 2) == 0) &&
      (instr->Bit(21) == 0)) {
    if (instr->Bits(8, 4) == 0) {
      // Format(instr, "nop");
    } else {
      UnimplementedInstruction(instr);
    }
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeUnconditionalBranchReg(Instr* instr) {
  if ((instr->Bits(0, 5) == 0) && (instr->Bits(10, 6) == 0) &&
      (instr->Bits(16, 5) == 0x1f)) {
    switch (instr->Bits(21, 4)) {
      case 2: {
        // Format(instr, "ret 'rn");
        const Register rn = instr->RnField();
        const int64_t rn_val = get_register(rn, instr->RnMode());
        set_pc(rn_val);
        break;
      }
      default:
        UnimplementedInstruction(instr);
        break;
    }
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeCompareBranch(Instr* instr) {
  if (instr->IsExceptionGenOp()) {
    DecodeExceptionGen(instr);
  } else if (instr->IsSystemOp()) {
    DecodeSystem(instr);
  } else if (instr->IsUnconditionalBranchRegOp()) {
    DecodeUnconditionalBranchReg(instr);
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeLoadStore(Instr* instr) {
  UnimplementedInstruction(instr);
}


int64_t Simulator::ShiftOperand(uint8_t reg_size,
                                int64_t value,
                                Shift shift_type,
                                uint8_t amount) {
  if (amount == 0) {
    return value;
  }
  int64_t mask = reg_size == kXRegSizeInBits ? kXRegMask : kWRegMask;
  switch (shift_type) {
    case LSL:
      return (value << amount) & mask;
    case LSR:
      return static_cast<uint64_t>(value) >> amount;
    case ASR: {
      // Shift used to restore the sign.
      uint8_t s_shift = kXRegSizeInBits - reg_size;
      // Value with its sign restored.
      int64_t s_value = (value << s_shift) >> s_shift;
      return (s_value >> amount) & mask;
    }
    case ROR: {
      if (reg_size == kWRegSizeInBits) {
        value &= kWRegMask;
      }
      return (static_cast<uint64_t>(value) >> amount) |
             ((value & ((1L << amount) - 1L)) << (reg_size - amount));
    }
    default:
      UNIMPLEMENTED();
      return 0;
  }
}


int64_t Simulator::ExtendOperand(uint8_t reg_size,
                                 int64_t value,
                                 Extend extend_type,
                                 uint8_t amount) {
  switch (extend_type) {
    case UXTB:
      value &= 0xff;
      break;
    case UXTH:
      value &= 0xffff;
      break;
    case UXTW:
      value &= 0xffffffff;
      break;
    case SXTB:
      value = (value << 56) >> 56;
      break;
    case SXTH:
      value = (value << 48) >> 48;
      break;
    case SXTW:
      value = (value << 32) >> 32;
      break;
    case UXTX:
    case SXTX:
      break;
    default:
      UNREACHABLE();
  }
  int64_t mask = (reg_size == kXRegSizeInBits) ? kXRegMask : kWRegMask;
  return (value << amount) & mask;
}


int64_t Simulator::DecodeShiftExtendOperand(Instr* instr) {
  const Register rm = instr->RmField();
  const int64_t rm_val = get_register(rm, R31IsZR);
  const uint8_t size = instr->SFField() ? kXRegSizeInBits : kWRegSizeInBits;
  if (instr->IsShift()) {
    const Shift shift_type = instr->ShiftTypeField();
    const uint8_t shift_amount = instr->Imm6Field();
    return ShiftOperand(size, rm_val, shift_type, shift_amount);
  } else {
    ASSERT(instr->IsExtend());
    const Extend extend_type = instr->ExtendTypeField();
    const uint8_t shift_amount = instr->Imm3Field();
    return ExtendOperand(size, rm_val, extend_type, shift_amount);
  }
  UNREACHABLE();
  return -1;
}


void Simulator::DecodeAddSubShiftExt(Instr* instr) {
  switch (instr->Bit(30)) {
    case 0: {
      // Format(instr, "add'sf's 'rd, 'rn, 'shift_op");
      const Register rd = instr->RdField();
      const Register rn = instr->RnField();
      const int64_t rm_val = DecodeShiftExtendOperand(instr);
      if (instr->SFField()) {
        // 64-bit add.
        const int64_t rn_val = get_register(rn, instr->RnMode());
        const int64_t alu_out = rn_val + rm_val;
        set_register(rd, alu_out, instr->RdMode());
        if (instr->HasS()) {
          SetNZFlagsX(alu_out);
          SetCFlag(CarryFromX(rn_val, rm_val));
          SetVFlag(OverflowFromX(alu_out, rn_val, rm_val, true));
        }
      } else {
        // 32-bit add.
        const int32_t rn_val = get_wregister(rn, instr->RnMode());
        const int32_t rm_val32 = static_cast<int32_t>(rm_val & kWRegMask);
        const int32_t alu_out = rn_val + rm_val32;
        set_wregister(rd, alu_out, instr->RdMode());
        if (instr->HasS()) {
          SetNZFlagsW(alu_out);
          SetCFlag(CarryFromW(rn_val, rm_val32));
          SetVFlag(OverflowFromW(alu_out, rn_val, rm_val32, true));
        }
      }
      break;
    }
    default:
      UnimplementedInstruction(instr);
      break;
  }
}


void Simulator::DecodeDPRegister(Instr* instr) {
  if (instr->IsAddSubShiftExtOp()) {
    DecodeAddSubShiftExt(instr);
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeDPSimd1(Instr* instr) {
  UnimplementedInstruction(instr);
}


void Simulator::DecodeDPSimd2(Instr* instr) {
  UnimplementedInstruction(instr);
}


// Executes the current instruction.
void Simulator::InstructionDecode(Instr* instr) {
  pc_modified_ = false;
  if (FLAG_trace_sim) {
    const uword start = reinterpret_cast<uword>(instr);
    const uword end = start + Instr::kInstrSize;
    Disassembler::Disassemble(start, end);
  }

  if (instr->IsDPImmediateOp()) {
    DecodeDPImmediate(instr);
  } else if (instr->IsCompareBranchOp()) {
    DecodeCompareBranch(instr);
  } else if (instr->IsLoadStoreOp()) {
    DecodeLoadStore(instr);
  } else if (instr->IsDPRegisterOp()) {
    DecodeDPRegister(instr);
  } else if (instr->IsDPSimd1Op()) {
    DecodeDPSimd1(instr);
  } else {
    ASSERT(instr->IsDPSimd2Op());
    DecodeDPSimd2(instr);
  }

  if (!pc_modified_) {
    set_pc(reinterpret_cast<int64_t>(instr) + Instr::kInstrSize);
  }
}


void Simulator::Execute() {
  // Get the PC to simulate. Cannot use the accessor here as we need the
  // raw PC value and not the one used as input to arithmetic instructions.
  uword program_counter = get_pc();

  if (FLAG_stop_sim_at == 0) {
    // Fast version of the dispatch loop without checking whether the simulator
    // should be stopping at a particular executed instruction.
    while (program_counter != kEndSimulatingPC) {
      Instr* instr = reinterpret_cast<Instr*>(program_counter);
      icount_++;
      if (IsIllegalAddress(program_counter)) {
        HandleIllegalAccess(program_counter, instr);
      } else {
        InstructionDecode(instr);
      }
      program_counter = get_pc();
    }
  } else {
    // FLAG_stop_sim_at is at the non-default value. Stop in the debugger when
    // we reach the particular instruction count.
    while (program_counter != kEndSimulatingPC) {
      Instr* instr = reinterpret_cast<Instr*>(program_counter);
      icount_++;
      if (icount_ == FLAG_stop_sim_at) {
        // TODO(zra): Add a debugger.
        UNIMPLEMENTED();
      } else if (IsIllegalAddress(program_counter)) {
        HandleIllegalAccess(program_counter, instr);
      } else {
        InstructionDecode(instr);
      }
      program_counter = get_pc();
    }
  }
}


int64_t Simulator::Call(int64_t entry,
                        int64_t parameter0,
                        int64_t parameter1,
                        int64_t parameter2,
                        int64_t parameter3) {
  // Save the SP register before the call so we can restore it.
  int32_t sp_before_call = get_register(SP, R31IsSP);

  // Setup parameters.
  set_register(R0, parameter0);
  set_register(R1, parameter1);
  set_register(R2, parameter2);
  set_register(R3, parameter3);

  // Make sure the activation frames are properly aligned.
  int32_t stack_pointer = sp_before_call;
  if (OS::ActivationFrameAlignment() > 1) {
    stack_pointer =
        Utils::RoundDown(stack_pointer, OS::ActivationFrameAlignment());
  }
  set_register(SP, stack_pointer, R31IsSP);

  // Prepare to execute the code at entry.
  set_pc(entry);
  // Put down marker for end of simulation. The simulator will stop simulation
  // when the PC reaches this value. By saving the "end simulation" value into
  // the LR the simulation stops when returning to this call point.
  set_register(LR, kEndSimulatingPC);

  // Remember the values of callee-saved registers.
  int64_t r19_val = get_register(R19);
  int64_t r20_val = get_register(R20);
  int64_t r21_val = get_register(R21);
  int64_t r22_val = get_register(R22);
  int64_t r23_val = get_register(R23);
  int64_t r24_val = get_register(R24);
  int64_t r25_val = get_register(R25);
  int64_t r26_val = get_register(R26);
  int64_t r27_val = get_register(R27);
  int64_t r28_val = get_register(R28);
  int64_t r29_val = get_register(R29);

  // Setup the callee-saved registers with a known value. To be able to check
  // that they are preserved properly across dart execution.
  int64_t callee_saved_value = icount_;
  set_register(R19, callee_saved_value);
  set_register(R20, callee_saved_value);
  set_register(R21, callee_saved_value);
  set_register(R22, callee_saved_value);
  set_register(R23, callee_saved_value);
  set_register(R24, callee_saved_value);
  set_register(R25, callee_saved_value);
  set_register(R26, callee_saved_value);
  set_register(R27, callee_saved_value);
  set_register(R28, callee_saved_value);
  set_register(R29, callee_saved_value);

  // Start the simulation
  Execute();

  // Check that the callee-saved registers have been preserved.
  ASSERT(callee_saved_value == get_register(R19));
  ASSERT(callee_saved_value == get_register(R20));
  ASSERT(callee_saved_value == get_register(R21));
  ASSERT(callee_saved_value == get_register(R22));
  ASSERT(callee_saved_value == get_register(R23));
  ASSERT(callee_saved_value == get_register(R24));
  ASSERT(callee_saved_value == get_register(R25));
  ASSERT(callee_saved_value == get_register(R26));
  ASSERT(callee_saved_value == get_register(R27));
  ASSERT(callee_saved_value == get_register(R28));
  ASSERT(callee_saved_value == get_register(R29));

  // Restore callee-saved registers with the original value.
  set_register(R19, r19_val);
  set_register(R20, r20_val);
  set_register(R21, r21_val);
  set_register(R22, r22_val);
  set_register(R23, r23_val);
  set_register(R24, r24_val);
  set_register(R25, r25_val);
  set_register(R26, r26_val);
  set_register(R27, r27_val);
  set_register(R28, r28_val);
  set_register(R29, r29_val);

  // Restore the SP register and return R1:R0.
  set_register(SP, sp_before_call, R31IsSP);
  int64_t return_value;
  return_value = get_register(R0);
  return return_value;
}

}  // namespace dart

#endif  // !defined(HOST_ARCH_ARM64)

#endif  // defined TARGET_ARCH_ARM64
