// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#include "vm/instructions.h"
#include "vm/signal_handler.h"
#include "vm/simulator.h"
#if defined(DART_HOST_OS_ANDROID)

namespace dart {

uintptr_t SignalHandler::GetProgramCounter(const mcontext_t& mcontext) {
  uintptr_t pc = 0;

#if defined(HOST_ARCH_IA32)
  pc = static_cast<uintptr_t>(mcontext.gregs[REG_EIP]);
#elif defined(HOST_ARCH_X64)
  pc = static_cast<uintptr_t>(mcontext.gregs[REG_RIP]);
#elif defined(HOST_ARCH_ARM)
  pc = static_cast<uintptr_t>(mcontext.arm_pc);
#elif defined(HOST_ARCH_ARM64)
  pc = static_cast<uintptr_t>(mcontext.pc);
#elif defined(HOST_ARCH_RISCV64)
  pc = static_cast<uintptr_t>(mcontext.__gregs[REG_PC]);
#else
#error Unsupported architecture.
#endif  // HOST_ARCH_...
  return pc;
}

uintptr_t SignalHandler::GetFramePointer(const mcontext_t& mcontext) {
  uintptr_t fp = 0;

#if defined(HOST_ARCH_IA32)
  fp = static_cast<uintptr_t>(mcontext.gregs[REG_EBP]);
#elif defined(HOST_ARCH_X64)
  fp = static_cast<uintptr_t>(mcontext.gregs[REG_RBP]);
#elif defined(HOST_ARCH_ARM)
  // B1.3.3 Program Status Registers (PSRs)
  if ((mcontext.arm_cpsr & (1 << 5)) != 0) {
    // Thumb mode.
    fp = static_cast<uintptr_t>(mcontext.arm_r7);
  } else {
    // ARM mode.
    fp = static_cast<uintptr_t>(mcontext.arm_fp);
  }
#elif defined(HOST_ARCH_ARM64)
  fp = static_cast<uintptr_t>(mcontext.regs[29]);
#elif defined(HOST_ARCH_RISCV64)
  fp = static_cast<uintptr_t>(mcontext.__gregs[REG_S0]);
#else
#error Unsupported architecture.
#endif  // HOST_ARCH_...

  return fp;
}

uintptr_t SignalHandler::GetCStackPointer(const mcontext_t& mcontext) {
  uintptr_t sp = 0;

#if defined(HOST_ARCH_IA32)
  sp = static_cast<uintptr_t>(mcontext.gregs[REG_ESP]);
#elif defined(HOST_ARCH_X64)
  sp = static_cast<uintptr_t>(mcontext.gregs[REG_RSP]);
#elif defined(HOST_ARCH_ARM)
  sp = static_cast<uintptr_t>(mcontext.arm_sp);
#elif defined(HOST_ARCH_ARM64)
  sp = static_cast<uintptr_t>(mcontext.sp);
#elif defined(HOST_ARCH_RISCV64)
  sp = static_cast<uintptr_t>(mcontext.__gregs[REG_SP]);
#else
#error Unsupported architecture.
#endif  // HOST_ARCH_...
  return sp;
}

uintptr_t SignalHandler::GetDartStackPointer(const mcontext_t& mcontext) {
#if defined(TARGET_ARCH_ARM64) && !defined(USING_SIMULATOR)
  return static_cast<uintptr_t>(mcontext.regs[SPREG]);
#else
  return GetCStackPointer(mcontext);
#endif
}

uintptr_t SignalHandler::GetLinkRegister(const mcontext_t& mcontext) {
  uintptr_t lr = 0;

#if defined(HOST_ARCH_IA32)
  lr = 0;
#elif defined(HOST_ARCH_X64)
  lr = 0;
#elif defined(HOST_ARCH_ARM)
  lr = static_cast<uintptr_t>(mcontext.arm_lr);
#elif defined(HOST_ARCH_ARM64)
  lr = static_cast<uintptr_t>(mcontext.regs[30]);
#elif defined(HOST_ARCH_RISCV64)
  lr = static_cast<uintptr_t>(mcontext.__gregs[REG_RA]);
#else
#error Unsupported architecture.
#endif  // HOST_ARCH_...
  return lr;
}

void SignalHandler::Install(SignalAction action) {
  // Bionic implementation of setjmp temporary mangles SP register
  // in place which breaks signal delivery on the thread stack - when
  // kernel tries to deliver SIGPROF and we are in the middle of
  // setjmp SP value is invalid - might be pointing to random memory
  // or outside of writable space at all. In the first case we
  // get memory corruption and in the second case kernel would send
  // SIGSEGV to the process. See b/152210274 for details.
  // To work around this issue we request SIGPROF signals to be delivered
  // on the alternative signal stack by setting SA_ONSTACK. The stack itself
  // is configured when interrupts are enabled for a particular thread.
  // In reality Bionic's |pthread_create| eagerly creates and assigns an
  // alternative signal stack for each thread. However older versions of Bionic
  // (L and below) make the size of alternative stack too small which causes
  // stack overflows and crashes.
  struct sigaction act = {};
  act.sa_sigaction = action;
  sigemptyset(&act.sa_mask);
  sigaddset(&act.sa_mask, SIGPROF);  // Prevent nested signals.
  act.sa_flags = SA_RESTART | SA_SIGINFO | SA_ONSTACK;
  int r = sigaction(SIGPROF, &act, nullptr);
  ASSERT(r == 0);
}

void SignalHandler::Remove() {
  // Ignore future SIGPROF signals because by default SIGPROF will terminate
  // the process and we may have some signals in flight.
  struct sigaction act = {};
  act.sa_handler = SIG_IGN;
  sigemptyset(&act.sa_mask);
  int r = sigaction(SIGPROF, &act, nullptr);
  RELEASE_ASSERT(r == 0);
}

void* SignalHandler::PrepareCurrentThread() {
  // These constants are selected to prevent allocating alternative signal
  // stack if Bionic has already allocated large enough one for us. They
  // match current values used in Bionic[1].
  //
  // [1]: https://cs.android.com/android/platform/superproject/main/+/main:bionic/libc/bionic/pthread_internal.h;drc=3649db34a154cedb8ef53a5adbaa349970159b58;l=243
  const intptr_t kGuardPageSize = 4 * KB;
#if defined(TARGET_ARCH_IS_64_BIT)
  const intptr_t kSigAltStackSize = 32 * KB;
#else
  const intptr_t kSigAltStackSize = 16 * KB;
#endif

  // First check if the alternative signal stack is already installed and
  // large enough.
  int r;
  stack_t ss;
  memset(&ss, 0, sizeof(ss));
  r = sigaltstack(nullptr, &ss);
  ASSERT(r == 0);
  if (ss.ss_flags == 0 && ss.ss_size >= (kSigAltStackSize - kGuardPageSize)) {
    // Bionic has created a large enough stack already.
    return nullptr;
  }

  // We are running on an older version of Android, where Bionic creates
  // stacks which are too small.
  ss.ss_sp = malloc(kSigAltStackSize);
  ss.ss_size = kSigAltStackSize;
  ss.ss_flags = 0;
  r = sigaltstack(&ss, nullptr);
  ASSERT(r == 0);

  return ss.ss_sp;
}

void SignalHandler::CleanupCurrentThreadState(void* stack) {
  if (stack != nullptr) {
    // Disable alternative stack then free allocated memory.
    stack_t ss, old_ss;
    memset(&ss, 0, sizeof(ss));
    ss.ss_flags = SS_DISABLE;
    int r = sigaltstack(&ss, &old_ss);
    ASSERT(r == 0);
    ASSERT(old_ss.ss_sp == stack);
    free(stack);
  }
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_ANDROID)
