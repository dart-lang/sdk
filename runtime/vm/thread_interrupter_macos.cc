// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_MACOS)

#include <assert.h>            // NOLINT
#include <errno.h>             // NOLINT
#include <mach/kern_return.h>  // NOLINT
#include <mach/mach.h>         // NOLINT
#include <mach/thread_act.h>   // NOLINT
#include <stdbool.h>           // NOLINT
#include <sys/sysctl.h>        // NOLINT
#include <sys/types.h>         // NOLINT
#include <unistd.h>            // NOLINT

#include "vm/flags.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/signal_handler.h"
#include "vm/thread_interrupter.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, trace_thread_interrupter);

#if defined(HOST_ARCH_X64)
#define THREAD_STATE_FLAVOR x86_THREAD_STATE64
#define THREAD_STATE_FLAVOR_SIZE x86_THREAD_STATE64_COUNT
typedef x86_thread_state64_t thread_state_flavor_t;
#elif defined(HOST_ARCH_ARM64)
#define THREAD_STATE_FLAVOR ARM_THREAD_STATE64
#define THREAD_STATE_FLAVOR_SIZE ARM_THREAD_STATE64_COUNT
typedef arm_thread_state64_t thread_state_flavor_t;
#elif defined(HOST_ARCH_ARM)
#define THREAD_STATE_FLAVOR ARM_THREAD_STATE32
#define THREAD_STATE_FLAVOR_SIZE ARM_THREAD_STATE32_COUNT
typedef arm_thread_state32_t thread_state_flavor_t;
#else
#error "Unsupported architecture."
#endif  // HOST_ARCH_...

class ThreadInterrupterMacOS {
 public:
  explicit ThreadInterrupterMacOS(OSThread* os_thread) : os_thread_(os_thread) {
    ASSERT(os_thread != nullptr);
    mach_thread_ = pthread_mach_thread_np(os_thread->id());
    ASSERT(reinterpret_cast<void*>(mach_thread_) != nullptr);
    res = thread_suspend(mach_thread_);
  }

  void CollectSample() {
    if (res != KERN_SUCCESS) {
      return;
    }
    auto count = static_cast<mach_msg_type_number_t>(THREAD_STATE_FLAVOR_SIZE);
    thread_state_flavor_t state;
    kern_return_t res =
        thread_get_state(mach_thread_, THREAD_STATE_FLAVOR,
                         reinterpret_cast<thread_state_t>(&state), &count);
    ASSERT(res == KERN_SUCCESS);
    Thread* thread = static_cast<Thread*>(os_thread_->thread());
    if (thread == nullptr) {
      return;
    }
    Profiler::SampleThread(thread, ProcessState(state));
  }

  ~ThreadInterrupterMacOS() {
    if (res != KERN_SUCCESS) {
      return;
    }
    res = thread_resume(mach_thread_);
    ASSERT(res == KERN_SUCCESS);
  }

 private:
  static InterruptedThreadState ProcessState(thread_state_flavor_t state) {
    InterruptedThreadState its;
#if defined(HOST_ARCH_X64)
    its.pc = state.__rip;
    its.fp = state.__rbp;
    its.csp = state.__rsp;
    its.dsp = state.__rsp;
    its.lr = 0;
#elif defined(HOST_ARCH_ARM64)
    its.pc = state.__pc;
    its.fp = state.__fp;
    its.csp = state.__sp;
    its.dsp = state.__sp;
    its.lr = state.__lr;
#elif defined(HOST_ARCH_ARM)
    its.pc = state.__pc;
    its.fp = state.__r[7];
    its.csp = state.__sp;
    its.dsp = state.__sp;
    its.lr = state.__lr;
#endif  // HOST_ARCH_...

#if defined(TARGET_ARCH_ARM64) && !defined(USING_SIMULATOR)
    its.dsp = state.__x[SPREG];
#endif
    return its;
  }

  kern_return_t res;
  OSThread* os_thread_;
  mach_port_t mach_thread_;
};

void ThreadInterrupter::InterruptThread(OSThread* os_thread) {
  ASSERT(!OSThread::Compare(OSThread::GetCurrentThreadId(), os_thread->id()));
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter interrupting %p\n", os_thread->id());
  }

  ThreadInterrupter::SampleBufferWriterScope scope;
  if (!scope.CanSample()) {
    return;
  }
  ThreadInterrupterMacOS interrupter(os_thread);
  interrupter.CollectSample();
}

void ThreadInterrupter::InstallSignalHandler() {
  // Nothing to do on MacOS.
}

void ThreadInterrupter::RemoveSignalHandler() {
  // Nothing to do on MacOS.
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined(DART_HOST_OS_MACOS)
