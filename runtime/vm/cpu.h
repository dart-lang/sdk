// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CPU_H_
#define RUNTIME_VM_CPU_H_

#include "vm/globals.h"
#include "vm/allocation.h"

namespace dart {

// Forward Declarations.
class Error;
class Instance;


class CPU : public AllStatic {
 public:
  static void FlushICache(uword start, uword size);
  static const char* Id();
};

}  // namespace dart

#if defined(TARGET_ARCH_IA32)
#include "vm/cpu_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/cpu_x64.h"
#elif defined(TARGET_ARCH_ARM)
#include "vm/cpu_arm.h"
#elif defined(TARGET_ARCH_ARM64)
#include "vm/cpu_arm64.h"
#elif defined(TARGET_ARCH_DBC)
#include "vm/cpu_dbc.h"
#else
#error Unknown architecture.
#endif

#endif  // RUNTIME_VM_CPU_H_
