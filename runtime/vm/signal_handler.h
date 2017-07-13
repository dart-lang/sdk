// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SIGNAL_HANDLER_H_
#define RUNTIME_VM_SIGNAL_HANDLER_H_

#include "vm/allocation.h"
#include "vm/globals.h"

#if defined(HOST_OS_LINUX)
#include <signal.h>    // NOLINT
#include <ucontext.h>  // NOLINT
#elif defined(HOST_OS_ANDROID)
#include <signal.h>  // NOLINT
#if !defined(__BIONIC_HAVE_UCONTEXT_T)
#include <asm/sigcontext.h>  // NOLINT
// If ucontext_t is not defined on Android, define it here.
typedef struct sigcontext mcontext_t;
typedef struct ucontext {
  uint32_t uc_flags;
  struct ucontext* uc_link;
  stack_t uc_stack;
  struct sigcontext uc_mcontext;
  uint32_t uc_sigmask;
} ucontext_t;
#endif                       // !defined(__BIONIC_HAVE_UCONTEXT_T)
#elif defined(HOST_OS_MACOS)
#include <signal.h>        // NOLINT
#include <sys/ucontext.h>  // NOLINT
#elif defined(HOST_OS_WINDOWS)
// Stub out for windows.
struct siginfo_t;
struct mcontext_t;
struct sigset_t {};
#elif defined(HOST_OS_FUCHSIA)
#include <signal.h>    // NOLINT
#include <ucontext.h>  // NOLINT
#endif

// Old linux kernels on ARM might require a trampoline to
// work around incorrect Thumb -> ARM transitions. See SignalHandlerTrampoline
// below for more details.
#if defined(HOST_ARCH_ARM) &&                                                  \
    (defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)) &&                    \
    !defined(__thumb__)
#define USE_SIGNAL_HANDLER_TRAMPOLINE
#endif

namespace dart {

typedef void (*SignalAction)(int signal, siginfo_t* info, void* context);

class SignalHandler : public AllStatic {
 public:
  template <SignalAction action>
  static void Install() {
#if defined(USE_SIGNAL_HANDLER_TRAMPOLINE)
    InstallImpl(SignalHandlerTrampoline<action>);
#else
    InstallImpl(action);
#endif  // defined(USE_SIGNAL_HANDLER_TRAMPOLINE)
  }
  static void Remove();
  static uintptr_t GetProgramCounter(const mcontext_t& mcontext);
  static uintptr_t GetFramePointer(const mcontext_t& mcontext);
  static uintptr_t GetCStackPointer(const mcontext_t& mcontext);
  static uintptr_t GetDartStackPointer(const mcontext_t& mcontext);
  static uintptr_t GetLinkRegister(const mcontext_t& mcontext);

 private:
  static void InstallImpl(SignalAction action);

#if defined(USE_SIGNAL_HANDLER_TRAMPOLINE)
  // Work around for a bug in old kernels (only fixed in 3.18 Android kernel):
  //
  // Kernel does not clear If-Then execution state bits when entering ARM signal
  // handler which violates requirements imposed by ARM architecture reference.
  // Some CPUs look at these bits even while in ARM mode which causes them
  // to skip some instructions in the prologue of the signal handler.
  //
  // To work around the issue we insert enough NOPs in the prologue to ensure
  // that no actual instructions are skipped and then branch to the actual
  // signal handler.
  //
  // For the kernel patch that fixes the issue see:
  // http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=6ecf830e5029598732e04067e325d946097519cb
  //
  // Note: this function is marked "naked" because we must guarantee that
  // our NOPs occur before any compiler generated prologue.
  template <SignalAction action>
  static __attribute__((naked)) void SignalHandlerTrampoline(int signal,
                                                             siginfo_t* info,
                                                             void* context_) {
    // IT (If-Then) instruction makes up to four instructions that follow it
    // conditional.
    asm volatile("nop; nop; nop; nop" : : : "memory");

    // Tail-call into the actual signal handler.
    // Note: this code is split into a separate inline assembly block because
    // any code that compiler generates to satisfy register constraints must
    // be generated after four NOPs.
    register int arg0 asm("r0") = signal;
    register siginfo_t* arg1 asm("r1") = info;
    register void* arg2 asm("r2") = context_;
    asm volatile("bx %3"
                 :
                 : "r"(arg0), "r"(arg1), "r"(arg2), "r"(action)
                 : "memory");
  }
#endif  // defined(USE_SIGNAL_HANDLER_TRAMPOLINE)
};

#undef USE_SIGNAL_HANDLER_TRAMPOLINE

}  // namespace dart

#endif  // RUNTIME_VM_SIGNAL_HANDLER_H_
