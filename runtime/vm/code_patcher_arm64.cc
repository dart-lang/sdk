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

void CodePatcher::PatchInstanceCallAt(uword return_address,
                                      const Code& code,
                                      uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  call.SetTargetAddress(new_target);
}


class PoolPointerCall : public ValueObject {
 public:
  PoolPointerCall(uword pc, const Code& code)
      : end_(pc),
        object_pool_(ObjectPool::Handle(code.GetObjectPool())) {
    // Last instruction: blr ip0.
    ASSERT(*(reinterpret_cast<uint32_t*>(end_) - 1) == 0xd63f0200);
    InstructionPattern::DecodeLoadWordFromPool(
        end_ - Instr::kInstrSize, &reg_, &index_);
  }

  intptr_t pp_index() const {
    return index_;
  }

  uword Target() const {
    return object_pool_.RawValueAt(pp_index());
  }

  void SetTarget(uword target) const {
    object_pool_.SetRawValueAt(pp_index(), target);
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


uword CodePatcher::GetStaticCallTargetAt(uword return_address,
                                         const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  PoolPointerCall call(return_address, code);
  return call.Target();
}


void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    uword new_target) {
  PatchPoolPointerCallAt(return_address, code, new_target);
}


void CodePatcher::PatchPoolPointerCallAt(uword return_address,
                                         const Code& code,
                                         uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  PoolPointerCall call(return_address, code);
  call.SetTarget(new_target);
}


void CodePatcher::InsertCallAt(uword start, uword target) {
  // The inserted call should not overlap the lazy deopt jump code.
  ASSERT(start + CallPattern::kLengthInBytes <= target);
  CallPattern::InsertAt(start, target);
}


uword CodePatcher::GetInstanceCallAt(uword return_address,
                                     const Code& code,
                                     ICData* ic_data) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  if (ic_data != NULL) {
    *ic_data = call.IcData();
  }
  return call.TargetAddress();
}


intptr_t CodePatcher::InstanceCallSizeInBytes() {
  // The instance call instruction sequence has a variable size on ARM64.
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


void CodePatcher::PatchNativeCallAt(uword return_address,
                                    const Code& code,
                                    NativeFunction target,
                                    const Code& trampoline) {
  ASSERT(code.ContainsInstructionAt(return_address));
  NativeCallPattern call(return_address, code);
  call.set_target(trampoline.EntryPoint());
  call.set_native_function(target);
}


uword CodePatcher::GetNativeCallAt(uword return_address,
                                   const Code& code,
                                   NativeFunction* target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  NativeCallPattern call(return_address, code);
  *target = call.native_function();
  return call.target();
}


// This class pattern matches on a load from the object pool.  Loading on
// ARM64 is complicated because it can take more than one form.  We
// match backwards from the end of the sequence so we can reuse the code for
// matching object pool loads at calls.
class EdgeCounter : public ValueObject {
 public:
  EdgeCounter(uword pc, const Code& code)
      : end_(pc - kAdjust),
        object_pool_(ObjectPool::Handle(code.GetObjectPool())) {
    // An IsValid predicate is complicated and duplicates the code in the
    // decoding function.  Instead we rely on decoding the pattern which
    // will assert partial validity.
  }

  RawObject* edge_counter() const {
    Register ignored;
    intptr_t index;
    InstructionPattern::DecodeLoadWordFromPool(end_, &ignored, &index);
    ASSERT(ignored == R0);
    return object_pool_.ObjectAt(index);
  }

 private:
  // The object pool load is followed by the fixed-size edge counter
  // incrementing code:
  //     ldr ip, [r0, #+11]
  //     adds ip, ip, #2
  //     str ip, [r0, #+11]
  static const intptr_t kAdjust = 3 * Instr::kInstrSize;

  uword end_;
  const ObjectPool& object_pool_;
};


RawObject* CodePatcher::GetEdgeCounterAt(uword pc, const Code& code) {
  ASSERT(code.ContainsInstructionAt(pc));
  EdgeCounter counter(pc, code);
  return counter.edge_counter();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
