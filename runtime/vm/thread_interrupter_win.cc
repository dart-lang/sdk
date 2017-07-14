// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "vm/flags.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/thread_interrupter.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, thread_interrupter);
DECLARE_FLAG(bool, trace_thread_interrupter);

#define kThreadError -1

class ThreadInterrupterWin : public AllStatic {
 public:
  static bool GrabRegisters(HANDLE handle, InterruptedThreadState* state) {
    CONTEXT context;
    memset(&context, 0, sizeof(context));
#if defined(HOST_ARCH_IA32)
    // On IA32, CONTEXT_CONTROL includes Eip, Ebp, and Esp.
    context.ContextFlags = CONTEXT_CONTROL;
#elif defined(HOST_ARCH_X64)
    // On X64, CONTEXT_CONTROL includes Rip and Rsp. Rbp is classified
    // as an "integer" register.
    context.ContextFlags = CONTEXT_CONTROL | CONTEXT_INTEGER;
#else
#error Unsupported architecture.
#endif
    if (GetThreadContext(handle, &context) != 0) {
#if defined(HOST_ARCH_IA32)
      state->pc = static_cast<uintptr_t>(context.Eip);
      state->fp = static_cast<uintptr_t>(context.Ebp);
      state->csp = static_cast<uintptr_t>(context.Esp);
      state->dsp = static_cast<uintptr_t>(context.Esp);
#elif defined(HOST_ARCH_X64)
      state->pc = static_cast<uintptr_t>(context.Rip);
      state->fp = static_cast<uintptr_t>(context.Rbp);
      state->csp = static_cast<uintptr_t>(context.Rsp);
      state->dsp = static_cast<uintptr_t>(context.Rsp);
#else
#error Unsupported architecture.
#endif
      return true;
    }
    return false;
  }

  static void Interrupt(OSThread* os_thread) {
    ASSERT(!OSThread::Compare(GetCurrentThreadId(), os_thread->id()));
    HANDLE handle = OpenThread(
        THREAD_GET_CONTEXT | THREAD_QUERY_INFORMATION | THREAD_SUSPEND_RESUME,
        false, os_thread->id());
    ASSERT(handle != NULL);
    DWORD result = SuspendThread(handle);
    if (result == kThreadError) {
      if (FLAG_trace_thread_interrupter) {
        OS::PrintErr("ThreadInterrupter failed to suspend thread %p\n",
                     reinterpret_cast<void*>(os_thread->id()));
      }
      CloseHandle(handle);
      return;
    }
    InterruptedThreadState its;
    if (!GrabRegisters(handle, &its)) {
      // Failed to get thread registers.
      ResumeThread(handle);
      if (FLAG_trace_thread_interrupter) {
        OS::PrintErr("ThreadInterrupter failed to get registers for %p\n",
                     reinterpret_cast<void*>(os_thread->id()));
      }
      CloseHandle(handle);
      return;
    }
    // Currently we sample only threads that are associated
    // with an isolate. It is safe to call 'os_thread->thread()'
    // here as the thread which is being queried is suspended.
    Thread* thread = os_thread->thread();
    if (thread != NULL) {
      Profiler::SampleThread(thread, its);
    }
    ResumeThread(handle);
    CloseHandle(handle);
  }
};

bool ThreadInterrupter::IsDebuggerAttached() {
  return false;
}

void ThreadInterrupter::InterruptThread(OSThread* thread) {
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter suspending %p\n",
                 reinterpret_cast<void*>(thread->id()));
  }
  ThreadInterrupterWin::Interrupt(thread);
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter resuming %p\n",
                 reinterpret_cast<void*>(thread->id()));
  }
}

void ThreadInterrupter::InstallSignalHandler() {
  // Nothing to do on Windows.
}

void ThreadInterrupter::RemoveSignalHandler() {
  // Nothing to do on Windows.
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
