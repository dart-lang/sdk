// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"

namespace dart {
namespace compiler {

void Assembler::PushRegisters(const RegisterSet& registers) {
  const intptr_t size = registers.SpillSize();
  if (size == 0) {
    return;
  }

  AddImmediate(SP, SP, -size);
  intptr_t offset = size;
  for (intptr_t i = kNumberOfFpuRegisters - 1; i >= 0; i--) {
    const FRegister reg = static_cast<FRegister>(i);
    if (registers.ContainsFpuRegister(reg)) {
      offset -= kFpuRegisterSize;
      StoreQ(reg, Address(SP, offset));
    }
  }
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    const Register reg = static_cast<Register>(i);
    if (registers.ContainsRegister(reg)) {
      offset -= target::kWordSize;
      Store(reg, Address(SP, offset));
    }
  }
  ASSERT(offset == 0);
}

void Assembler::PopRegisters(const RegisterSet& registers) {
  const intptr_t size = registers.SpillSize();
  if (size == 0) {
    return;
  }

  intptr_t offset = 0;
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    const Register reg = static_cast<Register>(i);
    if (registers.ContainsRegister(reg)) {
      Load(reg, Address(SP, offset));
      offset += target::kWordSize;
    }
  }
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    const FRegister reg = static_cast<FRegister>(i);
    if (registers.ContainsFpuRegister(reg)) {
      LoadQ(reg, Address(SP, offset));
      offset += kFpuRegisterSize;
    }
  }
  ASSERT(offset == size);
  AddImmediate(SP, SP, size);
}

void Assembler::PushRegistersAligned(const RegisterSet& registers,
                                     intptr_t space) {
  PushRegisters(registers);
  const intptr_t aligned_space =
      Utils::RoundUp(registers.SpillSize() + space,
                     OS::ActivationFrameAlignment()) -
      registers.SpillSize();
  if (aligned_space != 0) {
    AddImmediate(SP, SP, -aligned_space);
  }
}

void Assembler::PopRegistersAligned(const RegisterSet& registers,
                                    intptr_t space) {
  const intptr_t aligned_space =
      Utils::RoundUp(registers.SpillSize() + space,
                     OS::ActivationFrameAlignment()) -
      registers.SpillSize();
  if (aligned_space != 0) {
    AddImmediate(SP, SP, aligned_space);
  }
  PopRegisters(registers);
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
