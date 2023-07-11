// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <setjmp.h>  // NOLINT
#include <stdlib.h>

#include "vm/globals.h"
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

// Only build the simulator if not compiling for real RISCV hardware.
#if defined(USING_SIMULATOR)

#include "vm/simulator.h"

#include "vm/compiler/assembler/disassembler.h"
#include "vm/constants.h"
#include "vm/image_snapshot.h"
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
    sp_ = static_cast<uword>(sim->get_register(SP));
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

// When the generated code calls an external reference we need to catch that in
// the simulator.  The external reference will be a function compiled for the
// host architecture.  We need to call that function instead of trying to
// execute it with the simulator.  We do that by redirecting the external
// reference to a svc (supervisor call) instruction that is handled by
// the simulator.  We write the original destination of the jump just at a known
// offset from the svc instruction so the simulator knows what to call.
class Redirection {
 public:
  uword address_of_ecall_instruction() {
    return reinterpret_cast<uword>(&ecall_instruction_);
  }

  uword external_function() const { return external_function_; }

  Simulator::CallKind call_kind() const { return call_kind_; }

  int argument_count() const { return argument_count_; }

  static Redirection* Get(uword external_function,
                          Simulator::CallKind call_kind,
                          int argument_count) {
    MutexLocker ml(mutex_);

    Redirection* old_head = list_.load(std::memory_order_relaxed);
    for (Redirection* current = old_head; current != nullptr;
         current = current->next_) {
      if (current->external_function_ == external_function) return current;
    }

    Redirection* redirection =
        new Redirection(external_function, call_kind, argument_count);
    redirection->next_ = old_head;

    // Use a memory fence to ensure all pending writes are written at the time
    // of updating the list head, so the profiling thread always has a valid
    // list to look at.
    list_.store(redirection, std::memory_order_release);

    return redirection;
  }

  static Redirection* FromECallInstruction(uintx_t ecall_instruction) {
    char* addr_of_ecall = reinterpret_cast<char*>(ecall_instruction);
    char* addr_of_redirection =
        addr_of_ecall - OFFSET_OF(Redirection, ecall_instruction_);
    return reinterpret_cast<Redirection*>(addr_of_redirection);
  }

  // Please note that this function is called by the signal handler of the
  // profiling thread.  It can therefore run at any point in time and is not
  // allowed to hold any locks - which is precisely the reason why the list is
  // prepend-only and a memory fence is used when writing the list head [list_]!
  static uword FunctionForRedirect(uword address_of_ecall) {
    for (Redirection* current = list_.load(std::memory_order_acquire);
         current != nullptr; current = current->next_) {
      if (current->address_of_ecall_instruction() == address_of_ecall) {
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
        ecall_instruction_(Instr::kSimulatorRedirectInstruction),
        next_(nullptr) {}

  uword external_function_;
  Simulator::CallKind call_kind_;
  int argument_count_;
  uint32_t ecall_instruction_;
  Redirection* next_;
  static std::atomic<Redirection*> list_;
  static Mutex* mutex_;
};

std::atomic<Redirection*> Redirection::list_ = {nullptr};
Mutex* Redirection::mutex_ = new Mutex();

uword Simulator::RedirectExternalReference(uword function,
                                           CallKind call_kind,
                                           int argument_count) {
  Redirection* redirection =
      Redirection::Get(function, call_kind, argument_count);
  return redirection->address_of_ecall_instruction();
}

uword Simulator::FunctionForRedirect(uword redirect) {
  return Redirection::FunctionForRedirect(redirect);
}

// Get the active Simulator for the current isolate.
Simulator* Simulator::Current() {
  Isolate* isolate = Isolate::Current();
  Simulator* simulator = isolate->simulator();
  if (simulator == nullptr) {
    NoSafepointScope no_safepoint;
    simulator = new Simulator();
    isolate->set_simulator(simulator);
  }
  return simulator;
}

void Simulator::Init() {}

Simulator::Simulator()
    : pc_(0),
      instret_(0),
      reserved_address_(0),
      reserved_value_(0),
      fcsr_(0),
      random_(),
      last_setjmp_buffer_(nullptr) {
  // Setup simulator support first. Some of this information is needed to
  // setup the architecture state.
  // We allocate the stack here, the size is computed as the sum of
  // the size specified by the user and the buffer space needed for
  // handling stack overflow exceptions. To be safe in potential
  // stack underflows we also add some underflow buffer space.
  stack_ =
      new char[(OSThread::GetSpecifiedStackSize() +
                OSThread::kStackSizeBufferMax + kSimulatorStackUnderflowSize)];
  // Low address.
  stack_limit_ = reinterpret_cast<uword>(stack_);
  // Limit for StackOverflowError.
  overflow_stack_limit_ = stack_limit_ + OSThread::kStackSizeBufferMax;
  // High address.
  stack_base_ = overflow_stack_limit_ + OSThread::GetSpecifiedStackSize();

  // Setup architecture state.
  xregs_[0] = 0;
  for (intptr_t i = 1; i < kNumberOfCpuRegisters; i++) {
    xregs_[i] = random_.NextUInt64();
  }
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    // TODO(riscv): This generates values that are very wide when printed,
    // making it hard to read register state. Maybe generate random values in
    // the unit interval instead?
    // fregs_[i] = bit_cast<double>(random_.NextUInt64());
    fregs_[i] = bit_cast<double>(kNaNBox);
  }

  // The sp is initialized to point to the bottom (high address) of the
  // allocated stack area.
  set_xreg(SP, stack_base());
  // The lr and pc are initialized to a known bad value that will cause an
  // access violation if the simulator ever tries to execute it.
  set_xreg(RA, kBadLR);
  pc_ = kBadLR;
}

Simulator::~Simulator() {
  delete[] stack_;
  Isolate* isolate = Isolate::Current();
  if (isolate != nullptr) {
    isolate->set_simulator(nullptr);
  }
}

void Simulator::PrepareCall(PreservedRegisters* preserved) {
#if defined(DEBUG)
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    preserved->xregs[i] = xregs_[i];
    if ((kAbiVolatileCpuRegs & (1 << i)) != 0) {
      xregs_[i] = random_.NextUInt64();
    }
  }
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    preserved->fregs[i] = fregs_[i];
    if ((kAbiVolatileFpuRegs & (1 << i)) != 0) {
      // TODO(riscv): This generates values that are very wide when printed,
      // making it hard to read register state. Maybe generate random values in
      // the unit interval instead?
      // fregs_[i] = bit_cast<double>(random_.NextUInt64());
      fregs_[i] = bit_cast<double>(kNaNBox);
    }
  }
#endif
}

void Simulator::ClobberVolatileRegisters() {
#if defined(DEBUG)
  reserved_address_ = reserved_value_ = 0;  // Clear atomic reservation.
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    if ((kAbiVolatileCpuRegs & (1 << i)) != 0) {
      xregs_[i] = random_.NextUInt64();
    }
  }
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    if ((kAbiVolatileFpuRegs & (1 << i)) != 0) {
      // TODO(riscv): This generates values that are very wide when printed,
      // making it hard to read register state. Maybe generate random values in
      // the unit interval instead?
      // fregs_[i] = bit_cast<double>(random_.NextUInt64());
      fregs_[i] = bit_cast<double>(kNaNBox);
    }
  }
#endif
}

void Simulator::SavePreservedRegisters(PreservedRegisters* preserved) {
#if defined(DEBUG)
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    preserved->xregs[i] = xregs_[i];
  }
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    preserved->fregs[i] = fregs_[i];
  }
#endif
}

void Simulator::CheckPreservedRegisters(PreservedRegisters* preserved) {
#if defined(DEBUG)
  if (preserved->xregs[SP] != xregs_[SP]) {
    PrintRegisters();
    PrintStack();
    FATAL("Stack unbalanced");
  }
  const intptr_t kPreservedAtCall =
      kAbiPreservedCpuRegs | (1 << TP) | (1 << GP) | (1 << SP) | (1 << FP);
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    if ((kPreservedAtCall & (1 << i)) != 0) {
      if (preserved->xregs[i] != xregs_[i]) {
        FATAL("%s was not preserved\n", cpu_reg_names[i]);
      }
    }
  }
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    if ((kAbiVolatileFpuRegs & (1 << i)) == 0) {
      if (bit_cast<uint64_t>(preserved->fregs[i]) !=
          bit_cast<uint64_t>(fregs_[i])) {
        FATAL("%s was not preserved\n", fpu_reg_names[i]);
      }
    }
  }
#endif
}

void Simulator::RunCall(intx_t entry, PreservedRegisters* preserved) {
  pc_ = entry;
  set_xreg(RA, kEndSimulatingPC);
  Execute();
  CheckPreservedRegisters(preserved);
}

int64_t Simulator::Call(intx_t entry,
                        intx_t parameter0,
                        intx_t parameter1,
                        intx_t parameter2,
                        intx_t parameter3,
                        bool fp_return,
                        bool fp_args) {
  // Save the SP register before the call so we can restore it.
  const intptr_t sp_before_call = get_xreg(SP);

  // Setup parameters.
  if (fp_args) {
    set_fregd(FA0, parameter0);
    set_fregd(FA1, parameter1);
    set_fregd(FA2, parameter2);
    set_fregd(FA3, parameter3);
  } else {
    set_xreg(A0, parameter0);
    set_xreg(A1, parameter1);
    set_xreg(A2, parameter2);
    set_xreg(A3, parameter3);
  }

  // Make sure the activation frames are properly aligned.
  intptr_t stack_pointer = sp_before_call;
  if (OS::ActivationFrameAlignment() > 1) {
    stack_pointer =
        Utils::RoundDown(stack_pointer, OS::ActivationFrameAlignment());
  }
  set_xreg(SP, stack_pointer);

  // Prepare to execute the code at entry.
  pc_ = entry;
  // Put down marker for end of simulation. The simulator will stop simulation
  // when the PC reaches this value. By saving the "end simulation" value into
  // the LR the simulation stops when returning to this call point.
  set_xreg(RA, kEndSimulatingPC);

  // Remember the values of callee-saved registers, and set them up with a
  // known value so that we are able to check that they are preserved
  // properly across Dart execution.
  PreservedRegisters preserved;
  SavePreservedRegisters(&preserved);

  // Start the simulation.
  Execute();

  // Check that the callee-saved registers have been preserved,
  // and restore them with the original value.
  CheckPreservedRegisters(&preserved);

  // Restore the SP register and return R0.
  set_xreg(SP, sp_before_call);
  int64_t return_value;
  if (fp_return) {
    return_value = get_fregd(FA0);
  } else {
    return_value = get_xreg(A0);
  }
  return return_value;
}

void Simulator::Execute() {
  if (LIKELY(FLAG_trace_sim_after == ULLONG_MAX)) {
    ExecuteNoTrace();
  } else {
    ExecuteTrace();
  }
}

void Simulator::ExecuteNoTrace() {
  while (pc_ != kEndSimulatingPC) {
    uint16_t parcel = *reinterpret_cast<uint16_t*>(pc_);
    if (IsCInstruction(parcel)) {
      CInstr instr(parcel);
      Interpret(instr);
    } else {
      Instr instr(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)));
      Interpret(instr);
    }
    instret_++;
  }
}

void Simulator::ExecuteTrace() {
  while (pc_ != kEndSimulatingPC) {
    uint16_t parcel = *reinterpret_cast<uint16_t*>(pc_);
    if (IsCInstruction(parcel)) {
      CInstr instr(parcel);
      if (IsTracingExecution()) {
        Disassembler::Disassemble(pc_, pc_ + instr.length());
      }
      Interpret(instr);
    } else {
      Instr instr(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)));
      if (IsTracingExecution()) {
        Disassembler::Disassemble(pc_, pc_ + instr.length());
      }
      Interpret(instr);
    }
    instret_++;
  }
}

bool Simulator::IsTracingExecution() const {
  return instret_ > FLAG_trace_sim_after;
}

void Simulator::JumpToFrame(uword pc, uword sp, uword fp, Thread* thread) {
  // Walk over all setjmp buffers (simulated --> C++ transitions)
  // and try to find the setjmp associated with the simulated stack pointer.
  SimulatorSetjmpBuffer* buf = last_setjmp_buffer();
  while (buf->link() != nullptr && buf->link()->sp() <= sp) {
    buf = buf->link();
  }
  ASSERT(buf != nullptr);

  // The C++ caller has not cleaned up the stack memory of C++ frames.
  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous C++ frames.
  StackResource::Unwind(thread);

  // Keep the following code in sync with `StubCode::JumpToFrameStub()`.

  // Unwind the C++ stack and continue simulation in the target frame.
  pc_ = pc;
  set_xreg(SP, static_cast<uintx_t>(sp));
  set_xreg(FP, static_cast<uintx_t>(fp));
  set_xreg(THR, reinterpret_cast<uintx_t>(thread));
#if defined(DART_TARGET_OS_FUCHSIA) || defined(DART_TARGET_OS_ANDROID)
  set_xreg(GP, thread->saved_shadow_call_stack());
#endif
  // Set the tag.
  thread->set_vm_tag(VMTag::kDartTagId);
  // Clear top exit frame.
  thread->set_top_exit_frame_info(0);
  // Restore pool pointer.
  uintx_t code =
      *reinterpret_cast<uintx_t*>(fp + kPcMarkerSlotFromFp * kWordSize);
  uintx_t pp = FLAG_precompiled_mode
                   ? static_cast<uintx_t>(thread->global_object_pool())
                   : *reinterpret_cast<uintx_t*>(
                         code + Code::object_pool_offset() - kHeapObjectTag);
  pp -= kHeapObjectTag;  // In the PP register, the pool pointer is untagged.
  set_xreg(CODE_REG, code);
  set_xreg(PP, pp);
  set_xreg(WRITE_BARRIER_STATE,
           thread->write_barrier_mask() ^
               ((UntaggedObject::kGenerationalBarrierMask << 1) - 1));
  set_xreg(NULL_REG, static_cast<uintx_t>(Object::null()));
  if (FLAG_precompiled_mode) {
    set_xreg(DISPATCH_TABLE_REG,
             reinterpret_cast<uintx_t>(thread->dispatch_table_array()));
  }

  buf->Longjmp();
}

void Simulator::PrintRegisters() {
  ASSERT(static_cast<intptr_t>(kNumberOfCpuRegisters) ==
         static_cast<intptr_t>(kNumberOfFpuRegisters));
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
#if XLEN == 32
    OS::Print("%4s: %8x %11d", cpu_reg_names[i], xregs_[i], xregs_[i]);
#elif XLEN == 64
    OS::Print("%4s: %16" Px64 " %20" Pd64, cpu_reg_names[i], xregs_[i],
              xregs_[i]);
#endif
    OS::Print("  %4s: %lf\n", fpu_reg_names[i], fregs_[i]);
  }
#if XLEN == 32
  OS::Print("  pc: %8x\n", pc_);
#elif XLEN == 64
  OS::Print("  pc: %16" Px64 "\n", pc_);
#endif
}

void Simulator::PrintStack() {
  StackFrameIterator frames(get_register(FP), get_register(SP), get_pc(),
                            ValidationPolicy::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != nullptr) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame = frames.NextFrame();
  }
}

DART_FORCE_INLINE
void Simulator::Interpret(Instr instr) {
  switch (instr.opcode()) {
    case LUI:
      InterpretLUI(instr);
      break;
    case AUIPC:
      InterpretAUIPC(instr);
      break;
    case JAL:
      InterpretJAL(instr);
      break;
    case JALR:
      InterpretJALR(instr);
      break;
    case BRANCH:
      InterpretBRANCH(instr);
      break;
    case LOAD:
      InterpretLOAD(instr);
      break;
    case STORE:
      InterpretSTORE(instr);
      break;
    case OPIMM:
      InterpretOPIMM(instr);
      break;
    case OPIMM32:
      InterpretOPIMM32(instr);
      break;
    case OP:
      InterpretOP(instr);
      break;
    case OP32:
      InterpretOP32(instr);
      break;
    case MISCMEM:
      InterpretMISCMEM(instr);
      break;
    case SYSTEM:
      InterpretSYSTEM(instr);
      break;
    case AMO:
      InterpretAMO(instr);
      break;
    case LOADFP:
      InterpretLOADFP(instr);
      break;
    case STOREFP:
      InterpretSTOREFP(instr);
      break;
    case FMADD:
      InterpretFMADD(instr);
      break;
    case FMSUB:
      InterpretFMSUB(instr);
      break;
    case FNMADD:
      InterpretFNMADD(instr);
      break;
    case FNMSUB:
      InterpretFNMSUB(instr);
      break;
    case OPFP:
      InterpretOPFP(instr);
      break;
    default:
      IllegalInstruction(instr);
  }
}

DART_FORCE_INLINE
void Simulator::Interpret(CInstr instr) {
  switch (instr.opcode()) {
    case C_LWSP: {
      uintx_t addr = get_xreg(SP) + instr.spload4_imm();
      set_xreg(instr.rd(), MemoryRead<int32_t>(addr, SP));
      break;
    }
#if XLEN == 32
    case C_FLWSP: {
      uintx_t addr = get_xreg(SP) + instr.spload4_imm();
      set_fregs(instr.frd(), MemoryRead<float>(addr, SP));
      break;
    }
#else
    case C_LDSP: {
      uintx_t addr = get_xreg(SP) + instr.spload8_imm();
      set_xreg(instr.rd(), MemoryRead<int64_t>(addr, SP));
      break;
    }
#endif
    case C_FLDSP: {
      uintx_t addr = get_xreg(SP) + instr.spload8_imm();
      set_fregd(instr.frd(), MemoryRead<double>(addr, SP));
      break;
    }
    case C_SWSP: {
      uintx_t addr = get_xreg(SP) + instr.spstore4_imm();
      MemoryWrite<uint32_t>(addr, get_xreg(instr.rs2()), SP);
      break;
    }
#if XLEN == 32
    case C_FSWSP: {
      uintx_t addr = get_xreg(SP) + instr.spstore4_imm();
      MemoryWrite<float>(addr, get_fregs(instr.frs2()), SP);
      break;
    }
#else
    case C_SDSP: {
      uintx_t addr = get_xreg(SP) + instr.spstore8_imm();
      MemoryWrite<uint64_t>(addr, get_xreg(instr.rs2()), SP);
      break;
    }
#endif
    case C_FSDSP: {
      uintx_t addr = get_xreg(SP) + instr.spstore8_imm();
      MemoryWrite<double>(addr, get_fregd(instr.frs2()), SP);
      break;
    }
    case C_LW: {
      uintx_t addr = get_xreg(instr.rs1p()) + instr.mem4_imm();
      set_xreg(instr.rdp(), MemoryRead<int32_t>(addr, instr.rs1p()));
      break;
    }
#if XLEN == 32
    case C_FLW: {
      uintx_t addr = get_xreg(instr.rs1p()) + instr.mem4_imm();
      set_fregs(instr.frdp(), MemoryRead<float>(addr, instr.rs1p()));
      break;
    }
#else
    case C_LD: {
      uintx_t addr = get_xreg(instr.rs1p()) + instr.mem8_imm();
      set_xreg(instr.rdp(), MemoryRead<int64_t>(addr, instr.rs1p()));
      break;
    }
#endif
    case C_FLD: {
      uintx_t addr = get_xreg(instr.rs1p()) + instr.mem8_imm();
      set_fregd(instr.frdp(), MemoryRead<double>(addr, instr.rs1p()));
      break;
    }
    case C_SW: {
      uintx_t addr = get_xreg(instr.rs1p()) + instr.mem4_imm();
      MemoryWrite<uint32_t>(addr, get_xreg(instr.rs2p()), instr.rs1p());
      break;
    }
#if XLEN == 32
    case C_FSW: {
      uintx_t addr = get_xreg(instr.rs1p()) + instr.mem4_imm();
      MemoryWrite<float>(addr, get_fregs(instr.frs2p()), instr.rs1p());
      break;
    }
#else
    case C_SD: {
      uintx_t addr = get_xreg(instr.rs1p()) + instr.mem8_imm();
      MemoryWrite<uint64_t>(addr, get_xreg(instr.rs2p()), instr.rs1p());
      break;
    }
#endif
    case C_FSD: {
      uintx_t addr = get_xreg(instr.rs1p()) + instr.mem8_imm();
      MemoryWrite<double>(addr, get_fregd(instr.frs2p()), instr.rs1p());
      break;
    }
    case C_J: {
      pc_ += sign_extend((int32_t)instr.j_imm());
      return;
    }
#if XLEN == 32
    case C_JAL: {
      set_xreg(RA, pc_ + instr.length());
      pc_ += sign_extend((int32_t)instr.j_imm());
      return;
    }
#endif
    case C_JR: {
      if ((instr.encoding() & (C_JALR ^ C_JR)) != 0) {
        if ((instr.rs1() == ZR) && (instr.rs2() == ZR)) {
          InterpretEBREAK(instr);
        } else if (instr.rs2() == ZR) {
          // JALR
          uintx_t target = get_xreg(instr.rs1());
          set_xreg(RA, pc_ + instr.length());
          pc_ = target;
          return;
        } else {
          // ADD
          set_xreg(instr.rd(), get_xreg(instr.rs1()) + get_xreg(instr.rs2()));
        }
      } else {
        if ((instr.rd() != ZR) && (instr.rs2() != ZR)) {
          // MV
          set_xreg(instr.rd(), get_xreg(instr.rs2()));
        } else if (instr.rs2() != ZR) {
          IllegalInstruction(instr);
        } else {
          // JR
          pc_ = get_xreg(instr.rs1());
          return;
        }
      }
      break;
    }
    case C_BEQZ:
      if (get_xreg(instr.rs1p()) == 0) {
        pc_ += instr.b_imm();
        return;
      }
      break;
    case C_BNEZ:
      if (get_xreg(instr.rs1p()) != 0) {
        pc_ += instr.b_imm();
        return;
      }
      break;
    case C_LI:
      if (instr.rd() == ZR) {
        IllegalInstruction(instr);
      } else {
        set_xreg(instr.rd(), sign_extend(instr.i_imm()));
      }
      break;
    case C_LUI:
      if (instr.rd() == SP) {
        if (instr.i16_imm() == 0) {
          IllegalInstruction(instr);
        } else {
          set_xreg(instr.rd(),
                   get_xreg(instr.rs1()) + sign_extend(instr.i16_imm()));
        }
      } else if ((instr.rd() == ZR) || (instr.u_imm() == 0)) {
        IllegalInstruction(instr);
      } else {
        set_xreg(instr.rd(), sign_extend(instr.u_imm()));
      }
      break;
    case C_ADDI:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) + instr.i_imm());
      break;
#if XLEN >= 64
    case C_ADDIW: {
      uint32_t a = get_xreg(instr.rs1());
      uint32_t b = instr.i_imm();
      set_xreg(instr.rd(), sign_extend(a + b));
      break;
    }
#endif  // XLEN >= 64
    case C_ADDI4SPN:
      if (instr.i4spn_imm() == 0) {
        IllegalInstruction(instr);
      } else {
        set_xreg(instr.rdp(), get_xreg(SP) + instr.i4spn_imm());
      }
      break;
    case C_SLLI:
      if (instr.i_imm() == 0) {
        IllegalInstruction(instr);
      } else {
        set_xreg(instr.rd(), get_xreg(instr.rs1())
                                 << (instr.i_imm() & (XLEN - 1)));
      }
      break;
    case C_MISCALU:
      // Note MISCALU has a different notion of rsd′ than other instructions,
      // so use rs1′ instead.
      switch (instr.encoding() & C_MISCALU_MASK) {
        case C_SRLI:
          if (instr.i_imm() == 0) {
            IllegalInstruction(instr);
          } else {
            set_xreg(instr.rs1p(),
                     get_xreg(instr.rs1p()) >> (instr.i_imm() & (XLEN - 1)));
          }
          break;
        case C_SRAI:
          if (instr.i_imm() == 0) {
            IllegalInstruction(instr);
          } else {
            set_xreg(instr.rs1p(),
                     static_cast<intx_t>(get_xreg(instr.rs1p())) >>
                         (instr.i_imm() & (XLEN - 1)));
          }
          break;
        case C_ANDI:
          set_xreg(instr.rs1p(), get_xreg(instr.rs1p()) & instr.i_imm());
          break;
        case C_RR:
          switch (instr.encoding() & C_RR_MASK) {
            case C_AND:
              set_xreg(instr.rs1p(),
                       get_xreg(instr.rs1p()) & get_xreg(instr.rs2p()));
              break;
            case C_OR:
              set_xreg(instr.rs1p(),
                       get_xreg(instr.rs1p()) | get_xreg(instr.rs2p()));
              break;
            case C_XOR:
              set_xreg(instr.rs1p(),
                       get_xreg(instr.rs1p()) ^ get_xreg(instr.rs2p()));
              break;
            case C_SUB:
              set_xreg(instr.rs1p(),
                       get_xreg(instr.rs1p()) - get_xreg(instr.rs2p()));
              break;
            case C_ADDW: {
              uint32_t a = get_xreg(instr.rs1p());
              uint32_t b = get_xreg(instr.rs2p());
              set_xreg(instr.rs1p(), sign_extend(a + b));
              break;
            }
            case C_SUBW: {
              uint32_t a = get_xreg(instr.rs1p());
              uint32_t b = get_xreg(instr.rs2p());
              set_xreg(instr.rs1p(), sign_extend(a - b));
              break;
            }
            default:
              IllegalInstruction(instr);
          }
          break;
        default:
          IllegalInstruction(instr);
      }
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretLUI(Instr instr) {
  set_xreg(instr.rd(), sign_extend(instr.utype_imm()));
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretAUIPC(Instr instr) {
  set_xreg(instr.rd(), pc_ + sign_extend(instr.utype_imm()));
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretJAL(Instr instr) {
  set_xreg(instr.rd(), pc_ + instr.length());
  pc_ += sign_extend(instr.jtype_imm());
}

DART_FORCE_INLINE
void Simulator::InterpretJALR(Instr instr) {
  uintx_t base = get_xreg(instr.rs1());
  uintx_t offset = static_cast<uintx_t>(instr.itype_imm());
  set_xreg(instr.rd(), pc_ + instr.length());
  pc_ = base + offset;
}

DART_FORCE_INLINE
void Simulator::InterpretBRANCH(Instr instr) {
  switch (instr.funct3()) {
    case BEQ:
      if (get_xreg(instr.rs1()) == get_xreg(instr.rs2())) {
        pc_ += instr.btype_imm();
      } else {
        pc_ += instr.length();
      }
      break;
    case BNE:
      if (get_xreg(instr.rs1()) != get_xreg(instr.rs2())) {
        pc_ += instr.btype_imm();
      } else {
        pc_ += instr.length();
      }
      break;
    case BLT:
      if (static_cast<intx_t>(get_xreg(instr.rs1())) <
          static_cast<intx_t>(get_xreg(instr.rs2()))) {
        pc_ += instr.btype_imm();
      } else {
        pc_ += instr.length();
      }
      break;
    case BGE:
      if (static_cast<intx_t>(get_xreg(instr.rs1())) >=
          static_cast<intx_t>(get_xreg(instr.rs2()))) {
        pc_ += instr.btype_imm();
      } else {
        pc_ += instr.length();
      }
      break;
    case BLTU:
      if (static_cast<uintx_t>(get_xreg(instr.rs1())) <
          static_cast<uintx_t>(get_xreg(instr.rs2()))) {
        pc_ += instr.btype_imm();
      } else {
        pc_ += instr.length();
      }
      break;
    case BGEU:
      if (static_cast<uintx_t>(get_xreg(instr.rs1())) >=
          static_cast<uintx_t>(get_xreg(instr.rs2()))) {
        pc_ += instr.btype_imm();
      } else {
        pc_ += instr.length();
      }
      break;
    default:
      IllegalInstruction(instr);
  }
}

DART_FORCE_INLINE
void Simulator::InterpretLOAD(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1()) + instr.itype_imm();
  switch (instr.funct3()) {
    case LB:
      set_xreg(instr.rd(), MemoryRead<int8_t>(addr, instr.rs1()));
      break;
    case LH:
      set_xreg(instr.rd(), MemoryRead<int16_t>(addr, instr.rs1()));
      break;
    case LW:
      set_xreg(instr.rd(), MemoryRead<int32_t>(addr, instr.rs1()));
      break;
    case LBU:
      set_xreg(instr.rd(), MemoryRead<uint8_t>(addr, instr.rs1()));
      break;
    case LHU:
      set_xreg(instr.rd(), MemoryRead<uint16_t>(addr, instr.rs1()));
      break;
#if XLEN >= 64
    case LWU:
      set_xreg(instr.rd(), MemoryRead<uint32_t>(addr, instr.rs1()));
      break;
    case LD:
      set_xreg(instr.rd(), MemoryRead<int64_t>(addr, instr.rs1()));
      break;
#endif  // XLEN >= 64
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretLOADFP(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1()) + instr.itype_imm();
  switch (instr.funct3()) {
    case S:
      set_fregs(instr.frd(), MemoryRead<float>(addr, instr.rs1()));
      break;
    case D:
      set_fregd(instr.frd(), MemoryRead<double>(addr, instr.rs1()));
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretSTORE(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1()) + instr.stype_imm();
  switch (instr.funct3()) {
    case SB:
      MemoryWrite<uint8_t>(addr, get_xreg(instr.rs2()), instr.rs1());
      break;
    case SH:
      MemoryWrite<uint16_t>(addr, get_xreg(instr.rs2()), instr.rs1());
      break;
    case SW:
      MemoryWrite<uint32_t>(addr, get_xreg(instr.rs2()), instr.rs1());
      break;
#if XLEN >= 64
    case SD:
      MemoryWrite<uint64_t>(addr, get_xreg(instr.rs2()), instr.rs1());
      break;
#endif  // XLEN >= 64
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretSTOREFP(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1()) + instr.stype_imm();
  switch (instr.funct3()) {
    case S:
      MemoryWrite<float>(addr, get_fregs(instr.frs2()), instr.rs1());
      break;
    case D:
      MemoryWrite<double>(addr, get_fregd(instr.frs2()), instr.rs1());
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

static uintx_t clz(uintx_t a) {
  for (int bit = XLEN - 1; bit >= 0; bit--) {
    if ((a & (static_cast<uintx_t>(1) << bit)) != 0) {
      return XLEN - bit - 1;
    }
  }
  return XLEN;
}

static uintx_t ctz(uintx_t a) {
  for (int bit = 0; bit < XLEN; bit++) {
    if ((a & (static_cast<uintx_t>(1) << bit)) != 0) {
      return bit;
    }
  }
  return XLEN;
}

static uintx_t cpop(uintx_t a) {
  uintx_t count = 0;
  for (int bit = 0; bit < XLEN; bit++) {
    if ((a & (static_cast<uintx_t>(1) << bit)) != 0) {
      count++;
    }
  }
  return count;
}

static uintx_t clzw(uint32_t a) {
  for (int bit = 32 - 1; bit >= 0; bit--) {
    if ((a & (static_cast<uint32_t>(1) << bit)) != 0) {
      return 32 - bit - 1;
    }
  }
  return 32;
}

static uintx_t ctzw(uint32_t a) {
  for (int bit = 0; bit < 32; bit++) {
    if ((a & (static_cast<uint32_t>(1) << bit)) != 0) {
      return bit;
    }
  }
  return 32;
}

static uintx_t cpopw(uint32_t a) {
  uintx_t count = 0;
  for (int bit = 0; bit < 32; bit++) {
    if ((a & (static_cast<uint32_t>(1) << bit)) != 0) {
      count++;
    }
  }
  return count;
}

static intx_t max(intx_t a, intx_t b) {
  return a > b ? a : b;
}
static uintx_t maxu(uintx_t a, uintx_t b) {
  return a > b ? a : b;
}
static intx_t min(intx_t a, intx_t b) {
  return a < b ? a : b;
}
static uintx_t minu(uintx_t a, uintx_t b) {
  return a < b ? a : b;
}
static uintx_t clmul(uintx_t a, uintx_t b) {
  uintx_t result = 0;
  for (int bit = 0; bit < XLEN; bit++) {
    if (((b >> bit) & 1) != 0) {
      result ^= a << bit;
    }
  }
  return result;
}
static uintx_t clmulh(uintx_t a, uintx_t b) {
  uintx_t result = 0;
  for (int bit = 1; bit < XLEN; bit++) {
    if (((b >> bit) & 1) != 0) {
      result ^= a >> (XLEN - bit);
    }
  }
  return result;
}
static uintx_t clmulr(uintx_t a, uintx_t b) {
  uintx_t result = 0;
  for (int bit = 0; bit < XLEN; bit++) {
    if (((b >> bit) & 1) != 0) {
      result ^= a >> (XLEN - bit - 1);
    }
  }
  return result;
}
static uintx_t sextb(uintx_t a) {
  return static_cast<intx_t>(a << (XLEN - 8)) >> (XLEN - 8);
}
static uintx_t sexth(uintx_t a) {
  return static_cast<intx_t>(a << (XLEN - 16)) >> (XLEN - 16);
}
static uintx_t zexth(uintx_t a) {
  return a << (XLEN - 16) >> (XLEN - 16);
}
static uintx_t ror(uintx_t a, uintx_t b) {
  uintx_t r = b & (XLEN - 1);
  uintx_t l = (XLEN - r) & (XLEN - 1);
  return (a << l) | (a >> r);
}
static uintx_t rol(uintx_t a, uintx_t b) {
  uintx_t l = b & (XLEN - 1);
  uintx_t r = (XLEN - l) & (XLEN - 1);
  return (a << l) | (a >> r);
}
static uintx_t rorw(uintx_t a, uintx_t b) {
  uint32_t r = b & (XLEN - 1);
  uint32_t l = (XLEN - r) & (XLEN - 1);
  uint32_t x = a;
  return sign_extend((x << l) | (x >> r));
}
static uintx_t rolw(uintx_t a, uintx_t b) {
  uint32_t l = b & (XLEN - 1);
  uint32_t r = (XLEN - l) & (XLEN - 1);
  uint32_t x = a;
  return sign_extend((x << l) | (x >> r));
}
static uintx_t orcb(uintx_t a) {
  uintx_t result = 0;
  for (int shift = 0; shift < XLEN; shift += 8) {
    if (((a >> shift) & 0xFF) != 0) {
      result |= static_cast<uintx_t>(0xFF) << shift;
    }
  }
  return result;
}
static uintx_t rev8(uintx_t a) {
  uintx_t result = 0;
  for (int shift = 0; shift < XLEN; shift += 8) {
    result <<= 8;
    result |= (a >> shift) & 0xFF;
  }
  return result;
}
static uintx_t bclr(uintx_t a, uintx_t b) {
  return a & ~(static_cast<uintx_t>(1) << (b & (XLEN - 1)));
}
static uintx_t bext(uintx_t a, uintx_t b) {
  return (a >> (b & (XLEN - 1))) & 1;
}
static uintx_t binv(uintx_t a, uintx_t b) {
  return a ^ (static_cast<uintx_t>(1) << (b & (XLEN - 1)));
}
static uintx_t bset(uintx_t a, uintx_t b) {
  return a | (static_cast<uintx_t>(1) << (b & (XLEN - 1)));
}

DART_FORCE_INLINE
void Simulator::InterpretOPIMM(Instr instr) {
  switch (instr.funct3()) {
    case ADDI:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) + instr.itype_imm());
      break;
    case SLTI: {
      set_xreg(instr.rd(), static_cast<intx_t>(get_xreg(instr.rs1())) <
                                   static_cast<intx_t>(instr.itype_imm())
                               ? 1
                               : 0);
      break;
    }
    case SLTIU:
      set_xreg(instr.rd(), static_cast<uintx_t>(get_xreg(instr.rs1())) <
                                   static_cast<uintx_t>(instr.itype_imm())
                               ? 1
                               : 0);
      break;
    case XORI:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) ^ instr.itype_imm());
      break;
    case ORI:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) | instr.itype_imm());
      break;
    case ANDI:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) & instr.itype_imm());
      break;
    case SLLI:
      if (instr.funct7() == COUNT) {
        if (instr.shamt() == 0b00000) {
          set_xreg(instr.rd(), clz(get_xreg(instr.rs1())));
        } else if (instr.shamt() == 0b00001) {
          set_xreg(instr.rd(), ctz(get_xreg(instr.rs1())));
        } else if (instr.shamt() == 0b00010) {
          set_xreg(instr.rd(), cpop(get_xreg(instr.rs1())));
        } else if (instr.shamt() == 0b00100) {
          set_xreg(instr.rd(), sextb(get_xreg(instr.rs1())));
        } else if (instr.shamt() == 0b00101) {
          set_xreg(instr.rd(), sexth(get_xreg(instr.rs1())));
        } else {
          IllegalInstruction(instr);
        }
      } else if ((instr.funct7() & 0b1111110) == BCLRBEXT) {
        set_xreg(instr.rd(), bclr(get_xreg(instr.rs1()), instr.shamt()));
      } else if ((instr.funct7() & 0b1111110) == BINV) {
        set_xreg(instr.rd(), binv(get_xreg(instr.rs1()), instr.shamt()));
      } else if ((instr.funct7() & 0b1111110) == BSET) {
        set_xreg(instr.rd(), bset(get_xreg(instr.rs1()), instr.shamt()));
      } else {
        set_xreg(instr.rd(), get_xreg(instr.rs1()) << instr.shamt());
      }
      break;
    case SRI:
      if ((instr.funct7() & 0b1111110) == SRA) {
        set_xreg(instr.rd(),
                 static_cast<intx_t>(get_xreg(instr.rs1())) >> instr.shamt());
      } else if ((instr.funct7() & 0b1111110) == ROTATE) {
        set_xreg(instr.rd(), ror(get_xreg(instr.rs1()), instr.shamt()));
      } else if (instr.funct7() == 0b0010100) {
        set_xreg(instr.rd(), orcb(get_xreg(instr.rs1())));
#if XLEN == 32
      } else if (instr.funct7() == 0b0110100) {
#else
      } else if (instr.funct7() == 0b0110101) {
#endif
        set_xreg(instr.rd(), rev8(get_xreg(instr.rs1())));
      } else if ((instr.funct7() & 0b1111110) == BCLRBEXT) {
        set_xreg(instr.rd(), bext(get_xreg(instr.rs1()), instr.shamt()));
      } else {
        set_xreg(instr.rd(),
                 static_cast<uintx_t>(get_xreg(instr.rs1())) >> instr.shamt());
      }
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOPIMM32(Instr instr) {
  switch (instr.funct3()) {
    case ADDI: {
      uint32_t a = get_xreg(instr.rs1());
      uint32_t b = instr.itype_imm();
      set_xreg(instr.rd(), sign_extend(a + b));
      break;
    }
    case SLLI: {
      if (instr.funct7() == SLLIUW) {
        uintx_t a = static_cast<uint32_t>(get_xreg(instr.rs1()));
        uintx_t b = instr.shamt();
        set_xreg(instr.rd(), a << b);
      } else if (instr.funct7() == COUNT) {
        if (instr.shamt() == 0b00000) {
          set_xreg(instr.rd(), clzw(get_xreg(instr.rs1())));
        } else if (instr.shamt() == 0b00001) {
          set_xreg(instr.rd(), ctzw(get_xreg(instr.rs1())));
        } else if (instr.shamt() == 0b00010) {
          set_xreg(instr.rd(), cpopw(get_xreg(instr.rs1())));
        } else {
          IllegalInstruction(instr);
        }
      } else {
        uint32_t a = get_xreg(instr.rs1());
        uint32_t b = instr.shamt();
        set_xreg(instr.rd(), sign_extend(a << b));
      }
      break;
    }
    case SRI:
      if (instr.funct7() == SRA) {
        int32_t a = get_xreg(instr.rs1());
        int32_t b = instr.shamt();
        set_xreg(instr.rd(), sign_extend(a >> b));
      } else if (instr.funct7() == ROTATE) {
        set_xreg(instr.rd(), rorw(get_xreg(instr.rs1()), instr.shamt()));
      } else {
        uint32_t a = get_xreg(instr.rs1());
        uint32_t b = instr.shamt();
        set_xreg(instr.rd(), sign_extend(a >> b));
      }
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP(Instr instr) {
  switch (instr.funct7()) {
    case 0:
      InterpretOP_0(instr);
      break;
    case SUB:
      InterpretOP_SUB(instr);
      break;
    case MULDIV:
      InterpretOP_MULDIV(instr);
      break;
    case SHADD:
      InterpretOP_SHADD(instr);
      break;
    case MINMAXCLMUL:
      InterpretOP_MINMAXCLMUL(instr);
      break;
    case ROTATE:
      InterpretOP_ROTATE(instr);
      break;
    case BCLRBEXT:
      InterpretOP_BCLRBEXT(instr);
      break;
    case BINV:
      set_xreg(instr.rd(), binv(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      pc_ += instr.length();
      break;
    case BSET:
      set_xreg(instr.rd(), bset(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      pc_ += instr.length();
      break;
#if XLEN == 32
    case 0b0000100:
      set_xreg(instr.rd(), zexth(get_xreg(instr.rs1())));
      pc_ += instr.length();
      break;
#endif
    default:
      IllegalInstruction(instr);
  }
}

DART_FORCE_INLINE
void Simulator::InterpretOP_0(Instr instr) {
  switch (instr.funct3()) {
    case ADD:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) + get_xreg(instr.rs2()));
      break;
    case SLL: {
      uintx_t shamt = get_xreg(instr.rs2()) & (XLEN - 1);
      set_xreg(instr.rd(), get_xreg(instr.rs1()) << shamt);
      break;
    }
    case SLT:
      set_xreg(instr.rd(), static_cast<intx_t>(get_xreg(instr.rs1())) <
                                   static_cast<intx_t>(get_xreg(instr.rs2()))
                               ? 1
                               : 0);
      break;
    case SLTU:
      set_xreg(instr.rd(), static_cast<uintx_t>(get_xreg(instr.rs1())) <
                                   static_cast<uintx_t>(get_xreg(instr.rs2()))
                               ? 1
                               : 0);
      break;
    case XOR:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) ^ get_xreg(instr.rs2()));
      break;
    case SR: {
      uintx_t shamt = get_xreg(instr.rs2()) & (XLEN - 1);
      set_xreg(instr.rd(),
               static_cast<uintx_t>(get_xreg(instr.rs1())) >> shamt);
      break;
    }
    case OR:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) | get_xreg(instr.rs2()));
      break;
    case AND:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) & get_xreg(instr.rs2()));
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

static intx_t mul(intx_t a, intx_t b) {
  return static_cast<uintx_t>(a) * static_cast<uintx_t>(b);
}

static intx_t mulh(intx_t a, intx_t b) {
  const uintx_t kLoMask = (static_cast<uintx_t>(1) << (XLEN / 2)) - 1;
  const uintx_t kHiShift = XLEN / 2;

  uintx_t a_lo = a & kLoMask;
  intx_t a_hi = a >> kHiShift;
  uintx_t b_lo = b & kLoMask;
  intx_t b_hi = b >> kHiShift;

  uintx_t x = a_lo * b_lo;
  intx_t y = a_hi * b_lo;
  intx_t z = a_lo * b_hi;
  intx_t w = a_hi * b_hi;

  intx_t r0 = (x >> kHiShift) + y;
  intx_t r1 = (r0 & kLoMask) + z;
  return w + (r0 >> kHiShift) + (r1 >> kHiShift);
}

static uintx_t mulhu(uintx_t a, uintx_t b) {
  const uintx_t kLoMask = (static_cast<uintx_t>(1) << (XLEN / 2)) - 1;
  const uintx_t kHiShift = XLEN / 2;

  uintx_t a_lo = a & kLoMask;
  uintx_t a_hi = a >> kHiShift;
  uintx_t b_lo = b & kLoMask;
  uintx_t b_hi = b >> kHiShift;

  uintx_t x = a_lo * b_lo;
  uintx_t y = a_hi * b_lo;
  uintx_t z = a_lo * b_hi;
  uintx_t w = a_hi * b_hi;

  uintx_t r0 = (x >> kHiShift) + y;
  uintx_t r1 = (r0 & kLoMask) + z;
  return w + (r0 >> kHiShift) + (r1 >> kHiShift);
}

static uintx_t mulhsu(intx_t a, uintx_t b) {
  const uintx_t kLoMask = (static_cast<uintx_t>(1) << (XLEN / 2)) - 1;
  const uintx_t kHiShift = XLEN / 2;

  uintx_t a_lo = a & kLoMask;
  intx_t a_hi = a >> kHiShift;
  uintx_t b_lo = b & kLoMask;
  uintx_t b_hi = b >> kHiShift;

  uintx_t x = a_lo * b_lo;
  intx_t y = a_hi * b_lo;
  uintx_t z = a_lo * b_hi;
  intx_t w = a_hi * b_hi;

  intx_t r0 = (x >> kHiShift) + y;
  uintx_t r1 = (r0 & kLoMask) + z;
  return w + (r0 >> kHiShift) + (r1 >> kHiShift);
}

static intx_t div(intx_t a, intx_t b) {
  if (b == 0) {
    return -1;
  } else if (b == -1 && a == kMinIntX) {
    return kMinIntX;
  } else {
    return a / b;
  }
}

static uintx_t divu(uintx_t a, uintx_t b) {
  if (b == 0) {
    return kMaxUIntX;
  } else {
    return a / b;
  }
}

static intx_t rem(intx_t a, intx_t b) {
  if (b == 0) {
    return a;
  } else if (b == -1 && a == kMinIntX) {
    return 0;
  } else {
    return a % b;
  }
}

static uintx_t remu(uintx_t a, uintx_t b) {
  if (b == 0) {
    return a;
  } else {
    return a % b;
  }
}

#if XLEN >= 64
static int32_t mulw(int32_t a, int32_t b) {
  return a * b;
}

static int32_t divw(int32_t a, int32_t b) {
  if (b == 0) {
    return -1;
  } else if (b == -1 && a == kMinInt32) {
    return kMinInt32;
  } else {
    return a / b;
  }
}

static uint32_t divuw(uint32_t a, uint32_t b) {
  if (b == 0) {
    return kMaxUint32;
  } else {
    return a / b;
  }
}

static int32_t remw(int32_t a, int32_t b) {
  if (b == 0) {
    return a;
  } else if (b == -1 && a == kMinInt32) {
    return 0;
  } else {
    return a % b;
  }
}

static uint32_t remuw(uint32_t a, uint32_t b) {
  if (b == 0) {
    return a;
  } else {
    return a % b;
  }
}
#endif  // XLEN >= 64

DART_FORCE_INLINE
void Simulator::InterpretOP_MULDIV(Instr instr) {
  switch (instr.funct3()) {
    case MUL:
      set_xreg(instr.rd(), mul(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case MULH:
      set_xreg(instr.rd(), mulh(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case MULHSU:
      set_xreg(instr.rd(),
               mulhsu(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case MULHU:
      set_xreg(instr.rd(), mulhu(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case DIV:
      set_xreg(instr.rd(), div(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case DIVU:
      set_xreg(instr.rd(), divu(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case REM:
      set_xreg(instr.rd(), rem(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case REMU:
      set_xreg(instr.rd(), remu(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP_SUB(Instr instr) {
  switch (instr.funct3()) {
    case ADD:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) - get_xreg(instr.rs2()));
      break;
    case SR: {
      uintx_t shamt = get_xreg(instr.rs2()) & (XLEN - 1);
      set_xreg(instr.rd(), static_cast<intx_t>(get_xreg(instr.rs1())) >> shamt);
      break;
    }
    case AND:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) & ~get_xreg(instr.rs2()));
      break;
    case OR:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) | ~get_xreg(instr.rs2()));
      break;
    case XOR:
      set_xreg(instr.rd(), get_xreg(instr.rs1()) ^ ~get_xreg(instr.rs2()));
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP_SHADD(Instr instr) {
  switch (instr.funct3()) {
    case SH1ADD:
      set_xreg(instr.rd(),
               (get_xreg(instr.rs1()) << 1) + get_xreg(instr.rs2()));
      break;
    case SH2ADD:
      set_xreg(instr.rd(),
               (get_xreg(instr.rs1()) << 2) + get_xreg(instr.rs2()));
      break;
    case SH3ADD:
      set_xreg(instr.rd(),
               (get_xreg(instr.rs1()) << 3) + get_xreg(instr.rs2()));
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP_MINMAXCLMUL(Instr instr) {
  switch (instr.funct3()) {
    case MAX:
      set_xreg(instr.rd(), max(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case MAXU:
      set_xreg(instr.rd(), maxu(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case MIN:
      set_xreg(instr.rd(), min(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case MINU:
      set_xreg(instr.rd(), minu(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case CLMUL:
      set_xreg(instr.rd(), clmul(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case CLMULH:
      set_xreg(instr.rd(),
               clmulh(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case CLMULR:
      set_xreg(instr.rd(),
               clmulr(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP_ROTATE(Instr instr) {
  switch (instr.funct3()) {
    case ROR:
      set_xreg(instr.rd(), ror(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case ROL:
      set_xreg(instr.rd(), rol(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP_BCLRBEXT(Instr instr) {
  switch (instr.funct3()) {
    case BCLR:
      set_xreg(instr.rd(), bclr(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case BEXT:
      set_xreg(instr.rd(), bext(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP32(Instr instr) {
  switch (instr.funct7()) {
#if XLEN >= 64
    case 0:
      InterpretOP32_0(instr);
      break;
    case SUB:
      InterpretOP32_SUB(instr);
      break;
    case MULDIV:
      InterpretOP32_MULDIV(instr);
      break;
    case SHADD:
      InterpretOP32_SHADD(instr);
      break;
    case ADDUW:
      InterpretOP32_ADDUW(instr);
      break;
    case ROTATE:
      InterpretOP32_ROTATE(instr);
      break;
#endif  // XLEN >= 64
    default:
      IllegalInstruction(instr);
  }
}

DART_FORCE_INLINE
void Simulator::InterpretOP32_0(Instr instr) {
  switch (instr.funct3()) {
#if XLEN >= 64
    case ADD: {
      uint32_t a = get_xreg(instr.rs1());
      uint32_t b = get_xreg(instr.rs2());
      set_xreg(instr.rd(), sign_extend(a + b));
      break;
    }
    case SLL: {
      uint32_t a = get_xreg(instr.rs1());
      uint32_t b = get_xreg(instr.rs2()) & (32 - 1);
      set_xreg(instr.rd(), sign_extend(a << b));
      break;
    }
    case SR: {
      uint32_t b = get_xreg(instr.rs2()) & (32 - 1);
      uint32_t a = get_xreg(instr.rs1());
      set_xreg(instr.rd(), sign_extend(a >> b));
      break;
    }
#endif  // XLEN >= 64
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP32_SUB(Instr instr) {
  switch (instr.funct3()) {
#if XLEN >= 64
    case ADD: {
      uint32_t a = get_xreg(instr.rs1());
      uint32_t b = get_xreg(instr.rs2());
      set_xreg(instr.rd(), sign_extend(a - b));
      break;
    }
    case SR: {
      uint32_t b = get_xreg(instr.rs2()) & (32 - 1);
      int32_t a = get_xreg(instr.rs1());
      set_xreg(instr.rd(), sign_extend(a >> b));
      break;
    }
#endif  // XLEN >= 64
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP32_MULDIV(Instr instr) {
  switch (instr.funct3()) {
#if XLEN >= 64
    case MULW:
      set_xreg(instr.rd(),
               sign_extend(mulw(get_xreg(instr.rs1()), get_xreg(instr.rs2()))));
      break;
    case DIVW:
      set_xreg(instr.rd(),
               sign_extend(divw(get_xreg(instr.rs1()), get_xreg(instr.rs2()))));
      break;
    case DIVUW:
      set_xreg(instr.rd(), sign_extend(divuw(get_xreg(instr.rs1()),
                                             get_xreg(instr.rs2()))));
      break;
    case REMW:
      set_xreg(instr.rd(),
               sign_extend(remw(get_xreg(instr.rs1()), get_xreg(instr.rs2()))));
      break;
    case REMUW:
      set_xreg(instr.rd(), sign_extend(remuw(get_xreg(instr.rs1()),
                                             get_xreg(instr.rs2()))));
      break;
#endif  // XLEN >= 64
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP32_SHADD(Instr instr) {
  switch (instr.funct3()) {
    case SH1ADD: {
      uintx_t a = static_cast<uint32_t>(get_xreg(instr.rs1()));
      uintx_t b = get_xreg(instr.rs2());
      set_xreg(instr.rd(), (a << 1) + b);
      break;
    }
    case SH2ADD: {
      uintx_t a = static_cast<uint32_t>(get_xreg(instr.rs1()));
      uintx_t b = get_xreg(instr.rs2());
      set_xreg(instr.rd(), (a << 2) + b);
      break;
    }
    case SH3ADD: {
      uintx_t a = static_cast<uint32_t>(get_xreg(instr.rs1()));
      uintx_t b = get_xreg(instr.rs2());
      set_xreg(instr.rd(), (a << 3) + b);
      break;
    }
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP32_ADDUW(Instr instr) {
  switch (instr.funct3()) {
#if XLEN >= 64
    case F3_0: {
      uintx_t a = static_cast<uint32_t>(get_xreg(instr.rs1()));
      uintx_t b = get_xreg(instr.rs2());
      set_xreg(instr.rd(), a + b);
      break;
    }
    case ZEXT:
      set_xreg(instr.rd(), zexth(get_xreg(instr.rs1())));
      break;
#endif  // XLEN >= 64
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

DART_FORCE_INLINE
void Simulator::InterpretOP32_ROTATE(Instr instr) {
  switch (instr.funct3()) {
    case ROR:
      set_xreg(instr.rd(), rorw(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    case ROL:
      set_xreg(instr.rd(), rolw(get_xreg(instr.rs1()), get_xreg(instr.rs2())));
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

void Simulator::InterpretMISCMEM(Instr instr) {
  switch (instr.funct3()) {
    case FENCE:
      std::atomic_thread_fence(std::memory_order_acq_rel);
      break;
    case FENCEI:
      // Nothing to do: simulated instructions are data on the host.
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

void Simulator::InterpretSYSTEM(Instr instr) {
  switch (instr.funct3()) {
    case 0:
      switch (instr.funct12()) {
        case ECALL:
          InterpretECALL(instr);
          return;
        case EBREAK:
          InterpretEBREAK(instr);
          return;
        default:
          IllegalInstruction(instr);
      }
      break;
    case CSRRW: {
      if (instr.rd() == ZR) {
        // No read effect.
        CSRWrite(instr.csr(), get_xreg(instr.rs1()));
      } else {
        intx_t result = CSRRead(instr.csr());
        CSRWrite(instr.csr(), get_xreg(instr.rs1()));
        set_xreg(instr.rd(), result);
      }
      break;
    }
    case CSRRS: {
      intx_t result = CSRRead(instr.csr());
      if (instr.rs1() == ZR) {
        // No write effect.
      } else {
        CSRSet(instr.csr(), get_xreg(instr.rs1()));
      }
      set_xreg(instr.rd(), result);
      break;
    }
    case CSRRC: {
      intx_t result = CSRRead(instr.csr());
      if (instr.rs1() == ZR) {
        // No write effect.
      } else {
        CSRClear(instr.csr(), get_xreg(instr.rs1()));
      }
      set_xreg(instr.rd(), result);
      break;
    }
    case CSRRWI: {
      if (instr.rd() == ZR) {
        // No read effect.
        CSRWrite(instr.csr(), instr.zimm());
      } else {
        intx_t result = CSRRead(instr.csr());
        CSRWrite(instr.csr(), instr.zimm());
        set_xreg(instr.rd(), result);
      }
      break;
    }
    case CSRRSI: {
      intx_t result = CSRRead(instr.csr());
      if (instr.zimm() == 0) {
        // No write effect.
      } else {
        CSRSet(instr.csr(), instr.zimm());
      }
      set_xreg(instr.rd(), result);
      break;
    }
    case CSRRCI: {
      intx_t result = CSRRead(instr.csr());
      if (instr.zimm() == 0) {
        // No write effect.
      } else {
        CSRClear(instr.csr(), instr.zimm());
      }
      set_xreg(instr.rd(), result);
      break;
    }
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

// Calls into the Dart runtime are based on this interface.
typedef void (*SimulatorRuntimeCall)(NativeArguments arguments);

// Calls to leaf Dart runtime functions are based on this interface.
typedef intx_t (*SimulatorLeafRuntimeCall)(intx_t r0,
                                           intx_t r1,
                                           intx_t r2,
                                           intx_t r3,
                                           intx_t r4,
                                           intx_t r5,
                                           intx_t r6,
                                           intx_t r7);

// [target] has several different signatures that differ from
// SimulatorLeafRuntimeCall. We can call them all from here only because in
// X64's calling conventions a function can be called with extra arguments
// and the callee will see the first arguments and won't unbalance the stack.
NO_SANITIZE_UNDEFINED("function")
static intx_t InvokeLeafRuntime(SimulatorLeafRuntimeCall target,
                                intx_t r0,
                                intx_t r1,
                                intx_t r2,
                                intx_t r3,
                                intx_t r4,
                                intx_t r5,
                                intx_t r6,
                                intx_t r7) {
  return target(r0, r1, r2, r3, r4, r5, r6, r7);
}

// Calls to leaf float Dart runtime functions are based on this interface.
typedef double (*SimulatorLeafFloatRuntimeCall)(double d0,
                                                double d1,
                                                double d2,
                                                double d3,
                                                double d4,
                                                double d5,
                                                double d6,
                                                double d7);

// [target] has several different signatures that differ from
// SimulatorFloatLeafRuntimeCall. We can call them all from here only because in
// X64's calling conventions a function can be called with extra arguments
// and the callee will see the first arguments and won't unbalance the stack.
NO_SANITIZE_UNDEFINED("function")
static double InvokeFloatLeafRuntime(SimulatorLeafFloatRuntimeCall target,
                                     double d0,
                                     double d1,
                                     double d2,
                                     double d3,
                                     double d4,
                                     double d5,
                                     double d6,
                                     double d7) {
  return target(d0, d1, d2, d3, d4, d5, d6, d7);
}

// Calls to native Dart functions are based on this interface.
typedef void (*SimulatorNativeCallWrapper)(Dart_NativeArguments arguments,
                                           Dart_NativeFunction target);

void Simulator::InterpretECALL(Instr instr) {
  if (instr.rs1() != ZR) {
    // Fake instruction generated by Assembler::SimulatorPrintObject.
    if (true || IsTracingExecution()) {
      Object& obj = Object::Handle(
          static_cast<ObjectPtr>(static_cast<uword>(get_xreg(instr.rs1()))));
      THR_Print("%" Px ": %s = %s\n", static_cast<uword>(pc_),
                cpu_reg_names[instr.rs1()], obj.ToCString());
      FLAG_trace_sim_after = 1;
    }
    pc_ += instr.length();
    return;
  }

  // The C ABI stack alignment is 16 for both 32 and 64 bit.
  if (!Utils::IsAligned(get_xreg(SP), 16)) {
    PrintRegisters();
    PrintStack();
    FATAL("Stack misaligned at call to C function");
  }

  SimulatorSetjmpBuffer buffer(this);
  if (!setjmp(buffer.buffer_)) {
    uintx_t saved_ra = get_xreg(RA);
    Redirection* redirection = Redirection::FromECallInstruction(pc_);
    uword external = redirection->external_function();
    if (IsTracingExecution()) {
      THR_Print("Call to host function at 0x%" Pd "\n", external);
    }

    if (redirection->call_kind() == kRuntimeCall) {
      NativeArguments* arguments =
          reinterpret_cast<NativeArguments*>(get_register(A0));
      SimulatorRuntimeCall target =
          reinterpret_cast<SimulatorRuntimeCall>(external);
      target(*arguments);
      ClobberVolatileRegisters();
    } else if (redirection->call_kind() == kLeafRuntimeCall) {
      ASSERT((0 <= redirection->argument_count()) &&
             (redirection->argument_count() <= 8));
      SimulatorLeafRuntimeCall target =
          reinterpret_cast<SimulatorLeafRuntimeCall>(external);
      const intx_t r0 = get_register(A0);
      const intx_t r1 = get_register(A1);
      const intx_t r2 = get_register(A2);
      const intx_t r3 = get_register(A3);
      const intx_t r4 = get_register(A4);
      const intx_t r5 = get_register(A5);
      const intx_t r6 = get_register(A6);
      const intx_t r7 = get_register(A7);
      const intx_t res =
          InvokeLeafRuntime(target, r0, r1, r2, r3, r4, r5, r6, r7);
      ClobberVolatileRegisters();
      set_xreg(A0, res);  // Set returned result from function.
    } else if (redirection->call_kind() == kLeafFloatRuntimeCall) {
      ASSERT((0 <= redirection->argument_count()) &&
             (redirection->argument_count() <= 8));
      SimulatorLeafFloatRuntimeCall target =
          reinterpret_cast<SimulatorLeafFloatRuntimeCall>(external);
      const double d0 = get_fregd(FA0);
      const double d1 = get_fregd(FA1);
      const double d2 = get_fregd(FA2);
      const double d3 = get_fregd(FA3);
      const double d4 = get_fregd(FA4);
      const double d5 = get_fregd(FA5);
      const double d6 = get_fregd(FA6);
      const double d7 = get_fregd(FA7);
      const double res =
          InvokeFloatLeafRuntime(target, d0, d1, d2, d3, d4, d5, d6, d7);
      ClobberVolatileRegisters();
      set_fregd(FA0, res);
    } else if (redirection->call_kind() == kNativeCallWrapper) {
      SimulatorNativeCallWrapper wrapper =
          reinterpret_cast<SimulatorNativeCallWrapper>(external);
      Dart_NativeArguments arguments =
          reinterpret_cast<Dart_NativeArguments>(get_register(A0));
      Dart_NativeFunction target =
          reinterpret_cast<Dart_NativeFunction>(get_register(A1));
      wrapper(arguments, target);
      ClobberVolatileRegisters();
    } else {
      UNREACHABLE();
    }

    // Return.
    pc_ = saved_ra;
  } else {
    // Coming via long jump from a throw. Continue to exception handler.
  }
}

void Simulator::InterpretAMO(Instr instr) {
  switch (instr.funct3()) {
    case WIDTH32:
      InterpretAMO32(instr);
      break;
    case WIDTH64:
      InterpretAMO64(instr);
      break;
    default:
      IllegalInstruction(instr);
  }
}

// Note: This implementation does not give full LR/SC semantics because it
// suffers from the ABA problem.

template <typename type>
void Simulator::InterpretLR(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1());
  if ((addr & (sizeof(type) - 1)) != 0) {
    FATAL("Misaligned atomic memory operation");
  }
  std::atomic<type>* atomic = reinterpret_cast<std::atomic<type>*>(addr);
  reserved_address_ = addr;
  reserved_value_ = atomic->load(instr.memory_order());
  set_xreg(instr.rd(), reserved_value_);
}

template <typename type>
void Simulator::InterpretSC(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1());
  if ((addr & (sizeof(type) - 1)) != 0) {
    FATAL("Misaligned atomic memory operation");
  }
  std::atomic<type>* atomic = reinterpret_cast<std::atomic<type>*>(addr);
  if (addr != reserved_address_) {
    set_xreg(instr.rd(), 1);
    return;
  }
  type expected = reserved_value_;
  type desired = get_xreg(instr.rs2());
  bool success =
      atomic->compare_exchange_strong(expected, desired, instr.memory_order());
  set_xreg(instr.rd(), success ? 0 : 1);
}

template <typename type>
void Simulator::InterpretAMOSWAP(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1());
  if ((addr & (sizeof(type) - 1)) != 0) {
    FATAL("Misaligned atomic memory operation");
  }
  std::atomic<type>* atomic = reinterpret_cast<std::atomic<type>*>(addr);
  type desired = get_xreg(instr.rs2());
  type result = atomic->exchange(desired, instr.memory_order());
  set_xreg(instr.rd(), sign_extend(result));
}

template <typename type>
void Simulator::InterpretAMOADD(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1());
  if ((addr & (sizeof(type) - 1)) != 0) {
    FATAL("Misaligned atomic memory operation");
  }
  std::atomic<type>* atomic = reinterpret_cast<std::atomic<type>*>(addr);
  type arg = get_xreg(instr.rs2());
  type result = atomic->fetch_add(arg, instr.memory_order());
  set_xreg(instr.rd(), sign_extend(result));
}

template <typename type>
void Simulator::InterpretAMOXOR(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1());
  if ((addr & (sizeof(type) - 1)) != 0) {
    FATAL("Misaligned atomic memory operation");
  }
  std::atomic<type>* atomic = reinterpret_cast<std::atomic<type>*>(addr);
  type arg = get_xreg(instr.rs2());
  type result = atomic->fetch_xor(arg, instr.memory_order());
  set_xreg(instr.rd(), sign_extend(result));
}

template <typename type>
void Simulator::InterpretAMOAND(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1());
  if ((addr & (sizeof(type) - 1)) != 0) {
    FATAL("Misaligned atomic memory operation");
  }
  std::atomic<type>* atomic = reinterpret_cast<std::atomic<type>*>(addr);
  type arg = get_xreg(instr.rs2());
  type result = atomic->fetch_and(arg, instr.memory_order());
  set_xreg(instr.rd(), sign_extend(result));
}

template <typename type>
void Simulator::InterpretAMOOR(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1());
  if ((addr & (sizeof(type) - 1)) != 0) {
    FATAL("Misaligned atomic memory operation");
  }
  std::atomic<type>* atomic = reinterpret_cast<std::atomic<type>*>(addr);
  type arg = get_xreg(instr.rs2());
  type result = atomic->fetch_or(arg, instr.memory_order());
  set_xreg(instr.rd(), sign_extend(result));
}

template <typename type>
void Simulator::InterpretAMOMIN(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1());
  if ((addr & (sizeof(type) - 1)) != 0) {
    FATAL("Misaligned atomic memory operation");
  }
  std::atomic<type>* atomic = reinterpret_cast<std::atomic<type>*>(addr);
  type expected = atomic->load(std::memory_order_relaxed);
  type compare = get_xreg(instr.rs2());
  type desired;
  do {
    desired = expected < compare ? expected : compare;
  } while (
      !atomic->compare_exchange_weak(expected, desired, instr.memory_order()));
  set_xreg(instr.rd(), sign_extend(expected));
}

template <typename type>
void Simulator::InterpretAMOMAX(Instr instr) {
  uintx_t addr = get_xreg(instr.rs1());
  if ((addr & (sizeof(type) - 1)) != 0) {
    FATAL("Misaligned atomic memory operation");
  }
  std::atomic<type>* atomic = reinterpret_cast<std::atomic<type>*>(addr);
  type expected = atomic->load(std::memory_order_relaxed);
  type compare = get_xreg(instr.rs2());
  type desired;
  do {
    desired = expected > compare ? expected : compare;
  } while (
      !atomic->compare_exchange_weak(expected, desired, instr.memory_order()));
  set_xreg(instr.rd(), sign_extend(expected));
}

void Simulator::InterpretAMO32(Instr instr) {
  switch (instr.funct5()) {
    case LR:
      InterpretLR<int32_t>(instr);
      break;
    case SC:
      InterpretSC<int32_t>(instr);
      break;
    case AMOSWAP:
      InterpretAMOSWAP<int32_t>(instr);
      break;
    case AMOADD:
      InterpretAMOADD<int32_t>(instr);
      break;
    case AMOXOR:
      InterpretAMOXOR<int32_t>(instr);
      break;
    case AMOAND:
      InterpretAMOAND<int32_t>(instr);
      break;
    case AMOOR:
      InterpretAMOOR<int32_t>(instr);
      break;
    case AMOMIN:
      InterpretAMOMIN<int32_t>(instr);
      break;
    case AMOMAX:
      InterpretAMOMAX<int32_t>(instr);
      break;
    case AMOMINU:
      InterpretAMOMIN<uint32_t>(instr);
      break;
    case AMOMAXU:
      InterpretAMOMAX<uint32_t>(instr);
      break;
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

void Simulator::InterpretAMO64(Instr instr) {
  switch (instr.funct5()) {
#if XLEN >= 64
    case LR:
      InterpretLR<int64_t>(instr);
      break;
    case SC:
      InterpretSC<int64_t>(instr);
      break;
    case AMOSWAP:
      InterpretAMOSWAP<int64_t>(instr);
      break;
    case AMOADD:
      InterpretAMOADD<int64_t>(instr);
      break;
    case AMOXOR:
      InterpretAMOXOR<int64_t>(instr);
      break;
    case AMOAND:
      InterpretAMOAND<int64_t>(instr);
      break;
    case AMOOR:
      InterpretAMOOR<int64_t>(instr);
      break;
    case AMOMIN:
      InterpretAMOMIN<int64_t>(instr);
      break;
    case AMOMAX:
      InterpretAMOMAX<int64_t>(instr);
      break;
    case AMOMINU:
      InterpretAMOMIN<uint64_t>(instr);
      break;
    case AMOMAXU:
      InterpretAMOMAX<uint64_t>(instr);
      break;
#endif  // XLEN >= 64
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

void Simulator::InterpretFMADD(Instr instr) {
  switch (instr.funct2()) {
    case F2_S: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      float rs3 = get_fregs(instr.frs3());
      set_fregs(instr.frd(), (rs1 * rs2) + rs3);
      break;
    }
    case F2_D: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      double rs3 = get_fregd(instr.frs3());
      set_fregd(instr.frd(), (rs1 * rs2) + rs3);
      break;
    }
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

void Simulator::InterpretFMSUB(Instr instr) {
  switch (instr.funct2()) {
    case F2_S: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      float rs3 = get_fregs(instr.frs3());
      set_fregs(instr.frd(), (rs1 * rs2) - rs3);
      break;
    }
    case F2_D: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      double rs3 = get_fregd(instr.frs3());
      set_fregd(instr.frd(), (rs1 * rs2) - rs3);
      break;
    }
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

void Simulator::InterpretFNMSUB(Instr instr) {
  switch (instr.funct2()) {
    case F2_S: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      float rs3 = get_fregs(instr.frs3());
      set_fregs(instr.frd(), -(rs1 * rs2) + rs3);
      break;
    }
    case F2_D: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      double rs3 = get_fregd(instr.frs3());
      set_fregd(instr.frd(), -(rs1 * rs2) + rs3);
      break;
    }
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

void Simulator::InterpretFNMADD(Instr instr) {
  switch (instr.funct2()) {
    case F2_S: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      float rs3 = get_fregs(instr.frs3());
      set_fregs(instr.frd(), -(rs1 * rs2) - rs3);
      break;
    }
    case F2_D: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      double rs3 = get_fregd(instr.frs3());
      set_fregd(instr.frd(), -(rs1 * rs2) - rs3);
      break;
    }
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

// "For the purposes of these instructions only, the value −0.0 is considered to
//  be less than the value +0.0. If both inputs are NaNs, the result is the
//  canonical NaN. If only one operand is a NaN, the result is the non-NaN
//  operand."
static double rv_fmin(double x, double y) {
  if (isnan(x) && isnan(y)) return std::numeric_limits<double>::quiet_NaN();
  if (isnan(x)) return y;
  if (isnan(y)) return x;
  if (x == y) return signbit(x) ? x : y;
  return fmin(x, y);
}

static double rv_fmax(double x, double y) {
  if (isnan(x) && isnan(y)) return std::numeric_limits<double>::quiet_NaN();
  if (isnan(x)) return y;
  if (isnan(y)) return x;
  if (x == y) return signbit(x) ? y : x;
  return fmax(x, y);
}

static float rv_fminf(float x, float y) {
  if (isnan(x) && isnan(y)) return std::numeric_limits<float>::quiet_NaN();
  if (isnan(x)) return y;
  if (isnan(y)) return x;
  if (x == y) return signbit(x) ? x : y;
  return fminf(x, y);
}

static float rv_fmaxf(float x, float y) {
  if (isnan(x) && isnan(y)) return std::numeric_limits<float>::quiet_NaN();
  if (isnan(x)) return y;
  if (isnan(y)) return x;
  if (x == y) return signbit(x) ? y : x;
  return fmaxf(x, y);
}

static bool is_quiet(float x) {
  // Warning: This is true on Intel/ARM, but not everywhere.
  return (bit_cast<uint32_t>(x) & (static_cast<uint32_t>(1) << 22)) != 0;
}

static uintx_t fclass(float x) {
  ASSERT(!is_quiet(std::numeric_limits<float>::signaling_NaN()));
  ASSERT(is_quiet(std::numeric_limits<float>::quiet_NaN()));

  switch (fpclassify(x)) {
    case FP_INFINITE:
      return signbit(x) ? kFClassNegInfinity : kFClassPosInfinity;
    case FP_NAN:
      return is_quiet(x) ? kFClassQuietNan : kFClassSignallingNan;
    case FP_ZERO:
      return signbit(x) ? kFClassNegZero : kFClassPosZero;
    case FP_SUBNORMAL:
      return signbit(x) ? kFClassNegSubnormal : kFClassPosSubnormal;
    case FP_NORMAL:
      return signbit(x) ? kFClassNegNormal : kFClassPosNormal;
    default:
      UNREACHABLE();
      return 0;
  }
}

static bool is_quiet(double x) {
  // Warning: This is true on Intel/ARM, but not everywhere.
  return (bit_cast<uint64_t>(x) & (static_cast<uint64_t>(1) << 51)) != 0;
}

static uintx_t fclass(double x) {
  ASSERT(!is_quiet(std::numeric_limits<double>::signaling_NaN()));
  ASSERT(is_quiet(std::numeric_limits<double>::quiet_NaN()));

  switch (fpclassify(x)) {
    case FP_INFINITE:
      return signbit(x) ? kFClassNegInfinity : kFClassPosInfinity;
    case FP_NAN:
      return is_quiet(x) ? kFClassQuietNan : kFClassSignallingNan;
    case FP_ZERO:
      return signbit(x) ? kFClassNegZero : kFClassPosZero;
    case FP_SUBNORMAL:
      return signbit(x) ? kFClassNegSubnormal : kFClassPosSubnormal;
    case FP_NORMAL:
      return signbit(x) ? kFClassNegNormal : kFClassPosNormal;
    default:
      UNREACHABLE();
      return 0;
  }
}

static float roundevenf(float x) {
  float rounded = roundf(x);
  if (fabsf(x - rounded) == 0.5f) {  // Tie
    if (fmodf(rounded, 2) != 0) {    // Not even
      if (rounded > 0.0f) {
        rounded -= 1.0f;
      } else {
        rounded += 1.0f;
      }
      ASSERT(fmodf(rounded, 2) == 0);
    }
  }
  return rounded;
}

static double roundeven(double x) {
  double rounded = round(x);
  if (fabs(x - rounded) == 0.5f) {  // Tie
    if (fmod(rounded, 2) != 0) {    // Not even
      if (rounded > 0.0f) {
        rounded -= 1.0f;
      } else {
        rounded += 1.0f;
      }
      ASSERT(fmod(rounded, 2) == 0);
    }
  }
  return rounded;
}

static float Round(float x, RoundingMode rounding) {
  switch (rounding) {
    case RNE:  // Round to Nearest, ties to Even
      return roundevenf(x);
    case RTZ:  // Round towards Zero
      return truncf(x);
    case RDN:  // Round Down (toward negative infinity)
      return floorf(x);
    case RUP:  // Round Up (toward positive infinity)
      return ceilf(x);
    case RMM:  // Round to nearest, ties to Max Magnitude
      return roundf(x);
    case DYN:  // Dynamic rounding mode
      UNIMPLEMENTED();
    default:
      FATAL("Invalid rounding mode");
  }
}

static double Round(double x, RoundingMode rounding) {
  switch (rounding) {
    case RNE:  // Round to Nearest, ties to Even
      return roundeven(x);
    case RTZ:  // Round towards Zero
      return trunc(x);
    case RDN:  // Round Down (toward negative infinity)
      return floor(x);
    case RUP:  // Round Up (toward positive infinity)
      return ceil(x);
    case RMM:  // Round to nearest, ties to Max Magnitude
      return round(x);
    case DYN:  // Dynamic rounding mode
      UNIMPLEMENTED();
    default:
      FATAL("Invalid rounding mode");
  }
}

static int32_t fcvtws(float x, RoundingMode rounding) {
  if (x < static_cast<float>(kMinInt32)) {
    return kMinInt32;  // Negative infinity.
  }
  if (x < static_cast<float>(kMaxInt32)) {
    return static_cast<int32_t>(Round(x, rounding));
  }
  return kMaxInt32;  // Positive infinity, NaN.
}

static uint32_t fcvtwus(float x, RoundingMode rounding) {
  if (x < static_cast<float>(0)) {
    return 0;  // Negative infinity.
  }
  if (x < static_cast<float>(kMaxUint32)) {
    return static_cast<uint32_t>(Round(x, rounding));
  }
  return kMaxUint32;  // Positive infinity, NaN.
}

#if XLEN >= 64
static int64_t fcvtls(float x, RoundingMode rounding) {
  if (x < static_cast<float>(kMinInt64)) {
    return kMinInt64;  // Negative infinity.
  }
  if (x < static_cast<float>(kMaxInt64)) {
    return static_cast<int64_t>(Round(x, rounding));
  }
  return kMaxInt64;  // Positive infinity, NaN.
}

static uint64_t fcvtlus(float x, RoundingMode rounding) {
  if (x < static_cast<float>(0.0)) {
    return 0;  // Negative infinity.
  }
  if (x < static_cast<float>(kMaxUint64)) {
    return static_cast<uint64_t>(Round(x, rounding));
  }
  return kMaxUint64;  // Positive infinity, NaN.
}
#endif  // XLEN >= 64

static int32_t fcvtwd(double x, RoundingMode rounding) {
  if (x < static_cast<double>(kMinInt32)) {
    return kMinInt32;  // Negative infinity.
  }
  if (x < static_cast<double>(kMaxInt32)) {
    return static_cast<int32_t>(Round(x, rounding));
  }
  return kMaxInt32;  // Positive infinity, NaN.
}

static uint32_t fcvtwud(double x, RoundingMode rounding) {
  if (x < static_cast<double>(0)) {
    return 0;  // Negative infinity.
  }
  if (x < static_cast<double>(kMaxUint32)) {
    return static_cast<uint32_t>(Round(x, rounding));
  }
  return kMaxUint32;  // Positive infinity, NaN.
}

#if XLEN >= 64
static int64_t fcvtld(double x, RoundingMode rounding) {
  if (x < static_cast<double>(kMinInt64)) {
    return kMinInt64;  // Negative infinity.
  }
  if (x < static_cast<double>(kMaxInt64)) {
    return static_cast<int64_t>(Round(x, rounding));
  }
  return kMaxInt64;  // Positive infinity, NaN.
}

static uint64_t fcvtlud(double x, RoundingMode rounding) {
  if (x < static_cast<double>(0.0)) {
    return 0;  // Negative infinity.
  }
  if (x < static_cast<double>(kMaxUint64)) {
    return static_cast<uint64_t>(Round(x, rounding));
  }
  return kMaxUint64;  // Positive infinity, NaN.
}
#endif  // XLEN >= 64

void Simulator::InterpretOPFP(Instr instr) {
  switch (instr.funct7()) {
    case FADDS: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      set_fregs(instr.frd(), rs1 + rs2);
      break;
    }
    case FSUBS: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      set_fregs(instr.frd(), rs1 - rs2);
      break;
    }
    case FMULS: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      set_fregs(instr.frd(), rs1 * rs2);
      break;
    }
    case FDIVS: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      set_fregs(instr.frd(), rs1 / rs2);
      break;
    }
    case FSQRTS: {
      float rs1 = get_fregs(instr.frs1());
      set_fregs(instr.frd(), sqrtf(rs1));
      break;
    }
    case FSGNJS: {
      const uint32_t kSignMask = static_cast<uint32_t>(1) << 31;
      uint32_t rs1 = bit_cast<uint32_t>(get_fregs(instr.frs1()));
      uint32_t rs2 = bit_cast<uint32_t>(get_fregs(instr.frs2()));
      uint32_t result;
      switch (instr.funct3()) {
        case J:
          result = (rs1 & ~kSignMask) | (rs2 & kSignMask);
          break;
        case JN:
          result = (rs1 & ~kSignMask) | (~rs2 & kSignMask);
          break;
        case JX:
          result = (rs1 & ~kSignMask) | ((rs1 ^ rs2) & kSignMask);
          break;
        default:
          IllegalInstruction(instr);
      }
      set_fregs(instr.frd(), bit_cast<float>(result));
      break;
    }
    case FMINMAXS: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      switch (instr.funct3()) {
        case FMIN:
          set_fregs(instr.frd(), rv_fminf(rs1, rs2));
          break;
        case FMAX:
          set_fregs(instr.frd(), rv_fmaxf(rs1, rs2));
          break;
        default:
          IllegalInstruction(instr);
      }
      break;
    }
    case FCMPS: {
      float rs1 = get_fregs(instr.frs1());
      float rs2 = get_fregs(instr.frs2());
      switch (instr.funct3()) {
        case FEQ:
          set_xreg(instr.rd(), rs1 == rs2 ? 1 : 0);
          break;
        case FLT:
          set_xreg(instr.rd(), rs1 < rs2 ? 1 : 0);
          break;
        case FLE:
          set_xreg(instr.rd(), rs1 <= rs2 ? 1 : 0);
          break;
        default:
          IllegalInstruction(instr);
      }
      break;
    }
    case FCLASSS:  // = FMVXW
      switch (instr.funct3()) {
        case 1:
          // fclass.s
          set_xreg(instr.rd(), fclass(get_fregs(instr.frs1())));
          break;
        case 0:
          // fmv.x.s
          set_xreg(instr.rd(),
                   sign_extend(bit_cast<int32_t>(get_fregs(instr.frs1()))));
          break;
        default:
          IllegalInstruction(instr);
      }
      break;
    case FCVTintS:
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case W:
          set_xreg(instr.rd(), sign_extend(fcvtws(get_fregs(instr.frs1()),
                                                  instr.rounding())));
          break;
        case WU:
          set_xreg(instr.rd(), sign_extend(fcvtwus(get_fregs(instr.frs1()),
                                                   instr.rounding())));
          break;
#if XLEN >= 64
        case L:
          set_xreg(instr.rd(), sign_extend(fcvtls(get_fregs(instr.frs1()),
                                                  instr.rounding())));
          break;
        case LU:
          set_xreg(instr.rd(), sign_extend(fcvtlus(get_fregs(instr.frs1()),
                                                   instr.rounding())));
          break;
#endif  // XLEN >= 64
        default:
          IllegalInstruction(instr);
      }
      break;
    case FCVTSint:
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case W:
          set_fregs(
              instr.frd(),
              static_cast<float>(static_cast<int32_t>(get_xreg(instr.rs1()))));
          break;
        case WU:
          set_fregs(
              instr.frd(),
              static_cast<float>(static_cast<uint32_t>(get_xreg(instr.rs1()))));
          break;
#if XLEN >= 64
        case L:
          set_fregs(
              instr.frd(),
              static_cast<float>(static_cast<int64_t>(get_xreg(instr.rs1()))));
          break;
        case LU:
          set_fregs(
              instr.frd(),
              static_cast<float>(static_cast<uint64_t>(get_xreg(instr.rs1()))));
          break;
#endif  // XLEN >= 64
        default:
          IllegalInstruction(instr);
      }
      break;
    case FMVWX:
      set_fregs(instr.frd(),
                bit_cast<float>(static_cast<int32_t>(get_xreg(instr.rs1()))));
      break;
    case FADDD: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      set_fregd(instr.frd(), rs1 + rs2);
      break;
    }
    case FSUBD: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      set_fregd(instr.frd(), rs1 - rs2);
      break;
    }
    case FMULD: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      set_fregd(instr.frd(), rs1 * rs2);
      break;
    }
    case FDIVD: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      set_fregd(instr.frd(), rs1 / rs2);
      break;
    }
    case FSQRTD: {
      double rs1 = get_fregd(instr.frs1());
      set_fregd(instr.frd(), sqrt(rs1));
      break;
    }
    case FSGNJD: {
      const uint64_t kSignMask = static_cast<uint64_t>(1) << 63;
      uint64_t rs1 = bit_cast<uint64_t>(get_fregd(instr.frs1()));
      uint64_t rs2 = bit_cast<uint64_t>(get_fregd(instr.frs2()));
      uint64_t result;
      switch (instr.funct3()) {
        case J:
          result = (rs1 & ~kSignMask) | (rs2 & kSignMask);
          break;
        case JN:
          result = (rs1 & ~kSignMask) | (~rs2 & kSignMask);
          break;
        case JX:
          result = (rs1 & ~kSignMask) | ((rs1 ^ rs2) & kSignMask);
          break;
        default:
          IllegalInstruction(instr);
      }
      set_fregd(instr.frd(), bit_cast<double>(result));
      break;
    }
    case FMINMAXD: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      switch (instr.funct3()) {
        case FMIN:
          set_fregd(instr.frd(), rv_fmin(rs1, rs2));
          break;
        case FMAX:
          set_fregd(instr.frd(), rv_fmax(rs1, rs2));
          break;
        default:
          IllegalInstruction(instr);
      }
      break;
    }
    case FCVTS: {
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case 1:
          set_fregs(instr.frd(), static_cast<float>(get_fregd(instr.frs1())));
          break;
        default:
          IllegalInstruction(instr);
      }
      break;
    }
    case FCVTD: {
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case 0:
          set_fregd(instr.frd(), static_cast<double>(get_fregs(instr.frs1())));
          break;
        default:
          IllegalInstruction(instr);
      }
      break;
    }

    case FCMPD: {
      double rs1 = get_fregd(instr.frs1());
      double rs2 = get_fregd(instr.frs2());
      switch (instr.funct3()) {
        case FEQ:
          set_xreg(instr.rd(), rs1 == rs2 ? 1 : 0);
          break;
        case FLT:
          set_xreg(instr.rd(), rs1 < rs2 ? 1 : 0);
          break;
        case FLE:
          set_xreg(instr.rd(), rs1 <= rs2 ? 1 : 0);
          break;
        default:
          IllegalInstruction(instr);
      }
      break;
    }
    case FCLASSD:  // = FMVXD
      switch (instr.funct3()) {
        case 1:
          // fclass.d
          set_xreg(instr.rd(), fclass(get_fregd(instr.frs1())));
          break;
#if XLEN >= 64
        case 0:
          // fmv.x.d
          set_xreg(instr.rd(), bit_cast<int64_t>(get_fregd(instr.frs1())));
          break;
#endif  // XLEN >= 64
        default:
          IllegalInstruction(instr);
      }
      break;
    case FCVTintD:
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case W:
          set_xreg(instr.rd(), sign_extend(fcvtwd(get_fregd(instr.frs1()),
                                                  instr.rounding())));
          break;
        case WU:
          set_xreg(instr.rd(), sign_extend(fcvtwud(get_fregd(instr.frs1()),
                                                   instr.rounding())));
          break;
#if XLEN >= 64
        case L:
          set_xreg(instr.rd(), sign_extend(fcvtld(get_fregd(instr.frs1()),
                                                  instr.rounding())));
          break;
        case LU:
          set_xreg(instr.rd(), sign_extend(fcvtlud(get_fregd(instr.frs1()),
                                                   instr.rounding())));
          break;
#endif  // XLEN >= 64
        default:
          IllegalInstruction(instr);
      }
      break;
    case FCVTDint:
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case W:
          set_fregd(
              instr.frd(),
              static_cast<double>(static_cast<int32_t>(get_xreg(instr.rs1()))));
          break;
        case WU:
          set_fregd(instr.frd(), static_cast<double>(static_cast<uint32_t>(
                                     get_xreg(instr.rs1()))));
          break;
#if XLEN >= 64
        case L:
          set_fregd(
              instr.frd(),
              static_cast<double>(static_cast<int64_t>(get_xreg(instr.rs1()))));
          break;
        case LU:
          set_fregd(instr.frd(), static_cast<double>(static_cast<uint64_t>(
                                     get_xreg(instr.rs1()))));
          break;
#endif  // XLEN >= 64
        default:
          IllegalInstruction(instr);
      }
      break;
#if XLEN >= 64
    case FMVDX:
      set_fregd(instr.frd(), bit_cast<double>(get_xreg(instr.rs1())));
      break;
#endif  // XLEN >= 64
    default:
      IllegalInstruction(instr);
  }
  pc_ += instr.length();
}

void Simulator::InterpretEBREAK(Instr instr) {
  PrintRegisters();
  PrintStack();
  FATAL("Encountered EBREAK");
}

void Simulator::InterpretEBREAK(CInstr instr) {
  PrintRegisters();
  PrintStack();
  FATAL("Encountered EBREAK");
}

void Simulator::IllegalInstruction(Instr instr) {
  PrintRegisters();
  PrintStack();
  FATAL("Illegal instruction: 0x%08x", instr.encoding());
}

void Simulator::IllegalInstruction(CInstr instr) {
  PrintRegisters();
  PrintStack();
  FATAL("Illegal instruction: 0x%04x", instr.encoding());
}

template <typename type>
type Simulator::MemoryRead(uintx_t addr, Register base) {
#if defined(DEBUG)
  if ((base == SP) || (base == FP)) {
    if ((addr + sizeof(type) > stack_base()) || (addr < get_xreg(SP))) {
      PrintRegisters();
      PrintStack();
      FATAL("Out-of-bounds stack access");
    }
  } else {
    const uintx_t kPageSize = 16 * KB;
    if ((addr < kPageSize) || (addr + sizeof(type) >= ~kPageSize)) {
      PrintRegisters();
      PrintStack();
      FATAL("Bad memory access");
    }
  }
#endif
  return LoadUnaligned(reinterpret_cast<type*>(addr));
}

template <typename type>
void Simulator::MemoryWrite(uintx_t addr, type value, Register base) {
#if defined(DEBUG)
  if ((base == SP) || (base == FP)) {
    if ((addr + sizeof(type) > stack_base()) || (addr < get_xreg(SP))) {
      PrintRegisters();
      PrintStack();
      FATAL("Out-of-bounds stack access");
    }
  } else {
    const uintx_t kPageSize = 16 * KB;
    if ((addr < kPageSize) || (addr + sizeof(type) >= ~kPageSize)) {
      PrintRegisters();
      PrintStack();
      FATAL("Bad memory access");
    }
  }
#endif
  StoreUnaligned(reinterpret_cast<type*>(addr), value);
}

enum ControlStatusRegister {
  fflags = 0x001,
  frm = 0x002,
  fcsr = 0x003,
  cycle = 0xC00,
  time = 0xC01,
  instret = 0xC02,
#if XLEN == 32
  cycleh = 0xC80,
  timeh = 0xC81,
  instreth = 0xC82,
#endif
};

intx_t Simulator::CSRRead(uint16_t csr) {
  switch (csr) {
    case fcsr:
      return fcsr_;
    case cycle:
      return instret_ / 2;
    case time:
      return 0;
    case instret:
      return instret_;
#if XLEN == 32
    case cycleh:
      return (instret_ / 2) >> 32;
    case timeh:
      return 0;
    case instreth:
      return instret_ >> 32;
#endif
    default:
      FATAL("Unknown CSR: %d", csr);
  }
}

void Simulator::CSRWrite(uint16_t csr, intx_t value) {
  UNIMPLEMENTED();
}

void Simulator::CSRSet(uint16_t csr, intx_t mask) {
  UNIMPLEMENTED();
}

void Simulator::CSRClear(uint16_t csr, intx_t mask) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // !defined(USING_SIMULATOR)

#endif  // defined TARGET_ARCH_RISCV
