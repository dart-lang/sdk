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
class Mutex;
class RawObject;
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

  void set_dregister_bits(DRegister freg, int64_t value);
  void set_dregister(DRegister freg, double value);

  int64_t get_dregister_bits(DRegister freg) const;
  double get_dregister(DRegister freg) const;

  // Accessor for the pc.
  void set_pc(int32_t value) { pc_ = value; }
  int32_t get_pc() const { return pc_; }

  // Accessors for hi, lo registers.
  void set_hi_register(int32_t value) { hi_reg_ = value; }
  void set_lo_register(int32_t value) { lo_reg_ = value; }
  int32_t get_hi_register() const { return hi_reg_; }
  int32_t get_lo_register() const { return lo_reg_; }

  int32_t get_fcsr_condition_bit(int32_t cc) const {
    if (cc == 0) {
      return 23;
    } else {
      return 24 + cc;
    }
  }

  void set_fcsr_bit(uint32_t cc, bool value) {
    if (value) {
      fcsr_ |= (1 << cc);
    } else {
      fcsr_ &= ~(1 << cc);
    }
  }

  bool test_fcsr_bit(uint32_t cc) {
    return fcsr_ & (1 << cc);
  }

  // Accessor to the internal simulator stack top.
  uword StackTop() const;

  // Accessor to the instruction counter.
  intptr_t get_icount() const { return icount_; }

  // The isolate's top_exit_frame_info refers to a Dart frame in the simulator
  // stack. The simulator's top_exit_frame_info refers to a C++ frame in the
  // native stack.
  uword top_exit_frame_info() const { return top_exit_frame_info_; }
  void set_top_exit_frame_info(uword value) { top_exit_frame_info_ = value; }

  // Call on program start.
  static void InitOnce();

  // Dart generally calls into generated code with 5 parameters. This is a
  // convenience function, which sets up the simulator state and grabs the
  // result on return. When fp_return is true the return value is the D0
  // floating point register. Otherwise, the return value is V1:V0.
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
               Isolate* isolate);

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
  int32_t fcsr_;
  uword pc_;

  // Simulator support.
  char* stack_;
  intptr_t icount_;
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

  void set_pc(uword value) { pc_ = value; }

  void Format(Instr* instr, const char* format);

  inline int8_t ReadB(uword addr);
  inline uint8_t ReadBU(uword addr);
  inline int16_t ReadH(uword addr, Instr* instr);
  inline uint16_t ReadHU(uword addr, Instr *instr);
  inline intptr_t ReadW(uword addr, Instr* instr);

  inline void WriteB(uword addr, uint8_t value);
  inline void WriteH(uword addr, uint16_t value, Instr* isntr);
  inline void WriteW(uword addr, intptr_t value, Instr* instr);

  inline double ReadD(uword addr, Instr* instr);
  inline void WriteD(uword addr, double value, Instr* instr);

  // In Dart, there is at most one thread per isolate.
  // We keep track of 16 exclusive access address tags across all isolates.
  // Since we cannot simulate a native context switch, which clears
  // the exclusive access state of the local monitor, we associate the isolate
  // requesting exclusive access to the address tag.
  // Multiple isolates requesting exclusive access (using the LL instruction)
  // to the same address will result in multiple address tags being created for
  // the same address, one per isolate.
  // At any given time, each isolate is associated to at most one address tag.
  static Mutex* exclusive_access_lock_;
  static const int kNumAddressTags = 16;
  static struct AddressTag {
    Isolate* isolate;
    uword addr;
  } exclusive_access_state_[kNumAddressTags];
  static int next_address_tag_;

  // Synchronization primitives support.
  void ClearExclusive();
  intptr_t ReadExclusiveW(uword addr, Instr* instr);
  intptr_t WriteExclusiveW(uword addr, intptr_t value, Instr* instr);

  // Set access to given address to 'exclusive state' for current isolate.
  static void SetExclusiveAccess(uword addr);

  // Returns true if the current isolate has exclusive access to given address,
  // returns false otherwise. In either case, set access to given address to
  // 'open state' for all isolates.
  // If given addr is NULL, set access to 'open state' for current
  // isolate (CLREX).
  static bool HasExclusiveAccessAndOpen(uword addr);

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
  DISALLOW_COPY_AND_ASSIGN(Simulator);
};

}  // namespace dart

#endif  // VM_SIMULATOR_MIPS_H_
