// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "vm/thread_interrupter.h"

namespace dart {

DECLARE_FLAG(bool, thread_interrupter);
DECLARE_FLAG(bool, trace_thread_interrupter);

#define kThreadError -1

class ThreadInterrupterWin : public AllStatic {
 public:
  static bool GrabRegisters(ThreadId thread, InterruptedThreadState* state) {
    CONTEXT context;
    memset(&context, 0, sizeof(context));
    context.ContextFlags = CONTEXT_FULL;
    if (GetThreadContext(thread, &context) != 0) {
#if defined(TARGET_ARCH_IA32)
      state->pc = static_cast<uintptr_t>(context.Eip);
      state->fp = static_cast<uintptr_t>(context.Ebp);
      state->sp = static_cast<uintptr_t>(context.Esp);
#elif defined(TARGET_ARCH_X64)
      state->pc = reinterpret_cast<uintptr_t>(context.Rip);
      state->fp = reinterpret_cast<uintptr_t>(context.Rbp);
      state->sp = reinterpret_cast<uintptr_t>(context.Rsp);
#else
      UNIMPLEMENTED();
#endif
      return true;
    }
    return false;
  }


  static void Interrupt(InterruptableThreadState* state) {
    ASSERT(GetCurrentThread() != state->id);
    DWORD result = SuspendThread(state->id);
    if (result == kThreadError) {
      if (FLAG_trace_thread_interrupter) {
        OS::Print("ThreadInterrupted failed to suspend thread %p\n",
                  reinterpret_cast<void*>(state->id));
      }
      return;
    }
    InterruptedThreadState its;
    its.tid = state->id;
    if (!GrabRegisters(state->id, &its)) {
      // Failed to get thread registers.
      ResumeThread(state->id);
      if (FLAG_trace_thread_interrupter) {
        OS::Print("ThreadInterrupted failed to get registers for %p\n",
                  reinterpret_cast<void*>(state->id));
      }
      return;
    }
    if (state->callback == NULL) {
      // No callback registered.
      ResumeThread(state->id);
      return;
    }
    state->callback(its, state->data);
    ResumeThread(state->id);
  }
};


void ThreadInterrupter::InterruptThread(InterruptableThreadState* state) {
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter suspending %p\n",
              reinterpret_cast<void*>(state->id));
  }
  ThreadInterrupterWin::Interrupt(state);
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter resuming %p\n",
              reinterpret_cast<void*>(state->id));
  }
}


void ThreadInterrupter::InstallSignalHandler() {
  // Nothing to do on Windows.
}


}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)

