// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_LINUX)

#include <errno.h>  // NOLINT

#include "vm/flags.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/signal_handler.h"
#include "vm/thread_interrupter.h"

namespace dart {

#if defined(DART_INCLUDE_PROFILER)

DECLARE_FLAG(bool, trace_thread_interrupter);

class SignalState : public AllStatic {
 public:
  static bool Start() {
    uword expected = state_.load(std::memory_order_relaxed);
    uword desired;
    do {
      if (!Enabled::decode(expected)) return false;
      desired = Pending::update(Pending::decode(expected) + 1, expected);
    } while (!state_.compare_exchange_weak(expected, desired,
                                           std::memory_order_relaxed));
    return true;
  }

  static void End() {
    uword expected = state_.load(std::memory_order_relaxed);
    uword desired;
    do {
      intptr_t pending = Pending::decode(expected);
      ASSERT(pending > 0);
      desired = Pending::update(pending - 1, expected);
    } while (!state_.compare_exchange_weak(expected, desired,
                                           std::memory_order_relaxed));
  }

  static void Enable() {
    uword expected = state_.load(std::memory_order_relaxed);
    ASSERT(expected == (Enabled::encode(false) | Pending::encode(0)));
    uword desired = Enabled::encode(true) | Pending::encode(0);
    bool success = state_.compare_exchange_strong(expected, desired,
                                                  std::memory_order_relaxed);
    ASSERT(success);
  }

  static void Disable() {
    ASSERT(Enabled::decode(state_.load(std::memory_order_relaxed)));
    uword expected;
    uword desired = Enabled::encode(false) | Pending::encode(0);
    do {
      // Failed CAS updates [expected], recompute.
      expected = Enabled::encode(true) | Pending::encode(0);
    } while (!state_.compare_exchange_weak(expected, desired,
                                           std::memory_order_relaxed));
  }

 private:
  using Enabled = BitField<uword, bool, 0, 1>;
  using Pending =
      BitField<uword, intptr_t, Enabled::kNextBit, kBitsPerWord - 1>;
  static std::atomic<uword> state_;
};

std::atomic<uword> SignalState::state_ = {Enabled::encode(false) |
                                          Pending::encode(0)};

class ThreadInterrupterLinux : public AllStatic {
 public:
  static void ThreadInterruptSignalHandler(int signal,
                                           siginfo_t* info,
                                           void* context_) {
    if (signal != SIGPROF) {
      return;
    }
    Thread* thread = Thread::Current();
    if (thread == nullptr) {
      return;
    }
    if (!SignalState::Start()) {
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
    SignalState::End();
  }
};

void ThreadInterrupter::InterruptThread(OSThread* thread) {
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter interrupting %p\n",
                 reinterpret_cast<void*>(thread->id()));
  }
  int result = pthread_kill(thread->id(), SIGPROF);
  ASSERT((result == 0) || (result == ESRCH));
}

void ThreadInterrupter::InstallSignalHandler() {
  SignalHandler::Install(&ThreadInterrupterLinux::ThreadInterruptSignalHandler);
  SignalState::Enable();
}

void ThreadInterrupter::RemoveSignalHandler() {
  SignalState::Disable();
  SignalHandler::Remove();
}

#endif  // defined(DART_INCLUDE_PROFILER)

}  // namespace dart

#endif  // defined(DART_HOST_OS_LINUX)
