// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_X64)

#include "vm/cpu.h"

#include "vm/constants_x64.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"

namespace dart {

void CPU::FlushICache(uword start, uword size) {
  // Nothing to be done here.
}


void CPU::JumpToExceptionHandler(uword program_counter,
                                 uword stack_pointer,
                                 uword frame_pointer,
                                 const Instance& exception_object,
                                 const Instance& stacktrace_object) {
  // The no_gc StackResource is unwound through the tear down of
  // stack resources below.
  NoGCScope no_gc;
  RawInstance* exception = exception_object.raw();
  RawInstance* stacktrace = stacktrace_object.raw();

  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous frames.
  Isolate* isolate = Isolate::Current();
  while (isolate->top_resource() != NULL &&
         (reinterpret_cast<uword>(isolate->top_resource()) < stack_pointer)) {
    isolate->top_resource()->~StackResource();
  }

  // Set up the appropriate register state and jump to the handler.
  ASSERT(kExceptionObjectReg == RAX);
  ASSERT(kStackTraceObjectReg == RDX);
#if defined(TARGET_OS_WINDOWS)
  UNIMPLEMENTED();
#else
  asm volatile("mov %[exception], %%rax;"
               "mov %[stacktrace], %%rdx;"
               "mov %[pc], %%rbx;"
               "mov %[fp], %%rcx;"
               "mov %[sp], %%rdi;"
               "mov %%rcx, %%rbp;"
               "mov %%rdi, %%rsp;"
               "jmp *%%rbx;"
               :
               : [exception] "m" (exception),
                 [stacktrace] "m" (stacktrace),
                 [pc] "m" (program_counter),
                 [sp] "m" (stack_pointer),
                 [fp] "m" (frame_pointer));
#endif
  UNREACHABLE();
}


void CPU::JumpToErrorHandler(
    uword program_counter,
    uword stack_pointer,
    uword frame_pointer,
    const Error& error) {
  // The no_gc StackResource is unwound through the tear down of
  // stack resources below.
  NoGCScope no_gc;
  ASSERT(!error.IsNull());
  RawError* raw_error = error.raw();

  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous frames.
  Isolate* isolate = Isolate::Current();
  while (isolate->top_resource() != NULL &&
         (reinterpret_cast<uword>(isolate->top_resource()) < stack_pointer)) {
    isolate->top_resource()->~StackResource();
  }

  // Set up the error object as the return value in RAX and continue
  // from the invocation stub.
#if defined(TARGET_OS_WINDOWS)
  UNIMPLEMENTED();
#else
  asm volatile("mov %[raw_error], %%rax;"
               "mov %[pc], %%rbx;"
               "mov %[fp], %%rcx;"
               "mov %[sp], %%rdi;"
               "mov %%rcx, %%rbp;"
               "mov %%rdi, %%rsp;"
               "jmp *%%rbx;"
               :
               : [raw_error] "m" (raw_error),
                 [pc] "m" (program_counter),
                 [sp] "m" (stack_pointer),
                 [fp] "m" (frame_pointer));
#endif
  UNREACHABLE();
}


const char* CPU::Id() {
  return "x64";
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
