// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "vm/thread_interrupter.h"

#include <magenta/process.h>
#include <magenta/status.h>
#include <magenta/syscalls.h>
#include <magenta/syscalls/debug.h>
#include <magenta/types.h>

#include "vm/flags.h"
#include "vm/instructions.h"
#include "vm/os.h"
#include "vm/profiler.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, thread_interrupter);
DECLARE_FLAG(bool, trace_thread_interrupter);

// TODO(MG-430): Currently, CPU profiling for Fuchsia is arranged very similarly
// to our Windows profiling. That is, the interrupter thread iterates over
// all threads, suspends them, samples various things, and then resumes them.
// When MG-430 is resolved, the code below should be rewritten to use whatever
// feature is added for it.

// TODO(zra): The profiler is currently off by default on Fuchsia because
// suspending a thread that is in a call to pthread_cond_wait() causes
// pthread_cond_wait() to return ETIMEDOUT.

class ThreadInterrupterFuchsia : public AllStatic {
 public:
  static bool GrabRegisters(mx_handle_t thread, InterruptedThreadState* state) {
    // TODO(zra): Enable this when mx_thread_read_state() works on suspended
    // threads.
    while (false) {
      char buf[MX_MAX_THREAD_STATE_SIZE];
      uint32_t regset_size = MX_MAX_THREAD_STATE_SIZE;
      mx_status_t status = mx_thread_read_state(
          thread, MX_THREAD_STATE_REGSET0, &buf[0], regset_size, &regset_size);
      if (status != NO_ERROR) {
        OS::PrintErr("ThreadInterrupter failed to get registers: %s\n",
                     mx_status_get_string(status));
        return false;
      }
#if defined(TARGET_ARCH_X64)
      mx_x86_64_general_regs_t* regs =
          reinterpret_cast<mx_x86_64_general_regs_t*>(&buf[0]);
      state->pc = static_cast<uintptr_t>(regs->rip);
      state->fp = static_cast<uintptr_t>(regs->rbp);
      state->csp = static_cast<uintptr_t>(regs->rsp);
      state->dsp = static_cast<uintptr_t>(regs->rsp);
#elif defined(TARGET_ARCH_ARM64)
      mx_aarch64_general_regs_t* regs =
          reinterpret_cast<mx_aarch64_general_regs_t*>(&buf[0]);
      state->pc = static_cast<uintptr_t>(regs->pc);
      state->fp = static_cast<uintptr_t>(regs->r[FPREG]);
      state->csp = static_cast<uintptr_t>(regs->sp);
      state->dsp = static_cast<uintptr_t>(regs->r[SPREG]);
      state->lr = static_cast<uintptr_t>(regs->lr);
#else
#error "Unsupported architecture"
#endif
    }
    return true;
  }


  static void Interrupt(OSThread* os_thread) {
    ASSERT(!OSThread::Compare(OSThread::GetCurrentThreadId(), os_thread->id()));
    mx_status_t status;

    // Get a handle on the target thread.
    mx_koid_t target_thread_koid = os_thread->id();
    if (FLAG_trace_thread_interrupter) {
      OS::Print("ThreadInterrupter: interrupting thread with koid=%d\n",
                target_thread_koid);
    }
    mx_handle_t target_thread_handle;
    status = mx_object_get_child(mx_process_self(), target_thread_koid,
                                 MX_RIGHT_SAME_RIGHTS, &target_thread_handle);
    if (status != NO_ERROR) {
      if (FLAG_trace_thread_interrupter) {
        OS::Print("ThreadInterrupter failed to get the thread handle: %s\n",
                  mx_status_get_string(status));
      }
      FATAL1("mx_object_get_child failed: %s", mx_status_get_string(status));
    }
    if (target_thread_handle == MX_HANDLE_INVALID) {
      FATAL("ThreadInterrupter got an invalid target thread handle!");
    }

    // Pause the target thread.
    status = mx_task_suspend(target_thread_handle);
    if (status != NO_ERROR) {
      if (FLAG_trace_thread_interrupter) {
        OS::Print("ThreadInterrupter failed to suspend thread %ld: %s\n",
                  static_cast<intptr_t>(os_thread->id()),
                  mx_status_get_string(status));
      }
      mx_handle_close(target_thread_handle);
      FATAL1("mx_task_suspend failed: %s", mx_status_get_string(status));
    }

    // TODO(zra): Enable this when mx_thread_read_state() works on suspended
    // threads.
    while (false) {
      // Grab the target thread's registers.
      InterruptedThreadState its;
      if (!GrabRegisters(target_thread_handle, &its)) {
        // Failed to get thread registers.
        status = mx_task_resume(target_thread_handle, 0);
        if (status != NO_ERROR) {
          FATAL1("mx_task_resume failed: %s", mx_status_get_string(status));
        }
        mx_handle_close(target_thread_handle);
        return;
      }
      // Currently we sample only threads that are associated
      // with an isolate. It is safe to call 'os_thread->thread()'
      // here as the thread which is being queried is suspended.
      Thread* thread = os_thread->thread();
      if (thread != NULL) {
        Profiler::SampleThread(thread, its);
      }
    }

    // Resume the target thread.
    status = mx_task_resume(target_thread_handle, 0);
    if (status != NO_ERROR) {
      FATAL1("mx_task_resume failed: %s", mx_status_get_string(status));
    }
    mx_handle_close(target_thread_handle);
  }
};


bool ThreadInterrupter::IsDebuggerAttached() {
  return false;
}


void ThreadInterrupter::InterruptThread(OSThread* thread) {
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter suspending %p\n",
              reinterpret_cast<void*>(thread->id()));
  }
  ThreadInterrupterFuchsia::Interrupt(thread);
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter resuming %p\n",
              reinterpret_cast<void*>(thread->id()));
  }
}


void ThreadInterrupter::InstallSignalHandler() {
  // Nothing to do on Fuchsia.
}


void ThreadInterrupter::RemoveSignalHandler() {
  // Nothing to do on Fuchsia.
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
