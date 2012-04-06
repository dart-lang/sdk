// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

// The pattern of a Dart call is:
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

  uint32_t immediate_one() const {
    return *reinterpret_cast<uint32_t*>(start_ + 1);
  }

  void set_immediate_one(uint32_t value) {
    uint32_t* target_addr = reinterpret_cast<uint32_t*>(start_ + 1);
    *target_addr = value;
    CPU::FlushICache(start_, kInstructionSize);
  }

  uint32_t immediate_two() const {
    return *reinterpret_cast<uint32_t*>(start_ + kInstructionSize + 1);
  }

  int argument_count() const {
    Array& args_desc = Array::Handle();
    args_desc ^= reinterpret_cast<RawObject*>(immediate_two());
    Smi& num_args = Smi::Handle();
    num_args ^= args_desc.At(0);
    return num_args.Value();
  }

  int named_argument_count() const {
    Array& args_desc = Array::Handle();
    args_desc ^= reinterpret_cast<RawObject*>(immediate_two());
    Smi& num_args = Smi::Handle();
    num_args ^= args_desc.At(0);
    Smi& num_pos_args = Smi::Handle();
    num_pos_args ^= args_desc.At(1);
    return num_args.Value() - num_pos_args.Value();
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


// The expected pattern of a dart static call:
//  mov ECX, function_object
//  mov EDX, argument_descriptor_array
//  call target_address
//  <- return address
class StaticCall : public DartCallPattern {
 public:
  explicit StaticCall(uword return_address)
      : DartCallPattern(return_address) {}

  RawFunction* function() const {
    Function& f = Function::Handle();
    f ^= reinterpret_cast<RawObject*>(immediate_one());
    return f.raw();
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(StaticCall);
};


// The expected pattern of a dart instance call:
//  mov ECX, ic-data
//  mov EDX, argument_descriptor_array
//  call target_address
//  <- return address
class InstanceCall : public DartCallPattern {
 public:
  explicit InstanceCall(uword return_address)
      : DartCallPattern(return_address) {}

  RawICData* ic_data() const {
    ICData& ic_data = ICData::Handle();
    ic_data ^= reinterpret_cast<RawObject*>(immediate_one());
    return ic_data.raw();
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(InstanceCall);
};


void CodePatcher::GetStaticCallAt(uword return_address,
                                  Function* function,
                                  uword* target) {
  ASSERT(function != NULL);
  ASSERT(target != NULL);
  StaticCall call(return_address);
  *target = call.target();
  *function = call.function();
}


void CodePatcher::PatchStaticCallAt(uword return_address, uword new_target) {
  StaticCall call(return_address);
  call.set_target(new_target);
}


void CodePatcher::PatchInstanceCallAt(uword return_address, uword new_target) {
  InstanceCall call(return_address);
  call.set_target(new_target);
}


static void SwapCode(intptr_t num_bytes, char* a, char* b) {
  for (intptr_t i = 0; i < num_bytes; i++) {
    char tmp = *a;
    *a = *b;
    *b = tmp;
    a++;
    b++;
  }
}


// The patch code buffer contains the jmp code which will be inserted at
// entry point.
void CodePatcher::PatchEntry(const Code& code) {
  JumpPattern jmp_entry(code.EntryPoint());
  ASSERT(!jmp_entry.IsValid());
  const uword patch_buffer = code.GetPatchCodePc();
  ASSERT(patch_buffer != 0);
  JumpPattern jmp_patch(patch_buffer);
  ASSERT(jmp_patch.IsValid());
  const uword jump_target = jmp_patch.TargetAddress();
  SwapCode(jmp_patch.pattern_length_in_bytes(),
           reinterpret_cast<char*>(code.EntryPoint()),
           reinterpret_cast<char*>(patch_buffer));
  jmp_entry.SetTargetAddress(jump_target);
}


// The entry point is a jmp instruction, the patch code buffer contains
// original code, the entry point contains the jump instruction.
void CodePatcher::RestoreEntry(const Code& code) {
  JumpPattern jmp_entry(code.EntryPoint());
  ASSERT(jmp_entry.IsValid());
  const uword jump_target = jmp_entry.TargetAddress();
  const uword patch_buffer = code.GetPatchCodePc();
  ASSERT(patch_buffer != 0);
  // 'patch_buffer' contains original entry code.
  JumpPattern jmp_patch(patch_buffer);
  ASSERT(!jmp_patch.IsValid());
  SwapCode(jmp_patch.pattern_length_in_bytes(),
           reinterpret_cast<char*>(code.EntryPoint()),
           reinterpret_cast<char*>(patch_buffer));
  ASSERT(jmp_patch.IsValid());
  jmp_patch.SetTargetAddress(jump_target);
}


bool CodePatcher::CodeIsPatchable(const Code& code) {
  JumpPattern jmp_entry(code.EntryPoint());
  if (code.Size() < (jmp_entry.pattern_length_in_bytes() * 2)) {
    return false;
  }
  uword limit = code.EntryPoint() + jmp_entry.pattern_length_in_bytes();
  for (intptr_t i = 0; i < code.pointer_offsets_length(); i++) {
    const uword addr = code.GetPointerOffsetAt(i) + code.EntryPoint();
    if (addr < limit) {
      return false;
    }
  }
  return true;
}


bool CodePatcher::IsDartCall(uword return_address) {
  return DartCallPattern::IsValid(return_address);
}


void CodePatcher::GetInstanceCallAt(uword return_address,
                                    String* function_name,
                                    int* num_arguments,
                                    int* num_named_arguments,
                                    uword* target) {
  ASSERT(num_arguments != NULL);
  ASSERT(num_named_arguments != NULL);
  ASSERT(target != NULL);
  InstanceCall call(return_address);
  *num_arguments = call.argument_count();
  *num_named_arguments = call.named_argument_count();
  *target = call.target();
  const ICData& ic_data = ICData::Handle(call.ic_data());
  if (function_name != NULL) {
    *function_name = ic_data.target_name();
  }
}


RawICData* CodePatcher::GetInstanceCallIcDataAt(uword return_address) {
  InstanceCall call(return_address);
  return call.ic_data();
}


intptr_t CodePatcher::InstanceCallSizeInBytes() {
  return DartCallPattern::kNumInstructions * DartCallPattern::kInstructionSize;
}


RawArray* CodePatcher::GetTypeTestArray(uword instruction_address) {
  Array& result = Array::Handle();
  uint32_t* target_addr = reinterpret_cast<uint32_t*>(instruction_address + 1);
  result ^= reinterpret_cast<RawObject*>(*target_addr);
  return result.raw();
}


void CodePatcher::SetTypeTestArray(uword instruction_address,
                                   const Array& value) {
  uint32_t* target_addr = reinterpret_cast<uint32_t*>(instruction_address + 1);
  *target_addr = reinterpret_cast<uint32_t>(value.raw());
}


}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
