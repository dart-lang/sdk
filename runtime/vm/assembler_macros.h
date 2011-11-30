// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSEMBLER_MACROS_H_
#define VM_ASSEMBLER_MACROS_H_

#if defined(TARGET_ARCH_IA32)
#include "vm/assembler_macros_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/assembler_macros_x64.h"
#elif defined(TARGET_ARCH_ARM)
// Not yet implemented.
#else
#error Unknown architecture.
#endif

#endif  // VM_ASSEMBLER_MACROS_H_
