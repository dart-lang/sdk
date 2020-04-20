// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declares a Simulator for ARM64 instructions if we are not generating a native
// ARM64 binary. This Simulator allows us to run and debug ARM64 code generation
// on regular desktop machines.
// Dart calls into generated code by "calling" the InvokeDartCode stub,
// which will start execution in the Simulator or forwards to the real entry
// on a ARM64 HW platform.

#ifndef RUNTIME_VM_SIMULATOR_ARM64_H_
#define RUNTIME_VM_SIMULATOR_ARM64_H_

#ifndef RUNTIME_VM_SIMULATOR_H_
#error Do not include simulator_arm64.h directly; use simulator.h.
#endif

#include "vm/constants.h"

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
  void set_register(Instr* instr,
                    Register reg,
                    int64_t value,
                    R31Type r31t = R31IsSP);
  int64_t get_register(Register reg, R31Type r31t = R31IsSP) const;
  void set_wregister(Register reg, int32_t value, R31Type r31t = R31IsSP);
  int32_t get_wregister(Register reg, R31Type r31t = R31IsSP) const;

  int32_t get_vregisters(VRegister reg, int idx) const;
  void set_vregisters(VRegister reg, int idx, int32_t value);

  int64_t get_vregisterd(VRegister reg, int idx) const;
  void set_vregisterd(VRegister reg, int idx, int64_t value);

  void get_vregister(VRegister reg, simd_value_t* value) const;
  void set_vregister(VRegister reg, const simd_value_t& value);

  int64_t get_sp() const { return get_register(SPREG); }

  int64_t get_pc() const;
  int64_t get_last_pc() const;
  void set_pc(int64_t pc);

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
  // result on return. The return value is R0. The parameters are placed in
  // R0-3.
  int64_t Call(int64_t entry,
               int64_t parameter0,
               int64_t parameter1,
               int64_t parameter2,
               int64_t parameter3,
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
  uword stack_limit_;
  uword overflow_stack_limit_;
  uword stack_base_;
  bool pc_modified_;
  uint64_t icount_;
  static int64_t flag_stop_sim_at_;
  SimulatorSetjmpBuffer* last_setjmp_buffer_;

  // Registered breakpoints.
  Instr* break_pc_;
  int64_t break_instr_;

  // Illegal memory access support.
  static bool IsIllegalAddress(uword addr) { return addr < 64 * 1024; }
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

  inline uint32_t ReadWU(uword addr,
                         Instr* instr,
                         bool must_be_aligned = false);
  inline int32_t ReadW(uword addr, Instr* instr);
  inline void WriteW(uword addr, uint32_t value, Instr* instr);

  inline intptr_t ReadX(uword addr, Instr* instr, bool must_be_aligned = false);
  inline void WriteX(uword addr, intptr_t value, Instr* instr);

  // Synchronization primitives support.
  void ClearExclusive();
  intptr_t ReadExclusiveX(uword addr, Instr* instr);
  intptr_t WriteExclusiveX(uword addr, intptr_t value, Instr* instr);
  // 32 bit versions.
  intptr_t ReadExclusiveW(uword addr, Instr* instr);
  intptr_t WriteExclusiveW(uword addr, intptr_t value, Instr* instr);

  // Exclusive access reservation: address and value observed during
  // load-exclusive. Store-exclusive verifies that address is the same and
  // performs atomic compare-and-swap with remembered value to observe value
  // changes. This implementation of ldxr/stxr instructions does not detect
  // ABA situation and our uses of ldxr/stxr don't need this detection.
  uword exclusive_access_addr_;
  uword exclusive_access_value_;

  // Helper functions to set the conditional flags in the architecture state.
  void SetNZFlagsW(int32_t val);
  bool CarryFromW(int32_t left, int32_t right, int32_t carry);
  bool OverflowFromW(int32_t left, int32_t right, int32_t carry);

  void SetNZFlagsX(int64_t val);
  bool CarryFromX(int64_t alu_out, int64_t left, int64_t right, bool addition);
  bool OverflowFromX(int64_t alu_out,
                     int64_t left,
                     int64_t right,
                     bool addition);

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
#define DECODE_OP(op) void Decode##op(Instr* instr);
  APPLY_OP_LIST(DECODE_OP)
#undef DECODE_OP

  // Executes ARM64 instructions until the PC reaches kEndSimulatingPC.
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

#endif  // RUNTIME_VM_SIMULATOR_ARM64_H_
