// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/assembler.h"
#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

// The pattern of a Dart instance call is:
//  00: 48 bb imm64  mov RBX, immediate 1
//  10: 49 ba imm64  mov R10, immediate 2
//  20: 49 bb imm64  mov R11, target_address
//  30: 41 ff d3     call R11
//  33: <- return_address
class DartCallPattern : public ValueObject {
 public:
  explicit DartCallPattern(uword return_address)
      : start_(return_address - kCallPatternSize) {
    ASSERT(IsValid(return_address));
    ASSERT((kCallPatternSize - 20) == Assembler::kCallExternalLabelSize);
  }

  static const int kCallPatternSize = 33;

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(return_address - kCallPatternSize);
    return (code_bytes[00] == 0x48) && (code_bytes[01] == 0xBB) &&
           (code_bytes[10] == 0x49) && (code_bytes[11] == 0xBA) &&
           (code_bytes[20] == 0x49) && (code_bytes[21] == 0xBB) &&
           (code_bytes[30] == 0x41) && (code_bytes[31] == 0xFF) &&
           (code_bytes[32] == 0xD3);
  }

  uword target() const {
    return *reinterpret_cast<uword*>(start_ + 20 + 2);
  }

  void set_target(uword target) const {
    uword* target_addr = reinterpret_cast<uword*>(start_ + 20 + 2);
    *target_addr = target;
    CPU::FlushICache(start_ + 20, 2 + 8);
  }

  uint64_t immediate_one() const {
    return *reinterpret_cast<uint64_t*>(start_ + 0 + 2);
  }

  void set_immediate_one(uint64_t value) {
    uint64_t* target_addr = reinterpret_cast<uint64_t*>(start_ + 0 + 2);
    *target_addr = value;
    CPU::FlushICache(start_ + 0, 2 + 8);
  }

  uint64_t immediate_two() const {
    return *reinterpret_cast<uint64_t*>(start_ + 10 + 2);
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

  uword start_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(DartCallPattern);
};


// A Dart instance call passes the ic-data in RBX.
// The expected pattern of a dart instance call:
//  mov RBX, ic-data
//  mov R10, argument_descriptor_array
//  mov R11, target_address
//  call R11
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


// The expected pattern of a dart static call:
//  mov R10, argument_descriptor_array (10 bytes)
//  mov R11, target_address (10 bytes)
//  call R11  (3 bytes)
//  <- return address
class StaticCall : public ValueObject {
 public:
  explicit StaticCall(uword return_address)
      : start_(return_address - kCallPatternSize) {
    ASSERT(IsValid(return_address));
    ASSERT((kCallPatternSize - 10) == Assembler::kCallExternalLabelSize);
  }

  static const int kCallPatternSize = 23;

  static bool IsValid(uword return_address) {
    uint8_t* code_bytes =
        reinterpret_cast<uint8_t*>(return_address - kCallPatternSize);
    return (code_bytes[00] == 0x49) && (code_bytes[01] == 0xBA) &&
           (code_bytes[10] == 0x49) && (code_bytes[11] == 0xBB) &&
           (code_bytes[20] == 0x41) && (code_bytes[21] == 0xFF) &&
           (code_bytes[22] == 0xD3);
  }

  uword target() const {
    return *reinterpret_cast<uword*>(start_ + 10 + 2);
  }

  void set_target(uword target) const {
    uword* target_addr = reinterpret_cast<uword*>(start_ + 10 + 2);
    *target_addr = target;
    CPU::FlushICache(start_ + 10, 2 + 8);
  }

 private:
  uword start_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StaticCall);
};


uword CodePatcher::GetStaticCallTargetAt(uword return_address) {
  StaticCall call(return_address);
  return call.target();
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


// The patch code buffer contains the jump code sequence which will be inserted
// at entry point.
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


// The entry point is a jump code sequence, the patch code buffer contains
// original code, the entry point contains the jump code sequence.
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
  return DartCallPattern::kCallPatternSize;
}


void CodePatcher::InsertCallAt(uword start, uword target) {
  *reinterpret_cast<uint8_t*>(start) = 0xE8;
  ShortCallPattern call(start);
  call.SetTargetAddress(target);
  CPU::FlushICache(start, ShortCallPattern::InstructionLength());
}


}  // namespace dart

#endif  // defined TARGET_ARCH_X64
