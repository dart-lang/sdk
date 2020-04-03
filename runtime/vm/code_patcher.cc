// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/virtual_memory.h"

namespace dart {

DEFINE_FLAG(bool, write_protect_code, true, "Write protect jitted code");

#if defined(DUAL_MAPPING_SUPPORTED)
DEFINE_FLAG(bool, dual_map_code, true, "Dual map jitted code, RW and RX");
#else
DEFINE_FLAG(bool, dual_map_code, false, "Dual map jitted code, RW and RX");
#endif  // defined(DUAL_MAPPING_SUPPORTED)

#if defined(TARGET_ARCH_IA32)
WritableInstructionsScope::WritableInstructionsScope(uword address,
                                                     intptr_t size)
    : address_(address), size_(size) {
  if (FLAG_write_protect_code) {
    VirtualMemory::Protect(reinterpret_cast<void*>(address), size,
                           VirtualMemory::kReadWrite);
  }
}

WritableInstructionsScope::~WritableInstructionsScope() {
  if (FLAG_write_protect_code) {
    VirtualMemory::Protect(reinterpret_cast<void*>(address_), size_,
                           VirtualMemory::kReadExecute);
  }
}
#endif  // defined(TARGET_ARCH_IA32)

bool MatchesPattern(uword end, const int16_t* pattern, intptr_t size) {
  // When breaking within generated code in GDB, it may overwrite individual
  // instructions with trap instructions, which can cause this test to fail.
  //
  // Ignoring trap instructions would work well enough within GDB alone, but it
  // doesn't work in RR, because the check for the trap instrution itself will
  // cause replay to diverge from the original record.
  if (FLAG_support_rr) return true;

  uint8_t* bytes = reinterpret_cast<uint8_t*>(end - size);
  for (intptr_t i = 0; i < size; i++) {
    int16_t val = pattern[i];
    if ((val >= 0) && (val != bytes[i])) {
      return false;
    }
  }
  return true;
}

}  // namespace dart
