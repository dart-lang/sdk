// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declares a Simulator for ARM instructions if we are not generating a native
// ARM binary. This Simulator allows us to run and debug ARM code generation on
// regular desktop machines.
// Dart calls into generated code by "calling" the InvokeDartCode stub,
// which will start execution in the Simulator or forwards to the real entry
// on a ARM HW platform.

#ifndef VM_SIMULATOR_ARM_H_
#define VM_SIMULATOR_ARM_H_

#ifndef VM_SIMULATOR_H_
#error Do not include simulator_arm.h directly; use simulator.h.
#endif

#include "vm/constants_arm.h"

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
  int32_t get_register(Register reg) const;

  int32_t get_sp() const {
    return get_register(SPREG);
  }

  // Special case of set_register and get_register to access the raw PC value.
  void set_pc(int32_t value);
  int32_t get_pc() const;

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

  // Accessors to the internal simulator stack base and top.
  uword StackBase() const { return reinterpret_cast<uword>(stack_); }
  uword StackTop() const;

  // Accessor to the instruction counter.
  uint64_t get_icount() const { return icount_; }

  // The isolate's top_exit_frame_info refers to a Dart frame in the simulator
  // stack. The simulator's top_exit_frame_info refers to a C++ frame in the
  // native stack.
  uword top_exit_frame_info() const { return top_exit_frame_info_; }
  void set_top_exit_frame_info(uword value) { top_exit_frame_info_ = value; }

  // Call on program start.
  static void InitOnce();

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

  // Implementation of atomic compare and exchange in the same synchronization
  // domain as other synchronization primitive instructions (e.g. ldrex, strex).
  static uword CompareExchange(uword* address,
                               uword compare_value,
                               uword new_value);
  static uint32_t CompareExchangeUint32(uint32_t* address,
                                        uint32_t compare_value,
                                        uint32_t new_value);

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

  void Longjmp(uword pc,
               uword sp,
               uword fp,
               RawObject* raw_exception,
               RawObject* raw_stacktrace,
               Thread* thread);

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
  bool pc_modified_;
  uint64_t icount_;
  static int32_t flag_stop_sim_at_;
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

  // We keep track of 16 exclusive access address tags across all threads.
  // Since we cannot simulate a native context switch, which clears
  // the exclusive access state of the local monitor (using the CLREX
  // instruction), we associate the thread requesting exclusive access to the
  // address tag. Multiple threads requesting exclusive access (using the LDREX
  // instruction) to the same address will result in multiple address tags being
  // created for the same address, one per thread.
  // At any given time, each thread is associated to at most one address tag.
  static Mutex* exclusive_access_lock_;
  static const int kNumAddressTags = 16;
  static struct AddressTag {
    Thread* thread;
    uword addr;
  } exclusive_access_state_[kNumAddressTags];
  static int next_address_tag_;

  // Set access to given address to 'exclusive state' for current thread.
  static void SetExclusiveAccess(uword addr);

  // Returns true if the current thread has exclusive access to given address,
  // returns false otherwise. In either case, set access to given address to
  // 'open state' for all threads.
  // If given addr is NULL, set access to 'open state' for current
  // thread (CLREX).
  static bool HasExclusiveAccessAndOpen(uword addr);

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

  // Executes ARM instructions until the PC reaches kEndSimulatingPC.
  void Execute();

  // Returns true if tracing of executed instructions is enabled.
  bool IsTracingExecution() const;

  // Longjmp support for exceptions.
  SimulatorSetjmpBuffer* last_setjmp_buffer() {
    return last_setjmp_buffer_;
  }
  void set_last_setjmp_buffer(SimulatorSetjmpBuffer* buffer) {
    last_setjmp_buffer_ = buffer;
  }

  friend class SimulatorDebugger;
  friend class SimulatorSetjmpBuffer;
  DISALLOW_COPY_AND_ASSIGN(Simulator);
};

}  // namespace dart

#endif  // VM_SIMULATOR_ARM_H_
