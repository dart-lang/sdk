// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/asm_intrinsifier.h"
#include "vm/compiler/assembler/assembler.h"

namespace dart {
namespace compiler {

// When entering intrinsics code:
// R4: Arguments descriptor
// LR: Return address
// The R4 register can be destroyed only if there is no slow-path, i.e.
// if the intrinsified method always executes a return.
// The FP register should not be modified, because it is used by the profiler.
// The PP and THR registers (see constants_arm.h) must be preserved.

#define __ assembler->

intptr_t AsmIntrinsifier::ParameterSlotFromSp() {
  return -1;
}

void AsmIntrinsifier::IntrinsicCallPrologue(Assembler* assembler) {
  COMPILE_ASSERT(IsAbiPreservedRegister(CODE_REG));
  COMPILE_ASSERT(IsAbiPreservedRegister(ARGS_DESC_REG));
  COMPILE_ASSERT(IsAbiPreservedRegister(CALLEE_SAVED_TEMP));

  // Save LR by moving it to a callee saved temporary register.
  __ Comment("IntrinsicCallPrologue");
  SPILLS_RETURN_ADDRESS_FROM_LR_TO_REGISTER(
      __ mov(CALLEE_SAVED_TEMP, Operand(LR)));
}

void AsmIntrinsifier::IntrinsicCallEpilogue(Assembler* assembler) {
  // Restore LR.
  __ Comment("IntrinsicCallEpilogue");
  RESTORES_RETURN_ADDRESS_FROM_REGISTER_TO_LR(
      __ mov(LR, Operand(CALLEE_SAVED_TEMP)));
}

// Allocate a GrowableObjectArray:: using the backing array specified.
// On stack: type argument (+1), data (+0).
void AsmIntrinsifier::GrowableArray_Allocate(Assembler* assembler,
                                             Label* normal_ir_body) {
  // The newly allocated object is returned in R0.
  const intptr_t kTypeArgumentsOffset = 1 * target::kWordSize;
  const intptr_t kArrayOffset = 0 * target::kWordSize;

  // Try allocating in new space.
  const Class& cls = GrowableObjectArrayClass();
  __ TryAllocate(cls, normal_ir_body, R0, R1);

  // Store backing array object in growable array object.
  __ ldr(R1, Address(SP, kArrayOffset));  // Data argument.
  // R0 is new, no barrier needed.
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, target::GrowableObjectArray::data_offset()), R1);

  // R0: new growable array object start as a tagged pointer.
  // Store the type argument field in the growable array object.
  __ ldr(R1, Address(SP, kTypeArgumentsOffset));  // Type argument.
  __ StoreIntoObjectNoBarrier(
      R0,
      FieldAddress(R0, target::GrowableObjectArray::type_arguments_offset()),
      R1);

  // Set the length field in the growable array object to 0.
  __ LoadImmediate(R1, 0);
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, target::GrowableObjectArray::length_offset()), R1);
  __ Ret();  // Returns the newly allocated object in R0.

  __ Bind(normal_ir_body);
}

// Loads args from stack into R0 and R1
// Tests if they are smis, jumps to label not_smi if not.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ ldr(R0, Address(SP, +0 * target::kWordSize));
  __ ldr(R1, Address(SP, +1 * target::kWordSize));
  __ orr(TMP, R0, Operand(R1));
  __ tst(TMP, Operand(kSmiTagMask));
  __ b(not_smi, NE);
}

void AsmIntrinsifier::Integer_addFromInteger(Assembler* assembler,
                                             Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);  // Checks two smis.
  __ adds(R0, R0, Operand(R1));                      // Adds.
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, VC));       // Return if no overflow.
  // Otherwise fall through.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_add(Assembler* assembler, Label* normal_ir_body) {
  Integer_addFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_subFromInteger(Assembler* assembler,
                                             Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  __ subs(R0, R0, Operand(R1));  // Subtract.
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, VC));  // Return if no overflow.
  // Otherwise fall through.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_sub(Assembler* assembler, Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  __ subs(R0, R1, Operand(R0));  // Subtract.
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, VC));  // Return if no overflow.
  // Otherwise fall through.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_mulFromInteger(Assembler* assembler,
                                             Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);  // checks two smis
  __ SmiUntag(R0);           // Untags R0. We only want result shifted by one.
  __ smull(R0, IP, R0, R1);  // IP:R0 <- R0 * R1.
  __ cmp(IP, Operand(R0, ASR, 31));
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, EQ));
  __ Bind(normal_ir_body);  // Fall through on overflow.
}

void AsmIntrinsifier::Integer_mul(Assembler* assembler, Label* normal_ir_body) {
  Integer_mulFromInteger(assembler, normal_ir_body);
}

// Optimizations:
// - result is 0 if:
//   - left is 0
//   - left equals right
// - result is left if
//   - left > 0 && left < right
// R1: Tagged left (dividend).
// R0: Tagged right (divisor).
// Returns:
//   R1: Untagged fallthrough result (remainder to be adjusted), or
//   R0: Tagged return result (remainder).
static void EmitRemainderOperation(Assembler* assembler) {
  Label modulo;
  const Register left = R1;
  const Register right = R0;
  const Register result = R1;
  const Register tmp = R2;
  ASSERT(left == result);

  // Check for quick zero results.
  __ cmp(left, Operand(0));
  __ mov(R0, Operand(0), EQ);
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, EQ));  // left is 0? Return 0.
  __ cmp(left, Operand(right));
  __ mov(R0, Operand(0), EQ);
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, EQ));  // left == right? Return 0.

  // Check if result should be left.
  __ cmp(left, Operand(0));
  __ b(&modulo, LT);
  // left is positive.
  __ cmp(left, Operand(right));
  // left is less than right, result is left.
  __ mov(R0, Operand(left), LT);
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, LT));
  __ Bind(&modulo);
  // result <- left - right * (left / right)
  __ SmiUntag(left);
  __ SmiUntag(right);

  __ IntegerDivide(tmp, left, right, D1, D0);

  __ mls(result, right, tmp, left);  // result <- left - right * TMP
}

// Implementation:
//  res = left % right;
//  if (res < 0) {
//    if (right < 0) {
//      res = res - right;
//    } else {
//      res = res + right;
//    }
//  }
void AsmIntrinsifier::Integer_moduloFromInteger(Assembler* assembler,
                                                Label* normal_ir_body) {
  if (!TargetCPUFeatures::can_divide()) {
    return;
  }
  // Check to see if we have integer division
  __ ldr(R1, Address(SP, +0 * target::kWordSize));
  __ ldr(R0, Address(SP, +1 * target::kWordSize));
  __ orr(TMP, R0, Operand(R1));
  __ tst(TMP, Operand(kSmiTagMask));
  __ b(normal_ir_body, NE);
  // R1: Tagged left (dividend).
  // R0: Tagged right (divisor).
  // Check if modulo by zero -> exception thrown in main function.
  __ cmp(R0, Operand(0));
  __ b(normal_ir_body, EQ);
  EmitRemainderOperation(assembler);
  // Untagged right in R0. Untagged remainder result in R1.

  __ cmp(R1, Operand(0));
  __ mov(R0, Operand(R1, LSL, 1), GE);  // Tag and move result to R0.
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, GE));
  // Result is negative, adjust it.
  __ cmp(R0, Operand(0));
  __ sub(R0, R1, Operand(R0), LT);
  __ add(R0, R1, Operand(R0), GE);
  __ SmiTag(R0);
  __ Ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_truncDivide(Assembler* assembler,
                                          Label* normal_ir_body) {
  if (!TargetCPUFeatures::can_divide()) {
    return;
  }
  // Check to see if we have integer division

  TestBothArgumentsSmis(assembler, normal_ir_body);
  __ cmp(R0, Operand(0));
  __ b(normal_ir_body, EQ);  // If b is 0, fall through.

  __ SmiUntag(R0);
  __ SmiUntag(R1);

  __ IntegerDivide(R0, R1, R0, D1, D0);

  // Check the corner case of dividing the 'MIN_SMI' with -1, in which case we
  // cannot tag the result.
  __ CompareImmediate(R0, 0x40000000);
  __ SmiTag(R0, NE);  // Not equal. Okay to tag and return.
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, NE));
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_negate(Assembler* assembler,
                                     Label* normal_ir_body) {
  __ ldr(R0, Address(SP, +0 * target::kWordSize));  // Grab first argument.
  __ tst(R0, Operand(kSmiTagMask));                 // Test for Smi.
  __ b(normal_ir_body, NE);
  __ rsbs(R0, R0, Operand(0));  // R0 is a Smi. R0 <- 0 - R0.
  READS_RETURN_ADDRESS_FROM_LR(__ bx(
      LR, VC));  // Return if there wasn't overflow, fall through otherwise.
  // R0 is not a Smi. Fall through.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_bitAndFromInteger(Assembler* assembler,
                                                Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);  // checks two smis
  __ and_(R0, R0, Operand(R1));

  __ Ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_bitAnd(Assembler* assembler,
                                     Label* normal_ir_body) {
  Integer_bitAndFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_bitOrFromInteger(Assembler* assembler,
                                               Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);  // checks two smis
  __ orr(R0, R0, Operand(R1));

  __ Ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_bitOr(Assembler* assembler,
                                    Label* normal_ir_body) {
  Integer_bitOrFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_bitXorFromInteger(Assembler* assembler,
                                                Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);  // checks two smis
  __ eor(R0, R0, Operand(R1));

  __ Ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_bitXor(Assembler* assembler,
                                     Label* normal_ir_body) {
  Integer_bitXorFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_shl(Assembler* assembler, Label* normal_ir_body) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(kSmiTag == 0);
  TestBothArgumentsSmis(assembler, normal_ir_body);
  __ CompareImmediate(R0, target::ToRawSmi(target::kSmiBits));
  __ b(normal_ir_body, HI);

  __ SmiUntag(R0);

  // Check for overflow by shifting left and shifting back arithmetically.
  // If the result is different from the original, there was overflow.
  __ mov(IP, Operand(R1, LSL, R0));
  __ cmp(R1, Operand(IP, ASR, R0));

  // No overflow, result in R0.
  __ mov(R0, Operand(R1, LSL, R0), EQ);
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, EQ));
  // Arguments are Smi but the shift produced an overflow to Mint.
  __ CompareImmediate(R1, 0);
  __ b(normal_ir_body, LT);
  __ SmiUntag(R1);

  // Pull off high bits that will be shifted off of R1 by making a mask
  // ((1 << R0) - 1), shifting it to the left, masking R1, then shifting back.
  // high bits = (((1 << R0) - 1) << (32 - R0)) & R1) >> (32 - R0)
  // lo bits = R1 << R0
  __ LoadImmediate(R8, 1);
  __ mov(R8, Operand(R8, LSL, R0));        // R8 <- 1 << R0
  __ sub(R8, R8, Operand(1));              // R8 <- R8 - 1
  __ rsb(R3, R0, Operand(32));             // R3 <- 32 - R0
  __ mov(R8, Operand(R8, LSL, R3));        // R8 <- R8 << R3
  __ and_(R8, R1, Operand(R8));            // R8 <- R8 & R1
  __ mov(R8, Operand(R8, LSR, R3));        // R8 <- R8 >> R3
  // Now R8 has the bits that fall off of R1 on a left shift.
  __ mov(R1, Operand(R1, LSL, R0));  // R1 gets the low bits.

  const Class& mint_class = MintClass();
  __ TryAllocate(mint_class, normal_ir_body, R0, R2);

  __ str(R1, FieldAddress(R0, target::Mint::value_offset()));
  __ str(R8,
         FieldAddress(R0, target::Mint::value_offset() + target::kWordSize));
  __ Ret();
  __ Bind(normal_ir_body);
}

static void Get64SmiOrMint(Assembler* assembler,
                           Register res_hi,
                           Register res_lo,
                           Register reg,
                           Label* not_smi_or_mint) {
  Label not_smi, done;
  __ tst(reg, Operand(kSmiTagMask));
  __ b(&not_smi, NE);
  __ SmiUntag(reg);

  // Sign extend to 64 bit
  __ mov(res_lo, Operand(reg));
  __ mov(res_hi, Operand(res_lo, ASR, 31));
  __ b(&done);

  __ Bind(&not_smi);
  __ CompareClassId(reg, kMintCid, res_lo);
  __ b(not_smi_or_mint, NE);

  // Mint.
  __ ldr(res_lo, FieldAddress(reg, target::Mint::value_offset()));
  __ ldr(res_hi,
         FieldAddress(reg, target::Mint::value_offset() + target::kWordSize));
  __ Bind(&done);
}

static void CompareIntegers(Assembler* assembler,
                            Label* normal_ir_body,
                            Condition true_condition) {
  Label try_mint_smi, is_true, is_false, drop_two_fall_through, fall_through;
  TestBothArgumentsSmis(assembler, &try_mint_smi);
  // R0 contains the right argument. R1 contains left argument

  __ cmp(R1, Operand(R0));
  __ b(&is_true, true_condition);
  __ Bind(&is_false);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ Ret();
  __ Bind(&is_true);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ Ret();

  // 64-bit comparison
  Condition hi_true_cond, hi_false_cond, lo_false_cond;
  switch (true_condition) {
    case LT:
    case LE:
      hi_true_cond = LT;
      hi_false_cond = GT;
      lo_false_cond = (true_condition == LT) ? CS : HI;
      break;
    case GT:
    case GE:
      hi_true_cond = GT;
      hi_false_cond = LT;
      lo_false_cond = (true_condition == GT) ? LS : CC;
      break;
    default:
      UNREACHABLE();
      hi_true_cond = hi_false_cond = lo_false_cond = VS;
  }

  __ Bind(&try_mint_smi);
  // Get left as 64 bit integer.
  Get64SmiOrMint(assembler, R3, R2, R1, normal_ir_body);
  // Get right as 64 bit integer.
  Get64SmiOrMint(assembler, R1, R8, R0, normal_ir_body);
  // R3: left high.
  // R2: left low.
  // R1: right high.
  // R8: right low.

  __ cmp(R3, Operand(R1));  // Compare left hi, right high.
  __ b(&is_false, hi_false_cond);
  __ b(&is_true, hi_true_cond);
  __ cmp(R2, Operand(R8));  // Compare left lo, right lo.
  __ b(&is_false, lo_false_cond);
  // Else is true.
  __ b(&is_true);

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_greaterThanFromInt(Assembler* assembler,
                                                 Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, LT);
}

void AsmIntrinsifier::Integer_lessThan(Assembler* assembler,
                                       Label* normal_ir_body) {
  Integer_greaterThanFromInt(assembler, normal_ir_body);
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
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ ldr(R1, Address(SP, 1 * target::kWordSize));
  __ cmp(R0, Operand(R1));
  __ b(&true_label, EQ);

  __ orr(R2, R0, Operand(R1));
  __ tst(R2, Operand(kSmiTagMask));
  __ b(&check_for_mint, NE);  // If R0 or R1 is not a smi do Mint checks.

  // Both arguments are smi, '===' is good enough.
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ Ret();
  __ Bind(&true_label);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ Ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);

  __ tst(R1, Operand(kSmiTagMask));  // Check receiver.
  __ b(&receiver_not_smi, NE);

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint never contains a value that can be
  // represented by Smi.

  __ CompareClassId(R0, kDoubleCid, R2);
  __ b(normal_ir_body, EQ);
  __ LoadObject(R0,
                CastHandle<Object>(FalseObject()));  // Smi == Mint -> false.
  __ Ret();

  __ Bind(&receiver_not_smi);
  // R1:: receiver.

  __ CompareClassId(R1, kMintCid, R2);
  __ b(normal_ir_body, NE);
  // Receiver is Mint, return false if right is Smi.
  __ tst(R0, Operand(kSmiTagMask));
  __ LoadObject(R0, CastHandle<Object>(FalseObject()), EQ);
  READS_RETURN_ADDRESS_FROM_LR(
      __ bx(LR, EQ));  // TODO(srdjan): Implement Mint == Mint comparison.

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_equal(Assembler* assembler,
                                    Label* normal_ir_body) {
  Integer_equalToInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_sar(Assembler* assembler, Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // Shift amount in R0. Value to shift in R1.

  // Fall through if shift amount is negative.
  __ SmiUntag(R0);
  __ CompareImmediate(R0, 0);
  __ b(normal_ir_body, LT);

  // If shift amount is bigger than 31, set to 31.
  __ CompareImmediate(R0, 0x1F);
  __ LoadImmediate(R0, 0x1F, GT);
  __ SmiUntag(R1);
  __ mov(R0, Operand(R1, ASR, R0));
  __ SmiTag(R0);
  __ Ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Smi_bitNegate(Assembler* assembler,
                                    Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ mvn(R0, Operand(R0));
  __ bic(R0, R0, Operand(kSmiTagMask));  // Remove inverted smi-tag.
  __ Ret();
}

void AsmIntrinsifier::Smi_bitLength(Assembler* assembler,
                                    Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ SmiUntag(R0);
  // XOR with sign bit to complement bits if value is negative.
  __ eor(R0, R0, Operand(R0, ASR, 31));
  __ clz(R0, R0);
  __ rsb(R0, R0, Operand(32));
  __ SmiTag(R0);
  __ Ret();
}

void AsmIntrinsifier::Smi_bitAndFromSmi(Assembler* assembler,
                                        Label* normal_ir_body) {
  Integer_bitAndFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Bigint_lsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // R0 = x_used, R1 = x_digits, x_used > 0, x_used is Smi.
  __ ldrd(R0, R1, SP, 2 * target::kWordSize);
  // R2 = r_digits, R3 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ ldrd(R2, R3, SP, 0 * target::kWordSize);
  __ SmiUntag(R3);
  // R4 = n ~/ _DIGIT_BITS
  __ Asr(R4, R3, Operand(5));
  // R8 = &x_digits[0]
  __ add(R8, R1, Operand(target::TypedData::data_offset() - kHeapObjectTag));
  // R6 = &r_digits[1]
  __ add(R6, R2,
         Operand(target::TypedData::data_offset() - kHeapObjectTag +
                 kBytesPerBigIntDigit));
  // R2 = &x_digits[x_used]
  __ add(R2, R8, Operand(R0, LSL, 1));
  // R6 = &r_digits[x_used + n ~/ _DIGIT_BITS + 1]
  __ add(R4, R4, Operand(R0, ASR, 1));
  __ add(R6, R6, Operand(R4, LSL, 2));
  // R1 = n % _DIGIT_BITS
  __ and_(R1, R3, Operand(31));
  // R0 = 32 - R1
  __ rsb(R0, R1, Operand(32));
  __ mov(R9, Operand(0));
  Label loop;
  __ Bind(&loop);
  __ ldr(R4, Address(R2, -kBytesPerBigIntDigit, Address::PreIndex));
  __ orr(R9, R9, Operand(R4, LSR, R0));
  __ str(R9, Address(R6, -kBytesPerBigIntDigit, Address::PreIndex));
  __ mov(R9, Operand(R4, LSL, R1));
  __ teq(R2, Operand(R8));
  __ b(&loop, NE);
  __ str(R9, Address(R6, -kBytesPerBigIntDigit, Address::PreIndex));
  __ LoadObject(R0, NullObject());
  __ Ret();
}

void AsmIntrinsifier::Bigint_rsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // R0 = x_used, R1 = x_digits, x_used > 0, x_used is Smi.
  __ ldrd(R0, R1, SP, 2 * target::kWordSize);
  // R2 = r_digits, R3 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ ldrd(R2, R3, SP, 0 * target::kWordSize);
  __ SmiUntag(R3);
  // R4 = n ~/ _DIGIT_BITS
  __ Asr(R4, R3, Operand(5));
  // R6 = &r_digits[0]
  __ add(R6, R2, Operand(target::TypedData::data_offset() - kHeapObjectTag));
  // R2 = &x_digits[n ~/ _DIGIT_BITS]
  __ add(R2, R1, Operand(target::TypedData::data_offset() - kHeapObjectTag));
  __ add(R2, R2, Operand(R4, LSL, 2));
  // R8 = &r_digits[x_used - n ~/ _DIGIT_BITS - 1]
  __ add(R4, R4, Operand(1));
  __ rsb(R4, R4, Operand(R0, ASR, 1));
  __ add(R8, R6, Operand(R4, LSL, 2));
  // R1 = n % _DIGIT_BITS
  __ and_(R1, R3, Operand(31));
  // R0 = 32 - R1
  __ rsb(R0, R1, Operand(32));
  // R9 = x_digits[n ~/ _DIGIT_BITS] >> (n % _DIGIT_BITS)
  __ ldr(R9, Address(R2, kBytesPerBigIntDigit, Address::PostIndex));
  __ mov(R9, Operand(R9, LSR, R1));
  Label loop_entry;
  __ b(&loop_entry);
  Label loop;
  __ Bind(&loop);
  __ ldr(R4, Address(R2, kBytesPerBigIntDigit, Address::PostIndex));
  __ orr(R9, R9, Operand(R4, LSL, R0));
  __ str(R9, Address(R6, kBytesPerBigIntDigit, Address::PostIndex));
  __ mov(R9, Operand(R4, LSR, R1));
  __ Bind(&loop_entry);
  __ teq(R6, Operand(R8));
  __ b(&loop, NE);
  __ str(R9, Address(R6, 0));
  __ LoadObject(R0, NullObject());
  __ Ret();
}

void AsmIntrinsifier::Bigint_absAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absAdd(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // R0 = used, R1 = digits
  __ ldrd(R0, R1, SP, 3 * target::kWordSize);
  // R1 = &digits[0]
  __ add(R1, R1, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R2 = a_used, R3 = a_digits
  __ ldrd(R2, R3, SP, 1 * target::kWordSize);
  // R3 = &a_digits[0]
  __ add(R3, R3, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R8 = r_digits
  __ ldr(R8, Address(SP, 0 * target::kWordSize));
  // R8 = &r_digits[0]
  __ add(R8, R8, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R2 = &digits[a_used >> 1], a_used is Smi.
  __ add(R2, R1, Operand(R2, LSL, 1));

  // R6 = &digits[used >> 1], used is Smi.
  __ add(R6, R1, Operand(R0, LSL, 1));

  __ adds(R4, R4, Operand(0));  // carry flag = 0
  Label add_loop;
  __ Bind(&add_loop);
  // Loop a_used times, a_used > 0.
  __ ldr(R4, Address(R1, kBytesPerBigIntDigit, Address::PostIndex));
  __ ldr(R9, Address(R3, kBytesPerBigIntDigit, Address::PostIndex));
  __ adcs(R4, R4, Operand(R9));
  __ teq(R1, Operand(R2));  // Does not affect carry flag.
  __ str(R4, Address(R8, kBytesPerBigIntDigit, Address::PostIndex));
  __ b(&add_loop, NE);

  Label last_carry;
  __ teq(R1, Operand(R6));  // Does not affect carry flag.
  __ b(&last_carry, EQ);    // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop used - a_used times, used - a_used > 0.
  __ ldr(R4, Address(R1, kBytesPerBigIntDigit, Address::PostIndex));
  __ adcs(R4, R4, Operand(0));
  __ teq(R1, Operand(R6));  // Does not affect carry flag.
  __ str(R4, Address(R8, kBytesPerBigIntDigit, Address::PostIndex));
  __ b(&carry_loop, NE);

  __ Bind(&last_carry);
  __ mov(R4, Operand(0));
  __ adc(R4, R4, Operand(0));
  __ str(R4, Address(R8, 0));

  __ LoadObject(R0, NullObject());
  __ Ret();
}

void AsmIntrinsifier::Bigint_absSub(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absSub(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // R0 = used, R1 = digits
  __ ldrd(R0, R1, SP, 3 * target::kWordSize);
  // R1 = &digits[0]
  __ add(R1, R1, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R2 = a_used, R3 = a_digits
  __ ldrd(R2, R3, SP, 1 * target::kWordSize);
  // R3 = &a_digits[0]
  __ add(R3, R3, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R8 = r_digits
  __ ldr(R8, Address(SP, 0 * target::kWordSize));
  // R8 = &r_digits[0]
  __ add(R8, R8, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R2 = &digits[a_used >> 1], a_used is Smi.
  __ add(R2, R1, Operand(R2, LSL, 1));

  // R6 = &digits[used >> 1], used is Smi.
  __ add(R6, R1, Operand(R0, LSL, 1));

  __ subs(R4, R4, Operand(0));  // carry flag = 1
  Label sub_loop;
  __ Bind(&sub_loop);
  // Loop a_used times, a_used > 0.
  __ ldr(R4, Address(R1, kBytesPerBigIntDigit, Address::PostIndex));
  __ ldr(R9, Address(R3, kBytesPerBigIntDigit, Address::PostIndex));
  __ sbcs(R4, R4, Operand(R9));
  __ teq(R1, Operand(R2));  // Does not affect carry flag.
  __ str(R4, Address(R8, kBytesPerBigIntDigit, Address::PostIndex));
  __ b(&sub_loop, NE);

  Label done;
  __ teq(R1, Operand(R6));  // Does not affect carry flag.
  __ b(&done, EQ);          // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop used - a_used times, used - a_used > 0.
  __ ldr(R4, Address(R1, kBytesPerBigIntDigit, Address::PostIndex));
  __ sbcs(R4, R4, Operand(0));
  __ teq(R1, Operand(R6));  // Does not affect carry flag.
  __ str(R4, Address(R8, kBytesPerBigIntDigit, Address::PostIndex));
  __ b(&carry_loop, NE);

  __ Bind(&done);
  __ LoadObject(R0, NullObject());
  __ Ret();
}

void AsmIntrinsifier::Bigint_mulAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // Pseudo code:
  // static int _mulAdd(Uint32List x_digits, int xi,
  //                    Uint32List m_digits, int i,
  //                    Uint32List a_digits, int j, int n) {
  //   uint32_t x = x_digits[xi >> 1];  // xi is Smi.
  //   if (x == 0 || n == 0) {
  //     return 1;
  //   }
  //   uint32_t* mip = &m_digits[i >> 1];  // i is Smi.
  //   uint32_t* ajp = &a_digits[j >> 1];  // j is Smi.
  //   uint32_t c = 0;
  //   SmiUntag(n);
  //   do {
  //     uint32_t mi = *mip++;
  //     uint32_t aj = *ajp;
  //     uint64_t t = x*mi + aj + c;  // 32-bit * 32-bit -> 64-bit.
  //     *ajp++ = low32(t);
  //     c = high32(t);
  //   } while (--n > 0);
  //   while (c != 0) {
  //     uint64_t t = *ajp + c;
  //     *ajp++ = low32(t);
  //     c = high32(t);  // c == 0 or 1.
  //   }
  //   return 1;
  // }

  Label done;
  // R3 = x, no_op if x == 0
  __ ldrd(R0, R1, SP, 5 * target::kWordSize);  // R0 = xi as Smi, R1 = x_digits.
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R3, FieldAddress(R1, target::TypedData::data_offset()));
  __ tst(R3, Operand(R3));
  __ b(&done, EQ);

  // R8 = SmiUntag(n), no_op if n == 0
  __ ldr(R8, Address(SP, 0 * target::kWordSize));
  __ Asrs(R8, R8, Operand(kSmiTagSize));
  __ b(&done, EQ);

  // R4 = mip = &m_digits[i >> 1]
  __ ldrd(R0, R1, SP, 3 * target::kWordSize);  // R0 = i as Smi, R1 = m_digits.
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ add(R4, R1, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R9 = ajp = &a_digits[j >> 1]
  __ ldrd(R0, R1, SP, 1 * target::kWordSize);  // R0 = j as Smi, R1 = a_digits.
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ add(R9, R1, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R1 = c = 0
  __ mov(R1, Operand(0));

  Label muladd_loop;
  __ Bind(&muladd_loop);
  // x:   R3
  // mip: R4
  // ajp: R9
  // c:   R1
  // n:   R8

  // uint32_t mi = *mip++
  __ ldr(R2, Address(R4, kBytesPerBigIntDigit, Address::PostIndex));

  // uint32_t aj = *ajp
  __ ldr(R0, Address(R9, 0));

  // uint64_t t = x*mi + aj + c
  __ umaal(R0, R1, R2, R3);  // R1:R0 = R2*R3 + R1 + R0.

  // *ajp++ = low32(t) = R0
  __ str(R0, Address(R9, kBytesPerBigIntDigit, Address::PostIndex));

  // c = high32(t) = R1

  // while (--n > 0)
  __ subs(R8, R8, Operand(1));  // --n
  __ b(&muladd_loop, NE);

  __ tst(R1, Operand(R1));
  __ b(&done, EQ);

  // *ajp++ += c
  __ ldr(R0, Address(R9, 0));
  __ adds(R0, R0, Operand(R1));
  __ str(R0, Address(R9, kBytesPerBigIntDigit, Address::PostIndex));
  __ b(&done, CC);

  Label propagate_carry_loop;
  __ Bind(&propagate_carry_loop);
  __ ldr(R0, Address(R9, 0));
  __ adds(R0, R0, Operand(1));
  __ str(R0, Address(R9, kBytesPerBigIntDigit, Address::PostIndex));
  __ b(&propagate_carry_loop, CS);

  __ Bind(&done);
  __ mov(R0, Operand(target::ToRawSmi(1)));  // One digit processed.
  __ Ret();
}

void AsmIntrinsifier::Bigint_sqrAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // Pseudo code:
  // static int _sqrAdd(Uint32List x_digits, int i,
  //                    Uint32List a_digits, int used) {
  //   uint32_t* xip = &x_digits[i >> 1];  // i is Smi.
  //   uint32_t x = *xip++;
  //   if (x == 0) return 1;
  //   uint32_t* ajp = &a_digits[i];  // j == 2*i, i is Smi.
  //   uint32_t aj = *ajp;
  //   uint64_t t = x*x + aj;
  //   *ajp++ = low32(t);
  //   uint64_t c = high32(t);
  //   int n = ((used - i) >> 1) - 1;  // used and i are Smi.
  //   while (--n >= 0) {
  //     uint32_t xi = *xip++;
  //     uint32_t aj = *ajp;
  //     uint96_t t = 2*x*xi + aj + c;  // 2-bit * 32-bit * 32-bit -> 65-bit.
  //     *ajp++ = low32(t);
  //     c = high64(t);  // 33-bit.
  //   }
  //   uint32_t aj = *ajp;
  //   uint64_t t = aj + c;  // 32-bit + 33-bit -> 34-bit.
  //   *ajp++ = low32(t);
  //   *ajp = high32(t);
  //   return 1;
  // }

  // The code has no bailout path, so we can use R6 (CODE_REG) freely.

  // R4 = xip = &x_digits[i >> 1]
  __ ldrd(R2, R3, SP, 2 * target::kWordSize);  // R2 = i as Smi, R3 = x_digits
  __ add(R3, R3, Operand(R2, LSL, 1));
  __ add(R4, R3, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R3 = x = *xip++, return if x == 0
  Label x_zero;
  __ ldr(R3, Address(R4, kBytesPerBigIntDigit, Address::PostIndex));
  __ tst(R3, Operand(R3));
  __ b(&x_zero, EQ);

  // R6 = ajp = &a_digits[i]
  __ ldr(R1, Address(SP, 1 * target::kWordSize));  // a_digits
  __ add(R1, R1, Operand(R2, LSL, 2));             // j == 2*i, i is Smi.
  __ add(R6, R1, Operand(target::TypedData::data_offset() - kHeapObjectTag));

  // R8:R0 = t = x*x + *ajp
  __ ldr(R0, Address(R6, 0));
  __ mov(R8, Operand(0));
  __ umaal(R0, R8, R3, R3);  // R8:R0 = R3*R3 + R8 + R0.

  // *ajp++ = low32(t) = R0
  __ str(R0, Address(R6, kBytesPerBigIntDigit, Address::PostIndex));

  // R8 = low32(c) = high32(t)
  // R9 = high32(c) = 0
  __ mov(R9, Operand(0));

  // int n = used - i - 1; while (--n >= 0) ...
  __ ldr(R0, Address(SP, 0 * target::kWordSize));  // used is Smi
  __ sub(TMP, R0, Operand(R2));
  __ mov(R0, Operand(2));  // n = used - i - 2; if (n >= 0) ... while (--n >= 0)
  __ rsbs(TMP, R0, Operand(TMP, ASR, kSmiTagSize));

  Label loop, done;
  __ b(&done, MI);

  __ Bind(&loop);
  // x:   R3
  // xip: R4
  // ajp: R6
  // c:   R9:R8
  // t:   R2:R1:R0 (not live at loop entry)
  // n:   TMP

  // uint32_t xi = *xip++
  __ ldr(R2, Address(R4, kBytesPerBigIntDigit, Address::PostIndex));

  // uint96_t t = R9:R8:R0 = 2*x*xi + aj + c
  __ umull(R0, R1, R2, R3);  // R1:R0 = R2*R3.
  __ adds(R0, R0, Operand(R0));
  __ adcs(R1, R1, Operand(R1));
  __ mov(R2, Operand(0));
  __ adc(R2, R2, Operand(0));  // R2:R1:R0 = 2*x*xi.
  __ adds(R0, R0, Operand(R8));
  __ adcs(R1, R1, Operand(R9));
  __ adc(R2, R2, Operand(0));  // R2:R1:R0 = 2*x*xi + c.
  __ ldr(R8, Address(R6, 0));  // R8 = aj = *ajp.
  __ adds(R0, R0, Operand(R8));
  __ adcs(R8, R1, Operand(0));
  __ adc(R9, R2, Operand(0));  // R9:R8:R0 = 2*x*xi + c + aj.

  // *ajp++ = low32(t) = R0
  __ str(R0, Address(R6, kBytesPerBigIntDigit, Address::PostIndex));

  // while (--n >= 0)
  __ subs(TMP, TMP, Operand(1));  // --n
  __ b(&loop, PL);

  __ Bind(&done);
  // uint32_t aj = *ajp
  __ ldr(R0, Address(R6, 0));

  // uint64_t t = aj + c
  __ adds(R8, R8, Operand(R0));
  __ adc(R9, R9, Operand(0));

  // *ajp = low32(t) = R8
  // *(ajp + 1) = high32(t) = R9
  __ strd(R8, R9, R6, 0);

  __ Bind(&x_zero);
  __ mov(R0, Operand(target::ToRawSmi(1)));  // One digit processed.
  __ Ret();
}

void AsmIntrinsifier::Bigint_estimateQuotientDigit(Assembler* assembler,
                                                   Label* normal_ir_body) {
  // No unsigned 64-bit / 32-bit divide instruction.
}

void AsmIntrinsifier::Montgomery_mulMod(Assembler* assembler,
                                        Label* normal_ir_body) {
  // Pseudo code:
  // static int _mulMod(Uint32List args, Uint32List digits, int i) {
  //   uint32_t rho = args[_RHO];  // _RHO == 2.
  //   uint32_t d = digits[i >> 1];  // i is Smi.
  //   uint64_t t = rho*d;
  //   args[_MU] = t mod DIGIT_BASE;  // _MU == 4.
  //   return 1;
  // }

  // R4 = args
  __ ldr(R4, Address(SP, 2 * target::kWordSize));  // args

  // R3 = rho = args[2]
  __ ldr(R3, FieldAddress(R4, target::TypedData::data_offset() +
                                  2 * kBytesPerBigIntDigit));

  // R2 = digits[i >> 1]
  __ ldrd(R0, R1, SP, 0 * target::kWordSize);  // R0 = i as Smi, R1 = digits
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R2, FieldAddress(R1, target::TypedData::data_offset()));

  // R1:R0 = t = rho*d
  __ umull(R0, R1, R2, R3);

  // args[4] = t mod DIGIT_BASE = low32(t)
  __ str(R0, FieldAddress(R4, target::TypedData::data_offset() +
                                  4 * kBytesPerBigIntDigit));

  __ mov(R0, Operand(target::ToRawSmi(1)));  // One digit processed.
  __ Ret();
}

// Check if the last argument is a double, jump to label 'is_smi' if smi
// (easy to convert to double), otherwise jump to label 'not_double_smi',
// Returns the last argument in R0.
static void TestLastArgumentIsDouble(Assembler* assembler,
                                     Label* is_smi,
                                     Label* not_double_smi) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ tst(R0, Operand(kSmiTagMask));
  __ b(is_smi, EQ);
  __ CompareClassId(R0, kDoubleCid, R1);
  __ b(not_double_smi, NE);
  // Fall through with Double in R0.
}

// Both arguments on stack, arg0 (left) is a double, arg1 (right) is of unknown
// type. Return true or false object in the register R0. Any NaN argument
// returns false. Any non-double arg1 causes control flow to fall through to the
// slow case (compiled method body).
static void CompareDoubles(Assembler* assembler,
                           Label* normal_ir_body,
                           Condition true_condition) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label is_smi, double_op;

    TestLastArgumentIsDouble(assembler, &is_smi, normal_ir_body);
    // Both arguments are double, right operand is in R0.

    __ LoadDFromOffset(D1, R0, target::Double::value_offset() - kHeapObjectTag);
    __ Bind(&double_op);
    __ ldr(R0, Address(SP, 1 * target::kWordSize));  // Left argument.
    __ LoadDFromOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);

    __ vcmpd(D0, D1);
    __ vmstat();
    __ LoadObject(R0, CastHandle<Object>(FalseObject()));
    // Return false if D0 or D1 was NaN before checking true condition.
    READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, VS));
    __ LoadObject(R0, CastHandle<Object>(TrueObject()), true_condition);
    __ Ret();

    __ Bind(&is_smi);  // Convert R0 to a double.
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D1, S0);
    __ b(&double_op);  // Then do the comparison.
    __ Bind(normal_ir_body);
  }
}

void AsmIntrinsifier::Double_greaterThan(Assembler* assembler,
                                         Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, HI);
}

void AsmIntrinsifier::Double_greaterEqualThan(Assembler* assembler,
                                              Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, CS);
}

void AsmIntrinsifier::Double_lessThan(Assembler* assembler,
                                      Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, CC);
}

void AsmIntrinsifier::Double_equal(Assembler* assembler,
                                   Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, EQ);
}

void AsmIntrinsifier::Double_lessEqualThan(Assembler* assembler,
                                           Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, LS);
}

// Expects left argument to be double (receiver). Right argument is unknown.
// Both arguments are on stack.
static void DoubleArithmeticOperations(Assembler* assembler,
                                       Label* normal_ir_body,
                                       Token::Kind kind) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label is_smi, double_op;

    TestLastArgumentIsDouble(assembler, &is_smi, normal_ir_body);
    // Both arguments are double, right operand is in R0.
    __ LoadDFromOffset(D1, R0, target::Double::value_offset() - kHeapObjectTag);
    __ Bind(&double_op);
    __ ldr(R0, Address(SP, 1 * target::kWordSize));  // Left argument.
    __ LoadDFromOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);
    switch (kind) {
      case Token::kADD:
        __ vaddd(D0, D0, D1);
        break;
      case Token::kSUB:
        __ vsubd(D0, D0, D1);
        break;
      case Token::kMUL:
        __ vmuld(D0, D0, D1);
        break;
      case Token::kDIV:
        __ vdivd(D0, D0, D1);
        break;
      default:
        UNREACHABLE();
    }
    const Class& double_class = DoubleClass();
    __ TryAllocate(double_class, normal_ir_body, R0,
                   R1);  // Result register.
    __ StoreDToOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);
    __ Ret();
    __ Bind(&is_smi);  // Convert R0 to a double.
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D1, S0);
    __ b(&double_op);
    __ Bind(normal_ir_body);
  }
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
  if (TargetCPUFeatures::vfp_supported()) {
    Label fall_through;
    // Only smis allowed.
    __ ldr(R0, Address(SP, 0 * target::kWordSize));
    __ tst(R0, Operand(kSmiTagMask));
    __ b(normal_ir_body, NE);
    // Is Smi.
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D1, S0);
    __ ldr(R0, Address(SP, 1 * target::kWordSize));
    __ LoadDFromOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);
    __ vmuld(D0, D0, D1);
    const Class& double_class = DoubleClass();
    __ TryAllocate(double_class, normal_ir_body, R0,
                   R1);  // Result register.
    __ StoreDToOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);
    __ Ret();
    __ Bind(normal_ir_body);
  }
}

void AsmIntrinsifier::DoubleFromInteger(Assembler* assembler,
                                        Label* normal_ir_body) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label fall_through;

    __ ldr(R0, Address(SP, 0 * target::kWordSize));
    __ tst(R0, Operand(kSmiTagMask));
    __ b(normal_ir_body, NE);
    // Is Smi.
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D0, S0);
    const Class& double_class = DoubleClass();
    __ TryAllocate(double_class, normal_ir_body, R0,
                   R1);  // Result register.
    __ StoreDToOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);
    __ Ret();
    __ Bind(normal_ir_body);
  }
}

void AsmIntrinsifier::Double_getIsNaN(Assembler* assembler,
                                      Label* normal_ir_body) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ ldr(R0, Address(SP, 0 * target::kWordSize));
    __ LoadDFromOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);
    __ vcmpd(D0, D0);
    __ vmstat();
    __ LoadObject(R0, CastHandle<Object>(FalseObject()), VC);
    __ LoadObject(R0, CastHandle<Object>(TrueObject()), VS);
    __ Ret();
  }
}

void AsmIntrinsifier::Double_getIsInfinite(Assembler* assembler,
                                           Label* normal_ir_body) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ ldr(R0, Address(SP, 0 * target::kWordSize));
    // R1 <- value[0:31], R2 <- value[32:63]
    __ LoadFieldFromOffset(R1, R0, target::Double::value_offset());
    __ LoadFieldFromOffset(R2, R0,
                           target::Double::value_offset() + target::kWordSize);

    // If the low word isn't 0, then it isn't infinity.
    __ cmp(R1, Operand(0));
    __ LoadObject(R0, CastHandle<Object>(FalseObject()), NE);
    READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, NE));  // Return if NE.

    // Mask off the sign bit.
    __ AndImmediate(R2, R2, 0x7FFFFFFF);
    // Compare with +infinity.
    __ CompareImmediate(R2, 0x7FF00000);
    __ LoadObject(R0, CastHandle<Object>(FalseObject()), NE);
    READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, NE));
    __ LoadObject(R0, CastHandle<Object>(TrueObject()));
    __ Ret();
  }
}

void AsmIntrinsifier::Double_getIsNegative(Assembler* assembler,
                                           Label* normal_ir_body) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label is_false, is_true, is_zero;
    __ ldr(R0, Address(SP, 0 * target::kWordSize));
    __ LoadDFromOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);
    __ vcmpdz(D0);
    __ vmstat();
    __ b(&is_false, VS);  // NaN -> false.
    __ b(&is_zero, EQ);   // Check for negative zero.
    __ b(&is_false, CS);  // >= 0 -> false.

    __ Bind(&is_true);
    __ LoadObject(R0, CastHandle<Object>(TrueObject()));
    __ Ret();

    __ Bind(&is_false);
    __ LoadObject(R0, CastHandle<Object>(FalseObject()));
    __ Ret();

    __ Bind(&is_zero);
    // Check for negative zero by looking at the sign bit.
    __ vmovrrd(R0, R1, D0);  // R1:R0 <- D0, so sign bit is in bit 31 of R1.
    __ mov(R1, Operand(R1, LSR, 31));
    __ tst(R1, Operand(1));
    __ b(&is_true, NE);  // Sign bit set.
    __ b(&is_false);
  }
}

void AsmIntrinsifier::DoubleToInteger(Assembler* assembler,
                                      Label* normal_ir_body) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label fall_through;

    __ ldr(R0, Address(SP, 0 * target::kWordSize));
    __ LoadDFromOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);

    // Explicit NaN check, since ARM gives an FPU exception if you try to
    // convert NaN to an int.
    __ vcmpd(D0, D0);
    __ vmstat();
    __ b(normal_ir_body, VS);

    __ vcvtid(S0, D0);
    __ vmovrs(R0, S0);
    // Overflow is signaled with minint.
    // Check for overflow and that it fits into Smi.
    __ CompareImmediate(R0, 0xC0000000);
    __ SmiTag(R0, PL);
    READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, PL));
    __ Bind(normal_ir_body);
  }
}

void AsmIntrinsifier::Double_hashCode(Assembler* assembler,
                                      Label* normal_ir_body) {
  // TODO(dartbug.com/31174): Convert this to a graph intrinsic.

  if (!TargetCPUFeatures::vfp_supported()) return;

  // Load double value and check that it isn't NaN, since ARM gives an
  // FPU exception if you try to convert NaN to an int.
  Label double_hash;
  __ ldr(R1, Address(SP, 0 * target::kWordSize));
  __ LoadDFromOffset(D0, R1, target::Double::value_offset() - kHeapObjectTag);
  __ vcmpd(D0, D0);
  __ vmstat();
  __ b(&double_hash, VS);

  // Convert double value to signed 32-bit int in R0.
  __ vcvtid(S2, D0);
  __ vmovrs(R0, S2);

  // Tag the int as a Smi, making sure that it fits; this checks for
  // overflow in the conversion from double to int. Conversion
  // overflow is signalled by vcvt through clamping R0 to either
  // INT32_MAX or INT32_MIN (saturation).
  ASSERT(kSmiTag == 0 && kSmiTagShift == 1);
  __ adds(R0, R0, Operand(R0));
  __ b(normal_ir_body, VS);

  // Compare the two double values. If they are equal, we return the
  // Smi tagged result immediately as the hash code.
  __ vcvtdi(D1, S2);
  __ vcmpd(D0, D1);
  __ vmstat();
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, EQ));
  // Convert the double bits to a hash code that fits in a Smi.
  __ Bind(&double_hash);
  __ ldr(R0, FieldAddress(R1, target::Double::value_offset()));
  __ ldr(R1, FieldAddress(R1, target::Double::value_offset() + 4));
  __ eor(R0, R0, Operand(R1));
  __ AndImmediate(R0, R0, target::kSmiMax);
  __ SmiTag(R0);
  __ Ret();

  // Fall into the native C++ implementation.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::MathSqrt(Assembler* assembler, Label* normal_ir_body) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label is_smi, double_op;
    TestLastArgumentIsDouble(assembler, &is_smi, normal_ir_body);
    // Argument is double and is in R0.
    __ LoadDFromOffset(D1, R0, target::Double::value_offset() - kHeapObjectTag);
    __ Bind(&double_op);
    __ vsqrtd(D0, D1);
    const Class& double_class = DoubleClass();
    __ TryAllocate(double_class, normal_ir_body, R0,
                   R1);  // Result register.
    __ StoreDToOffset(D0, R0, target::Double::value_offset() - kHeapObjectTag);
    __ Ret();
    __ Bind(&is_smi);
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D1, S0);
    __ b(&double_op);
    __ Bind(normal_ir_body);
  }
}

//    var state = ((_A * (_state[kSTATE_LO])) + _state[kSTATE_HI]) & _MASK_64;
//    _state[kSTATE_LO] = state & _MASK_32;
//    _state[kSTATE_HI] = state >> 32;
void AsmIntrinsifier::Random_nextState(Assembler* assembler,
                                       Label* normal_ir_body) {
  const Field& state_field = LookupMathRandomStateFieldOffset();
  const int64_t a_int_value = AsmIntrinsifier::kRandomAValue;

  // 'a_int_value' is a mask.
  ASSERT(Utils::IsUint(32, a_int_value));
  int32_t a_int32_value = static_cast<int32_t>(a_int_value);

  // Receiver.
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  // Field '_state'.
  __ ldr(R1, FieldAddress(R0, target::Field::OffsetOf(state_field)));
  // Addresses of _state[0] and _state[1].

  const int64_t disp_0 =
      target::Instance::DataOffsetFor(kTypedDataUint32ArrayCid);
  const int64_t disp_1 =
      disp_0 + target::Instance::ElementSizeFor(kTypedDataUint32ArrayCid);

  __ LoadImmediate(R0, a_int32_value);
  __ LoadFieldFromOffset(R2, R1, disp_0);
  __ LoadFieldFromOffset(R3, R1, disp_1);
  __ mov(R8, Operand(0));  // Zero extend unsigned _state[kSTATE_HI].
  // Unsigned 32-bit multiply and 64-bit accumulate into R8:R3.
  __ umlal(R3, R8, R0, R2);  // R8:R3 <- R8:R3 + R0 * R2.
  __ StoreFieldToOffset(R3, R1, disp_0);
  __ StoreFieldToOffset(R8, R1, disp_1);
  ASSERT(target::ToRawSmi(0) == 0);
  __ eor(R0, R0, Operand(R0));
  __ Ret();
}

void AsmIntrinsifier::ObjectEquals(Assembler* assembler,
                                   Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ ldr(R1, Address(SP, 1 * target::kWordSize));
  __ cmp(R0, Operand(R1));
  __ LoadObject(R0, CastHandle<Object>(FalseObject()), NE);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()), EQ);
  __ Ret();
}

static void RangeCheck(Assembler* assembler,
                       Register val,
                       Register tmp,
                       intptr_t low,
                       intptr_t high,
                       Condition cc,
                       Label* target) {
  __ AddImmediate(tmp, val, -low);
  __ CompareImmediate(tmp, high - low);
  __ b(target, cc);
}

const Condition kIfNotInRange = HI;
const Condition kIfInRange = LS;

static void JumpIfInteger(Assembler* assembler,
                          Register cid,
                          Register tmp,
                          Label* target) {
  RangeCheck(assembler, cid, tmp, kSmiCid, kMintCid, kIfInRange, target);
}

static void JumpIfNotInteger(Assembler* assembler,
                             Register cid,
                             Register tmp,
                             Label* target) {
  RangeCheck(assembler, cid, tmp, kSmiCid, kMintCid, kIfNotInRange, target);
}

static void JumpIfString(Assembler* assembler,
                         Register cid,
                         Register tmp,
                         Label* target) {
  RangeCheck(assembler, cid, tmp, kOneByteStringCid, kExternalTwoByteStringCid,
             kIfInRange, target);
}

static void JumpIfNotString(Assembler* assembler,
                            Register cid,
                            Register tmp,
                            Label* target) {
  RangeCheck(assembler, cid, tmp, kOneByteStringCid, kExternalTwoByteStringCid,
             kIfNotInRange, target);
}

// Return type quickly for simple types (not parameterized and not signature).
void AsmIntrinsifier::ObjectRuntimeType(Assembler* assembler,
                                        Label* normal_ir_body) {
  Label use_declaration_type, not_double, not_integer;
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ LoadClassIdMayBeSmi(R1, R0);

  __ CompareImmediate(R1, kClosureCid);
  __ b(normal_ir_body, EQ);  // Instance is a closure.

  __ CompareImmediate(R1, kNumPredefinedCids);
  __ b(&use_declaration_type, HI);

  __ CompareImmediate(R1, kDoubleCid);
  __ b(&not_double, NE);

  __ LoadIsolate(R0);
  __ LoadFromOffset(R0, R0, target::Isolate::cached_object_store_offset());
  __ LoadFromOffset(R0, R0, target::ObjectStore::double_type_offset());
  __ Ret();

  __ Bind(&not_double);
  JumpIfNotInteger(assembler, R1, R0, &not_integer);
  __ LoadIsolate(R0);
  __ LoadFromOffset(R0, R0, target::Isolate::cached_object_store_offset());
  __ LoadFromOffset(R0, R0, target::ObjectStore::int_type_offset());
  __ Ret();

  __ Bind(&not_integer);
  JumpIfNotString(assembler, R1, R0, &use_declaration_type);
  __ LoadIsolate(R0);
  __ LoadFromOffset(R0, R0, target::Isolate::cached_object_store_offset());
  __ LoadFromOffset(R0, R0, target::ObjectStore::string_type_offset());
  __ Ret();

  __ Bind(&use_declaration_type);
  __ LoadClassById(R2, R1);
  __ ldrh(R3, FieldAddress(R2, target::Class::num_type_arguments_offset()));
  __ CompareImmediate(R3, 0);
  __ b(normal_ir_body, NE);

  __ ldr(R0, FieldAddress(R2, target::Class::declaration_type_offset()));
  __ CompareObject(R0, NullObject());
  __ b(normal_ir_body, EQ);
  __ Ret();

  __ Bind(normal_ir_body);
}

// Compares cid1 and cid2 to see if they're syntactically equivalent. If this
// can be determined by this fast path, it jumps to either equal or not_equal,
// otherwise it jumps to normal_ir_body. May clobber cid1, cid2, and scratch.
static void EquivalentClassIds(Assembler* assembler,
                               Label* normal_ir_body,
                               Label* equal,
                               Label* not_equal,
                               Register cid1,
                               Register cid2,
                               Register scratch) {
  Label different_cids, not_integer;

  // Check if left hand side is a closure. Closures are handled in the runtime.
  __ CompareImmediate(cid1, kClosureCid);
  __ b(normal_ir_body, EQ);

  // Check whether class ids match. If class ids don't match types may still be
  // considered equivalent (e.g. multiple string implementation classes map to a
  // single String type).
  __ cmp(cid1, Operand(cid2));
  __ b(&different_cids, NE);

  // Types have the same class and neither is a closure type.
  // Check if there are no type arguments. In this case we can return true.
  // Otherwise fall through into the runtime to handle comparison.
  __ LoadClassById(scratch, cid1);
  __ ldrh(scratch,
          FieldAddress(scratch, target::Class::num_type_arguments_offset()));
  __ CompareImmediate(scratch, 0);
  __ b(normal_ir_body, NE);
  __ b(equal);

  // Class ids are different. Check if we are comparing two string types (with
  // different representations) or two integer types.
  __ Bind(&different_cids);
  __ CompareImmediate(cid1, kNumPredefinedCids);
  __ b(not_equal, HI);

  // Check if both are integer types.
  JumpIfNotInteger(assembler, cid1, scratch, &not_integer);

  // First type is an integer. Check if the second is an integer too.
  // Otherwise types are unequiv because only integers have the same runtime
  // type as other integers.
  JumpIfInteger(assembler, cid2, scratch, equal);
  __ b(not_equal);

  __ Bind(&not_integer);
  // Check if the first type is String. If it is not then types are not
  // equivalent because they have different class ids and they are not strings
  // or integers.
  JumpIfNotString(assembler, cid1, scratch, not_equal);
  // First type is String. Check if the second is a string too.
  JumpIfString(assembler, cid2, scratch, equal);
  // String types are only equivalent to other String types.
  __ b(not_equal);
}

void AsmIntrinsifier::ObjectHaveSameRuntimeType(Assembler* assembler,
                                                Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ LoadClassIdMayBeSmi(R1, R0);

  __ ldr(R0, Address(SP, 1 * target::kWordSize));
  __ LoadClassIdMayBeSmi(R2, R0);

  Label equal, not_equal;
  EquivalentClassIds(assembler, normal_ir_body, &equal, &not_equal, R1, R2, R0);

  __ Bind(&equal);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ Ret();

  __ Bind(&not_equal);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ Ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::String_getHashCode(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ ldr(R0, FieldAddress(R0, target::String::hash_offset()));
  __ cmp(R0, Operand(0));
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, NE));  // Hash not yet computed.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Type_getHashCode(Assembler* assembler,
                                       Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ ldr(R0, FieldAddress(R0, target::Type::hash_offset()));
  __ cmp(R0, Operand(0));
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, NE));  // Hash not yet computed.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Type_equality(Assembler* assembler,
                                    Label* normal_ir_body) {
  Label equal, not_equal, equiv_cids, check_legacy;

  __ ldm(IA, SP, (1 << R1 | 1 << R2));
  __ cmp(R1, Operand(R2));
  __ b(&equal, EQ);

  // R1 might not be a Type object, so check that first (R2 should be though,
  // since this is a method on the Type class).
  __ LoadClassIdMayBeSmi(R0, R1);
  __ CompareImmediate(R0, kTypeCid);
  __ b(normal_ir_body, NE);

  // Check if types are syntactically equal.
  __ ldr(R3, FieldAddress(R1, target::Type::type_class_id_offset()));
  __ SmiUntag(R3);
  __ ldr(R4, FieldAddress(R2, target::Type::type_class_id_offset()));
  __ SmiUntag(R4);
  EquivalentClassIds(assembler, normal_ir_body, &equiv_cids, &not_equal, R3, R4,
                     R0);

  // Check nullability.
  __ Bind(&equiv_cids);
  __ ldrb(R1, FieldAddress(R1, target::Type::nullability_offset()));
  __ ldrb(R2, FieldAddress(R2, target::Type::nullability_offset()));
  __ cmp(R1, Operand(R2));
  __ b(&check_legacy, NE);
  // Fall through to equal case if nullability is strictly equal.

  __ Bind(&equal);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ Ret();

  // At this point the nullabilities are different, so they can only be
  // syntactically equivalent if they're both either kNonNullable or kLegacy.
  // These are the two largest values of the enum, so we can just do a < check.
  ASSERT(target::Nullability::kNullable < target::Nullability::kNonNullable &&
         target::Nullability::kNonNullable < target::Nullability::kLegacy);
  __ Bind(&check_legacy);
  __ CompareImmediate(R1, target::Nullability::kNonNullable);
  __ b(&not_equal, LT);
  __ CompareImmediate(R2, target::Nullability::kNonNullable);
  __ b(&equal, GE);

  __ Bind(&not_equal);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ Ret();

  __ Bind(normal_ir_body);
}

void GenerateSubstringMatchesSpecialization(Assembler* assembler,
                                            intptr_t receiver_cid,
                                            intptr_t other_cid,
                                            Label* return_true,
                                            Label* return_false) {
  __ SmiUntag(R1);
  __ ldr(R8, FieldAddress(R0, target::String::length_offset()));  // this.length
  __ SmiUntag(R8);
  __ ldr(R9,
         FieldAddress(R2, target::String::length_offset()));  // other.length
  __ SmiUntag(R9);

  // if (other.length == 0) return true;
  __ cmp(R9, Operand(0));
  __ b(return_true, EQ);

  // if (start < 0) return false;
  __ cmp(R1, Operand(0));
  __ b(return_false, LT);

  // if (start + other.length > this.length) return false;
  __ add(R3, R1, Operand(R9));
  __ cmp(R3, Operand(R8));
  __ b(return_false, GT);

  if (receiver_cid == kOneByteStringCid) {
    __ AddImmediate(R0, target::OneByteString::data_offset() - kHeapObjectTag);
    __ add(R0, R0, Operand(R1));
  } else {
    ASSERT(receiver_cid == kTwoByteStringCid);
    __ AddImmediate(R0, target::TwoByteString::data_offset() - kHeapObjectTag);
    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R1));
  }
  if (other_cid == kOneByteStringCid) {
    __ AddImmediate(R2, target::OneByteString::data_offset() - kHeapObjectTag);
  } else {
    ASSERT(other_cid == kTwoByteStringCid);
    __ AddImmediate(R2, target::TwoByteString::data_offset() - kHeapObjectTag);
  }

  // i = 0
  __ LoadImmediate(R3, 0);

  // do
  Label loop;
  __ Bind(&loop);

  if (receiver_cid == kOneByteStringCid) {
    __ ldrb(R4, Address(R0, 0));  // this.codeUnitAt(i + start)
  } else {
    __ ldrh(R4, Address(R0, 0));  // this.codeUnitAt(i + start)
  }
  if (other_cid == kOneByteStringCid) {
    __ ldrb(TMP, Address(R2, 0));  // other.codeUnitAt(i)
  } else {
    __ ldrh(TMP, Address(R2, 0));  // other.codeUnitAt(i)
  }
  __ cmp(R4, Operand(TMP));
  __ b(return_false, NE);

  // i++, while (i < len)
  __ AddImmediate(R3, 1);
  __ AddImmediate(R0, receiver_cid == kOneByteStringCid ? 1 : 2);
  __ AddImmediate(R2, other_cid == kOneByteStringCid ? 1 : 2);
  __ cmp(R3, Operand(R9));
  __ b(&loop, LT);

  __ b(return_true);
}

// bool _substringMatches(int start, String other)
// This intrinsic handles a OneByteString or TwoByteString receiver with a
// OneByteString other.
void AsmIntrinsifier::StringBaseSubstringMatches(Assembler* assembler,
                                                 Label* normal_ir_body) {
  Label return_true, return_false, try_two_byte;
  __ ldr(R0, Address(SP, 2 * target::kWordSize));  // this
  __ ldr(R1, Address(SP, 1 * target::kWordSize));  // start
  __ ldr(R2, Address(SP, 0 * target::kWordSize));  // other
  __ Push(R4);  // Make ARGS_DESC_REG available.

  __ tst(R1, Operand(kSmiTagMask));
  __ b(normal_ir_body, NE);  // 'start' is not a Smi.

  __ CompareClassId(R2, kOneByteStringCid, R3);
  __ b(normal_ir_body, NE);

  __ CompareClassId(R0, kOneByteStringCid, R3);
  __ b(&try_two_byte, NE);

  GenerateSubstringMatchesSpecialization(assembler, kOneByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&try_two_byte);
  __ CompareClassId(R0, kTwoByteStringCid, R3);
  __ b(normal_ir_body, NE);

  GenerateSubstringMatchesSpecialization(assembler, kTwoByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&return_true);
  __ Pop(R4);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ Ret();

  __ Bind(&return_false);
  __ Pop(R4);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ Ret();

  __ Bind(normal_ir_body);
  __ Pop(R4);
}

void AsmIntrinsifier::Object_getHash(Assembler* assembler,
                                     Label* normal_ir_body) {
  UNREACHABLE();
}

void AsmIntrinsifier::Object_setHash(Assembler* assembler,
                                     Label* normal_ir_body) {
  UNREACHABLE();
}

void AsmIntrinsifier::StringBaseCharAt(Assembler* assembler,
                                       Label* normal_ir_body) {
  Label try_two_byte_string;

  __ ldr(R1, Address(SP, 0 * target::kWordSize));  // Index.
  __ ldr(R0, Address(SP, 1 * target::kWordSize));  // String.
  __ tst(R1, Operand(kSmiTagMask));
  __ b(normal_ir_body, NE);  // Index is not a Smi.
  // Range check.
  __ ldr(R2, FieldAddress(R0, target::String::length_offset()));
  __ cmp(R1, Operand(R2));
  __ b(normal_ir_body, CS);  // Runtime throws exception.

  __ CompareClassId(R0, kOneByteStringCid, R3);
  __ b(&try_two_byte_string, NE);
  __ SmiUntag(R1);
  __ AddImmediate(R0, target::OneByteString::data_offset() - kHeapObjectTag);
  __ ldrb(R1, Address(R0, R1));
  __ CompareImmediate(R1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ b(normal_ir_body, GE);
  __ ldr(R0, Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ AddImmediate(
      R0, target::Symbols::kNullCharCodeSymbolOffset * target::kWordSize);
  __ ldr(R0, Address(R0, R1, LSL, 2));
  __ Ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(R0, kTwoByteStringCid, R3);
  __ b(normal_ir_body, NE);
  ASSERT(kSmiTagShift == 1);
  __ AddImmediate(R0, target::TwoByteString::data_offset() - kHeapObjectTag);
  __ ldrh(R1, Address(R0, R1));
  __ CompareImmediate(R1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ b(normal_ir_body, GE);
  __ ldr(R0, Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ AddImmediate(
      R0, target::Symbols::kNullCharCodeSymbolOffset * target::kWordSize);
  __ ldr(R0, Address(R0, R1, LSL, 2));
  __ Ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseIsEmpty(Assembler* assembler,
                                        Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ ldr(R0, FieldAddress(R0, target::String::length_offset()));
  __ cmp(R0, Operand(target::ToRawSmi(0)));
  __ LoadObject(R0, CastHandle<Object>(TrueObject()), EQ);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()), NE);
  __ Ret();
}

void AsmIntrinsifier::OneByteString_getHashCode(Assembler* assembler,
                                                Label* normal_ir_body) {
  __ ldr(R1, Address(SP, 0 * target::kWordSize));
  __ ldr(R0, FieldAddress(R1, target::String::hash_offset()));
  __ cmp(R0, Operand(0));
  READS_RETURN_ADDRESS_FROM_LR(__ bx(LR, NE));  // Return if already computed.

  __ ldr(R2, FieldAddress(R1, target::String::length_offset()));

  Label done;
  // If the string is empty, set the hash to 1, and return.
  __ cmp(R2, Operand(target::ToRawSmi(0)));
  __ b(&done, EQ);

  __ SmiUntag(R2);
  __ mov(R3, Operand(0));
  __ AddImmediate(R8, R1,
                  target::OneByteString::data_offset() - kHeapObjectTag);
  // R1: Instance of OneByteString.
  // R2: String length, untagged integer.
  // R3: Loop counter, untagged integer.
  // R8: String data.
  // R0: Hash code, untagged integer.

  Label loop;
  // Add to hash code: (hash_ is uint32)
  // hash_ += ch;
  // hash_ += hash_ << 10;
  // hash_ ^= hash_ >> 6;
  // Get one characters (ch).
  __ Bind(&loop);
  __ ldrb(TMP, Address(R8, 0));
  // TMP: ch.
  __ add(R3, R3, Operand(1));
  __ add(R8, R8, Operand(1));
  __ add(R0, R0, Operand(TMP));
  __ add(R0, R0, Operand(R0, LSL, 10));
  __ eor(R0, R0, Operand(R0, LSR, 6));
  __ cmp(R3, Operand(R2));
  __ b(&loop, NE);

  // Finalize.
  // hash_ += hash_ << 3;
  // hash_ ^= hash_ >> 11;
  // hash_ += hash_ << 15;
  __ add(R0, R0, Operand(R0, LSL, 3));
  __ eor(R0, R0, Operand(R0, LSR, 11));
  __ add(R0, R0, Operand(R0, LSL, 15));
  // hash_ = hash_ & ((static_cast<intptr_t>(1) << bits) - 1);
  __ LoadImmediate(R2,
                   (static_cast<intptr_t>(1) << target::String::kHashBits) - 1);
  __ and_(R0, R0, Operand(R2));
  __ cmp(R0, Operand(0));
  // return hash_ == 0 ? 1 : hash_;
  __ Bind(&done);
  __ mov(R0, Operand(1), EQ);
  __ SmiTag(R0);
  __ StoreIntoSmiField(FieldAddress(R1, target::String::hash_offset()), R0);
  __ Ret();
}

// Allocates a _OneByteString or _TwoByteString. The content is not initialized.
// 'length-reg' (R2) contains the desired length as a _Smi or _Mint.
// Returns new string as tagged pointer in R0.
static void TryAllocateString(Assembler* assembler,
                              classid_t cid,
                              Label* ok,
                              Label* failure) {
  ASSERT(cid == kOneByteStringCid || cid == kTwoByteStringCid);
  const Register length_reg = R2;
  // _Mint length: call to runtime to produce error.
  __ BranchIfNotSmi(length_reg, failure);
  // Negative length: call to runtime to produce error.
  __ cmp(length_reg, Operand(0));
  __ b(failure, LT);

  NOT_IN_PRODUCT(__ LoadAllocationStatsAddress(R0, cid));
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(R0, failure));
  __ mov(R8, Operand(length_reg));  // Save the length register.
  if (cid == kOneByteStringCid) {
    __ SmiUntag(length_reg);
  } else {
    // Untag length and multiply by element size -> no-op.
  }
  const intptr_t fixed_size_plus_alignment_padding =
      target::String::InstanceSize() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ AddImmediate(length_reg, fixed_size_plus_alignment_padding);
  __ bic(length_reg, length_reg,
         Operand(target::ObjectAlignment::kObjectAlignment - 1));

  __ ldr(R0, Address(THR, target::Thread::top_offset()));

  // length_reg: allocation size.
  __ adds(R1, R0, Operand(length_reg));
  __ b(failure, CS);  // Fail on unsigned overflow.

  // Check if the allocation fits into the remaining space.
  // R0: potential new object start.
  // R1: potential next object start.
  // R2: allocation size.
  __ ldr(TMP, Address(THR, target::Thread::end_offset()));
  __ cmp(R1, Operand(TMP));
  __ b(failure, CS);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ str(R1, Address(THR, target::Thread::top_offset()));
  __ AddImmediate(R0, kHeapObjectTag);

  // Initialize the tags.
  // R0: new object start as a tagged pointer.
  // R1: new object end address.
  // R2: allocation size.
  {
    const intptr_t shift = target::ObjectLayout::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2;

    __ CompareImmediate(R2, target::ObjectLayout::kSizeTagMaxSizeTag);
    __ mov(R3, Operand(R2, LSL, shift), LS);
    __ mov(R3, Operand(0), HI);

    // Get the class index and insert it into the tags.
    // R3: size and bit tags.
    const uword tags =
        target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
    __ LoadImmediate(TMP, tags);
    __ orr(R3, R3, Operand(TMP));
    __ str(R3, FieldAddress(R0, target::Object::tags_offset()));  // Store tags.
  }

  // Set the length field using the saved length (R8).
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, target::String::length_offset()), R8);
  // Clear hash.
  __ LoadImmediate(TMP, 0);
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, target::String::hash_offset()), TMP);

  __ b(ok);
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

  __ ldr(R2, Address(SP, kEndIndexOffset));
  __ ldr(TMP, Address(SP, kStartIndexOffset));
  __ orr(R3, R2, Operand(TMP));
  __ tst(R3, Operand(kSmiTagMask));
  __ b(normal_ir_body, NE);  // 'start', 'end' not Smi.

  __ sub(R2, R2, Operand(TMP));
  TryAllocateString(assembler, kOneByteStringCid, &ok, normal_ir_body);
  __ Bind(&ok);
  // R0: new string as tagged pointer.
  // Copy string.
  __ ldr(R3, Address(SP, kStringOffset));
  __ ldr(R1, Address(SP, kStartIndexOffset));
  __ SmiUntag(R1);
  __ add(R3, R3, Operand(R1));
  // Calculate start address and untag (- 1).
  __ AddImmediate(R3, target::OneByteString::data_offset() - 1);

  // R3: Start address to copy from (untagged).
  // R1: Untagged start index.
  __ ldr(R2, Address(SP, kEndIndexOffset));
  __ SmiUntag(R2);
  __ sub(R2, R2, Operand(R1));

  // R3: Start address to copy from (untagged).
  // R2: Untagged number of bytes to copy.
  // R0: Tagged result string.
  // R8: Pointer into R3.
  // R1: Pointer into R0.
  // TMP: Scratch register.
  Label loop, done;
  __ cmp(R2, Operand(0));
  __ b(&done, LE);
  __ mov(R8, Operand(R3));
  __ mov(R1, Operand(R0));
  __ Bind(&loop);
  __ ldrb(TMP, Address(R8, 1, Address::PostIndex));
  __ sub(R2, R2, Operand(1));
  __ cmp(R2, Operand(0));
  __ strb(TMP, FieldAddress(R1, target::OneByteString::data_offset()));
  __ add(R1, R1, Operand(1));
  __ b(&loop, GT);

  __ Bind(&done);
  __ Ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::WriteIntoOneByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ ldr(R2, Address(SP, 0 * target::kWordSize));  // Value.
  __ ldr(R1, Address(SP, 1 * target::kWordSize));  // Index.
  __ ldr(R0, Address(SP, 2 * target::kWordSize));  // OneByteString.
  __ SmiUntag(R1);
  __ SmiUntag(R2);
  __ AddImmediate(R3, R0,
                  target::OneByteString::data_offset() - kHeapObjectTag);
  __ strb(R2, Address(R3, R1));
  __ Ret();
}

void AsmIntrinsifier::WriteIntoTwoByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ ldr(R2, Address(SP, 0 * target::kWordSize));  // Value.
  __ ldr(R1, Address(SP, 1 * target::kWordSize));  // Index.
  __ ldr(R0, Address(SP, 2 * target::kWordSize));  // TwoByteString.
  // Untag index and multiply by element size -> no-op.
  __ SmiUntag(R2);
  __ AddImmediate(R3, R0,
                  target::TwoByteString::data_offset() - kHeapObjectTag);
  __ strh(R2, Address(R3, R1));
  __ Ret();
}

void AsmIntrinsifier::AllocateOneByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ ldr(R2, Address(SP, 0 * target::kWordSize));  // Length.
  Label ok;
  TryAllocateString(assembler, kOneByteStringCid, &ok, normal_ir_body);

  __ Bind(&ok);
  __ Ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AllocateTwoByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ ldr(R2, Address(SP, 0 * target::kWordSize));  // Length.
  Label ok;
  TryAllocateString(assembler, kTwoByteStringCid, &ok, normal_ir_body);

  __ Bind(&ok);
  __ Ret();

  __ Bind(normal_ir_body);
}

// TODO(srdjan): Add combinations (one-byte/two-byte/external strings).
static void StringEquality(Assembler* assembler,
                           Label* normal_ir_body,
                           intptr_t string_cid) {
  Label is_true, is_false, loop;
  __ ldr(R0, Address(SP, 1 * target::kWordSize));  // This.
  __ ldr(R1, Address(SP, 0 * target::kWordSize));  // Other.

  // Are identical?
  __ cmp(R0, Operand(R1));
  __ b(&is_true, EQ);

  // Is other OneByteString?
  __ tst(R1, Operand(kSmiTagMask));
  __ b(normal_ir_body, EQ);
  __ CompareClassId(R1, string_cid, R2);
  __ b(normal_ir_body, NE);

  // Have same length?
  __ ldr(R2, FieldAddress(R0, target::String::length_offset()));
  __ ldr(R3, FieldAddress(R1, target::String::length_offset()));
  __ cmp(R2, Operand(R3));
  __ b(&is_false, NE);

  // Check contents, no fall-through possible.
  // TODO(zra): try out other sequences.
  ASSERT((string_cid == kOneByteStringCid) ||
         (string_cid == kTwoByteStringCid));
  const intptr_t offset = (string_cid == kOneByteStringCid)
                              ? target::OneByteString::data_offset()
                              : target::TwoByteString::data_offset();
  __ AddImmediate(R0, offset - kHeapObjectTag);
  __ AddImmediate(R1, offset - kHeapObjectTag);
  __ SmiUntag(R2);
  __ Bind(&loop);
  __ AddImmediate(R2, -1);
  __ cmp(R2, Operand(0));
  __ b(&is_true, LT);
  if (string_cid == kOneByteStringCid) {
    __ ldrb(R3, Address(R0));
    __ ldrb(R4, Address(R1));
    __ AddImmediate(R0, 1);
    __ AddImmediate(R1, 1);
  } else if (string_cid == kTwoByteStringCid) {
    __ ldrh(R3, Address(R0));
    __ ldrh(R4, Address(R1));
    __ AddImmediate(R0, 2);
    __ AddImmediate(R1, 2);
  } else {
    UNIMPLEMENTED();
  }
  __ cmp(R3, Operand(R4));
  __ b(&is_false, NE);
  __ b(&loop);

  __ Bind(&is_true);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ Ret();

  __ Bind(&is_false);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ Ret();

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
  // R0: Function. (Will be reloaded with the specialized matcher function.)
  // R4: Arguments descriptor. (Will be preserved.)
  // R9: Unknown. (Must be GC safe on tail call.)

  // Load the specialized function pointer into R0. Leverage the fact the
  // string CIDs as well as stored function pointers are in sequence.
  __ ldr(R2, Address(SP, kRegExpParamOffset));
  __ ldr(R1, Address(SP, kStringParamOffset));
  __ LoadClassId(R1, R1);
  __ AddImmediate(R1, -kOneByteStringCid);
  __ add(R1, R2, Operand(R1, LSL, target::kWordSizeLog2));
  __ ldr(R0, FieldAddress(R1, target::RegExp::function_offset(kOneByteStringCid,
                                                              sticky)));

  // Registers are now set up for the lazy compile stub. It expects the function
  // in R0, the argument descriptor in R4, and IC-Data in R9.
  __ eor(R9, R9, Operand(R9));

  // Tail-call the function.
  __ ldr(CODE_REG, FieldAddress(R0, target::Function::code_offset()));
  __ Branch(FieldAddress(R0, target::Function::entry_point_offset()));
}

// On stack: user tag (+0).
void AsmIntrinsifier::UserTag_makeCurrent(Assembler* assembler,
                                          Label* normal_ir_body) {
  // R1: Isolate.
  __ LoadIsolate(R1);
  // R0: Current user tag.
  __ ldr(R0, Address(R1, target::Isolate::current_tag_offset()));
  // R2: UserTag.
  __ ldr(R2, Address(SP, +0 * target::kWordSize));
  // Set target::Isolate::current_tag_.
  __ str(R2, Address(R1, target::Isolate::current_tag_offset()));
  // R2: UserTag's tag.
  __ ldr(R2, FieldAddress(R2, target::UserTag::tag_offset()));
  // Set target::Isolate::user_tag_.
  __ str(R2, Address(R1, target::Isolate::user_tag_offset()));
  __ Ret();
}

void AsmIntrinsifier::UserTag_defaultTag(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ LoadIsolate(R0);
  __ ldr(R0, Address(R0, target::Isolate::default_tag_offset()));
  __ Ret();
}

void AsmIntrinsifier::Profiler_getCurrentTag(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ LoadIsolate(R0);
  __ ldr(R0, Address(R0, target::Isolate::current_tag_offset()));
  __ Ret();
}

void AsmIntrinsifier::Timeline_isDartStreamEnabled(Assembler* assembler,
                                                   Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ Ret();
#else
  // Load TimelineStream*.
  __ ldr(R0, Address(THR, target::Thread::dart_stream_offset()));
  // Load uintptr_t from TimelineStream*.
  __ ldr(R0, Address(R0, target::TimelineStream::enabled_offset()));
  __ cmp(R0, Operand(0));
  __ LoadObject(R0, CastHandle<Object>(TrueObject()), NE);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()), EQ);
  __ Ret();
#endif
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM)
