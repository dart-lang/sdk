// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

// The expected pattern of a Dart unoptimized call (static and instance):
//  mov ECX, ic-data
//  call target_address (stub)
//  <- return address
class UnoptimizedCall : public ValueObject {
 public:
  explicit UnoptimizedCall(uword return_address)
      : start_(return_address - (kNumInstructions * kInstructionSize)) {
    ASSERT(IsValid(return_address));
    ASSERT(kInstructionSize == Assembler::kCallExternalLabelSize);
  }

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(
            return_address - (kNumInstructions * kInstructionSize));
    return (code_bytes[0] == 0xB9) &&
           (code_bytes[1 * kInstructionSize] == 0xE8);
  }

  uword target() const {
    const uword offset = *reinterpret_cast<uword*>(call_address() + 1);
    return return_address() + offset;
  }

  void set_target(uword target) const {
    uword* target_addr = reinterpret_cast<uword*>(call_address() + 1);
    uword offset = target - return_address();
    *target_addr = offset;
    CPU::FlushICache(call_address(), kInstructionSize);
  }

  RawObject* ic_data() const {
    return *reinterpret_cast<RawObject**>(start_ + 1);
  }

  static const int kNumInstructions = 2;
  static const int kInstructionSize = 5;  // All instructions have same length.

 private:
  uword return_address() const {
    return start_ + kNumInstructions * kInstructionSize;
  }

  uword call_address() const {
    return start_ + 1 * kInstructionSize;
  }

  uword start_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(UnoptimizedCall);
};


class InstanceCall : public UnoptimizedCall {
 public:
  explicit InstanceCall(uword return_address)
      : UnoptimizedCall(return_address) {
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
  explicit UnoptimizedStaticCall(uword return_address)
      : UnoptimizedCall(return_address) {
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
//  mov EDX, arguments_descriptor_array (optional in polymorphic calls)
//  call target_address
//  <- return address
class StaticCall : public ValueObject {
 public:
  explicit StaticCall(uword return_address)
      : start_(return_address - (kNumInstructions * kInstructionSize)) {
    ASSERT(IsValid(return_address));
    ASSERT(kInstructionSize == Assembler::kCallExternalLabelSize);
  }

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(
            return_address - (kNumInstructions * kInstructionSize));
    return (code_bytes[0] == 0xE8);
  }

  uword target() const {
    const uword offset = *reinterpret_cast<uword*>(call_address() + 1);
    return return_address() + offset;
  }

  void set_target(uword target) const {
    uword* target_addr = reinterpret_cast<uword*>(call_address() + 1);
    uword offset = target - return_address();
    *target_addr = offset;
    CPU::FlushICache(call_address(), kInstructionSize);
  }

  static const int kNumInstructions = 1;
  static const int kInstructionSize = 5;  // All instructions have same length.

 private:
  uword return_address() const {
    return start_ + kNumInstructions * kInstructionSize;
  }

  uword call_address() const {
    return start_;
  }

  uword start_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StaticCall);
};


// The expected pattern of a Dart closure call:
//   mov EDX, arguments_descriptor_array
//   call target_address
//   <- return address
class ClosureCall : public ValueObject {
 public:
  explicit ClosureCall(uword return_address)
      : start_(return_address - (kInstr1Size + kInstr2Size)) {
    ASSERT(IsValid(return_address));
    ASSERT(kInstr2Size == Assembler::kCallExternalLabelSize);
  }

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes = reinterpret_cast<uint8_t*>(
        return_address - (kInstr1Size + kInstr2Size));
    return (code_bytes[0] == 0xBA) && (code_bytes[kInstr1Size] == 0xE8);
  }

  RawArray* arguments_descriptor() const {
    return *reinterpret_cast<RawArray**>(start_ + 1);
  }

 private:
  static const int kInstr1Size = 5;  // mov EDX, arguments descriptor array
  static const int kInstr2Size = 5;  // call stub

  uword return_address() const {
    return start_ + kInstr1Size + kInstr2Size;
  }
  uword call_address() const { return start_; }

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
  StaticCall call(return_address);
  return call.target();
}


void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  StaticCall call(return_address);
  call.set_target(new_target);
}


void CodePatcher::PatchInstanceCallAt(uword return_address,
                                      const Code& code,
                                      uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  InstanceCall call(return_address);
  call.set_target(new_target);
}


int32_t CodePatcher::GetPoolOffsetAt(uword return_address) {
  UNREACHABLE();
  return 0;
}


void CodePatcher::SetPoolOffsetAt(uword return_address, int32_t offset) {
  UNREACHABLE();
}


void CodePatcher::InsertCallAt(uword start, uword target) {
  // The inserted call should not overlap the lazy deopt jump code.
  ASSERT(start + CallPattern::InstructionLength() <= target);
  *reinterpret_cast<uint8_t*>(start) = 0xE8;
  CallPattern call(start);
  call.SetTargetAddress(target);
  CPU::FlushICache(start, CallPattern::InstructionLength());
}


uword CodePatcher::GetInstanceCallAt(
    uword return_address, const Code& code, ICData* ic_data) {
  ASSERT(code.ContainsInstructionAt(return_address));
  InstanceCall call(return_address);
  if (ic_data != NULL) {
    *ic_data ^= call.ic_data();
  }
  return call.target();
}


RawFunction* CodePatcher::GetUnoptimizedStaticCallAt(
    uword return_address, const Code& code, ICData* ic_data_result) {
  ASSERT(code.ContainsInstructionAt(return_address));
  UnoptimizedStaticCall static_call(return_address);
  ICData& ic_data = ICData::Handle();
  ic_data ^= static_call.ic_data();
  if (ic_data_result != NULL) {
    *ic_data_result = ic_data.raw();
  }
  return ic_data.GetTargetAt(0);
}


intptr_t CodePatcher::InstanceCallSizeInBytes() {
  return InstanceCall::kNumInstructions * InstanceCall::kInstructionSize;
}


// The expected code pattern of an edge counter in unoptimized code:
//  b8 imm32    mov EAX, immediate
class EdgeCounter : public ValueObject {
 public:
  EdgeCounter(uword pc, const Code& ignored)
      : end_(pc - CodePatcher::EdgeCounterIncrementSizeInBytes()) {
    ASSERT(IsValid(end_));
  }

  static bool IsValid(uword end) {
    return (*reinterpret_cast<uint8_t*>(end - 5) == 0xb8);
  }

  RawObject* edge_counter() const {
    return *reinterpret_cast<RawObject**>(end_ - 4);
  }

 private:
  uword end_;
};


int32_t CodePatcher::EdgeCounterIncrementSizeInBytes() {
  // The edge counter load is followed by the fixed-size edge counter
  // incrementing code:
  //     83 40 0b 02               add [eax+0xb],0x2
  return 4;
}


RawObject* CodePatcher::GetEdgeCounterAt(uword pc, const Code& code) {
  ASSERT(code.ContainsInstructionAt(pc));
  EdgeCounter counter(pc, code);
  return counter.edge_counter();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
