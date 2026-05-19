// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/asm_intrinsifier.h"
#include "vm/compiler/assembler/assembler.h"

namespace dart {
namespace compiler {

#define __ assembler->

static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ Load(A0, Address(SP, +1 * target::kWordSize));
  __ Load(A1, Address(SP, +0 * target::kWordSize));
  __ or_(TMP, A0, A1);
  __ BranchIfNotSmi(TMP, not_smi, Assembler::kNearJump);
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

void AsmIntrinsifier::Smi_bitLength(Assembler* assembler,
                                    Label* normal_ir_body) {
  __ Load(A0, Address(SP, 0 * target::kWordSize));
  __ SmiUntag(A0);

  // XOR with sign bits to complement the value when it is negative.
  __ srai_d(A1, A0, XLEN - 1);
  __ xor_(A0, A0, A1);

  __ CountLeadingZeroes(A0, A0);
  __ LoadImmediate(TMP, XLEN);
  __ sub_d(A0, TMP, A0);
  __ SmiTag(A0);
  __ ret();
}

void AsmIntrinsifier::Bigint_lsh(Assembler* assembler, Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_rsh(Assembler* assembler, Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_absAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_absSub(Assembler* assembler,
                                    Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_mulAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_sqrAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Bigint_estimateQuotientDigit(Assembler* assembler,
                                                   Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Montgomery_mulMod(Assembler* assembler,
                                        Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

// FA0: left, FA1: right.
static void PrepareDoubleOp(Assembler* assembler, Label* normal_ir_body) {
  Label double_op;
  __ Load(A0, Address(SP, 1 * target::kWordSize));  // Left.
  __ Load(A1, Address(SP, 0 * target::kWordSize));  // Right.

  __ LoadDFieldFromOffset(FA0, A0, target::Double::value_offset());

  __ SmiUntag(TMP, A1);
  __ movgr2fr_d(FA1, TMP);
  __ ffint_d_l(FA1, FA1);
  __ BranchIfSmi(A1, &double_op, Assembler::kNearJump);
  __ CompareClassId(A1, kDoubleCid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);
  __ LoadDFieldFromOffset(FA1, A1, target::Double::value_offset());

  __ Bind(&double_op);
}

static void ReturnBool(Assembler* assembler, Register value) {
  Label true_label;
  __ bnez(value, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();
}

void AsmIntrinsifier::Double_greaterThan(Assembler* assembler,
                                         Label* normal_ir_body) {
  PrepareDoubleOp(assembler, normal_ir_body);
  __ fcmp_clt_d(FA1, FA0);
  __ movcf2gr(TMP);
  ReturnBool(assembler, TMP);
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_greaterEqualThan(Assembler* assembler,
                                              Label* normal_ir_body) {
  PrepareDoubleOp(assembler, normal_ir_body);
  __ fcmp_cle_d(FA1, FA0);
  __ movcf2gr(TMP);
  ReturnBool(assembler, TMP);
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_lessThan(Assembler* assembler,
                                      Label* normal_ir_body) {
  PrepareDoubleOp(assembler, normal_ir_body);
  __ fcmp_clt_d(FA0, FA1);
  __ movcf2gr(TMP);
  ReturnBool(assembler, TMP);
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_lessEqualThan(Assembler* assembler,
                                           Label* normal_ir_body) {
  PrepareDoubleOp(assembler, normal_ir_body);
  __ fcmp_cle_d(FA0, FA1);
  __ movcf2gr(TMP);
  ReturnBool(assembler, TMP);
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_equal(Assembler* assembler,
                                   Label* normal_ir_body) {
  PrepareDoubleOp(assembler, normal_ir_body);
  __ fcmp_ceq_d(FA0, FA1);
  __ movcf2gr(TMP);
  ReturnBool(assembler, TMP);
  __ Bind(normal_ir_body);
}

static void DoubleArithmeticOperation(Assembler* assembler,
                                      Label* normal_ir_body,
                                      Token::Kind kind) {
  PrepareDoubleOp(assembler, normal_ir_body);
  switch (kind) {
    case Token::kADD:
      __ fadd_d(FA0, FA0, FA1);
      break;
    case Token::kSUB:
      __ fsub_d(FA0, FA0, FA1);
      break;
    case Token::kMUL:
      __ fmul_d(FA0, FA0, FA1);
      break;
    case Token::kDIV:
      __ fdiv_d(FA0, FA0, FA1);
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
  DoubleArithmeticOperation(assembler, normal_ir_body, Token::kADD);
}

void AsmIntrinsifier::Double_sub(Assembler* assembler, Label* normal_ir_body) {
  DoubleArithmeticOperation(assembler, normal_ir_body, Token::kSUB);
}

void AsmIntrinsifier::Double_mul(Assembler* assembler, Label* normal_ir_body) {
  DoubleArithmeticOperation(assembler, normal_ir_body, Token::kMUL);
}

void AsmIntrinsifier::Double_div(Assembler* assembler, Label* normal_ir_body) {
  DoubleArithmeticOperation(assembler, normal_ir_body, Token::kDIV);
}

void AsmIntrinsifier::Double_getIsNaN(Assembler* assembler,
                                      Label* normal_ir_body) {
  __ Load(A0, Address(SP, 0 * target::kWordSize));
  __ LoadDFieldFromOffset(FA0, A0, target::Double::value_offset());
  __ fcmp_ceq_d(FA0, FA0);
  __ movcf2gr(TMP);
  __ xori(TMP, TMP, 1);
  ReturnBool(assembler, TMP);
}

void AsmIntrinsifier::Double_getIsInfinite(Assembler* assembler,
                                           Label* normal_ir_body) {
  Label true_label;
  __ Load(A0, Address(SP, 0 * target::kWordSize));
  __ LoadFieldFromOffset(A0, A0, target::Double::value_offset());
  __ slli_d(A0, A0, 1);
  __ srli_d(A0, A0, 1);
  __ LoadImmediate(TMP, 0x7FF0000000000000LL);
  __ CompareRegisters(A0, TMP);
  __ BranchIf(EQ, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();
}

void AsmIntrinsifier::Double_getIsNegative(Assembler* assembler,
                                           Label* normal_ir_body) {
  Label true_label;
  __ Load(A0, Address(SP, 0 * target::kWordSize));
  __ LoadFieldFromOffset(A0, A0, target::Double::value_offset());
  __ BranchIfBit(A0, 63, NOT_ZERO, &true_label, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();
}

void AsmIntrinsifier::Double_mulFromInteger(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ Load(A1, Address(SP, 0 * target::kWordSize));
  __ BranchIfNotSmi(A1, normal_ir_body, Assembler::kNearJump);
  __ SmiUntag(A1);
  __ movgr2fr_d(FA1, A1);
  __ ffint_d_l(FA1, FA1);
  __ Load(A0, Address(SP, 1 * target::kWordSize));
  __ LoadDFieldFromOffset(FA0, A0, target::Double::value_offset());
  __ fmul_d(FA0, FA0, FA1);
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kNearJump, A0, A1);
  __ StoreDFieldToOffset(FA0, A0, target::Double::value_offset());
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::DoubleFromInteger(Assembler* assembler,
                                        Label* normal_ir_body) {
  __ Load(A0, Address(SP, 0 * target::kWordSize));
  __ BranchIfNotSmi(A0, normal_ir_body, Assembler::kNearJump);
  __ SmiUntag(A0);
  __ movgr2fr_d(FA0, A0);
  __ ffint_d_l(FA0, FA0);
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kNearJump, A0, TMP);
  __ StoreDFieldToOffset(FA0, A0, target::Double::value_offset());
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::ObjectEquals(Assembler* assembler,
                                   Label* normal_ir_body) {
  Label is_true;
  __ Load(A0, Address(SP, 1 * target::kWordSize));
  __ Load(A1, Address(SP, 0 * target::kWordSize));
  __ beq(A0, A1, &is_true, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();
}

static void JumpIfInteger(Assembler* assembler,
                          Register cid,
                          Register tmp,
                          Label* target) {
  assembler->RangeCheck(cid, tmp, kSmiCid, kMintCid, Assembler::kIfInRange,
                        target);
}

static void JumpIfNotInteger(Assembler* assembler,
                             Register cid,
                             Register tmp,
                             Label* target) {
  assembler->RangeCheck(cid, tmp, kSmiCid, kMintCid, Assembler::kIfNotInRange,
                        target);
}

static void JumpIfString(Assembler* assembler,
                         Register cid,
                         Register tmp,
                         Label* target) {
  assembler->RangeCheck(cid, tmp, kOneByteStringCid, kTwoByteStringCid,
                        Assembler::kIfInRange, target);
}

static void JumpIfNotString(Assembler* assembler,
                            Register cid,
                            Register tmp,
                            Label* target) {
  assembler->RangeCheck(cid, tmp, kOneByteStringCid, kTwoByteStringCid,
                        Assembler::kIfNotInRange, target);
}

static void JumpIfNotList(Assembler* assembler,
                          Register cid,
                          Register tmp,
                          Label* target) {
  assembler->RangeCheck(cid, tmp, kArrayCid, kGrowableObjectArrayCid,
                        Assembler::kIfNotInRange, target);
}

static void JumpIfType(Assembler* assembler,
                       Register cid,
                       Register tmp,
                       Label* target) {
  COMPILE_ASSERT((kFunctionTypeCid == kTypeCid + 1) &&
                 (kRecordTypeCid == kTypeCid + 2));
  assembler->RangeCheck(cid, tmp, kTypeCid, kRecordTypeCid,
                        Assembler::kIfInRange, target);
}

static void JumpIfNotType(Assembler* assembler,
                          Register cid,
                          Register tmp,
                          Label* target) {
  COMPILE_ASSERT((kFunctionTypeCid == kTypeCid + 1) &&
                 (kRecordTypeCid == kTypeCid + 2));
  assembler->RangeCheck(cid, tmp, kTypeCid, kRecordTypeCid,
                        Assembler::kIfNotInRange, target);
}

// Return type quickly for simple types (not parameterized and not signature).
void AsmIntrinsifier::ObjectRuntimeType(Assembler* assembler,
                                        Label* normal_ir_body) {
  Label use_declaration_type, not_double, not_integer, not_string;
  __ Load(A0, Address(SP, 0 * target::kWordSize));
  __ LoadClassIdMayBeSmi(A1, A0);

  __ CompareImmediate(A1, kClosureCid);
  __ BranchIf(EQ, normal_ir_body,
              Assembler::kNearJump);  // Instance is a closure.

  __ CompareImmediate(A1, kRecordCid);
  __ BranchIf(EQ, normal_ir_body,
              Assembler::kNearJump);  // Instance is a record.

  __ CompareImmediate(A1, kNumPredefinedCids);
  __ BranchIf(HI, &use_declaration_type, Assembler::kNearJump);

  __ LoadIsolateGroup(T0);
  __ LoadFromOffset(T0, T0, target::IsolateGroup::object_store_offset());

  __ CompareImmediate(A1, kDoubleCid);
  __ BranchIf(NE, &not_double, Assembler::kNearJump);
  __ LoadFromOffset(A0, T0, target::ObjectStore::double_type_offset());
  __ ret();

  __ Bind(&not_double);
  JumpIfNotInteger(assembler, A1, TMP, &not_integer);
  __ LoadFromOffset(A0, T0, target::ObjectStore::int_type_offset());
  __ ret();

  __ Bind(&not_integer);
  JumpIfNotString(assembler, A1, TMP, &not_string);
  __ LoadFromOffset(A0, T0, target::ObjectStore::string_type_offset());
  __ ret();

  __ Bind(&not_string);
  JumpIfNotType(assembler, A1, TMP, &use_declaration_type);
  __ LoadFromOffset(A0, T0, target::ObjectStore::type_type_offset());
  __ ret();

  __ Bind(&use_declaration_type);
  __ LoadClassById(T0, A1);
  __ Load(T1, FieldAddress(T0, target::Class::num_type_arguments_offset()),
          kUnsignedTwoBytes);
  __ bnez(T1, normal_ir_body, Assembler::kNearJump);

  __ LoadCompressed(A0,
                    FieldAddress(T0, target::Class::declaration_type_offset()));
  __ beq(A0, NULL_REG, normal_ir_body, Assembler::kNearJump);
  __ ret();

  __ Bind(normal_ir_body);
}

// Compares cid1 and cid2 to see if they're syntactically equivalent. If this
// can be determined by this fast path, it jumps to either equal_* or not_equal.
// If classes are equivalent but may be generic, then jumps to
// equal_may_be_generic. Clobbers scratch.
static void EquivalentClassIds(Assembler* assembler,
                               Label* normal_ir_body,
                               Label* equal_may_be_generic,
                               Label* equal_not_generic,
                               Label* not_equal,
                               Register cid1,
                               Register cid2,
                               Register scratch,
                               bool testing_instance_cids) {
  Label not_integer, not_integer_or_string, not_integer_or_string_or_list;

  // Check if left hand side is a closure. Closures are handled in the runtime.
  __ CompareImmediate(cid1, kClosureCid);
  __ BranchIf(EQ, normal_ir_body, Assembler::kNearJump);

  // Check if left hand side is a record. Records are handled in the runtime.
  __ CompareImmediate(cid1, kRecordCid);
  __ BranchIf(EQ, normal_ir_body, Assembler::kNearJump);

  // Check whether class ids match. If class ids don't match types may still be
  // considered equivalent (e.g. multiple string implementation classes map to a
  // single String type).
  __ beq(cid1, cid2, equal_may_be_generic, Assembler::kNearJump);

  // Class ids are different. Check if we are comparing two string types (with
  // different representations), two integer types, two list types or two type
  // types.
  __ CompareImmediate(cid1, kNumPredefinedCids);
  __ BranchIf(HI, not_equal, Assembler::kNearJump);

  // Check if both are integer types.
  JumpIfNotInteger(assembler, cid1, scratch, &not_integer);

  // First type is an integer. Check if the second is an integer too.
  JumpIfInteger(assembler, cid2, scratch, equal_not_generic);
  // Integer types are only equivalent to other integer types.
  __ j(not_equal, Assembler::kNearJump);

  __ Bind(&not_integer);
  // Check if both are String types.
  JumpIfNotString(assembler, cid1, scratch,
                  testing_instance_cids ? &not_integer_or_string : not_equal);

  // First type is String. Check if the second is a string too.
  JumpIfString(assembler, cid2, scratch, equal_not_generic);
  // String types are only equivalent to other String types.
  __ j(not_equal, Assembler::kNearJump);

  if (testing_instance_cids) {
    __ Bind(&not_integer_or_string);
    // Check if both are List types.
    JumpIfNotList(assembler, cid1, scratch, &not_integer_or_string_or_list);

    // First type is a List. Check if the second is a List too.
    JumpIfNotList(assembler, cid2, scratch, not_equal);
    ASSERT(compiler::target::Array::type_arguments_offset() ==
           compiler::target::GrowableObjectArray::type_arguments_offset());
    __ j(equal_may_be_generic, Assembler::kNearJump);

    __ Bind(&not_integer_or_string_or_list);
    // Check if the first type is a Type. If it is not then types are not
    // equivalent because they have different class ids and they are not String
    // or integer or List or Type.
    JumpIfNotType(assembler, cid1, scratch, not_equal);

    // First type is a Type. Check if the second is a Type too.
    JumpIfType(assembler, cid2, scratch, equal_not_generic);
    // Type types are only equivalent to other Type types.
    __ j(not_equal, Assembler::kNearJump);
  }
}

void AsmIntrinsifier::ObjectHaveSameRuntimeType(Assembler* assembler,
                                                Label* normal_ir_body) {
  __ Load(A0, Address(SP, 1 * target::kWordSize));
  __ Load(A1, Address(SP, 0 * target::kWordSize));
  __ LoadClassIdMayBeSmi(T0, A1);
  __ LoadClassIdMayBeSmi(A1, A0);

  Label equal_may_be_generic, equal, not_equal;
  EquivalentClassIds(assembler, normal_ir_body, &equal_may_be_generic, &equal,
                     &not_equal, A1, T0, TMP,
                     /* testing_instance_cids = */ true);

  __ Bind(&equal_may_be_generic);
  // Classes are equivalent and neither is a closure class.
  // Check if there are no type arguments. In this case we can return true.
  // Otherwise fall through into the runtime to handle comparison.
  __ LoadClassById(A0, A1);
  __ Load(T1,
          FieldAddress(
              A0,
              target::Class::host_type_arguments_field_offset_in_words_offset()),
          kUnsignedFourBytes);
  __ CompareImmediate(T1, target::Class::kNoTypeArguments);
  __ BranchIf(EQ, &equal, Assembler::kNearJump);

  // Compare type arguments, host_type_arguments_field_offset_in_words in T1.
  __ Load(A0, Address(SP, 1 * target::kWordSize));
  __ Load(A1, Address(SP, 0 * target::kWordSize));
  __ slli_d(T1, T1, target::kCompressedWordSizeLog2);
  __ add_d(A0, A0, T1);
  __ add_d(A1, A1, T1);
  __ Load(A0, FieldAddress(A0, 0));
  __ Load(A1, FieldAddress(A1, 0));
  __ bne(A0, A1, normal_ir_body, Assembler::kNearJump);
  // Fall through to equal case if type arguments are equal.

  __ Bind(&equal);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ Ret();

  __ Bind(&not_equal);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::String_getHashCode(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseIsEmpty(Assembler* assembler,
                                        Label* normal_ir_body) {
  Label is_true;
  __ Load(A0, Address(SP, 0 * target::kWordSize));
  __ LoadCompressedSmi(A0, FieldAddress(A0, target::String::length_offset()));
  __ beqz(A0, &is_true, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();
  __ Bind(normal_ir_body);
}

static void GenerateSubstringMatchesSpecialization(Assembler* assembler,
                                                   intptr_t receiver_cid,
                                                   intptr_t other_cid,
                                                   Label* return_true,
                                                   Label* return_false) {
  __ SmiUntag(T0);
  __ LoadCompressedSmi(
      T1, FieldAddress(A0, target::String::length_offset()));
  __ SmiUntag(T1);
  __ LoadCompressedSmi(
      T3, FieldAddress(A1, target::String::length_offset()));
  __ SmiUntag(T3);

  __ beqz(T3, return_true, Assembler::kNearJump);
  __ blt(T0, ZR, return_false, Assembler::kNearJump);

  __ add_d(T4, T0, T3);
  __ blt(T1, T4, return_false, Assembler::kNearJump);

  if (receiver_cid == kOneByteStringCid) {
    __ add_d(A0, A0, T0);
  } else {
    ASSERT(receiver_cid == kTwoByteStringCid);
    __ slli_d(T4, T0, 1);
    __ add_d(A0, A0, T4);
  }

  __ LoadImmediate(T4, 0);

  Label loop;
  __ Bind(&loop);

  if (receiver_cid == kOneByteStringCid) {
    __ Load(TMP, FieldAddress(A0, target::OneByteString::data_offset()),
            kUnsignedByte);
  } else {
    __ Load(TMP, FieldAddress(A0, target::TwoByteString::data_offset()),
            kUnsignedTwoBytes);
  }

  if (other_cid == kOneByteStringCid) {
    __ Load(TMP2, FieldAddress(A1, target::OneByteString::data_offset()),
            kUnsignedByte);
  } else {
    __ Load(TMP2, FieldAddress(A1, target::TwoByteString::data_offset()),
            kUnsignedTwoBytes);
  }
  __ bne(TMP, TMP2, return_false, Assembler::kNearJump);

  __ AddImmediate(T4, T4, 1);
  __ AddImmediate(A0, A0, receiver_cid == kOneByteStringCid ? 1 : 2);
  __ AddImmediate(A1, A1, other_cid == kOneByteStringCid ? 1 : 2);
  __ blt(T4, T3, &loop, Assembler::kNearJump);

  __ j(return_true, Assembler::kNearJump);
}

void AsmIntrinsifier::StringBaseSubstringMatches(Assembler* assembler,
                                                 Label* normal_ir_body) {
  Label return_true, return_false, try_two_byte;
  __ Load(A0, Address(SP, 2 * target::kWordSize));
  __ Load(T0, Address(SP, 1 * target::kWordSize));
  __ Load(A1, Address(SP, 0 * target::kWordSize));

  __ BranchIfNotSmi(T0, normal_ir_body, Assembler::kNearJump);

  __ CompareClassId(A1, kOneByteStringCid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);

  __ CompareClassId(A0, kOneByteStringCid, TMP);
  __ BranchIf(NE, &try_two_byte, Assembler::kNearJump);

  GenerateSubstringMatchesSpecialization(assembler, kOneByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&try_two_byte);
  __ CompareClassId(A0, kTwoByteStringCid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);

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

  __ Load(A1, Address(SP, 0 * target::kWordSize));  // Index.
  __ Load(A0, Address(SP, 1 * target::kWordSize));  // String.
  __ BranchIfNotSmi(A1, normal_ir_body, Assembler::kNearJump);

  __ LoadCompressedSmi(TMP, FieldAddress(A0, target::String::length_offset()));
  __ bgeu(A1, TMP, normal_ir_body, Assembler::kNearJump);

  __ CompareClassId(A0, kOneByteStringCid, TMP);
  __ BranchIf(NE, &try_two_byte_string, Assembler::kNearJump);
  __ SmiUntag(A1);
  __ AddImmediate(A0, A0,
                  target::OneByteString::data_offset() - kHeapObjectTag);
  __ add_d(A0, A0, A1);
  __ Load(A1, Address(A0, 0), kUnsignedByte);
  __ CompareImmediate(A1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ BranchIf(GE, normal_ir_body, Assembler::kNearJump);
  __ Load(A0, Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ AddShifted(A0, A0, A1, target::kWordSizeLog2);
  __ Load(A0, Address(A0, target::Symbols::kNullCharCodeSymbolOffset *
                              target::kWordSize));
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(A0, kTwoByteStringCid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);
  ASSERT(kSmiTagShift == 1);
  __ AddImmediate(A0, A0,
                  target::TwoByteString::data_offset() - kHeapObjectTag);
  __ add_d(A0, A0, A1);
  __ Load(A1, Address(A0, 0), kUnsignedTwoBytes);
  __ CompareImmediate(A1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ BranchIf(GE, normal_ir_body, Assembler::kNearJump);
  __ Load(A0, Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ AddShifted(A0, A0, A1, target::kWordSizeLog2);
  __ Load(A0, Address(A0, target::Symbols::kNullCharCodeSymbolOffset *
                              target::kWordSize));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::OneByteString_getHashCode(Assembler* assembler,
                                                Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::OneByteString_substringUnchecked(
    Assembler* assembler,
    Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::OneByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::TwoByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AbstractType_getHashCode(Assembler* assembler,
                                               Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AbstractType_equality(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Type_equality(Assembler* assembler,
                                    Label* normal_ir_body) {
  __ Bind(normal_ir_body);
}

// Keep in sync with Instance::IdentityHashCode.
// Note int and double never reach here because they override _identityHashCode.
// Special cases are also not needed for null or bool because they were pre-set
// during VM isolate finalization.
void AsmIntrinsifier::Object_getHash(Assembler* assembler,
                                     Label* normal_ir_body) {
  Label not_yet_computed;
  __ Load(A0, Address(SP, 0 * target::kWordSize));  // Object.
  __ Load(A0, FieldAddress(A0, target::Object::tags_offset() +
                                   target::UntaggedObject::kHashTagPos /
                                       kBitsPerByte),
          kUnsignedFourBytes);
  __ beqz(A0, &not_yet_computed, Assembler::kNearJump);
  __ SmiTag(A0);
  __ ret();

  __ Bind(&not_yet_computed);
  __ Load(A1, Address(THR, target::Thread::random_offset()));
  __ AndImmediate(T5, A1, 0xffffffff);  // state_lo
  __ srli_d(T3, A1, 32);                // state_hi
  __ LoadImmediate(A1, 0xffffda61);     // A
  __ mul_d(A1, A1, T5);
  __ add_d(A1, A1, T3);  // new_state = (A * state_lo) + state_hi
  __ Store(A1, Address(THR, target::Thread::random_offset()));
  __ AndImmediate(A1, A1, 0x3fffffff);
  __ beqz(A1, &not_yet_computed, Assembler::kNearJump);

  __ Load(A0, Address(SP, 0 * target::kWordSize));  // Object.
  __ AddImmediate(A0, A0, -kHeapObjectTag);
  __ slli_d(T3, A1, target::UntaggedObject::kHashTagPos);

  Label retry, already_set;
  __ Bind(&retry);
  __ ll_d(T5, Address(A0, 0));
  __ srli_d(T4, T5, target::UntaggedObject::kHashTagPos);
  __ bnez(T4, &already_set, Assembler::kNearJump);
  __ or_(T5, T5, T3);
  __ sc_d(T5, Address(A0, 0));
  __ beqz(T5, &retry, Assembler::kNearJump);
  // Fall-through with A1 containing new hash value (untagged).
  __ SmiTag(A0, A1);
  __ ret();

  __ Bind(&already_set);
  __ SmiTag(A0, T4);
  __ ret();
}

void AsmIntrinsifier::Integer_greaterThan(Assembler* assembler,
                                          Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, GT);
}

void AsmIntrinsifier::Integer_equal(Assembler* assembler,
                                    Label* normal_ir_body) {
  Integer_equalToInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_equalToInteger(Assembler* assembler,
                                             Label* normal_ir_body) {
  Label true_label, check_for_mint;
  __ Load(A0, Address(SP, 1 * target::kWordSize));
  __ Load(A1, Address(SP, 0 * target::kWordSize));
  __ CompareObjectRegisters(A0, A1);
  __ BranchIf(EQ, &true_label, Assembler::kNearJump);

  __ or_(TMP, A0, A1);
  __ BranchIfNotSmi(TMP, &check_for_mint, Assembler::kNearJump);

  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(&check_for_mint);
  Label receiver_not_smi;
  __ BranchIfNotSmi(A0, &receiver_not_smi, Assembler::kNearJump);

  __ CompareClassId(A1, kDoubleCid, TMP);
  __ BranchIf(EQ, normal_ir_body, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(&receiver_not_smi);
  __ CompareClassId(A0, kMintCid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);
  __ BranchIfNotSmi(A1, normal_ir_body, Assembler::kNearJump);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_lessThan(Assembler* assembler,
                                       Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, LT);
}

void AsmIntrinsifier::Integer_lessEqualThan(Assembler* assembler,
                                            Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, LE);
}

void AsmIntrinsifier::Integer_greaterEqualThan(Assembler* assembler,
                                               Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, GE);
}

void AsmIntrinsifier::Integer_shl(Assembler* assembler,
                                  Label* normal_ir_body) {
  const Register left = A0;
  const Register right = A1;
  const Register result = A0;

  TestBothArgumentsSmis(assembler, normal_ir_body);
  __ CompareImmediate(right, target::ToRawSmi(target::kSmiBits),
                      compiler::kObjectBytes);
  __ BranchIf(CS, normal_ir_body, Assembler::kNearJump);

  __ SmiUntag(right);
  __ sll_d(TMP, left, right);
  __ sra_d(TMP2, TMP, right);
  __ bne(TMP2, left, normal_ir_body, Assembler::kNearJump);
  __ MoveRegister(result, TMP);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Timeline_getNextTaskId(Assembler* assembler,
                                             Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ LoadImmediate(A0, target::ToRawSmi(0));
  __ ret();
#else
  __ Load(A0, Address(THR, target::Thread::next_task_id_offset()));
  __ AddImmediate(A1, A0, 1);
  __ Store(A1, Address(THR, target::Thread::next_task_id_offset()));
  __ SmiTag(A0);  // Ignore loss of precision.
  __ ret();
#endif
}

static void TryAllocateString(Assembler* assembler,
                              classid_t cid,
                              intptr_t max_elements,
                              Label* ok,
                              Label* failure) {
  ASSERT(cid == kOneByteStringCid || cid == kTwoByteStringCid);
  const Register length_reg = A1;

  __ BranchIfNotSmi(length_reg, failure, Assembler::kNearJump);
  __ CompareImmediate(length_reg, target::ToRawSmi(max_elements));
  __ BranchIf(HI, failure, Assembler::kNearJump);

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, failure, TMP));
  __ MoveRegister(T0, length_reg);
  if (cid == kOneByteStringCid) {
    __ SmiUntag(length_reg);
  } else {
    ASSERT(kSmiTagSize == 1);
  }

  const intptr_t fixed_size_plus_alignment_padding =
      target::String::InstanceSize() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ AddImmediate(length_reg, length_reg, fixed_size_plus_alignment_padding);
  __ AndImmediate(length_reg,
                  ~(target::ObjectAlignment::kObjectAlignment - 1));

  __ Load(A0, Address(THR, target::Thread::top_offset()));
  __ add_d(T1, A0, length_reg);
  __ bltu(T1, A0, failure, Assembler::kNearJump);

  __ Load(TMP, Address(THR, target::Thread::end_offset()));
  __ bgeu(T1, TMP, failure, Assembler::kNearJump);
  __ CheckAllocationCanary(A0, TMP);

  __ Store(T1, Address(THR, target::Thread::top_offset()));
  __ AddImmediate(A0, A0, kHeapObjectTag);
  __ Store(ZR, Address(T1, -1 * target::kWordSize));
  __ Store(ZR, Address(T1, -2 * target::kWordSize));

  const intptr_t shift = target::UntaggedObject::kSizeTagPos -
                         target::ObjectAlignment::kObjectAlignmentLog2;
  __ CompareImmediate(length_reg, target::UntaggedObject::kSizeTagMaxSizeTag);
  Label dont_zero_tag;
  __ BranchIf(LS, &dont_zero_tag, Assembler::kNearJump);
  __ LoadImmediate(length_reg, 0);
  __ Bind(&dont_zero_tag);
  __ slli_d(length_reg, length_reg, shift);

  const uword tags =
      target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
  __ OrImmediate(length_reg, tags);
  __ InitializeHeader(length_reg, A0);

  __ StoreCompressedIntoObjectNoBarrier(
      A0, FieldAddress(A0, target::String::length_offset()), T0);
  __ j(ok, Assembler::kNearJump);
}

void AsmIntrinsifier::AllocateOneByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  Label ok;
  __ Load(A1, Address(SP, 0 * target::kWordSize));
  TryAllocateString(assembler, kOneByteStringCid,
                    target::OneByteString::kMaxNewSpaceElements, &ok,
                    normal_ir_body);
  __ Bind(&ok);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AllocateTwoByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  Label ok;
  __ Load(A1, Address(SP, 0 * target::kWordSize));
  TryAllocateString(assembler, kTwoByteStringCid,
                    target::TwoByteString::kMaxNewSpaceElements, &ok,
                    normal_ir_body);
  __ Bind(&ok);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::WriteIntoOneByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ Load(A0, Address(SP, 2 * target::kWordSize));  // OneByteString.
  __ Load(A1, Address(SP, 1 * target::kWordSize));  // Index.
  __ Load(A2, Address(SP, 0 * target::kWordSize));  // Value.
  __ SmiUntag(A1);
  __ SmiUntag(A2);
  __ add_d(A1, A1, A0);
  __ Store(A2, FieldAddress(A1, target::OneByteString::data_offset()), kByte);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::WriteIntoTwoByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ Load(A0, Address(SP, 2 * target::kWordSize));  // TwoByteString.
  __ Load(A1, Address(SP, 1 * target::kWordSize));  // Index.
  __ Load(A2, Address(SP, 0 * target::kWordSize));  // Value.
  __ SmiUntag(A2);
  __ add_d(A1, A1, A0);
  __ Store(A2, FieldAddress(A1, target::TwoByteString::data_offset()),
           kTwoBytes);
  __ ret();
  __ Bind(normal_ir_body);
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
