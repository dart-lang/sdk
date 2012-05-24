// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/locations.h"

#include "vm/intermediate_language.h"

namespace dart {


static Register AllocateFreeRegister(
    EmbeddedArray<bool, kNumberOfCpuRegisters>* blocked_registers) {
  for (intptr_t regno = 0; regno < kNumberOfCpuRegisters; regno++) {
    if (!blocked_registers->At(regno)) {
      blocked_registers->SetAt(regno, true);
      return static_cast<Register>(regno);
    }
  }
  UNREACHABLE();
  return kNoRegister;
}


void LocationSummary::AllocateRegisters() {
  EmbeddedArray<bool, kNumberOfCpuRegisters> blocked_registers;

  // Mark all available registers free.
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    blocked_registers[i] = false;
  }

  // Mark all fixed registers as used.
  for (intptr_t i = 0; i < count(); i++) {
    Location loc = in(i);
    if (loc.kind() == Location::kRegister) {
      ASSERT(!blocked_registers[loc.reg()]);
      blocked_registers[loc.reg()] = true;
    }
  }

  // Do not allocate known registers.
  blocked_registers[CTX] = true;
  if (TMP != kNoRegister) {
    blocked_registers[TMP] = true;
  }

  // Allocate all unallocated input locations.
  for (intptr_t i = 0; i < count(); i++) {
    Location loc = in(i);
    if (loc.kind() == Location::kUnallocated) {
      ASSERT(loc.policy() == Location::kRequiresRegister);
      set_in(i, Location::RegisterLocation(
          AllocateFreeRegister(&blocked_registers)));
    }
  }

  Location result_location = out();
  if (result_location.kind() == Location::kUnallocated) {
    switch (result_location.policy()) {
      case Location::kRequiresRegister:
        result_location = Location::RegisterLocation(
            AllocateFreeRegister(&blocked_registers));
        break;
      case Location::kSameAsFirstInput:
        result_location = in(0);
        break;
    }
    set_out(result_location);
  }
}


}  // namespace dart

