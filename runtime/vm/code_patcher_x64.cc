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
//  00: 49 8b 9f imm32  mov RBX, [PP + off]
//  07: 4d 8b 9f imm32  mov R11, [PP + off]
//  14: 41 ff d3        call R11
//  17 <- return address
class UnoptimizedCall : public ValueObject {
 public:
  UnoptimizedCall(uword return_address, const Code& code)
      : start_(return_address - kCallPatternSize),
        object_pool_(Array::Handle(code.ObjectPool())) {
    ASSERT(IsValid(return_address));
    ASSERT((kCallPatternSize - 7) == Assembler::kCallExternalLabelSize);
  }

  static const int kCallPatternSize = 17;

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(return_address - kCallPatternSize);
    return (code_bytes[0] == 0x49) && (code_bytes[1] == 0x8B) &&
           (code_bytes[2] == 0x9F) &&
           (code_bytes[7] == 0x4D) && (code_bytes[8] == 0x8B) &&
           (code_bytes[9] == 0x9F) &&
           (code_bytes[14] == 0x41) && (code_bytes[15] == 0xFF) &&
           (code_bytes[16] == 0xD3);
  }

  RawObject* ic_data() const {
    intptr_t index = InstructionPattern::IndexFromPPLoad(start_ + 3);
    return object_pool_.At(index);
  }

  uword target() const {
    intptr_t index = InstructionPattern::IndexFromPPLoad(start_ + 10);
    return reinterpret_cast<uword>(object_pool_.At(index));
  }

  void set_target(uword target) const {
    intptr_t index = InstructionPattern::IndexFromPPLoad(start_ + 10);
    const Smi& smi = Smi::Handle(reinterpret_cast<RawSmi*>(target));
    object_pool_.SetAt(index, smi);
    // No need to flush the instruction cache, since the code is not modified.
  }

 private:
  uword start_;
  const Array& object_pool_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(UnoptimizedCall);
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


// The expected pattern of a dart static call:
//  00 mov R10, arguments_descriptor_array (10 bytes) (optional in polym. calls)
//  11: 4d 8b 9f imm32  mov R11, [PP + off]
//  16: call R11  (3 bytes)
//  <- return address
class StaticCall : public ValueObject {
 public:
  explicit StaticCall(uword return_address, const Code& code)
      : start_(return_address - kCallPatternSize),
        object_pool_(Array::Handle(code.ObjectPool())) {
    ASSERT(IsValid(return_address));
    ASSERT(kCallPatternSize == Assembler::kCallExternalLabelSize);
  }

  static const int kCallPatternSize = 10;

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(return_address - kCallPatternSize);
    return (code_bytes[0] == 0x4D) && (code_bytes[1] == 0x8B) &&
           (code_bytes[2] == 0x9F) &&
           (code_bytes[7] == 0x41) && (code_bytes[8] == 0xFF) &&
           (code_bytes[9] == 0xD3);
  }

  uword target() const {
    intptr_t index = InstructionPattern::IndexFromPPLoad(start_ + 3);
    return reinterpret_cast<uword>(object_pool_.At(index));
  }

  void set_target(uword target) const {
    intptr_t index = InstructionPattern::IndexFromPPLoad(start_ + 3);
    const Smi& smi = Smi::Handle(reinterpret_cast<RawSmi*>(target));
    object_pool_.SetAt(index, smi);
    // No need to flush the instruction cache, since the code is not modified.
  }

 private:
  uword start_;
  const Array& object_pool_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(StaticCall);
};


// The expected pattern of a call where the target is loaded from
// the object pool:
//  00: 4d 8b 9f imm32  mov R11, [PP + off]
//  07: 41 ff d3        call R11
//  10 <- return address
class PoolPointerCall : public ValueObject {
 public:
  explicit PoolPointerCall(uword return_address)
      : start_(return_address - kCallPatternSize) {
    ASSERT(IsValid(return_address));
  }

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(return_address - kCallPatternSize);
    return (code_bytes[0] == 0x4D) && (code_bytes[1] == 0x8B) &&
           (code_bytes[2] == 0x9F) &&
           (code_bytes[7] == 0x41) && (code_bytes[8] == 0xFF) &&
           (code_bytes[9] == 0xD3);
  }

  int32_t pp_offset() const {
    return *reinterpret_cast<int32_t*>(start_ + 3);
  }

  void set_pp_offset(int32_t offset) const {
    *reinterpret_cast<int32_t*>(start_ + 3) = offset;
    CPU::FlushICache(start_, kCallPatternSize);
  }

 private:
  static const int kCallPatternSize = 7 + 3;
  uword start_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(PoolPointerCall);
};


// The expected code pattern of a Dart closure call:
//  00: 49 ba imm64     mov R10, immediate 2      ; 10 bytes
//  10: 4d 8b 9f imm32  mov R11, [PP + off]
//  17: 41 ff d3        call R11                  ; 3 bytes
//  20: <- return_address
class ClosureCall : public ValueObject {
 public:
  explicit ClosureCall(uword return_address)
      : start_(return_address - kCallPatternSize) {
    ASSERT(IsValid(return_address));
  }

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(return_address - kCallPatternSize);
    return (code_bytes[00] == 0x49) && (code_bytes[01] == 0xBA) &&
           (code_bytes[10] == 0x4D) && (code_bytes[11] == 0x8B) &&
           (code_bytes[12] == 0x9F) &&
           (code_bytes[17] == 0x41) && (code_bytes[18] == 0xFF) &&
           (code_bytes[19] == 0xD3);
  }

  RawArray* arguments_descriptor() const {
    return *reinterpret_cast<RawArray**>(start_ + 2);
  }

 private:
  static const int kCallPatternSize = 10 + 7 + 3;
  uword start_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(ClosureCall);
};


RawArray* CodePatcher::GetClosureArgDescAt(uword return_address,
                                           const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  ClosureCall call(return_address);
  return call.arguments_descriptor();
}


uword CodePatcher::GetStaticCallTargetAt(uword return_address,
                                         const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  StaticCall call(return_address, code);
  return call.target();
}


void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  StaticCall call(return_address, code);
  call.set_target(new_target);
}


int32_t CodePatcher::GetPoolOffsetAt(uword return_address) {
  PoolPointerCall call(return_address);
  return call.pp_offset();
}


void CodePatcher::SetPoolOffsetAt(uword return_address, int32_t offset) {
  PoolPointerCall call(return_address);
  call.set_pp_offset(offset);
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
  ASSERT(start + ShortCallPattern::InstructionLength() <= target);
  *reinterpret_cast<uint8_t*>(start) = 0xE8;
  ShortCallPattern call(start);
  call.SetTargetAddress(target);
  CPU::FlushICache(start, ShortCallPattern::InstructionLength());
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


// The expected code pattern of an edge counter in unoptimized code:
//  49 8b 87 imm32    mov RAX, [PP + offset]
class EdgeCounter : public ValueObject {
 public:
  EdgeCounter(uword pc, const Code& code)
      : end_(pc - FlowGraphCompiler::EdgeCounterIncrementSizeInBytes()),
        object_pool_(Array::Handle(code.ObjectPool())) {
    ASSERT(IsValid(end_));
  }

  static bool IsValid(uword end) {
    uint8_t* bytes = reinterpret_cast<uint8_t*>(end - 7);
    return (bytes[0] == 0x49) && (bytes[1] == 0x8b) && (bytes[2] == 0x87);
  }

  RawObject* edge_counter() const {
    return object_pool_.At(InstructionPattern::IndexFromPPLoad(end_ - 4));
  }

 private:
  uword end_;
  const Array& object_pool_;
};


RawObject* CodePatcher::GetEdgeCounterAt(uword pc, const Code& code) {
  ASSERT(code.ContainsInstructionAt(pc));
  EdgeCounter counter(pc, code);
  return counter.edge_counter();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
