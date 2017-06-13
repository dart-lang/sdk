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
#include <magenta/syscalls/object.h>
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

// A scope within which a target thread is suspended. When the scope is exited,
// the thread is resumed and its handle is closed.
class ThreadSuspendScope {
 public:
  explicit ThreadSuspendScope(mx_handle_t thread_handle)
      : thread_handle_(thread_handle), suspended_(true) {
    mx_status_t status = mx_task_suspend(thread_handle);
    // If a thread is somewhere where suspend is impossible, mx_task_suspend()
    // can return MX_ERR_NOT_SUPPORTED.
    if (status != MX_OK) {
      if (FLAG_trace_thread_interrupter) {
        OS::PrintErr("ThreadInterrupter: mx_task_suspend failed: %s\n",
                     mx_status_get_string(status));
      }
      suspended_ = false;
    }
  }

  ~ThreadSuspendScope() {
    if (suspended_) {
      mx_status_t status = mx_task_resume(thread_handle_, 0);
      if (status != MX_OK) {
        // If we fail to resume a thread, then it's likely the program will
        // hang. Crash instead.
        FATAL1("mx_task_resume failed: %s", mx_status_get_string(status));
      }
    }
    mx_handle_close(thread_handle_);
  }

  bool suspended() const { return suspended_; }

 private:
  mx_handle_t thread_handle_;
  bool suspended_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ThreadSuspendScope);
};

class ThreadInterrupterFuchsia : public AllStatic {
 public:
#if defined(TARGET_ARCH_X64)
  static bool GrabRegisters(mx_handle_t thread, InterruptedThreadState* state) {
    mx_x86_64_general_regs_t regs;
    uint32_t regset_size;
    mx_status_t status = mx_thread_read_state(
        thread, MX_THREAD_STATE_REGSET0, &regs, sizeof(regs), &regset_size);
    if (status != MX_OK) {
      if (FLAG_trace_thread_interrupter) {
        OS::PrintErr("ThreadInterrupter failed to get registers: %s\n",
                     mx_status_get_string(status));
      }
      return false;
    }
    state->pc = static_cast<uintptr_t>(regs.rip);
    state->fp = static_cast<uintptr_t>(regs.rbp);
    state->csp = static_cast<uintptr_t>(regs.rsp);
    state->dsp = static_cast<uintptr_t>(regs.rsp);
    return true;
  }
#elif defined(TARGET_ARCH_ARM64)
  static bool GrabRegisters(mx_handle_t thread, InterruptedThreadState* state) {
    mx_arm64_general_regs_t regs;
    uint32_t regset_size;
    mx_status_t status = mx_thread_read_state(
        thread, MX_THREAD_STATE_REGSET0, &regs, sizeof(regs), &regset_size);
    if (status != MX_OK) {
      if (FLAG_trace_thread_interrupter) {
        OS::PrintErr("ThreadInterrupter failed to get registers: %s\n",
                     mx_status_get_string(status));
      }
      return false;
    }
    state->pc = static_cast<uintptr_t>(regs.pc);
    state->fp = static_cast<uintptr_t>(regs.r[FPREG]);
    state->csp = static_cast<uintptr_t>(regs.sp);
    state->dsp = static_cast<uintptr_t>(regs.r[SPREG]);
    state->lr = static_cast<uintptr_t>(regs.lr);
    return true;
  }
#else
#error "Unsupported architecture"
#endif

  static void Interrupt(OSThread* os_thread) {
    ASSERT(os_thread->id() != MX_KOID_INVALID);
    ASSERT(!OSThread::Compare(OSThread::GetCurrentThreadId(), os_thread->id()));
    mx_status_t status;

    // Get a handle on the target thread.
    const mx_koid_t target_thread_koid = os_thread->id();
    if (FLAG_trace_thread_interrupter) {
      OS::PrintErr("ThreadInterrupter: interrupting thread with koid=%d\n",
                   target_thread_koid);
    }
    mx_handle_t target_thread_handle;
    status = mx_object_get_child(mx_process_self(), target_thread_koid,
                                 MX_RIGHT_SAME_RIGHTS, &target_thread_handle);
    if (status != MX_OK) {
      if (FLAG_trace_thread_interrupter) {
        OS::PrintErr("ThreadInterrupter: mx_object_get_child failed: %s\n",
                     mx_status_get_string(status));
      }
      return;
    }
    if (target_thread_handle == MX_HANDLE_INVALID) {
      if (FLAG_trace_thread_interrupter) {
        OS::PrintErr(
            "ThreadInterrupter: mx_object_get_child gave an invalid "
            "thread handle!");
      }
      return;
    }

    // This scope suspends the thread. When we exit the scope, the thread is
    // resumed, and the thread handle is closed.
    ThreadSuspendScope tss(target_thread_handle);
    if (!tss.suspended()) {
      return;
    }

    // Check that the thread is suspended.
    status = PollThreadUntilSuspended(target_thread_handle);
    if (status != MX_OK) {
      return;
    }

    // Grab the target thread's registers.
    InterruptedThreadState its;
    if (!GrabRegisters(target_thread_handle, &its)) {
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

 private:
  static const char* ThreadStateGetString(uint32_t state) {
    switch (state) {
      case MX_THREAD_STATE_NEW:
        return "MX_THREAD_STATE_NEW";
      case MX_THREAD_STATE_RUNNING:
        return "MX_THREAD_STATE_RUNNING";
      case MX_THREAD_STATE_SUSPENDED:
        return "MX_THREAD_STATE_SUSPENDED";
      case MX_THREAD_STATE_BLOCKED:
        return "MX_THREAD_STATE_BLOCKED";
      case MX_THREAD_STATE_DYING:
        return "MX_THREAD_STATE_DYING";
      case MX_THREAD_STATE_DEAD:
        return "MX_THREAD_STATE_DEAD";
      default:
        return "<Unknown>";
    }
  }

  static mx_status_t PollThreadUntilSuspended(mx_handle_t thread_handle) {
    const intptr_t kMaxPollAttempts = 10;
    intptr_t poll_tries = 0;
    while (poll_tries < kMaxPollAttempts) {
      mx_info_thread_t thread_info;
      mx_status_t status =
          mx_object_get_info(thread_handle, MX_INFO_THREAD, &thread_info,
                             sizeof(thread_info), NULL, NULL);
      poll_tries++;
      if (status != MX_OK) {
        if (FLAG_trace_thread_interrupter) {
          OS::PrintErr("ThreadInterrupter: mx_object_get_info failed: %s\n",
                       mx_status_get_string(status));
        }
        return status;
      }
      if (thread_info.state == MX_THREAD_STATE_SUSPENDED) {
        // Success.
        return MX_OK;
      }
      if (thread_info.state == MX_THREAD_STATE_RUNNING) {
        // Poll.
        continue;
      }
      if (FLAG_trace_thread_interrupter) {
        OS::PrintErr("ThreadInterrupter: Thread is not suspended: %s\n",
                     ThreadStateGetString(thread_info.state));
      }
      return MX_ERR_BAD_STATE;
    }
    if (FLAG_trace_thread_interrupter) {
      OS::PrintErr("ThreadInterrupter: Exceeded max suspend poll tries\n");
    }
    return MX_ERR_BAD_STATE;
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
  ThreadInterrupterFuchsia::Interrupt(thread);
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter resuming %p\n",
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
