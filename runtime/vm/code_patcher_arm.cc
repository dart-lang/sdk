// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/code_patcher.h"

#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

CodePtr CodePatcher::GetStaticCallTargetAt(uword return_address,
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

void CodePatcher::PatchPoolPointerCallAt(uword return_address,
                                         const Code& code,
                                         const Code& new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  call.SetTargetCode(new_target);
}

CodePtr CodePatcher::GetInstanceCallAt(uword return_address,
                                       const Code& caller_code,
                                       Object* data) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  ICCallPattern call(return_address, caller_code);
  if (data != nullptr) {
    *data = call.Data();
  }
  return call.TargetCode();
}

void CodePatcher::PatchInstanceCallAt(uword return_address,
                                      const Code& caller_code,
                                      const Object& data,
                                      const Code& target) {
  auto thread = Thread::Current();
  thread->isolate_group()->RunWithStoppedMutators([&]() {
    PatchInstanceCallAtWithMutatorsStopped(thread, return_address, caller_code,
                                           data, target);
  });
}

void CodePatcher::PatchInstanceCallAtWithMutatorsStopped(
    Thread* thread,
    uword return_address,
    const Code& caller_code,
    const Object& data,
    const Code& target) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  ICCallPattern call(return_address, caller_code);
  call.SetData(data);
  call.SetTargetCode(target);
}

FunctionPtr CodePatcher::GetUnoptimizedStaticCallAt(uword return_address,
                                                    const Code& caller_code,
                                                    ICData* ic_data_result) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  ICCallPattern static_call(return_address, caller_code);
  ICData& ic_data = ICData::Handle();
  ic_data ^= static_call.Data();
  if (ic_data_result != nullptr) {
    *ic_data_result = ic_data.ptr();
  }
  return ic_data.GetTargetAt(0);
}

void CodePatcher::PatchSwitchableCallAt(uword return_address,
                                        const Code& caller_code,
                                        const Object& data,
                                        const Code& target) {
  auto thread = Thread::Current();
  // Ensure all threads are suspended as we update data and target pair.
  thread->isolate_group()->RunWithStoppedMutators([&]() {
    PatchSwitchableCallAtWithMutatorsStopped(thread, return_address,
                                             caller_code, data, target);
  });
}

void CodePatcher::PatchSwitchableCallAtWithMutatorsStopped(
    Thread* thread,
    uword return_address,
    const Code& caller_code,
    const Object& data,
    const Code& target) {
  if (FLAG_precompiled_mode) {
    BareSwitchableCallPattern call(return_address);
    call.SetData(data);
    call.SetTarget(target);
  } else {
    SwitchableCallPattern call(return_address, caller_code);
    call.SetData(data);
    call.SetTarget(target);
  }
}

ObjectPtr CodePatcher::GetSwitchableCallTargetAt(uword return_address,
                                                 const Code& caller_code) {
  if (FLAG_precompiled_mode) {
    UNREACHABLE();
  } else {
    SwitchableCallPattern call(return_address, caller_code);
    return call.target();
  }
}

uword CodePatcher::GetSwitchableCallTargetEntryAt(uword return_address,
                                                  const Code& caller_code) {
  if (FLAG_precompiled_mode) {
    BareSwitchableCallPattern call(return_address);
    return call.target_entry();
  } else {
    UNREACHABLE();
  }
}

ObjectPtr CodePatcher::GetSwitchableCallDataAt(uword return_address,
                                               const Code& caller_code) {
  if (FLAG_precompiled_mode) {
    BareSwitchableCallPattern call(return_address);
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
  Thread::Current()->isolate_group()->RunWithStoppedMutators([&]() {
    ASSERT(code.ContainsInstructionAt(return_address));
    NativeCallPattern call(return_address, code);
    call.set_target(trampoline);
    call.set_native_function(target);
  });
}

CodePtr CodePatcher::GetNativeCallAt(uword return_address,
                                     const Code& code,
                                     NativeFunction* target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  NativeCallPattern call(return_address, code);
  *target = call.native_function();
  return call.target();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
