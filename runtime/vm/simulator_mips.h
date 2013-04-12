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

class Isolate;
class SimulatorSetjmpBuffer;

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
  void set_fregister(FRegister freg, int32_t value);
  void set_fregister_float(FRegister freg, float value);
  void set_fregister_double(FRegister freg, double value);
  void set_fregister_long(FRegister freg, int64_t value);

  int32_t get_fregister(FRegister freg) const;
  float get_fregister_float(FRegister freg) const;
  double get_fregister_double(FRegister freg) const;
  int64_t get_fregister_long(FRegister freg) const;


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

  // The isolate's top_exit_frame_info refers to a Dart frame in the simulator
  // stack. The simulator's top_exit_frame_info refers to a C++ frame in the
  // native stack.
  uword top_exit_frame_info() const { return top_exit_frame_info_; }
  void set_top_exit_frame_info(uword value) { top_exit_frame_info_ = value; }

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

  // Runtime and native call support.
  enum CallKind {
    kRuntimeCall,
    kLeafRuntimeCall,
    kNativeCall
  };
  static uword RedirectExternalReference(uword function, CallKind call_kind);

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
  int32_t fregisters_[kNumberOfFRegisters];
  uword pc_;

  // Simulator support.
  char* stack_;
  int icount_;
  bool delay_slot_;
  SimulatorSetjmpBuffer* last_setjmp_buffer_;
  uword top_exit_frame_info_;

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

  inline double ReadD(uword addr, Instr* instr);
  inline void WriteD(uword addr, double value, Instr* instr);

  void DoBranch(Instr* instr, bool taken, bool likely);
  void DoBreak(Instr *instr);

  void DecodeSpecial(Instr* instr);
  void DecodeSpecial2(Instr* instr);
  void DecodeRegImm(Instr* instr);
  void DecodeCop1(Instr* instr);
  void InstructionDecode(Instr* instr);

  void Execute();
  void ExecuteDelaySlot();

  // Longjmp support for exceptions.
  SimulatorSetjmpBuffer* last_setjmp_buffer() {
    return last_setjmp_buffer_;
  }
  void set_last_setjmp_buffer(SimulatorSetjmpBuffer* buffer) {
    last_setjmp_buffer_ = buffer;
  }

  friend class SimulatorDebugger;
  friend class SimulatorSetjmpBuffer;
};

}  // namespace dart

#endif  // VM_SIMULATOR_MIPS_H_
