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

#include "vm/allocation.h"
#include "vm/constants_arm.h"
#include "vm/object.h"

namespace dart {

class Isolate;
class SimulatorSetjmpBuffer;

class Simulator {
 public:
  static const size_t kSimulatorStackUnderflowSize = 64;

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

  // Special case of set_register and get_register to access the raw PC value.
  void set_pc(int32_t value);
  int32_t get_pc() const;

  // Accessors for VFP register state.
  void set_sregister(SRegister reg, float value);
  float get_sregister(SRegister reg) const;
  void set_dregister(DRegister reg, double value);
  double get_dregister(DRegister reg) const;

  // Accessor to the internal simulator stack area.
  uintptr_t StackTop() const;
  uintptr_t StackLimit() const;

  // Executes ARM instructions until the PC reaches end_sim_pc.
  void Execute();

  // Call on program start.
  static void InitOnce();

  // Dart generally calls into generated code with 5 parameters. This is a
  // convenience function, which sets up the simulator state and grabs the
  // result on return.
  int64_t Call(int32_t entry,
               int32_t parameter0,
               int32_t parameter1,
               int32_t parameter2,
               int32_t parameter3,
               int32_t parameter4);

  // Implementation of atomic compare and exchange in the same synchronization
  // domain as other synchronization primitive instructions (e.g. ldrex, strex).
  static uword CompareExchange(uword* address,
                               uword compare_value,
                               uword new_value);

  // Runtime call support.
  static uword RedirectExternalReference(void* function,
                                         uint32_t argument_count);

  void Longjmp(int32_t pc, int32_t sp, int32_t fp, const Instance& object);

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
  union {  // S and D register banks are overlapping.
    float sregisters_[kNumberOfSRegisters];
    double dregisters_[kNumberOfDRegisters];
  };
  bool fp_n_flag_;
  bool fp_z_flag_;
  bool fp_c_flag_;
  bool fp_v_flag_;

  // Simulator support.
  char* stack_;
  bool pc_modified_;
  int icount_;
  static bool flag_trace_sim_;
  static int32_t flag_stop_sim_at_;
  SimulatorSetjmpBuffer* last_setjmp_buffer_;

  // Registered breakpoints.
  Instr* break_pc_;
  int32_t break_instr_;

  // Illegal memory access support.
  static bool IsIllegalAddress(uword addr) {
    return addr < 64*1024;
  }
  void HandleIllegalAccess(uword addr, Instr* instr);

  // Unsupported instructions use Format to print an error and stop execution.
  void Format(Instr* instr, const char* format);

  // Checks if the current instruction should be executed based on its
  // condition bits.
  bool ConditionallyExecute(Instr* instr);

  // Helper functions to set the conditional flags in the architecture state.
  void SetNZFlags(int32_t val);
  void SetCFlag(bool val);
  void SetVFlag(bool val);
  bool CarryFrom(int32_t left, int32_t right);
  bool BorrowFrom(int32_t left, int32_t right);
  bool OverflowFrom(int32_t alu_out,
                    int32_t left,
                    int32_t right,
                    bool addition);

  // Helper functions to decode common "addressing" modes.
  int32_t GetShiftRm(Instr* instr, bool* carry_out);
  int32_t GetImm(Instr* instr, bool* carry_out);
  void HandleRList(Instr* instr, bool load);
  void SupervisorCall(Instr* instr);

  // Read and write memory.
  void UnalignedAccess(const char* msg, uword addr, Instr* instr);

  inline uint8_t ReadBU(uword addr);
  inline int8_t ReadB(uword addr);
  inline void WriteB(uword addr, uint8_t value);

  inline uint16_t ReadHU(uword addr, Instr* instr);
  inline int16_t ReadH(uword addr, Instr* instr);
  inline void WriteH(uword addr, uint16_t value, Instr* instr);

  inline int ReadW(uword addr, Instr* instr);
  inline void WriteW(uword addr, int value, Instr* instr);

  // Synchronization primitives support.
  void ClearExclusive();
  int ReadExclusiveW(uword addr, Instr* instr);
  int WriteExclusiveW(uword addr, int value, Instr* instr);

  // TODO(regis): Remove exclusive access support machinery if not needed.
  // In Dart, there is at most one thread per isolate.
  // We keep track of 16 exclusive access address tags across all isolates.
  // Since we cannot simulate a native context switch, which clears
  // the exclusive access state of the local monitor (using the CLREX
  // instruction), we associate the isolate requesting exclusive access to the
  // address tag. Multiple isolates requesting exclusive access (using the LDREX
  // instruction) to the same address will result in multiple address tags being
  // created for the same address, one per isolate.
  // At any given time, each isolate is associated to at most one address tag.
  static Mutex* exclusive_access_lock_;
  static const int kNumAddressTags = 16;
  static struct AddressTag {
    Isolate* isolate;
    uword addr;
  } exclusive_access_state_[kNumAddressTags];
  static int next_address_tag_;

  // Set access to given address to 'exclusive state' for current isolate.
  static void SetExclusiveAccess(uword addr);

  // Returns true if the current isolate has exclusive access to given address,
  // returns false otherwise. In either case, set access to given address to
  // 'open state' for all isolates.
  // If given addr is NULL, set access to 'open state' for current
  // isolate (CLREX).
  static bool HasExclusiveAccessAndOpen(uword addr);

  // Executing is handled based on the instruction type.
  void DecodeType01(Instr* instr);  // Both type 0 and type 1 rolled into one.
  void DecodeType2(Instr* instr);
  void DecodeType3(Instr* instr);
  void DecodeType4(Instr* instr);
  void DecodeType5(Instr* instr);
  void DecodeType6(Instr* instr);
  void DecodeType7(Instr* instr);

  // Executes one instruction.
  void InstructionDecode(Instr* instr);

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
