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
#include <android/api-level.h>  // NOLINT
/* Android <= 19 doesn't have ucontext.h */
#if __ANDROID_API__ <= 19
#include <signal.h>  // NOLINT
#include <asm/sigcontext.h>  // NOLINT
// These are not defined on Android, so we have to define them here.
typedef struct sigcontext mcontext_t;
typedef struct ucontext {
  uint32_t uc_flags;
  struct ucontext *uc_link;
  stack_t uc_stack;
  struct sigcontext uc_mcontext;
  uint32_t uc_sigmask;
} ucontext_t;
#else
// Android > 19 has ucontext.h
#include <signal.h>  // NOLINT
#include <ucontext.h>  // NOLINT
#endif  // __ANDROID_API__ <= 19
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


}  // namespace dart

#endif  // VM_SIGNAL_HANDLER_H_
