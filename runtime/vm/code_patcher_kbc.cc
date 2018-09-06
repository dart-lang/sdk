// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get DART_USE_INTERPRETER.
#if defined(DART_USE_INTERPRETER)

#include "vm/code_patcher.h"

#include "vm/instructions_kbc.h"
#include "vm/object.h"

namespace dart {

void KBCPatcher::PatchNativeCallAt(uword return_address,
                                   const Code& bytecode,
                                   NativeFunction function,
                                   NativeFunctionWrapper trampoline) {
  ASSERT(bytecode.ContainsInstructionAt(return_address));
  const NativeEntryData& native_entry_data = NativeEntryData::Handle(
      KBCNativeCallPattern::GetNativeEntryDataAt(return_address, bytecode));
  native_entry_data.set_trampoline(trampoline);
  native_entry_data.set_native_function(function);
}

NativeFunctionWrapper KBCPatcher::GetNativeCallAt(uword return_address,
                                                  const Code& bytecode,
                                                  NativeFunction* function) {
  ASSERT(bytecode.ContainsInstructionAt(return_address));
  const NativeEntryData& native_entry_data = NativeEntryData::Handle(
      KBCNativeCallPattern::GetNativeEntryDataAt(return_address, bytecode));
  *function = native_entry_data.native_function();
  return native_entry_data.trampoline();
}

}  // namespace dart

#endif  // defined DART_USE_INTERPRETER
