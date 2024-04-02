// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.
#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/asm_intrinsifier.h"

namespace dart {
namespace compiler {

void AsmIntrinsifier::String_identityHash(Assembler* assembler,
                                          Label* normal_ir_body) {
  String_getHashCode(assembler, normal_ir_body);
}

void AsmIntrinsifier::RegExp_ExecuteMatch(Assembler* assembler,
                                          Label* normal_ir_body) {
  AsmIntrinsifier::IntrinsifyRegExpExecuteMatch(assembler, normal_ir_body,
                                                /*sticky=*/false);
}

void AsmIntrinsifier::RegExp_ExecuteMatchSticky(Assembler* assembler,
                                                Label* normal_ir_body) {
  AsmIntrinsifier::IntrinsifyRegExpExecuteMatch(assembler, normal_ir_body,
                                                /*sticky=*/true);
}

#define __ assembler->

// TODO(srdjan): Add combinations (one-byte/two-byte/external strings).
void AsmIntrinsifier::StringEquality(Assembler* assembler,
                                     Register obj1,
                                     Register obj2,
                                     Register temp1,
                                     Register temp2,
                                     Register result,
                                     Label* normal_ir_body,
                                     intptr_t string_cid) {
  Label is_true, is_false, loop;

  __ CompareRegisters(obj1, obj2);
  __ BranchIf(EQUAL, &is_true, AssemblerBase::kNearJump);
  __ BranchIfSmi(obj2, &is_false, AssemblerBase::kNearJump);
  __ CompareClassId(obj2, string_cid, temp1);
  __ BranchIf(NOT_EQUAL, normal_ir_body, AssemblerBase::kNearJump);

  __ LoadFieldFromOffset(temp1, obj1, target::String::length_offset());
  __ CompareWithMemoryValue(
      temp1, FieldAddress(obj2, target::String::length_offset()));
  __ BranchIf(NOT_EQUAL, &is_false, AssemblerBase::kNearJump);

  // Ensure temp1 has length in bytes
  if (string_cid == kOneByteStringCid) {
    __ ArithmeticShiftRightImmediate(temp1, 1);
  }
  // Rounding up to word boundary
  __ AddImmediate(temp1, target::kWordSize - 1);
  __ ArithmeticShiftRightImmediate(temp1, target::kWordSizeLog2);
  __ CompareWords(obj1, obj2,
                  target::String::length_offset() + target::kWordSize, temp1,
                  temp2, &is_true);

  __ Bind(&is_false);
  __ LoadObject(result, CastHandle<Object>(FalseObject()));
  __ Ret();

  __ Bind(&is_true);
  __ LoadObject(result, CastHandle<Object>(TrueObject()));
  __ Ret();

  __ Bind(normal_ir_body);
}

}  // namespace compiler
}  // namespace dart
