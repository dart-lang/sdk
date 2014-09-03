// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#include "vm/simulator.h"
#include "vm/signal_handler.h"
#if defined(TARGET_OS_ANDROID)

namespace dart {

uintptr_t SignalHandler::GetProgramCounter(const mcontext_t& mcontext) {
  uintptr_t pc = 0;

#if defined(TARGET_ARCH_ARM)
  pc = static_cast<uintptr_t>(mcontext.arm_pc);
#elif defined(TARGET_ARCH_ARM64)
  pc = static_cast<uintptr_t>(mcontext.pc);
#else
  UNIMPLEMENTED();
#endif  // TARGET_ARCH_...
  return pc;
}


uintptr_t SignalHandler::GetFramePointer(const mcontext_t& mcontext) {
  uintptr_t fp = 0;

#if defined(TARGET_ARCH_ARM)
  fp = static_cast<uintptr_t>(mcontext.arm_fp);
#elif defined(TARGET_ARCH_ARM64)
  fp = static_cast<uintptr_t>(mcontext.regs[29]);
#else
  UNIMPLEMENTED();
#endif  // TARGET_ARCH_...

  return fp;
}


uintptr_t SignalHandler::GetStackPointer(const mcontext_t& mcontext) {
  uintptr_t sp = 0;

#if defined(TARGET_ARCH_ARM)
  sp = static_cast<uintptr_t>(mcontext.arm_sp);
#elif defined(TARGET_ARCH_ARM64)
  sp = static_cast<uintptr_t>(mcontext.sp);
#else
  UNIMPLEMENTED();
#endif  // TARGET_ARCH_...
  return sp;
}


void SignalHandler::Install(SignalAction action) {
  struct sigaction act;
  memset(&act, 0, sizeof(act));
  act.sa_sigaction = action;
  act.sa_flags = SA_RESTART | SA_SIGINFO;
  sigemptyset(&act.sa_mask);
  // TODO(johnmccutchan): Do we care about restoring the signal handler?
  struct sigaction old_act;
  int r = sigaction(SIGPROF, &act, &old_act);
  ASSERT(r == 0);
}


}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
