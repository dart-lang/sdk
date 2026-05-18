// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/asm_intrinsifier.h"
#include "vm/compiler/assembler/assembler.h"

namespace dart {
namespace compiler {

void AsmIntrinsifier::Smi_bitLength(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Bigint_lsh(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Bigint_rsh(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Bigint_absAdd(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Bigint_absSub(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Bigint_mulAdd(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Bigint_sqrAdd(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Bigint_estimateQuotientDigit(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Montgomery_mulMod(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_greaterThan(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_greaterEqualThan(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_lessThan(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_lessEqualThan(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_equal(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_add(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_sub(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_mul(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_div(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_getIsNaN(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_getIsInfinite(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_getIsNegative(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Double_mulFromInteger(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::DoubleFromInteger(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::ObjectEquals(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::ObjectRuntimeType(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::ObjectHaveSameRuntimeType(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::String_getHashCode(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::StringBaseIsEmpty(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::StringBaseSubstringMatches(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::StringBaseCharAt(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::OneByteString_getHashCode(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::OneByteString_substringUnchecked(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::OneByteString_equality(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::TwoByteString_equality(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::AbstractType_getHashCode(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::AbstractType_equality(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Type_equality(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Object_getHash(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Integer_greaterThan(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Integer_equal(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Integer_equalToInteger(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Integer_lessThan(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Integer_lessEqualThan(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Integer_greaterEqualThan(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Integer_shl(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::Timeline_getNextTaskId(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::AllocateOneByteString(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::AllocateTwoByteString(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::WriteIntoOneByteString(Assembler*, Label*) {
  UNIMPLEMENTED();
}

void AsmIntrinsifier::WriteIntoTwoByteString(Assembler*, Label*) {
  UNIMPLEMENTED();
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
