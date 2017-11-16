// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <setjmp.h>  // NOLINT
#include <stdlib.h>

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

// Only build the simulator if not compiling for real ARM hardware.
#if defined(USING_SIMULATOR)

#include "vm/simulator.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/constants_arm64.h"
#include "vm/native_arguments.h"
#include "vm/os_thread.h"
#include "vm/stack_frame.h"

namespace dart {

DEFINE_FLAG(uint64_t,
            trace_sim_after,
            ULLONG_MAX,
            "Trace simulator execution after instruction count reached.");
DEFINE_FLAG(uint64_t,
            stop_sim_at,
            ULLONG_MAX,
            "Instruction address or instruction count to stop simulator at.");

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
  }

  ~SimulatorSetjmpBuffer() {
    ASSERT(simulator_->last_setjmp_buffer() == this);
    simulator_->set_last_setjmp_buffer(link_);
  }

  SimulatorSetjmpBuffer* link() { return link_; }

  uword sp() { return sp_; }

 private:
  uword sp_;
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

  bool GetValue(char* desc, uint64_t* value);
  bool GetSValue(char* desc, uint32_t* value);
  bool GetDValue(char* desc, uint64_t* value);
  bool GetQValue(char* desc, simd_value_t* value);

  static TokenPosition GetApproximateTokenIndex(const Code& code, uword pc);

  static void PrintDartFrame(uword pc,
                             uword fp,
                             uword sp,
                             const Function& function,
                             TokenPosition token_pos,
                             bool is_optimized,
                             bool is_inlined);
  void PrintBacktrace();

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

SimulatorDebugger::~SimulatorDebugger() {}

void SimulatorDebugger::Stop(Instr* instr, const char* message) {
  OS::Print("Simulator hit %s\n", message);
  Debug();
}

static Register LookupCpuRegisterByName(const char* name) {
  static const char* kNames[] = {
      "r0",  "r1",  "r2",  "r3",  "r4",  "r5",  "r6",  "r7",
      "r8",  "r9",  "r10", "r11", "r12", "r13", "r14", "r15",
      "r16", "r17", "r18", "r19", "r20", "r21", "r22", "r23",
      "r24", "r25", "r26", "r27", "r28", "r29", "r30",

      "ip0", "ip1", "pp",  "ctx", "fp",  "lr",  "sp",  "zr",
  };
  static const Register kRegisters[] = {
      R0,  R1,  R2,  R3,  R4,  R5,  R6,  R7,  R8,  R9,  R10,
      R11, R12, R13, R14, R15, R16, R17, R18, R19, R20, R21,
      R22, R23, R24, R25, R26, R27, R28, R29, R30,

      IP0, IP1, PP,  CTX, FP,  LR,  R31, ZR,
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

bool SimulatorDebugger::GetValue(char* desc, uint64_t* value) {
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
    uint64_t addr;
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
  bool retval = SScanF(desc, "0x%" Px64, value) == 1;
  if (!retval) {
    retval = SScanF(desc, "%" Px64, value) == 1;
  }
  return retval;
}

bool SimulatorDebugger::GetSValue(char* desc, uint32_t* value) {
  VRegister vreg = LookupVRegisterByName(desc);
  if (vreg != kNoVRegister) {
    *value = sim_->get_vregisters(vreg, 0);
    return true;
  }
  if (desc[0] == '*') {
    uint64_t addr;
    if (GetValue(desc + 1, &addr)) {
      if (Simulator::IsIllegalAddress(addr)) {
        return false;
      }
      *value = *(reinterpret_cast<uint32_t*>(addr));
      return true;
    }
  }
  return false;
}

bool SimulatorDebugger::GetDValue(char* desc, uint64_t* value) {
  VRegister vreg = LookupVRegisterByName(desc);
  if (vreg != kNoVRegister) {
    *value = sim_->get_vregisterd(vreg, 0);
    return true;
  }
  if (desc[0] == '*') {
    uint64_t addr;
    if (GetValue(desc + 1, &addr)) {
      if (Simulator::IsIllegalAddress(addr)) {
        return false;
      }
      *value = *(reinterpret_cast<uint64_t*>(addr));
      return true;
    }
  }
  return false;
}

bool SimulatorDebugger::GetQValue(char* desc, simd_value_t* value) {
  VRegister vreg = LookupVRegisterByName(desc);
  if (vreg != kNoVRegister) {
    sim_->get_vregister(vreg, value);
    return true;
  }
  if (desc[0] == '*') {
    uint64_t addr;
    if (GetValue(desc + 1, &addr)) {
      if (Simulator::IsIllegalAddress(addr)) {
        return false;
      }
      *value = *(reinterpret_cast<simd_value_t*>(addr));
      return true;
    }
  }
  return false;
}

TokenPosition SimulatorDebugger::GetApproximateTokenIndex(const Code& code,
                                                          uword pc) {
  TokenPosition token_pos = TokenPosition::kNoSource;
  uword pc_offset = pc - code.PayloadStart();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kAnyKind);
  while (iter.MoveNext()) {
    if (iter.PcOffset() == pc_offset) {
      return iter.TokenPos();
    } else if (!token_pos.IsReal() && (iter.PcOffset() > pc_offset)) {
      token_pos = iter.TokenPos();
    }
  }
  return token_pos;
}

void SimulatorDebugger::PrintDartFrame(uword pc,
                                       uword fp,
                                       uword sp,
                                       const Function& function,
                                       TokenPosition token_pos,
                                       bool is_optimized,
                                       bool is_inlined) {
  const Script& script = Script::Handle(function.script());
  const String& func_name = String::Handle(function.QualifiedScrubbedName());
  const String& url = String::Handle(script.url());
  intptr_t line = -1;
  intptr_t column = -1;
  if (token_pos.IsReal()) {
    script.GetTokenLocation(token_pos, &line, &column);
  }
  OS::Print(
      "pc=0x%" Px " fp=0x%" Px " sp=0x%" Px " %s%s (%s:%" Pd ":%" Pd ")\n", pc,
      fp, sp, is_optimized ? (is_inlined ? "inlined " : "optimized ") : "",
      func_name.ToCString(), url.ToCString(), line, column);
}

void SimulatorDebugger::PrintBacktrace() {
  StackFrameIterator frames(
      sim_->get_register(FP), sim_->get_register(SP), sim_->get_pc(),
      StackFrameIterator::kDontValidateFrames, Thread::Current(),
      StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);
  Function& function = Function::Handle();
  Function& inlined_function = Function::Handle();
  Code& code = Code::Handle();
  Code& unoptimized_code = Code::Handle();
  while (frame != NULL) {
    if (frame->IsDartFrame()) {
      code = frame->LookupDartCode();
      function = code.function();
      if (code.is_optimized()) {
        // For optimized frames, extract all the inlined functions if any
        // into the stack trace.
        InlinedFunctionsIterator it(code, frame->pc());
        while (!it.Done()) {
          // Print each inlined frame with its pc in the corresponding
          // unoptimized frame.
          inlined_function = it.function();
          unoptimized_code = it.code();
          uword unoptimized_pc = it.pc();
          it.Advance();
          if (!it.Done()) {
            PrintDartFrame(
                unoptimized_pc, frame->fp(), frame->sp(), inlined_function,
                GetApproximateTokenIndex(unoptimized_code, unoptimized_pc),
                true, true);
          }
        }
        // Print the optimized inlining frame below.
      }
      PrintDartFrame(frame->pc(), frame->fp(), frame->sp(), function,
                     GetApproximateTokenIndex(code, frame->pc()),
                     code.is_optimized(), false);
    } else {
      OS::Print("pc=0x%" Px " fp=0x%" Px " sp=0x%" Px " %s frame\n",
                frame->pc(), frame->fp(), frame->sp(),
                frame->IsEntryFrame()
                    ? "entry"
                    : frame->IsExitFrame()
                          ? "exit"
                          : frame->IsStubFrame() ? "stub" : "invalid");
    }
    frame = frames.NextFrame();
  }
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
    sim_->break_pc_->SetInstructionBits(Instr::kSimulatorBreakpointInstruction);
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
        if (FLAG_support_disassembler) {
          Disassembler::Disassemble(last_pc, last_pc + Instr::kInstrSize);
        } else {
          OS::Print("Disassembler not supported in this mode.\n");
        }
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
        OS::Print(
            "c/cont -- continue execution\n"
            "disasm -- disassemble instrs at current pc location\n"
            "  other variants are:\n"
            "    disasm <address>\n"
            "    disasm <address> <number_of_instructions>\n"
            "  by default 10 instrs are disassembled\n"
            "del -- delete breakpoints\n"
            "flags -- print flag values\n"
            "gdb -- transfer control to gdb\n"
            "h/help -- print this help string\n"
            "break <address> -- set break point at specified address\n"
            "p/print <reg or icount or value or *addr> -- print integer\n"
            "pf/printfloat <vreg or *addr> --print float value\n"
            "pd/printdouble <vreg or *addr> -- print double value\n"
            "pq/printquad <vreg or *addr> -- print vector register\n"
            "po/printobject <*reg or *addr> -- print object\n"
            "si/stepi -- single step an instruction\n"
            "trace -- toggle execution tracing mode\n"
            "bt -- print backtrace\n"
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
          uint64_t value;
          if (strcmp(arg1, "icount") == 0) {
            value = sim_->get_icount();
            OS::Print("icount: %" Pu64 " 0x%" Px64 "\n", value, value);
          } else if (GetValue(arg1, &value)) {
            OS::Print("%s: %" Pu64 " 0x%" Px64 "\n", arg1, value, value);
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("print <reg or icount or value or *addr>\n");
        }
      } else if ((strcmp(cmd, "pf") == 0) || (strcmp(cmd, "printfloat") == 0)) {
        if (args == 2) {
          uint32_t value;
          if (GetSValue(arg1, &value)) {
            float svalue = bit_cast<float, uint32_t>(value);
            OS::Print("%s: %d 0x%x %.8g\n", arg1, value, value, svalue);
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("printfloat <vreg or *addr>\n");
        }
      } else if ((strcmp(cmd, "pd") == 0) ||
                 (strcmp(cmd, "printdouble") == 0)) {
        if (args == 2) {
          uint64_t long_value;
          if (GetDValue(arg1, &long_value)) {
            double dvalue = bit_cast<double, uint64_t>(long_value);
            OS::Print("%s: %" Pu64 " 0x%" Px64 " %.8g\n", arg1, long_value,
                      long_value, dvalue);
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("printdouble <vreg or *addr>\n");
        }
      } else if ((strcmp(cmd, "pq") == 0) || (strcmp(cmd, "printquad") == 0)) {
        if (args == 2) {
          simd_value_t quad_value;
          if (GetQValue(arg1, &quad_value)) {
            const int64_t d0 = quad_value.bits.i64[0];
            const int64_t d1 = quad_value.bits.i64[1];
            const double dval0 = bit_cast<double, int64_t>(d0);
            const double dval1 = bit_cast<double, int64_t>(d1);
            const int32_t s0 = quad_value.bits.i32[0];
            const int32_t s1 = quad_value.bits.i32[1];
            const int32_t s2 = quad_value.bits.i32[2];
            const int32_t s3 = quad_value.bits.i32[3];
            const float sval0 = bit_cast<float, int32_t>(s0);
            const float sval1 = bit_cast<float, int32_t>(s1);
            const float sval2 = bit_cast<float, int32_t>(s2);
            const float sval3 = bit_cast<float, int32_t>(s3);
            OS::Print("%s: %" Pu64 " 0x%" Px64 " %.8g\n", arg1, d0, d0, dval0);
            OS::Print("%s: %" Pu64 " 0x%" Px64 " %.8g\n", arg1, d1, d1, dval1);
            OS::Print("%s: %d 0x%x %.8g\n", arg1, s0, s0, sval0);
            OS::Print("%s: %d 0x%x %.8g\n", arg1, s1, s1, sval1);
            OS::Print("%s: %d 0x%x %.8g\n", arg1, s2, s2, sval2);
            OS::Print("%s: %d 0x%x %.8g\n", arg1, s3, s3, sval3);
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("printquad <vreg or *addr>\n");
        }
      } else if ((strcmp(cmd, "po") == 0) ||
                 (strcmp(cmd, "printobject") == 0)) {
        if (args == 2) {
          uint64_t value;
          // Make the dereferencing '*' optional.
          if (((arg1[0] == '*') && GetValue(arg1 + 1, &value)) ||
              GetValue(arg1, &value)) {
            if (Isolate::Current()->heap()->Contains(value)) {
              OS::Print("%s: \n", arg1);
#if defined(DEBUG)
              const Object& obj =
                  Object::Handle(reinterpret_cast<RawObject*>(value));
              obj.Print();
#endif  // defined(DEBUG)
            } else {
              OS::Print("0x%" Px64 " is not an object reference\n", value);
            }
          } else {
            OS::Print("%s unrecognized\n", arg1);
          }
        } else {
          OS::Print("printobject <*reg or *addr>\n");
        }
      } else if (strcmp(cmd, "disasm") == 0) {
        uint64_t start = 0;
        uint64_t end = 0;
        if (args == 1) {
          start = sim_->get_pc();
          end = start + (10 * Instr::kInstrSize);
        } else if (args == 2) {
          if (GetValue(arg1, &start)) {
            // No length parameter passed, assume 10 instructions.
            if (Simulator::IsIllegalAddress(start)) {
              // If start isn't a valid address, warn and use PC instead.
              OS::Print("First argument yields invalid address: 0x%" Px64 "\n",
                        start);
              OS::Print("Using PC instead\n");
              start = sim_->get_pc();
            }
            end = start + (10 * Instr::kInstrSize);
          }
        } else {
          uint64_t length;
          if (GetValue(arg1, &start) && GetValue(arg2, &length)) {
            if (Simulator::IsIllegalAddress(start)) {
              // If start isn't a valid address, warn and use PC instead.
              OS::Print("First argument yields invalid address: 0x%" Px64 "\n",
                        start);
              OS::Print("Using PC instead\n");
              start = sim_->get_pc();
            }
            end = start + (length * Instr::kInstrSize);
          }
        }
        if ((start > 0) && (end > start)) {
          if (FLAG_support_disassembler) {
            Disassembler::Disassemble(start, end);
          } else {
            OS::Print("Disassembler not supported in this mode.\n");
          }
        } else {
          OS::Print("disasm [<address> [<number_of_instructions>]]\n");
        }
      } else if (strcmp(cmd, "gdb") == 0) {
        OS::Print("relinquishing control to gdb\n");
        OS::DebugBreak();
        OS::Print("regaining control from gdb\n");
      } else if (strcmp(cmd, "break") == 0) {
        if (args == 2) {
          uint64_t addr;
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
      } else if (strcmp(cmd, "flags") == 0) {
        OS::Print("APSR: ");
        OS::Print("N flag: %d; ", sim_->n_flag_);
        OS::Print("Z flag: %d; ", sim_->z_flag_);
        OS::Print("C flag: %d; ", sim_->c_flag_);
        OS::Print("V flag: %d\n", sim_->v_flag_);
      } else if (strcmp(cmd, "unstop") == 0) {
        intptr_t stop_pc = sim_->get_pc() - Instr::kInstrSize;
        Instr* stop_instr = reinterpret_cast<Instr*>(stop_pc);
        if (stop_instr->IsExceptionGenOp()) {
          stop_instr->SetInstructionBits(Instr::kNopInstruction);
        } else {
          OS::Print("Not at debugger stop.\n");
        }
      } else if (strcmp(cmd, "trace") == 0) {
        if (FLAG_trace_sim_after == ULLONG_MAX) {
          FLAG_trace_sim_after = sim_->get_icount();
          OS::Print("execution tracing on\n");
        } else {
          FLAG_trace_sim_after = ULLONG_MAX;
          OS::Print("execution tracing off\n");
        }
      } else if (strcmp(cmd, "bt") == 0) {
        PrintBacktrace();
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
    if (len > 1 && line_buf[len - 2] == '\\' && line_buf[len - 1] == '\n') {
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

Simulator::Simulator() : exclusive_access_addr_(0), exclusive_access_value_(0) {
  // Setup simulator support first. Some of this information is needed to
  // setup the architecture state.
  // We allocate the stack here, the size is computed as the sum of
  // the size specified by the user and the buffer space needed for
  // handling stack overflow exceptions. To be safe in potential
  // stack underflows we also add some underflow buffer space.
  stack_ =
      new char[(OSThread::GetSpecifiedStackSize() + OSThread::kStackSizeBuffer +
                kSimulatorStackUnderflowSize)];
  // Low address.
  stack_limit_ = reinterpret_cast<uword>(stack_) + OSThread::kStackSizeBuffer;
  // High address.
  stack_base_ = stack_limit_ + OSThread::GetSpecifiedStackSize();

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
    vregisters_[i].bits.i64[0] = 0;
    vregisters_[i].bits.i64[1] = 0;
  }

  // The sp is initialized to point to the bottom (high address) of the
  // allocated stack area.
  registers_[R31] = stack_base();
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

  static uword FunctionForRedirect(uword address_of_hlt) {
    Redirection* current;
    for (current = list_; current != NULL; current = current->next_) {
      if (current->address_of_hlt_instruction() == address_of_hlt) {
        return current->external_function_;
      }
    }
    return 0;
  }

 private:
  Redirection(uword external_function,
              Simulator::CallKind call_kind,
              int argument_count)
      : external_function_(external_function),
        call_kind_(call_kind),
        argument_count_(argument_count),
        hlt_instruction_(Instr::kSimulatorRedirectInstruction),
        next_(list_) {
    // Atomically prepend this element to the front of the global list.
    // Note: Since elements are never removed, there is no ABA issue.
    Redirection* list_head = list_;
    do {
      next_ = list_head;
      list_head =
          reinterpret_cast<Redirection*>(AtomicOperations::CompareAndSwapWord(
              reinterpret_cast<uword*>(&list_), reinterpret_cast<uword>(next_),
              reinterpret_cast<uword>(this)));
    } while (list_head != next_);
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

uword Simulator::FunctionForRedirect(uword redirect) {
  return Redirection::FunctionForRedirect(redirect);
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
void Simulator::set_register(Instr* instr,
                             Register reg,
                             int64_t value,
                             R31Type r31t) {
  // Register is in range.
  ASSERT((reg >= 0) && (reg < kNumberOfCpuRegisters));
  ASSERT(instr == NULL || reg != R18);  // R18 is globally reserved on iOS.
  if ((reg != R31) || (r31t != R31IsZR)) {
    registers_[reg] = value;
    // If we're setting CSP, make sure it is 16-byte aligned. In truth, CSP
    // can store addresses that are not 16-byte aligned, but loads and stores
    // are not allowed through CSP when it is not aligned. Thus, this check is
    // more conservative that necessary. However, it will likely be more
    // useful to find the program locations where CSP is set to a bad value,
    // than to find only the resulting loads/stores that would cause a fault on
    // hardware.
    if ((instr != NULL) && (reg == R31) && !Utils::IsAligned(value, 16)) {
      UnalignedAccess("CSP set", value, instr);
    }
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
    return static_cast<int32_t>(registers_[reg]);
  }
}

int32_t Simulator::get_vregisters(VRegister reg, int idx) const {
  ASSERT((reg >= 0) && (reg < kNumberOfVRegisters));
  ASSERT((idx >= 0) && (idx <= 3));
  return vregisters_[reg].bits.i32[idx];
}

void Simulator::set_vregisters(VRegister reg, int idx, int32_t value) {
  ASSERT((reg >= 0) && (reg < kNumberOfVRegisters));
  ASSERT((idx >= 0) && (idx <= 3));
  vregisters_[reg].bits.i32[idx] = value;
}

int64_t Simulator::get_vregisterd(VRegister reg, int idx) const {
  ASSERT((reg >= 0) && (reg < kNumberOfVRegisters));
  ASSERT((idx == 0) || (idx == 1));
  return vregisters_[reg].bits.i64[idx];
}

void Simulator::set_vregisterd(VRegister reg, int idx, int64_t value) {
  ASSERT((reg >= 0) && (reg < kNumberOfVRegisters));
  ASSERT((idx == 0) || (idx == 1));
  vregisters_[reg].bits.i64[idx] = value;
}

void Simulator::get_vregister(VRegister reg, simd_value_t* value) const {
  ASSERT((reg >= 0) && (reg < kNumberOfVRegisters));
  value->bits.i64[0] = vregisters_[reg].bits.i64[0];
  value->bits.i64[1] = vregisters_[reg].bits.i64[1];
}

void Simulator::set_vregister(VRegister reg, const simd_value_t& value) {
  ASSERT((reg >= 0) && (reg < kNumberOfVRegisters));
  vregisters_[reg].bits.i64[0] = value.bits.i64[0];
  vregisters_[reg].bits.i64[1] = value.bits.i64[1];
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
  char buffer[128];
  snprintf(buffer, sizeof(buffer),
           "illegal memory access at 0x%" Px ", pc=0x%" Px ", last_pc=0x%" Px
           "\n",
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
  snprintf(buffer, sizeof(buffer), "unaligned %s at 0x%" Px ", pc=%p\n", msg,
           addr, instr);
  SimulatorDebugger dbg(this);
  dbg.Stop(instr, buffer);
  // The debugger will not be able to single step past this instruction, but
  // it will be possible to disassemble the code and inspect registers.
  FATAL("Cannot continue execution after unaligned access.");
}

void Simulator::UnimplementedInstruction(Instr* instr) {
  char buffer[128];
  snprintf(buffer, sizeof(buffer),
           "Unimplemented instruction: at %p, last_pc=0x%" Px64 "\n", instr,
           get_last_pc());
  SimulatorDebugger dbg(this);
  dbg.Stop(instr, buffer);
  FATAL("Cannot continue execution after unimplemented instruction.");
}

bool Simulator::IsTracingExecution() const {
  return icount_ > FLAG_trace_sim_after;
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

void Simulator::ClearExclusive() {
  exclusive_access_addr_ = 0;
  exclusive_access_value_ = 0;
}

intptr_t Simulator::ReadExclusiveX(uword addr, Instr* instr) {
  exclusive_access_addr_ = addr;
  exclusive_access_value_ = ReadX(addr, instr);
  return exclusive_access_value_;
}

intptr_t Simulator::ReadExclusiveW(uword addr, Instr* instr) {
  exclusive_access_addr_ = addr;
  exclusive_access_value_ = ReadWU(addr, instr);
  return exclusive_access_value_;
}

intptr_t Simulator::WriteExclusiveX(uword addr, intptr_t value, Instr* instr) {
  // In a well-formed code store-exclusive instruction should always follow
  // a corresponding load-exclusive instruction with the same address.
  ASSERT((exclusive_access_addr_ == 0) || (exclusive_access_addr_ == addr));
  if (exclusive_access_addr_ != addr) {
    return 1;  // Failure.
  }

  uword old_value = exclusive_access_value_;
  ClearExclusive();

  if (AtomicOperations::CompareAndSwapWord(reinterpret_cast<uword*>(addr),
                                           old_value, value) == old_value) {
    return 0;  // Success.
  }
  return 1;  // Failure.
}

intptr_t Simulator::WriteExclusiveW(uword addr, intptr_t value, Instr* instr) {
  // In a well-formed code store-exclusive instruction should always follow
  // a corresponding load-exclusive instruction with the same address.
  ASSERT((exclusive_access_addr_ == 0) || (exclusive_access_addr_ == addr));
  if (exclusive_access_addr_ != addr) {
    return 1;  // Failure.
  }

  uint32_t old_value = static_cast<uint32_t>(exclusive_access_value_);
  ClearExclusive();

  if (AtomicOperations::CompareAndSwapUint32(reinterpret_cast<uint32_t*>(addr),
                                             old_value, value) == old_value) {
    return 0;  // Success.
  }
  return 1;  // Failure.
}

// Unsupported instructions use Format to print an error and stop execution.
void Simulator::Format(Instr* instr, const char* format) {
  OS::Print("Simulator found unsupported instruction:\n 0x%p: %s\n", instr,
            format);
  UNIMPLEMENTED();
}

// Calculate and set the Negative and Zero flags.
void Simulator::SetNZFlagsW(int32_t val) {
  n_flag_ = (val < 0);
  z_flag_ = (val == 0);
}

// Calculate C flag value for additions (and subtractions with adjusted args).
bool Simulator::CarryFromW(int32_t left, int32_t right, int32_t carry) {
  uint64_t uleft = static_cast<uint32_t>(left);
  uint64_t uright = static_cast<uint32_t>(right);
  uint64_t ucarry = static_cast<uint32_t>(carry);
  return ((uleft + uright + ucarry) >> 32) != 0;
}

// Calculate V flag value for additions (and subtractions with adjusted args).
bool Simulator::OverflowFromW(int32_t left, int32_t right, int32_t carry) {
  int64_t result = static_cast<int64_t>(left) + right + carry;
  return (result >> 31) != (result >> 32);
}

// Calculate and set the Negative and Zero flags.
void Simulator::SetNZFlagsX(int64_t val) {
  n_flag_ = (val < 0);
  z_flag_ = (val == 0);
}

// Calculate C flag value for additions and subtractions.
bool Simulator::CarryFromX(int64_t alu_out,
                           int64_t left,
                           int64_t right,
                           bool addition) {
  if (addition) {
    return (((left & right) | ((left | right) & ~alu_out)) >> 63) != 0;
  } else {
    return (((~left & right) | ((~left | right) & alu_out)) >> 63) == 0;
  }
}

// Calculate V flag value for additions and subtractions.
bool Simulator::OverflowFromX(int64_t alu_out,
                              int64_t left,
                              int64_t right,
                              bool addition) {
  if (addition) {
    return (((alu_out ^ left) & (alu_out ^ right)) >> 63) != 0;
  } else {
    return (((left ^ right) & (alu_out ^ left)) >> 63) != 0;
  }
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
  const int64_t shifted_imm = static_cast<int64_t>(instr->Imm16Field())
                              << shift;

  if (instr->SFField()) {
    if (instr->Bits(29, 2) == 0) {
      // Format(instr, "movn'sf 'rd, 'imm16 'hw");
      set_register(instr, rd, ~shifted_imm, instr->RdMode());
    } else if (instr->Bits(29, 2) == 2) {
      // Format(instr, "movz'sf 'rd, 'imm16 'hw");
      set_register(instr, rd, shifted_imm, instr->RdMode());
    } else if (instr->Bits(29, 2) == 3) {
      // Format(instr, "movk'sf 'rd, 'imm16 'hw");
      const int64_t rd_val = get_register(rd, instr->RdMode());
      const int64_t result = (rd_val & ~(0xffffL << shift)) | shifted_imm;
      set_register(instr, rd, result, instr->RdMode());
    } else {
      UnimplementedInstruction(instr);
    }
  } else if ((hw & 0x2) == 0) {
    if (instr->Bits(29, 2) == 0) {
      // Format(instr, "movn'sf 'rd, 'imm16 'hw");
      set_wregister(rd, ~shifted_imm & kWRegMask, instr->RdMode());
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
  const bool addition = (instr->Bit(30) == 0);
  // Format(instr, "addi'sf's 'rd, 'rn, 'imm12s");
  // Format(instr, "subi'sf's 'rd, 'rn, 'imm12s");
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  uint32_t imm = (instr->Bit(22) == 1) ? (instr->Imm12Field() << 12)
                                       : (instr->Imm12Field());
  if (instr->SFField()) {
    // 64-bit add.
    const int64_t rn_val = get_register(rn, instr->RnMode());
    const int64_t alu_out = addition ? (rn_val + imm) : (rn_val - imm);
    set_register(instr, rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsX(alu_out);
      SetCFlag(CarryFromX(alu_out, rn_val, imm, addition));
      SetVFlag(OverflowFromX(alu_out, rn_val, imm, addition));
    }
  } else {
    // 32-bit add.
    const int32_t rn_val = get_wregister(rn, instr->RnMode());
    int32_t carry_in = 0;
    if (!addition) {
      carry_in = 1;
      imm = ~imm;
    }
    const int32_t alu_out = rn_val + imm + carry_in;
    set_wregister(rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsW(alu_out);
      SetCFlag(CarryFromW(rn_val, imm, carry_in));
      SetVFlag(OverflowFromW(rn_val, imm, carry_in));
    }
  }
}

void Simulator::DecodeBitfield(Instr* instr) {
  int bitwidth = instr->SFField() == 0 ? 32 : 64;
  unsigned op = instr->Bits(29, 2);
  ASSERT(op <= 2);
  bool sign_extend = op == 0;
  bool zero_extend = op == 2;
  ASSERT(instr->NField() == instr->SFField());
  const Register rn = instr->RnField();
  const Register rd = instr->RdField();
  int64_t result = get_register(rn, instr->RnMode());
  int r_bit = instr->ImmRField();
  int s_bit = instr->ImmSField();
  result &= Utils::NBitMask(bitwidth);
  ASSERT(s_bit < bitwidth && r_bit < bitwidth);
  // See ARM v8 Instruction set overview 5.4.5.
  // If s >= r then Rd[s-r:0] := Rn[s:r], else Rd[bitwidth+s-r:bitwidth-r] :=
  // Rn[s:0].
  uword mask = Utils::NBitMask(s_bit + 1);
  if (s_bit >= r_bit) {
    mask >>= r_bit;
    result >>= r_bit;
  } else {
    result <<= bitwidth - r_bit;
    mask <<= bitwidth - r_bit;
  }
  result &= mask;
  if (sign_extend) {
    int highest_bit = (s_bit - r_bit) & (bitwidth - 1);
    int shift = bitwidth - highest_bit - 1;
    result <<= shift;
    result = static_cast<word>(result) >> shift;
  } else if (!zero_extend) {
    const int64_t rd_val = get_register(rd, instr->RnMode());
    result |= rd_val & ~mask;
  }
  if (bitwidth == 64) {
    set_register(instr, rd, result, instr->RdMode());
  } else {
    set_wregister(rd, result, instr->RdMode());
  }
}

void Simulator::DecodeLogicalImm(Instr* instr) {
  const int op = instr->Bits(29, 2);
  const bool set_flags = op == 3;
  const int out_size = ((instr->SFField() == 0) && (instr->NField() == 0))
                           ? kWRegSizeInBits
                           : kXRegSizeInBits;
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
    set_register(instr, rd, alu_out, instr->RdMode());
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
    set_register(instr, rd, dest, instr->RdMode());
  } else {
    UnimplementedInstruction(instr);
  }
}

void Simulator::DecodeDPImmediate(Instr* instr) {
  if (instr->IsMoveWideOp()) {
    DecodeMoveWide(instr);
  } else if (instr->IsAddSubImmOp()) {
    DecodeAddSubImm(instr);
  } else if (instr->IsBitfieldOp()) {
    DecodeBitfield(instr);
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
    case EQ:
      return z_flag_;
    case NE:
      return !z_flag_;
    case CS:
      return c_flag_;
    case CC:
      return !c_flag_;
    case MI:
      return n_flag_;
    case PL:
      return !n_flag_;
    case VS:
      return v_flag_;
    case VC:
      return !v_flag_;
    case HI:
      return c_flag_ && !z_flag_;
    case LS:
      return !c_flag_ || z_flag_;
    case GE:
      return n_flag_ == v_flag_;
    case LT:
      return n_flag_ != v_flag_;
    case GT:
      return !z_flag_ && (n_flag_ == v_flag_);
    case LE:
      return z_flag_ || (n_flag_ != v_flag_);
    case AL:
      return true;
    default:
      UNREACHABLE();
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
typedef int64_t (*SimulatorLeafRuntimeCall)(int64_t r0,
                                            int64_t r1,
                                            int64_t r2,
                                            int64_t r3,
                                            int64_t r4,
                                            int64_t r5,
                                            int64_t r6,
                                            int64_t r7);

// Calls to leaf float Dart runtime functions are based on this interface.
typedef double (*SimulatorLeafFloatRuntimeCall)(double d0,
                                                double d1,
                                                double d2,
                                                double d3,
                                                double d4,
                                                double d5,
                                                double d6,
                                                double d7);

// Calls to native Dart functions are based on this interface.
typedef void (*SimulatorBootstrapNativeCall)(NativeArguments* arguments);
typedef void (*SimulatorNativeCall)(NativeArguments* arguments, uword target);

void Simulator::DoRedirectedCall(Instr* instr) {
  SimulatorSetjmpBuffer buffer(this);
  if (!setjmp(buffer.buffer_)) {
    int64_t saved_lr = get_register(LR);
    Redirection* redirection = Redirection::FromHltInstruction(instr);
    uword external = redirection->external_function();
    if (IsTracingExecution()) {
      THR_Print("Call to host function at 0x%" Pd "\n", external);
    }

    if ((redirection->call_kind() == kRuntimeCall) ||
        (redirection->call_kind() == kBootstrapNativeCall) ||
        (redirection->call_kind() == kNativeCall)) {
      // Set the top_exit_frame_info of this simulator to the native stack.
      set_top_exit_frame_info(Thread::GetCurrentStackPointer());
    }
    if (redirection->call_kind() == kRuntimeCall) {
      NativeArguments* arguments =
          reinterpret_cast<NativeArguments*>(get_register(R0));
      SimulatorRuntimeCall target =
          reinterpret_cast<SimulatorRuntimeCall>(external);
      target(*arguments);
      // Zap result register from void function.
      set_register(instr, R0, icount_);
      set_register(instr, R1, icount_);
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
      set_register(instr, R0, res);      // Set returned result from function.
      set_register(instr, R1, icount_);  // Zap unused result register.
    } else if (redirection->call_kind() == kLeafFloatRuntimeCall) {
      ASSERT((0 <= redirection->argument_count()) &&
             (redirection->argument_count() <= 8));
      SimulatorLeafFloatRuntimeCall target =
          reinterpret_cast<SimulatorLeafFloatRuntimeCall>(external);
      const double d0 = bit_cast<double, int64_t>(get_vregisterd(V0, 0));
      const double d1 = bit_cast<double, int64_t>(get_vregisterd(V1, 0));
      const double d2 = bit_cast<double, int64_t>(get_vregisterd(V2, 0));
      const double d3 = bit_cast<double, int64_t>(get_vregisterd(V3, 0));
      const double d4 = bit_cast<double, int64_t>(get_vregisterd(V4, 0));
      const double d5 = bit_cast<double, int64_t>(get_vregisterd(V5, 0));
      const double d6 = bit_cast<double, int64_t>(get_vregisterd(V6, 0));
      const double d7 = bit_cast<double, int64_t>(get_vregisterd(V7, 0));
      const double res = target(d0, d1, d2, d3, d4, d5, d6, d7);
      set_vregisterd(V0, 0, bit_cast<int64_t, double>(res));
      set_vregisterd(V0, 1, 0);
    } else if (redirection->call_kind() == kBootstrapNativeCall) {
      ASSERT(redirection->argument_count() == 1);
      NativeArguments* arguments;
      arguments = reinterpret_cast<NativeArguments*>(get_register(R0));
      SimulatorBootstrapNativeCall target =
          reinterpret_cast<SimulatorBootstrapNativeCall>(external);
      target(arguments);
      // Zap result register from void function.
      set_register(instr, R0, icount_);
    } else {
      ASSERT(redirection->call_kind() == kNativeCall);
      NativeArguments* arguments;
      arguments = reinterpret_cast<NativeArguments*>(get_register(R0));
      uword target_func = get_register(R1);
      SimulatorNativeCall target =
          reinterpret_cast<SimulatorNativeCall>(external);
      target(arguments, target_func);
      // Zap result register from void function.
      set_register(instr, R0, icount_);
      set_register(instr, R1, icount_);
    }
    set_top_exit_frame_info(0);

    // Zap caller-saved registers, since the actual runtime call could have
    // used them.
    set_register(NULL, R2, icount_);
    set_register(NULL, R3, icount_);
    set_register(NULL, R4, icount_);
    set_register(NULL, R5, icount_);
    set_register(NULL, R6, icount_);
    set_register(NULL, R7, icount_);
    set_register(NULL, R8, icount_);
    set_register(NULL, R9, icount_);
    set_register(NULL, R10, icount_);
    set_register(NULL, R11, icount_);
    set_register(NULL, R12, icount_);
    set_register(NULL, R13, icount_);
    set_register(NULL, R14, icount_);
    set_register(NULL, R15, icount_);
    set_register(NULL, IP0, icount_);
    set_register(NULL, IP1, icount_);
    set_register(NULL, R18, icount_);
    set_register(NULL, LR, icount_);

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
    SimulatorDebugger dbg(this);
    int32_t imm = instr->Imm16Field();
    if (imm == Instr::kStopMessageCode) {
      const char* message = *reinterpret_cast<const char**>(
          reinterpret_cast<intptr_t>(instr) - 2 * Instr::kInstrSize);
      set_pc(get_pc() + Instr::kInstrSize);
      dbg.Stop(instr, message);
    } else {
      char buffer[32];
      snprintf(buffer, sizeof(buffer), "brk #0x%x", imm);
      set_pc(get_pc() + Instr::kInstrSize);
      dbg.Stop(instr, buffer);
    }
  } else if ((instr->Bits(0, 2) == 0) && (instr->Bits(2, 3) == 0) &&
             (instr->Bits(21, 3) == 2)) {
    // Format(instr, "hlt 'imm16");
    uint16_t imm = static_cast<uint16_t>(instr->Imm16Field());
    if (imm == Instr::kSimulatorBreakCode) {
      SimulatorDebugger dbg(this);
      dbg.Stop(instr, "breakpoint");
    } else if (imm == Instr::kSimulatorRedirectCode) {
      DoRedirectedCall(instr);
    } else {
      UnimplementedInstruction(instr);
    }
  } else {
    UnimplementedInstruction(instr);
  }
}

void Simulator::DecodeSystem(Instr* instr) {
  if (instr->InstructionBits() == CLREX) {
    // Format(instr, "clrex");
    ClearExclusive();
    return;
  }

  if ((instr->Bits(0, 8) == 0x1f) && (instr->Bits(12, 4) == 2) &&
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
    set_register(instr, LR, ret);
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
        set_register(instr, LR, ret);
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
  const uint32_t size = (instr->Bit(26) == 1)
                            ? ((instr->Bit(23) << 2) | instr->SzField())
                            : instr->SzField();
  uword address = 0;
  uword wb_address = 0;
  bool wb = false;
  if (instr->Bit(24) == 1) {
    // addr = rn + scaled unsigned 12-bit immediate offset.
    const uint32_t imm12 = static_cast<uint32_t>(instr->Imm12Field());
    const uint32_t offset = imm12 << size;
    address = rn_val + offset;
  } else if (instr->Bits(10, 2) == 0) {
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
    const uint8_t scale = (ext == UXTX) && (instr->Bit(12) == 1) ? size : 0;
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
  if (instr->Bit(26) == 1) {
    if (instr->Bit(22) == 0) {
      // Format(instr, "fstr'fsz 'vt, 'memop");
      const int64_t vt_val = get_vregisterd(vt, 0);
      switch (size) {
        case 2:
          WriteW(address, vt_val & kWRegMask, instr);
          break;
        case 3:
          WriteX(address, vt_val, instr);
          break;
        case 4: {
          simd_value_t val;
          get_vregister(vt, &val);
          WriteX(address, val.bits.i64[0], instr);
          WriteX(address + kWordSize, val.bits.i64[1], instr);
          break;
        }
        default:
          UnimplementedInstruction(instr);
          return;
      }
    } else {
      // Format(instr, "fldr'fsz 'vt, 'memop");
      switch (size) {
        case 2:
          set_vregisterd(vt, 0, static_cast<int64_t>(ReadWU(address, instr)));
          set_vregisterd(vt, 1, 0);
          break;
        case 3:
          set_vregisterd(vt, 0, ReadX(address, instr));
          set_vregisterd(vt, 1, 0);
          break;
        case 4: {
          simd_value_t val;
          val.bits.i64[0] = ReadX(address, instr);
          val.bits.i64[1] = ReadX(address + kWordSize, instr);
          set_vregister(vt, val);
          break;
        }
        default:
          UnimplementedInstruction(instr);
          return;
      }
    }
  } else {
    if (instr->Bits(22, 2) == 0) {
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
        set_register(instr, rt, val, R31IsZR);
      }
    }
  }

  // Do writeback.
  if (wb) {
    set_register(instr, rn, wb_address, R31IsSP);
  }
}

void Simulator::DecodeLoadStoreRegPair(Instr* instr) {
  const int32_t opc = instr->Bits(23, 3);
  const Register rn = instr->RnField();
  const Register rt = instr->RtField();
  const Register rt2 = instr->Rt2Field();
  const int64_t rn_val = get_register(rn, R31IsSP);
  const intptr_t shift = 2 + instr->SFField();
  const intptr_t size = 1 << shift;
  const int32_t offset = (instr->SImm7Field() << shift);
  uword address = 0;
  uword wb_address = 0;
  bool wb = false;

  if ((instr->Bits(30, 2) == 3) || (instr->Bit(26) != 0)) {
    UnimplementedInstruction(instr);
    return;
  }

  // Calculate address.
  switch (opc) {
    case 1:
      address = rn_val;
      wb_address = rn_val + offset;
      wb = true;
      break;
    case 2:
      address = rn_val + offset;
      break;
    case 3:
      address = rn_val + offset;
      wb_address = address;
      wb = true;
      break;
    default:
      UnimplementedInstruction(instr);
      return;
  }

  // Check the address.
  if (IsIllegalAddress(address)) {
    HandleIllegalAccess(address, instr);
    return;
  }

  // Do access.
  if (instr->Bit(22)) {
    // Format(instr, "ldp'sf 'rt, 'ra, 'memop");
    const bool signd = instr->Bit(30) == 1;
    int64_t val1 = 0;  // Sign extend into an int64_t.
    int64_t val2 = 0;
    if (instr->Bit(31) == 1) {
      // 64-bit read.
      val1 = ReadX(address, instr);
      val2 = ReadX(address + size, instr);
    } else {
      if (signd) {
        val1 = static_cast<int64_t>(ReadW(address, instr));
        val2 = static_cast<int64_t>(ReadW(address + size, instr));
      } else {
        val1 = static_cast<int64_t>(ReadWU(address, instr));
        val2 = static_cast<int64_t>(ReadWU(address + size, instr));
      }
    }

    // Write to register.
    if (instr->Bit(31) == 1) {
      set_register(instr, rt, val1, R31IsZR);
      set_register(instr, rt2, val2, R31IsZR);
    } else {
      set_wregister(rt, static_cast<int32_t>(val1), R31IsZR);
      set_wregister(rt2, static_cast<int32_t>(val2), R31IsZR);
    }
  } else {
    // Format(instr, "stp'sf 'rt, 'ra, 'memop");
    if (instr->Bit(31) == 1) {
      const int64_t val1 = get_register(rt, R31IsZR);
      const int64_t val2 = get_register(rt2, R31IsZR);
      WriteX(address, val1, instr);
      WriteX(address + size, val2, instr);
    } else {
      const int32_t val1 = get_wregister(rt, R31IsZR);
      const int32_t val2 = get_wregister(rt2, R31IsZR);
      WriteW(address, val1, instr);
      WriteW(address + size, val2, instr);
    }
  }

  // Do writeback.
  if (wb) {
    set_register(instr, rn, wb_address, R31IsSP);
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
    set_register(instr, rt, val, R31IsZR);
  } else {
    // Format(instr, "ldrw 'rt, 'pcldr");
    set_wregister(rt, static_cast<int32_t>(val), R31IsZR);
  }
}

void Simulator::DecodeLoadStoreExclusive(Instr* instr) {
  if ((instr->Bit(23) != 0) || (instr->Bit(21) != 0) || (instr->Bit(15) != 0)) {
    UNIMPLEMENTED();
  }
  const int32_t size = instr->Bits(30, 2);
  if (size != 3 && size != 2) {
    UNIMPLEMENTED();
  }
  const Register rs = instr->RsField();
  const Register rn = instr->RnField();
  const Register rt = instr->RtField();
  const bool is_load = instr->Bit(22) == 1;
  if (is_load) {
    // Format(instr, "ldxr 'rt, 'rn");
    if (size == 3) {
      const int64_t addr = get_register(rn, R31IsSP);
      intptr_t value = ReadExclusiveX(addr, instr);
      set_register(instr, rt, value, R31IsSP);
    } else {
      const int64_t addr = get_register(rn, R31IsSP);
      intptr_t value = ReadExclusiveW(addr, instr);
      set_register(instr, rt, value, R31IsSP);
    }
  } else {
    // Format(instr, "stxr 'rs, 'rt, 'rn");
    if (size == 3) {
      uword value = get_register(rt, R31IsSP);
      uword addr = get_register(rn, R31IsSP);
      intptr_t status = WriteExclusiveX(addr, value, instr);
      set_register(instr, rs, status, R31IsSP);
    } else {
      uint32_t value = get_register(rt, R31IsSP);
      uword addr = get_register(rn, R31IsSP);
      intptr_t status = WriteExclusiveW(addr, value, instr);
      set_register(instr, rs, status, R31IsSP);
    }
  }
}

void Simulator::DecodeLoadStore(Instr* instr) {
  if (instr->IsLoadStoreRegOp()) {
    DecodeLoadStoreReg(instr);
  } else if (instr->IsLoadStoreRegPairOp()) {
    DecodeLoadStoreRegPair(instr);
  } else if (instr->IsLoadRegLiteralOp()) {
    DecodeLoadRegLiteral(instr);
  } else if (instr->IsLoadStoreExclusiveOp()) {
    DecodeLoadStoreExclusive(instr);
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
             ((static_cast<uint64_t>(value) & ((1ULL << amount) - 1ULL))
              << (reg_size - amount));
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
  const bool addition = (instr->Bit(30) == 0);
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const int64_t rm_val = DecodeShiftExtendOperand(instr);
  if (instr->SFField()) {
    // 64-bit add.
    const int64_t rn_val = get_register(rn, instr->RnMode());
    const int64_t alu_out = rn_val + (addition ? rm_val : -rm_val);
    set_register(instr, rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsX(alu_out);
      SetCFlag(CarryFromX(alu_out, rn_val, rm_val, addition));
      SetVFlag(OverflowFromX(alu_out, rn_val, rm_val, addition));
    }
  } else {
    // 32-bit add.
    const int32_t rn_val = get_wregister(rn, instr->RnMode());
    int32_t rm_val32 = static_cast<int32_t>(rm_val & kWRegMask);
    int32_t carry_in = 0;
    if (!addition) {
      carry_in = 1;
      rm_val32 = ~rm_val32;
    }
    const int32_t alu_out = rn_val + rm_val32 + carry_in;
    set_wregister(rd, alu_out, instr->RdMode());
    if (instr->HasS()) {
      SetNZFlagsW(alu_out);
      SetCFlag(CarryFromW(rn_val, rm_val32, carry_in));
      SetVFlag(OverflowFromW(rn_val, rm_val32, carry_in));
    }
  }
}

void Simulator::DecodeAddSubWithCarry(Instr* instr) {
  // Format(instr, "adc'sf's 'rd, 'rn, 'rm");
  // Format(instr, "sbc'sf's 'rd, 'rn, 'rm");
  const bool addition = (instr->Bit(30) == 0);
  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const Register rm = instr->RmField();
  const int64_t rn_val64 = get_register(rn, R31IsZR);
  const int32_t rn_val32 = get_wregister(rn, R31IsZR);
  const int64_t rm_val64 = get_register(rm, R31IsZR);
  int32_t rm_val32 = get_wregister(rm, R31IsZR);
  const int32_t carry_in = c_flag_ ? 1 : 0;
  if (instr->SFField()) {
    // 64-bit add.
    const int64_t alu_out =
        rn_val64 + (addition ? rm_val64 : ~rm_val64) + carry_in;
    set_register(instr, rd, alu_out, R31IsZR);
    if (instr->HasS()) {
      SetNZFlagsX(alu_out);
      SetCFlag(CarryFromX(alu_out, rn_val64, rm_val64, addition));
      SetVFlag(OverflowFromX(alu_out, rn_val64, rm_val64, addition));
    }
  } else {
    // 32-bit add.
    if (!addition) {
      rm_val32 = ~rm_val32;
    }
    const int32_t alu_out = rn_val32 + rm_val32 + carry_in;
    set_wregister(rd, alu_out, R31IsZR);
    if (instr->HasS()) {
      SetNZFlagsW(alu_out);
      SetCFlag(CarryFromW(rn_val32, rm_val32, carry_in));
      SetVFlag(OverflowFromW(rn_val32, rm_val32, carry_in));
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
    set_register(instr, rd, alu_out, instr->RdMode());
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

void Simulator::DecodeMiscDP1Source(Instr* instr) {
  if (instr->Bit(29) != 0) {
    UnimplementedInstruction(instr);
  }

  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const int op = instr->Bits(10, 10);
  const int64_t rn_val64 = get_register(rn, R31IsZR);
  const int32_t rn_val32 = get_wregister(rn, R31IsZR);
  switch (op) {
    case 4: {
      // Format(instr, "clz'sf 'rd, 'rn");
      int64_t rd_val = 0;
      int64_t rn_val = (instr->SFField() == 1) ? rn_val64 : rn_val32;
      if (rn_val != 0) {
        while (rn_val > 0) {
          rd_val++;
          rn_val <<= 1;
        }
      } else {
        rd_val = (instr->SFField() == 1) ? 64 : 32;
      }
      if (instr->SFField() == 1) {
        set_register(instr, rd, rd_val, R31IsZR);
      } else {
        set_wregister(rd, rd_val, R31IsZR);
      }
      break;
    }
    default:
      UnimplementedInstruction(instr);
      break;
  }
}

void Simulator::DecodeMiscDP2Source(Instr* instr) {
  if (instr->Bit(29) != 0) {
    UnimplementedInstruction(instr);
  }

  const Register rd = instr->RdField();
  const Register rn = instr->RnField();
  const Register rm = instr->RmField();
  const int op = instr->Bits(10, 5);
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
        set_register(instr, rd, divide64(rn_val64, rm_val64, signd), R31IsZR);
      } else {
        set_wregister(rd, divide32(rn_val32, rm_val32, signd), R31IsZR);
      }
      break;
    }
    case 8: {
      // Format(instr, "lsl'sf 'rd, 'rn, 'rm");
      if (instr->SFField() == 1) {
        const int64_t alu_out = rn_val64 << (rm_val64 & (kXRegSizeInBits - 1));
        set_register(instr, rd, alu_out, R31IsZR);
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
        set_register(instr, rd, alu_out, R31IsZR);
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
        set_register(instr, rd, alu_out, R31IsZR);
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
      set_register(instr, rd, alu_out, R31IsZR);
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
      set_register(instr, rd, alu_out, R31IsZR);
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
#if defined(HOST_OS_WINDOWS)
    // Visual Studio does not support __int128.
    int64_t alu_out;
    Multiply128(rn_val, rm_val, &alu_out);
#else
    const __int128 res =
        static_cast<__int128>(rn_val) * static_cast<__int128>(rm_val);
    const int64_t alu_out = static_cast<int64_t>(res >> 64);
#endif  // HOST_OS_WINDOWS
    set_register(instr, rd, alu_out, R31IsZR);
  } else if ((instr->Bits(29, 2) == 0) && (instr->Bits(21, 3) == 6) &&
             (instr->Bit(15) == 0)) {
    // Format(instr, "umulh 'rd, 'rn, 'rm");
    const uint64_t rn_val = get_register(rn, R31IsZR);
    const uint64_t rm_val = get_register(rm, R31IsZR);
#if defined(HOST_OS_WINDOWS)
    // Visual Studio does not support __int128.
    uint64_t alu_out;
    UnsignedMultiply128(rn_val, rm_val, &alu_out);
#else
    const unsigned __int128 res = static_cast<unsigned __int128>(rn_val) *
                                  static_cast<unsigned __int128>(rm_val);
    const uint64_t alu_out = static_cast<uint64_t>(res >> 64);
#endif  // HOST_OS_WINDOWS
    set_register(instr, rd, alu_out, R31IsZR);
  } else if ((instr->Bits(29, 3) == 4) && (instr->Bits(21, 3) == 5) &&
             (instr->Bit(15) == 0)) {
    // Format(instr, "umaddl 'rd, 'rn, 'rm, 'ra");
    const uint64_t rn_val = static_cast<uint32_t>(get_wregister(rn, R31IsZR));
    const uint64_t rm_val = static_cast<uint32_t>(get_wregister(rm, R31IsZR));
    const uint64_t ra_val = get_register(ra, R31IsZR);
    const uint64_t alu_out = ra_val + (rn_val * rm_val);
    set_register(instr, rd, alu_out, R31IsZR);
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
  } else if ((instr->Bits(29, 2) == 2) && (instr->Bits(10, 2) == 0)) {
    // Format(instr, "csinv'sf'cond 'rd, 'rn, 'rm");
    result64 = ~rm_val64;
    result32 = ~rm_val32;
    if (ConditionallyExecute(instr)) {
      result64 = rn_val64;
      result32 = rn_val32;
    }
  } else if ((instr->Bits(29, 2) == 2) && (instr->Bits(10, 2) == 1)) {
    // Format(instr, "csneg'sf'cond 'rd, 'rn, 'rm");
    result64 = -rm_val64;
    result32 = -rm_val32;
    if (ConditionallyExecute(instr)) {
      result64 = rn_val64;
      result32 = rn_val32;
    }
  } else {
    UnimplementedInstruction(instr);
    return;
  }

  if (instr->SFField() == 1) {
    set_register(instr, rd, result64, instr->RdMode());
  } else {
    set_wregister(rd, result32, instr->RdMode());
  }
}

void Simulator::DecodeDPRegister(Instr* instr) {
  if (instr->IsAddSubShiftExtOp()) {
    DecodeAddSubShiftExt(instr);
  } else if (instr->IsAddSubWithCarryOp()) {
    DecodeAddSubWithCarry(instr);
  } else if (instr->IsLogicalShiftOp()) {
    DecodeLogicalShift(instr);
  } else if (instr->IsMiscDP1SourceOp()) {
    DecodeMiscDP1Source(instr);
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

void Simulator::DecodeSIMDCopy(Instr* instr) {
  const int32_t Q = instr->Bit(30);
  const int32_t op = instr->Bit(29);
  const int32_t imm4 = instr->Bits(11, 4);
  const int32_t imm5 = instr->Bits(16, 5);

  int32_t idx4 = -1;
  int32_t idx5 = -1;
  int32_t element_bytes;
  if (imm5 & 0x1) {
    idx4 = imm4;
    idx5 = imm5 >> 1;
    element_bytes = 1;
  } else if (imm5 & 0x2) {
    idx4 = imm4 >> 1;
    idx5 = imm5 >> 2;
    element_bytes = 2;
  } else if (imm5 & 0x4) {
    idx4 = imm4 >> 2;
    idx5 = imm5 >> 3;
    element_bytes = 4;
  } else if (imm5 & 0x8) {
    idx4 = imm4 >> 3;
    idx5 = imm5 >> 4;
    element_bytes = 8;
  } else {
    UnimplementedInstruction(instr);
    return;
  }
  ASSERT((idx4 != -1) && (idx5 != -1));

  const VRegister vd = instr->VdField();
  const VRegister vn = instr->VnField();
  const Register rn = instr->RnField();
  const Register rd = instr->RdField();
  if ((op == 0) && (imm4 == 7)) {
    if (Q == 0) {
      // Format(instr, "vmovrs 'rd, 'vn'idx5");
      set_wregister(rd, get_vregisters(vn, idx5), R31IsZR);
    } else {
      // Format(instr, "vmovrd 'rd, 'vn'idx5");
      set_register(instr, rd, get_vregisterd(vn, idx5), R31IsZR);
    }
  } else if ((Q == 1) && (op == 0) && (imm4 == 0)) {
    // Format(instr, "vdup'csz 'vd, 'vn'idx5");
    if (element_bytes == 4) {
      for (int i = 0; i < 4; i++) {
        set_vregisters(vd, i, get_vregisters(vn, idx5));
      }
    } else if (element_bytes == 8) {
      for (int i = 0; i < 2; i++) {
        set_vregisterd(vd, i, get_vregisterd(vn, idx5));
      }
    } else {
      UnimplementedInstruction(instr);
      return;
    }
  } else if ((Q == 1) && (op == 0) && (imm4 == 3)) {
    // Format(instr, "vins'csz 'vd'idx5, 'rn");
    if (element_bytes == 4) {
      set_vregisters(vd, idx5, get_wregister(rn, R31IsZR));
    } else if (element_bytes == 8) {
      set_vregisterd(vd, idx5, get_register(rn, R31IsZR));
    } else {
      UnimplementedInstruction(instr);
    }
  } else if ((Q == 1) && (op == 0) && (imm4 == 1)) {
    // Format(instr, "vdup'csz 'vd, 'rn");
    if (element_bytes == 4) {
      for (int i = 0; i < 4; i++) {
        set_vregisters(vd, i, get_wregister(rn, R31IsZR));
      }
    } else if (element_bytes == 8) {
      for (int i = 0; i < 2; i++) {
        set_vregisterd(vd, i, get_register(rn, R31IsZR));
      }
    } else {
      UnimplementedInstruction(instr);
      return;
    }
  } else if ((Q == 1) && (op == 1)) {
    // Format(instr, "vins'csz 'vd'idx5, 'vn'idx4");
    if (element_bytes == 4) {
      set_vregisters(vd, idx5, get_vregisters(vn, idx4));
    } else if (element_bytes == 8) {
      set_vregisterd(vd, idx5, get_vregisterd(vn, idx4));
    } else {
      UnimplementedInstruction(instr);
    }
  } else {
    UnimplementedInstruction(instr);
  }
}

void Simulator::DecodeSIMDThreeSame(Instr* instr) {
  const int Q = instr->Bit(30);
  const int U = instr->Bit(29);
  const int opcode = instr->Bits(11, 5);

  if (Q == 0) {
    UnimplementedInstruction(instr);
    return;
  }

  const VRegister vd = instr->VdField();
  const VRegister vn = instr->VnField();
  const VRegister vm = instr->VmField();
  if (instr->Bit(22) == 0) {
    // f32 case.
    for (int idx = 0; idx < 4; idx++) {
      const int32_t vn_val = get_vregisters(vn, idx);
      const int32_t vm_val = get_vregisters(vm, idx);
      const float vn_flt = bit_cast<float, int32_t>(vn_val);
      const float vm_flt = bit_cast<float, int32_t>(vm_val);
      int32_t res = 0.0;
      if ((U == 0) && (opcode == 0x3)) {
        if (instr->Bit(23) == 0) {
          // Format(instr, "vand 'vd, 'vn, 'vm");
          res = vn_val & vm_val;
        } else {
          // Format(instr, "vorr 'vd, 'vn, 'vm");
          res = vn_val | vm_val;
        }
      } else if ((U == 1) && (opcode == 0x3)) {
        // Format(instr, "veor 'vd, 'vn, 'vm");
        res = vn_val ^ vm_val;
      } else if ((U == 0) && (opcode == 0x10)) {
        // Format(instr, "vadd'vsz 'vd, 'vn, 'vm");
        res = vn_val + vm_val;
      } else if ((U == 1) && (opcode == 0x10)) {
        // Format(instr, "vsub'vsz 'vd, 'vn, 'vm");
        res = vn_val - vm_val;
      } else if ((U == 0) && (opcode == 0x1a)) {
        if (instr->Bit(23) == 0) {
          // Format(instr, "vadd'vsz 'vd, 'vn, 'vm");
          res = bit_cast<int32_t, float>(vn_flt + vm_flt);
        } else {
          // Format(instr, "vsub'vsz 'vd, 'vn, 'vm");
          res = bit_cast<int32_t, float>(vn_flt - vm_flt);
        }
      } else if ((U == 1) && (opcode == 0x1b)) {
        // Format(instr, "vmul'vsz 'vd, 'vn, 'vm");
        res = bit_cast<int32_t, float>(vn_flt * vm_flt);
      } else if ((U == 1) && (opcode == 0x1f)) {
        // Format(instr, "vdiv'vsz 'vd, 'vn, 'vm");
        res = bit_cast<int32_t, float>(vn_flt / vm_flt);
      } else if ((U == 0) && (opcode == 0x1c)) {
        // Format(instr, "vceq'vsz 'vd, 'vn, 'vm");
        res = (vn_flt == vm_flt) ? 0xffffffff : 0;
      } else if ((U == 1) && (opcode == 0x1c)) {
        if (instr->Bit(23) == 1) {
          // Format(instr, "vcgt'vsz 'vd, 'vn, 'vm");
          res = (vn_flt > vm_flt) ? 0xffffffff : 0;
        } else {
          // Format(instr, "vcge'vsz 'vd, 'vn, 'vm");
          res = (vn_flt >= vm_flt) ? 0xffffffff : 0;
        }
      } else if ((U == 0) && (opcode == 0x1e)) {
        if (instr->Bit(23) == 1) {
          // Format(instr, "vmin'vsz 'vd, 'vn, 'vm");
          const float m = (vn_flt > vm_flt) ? vm_flt : vn_flt;
          res = bit_cast<int32_t, float>(m);
        } else {
          // Format(instr, "vmax'vsz 'vd, 'vn, 'vm");
          const float m = (vn_flt < vm_flt) ? vm_flt : vn_flt;
          res = bit_cast<int32_t, float>(m);
        }
      } else if ((U == 0) && (opcode == 0x1f)) {
        if (instr->Bit(23) == 0) {
          // Format(instr, "vrecps'vsz 'vd, 'vn, 'vm");
          res = bit_cast<int32_t, float>(2.0 - (vn_flt * vm_flt));
        } else {
          // Format(instr, "vrsqrt'vsz 'vd, 'vn, 'vm");
          res = bit_cast<int32_t, float>((3.0 - vn_flt * vm_flt) / 2.0);
        }
      } else {
        UnimplementedInstruction(instr);
        return;
      }
      set_vregisters(vd, idx, res);
    }
  } else {
    // f64 case.
    for (int idx = 0; idx < 2; idx++) {
      const int64_t vn_val = get_vregisterd(vn, idx);
      const int64_t vm_val = get_vregisterd(vm, idx);
      const double vn_dbl = bit_cast<double, int64_t>(vn_val);
      const double vm_dbl = bit_cast<double, int64_t>(vm_val);
      int64_t res = 0.0;
      if ((U == 0) && (opcode == 0x3)) {
        if (instr->Bit(23) == 0) {
          // Format(instr, "vand 'vd, 'vn, 'vm");
          res = vn_val & vm_val;
        } else {
          // Format(instr, "vorr 'vd, 'vn, 'vm");
          res = vn_val | vm_val;
        }
      } else if ((U == 1) && (opcode == 0x3)) {
        // Format(instr, "veor 'vd, 'vn, 'vm");
        res = vn_val ^ vm_val;
      } else if ((U == 0) && (opcode == 0x10)) {
        // Format(instr, "vadd'vsz 'vd, 'vn, 'vm");
        res = vn_val + vm_val;
      } else if ((U == 1) && (opcode == 0x10)) {
        // Format(instr, "vsub'vsz 'vd, 'vn, 'vm");
        res = vn_val - vm_val;
      } else if ((U == 0) && (opcode == 0x1a)) {
        if (instr->Bit(23) == 0) {
          // Format(instr, "vadd'vsz 'vd, 'vn, 'vm");
          res = bit_cast<int64_t, double>(vn_dbl + vm_dbl);
        } else {
          // Format(instr, "vsub'vsz 'vd, 'vn, 'vm");
          res = bit_cast<int64_t, double>(vn_dbl - vm_dbl);
        }
      } else if ((U == 1) && (opcode == 0x1b)) {
        // Format(instr, "vmul'vsz 'vd, 'vn, 'vm");
        res = bit_cast<int64_t, double>(vn_dbl * vm_dbl);
      } else if ((U == 1) && (opcode == 0x1f)) {
        // Format(instr, "vdiv'vsz 'vd, 'vn, 'vm");
        res = bit_cast<int64_t, double>(vn_dbl / vm_dbl);
      } else if ((U == 0) && (opcode == 0x1c)) {
        // Format(instr, "vceq'vsz 'vd, 'vn, 'vm");
        res = (vn_dbl == vm_dbl) ? 0xffffffffffffffffLL : 0;
      } else if ((U == 1) && (opcode == 0x1c)) {
        if (instr->Bit(23) == 1) {
          // Format(instr, "vcgt'vsz 'vd, 'vn, 'vm");
          res = (vn_dbl > vm_dbl) ? 0xffffffffffffffffLL : 0;
        } else {
          // Format(instr, "vcge'vsz 'vd, 'vn, 'vm");
          res = (vn_dbl >= vm_dbl) ? 0xffffffffffffffffLL : 0;
        }
      } else if ((U == 0) && (opcode == 0x1e)) {
        if (instr->Bit(23) == 1) {
          // Format(instr, "vmin'vsz 'vd, 'vn, 'vm");
          const double m = (vn_dbl > vm_dbl) ? vm_dbl : vn_dbl;
          res = bit_cast<int64_t, double>(m);
        } else {
          // Format(instr, "vmax'vsz 'vd, 'vn, 'vm");
          const double m = (vn_dbl < vm_dbl) ? vm_dbl : vn_dbl;
          res = bit_cast<int64_t, double>(m);
        }
      } else {
        UnimplementedInstruction(instr);
        return;
      }
      set_vregisterd(vd, idx, res);
    }
  }
}

static float arm_reciprocal_sqrt_estimate(float a) {
  // From the ARM Architecture Reference Manual A2-87.
  if (isinf(a) || (fabs(a) >= exp2f(126)))
    return 0.0;
  else if (a == 0.0)
    return kPosInfinity;
  else if (isnan(a))
    return a;

  uint32_t a_bits = bit_cast<uint32_t, float>(a);
  uint64_t scaled;
  if (((a_bits >> 23) & 1) != 0) {
    // scaled = '0 01111111101' : operand<22:0> : Zeros(29)
    scaled = (static_cast<uint64_t>(0x3fd) << 52) |
             ((static_cast<uint64_t>(a_bits) & 0x7fffff) << 29);
  } else {
    // scaled = '0 01111111110' : operand<22:0> : Zeros(29)
    scaled = (static_cast<uint64_t>(0x3fe) << 52) |
             ((static_cast<uint64_t>(a_bits) & 0x7fffff) << 29);
  }
  // result_exp = (380 - UInt(operand<30:23>) DIV 2;
  int32_t result_exp = (380 - ((a_bits >> 23) & 0xff)) / 2;

  double scaled_d = bit_cast<double, uint64_t>(scaled);
  ASSERT((scaled_d >= 0.25) && (scaled_d < 1.0));

  double r;
  if (scaled_d < 0.5) {
    // range 0.25 <= a < 0.5

    // a in units of 1/512 rounded down.
    int32_t q0 = static_cast<int32_t>(scaled_d * 512.0);
    // reciprocal root r.
    r = 1.0 / sqrt((static_cast<double>(q0) + 0.5) / 512.0);
  } else {
    // range 0.5 <= a < 1.0

    // a in units of 1/256 rounded down.
    int32_t q1 = static_cast<int32_t>(scaled_d * 256.0);
    // reciprocal root r.
    r = 1.0 / sqrt((static_cast<double>(q1) + 0.5) / 256.0);
  }
  // r in units of 1/256 rounded to nearest.
  int32_t s = static_cast<int>(256.0 * r + 0.5);
  double estimate = static_cast<double>(s) / 256.0;
  ASSERT((estimate >= 1.0) && (estimate <= (511.0 / 256.0)));

  // result = 0 : result_exp<7:0> : estimate<51:29>
  int32_t result_bits =
      ((result_exp & 0xff) << 23) |
      ((bit_cast<uint64_t, double>(estimate) >> 29) & 0x7fffff);
  return bit_cast<float, int32_t>(result_bits);
}

static float arm_recip_estimate(float a) {
  // From the ARM Architecture Reference Manual A2-85.
  if (isinf(a) || (fabs(a) >= exp2f(126)))
    return 0.0;
  else if (a == 0.0)
    return kPosInfinity;
  else if (isnan(a))
    return a;

  uint32_t a_bits = bit_cast<uint32_t, float>(a);
  // scaled = '0011 1111 1110' : a<22:0> : Zeros(29)
  uint64_t scaled = (static_cast<uint64_t>(0x3fe) << 52) |
                    ((static_cast<uint64_t>(a_bits) & 0x7fffff) << 29);
  // result_exp = 253 - UInt(a<30:23>)
  int32_t result_exp = 253 - ((a_bits >> 23) & 0xff);
  ASSERT((result_exp >= 1) && (result_exp <= 252));

  double scaled_d = bit_cast<double, uint64_t>(scaled);
  ASSERT((scaled_d >= 0.5) && (scaled_d < 1.0));

  // a in units of 1/512 rounded down.
  int32_t q = static_cast<int32_t>(scaled_d * 512.0);
  // reciprocal r.
  double r = 1.0 / ((static_cast<double>(q) + 0.5) / 512.0);
  // r in units of 1/256 rounded to nearest.
  int32_t s = static_cast<int32_t>(256.0 * r + 0.5);
  double estimate = static_cast<double>(s) / 256.0;
  ASSERT((estimate >= 1.0) && (estimate <= (511.0 / 256.0)));

  // result = sign : result_exp<7:0> : estimate<51:29>
  int32_t result_bits =
      (a_bits & 0x80000000) | ((result_exp & 0xff) << 23) |
      ((bit_cast<uint64_t, double>(estimate) >> 29) & 0x7fffff);
  return bit_cast<float, int32_t>(result_bits);
}

void Simulator::DecodeSIMDTwoReg(Instr* instr) {
  const int32_t Q = instr->Bit(30);
  const int32_t U = instr->Bit(29);
  const int32_t op = instr->Bits(12, 5);
  const int32_t sz = instr->Bits(22, 2);
  const VRegister vd = instr->VdField();
  const VRegister vn = instr->VnField();

  if (Q != 1) {
    UnimplementedInstruction(instr);
    return;
  }

  if ((U == 1) && (op == 5)) {
    // Format(instr, "vnot 'vd, 'vn");
    for (int i = 0; i < 2; i++) {
      set_vregisterd(vd, i, ~get_vregisterd(vn, i));
    }
  } else if ((U == 0) && (op == 0xf)) {
    if (sz == 2) {
      // Format(instr, "vabss 'vd, 'vn");
      for (int i = 0; i < 4; i++) {
        const int32_t vn_val = get_vregisters(vn, i);
        const float vn_flt = bit_cast<float, int32_t>(vn_val);
        set_vregisters(vd, i, bit_cast<int32_t, float>(fabsf(vn_flt)));
      }
    } else if (sz == 3) {
      // Format(instr, "vabsd 'vd, 'vn");
      for (int i = 0; i < 2; i++) {
        const int64_t vn_val = get_vregisterd(vn, i);
        const double vn_dbl = bit_cast<double, int64_t>(vn_val);
        set_vregisterd(vd, i, bit_cast<int64_t, double>(fabs(vn_dbl)));
      }
    } else {
      UnimplementedInstruction(instr);
    }
  } else if ((U == 1) && (op == 0xf)) {
    if (sz == 2) {
      // Format(instr, "vnegs 'vd, 'vn");
      for (int i = 0; i < 4; i++) {
        const int32_t vn_val = get_vregisters(vn, i);
        const float vn_flt = bit_cast<float, int32_t>(vn_val);
        set_vregisters(vd, i, bit_cast<int32_t, float>(-vn_flt));
      }
    } else if (sz == 3) {
      // Format(instr, "vnegd 'vd, 'vn");
      for (int i = 0; i < 2; i++) {
        const int64_t vn_val = get_vregisterd(vn, i);
        const double vn_dbl = bit_cast<double, int64_t>(vn_val);
        set_vregisterd(vd, i, bit_cast<int64_t, double>(-vn_dbl));
      }
    } else {
      UnimplementedInstruction(instr);
    }
  } else if ((U == 1) && (op == 0x1f)) {
    if (sz == 2) {
      // Format(instr, "vsqrts 'vd, 'vn");
      for (int i = 0; i < 4; i++) {
        const int32_t vn_val = get_vregisters(vn, i);
        const float vn_flt = bit_cast<float, int32_t>(vn_val);
        set_vregisters(vd, i, bit_cast<int32_t, float>(sqrtf(vn_flt)));
      }
    } else if (sz == 3) {
      // Format(instr, "vsqrtd 'vd, 'vn");
      for (int i = 0; i < 2; i++) {
        const int64_t vn_val = get_vregisterd(vn, i);
        const double vn_dbl = bit_cast<double, int64_t>(vn_val);
        set_vregisterd(vd, i, bit_cast<int64_t, double>(sqrt(vn_dbl)));
      }
    } else {
      UnimplementedInstruction(instr);
    }
  } else if ((U == 0) && (op == 0x1d)) {
    if (sz != 2) {
      UnimplementedInstruction(instr);
      return;
    }
    // Format(instr, "vrecpes 'vd, 'vn");
    for (int i = 0; i < 4; i++) {
      const int32_t vn_val = get_vregisters(vn, i);
      const float vn_flt = bit_cast<float, int32_t>(vn_val);
      const float re = arm_recip_estimate(vn_flt);
      set_vregisters(vd, i, bit_cast<int32_t, float>(re));
    }
  } else if ((U == 1) && (op == 0x1d)) {
    if (sz != 2) {
      UnimplementedInstruction(instr);
      return;
    }
    // Format(instr, "vrsqrtes 'vd, 'vn");
    for (int i = 0; i < 4; i++) {
      const int32_t vn_val = get_vregisters(vn, i);
      const float vn_flt = bit_cast<float, int32_t>(vn_val);
      const float re = arm_reciprocal_sqrt_estimate(vn_flt);
      set_vregisters(vd, i, bit_cast<int32_t, float>(re));
    }
  } else {
    UnimplementedInstruction(instr);
  }
}

void Simulator::DecodeDPSimd1(Instr* instr) {
  if (instr->IsSIMDCopyOp()) {
    DecodeSIMDCopy(instr);
  } else if (instr->IsSIMDThreeSameOp()) {
    DecodeSIMDThreeSame(instr);
  } else if (instr->IsSIMDTwoRegOp()) {
    DecodeSIMDTwoReg(instr);
  } else {
    UnimplementedInstruction(instr);
  }
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
    set_vregisterd(vd, 0, immd);
    set_vregisterd(vd, 1, 0);
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

  if (instr->Bit(29) != 0) {
    UnimplementedInstruction(instr);
    return;
  }

  if ((instr->SFField() == 0) && (instr->Bits(22, 2) == 0)) {
    if (instr->Bits(16, 5) == 6) {
      // Format(instr, "fmovrs'sf 'rd, 'vn");
      const int32_t vn_val = get_vregisters(vn, 0);
      set_wregister(rd, vn_val, R31IsZR);
    } else if (instr->Bits(16, 5) == 7) {
      // Format(instr, "fmovsr'sf 'vd, 'rn");
      const int32_t rn_val = get_wregister(rn, R31IsZR);
      set_vregisters(vd, 0, rn_val);
      set_vregisters(vd, 1, 0);
      set_vregisters(vd, 2, 0);
      set_vregisters(vd, 3, 0);
    } else {
      UnimplementedInstruction(instr);
    }
  } else if (instr->Bits(22, 2) == 1) {
    if (instr->Bits(16, 5) == 2) {
      // Format(instr, "scvtfd'sf 'vd, 'rn");
      const int64_t rn_val64 = get_register(rn, instr->RnMode());
      const int32_t rn_val32 = get_wregister(rn, instr->RnMode());
      const double vn_dbl = (instr->SFField() == 1)
                                ? static_cast<double>(rn_val64)
                                : static_cast<double>(rn_val32);
      set_vregisterd(vd, 0, bit_cast<int64_t, double>(vn_dbl));
      set_vregisterd(vd, 1, 0);
    } else if (instr->Bits(16, 5) == 6) {
      // Format(instr, "fmovrd'sf 'rd, 'vn");
      const int64_t vn_val = get_vregisterd(vn, 0);
      set_register(instr, rd, vn_val, R31IsZR);
    } else if (instr->Bits(16, 5) == 7) {
      // Format(instr, "fmovdr'sf 'vd, 'rn");
      const int64_t rn_val = get_register(rn, R31IsZR);
      set_vregisterd(vd, 0, rn_val);
      set_vregisterd(vd, 1, 0);
    } else if (instr->Bits(16, 5) == 24) {
      // Format(instr, "fcvtzds'sf 'rd, 'vn");
      const double vn_val = bit_cast<double, int64_t>(get_vregisterd(vn, 0));
      if (vn_val >= static_cast<double>(INT64_MAX)) {
        set_register(instr, rd, INT64_MAX, instr->RdMode());
      } else if (vn_val <= static_cast<double>(INT64_MIN)) {
        set_register(instr, rd, INT64_MIN, instr->RdMode());
      } else {
        set_register(instr, rd, static_cast<int64_t>(vn_val), instr->RdMode());
      }
    } else {
      UnimplementedInstruction(instr);
    }
  } else {
    UnimplementedInstruction(instr);
  }
}

void Simulator::DecodeFPOneSource(Instr* instr) {
  const int opc = instr->Bits(15, 6);
  const VRegister vd = instr->VdField();
  const VRegister vn = instr->VnField();
  const int64_t vn_val = get_vregisterd(vn, 0);
  const int32_t vn_val32 = vn_val & kWRegMask;
  const double vn_dbl = bit_cast<double, int64_t>(vn_val);
  const float vn_flt = bit_cast<float, int32_t>(vn_val32);

  if ((opc != 5) && (instr->Bit(22) != 1)) {
    // Source is interpreted as single-precision only if we're doing a
    // conversion from single -> double.
    UnimplementedInstruction(instr);
    return;
  }

  int64_t res_val = 0;
  switch (opc) {
    case 0:
      // Format("fmovdd 'vd, 'vn");
      res_val = get_vregisterd(vn, 0);
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
    case 4: {
      // Format(instr, "fcvtsd 'vd, 'vn");
      const uint32_t val =
          bit_cast<uint32_t, float>(static_cast<float>(vn_dbl));
      res_val = static_cast<int64_t>(val);
      break;
    }
    case 5:
      // Format(instr, "fcvtds 'vd, 'vn");
      res_val = bit_cast<int64_t, double>(static_cast<double>(vn_flt));
      break;
    default:
      UnimplementedInstruction(instr);
      break;
  }

  set_vregisterd(vd, 0, res_val);
  set_vregisterd(vd, 1, 0);
}

void Simulator::DecodeFPTwoSource(Instr* instr) {
  if (instr->Bits(22, 2) != 1) {
    UnimplementedInstruction(instr);
    return;
  }
  const VRegister vd = instr->VdField();
  const VRegister vn = instr->VnField();
  const VRegister vm = instr->VmField();
  const double vn_val = bit_cast<double, int64_t>(get_vregisterd(vn, 0));
  const double vm_val = bit_cast<double, int64_t>(get_vregisterd(vm, 0));
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
      UnimplementedInstruction(instr);
      return;
  }

  set_vregisterd(vd, 0, bit_cast<int64_t, double>(result));
  set_vregisterd(vd, 1, 0);
}

void Simulator::DecodeFPCompare(Instr* instr) {
  const VRegister vn = instr->VnField();
  const VRegister vm = instr->VmField();
  const double vn_val = bit_cast<double, int64_t>(get_vregisterd(vn, 0));
  double vm_val;

  if ((instr->Bit(22) == 1) && (instr->Bits(3, 2) == 0)) {
    // Format(instr, "fcmpd 'vn, 'vm");
    vm_val = bit_cast<double, int64_t>(get_vregisterd(vm, 0));
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
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    const uword start = reinterpret_cast<uword>(instr);
    const uword end = start + Instr::kInstrSize;
    if (FLAG_support_disassembler) {
      Disassembler::Disassemble(start, end);
    } else {
      THR_Print("Disassembler not supported in this mode.\n");
    }
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

  if (FLAG_stop_sim_at == ULLONG_MAX) {
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
    // we reach the particular instruction count or address.
    while (program_counter != kEndSimulatingPC) {
      Instr* instr = reinterpret_cast<Instr*>(program_counter);
      icount_++;
      if (icount_ == FLAG_stop_sim_at) {
        SimulatorDebugger dbg(this);
        dbg.Stop(instr, "Instruction count reached");
      } else if (reinterpret_cast<uint64_t>(instr) == FLAG_stop_sim_at) {
        SimulatorDebugger dbg(this);
        dbg.Stop(instr, "Instruction address reached");
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
  const intptr_t sp_before_call = get_register(R31, R31IsSP);

  // Setup parameters.
  if (fp_args) {
    set_vregisterd(V0, 0, parameter0);
    set_vregisterd(V0, 1, 0);
    set_vregisterd(V1, 0, parameter1);
    set_vregisterd(V1, 1, 0);
    set_vregisterd(V2, 0, parameter2);
    set_vregisterd(V2, 1, 0);
    set_vregisterd(V3, 0, parameter3);
    set_vregisterd(V3, 1, 0);
  } else {
    set_register(NULL, R0, parameter0);
    set_register(NULL, R1, parameter1);
    set_register(NULL, R2, parameter2);
    set_register(NULL, R3, parameter3);
  }

  // Make sure the activation frames are properly aligned.
  intptr_t stack_pointer = sp_before_call;
  if (OS::ActivationFrameAlignment() > 1) {
    stack_pointer =
        Utils::RoundDown(stack_pointer, OS::ActivationFrameAlignment());
  }
  set_register(NULL, R31, stack_pointer, R31IsSP);

  // Prepare to execute the code at entry.
  set_pc(entry);
  // Put down marker for end of simulation. The simulator will stop simulation
  // when the PC reaches this value. By saving the "end simulation" value into
  // the LR the simulation stops when returning to this call point.
  set_register(NULL, LR, kEndSimulatingPC);

  // Remember the values of callee-saved registers, and set them up with a
  // known value so that we are able to check that they are preserved
  // properly across Dart execution.
  int64_t preserved_vals[kAbiPreservedCpuRegCount];
  const double dicount = static_cast<double>(icount_);
  const int64_t callee_saved_value = bit_cast<int64_t, double>(dicount);
  for (int i = kAbiFirstPreservedCpuReg; i <= kAbiLastPreservedCpuReg; i++) {
    const Register r = static_cast<Register>(i);
    preserved_vals[i - kAbiFirstPreservedCpuReg] = get_register(r);
    set_register(NULL, r, callee_saved_value);
  }

  // Only the bottom half of the V registers must be preserved.
  int64_t preserved_dvals[kAbiPreservedFpuRegCount];
  for (int i = kAbiFirstPreservedFpuReg; i <= kAbiLastPreservedFpuReg; i++) {
    const VRegister r = static_cast<VRegister>(i);
    preserved_dvals[i - kAbiFirstPreservedFpuReg] = get_vregisterd(r, 0);
    set_vregisterd(r, 0, callee_saved_value);
    set_vregisterd(r, 1, 0);
  }

  // Start the simulation.
  Execute();

  // Check that the callee-saved registers have been preserved,
  // and restore them with the original value.
  for (int i = kAbiFirstPreservedCpuReg; i <= kAbiLastPreservedCpuReg; i++) {
    const Register r = static_cast<Register>(i);
    ASSERT(callee_saved_value == get_register(r));
    set_register(NULL, r, preserved_vals[i - kAbiFirstPreservedCpuReg]);
  }

  for (int i = kAbiFirstPreservedFpuReg; i <= kAbiLastPreservedFpuReg; i++) {
    const VRegister r = static_cast<VRegister>(i);
    ASSERT(callee_saved_value == get_vregisterd(r, 0));
    set_vregisterd(r, 0, preserved_dvals[i - kAbiFirstPreservedFpuReg]);
    set_vregisterd(r, 1, 0);
  }

  // Restore the SP register and return R0.
  set_register(NULL, R31, sp_before_call, R31IsSP);
  int64_t return_value;
  if (fp_return) {
    return_value = get_vregisterd(V0, 0);
  } else {
    return_value = get_register(R0);
  }
  return return_value;
}

void Simulator::JumpToFrame(uword pc, uword sp, uword fp, Thread* thread) {
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
  StackResource::Unwind(thread);

  // Unwind the C++ stack and continue simulation in the target frame.
  set_pc(static_cast<int64_t>(pc));
  set_register(NULL, SP, static_cast<int64_t>(sp));
  set_register(NULL, FP, static_cast<int64_t>(fp));
  set_register(NULL, THR, reinterpret_cast<int64_t>(thread));
  // Set the tag.
  thread->set_vm_tag(VMTag::kDartTagId);
  // Clear top exit frame.
  thread->set_top_exit_frame_info(0);
  // Restore pool pointer.
  int64_t code =
      *reinterpret_cast<int64_t*>(fp + kPcMarkerSlotFromFp * kWordSize);
  int64_t pp = *reinterpret_cast<int64_t*>(code + Code::object_pool_offset() -
                                           kHeapObjectTag);
  pp -= kHeapObjectTag;  // In the PP register, the pool pointer is untagged.
  set_register(NULL, CODE_REG, code);
  set_register(NULL, PP, pp);
  buf->Longjmp();
}

}  // namespace dart

#endif  // !defined(USING_SIMULATOR)

#endif  // defined TARGET_ARCH_ARM64
