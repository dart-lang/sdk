// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SIGNAL_HANDLER_H_
#define VM_SIGNAL_HANDLER_H_

#include "vm/allocation.h"
#include "vm/globals.h"

#if defined(TARGET_OS_LINUX)
#include <signal.h>  // NOLINT
#include <ucontext.h>  // NOLINT
#elif defined(TARGET_OS_ANDROID)
#include <asm/signal.h>  // NOLINT
#include <asm/sigcontext.h>  // NOLINT
#elif defined(TARGET_OS_MACOS)
#include <signal.h>  // NOLINT
#include <sys/ucontext.h>  // NOLINT
#elif defined(TARGET_OS_WINDOWS)
// Stub out for windows.
struct siginfo_t;
struct mcontext_t;
struct sigset_t {
};
#endif

namespace dart {

typedef void (*SignalAction)(int signal, siginfo_t* info,
                             void* context);

class SignalHandler : public AllStatic {
 public:
  static void Install(SignalAction action);
  static uintptr_t GetProgramCounter(const mcontext_t& mcontext);
  static uintptr_t GetFramePointer(const mcontext_t& mcontext);
  static uintptr_t GetStackPointer(const mcontext_t& mcontext);
 private:
};


class ScopedSignalBlocker {
 public:
  ScopedSignalBlocker();
  ~ScopedSignalBlocker();

 private:
  sigset_t old_;
};


}  // namespace dart

#endif  // VM_SIGNAL_HANDLER_H_
