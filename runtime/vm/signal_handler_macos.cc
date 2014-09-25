// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#include "vm/simulator.h"
#include "vm/signal_handler.h"
#if defined(TARGET_OS_MACOS)

namespace dart {

uintptr_t SignalHandler::GetProgramCounter(const mcontext_t& mcontext) {
  uintptr_t pc = 0;

#if defined(TARGET_ARCH_IA32)
  pc = static_cast<uintptr_t>(mcontext->__ss.__eip);
#elif defined(TARGET_ARCH_X64)
  pc = static_cast<uintptr_t>(mcontext->__ss.__rip);
#elif defined(TARGET_ARCH_MIPS) && defined(USING_SIMULATOR)
  pc = static_cast<uintptr_t>(mcontext->__ss.__eip);
#elif defined(TARGET_ARCH_ARM) && defined(USING_SIMULATOR)
  pc = static_cast<uintptr_t>(mcontext->__ss.__eip);
#elif defined(TARGET_ARCH_ARM64) && defined(USING_SIMULATOR)
  pc = static_cast<uintptr_t>(mcontext->__ss.__rip);
#else
  UNIMPLEMENTED();
#endif  // TARGET_ARCH_...

  return pc;
}


uintptr_t SignalHandler::GetFramePointer(const mcontext_t& mcontext) {
  uintptr_t fp = 0;

#if defined(TARGET_ARCH_IA32)
  fp = static_cast<uintptr_t>(mcontext->__ss.__ebp);
#elif defined(TARGET_ARCH_X64)
  fp = static_cast<uintptr_t>(mcontext->__ss.__rbp);
#elif defined(TARGET_ARCH_MIPS) && defined(USING_SIMULATOR)
  fp = static_cast<uintptr_t>(mcontext->__ss.__ebp);
#elif defined(TARGET_ARCH_ARM) && defined(USING_SIMULATOR)
  fp = static_cast<uintptr_t>(mcontext->__ss.__ebp);
#elif defined(TARGET_ARCH_ARM64) && defined(USING_SIMULATOR)
  fp = static_cast<uintptr_t>(mcontext->__ss.__rbp);
#else
  UNIMPLEMENTED();
#endif  // TARGET_ARCH_...

  return fp;
}


uintptr_t SignalHandler::GetCStackPointer(const mcontext_t& mcontext) {
  uintptr_t sp = 0;

#if defined(TARGET_ARCH_IA32)
  sp = static_cast<uintptr_t>(mcontext->__ss.__esp);
#elif defined(TARGET_ARCH_X64)
  sp = static_cast<uintptr_t>(mcontext->__ss.__rsp);
#elif defined(TARGET_ARCH_MIPS) && defined(USING_SIMULATOR)
  sp = static_cast<uintptr_t>(mcontext->__ss.__esp);
#elif defined(TARGET_ARCH_ARM) && defined(USING_SIMULATOR)
  sp = static_cast<uintptr_t>(mcontext->__ss.__esp);
#elif defined(TARGET_ARCH_ARM64) && defined(USING_SIMULATOR)
  sp = static_cast<uintptr_t>(mcontext->__ss.__rsp);
#else
  UNIMPLEMENTED();
#endif  // TARGET_ARCH_...

  return sp;
}


uintptr_t SignalHandler::GetDartStackPointer(const mcontext_t& mcontext) {
  return GetCStackPointer(mcontext);
}


void SignalHandler::Install(SignalAction action) {
  struct sigaction act;
  act.sa_handler = NULL;
  act.sa_sigaction = action;
  sigemptyset(&act.sa_mask);
  act.sa_flags = SA_RESTART | SA_SIGINFO;
  // TODO(johnmccutchan): Do we care about restoring the signal handler?
  struct sigaction old_act;
  int r = sigaction(SIGPROF, &act, &old_act);
  ASSERT(r == 0);
}


}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)
