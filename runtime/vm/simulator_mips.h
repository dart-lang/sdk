// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declares a Simulator for MIPS instructions if we are not generating a native
// MIPS binary. This Simulator allows us to run and debug MIPS code generation
// on regular desktop machines.
// Dart calls into generated code by "calling" the InvokeDartCode stub,
// which will start execution in the Simulator or forwards to the real entry
// on a MIPS HW platform.

#ifndef VM_SIMULATOR_MIPS_H_
#define VM_SIMULATOR_MIPS_H_

#ifndef VM_SIMULATOR_H_
#error Do not include simulator_mips.h directly; use simulator.h.
#endif

#include "vm/constants_mips.h"

namespace dart {

class Simulator {
 public:
  static const uword kSimulatorStackUnderflowSize = 64;

  Simulator();
  ~Simulator();

  // The currently executing Simulator instance, which is associated to the
  // current isolate
  static Simulator* Current();

  // Accessors for register state.
  void set_register(Register reg, int32_t value);
  int32_t get_register(Register reg) const;

  // Accessors for floating point register state.
  void set_fregister(FRegister freg, double value);
  double get_fregister(FRegister) const;

  // Accessor for the pc.
  void set_pc(int32_t value) { pc_ = value; }
  int32_t get_pc() const { return pc_; }

  // Accessors for hi, lo registers.
  void set_hi_register(int32_t value) { hi_reg_ = value; }
  void set_lo_register(int32_t value) { lo_reg_ = value; }
  int32_t get_hi_register() const { return hi_reg_; }
  int32_t get_lo_register() const { return lo_reg_; }

  // Accessor to the internal simulator stack top.
  uword StackTop() const;

  // Call on program start.
  static void InitOnce();

  // Dart generally calls into generated code with 5 parameters. This is a
  // convenience function, which sets up the simulator state and grabs the
  // result on return.
  int64_t Call(int32_t entry,
               int32_t parameter0,
               int32_t parameter1,
               int32_t parameter2,
               int32_t parameter3);

 private:
  // A pc value used to signal the simulator to stop execution.  Generally
  // the ra is set to this value on transition from native C code to
  // simulated execution, so that the simulator can "return" to the native
  // C code.
  static const uword kEndSimulatingPC = -1;

  // Special registers for the results of div, divu.
  int32_t hi_reg_;
  int32_t lo_reg_;

  int32_t registers_[kNumberOfCpuRegisters];
  double fregisters_[kNumberOfFRegisters];
  uword pc_;

  // Simulator support.
  char* stack_;
  int icount_;
  bool delay_slot_;

  // Registered breakpoints.
  Instr* break_pc_;
  int32_t break_instr_;

  // Illegal memory access support.
  static bool IsIllegalAddress(uword addr) {
    return addr < 64*1024;
  }
  void HandleIllegalAccess(uword addr, Instr* instr);

  // Read and write memory.
  void UnalignedAccess(const char* msg, uword addr, Instr* instr);

  // Handles a legal instruction that the simulator does not implement.
  void UnimplementedInstruction(Instr* instr);

  bool OverflowFrom(int32_t alu_out,
                    int32_t left,
                    int32_t right,
                    bool addition);

  void set_pc(uword value) { pc_ = value; }

  void Format(Instr* instr, const char* format);

  inline int8_t ReadB(uword addr);
  inline uint8_t ReadBU(uword addr);
  inline int16_t ReadH(uword addr, Instr* instr);
  inline uint16_t ReadHU(uword addr, Instr *instr);
  inline int ReadW(uword addr, Instr* instr);

  inline void WriteB(uword addr, uint8_t value);
  inline void WriteH(uword addr, uint16_t value, Instr* isntr);
  inline void WriteW(uword addr, int value, Instr* instr);

  void DoBranch(Instr* instr, bool taken, bool likely);
  void DecodeSpecial(Instr* instr);
  void DecodeSpecial2(Instr* instr);
  void DecodeRegImm(Instr* instr);
  void InstructionDecode(Instr* instr);

  void Execute();
  void ExecuteDelaySlot();

  friend class SimulatorDebugger;
};

}  // namespace dart

#endif  // VM_SIMULATOR_MIPS_H_
