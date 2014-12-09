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

RawArray* CodePatcher::GetClosureArgDescAt(uword return_address,
                                           const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  return call.ClosureArgumentsDescriptor();
}


uword CodePatcher::GetStaticCallTargetAt(uword return_address,
                                         const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  return call.TargetAddress();
}


void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  call.SetTargetAddress(new_target);
}


void CodePatcher::PatchInstanceCallAt(uword return_address,
                                      const Code& code,
                                      uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  CallPattern call(return_address, code);
  call.SetTargetAddress(new_target);
}


int32_t CodePatcher::GetPoolOffsetAt(uword return_address) {
  UNIMPLEMENTED();
  return 0;
}


void CodePatcher::SetPoolOffsetAt(uword return_address, int32_t offset) {
  UNIMPLEMENTED();
}


void CodePatcher::InsertCallAt(uword start, uword target) {
  // The inserted call should not overlap the lazy deopt jump code.
  ASSERT(start + CallPattern::LengthInBytes() <= target);
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


// This class pattern matches on a load from the object pool.  Loading on
// ARM is complicated because it can take four possible different forms.  We
// match backwards from the end of the sequence so we can reuse the code for
// matching object pool loads at calls.
class EdgeCounter : public ValueObject {
 public:
  EdgeCounter(uword pc, const Code& code)
      : end_(pc - FlowGraphCompiler::EdgeCounterIncrementSizeInBytes()),
        object_pool_(Array::Handle(code.ObjectPool())) {
    // An IsValid predicate is complicated and duplicates the code in the
    // decoding function.  Instead we rely on decoding the pattern which
    // will assert partial validity.
  }

  RawObject* edge_counter() const {
    Register ignored;
    intptr_t index;
    InstructionPattern::DecodeLoadWordFromPool(end_, &ignored, &index);
    ASSERT(ignored == R0);
    return object_pool_.At(index);
  }

 private:
  // The object pool load is followed by the fixed-size edge counter
  // incrementing code:
  //     ldr ip, [r0, #+11]
  //     adds ip, ip, #2
  //     str ip, [r0, #+11]
  static const intptr_t kAdjust = 3 * Instr::kInstrSize;

  uword end_;
  const Array& object_pool_;
};


RawObject* CodePatcher::GetEdgeCounterAt(uword pc, const Code& code) {
  ASSERT(code.ContainsInstructionAt(pc));
  EdgeCounter counter(pc, code);
  return counter.edge_counter();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
