// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/instructions.h"
#include "vm/instructions_kbc.h"

#include "vm/constants_kbc.h"
#include "vm/object.h"

namespace dart {

RawNativeEntryData* KBCNativeCallPattern::GetNativeEntryDataAt(
    uword pc,
    const Code& bytecode) {
  ASSERT(bytecode.ContainsInstructionAt(pc));
  const uword call_pc = pc - sizeof(KBCInstr);
  KBCInstr call_instr = KernelBytecode::At(call_pc);
  ASSERT(KernelBytecode::DecodeOpcode(call_instr) ==
         KernelBytecode::kNativeCall);
  intptr_t native_entry_data_pool_index = KernelBytecode::DecodeD(call_instr);
  const ObjectPool& object_pool = ObjectPool::Handle(bytecode.GetObjectPool());
  NativeEntryData& native_entry_data = NativeEntryData::Handle();
  native_entry_data ^= object_pool.ObjectAt(native_entry_data_pool_index);
  // Native calls to recognized functions should never be patched.
  ASSERT(native_entry_data.kind() == MethodRecognizer::kUnknown);
  return native_entry_data.raw();
}

}  // namespace dart
