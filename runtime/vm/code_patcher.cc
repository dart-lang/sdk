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


static void SwapCode(intptr_t num_bytes, char* code, char* buffer) {
  uword code_address = reinterpret_cast<uword>(code);
  for (intptr_t i = 0; i < num_bytes; i++) {
    char tmp = *code;
    *code = *buffer;
    *buffer = tmp;
    code++;
    buffer++;
  }
  CPU::FlushICache(code_address, num_bytes);
  // The buffer is not executed. No need to flush.
}


// The patch code buffer contains the jmp code which will be inserted at
// entry point.
void CodePatcher::PatchEntry(const Code& code) {
  const uword patch_addr = code.GetEntryPatchPc();
  ASSERT(patch_addr != 0);
  JumpPattern jmp_entry(patch_addr, code);
  ASSERT(!jmp_entry.IsValid());
  const uword patch_buffer = code.GetPatchCodePc();
  ASSERT(patch_buffer != 0);
  JumpPattern jmp_patch(patch_buffer, code);
  ASSERT(jmp_patch.IsValid());
  const uword jump_target = jmp_patch.TargetAddress();
  intptr_t length = jmp_patch.pattern_length_in_bytes();
  {
    WritableInstructionsScope writable_code(patch_addr, length);
    WritableInstructionsScope writable_buffer(patch_buffer, length);
    SwapCode(jmp_patch.pattern_length_in_bytes(),
             reinterpret_cast<char*>(patch_addr),
             reinterpret_cast<char*>(patch_buffer));
    jmp_entry.SetTargetAddress(jump_target);
  }
}


// The entry point is a jmp instruction, the patch code buffer contains
// original code, the entry point contains the jump instruction.
void CodePatcher::RestoreEntry(const Code& code) {
  const uword patch_addr = code.GetEntryPatchPc();
  ASSERT(patch_addr != 0);
  JumpPattern jmp_entry(patch_addr, code);
  ASSERT(jmp_entry.IsValid());
  const uword jump_target = jmp_entry.TargetAddress();
  const uword patch_buffer = code.GetPatchCodePc();
  ASSERT(patch_buffer != 0);
  // 'patch_buffer' contains original entry code.
  JumpPattern jmp_patch(patch_buffer, code);
  ASSERT(!jmp_patch.IsValid());
  intptr_t length = jmp_patch.pattern_length_in_bytes();
  {
    WritableInstructionsScope writable_code(patch_addr, length);
    WritableInstructionsScope writable_buffer(patch_buffer, length);
    SwapCode(jmp_patch.pattern_length_in_bytes(),
             reinterpret_cast<char*>(patch_addr),
             reinterpret_cast<char*>(patch_buffer));
    ASSERT(jmp_patch.IsValid());
    jmp_patch.SetTargetAddress(jump_target);
  }
}


bool CodePatcher::IsEntryPatched(const Code& code) {
  const uword patch_addr = code.GetEntryPatchPc();
  if (patch_addr == 0) {
    return false;
  }
  JumpPattern jmp_entry(patch_addr, code);
  return jmp_entry.IsValid();
}


bool CodePatcher::CodeIsPatchable(const Code& code) {
  const uword patch_addr = code.GetEntryPatchPc();
  // Zero means means that the function is not patchable.
  if (patch_addr == 0) {
    return false;
  }
  JumpPattern jmp_entry(patch_addr, code);
  if (code.Size() < (jmp_entry.pattern_length_in_bytes() * 2)) {
    return false;
  }
  const uword limit = patch_addr + jmp_entry.pattern_length_in_bytes();
  // Check no object stored between patch_addr .. limit.
  for (intptr_t i = 0; i < code.pointer_offsets_length(); i++) {
    const uword obj_start = code.GetPointerOffsetAt(i) + code.EntryPoint();
    const uword obj_end  = obj_start + kWordSize;
    if ((obj_start < limit) && (obj_end > patch_addr)) {
      return false;
    }
  }
  return true;
}

}  // namespace dart
