// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_RISCV.
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/asm_intrinsifier.h"
#include "vm/compiler/assembler/assembler.h"

namespace dart {
namespace compiler {

// When entering intrinsics code:
// PP: Caller's ObjectPool in JIT / global ObjectPool in AOT
// CODE_REG: Callee's Code in JIT / not passed in AOT
// S4: Arguments descriptor
// RA: Return address
// The S4 and CODE_REG registers can be destroyed only if there is no slow-path,
// i.e. if the intrinsified method always executes a return.
// The FP register should not be modified, because it is used by the profiler.
// The PP and THR registers (see constants_riscv.h) must be preserved.

#define __ assembler->

// Loads args from stack into A0 and A1
// Tests if they are smis, jumps to label not_smi if not.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ lx(A0, Address(SP, +1 * target::kWordSize));
  __ lx(A1, Address(SP, +0 * target::kWordSize));
  __ or_(TMP, A0, A1);
  __ BranchIfNotSmi(TMP, not_smi, Assembler::kNearJump);
}

void AsmIntrinsifier::Integer_shl(Assembler* assembler, Label* normal_ir_body) {
  const Register left = A0;
  const Register right = A1;
  const Register result = A0;

  TestBothArgumentsSmis(assembler, normal_ir_body);
  __ CompareImmediate(right, target::ToRawSmi(target::kSmiBits),
                      compiler::kObjectBytes);
  __ BranchIf(CS, normal_ir_body, Assembler::kNearJump);

  __ SmiUntag(right);
  __ sll(TMP, left, right);
  __ sra(TMP2, TMP, right);
  __ bne(TMP2, left, normal_ir_body, Assembler::kNearJump);
  __ mv(result, TMP);
  __ ret();

  __ Bind(normal_ir_body);
}

static void CompareIntegers(Assembler* assembler,
                            Label* normal_ir_body,
                            Condition true_condition) {
  Label true_label;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  __ CompareObjectRegisters(A0, A1);
  __ BranchIf(true_condition, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_lessThan(Assembler* assembler,
                                       Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, LT);
}

void AsmIntrinsifier::Integer_greaterThan(Assembler* assembler,
                                          Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, GT);
}

void AsmIntrinsifier::Integer_lessEqualThan(Assembler* assembler,
                                            Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, LE);
}

void AsmIntrinsifier::Integer_greaterEqualThan(Assembler* assembler,
                                               Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, GE);
}

// This is called for Smi and Mint receivers. The right argument
// can be Smi, Mint or double.
void AsmIntrinsifier::Integer_equalToInteger(Assembler* assembler,
                                             Label* normal_ir_body) {
  Label true_label, check_for_mint;
  // For integer receiver '===' check first.
  __ lx(A0, Address(SP, 1 * target::kWordSize));
  __ lx(A1, Address(SP, 0 * target::kWordSize));
  __ CompareObjectRegisters(A0, A1);
  __ BranchIf(EQ, &true_label, Assembler::kNearJump);

  __ or_(TMP, A0, A1);
  __ BranchIfNotSmi(TMP, &check_for_mint, Assembler::kNearJump);
  // If R0 or R1 is not a smi do Mint checks.

  // Both arguments are smi, '===' is good enough.
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);

  __ BranchIfNotSmi(A0, &receiver_not_smi,
                    Assembler::kNearJump);  // Check receiver.

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint never contains a value that can be
  // represented by Smi.

  __ CompareClassId(A1, kDoubleCid, TMP);
  __ BranchIf(EQ, normal_ir_body, Assembler::kNearJump);
  __ LoadObject(A0,
                CastHandle<Object>(FalseObject()));  // Smi == Mint -> false.
  __ ret();

  __ Bind(&receiver_not_smi);
  // A0: receiver.

  __ CompareClassId(A0, kMintCid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);
  // Receiver is Mint, return false if right is Smi.
  __ BranchIfNotSmi(A1, normal_ir_body, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  // TODO(srdjan): Implement Mint == Mint comparison.

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_equal(Assembler* assembler,
                                    Label* normal_ir_body) {
  Integer_equalToInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Smi_bitLength(Assembler* assembler,
                                    Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_lsh(Assembler* assembler, Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_rsh(Assembler* assembler, Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_absAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_absSub(Assembler* assembler,
                                    Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_mulAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_sqrAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_estimateQuotientDigit(Assembler* assembler,
                                                   Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Montgomery_mulMod(Assembler* assembler,
                                        Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

// FA0: left
// FA1: right
static void PrepareDoubleOp(Assembler* assembler, Label* normal_ir_body) {
  Label double_op;
  __ lx(A0, Address(SP, 1 * target::kWordSize));  // Left
  __ lx(A1, Address(SP, 0 * target::kWordSize));  // Right

  __ fld(FA0, FieldAddress(A0, target::Double::value_offset()));

  __ SmiUntag(TMP, A1);
#if XLEN == 32
  __ fcvtdw(FA1, TMP);
#else
  __ fcvtdl(FA1, TMP);
#endif
  __ BranchIfSmi(A1, &double_op, Assembler::kNearJump);
  __ CompareClassId(A1, kDoubleCid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);
  __ fld(FA1, FieldAddress(A1, target::Double::value_offset()));

  __ Bind(&double_op);
}

void AsmIntrinsifier::Double_greaterThan(Assembler* assembler,
                                         Label* normal_ir_body) {
  Label true_label;
  PrepareDoubleOp(assembler, normal_ir_body);
  __ fltd(TMP, FA1, FA0);
  __ bnez(TMP, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_greaterEqualThan(Assembler* assembler,
                                              Label* normal_ir_body) {
  Label true_label;
  PrepareDoubleOp(assembler, normal_ir_body);
  __ fled(TMP, FA1, FA0);
  __ bnez(TMP, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_lessThan(Assembler* assembler,
                                      Label* normal_ir_body) {
  Label true_label;
  PrepareDoubleOp(assembler, normal_ir_body);
  __ fltd(TMP, FA0, FA1);
  __ bnez(TMP, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_equal(Assembler* assembler,
                                   Label* normal_ir_body) {
  Label true_label;
  PrepareDoubleOp(assembler, normal_ir_body);
  __ feqd(TMP, FA0, FA1);
  __ bnez(TMP, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_lessEqualThan(Assembler* assembler,
                                           Label* normal_ir_body) {
  Label true_label;
  PrepareDoubleOp(assembler, normal_ir_body);
  __ fled(TMP, FA0, FA1);
  __ bnez(TMP, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

// Expects left argument to be double (receiver). Right argument is unknown.
// Both arguments are on stack.
static void DoubleArithmeticOperations(Assembler* assembler,
                                       Label* normal_ir_body,
                                       Token::Kind kind) {
  PrepareDoubleOp(assembler, normal_ir_body);
  switch (kind) {
    case Token::kADD:
      __ faddd(FA0, FA0, FA1);
      break;
    case Token::kSUB:
      __ fsubd(FA0, FA0, FA1);
      break;
    case Token::kMUL:
      __ fmuld(FA0, FA0, FA1);
      break;
    case Token::kDIV:
      __ fdivd(FA0, FA0, FA1);
      break;
    default:
      UNREACHABLE();
  }
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kFarJump, A0, TMP);
  __ StoreDFieldToOffset(FA0, A0, target::Double::value_offset());
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_add(Assembler* assembler, Label* normal_ir_body) {
  DoubleArithmeticOperations(assembler, normal_ir_body, Token::kADD);
}

void AsmIntrinsifier::Double_mul(Assembler* assembler, Label* normal_ir_body) {
  DoubleArithmeticOperations(assembler, normal_ir_body, Token::kMUL);
}

void AsmIntrinsifier::Double_sub(Assembler* assembler, Label* normal_ir_body) {
  DoubleArithmeticOperations(assembler, normal_ir_body, Token::kSUB);
}

void AsmIntrinsifier::Double_div(Assembler* assembler, Label* normal_ir_body) {
  DoubleArithmeticOperations(assembler, normal_ir_body, Token::kDIV);
}

// Left is double, right is integer (Mint or Smi)
void AsmIntrinsifier::Double_mulFromInteger(Assembler* assembler,
                                            Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::DoubleFromInteger(Assembler* assembler,
                                        Label* normal_ir_body) {
  __ lx(A0, Address(SP, 0 * target::kWordSize));
  __ BranchIfNotSmi(A0, normal_ir_body, Assembler::kNearJump);
  // Is Smi.
  __ SmiUntag(A0);
#if XLEN == 32
  __ fcvtdw(FA0, A0);
#else
  __ fcvtdl(FA0, A0);
#endif
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kFarJump, A0, TMP);
  __ StoreDFieldToOffset(FA0, A0, target::Double::value_offset());
  __ ret();
  __ Bind(normal_ir_body);
}

static void DoubleIsClass(Assembler* assembler, intx_t fclass) {
  Label true_label;
  __ lx(A0, Address(SP, 0 * target::kWordSize));
  __ LoadDFieldFromOffset(FA0, A0, target::Double::value_offset());
  __ fclassd(TMP, FA0);
  __ andi(TMP, TMP, fclass);
  __ bnez(TMP, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();
}

void AsmIntrinsifier::Double_getIsNaN(Assembler* assembler,
                                      Label* normal_ir_body) {
  DoubleIsClass(assembler, kFClassSignallingNan | kFClassQuietNan);
}

void AsmIntrinsifier::Double_getIsInfinite(Assembler* assembler,
                                           Label* normal_ir_body) {
  DoubleIsClass(assembler, kFClassNegInfinity | kFClassPosInfinity);
}

void AsmIntrinsifier::Double_getIsNegative(Assembler* assembler,
                                           Label* normal_ir_body) {
  DoubleIsClass(assembler, kFClassNegInfinity | kFClassNegNormal |
                               kFClassNegSubnormal | kFClassNegZero);
}

void AsmIntrinsifier::Double_hashCode(Assembler* assembler,
                                      Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::ObjectEquals(Assembler* assembler,
                                   Label* normal_ir_body) {
  Label true_label;
  __ lx(A0, Address(SP, 1 * target::kWordSize));
  __ lx(A1, Address(SP, 0 * target::kWordSize));
  __ beq(A0, A1, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();
}

// Return type quickly for simple types (not parameterized and not signature).
void AsmIntrinsifier::ObjectRuntimeType(Assembler* assembler,
                                        Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::ObjectHaveSameRuntimeType(Assembler* assembler,
                                                Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::String_getHashCode(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ lx(A0, Address(SP, 0 * target::kWordSize));
#if XLEN == 32
  // Smi field.
  __ lw(A0, FieldAddress(A0, target::String::hash_offset()));
#else
  // uint32_t field in header.
  __ lwu(A0, FieldAddress(A0, target::String::hash_offset()));
  __ SmiTag(A0);
#endif
  __ beqz(A0, normal_ir_body, Assembler::kNearJump);
  __ ret();

  // Hash not yet computed.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Type_getHashCode(Assembler* assembler,
                                       Label* normal_ir_body) {
  __ lx(A0, Address(SP, 0 * target::kWordSize));
  __ LoadCompressed(A0, FieldAddress(A0, target::Type::hash_offset()));
  __ beqz(A0, normal_ir_body, Assembler::kNearJump);
  __ ret();
  // Hash not yet computed.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Type_equality(Assembler* assembler,
                                    Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::FunctionType_getHashCode(Assembler* assembler,
                                               Label* normal_ir_body) {
  __ lx(A0, Address(SP, 0 * target::kWordSize));
  __ LoadCompressed(A0, FieldAddress(A0, target::FunctionType::hash_offset()));
  __ beqz(A0, normal_ir_body, Assembler::kNearJump);
  __ ret();
  // Hash not yet computed.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::FunctionType_equality(Assembler* assembler,
                                            Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

// Keep in sync with Instance::IdentityHashCode.
// Note int and double never reach here because they override _identityHashCode.
// Special cases are also not needed for null or bool because they were pre-set
// during VM isolate finalization.
void AsmIntrinsifier::Object_getHash(Assembler* assembler,
                                     Label* normal_ir_body) {
#if XLEN == 32
  UNREACHABLE();
#else
  Label not_yet_computed;
  __ lx(A0, Address(SP, 0 * target::kWordSize));  // Object.
  __ lwu(A0, FieldAddress(
                 A0, target::Object::tags_offset() +
                         target::UntaggedObject::kHashTagPos / kBitsPerByte));
  __ beqz(A0, &not_yet_computed);
  __ SmiTag(A0);
  __ ret();

  __ Bind(&not_yet_computed);
  __ LoadFromOffset(A1, THR, target::Thread::random_offset());
  __ AndImmediate(T2, A1, 0xffffffff);  // state_lo
  __ srli(T3, A1, 32);                  // state_hi
  __ LoadImmediate(A1, 0xffffda61);     // A
  __ mul(A1, A1, T2);
  __ add(A1, A1, T3);  // new_state = (A * state_lo) + state_hi
  __ StoreToOffset(A1, THR, target::Thread::random_offset());
  __ AndImmediate(A1, A1, 0x3fffffff);
  __ beqz(A1, &not_yet_computed);

  __ lx(A0, Address(SP, 0 * target::kWordSize));  // Object
  __ subi(A0, A0, kHeapObjectTag);
  __ slli(T3, A1, target::UntaggedObject::kHashTagPos);

  Label retry, already_set_in_r4;
  __ Bind(&retry);
  __ lr(T2, Address(A0, 0));
  __ srli(T4, T2, target::UntaggedObject::kHashTagPos);
  __ bnez(T4, &already_set_in_r4);
  __ or_(T2, T2, T3);
  __ sc(T4, T2, Address(A0, 0));
  __ bnez(T4, &retry);
  // Fall-through with A1 containing new hash value (untagged).
  __ SmiTag(A0, A1);
  __ ret();
  __ Bind(&already_set_in_r4);
  __ SmiTag(A0, T4);
  __ ret();
#endif
}

void GenerateSubstringMatchesSpecialization(Assembler* assembler,
                                            intptr_t receiver_cid,
                                            intptr_t other_cid,
                                            Label* return_true,
                                            Label* return_false) {
  __ SmiUntag(T0);
  __ LoadCompressedSmi(
      T1, FieldAddress(A0, target::String::length_offset()));  // this.length
  __ SmiUntag(T1);
  __ LoadCompressedSmi(
      T2, FieldAddress(A1, target::String::length_offset()));  // other.length
  __ SmiUntag(T2);

  // if (other.length == 0) return true;
  __ beqz(T2, return_true);

  // if (start < 0) return false;
  __ bltz(T0, return_false);

  // if (start + other.length > this.length) return false;
  __ add(T3, T0, T2);
  __ bgt(T3, T1, return_false);

  if (receiver_cid == kOneByteStringCid) {
    __ add(A0, A0, T0);
  } else {
    ASSERT(receiver_cid == kTwoByteStringCid);
    __ add(A0, A0, T0);
    __ add(A0, A0, T0);
  }

  // i = 0
  __ li(T3, 0);

  // do
  Label loop;
  __ Bind(&loop);

  // this.codeUnitAt(i + start)
  if (receiver_cid == kOneByteStringCid) {
    __ lbu(TMP, FieldAddress(A0, target::OneByteString::data_offset()));
  } else {
    __ lhu(TMP, FieldAddress(A0, target::TwoByteString::data_offset()));
  }
  // other.codeUnitAt(i)
  if (other_cid == kOneByteStringCid) {
    __ lbu(TMP2, FieldAddress(A1, target::OneByteString::data_offset()));
  } else {
    __ lhu(TMP2, FieldAddress(A1, target::TwoByteString::data_offset()));
  }
  __ bne(TMP, TMP2, return_false);

  // i++, while (i < len)
  __ addi(T3, T3, 1);
  __ addi(A0, A0, receiver_cid == kOneByteStringCid ? 1 : 2);
  __ addi(A1, A1, other_cid == kOneByteStringCid ? 1 : 2);
  __ blt(T3, T2, &loop);

  __ j(return_true);
}

// bool _substringMatches(int start, String other)
// This intrinsic handles a OneByteString or TwoByteString receiver with a
// OneByteString other.
void AsmIntrinsifier::StringBaseSubstringMatches(Assembler* assembler,
                                                 Label* normal_ir_body) {
  Label return_true, return_false, try_two_byte;
  __ lx(A0, Address(SP, 2 * target::kWordSize));  // this
  __ lx(T0, Address(SP, 1 * target::kWordSize));  // start
  __ lx(A1, Address(SP, 0 * target::kWordSize));  // other

  __ BranchIfNotSmi(T0, normal_ir_body);

  __ CompareClassId(A1, kOneByteStringCid, TMP);
  __ BranchIf(NE, normal_ir_body);

  __ CompareClassId(A0, kOneByteStringCid, TMP);
  __ BranchIf(NE, normal_ir_body);

  GenerateSubstringMatchesSpecialization(assembler, kOneByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&try_two_byte);
  __ CompareClassId(A0, kTwoByteStringCid, TMP);
  __ BranchIf(NE, normal_ir_body);

  GenerateSubstringMatchesSpecialization(assembler, kTwoByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&return_true);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(&return_false);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseCharAt(Assembler* assembler,
                                       Label* normal_ir_body) {
  Label try_two_byte_string;

  __ lx(A1, Address(SP, 0 * target::kWordSize));  // Index.
  __ lx(A0, Address(SP, 1 * target::kWordSize));  // String.
  __ BranchIfNotSmi(A1, normal_ir_body);          // Index is not a Smi.
  // Range check.
  __ lx(TMP, FieldAddress(A0, target::String::length_offset()));
  __ bgeu(A1, TMP, normal_ir_body);  // Runtime throws exception.

  __ CompareClassId(A0, kOneByteStringCid, TMP);
  __ BranchIf(NE, &try_two_byte_string);
  __ SmiUntag(A1);
  __ add(A0, A0, A1);
  __ lbu(A1, FieldAddress(A0, target::OneByteString::data_offset()));
  __ CompareImmediate(A1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ BranchIf(GE, normal_ir_body);
  __ lx(A0, Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ slli(A1, A1, target::kWordSizeLog2);
  __ add(A0, A0, A1);
  __ lx(A0, Address(A0, target::Symbols::kNullCharCodeSymbolOffset *
                            target::kWordSize));
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(A0, kTwoByteStringCid, TMP);
  __ BranchIf(NE, normal_ir_body);
  ASSERT(kSmiTagShift == 1);
  __ add(A0, A0, A1);
  __ lhu(A1, FieldAddress(A0, target::TwoByteString::data_offset()));
  __ CompareImmediate(A1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ BranchIf(GE, normal_ir_body);
  __ lx(A0, Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ slli(A1, A1, target::kWordSizeLog2);
  __ add(A0, A0, A1);
  __ lx(A0, Address(A0, target::Symbols::kNullCharCodeSymbolOffset *
                            target::kWordSize));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseIsEmpty(Assembler* assembler,
                                        Label* normal_ir_body) {
  Label is_true;
  __ lx(A0, Address(SP, 0 * target::kWordSize));
  __ lx(A0, FieldAddress(A0, target::String::length_offset()));
  __ beqz(A0, &is_true, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();
}

void AsmIntrinsifier::OneByteString_getHashCode(Assembler* assembler,
                                                Label* normal_ir_body) {
  Label compute_hash;
  __ lx(A1, Address(SP, 0 * target::kWordSize));  // OneByteString object.
#if XLEN == 32
  __ lw(A0, FieldAddress(A1, target::String::hash_offset()));
#else
  __ lwu(A0, FieldAddress(A1, target::String::hash_offset()));
  __ SmiTag(A0);
#endif
  __ beqz(A0, &compute_hash);
  __ ret();  // Return if already computed.

  __ Bind(&compute_hash);
  __ lx(T0, FieldAddress(A1, target::String::length_offset()));
  __ SmiUntag(T0);

  Label set_to_one, done;
  // If the string is empty, set the hash to 1, and return.
  __ beqz(T0, &set_to_one);

  __ mv(T1, ZR);
  __ addi(T2, A1, target::OneByteString::data_offset() - kHeapObjectTag);
  // A1: Instance of OneByteString.
  // T0: String length, untagged integer.
  // T1: Loop counter, untagged integer.
  // T2: String data.
  // A0: Hash code, untagged integer.

  Label loop;
  // Add to hash code: (hash_ is uint32)
  // hash_ += ch;
  // hash_ += hash_ << 10;
  // hash_ ^= hash_ >> 6;
  // Get one characters (ch).
  __ Bind(&loop);
  __ lbu(T3, Address(T2, 0));
  __ addi(T2, T2, 1);
  // T3: ch.
  __ addi(T1, T1, 1);
#if XLEN == 32
  __ add(A0, A0, T3);
  __ slli(TMP, A0, 10);
  __ add(A0, A0, TMP);
  __ srli(TMP, A0, 6);
#else
  __ addw(A0, A0, T3);
  __ slliw(TMP, A0, 10);
  __ addw(A0, A0, TMP);
  __ srliw(TMP, A0, 6);
#endif
  __ xor_(A0, A0, TMP);
  __ bne(T1, T0, &loop);

  // Finalize.
  // hash_ += hash_ << 3;
  // hash_ ^= hash_ >> 11;
  // hash_ += hash_ << 15;
#if XLEN == 32
  __ slli(TMP, A0, 3);
  __ add(A0, A0, TMP);
  __ srli(TMP, A0, 11);
  __ xor_(A0, A0, TMP);
  __ slli(TMP, A0, 15);
  __ add(A0, A0, TMP);
#else
  __ slliw(TMP, A0, 3);
  __ addw(A0, A0, TMP);
  __ srliw(TMP, A0, 11);
  __ xor_(A0, A0, TMP);
  __ slliw(TMP, A0, 15);
  __ addw(A0, A0, TMP);
#endif
  // hash_ = hash_ & ((static_cast<intptr_t>(1) << bits) - 1);
  __ AndImmediate(A0, A0,
                  (static_cast<intptr_t>(1) << target::String::kHashBits) - 1);
  // return hash_ == 0 ? 1 : hash_;
  __ bnez(A0, &done, Assembler::kNearJump);
  __ Bind(&set_to_one);
  __ li(A0, 1);
  __ Bind(&done);

#if XLEN == 32
  __ SmiTag(A0);
  __ sx(A0, FieldAddress(A1, target::String::hash_offset()));
  __ ret();
#else
  // A1: Untagged address of header word (lr/sc do not support offsets).
  __ subi(A1, A1, kHeapObjectTag);
  __ slli(A0, A0, target::UntaggedObject::kHashTagPos);
  Label retry;
  __ Bind(&retry);
  __ lr(T0, Address(A1, 0));
  __ or_(T0, T0, A0);
  __ sc(TMP, T0, Address(A1, 0));
  __ bnez(TMP, &retry);

  __ srli(A0, A0, target::UntaggedObject::kHashTagPos);
  __ SmiTag(A0);
  __ ret();
#endif
}

// Allocates a _OneByteString or _TwoByteString. The content is not initialized.
// 'length-reg' (A1) contains the desired length as a _Smi or _Mint.
// Returns new string as tagged pointer in A0.
static void TryAllocateString(Assembler* assembler,
                              classid_t cid,
                              Label* ok,
                              Label* failure) {
  ASSERT(cid == kOneByteStringCid || cid == kTwoByteStringCid);
  const Register length_reg = A1;
  // _Mint length: call to runtime to produce error.
  __ BranchIfNotSmi(length_reg, failure);
  // negative length: call to runtime to produce error.
  __ bltz(length_reg, failure);

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, TMP, failure));
  __ mv(T0, length_reg);  // Save the length register.
  if (cid == kOneByteStringCid) {
    // Untag length.
    __ SmiUntag(length_reg);
  } else {
    // Untag length and multiply by element size -> no-op.
    ASSERT(kSmiTagSize == 1);
  }
  const intptr_t fixed_size_plus_alignment_padding =
      target::String::InstanceSize() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ addi(length_reg, length_reg, fixed_size_plus_alignment_padding);
  __ andi(length_reg, length_reg,
          ~(target::ObjectAlignment::kObjectAlignment - 1));

  __ lx(A0, Address(THR, target::Thread::top_offset()));

  // length_reg: allocation size.
  __ add(T1, A0, length_reg);
  __ bltu(T1, A0, failure);  // Fail on unsigned overflow.

  // Check if the allocation fits into the remaining space.
  // A0: potential new object start.
  // T1: potential next object start.
  // A1: allocation size.
  __ lx(TMP, Address(THR, target::Thread::end_offset()));
  __ bgtu(T1, TMP, failure);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ sx(T1, Address(THR, target::Thread::top_offset()));
  __ AddImmediate(A0, kHeapObjectTag);

  // Initialize the tags.
  // A0: new object start as a tagged pointer.
  // T1: new object end address.
  // A1: allocation size.
  {
    const intptr_t shift = target::UntaggedObject::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2;

    __ CompareImmediate(A1, target::UntaggedObject::kSizeTagMaxSizeTag);
    Label dont_zero_tag;
    __ BranchIf(UNSIGNED_LESS_EQUAL, &dont_zero_tag);
    __ li(A1, 0);
    __ Bind(&dont_zero_tag);
    __ slli(A1, A1, shift);

    // Get the class index and insert it into the tags.
    // A1: size and bit tags.
    // This also clears the hash, which is in the high word of the tags.
    const uword tags =
        target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
    __ OrImmediate(A1, A1, tags);
    __ sx(A1, FieldAddress(A0, target::Object::tags_offset()));  // Store tags.
  }

  // Set the length field using the saved length (T0).
  __ StoreIntoObjectNoBarrier(
      A0, FieldAddress(A0, target::String::length_offset()), T0);
  __ j(ok);
}

// Arg0: OneByteString (receiver).
// Arg1: Start index as Smi.
// Arg2: End index as Smi.
// The indexes must be valid.
void AsmIntrinsifier::OneByteString_substringUnchecked(Assembler* assembler,
                                                       Label* normal_ir_body) {
  const intptr_t kStringOffset = 2 * target::kWordSize;
  const intptr_t kStartIndexOffset = 1 * target::kWordSize;
  const intptr_t kEndIndexOffset = 0 * target::kWordSize;
  Label ok;

  __ lx(T0, Address(SP, kEndIndexOffset));
  __ lx(TMP, Address(SP, kStartIndexOffset));
  __ or_(T1, T0, TMP);
  __ BranchIfNotSmi(T1, normal_ir_body);  // 'start', 'end' not Smi.

  __ sub(A1, T0, TMP);
  TryAllocateString(assembler, kOneByteStringCid, &ok, normal_ir_body);
  __ Bind(&ok);
  // A0: new string as tagged pointer.
  // Copy string.
  __ lx(T1, Address(SP, kStringOffset));
  __ lx(T2, Address(SP, kStartIndexOffset));
  __ SmiUntag(T2);
  // Calculate start address.
  __ add(T1, T1, T2);

  // T1: Start address to copy from.
  // T2: Untagged start index.
  __ lx(T0, Address(SP, kEndIndexOffset));
  __ SmiUntag(T0);
  __ sub(T0, T0, T2);

  // T1: Start address to copy from (untagged).
  // T0: Untagged number of bytes to copy.
  // A0: Tagged result string.
  // T3: Pointer into T1.
  // T4: Pointer into A0.
  // T2: Scratch register.
  Label loop, done;
  __ blez(T0, &done, Assembler::kNearJump);
  __ mv(T3, T1);
  __ mv(T4, A0);
  __ Bind(&loop);
  __ subi(T0, T0, 1);
  __ lbu(T2, FieldAddress(T3, target::OneByteString::data_offset()));
  __ addi(T3, T3, 1);
  __ sb(T2, FieldAddress(T4, target::OneByteString::data_offset()));
  __ addi(T4, T4, 1);
  __ bgtz(T0, &loop);

  __ Bind(&done);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::WriteIntoOneByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ lx(A0, Address(SP, 2 * target::kWordSize));  // OneByteString.
  __ lx(A1, Address(SP, 1 * target::kWordSize));  // Index.
  __ lx(A2, Address(SP, 0 * target::kWordSize));  // Value.
  __ SmiUntag(A1);
  __ SmiUntag(A2);
  __ add(A1, A1, A0);
  __ sb(A2, FieldAddress(A1, target::OneByteString::data_offset()));
  __ ret();
}

void AsmIntrinsifier::WriteIntoTwoByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ lx(A0, Address(SP, 2 * target::kWordSize));  // TwoByteString.
  __ lx(A1, Address(SP, 1 * target::kWordSize));  // Index.
  __ lx(A2, Address(SP, 0 * target::kWordSize));  // Value.
  // Untag index and multiply by element size -> no-op.
  __ SmiUntag(A2);
  __ add(A1, A1, A0);
  __ sh(A2, FieldAddress(A1, target::OneByteString::data_offset()));
  __ ret();
}

void AsmIntrinsifier::AllocateOneByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  Label ok;

  __ lx(A1, Address(SP, 0 * target::kWordSize));  // Length.
  TryAllocateString(assembler, kOneByteStringCid, &ok, normal_ir_body);

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AllocateTwoByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  Label ok;

  __ lx(A1, Address(SP, 0 * target::kWordSize));  // Length.
  TryAllocateString(assembler, kTwoByteStringCid, &ok, normal_ir_body);

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

// TODO(srdjan): Add combinations (one-byte/two-byte/external strings).
static void StringEquality(Assembler* assembler,
                           Label* normal_ir_body,
                           intptr_t string_cid) {
  Label is_true, is_false, loop;
  __ lx(A0, Address(SP, 1 * target::kWordSize));  // This.
  __ lx(A1, Address(SP, 0 * target::kWordSize));  // Other.

  // Are identical?
  __ beq(A0, A1, &is_true, Assembler::kNearJump);

  // Is other OneByteString?
  __ BranchIfSmi(A1, normal_ir_body, Assembler::kNearJump);
  __ CompareClassId(A1, string_cid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);

  // Have same length?
  __ lx(T2, FieldAddress(A0, target::String::length_offset()));
  __ lx(T3, FieldAddress(A1, target::String::length_offset()));
  __ bne(T2, T3, &is_false, Assembler::kNearJump);

  // Check contents, no fall-through possible.
  __ SmiUntag(T2);
  __ Bind(&loop);
  __ AddImmediate(T2, -1);
  __ bltz(T2, &is_true, Assembler::kNearJump);
  if (string_cid == kOneByteStringCid) {
    __ lbu(TMP, FieldAddress(A0, target::OneByteString::data_offset()));
    __ lbu(TMP2, FieldAddress(A1, target::OneByteString::data_offset()));
    __ addi(A0, A0, 1);
    __ addi(A1, A1, 1);
  } else if (string_cid == kTwoByteStringCid) {
    __ lhu(TMP, FieldAddress(A0, target::TwoByteString::data_offset()));
    __ lhu(TMP2, FieldAddress(A1, target::TwoByteString::data_offset()));
    __ addi(A0, A0, 2);
    __ addi(A1, A1, 2);
  } else {
    UNIMPLEMENTED();
  }
  __ bne(TMP, TMP2, &is_false, Assembler::kNearJump);
  __ j(&loop);

  __ Bind(&is_true);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(&is_false);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::OneByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  StringEquality(assembler, normal_ir_body, kOneByteStringCid);
}

void AsmIntrinsifier::TwoByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  StringEquality(assembler, normal_ir_body, kTwoByteStringCid);
}

void AsmIntrinsifier::IntrinsifyRegExpExecuteMatch(Assembler* assembler,
                                                   Label* normal_ir_body,
                                                   bool sticky) {
  if (FLAG_interpret_irregexp) return;

  static const intptr_t kRegExpParamOffset = 2 * target::kWordSize;
  static const intptr_t kStringParamOffset = 1 * target::kWordSize;
  // start_index smi is located at offset 0.

  // Incoming registers:
  // T0: Function. (Will be reloaded with the specialized matcher function.)
  // S4: Arguments descriptor. (Will be preserved.)
  // S5: Unknown. (Must be GC safe on tail call.)

  // Load the specialized function pointer into T0. Leverage the fact the
  // string CIDs as well as stored function pointers are in sequence.
  __ lx(T2, Address(SP, kRegExpParamOffset));
  __ lx(T1, Address(SP, kStringParamOffset));
  __ LoadClassId(T1, T1);
  __ AddImmediate(T1, -kOneByteStringCid);
  __ slli(T1, T1, target::kWordSizeLog2);
  __ add(T1, T1, T2);
  __ lx(T0, FieldAddress(T1, target::RegExp::function_offset(kOneByteStringCid,
                                                             sticky)));

  // Registers are now set up for the lazy compile stub. It expects the function
  // in T0, the argument descriptor in S4, and IC-Data in S5.
  __ li(S5, 0);

  // Tail-call the function.
  __ lx(CODE_REG, FieldAddress(T0, target::Function::code_offset()));
  __ lx(T1, FieldAddress(T0, target::Function::entry_point_offset()));
  __ jr(T1);
}

void AsmIntrinsifier::UserTag_defaultTag(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ LoadIsolate(A0);
  __ lx(A0, Address(A0, target::Isolate::default_tag_offset()));
  __ ret();
}

void AsmIntrinsifier::Profiler_getCurrentTag(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ LoadIsolate(A0);
  __ lx(A0, Address(A0, target::Isolate::current_tag_offset()));
  __ ret();
}

void AsmIntrinsifier::Timeline_isDartStreamEnabled(Assembler* assembler,
                                                   Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
#else
  Label true_label;
  // Load TimelineStream*.
  __ lx(A0, Address(THR, target::Thread::dart_stream_offset()));
  // Load uintptr_t from TimelineStream*.
  __ lx(A0, Address(A0, target::TimelineStream::enabled_offset()));
  __ bnez(A0, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();
#endif
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_RISCV)
