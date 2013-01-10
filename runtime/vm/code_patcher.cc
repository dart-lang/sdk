// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_patcher.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

static void SwapCode(intptr_t num_bytes, char* a, char* b) {
  for (intptr_t i = 0; i < num_bytes; i++) {
    char tmp = *a;
    *a = *b;
    *b = tmp;
    a++;
    b++;
  }
}


// The patch code buffer contains the jmp code which will be inserted at
// entry point.
void CodePatcher::PatchEntry(const Code& code) {
  const uword patch_addr = code.GetPcForDeoptId(Isolate::kNoDeoptId,
                                                PcDescriptors::kEntryPatch);
  JumpPattern jmp_entry(patch_addr);
  ASSERT(!jmp_entry.IsValid());
  const uword patch_buffer = code.GetPatchCodePc();
  ASSERT(patch_buffer != 0);
  JumpPattern jmp_patch(patch_buffer);
  ASSERT(jmp_patch.IsValid());
  const uword jump_target = jmp_patch.TargetAddress();
  SwapCode(jmp_patch.pattern_length_in_bytes(),
           reinterpret_cast<char*>(patch_addr),
           reinterpret_cast<char*>(patch_buffer));
  jmp_entry.SetTargetAddress(jump_target);
}


// The entry point is a jmp instruction, the patch code buffer contains
// original code, the entry point contains the jump instruction.
void CodePatcher::RestoreEntry(const Code& code) {
  const uword patch_addr = code.GetPcForDeoptId(Isolate::kNoDeoptId,
                                                PcDescriptors::kEntryPatch);
  JumpPattern jmp_entry(patch_addr);
  ASSERT(jmp_entry.IsValid());
  const uword jump_target = jmp_entry.TargetAddress();
  const uword patch_buffer = code.GetPatchCodePc();
  ASSERT(patch_buffer != 0);
  // 'patch_buffer' contains original entry code.
  JumpPattern jmp_patch(patch_buffer);
  ASSERT(!jmp_patch.IsValid());
  SwapCode(jmp_patch.pattern_length_in_bytes(),
           reinterpret_cast<char*>(patch_addr),
           reinterpret_cast<char*>(patch_buffer));
  ASSERT(jmp_patch.IsValid());
  jmp_patch.SetTargetAddress(jump_target);
}


bool CodePatcher::CodeIsPatchable(const Code& code) {
  const uword patch_addr = code.GetPcForDeoptId(Isolate::kNoDeoptId,
                                                PcDescriptors::kEntryPatch);
  // kEntryPatch may not exist which means the function is not patchable.
  if (patch_addr == 0) {
    return true;
  }
  JumpPattern jmp_entry(patch_addr);
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
