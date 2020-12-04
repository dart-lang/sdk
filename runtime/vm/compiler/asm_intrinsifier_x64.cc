// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/asm_intrinsifier.h"
#include "vm/compiler/assembler/assembler.h"

namespace dart {
namespace compiler {

// When entering intrinsics code:
// R10: Arguments descriptor
// TOS: Return address
// The R10 registers can be destroyed only if there is no slow-path, i.e.
// if the intrinsified method always executes a return.
// The RBP register should not be modified, because it is used by the profiler.
// The PP and THR registers (see constants_x64.h) must be preserved.

#define __ assembler->

intptr_t AsmIntrinsifier::ParameterSlotFromSp() {
  return 0;
}

void AsmIntrinsifier::IntrinsicCallPrologue(Assembler* assembler) {
  COMPILE_ASSERT(IsAbiPreservedRegister(CODE_REG));
  COMPILE_ASSERT(!IsAbiPreservedRegister(ARGS_DESC_REG));
  COMPILE_ASSERT(IsAbiPreservedRegister(CALLEE_SAVED_TEMP));
  COMPILE_ASSERT(CALLEE_SAVED_TEMP != CODE_REG);
  COMPILE_ASSERT(CALLEE_SAVED_TEMP != ARGS_DESC_REG);

  assembler->Comment("IntrinsicCallPrologue");
  assembler->movq(CALLEE_SAVED_TEMP, ARGS_DESC_REG);
}

void AsmIntrinsifier::IntrinsicCallEpilogue(Assembler* assembler) {
  assembler->Comment("IntrinsicCallEpilogue");
  assembler->movq(ARGS_DESC_REG, CALLEE_SAVED_TEMP);
}

// Allocate a GrowableObjectArray using the backing array specified.
// On stack: type argument (+2), data (+1), return-address (+0).
void AsmIntrinsifier::GrowableArray_Allocate(Assembler* assembler,
                                             Label* normal_ir_body) {
  // This snippet of inlined code uses the following registers:
  // RAX, RCX, R13
  // and the newly allocated object is returned in RAX.
  const intptr_t kTypeArgumentsOffset = 2 * target::kWordSize;
  const intptr_t kArrayOffset = 1 * target::kWordSize;

  // Try allocating in new space.
  const Class& cls = GrowableObjectArrayClass();
  __ TryAllocate(cls, normal_ir_body, Assembler::kFarJump, RAX, R13);

  // Store backing array object in growable array object.
  __ movq(RCX, Address(RSP, kArrayOffset));  // data argument.
  // RAX is new, no barrier needed.
  __ StoreIntoObjectNoBarrier(
      RAX, FieldAddress(RAX, target::GrowableObjectArray::data_offset()), RCX);

  // RAX: new growable array object start as a tagged pointer.
  // Store the type argument field in the growable array object.
  __ movq(RCX, Address(RSP, kTypeArgumentsOffset));  // type argument.
  __ StoreIntoObjectNoBarrier(
      RAX,
      FieldAddress(RAX, target::GrowableObjectArray::type_arguments_offset()),
      RCX);

  // Set the length field in the growable array object to 0.
  __ ZeroInitSmiField(
      FieldAddress(RAX, target::GrowableObjectArray::length_offset()));
  __ ret();  // returns the newly allocated object in RAX.

  __ Bind(normal_ir_body);
}

// Tests if two top most arguments are smis, jumps to label not_smi if not.
// Topmost argument is in RAX.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ movq(RCX, Address(RSP, +2 * target::kWordSize));
  __ orq(RCX, RAX);
  __ testq(RCX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, not_smi);
}

void AsmIntrinsifier::Integer_addFromInteger(Assembler* assembler,
                                             Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX contains right argument.
  __ addq(RAX, Address(RSP, +2 * target::kWordSize));
  __ j(OVERFLOW, normal_ir_body, Assembler::kNearJump);
  // Result is in RAX.
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_add(Assembler* assembler, Label* normal_ir_body) {
  Integer_addFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_subFromInteger(Assembler* assembler,
                                             Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX contains right argument, which is the actual minuend of subtraction.
  __ subq(RAX, Address(RSP, +2 * target::kWordSize));
  __ j(OVERFLOW, normal_ir_body, Assembler::kNearJump);
  // Result is in RAX.
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_sub(Assembler* assembler, Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX contains right argument, which is the actual subtrahend of subtraction.
  __ movq(RCX, RAX);
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));
  __ subq(RAX, RCX);
  __ j(OVERFLOW, normal_ir_body, Assembler::kNearJump);
  // Result is in RAX.
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_mulFromInteger(Assembler* assembler,
                                             Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX is the right argument.
  ASSERT(kSmiTag == 0);  // Adjust code below if not the case.
  __ SmiUntag(RAX);
  __ imulq(RAX, Address(RSP, +2 * target::kWordSize));
  __ j(OVERFLOW, normal_ir_body, Assembler::kNearJump);
  // Result is in RAX.
  __ ret();
  __ Bind(normal_ir_body);
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
// RAX: Tagged left (dividend).
// RCX: Tagged right (divisor).
// Returns:
//   RAX: Untagged fallthrough result (remainder to be adjusted), or
//   RAX: Tagged return result (remainder).
static void EmitRemainderOperation(Assembler* assembler) {
  Label return_zero, try_modulo, not_32bit, done;
  // Check for quick zero results.
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &return_zero, Assembler::kNearJump);
  __ cmpq(RAX, RCX);
  __ j(EQUAL, &return_zero, Assembler::kNearJump);

  // Check if result equals left.
  __ cmpq(RAX, Immediate(0));
  __ j(LESS, &try_modulo, Assembler::kNearJump);
  // left is positive.
  __ cmpq(RAX, RCX);
  __ j(GREATER, &try_modulo, Assembler::kNearJump);
  // left is less than right, result is left (RAX).
  __ ret();

  __ Bind(&return_zero);
  __ xorq(RAX, RAX);
  __ ret();

  __ Bind(&try_modulo);

  // Check if both operands fit into 32bits as idiv with 64bit operands
  // requires twice as many cycles and has much higher latency. We are checking
  // this before untagging them to avoid corner case dividing INT_MAX by -1 that
  // raises exception because quotient is too large for 32bit register.
  __ movsxd(RBX, RAX);
  __ cmpq(RBX, RAX);
  __ j(NOT_EQUAL, &not_32bit, Assembler::kNearJump);
  __ movsxd(RBX, RCX);
  __ cmpq(RBX, RCX);
  __ j(NOT_EQUAL, &not_32bit, Assembler::kNearJump);

  // Both operands are 31bit smis. Divide using 32bit idiv.
  __ SmiUntag(RAX);
  __ SmiUntag(RCX);
  __ cdq();
  __ idivl(RCX);
  __ movsxd(RAX, RDX);
  __ jmp(&done, Assembler::kNearJump);

  // Divide using 64bit idiv.
  __ Bind(&not_32bit);
  __ SmiUntag(RAX);
  __ SmiUntag(RCX);
  __ cqo();
  __ idivq(RCX);
  __ movq(RAX, RDX);
  __ Bind(&done);
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
  Label negative_result;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  __ movq(RCX, Address(RSP, +2 * target::kWordSize));
  // RAX: Tagged left (dividend).
  // RCX: Tagged right (divisor).
  __ cmpq(RCX, Immediate(0));
  __ j(EQUAL, normal_ir_body);
  EmitRemainderOperation(assembler);
  // Untagged remainder result in RAX.
  __ cmpq(RAX, Immediate(0));
  __ j(LESS, &negative_result, Assembler::kNearJump);
  __ SmiTag(RAX);
  __ ret();

  __ Bind(&negative_result);
  Label subtract;
  // RAX: Untagged result.
  // RCX: Untagged right.
  __ cmpq(RCX, Immediate(0));
  __ j(LESS, &subtract, Assembler::kNearJump);
  __ addq(RAX, RCX);
  __ SmiTag(RAX);
  __ ret();

  __ Bind(&subtract);
  __ subq(RAX, RCX);
  __ SmiTag(RAX);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_truncDivide(Assembler* assembler,
                                          Label* normal_ir_body) {
  Label not_32bit;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX: right argument (divisor)
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, normal_ir_body, Assembler::kNearJump);
  __ movq(RCX, RAX);
  __ movq(RAX,
          Address(RSP, +2 * target::kWordSize));  // Left argument (dividend).

  // Check if both operands fit into 32bits as idiv with 64bit operands
  // requires twice as many cycles and has much higher latency. We are checking
  // this before untagging them to avoid corner case dividing INT_MAX by -1 that
  // raises exception because quotient is too large for 32bit register.
  __ movsxd(RBX, RAX);
  __ cmpq(RBX, RAX);
  __ j(NOT_EQUAL, &not_32bit);
  __ movsxd(RBX, RCX);
  __ cmpq(RBX, RCX);
  __ j(NOT_EQUAL, &not_32bit);

  // Both operands are 31bit smis. Divide using 32bit idiv.
  __ SmiUntag(RAX);
  __ SmiUntag(RCX);
  __ cdq();
  __ idivl(RCX);
  __ movsxd(RAX, RAX);
  __ SmiTag(RAX);  // Result is guaranteed to fit into a smi.
  __ ret();

  // Divide using 64bit idiv.
  __ Bind(&not_32bit);
  __ SmiUntag(RAX);
  __ SmiUntag(RCX);
  __ pushq(RDX);  // Preserve RDX in case of 'fall_through'.
  __ cqo();
  __ idivq(RCX);
  __ popq(RDX);
  // Check the corner case of dividing the 'MIN_SMI' with -1, in which case we
  // cannot tag the result.
  __ cmpq(RAX, Immediate(0x4000000000000000));
  __ j(EQUAL, normal_ir_body);
  __ SmiTag(RAX);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_negate(Assembler* assembler,
                                     Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ testq(RAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body, Assembler::kNearJump);  // Non-smi value.
  __ negq(RAX);
  __ j(OVERFLOW, normal_ir_body, Assembler::kNearJump);
  // Result is in RAX.
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_bitAndFromInteger(Assembler* assembler,
                                                Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX is the right argument.
  __ andq(RAX, Address(RSP, +2 * target::kWordSize));
  // Result is in RAX.
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_bitAnd(Assembler* assembler,
                                     Label* normal_ir_body) {
  Integer_bitAndFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_bitOrFromInteger(Assembler* assembler,
                                               Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX is the right argument.
  __ orq(RAX, Address(RSP, +2 * target::kWordSize));
  // Result is in RAX.
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_bitOr(Assembler* assembler,
                                    Label* normal_ir_body) {
  Integer_bitOrFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_bitXorFromInteger(Assembler* assembler,
                                                Label* normal_ir_body) {
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX is the right argument.
  __ xorq(RAX, Address(RSP, +2 * target::kWordSize));
  // Result is in RAX.
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_bitXor(Assembler* assembler,
                                     Label* normal_ir_body) {
  Integer_bitXorFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_shl(Assembler* assembler, Label* normal_ir_body) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(kSmiTag == 0);
  Label overflow;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // Shift value is in RAX. Compare with tagged Smi.
  __ cmpq(RAX, Immediate(target::ToRawSmi(target::kSmiBits)));
  __ j(ABOVE_EQUAL, normal_ir_body, Assembler::kNearJump);

  __ SmiUntag(RAX);
  __ movq(RCX, RAX);  // Shift amount must be in RCX.
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // Value.

  // Overflow test - all the shifted-out bits must be same as the sign bit.
  __ movq(RDI, RAX);
  __ shlq(RAX, RCX);
  __ sarq(RAX, RCX);
  __ cmpq(RAX, RDI);
  __ j(NOT_EQUAL, &overflow, Assembler::kNearJump);

  __ shlq(RAX, RCX);  // Shift for result now we know there is no overflow.

  // RAX is a correctly tagged Smi.
  __ ret();

  __ Bind(&overflow);
  // Mint is rarely used on x64 (only for integers requiring 64 bit instead of
  // 63 bits as represented by Smi).
  __ Bind(normal_ir_body);
}

static void CompareIntegers(Assembler* assembler,
                            Label* normal_ir_body,
                            Condition true_condition) {
  Label true_label;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX contains the right argument.
  __ cmpq(Address(RSP, +2 * target::kWordSize), RAX);
  __ j(true_condition, &true_label, Assembler::kNearJump);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_lessThan(Assembler* assembler,
                                       Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, LESS);
}

void AsmIntrinsifier::Integer_greaterThanFromInt(Assembler* assembler,
                                                 Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, LESS);
}

void AsmIntrinsifier::Integer_greaterThan(Assembler* assembler,
                                          Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, GREATER);
}

void AsmIntrinsifier::Integer_lessEqualThan(Assembler* assembler,
                                            Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, LESS_EQUAL);
}

void AsmIntrinsifier::Integer_greaterEqualThan(Assembler* assembler,
                                               Label* normal_ir_body) {
  CompareIntegers(assembler, normal_ir_body, GREATER_EQUAL);
}

// This is called for Smi and Mint receivers. The right argument
// can be Smi, Mint or double.
void AsmIntrinsifier::Integer_equalToInteger(Assembler* assembler,
                                             Label* normal_ir_body) {
  Label true_label, check_for_mint;
  const intptr_t kReceiverOffset = 2;
  const intptr_t kArgumentOffset = 1;

  // For integer receiver '===' check first.
  __ movq(RAX, Address(RSP, +kArgumentOffset * target::kWordSize));
  __ movq(RCX, Address(RSP, +kReceiverOffset * target::kWordSize));
  __ cmpq(RAX, RCX);
  __ j(EQUAL, &true_label, Assembler::kNearJump);
  __ orq(RAX, RCX);
  __ testq(RAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &check_for_mint, Assembler::kNearJump);
  // Both arguments are smi, '===' is good enough.
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);
  __ movq(RAX, Address(RSP, +kReceiverOffset * target::kWordSize));
  __ testq(RAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &receiver_not_smi);

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint never contains a value that can be
  // represented by Smi.
  __ movq(RAX, Address(RSP, +kArgumentOffset * target::kWordSize));
  __ CompareClassId(RAX, kDoubleCid);
  __ j(EQUAL, normal_ir_body);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(&receiver_not_smi);
  // RAX:: receiver.
  __ CompareClassId(RAX, kMintCid);
  __ j(NOT_EQUAL, normal_ir_body);
  // Receiver is Mint, return false if right is Smi.
  __ movq(RAX, Address(RSP, +kArgumentOffset * target::kWordSize));
  __ testq(RAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body);
  // Smi == Mint -> false.
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  // TODO(srdjan): Implement Mint == Mint comparison.

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_equal(Assembler* assembler,
                                    Label* normal_ir_body) {
  Integer_equalToInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Integer_sar(Assembler* assembler, Label* normal_ir_body) {
  Label shift_count_ok;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  const Immediate& count_limit = Immediate(0x3F);
  // Check that the count is not larger than what the hardware can handle.
  // For shifting right a Smi the result is the same for all numbers
  // >= count_limit.
  __ SmiUntag(RAX);
  // Negative counts throw exception.
  __ cmpq(RAX, Immediate(0));
  __ j(LESS, normal_ir_body, Assembler::kNearJump);
  __ cmpq(RAX, count_limit);
  __ j(LESS_EQUAL, &shift_count_ok, Assembler::kNearJump);
  __ movq(RAX, count_limit);
  __ Bind(&shift_count_ok);
  __ movq(RCX, RAX);  // Shift amount must be in RCX.
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // Value.
  __ SmiUntag(RAX);                                    // Value.
  __ sarq(RAX, RCX);
  __ SmiTag(RAX);
  __ ret();
  __ Bind(normal_ir_body);
}

// Argument is Smi (receiver).
void AsmIntrinsifier::Smi_bitNegate(Assembler* assembler,
                                    Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));  // Index.
  __ notq(RAX);
  __ andq(RAX, Immediate(~kSmiTagMask));  // Remove inverted smi-tag.
  __ ret();
}

void AsmIntrinsifier::Smi_bitLength(Assembler* assembler,
                                    Label* normal_ir_body) {
  ASSERT(kSmiTagShift == 1);
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));  // Index.
  // XOR with sign bit to complement bits if value is negative.
  __ movq(RCX, RAX);
  __ sarq(RCX, Immediate(63));  // All 0 or all 1.
  __ xorq(RAX, RCX);
  // BSR does not write the destination register if source is zero.  Put a 1 in
  // the Smi tag bit to ensure BSR writes to destination register.
  __ orq(RAX, Immediate(kSmiTagMask));
  __ bsrq(RAX, RAX);
  __ SmiTag(RAX);
  __ ret();
}

void AsmIntrinsifier::Smi_bitAndFromSmi(Assembler* assembler,
                                        Label* normal_ir_body) {
  Integer_bitAndFromInteger(assembler, normal_ir_body);
}

void AsmIntrinsifier::Bigint_lsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  __ movq(RDI, Address(RSP, 4 * target::kWordSize));  // x_digits
  __ movq(R8, Address(RSP, 3 * target::kWordSize));   // x_used is Smi
  __ subq(R8, Immediate(2));  // x_used > 0, Smi. R8 = x_used - 1, round up.
  __ sarq(R8, Immediate(2));  // R8 + 1 = number of digit pairs to read.
  __ movq(RCX, Address(RSP, 2 * target::kWordSize));  // n is Smi
  __ SmiUntag(RCX);
  __ movq(RBX, Address(RSP, 1 * target::kWordSize));  // r_digits
  __ movq(RSI, RCX);
  __ sarq(RSI, Immediate(6));  // RSI = n ~/ (2*_DIGIT_BITS).
  __ leaq(RBX,
          FieldAddress(RBX, RSI, TIMES_8, target::TypedData::data_offset()));
  __ xorq(RAX, RAX);  // RAX = 0.
  __ movq(RDX,
          FieldAddress(RDI, R8, TIMES_8, target::TypedData::data_offset()));
  __ shldq(RAX, RDX, RCX);
  __ movq(Address(RBX, R8, TIMES_8, 2 * kBytesPerBigIntDigit), RAX);
  Label last;
  __ cmpq(R8, Immediate(0));
  __ j(EQUAL, &last, Assembler::kNearJump);
  Label loop;
  __ Bind(&loop);
  __ movq(RAX, RDX);
  __ movq(RDX, FieldAddress(RDI, R8, TIMES_8,
                            target::TypedData::data_offset() -
                                2 * kBytesPerBigIntDigit));
  __ shldq(RAX, RDX, RCX);
  __ movq(Address(RBX, R8, TIMES_8, 0), RAX);
  __ decq(R8);
  __ j(NOT_ZERO, &loop, Assembler::kNearJump);
  __ Bind(&last);
  __ shldq(RDX, R8, RCX);  // R8 == 0.
  __ movq(Address(RBX, 0), RDX);
  __ LoadObject(RAX, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_rsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _rsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  __ movq(RDI, Address(RSP, 4 * target::kWordSize));  // x_digits
  __ movq(RCX, Address(RSP, 2 * target::kWordSize));  // n is Smi
  __ SmiUntag(RCX);
  __ movq(RBX, Address(RSP, 1 * target::kWordSize));  // r_digits
  __ movq(RDX, RCX);
  __ sarq(RDX, Immediate(6));  // RDX = n ~/ (2*_DIGIT_BITS).
  __ movq(RSI, Address(RSP, 3 * target::kWordSize));  // x_used is Smi
  __ subq(RSI, Immediate(2));  // x_used > 0, Smi. RSI = x_used - 1, round up.
  __ sarq(RSI, Immediate(2));
  __ leaq(RDI,
          FieldAddress(RDI, RSI, TIMES_8, target::TypedData::data_offset()));
  __ subq(RSI, RDX);  // RSI + 1 = number of digit pairs to read.
  __ leaq(RBX,
          FieldAddress(RBX, RSI, TIMES_8, target::TypedData::data_offset()));
  __ negq(RSI);
  __ movq(RDX, Address(RDI, RSI, TIMES_8, 0));
  Label last;
  __ cmpq(RSI, Immediate(0));
  __ j(EQUAL, &last, Assembler::kNearJump);
  Label loop;
  __ Bind(&loop);
  __ movq(RAX, RDX);
  __ movq(RDX, Address(RDI, RSI, TIMES_8, 2 * kBytesPerBigIntDigit));
  __ shrdq(RAX, RDX, RCX);
  __ movq(Address(RBX, RSI, TIMES_8, 0), RAX);
  __ incq(RSI);
  __ j(NOT_ZERO, &loop, Assembler::kNearJump);
  __ Bind(&last);
  __ shrdq(RDX, RSI, RCX);  // RSI == 0.
  __ movq(Address(RBX, 0), RDX);
  __ LoadObject(RAX, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_absAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absAdd(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  __ movq(RDI, Address(RSP, 5 * target::kWordSize));  // digits
  __ movq(R8, Address(RSP, 4 * target::kWordSize));   // used is Smi
  __ addq(R8, Immediate(2));  // used > 0, Smi. R8 = used + 1, round up.
  __ sarq(R8, Immediate(2));  // R8 = number of digit pairs to process.
  __ movq(RSI, Address(RSP, 3 * target::kWordSize));  // a_digits
  __ movq(RCX, Address(RSP, 2 * target::kWordSize));  // a_used is Smi
  __ addq(RCX, Immediate(2));  // a_used > 0, Smi. R8 = a_used + 1, round up.
  __ sarq(RCX, Immediate(2));  // R8 = number of digit pairs to process.
  __ movq(RBX, Address(RSP, 1 * target::kWordSize));  // r_digits

  // Precompute 'used - a_used' now so that carry flag is not lost later.
  __ subq(R8, RCX);
  __ incq(R8);  // To account for the extra test between loops.

  __ xorq(RDX, RDX);  // RDX = 0, carry flag = 0.
  Label add_loop;
  __ Bind(&add_loop);
  // Loop (a_used+1)/2 times, RCX > 0.
  __ movq(RAX,
          FieldAddress(RDI, RDX, TIMES_8, target::TypedData::data_offset()));
  __ adcq(RAX,
          FieldAddress(RSI, RDX, TIMES_8, target::TypedData::data_offset()));
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::data_offset()),
          RAX);
  __ incq(RDX);  // Does not affect carry flag.
  __ decq(RCX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &add_loop, Assembler::kNearJump);

  Label last_carry;
  __ decq(R8);                                    // Does not affect carry flag.
  __ j(ZERO, &last_carry, Assembler::kNearJump);  // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop (used+1)/2 - (a_used+1)/2 times, R8 > 0.
  __ movq(RAX,
          FieldAddress(RDI, RDX, TIMES_8, target::TypedData::data_offset()));
  __ adcq(RAX, Immediate(0));
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::data_offset()),
          RAX);
  __ incq(RDX);  // Does not affect carry flag.
  __ decq(R8);   // Does not affect carry flag.
  __ j(NOT_ZERO, &carry_loop, Assembler::kNearJump);

  __ Bind(&last_carry);
  Label done;
  __ j(NOT_CARRY, &done);
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::data_offset()),
          Immediate(1));

  __ Bind(&done);
  __ LoadObject(RAX, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_absSub(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absSub(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  __ movq(RDI, Address(RSP, 5 * target::kWordSize));  // digits
  __ movq(R8, Address(RSP, 4 * target::kWordSize));   // used is Smi
  __ addq(R8, Immediate(2));  // used > 0, Smi. R8 = used + 1, round up.
  __ sarq(R8, Immediate(2));  // R8 = number of digit pairs to process.
  __ movq(RSI, Address(RSP, 3 * target::kWordSize));  // a_digits
  __ movq(RCX, Address(RSP, 2 * target::kWordSize));  // a_used is Smi
  __ addq(RCX, Immediate(2));  // a_used > 0, Smi. R8 = a_used + 1, round up.
  __ sarq(RCX, Immediate(2));  // R8 = number of digit pairs to process.
  __ movq(RBX, Address(RSP, 1 * target::kWordSize));  // r_digits

  // Precompute 'used - a_used' now so that carry flag is not lost later.
  __ subq(R8, RCX);
  __ incq(R8);  // To account for the extra test between loops.

  __ xorq(RDX, RDX);  // RDX = 0, carry flag = 0.
  Label sub_loop;
  __ Bind(&sub_loop);
  // Loop (a_used+1)/2 times, RCX > 0.
  __ movq(RAX,
          FieldAddress(RDI, RDX, TIMES_8, target::TypedData::data_offset()));
  __ sbbq(RAX,
          FieldAddress(RSI, RDX, TIMES_8, target::TypedData::data_offset()));
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::data_offset()),
          RAX);
  __ incq(RDX);  // Does not affect carry flag.
  __ decq(RCX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &sub_loop, Assembler::kNearJump);

  Label done;
  __ decq(R8);                              // Does not affect carry flag.
  __ j(ZERO, &done, Assembler::kNearJump);  // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop (used+1)/2 - (a_used+1)/2 times, R8 > 0.
  __ movq(RAX,
          FieldAddress(RDI, RDX, TIMES_8, target::TypedData::data_offset()));
  __ sbbq(RAX, Immediate(0));
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::data_offset()),
          RAX);
  __ incq(RDX);  // Does not affect carry flag.
  __ decq(R8);   // Does not affect carry flag.
  __ j(NOT_ZERO, &carry_loop, Assembler::kNearJump);

  __ Bind(&done);
  __ LoadObject(RAX, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_mulAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // Pseudo code:
  // static int _mulAdd(Uint32List x_digits, int xi,
  //                    Uint32List m_digits, int i,
  //                    Uint32List a_digits, int j, int n) {
  //   uint64_t x = x_digits[xi >> 1 .. (xi >> 1) + 1];  // xi is Smi and even.
  //   if (x == 0 || n == 0) {
  //     return 2;
  //   }
  //   uint64_t* mip = &m_digits[i >> 1];  // i is Smi and even.
  //   uint64_t* ajp = &a_digits[j >> 1];  // j is Smi and even.
  //   uint64_t c = 0;
  //   SmiUntag(n);  // n is Smi and even.
  //   n = (n + 1)/2;  // Number of pairs to process.
  //   do {
  //     uint64_t mi = *mip++;
  //     uint64_t aj = *ajp;
  //     uint128_t t = x*mi + aj + c;  // 64-bit * 64-bit -> 128-bit.
  //     *ajp++ = low64(t);
  //     c = high64(t);
  //   } while (--n > 0);
  //   while (c != 0) {
  //     uint128_t t = *ajp + c;
  //     *ajp++ = low64(t);
  //     c = high64(t);  // c == 0 or 1.
  //   }
  //   return 2;
  // }

  Label done;
  // RBX = x, done if x == 0
  __ movq(RCX, Address(RSP, 7 * target::kWordSize));  // x_digits
  __ movq(RAX, Address(RSP, 6 * target::kWordSize));  // xi is Smi
  __ movq(RBX,
          FieldAddress(RCX, RAX, TIMES_2, target::TypedData::data_offset()));
  __ testq(RBX, RBX);
  __ j(ZERO, &done, Assembler::kNearJump);

  // R8 = (SmiUntag(n) + 1)/2, no_op if n == 0
  __ movq(R8, Address(RSP, 1 * target::kWordSize));
  __ addq(R8, Immediate(2));
  __ sarq(R8, Immediate(2));  // R8 = number of digit pairs to process.
  __ j(ZERO, &done, Assembler::kNearJump);

  // RDI = mip = &m_digits[i >> 1]
  __ movq(RDI, Address(RSP, 5 * target::kWordSize));  // m_digits
  __ movq(RAX, Address(RSP, 4 * target::kWordSize));  // i is Smi
  __ leaq(RDI,
          FieldAddress(RDI, RAX, TIMES_2, target::TypedData::data_offset()));

  // RSI = ajp = &a_digits[j >> 1]
  __ movq(RSI, Address(RSP, 3 * target::kWordSize));  // a_digits
  __ movq(RAX, Address(RSP, 2 * target::kWordSize));  // j is Smi
  __ leaq(RSI,
          FieldAddress(RSI, RAX, TIMES_2, target::TypedData::data_offset()));

  // RCX = c = 0
  __ xorq(RCX, RCX);

  Label muladd_loop;
  __ Bind(&muladd_loop);
  // x:   RBX
  // mip: RDI
  // ajp: RSI
  // c:   RCX
  // t:   RDX:RAX (not live at loop entry)
  // n:   R8

  // uint64_t mi = *mip++
  __ movq(RAX, Address(RDI, 0));
  __ addq(RDI, Immediate(2 * kBytesPerBigIntDigit));

  // uint128_t t = x*mi
  __ mulq(RBX);       // t = RDX:RAX = RAX * RBX, 64-bit * 64-bit -> 64-bit
  __ addq(RAX, RCX);  // t += c
  __ adcq(RDX, Immediate(0));

  // uint64_t aj = *ajp; t += aj
  __ addq(RAX, Address(RSI, 0));
  __ adcq(RDX, Immediate(0));

  // *ajp++ = low64(t)
  __ movq(Address(RSI, 0), RAX);
  __ addq(RSI, Immediate(2 * kBytesPerBigIntDigit));

  // c = high64(t)
  __ movq(RCX, RDX);

  // while (--n > 0)
  __ decq(R8);  // --n
  __ j(NOT_ZERO, &muladd_loop, Assembler::kNearJump);

  __ testq(RCX, RCX);
  __ j(ZERO, &done, Assembler::kNearJump);

  // *ajp += c
  __ addq(Address(RSI, 0), RCX);
  __ j(NOT_CARRY, &done, Assembler::kNearJump);

  Label propagate_carry_loop;
  __ Bind(&propagate_carry_loop);
  __ addq(RSI, Immediate(2 * kBytesPerBigIntDigit));
  __ incq(Address(RSI, 0));  // c == 0 or 1
  __ j(CARRY, &propagate_carry_loop, Assembler::kNearJump);

  __ Bind(&done);
  __ movq(RAX, Immediate(target::ToRawSmi(2)));  // Two digits processed.
  __ ret();
}

void AsmIntrinsifier::Bigint_sqrAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // Pseudo code:
  // static int _sqrAdd(Uint32List x_digits, int i,
  //                    Uint32List a_digits, int used) {
  //   uint64_t* xip = &x_digits[i >> 1];  // i is Smi and even.
  //   uint64_t x = *xip++;
  //   if (x == 0) return 2;
  //   uint64_t* ajp = &a_digits[i];  // j == 2*i, i is Smi.
  //   uint64_t aj = *ajp;
  //   uint128_t t = x*x + aj;
  //   *ajp++ = low64(t);
  //   uint128_t c = high64(t);
  //   int n = ((used - i + 2) >> 2) - 1;  // used and i are Smi. n: num pairs.
  //   while (--n >= 0) {
  //     uint64_t xi = *xip++;
  //     uint64_t aj = *ajp;
  //     uint192_t t = 2*x*xi + aj + c;  // 2-bit * 64-bit * 64-bit -> 129-bit.
  //     *ajp++ = low64(t);
  //     c = high128(t);  // 65-bit.
  //   }
  //   uint64_t aj = *ajp;
  //   uint128_t t = aj + c;  // 64-bit + 65-bit -> 66-bit.
  //   *ajp++ = low64(t);
  //   *ajp = high64(t);
  //   return 2;
  // }

  // RDI = xip = &x_digits[i >> 1]
  __ movq(RDI, Address(RSP, 4 * target::kWordSize));  // x_digits
  __ movq(RAX, Address(RSP, 3 * target::kWordSize));  // i is Smi
  __ leaq(RDI,
          FieldAddress(RDI, RAX, TIMES_2, target::TypedData::data_offset()));

  // RBX = x = *xip++, return if x == 0
  Label x_zero;
  __ movq(RBX, Address(RDI, 0));
  __ cmpq(RBX, Immediate(0));
  __ j(EQUAL, &x_zero);
  __ addq(RDI, Immediate(2 * kBytesPerBigIntDigit));

  // RSI = ajp = &a_digits[i]
  __ movq(RSI, Address(RSP, 2 * target::kWordSize));  // a_digits
  __ leaq(RSI,
          FieldAddress(RSI, RAX, TIMES_4, target::TypedData::data_offset()));

  // RDX:RAX = t = x*x + *ajp
  __ movq(RAX, RBX);
  __ mulq(RBX);
  __ addq(RAX, Address(RSI, 0));
  __ adcq(RDX, Immediate(0));

  // *ajp++ = low64(t)
  __ movq(Address(RSI, 0), RAX);
  __ addq(RSI, Immediate(2 * kBytesPerBigIntDigit));

  // int n = (used - i + 1)/2 - 1
  __ movq(R8, Address(RSP, 1 * target::kWordSize));  // used is Smi
  __ subq(R8, Address(RSP, 3 * target::kWordSize));  // i is Smi
  __ addq(R8, Immediate(2));
  __ sarq(R8, Immediate(2));
  __ decq(R8);  // R8 = number of digit pairs to process.

  // uint128_t c = high64(t)
  __ xorq(R13, R13);  // R13 = high64(c) == 0
  __ movq(R12, RDX);  // R12 = low64(c) == high64(t)

  Label loop, done;
  __ Bind(&loop);
  // x:   RBX
  // xip: RDI
  // ajp: RSI
  // c:   R13:R12
  // t:   RCX:RDX:RAX (not live at loop entry)
  // n:   R8

  // while (--n >= 0)
  __ decq(R8);  // --n
  __ j(NEGATIVE, &done, Assembler::kNearJump);

  // uint64_t xi = *xip++
  __ movq(RAX, Address(RDI, 0));
  __ addq(RDI, Immediate(2 * kBytesPerBigIntDigit));

  // uint192_t t = RCX:RDX:RAX = 2*x*xi + aj + c
  __ mulq(RBX);       // RDX:RAX = RAX * RBX
  __ xorq(RCX, RCX);  // RCX = 0
  __ shldq(RCX, RDX, Immediate(1));
  __ shldq(RDX, RAX, Immediate(1));
  __ shlq(RAX, Immediate(1));     // RCX:RDX:RAX <<= 1
  __ addq(RAX, Address(RSI, 0));  // t += aj
  __ adcq(RDX, Immediate(0));
  __ adcq(RCX, Immediate(0));
  __ addq(RAX, R12);  // t += low64(c)
  __ adcq(RDX, R13);  // t += high64(c) << 64
  __ adcq(RCX, Immediate(0));

  // *ajp++ = low64(t)
  __ movq(Address(RSI, 0), RAX);
  __ addq(RSI, Immediate(2 * kBytesPerBigIntDigit));

  // c = high128(t)
  __ movq(R12, RDX);
  __ movq(R13, RCX);

  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&done);
  // uint128_t t = aj + c
  __ addq(R12, Address(RSI, 0));  // t = c, t += *ajp
  __ adcq(R13, Immediate(0));

  // *ajp++ = low64(t)
  // *ajp = high64(t)
  __ movq(Address(RSI, 0), R12);
  __ movq(Address(RSI, 2 * kBytesPerBigIntDigit), R13);

  __ Bind(&x_zero);
  __ movq(RAX, Immediate(target::ToRawSmi(2)));  // Two digits processed.
  __ ret();
}

void AsmIntrinsifier::Bigint_estimateQuotientDigit(Assembler* assembler,
                                                   Label* normal_ir_body) {
  // Pseudo code:
  // static int _estQuotientDigit(Uint32List args, Uint32List digits, int i) {
  //   uint64_t yt = args[_YT_LO .. _YT];  // _YT_LO == 0, _YT == 1.
  //   uint64_t* dp = &digits[(i >> 1) - 1];  // i is Smi.
  //   uint64_t dh = dp[0];  // dh == digits[(i >> 1) - 1 .. i >> 1].
  //   uint64_t qd;
  //   if (dh == yt) {
  //     qd = (DIGIT_MASK << 32) | DIGIT_MASK;
  //   } else {
  //     dl = dp[-1];  // dl == digits[(i >> 1) - 3 .. (i >> 1) - 2].
  //     qd = dh:dl / yt;  // No overflow possible, because dh < yt.
  //   }
  //   args[_QD .. _QD_HI] = qd;  // _QD == 2, _QD_HI == 3.
  //   return 2;
  // }

  // RDI = args
  __ movq(RDI, Address(RSP, 3 * target::kWordSize));  // args

  // RCX = yt = args[0..1]
  __ movq(RCX, FieldAddress(RDI, target::TypedData::data_offset()));

  // RBX = dp = &digits[(i >> 1) - 1]
  __ movq(RBX, Address(RSP, 2 * target::kWordSize));  // digits
  __ movq(RAX, Address(RSP, 1 * target::kWordSize));  // i is Smi and odd.
  __ leaq(RBX, FieldAddress(
                   RBX, RAX, TIMES_2,
                   target::TypedData::data_offset() - kBytesPerBigIntDigit));

  // RDX = dh = dp[0]
  __ movq(RDX, Address(RBX, 0));

  // RAX = qd = (DIGIT_MASK << 32) | DIGIT_MASK = -1
  __ movq(RAX, Immediate(-1));

  // Return qd if dh == yt
  Label return_qd;
  __ cmpq(RDX, RCX);
  __ j(EQUAL, &return_qd, Assembler::kNearJump);

  // RAX = dl = dp[-1]
  __ movq(RAX, Address(RBX, -2 * kBytesPerBigIntDigit));

  // RAX = qd = dh:dl / yt = RDX:RAX / RCX
  __ divq(RCX);

  __ Bind(&return_qd);
  // args[2..3] = qd
  __ movq(FieldAddress(
              RDI, target::TypedData::data_offset() + 2 * kBytesPerBigIntDigit),
          RAX);

  __ movq(RAX, Immediate(target::ToRawSmi(2)));  // Two digits processed.
  __ ret();
}

void AsmIntrinsifier::Montgomery_mulMod(Assembler* assembler,
                                        Label* normal_ir_body) {
  // Pseudo code:
  // static int _mulMod(Uint32List args, Uint32List digits, int i) {
  //   uint64_t rho = args[_RHO .. _RHO_HI];  // _RHO == 2, _RHO_HI == 3.
  //   uint64_t d = digits[i >> 1 .. (i >> 1) + 1];  // i is Smi and even.
  //   uint128_t t = rho*d;
  //   args[_MU .. _MU_HI] = t mod DIGIT_BASE^2;  // _MU == 4, _MU_HI == 5.
  //   return 2;
  // }

  // RDI = args
  __ movq(RDI, Address(RSP, 3 * target::kWordSize));  // args

  // RCX = rho = args[2 .. 3]
  __ movq(RCX, FieldAddress(RDI, target::TypedData::data_offset() +
                                     2 * kBytesPerBigIntDigit));

  // RAX = digits[i >> 1 .. (i >> 1) + 1]
  __ movq(RBX, Address(RSP, 2 * target::kWordSize));  // digits
  __ movq(RAX, Address(RSP, 1 * target::kWordSize));  // i is Smi
  __ movq(RAX,
          FieldAddress(RBX, RAX, TIMES_2, target::TypedData::data_offset()));

  // RDX:RAX = t = rho*d
  __ mulq(RCX);

  // args[4 .. 5] = t mod DIGIT_BASE^2 = low64(t)
  __ movq(FieldAddress(
              RDI, target::TypedData::data_offset() + 4 * kBytesPerBigIntDigit),
          RAX);

  __ movq(RAX, Immediate(target::ToRawSmi(2)));  // Two digits processed.
  __ ret();
}

// Check if the last argument is a double, jump to label 'is_smi' if smi
// (easy to convert to double), otherwise jump to label 'not_double_smi',
// Returns the last argument in RAX.
static void TestLastArgumentIsDouble(Assembler* assembler,
                                     Label* is_smi,
                                     Label* not_double_smi) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ testq(RAX, Immediate(kSmiTagMask));
  __ j(ZERO, is_smi);  // Jump if Smi.
  __ CompareClassId(RAX, kDoubleCid);
  __ j(NOT_EQUAL, not_double_smi);
  // Fall through if double.
}

// Both arguments on stack, left argument is a double, right argument is of
// unknown type. Return true or false object in RAX. Any NaN argument
// returns false. Any non-double argument causes control flow to fall through
// to the slow case (compiled method body).
static void CompareDoubles(Assembler* assembler,
                           Label* normal_ir_body,
                           Condition true_condition) {
  Label is_false, is_true, is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, normal_ir_body);
  // Both arguments are double, right operand is in RAX.
  __ movsd(XMM1, FieldAddress(RAX, target::Double::value_offset()));
  __ Bind(&double_op);
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // Left argument.
  __ movsd(XMM0, FieldAddress(RAX, target::Double::value_offset()));
  __ comisd(XMM0, XMM1);
  __ j(PARITY_EVEN, &is_false, Assembler::kNearJump);  // NaN -> false;
  __ j(true_condition, &is_true, Assembler::kNearJump);
  // Fall through false.
  __ Bind(&is_false);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();
  __ Bind(&is_smi);
  __ SmiUntag(RAX);
  __ cvtsi2sdq(XMM1, RAX);
  __ jmp(&double_op);
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_greaterThan(Assembler* assembler,
                                         Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, ABOVE);
}

void AsmIntrinsifier::Double_greaterEqualThan(Assembler* assembler,
                                              Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, ABOVE_EQUAL);
}

void AsmIntrinsifier::Double_lessThan(Assembler* assembler,
                                      Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, BELOW);
}

void AsmIntrinsifier::Double_equal(Assembler* assembler,
                                   Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, EQUAL);
}

void AsmIntrinsifier::Double_lessEqualThan(Assembler* assembler,
                                           Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, BELOW_EQUAL);
}

// Expects left argument to be double (receiver). Right argument is unknown.
// Both arguments are on stack.
static void DoubleArithmeticOperations(Assembler* assembler,
                                       Label* normal_ir_body,
                                       Token::Kind kind) {
  Label is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, normal_ir_body);
  // Both arguments are double, right operand is in RAX.
  __ movsd(XMM1, FieldAddress(RAX, target::Double::value_offset()));
  __ Bind(&double_op);
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // Left argument.
  __ movsd(XMM0, FieldAddress(RAX, target::Double::value_offset()));
  switch (kind) {
    case Token::kADD:
      __ addsd(XMM0, XMM1);
      break;
    case Token::kSUB:
      __ subsd(XMM0, XMM1);
      break;
    case Token::kMUL:
      __ mulsd(XMM0, XMM1);
      break;
    case Token::kDIV:
      __ divsd(XMM0, XMM1);
      break;
    default:
      UNREACHABLE();
  }
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kFarJump,
                 RAX,  // Result register.
                 R13);
  __ movsd(FieldAddress(RAX, target::Double::value_offset()), XMM0);
  __ ret();
  __ Bind(&is_smi);
  __ SmiUntag(RAX);
  __ cvtsi2sdq(XMM1, RAX);
  __ jmp(&double_op);
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

void AsmIntrinsifier::Double_mulFromInteger(Assembler* assembler,
                                            Label* normal_ir_body) {
  // Only smis allowed.
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ testq(RAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body);
  // Is Smi.
  __ SmiUntag(RAX);
  __ cvtsi2sdq(XMM1, RAX);
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));
  __ movsd(XMM0, FieldAddress(RAX, target::Double::value_offset()));
  __ mulsd(XMM0, XMM1);
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kFarJump,
                 RAX,  // Result register.
                 R13);
  __ movsd(FieldAddress(RAX, target::Double::value_offset()), XMM0);
  __ ret();
  __ Bind(normal_ir_body);
}

// Left is double, right is integer (Mint or Smi)
void AsmIntrinsifier::DoubleFromInteger(Assembler* assembler,
                                        Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ testq(RAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body);
  // Is Smi.
  __ SmiUntag(RAX);
  __ cvtsi2sdq(XMM0, RAX);
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kFarJump,
                 RAX,  // Result register.
                 R13);
  __ movsd(FieldAddress(RAX, target::Double::value_offset()), XMM0);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_getIsNaN(Assembler* assembler,
                                      Label* normal_ir_body) {
  Label is_true;
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ movsd(XMM0, FieldAddress(RAX, target::Double::value_offset()));
  __ comisd(XMM0, XMM0);
  __ j(PARITY_EVEN, &is_true, Assembler::kNearJump);  // NaN -> true;
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();
}

void AsmIntrinsifier::Double_getIsInfinite(Assembler* assembler,
                                           Label* normal_ir_body) {
  Label is_inf, done;
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ movq(RAX, FieldAddress(RAX, target::Double::value_offset()));
  // Mask off the sign.
  __ AndImmediate(RAX, Immediate(0x7FFFFFFFFFFFFFFFLL));
  // Compare with +infinity.
  __ CompareImmediate(RAX, Immediate(0x7FF0000000000000LL));
  __ j(EQUAL, &is_inf, Assembler::kNearJump);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ jmp(&done);

  __ Bind(&is_inf);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));

  __ Bind(&done);
  __ ret();
}

void AsmIntrinsifier::Double_getIsNegative(Assembler* assembler,
                                           Label* normal_ir_body) {
  Label is_false, is_true, is_zero;
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ movsd(XMM0, FieldAddress(RAX, target::Double::value_offset()));
  __ xorpd(XMM1, XMM1);  // 0.0 -> XMM1.
  __ comisd(XMM0, XMM1);
  __ j(PARITY_EVEN, &is_false, Assembler::kNearJump);  // NaN -> false.
  __ j(EQUAL, &is_zero, Assembler::kNearJump);  // Check for negative zero.
  __ j(ABOVE_EQUAL, &is_false, Assembler::kNearJump);  // >= 0 -> false.
  __ Bind(&is_true);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();
  __ Bind(&is_false);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_zero);
  // Check for negative zero (get the sign bit).
  __ movmskpd(RAX, XMM0);
  __ testq(RAX, Immediate(1));
  __ j(NOT_ZERO, &is_true, Assembler::kNearJump);
  __ jmp(&is_false, Assembler::kNearJump);
}

void AsmIntrinsifier::DoubleToInteger(Assembler* assembler,
                                      Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ movsd(XMM0, FieldAddress(RAX, target::Double::value_offset()));
  __ cvttsd2siq(RAX, XMM0);
  // Overflow is signalled with minint.
  // Check for overflow and that it fits into Smi.
  __ movq(RCX, RAX);
  __ shlq(RCX, Immediate(1));
  __ j(OVERFLOW, normal_ir_body, Assembler::kNearJump);
  __ SmiTag(RAX);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_hashCode(Assembler* assembler,
                                      Label* normal_ir_body) {
  // TODO(dartbug.com/31174): Convert this to a graph intrinsic.

  // Convert double value to signed 64-bit int in RAX and
  // back to a double in XMM1.
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));
  __ movsd(XMM0, FieldAddress(RCX, target::Double::value_offset()));
  __ cvttsd2siq(RAX, XMM0);
  __ cvtsi2sdq(XMM1, RAX);

  // Tag the int as a Smi, making sure that it fits; this checks for
  // overflow and NaN in the conversion from double to int. Conversion
  // overflow from cvttsd2si is signalled with an INT64_MIN value.
  ASSERT(kSmiTag == 0 && kSmiTagShift == 1);
  __ addq(RAX, RAX);
  __ j(OVERFLOW, normal_ir_body, Assembler::kNearJump);

  // Compare the two double values. If they are equal, we return the
  // Smi tagged result immediately as the hash code.
  Label double_hash;
  __ comisd(XMM0, XMM1);
  __ j(NOT_EQUAL, &double_hash, Assembler::kNearJump);
  __ ret();

  // Convert the double bits to a hash code that fits in a Smi.
  __ Bind(&double_hash);
  __ movq(RAX, FieldAddress(RCX, target::Double::value_offset()));
  __ movq(RCX, RAX);
  __ shrq(RCX, Immediate(32));
  __ xorq(RAX, RCX);
  __ andq(RAX, Immediate(target::kSmiMax));
  __ SmiTag(RAX);
  __ ret();

  // Fall into the native C++ implementation.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::MathSqrt(Assembler* assembler, Label* normal_ir_body) {
  Label is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, normal_ir_body);
  // Argument is double and is in RAX.
  __ movsd(XMM1, FieldAddress(RAX, target::Double::value_offset()));
  __ Bind(&double_op);
  __ sqrtsd(XMM0, XMM1);
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kFarJump,
                 RAX,  // Result register.
                 R13);
  __ movsd(FieldAddress(RAX, target::Double::value_offset()), XMM0);
  __ ret();
  __ Bind(&is_smi);
  __ SmiUntag(RAX);
  __ cvtsi2sdq(XMM1, RAX);
  __ jmp(&double_op);
  __ Bind(normal_ir_body);
}

//    var state = ((_A * (_state[kSTATE_LO])) + _state[kSTATE_HI]) & _MASK_64;
//    _state[kSTATE_LO] = state & _MASK_32;
//    _state[kSTATE_HI] = state >> 32;
void AsmIntrinsifier::Random_nextState(Assembler* assembler,
                                       Label* normal_ir_body) {
  const Field& state_field = LookupMathRandomStateFieldOffset();
  const int64_t a_int_value = AsmIntrinsifier::kRandomAValue;

  // Receiver.
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  // Field '_state'.
  __ movq(RBX, FieldAddress(RAX, LookupFieldOffsetInBytes(state_field)));
  // Addresses of _state[0] and _state[1].
  const intptr_t scale =
      target::Instance::ElementSizeFor(kTypedDataUint32ArrayCid);
  const intptr_t offset =
      target::Instance::DataOffsetFor(kTypedDataUint32ArrayCid);
  Address addr_0 = FieldAddress(RBX, 0 * scale + offset);
  Address addr_1 = FieldAddress(RBX, 1 * scale + offset);
  __ movq(RAX, Immediate(a_int_value));
  __ movl(RCX, addr_0);
  __ imulq(RCX, RAX);
  __ movl(RDX, addr_1);
  __ addq(RDX, RCX);
  __ movl(addr_0, RDX);
  __ shrq(RDX, Immediate(32));
  __ movl(addr_1, RDX);
  ASSERT(target::ToRawSmi(0) == 0);
  __ xorq(RAX, RAX);
  __ ret();
}

// Identity comparison.
void AsmIntrinsifier::ObjectEquals(Assembler* assembler,
                                   Label* normal_ir_body) {
  Label is_true;
  const intptr_t kReceiverOffset = 2;
  const intptr_t kArgumentOffset = 1;

  __ movq(RAX, Address(RSP, +kArgumentOffset * target::kWordSize));
  __ cmpq(RAX, Address(RSP, +kReceiverOffset * target::kWordSize));
  __ j(EQUAL, &is_true, Assembler::kNearJump);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();
}

static void RangeCheck(Assembler* assembler,
                       Register reg,
                       intptr_t low,
                       intptr_t high,
                       Condition cc,
                       Label* target) {
  __ subq(reg, Immediate(low));
  __ cmpq(reg, Immediate(high - low));
  __ j(cc, target);
}

const Condition kIfNotInRange = ABOVE;
const Condition kIfInRange = BELOW_EQUAL;

static void JumpIfInteger(Assembler* assembler, Register cid, Label* target) {
  RangeCheck(assembler, cid, kSmiCid, kMintCid, kIfInRange, target);
}

static void JumpIfNotInteger(Assembler* assembler,
                             Register cid,
                             Label* target) {
  RangeCheck(assembler, cid, kSmiCid, kMintCid, kIfNotInRange, target);
}

static void JumpIfString(Assembler* assembler, Register cid, Label* target) {
  RangeCheck(assembler, cid, kOneByteStringCid, kExternalTwoByteStringCid,
             kIfInRange, target);
}

static void JumpIfNotString(Assembler* assembler, Register cid, Label* target) {
  RangeCheck(assembler, cid, kOneByteStringCid, kExternalTwoByteStringCid,
             kIfNotInRange, target);
}

// Return type quickly for simple types (not parameterized and not signature).
void AsmIntrinsifier::ObjectRuntimeType(Assembler* assembler,
                                        Label* normal_ir_body) {
  Label use_declaration_type, not_integer, not_double;
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ LoadClassIdMayBeSmi(RCX, RAX);

  // RCX: untagged cid of instance (RAX).
  __ cmpq(RCX, Immediate(kClosureCid));
  __ j(EQUAL, normal_ir_body);  // Instance is a closure.

  __ cmpl(RCX, Immediate(kNumPredefinedCids));
  __ j(ABOVE, &use_declaration_type);

  // If object is a instance of _Double return double type.
  __ cmpl(RCX, Immediate(kDoubleCid));
  __ j(NOT_EQUAL, &not_double);

  __ LoadIsolate(RAX);
  __ movq(RAX, Address(RAX, target::Isolate::cached_object_store_offset()));
  __ movq(RAX, Address(RAX, target::ObjectStore::double_type_offset()));
  __ ret();

  __ Bind(&not_double);
  // If object is an integer (smi, mint or bigint) return int type.
  __ movl(RAX, RCX);
  JumpIfNotInteger(assembler, RAX, &not_integer);

  __ LoadIsolate(RAX);
  __ movq(RAX, Address(RAX, target::Isolate::cached_object_store_offset()));
  __ movq(RAX, Address(RAX, target::ObjectStore::int_type_offset()));
  __ ret();

  __ Bind(&not_integer);
  // If object is a string (one byte, two byte or external variants) return
  // string type.
  __ movq(RAX, RCX);
  JumpIfNotString(assembler, RAX, &use_declaration_type);

  __ LoadIsolate(RAX);
  __ movq(RAX, Address(RAX, target::Isolate::cached_object_store_offset()));
  __ movq(RAX, Address(RAX, target::ObjectStore::string_type_offset()));
  __ ret();

  // Object is neither double, nor integer, nor string.
  __ Bind(&use_declaration_type);
  __ LoadClassById(RDI, RCX);
  __ movzxw(RCX, FieldAddress(RDI, target::Class::num_type_arguments_offset()));
  __ cmpq(RCX, Immediate(0));
  __ j(NOT_EQUAL, normal_ir_body, Assembler::kNearJump);
  __ movq(RAX, FieldAddress(RDI, target::Class::declaration_type_offset()));
  __ CompareObject(RAX, NullObject());
  __ j(EQUAL, normal_ir_body, Assembler::kNearJump);  // Not yet set.
  __ ret();

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
  __ cmpq(cid1, Immediate(kClosureCid));
  __ j(EQUAL, normal_ir_body);

  // Check whether class ids match. If class ids don't match types may still be
  // considered equivalent (e.g. multiple string implementation classes map to a
  // single String type).
  __ cmpq(cid1, cid2);
  __ j(NOT_EQUAL, &different_cids);

  // Types have the same class and neither is a closure type.
  // Check if there are no type arguments. In this case we can return true.
  // Otherwise fall through into the runtime to handle comparison.
  __ LoadClassById(scratch, cid1);
  __ movzxw(scratch,
            FieldAddress(scratch, target::Class::num_type_arguments_offset()));
  __ cmpq(scratch, Immediate(0));
  __ j(NOT_EQUAL, normal_ir_body);
  __ jmp(equal);

  // Class ids are different. Check if we are comparing two string types (with
  // different representations) or two integer types.
  __ Bind(&different_cids);
  __ cmpq(cid1, Immediate(kNumPredefinedCids));
  __ j(ABOVE_EQUAL, not_equal);

  // Check if both are integer types.
  __ movq(scratch, cid1);
  JumpIfNotInteger(assembler, scratch, &not_integer);

  // First type is an integer. Check if the second is an integer too.
  // Otherwise types are unequiv because only integers have the same runtime
  // type as other integers.
  JumpIfInteger(assembler, cid2, equal);
  __ jmp(not_equal);

  __ Bind(&not_integer);
  // Check if the first type is String. If it is not then types are not
  // equivalent because they have different class ids and they are not strings
  // or integers.
  JumpIfNotString(assembler, cid1, not_equal);
  // First type is String. Check if the second is a string too.
  JumpIfString(assembler, cid2, equal);
  // String types are only equivalent to other String types.
  __ jmp(not_equal);
}

void AsmIntrinsifier::ObjectHaveSameRuntimeType(Assembler* assembler,
                                                Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ LoadClassIdMayBeSmi(RCX, RAX);

  __ movq(RAX, Address(RSP, +2 * target::kWordSize));
  __ LoadClassIdMayBeSmi(RDX, RAX);

  Label equal, not_equal;
  EquivalentClassIds(assembler, normal_ir_body, &equal, &not_equal, RCX, RDX,
                     RAX);

  __ Bind(&equal);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(&not_equal);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::String_getHashCode(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));  // String object.
  __ movl(RAX, FieldAddress(RAX, target::String::hash_offset()));
  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagShift == 1);
  __ addq(RAX, RAX);  // Smi tag RAX, setting Z flag.
  __ j(ZERO, normal_ir_body, Assembler::kNearJump);
  __ ret();
  __ Bind(normal_ir_body);
  // Hash not yet computed.
}

void AsmIntrinsifier::Type_getHashCode(Assembler* assembler,
                                       Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));  // Type object.
  __ movq(RAX, FieldAddress(RAX, target::Type::hash_offset()));
  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagShift == 1);
  __ testq(RAX, RAX);
  __ j(ZERO, normal_ir_body, Assembler::kNearJump);
  __ ret();
  __ Bind(normal_ir_body);
  // Hash not yet computed.
}

void AsmIntrinsifier::Type_equality(Assembler* assembler,
                                    Label* normal_ir_body) {
  Label equal, not_equal, equiv_cids, check_legacy;

  __ movq(RCX, Address(RSP, +1 * target::kWordSize));
  __ movq(RDX, Address(RSP, +2 * target::kWordSize));
  __ cmpq(RCX, RDX);
  __ j(EQUAL, &equal);

  // RCX might not be a Type object, so check that first (RDX should be though,
  // since this is a method on the Type class).
  __ LoadClassIdMayBeSmi(RAX, RCX);
  __ cmpq(RAX, Immediate(kTypeCid));
  __ j(NOT_EQUAL, normal_ir_body);

  // Check if types are syntactically equal.
  __ movq(RDI, FieldAddress(RCX, target::Type::type_class_id_offset()));
  __ SmiUntag(RDI);
  __ movq(RSI, FieldAddress(RDX, target::Type::type_class_id_offset()));
  __ SmiUntag(RSI);
  EquivalentClassIds(assembler, normal_ir_body, &equiv_cids, &not_equal, RDI,
                     RSI, RAX);

  // Check nullability.
  __ Bind(&equiv_cids);
  __ movzxb(RCX, FieldAddress(RCX, target::Type::nullability_offset()));
  __ movzxb(RDX, FieldAddress(RDX, target::Type::nullability_offset()));
  __ cmpq(RCX, RDX);
  __ j(NOT_EQUAL, &check_legacy, Assembler::kNearJump);
  // Fall through to equal case if nullability is strictly equal.

  __ Bind(&equal);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();

  // At this point the nullabilities are different, so they can only be
  // syntactically equivalent if they're both either kNonNullable or kLegacy.
  // These are the two largest values of the enum, so we can just do a < check.
  ASSERT(target::Nullability::kNullable < target::Nullability::kNonNullable &&
         target::Nullability::kNonNullable < target::Nullability::kLegacy);
  __ Bind(&check_legacy);
  __ cmpq(RCX, Immediate(target::Nullability::kNonNullable));
  __ j(LESS, &not_equal, Assembler::kNearJump);
  __ cmpq(RDX, Immediate(target::Nullability::kNonNullable));
  __ j(GREATER_EQUAL, &equal, Assembler::kNearJump);

  __ Bind(&not_equal);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Object_getHash(Assembler* assembler,
                                     Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));  // Object.
  __ movl(RAX, FieldAddress(RAX, target::String::hash_offset()));
  __ SmiTag(RAX);
  __ ret();
}

void AsmIntrinsifier::Object_setHash(Assembler* assembler,
                                     Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // Object.
  __ movq(RDX, Address(RSP, +1 * target::kWordSize));  // Value.
  __ SmiUntag(RDX);
  __ shlq(RDX, Immediate(target::ObjectLayout::kHashTagPos));
  // lock+orq is an atomic read-modify-write.
  __ lock();
  __ orq(FieldAddress(RAX, target::Object::tags_offset()), RDX);
  __ ret();
}

void GenerateSubstringMatchesSpecialization(Assembler* assembler,
                                            intptr_t receiver_cid,
                                            intptr_t other_cid,
                                            Label* return_true,
                                            Label* return_false) {
  __ movq(R8, FieldAddress(RAX, target::String::length_offset()));
  __ movq(R9, FieldAddress(RCX, target::String::length_offset()));

  // if (other.length == 0) return true;
  __ testq(R9, R9);
  __ j(ZERO, return_true);

  // if (start < 0) return false;
  __ testq(RBX, RBX);
  __ j(SIGN, return_false);

  // if (start + other.length > this.length) return false;
  __ movq(R11, RBX);
  __ addq(R11, R9);
  __ cmpq(R11, R8);
  __ j(GREATER, return_false);

  __ SmiUntag(RBX);                     // start
  __ SmiUntag(R9);                      // other.length
  __ LoadImmediate(R11, Immediate(0));  // i = 0

  // do
  Label loop;
  __ Bind(&loop);

  // this.codeUnitAt(i + start)
  // clobbering this.length
  __ movq(R8, R11);
  __ addq(R8, RBX);
  if (receiver_cid == kOneByteStringCid) {
    __ movzxb(R12, FieldAddress(RAX, R8, TIMES_1,
                                target::OneByteString::data_offset()));
  } else {
    ASSERT(receiver_cid == kTwoByteStringCid);
    __ movzxw(R12, FieldAddress(RAX, R8, TIMES_2,
                                target::TwoByteString::data_offset()));
  }
  // other.codeUnitAt(i)
  if (other_cid == kOneByteStringCid) {
    __ movzxb(R13, FieldAddress(RCX, R11, TIMES_1,
                                target::OneByteString::data_offset()));
  } else {
    ASSERT(other_cid == kTwoByteStringCid);
    __ movzxw(R13, FieldAddress(RCX, R11, TIMES_2,
                                target::TwoByteString::data_offset()));
  }
  __ cmpq(R12, R13);
  __ j(NOT_EQUAL, return_false);

  // i++, while (i < len)
  __ addq(R11, Immediate(1));
  __ cmpq(R11, R9);
  __ j(LESS, &loop, Assembler::kNearJump);

  __ jmp(return_true);
}

// bool _substringMatches(int start, String other)
// This intrinsic handles a OneByteString or TwoByteString receiver with a
// OneByteString other.
void AsmIntrinsifier::StringBaseSubstringMatches(Assembler* assembler,
                                                 Label* normal_ir_body) {
  Label return_true, return_false, try_two_byte;
  __ movq(RAX, Address(RSP, +3 * target::kWordSize));  // receiver
  __ movq(RBX, Address(RSP, +2 * target::kWordSize));  // start
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));  // other

  __ testq(RBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body);  // 'start' is not Smi.

  __ CompareClassId(RCX, kOneByteStringCid);
  __ j(NOT_EQUAL, normal_ir_body);

  __ CompareClassId(RAX, kOneByteStringCid);
  __ j(NOT_EQUAL, &try_two_byte);

  GenerateSubstringMatchesSpecialization(assembler, kOneByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&try_two_byte);
  __ CompareClassId(RAX, kTwoByteStringCid);
  __ j(NOT_EQUAL, normal_ir_body);

  GenerateSubstringMatchesSpecialization(assembler, kTwoByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&return_true);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(&return_false);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseCharAt(Assembler* assembler,
                                       Label* normal_ir_body) {
  Label try_two_byte_string;
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));  // Index.
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // String.
  __ testq(RCX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body);  // Non-smi index.
  // Range check.
  __ cmpq(RCX, FieldAddress(RAX, target::String::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, normal_ir_body);
  __ CompareClassId(RAX, kOneByteStringCid);
  __ j(NOT_EQUAL, &try_two_byte_string, Assembler::kNearJump);
  __ SmiUntag(RCX);
  __ movzxb(RCX, FieldAddress(RAX, RCX, TIMES_1,
                              target::OneByteString::data_offset()));
  __ cmpq(RCX, Immediate(target::Symbols::kNumberOfOneCharCodeSymbols));
  __ j(GREATER_EQUAL, normal_ir_body);
  __ movq(RAX,
          Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ movq(RAX, Address(RAX, RCX, TIMES_8,
                       target::Symbols::kNullCharCodeSymbolOffset *
                           target::kWordSize));
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(RAX, kTwoByteStringCid);
  __ j(NOT_EQUAL, normal_ir_body);
  ASSERT(kSmiTagShift == 1);
  __ movzxw(RCX, FieldAddress(RAX, RCX, TIMES_1,
                              target::OneByteString::data_offset()));
  __ cmpq(RCX, Immediate(target::Symbols::kNumberOfOneCharCodeSymbols));
  __ j(GREATER_EQUAL, normal_ir_body);
  __ movq(RAX,
          Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ movq(RAX, Address(RAX, RCX, TIMES_8,
                       target::Symbols::kNullCharCodeSymbolOffset *
                           target::kWordSize));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseIsEmpty(Assembler* assembler,
                                        Label* normal_ir_body) {
  Label is_true;
  // Get length.
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));  // String object.
  __ movq(RAX, FieldAddress(RAX, target::String::length_offset()));
  __ cmpq(RAX, Immediate(target::ToRawSmi(0)));
  __ j(EQUAL, &is_true, Assembler::kNearJump);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();
}

void AsmIntrinsifier::OneByteString_getHashCode(Assembler* assembler,
                                                Label* normal_ir_body) {
  Label compute_hash;
  __ movq(
      RBX,
      Address(RSP, +1 * target::kWordSize));  // target::OneByteString object.
  __ movl(RAX, FieldAddress(RBX, target::String::hash_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &compute_hash, Assembler::kNearJump);
  __ SmiTag(RAX);
  __ ret();

  __ Bind(&compute_hash);
  // Hash not yet computed, use algorithm of class StringHasher.
  __ movq(RCX, FieldAddress(RBX, target::String::length_offset()));
  __ SmiUntag(RCX);
  __ xorq(RAX, RAX);
  __ xorq(RDI, RDI);
  // RBX: Instance of target::OneByteString.
  // RCX: String length, untagged integer.
  // RDI: Loop counter, untagged integer.
  // RAX: Hash code, untagged integer.
  Label loop, done, set_hash_code;
  __ Bind(&loop);
  __ cmpq(RDI, RCX);
  __ j(EQUAL, &done, Assembler::kNearJump);
  // Add to hash code: (hash_ is uint32)
  // hash_ += ch;
  // hash_ += hash_ << 10;
  // hash_ ^= hash_ >> 6;
  // Get one characters (ch).
  __ movzxb(RDX, FieldAddress(RBX, RDI, TIMES_1,
                              target::OneByteString::data_offset()));
  // RDX: ch and temporary.
  __ addl(RAX, RDX);
  __ movq(RDX, RAX);
  __ shll(RDX, Immediate(10));
  __ addl(RAX, RDX);
  __ movq(RDX, RAX);
  __ shrl(RDX, Immediate(6));
  __ xorl(RAX, RDX);

  __ incq(RDI);
  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&done);
  // Finalize:
  // hash_ += hash_ << 3;
  // hash_ ^= hash_ >> 11;
  // hash_ += hash_ << 15;
  __ movq(RDX, RAX);
  __ shll(RDX, Immediate(3));
  __ addl(RAX, RDX);
  __ movq(RDX, RAX);
  __ shrl(RDX, Immediate(11));
  __ xorl(RAX, RDX);
  __ movq(RDX, RAX);
  __ shll(RDX, Immediate(15));
  __ addl(RAX, RDX);
  // hash_ = hash_ & ((static_cast<intptr_t>(1) << bits) - 1);
  __ andl(
      RAX,
      Immediate(((static_cast<intptr_t>(1) << target::String::kHashBits) - 1)));

  // return hash_ == 0 ? 1 : hash_;
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &set_hash_code, Assembler::kNearJump);
  __ incq(RAX);
  __ Bind(&set_hash_code);
  __ shlq(RAX, Immediate(target::ObjectLayout::kHashTagPos));
  // lock+orq is an atomic read-modify-write.
  __ lock();
  __ orq(FieldAddress(RBX, target::Object::tags_offset()), RAX);
  __ sarq(RAX, Immediate(target::ObjectLayout::kHashTagPos));
  __ SmiTag(RAX);
  __ ret();
}

// Allocates a _OneByteString or _TwoByteString. The content is not initialized.
// 'length_reg' contains the desired length as a _Smi or _Mint.
// Returns new string as tagged pointer in RAX.
static void TryAllocateString(Assembler* assembler,
                              classid_t cid,
                              Label* ok,
                              Label* failure,
                              Register length_reg) {
  ASSERT(cid == kOneByteStringCid || cid == kTwoByteStringCid);
  // _Mint length: call to runtime to produce error.
  __ BranchIfNotSmi(length_reg, failure);
  // negative length: call to runtime to produce error.
  __ cmpq(length_reg, Immediate(0));
  __ j(LESS, failure);

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, failure, Assembler::kFarJump));
  if (length_reg != RDI) {
    __ movq(RDI, length_reg);
  }
  Label pop_and_fail, not_zero_length;
  __ pushq(RDI);                          // Preserve length.
  if (cid == kOneByteStringCid) {
    // Untag length.
    __ SmiUntag(RDI);
  } else {
    // Untag length and multiply by element size -> no-op.
    ASSERT(kSmiTagSize == 1);
  }
  const intptr_t fixed_size_plus_alignment_padding =
      target::String::InstanceSize() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ addq(RDI, Immediate(fixed_size_plus_alignment_padding));
  __ andq(RDI, Immediate(-target::ObjectAlignment::kObjectAlignment));

  __ movq(RAX, Address(THR, target::Thread::top_offset()));

  // RDI: allocation size.
  __ movq(RCX, RAX);
  __ addq(RCX, RDI);
  __ j(CARRY, &pop_and_fail);

  // Check if the allocation fits into the remaining space.
  // RAX: potential new object start.
  // RCX: potential next object start.
  // RDI: allocation size.
  __ cmpq(RCX, Address(THR, target::Thread::end_offset()));
  __ j(ABOVE_EQUAL, &pop_and_fail);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ movq(Address(THR, target::Thread::top_offset()), RCX);
  __ addq(RAX, Immediate(kHeapObjectTag));

  // Initialize the tags.
  // RAX: new object start as a tagged pointer.
  // RDI: allocation size.
  {
    Label size_tag_overflow, done;
    __ cmpq(RDI, Immediate(target::ObjectLayout::kSizeTagMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shlq(RDI, Immediate(target::ObjectLayout::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&size_tag_overflow);
    __ xorq(RDI, RDI);
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    // This also clears the hash, which is in the high bits of the tags.
    const uword tags =
        target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
    __ orq(RDI, Immediate(tags));
    __ movq(FieldAddress(RAX, target::Object::tags_offset()), RDI);  // Tags.
  }

  // Set the length field.
  __ popq(RDI);
  __ StoreIntoObjectNoBarrier(
      RAX, FieldAddress(RAX, target::String::length_offset()), RDI);
  __ jmp(ok, Assembler::kNearJump);

  __ Bind(&pop_and_fail);
  __ popq(RDI);
  __ jmp(failure);
}

// Arg0: target::OneByteString (receiver).
// Arg1: Start index as Smi.
// Arg2: End index as Smi.
// The indexes must be valid.
void AsmIntrinsifier::OneByteString_substringUnchecked(Assembler* assembler,
                                                       Label* normal_ir_body) {
  const intptr_t kStringOffset = 3 * target::kWordSize;
  const intptr_t kStartIndexOffset = 2 * target::kWordSize;
  const intptr_t kEndIndexOffset = 1 * target::kWordSize;
  Label ok;
  __ movq(RSI, Address(RSP, +kStartIndexOffset));
  __ movq(RDI, Address(RSP, +kEndIndexOffset));
  __ orq(RSI, RDI);
  __ testq(RSI, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body);  // 'start', 'end' not Smi.

  __ subq(RDI, Address(RSP, +kStartIndexOffset));
  TryAllocateString(assembler, kOneByteStringCid, &ok, normal_ir_body, RDI);
  __ Bind(&ok);
  // RAX: new string as tagged pointer.
  // Copy string.
  __ movq(RSI, Address(RSP, +kStringOffset));
  __ movq(RBX, Address(RSP, +kStartIndexOffset));
  __ SmiUntag(RBX);
  __ leaq(RSI, FieldAddress(RSI, RBX, TIMES_1,
                            target::OneByteString::data_offset()));
  // RSI: Start address to copy from (untagged).
  // RBX: Untagged start index.
  __ movq(RCX, Address(RSP, +kEndIndexOffset));
  __ SmiUntag(RCX);
  __ subq(RCX, RBX);
  __ xorq(RDX, RDX);
  // RSI: Start address to copy from (untagged).
  // RCX: Untagged number of bytes to copy.
  // RAX: Tagged result string
  // RDX: Loop counter.
  // RBX: Scratch register.
  Label loop, check;
  __ jmp(&check, Assembler::kNearJump);
  __ Bind(&loop);
  __ movzxb(RBX, Address(RSI, RDX, TIMES_1, 0));
  __ movb(FieldAddress(RAX, RDX, TIMES_1, target::OneByteString::data_offset()),
          RBX);
  __ incq(RDX);
  __ Bind(&check);
  __ cmpq(RDX, RCX);
  __ j(LESS, &loop, Assembler::kNearJump);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::WriteIntoOneByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));  // Value.
  __ movq(RBX, Address(RSP, +2 * target::kWordSize));  // Index.
  __ movq(RAX, Address(RSP, +3 * target::kWordSize));  // target::OneByteString.
  __ SmiUntag(RBX);
  __ SmiUntag(RCX);
  __ movb(FieldAddress(RAX, RBX, TIMES_1, target::OneByteString::data_offset()),
          RCX);
  __ ret();
}

void AsmIntrinsifier::WriteIntoTwoByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));  // Value.
  __ movq(RBX, Address(RSP, +2 * target::kWordSize));  // Index.
  __ movq(RAX, Address(RSP, +3 * target::kWordSize));  // target::TwoByteString.
  // Untag index and multiply by element size -> no-op.
  __ SmiUntag(RCX);
  __ movw(FieldAddress(RAX, RBX, TIMES_1, target::TwoByteString::data_offset()),
          RCX);
  __ ret();
}

void AsmIntrinsifier::AllocateOneByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ movq(RDI, Address(RSP, +1 * target::kWordSize));  // Length.v=
  Label ok;
  TryAllocateString(assembler, kOneByteStringCid, &ok, normal_ir_body, RDI);
  // RDI: Start address to copy from (untagged).

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AllocateTwoByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ movq(RDI, Address(RSP, +1 * target::kWordSize));  // Length.v=
  Label ok;
  TryAllocateString(assembler, kTwoByteStringCid, &ok, normal_ir_body, RDI);
  // RDI: Start address to copy from (untagged).

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

// TODO(srdjan): Add combinations (one-byte/two-byte/external strings).
static void StringEquality(Assembler* assembler,
                           Label* normal_ir_body,
                           intptr_t string_cid) {
  Label is_true, is_false, loop;
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // This.
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));  // Other.

  // Are identical?
  __ cmpq(RAX, RCX);
  __ j(EQUAL, &is_true, Assembler::kNearJump);

  // Is other target::OneByteString?
  __ testq(RCX, Immediate(kSmiTagMask));
  __ j(ZERO, &is_false);  // Smi
  __ CompareClassId(RCX, string_cid);
  __ j(NOT_EQUAL, normal_ir_body, Assembler::kNearJump);

  // Have same length?
  __ movq(RDI, FieldAddress(RAX, target::String::length_offset()));
  __ cmpq(RDI, FieldAddress(RCX, target::String::length_offset()));
  __ j(NOT_EQUAL, &is_false, Assembler::kNearJump);

  // Check contents, no fall-through possible.
  // TODO(srdjan): write a faster check.
  __ SmiUntag(RDI);
  __ Bind(&loop);
  __ decq(RDI);
  __ cmpq(RDI, Immediate(0));
  __ j(LESS, &is_true, Assembler::kNearJump);
  if (string_cid == kOneByteStringCid) {
    __ movzxb(RBX, FieldAddress(RAX, RDI, TIMES_1,
                                target::OneByteString::data_offset()));
    __ movzxb(RDX, FieldAddress(RCX, RDI, TIMES_1,
                                target::OneByteString::data_offset()));
  } else if (string_cid == kTwoByteStringCid) {
    __ movzxw(RBX, FieldAddress(RAX, RDI, TIMES_2,
                                target::TwoByteString::data_offset()));
    __ movzxw(RDX, FieldAddress(RCX, RDI, TIMES_2,
                                target::TwoByteString::data_offset()));
  } else {
    UNIMPLEMENTED();
  }
  __ cmpq(RBX, RDX);
  __ j(NOT_EQUAL, &is_false, Assembler::kNearJump);
  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&is_true);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(&is_false);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
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

  static const intptr_t kRegExpParamOffset = 3 * target::kWordSize;
  static const intptr_t kStringParamOffset = 2 * target::kWordSize;
  // start_index smi is located at offset 1.

  // Incoming registers:
  // RAX: Function. (Will be loaded with the specialized matcher function.)
  // RCX: Unknown. (Must be GC safe on tail call.)
  // R10: Arguments descriptor. (Will be preserved.)

  // Load the specialized function pointer into RAX. Leverage the fact the
  // string CIDs as well as stored function pointers are in sequence.
  __ movq(RBX, Address(RSP, kRegExpParamOffset));
  __ movq(RDI, Address(RSP, kStringParamOffset));
  __ LoadClassId(RDI, RDI);
  __ SubImmediate(RDI, Immediate(kOneByteStringCid));
  __ movq(RAX, FieldAddress(
                   RBX, RDI, TIMES_8,
                   target::RegExp::function_offset(kOneByteStringCid, sticky)));

  // Registers are now set up for the lazy compile stub. It expects the function
  // in RAX, the argument descriptor in R10, and IC-Data in RCX.
  __ xorq(RCX, RCX);

  // Tail-call the function.
  __ movq(CODE_REG, FieldAddress(RAX, target::Function::code_offset()));
  __ movq(RDI, FieldAddress(RAX, target::Function::entry_point_offset()));
  __ jmp(RDI);
}

// On stack: user tag (+1), return-address (+0).
void AsmIntrinsifier::UserTag_makeCurrent(Assembler* assembler,
                                          Label* normal_ir_body) {
  // RBX: Isolate.
  __ LoadIsolate(RBX);
  // RAX: Current user tag.
  __ movq(RAX, Address(RBX, target::Isolate::current_tag_offset()));
  // R10: UserTag.
  __ movq(R10, Address(RSP, +1 * target::kWordSize));
  // Set Isolate::current_tag_.
  __ movq(Address(RBX, target::Isolate::current_tag_offset()), R10);
  // R10: UserTag's tag.
  __ movq(R10, FieldAddress(R10, target::UserTag::tag_offset()));
  // Set Isolate::user_tag_.
  __ movq(Address(RBX, target::Isolate::user_tag_offset()), R10);
  __ ret();
}

void AsmIntrinsifier::UserTag_defaultTag(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ LoadIsolate(RAX);
  __ movq(RAX, Address(RAX, target::Isolate::default_tag_offset()));
  __ ret();
}

void AsmIntrinsifier::Profiler_getCurrentTag(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ LoadIsolate(RAX);
  __ movq(RAX, Address(RAX, target::Isolate::current_tag_offset()));
  __ ret();
}

void AsmIntrinsifier::Timeline_isDartStreamEnabled(Assembler* assembler,
                                                   Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
#else
  Label true_label;
  // Load TimelineStream*.
  __ movq(RAX, Address(THR, target::Thread::dart_stream_offset()));
  // Load uintptr_t from TimelineStream*.
  __ movq(RAX, Address(RAX, target::TimelineStream::enabled_offset()));
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_ZERO, &true_label, Assembler::kNearJump);
  // Not enabled.
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  // Enabled.
  __ Bind(&true_label);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();
#endif
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_X64)
