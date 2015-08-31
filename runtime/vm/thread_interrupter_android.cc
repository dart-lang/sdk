// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include <sys/syscall.h>  // NOLINT

#include "vm/flags.h"
#include "vm/os.h"
#include "vm/signal_handler.h"
#include "vm/thread_interrupter.h"

namespace dart {

DECLARE_FLAG(bool, thread_interrupter);
DECLARE_FLAG(bool, trace_thread_interrupter);

class ThreadInterrupterAndroid : public AllStatic {
 public:
  static void ThreadInterruptSignalHandler(int signal, siginfo_t* info,
                                           void* context_) {
    if (signal != SIGPROF) {
      return;
    }
    Thread* thread = Thread::Current();
    if (thread == NULL) {
      return;
    }
    ThreadInterruptCallback callback = NULL;
    void* callback_data = NULL;
    if (!thread->IsThreadInterrupterEnabled(&callback, &callback_data)) {
      return;
    }
    // Extract thread state.
    ucontext_t* context = reinterpret_cast<ucontext_t*>(context_);
    mcontext_t mcontext = context->uc_mcontext;
    InterruptedThreadState its;
    its.tid = thread->id();
    its.pc = SignalHandler::GetProgramCounter(mcontext);
    its.fp = SignalHandler::GetFramePointer(mcontext);
    its.csp = SignalHandler::GetCStackPointer(mcontext);
    its.dsp = SignalHandler::GetDartStackPointer(mcontext);
    its.lr = SignalHandler::GetLinkRegister(mcontext);
    callback(its, callback_data);
  }
};


void ThreadInterrupter::InterruptThread(Thread* thread) {
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter interrupting %p\n",
              reinterpret_cast<void*>(thread->id()));
  }
  int result = syscall(__NR_tgkill, getpid(), thread->id(), SIGPROF);
  ASSERT(result == 0);
}


void ThreadInterrupter::InstallSignalHandler() {
  SignalHandler::Install(
      ThreadInterrupterAndroid::ThreadInterruptSignalHandler);
}


void ThreadInterrupter::RemoveSignalHandler() {
  SignalHandler::Remove();
}

}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
