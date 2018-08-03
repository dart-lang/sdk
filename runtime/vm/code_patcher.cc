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

bool MatchesPattern(uword addr, int16_t* pattern, intptr_t size) {
  uint8_t* bytes = reinterpret_cast<uint8_t*>(addr);
  for (intptr_t i = 0; i < size; i++) {
    int16_t val = pattern[i];
    if ((val >= 0) && (val != bytes[i])) {
      return false;
    }
  }
  return true;
}

}  // namespace dart
