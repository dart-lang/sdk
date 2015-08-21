// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/assembler.h"
#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

// The expected pattern of a Dart unoptimized call (static and instance):
//   0: 49 8b 9f imm32  mov RBX, [PP + off]
//   7: 41 ff 97 imm32  call [PP + off]
//  14 <- return address
class UnoptimizedCall : public ValueObject {
 public:
  UnoptimizedCall(uword return_address, const Code& code)
      : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
        start_(return_address - kCallPatternSize) {
    ASSERT(IsValid(return_address));
    ASSERT((kCallPatternSize - 7) == Assembler::kCallExternalLabelSize);
  }

  static const int kCallPatternSize = 14;

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(return_address - kCallPatternSize);
    return (code_bytes[0] == 0x49) && (code_bytes[1] == 0x8B) &&
           (code_bytes[2] == 0x9F) &&
           (code_bytes[7] == 0x41) && (code_bytes[8] == 0xFF) &&
           (code_bytes[9] == 0x97);
  }

  intptr_t argument_index() const {
    return IndexFromPPLoad(start_ + 3);
  }

  RawObject* ic_data() const {
    return object_pool_.ObjectAt(argument_index());
  }

  uword target() const {
    intptr_t index = IndexFromPPLoad(start_ + 10);
    return object_pool_.RawValueAt(index);
  }

  void set_target(uword target) const {
    intptr_t index = IndexFromPPLoad(start_ + 10);
    object_pool_.SetRawValueAt(index, target);
    // No need to flush the instruction cache, since the code is not modified.
  }

 protected:
  const ObjectPool& object_pool_;

 private:
  uword start_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(UnoptimizedCall);
};


class NativeCall : public UnoptimizedCall {
 public:
  NativeCall(uword return_address, const Code& code)
      : UnoptimizedCall(return_address, code) {
  }

  NativeFunction native_function() const {
    return reinterpret_cast<NativeFunction>(
        object_pool_.RawValueAt(argument_index()));
  }

  void set_native_function(NativeFunction func) const {
    object_pool_.SetRawValueAt(argument_index(),
        reinterpret_cast<uword>(func));
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(NativeCall);
};


class InstanceCall : public UnoptimizedCall {
 public:
  InstanceCall(uword return_address, const Code& code)
      : UnoptimizedCall(return_address, code) {
#if defined(DEBUG)
    ICData& test_ic_data = ICData::Handle();
    test_ic_data ^= ic_data();
    ASSERT(test_ic_data.NumArgsTested() > 0);
#endif  // DEBUG
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(InstanceCall);
};


class UnoptimizedStaticCall : public UnoptimizedCall {
 public:
  UnoptimizedStaticCall(uword return_address, const Code& code)
      : UnoptimizedCall(return_address, code) {
#if defined(DEBUG)
    ICData& test_ic_data = ICData::Handle();
    test_ic_data ^= ic_data();
    ASSERT(test_ic_data.NumArgsTested() >= 0);
#endif  // DEBUG
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(UnoptimizedStaticCall);
};


// The expected pattern of a call where the target is loaded from
// the object pool:
//   0: 41 ff 97 imm32  call [PP + off]
//   7: <- return address
class PoolPointerCall : public ValueObject {
 public:
  explicit PoolPointerCall(uword return_address, const Code& code)
      : start_(return_address - kCallPatternSize),
        object_pool_(ObjectPool::Handle(code.GetObjectPool())) {
    ASSERT(IsValid(return_address));
  }

  static const int kCallPatternSize = 7;

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(return_address - kCallPatternSize);
    return (code_bytes[0] == 0x41) && (code_bytes[1] == 0xFF) &&
           (code_bytes[2] == 0x97);
  }

  intptr_t pp_index() const {
    return IndexFromPPLoad(start_ + 3);
  }

  uword Target() const {
    return object_pool_.RawValueAt(pp_index());
  }

  void SetTarget(uword target) const {
    object_pool_.SetRawValueAt(pp_index(), target);
    // No need to flush the instruction cache, since the code is not modified.
  }

 protected:
  uword start_;
  const ObjectPool& object_pool_;

 private:
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


void CodePatcher::PatchInstanceCallAt(uword return_address,
                                      const Code& code,
                                      uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  InstanceCall call(return_address, code);
  call.set_target(new_target);
}


uword CodePatcher::GetInstanceCallAt(uword return_address,
                                     const Code& code,
                                     ICData* ic_data) {
  ASSERT(code.ContainsInstructionAt(return_address));
  InstanceCall call(return_address, code);
  if (ic_data != NULL) {
    *ic_data ^= call.ic_data();
  }
  return call.target();
}


intptr_t CodePatcher::InstanceCallSizeInBytes() {
  return InstanceCall::kCallPatternSize;
}


void CodePatcher::InsertCallAt(uword start, uword target) {
  // The inserted call should not overlap the lazy deopt jump code.
  ASSERT(start + ShortCallPattern::pattern_length_in_bytes() <= target);
  *reinterpret_cast<uint8_t*>(start) = 0xE8;
  ShortCallPattern call(start);
  call.SetTargetAddress(target);
  CPU::FlushICache(start, ShortCallPattern::pattern_length_in_bytes());
}


RawFunction* CodePatcher::GetUnoptimizedStaticCallAt(
    uword return_address, const Code& code, ICData* ic_data_result) {
  ASSERT(code.ContainsInstructionAt(return_address));
  UnoptimizedStaticCall static_call(return_address, code);
  ICData& ic_data = ICData::Handle();
  ic_data ^= static_call.ic_data();
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
  NativeCall call(return_address, code);
  call.set_target(trampoline.EntryPoint());
  call.set_native_function(target);
}


uword CodePatcher::GetNativeCallAt(uword return_address,
                                   const Code& code,
                                   NativeFunction* target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  NativeCall call(return_address, code);
  *target = call.native_function();
  return call.target();
}


// The expected code pattern of an edge counter in unoptimized code:
//  49 8b 87 imm32    mov RAX, [PP + offset]
class EdgeCounter : public ValueObject {
 public:
  EdgeCounter(uword pc, const Code& code)
      : end_(pc - FlowGraphCompiler::EdgeCounterIncrementSizeInBytes()),
        object_pool_(ObjectPool::Handle(code.GetObjectPool())) {
    ASSERT(IsValid(end_));
  }

  static bool IsValid(uword end) {
    uint8_t* bytes = reinterpret_cast<uint8_t*>(end - 7);
    return (bytes[0] == 0x49) && (bytes[1] == 0x8b) && (bytes[2] == 0x87);
  }

  RawObject* edge_counter() const {
    return object_pool_.ObjectAt(IndexFromPPLoad(end_ - 4));
  }

 private:
  uword end_;
  const ObjectPool& object_pool_;
};


RawObject* CodePatcher::GetEdgeCounterAt(uword pc, const Code& code) {
  ASSERT(code.ContainsInstructionAt(pc));
  EdgeCounter counter(pc, code);
  return counter.edge_counter();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
