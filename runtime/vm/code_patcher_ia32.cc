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

// The pattern of a Dart instance call is:
//  1: mov ECX, immediate 1
//  2: mov EDX, immediate 2
//  3: call target_address
//  <- return_address
class DartCallPattern : public ValueObject {
 public:
  explicit DartCallPattern(uword return_address)
      : start_(return_address - (kNumInstructions * kInstructionSize)) {
    ASSERT(IsValid(return_address));
    ASSERT(kInstructionSize == Assembler::kCallExternalLabelSize);
  }

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(
            return_address - (kNumInstructions * kInstructionSize));
    return (code_bytes[0] == 0xB9) &&
           (code_bytes[kInstructionSize] == 0xBA) &&
           (code_bytes[2 * kInstructionSize] == 0xE8);
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

  RawObject* immediate_one() const {
    return *reinterpret_cast<RawObject**>(start_ + 1);
  }

  RawObject* immediate_two() const {
    return *reinterpret_cast<RawObject**>(start_ + kInstructionSize + 1);
  }

  static const int kNumInstructions = 3;
  static const int kInstructionSize = 5;  // All instructions have same length.

 private:
  uword return_address() const {
    return start_ + kNumInstructions * kInstructionSize;
  }

  uword call_address() const {
    return start_ + 2 * kInstructionSize;
  }

  uword start_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(DartCallPattern);
};


// The expected pattern of a dart instance call:
//  mov ECX, ic-data
//  mov EDX, arguments_descriptor_array
//  call target_address
//  <- return address
class InstanceCall : public DartCallPattern {
 public:
  explicit InstanceCall(uword return_address)
      : DartCallPattern(return_address) {}

  RawObject* ic_data() const { return immediate_one(); }
  RawObject* arguments_descriptor() const { return immediate_two(); }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(InstanceCall);
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



void CodePatcher::InsertCallAt(uword start, uword target) {
  *reinterpret_cast<uint8_t*>(start) = 0xE8;
  CallPattern call(start);
  call.SetTargetAddress(target);
  CPU::FlushICache(start, CallPattern::InstructionLength());
}


uword CodePatcher::GetInstanceCallAt(uword return_address,
                                     const Code& code,
                                     ICData* ic_data,
                                     Array* arguments_descriptor) {
  ASSERT(code.ContainsInstructionAt(return_address));
  InstanceCall call(return_address);
  if (ic_data != NULL) {
    *ic_data ^= call.ic_data();
  }
  if (arguments_descriptor != NULL) {
    *arguments_descriptor ^= call.arguments_descriptor();
  }
  return call.target();
}


intptr_t CodePatcher::InstanceCallSizeInBytes() {
  return DartCallPattern::kNumInstructions * DartCallPattern::kInstructionSize;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
