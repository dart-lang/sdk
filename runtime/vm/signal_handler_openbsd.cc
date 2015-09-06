// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#include "vm/simulator.h"
#include "vm/signal_handler.h"
#if defined(TARGET_OS_OPENBSD

namespace dart {

uintptr_t SignalHandler::GetProgramCounter(const mcontext_t& mcontext) {
  uintptr_t pc = 0;

#if defined(HOST_ARCH_IA32)
  pc = static_cast<uintptr_t>(mcontext.sc_eip);
#elif defined(HOST_ARCH_X64)
  pc = static_cast<uintptr_t>(mcontext.sc_rip);
#else
#error Unsupported architecture.
#endif  // HOST_ARCH_...
  return pc;
}


uintptr_t SignalHandler::GetFramePointer(const mcontext_t& mcontext) {
  uintptr_t fp = 0;

#if defined(HOST_ARCH_IA32)
  fp = static_cast<uintptr_t>(mcontext.sc_ebp);
#elif defined(HOST_ARCH_X64)
  fp = static_cast<uintptr_t>(mcontext.sc_rbp);
#else
#error Unsupported architecture.
#endif  // HOST_ARCH_...

  return fp;
}


uintptr_t SignalHandler::GetCStackPointer(const mcontext_t& mcontext) {
  uintptr_t sp = 0;

#if defined(HOST_ARCH_IA32)
  sp = static_cast<uintptr_t>(mcontext.sc_esp);
#elif defined(HOST_ARCH_X64)
  sp = static_cast<uintptr_t>(mcontext.sc_rsp);
#else
#error Unsupported architecture.
#endif  // HOST_ARCH_...
  return sp;
}


uintptr_t SignalHandler::GetDartStackPointer(const mcontext_t& mcontext) {
#if defined(TARGET_ARCH_ARM64) && !defined(USING_SIMULATOR)
  return static_cast<uintptr_t>(mcontext.regs[18]);
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
#elif defined(HOST_ARCH_MIPS)
  lr = static_cast<uintptr_t>(mcontext.gregs[31]);
#else
#error Unsupported architecture.
#endif  // HOST_ARCH_...
  return lr;
}


void SignalHandler::Install(SignalAction action) {
  struct sigaction act;
  act.sa_handler = NULL;
  act.sa_sigaction = action;
  sigemptyset(&act.sa_mask);
  act.sa_flags = SA_RESTART | SA_SIGINFO;
  int r = sigaction(SIGPROF, &act, NULL);
  ASSERT(r == 0);
}


void SignalHandler::Remove() {
  // Ignore future SIGPROF signals because by default SIGPROF will terminate
  // the process and we may have some signals in flight.
  struct sigaction act;
  act.sa_handler = SIG_IGN;
  sigemptyset(&act.sa_mask);
  act.sa_flags = 0;
  int r = sigaction(SIGPROF, &act, NULL);
  ASSERT(r == 0);
}


}  // namespace dart

#endif  // defined(TARGET_OS_OPENBSD
