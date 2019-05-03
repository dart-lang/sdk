// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_H_
#define RUNTIME_VM_CONSTANTS_H_

#if defined(TARGET_ARCH_IA32)
#include "vm/constants_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/constants_x64.h"
#elif defined(TARGET_ARCH_ARM)
#include "vm/constants_arm.h"
#elif defined(TARGET_ARCH_ARM64)
#include "vm/constants_arm64.h"
#elif defined(TARGET_ARCH_DBC)
#include "vm/constants_dbc.h"
#else
#error Unknown architecture.
#endif

#if defined(HOST_ARCH_IA32)
#include "vm/constants_ia32.h"
#elif defined(HOST_ARCH_X64)
#include "vm/constants_x64.h"
#elif defined(HOST_ARCH_ARM)
#include "vm/constants_arm.h"
#elif defined(HOST_ARCH_ARM64)
#include "vm/constants_arm64.h"
#else
#error Unknown host architecture.
#endif

namespace dart {

#if defined(TARGET_ARCH_IA32)
using namespace arch_ia32;  // NOLINT
#elif defined(TARGET_ARCH_X64)
using namespace arch_x64;  // NOLINT
#elif defined(TARGET_ARCH_ARM)
using namespace arch_arm;  // NOLINT
#elif defined(TARGET_ARCH_ARM64)
using namespace arch_arm64;  // NOLINT
#elif defined(TARGET_ARCH_DBC)
// DBC is defined in namespace dart already.
#else
#error Unknown architecture.
#endif

namespace host {

#if defined(HOST_ARCH_IA32)
using namespace arch_ia32;  // NOLINT
#elif defined(HOST_ARCH_X64)
using namespace arch_x64;  // NOLINT
#elif defined(HOST_ARCH_ARM)
using namespace arch_arm;  // NOLINT
#elif defined(HOST_ARCH_ARM64)
using namespace arch_arm64;  // NOLINT
#else
#error Unknown host architecture.
#endif

}  // namespace host

class RegisterNames {
 public:
  static const char* RegisterName(Register reg) {
    ASSERT((0 <= reg) && (reg < kNumberOfCpuRegisters));
    return cpu_reg_names[reg];
  }
  static const char* FpuRegisterName(FpuRegister reg) {
    ASSERT((0 <= reg) && (reg < kNumberOfFpuRegisters));
    return fpu_reg_names[reg];
  }
#if !defined(HOST_ARCH_EQUALS_TARGET_ARCH)
  static const char* RegisterName(host::Register reg) {
    ASSERT((0 <= reg) && (reg < host::kNumberOfCpuRegisters));
    return host::cpu_reg_names[reg];
  }
  static const char* FpuRegisterName(host::FpuRegister reg) {
    ASSERT((0 <= reg) && (reg < host::kNumberOfFpuRegisters));
    return host::fpu_reg_names[reg];
  }
#endif  // !defined(HOST_ARCH_EQUALS_TARGET_ARCH)
};

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_H_
