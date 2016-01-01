// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/code_patcher.h"

#include "vm/flow_graph_compiler.h"
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


void CodePatcher::InsertDeoptimizationCallAt(uword start, uword target) {
  // The inserted call should not overlap the lazy deopt jump code.
  ASSERT(start + CallPattern::DeoptCallPatternLengthInBytes() <= target);
  CallPattern::InsertDeoptCallAt(start, target);
}


RawCode* CodePatcher::GetInstanceCallAt(uword return_address,
                                        const Code& code,
                                        ICData* ic_data) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  if (ic_data != NULL) {
    *ic_data = call.IcData();
  }
  return call.TargetCode();
}


intptr_t CodePatcher::InstanceCallSizeInBytes() {
  // The instance call instruction sequence has a variable size on ARM.
  UNREACHABLE();
  return 0;
}


RawFunction* CodePatcher::GetUnoptimizedStaticCallAt(
    uword return_address, const Code& code, ICData* ic_data_result) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern static_call(return_address, code);
  ICData& ic_data = ICData::Handle();
  ic_data ^= static_call.IcData();
  if (ic_data_result != NULL) {
    *ic_data_result = ic_data.raw();
  }
  return ic_data.GetTargetAt(0);
}


void CodePatcher::PatchSwitchableCallAt(uword return_address,
                                        const Code& code,
                                        const ICData& ic_data,
                                        const MegamorphicCache& cache,
                                        const Code& lookup_stub) {
  ASSERT(code.ContainsInstructionAt(return_address));
  SwitchableCallPattern call(return_address, code);
  ASSERT(call.cache() == ic_data.raw());
  call.SetLookupStub(lookup_stub);
  call.SetCache(cache);
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
