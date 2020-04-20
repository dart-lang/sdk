// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declares a Simulator for ARM instructions if we are not generating a native
// ARM binary. This Simulator allows us to run and debug ARM code generation on
// regular desktop machines.
// Dart calls into generated code by "calling" the InvokeDartCode stub,
// which will start execution in the Simulator or forwards to the real entry
// on a ARM HW platform.

#ifndef RUNTIME_VM_SIMULATOR_ARM_H_
#define RUNTIME_VM_SIMULATOR_ARM_H_

#ifndef RUNTIME_VM_SIMULATOR_H_
#error Do not include simulator_arm.h directly; use simulator.h.
#endif

#include "vm/constants.h"

namespace dart {

class Isolate;
class Mutex;
class RawObject;
class SimulatorSetjmpBuffer;
class Thread;

#if !defined(SIMD_VALUE_T_)
typedef struct {
  union {
    uint32_t u;
    float f;
  } data_[4];
} simd_value_t;
#endif

class Simulator {
 public:
  static const uword kSimulatorStackUnderflowSize = 64;

  Simulator();
  ~Simulator();

  // The currently executing Simulator instance, which is associated to the
  // current isolate
  static Simulator* Current();

  // Accessors for register state. Reading the pc value adheres to the ARM
  // architecture specification and is off by 8 from the currently executing
  // instruction.
  void set_register(Register reg, int32_t value);
  DART_FORCE_INLINE int32_t get_register(Register reg) const {
    ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
    return registers_[reg] + ((reg == PC) ? Instr::kPCReadOffset : 0);
  }

  int32_t get_sp() const { return get_register(SPREG); }

  // Special case of set_register and get_register to access the raw PC value.
  void set_pc(int32_t value);
  DART_FORCE_INLINE int32_t get_pc() const { return registers_[PC]; }

  // Accessors for VFP register state.
  void set_sregister(SRegister reg, float value);
  float get_sregister(SRegister reg) const;
  void set_dregister(DRegister reg, double value);
  double get_dregister(DRegister reg) const;
  void set_qregister(QRegister reg, const simd_value_t& value);
  void get_qregister(QRegister reg, simd_value_t* value) const;

  // When moving integer (rather than floating point) values to/from
  // the FPU registers, use the _bits calls to avoid gcc taking liberties with
  // integers that map to such things as NaN floating point values.
  void set_sregister_bits(SRegister reg, int32_t value);
  int32_t get_sregister_bits(SRegister reg) const;
  void set_dregister_bits(DRegister reg, int64_t value);
  int64_t get_dregister_bits(DRegister reg) const;

  // High address.
  uword stack_base() const { return stack_base_; }
  // Limit for StackOverflowError.
  uword overflow_stack_limit() const { return overflow_stack_limit_; }
  // Low address.
  uword stack_limit() const { return stack_limit_; }

  // Accessor to the instruction counter.
  uint64_t get_icount() const { return icount_; }

  // Call on program start.
  static void Init();

  // Dart generally calls into generated code with 4 parameters. This is a
  // convenience function, which sets up the simulator state and grabs the
  // result on return. When fp_return is true the return value is the D0
  // floating point register. Otherwise, the return value is R1:R0.
  // If fp_args is true, the parameters0-3 are placed in S0-3. Otherwise, they
  // are placed in R0-3.
  int64_t Call(int32_t entry,
               int32_t parameter0,
               int32_t parameter1,
               int32_t parameter2,
               int32_t parameter3,
               bool fp_return = false,
               bool fp_args = false);

  // Runtime and native call support.
  enum CallKind {
    kRuntimeCall,
    kLeafRuntimeCall,
    kLeafFloatRuntimeCall,
    kBootstrapNativeCall,
    kNativeCall
  };
  static uword RedirectExternalReference(uword function,
                                         CallKind call_kind,
                                         int argument_count);

  static uword FunctionForRedirect(uword redirect);

  void JumpToFrame(uword pc, uword sp, uword fp, Thread* thread);

 private:
  // Known bad pc value to ensure that the simulator does not execute
  // without being properly setup.
  static const uword kBadLR = -1;
  // A pc value used to signal the simulator to stop execution.  Generally
  // the lr is set to this value on transition from native C code to
  // simulated execution, so that the simulator can "return" to the native
  // C code.
  static const uword kEndSimulatingPC = -2;

  // CPU state.
  int32_t registers_[kNumberOfCpuRegisters];
  bool n_flag_;
  bool z_flag_;
  bool c_flag_;
  bool v_flag_;

  // VFP state.
  union {  // S, D, and Q register banks are overlapping.
    int32_t sregisters_[kNumberOfSRegisters];
    int64_t dregisters_[kNumberOfDRegisters];
    simd_value_t qregisters_[kNumberOfQRegisters];
  };
  bool fp_n_flag_;
  bool fp_z_flag_;
  bool fp_c_flag_;
  bool fp_v_flag_;

  // Simulator support.
  char* stack_;
  uword stack_limit_;
  uword overflow_stack_limit_;
  uword stack_base_;
  bool pc_modified_;
  uint64_t icount_;
  static int32_t flag_stop_sim_at_;
  SimulatorSetjmpBuffer* last_setjmp_buffer_;

  // Registered breakpoints.
  Instr* break_pc_;
  int32_t break_instr_;

  // Illegal memory access support.
  static bool IsIllegalAddress(uword addr) { return addr < 64 * 1024; }
  void HandleIllegalAccess(uword addr, Instr* instr);

  // Handles a legal instruction that the simulator does not implement.
  void UnimplementedInstruction(Instr* instr);

  // Unsupported instructions use Format to print an error and stop execution.
  void Format(Instr* instr, const char* format);

  // Checks if the current instruction should be executed based on its
  // condition bits.
  bool ConditionallyExecute(Instr* instr);

  // Helper functions to set the conditional flags in the architecture state.
  void SetNZFlags(int32_t val);
  void SetCFlag(bool val);
  void SetVFlag(bool val);
  bool CarryFrom(int32_t left, int32_t right, int32_t carry);
  bool OverflowFrom(int32_t left, int32_t right, int32_t carry);

  // Helper functions to decode common "addressing" modes.
  int32_t GetShiftRm(Instr* instr, bool* carry_out);
  int32_t GetImm(Instr* instr, bool* carry_out);
  void HandleRList(Instr* instr, bool load);
  void SupervisorCall(Instr* instr);

  // Read and write memory.
  void UnalignedAccess(const char* msg, uword addr, Instr* instr);

  // Perform a division.
  void DoDivision(Instr* instr);

  inline uint8_t ReadBU(uword addr);
  inline int8_t ReadB(uword addr);
  inline void WriteB(uword addr, uint8_t value);

  inline uint16_t ReadHU(uword addr, Instr* instr);
  inline int16_t ReadH(uword addr, Instr* instr);
  inline void WriteH(uword addr, uint16_t value, Instr* instr);

  inline intptr_t ReadW(uword addr, Instr* instr);
  inline void WriteW(uword addr, intptr_t value, Instr* instr);

  // Synchronization primitives support.
  void ClearExclusive();
  intptr_t ReadExclusiveW(uword addr, Instr* instr);
  intptr_t WriteExclusiveW(uword addr, intptr_t value, Instr* instr);

  // Exclusive access reservation: address and value observed during
  // load-exclusive. Store-exclusive verifies that address is the same and
  // performs atomic compare-and-swap with remembered value to observe value
  // changes. This implementation of ldrex/strex instructions does not detect
  // ABA situation and our uses of ldrex/strex don't need this detection.
  uword exclusive_access_addr_;
  uword exclusive_access_value_;

  // Executing is handled based on the instruction type.
  void DecodeType01(Instr* instr);  // Both type 0 and type 1 rolled into one.
  void DecodeType2(Instr* instr);
  void DecodeType3(Instr* instr);
  void DecodeType4(Instr* instr);
  void DecodeType5(Instr* instr);
  void DecodeType6(Instr* instr);
  void DecodeType7(Instr* instr);
  void DecodeSIMDDataProcessing(Instr* instr);

  // Executes one instruction.
  void InstructionDecode(Instr* instr);
  void InstructionDecodeImpl(Instr* instr);

  // Executes ARM instructions until the PC reaches kEndSimulatingPC.
  void Execute();

  // Returns true if tracing of executed instructions is enabled.
  bool IsTracingExecution() const;

  // Longjmp support for exceptions.
  SimulatorSetjmpBuffer* last_setjmp_buffer() { return last_setjmp_buffer_; }
  void set_last_setjmp_buffer(SimulatorSetjmpBuffer* buffer) {
    last_setjmp_buffer_ = buffer;
  }

  friend class SimulatorDebugger;
  friend class SimulatorSetjmpBuffer;
  DISALLOW_COPY_AND_ASSIGN(Simulator);
};

}  // namespace dart

#endif  // RUNTIME_VM_SIMULATOR_ARM_H_
