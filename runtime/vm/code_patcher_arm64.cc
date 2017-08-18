// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

class PoolPointerCall : public ValueObject {
 public:
  PoolPointerCall(uword pc, const Code& code)
      : end_(pc), object_pool_(ObjectPool::Handle(code.GetObjectPool())) {
    // Last instruction: blr ip0.
    ASSERT(*(reinterpret_cast<uint32_t*>(end_) - 1) == 0xd63f0200);
    InstructionPattern::DecodeLoadWordFromPool(end_ - 2 * Instr::kInstrSize,
                                               &reg_, &index_);
  }

  intptr_t pp_index() const { return index_; }

  RawCode* Target() const {
    return reinterpret_cast<RawCode*>(object_pool_.ObjectAt(pp_index()));
  }

  void SetTarget(const Code& target) const {
    object_pool_.SetObjectAt(pp_index(), target);
    // No need to flush the instruction cache, since the code is not modified.
  }

 private:
  static const int kCallPatternSize = 3 * Instr::kInstrSize;
  uword end_;
  const ObjectPool& object_pool_;
  Register reg_;
  intptr_t index_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(PoolPointerCall);
};

RawCode* CodePatcher::GetStaticCallTargetAt(uword return_address,
                                            const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  PoolPointerCall call(return_address, code);
  return call.Target();
}

void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    const Code& new_target) {
  PatchPoolPointerCallAt(return_address, code, new_target);
}

void CodePatcher::PatchPoolPointerCallAt(uword return_address,
                                         const Code& code,
                                         const Code& new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  PoolPointerCall call(return_address, code);
  call.SetTarget(new_target);
}

void CodePatcher::InsertDeoptimizationCallAt(uword start) {
  UNREACHABLE();
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
  // The instance call instruction sequence has a variable size on ARM64.
  UNREACHABLE();
  return 0;
}

RawFunction* CodePatcher::GetUnoptimizedStaticCallAt(uword return_address,
                                                     const Code& code,
                                                     ICData* ic_data_result) {
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
                                        const Code& caller_code,
                                        const Object& data,
                                        const Code& target) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  SwitchableCallPattern call(return_address, caller_code);
  call.SetData(data);
  call.SetTarget(target);
}

RawCode* CodePatcher::GetSwitchableCallTargetAt(uword return_address,
                                                const Code& caller_code) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  SwitchableCallPattern call(return_address, caller_code);
  return call.target();
}

RawObject* CodePatcher::GetSwitchableCallDataAt(uword return_address,
                                                const Code& caller_code) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  SwitchableCallPattern call(return_address, caller_code);
  return call.data();
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

#endif  // defined TARGET_ARCH_ARM64
