// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declares a Simulator for ARM64 instructions if we are not generating a native
// ARM64 binary. This Simulator allows us to run and debug ARM64 code generation
// on regular desktop machines.
// Dart calls into generated code by "calling" the InvokeDartCode stub,
// which will start execution in the Simulator or forwards to the real entry
// on a ARM64 HW platform.

#ifndef VM_SIMULATOR_ARM64_H_
#define VM_SIMULATOR_ARM64_H_

#ifndef VM_SIMULATOR_H_
#error Do not include simulator_arm64.h directly; use simulator.h.
#endif

#include "vm/constants_arm64.h"

namespace dart {

class Isolate;
class Mutex;
class RawObject;
class SimulatorSetjmpBuffer;
class Thread;

typedef struct {
  union {
    int64_t i64[2];
    int32_t i32[4];
  } bits;
} simd_value_t;

class Simulator {
 public:
  static const uword kSimulatorStackUnderflowSize = 64;

  Simulator();
  ~Simulator();

  // The currently executing Simulator instance, which is associated to the
  // current isolate
  static Simulator* Current();

  // Accessors for register state.
  // The default value for R31Type has to be R31IsSP because get_register is
  // accessed from architecture independent code through SPREG without
  // specifying the type. We also can't translate a dummy value for SPREG into
  // a real value because the architecture independent code expects SPREG to
  // be a real register value.
  void set_register(
      Instr* instr, Register reg, int64_t value, R31Type r31t = R31IsSP);
  int64_t get_register(Register reg, R31Type r31t = R31IsSP) const;
  void set_wregister(Register reg, int32_t value, R31Type r31t = R31IsSP);
  int32_t get_wregister(Register reg, R31Type r31t = R31IsSP) const;

  int32_t get_vregisters(VRegister reg, int idx) const;
  void set_vregisters(VRegister reg, int idx, int32_t value);

  int64_t get_vregisterd(VRegister reg, int idx) const;
  void set_vregisterd(VRegister reg, int idx, int64_t value);

  void get_vregister(VRegister reg, simd_value_t* value) const;
  void set_vregister(VRegister reg, const simd_value_t& value);

  int64_t get_sp() const {
    return get_register(SPREG);
  }

  int64_t get_pc() const;
  int64_t get_last_pc() const;
  void set_pc(int64_t pc);

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
  // result on return. The return value is R0. The parameters are placed in
  // R0-3.
  int64_t Call(int64_t entry,
               int64_t parameter0,
               int64_t parameter1,
               int64_t parameter2,
               int64_t parameter3,
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
  int64_t registers_[kNumberOfCpuRegisters];
  bool n_flag_;
  bool z_flag_;
  bool c_flag_;
  bool v_flag_;

  simd_value_t vregisters_[kNumberOfVRegisters];

  // Simulator support.
  int64_t last_pc_;
  int64_t pc_;
  char* stack_;
  bool pc_modified_;
  uint64_t icount_;
  static int64_t flag_stop_sim_at_;
  SimulatorSetjmpBuffer* last_setjmp_buffer_;
  uword top_exit_frame_info_;

  // Registered breakpoints.
  Instr* break_pc_;
  int64_t break_instr_;

  // Illegal memory access support.
  static bool IsIllegalAddress(uword addr) {
    return addr < 64*1024;
  }
  void HandleIllegalAccess(uword addr, Instr* instr);

  // Handles an unaligned memory access.
  void UnalignedAccess(const char* msg, uword addr, Instr* instr);

  // Handles a legal instruction that the simulator does not implement.
  void UnimplementedInstruction(Instr* instr);

  // Unsupported instructions use Format to print an error and stop execution.
  void Format(Instr* instr, const char* format);

  inline uint8_t ReadBU(uword addr);
  inline int8_t ReadB(uword addr);
  inline void WriteB(uword addr, uint8_t value);

  inline uint16_t ReadHU(uword addr, Instr* instr);
  inline int16_t ReadH(uword addr, Instr* instr);
  inline void WriteH(uword addr, uint16_t value, Instr* instr);

  inline uint32_t ReadWU(uword addr, Instr* instr);
  inline int32_t ReadW(uword addr, Instr* instr);
  inline void WriteW(uword addr, uint32_t value, Instr* instr);

  inline intptr_t ReadX(uword addr, Instr* instr);
  inline void WriteX(uword addr, intptr_t value, Instr* instr);

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

  // Synchronization primitives support.
  void ClearExclusive();
  intptr_t ReadExclusiveX(uword addr, Instr* instr);
  intptr_t WriteExclusiveX(uword addr, intptr_t value, Instr* instr);

  // Set access to given address to 'exclusive state' for current thread.
  static void SetExclusiveAccess(uword addr);

  // Returns true if the current thread has exclusive access to given address,
  // returns false otherwise. In either case, set access to given address to
  // 'open state' for all threads.
  // If given addr is NULL, set access to 'open state' for current
  // thread (CLREX).
  static bool HasExclusiveAccessAndOpen(uword addr);

  // Helper functions to set the conditional flags in the architecture state.
  void SetNZFlagsW(int32_t val);
  bool CarryFromW(int32_t left, int32_t right, int32_t carry);
  bool OverflowFromW(int32_t left, int32_t right, int32_t carry);

  void SetNZFlagsX(int64_t val);
  bool CarryFromX(int64_t alu_out, int64_t left, int64_t right, bool addition);
  bool OverflowFromX(
      int64_t alu_out, int64_t left, int64_t right, bool addition);

  void SetCFlag(bool val);
  void SetVFlag(bool val);

  int64_t ShiftOperand(uint8_t reg_size,
                       int64_t value,
                       Shift shift_type,
                       uint8_t amount);

  int64_t ExtendOperand(uint8_t reg_size,
                        int64_t value,
                        Extend extend_type,
                        uint8_t amount);

  int64_t DecodeShiftExtendOperand(Instr* instr);

  bool ConditionallyExecute(Instr* instr);

  void DoRedirectedCall(Instr* instr);

  // Decode instructions.
  void InstructionDecode(Instr* instr);
  #define DECODE_OP(op)                                                        \
    void Decode##op(Instr* instr);
  APPLY_OP_LIST(DECODE_OP)
  #undef DECODE_OP

  // Executes ARM64 instructions until the PC reaches kEndSimulatingPC.
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

#endif  // VM_SIMULATOR_ARM64_H_
