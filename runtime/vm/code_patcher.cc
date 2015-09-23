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
    bool status = VirtualMemory::Protect(reinterpret_cast<void*>(address),
                                         size,
                                         VirtualMemory::kReadWrite);
    ASSERT(status);
  }
}


WritableInstructionsScope::~WritableInstructionsScope() {
  if (FLAG_write_protect_code) {
    bool status = VirtualMemory::Protect(reinterpret_cast<void*>(address_),
                                         size_,
                                         VirtualMemory::kReadExecute);
    ASSERT(status);
  }
}


// The patch code buffer contains the jmp code which will be inserted at
// entry point.
void CodePatcher::PatchEntry(const Code& code, const Code& new_code) {
  ASSERT(code.instructions() == code.active_instructions());
  code.set_active_instructions(new_code.instructions());
}


// The entry point is a jmp instruction, the patch code buffer contains
// original code, the entry point contains the jump instruction.
void CodePatcher::RestoreEntry(const Code& code) {
  if (!IsEntryPatched(code)) return;
  ASSERT(code.instructions() != code.active_instructions());
  code.set_active_instructions(code.instructions());
}


bool CodePatcher::IsEntryPatched(const Code& code) {
  return code.instructions() != code.active_instructions();
}

}  // namespace dart
