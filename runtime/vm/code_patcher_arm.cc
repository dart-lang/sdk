// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/code_patcher.h"

#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

RawCode* CodePatcher::GetStaticCallTargetAt(uword return_address,
                                            const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  return call.TargetCode();
}

void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    const Code& new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  call.SetTargetCode(new_target);
}

void CodePatcher::InsertDeoptimizationCallAt(uword start) {
  UNREACHABLE();
}

RawCode* CodePatcher::GetInstanceCallAt(uword return_address,
                                        const Code& caller_code,
                                        Object* data) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  ICCallPattern call(return_address, caller_code);
  if (data != NULL) {
    *data = call.Data();
  }
  return call.TargetCode();
}

void CodePatcher::PatchInstanceCallAt(uword return_address,
                                      const Code& caller_code,
                                      const Object& data,
                                      const Code& target) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  ICCallPattern call(return_address, caller_code);
  call.SetData(data);
  call.SetTargetCode(target);
}

RawFunction* CodePatcher::GetUnoptimizedStaticCallAt(uword return_address,
                                                     const Code& caller_code,
                                                     ICData* ic_data_result) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  ICCallPattern static_call(return_address, caller_code);
  ICData& ic_data = ICData::Handle();
  ic_data ^= static_call.Data();
  if (ic_data_result != NULL) {
    *ic_data_result = ic_data.raw();
  }
  return ic_data.GetTargetAt(0);
}

void CodePatcher::PatchSwitchableCallAt(uword return_address,
                                        const Code& caller_code,
                                        const Object& data,
                                        const Code& target) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    BareSwitchableCallPattern call(return_address, caller_code);
    call.SetData(data);
    call.SetTarget(target);
  } else {
    SwitchableCallPattern call(return_address, caller_code);
    call.SetData(data);
    call.SetTarget(target);
  }
}

RawCode* CodePatcher::GetSwitchableCallTargetAt(uword return_address,
                                                const Code& caller_code) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    BareSwitchableCallPattern call(return_address, caller_code);
    return call.target();
  } else {
    SwitchableCallPattern call(return_address, caller_code);
    return call.target();
  }
}

RawObject* CodePatcher::GetSwitchableCallDataAt(uword return_address,
                                                const Code& caller_code) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    BareSwitchableCallPattern call(return_address, caller_code);
    return call.data();
  } else {
    SwitchableCallPattern call(return_address, caller_code);
    return call.data();
  }
}

void CodePatcher::PatchNativeCallAt(uword return_address,
                                    const Code& code,
                                    NativeFunction target,
                                    const Code& trampoline) {
  ASSERT(code.ContainsInstructionAt(return_address));
  NativeCallPattern call(return_address, code);
  call.set_target(trampoline);
  call.set_native_function(target);
}

RawCode* CodePatcher::GetNativeCallAt(uword return_address,
                                      const Code& code,
                                      NativeFunction* target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  NativeCallPattern call(return_address, code);
  *target = call.native_function();
  return call.target();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
