// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include <assert.h>      // NOLINT
#include <errno.h>       // NOLINT
#include <stdbool.h>     // NOLINT
#include <sys/sysctl.h>  // NOLINT
#include <sys/types.h>   // NOLINT
#include <unistd.h>      // NOLINT

#include "vm/flags.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/signal_handler.h"
#include "vm/thread_interrupter.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, thread_interrupter);
DECLARE_FLAG(bool, trace_thread_interrupter);

// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
// Code from https://developer.apple.com/library/content/qa/qa1361/_index.html
bool ThreadInterrupter::IsDebuggerAttached() {
  struct kinfo_proc info;
  // Initialize the flags so that, if sysctl fails for some bizarre
  // reason, we get a predictable result.
  info.kp_proc.p_flag = 0;
  // Initialize mib, which tells sysctl the info we want, in this case
  // we're looking for information about a specific process ID.
  int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};
  size_t size = sizeof(info);

  // Call sysctl.
  size = sizeof(info);
  int junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
  ASSERT(junk == 0);
  // We're being debugged if the P_TRACED flag is set.
  return ((info.kp_proc.p_flag & P_TRACED) != 0);
}

class ThreadInterrupterMacOS : public AllStatic {
 public:
  static void ThreadInterruptSignalHandler(int signal,
                                           siginfo_t* info,
                                           void* context_) {
    if (signal != SIGPROF) {
      return;
    }
    Thread* thread = Thread::Current();
    if (thread == NULL) {
      return;
    }
    // Extract thread state.
    ucontext_t* context = reinterpret_cast<ucontext_t*>(context_);
    mcontext_t mcontext = context->uc_mcontext;
    InterruptedThreadState its;
    its.pc = SignalHandler::GetProgramCounter(mcontext);
    its.fp = SignalHandler::GetFramePointer(mcontext);
    its.csp = SignalHandler::GetCStackPointer(mcontext);
    its.dsp = SignalHandler::GetDartStackPointer(mcontext);
    its.lr = SignalHandler::GetLinkRegister(mcontext);
    Profiler::SampleThread(thread, its);
  }
};

void ThreadInterrupter::InterruptThread(OSThread* thread) {
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter interrupting %p\n", thread->id());
  }
  int result = pthread_kill(thread->id(), SIGPROF);
  ASSERT((result == 0) || (result == ESRCH));
}

void ThreadInterrupter::InstallSignalHandler() {
  SignalHandler::Install<
      ThreadInterrupterMacOS::ThreadInterruptSignalHandler>();
}

void ThreadInterrupter::RemoveSignalHandler() {
  SignalHandler::Remove();
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined(HOST_OS_MACOS)
