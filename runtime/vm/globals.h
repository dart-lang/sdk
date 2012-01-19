// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_GLOBALS_H_
#define VM_GLOBALS_H_

// This file contains global definitions for the VM library only. Anything that
// is more globally useful should be added to 'vm/globals.h'.

#include "platform/globals.h"

#if defined(_WIN32)
// Undef conflicting defines.
#undef PARITY_EVEN
#undef PARITY_ODD
#undef near
#endif

// The following #defines are invalidated.
#undef OVERFLOW  // From math.h conflicts in constants_ia32.h

namespace dart {

// The expression ARRAY_SIZE(array) is a compile-time constant of type
// size_t which represents the number of elements of the given
// array. You should only use ARRAY_SIZE on statically allocated
// arrays.
#define ARRAY_SIZE(array)                                       \
  ((sizeof(array) / sizeof(*(array))) /                         \
  static_cast<intptr_t>(!(sizeof(array) % sizeof(*(array)))))


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
  (reinterpret_cast<intptr_t>(&(reinterpret_cast<type*>(kOffsetOfPtr)->field)) \
      - kOffsetOfPtr)

#define OFFSET_OF_RETURNED_VALUE(type, accessor)                            \
  (reinterpret_cast<intptr_t>(                                              \
      (reinterpret_cast<type*>(kOffsetOfPtr)->accessor())) - kOffsetOfPtr)


// A type large enough to contain the value of the C++ vtable. This is needed
// to support the handle operations.
typedef uword cpp_vtable;


// When using GCC we can use GCC attributes to ensure that certain
// contants are 16 byte aligned.
#if defined(TARGET_OS_WINDOWS)
#define ALIGN16 __declspec(align(16))
#else
#define ALIGN16 __attribute__((aligned(16)))
#endif

}  // namespace dart

#endif  // VM_GLOBALS_H_
