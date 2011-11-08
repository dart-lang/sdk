// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_IA32)

#include "vm/cpu.h"

#include "vm/constants_ia32.h"
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
  ASSERT(kExceptionObjectReg == EAX);
  ASSERT(kStackTraceObjectReg == EDX);
#if defined(TARGET_OS_WINDOWS)
  __asm {
    mov eax, exception
    mov edx, stacktrace
    mov ebx, program_counter
    mov ecx, frame_pointer
    mov edi, stack_pointer
    mov ebp, ecx
    mov esp, edi
    jmp ebx
  }
#else
  asm volatile("mov %[exception], %%eax;"
               "mov %[stacktrace], %%edx;"
               "mov %[pc], %%ebx;"
               "mov %[fp], %%ecx;"
               "mov %[sp], %%edi;"
               "mov %%ecx, %%ebp;"
               "mov %%edi, %%esp;"
               "jmp *%%ebx;"
               :
               : [exception] "m" (exception),
                 [stacktrace] "m" (stacktrace),
                 [pc] "m" (program_counter),
                 [sp] "m" (stack_pointer),
                 [fp] "m" (frame_pointer));
#endif
  UNREACHABLE();
}


void CPU::JumpToUnhandledExceptionHandler(
    uword program_counter,
    uword stack_pointer,
    uword frame_pointer,
    const UnhandledException& unhandled_exception_object) {
  NoGCScope no_gc;
  ASSERT(!unhandled_exception_object.IsNull());
  RawUnhandledException* unhandled_exception = unhandled_exception_object.raw();

  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous frames.
  Isolate* isolate = Isolate::Current();
  while (isolate->top_resource() != NULL &&
         (reinterpret_cast<uword>(isolate->top_resource()) < stack_pointer)) {
    isolate->top_resource()->~StackResource();
  }

  // Set up the unhandled exception object as the return value in EAX
  // and continue from the invocation stub.
#if defined(TARGET_OS_WINDOWS)
  __asm {
    mov eax, unhandled_exception
    mov ebx, program_counter
    mov ecx, frame_pointer
    mov edi, stack_pointer
    mov ebp, ecx
    mov esp, edi
    jmp ebx
  }
#else
  asm volatile("mov %[unhandled_exception], %%eax;"
               "mov %[pc], %%ebx;"
               "mov %[fp], %%ecx;"
               "mov %[sp], %%edi;"
               "mov %%ecx, %%ebp;"
               "mov %%edi, %%esp;"
               "jmp *%%ebx;"
               :
               : [unhandled_exception] "m" (unhandled_exception),
                 [pc] "m" (program_counter),
                 [sp] "m" (stack_pointer),
                 [fp] "m" (frame_pointer));
#endif
  UNREACHABLE();
}


const char* CPU::Id() {
  return "ia32";
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
