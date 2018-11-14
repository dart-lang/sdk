// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/code_patcher.h"

#include "vm/instructions_kbc.h"
#include "vm/native_entry.h"

namespace dart {

void KBCPatcher::PatchNativeCallAt(uword return_address,
                                   const Bytecode& bytecode,
                                   NativeFunction function,
                                   NativeFunctionWrapper trampoline) {
  ASSERT(bytecode.ContainsInstructionAt(return_address));
  NativeEntryData native_entry_data(TypedData::Handle(
      KBCNativeCallPattern::GetNativeEntryDataAt(return_address, bytecode)));
  native_entry_data.set_trampoline(trampoline);
  native_entry_data.set_native_function(function);
}

NativeFunctionWrapper KBCPatcher::GetNativeCallAt(uword return_address,
                                                  const Bytecode& bytecode,
                                                  NativeFunction* function) {
  ASSERT(bytecode.ContainsInstructionAt(return_address));
  NativeEntryData native_entry_data(TypedData::Handle(
      KBCNativeCallPattern::GetNativeEntryDataAt(return_address, bytecode)));
  *function = native_entry_data.native_function();
  return native_entry_data.trampoline();
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
