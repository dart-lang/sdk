// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/instructions.h"
#include "vm/instructions_kbc.h"

#include "vm/constants_kbc.h"
#include "vm/native_entry.h"

namespace dart {

TypedDataPtr KBCNativeCallPattern::GetNativeEntryDataAt(
    uword pc,
    const Bytecode& bytecode) {
  ASSERT(bytecode.ContainsInstructionAt(pc));

  const KBCInstr* return_addr = reinterpret_cast<const KBCInstr*>(pc);
  const KBCInstr* instr =
      reinterpret_cast<const KBCInstr*>(bytecode.PayloadStart());
  ASSERT(instr < return_addr);
  while (!KernelBytecode::IsNativeCallOpcode(instr)) {
    instr = KernelBytecode::Next(instr);
    if (instr >= return_addr) {
      FATAL1(
          "Unable to find NativeCall bytecode instruction"
          " corresponding to PC %" Px,
          pc);
    }
  }

  intptr_t native_entry_data_pool_index = KernelBytecode::DecodeD(instr);
  const ObjectPool& obj_pool = ObjectPool::Handle(bytecode.object_pool());
  TypedData& native_entry_data = TypedData::Handle();
  native_entry_data ^= obj_pool.ObjectAt(native_entry_data_pool_index);
  // Native calls to recognized functions should never be patched.
  ASSERT(NativeEntryData(native_entry_data).kind() ==
         MethodRecognizer::kUnknown);
  return native_entry_data.raw();
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
