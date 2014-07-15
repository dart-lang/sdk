// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <setjmp.h>
#include <stdlib.h>

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

// Only build the simulator if not compiling for real MIPS hardware.
#if !defined(HOST_ARCH_MIPS)

#include "vm/simulator.h"

#include "vm/assembler.h"
#include "vm/constants_mips.h"
#include "vm/disassembler.h"
#include "vm/native_arguments.h"
#include "vm/thread.h"

namespace dart {

DEFINE_FLAG(bool, trace_sim, false, "Trace simulator execution.");
DEFINE_FLAG(int, stop_sim_at, 0, "Address to stop simulator at.");


// This macro provides a platform independent use of sscanf. The reason for
// SScanF not being implemented in a platform independent way through
// OS in the same way as SNPrint is that the Windows C Run-Time
// Library does not provide vsscanf.
#define SScanF sscanf  // NOLINT


// SimulatorSetjmpBuffer are linked together, and the last created one
// is referenced by the Simulator. When an exception is thrown, the exception
// runtime looks at where to jump and finds the corresponding
// SimulatorSetjmpBuffer based on the stack pointer of the exception handler.
// The runtime then does a Longjmp on that buffer to return to the simulator.
class SimulatorSetjmpBuffer {
 public:
  int Setjmp() { return setjmp(buffer_); }
  void Longjmp() {
    // "This" is now the last setjmp buffer.
    simulator_->set_last_setjmp_buffer(this);
    longjmp(buffer_, 1);
  }

  explicit SimulatorSetjmpBuffer(Simulator* sim) {
    simulator_ = sim;
    link_ = sim->last_setjmp_buffer();
    sim->set_last_setjmp_buffer(this);
    sp_ = static_cast<uword>(sim->get_register(SP));
    native_sp_ = reinterpret_cast<uword>(&sim);  // Current C++ stack pointer.
  }

  ~SimulatorSetjmpBuffer() {
    ASSERT(simulator_->last_setjmp_buffer() == this);
    simulator_->set_last_setjmp_buffer(link_);
  }

  SimulatorSetjmpBuffer* link() { return link_; }

  uword sp() { return sp_; }
  uword native_sp() { return native_sp_; }

 private:
  uword sp_;
  uword native_sp_;
  Simulator* simulator_;
  SimulatorSetjmpBuffer* link_;
  jmp_buf buffer_;

  friend class Simulator;
};


// The SimulatorDebugger class is used by the simulator while debugging
// simulated MIPS code.
class SimulatorDebugger {
 public:
  explicit SimulatorDebugger(Simulator* sim);
  ~SimulatorDebugger();

  void Stop(Instr* instr, const char* message);
  void Debug();
  char* ReadLine(const char* prompt);

 private:
  Simulator* sim_;

  bool GetValue(char* desc, uint32_t* value);
  bool GetFValue(char* desc, double* value);
  bool GetDValue(char* desc, double* value);

  // Set or delete a breakpoint. Returns true if successful.
  bool SetBreakpoint(Instr* breakpc);
  bool DeleteBreakpoint(Instr* breakpc);

  // Undo and redo all breakpoints. This is needed to bracket disassembly and
  // execution to skip past breakpoints when run from the debugger.
  void UndoBreakpoints();
  void RedoBreakpoints();
};


SimulatorDebugger::SimulatorDebugger(Simulator* sim) {
  sim_ = sim;
}


SimulatorDebugger::~SimulatorDebugger() {
}


void SimulatorDebugger::Stop(Instr* instr, const char* message) {
  OS::Print("Simulator hit %s\n", message);
  Debug();
}


static Register LookupCpuRegisterByName(const char* name) {
  static const char* kNames[] = {
      "r0",  "r1",  "r2",  "r3",
      "r4",  "r5",  "r6",  "r7",
      "r8",  "r9",  "r10", "r11",
      "r12", "r13", "r14", "r15",
      "r16", "r17", "r18", "r19",
      "r20", "r21", "r22", "r23",
      "r24", "r25", "r26", "r27",
      "r28", "r29", "r30", "r31",

      "zr",  "at",  "v0",  "v1",
      "a0",  "a1",  "a2",  "a3",
      "t0",  "t1",  "t2",  "t3",
      "t4",  "t5",  "t6",  "t7",
      "s0",  "s1",  "s2",  "s3",
      "s4",  "s5",  "s6",  "s7",
      "t8",  "t9",  "k0",  "k1",
      "gp",  "sp",  "fp",  "ra"
  };
  static const Register kRegisters[] = {
      R0,  R1,  R2,  R3,
      R4,  R5,  R6,  R7,
      R8,  R9,  R10, R11,
      R12, R13, R14, R15,
      R16, R17, R18, R19,
      R20, R21, R22, R23,
      R24, R25, R26, R27,
      R28, R29, R30, R31,

      ZR,  AT,  V0,  V1,
      A0,  A1,  A2,  A3,
      T0,  T1,  T2,  T3,
      T4,  T5,  T6,  T7,
      S0,  S1,  S2,  S3,
      S4,  S5,  S6,  S7,
      T8,  T9,  K0,  K1,
      GP,  SP,  FP,  RA
  };
  ASSERT(ARRAY_SIZE(kNames) == ARRAY_SIZE(kRegisters));
  for (unsigned i = 0; i < ARRAY_SIZE(kNames); i++) {
    if (strcmp(kNames[i], name) == 0) {
      return kRegisters[i];
    }
  }
  return kNoRegister;
}


static FRegister LookupFRegisterByName(const char* name) {
  int reg_nr = -1;
  bool ok = SScanF(name, "f%d", &reg_nr);
  if (ok && (0 <= reg_nr) && (reg_nr < kNumberOfFRegisters)) {
    return static_cast<FRegister>(reg_nr);
  }
  return kNoFRegister;
}


bool SimulatorDebugger::GetValue(char* desc, uint32_t* value) {
  Register reg = LookupCpuRegisterByName(desc);
  if (reg != kNoRegister) {
    *value = sim_->get_register(reg);
    return true;
  }
  if (desc[0] == '*') {
    uint32_t addr;
    if (GetValue(desc + 1, &addr)) {
      if (Simulator::IsIllegalAddress(addr)) {
        return false;
      }
      *value = *(reinterpret_cast<uint32_t*>(addr));
      return true;
    }
  }
  if (strcmp("pc", desc) == 0) {
    *value = sim_->get_pc();
    return true;
  }
  bool retval = SScanF(desc, "0x%x", value) == 1;
  if (!retval) {
    retval = SScanF(desc, "%x", value) == 1;
  }
  return retval;
}


bool SimulatorDebugger::GetFValue(char* desc, double* value) {
  FRegister freg = LookupFRegisterByName(desc);
  if (freg != kNoFRegister) {
    *value = sim_->get_fregister(freg);
    return true;
  }
  if (desc[0] == '*') {
    uint32_t addr;
    if (GetValue(desc + 1, &addr)) {
      if (Simulator::IsIllegalAddress(addr)) {
        return false;
      }
      *value = *(reinterpret_cast<float*>(addr));
      return true;
    }
  }
  return false;
}


bool SimulatorDebugger::GetDValue(char* desc, double* value) {
  FRegister freg = LookupFRegisterByName(desc);
  if (freg != kNoFRegister) {
    *value = sim_->get_fregister_double(freg);
    return true;
  }
  if (desc[0] == '*') {
    uint32_t addr;
    if (GetValue(desc + 1, &addr)) {
      if (Simulator::IsIllegalAddress(addr)) {
        return false;
      }
      *value = *(reinterpret_cast<double*>(addr));
      return true;
    }
  }
  return false;
}


bool SimulatorDebugger::SetBreakpoint(Instr* breakpc) {
  // Check if a breakpoint can be set. If not return without any side-effects.
  if (sim_->break_pc_ != NULL) {
    return false;
  }

  // Set the breakpoint.
  sim_->break_pc_ = breakpc;
  sim_->break_instr_ = breakpc->InstructionBits();
  // Not setting the breakpoint instruction in the code itself. It will be set
  // when the debugger shell continues.
  return true;
}


bool SimulatorDebugger::DeleteBreakpoint(Instr* breakpc) {
  if (sim_->break_pc_ != NULL) {
    sim_->break_pc_->SetInstructionBits(sim_->break_instr_);
  }

  sim_->break_pc_ = NULL;
  sim_->break_instr_ = 0;
  return true;
}


void SimulatorDebugger::UndoBreakpoints() {
  if (sim_->break_pc_ != NULL) {
    sim_->break_pc_->SetInstructionBits(sim_->break_instr_);
  }
}


void SimulatorDebugger::RedoBreakpoints() {
  if (sim_->break_pc_ != NULL) {
    sim_->break_pc_->SetInstructionBits(Instr::kBreakPointInstruction);
  }
}


void SimulatorDebugger::Debug() {
  intptr_t last_pc = -1;
  bool done = false;

#define COMMAND_SIZE 63
#define ARG_SIZE 255

#define STR(a) #a
#define XSTR(a) STR(a)

  char cmd[COMMAND_SIZE + 1];
  char arg1[ARG_SIZE + 1];
  char arg2[ARG_SIZE + 1];

  // make sure to have a proper terminating character if reaching the limit
  cmd[COMMAND_SIZE] = 0;
  arg1[ARG_SIZE] = 0;
  arg2[ARG_SIZE] = 0;

  // Undo all set breakpoints while running in the debugger shell. This will
  // make them invisible to all commands.
  UndoBreakpoints();

  while (!done) {
    if (last_pc != sim_->get_pc()) {
      last_pc = sim_->get_pc();
      if (Simulator::IsIllegalAddress(last_pc)) {
        OS::Print("pc is out of bounds: 0x%" Px "\n", last_pc);
      } else {
        Disassembler::Disassemble(last_pc, last_pc + Instr::kInstrSize);
      }
    }
    char* line = ReadLine("sim> ");
    if (line == NULL) {
      FATAL("ReadLine failed");
    } else {
      // Use sscanf to parse the individual parts of the command line. At the
      // moment no command expects more than two parameters.
      int args = SScanF(line,
                        "%" XSTR(COMMAND_SIZE) "s "
                        "%" XSTR(ARG_SIZE) "s "
                        "%" XSTR(ARG_SIZE) "s",
                        cmd, arg1, arg2);
      if ((strcmp(cmd, "h") == 0) || (strcmp(cmd, "help") == 0)) {
        OS::Print("c/cont -- continue execution\n"
                  "disasm -- disassemble instrs at current pc location\n"
                  "  other variants are:\n"
                  "    disasm <address>\n"
                  "    disasm <address> <number_of_instructions>\n"
                  "  by default 10 instrs are disassembled\n"
                  "del -- delete breakpoints\n"
                  "gdb -- transfer control to gdb\n"
                  "h/help -- print this help string\n"
                  "break <address> -- set break point at specified address\n"
                  "p/print <reg or value or *addr> -- print integer value\n"
                  "pf/printfloat <freg or *addr> -- print float value\n"
                  "po/printobject <*reg or *addr> -- print object\n"
                  "si/stepi -- single step an instruction\n"
                  "unstop -- if current pc is a stop instr make it a nop\n"
                  "q/quit -- Quit the debugger and exit the program\n");
      } else if ((strcmp(cmd, "quit") == 0) || (strcmp(cmd, "q") == 0)) {
        OS::Print("Quitting\n");
        OS::Exit(0);
      } else if ((strcmp(cmd, "si") == 0) || (strcmp(cmd, "stepi") == 0)) {
        sim_->InstructionDecode(reinterpret_cast<Instr*>(sim_->get_pc()));
      } else if ((strcmp(cmd, "c") == 0) || (strcmp(cmd, "cont") == 0)) {
        // Execute the one instruction we broke at with breakpoints disabled.
        sim_->InstructionDecode(reinterpret_cast<Instr*>(sim_->get_pc()));
        // Leave the debugger shell.
        done = true;
      } else if ((strcmp(cmd, "p") == 0) || (strcmp(cmd, "print") == 0)) {
        if (args == 2) {
          uint32_t value;
          if (GetValue(arg1, &value)) {
            OS::Print("%s: %u 0x%x\n", arg1, value, value);
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("print <reg or value or *addr>\n");
        }
      } else if ((strcmp(cmd, "pf") == 0) ||
                 (strcmp(cmd, "printfloat") == 0)) {
        if (args == 2) {
          double dvalue;
          if (GetFValue(arg1, &dvalue)) {
            uint64_t long_value = bit_cast<uint64_t, double>(dvalue);
            OS::Print("%s: %llu 0x%llx %.8g\n",
                arg1, long_value, long_value, dvalue);
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("printfloat <dreg or *addr>\n");
        }
      } else if ((strcmp(cmd, "pd") == 0) ||
                 (strcmp(cmd, "printdouble") == 0)) {
        if (args == 2) {
          double dvalue;
          if (GetDValue(arg1, &dvalue)) {
            uint64_t long_value = bit_cast<uint64_t, double>(dvalue);
            OS::Print("%s: %llu 0x%llx %.8g\n",
                arg1, long_value, long_value, dvalue);
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("printfloat <dreg or *addr>\n");
        }
      } else if ((strcmp(cmd, "po") == 0) ||
                 (strcmp(cmd, "printobject") == 0)) {
        if (args == 2) {
          uint32_t value;
          // Make the dereferencing '*' optional.
          if (((arg1[0] == '*') && GetValue(arg1 + 1, &value)) ||
              GetValue(arg1, &value)) {
            if (Isolate::Current()->heap()->Contains(value)) {
              OS::Print("%s: \n", arg1);
#if defined(DEBUG)
              const Object& obj = Object::Handle(
                  reinterpret_cast<RawObject*>(value));
              obj.Print();
#endif  // defined(DEBUG)
            } else {
              OS::Print("0x%x is not an object reference\n", value);
            }
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("printobject <*reg or *addr>\n");
        }
      } else if (strcmp(cmd, "disasm") == 0) {
        uint32_t start = 0;
        uint32_t end = 0;
        if (args == 1) {
          start = sim_->get_pc();
          end = start + (10 * Instr::kInstrSize);
        } else if (args == 2) {
          if (GetValue(arg1, &start)) {
            // no length parameter passed, assume 10 instructions
            if (Simulator::IsIllegalAddress(start)) {
              // If start isn't a valid address, warn and use PC instead
              OS::Print("First argument yields invalid address: 0x%x\n", start);
              OS::Print("Using PC instead");
              start = sim_->get_pc();
            }
            end = start + (10 * Instr::kInstrSize);
          }
        } else {
          uint32_t length;
          if (GetValue(arg1, &start) && GetValue(arg2, &length)) {
            if (Simulator::IsIllegalAddress(start)) {
              // If start isn't a valid address, warn and use PC instead
              OS::Print("First argument yields invalid address: 0x%x\n", start);
              OS::Print("Using PC instead\n");
              start = sim_->get_pc();
            }
            end = start + (length * Instr::kInstrSize);
          }
        }

        Disassembler::Disassemble(start, end);
      } else if (strcmp(cmd, "gdb") == 0) {
        OS::Print("relinquishing control to gdb\n");
        OS::DebugBreak();
        OS::Print("regaining control from gdb\n");
      } else if (strcmp(cmd, "break") == 0) {
        if (args == 2) {
          uint32_t addr;
          if (GetValue(arg1, &addr)) {
            if (!SetBreakpoint(reinterpret_cast<Instr*>(addr))) {
              OS::Print("setting breakpoint failed\n");
            }
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("break <addr>\n");
        }
      } else if (strcmp(cmd, "del") == 0) {
        if (!DeleteBreakpoint(NULL)) {
          OS::Print("deleting breakpoint failed\n");
        }
      } else if (strcmp(cmd, "unstop") == 0) {
        intptr_t stop_pc = sim_->get_pc() - Instr::kInstrSize;
        Instr* stop_instr = reinterpret_cast<Instr*>(stop_pc);
        if (stop_instr->IsBreakPoint()) {
          stop_instr->SetInstructionBits(Instr::kNopInstruction);
        } else {
          OS::Print("Not at debugger stop.\n");
        }
      } else {
        OS::Print("Unknown command: %s\n", cmd);
      }
    }
    delete[] line;
  }

  // Add all the breakpoints back to stop execution and enter the debugger
  // shell when hit.
  RedoBreakpoints();

#undef COMMAND_SIZE
#undef ARG_SIZE

#undef STR
#undef XSTR
}


char* SimulatorDebugger::ReadLine(const char* prompt) {
  char* result = NULL;
  char line_buf[256];
  intptr_t offset = 0;
  bool keep_going = true;
  OS::Print("%s", prompt);
  while (keep_going) {
    if (fgets(line_buf, sizeof(line_buf), stdin) == NULL) {
      // fgets got an error. Just give up.
      if (result != NULL) {
        delete[] result;
      }
      return NULL;
    }
    intptr_t len = strlen(line_buf);
    if (len > 1 &&
        line_buf[len - 2] == '\\' &&
        line_buf[len - 1] == '\n') {
      // When we read a line that ends with a "\" we remove the escape and
      // append the remainder.
      line_buf[len - 2] = '\n';
      line_buf[len - 1] = 0;
      len -= 1;
    } else if ((len > 0) && (line_buf[len - 1] == '\n')) {
      // Since we read a new line we are done reading the line. This
      // will exit the loop after copying this buffer into the result.
      keep_going = false;
    }
    if (result == NULL) {
      // Allocate the initial result and make room for the terminating '\0'
      result = new char[len + 1];
      if (result == NULL) {
        // OOM, so cannot readline anymore.
        return NULL;
      }
    } else {
      // Allocate a new result with enough room for the new addition.
      intptr_t new_len = offset + len + 1;
      char* new_result = new char[new_len];
      if (new_result == NULL) {
        // OOM, free the buffer allocated so far and return NULL.
        delete[] result;
        return NULL;
      } else {
        // Copy the existing input into the new array and set the new
        // array as the result.
        memmove(new_result, result, offset);
        delete[] result;
        result = new_result;
      }
    }
    // Copy the newly read line into the result.
    memmove(result + offset, line_buf, len);
    offset += len;
  }
  ASSERT(result != NULL);
  result[offset] = '\0';
  return result;
}


void Simulator::InitOnce() {
}


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
  icount_ = 0;
  delay_slot_ = false;
  break_pc_ = NULL;
  break_instr_ = 0;
  last_setjmp_buffer_ = NULL;
  top_exit_frame_info_ = 0;

  // Setup architecture state.
  // All registers are initialized to zero to start with.
  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    registers_[i] = 0;
  }
  pc_ = 0;
  // The sp is initialized to point to the bottom (high address) of the
  // allocated stack area.
  registers_[SP] = StackTop();

  // All double-precision registers are initialized to zero.
  for (int i = 0; i < kNumberOfFRegisters; i++) {
    fregisters_[i] = 0.0;
  }
  fcsr_ = 0;
}


Simulator::~Simulator() {
  delete[] stack_;
  Isolate* isolate = Isolate::Current();
  if (isolate != NULL) {
    isolate->set_simulator(NULL);
  }
}


// When the generated code calls an external reference we need to catch that in
// the simulator.  The external reference will be a function compiled for the
// host architecture.  We need to call that function instead of trying to
// execute it with the simulator.  We do that by redirecting the external
// reference to a break instruction with code 2 that is handled by
// the simulator.  We write the original destination of the jump just at a known
// offset from the break instruction so the simulator knows what to call.
class Redirection {
 public:
  uword address_of_break_instruction() {
    return reinterpret_cast<uword>(&break_instruction_);
  }

  uword external_function() const { return external_function_; }

  Simulator::CallKind call_kind() const { return call_kind_; }

  int argument_count() const { return argument_count_; }

  static Redirection* Get(uword external_function,
                          Simulator::CallKind call_kind,
                          int argument_count) {
    Redirection* current;
    for (current = list_; current != NULL; current = current->next_) {
      if (current->external_function_ == external_function) return current;
    }
    return new Redirection(external_function, call_kind, argument_count);
  }

  static Redirection* FromBreakInstruction(Instr* break_instruction) {
    char* addr_of_break = reinterpret_cast<char*>(break_instruction);
    char* addr_of_redirection =
        addr_of_break - OFFSET_OF(Redirection, break_instruction_);
    return reinterpret_cast<Redirection*>(addr_of_redirection);
  }

 private:
  static const int32_t kRedirectInstruction =
    Instr::kBreakPointInstruction | (Instr::kRedirectCode << kBreakCodeShift);

  Redirection(uword external_function,
              Simulator::CallKind call_kind,
              int argument_count)
      : external_function_(external_function),
        call_kind_(call_kind),
        argument_count_(argument_count),
        break_instruction_(kRedirectInstruction),
        next_(list_) {
    list_ = this;
  }

  uword external_function_;
  Simulator::CallKind call_kind_;
  int argument_count_;
  uint32_t break_instruction_;
  Redirection* next_;
  static Redirection* list_;
};


Redirection* Redirection::list_ = NULL;


uword Simulator::RedirectExternalReference(uword function,
                                           CallKind call_kind,
                                           int argument_count) {
  Redirection* redirection =
      Redirection::Get(function, call_kind, argument_count);
  return redirection->address_of_break_instruction();
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
void Simulator::set_register(Register reg, int32_t value) {
  if (reg != R0) {
    registers_[reg] = value;
  }
}


void Simulator::set_fregister(FRegister reg, int32_t value) {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfFRegisters);
  fregisters_[reg] = value;
}


void Simulator::set_fregister_float(FRegister reg, float value) {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfFRegisters);
  fregisters_[reg] = bit_cast<int32_t, float>(value);
}


void Simulator::set_fregister_long(FRegister reg, int64_t value) {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfFRegisters);
  ASSERT((reg & 1) == 0);
  fregisters_[reg] = Utils::Low32Bits(value);
  fregisters_[reg + 1] = Utils::High32Bits(value);
}


void Simulator::set_fregister_double(FRegister reg, double value) {
  const int64_t ival = bit_cast<int64_t, double>(value);
  set_fregister_long(reg, ival);
}


void Simulator::set_dregister_bits(DRegister reg, int64_t value) {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfDRegisters);
  FRegister lo = static_cast<FRegister>(reg * 2);
  FRegister hi = static_cast<FRegister>((reg * 2) + 1);
  set_fregister(lo, Utils::Low32Bits(value));
  set_fregister(hi, Utils::High32Bits(value));
}


void Simulator::set_dregister(DRegister reg, double value) {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfDRegisters);
  set_dregister_bits(reg, bit_cast<int64_t, double>(value));
}


// Get the register from the architecture state.
int32_t Simulator::get_register(Register reg) const {
  if (reg == R0) {
    return 0;
  }
  return registers_[reg];
}


int32_t Simulator::get_fregister(FRegister reg) const {
  ASSERT((reg >= 0) && (reg < kNumberOfFRegisters));
  return fregisters_[reg];
}


float Simulator::get_fregister_float(FRegister reg) const {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfFRegisters);
  return bit_cast<float, int32_t>(fregisters_[reg]);
}


int64_t Simulator::get_fregister_long(FRegister reg) const {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfFRegisters);
  ASSERT((reg & 1) == 0);
  const int32_t low = fregisters_[reg];
  const int32_t high = fregisters_[reg + 1];
  const int64_t value = Utils::LowHighTo64Bits(low, high);
  return value;
}


double Simulator::get_fregister_double(FRegister reg) const {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfFRegisters);
  ASSERT((reg & 1) == 0);
  const int64_t value = get_fregister_long(reg);
  return bit_cast<double, int64_t>(value);
}


int64_t Simulator::get_dregister_bits(DRegister reg) const {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfDRegisters);
  FRegister lo = static_cast<FRegister>(reg * 2);
  FRegister hi = static_cast<FRegister>((reg * 2) + 1);
  return Utils::LowHighTo64Bits(get_fregister(lo), get_fregister(hi));
}


double Simulator::get_dregister(DRegister reg) const {
  ASSERT(reg >= 0);
  ASSERT(reg < kNumberOfDRegisters);
  const int64_t value = get_dregister_bits(reg);
  return bit_cast<double, int64_t>(value);
}


void Simulator::UnimplementedInstruction(Instr* instr) {
  char buffer[64];
  snprintf(buffer, sizeof(buffer), "Unimplemented instruction: pc=%p\n", instr);
  SimulatorDebugger dbg(this);
  dbg.Stop(instr, buffer);
  FATAL("Cannot continue execution after unimplemented instruction.");
}


void Simulator::HandleIllegalAccess(uword addr, Instr* instr) {
  uword fault_pc = get_pc();
  // The debugger will not be able to single step past this instruction, but
  // it will be possible to disassemble the code and inspect registers.
  char buffer[128];
  snprintf(buffer, sizeof(buffer),
           "illegal memory access at 0x%" Px ", pc=0x%" Px "\n",
           addr, fault_pc);
  SimulatorDebugger dbg(this);
  dbg.Stop(instr, buffer);
  // The debugger will return control in non-interactive mode.
  FATAL("Cannot continue execution after illegal memory access.");
}


void Simulator::UnalignedAccess(const char* msg, uword addr, Instr* instr) {
  // The debugger will not be able to single step past this instruction, but
  // it will be possible to disassemble the code and inspect registers.
  char buffer[128];
  snprintf(buffer, sizeof(buffer),
           "pc=%p, unaligned %s at 0x%" Px "\n",  instr, msg, addr);
  SimulatorDebugger dbg(this);
  dbg.Stop(instr, buffer);
  // The debugger will return control in non-interactive mode.
  FATAL("Cannot continue execution after unaligned access.");
}


// Returns the top of the stack area to enable checking for stack pointer
// validity.
uword Simulator::StackTop() const {
  // To be safe in potential stack underflows we leave some buffer above and
  // set the stack top.
  return reinterpret_cast<uword>(stack_) +
      (Isolate::GetSpecifiedStackSize() + Isolate::kStackSizeBuffer);
}


void Simulator::Format(Instr* instr, const char* format) {
  OS::PrintErr("Simulator - unknown instruction: %s\n", format);
  UNIMPLEMENTED();
}


int8_t Simulator::ReadB(uword addr) {
  int8_t* ptr = reinterpret_cast<int8_t*>(addr);
  return *ptr;
}


uint8_t Simulator::ReadBU(uword addr) {
  uint8_t* ptr = reinterpret_cast<uint8_t*>(addr);
  return *ptr;
}


int16_t Simulator::ReadH(uword addr, Instr* instr) {
  if ((addr & 1) == 0) {
    int16_t* ptr = reinterpret_cast<int16_t*>(addr);
    return *ptr;
  }
  UnalignedAccess("signed halfword read", addr, instr);
  return 0;
}


uint16_t Simulator::ReadHU(uword addr, Instr* instr) {
  if ((addr & 1) == 0) {
    uint16_t* ptr = reinterpret_cast<uint16_t*>(addr);
    return *ptr;
  }
  UnalignedAccess("unsigned halfword read", addr, instr);
  return 0;
}


intptr_t Simulator::ReadW(uword addr, Instr* instr) {
  if ((addr & 3) == 0) {
    intptr_t* ptr = reinterpret_cast<intptr_t*>(addr);
    return *ptr;
  }
  UnalignedAccess("read", addr, instr);
  return 0;
}


void Simulator::WriteB(uword addr, uint8_t value) {
  uint8_t* ptr = reinterpret_cast<uint8_t*>(addr);
  *ptr = value;
}


void Simulator::WriteH(uword addr, uint16_t value, Instr* instr) {
  if ((addr & 1) == 0) {
    uint16_t* ptr = reinterpret_cast<uint16_t*>(addr);
    *ptr = value;
    return;
  }
  UnalignedAccess("halfword write", addr, instr);
}


void Simulator::WriteW(uword addr, intptr_t value, Instr* instr) {
  if ((addr & 3) == 0) {
    intptr_t* ptr = reinterpret_cast<intptr_t*>(addr);
    *ptr = value;
    return;
  }
  UnalignedAccess("write", addr, instr);
}


double Simulator::ReadD(uword addr, Instr* instr) {
  if ((addr & 7) == 0) {
    double* ptr = reinterpret_cast<double*>(addr);
    return *ptr;
  }
  UnalignedAccess("double-precision floating point read", addr, instr);
  return 0.0;
}


void Simulator::WriteD(uword addr, double value, Instr* instr) {
  if ((addr & 7) == 0) {
    double* ptr = reinterpret_cast<double*>(addr);
    *ptr = value;
    return;
  }
  UnalignedAccess("double-precision floating point write", addr, instr);
}


bool Simulator::OverflowFrom(int32_t alu_out,
                             int32_t left, int32_t right, bool addition) {
  bool overflow;
  if (addition) {
               // Operands have the same sign.
    overflow = ((left >= 0 && right >= 0) || (left < 0 && right < 0))
               // And operands and result have different sign.
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  } else {
               // Operands have different signs.
    overflow = ((left < 0 && right >= 0) || (left >= 0 && right < 0))
               // And first operand and result have different signs.
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  }
  return overflow;
}


// Calls into the Dart runtime are based on this interface.
typedef void (*SimulatorRuntimeCall)(NativeArguments arguments);

// Calls to leaf Dart runtime functions are based on this interface.
typedef int32_t (*SimulatorLeafRuntimeCall)(
    int32_t r0, int32_t r1, int32_t r2, int32_t r3);

// Calls to leaf float Dart runtime functions are based on this interface.
typedef double (*SimulatorLeafFloatRuntimeCall)(double d0, double d1);

// Calls to native Dart functions are based on this interface.
typedef void (*SimulatorBootstrapNativeCall)(NativeArguments* arguments);
typedef void (*SimulatorNativeCall)(NativeArguments* arguments, uword target);


void Simulator::DoBreak(Instr *instr) {
  ASSERT(instr->OpcodeField() == SPECIAL);
  ASSERT(instr->FunctionField() == BREAK);
  if (instr->BreakCodeField() == Instr::kStopMessageCode) {
    SimulatorDebugger dbg(this);
    const char* message = *reinterpret_cast<const char**>(
        reinterpret_cast<intptr_t>(instr) - Instr::kInstrSize);
    set_pc(get_pc() + Instr::kInstrSize);
    dbg.Stop(instr, message);
    // Adjust for extra pc increment.
    set_pc(get_pc() - Instr::kInstrSize);
  } else if (instr->BreakCodeField() == Instr::kMsgMessageCode) {
    const char* message = *reinterpret_cast<const char**>(
        reinterpret_cast<intptr_t>(instr) - Instr::kInstrSize);
    if (FLAG_trace_sim) {
      OS::Print("Message: %s\n", message);
    } else {
      OS::PrintErr("Bad break code: 0x%x\n", instr->InstructionBits());
      UnimplementedInstruction(instr);
    }
  } else if (instr->BreakCodeField() == Instr::kRedirectCode) {
    SimulatorSetjmpBuffer buffer(this);

    if (!setjmp(buffer.buffer_)) {
      int32_t saved_ra = get_register(RA);
      Redirection* redirection = Redirection::FromBreakInstruction(instr);
      uword external = redirection->external_function();
      if (FLAG_trace_sim) {
        OS::Print("Call to host function at 0x%" Pd "\n", external);
      }

      if ((redirection->call_kind() == kRuntimeCall) ||
          (redirection->call_kind() == kBootstrapNativeCall) ||
          (redirection->call_kind() == kNativeCall)) {
        // Set the top_exit_frame_info of this simulator to the native stack.
        set_top_exit_frame_info(reinterpret_cast<uword>(&buffer));
      }
      if (redirection->call_kind() == kRuntimeCall) {
        NativeArguments arguments;
        ASSERT(sizeof(NativeArguments) == 4*kWordSize);
        arguments.isolate_ = reinterpret_cast<Isolate*>(get_register(A0));
        arguments.argc_tag_ = get_register(A1);
        arguments.argv_ = reinterpret_cast<RawObject*(*)[]>(get_register(A2));
        arguments.retval_ = reinterpret_cast<RawObject**>(get_register(A3));
        SimulatorRuntimeCall target =
            reinterpret_cast<SimulatorRuntimeCall>(external);
        target(arguments);
        set_register(V0, icount_);  // Zap result registers from void function.
        set_register(V1, icount_);
      } else if (redirection->call_kind() == kLeafRuntimeCall) {
        int32_t a0 = get_register(A0);
        int32_t a1 = get_register(A1);
        int32_t a2 = get_register(A2);
        int32_t a3 = get_register(A3);
        SimulatorLeafRuntimeCall target =
            reinterpret_cast<SimulatorLeafRuntimeCall>(external);
        a0 = target(a0, a1, a2, a3);
        set_register(V0, a0);  // Set returned result from function.
        set_register(V1, icount_);  // Zap second result register.
      } else if (redirection->call_kind() == kLeafFloatRuntimeCall) {
        ASSERT((0 <= redirection->argument_count()) &&
               (redirection->argument_count() <= 2));
        // double values are passed and returned in floating point registers.
        SimulatorLeafFloatRuntimeCall target =
            reinterpret_cast<SimulatorLeafFloatRuntimeCall>(external);
        double d0 = 0.0;
        double d6 = get_fregister_double(F12);
        double d7 = get_fregister_double(F14);
        d0 = target(d6, d7);
        set_fregister_double(F0, d0);
      } else if (redirection->call_kind() == kBootstrapNativeCall) {
        NativeArguments* arguments;
        arguments = reinterpret_cast<NativeArguments*>(get_register(A0));
        SimulatorBootstrapNativeCall target =
            reinterpret_cast<SimulatorBootstrapNativeCall>(external);
        target(arguments);
        set_register(V0, icount_);  // Zap result register from void function.
        set_register(V1, icount_);
      } else {
        ASSERT(redirection->call_kind() == kNativeCall);
        NativeArguments* arguments;
        arguments = reinterpret_cast<NativeArguments*>(get_register(A0));
        uword target_func = get_register(A1);
        SimulatorNativeCall target =
            reinterpret_cast<SimulatorNativeCall>(external);
        target(arguments, target_func);
        set_register(V0, icount_);  // Zap result register from void function.
        set_register(V1, icount_);
      }
      set_top_exit_frame_info(0);

      // Zap caller-saved registers, since the actual runtime call could have
      // used them.
      set_register(T0, icount_);
      set_register(T1, icount_);
      set_register(T2, icount_);
      set_register(T3, icount_);
      set_register(T4, icount_);
      set_register(T5, icount_);
      set_register(T6, icount_);
      set_register(T7, icount_);
      set_register(T8, icount_);
      set_register(T9, icount_);

      set_register(A0, icount_);
      set_register(A1, icount_);
      set_register(A2, icount_);
      set_register(A3, icount_);
      set_register(TMP, icount_);
      set_register(RA, icount_);

      // Zap floating point registers.
      int32_t zap_dvalue = icount_;
      for (int i = F4; i <= F18; i++) {
        set_fregister(static_cast<FRegister>(i), zap_dvalue);
      }

      // Return. Subtract to account for pc_ increment after return.
      set_pc(saved_ra - Instr::kInstrSize);
    } else {
      // Coming via long jump from a throw. Continue to exception handler.
      set_top_exit_frame_info(0);
      // Adjust for extra pc increment.
      set_pc(get_pc() - Instr::kInstrSize);
    }
  } else {
    SimulatorDebugger dbg(this);
    dbg.Stop(instr, "breakpoint");
    // Adjust for extra pc increment.
    set_pc(get_pc() - Instr::kInstrSize);
  }
}


void Simulator::DecodeSpecial(Instr* instr) {
  ASSERT(instr->OpcodeField() == SPECIAL);
  switch (instr->FunctionField()) {
    case ADDU: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "addu 'rd, 'rs, 'rt");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      set_register(instr->RdField(), rs_val + rt_val);
      break;
    }
    case AND: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "and 'rd, 'rs, 'rt");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      set_register(instr->RdField(), rs_val & rt_val);
      break;
    }
    case BREAK: {
      DoBreak(instr);
      break;
    }
    case DIV: {
      ASSERT(instr->RdField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "div 'rs, 'rt");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      if (rt_val == 0) {
        // Results are unpredictable, but there is no arithmetic exception.
        set_hi_register(icount_);
        set_lo_register(icount_);
        break;
      }

      if ((rs_val == static_cast<int32_t>(0x80000000)) &&
          (rt_val == static_cast<int32_t>(0xffffffff))) {
        set_lo_register(0x80000000);
        set_hi_register(0);
      } else {
        set_lo_register(rs_val / rt_val);
        set_hi_register(rs_val % rt_val);
      }
      break;
    }
    case DIVU: {
      ASSERT(instr->RdField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "divu 'rs, 'rt");
      uint32_t rs_val = get_register(instr->RsField());
      uint32_t rt_val = get_register(instr->RtField());
      if (rt_val == 0) {
        // Results are unpredictable, but there is no arithmetic exception.
        set_hi_register(icount_);
        set_lo_register(icount_);
        break;
      }
      set_lo_register(rs_val / rt_val);
      set_hi_register(rs_val % rt_val);
      break;
    }
    case JALR: {
      ASSERT(instr->RtField() == R0);
      ASSERT(instr->RsField() != instr->RdField());
      ASSERT(!delay_slot_);
      // Format(instr, "jalr'hint 'rd, rs");
      set_register(instr->RdField(), pc_ + 2*Instr::kInstrSize);
      uword next_pc = get_register(instr->RsField());
      ExecuteDelaySlot();
      // Set return address to be the instruction after the delay slot.
      pc_ = next_pc - Instr::kInstrSize;  // Account for regular PC increment.
      break;
    }
    case JR: {
      ASSERT(instr->RtField() == R0);
      ASSERT(instr->RdField() == R0);
      ASSERT(!delay_slot_);
      // Format(instr, "jr'hint 'rs");
      uword next_pc = get_register(instr->RsField());
      ExecuteDelaySlot();
      pc_ = next_pc - Instr::kInstrSize;  // Account for regular PC increment.
      break;
    }
    case MFHI: {
      ASSERT(instr->RsField() == 0);
      ASSERT(instr->RtField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "mfhi 'rd");
      set_register(instr->RdField(), get_hi_register());
      break;
    }
    case MFLO: {
      ASSERT(instr->RsField() == 0);
      ASSERT(instr->RtField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "mflo 'rd");
      set_register(instr->RdField(), get_lo_register());
      break;
    }
    case MOVCI: {
      ASSERT(instr->SaField() == 0);
      ASSERT(instr->Bit(17) == 0);
      int32_t rs_val = get_register(instr->RsField());
      uint32_t cc, fcsr_cc, test, status;
      cc = instr->Bits(18, 3);
      fcsr_cc = get_fcsr_condition_bit(cc);
      test = instr->Bit(16);
      status = test_fcsr_bit(fcsr_cc);
      if (test == status) {
        set_register(instr->RdField(), rs_val);
      }
      break;
    }
    case MOVN: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "movn 'rd, 'rs, 'rt");
      int32_t rt_val = get_register(instr->RtField());
      int32_t rs_val = get_register(instr->RsField());
      if (rt_val != 0) {
        set_register(instr->RdField(), rs_val);
      }
      break;
    }
    case MOVZ: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "movz 'rd, 'rs, 'rt");
      int32_t rt_val = get_register(instr->RtField());
      int32_t rs_val = get_register(instr->RsField());
      if (rt_val == 0) {
        set_register(instr->RdField(), rs_val);
      }
      break;
    }
    case MTHI: {
      ASSERT(instr->RtField() == 0);
      ASSERT(instr->RdField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "mthi 'rd");
      set_hi_register(get_register(instr->RsField()));
      break;
    }
    case MTLO: {
      ASSERT(instr->RtField() == 0);
      ASSERT(instr->RdField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "mflo 'rd");
      set_lo_register(get_register(instr->RsField()));
      break;
    }
    case MULT: {
      ASSERT(instr->RdField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "mult 'rs, 'rt");
      int64_t rs = static_cast<int64_t>(get_register(instr->RsField()));
      int64_t rt = static_cast<int64_t>(get_register(instr->RtField()));
      int64_t res = rs * rt;
      set_hi_register(Utils::High32Bits(res));
      set_lo_register(Utils::Low32Bits(res));
      break;
    }
    case MULTU: {
      ASSERT(instr->RdField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "multu 'rs, 'rt");
      uint64_t rs = static_cast<uint64_t>(get_register(instr->RsField()));
      uint64_t rt = static_cast<uint64_t>(get_register(instr->RtField()));
      uint64_t res = rs * rt;
      set_hi_register(Utils::High32Bits(res));
      set_lo_register(Utils::Low32Bits(res));
      break;
    }
    case NOR: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "nor 'rd, 'rs, 'rt");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      set_register(instr->RdField(), ~(rs_val | rt_val));
      break;
    }
    case OR: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "or 'rd, 'rs, 'rt");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      set_register(instr->RdField(), rs_val | rt_val);
      break;
    }
    case SLL: {
      ASSERT(instr->RsField() == 0);
      if ((instr->RdField() == R0) &&
          (instr->RtField() == R0) &&
          (instr->SaField() == 0)) {
        // Format(instr, "nop");
        // Nothing to be done for NOP.
      } else {
        int32_t rt_val = get_register(instr->RtField());
        int sa = instr->SaField();
        set_register(instr->RdField(), rt_val << sa);
      }
      break;
    }
    case SLLV: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "sllv 'rd, 'rt, 'rs");
      int32_t rt_val = get_register(instr->RtField());
      int32_t rs_val = get_register(instr->RsField());
      set_register(instr->RdField(), rt_val << (rs_val & 0x1f));
      break;
    }
    case SLT: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "slt 'rd, 'rs, 'rt");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      set_register(instr->RdField(), rs_val < rt_val ? 1 : 0);
      break;
    }
    case SLTU: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "sltu 'rd, 'rs, 'rt");
      uint32_t rs_val = static_cast<uint32_t>(get_register(instr->RsField()));
      uint32_t rt_val = static_cast<uint32_t>(get_register(instr->RtField()));
      set_register(instr->RdField(), rs_val < rt_val ? 1 : 0);
      break;
    }
    case SRA: {
      ASSERT(instr->RsField() == 0);
      // Format(instr, "sra 'rd, 'rt, 'sa");
      int32_t rt_val = get_register(instr->RtField());
      int32_t sa = instr->SaField();
      set_register(instr->RdField(), rt_val >> sa);
      break;
    }
    case SRAV: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "srav 'rd, 'rt, 'rs");
      int32_t rt_val = get_register(instr->RtField());
      int32_t rs_val = get_register(instr->RsField());
      set_register(instr->RdField(), rt_val >> (rs_val & 0x1f));
      break;
    }
    case SRL: {
      ASSERT(instr->RsField() == 0);
      // Format(instr, "srl 'rd, 'rt, 'sa");
      uint32_t rt_val = get_register(instr->RtField());
      uint32_t sa = instr->SaField();
      set_register(instr->RdField(), rt_val >> sa);
      break;
    }
    case SRLV: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "srlv 'rd, 'rt, 'rs");
      uint32_t rt_val = get_register(instr->RtField());
      uint32_t rs_val = get_register(instr->RsField());
      set_register(instr->RdField(), rt_val >> (rs_val & 0x1f));
      break;
    }
    case SUBU: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "subu 'rd, 'rs, 'rt");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      set_register(instr->RdField(), rs_val - rt_val);
      break;
    }
    case XOR: {
      ASSERT(instr->SaField() == 0);
      // Format(instr, "xor 'rd, 'rs, 'rt");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      set_register(instr->RdField(), rs_val ^ rt_val);
      break;
    }
    default: {
      OS::PrintErr("DecodeSpecial: 0x%x\n", instr->InstructionBits());
      UnimplementedInstruction(instr);
      break;
    }
  }
}


void Simulator::DecodeSpecial2(Instr* instr) {
  ASSERT(instr->OpcodeField() == SPECIAL2);
  switch (instr->FunctionField()) {
    case MADD: {
      ASSERT(instr->RdField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "madd 'rs, 'rt");
      uint32_t lo = get_lo_register();
      int32_t hi = get_hi_register();
      int64_t accum = Utils::LowHighTo64Bits(lo, hi);
      int64_t rs = get_register(instr->RsField());
      int64_t rt = get_register(instr->RtField());
      int64_t res = accum + rs * rt;
      set_hi_register(Utils::High32Bits(res));
      set_lo_register(Utils::Low32Bits(res));
      break;
    }
    case MADDU: {
      ASSERT(instr->RdField() == 0);
      ASSERT(instr->SaField() == 0);
      // Format(instr, "maddu 'rs, 'rt");
      uint32_t lo = get_lo_register();
      uint32_t hi = get_hi_register();
      uint64_t accum = Utils::LowHighTo64Bits(lo, hi);
      uint64_t rs = static_cast<uint32_t>(get_register(instr->RsField()));
      uint64_t rt = static_cast<uint32_t>(get_register(instr->RtField()));
      uint64_t res = accum + rs * rt;
      set_hi_register(Utils::High32Bits(res));
      set_lo_register(Utils::Low32Bits(res));
      break;
    }
    case CLO: {
      ASSERT(instr->SaField() == 0);
      ASSERT(instr->RtField() == instr->RdField());
      // Format(instr, "clo 'rd, 'rs");
      int32_t rs_val = get_register(instr->RsField());
      int32_t bitcount = 0;
      while (rs_val < 0) {
        bitcount++;
        rs_val <<= 1;
      }
      set_register(instr->RdField(), bitcount);
      break;
    }
    case CLZ: {
      ASSERT(instr->SaField() == 0);
      ASSERT(instr->RtField() == instr->RdField());
      // Format(instr, "clz 'rd, 'rs");
      int32_t rs_val = get_register(instr->RsField());
      int32_t bitcount = 0;
      if (rs_val != 0) {
        while (rs_val > 0) {
          bitcount++;
          rs_val <<= 1;
        }
      } else {
        bitcount = 32;
      }
      set_register(instr->RdField(), bitcount);
      break;
    }
    default: {
      OS::PrintErr("DecodeSpecial2: 0x%x\n", instr->InstructionBits());
      UnimplementedInstruction(instr);
      break;
    }
  }
}


void Simulator::DoBranch(Instr* instr, bool taken, bool likely) {
  ASSERT(!delay_slot_);
  int32_t imm_val = instr->SImmField() << 2;

  uword next_pc;
  if (taken) {
    // imm_val is added to the address of the instruction following the branch.
    next_pc = pc_ + imm_val + Instr::kInstrSize;
    if (likely) {
      ExecuteDelaySlot();
    }
  } else {
    next_pc = pc_ + (2 * Instr::kInstrSize);  // Next after delay slot.
  }
  if (!likely) {
    ExecuteDelaySlot();
  }
  pc_ = next_pc - Instr::kInstrSize;

  return;
}


void Simulator::DecodeRegImm(Instr* instr) {
  ASSERT(instr->OpcodeField() == REGIMM);
  switch (instr->RegImmFnField()) {
    case BGEZ: {
      // Format(instr, "bgez 'rs, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      DoBranch(instr, rs_val >= 0, false);
      break;
    }
    case BGEZAL: {
      int32_t rs_val = get_register(instr->RsField());
      // Return address is one after the delay slot.
      set_register(RA, pc_ + (2*Instr::kInstrSize));
      DoBranch(instr, rs_val >= 0, false);
      break;
    }
    case BLTZAL: {
      int32_t rs_val = get_register(instr->RsField());
      // Return address is one after the delay slot.
      set_register(RA, pc_ + (2*Instr::kInstrSize));
      DoBranch(instr, rs_val < 0, false);
      break;
    }
    case BGEZL: {
      // Format(instr, "bgezl 'rs, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      DoBranch(instr, rs_val >= 0, true);
      break;
    }
    case BLTZ: {
      // Format(instr, "bltz 'rs, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      DoBranch(instr, rs_val < 0, false);
      break;
    }
    case BLTZL: {
      // Format(instr, "bltzl 'rs, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      DoBranch(instr, rs_val < 0, true);
      break;
    }
    default: {
      OS::PrintErr("DecodeRegImm: 0x%x\n", instr->InstructionBits());
      UnimplementedInstruction(instr);
      break;
    }
  }
}


void Simulator::DecodeCop1(Instr* instr) {
  ASSERT(instr->OpcodeField() == COP1);
  if (instr->HasFormat()) {
    // If the rs field is a valid format, then the function field identifies the
    // instruction.
    double fs_val = get_fregister_double(instr->FsField());
    double ft_val = get_fregister_double(instr->FtField());
    uint32_t cc, fcsr_cc;
    cc = instr->FpuCCField();
    fcsr_cc = get_fcsr_condition_bit(cc);
    switch (instr->Cop1FunctionField()) {
      case COP1_ADD: {
        // Format(instr, "add.'fmt 'fd, 'fs, 'ft");
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        set_fregister_double(instr->FdField(), fs_val + ft_val);
        break;
      }
      case COP1_SUB: {
        // Format(instr, "sub.'fmt 'fd, 'fs, 'ft");
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        set_fregister_double(instr->FdField(), fs_val - ft_val);
        break;
      }
      case COP1_MUL: {
        // Format(instr, "mul.'fmt 'fd, 'fs, 'ft");
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        set_fregister_double(instr->FdField(), fs_val * ft_val);
        break;
      }
      case COP1_DIV: {
        // Format(instr, "div.'fmt 'fd, 'fs, 'ft");
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        set_fregister_double(instr->FdField(), fs_val / ft_val);
        break;
      }
      case COP1_SQRT: {
        // Format(instr, "sqrt.'fmt 'fd, 'fs");
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        set_fregister_double(instr->FdField(), sqrt(fs_val));
        break;
      }
      case COP1_MOV: {
        // Format(instr, "mov.'fmt 'fd, 'fs");
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        set_fregister_double(instr->FdField(), fs_val);
        break;
      }
      case COP1_C_F: {
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        ASSERT(instr->FdField() == F0);
        set_fcsr_bit(fcsr_cc, false);
        break;
      }
      case COP1_C_UN: {
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        ASSERT(instr->FdField() == F0);
        set_fcsr_bit(fcsr_cc, isnan(fs_val) || isnan(ft_val));
        break;
      }
      case COP1_C_EQ: {
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        ASSERT(instr->FdField() == F0);
        set_fcsr_bit(fcsr_cc, (fs_val == ft_val));
        break;
      }
      case COP1_C_UEQ: {
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        ASSERT(instr->FdField() == F0);
        set_fcsr_bit(fcsr_cc,
            (fs_val == ft_val) || isnan(fs_val) || isnan(ft_val));
        break;
      }
      case COP1_C_OLT: {
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        ASSERT(instr->FdField() == F0);
        set_fcsr_bit(fcsr_cc, (fs_val < ft_val));
        break;
      }
      case COP1_C_ULT: {
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        ASSERT(instr->FdField() == F0);
        set_fcsr_bit(fcsr_cc,
            (fs_val < ft_val) || isnan(fs_val) || isnan(ft_val));
        break;
      }
      case COP1_C_OLE: {
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        ASSERT(instr->FdField() == F0);
        set_fcsr_bit(fcsr_cc, (fs_val <= ft_val));
        break;
      }
      case COP1_C_ULE: {
        ASSERT(instr->FormatField() == FMT_D);  // Only D supported.
        ASSERT(instr->FdField() == F0);
        set_fcsr_bit(fcsr_cc,
            (fs_val <= ft_val) || isnan(fs_val) || isnan(ft_val));
        break;
      }
      case COP1_CVT_D: {
        switch (instr->FormatField()) {
          case FMT_W: {
            int32_t fs_int = get_fregister(instr->FsField());
            double fs_dbl = static_cast<double>(fs_int);
            set_fregister_double(instr->FdField(), fs_dbl);
            break;
          }
          case FMT_S: {
            float fs_flt = get_fregister_float(instr->FsField());
            double fs_dbl = static_cast<double>(fs_flt);
            set_fregister_double(instr->FdField(), fs_dbl);
            break;
          }
          case FMT_L: {
            int64_t fs_int = get_fregister_long(instr->FsField());
            double fs_dbl = static_cast<double>(fs_int);
            set_fregister_double(instr->FdField(), fs_dbl);
            break;
          }
          default: {
            OS::PrintErr("DecodeCop1: 0x%x\n", instr->InstructionBits());
            UnimplementedInstruction(instr);
            break;
          }
        }
        break;
      }
      case COP1_CVT_W: {
        switch (instr->FormatField()) {
          case FMT_D: {
            double fs_dbl = get_fregister_double(instr->FsField());
            int32_t fs_int;
            if (isnan(fs_dbl) || isinf(fs_dbl) || (fs_dbl > INT_MAX) ||
                (fs_dbl < INT_MIN)) {
              fs_int = INT_MIN;
            } else {
              fs_int = static_cast<int32_t>(fs_dbl);
            }
            set_fregister(instr->FdField(), fs_int);
            break;
          }
          default: {
            OS::PrintErr("DecodeCop1: 0x%x\n", instr->InstructionBits());
            UnimplementedInstruction(instr);
            break;
          }
        }
        break;
      }
      case COP1_CVT_S: {
        switch (instr->FormatField()) {
          case FMT_D: {
            double fs_dbl = get_fregister_double(instr->FsField());
            float fs_flt = static_cast<float>(fs_dbl);
            set_fregister_float(instr->FdField(), fs_flt);
            break;
          }
          default: {
            OS::PrintErr("DecodeCop1: 0x%x\n", instr->InstructionBits());
            UnimplementedInstruction(instr);
            break;
          }
        }
        break;
      }
      default: {
        OS::PrintErr("DecodeCop1: 0x%x\n", instr->InstructionBits());
        UnimplementedInstruction(instr);
        break;
      }
    }
  } else {
    // If the rs field isn't a valid format, then it must be a sub-op.
    switch (instr->Cop1SubField()) {
      case COP1_MF: {
        // Format(instr, "mfc1 'rt, 'fs");
        ASSERT(instr->Bits(0, 11) == 0);
        int32_t fs_val = get_fregister(instr->FsField());
        set_register(instr->RtField(), fs_val);
        break;
      }
      case COP1_MT: {
        // Format(instr, "mtc1 'rt, 'fs");
        ASSERT(instr->Bits(0, 11) == 0);
        int32_t rt_val = get_register(instr->RtField());
        set_fregister(instr->FsField(), rt_val);
        break;
      }
      case COP1_BC: {
        ASSERT(instr->Bit(17) == 0);
        uint32_t cc, fcsr_cc;
        cc = instr->Bits(18, 3);
        fcsr_cc = get_fcsr_condition_bit(cc);
        if (instr->Bit(16) == 1) {  // Branch on true.
          DoBranch(instr, test_fcsr_bit(fcsr_cc), false);
        } else {  // Branch on false.
          DoBranch(instr, !test_fcsr_bit(fcsr_cc), false);
        }
        break;
      }
      default: {
        OS::PrintErr("DecodeCop1: 0x%x\n", instr->InstructionBits());
        UnimplementedInstruction(instr);
        break;
      }
    }
  }
}


void Simulator::InstructionDecode(Instr* instr) {
  if (FLAG_trace_sim) {
    const uword start = reinterpret_cast<uword>(instr);
    const uword end = start + Instr::kInstrSize;
    Disassembler::Disassemble(start, end);
  }

  switch (instr->OpcodeField()) {
    case SPECIAL: {
      DecodeSpecial(instr);
      break;
    }
    case SPECIAL2: {
      DecodeSpecial2(instr);
      break;
    }
    case REGIMM: {
      DecodeRegImm(instr);
      break;
    }
    case COP1: {
      DecodeCop1(instr);
      break;
    }
    case ADDIU: {
      // Format(instr, "addiu 'rt, 'rs, 'imms");
      int32_t rs_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      int32_t res = rs_val + imm_val;
      // Rt is set even on overflow.
      set_register(instr->RtField(), res);
      break;
    }
    case ANDI: {
      // Format(instr, "andi 'rt, 'rs, 'immu");
      int32_t rs_val = get_register(instr->RsField());
      set_register(instr->RtField(), rs_val & instr->UImmField());
      break;
    }
    case BEQ: {
      // Format(instr, "beq 'rs, 'rt, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      DoBranch(instr, rs_val == rt_val, false);
      break;
    }
    case BEQL: {
      // Format(instr, "beql 'rs, 'rt, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      DoBranch(instr, rs_val == rt_val, true);
      break;
    }
    case BGTZ: {
      ASSERT(instr->RtField() == R0);
      // Format(instr, "bgtz 'rs, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      DoBranch(instr, rs_val > 0, false);
      break;
    }
    case BGTZL: {
      ASSERT(instr->RtField() == R0);
      // Format(instr, "bgtzl 'rs, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      DoBranch(instr, rs_val > 0, true);
      break;
    }
    case BLEZ: {
      ASSERT(instr->RtField() == R0);
      // Format(instr, "blez 'rs, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      DoBranch(instr, rs_val <= 0, false);
      break;
    }
    case BLEZL: {
      ASSERT(instr->RtField() == R0);
      // Format(instr, "blezl 'rs, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      DoBranch(instr, rs_val <= 0, true);
      break;
    }
    case BNE: {
      // Format(instr, "bne 'rs, 'rt, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      DoBranch(instr, rs_val != rt_val, false);
      break;
    }
    case BNEL: {
      // Format(instr, "bnel 'rs, 'rt, 'dest");
      int32_t rs_val = get_register(instr->RsField());
      int32_t rt_val = get_register(instr->RtField());
      DoBranch(instr, rs_val != rt_val, true);
      break;
    }
    case LB: {
      // Format(instr, "lb 'rt, 'imms('rs)");
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        int32_t res = ReadB(addr);
        set_register(instr->RtField(), res);
      }
      break;
    }
    case LBU: {
      // Format(instr, "lbu 'rt, 'imms('rs)");
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        uint32_t res = ReadBU(addr);
        set_register(instr->RtField(), res);
      }
      break;
    }
    case LDC1: {
      // Format(instr, "ldc1 'ft, 'imms('rs)");
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        double value = ReadD(addr, instr);
        set_fregister_double(instr->FtField(), value);
      }
      break;
    }
    case LH: {
      // Format(instr, "lh 'rt, 'imms('rs)");
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        int32_t res = ReadH(addr, instr);
        set_register(instr->RtField(), res);
      }
      break;
    }
    case LHU: {
      // Format(instr, "lhu 'rt, 'imms('rs)");
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        int32_t res = ReadHU(addr, instr);
        set_register(instr->RtField(), res);
      }
      break;
    }
    case LUI: {
      ASSERT(instr->RsField() == 0);
      set_register(instr->RtField(), instr->UImmField() << 16);
      break;
    }
    case LW: {
      // Format(instr, "lw 'rt, 'imms('rs)");
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        int32_t res = ReadW(addr, instr);
        set_register(instr->RtField(), res);
      }
      break;
    }
    case LWC1: {
      // Format(instr, "lwc1 'ft, 'imms('rs)");
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        int32_t value = ReadW(addr, instr);
        set_fregister(instr->FtField(), value);
      }
      break;
    }
    case ORI: {
      // Format(instr, "ori 'rt, 'rs, 'immu");
      int32_t rs_val = get_register(instr->RsField());
      set_register(instr->RtField(), rs_val | instr->UImmField());
      break;
    }
    case SB: {
      // Format(instr, "sb 'rt, 'imms('rs)");
      int32_t rt_val = get_register(instr->RtField());
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        WriteB(addr, rt_val & 0xff);
      }
      break;
    }
    case SLTI: {
      // Format(instr, "slti 'rt, 'rs, 'imms");
      int32_t rs_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      set_register(instr->RtField(), rs_val < imm_val ? 1 : 0);
      break;
    }
    case SLTIU: {
      // Format(instr, "slti 'rt, 'rs, 'immu");
      uint32_t rs_val = get_register(instr->RsField());
      uint32_t imm_val = instr->UImmField();
      set_register(instr->RtField(), rs_val < imm_val ? 1 : 0);
      break;
    }
    case SDC1: {
      // Format(instr, "sdc1 'ft, 'imms('rs)");
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        double value = get_fregister_double(instr->FtField());
        WriteD(addr, value, instr);
      }
      break;
    }
    case SH: {
      // Format(instr, "sh 'rt, 'imms('rs)");
      int32_t rt_val = get_register(instr->RtField());
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        WriteH(addr, rt_val & 0xffff, instr);
      }
      break;
    }
    case SW: {
      // Format(instr, "sw 'rt, 'imms('rs)");
      int32_t rt_val = get_register(instr->RtField());
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        WriteW(addr, rt_val, instr);
      }
      break;
    }
    case SWC1: {
      // Format(instr, "swc1 'ft, 'imms('rs)");
      int32_t base_val = get_register(instr->RsField());
      int32_t imm_val = instr->SImmField();
      uword addr = base_val + imm_val;
      if (Simulator::IsIllegalAddress(addr)) {
        HandleIllegalAccess(addr, instr);
      } else {
        int32_t value = get_fregister(instr->FtField());
        WriteW(addr, value, instr);
      }
      break;
    }
    case XORI: {
      // Format(instr, "xori 'rt, 'rs, 'immu");
      int32_t rs_val = get_register(instr->RsField());
      set_register(instr->RtField(), rs_val ^ instr->UImmField());
      break;
      break;
    }
    default: {
      OS::PrintErr("Undecoded instruction: 0x%x at %p\n",
                    instr->InstructionBits(), instr);
      UnimplementedInstruction(instr);
      break;
    }
  }
  pc_ += Instr::kInstrSize;
}


void Simulator::ExecuteDelaySlot() {
  ASSERT(pc_ != kEndSimulatingPC);
  delay_slot_ = true;
  icount_++;
  Instr* instr = Instr::At(pc_ + Instr::kInstrSize);
  if ((FLAG_stop_sim_at != 0) && (icount_ == FLAG_stop_sim_at)) {
    SimulatorDebugger dbg(this);
    dbg.Stop(instr, "Instruction count reached");
  }
  InstructionDecode(instr);
  delay_slot_ = false;
}


void Simulator::Execute() {
  if (FLAG_stop_sim_at == 0) {
    // Fast version of the dispatch loop without checking whether the simulator
    // should be stopping at a particular executed instruction.
    while (pc_ != kEndSimulatingPC) {
      icount_++;
      Instr* instr = Instr::At(pc_);
      if (IsIllegalAddress(pc_)) {
        HandleIllegalAccess(pc_, instr);
      } else {
        InstructionDecode(instr);
      }
    }
  } else {
    // FLAG_stop_sim_at is at the non-default value. Stop in the debugger when
    // we reach the particular instruction count.
    while (pc_ != kEndSimulatingPC) {
      icount_++;
      Instr* instr = Instr::At(pc_);
      if (icount_ == FLAG_stop_sim_at) {
        SimulatorDebugger dbg(this);
        dbg.Stop(instr, "Instruction count reached");
      } else {
        if (IsIllegalAddress(pc_)) {
          HandleIllegalAccess(pc_, instr);
        } else {
          InstructionDecode(instr);
        }
      }
    }
  }
}


int64_t Simulator::Call(int32_t entry,
                        int32_t parameter0,
                        int32_t parameter1,
                        int32_t parameter2,
                        int32_t parameter3,
                        bool fp_return,
                        bool fp_args) {
  // Save the SP register before the call so we can restore it.
  int32_t sp_before_call = get_register(SP);

  // Setup parameters.
  if (fp_args) {
    set_fregister(F0, parameter0);
    set_fregister(F1, parameter1);
    set_fregister(F2, parameter2);
    set_fregister(F3, parameter3);
  } else {
    set_register(A0, parameter0);
    set_register(A1, parameter1);
    set_register(A2, parameter2);
    set_register(A3, parameter3);
  }

  // Make sure the activation frames are properly aligned.
  int32_t stack_pointer = sp_before_call;
  if (OS::ActivationFrameAlignment() > 1) {
    stack_pointer =
        Utils::RoundDown(stack_pointer, OS::ActivationFrameAlignment());
  }
  set_register(SP, stack_pointer);

  // Prepare to execute the code at entry.
  set_pc(entry);
  // Put down marker for end of simulation. The simulator will stop simulation
  // when the PC reaches this value. By saving the "end simulation" value into
  // RA the simulation stops when returning to this call point.
  set_register(RA, kEndSimulatingPC);

  // Remember the values of callee-saved registers.
  // The code below assumes that r9 is not used as sb (static base) in
  // simulator code and therefore is regarded as a callee-saved register.
  int32_t r16_val = get_register(R16);
  int32_t r17_val = get_register(R17);
  int32_t r18_val = get_register(R18);
  int32_t r19_val = get_register(R19);
  int32_t r20_val = get_register(R20);
  int32_t r21_val = get_register(R21);
  int32_t r22_val = get_register(R22);
  int32_t r23_val = get_register(R23);

  double d10_val = get_dregister(D10);
  double d11_val = get_dregister(D11);
  double d12_val = get_dregister(D12);
  double d13_val = get_dregister(D13);
  double d14_val = get_dregister(D14);
  double d15_val = get_dregister(D15);

  // Setup the callee-saved registers with a known value. To be able to check
  // that they are preserved properly across dart execution.
  int32_t callee_saved_value = icount_;
  set_register(R16, callee_saved_value);
  set_register(R17, callee_saved_value);
  set_register(R18, callee_saved_value);
  set_register(R19, callee_saved_value);
  set_register(R20, callee_saved_value);
  set_register(R21, callee_saved_value);
  set_register(R22, callee_saved_value);
  set_register(R23, callee_saved_value);

  set_dregister_bits(D10, callee_saved_value);
  set_dregister_bits(D11, callee_saved_value);
  set_dregister_bits(D12, callee_saved_value);
  set_dregister_bits(D13, callee_saved_value);
  set_dregister_bits(D14, callee_saved_value);
  set_dregister_bits(D15, callee_saved_value);

  // Start the simulation
  Execute();

  // Check that the callee-saved registers have been preserved.
  ASSERT(callee_saved_value == get_register(R16));
  ASSERT(callee_saved_value == get_register(R17));
  ASSERT(callee_saved_value == get_register(R18));
  ASSERT(callee_saved_value == get_register(R19));
  ASSERT(callee_saved_value == get_register(R20));
  ASSERT(callee_saved_value == get_register(R21));
  ASSERT(callee_saved_value == get_register(R22));
  ASSERT(callee_saved_value == get_register(R23));

  ASSERT(callee_saved_value == get_dregister_bits(D10));
  ASSERT(callee_saved_value == get_dregister_bits(D11));
  ASSERT(callee_saved_value == get_dregister_bits(D12));
  ASSERT(callee_saved_value == get_dregister_bits(D13));
  ASSERT(callee_saved_value == get_dregister_bits(D14));
  ASSERT(callee_saved_value == get_dregister_bits(D15));

  // Restore callee-saved registers with the original value.
  set_register(R16, r16_val);
  set_register(R17, r17_val);
  set_register(R18, r18_val);
  set_register(R19, r19_val);
  set_register(R20, r20_val);
  set_register(R21, r21_val);
  set_register(R22, r22_val);
  set_register(R23, r23_val);

  set_dregister(D10, d10_val);
  set_dregister(D11, d11_val);
  set_dregister(D12, d12_val);
  set_dregister(D13, d13_val);
  set_dregister(D14, d14_val);
  set_dregister(D15, d15_val);

  // Restore the SP register and return V1:V0.
  set_register(SP, sp_before_call);
  int64_t return_value;
  if (fp_return) {
    return_value = Utils::LowHighTo64Bits(get_fregister(F0), get_fregister(F1));
  } else {
    return_value = Utils::LowHighTo64Bits(get_register(V0), get_register(V1));
  }
  return return_value;
}


void Simulator::Longjmp(uword pc,
                        uword sp,
                        uword fp,
                        RawObject* raw_exception,
                        RawObject* raw_stacktrace) {
  // Walk over all setjmp buffers (simulated --> C++ transitions)
  // and try to find the setjmp associated with the simulated stack pointer.
  SimulatorSetjmpBuffer* buf = last_setjmp_buffer();
  while (buf->link() != NULL && buf->link()->sp() <= sp) {
    buf = buf->link();
  }
  ASSERT(buf != NULL);

  // The C++ caller has not cleaned up the stack memory of C++ frames.
  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous C++ frames.
  uword native_sp = buf->native_sp();
  Isolate* isolate = Isolate::Current();
  while (isolate->top_resource() != NULL &&
         (reinterpret_cast<uword>(isolate->top_resource()) < native_sp)) {
    isolate->top_resource()->~StackResource();
  }

  // Unwind the C++ stack and continue simulation in the target frame.
  set_pc(static_cast<int32_t>(pc));
  set_register(SP, static_cast<int32_t>(sp));
  set_register(FP, static_cast<int32_t>(fp));

  ASSERT(raw_exception != Object::null());
  set_register(kExceptionObjectReg, bit_cast<int32_t>(raw_exception));
  set_register(kStackTraceObjectReg, bit_cast<int32_t>(raw_stacktrace));
  buf->Longjmp();
}

}  // namespace dart

#endif  // !defined(HOST_ARCH_MIPS)

#endif  // defined TARGET_ARCH_MIPS
