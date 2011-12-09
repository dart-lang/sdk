// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_INSTRUCTIONS_H_
#define VM_INSTRUCTIONS_H_

#include "vm/globals.h"

#if defined(TARGET_ARCH_IA32)
#include "vm/instructions_ia32.h"
#elif defined(TARGET_ARCH_X64)
// No instruction patterns implemented.
#elif defined(TARGET_ARCH_ARM)
// No instruction patterns implemented.
#else
#error Unknown architecture.
#endif

#endif  // VM_INSTRUCTIONS_H_
