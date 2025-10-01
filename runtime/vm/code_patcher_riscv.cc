// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_RISCV.
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

class PoolPointerCall : public ValueObject {
 public:
  PoolPointerCall(uword pc, const Code& code)
      : end_(pc), object_pool_(ObjectPool::Handle(code.GetObjectPool())) {
    ASSERT(*reinterpret_cast<uint16_t*>(end_ - 2) == 0x9082);  // jalr ra
    uint32_t load_entry = LoadUnaligned(reinterpret_cast<uint32_t*>(end_ - 6));
#if XLEN == 32
    ASSERT((load_entry == 0x0036a083) ||  // lw ra, entry(tmp)
           (load_entry == 0x00b6a083) ||  // lw ra, unchecked_entry(tmp)
           (load_entry == 0x00362083) ||  // lw ra, entry(code)
           (load_entry == 0x00b62083));   // lw ra, unchecked_entry(code)
#elif XLEN == 64
    ASSERT((load_entry == 0x0076b083) ||  // ld ra, entry(tmp)
           (load_entry == 0x0176b083) ||  // ld ra, unchecked_entry(tmp)
           (load_entry == 0x00763083) ||  // ld ra, entry(code)
           (load_entry == 0x01763083));   // ld ra, unchecked_entry(code)
#endif
    InstructionPattern::DecodeLoadWordFromPool(end_ - 6, &reg_, &index_);
  }

  intptr_t pp_index() const { return index_; }

  CodePtr Target() const {
    return static_cast<CodePtr>(object_pool_.ObjectAt(pp_index()));
  }

  void SetTarget(const Code& target) const {
    object_pool_.SetObjectAt<std::memory_order_release>(pp_index(), target);
    // No need to flush the instruction cache, since the code is not modified.
  }

 private:
  uword end_;
  const ObjectPool& object_pool_;
  Register reg_;
  intptr_t index_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(PoolPointerCall);
};

CodePtr CodePatcher::GetStaticCallTargetAt(uword return_address,
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
                                                    const Code& code,
                                                    ICData* ic_data_result) {
  ASSERT(code.ContainsInstructionAt(return_address));
  ICCallPattern static_call(return_address, code);
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
  // First update target to a stub that does not read 'data' so that concurrent
  // Dart execution cannot observe the new stub with the old data or the old
  // stub with the new data.
  if (FLAG_precompiled_mode) {
    BareSwitchableCallPattern call(return_address);
    call.SetTargetRelease(StubCode::SwitchableCallMiss());
    call.SetDataRelease(data);
    call.SetTargetRelease(target);
  } else {
    SwitchableCallPattern call(return_address, caller_code);
    call.SetTargetRelease(StubCode::SwitchableCallMiss());
    call.SetDataRelease(data);
    call.SetTargetRelease(target);
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
                                    const Code& caller_code,
                                    NativeFunction target,
                                    const Code& trampoline) {
  Thread::Current()->isolate_group()->RunWithStoppedMutators([&]() {
    ASSERT(caller_code.ContainsInstructionAt(return_address));
    NativeCallPattern call(return_address, caller_code);
    call.set_target(trampoline);
    call.set_native_function(target);
  });
}

CodePtr CodePatcher::GetNativeCallAt(uword return_address,
                                     const Code& caller_code,
                                     NativeFunction* target) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  NativeCallPattern call(return_address, caller_code);
  *target = call.native_function();
  return call.target();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_RISCV
