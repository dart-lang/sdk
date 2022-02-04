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

// Allocate a GrowableObjectArray:: using the backing array specified.
// On stack: type argument (+1), data (+0).
void AsmIntrinsifier::GrowableArray_Allocate(Assembler* assembler,
                                             Label* normal_ir_body) {
  // The newly allocated object is returned in R0.
  const intptr_t kTypeArgumentsOffset = 1 * target::kWordSize;
  const intptr_t kArrayOffset = 0 * target::kWordSize;

  // Try allocating in new space.
  const Class& cls = GrowableObjectArrayClass();
  __ TryAllocate(cls, normal_ir_body, Assembler::kFarJump, A0, A1);

  // Store backing array object in growable array object.
  __ lx(A1, Address(SP, kArrayOffset));  // Data argument.
  // R0 is new, no barrier needed.
  __ StoreCompressedIntoObjectNoBarrier(
      A0, FieldAddress(A0, target::GrowableObjectArray::data_offset()), A1);

  // R0: new growable array object start as a tagged pointer.
  // Store the type argument field in the growable array object.
  __ lx(A1, Address(SP, kTypeArgumentsOffset));  // Type argument.
  __ StoreCompressedIntoObjectNoBarrier(
      A0,
      FieldAddress(A0, target::GrowableObjectArray::type_arguments_offset()),
      A1);

  // Set the length field in the growable array object to 0.
  __ StoreCompressedIntoObjectNoBarrier(
      A0, FieldAddress(A0, target::GrowableObjectArray::length_offset()), ZR);
  __ ret();  // Returns the newly allocated object in A0.

  __ Bind(normal_ir_body);
}

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
  UNIMPLEMENTED();
}

// bool _substringMatches(int start, String other)
// This intrinsic handles a OneByteString or TwoByteString receiver with a
// OneByteString other.
void AsmIntrinsifier::StringBaseSubstringMatches(Assembler* assembler,
                                                 Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseCharAt(Assembler* assembler,
                                       Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseIsEmpty(Assembler* assembler,
                                        Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::OneByteString_getHashCode(Assembler* assembler,
                                                Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

// Arg0: OneByteString (receiver).
// Arg1: Start index as Smi.
// Arg2: End index as Smi.
// The indexes must be valid.
void AsmIntrinsifier::OneByteString_substringUnchecked(Assembler* assembler,
                                                       Label* normal_ir_body) {
  // TODO(riscv)
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
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AllocateTwoByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  // TODO(riscv)
  __ Bind(normal_ir_body);
}

// TODO(srdjan): Add combinations (one-byte/two-byte/external strings).
static void StringEquality(Assembler* assembler,
                           Label* normal_ir_body,
                           intptr_t string_cid) {
  // TODO(riscv)
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

  // TODO(riscv)
  __ Bind(normal_ir_body);
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
