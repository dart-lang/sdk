// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_ANDROID)

#include <errno.h>        // NOLINT
#include <sys/syscall.h>  // NOLINT

#include "vm/flags.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/signal_handler.h"
#include "vm/thread_interrupter.h"

namespace dart {

#ifndef PRODUCT

// Old linux kernels on ARM might require a trampoline to
// work around incorrect Thumb -> ARM transitions.
// See thread_interrupted_android_arm.S for more details.
#if defined(HOST_ARCH_ARM) &&                                                  \
    (defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)) &&          \
    !defined(__thumb__)
#define USE_SIGNAL_HANDLER_TRAMPOLINE
#endif

DECLARE_FLAG(bool, trace_thread_interrupter);

namespace {
#if defined(USE_SIGNAL_HANDLER_TRAMPOLINE)
extern "C" {
#endif
void ThreadInterruptSignalHandler(int signal, siginfo_t* info, void* context_) {
  if (signal != SIGPROF) {
    return;
  }
  Thread* thread = Thread::Current();
  if (thread == nullptr) {
    return;
  }
  ThreadInterruptScope signal_handler_scope;
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
#if defined(USE_SIGNAL_HANDLER_TRAMPOLINE)
}  // extern "C"
#endif
}  // namespace

void ThreadInterrupter::InterruptThread(OSThread* thread) {
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter interrupting %p\n",
                 reinterpret_cast<void*>(thread->id()));
  }
  int result = syscall(__NR_tgkill, getpid(), thread->id(), SIGPROF);
  ASSERT((result == 0) || (result == ESRCH));
}

#if defined(USE_SIGNAL_HANDLER_TRAMPOLINE)
// Defined in thread_interrupted_android_arm.S
extern "C" void ThreadInterruptSignalHandlerTrampoline(int signal,
                                                       siginfo_t* info,
                                                       void* context_);
#endif

void ThreadInterrupter::InstallSignalHandler() {
#if defined(USE_SIGNAL_HANDLER_TRAMPOLINE)
  SignalHandler::Install(&ThreadInterruptSignalHandlerTrampoline);
#else
  SignalHandler::Install(&ThreadInterruptSignalHandler);
#endif
}

void ThreadInterrupter::RemoveSignalHandler() {
  SignalHandler::Remove();
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined(DART_HOST_OS_ANDROID)
