// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SIMULATOR_RISCV_H_
#define RUNTIME_VM_SIMULATOR_RISCV_H_

#ifndef RUNTIME_VM_SIMULATOR_H_
#error Do not include simulator_riscv.h directly; use simulator.h.
#endif

#include "vm/constants.h"
#include "vm/random.h"

namespace dart {

class Isolate;
class Mutex;
class SimulatorSetjmpBuffer;
class Thread;

// TODO(riscv): Introduce random LR/SC failures.
// TODO(riscv): Dynamic rounding mode and other FSCR state.
class Simulator {
 public:
  static constexpr uword kSimulatorStackUnderflowSize = 64;

  Simulator();
  ~Simulator();

  static Simulator* Current();

  intx_t CallX(intx_t function,
               intx_t arg0 = 0,
               intx_t arg1 = 0,
               intx_t arg2 = 0,
               intx_t arg3 = 0) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_xreg(A0, arg0);
    set_xreg(A1, arg1);
    set_xreg(A2, arg2);
    set_xreg(A3, arg3);
    RunCall(function, &preserved);
    return get_xreg(A0);
  }

  intx_t CallI(intx_t function, double arg0, double arg1 = 0.0) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_fregd(FA0, arg0);
    set_fregd(FA1, arg1);
    RunCall(function, &preserved);
    return get_xreg(A0);
  }
  intx_t CallI(intx_t function, float arg0, float arg1 = 0.0f) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_fregs(FA0, arg0);
    set_fregs(FA1, arg1);
    RunCall(function, &preserved);
    return get_xreg(A0);
  }

  double CallD(intx_t function, intx_t arg0, intx_t arg1 = 0) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_xreg(A0, arg0);
    set_xreg(A1, arg1);
    RunCall(function, &preserved);
    return get_fregd(FA0);
  }
  double CallD(intx_t function,
               double arg0,
               double arg1 = 0.0,
               double arg2 = 0.0) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_fregd(FA0, arg0);
    set_fregd(FA1, arg1);
    set_fregd(FA2, arg2);
    RunCall(function, &preserved);
    return get_fregd(FA0);
  }
  double CallD(intx_t function, intx_t arg0, double arg1) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_xreg(A0, arg0);
    set_fregd(FA0, arg1);
    RunCall(function, &preserved);
    return get_fregd(FA0);
  }
  double CallD(intx_t function, float arg0) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_fregs(FA0, arg0);
    RunCall(function, &preserved);
    return get_fregd(FA0);
  }

  float CallF(intx_t function, intx_t arg0, intx_t arg1 = 0) {
    PreservedRegisters preserved;
    SavePreservedRegisters(&preserved);
    set_xreg(A0, arg0);
    set_xreg(A1, arg1);
    RunCall(function, &preserved);
    return get_fregs(FA0);
  }
  float CallF(intx_t function,
              float arg0,
              float arg1 = 0.0f,
              float arg2 = 0.0f) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_fregs(FA0, arg0);
    set_fregs(FA1, arg1);
    set_fregs(FA2, arg2);
    RunCall(function, &preserved);
    return get_fregs(FA0);
  }
  float CallF(intx_t function, intx_t arg0, float arg1) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_xreg(A0, arg0);
    set_fregs(FA0, arg1);
    RunCall(function, &preserved);
    return get_fregs(FA0);
  }
  float CallF(intx_t function, double arg0) {
    PreservedRegisters preserved;
    PrepareCall(&preserved);
    set_fregd(FA0, arg0);
    RunCall(function, &preserved);
    return get_fregs(FA0);
  }

  // Dart generally calls into generated code with 4 parameters. This is a
  // convenience function, which sets up the simulator state and grabs the
  // result on return. The return value is A0. The parameters are placed in
  // A0-3.
  int64_t Call(intx_t entry,
               intx_t parameter0,
               intx_t parameter1,
               intx_t parameter2,
               intx_t parameter3,
               bool fp_return = false,
               bool fp_args = false);

  // Runtime and native call support.
  enum CallKind {
    kRuntimeCall,
    kLeafRuntimeCall,
    kLeafFloatRuntimeCall,
    kNativeCallWrapper
  };
  static uword RedirectExternalReference(uword function,
                                         CallKind call_kind,
                                         int argument_count);

  static uword FunctionForRedirect(uword redirect);

  void JumpToFrame(uword pc, uword sp, uword fp, Thread* thread);

  uintx_t get_register(Register rs) const { return get_xreg(rs); }
  uintx_t get_pc() const { return pc_; }
  uintx_t get_sp() const { return get_xreg(SP); }
  uintx_t get_fp() const { return get_xreg(FP); }
  uintx_t get_lr() const { return get_xreg(RA); }
  void PrintRegisters();
  void PrintStack();

  // High address.
  uword stack_base() const { return stack_base_; }
  // Limit for StackOverflowError.
  uword overflow_stack_limit() const { return overflow_stack_limit_; }
  // Low address.
  uword stack_limit() const { return stack_limit_; }

  // Accessor to the instruction counter.
  uint64_t get_icount() const { return instret_; }

  // Call on program start.
  static void Init();

 private:
  struct PreservedRegisters {
    uintx_t xregs[kNumberOfCpuRegisters];
    double fregs[kNumberOfFpuRegisters];
  };
  void PrepareCall(PreservedRegisters* preserved);
  void ClobberVolatileRegisters();
  void SavePreservedRegisters(PreservedRegisters* preserved);
  void CheckPreservedRegisters(PreservedRegisters* preserved);
  void RunCall(intx_t function, PreservedRegisters* preserved);

  void Interpret(Instr instr);
  void Interpret(CInstr instr);
  void InterpretLUI(Instr instr);
  void InterpretAUIPC(Instr instr);
  void InterpretJAL(Instr instr);
  void InterpretJALR(Instr instr);
  void InterpretBRANCH(Instr instr);
  void InterpretLOAD(Instr instr);
  void InterpretSTORE(Instr instr);
  void InterpretOPIMM(Instr instr);
  void InterpretOPIMM32(Instr instr);
  void InterpretOP(Instr instr);
  void InterpretOP_0(Instr instr);
  void InterpretOP_SUB(Instr instr);
  void InterpretOP_MULDIV(Instr instr);
  void InterpretOP_SHADD(Instr instr);
  void InterpretOP_MINMAXCLMUL(Instr instr);
  void InterpretOP_ROTATE(Instr instr);
  void InterpretOP_BCLRBEXT(Instr instr);
  void InterpretOP32(Instr instr);
  void InterpretOP32_0(Instr instr);
  void InterpretOP32_SUB(Instr instr);
  void InterpretOP32_MULDIV(Instr instr);
  void InterpretOP32_SHADD(Instr instr);
  void InterpretOP32_ADDUW(Instr instr);
  void InterpretOP32_ROTATE(Instr instr);
  void InterpretMISCMEM(Instr instr);
  void InterpretSYSTEM(Instr instr);
  void InterpretECALL(Instr instr);
  void InterpretEBREAK(Instr instr);
  void InterpretEBREAK(CInstr instr);
  void InterpretAMO(Instr instr);
  void InterpretAMO32(Instr instr);
  void InterpretAMO64(Instr instr);
  template <typename type>
  void InterpretLR(Instr instr);
  template <typename type>
  void InterpretSC(Instr instr);
  template <typename type>
  void InterpretAMOSWAP(Instr instr);
  template <typename type>
  void InterpretAMOADD(Instr instr);
  template <typename type>
  void InterpretAMOXOR(Instr instr);
  template <typename type>
  void InterpretAMOAND(Instr instr);
  template <typename type>
  void InterpretAMOOR(Instr instr);
  template <typename type>
  void InterpretAMOMIN(Instr instr);
  template <typename type>
  void InterpretAMOMAX(Instr instr);
  template <typename type>
  void InterpretAMOMINU(Instr instr);
  template <typename type>
  void InterpretAMOMAXU(Instr instr);
  void InterpretLOADFP(Instr instr);
  void InterpretSTOREFP(Instr instr);
  void InterpretFMADD(Instr instr);
  void InterpretFMSUB(Instr instr);
  void InterpretFNMADD(Instr instr);
  void InterpretFNMSUB(Instr instr);
  void InterpretOPFP(Instr instr);
  DART_NORETURN void IllegalInstruction(Instr instr);
  DART_NORETURN void IllegalInstruction(CInstr instr);

  template <typename type>
  type MemoryRead(uintx_t address, Register base);
  template <typename type>
  void MemoryWrite(uintx_t address, type value, Register base);

  intx_t CSRRead(uint16_t csr);
  void CSRWrite(uint16_t csr, intx_t value);
  void CSRSet(uint16_t csr, intx_t mask);
  void CSRClear(uint16_t csr, intx_t mask);

  uintx_t get_xreg(Register rs) const { return xregs_[rs]; }
  void set_xreg(Register rd, uintx_t value) {
    if (rd != ZR) {
      xregs_[rd] = value;
    }
  }

  double get_fregd(FRegister rs) const { return fregs_[rs]; }
  void set_fregd(FRegister rd, double value) { fregs_[rd] = value; }

  static constexpr uint64_t kNaNBox = 0xFFFFFFFF00000000;

  float get_fregs(FRegister rs) const {
    uint64_t bits64 = bit_cast<uint64_t>(fregs_[rs]);
    if ((bits64 & kNaNBox) != kNaNBox) {
      // When the register value isn't a valid NaN, the canonical NaN is used
      // instead.
      return bit_cast<float>(0x7fc00000);
    }
    uint32_t bits32 = static_cast<uint32_t>(bits64);
    return bit_cast<float>(bits32);
  }
  void set_fregs(FRegister rd, float value) {
    uint32_t bits32 = bit_cast<uint32_t>(value);
    uint64_t bits64 = static_cast<uint64_t>(bits32);
    bits64 |= kNaNBox;
    fregs_[rd] = bit_cast<double>(bits64);
  }

  // Known bad pc value to ensure that the simulator does not execute
  // without being properly setup.
  static constexpr uword kBadLR = -1;
  // A pc value used to signal the simulator to stop execution.  Generally
  // the lr is set to this value on transition from native C code to
  // simulated execution, so that the simulator can "return" to the native
  // C code.
  static constexpr uword kEndSimulatingPC = -2;

  // I state.
  uintx_t pc_;
  uintx_t xregs_[kNumberOfCpuRegisters];
  uint64_t instret_;  // "Instructions retired" - mandatory counter.

  // A state.
  uintx_t reserved_address_;
  uintx_t reserved_value_;

  // F/D state.
  double fregs_[kNumberOfFpuRegisters];
  uint32_t fcsr_;

  // Simulator support.
  char* stack_;
  uword stack_limit_;
  uword overflow_stack_limit_;
  uword stack_base_;
  Random random_;
  SimulatorSetjmpBuffer* last_setjmp_buffer_;

  static bool IsIllegalAddress(uword addr) { return addr < 64 * 1024; }

  // Executes RISC-V instructions until the PC reaches kEndSimulatingPC.
  void Execute();
  void ExecuteNoTrace();
  void ExecuteTrace();

  // Returns true if tracing of executed instructions is enabled.
  bool IsTracingExecution() const;

  // Longjmp support for exceptions.
  SimulatorSetjmpBuffer* last_setjmp_buffer() { return last_setjmp_buffer_; }
  void set_last_setjmp_buffer(SimulatorSetjmpBuffer* buffer) {
    last_setjmp_buffer_ = buffer;
  }

  friend class SimulatorSetjmpBuffer;
  DISALLOW_COPY_AND_ASSIGN(Simulator);
};

}  // namespace dart

#endif  // RUNTIME_VM_SIMULATOR_RISCV_H_
