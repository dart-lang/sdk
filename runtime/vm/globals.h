// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_GLOBALS_H_
#define RUNTIME_VM_GLOBALS_H_

// This file contains global definitions for the VM library only. Anything that
// is more globally useful should be added to 'vm/globals.h'.

#include "platform/globals.h"

#if defined(_WIN32)
// Undef conflicting defines.
#undef PARITY_EVEN
#undef PARITY_ODD
#undef near
#endif  // defined(_WIN32)

// The following #defines are invalidated.
#undef OVERFLOW  // From math.h conflicts in constants_ia32.h

namespace dart {
// Smi value range is from -(2^N) to (2^N)-1.
// N=30 (32-bit build) or N=62 (64-bit build).
const intptr_t kSmiBits = kBitsPerWord - 2;
const intptr_t kSmiMax = (static_cast<intptr_t>(1) << kSmiBits) - 1;
const intptr_t kSmiMin = -(static_cast<intptr_t>(1) << kSmiBits);

// Hard coded from above but for 32-bit architectures.
const intptr_t kSmiBits32 = kBitsPerInt32 - 2;
const intptr_t kSmiMax32 = (static_cast<intptr_t>(1) << kSmiBits32) - 1;
const intptr_t kSmiMin32 = -(static_cast<intptr_t>(1) << kSmiBits32);

#define kPosInfinity bit_cast<double>(DART_UINT64_C(0x7ff0000000000000))
#define kNegInfinity bit_cast<double>(DART_UINT64_C(0xfff0000000000000))

// The expression ARRAY_SIZE(array) is a compile-time constant of type
// size_t which represents the number of elements of the given
// array. You should only use ARRAY_SIZE on statically allocated
// arrays.
#define ARRAY_SIZE(array)                                                      \
  ((sizeof(array) / sizeof(*(array))) /                                        \
   static_cast<intptr_t>(!(sizeof(array) % sizeof(*(array)))))  // NOLINT


// The expression OFFSET_OF(type, field) computes the byte-offset of
// the specified field relative to the containing type.
//
// The expression OFFSET_OF_RETURNED_VALUE(type, accessor) computes the
// byte-offset of the return value of the accessor to the containing type.
//
// None of these use 0 or NULL, which causes a problem with the compiler
// warnings we have enabled (which is also why 'offsetof' doesn't seem to work).
// The workaround is to use the non-zero value kOffsetOfPtr.
const intptr_t kOffsetOfPtr = 32;

#define OFFSET_OF(type, field)                                                 \
  (reinterpret_cast<intptr_t>(                                                 \
       &(reinterpret_cast<type*>(kOffsetOfPtr)->field)) -                      \
   kOffsetOfPtr)  // NOLINT

#define OFFSET_OF_RETURNED_VALUE(type, accessor)                               \
  (reinterpret_cast<intptr_t>(                                                 \
       (reinterpret_cast<type*>(kOffsetOfPtr)->accessor())) -                  \
   kOffsetOfPtr)  // NOLINT

#define OPEN_ARRAY_START(type, align)                                          \
  do {                                                                         \
    const uword result = reinterpret_cast<uword>(this) + sizeof(*this);        \
    ASSERT(Utils::IsAligned(result, sizeof(align)));                           \
    return reinterpret_cast<type*>(result);                                    \
  } while (0)


// A type large enough to contain the value of the C++ vtable. This is needed
// to support the handle operations.
typedef uword cpp_vtable;


// When using GCC we can use GCC attributes to ensure that certain
// contants are 8 or 16 byte aligned.
#if defined(TARGET_OS_WINDOWS)
#define ALIGN8 __declspec(align(8))
#define ALIGN16 __declspec(align(16))
#else
#define ALIGN8 __attribute__((aligned(8)))
#define ALIGN16 __attribute__((aligned(16)))
#endif


// Zap value used to indicate uninitialized handle area (debug purposes).
#if defined(ARCH_IS_32_BIT)
static const uword kZapUninitializedWord = 0xabababab;
#else
static const uword kZapUninitializedWord = 0xabababababababab;
#endif


// Macros to get the contents of the fp register.
#if defined(TARGET_OS_WINDOWS)

// clang-format off
#if defined(HOST_ARCH_IA32)
#define COPY_FP_REGISTER(fp)                                                   \
  __asm { mov fp, ebp}                                                         \
  ;  // NOLINT
// clang-format on
#elif defined(HOST_ARCH_X64)
// We don't have the asm equivalent to get at the frame pointer on
// windows x64, return the stack pointer instead.
#define COPY_FP_REGISTER(fp) fp = Thread::GetCurrentStackPointer();
#else
#error Unknown host architecture.
#endif

#else  // !defined(TARGET_OS_WINDOWS))

// Assume GCC-like inline syntax is valid.
#if defined(HOST_ARCH_IA32)
#define COPY_FP_REGISTER(fp) asm volatile("movl %%ebp, %0" : "=r"(fp));
#elif defined(HOST_ARCH_X64)
#define COPY_FP_REGISTER(fp) asm volatile("movq %%rbp, %0" : "=r"(fp));
#elif defined(HOST_ARCH_ARM)
#if defined(TARGET_OS_MAC)
#define COPY_FP_REGISTER(fp) asm volatile("mov %0, r7" : "=r"(fp));
#else
#define COPY_FP_REGISTER(fp) asm volatile("mov %0, r11" : "=r"(fp));
#endif
#elif defined(HOST_ARCH_ARM64)
#define COPY_FP_REGISTER(fp) asm volatile("mov %0, x29" : "=r"(fp));
#elif defined(HOST_ARCH_MIPS)
#define COPY_FP_REGISTER(fp) asm volatile("move %0, $fp" : "=r"(fp));
#else
#error Unknown host architecture.
#endif


#endif  // !defined(TARGET_OS_WINDOWS))

// Default value for flag --use-corelib-source-files.
#if defined(TARGET_OS_WINDOWS)
static const bool kDefaultCorelibSourceFlag = true;
#else
static const bool kDefaultCorelibSourceFlag = false;
#endif  // defined(TARGET_OS_WINDOWS)

}  // namespace dart

#endif  // RUNTIME_VM_GLOBALS_H_
