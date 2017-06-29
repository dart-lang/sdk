// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX)

#include <errno.h>  // NOLINT

#include "vm/flags.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/signal_handler.h"
#include "vm/thread_interrupter.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, thread_interrupter);
DECLARE_FLAG(bool, trace_thread_interrupter);

class ThreadInterrupterLinux : public AllStatic {
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


bool ThreadInterrupter::IsDebuggerAttached() {
  return false;
}


void ThreadInterrupter::InterruptThread(OSThread* thread) {
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter interrupting %p\n",
                 reinterpret_cast<void*>(thread->id()));
  }
  int result = pthread_kill(thread->id(), SIGPROF);
  ASSERT((result == 0) || (result == ESRCH));
}


void ThreadInterrupter::InstallSignalHandler() {
  SignalHandler::Install<
      ThreadInterrupterLinux::ThreadInterruptSignalHandler>();
}


void ThreadInterrupter::RemoveSignalHandler() {
  SignalHandler::Remove();
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined(HOST_OS_LINUX)
