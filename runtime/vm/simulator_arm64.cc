// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <math.h>  // for isnan.
#include <setjmp.h>
#include <stdlib.h>

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

// Only build the simulator if not compiling for real ARM hardware.
#if !defined(HOST_ARCH_ARM64)

#include "vm/simulator.h"

#include "vm/assembler.h"
#include "vm/constants_arm64.h"
#include "vm/cpu.h"
#include "vm/disassembler.h"
#include "vm/native_arguments.h"
#include "vm/stack_frame.h"
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
    sp_ = static_cast<uword>(sim->get_register(R31, R31IsSP));
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
// simulated ARM64 code.
class SimulatorDebugger {
 public:
  explicit SimulatorDebugger(Simulator* sim);
  ~SimulatorDebugger();

  void Stop(Instr* instr, const char* message);
  void Debug();
  char* ReadLine(const char* prompt);

 private:
  Simulator* sim_;

  bool GetValue(char* desc, int64_t* value);
  bool GetDValue(char* desc, int64_t* value);
  // TODO(zra): Breakpoints.
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
      "r28", "r29", "r30",

      "ip0", "ip1", "pp",  "ctx", "fp",  "lr",  "sp", "zr",
  };
  static const Register kRegisters[] = {
      R0,  R1,  R2,  R3,  R4,  R5,  R6,  R7,
      R8,  R9,  R10, R11, R12, R13, R14, R15,
      R16, R17, R18, R19, R20, R21, R22, R23,
      R24, R25, R26, R27, R28, R29, R30,

      IP0, IP1, PP, CTX, FP, LR, R31, ZR,
  };
  ASSERT(ARRAY_SIZE(kNames) == ARRAY_SIZE(kRegisters));
  for (unsigned i = 0; i < ARRAY_SIZE(kNames); i++) {
    if (strcmp(kNames[i], name) == 0) {
      return kRegisters[i];
    }
  }
  return kNoRegister;
}


static VRegister LookupVRegisterByName(const char* name) {
  int reg_nr = -1;
  bool ok = SScanF(name, "v%d", &reg_nr);
  if (ok && (0 <= reg_nr) && (reg_nr < kNumberOfVRegisters)) {
    return static_cast<VRegister>(reg_nr);
  }
  return kNoVRegister;
}


bool SimulatorDebugger::GetValue(char* desc, int64_t* value) {
  Register reg = LookupCpuRegisterByName(desc);
  if (reg != kNoRegister) {
    if (reg == ZR) {
      *value = 0;
      return true;
    }
    *value = sim_->get_register(reg);
    return true;
  }
  if (desc[0] == '*') {
    int64_t addr;
    if (GetValue(desc + 1, &addr)) {
      if (Simulator::IsIllegalAddress(addr)) {
        return false;
      }
      *value = *(reinterpret_cast<int64_t*>(addr));
      return true;
    }
  }
  if (strcmp("pc", desc) == 0) {
    *value = sim_->get_pc();
    return true;
  }
  bool retval = SScanF(desc, "0x%"Px64, value) == 1;
  if (!retval) {
    retval = SScanF(desc, "%"Px64, value) == 1;
  }
  return retval;
}


bool SimulatorDebugger::GetDValue(char* desc, int64_t* value) {
  VRegister vreg = LookupVRegisterByName(desc);
  if (vreg != kNoVRegister) {
    *value = sim_->get_vregisterd(vreg);
    return true;
  }
  if (desc[0] == '*') {
    int64_t addr;
    if (GetValue(desc + 1, &addr)) {
      if (Simulator::IsIllegalAddress(addr)) {
        return false;
      }
      *value = *(reinterpret_cast<int64_t*>(addr));
      return true;
    }
  }
  return false;
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

  // TODO(zra): Undo all set breakpoints while running in the debugger shell.
  // This will make them invisible to all commands.
  // UndoBreakpoints();

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
                  "flags -- print flag values\n"
                  "gdb -- transfer control to gdb\n"
                  "h/help -- print this help string\n"
                  "p/print <reg or value or *addr> -- print integer value\n"
                  "pd/printdouble <dreg or *addr> -- print double value\n"
                  "po/printobject <*reg or *addr> -- print object\n"
                  "si/stepi -- single step an instruction\n"
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
          int64_t value;
          if (GetValue(arg1, &value)) {
            OS::Print("%s: %"Pu64" 0x%"Px64"\n", arg1, value, value);
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("print <reg or value or *addr>\n");
        }
      } else if ((strcmp(cmd, "pd") == 0) ||
                 (strcmp(cmd, "printdouble") == 0)) {
        if (args == 2) {
          int64_t long_value;
          if (GetDValue(arg1, &long_value)) {
            double dvalue = bit_cast<double, int64_t>(long_value);
            OS::Print("%s: %"Pu64" 0x%"Px64" %.8g\n",
                arg1, long_value, long_value, dvalue);
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("printdouble <dreg or *addr>\n");
        }
      } else if ((strcmp(cmd, "po") == 0) ||
                 (strcmp(cmd, "printobject") == 0)) {
        if (args == 2) {
          int64_t value;
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
              OS::Print("0x%"Px64" is not an object reference\n", value);
            }
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("printobject <*reg or *addr>\n");
        }
      } else if (strcmp(cmd, "disasm") == 0) {
        int64_t start = 0;
        int64_t end = 0;
        if (args == 1) {
          start = sim_->get_pc();
          end = start + (10 * Instr::kInstrSize);
        } else if (args == 2) {
          if (GetValue(arg1, &start)) {
            // no length parameter passed, assume 10 instructions
            if (Simulator::IsIllegalAddress(start)) {
              // If start isn't a valid address, warn and use PC instead
              OS::Print("First argument yields invalid address: 0x%"Px64"\n",
                        start);
              OS::Print("Using PC instead");
              start = sim_->get_pc();
            }
            end = start + (10 * Instr::kInstrSize);
          }
        } else {
          int64_t length;
          if (GetValue(arg1, &start) && GetValue(arg2, &length)) {
            if (Simulator::IsIllegalAddress(start)) {
              // If start isn't a valid address, warn and use PC instead
              OS::Print("First argument yields invalid address: 0x%"Px64"\n",
                        start);
              OS::Print("Using PC instead\n");
              start = sim_->get_pc();
            }
            end = start + (length * Instr::kInstrSize);
          }
        }
        Disassembler::Disassemble(start, end);
      } else if (strcmp(cmd, "flags") == 0) {
        OS::Print("APSR: ");
        OS::Print("N flag: %d; ", sim_->n_flag_);
        OS::Print("Z flag: %d; ", sim_->z_flag_);
        OS::Print("C flag: %d; ", sim_->c_flag_);
        OS::Print("V flag: %d\n", sim_->v_flag_);
      } else if (strcmp(cmd, "gdb") == 0) {
        OS::Print("relinquishing control to gdb\n");
        OS::DebugBreak();
        OS::Print("regaining control from gdb\n");
      } else {
        OS::Print("Unknown command: %s\n", cmd);
      }
    }
    delete[] line;
  }

  // TODO(zra): Add all the breakpoints back to stop execution and enter the
  // debugger shell when hit.
  // RedoBreakpoints();

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
  pc_modified_ = false;
  icount_ = 0;
  break_pc_ = NULL;
  break_instr_ = 0;
  last_setjmp_buffer_ = NULL;
  top_exit_frame_info_ = 0;

  // Setup architecture state.
  // All registers are initialized to zero to start with.
  for (int i = 0; i < kNumberOfCpuRegisters; i++) {
    registers_[i] = 0;
  }
  n_flag_ = false;
  z_flag_ = false;
  c_flag_ = false;
  v_flag_ = false;

  for (int i = 0; i < kNumberOfVRegisters; i++) {
    vregisters_[i].lo = 0;
    vregisters_[i].hi = 0;
  }

  // The sp is initialized to point to the bottom (high address) of the
  // allocated stack area.
  registers_[R31] = StackTop();
  // The lr and pc are initialized to a known bad value that will cause an
  // access violation if the simulator ever tries to execute it.
  registers_[LR] = kBadLR;
  pc_ = kBadLR;
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
// reference to a svc (supervisor call) instruction that is handled by
// the simulator.  We write the original destination of the jump just at a known
// offset from the svc instruction so the simulator knows what to call.
class Redirection {
 public:
  uword address_of_hlt_instruction() {
    return reinterpret_cast<uword>(&hlt_instruction_);
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

  static Redirection* FromHltInstruction(Instr* hlt_instruction) {
    char* addr_of_hlt = reinterpret_cast<char*>(hlt_instruction);
    char* addr_of_redirection =
        addr_of_hlt - OFFSET_OF(Redirection, hlt_instruction_);
    return reinterpret_cast<Redirection*>(addr_of_redirection);
  }

 private:
  static const int32_t kRedirectInstruction = Instr::kRedirectInstruction;
  Redirection(uword external_function,
              Simulator::CallKind call_kind,
              int argument_count)
      : external_function_(external_function),
        call_kind_(call_kind),
        argument_count_(argument_count),
        hlt_instruction_(kRedirectInstruction),
        next_(list_) {
    list_ = this;
  }

  uword external_function_;
  Simulator::CallKind call_kind_;
  int argument_count_;
  uint32_t hlt_instruction_;
  Redirection* next_;
  static Redirection* list_;
};


Redirection* Redirection::list_ = NULL;


uword Simulator::RedirectExternalReference(uword function,
                                           CallKind call_kind,
                                           int argument_count) {
  Redirection* redirection =
      Redirection::Get(function, call_kind, argument_count);
  return redirection->address_of_hlt_instruction();
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
void Simulator::set_register(Register reg, int64_t value, R31Type r31t) {
  // register is in range, and if it is R31, a mode is specified.
  ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
  if ((reg != R31) || (r31t != R31IsZR)) {
    registers_[reg] = value;
  }
}


// Get the register from the architecture state.
int64_t Simulator::get_register(Register reg, R31Type r31t) const {
  ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
  if ((reg == R31) && (r31t == R31IsZR)) {
    return 0;
  } else {
    return registers_[reg];
  }
}


void Simulator::set_wregister(Register reg, int32_t value, R31Type r31t) {
  ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
  // When setting in W mode, clear the high bits.
  if ((reg != R31) || (r31t != R31IsZR)) {
    registers_[reg] = Utils::LowHighTo64Bits(static_cast<uint32_t>(value), 0);
  }
}


// Get the register from the architecture state.
int32_t Simulator::get_wregister(Register reg, R31Type r31t) const {
  ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
  if ((reg == R31) && (r31t == R31IsZR)) {
    return 0;
  } else {
    return registers_[reg];
  }
}


int64_t Simulator::get_vregisterd(VRegister reg) {
  ASSERT((reg >= 0) && (reg < kNumberOfVRegisters));
  return vregisters_[reg].lo;
}


void Simulator::set_vregisterd(VRegister reg, int64_t value) {
  ASSERT((reg >= 0) && (reg < kNumberOfVRegisters));
  vregisters_[reg].lo = value;
  vregisters_[reg].hi = 0;
}


// Raw access to the PC register.
void Simulator::set_pc(int64_t value) {
  pc_modified_ = true;
  last_pc_ = pc_;
  pc_ = value;
}


// Raw access to the pc.
int64_t Simulator::get_pc() const {
  return pc_;
}


int64_t Simulator::get_last_pc() const {
  return last_pc_;
}


void Simulator::HandleIllegalAccess(uword addr, Instr* instr) {
  uword fault_pc = get_pc();
  uword last_pc = get_last_pc();
  // TODO(zra): drop into debugger.
  char buffer[128];
  snprintf(buffer, sizeof(buffer),
      "illegal memory access at 0x%" Px ", pc=0x%" Px ", last_pc=0x%" Px"\n",
      addr, fault_pc, last_pc);
  SimulatorDebugger dbg(this);
  dbg.Stop(instr, buffer);
  // The debugger will return control in non-interactive mode.
  FATAL("Cannot continue execution after illegal memory access.");
}


// The ARMv8 manual advises that an unaligned access may generate a fault,
// and if not, will likely take a number of additional cycles to execute,
// so let's just not generate any.
void Simulator::UnalignedAccess(const char* msg, uword addr, Instr* instr) {
  char buffer[128];
  snprintf(buffer, sizeof(buffer),
           "unaligned %s at 0x%" Px ", pc=%p\n", msg, addr, instr);
  SimulatorDebugger dbg(this);
  dbg.Stop(instr, buffer);
  // The debugger will not be able to single step past this instruction, but
  // it will be possible to disassemble the code and inspect registers.
  FATAL("Cannot continue execution after unaligned access.");
}


void Simulator::UnimplementedInstruction(Instr* instr) {
  char buffer[128];
  snprintf(buffer, sizeof(buffer),
      "Unimplemented instruction: at %p, last_pc=0x%" Px64 "\n",
      instr, get_last_pc());
  SimulatorDebugger dbg(this);
  dbg.Stop(instr, buffer);
  FATAL("Cannot continue execution after unimplemented instruction.");
}


// Returns the top of the stack area to enable checking for stack pointer
// validity.
uword Simulator::StackTop() const {
  // To be safe in potential stack underflows we leave some buffer above and
  // set the stack top.
  return reinterpret_cast<uword>(stack_) +
      (Isolate::GetSpecifiedStackSize() + Isolate::kStackSizeBuffer);
}


intptr_t Simulator::ReadX(uword addr, Instr* instr) {
  if ((addr & 7) == 0) {
    intptr_t* ptr = reinterpret_cast<intptr_t*>(addr);
    return *ptr;
  }
  UnalignedAccess("read", addr, instr);
  return 0;
}


void Simulator::WriteX(uword addr, intptr_t value, Instr* instr) {
  if ((addr & 7) == 0) {
    intptr_t* ptr = reinterpret_cast<intptr_t*>(addr);
    *ptr = value;
    return;
  }
  UnalignedAccess("write", addr, instr);
}


uint32_t Simulator::ReadWU(uword addr, Instr* instr) {
  if ((addr & 3) == 0) {
    uint32_t* ptr = reinterpret_cast<uint32_t*>(addr);
    return *ptr;
  }
  UnalignedAccess("read unsigned single word", addr, instr);
  return 0;
}


int32_t Simulator::ReadW(uword addr, Instr* instr) {
  if ((addr & 3) == 0) {
    int32_t* ptr = reinterpret_cast<int32_t*>(addr);
    return *ptr;
  }
  UnalignedAccess("read single word", addr, instr);
  return 0;
}


void Simulator::WriteW(uword addr, uint32_t value, Instr* instr) {
  if ((addr & 3) == 0) {
    uint32_t* ptr = reinterpret_cast<uint32_t*>(addr);
    *ptr = value;
    return;
  }
  UnalignedAccess("write single word", addr, instr);
}


uint16_t Simulator::ReadHU(uword addr, Instr* instr) {
  if ((addr & 1) == 0) {
    uint16_t* ptr = reinterpret_cast<uint16_t*>(addr);
    return *ptr;
  }
  UnalignedAccess("unsigned halfword read", addr, instr);
  return 0;
}


int16_t Simulator::ReadH(uword addr, Instr* instr) {
  if ((addr & 1) == 0) {
    int16_t* ptr = reinterpret_cast<int16_t*>(addr);
    return *ptr;
  }
  UnalignedAccess("signed halfword read", addr, instr);
  return 0;
}


void Simulator::WriteH(uword addr, uint16_t value, Instr* instr) {
  if ((addr & 1) == 0) {
    uint16_t* ptr = reinterpret_cast<uint16_t*>(addr);
    *ptr = value;
    return;
  }
  UnalignedAccess("halfword write", addr, instr);
}


uint8_t Simulator::ReadBU(uword addr) {
  uint8_t* ptr = reinterpret_cast<uint8_t*>(addr);
  return *ptr;
}


int8_t Simulator::ReadB(uword addr) {
  int8_t* ptr = reinterpret_cast<int8_t*>(addr);
  return *ptr;
}


void Simulator::WriteB(uword addr, uint8_t value) {
  uint8_t* ptr = reinterpret_cast<uint8_t*>(addr);
  *ptr = value;
}


// Unsupported instructions use Format to print an error and stop execution.
void Simulator::Format(Instr* instr, const char* format) {
  OS::Print("Simulator found unsupported instruction:\n 0x%p: %s\n",
            instr,
            format);
  UNIMPLEMENTED();
}


// Calculate and set the Negative and Zero flags.
void Simulator::SetNZFlagsW(int32_t val) {
  n_flag_ = (val < 0);
  z_flag_ = (val == 0);
}


// Calculate C flag value for additions.
bool Simulator::CarryFromW(int32_t left, int32_t right) {
  uint32_t uleft = static_cast<uint32_t>(left);
  uint32_t uright = static_cast<uint32_t>(right);
  uint32_t urest  = 0xffffffffU - uleft;

  return (uright > urest);
}


// Calculate C flag value for subtractions.
bool Simulator::BorrowFromW(int32_t left, int32_t right) {
  uint32_t uleft = static_cast<uint32_t>(left);
  uint32_t uright = static_cast<uint32_t>(right);

  return (uright > uleft);
}


// Calculate V flag value for additions and subtractions.
bool Simulator::OverflowFromW(int32_t alu_out,
                              int32_t left, int32_t right, bool addition) {
  bool overflow;
  if (addition) {
               // operands have the same sign
    overflow = ((left >= 0 && right >= 0) || (left < 0 && right < 0))
               // and operands and result have different sign
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  } else {
               // operands have different signs
    overflow = ((left < 0 && right >= 0) || (left >= 0 && right < 0))
               // and first operand and result have different signs
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  }
  return overflow;
}


// Calculate and set the Negative and Zero flags.
void Simulator::SetNZFlagsX(int64_t val) {
  n_flag_ = (val < 0);
  z_flag_ = (val == 0);
}


// Calculate C flag value for additions.
bool Simulator::CarryFromX(int64_t left, int64_t right) {
  uint64_t uleft = static_cast<uint64_t>(left);
  uint64_t uright = static_cast<uint64_t>(right);
  uint64_t urest  = 0xffffffffffffffffULL - uleft;

  return (uright > urest);
}


// Calculate C flag value for subtractions.
bool Simulator::BorrowFromX(int64_t left, int64_t right) {
  uint64_t uleft = static_cast<uint64_t>(left);
  uint64_t uright = static_cast<uint64_t>(right);

  return (uright > uleft);
}


// Calculate V flag value for additions and subtractions.
bool Simulator::OverflowFromX(int64_t alu_out,
                              int64_t left, int64_t right, bool addition) {
  bool overflow;
  if (addition) {
               // operands have the same sign
    overflow = ((left >= 0 && right >= 0) || (left < 0 && right < 0))
               // and operands and result have different sign
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  } else {
               // operands have different signs
    overflow = ((left < 0 && right >= 0) || (left >= 0 && right < 0))
               // and first operand and result have different signs
               && ((left < 0 && alu_out >= 0) || (left >= 0 && alu_out < 0));
  }
  return overflow;
}


// Set the Carry flag.
void Simulator::SetCFlag(bool val) {
  c_flag_ = val;
}


// Set the oVerflow flag.
void Simulator::SetVFlag(bool val) {
  v_flag_ = val;
}


void Simulator::DecodeMoveWide(Instr* instr) {
  const Register rd = instr->RdField();
  const int hw = instr->HWField();
  const int64_t shift = hw << 4;
  const int64_t shifted_imm =
      static_cast<int64_t>(instr->Imm16Field()) << shift;

  if (instr->SFField()) {
    if (instr->Bits(29, 2) == 0) {
      // Format(instr, "movn'sf 'rd, 'imm16 'hw");
      set_register(rd, ~shifted_imm, instr->RdMode());
    } else if (instr->Bits(29, 2) == 2) {
      // Format(instr, "movz'sf 'rd, 'imm16 'hw");
      set_register(rd, shifted_imm, instr->RdMode());
    } else if (instr->Bits(29, 2) == 3) {
      // Format(instr, "movk'sf 'rd, 'imm16 'hw");
      const int64_t rd_val = get_register(rd, instr->RdMode());
      const int64_t result = (rd_val & ~(0xffffL << shift)) | shifted_imm;
      set_register(rd, result, instr->RdMode());
    } else {
      UnimplementedInstruction(instr);
    }
  } else if ((hw & 0x2) == 0) {
    if (instr->Bits(29, 2) == 0) {
      // Format(instr, "movn'sf 'rd, 'imm16 'hw");
      set_wregister(rd, ~shifted_imm & kWRegMask,  instr->RdMode());
    } else if (instr->Bits(29, 2) == 2) {
      // Format(instr, "movz'sf 'rd, 'imm16 'hw");
      set_wregister(rd, shifted_imm & kWRegMask, instr->RdMode());
    } else if (instr->Bits(29, 2) == 3) {
      // Format(instr, "movk'sf 'rd, 'imm16 'hw");
      const int32_t rd_val = get_wregister(rd, instr->RdMode());
      const int32_t result = (rd_val & ~(0xffffL << shift)) | shifted_imm;
      set_wregister(rd, result, instr->RdMode());
    } else {
      UnimplementedInstruction(instr);
    }
  } else {
    // Dest is 32 bits, but shift is more than 32.
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeAddSubImm(Instr* instr) {
  bool addition = (instr->Bit(30) == 0);
  // Format(instr, "addi'sf's 'rd, 'rn, 'imm12s");
  // Format(instr, "subi'sf's 'rd, 'rn, 'imm12s");
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const uint32_t imm = (instr->Bit(22) == 1) ? (instr->Imm12Field() << 12)
                                             : (instr->Imm12Field());
  if (instr->SFField()) {
    // 64-bit add.
    const int64_t rn_val = get_register(rn, instr->RnMode());
    const int64_t alu_out = addition ? (rn_val + imm) : (rn_val - imm);
    set_register(rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsX(alu_out);
      if (addition) {
        SetCFlag(CarryFromX(rn_val, imm));
      } else {
        SetCFlag(!BorrowFromX(rn_val, imm));
      }
      SetVFlag(OverflowFromX(alu_out, rn_val, imm, addition));
    }
  } else {
    // 32-bit add.
    const int32_t rn_val = get_wregister(rn, instr->RnMode());
    const int32_t alu_out = addition ? (rn_val + imm) : (rn_val - imm);
    set_wregister(rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsW(alu_out);
      if (addition) {
        SetCFlag(CarryFromW(rn_val, imm));
      } else {
        SetCFlag(!BorrowFromW(rn_val, imm));
      }
      SetVFlag(OverflowFromW(alu_out, rn_val, imm, addition));
    }
  }
}


void Simulator::DecodeLogicalImm(Instr* instr) {
  const int op = instr->Bits(29, 2);
  const bool set_flags = op == 3;
  const int out_size = ((instr->SFField() == 0) && (instr->NField() == 0))
                       ? kWRegSizeInBits : kXRegSizeInBits;
  const Register rn = instr->RnField();
  const Register rd = instr->RdField();
  const int64_t rn_val = get_register(rn, instr->RnMode());
  const uint64_t imm = instr->ImmLogical();
  if (imm == 0) {
    UnimplementedInstruction(instr);
  }

  int64_t alu_out = 0;
  switch (op) {
    case 0:
      alu_out = rn_val & imm;
      break;
    case 1:
      alu_out = rn_val | imm;
      break;
    case 2:
      alu_out = rn_val ^ imm;
      break;
    case 3:
      alu_out = rn_val & imm;
      break;
    default:
      UNREACHABLE();
      break;
  }

  if (set_flags) {
    if (out_size == kXRegSizeInBits) {
      SetNZFlagsX(alu_out);
    } else {
      SetNZFlagsW(alu_out);
    }
    SetCFlag(false);
    SetVFlag(false);
  }

  if (out_size == kXRegSizeInBits) {
    set_register(rd, alu_out, instr->RdMode());
  } else {
    set_wregister(rd, alu_out, instr->RdMode());
  }
}


void Simulator::DecodePCRel(Instr* instr) {
  const int op = instr->Bit(31);
  if (op == 0) {
    // Format(instr, "adr 'rd, 'pcrel")
    const Register rd = instr->RdField();
    const int64_t immhi = instr->SImm19Field();
    const int64_t immlo = instr->Bits(29, 2);
    const int64_t off = (immhi << 2) | immlo;
    const int64_t dest = get_pc() + off;
    set_register(rd, dest, instr->RdMode());
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeDPImmediate(Instr* instr) {
  if (instr->IsMoveWideOp()) {
    DecodeMoveWide(instr);
  } else if (instr->IsAddSubImmOp()) {
    DecodeAddSubImm(instr);
  } else if (instr->IsLogicalImmOp()) {
    DecodeLogicalImm(instr);
  } else if (instr->IsPCRelOp()) {
    DecodePCRel(instr);
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeCompareAndBranch(Instr* instr) {
  const int op = instr->Bit(24);
  const Register rt = instr->RtField();
  const int64_t imm19 = instr->SImm19Field();
  const int64_t dest = get_pc() + (imm19 << 2);
  const int64_t mask = instr->SFField() == 1 ? kXRegMask : kWRegMask;
  const int64_t rt_val = get_register(rt, R31IsZR) & mask;
  if (op == 0) {
    // Format(instr, "cbz'sf 'rt, 'dest19");
    if (rt_val == 0) {
      set_pc(dest);
    }
  } else {
    // Format(instr, "cbnz'sf 'rt, 'dest19");
    if (rt_val != 0) {
      set_pc(dest);
    }
  }
}


bool Simulator::ConditionallyExecute(Instr* instr) {
  Condition cond;
  if (instr->IsConditionalSelectOp()) {
    cond = instr->SelectConditionField();
  } else {
    cond = instr->ConditionField();
  }
  switch (cond) {
    case EQ: return z_flag_;
    case NE: return !z_flag_;
    case CS: return c_flag_;
    case CC: return !c_flag_;
    case MI: return n_flag_;
    case PL: return !n_flag_;
    case VS: return v_flag_;
    case VC: return !v_flag_;
    case HI: return c_flag_ && !z_flag_;
    case LS: return !c_flag_ || z_flag_;
    case GE: return n_flag_ == v_flag_;
    case LT: return n_flag_ != v_flag_;
    case GT: return !z_flag_ && (n_flag_ == v_flag_);
    case LE: return z_flag_ || (n_flag_ != v_flag_);
    case AL: return true;
    default: UNREACHABLE();
  }
  return false;
}


void Simulator::DecodeConditionalBranch(Instr* instr) {
  // Format(instr, "b'cond 'dest19");
  if ((instr->Bit(24) != 0) || (instr->Bit(4) != 0)) {
    UnimplementedInstruction(instr);
  }
  const int64_t imm19 = instr->SImm19Field();
  const int64_t dest = get_pc() + (imm19 << 2);
  if (ConditionallyExecute(instr)) {
    set_pc(dest);
  }
}


// Calls into the Dart runtime are based on this interface.
typedef void (*SimulatorRuntimeCall)(NativeArguments arguments);

// Calls to leaf Dart runtime functions are based on this interface.
typedef int32_t (*SimulatorLeafRuntimeCall)(
    int64_t r0, int64_t r1, int64_t r2, int64_t r3,
    int64_t r4, int64_t r5, int64_t r6, int64_t r7);

// Calls to leaf float Dart runtime functions are based on this interface.
typedef double (*SimulatorLeafFloatRuntimeCall)(
    double d0, double d1, double d2, double d3,
    double d4, double d5, double d6, double d7);

// Calls to native Dart functions are based on this interface.
typedef void (*SimulatorBootstrapNativeCall)(NativeArguments* arguments);
typedef void (*SimulatorNativeCall)(NativeArguments* arguments, uword target);


void Simulator::DoRedirectedCall(Instr* instr) {
  SimulatorSetjmpBuffer buffer(this);
  if (!setjmp(buffer.buffer_)) {
    int64_t saved_lr = get_register(LR);
    Redirection* redirection = Redirection::FromHltInstruction(instr);
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
      arguments.isolate_ = reinterpret_cast<Isolate*>(get_register(R0));
      arguments.argc_tag_ = get_register(R1);
      arguments.argv_ = reinterpret_cast<RawObject*(*)[]>(get_register(R2));
      arguments.retval_ = reinterpret_cast<RawObject**>(get_register(R3));
      SimulatorRuntimeCall target =
          reinterpret_cast<SimulatorRuntimeCall>(external);
      target(arguments);
      set_register(R0, icount_);  // Zap result register from void function.
      set_register(R1, icount_);
    } else if (redirection->call_kind() == kLeafRuntimeCall) {
      ASSERT((0 <= redirection->argument_count()) &&
             (redirection->argument_count() <= 8));
      SimulatorLeafRuntimeCall target =
          reinterpret_cast<SimulatorLeafRuntimeCall>(external);
      const int64_t r0 = get_register(R0);
      const int64_t r1 = get_register(R1);
      const int64_t r2 = get_register(R2);
      const int64_t r3 = get_register(R3);
      const int64_t r4 = get_register(R4);
      const int64_t r5 = get_register(R5);
      const int64_t r6 = get_register(R6);
      const int64_t r7 = get_register(R7);
      const int64_t res = target(r0, r1, r2, r3, r4, r5, r6, r7);
      set_register(R0, res);  // Set returned result from function.
      set_register(R1, icount_);  // Zap unused result register.
    } else if (redirection->call_kind() == kLeafFloatRuntimeCall) {
      ASSERT((0 <= redirection->argument_count()) &&
             (redirection->argument_count() <= 8));
      SimulatorLeafFloatRuntimeCall target =
          reinterpret_cast<SimulatorLeafFloatRuntimeCall>(external);
      const double d0 = bit_cast<double, int64_t>(get_vregisterd(V0));
      const double d1 = bit_cast<double, int64_t>(get_vregisterd(V1));
      const double d2 = bit_cast<double, int64_t>(get_vregisterd(V2));
      const double d3 = bit_cast<double, int64_t>(get_vregisterd(V3));
      const double d4 = bit_cast<double, int64_t>(get_vregisterd(V4));
      const double d5 = bit_cast<double, int64_t>(get_vregisterd(V5));
      const double d6 = bit_cast<double, int64_t>(get_vregisterd(V6));
      const double d7 = bit_cast<double, int64_t>(get_vregisterd(V7));
      const double res = target(d0, d1, d2, d3, d4, d5, d6, d7);
      set_vregisterd(V0, bit_cast<int64_t, double>(res));
    } else if (redirection->call_kind() == kBootstrapNativeCall) {
      NativeArguments* arguments;
      arguments = reinterpret_cast<NativeArguments*>(get_register(R0));
      SimulatorBootstrapNativeCall target =
          reinterpret_cast<SimulatorBootstrapNativeCall>(external);
      target(arguments);
      set_register(R0, icount_);  // Zap result register from void function.
    } else {
      ASSERT(redirection->call_kind() == kNativeCall);
      NativeArguments* arguments;
      arguments = reinterpret_cast<NativeArguments*>(get_register(R0));
      uword target_func = get_register(R1);
      SimulatorNativeCall target =
          reinterpret_cast<SimulatorNativeCall>(external);
      target(arguments, target_func);
      set_register(R0, icount_);  // Zap result register from void function.
      set_register(R1, icount_);
    }
    set_top_exit_frame_info(0);

    // Zap caller-saved registers, since the actual runtime call could have
    // used them.
    set_register(R2, icount_);
    set_register(R3, icount_);
    set_register(R4, icount_);
    set_register(R5, icount_);
    set_register(R6, icount_);
    set_register(R7, icount_);
    set_register(R8, icount_);
    set_register(R9, icount_);
    set_register(R10, icount_);
    set_register(R11, icount_);
    set_register(R12, icount_);
    set_register(R13, icount_);
    set_register(R14, icount_);
    set_register(R15, icount_);
    set_register(IP0, icount_);
    set_register(IP1, icount_);
    set_register(R18, icount_);
    set_register(LR, icount_);

    // TODO(zra): Zap caller-saved fpu registers.

    // Return.
    set_pc(saved_lr);
  } else {
    // Coming via long jump from a throw. Continue to exception handler.
    set_top_exit_frame_info(0);
  }
}


void Simulator::DecodeExceptionGen(Instr* instr) {
  if ((instr->Bits(0, 2) == 1) && (instr->Bits(2, 3) == 0) &&
      (instr->Bits(21, 3) == 0)) {
    // Format(instr, "svc 'imm16");
    UnimplementedInstruction(instr);
  } else if ((instr->Bits(0, 2) == 0) && (instr->Bits(2, 3) == 0) &&
             (instr->Bits(21, 3) == 1)) {
    // Format(instr, "brk 'imm16");
    UnimplementedInstruction(instr);
  } else if ((instr->Bits(0, 2) == 0) && (instr->Bits(2, 3) == 0) &&
             (instr->Bits(21, 3) == 2)) {
    // Format(instr, "hlt 'imm16");
    uint16_t imm = static_cast<uint16_t>(instr->Imm16Field());
    if (imm == kImmExceptionIsDebug) {
      SimulatorDebugger dbg(this);
      const char* message = *reinterpret_cast<const char**>(
          reinterpret_cast<intptr_t>(instr) - 2 * Instr::kInstrSize);
      set_pc(get_pc() + Instr::kInstrSize);
      dbg.Stop(instr, message);
    } else if (imm == kImmExceptionIsPrintf) {
      const char* message = *reinterpret_cast<const char**>(
          reinterpret_cast<intptr_t>(instr) - 2 * Instr::kInstrSize);
      OS::Print("Simulator hit: %s", message);
    } else if (imm == kImmExceptionIsRedirectedCall) {
      DoRedirectedCall(instr);
    } else {
      UnimplementedInstruction(instr);
    }
  }
}


void Simulator::DecodeSystem(Instr* instr) {
  if ((instr->Bits(0, 8) == 0x5f) && (instr->Bits(12, 4) == 2) &&
      (instr->Bits(16, 3) == 3) && (instr->Bits(19, 2) == 0) &&
      (instr->Bit(21) == 0)) {
    if (instr->Bits(8, 4) == 0) {
      // Format(instr, "nop");
    } else {
      UnimplementedInstruction(instr);
    }
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeTestAndBranch(Instr* instr) {
  const int op = instr->Bit(24);
  const int bitpos = instr->Bits(19, 4) | (instr->Bit(31) << 5);
  const int64_t imm14 = instr->SImm14Field();
  const int64_t dest = get_pc() + (imm14 << 2);
  const Register rt = instr->RtField();
  const int64_t rt_val = get_register(rt, R31IsZR);
  if (op == 0) {
    // Format(instr, "tbz'sf 'rt, 'bitpos, 'dest14");
    if ((rt_val & (1 << bitpos)) == 0) {
      set_pc(dest);
    }
  } else {
    // Format(instr, "tbnz'sf 'rt, 'bitpos, 'dest14");
    if ((rt_val & (1 << bitpos)) != 0) {
      set_pc(dest);
    }
  }
}


void Simulator::DecodeUnconditionalBranch(Instr* instr) {
  const bool link = instr->Bit(31) == 1;
  const int64_t imm26 = instr->SImm26Field();
  const int64_t dest = get_pc() + (imm26 << 2);
  const int64_t ret = get_pc() + Instr::kInstrSize;
  set_pc(dest);
  if (link) {
    set_register(LR, ret);
  }
}


void Simulator::DecodeUnconditionalBranchReg(Instr* instr) {
  if ((instr->Bits(0, 5) == 0) && (instr->Bits(10, 6) == 0) &&
      (instr->Bits(16, 5) == 0x1f)) {
    switch (instr->Bits(21, 4)) {
      case 0: {
        // Format(instr, "br 'rn");
        const Register rn = instr->RnField();
        const int64_t dest = get_register(rn, instr->RnMode());
        set_pc(dest);
        break;
      }
      case 1: {
        // Format(instr, "blr 'rn");
        const Register rn = instr->RnField();
        const int64_t dest = get_register(rn, instr->RnMode());
        const int64_t ret = get_pc() + Instr::kInstrSize;
        set_pc(dest);
        set_register(LR, ret);
        break;
      }
      case 2: {
        // Format(instr, "ret 'rn");
        const Register rn = instr->RnField();
        const int64_t rn_val = get_register(rn, instr->RnMode());
        set_pc(rn_val);
        break;
      }
      default:
        UnimplementedInstruction(instr);
        break;
    }
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeCompareBranch(Instr* instr) {
  if (instr->IsCompareAndBranchOp()) {
    DecodeCompareAndBranch(instr);
  } else if (instr->IsConditionalBranchOp()) {
    DecodeConditionalBranch(instr);
  } else if (instr->IsExceptionGenOp()) {
    DecodeExceptionGen(instr);
  } else if (instr->IsSystemOp()) {
    DecodeSystem(instr);
  } else if (instr->IsTestAndBranchOp()) {
    DecodeTestAndBranch(instr);
  } else if (instr->IsUnconditionalBranchOp()) {
    DecodeUnconditionalBranch(instr);
  } else if (instr->IsUnconditionalBranchRegOp()) {
    DecodeUnconditionalBranchReg(instr);
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeLoadStoreReg(Instr* instr) {
  // Calculate the address.
  const Register rn = instr->RnField();
  const Register rt = instr->RtField();
  const VRegister vt = instr->VtField();
  const int64_t rn_val = get_register(rn, R31IsSP);
  const uint32_t size = instr->SzField();
  uword address = 0;
  uword wb_address = 0;
  bool wb = false;
  if (instr->Bit(24) == 1) {
    // addr = rn + scaled unsigned 12-bit immediate offset.
    const uint32_t imm12 = static_cast<uint32_t>(instr->Imm12Field());
    const uint32_t offset = imm12 << size;
    address = rn_val + offset;
  }  else if (instr->Bits(10, 2) == 0) {
    // addr = rn + signed 9-bit immediate offset.
    wb = false;
    const int64_t offset = static_cast<int64_t>(instr->SImm9Field());
    address = rn_val + offset;
    wb_address = rn_val;
  } else if (instr->Bit(10) == 1) {
    // addr = rn + signed 9-bit immediate offset.
    wb = true;
    const int64_t offset = static_cast<int64_t>(instr->SImm9Field());
    if (instr->Bit(11) == 1) {
      // Pre-index.
      address = rn_val + offset;
      wb_address = address;
    } else {
      // Post-index.
      address = rn_val;
      wb_address = rn_val + offset;
    }
  } else if (instr->Bits(10, 2) == 2) {
    // addr = rn + (rm EXT optionally scaled by operand instruction size).
    const Register rm = instr->RmField();
    const Extend ext = instr->ExtendTypeField();
    const uint8_t scale =
        (ext == UXTX) && (instr->Bit(12) == 1) ? size : 0;
    const int64_t rm_val = get_register(rm, R31IsZR);
    const int64_t offset = ExtendOperand(kXRegSizeInBits, rm_val, ext, scale);
    address = rn_val + offset;
  } else {
    UnimplementedInstruction(instr);
    return;
  }

  // Check the address.
  if (IsIllegalAddress(address)) {
    HandleIllegalAccess(address, instr);
    return;
  }

  // Do access.
  if (instr->Bits(22, 2) == 0) {
    if (instr->Bit(26) == 1) {
      // Format(instr, "vstrd 'vt, 'memop");
      if (size != 3) {
        UnimplementedInstruction(instr);
        return;
      }
      const int64_t vt_val = get_vregisterd(vt);
      WriteX(address, vt_val, instr);
    } else {
      // Format(instr, "str'sz 'rt, 'memop");
      const int32_t rt_val32 = get_wregister(rt, R31IsZR);
      switch (size) {
        case 0: {
          const uint8_t val = static_cast<uint8_t>(rt_val32);
          WriteB(address, val);
          break;
        }
        case 1: {
          const uint16_t val = static_cast<uint16_t>(rt_val32);
          WriteH(address, val, instr);
          break;
        }
        case 2: {
          const uint32_t val = static_cast<uint32_t>(rt_val32);
          WriteW(address, val, instr);
          break;
        }
        case 3: {
          const int64_t val = get_register(rt, R31IsZR);
          WriteX(address, val, instr);
          break;
        }
        default:
          UNREACHABLE();
          break;
      }
    }
  } else {
    if (instr->Bit(26) == 1) {
      // Format(instr, "ldrd 'vt, 'memop");
      if ((size != 3) || (instr->Bit(23) != 0)) {
        UnimplementedInstruction(instr);
        return;
      }
      const int64_t val = ReadX(address, instr);
      set_vregisterd(vt, val);
    } else {
      // Format(instr, "ldr'sz 'rt, 'memop");
      // Undefined case.
      if ((size == 3) && (instr->Bits(22, 2) == 3)) {
        UnimplementedInstruction(instr);
        return;
      }

      // Read the value.
      const bool signd = instr->Bit(23) == 1;
      // Write the W register for signed values when size < 2.
      // Write the W register for unsigned values when size == 2.
      const bool use_w =
          (signd && (instr->Bit(22) == 1)) || (!signd && (size == 2));
      int64_t val = 0;  // Sign extend into an int64_t.
      switch (size) {
        case 0: {
          if (signd) {
            val = static_cast<int64_t>(ReadB(address));
          } else {
            val = static_cast<int64_t>(ReadBU(address));
          }
          break;
        }
        case 1: {
          if (signd) {
            val = static_cast<int64_t>(ReadH(address, instr));
          } else {
            val = static_cast<int64_t>(ReadHU(address, instr));
          }
          break;
        }
        case 2: {
          if (signd) {
            val = static_cast<int64_t>(ReadW(address, instr));
          } else {
            val = static_cast<int64_t>(ReadWU(address, instr));
          }
          break;
        }
        case 3:
          val = ReadX(address, instr);
          break;
        default:
          UNREACHABLE();
          break;
      }

      // Write to register.
      if (use_w) {
        set_wregister(rt, static_cast<int32_t>(val), R31IsZR);
      } else {
        set_register(rt, val, R31IsZR);
      }
    }
  }

  // Do writeback.
  if (wb) {
    set_register(rn, wb_address, R31IsSP);
  }
}


void Simulator::DecodeLoadRegLiteral(Instr* instr) {
  if ((instr->Bit(31) != 0) || (instr->Bit(29) != 0) ||
      (instr->Bits(24, 3) != 0)) {
    UnimplementedInstruction(instr);
  }

  const Register rt = instr->RtField();
  const int64_t off = instr->SImm19Field() << 2;
  const int64_t pc = reinterpret_cast<int64_t>(instr);
  const int64_t address = pc + off;
  const int64_t val = ReadX(address, instr);
  if (instr->Bit(30)) {
    // Format(instr, "ldrx 'rt, 'pcldr");
    set_register(rt, val, R31IsZR);
  } else {
    // Format(instr, "ldrw 'rt, 'pcldr");
    set_wregister(rt, static_cast<int32_t>(val), R31IsZR);
  }
}


void Simulator::DecodeLoadStore(Instr* instr) {
  if (instr->IsLoadStoreRegOp()) {
    DecodeLoadStoreReg(instr);
  } else if (instr->IsLoadRegLiteralOp()) {
    DecodeLoadRegLiteral(instr);
  } else {
    UnimplementedInstruction(instr);
  }
}


int64_t Simulator::ShiftOperand(uint8_t reg_size,
                                int64_t value,
                                Shift shift_type,
                                uint8_t amount) {
  if (amount == 0) {
    return value;
  }
  int64_t mask = reg_size == kXRegSizeInBits ? kXRegMask : kWRegMask;
  switch (shift_type) {
    case LSL:
      return (value << amount) & mask;
    case LSR:
      return static_cast<uint64_t>(value) >> amount;
    case ASR: {
      // Shift used to restore the sign.
      uint8_t s_shift = kXRegSizeInBits - reg_size;
      // Value with its sign restored.
      int64_t s_value = (value << s_shift) >> s_shift;
      return (s_value >> amount) & mask;
    }
    case ROR: {
      if (reg_size == kWRegSizeInBits) {
        value &= kWRegMask;
      }
      return (static_cast<uint64_t>(value) >> amount) |
             ((value & ((1L << amount) - 1L)) << (reg_size - amount));
    }
    default:
      UNIMPLEMENTED();
      return 0;
  }
}


int64_t Simulator::ExtendOperand(uint8_t reg_size,
                                 int64_t value,
                                 Extend extend_type,
                                 uint8_t amount) {
  switch (extend_type) {
    case UXTB:
      value &= 0xff;
      break;
    case UXTH:
      value &= 0xffff;
      break;
    case UXTW:
      value &= 0xffffffff;
      break;
    case SXTB:
      value = (value << 56) >> 56;
      break;
    case SXTH:
      value = (value << 48) >> 48;
      break;
    case SXTW:
      value = (value << 32) >> 32;
      break;
    case UXTX:
    case SXTX:
      break;
    default:
      UNREACHABLE();
      break;
  }
  int64_t mask = (reg_size == kXRegSizeInBits) ? kXRegMask : kWRegMask;
  return (value << amount) & mask;
}


int64_t Simulator::DecodeShiftExtendOperand(Instr* instr) {
  const Register rm = instr->RmField();
  const int64_t rm_val = get_register(rm, R31IsZR);
  const uint8_t size = instr->SFField() ? kXRegSizeInBits : kWRegSizeInBits;
  if (instr->IsShift()) {
    const Shift shift_type = instr->ShiftTypeField();
    const uint8_t shift_amount = instr->Imm6Field();
    return ShiftOperand(size, rm_val, shift_type, shift_amount);
  } else {
    ASSERT(instr->IsExtend());
    const Extend extend_type = instr->ExtendTypeField();
    const uint8_t shift_amount = instr->Imm3Field();
    return ExtendOperand(size, rm_val, extend_type, shift_amount);
  }
  UNREACHABLE();
  return -1;
}


void Simulator::DecodeAddSubShiftExt(Instr* instr) {
  // Format(instr, "add'sf's 'rd, 'rn, 'shift_op");
  // also, sub, cmp, etc.
  const bool subtract = instr->Bit(30) == 1;
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const int64_t rm_val = DecodeShiftExtendOperand(instr);
  if (instr->SFField()) {
    // 64-bit add.
    const int64_t rn_val = get_register(rn, instr->RnMode());
    int64_t alu_out = 0;
    if (subtract) {
      alu_out = rn_val - rm_val;
    } else {
      alu_out = rn_val + rm_val;
    }
    set_register(rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsX(alu_out);
      if (subtract) {
        SetCFlag(!BorrowFromX(rn_val, rm_val));
      } else {
        SetCFlag(CarryFromX(rn_val, rm_val));
      }
      SetVFlag(OverflowFromX(alu_out, rn_val, rm_val, !subtract));
    }
  } else {
    // 32-bit add.
    const int32_t rn_val = get_wregister(rn, instr->RnMode());
    const int32_t rm_val32 = static_cast<int32_t>(rm_val & kWRegMask);
    int32_t alu_out = 0;
    if (subtract) {
      alu_out = rn_val - rm_val32;
    } else {
      alu_out = rn_val + rm_val32;
    }
    set_wregister(rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsW(alu_out);
      if (subtract) {
        SetCFlag(!BorrowFromW(rn_val, rm_val32));
      } else {
        SetCFlag(CarryFromW(rn_val, rm_val32));
      }
      SetVFlag(OverflowFromW(alu_out, rn_val, rm_val32, !subtract));
    }
  }
}


void Simulator::DecodeLogicalShift(Instr* instr) {
  const int op = (instr->Bits(29, 2) << 1) | instr->Bit(21);
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const int64_t rn_val = get_register(rn, instr->RnMode());
  const int64_t rm_val = DecodeShiftExtendOperand(instr);
  int64_t alu_out = 0;
  switch (op) {
    case 0:
      // Format(instr, "and'sf 'rd, 'rn, 'shift_op");
      alu_out = rn_val & rm_val;
      break;
    case 1:
      // Format(instr, "bic'sf 'rd, 'rn, 'shift_op");
      alu_out = rn_val & (~rm_val);
      break;
    case 2:
      // Format(instr, "orr'sf 'rd, 'rn, 'shift_op");
      alu_out = rn_val | rm_val;
      break;
    case 3:
      // Format(instr, "orn'sf 'rd, 'rn, 'shift_op");
      alu_out = rn_val | (~rm_val);
      break;
    case 4:
      // Format(instr, "eor'sf 'rd, 'rn, 'shift_op");
      alu_out = rn_val ^ rm_val;
      break;
    case 5:
      // Format(instr, "eon'sf 'rd, 'rn, 'shift_op");
      alu_out = rn_val ^ (~rm_val);
      break;
    case 6:
      // Format(instr, "and'sfs 'rd, 'rn, 'shift_op");
      alu_out = rn_val & rm_val;
      break;
    case 7:
      // Format(instr, "bic'sfs 'rd, 'rn, 'shift_op");
      alu_out = rn_val & (~rm_val);
      break;
    default:
      UNREACHABLE();
      break;
  }

  // Set flags if ands or bics.
  if ((op == 6) || (op == 7)) {
    if (instr->SFField() == 1) {
      SetNZFlagsX(alu_out);
    } else {
      SetNZFlagsW(alu_out);
    }
    SetCFlag(false);
    SetVFlag(false);
  }

  if (instr->SFField() == 1) {
    set_register(rd, alu_out, instr->RdMode());
  } else {
    set_wregister(rd, alu_out & kWRegMask, instr->RdMode());
  }
}


static int64_t divide64(int64_t top, int64_t bottom, bool signd) {
  // ARM64 does not trap on integer division by zero. The destination register
  // is instead set to 0.
  if (bottom == 0) {
    return 0;
  }

  if (signd) {
    // INT_MIN / -1 = INT_MIN.
    if ((top == static_cast<int64_t>(0x8000000000000000LL)) &&
        (bottom == static_cast<int64_t>(0xffffffffffffffffLL))) {
      return static_cast<int64_t>(0x8000000000000000LL);
    } else {
      return top / bottom;
    }
  } else {
    const uint64_t utop = static_cast<uint64_t>(top);
    const uint64_t ubottom = static_cast<uint64_t>(bottom);
    return static_cast<int64_t>(utop / ubottom);
  }
}


static int32_t divide32(int32_t top, int32_t bottom, bool signd) {
  // ARM64 does not trap on integer division by zero. The destination register
  // is instead set to 0.
  if (bottom == 0) {
    return 0;
  }

  if (signd) {
    // INT_MIN / -1 = INT_MIN.
    if ((top == static_cast<int32_t>(0x80000000)) &&
        (bottom == static_cast<int32_t>(0xffffffff))) {
      return static_cast<int32_t>(0x80000000);
    } else {
      return top / bottom;
    }
  } else {
    const uint32_t utop = static_cast<uint32_t>(top);
    const uint32_t ubottom = static_cast<uint32_t>(bottom);
    return static_cast<int32_t>(utop / ubottom);
  }
}


void Simulator::DecodeMiscDP2Source(Instr* instr) {
  if (instr->Bit(29) != 0) {
    UnimplementedInstruction(instr);
  }

  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const Register rm = instr->RmField();
  const int op = instr->Bits(10, 6);
  const int64_t rn_val64 = get_register(rn, R31IsZR);
  const int64_t rm_val64 = get_register(rm, R31IsZR);
  const int32_t rn_val32 = get_wregister(rn, R31IsZR);
  const int32_t rm_val32 = get_wregister(rm, R31IsZR);
  switch (op) {
    case 2:
    case 3: {
      // Format(instr, "udiv'sf 'rd, 'rn, 'rm");
      // Format(instr, "sdiv'sf 'rd, 'rn, 'rm");
      const bool signd = instr->Bit(10) == 1;
      if (instr->SFField() == 1) {
        set_register(rd, divide64(rn_val64, rm_val64, signd), R31IsZR);
      } else {
        set_wregister(rd, divide32(rn_val32, rm_val32, signd), R31IsZR);
      }
      break;
    }
    case 8: {
      // Format(instr, "lsl'sf 'rd, 'rn, 'rm");
      if (instr->SFField() == 1) {
        const int64_t alu_out = rn_val64 << (rm_val64 & (kXRegSizeInBits - 1));
        set_register(rd, alu_out, R31IsZR);
      } else {
        const int32_t alu_out = rn_val32 << (rm_val32 & (kXRegSizeInBits - 1));
        set_wregister(rd, alu_out, R31IsZR);
      }
      break;
    }
    case 9: {
      // Format(instr, "lsr'sf 'rd, 'rn, 'rm");
      if (instr->SFField() == 1) {
        const uint64_t rn_u64 = static_cast<uint64_t>(rn_val64);
        const int64_t alu_out = rn_u64 >> (rm_val64 & (kXRegSizeInBits - 1));
        set_register(rd, alu_out, R31IsZR);
      } else {
        const uint32_t rn_u32 = static_cast<uint32_t>(rn_val32);
        const int32_t alu_out = rn_u32 >> (rm_val32 & (kXRegSizeInBits - 1));
        set_wregister(rd, alu_out, R31IsZR);
      }
      break;
    }
    case 10: {
      // Format(instr, "asr'sf 'rd, 'rn, 'rm");
      if (instr->SFField() == 1) {
        const int64_t alu_out = rn_val64 >> (rm_val64 & (kXRegSizeInBits - 1));
        set_register(rd, alu_out, R31IsZR);
      } else {
        const int32_t alu_out = rn_val32 >> (rm_val32 & (kXRegSizeInBits - 1));
        set_wregister(rd, alu_out, R31IsZR);
      }
      break;
    }
    default:
      UnimplementedInstruction(instr);
      break;
  }
}


void Simulator::DecodeMiscDP3Source(Instr* instr) {
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const Register rm = instr->RmField();
  const Register ra = instr->RaField();
  if ((instr->Bits(29, 2) == 0) && (instr->Bits(21, 3) == 0) &&
      (instr->Bit(15) == 0)) {
    // Format(instr, "madd'sf 'rd, 'rn, 'rm, 'ra");
    if (instr->SFField() == 1) {
      const int64_t rn_val = get_register(rn, R31IsZR);
      const int64_t rm_val = get_register(rm, R31IsZR);
      const int64_t ra_val = get_register(ra, R31IsZR);
      const int64_t alu_out = ra_val + (rn_val * rm_val);
      set_register(rd, alu_out, R31IsZR);
    } else {
      const int32_t rn_val = get_wregister(rn, R31IsZR);
      const int32_t rm_val = get_wregister(rm, R31IsZR);
      const int32_t ra_val = get_wregister(ra, R31IsZR);
      const int32_t alu_out = ra_val + (rn_val * rm_val);
      set_wregister(rd, alu_out, R31IsZR);
    }
  } else if ((instr->Bits(29, 2) == 0) && (instr->Bits(21, 3) == 0) &&
             (instr->Bit(15) == 1)) {
    // Format(instr, "msub'sf 'rd, 'rn, 'rm, 'ra");
    if (instr->SFField() == 1) {
      const int64_t rn_val = get_register(rn, R31IsZR);
      const int64_t rm_val = get_register(rm, R31IsZR);
      const int64_t ra_val = get_register(ra, R31IsZR);
      const int64_t alu_out = ra_val - (rn_val * rm_val);
      set_register(rd, alu_out, R31IsZR);
    } else {
      const int32_t rn_val = get_wregister(rn, R31IsZR);
      const int32_t rm_val = get_wregister(rm, R31IsZR);
      const int32_t ra_val = get_wregister(ra, R31IsZR);
      const int32_t alu_out = ra_val - (rn_val * rm_val);
      set_wregister(rd, alu_out, R31IsZR);
    }
  } else if ((instr->Bits(29, 2) == 0) && (instr->Bits(21, 3) == 2) &&
             (instr->Bit(15) == 0)) {
    // Format(instr, "smulh 'rd, 'rn, 'rm");
    const int64_t rn_val = get_register(rn, R31IsZR);
    const int64_t rm_val = get_register(rm, R31IsZR);
    const __int128 res =
        static_cast<__int128>(rn_val) * static_cast<__int128>(rm_val);
    const int64_t alu_out = static_cast<int64_t>(res >> 64);
    set_register(rd, alu_out, R31IsZR);
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeConditionalSelect(Instr* instr) {
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const Register rm = instr->RmField();
  const int64_t rm_val64 = get_register(rm, R31IsZR);
  const int32_t rm_val32 = get_wregister(rm, R31IsZR);
  const int64_t rn_val64 = get_register(rn, instr->RnMode());
  const int32_t rn_val32 = get_wregister(rn, instr->RnMode());
  int64_t result64 = 0;
  int32_t result32 = 0;

  if ((instr->Bits(29, 2) == 0) && (instr->Bits(10, 2) == 0)) {
    // Format(instr, "mov'sf'cond 'rd, 'rn, 'rm");
    result64 = rm_val64;
    result32 = rm_val32;
    if (ConditionallyExecute(instr)) {
      result64 = rn_val64;
      result32 = rn_val32;
    }
  } else if ((instr->Bits(29, 2) == 0) && (instr->Bits(10, 2) == 1)) {
    // Format(instr, "csinc'sf'cond 'rd, 'rn, 'rm");
    result64 = rm_val64 + 1;
    result32 = rm_val32 + 1;
    if (ConditionallyExecute(instr)) {
      result64 = rn_val64;
      result32 = rn_val32;
    }
  } else {
    UnimplementedInstruction(instr);
    return;
  }

  if (instr->SFField() == 1) {
    set_register(rd, result64, instr->RdMode());
  } else {
    set_wregister(rd, result32, instr->RdMode());
  }
}


void Simulator::DecodeDPRegister(Instr* instr) {
  if (instr->IsAddSubShiftExtOp()) {
    DecodeAddSubShiftExt(instr);
  } else if (instr->IsLogicalShiftOp()) {
    DecodeLogicalShift(instr);
  } else if (instr->IsMiscDP2SourceOp()) {
    DecodeMiscDP2Source(instr);
  } else if (instr->IsMiscDP3SourceOp()) {
    DecodeMiscDP3Source(instr);
  } else if (instr->IsConditionalSelectOp()) {
    DecodeConditionalSelect(instr);
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeDPSimd1(Instr* instr) {
  UnimplementedInstruction(instr);
}


void Simulator::DecodeFPImm(Instr* instr) {
  if ((instr->Bit(31) != 0) || (instr->Bit(29) != 0) || (instr->Bit(23) != 0) ||
      (instr->Bits(5, 5) != 0)) {
    UnimplementedInstruction(instr);
    return;
  }
  if (instr->Bit(22) == 1) {
    // Double.
    // Format(instr, "fmovd 'vd, #'immd");
    const VRegister vd = instr->VdField();
    const int64_t immd = Instr::VFPExpandImm(instr->Imm8Field());
    set_vregisterd(vd, immd);
  } else {
    // Single.
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeFPIntCvt(Instr* instr) {
  const VRegister vd = instr->VdField();
  const VRegister vn = instr->VnField();
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();

  if ((instr->SFField() != 1) || (instr->Bit(29) != 0) ||
      (instr->Bits(22, 2) != 1)) {
    UnimplementedInstruction(instr);
    return;
  }
  if (instr->Bits(16, 5) == 2) {
    // Format(instr, "scvtfd 'vd, 'vn");
    const int64_t rn_val = get_register(rn, instr->RnMode());
    const double vn_dbl = static_cast<double>(rn_val);
    set_vregisterd(vd, bit_cast<int64_t, double>(vn_dbl));
  } else if (instr->Bits(16, 5) == 6) {
    // Format(instr, "fmovrd 'rd, 'vn");
    const int64_t vn_val = get_vregisterd(vn);
    set_register(rd, vn_val, R31IsZR);
  } else if (instr->Bits(16, 5) == 7) {
    // Format(instr, "fmovdr 'vd, 'rn");
    const int64_t rn_val = get_register(rn, R31IsZR);
    set_vregisterd(vd, rn_val);
  } else if (instr->Bits(16, 5) == 24) {
    // Format(instr, "fcvtzds 'rd, 'vn");
    const double vn_val = bit_cast<double, int64_t>(get_vregisterd(vn));
    set_register(rd, static_cast<int64_t>(vn_val), instr->RdMode());
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeFPOneSource(Instr* instr) {
  const int opc = instr->Bits(15, 2);
  const VRegister vd = instr->VdField();
  const VRegister vn = instr->VnField();
  const int64_t vn_val = get_vregisterd(vn);
  const double vn_dbl = bit_cast<double, int64_t>(vn_val);

  int64_t res_val = 0;
  switch (opc) {
    case 0:
      // Format("fmovdd 'vd, 'vn");
      res_val = get_vregisterd(vn);
      break;
    case 1:
      // Format("fabsd 'vd, 'vn");
      res_val = bit_cast<int64_t, double>(fabs(vn_dbl));
      break;
    case 2:
      // Format("fnegd 'vd, 'vn");
      res_val = bit_cast<int64_t, double>(-vn_dbl);
      break;
    case 3:
      // Format("fsqrtd 'vd, 'vn");
      res_val = bit_cast<int64_t, double>(sqrt(vn_dbl));
      break;
    default:
      UNREACHABLE();
      break;
  }

  set_vregisterd(vd, res_val);
}


void Simulator::DecodeFPTwoSource(Instr* instr) {
  if (instr->Bits(22, 2) != 1) {
    UnimplementedInstruction(instr);
    return;
  }
  const VRegister vd = instr->VdField();
  const VRegister vn = instr->VnField();
  const VRegister vm = instr->VmField();
  const double vn_val = bit_cast<double, int64_t>(get_vregisterd(vn));
  const double vm_val = bit_cast<double, int64_t>(get_vregisterd(vm));
  const int opc = instr->Bits(12, 4);
  double result;

  switch (opc) {
    case 0:
      // Format(instr, "fmuld 'vd, 'vn, 'vm");
      result = vn_val * vm_val;
      break;
    case 1:
      // Format(instr, "fdivd 'vd, 'vn, 'vm");
      result = vn_val / vm_val;
      break;
    case 2:
      // Format(instr, "faddd 'vd, 'vn, 'vm");
      result = vn_val + vm_val;
      break;
    case 3:
      // Format(instr, "fsubd 'vd, 'vn, 'vm");
      result = vn_val - vm_val;
      break;
    default:
      // Unknown(instr);
      break;
  }

  set_vregisterd(vd, bit_cast<int64_t, double>(result));
}


void Simulator::DecodeFPCompare(Instr* instr) {
  const VRegister vn = instr->VnField();
  const VRegister vm = instr->VmField();
  const double vn_val = get_vregisterd(vn);
  double vm_val;

  if ((instr->Bit(22) == 1) && (instr->Bits(3, 2) == 0)) {
    // Format(instr, "fcmpd 'vn, 'vm");
    vm_val = get_vregisterd(vm);
  } else if ((instr->Bit(22) == 1) && (instr->Bits(3, 2) == 1)) {
    if (instr->VmField() == V0) {
      // Format(instr, "fcmpd 'vn, #0.0");
      vm_val = 0.0;
    } else {
      UnimplementedInstruction(instr);
      return;
    }
  } else {
    UnimplementedInstruction(instr);
    return;
  }

  n_flag_ = false;
  z_flag_ = false;
  c_flag_ = false;
  v_flag_ = false;

  if (isnan(vn_val) || isnan(vm_val)) {
    c_flag_ = true;
    v_flag_ = true;
  } else if (vn_val == vm_val) {
    z_flag_ = true;
    c_flag_ = true;
  } else if (vn_val < vm_val) {
    n_flag_ = true;
  } else {
    c_flag_ = true;
  }
}


void Simulator::DecodeFP(Instr* instr) {
  if (instr->IsFPImmOp()) {
    DecodeFPImm(instr);
  } else if (instr->IsFPIntCvtOp()) {
    DecodeFPIntCvt(instr);
  } else if (instr->IsFPOneSourceOp()) {
    DecodeFPOneSource(instr);
  } else if (instr->IsFPTwoSourceOp()) {
    DecodeFPTwoSource(instr);
  } else if (instr->IsFPCompareOp()) {
    DecodeFPCompare(instr);
  } else {
    UnimplementedInstruction(instr);
  }
}


void Simulator::DecodeDPSimd2(Instr* instr) {
  if (instr->IsFPOp()) {
    DecodeFP(instr);
  } else {
    UnimplementedInstruction(instr);
  }
}


// Executes the current instruction.
void Simulator::InstructionDecode(Instr* instr) {
  pc_modified_ = false;
  if (FLAG_trace_sim) {
    const uword start = reinterpret_cast<uword>(instr);
    const uword end = start + Instr::kInstrSize;
    Disassembler::Disassemble(start, end);
  }

  if (instr->IsDPImmediateOp()) {
    DecodeDPImmediate(instr);
  } else if (instr->IsCompareBranchOp()) {
    DecodeCompareBranch(instr);
  } else if (instr->IsLoadStoreOp()) {
    DecodeLoadStore(instr);
  } else if (instr->IsDPRegisterOp()) {
    DecodeDPRegister(instr);
  } else if (instr->IsDPSimd1Op()) {
    DecodeDPSimd1(instr);
  } else if (instr->IsDPSimd2Op()) {
    DecodeDPSimd2(instr);
  } else {
    UnimplementedInstruction(instr);
  }

  if (!pc_modified_) {
    set_pc(reinterpret_cast<int64_t>(instr) + Instr::kInstrSize);
  }
}


void Simulator::Execute() {
  // Get the PC to simulate. Cannot use the accessor here as we need the
  // raw PC value and not the one used as input to arithmetic instructions.
  uword program_counter = get_pc();

  if (FLAG_stop_sim_at == 0) {
    // Fast version of the dispatch loop without checking whether the simulator
    // should be stopping at a particular executed instruction.
    while (program_counter != kEndSimulatingPC) {
      Instr* instr = reinterpret_cast<Instr*>(program_counter);
      icount_++;
      if (IsIllegalAddress(program_counter)) {
        HandleIllegalAccess(program_counter, instr);
      } else {
        InstructionDecode(instr);
      }
      program_counter = get_pc();
    }
  } else {
    // FLAG_stop_sim_at is at the non-default value. Stop in the debugger when
    // we reach the particular instruction count.
    while (program_counter != kEndSimulatingPC) {
      Instr* instr = reinterpret_cast<Instr*>(program_counter);
      icount_++;
      if (icount_ == FLAG_stop_sim_at) {
        // TODO(zra): Add a debugger.
        UNIMPLEMENTED();
      } else if (IsIllegalAddress(program_counter)) {
        HandleIllegalAccess(program_counter, instr);
      } else {
        InstructionDecode(instr);
      }
      program_counter = get_pc();
    }
  }
}


int64_t Simulator::Call(int64_t entry,
                        int64_t parameter0,
                        int64_t parameter1,
                        int64_t parameter2,
                        int64_t parameter3,
                        bool fp_return,
                        bool fp_args) {
  // Save the SP register before the call so we can restore it.
  intptr_t sp_before_call = get_register(R31, R31IsSP);

  // Setup parameters.
  if (fp_args) {
    set_vregisterd(V0, parameter0);
    set_vregisterd(V1, parameter1);
    set_vregisterd(V2, parameter2);
    set_vregisterd(V3, parameter3);
  } else {
    set_register(R0, parameter0);
    set_register(R1, parameter1);
    set_register(R2, parameter2);
    set_register(R3, parameter3);
  }

  // Make sure the activation frames are properly aligned.
  intptr_t stack_pointer = sp_before_call;
  if (OS::ActivationFrameAlignment() > 1) {
    stack_pointer =
        Utils::RoundDown(stack_pointer, OS::ActivationFrameAlignment());
  }
  set_register(R31, stack_pointer, R31IsSP);

  // Prepare to execute the code at entry.
  set_pc(entry);
  // Put down marker for end of simulation. The simulator will stop simulation
  // when the PC reaches this value. By saving the "end simulation" value into
  // the LR the simulation stops when returning to this call point.
  set_register(LR, kEndSimulatingPC);

  // Remember the values of callee-saved registers, and set them up with a
  // known value so that we are able to check that they are preserved
  // properly across Dart execution.
  int64_t preserved_vals[kAbiPreservedCpuRegCount];
  int64_t callee_saved_value = icount_;
  for (int i = kAbiFirstPreservedCpuReg; i <= kAbiLastPreservedCpuReg; i++) {
    const Register r = static_cast<Register>(i);
    preserved_vals[i - kAbiFirstPreservedCpuReg] = get_register(r);
    set_register(r, callee_saved_value);
  }

  // Only the bottom half of the V registers must be preserved.
  int64_t preserved_dvals[kAbiPreservedFpuRegCount];
  for (int i = kAbiFirstPreservedFpuReg; i <= kAbiLastPreservedFpuReg; i++) {
    const VRegister r = static_cast<VRegister>(i);
    preserved_dvals[i - kAbiFirstPreservedFpuReg] = get_vregisterd(r);
    set_vregisterd(r, callee_saved_value);
  }

  // Start the simulation
  Execute();

  // Check that the callee-saved registers have been preserved,
  // and restore them with the original value
  for (int i = kAbiFirstPreservedCpuReg; i <= kAbiLastPreservedCpuReg; i++) {
    const Register r = static_cast<Register>(i);
    ASSERT(callee_saved_value == get_register(r));
    set_register(r, preserved_vals[i - kAbiFirstPreservedCpuReg]);
  }

  for (int i = kAbiFirstPreservedFpuReg; i <= kAbiLastPreservedFpuReg; i++) {
    const VRegister r = static_cast<VRegister>(i);
    ASSERT(callee_saved_value == get_vregisterd(r));
    set_vregisterd(r, preserved_dvals[i - kAbiFirstPreservedFpuReg]);
  }

  // Restore the SP register and return R0.
  set_register(R31, sp_before_call, R31IsSP);
  int64_t return_value;
  if (fp_return) {
    return_value = get_vregisterd(V0);
  } else {
    return_value = get_register(R0);
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
  set_pc(static_cast<int64_t>(pc));
  set_register(R31, static_cast<int64_t>(sp), R31IsSP);
  set_register(FP, static_cast<int64_t>(fp));

  ASSERT(raw_exception != Object::null());
  set_register(kExceptionObjectReg, bit_cast<int64_t>(raw_exception));
  set_register(kStackTraceObjectReg, bit_cast<int64_t>(raw_stacktrace));
  buf->Longjmp();
}

}  // namespace dart

#endif  // !defined(HOST_ARCH_ARM64)

#endif  // defined TARGET_ARCH_ARM64
