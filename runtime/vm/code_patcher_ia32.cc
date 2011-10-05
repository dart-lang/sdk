// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
 private:
  static const int kNumInstructions = 3;
  static const int kInstructionSize = 5;  // All instructions have same length.

 public:
  explicit DartCallPattern(uword return_address)
      : start_(return_address - (kNumInstructions * kInstructionSize)) {
    ASSERT(*reinterpret_cast<uint8_t*>(start_) == 0xB9);
    ASSERT(*reinterpret_cast<uint8_t*>(start_ + 1 * kInstructionSize) == 0xBA);
    ASSERT(*reinterpret_cast<uint8_t*>(start_ + 2 * kInstructionSize) == 0xE8);
    ASSERT(kInstructionSize == Assembler::kCallExternalLabelSize);
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
//  mov ECX, function_name
//  mov EDX, argument_descriptor_array
//  call target_address
//  <- return address
class InstanceCall : public DartCallPattern {
 public:
  explicit InstanceCall(uword return_address)
      : DartCallPattern(return_address) {}

  RawString* function_name() const {
    String& str = String::Handle();
    str ^= reinterpret_cast<RawObject*>(immediate_one());
    return str.raw();
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


static void InsertCallOrJump(uword at_addr,
                             const ExternalLabel* label,
                             uint8_t op) {
  const int kInstructionSize = 5;
  *reinterpret_cast<uint8_t*>(at_addr) = op;  // Call.
  uword* target_addr = reinterpret_cast<uword*>(at_addr + 1);
  uword offset = label->address() - (at_addr + kInstructionSize);
  *target_addr = offset;
  CPU::FlushICache(at_addr, kInstructionSize);
}


void CodePatcher::InsertCall(uword at_addr, const ExternalLabel* label) {
  const uint8_t kCallOp = 0xE8;
  InsertCallOrJump(at_addr, label, kCallOp);
}


void CodePatcher::InsertJump(uword at_addr, const ExternalLabel* label) {
  const uint8_t kJumpOp = 0xE9;
  InsertCallOrJump(at_addr, label, kJumpOp);
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
  Jump jmp_entry(code.EntryPoint());
  ASSERT(!jmp_entry.IsValid());
  const uword patch_buffer = code.GetPatchCodePc();
  ASSERT(patch_buffer != 0);
  Jump jmp_patch(patch_buffer);
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
  Jump jmp_entry(code.EntryPoint());
  ASSERT(jmp_entry.IsValid());
  const uword jump_target = jmp_entry.TargetAddress();
  const uword patch_buffer = code.GetPatchCodePc();
  ASSERT(patch_buffer != 0);
  // 'patch_buffer' contains original entry code.
  Jump jmp_patch(patch_buffer);
  ASSERT(!jmp_patch.IsValid());
  SwapCode(jmp_patch.pattern_length_in_bytes(),
           reinterpret_cast<char*>(code.EntryPoint()),
           reinterpret_cast<char*>(patch_buffer));
  ASSERT(jmp_patch.IsValid());
  jmp_patch.SetTargetAddress(jump_target);
}


bool CodePatcher::CodeIsPatchable(const Code& code) {
  Jump jmp_entry(code.EntryPoint());
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


void CodePatcher::GetInstanceCallAt(uword return_address,
                                    String* function_name,
                                    int* num_arguments,
                                    int* num_named_arguments,
                                    uword* target) {
  ASSERT(function_name != NULL);
  ASSERT(num_arguments != NULL);
  ASSERT(num_named_arguments != NULL);
  ASSERT(target != NULL);
  InstanceCall call(return_address);
  *num_arguments = call.argument_count();
  *num_named_arguments = call.named_argument_count();
  *target = call.target();
  *function_name = call.function_name();
}


void CodePatcher::PatchInstanceCallAt(uword return_address, uword new_target) {
  InstanceCall call(return_address);
  call.set_target(new_target);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
