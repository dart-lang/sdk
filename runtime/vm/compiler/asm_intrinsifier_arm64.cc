// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/asm_intrinsifier.h"
#include "vm/compiler/assembler/assembler.h"

namespace dart {
namespace compiler {

// When entering intrinsics code:
// PP: Caller's ObjectPool in JIT / global ObjectPool in AOT
// CODE_REG: Callee's Code in JIT / not passed in AOT
// R4: Arguments descriptor
// LR: Return address
// The R4 and CODE_REG registers can be destroyed only if there is no slow-path,
// i.e. if the intrinsified method always executes a return.
// The FP register should not be modified, because it is used by the profiler.
// The PP and THR registers (see constants_arm64.h) must be preserved.

#define __ assembler->

// Loads args from stack into R0 and R1
// Tests if they are smis, jumps to label not_smi if not.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ ldr(R0, Address(SP, +0 * target::kWordSize));
  __ ldr(R1, Address(SP, +1 * target::kWordSize));
  __ orr(TMP, R0, Operand(R1));
  __ BranchIfNotSmi(TMP, not_smi);
}

void AsmIntrinsifier::Integer_shl(Assembler* assembler, Label* normal_ir_body) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(kSmiTag == 0);
  const Register right = R0;
  const Register left = R1;
  const Register temp = R2;
  const Register result = R0;

  TestBothArgumentsSmis(assembler, normal_ir_body);
  __ CompareImmediate(right, target::ToRawSmi(target::kSmiBits),
                      compiler::kObjectBytes);
  __ b(normal_ir_body, CS);

  // Left is not a constant.
  // Check if count too large for handling it inlined.
  __ SmiUntag(TMP, right);  // SmiUntag right into TMP.
  // Overflow test (preserve left, right, and TMP);
  __ lslv(temp, left, TMP, kObjectBytes);
  __ asrv(TMP2, temp, TMP, kObjectBytes);
  __ cmp(left, Operand(TMP2), kObjectBytes);
  __ b(normal_ir_body, NE);  // Overflow.
  // Shift for result now we know there is no overflow.
  __ lslv(result, left, TMP, kObjectBytes);
  __ ret();
  __ Bind(normal_ir_body);
}

static void CompareIntegers(Assembler* assembler,
                            Label* normal_ir_body,
                            Condition true_condition) {
  Label true_label;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // R0 contains the right argument, R1 the left.
  __ CompareObjectRegisters(R1, R0);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ LoadObject(TMP, CastHandle<Object>(TrueObject()));
  __ csel(R0, TMP, R0, true_condition);
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
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ ldr(R1, Address(SP, 1 * target::kWordSize));
  __ CompareObjectRegisters(R0, R1);
  __ b(&true_label, EQ);

  __ orr(R2, R0, Operand(R1));
  __ BranchIfNotSmi(R2, &check_for_mint);
  // If R0 or R1 is not a smi do Mint checks.

  // Both arguments are smi, '===' is good enough.
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);

  __ BranchIfNotSmi(R1, &receiver_not_smi);  // Check receiver.

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint never contains a value that can be
  // represented by Smi.

  __ CompareClassId(R0, kDoubleCid);
  __ b(normal_ir_body, EQ);
  __ LoadObject(R0,
                CastHandle<Object>(FalseObject()));  // Smi == Mint -> false.
  __ ret();

  __ Bind(&receiver_not_smi);
  // R1: receiver.

  __ CompareClassId(R1, kMintCid);
  __ b(normal_ir_body, NE);
  // Receiver is Mint, return false if right is Smi.
  __ BranchIfNotSmi(R0, normal_ir_body);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
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
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ SmiUntag(R0);
  // XOR with sign bit to complement bits if value is negative.
#if !defined(DART_COMPRESSED_POINTERS)
  __ eor(R0, R0, Operand(R0, ASR, 63));
  __ clz(R0, R0);
  __ LoadImmediate(R1, 64);
#else
  __ eorw(R0, R0, Operand(R0, ASR, 31));
  __ clzw(R0, R0);
  __ LoadImmediate(R1, 32);
#endif
  __ sub(R0, R1, Operand(R0));
  __ SmiTag(R0);
  __ ret();
}

void AsmIntrinsifier::Bigint_lsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // R2 = x_used, R3 = x_digits, x_used > 0, x_used is Smi.
  __ ldp(R2, R3, Address(SP, 2 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R2, R2);
#endif
  __ add(R2, R2, Operand(2));  // x_used > 0, Smi. R2 = x_used + 1, round up.
  __ AsrImmediate(R2, R2, 2);  // R2 = num of digit pairs to read.
  // R4 = r_digits, R5 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ ldp(R4, R5, Address(SP, 0 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R5, R5);
#endif
  __ SmiUntag(R5);
  // R0 = n ~/ (2*_DIGIT_BITS)
  __ AsrImmediate(R0, R5, 6);
  // R6 = &x_digits[0]
  __ add(R6, R3, Operand(target::TypedData::payload_offset() - kHeapObjectTag));
  // R7 = &x_digits[2*R2]
  __ add(R7, R6, Operand(R2, LSL, 3));
  // R8 = &r_digits[2*1]
  __ add(R8, R4,
         Operand(target::TypedData::payload_offset() - kHeapObjectTag +
                 2 * kBytesPerBigIntDigit));
  // R8 = &r_digits[2*(R2 + n ~/ (2*_DIGIT_BITS) + 1)]
  __ add(R0, R0, Operand(R2));
  __ add(R8, R8, Operand(R0, LSL, 3));
  // R3 = n % (2 * _DIGIT_BITS)
  __ AndImmediate(R3, R5, 63);
  // R2 = 64 - R3
  __ LoadImmediate(R2, 64);
  __ sub(R2, R2, Operand(R3));
  __ mov(R1, ZR);
  Label loop;
  __ Bind(&loop);
  __ ldr(R0, Address(R7, -2 * kBytesPerBigIntDigit, Address::PreIndex));
  __ lsrv(R4, R0, R2);
  __ orr(R1, R1, Operand(R4));
  __ str(R1, Address(R8, -2 * kBytesPerBigIntDigit, Address::PreIndex));
  __ lslv(R1, R0, R3);
  __ cmp(R7, Operand(R6));
  __ b(&loop, NE);
  __ str(R1, Address(R8, -2 * kBytesPerBigIntDigit, Address::PreIndex));
  __ LoadObject(R0, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_rsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _rsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // R2 = x_used, R3 = x_digits, x_used > 0, x_used is Smi.
  __ ldp(R2, R3, Address(SP, 2 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R2, R2);
#endif
  __ add(R2, R2, Operand(2));  // x_used > 0, Smi. R2 = x_used + 1, round up.
  __ AsrImmediate(R2, R2, 2);  // R2 = num of digit pairs to read.
  // R4 = r_digits, R5 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ ldp(R4, R5, Address(SP, 0 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R5, R5);
#endif
  __ SmiUntag(R5);
  // R0 = n ~/ (2*_DIGIT_BITS)
  __ AsrImmediate(R0, R5, 6);
  // R8 = &r_digits[0]
  __ add(R8, R4, Operand(target::TypedData::payload_offset() - kHeapObjectTag));
  // R7 = &x_digits[2*(n ~/ (2*_DIGIT_BITS))]
  __ add(R7, R3, Operand(target::TypedData::payload_offset() - kHeapObjectTag));
  __ add(R7, R7, Operand(R0, LSL, 3));
  // R6 = &r_digits[2*(R2 - n ~/ (2*_DIGIT_BITS) - 1)]
  __ add(R0, R0, Operand(1));
  __ sub(R0, R2, Operand(R0));
  __ add(R6, R8, Operand(R0, LSL, 3));
  // R3 = n % (2*_DIGIT_BITS)
  __ AndImmediate(R3, R5, 63);
  // R2 = 64 - R3
  __ LoadImmediate(R2, 64);
  __ sub(R2, R2, Operand(R3));
  // R1 = x_digits[n ~/ (2*_DIGIT_BITS)] >> (n % (2*_DIGIT_BITS))
  __ ldr(R1, Address(R7, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ lsrv(R1, R1, R3);
  Label loop_entry;
  __ b(&loop_entry);
  Label loop;
  __ Bind(&loop);
  __ ldr(R0, Address(R7, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ lslv(R4, R0, R2);
  __ orr(R1, R1, Operand(R4));
  __ str(R1, Address(R8, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ lsrv(R1, R0, R3);
  __ Bind(&loop_entry);
  __ cmp(R8, Operand(R6));
  __ b(&loop, NE);
  __ str(R1, Address(R8, 0));
  __ LoadObject(R0, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_absAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absAdd(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // R2 = used, R3 = digits
  __ ldp(R2, R3, Address(SP, 3 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R2, R2);
#endif
  __ add(R2, R2, Operand(2));  // used > 0, Smi. R2 = used + 1, round up.
  __ add(R2, ZR, Operand(R2, ASR, 2));  // R2 = num of digit pairs to process.
  // R3 = &digits[0]
  __ add(R3, R3, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R4 = a_used, R5 = a_digits
  __ ldp(R4, R5, Address(SP, 1 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R4, R4);
#endif
  __ add(R4, R4, Operand(2));  // a_used > 0, Smi. R4 = a_used + 1, round up.
  __ add(R4, ZR, Operand(R4, ASR, 2));  // R4 = num of digit pairs to process.
  // R5 = &a_digits[0]
  __ add(R5, R5, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R6 = r_digits
  __ ldr(R6, Address(SP, 0 * target::kWordSize));
  // R6 = &r_digits[0]
  __ add(R6, R6, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R7 = &digits[a_used rounded up to even number].
  __ add(R7, R3, Operand(R4, LSL, 3));

  // R8 = &digits[a_used rounded up to even number].
  __ add(R8, R3, Operand(R2, LSL, 3));

  __ adds(R0, R0, Operand(0));  // carry flag = 0
  Label add_loop;
  __ Bind(&add_loop);
  // Loop (a_used+1)/2 times, a_used > 0.
  __ ldr(R0, Address(R3, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ ldr(R1, Address(R5, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ adcs(R0, R0, R1);
  __ sub(R9, R3, Operand(R7));  // Does not affect carry flag.
  __ str(R0, Address(R6, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ cbnz(&add_loop, R9);  // Does not affect carry flag.

  Label last_carry;
  __ sub(R9, R3, Operand(R8));  // Does not affect carry flag.
  __ cbz(&last_carry, R9);      // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop (used+1)/2 - (a_used+1)/2 times, used - a_used > 0.
  __ ldr(R0, Address(R3, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ adcs(R0, R0, ZR);
  __ sub(R9, R3, Operand(R8));  // Does not affect carry flag.
  __ str(R0, Address(R6, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ cbnz(&carry_loop, R9);

  __ Bind(&last_carry);
  Label done;
  __ b(&done, CC);
  __ LoadImmediate(R0, 1);
  __ str(R0, Address(R6, 0));

  __ Bind(&done);
  __ LoadObject(R0, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_absSub(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absSub(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // R2 = used, R3 = digits
  __ ldp(R2, R3, Address(SP, 3 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R2, R2);
#endif
  __ add(R2, R2, Operand(2));  // used > 0, Smi. R2 = used + 1, round up.
  __ add(R2, ZR, Operand(R2, ASR, 2));  // R2 = num of digit pairs to process.
  // R3 = &digits[0]
  __ add(R3, R3, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R4 = a_used, R5 = a_digits
  __ ldp(R4, R5, Address(SP, 1 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R4, R4);
#endif
  __ add(R4, R4, Operand(2));  // a_used > 0, Smi. R4 = a_used + 1, round up.
  __ add(R4, ZR, Operand(R4, ASR, 2));  // R4 = num of digit pairs to process.
  // R5 = &a_digits[0]
  __ add(R5, R5, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R6 = r_digits
  __ ldr(R6, Address(SP, 0 * target::kWordSize));
  // R6 = &r_digits[0]
  __ add(R6, R6, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R7 = &digits[a_used rounded up to even number].
  __ add(R7, R3, Operand(R4, LSL, 3));

  // R8 = &digits[a_used rounded up to even number].
  __ add(R8, R3, Operand(R2, LSL, 3));

  __ subs(R0, R0, Operand(0));  // carry flag = 1
  Label sub_loop;
  __ Bind(&sub_loop);
  // Loop (a_used+1)/2 times, a_used > 0.
  __ ldr(R0, Address(R3, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ ldr(R1, Address(R5, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ sbcs(R0, R0, R1);
  __ sub(R9, R3, Operand(R7));  // Does not affect carry flag.
  __ str(R0, Address(R6, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ cbnz(&sub_loop, R9);  // Does not affect carry flag.

  Label done;
  __ sub(R9, R3, Operand(R8));  // Does not affect carry flag.
  __ cbz(&done, R9);            // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop (used+1)/2 - (a_used+1)/2 times, used - a_used > 0.
  __ ldr(R0, Address(R3, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ sbcs(R0, R0, ZR);
  __ sub(R9, R3, Operand(R8));  // Does not affect carry flag.
  __ str(R0, Address(R6, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ cbnz(&carry_loop, R9);

  __ Bind(&done);
  __ LoadObject(R0, NullObject());
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
  // R3 = x, no_op if x == 0
  // R0 = xi as Smi, R1 = x_digits.
  __ ldp(R0, R1, Address(SP, 5 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R0, R0);
#endif
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R3, FieldAddress(R1, target::TypedData::payload_offset()));
  __ tst(R3, Operand(R3));
  __ b(&done, EQ);

  // R6 = (SmiUntag(n) + 1)/2, no_op if n == 0
  __ ldr(R6, Address(SP, 0 * target::kWordSize));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R6, R6);
#endif
  __ add(R6, R6, Operand(2));
  __ adds(R6, ZR, Operand(R6, ASR, 2));  // SmiUntag(R6) and set cc.
  __ b(&done, EQ);

  // R4 = mip = &m_digits[i >> 1]
  // R0 = i as Smi, R1 = m_digits.
  __ ldp(R0, R1, Address(SP, 3 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R0, R0);
#endif
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ add(R4, R1, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R5 = ajp = &a_digits[j >> 1]
  // R0 = j as Smi, R1 = a_digits.
  __ ldp(R0, R1, Address(SP, 1 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R0, R0);
#endif
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ add(R5, R1, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R1 = c = 0
  __ mov(R1, ZR);

  Label muladd_loop;
  __ Bind(&muladd_loop);
  // x:   R3
  // mip: R4
  // ajp: R5
  // c:   R1
  // n:   R6
  // t:   R7:R8 (not live at loop entry)

  // uint64_t mi = *mip++
  __ ldr(R2, Address(R4, 2 * kBytesPerBigIntDigit, Address::PostIndex));

  // uint64_t aj = *ajp
  __ ldr(R0, Address(R5, 0));

  // uint128_t t = x*mi + aj + c
  __ mul(R7, R2, R3);    // R7 = low64(R2*R3).
  __ umulh(R8, R2, R3);  // R8 = high64(R2*R3), t = R8:R7 = x*mi.
  __ adds(R7, R7, Operand(R0));
  __ adc(R8, R8, ZR);            // t += aj.
  __ adds(R0, R7, Operand(R1));  // t += c, R0 = low64(t).
  __ adc(R1, R8, ZR);            // c = R1 = high64(t).

  // *ajp++ = low64(t) = R0
  __ str(R0, Address(R5, 2 * kBytesPerBigIntDigit, Address::PostIndex));

  // while (--n > 0)
  __ subs(R6, R6, Operand(1));  // --n
  __ b(&muladd_loop, NE);

  __ tst(R1, Operand(R1));
  __ b(&done, EQ);

  // *ajp++ += c
  __ ldr(R0, Address(R5, 0));
  __ adds(R0, R0, Operand(R1));
  __ str(R0, Address(R5, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ b(&done, CC);

  Label propagate_carry_loop;
  __ Bind(&propagate_carry_loop);
  __ ldr(R0, Address(R5, 0));
  __ adds(R0, R0, Operand(1));
  __ str(R0, Address(R5, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ b(&propagate_carry_loop, CS);

  __ Bind(&done);
  __ LoadImmediate(R0, target::ToRawSmi(2));  // Two digits processed.
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

  // R4 = xip = &x_digits[i >> 1]
  // R2 = i as Smi, R3 = x_digits
  __ ldp(R2, R3, Address(SP, 2 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R2, R2);
#endif
  __ add(R3, R3, Operand(R2, LSL, 1));
  __ add(R4, R3, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R3 = x = *xip++, return if x == 0
  Label x_zero;
  __ ldr(R3, Address(R4, 2 * kBytesPerBigIntDigit, Address::PostIndex));
  __ tst(R3, Operand(R3));
  __ b(&x_zero, EQ);

  // R5 = ajp = &a_digits[i]
  __ ldr(R1, Address(SP, 1 * target::kWordSize));  // a_digits
  __ add(R1, R1, Operand(R2, LSL, 2));             // j == 2*i, i is Smi.
  __ add(R5, R1, Operand(target::TypedData::payload_offset() - kHeapObjectTag));

  // R6:R1 = t = x*x + *ajp
  __ ldr(R0, Address(R5, 0));
  __ mul(R1, R3, R3);            // R1 = low64(R3*R3).
  __ umulh(R6, R3, R3);          // R6 = high64(R3*R3).
  __ adds(R1, R1, Operand(R0));  // R6:R1 += *ajp.
  __ adc(R6, R6, ZR);            // R6 = low64(c) = high64(t).
  __ mov(R7, ZR);                // R7 = high64(c) = 0.

  // *ajp++ = low64(t) = R1
  __ str(R1, Address(R5, 2 * kBytesPerBigIntDigit, Address::PostIndex));

  // int n = (used - i + 1)/2 - 1
  __ ldr(R0, Address(SP, 0 * target::kWordSize));  // used is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R0, R0);
#endif
  __ sub(R8, R0, Operand(R2));
  __ add(R8, R8, Operand(2));
  __ movn(R0, Immediate(1), 0);          // R0 = ~1 = -2.
  __ adds(R8, R0, Operand(R8, ASR, 2));  // while (--n >= 0)

  Label loop, done;
  __ b(&done, MI);

  __ Bind(&loop);
  // x:   R3
  // xip: R4
  // ajp: R5
  // c:   R7:R6
  // t:   R2:R1:R0 (not live at loop entry)
  // n:   R8

  // uint64_t xi = *xip++
  __ ldr(R2, Address(R4, 2 * kBytesPerBigIntDigit, Address::PostIndex));

  // uint192_t t = R2:R1:R0 = 2*x*xi + aj + c
  __ mul(R0, R2, R3);    // R0 = low64(R2*R3) = low64(x*xi).
  __ umulh(R1, R2, R3);  // R1 = high64(R2*R3) = high64(x*xi).
  __ adds(R0, R0, Operand(R0));
  __ adcs(R1, R1, R1);
  __ adc(R2, ZR, ZR);  // R2:R1:R0 = R1:R0 + R1:R0 = 2*x*xi.
  __ adds(R0, R0, Operand(R6));
  __ adcs(R1, R1, R7);
  __ adc(R2, R2, ZR);          // R2:R1:R0 += c.
  __ ldr(R7, Address(R5, 0));  // R7 = aj = *ajp.
  __ adds(R0, R0, Operand(R7));
  __ adcs(R6, R1, ZR);
  __ adc(R7, R2, ZR);  // R7:R6:R0 = 2*x*xi + aj + c.

  // *ajp++ = low64(t) = R0
  __ str(R0, Address(R5, 2 * kBytesPerBigIntDigit, Address::PostIndex));

  // while (--n >= 0)
  __ subs(R8, R8, Operand(1));  // --n
  __ b(&loop, PL);

  __ Bind(&done);
  // uint64_t aj = *ajp
  __ ldr(R0, Address(R5, 0));

  // uint128_t t = aj + c
  __ adds(R6, R6, Operand(R0));
  __ adc(R7, R7, ZR);

  // *ajp = low64(t) = R6
  // *(ajp + 1) = high64(t) = R7
  __ stp(R6, R7, Address(R5, 0, Address::PairOffset));

  __ Bind(&x_zero);
  __ LoadImmediate(R0, target::ToRawSmi(2));  // Two digits processed.
  __ ret();
}

void AsmIntrinsifier::Bigint_estimateQuotientDigit(Assembler* assembler,
                                                   Label* normal_ir_body) {
  // There is no 128-bit by 64-bit division instruction on arm64, so we use two
  // 64-bit by 32-bit divisions and two 64-bit by 64-bit multiplications to
  // adjust the two 32-bit digits of the estimated quotient.
  //
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
  //     // We cannot calculate qd = dh:dl / yt, so ...
  //     uint64_t yth = yt >> 32;
  //     uint64_t qh = dh / yth;
  //     uint128_t ph:pl = yt*qh;
  //     uint64_t tl = (dh << 32)|(dl >> 32);
  //     uint64_t th = dh >> 32;
  //     while ((ph > th) || ((ph == th) && (pl > tl))) {
  //       if (pl < yt) --ph;
  //       pl -= yt;
  //       --qh;
  //     }
  //     qd = qh << 32;
  //     tl = (pl << 32);
  //     th = (ph << 32)|(pl >> 32);
  //     if (tl > dl) ++th;
  //     dl -= tl;
  //     dh -= th;
  //     uint64_t ql = ((dh << 32)|(dl >> 32)) / yth;
  //     ph:pl = yt*ql;
  //     while ((ph > dh) || ((ph == dh) && (pl > dl))) {
  //       if (pl < yt) --ph;
  //       pl -= yt;
  //       --ql;
  //     }
  //     qd |= ql;
  //   }
  //   args[_QD .. _QD_HI] = qd;  // _QD == 2, _QD_HI == 3.
  //   return 2;
  // }

  // R4 = args
  __ ldr(R4, Address(SP, 2 * target::kWordSize));  // args

  // R3 = yt = args[0..1]
  __ ldr(R3, FieldAddress(R4, target::TypedData::payload_offset()));

  // R2 = dh = digits[(i >> 1) - 1 .. i >> 1]
  // R0 = i as Smi, R1 = digits
  __ ldp(R0, R1, Address(SP, 0 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R0, R0);
#endif
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R2, FieldAddress(R1, target::TypedData::payload_offset() -
                                  kBytesPerBigIntDigit));

  // R0 = qd = (DIGIT_MASK << 32) | DIGIT_MASK = -1
  __ movn(R0, Immediate(0), 0);

  // Return qd if dh == yt
  Label return_qd;
  __ cmp(R2, Operand(R3));
  __ b(&return_qd, EQ);

  // R1 = dl = digits[(i >> 1) - 3 .. (i >> 1) - 2]
  __ ldr(R1, FieldAddress(R1, target::TypedData::payload_offset() -
                                  3 * kBytesPerBigIntDigit));

  // R5 = yth = yt >> 32
  __ orr(R5, ZR, Operand(R3, LSR, 32));

  // R6 = qh = dh / yth
  __ udiv(R6, R2, R5);

  // R8:R7 = ph:pl = yt*qh
  __ mul(R7, R3, R6);
  __ umulh(R8, R3, R6);

  // R9 = tl = (dh << 32)|(dl >> 32)
  __ orr(R9, ZR, Operand(R2, LSL, 32));
  __ orr(R9, R9, Operand(R1, LSR, 32));

  // R10 = th = dh >> 32
  __ orr(R10, ZR, Operand(R2, LSR, 32));

  // while ((ph > th) || ((ph == th) && (pl > tl)))
  Label qh_adj_loop, qh_adj, qh_ok;
  __ Bind(&qh_adj_loop);
  __ cmp(R8, Operand(R10));
  __ b(&qh_adj, HI);
  __ b(&qh_ok, NE);
  __ cmp(R7, Operand(R9));
  __ b(&qh_ok, LS);

  __ Bind(&qh_adj);
  // if (pl < yt) --ph
  __ sub(TMP, R8, Operand(1));  // TMP = ph - 1
  __ cmp(R7, Operand(R3));
  __ csel(R8, TMP, R8, CC);  // R8 = R7 < R3 ? TMP : R8

  // pl -= yt
  __ sub(R7, R7, Operand(R3));

  // --qh
  __ sub(R6, R6, Operand(1));

  // Continue while loop.
  __ b(&qh_adj_loop);

  __ Bind(&qh_ok);
  // R0 = qd = qh << 32
  __ orr(R0, ZR, Operand(R6, LSL, 32));

  // tl = (pl << 32)
  __ orr(R9, ZR, Operand(R7, LSL, 32));

  // th = (ph << 32)|(pl >> 32);
  __ orr(R10, ZR, Operand(R8, LSL, 32));
  __ orr(R10, R10, Operand(R7, LSR, 32));

  // if (tl > dl) ++th
  __ add(TMP, R10, Operand(1));  // TMP = th + 1
  __ cmp(R9, Operand(R1));
  __ csel(R10, TMP, R10, HI);  // R10 = R9 > R1 ? TMP : R10

  // dl -= tl
  __ sub(R1, R1, Operand(R9));

  // dh -= th
  __ sub(R2, R2, Operand(R10));

  // R6 = ql = ((dh << 32)|(dl >> 32)) / yth
  __ orr(R6, ZR, Operand(R2, LSL, 32));
  __ orr(R6, R6, Operand(R1, LSR, 32));
  __ udiv(R6, R6, R5);

  // R8:R7 = ph:pl = yt*ql
  __ mul(R7, R3, R6);
  __ umulh(R8, R3, R6);

  // while ((ph > dh) || ((ph == dh) && (pl > dl))) {
  Label ql_adj_loop, ql_adj, ql_ok;
  __ Bind(&ql_adj_loop);
  __ cmp(R8, Operand(R2));
  __ b(&ql_adj, HI);
  __ b(&ql_ok, NE);
  __ cmp(R7, Operand(R1));
  __ b(&ql_ok, LS);

  __ Bind(&ql_adj);
  // if (pl < yt) --ph
  __ sub(TMP, R8, Operand(1));  // TMP = ph - 1
  __ cmp(R7, Operand(R3));
  __ csel(R8, TMP, R8, CC);  // R8 = R7 < R3 ? TMP : R8

  // pl -= yt
  __ sub(R7, R7, Operand(R3));

  // --ql
  __ sub(R6, R6, Operand(1));

  // Continue while loop.
  __ b(&ql_adj_loop);

  __ Bind(&ql_ok);
  // qd |= ql;
  __ orr(R0, R0, Operand(R6));

  __ Bind(&return_qd);
  // args[2..3] = qd
  __ str(R0, FieldAddress(R4, target::TypedData::payload_offset() +
                                  2 * kBytesPerBigIntDigit));

  __ LoadImmediate(R0, target::ToRawSmi(2));  // Two digits processed.
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

  // R4 = args
  __ ldr(R4, Address(SP, 2 * target::kWordSize));  // args

  // R3 = rho = args[2..3]
  __ ldr(R3, FieldAddress(R4, target::TypedData::payload_offset() +
                                  2 * kBytesPerBigIntDigit));

  // R2 = digits[i >> 1 .. (i >> 1) + 1]
  // R0 = i as Smi, R1 = digits
  __ ldp(R0, R1, Address(SP, 0 * target::kWordSize, Address::PairOffset));
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R0, R0);
#endif
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R2, FieldAddress(R1, target::TypedData::payload_offset()));

  // R0 = rho*d mod DIGIT_BASE
  __ mul(R0, R2, R3);  // R0 = low64(R2*R3).

  // args[4 .. 5] = R0
  __ str(R0, FieldAddress(R4, target::TypedData::payload_offset() +
                                  4 * kBytesPerBigIntDigit));

  __ LoadImmediate(R0, target::ToRawSmi(2));  // Two digits processed.
  __ ret();
}

// Check if the last argument is a double, jump to label 'is_smi' if smi
// (easy to convert to double), otherwise jump to label 'not_double_smi',
// Returns the last argument in R0.
static void TestLastArgumentIsDouble(Assembler* assembler,
                                     Label* is_smi,
                                     Label* not_double_smi) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ BranchIfSmi(R0, is_smi);
  __ CompareClassId(R0, kDoubleCid);
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
  Label is_smi, double_op, not_nan;

  TestLastArgumentIsDouble(assembler, &is_smi, normal_ir_body);
  // Both arguments are double, right operand is in R0.

  __ LoadDFieldFromOffset(V1, R0, target::Double::value_offset());
  __ Bind(&double_op);
  __ ldr(R0, Address(SP, 1 * target::kWordSize));  // Left argument.
  __ LoadDFieldFromOffset(V0, R0, target::Double::value_offset());

  __ fcmpd(V0, V1);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  // Return false if D0 or D1 was NaN before checking true condition.
  __ b(&not_nan, VC);
  __ ret();
  __ Bind(&not_nan);
  __ LoadObject(TMP, CastHandle<Object>(TrueObject()));
  __ csel(R0, TMP, R0, true_condition);
  __ ret();

  __ Bind(&is_smi);  // Convert R0 to a double.
  __ SmiUntag(R0);
  __ scvtfdx(V1, R0);
  __ b(&double_op);  // Then do the comparison.
  __ Bind(normal_ir_body);
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
  Label is_smi, double_op;

  TestLastArgumentIsDouble(assembler, &is_smi, normal_ir_body);
  // Both arguments are double, right operand is in R0.
  __ LoadDFieldFromOffset(V1, R0, target::Double::value_offset());
  __ Bind(&double_op);
  __ ldr(R0, Address(SP, 1 * target::kWordSize));  // Left argument.
  __ LoadDFieldFromOffset(V0, R0, target::Double::value_offset());
  switch (kind) {
    case Token::kADD:
      __ faddd(V0, V0, V1);
      break;
    case Token::kSUB:
      __ fsubd(V0, V0, V1);
      break;
    case Token::kMUL:
      __ fmuld(V0, V0, V1);
      break;
    case Token::kDIV:
      __ fdivd(V0, V0, V1);
      break;
    default:
      UNREACHABLE();
  }
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kFarJump, R0, R1);
  __ StoreDFieldToOffset(V0, R0, target::Double::value_offset());
  __ ret();

  __ Bind(&is_smi);  // Convert R0 to a double.
  __ SmiUntag(R0);
  __ scvtfdx(V1, R0);
  __ b(&double_op);

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
  // Only smis allowed.
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ BranchIfNotSmi(R0, normal_ir_body);
  // Is Smi.
  __ SmiUntag(R0);
  __ scvtfdx(V1, R0);
  __ ldr(R0, Address(SP, 1 * target::kWordSize));
  __ LoadDFieldFromOffset(V0, R0, target::Double::value_offset());
  __ fmuld(V0, V0, V1);
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kNearJump, R0, R1);
  __ StoreDFieldToOffset(V0, R0, target::Double::value_offset());
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::DoubleFromInteger(Assembler* assembler,
                                        Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ BranchIfNotSmi(R0, normal_ir_body);
  // Is Smi.
  __ SmiUntag(R0);
#if !defined(DART_COMPRESSED_POINTERS)
  __ scvtfdx(V0, R0);
#else
  __ scvtfdw(V0, R0);
#endif
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kNearJump, R0, R1);
  __ StoreDFieldToOffset(V0, R0, target::Double::value_offset());
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_getIsNaN(Assembler* assembler,
                                      Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ LoadDFieldFromOffset(V0, R0, target::Double::value_offset());
  __ fcmpd(V0, V0);
  __ LoadObject(TMP, CastHandle<Object>(FalseObject()));
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ csel(R0, TMP, R0, VC);
  __ ret();
}

void AsmIntrinsifier::Double_getIsInfinite(Assembler* assembler,
                                           Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ LoadFieldFromOffset(R0, R0, target::Double::value_offset());
  // Mask off the sign.
  __ AndImmediate(R0, R0, 0x7FFFFFFFFFFFFFFFLL);
  // Compare with +infinity.
  __ CompareImmediate(R0, 0x7FF0000000000000LL);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ LoadObject(TMP, CastHandle<Object>(TrueObject()));
  __ csel(R0, TMP, R0, EQ);
  __ ret();
}

void AsmIntrinsifier::Double_getIsNegative(Assembler* assembler,
                                           Label* normal_ir_body) {
  const Register false_reg = R0;
  const Register true_reg = R2;
  Label is_false, is_true, is_zero;

  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ LoadDFieldFromOffset(V0, R0, target::Double::value_offset());
  __ fcmpdz(V0);
  __ LoadObject(true_reg, CastHandle<Object>(TrueObject()));
  __ LoadObject(false_reg, CastHandle<Object>(FalseObject()));
  __ b(&is_false, VS);  // NaN -> false.
  __ b(&is_zero, EQ);   // Check for negative zero.
  __ b(&is_false, CS);  // >= 0 -> false.

  __ Bind(&is_true);
  __ mov(R0, true_reg);

  __ Bind(&is_false);
  __ ret();

  __ Bind(&is_zero);
  // Check for negative zero by looking at the sign bit.
  __ fmovrd(R1, V0);
  __ LsrImmediate(R1, R1, 63);
  __ tsti(R1, Immediate(1));
  __ csel(R0, true_reg, false_reg, NE);  // Sign bit set.
  __ ret();
}

void AsmIntrinsifier::ObjectEquals(Assembler* assembler,
                                   Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ ldr(R1, Address(SP, 1 * target::kWordSize));
  __ CompareObjectRegisters(R0, R1);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ LoadObject(TMP, CastHandle<Object>(TrueObject()));
  __ csel(R0, TMP, R0, EQ);
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
  assembler->RangeCheck(cid, tmp, kOneByteStringCid, kExternalTwoByteStringCid,
                        Assembler::kIfInRange, target);
}

static void JumpIfNotString(Assembler* assembler,
                            Register cid,
                            Register tmp,
                            Label* target) {
  assembler->RangeCheck(cid, tmp, kOneByteStringCid, kExternalTwoByteStringCid,
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
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ LoadClassIdMayBeSmi(R1, R0);

  __ CompareImmediate(R1, kClosureCid);
  __ b(normal_ir_body, EQ);  // Instance is a closure.

  __ CompareImmediate(R1, kRecordCid);
  __ b(normal_ir_body, EQ);  // Instance is a record.

  __ CompareImmediate(R1, kNumPredefinedCids);
  __ b(&use_declaration_type, HI);

  __ LoadIsolateGroup(R2);
  __ LoadFromOffset(R2, R2, target::IsolateGroup::object_store_offset());

  __ CompareImmediate(R1, kDoubleCid);
  __ b(&not_double, NE);
  __ LoadFromOffset(R0, R2, target::ObjectStore::double_type_offset());
  __ ret();

  __ Bind(&not_double);
  JumpIfNotInteger(assembler, R1, R0, &not_integer);
  __ LoadFromOffset(R0, R2, target::ObjectStore::int_type_offset());
  __ ret();

  __ Bind(&not_integer);
  JumpIfNotString(assembler, R1, R0, &not_string);
  __ LoadFromOffset(R0, R2, target::ObjectStore::string_type_offset());
  __ ret();

  __ Bind(&not_string);
  JumpIfNotType(assembler, R1, R0, &use_declaration_type);
  __ LoadFromOffset(R0, R2, target::ObjectStore::type_type_offset());
  __ ret();

  __ Bind(&use_declaration_type);
  __ LoadClassById(R2, R1);
  __ ldr(R3, FieldAddress(R2, target::Class::num_type_arguments_offset()),
         kTwoBytes);
  __ cbnz(normal_ir_body, R3);

  __ LoadCompressed(R0,
                    FieldAddress(R2, target::Class::declaration_type_offset()));
  __ CompareObject(R0, NullObject());
  __ b(normal_ir_body, EQ);
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
  __ b(normal_ir_body, EQ);

  // Check if left hand side is a record. Records are handled in the runtime.
  __ CompareImmediate(cid1, kRecordCid);
  __ b(normal_ir_body, EQ);

  // Check whether class ids match. If class ids don't match types may still be
  // considered equivalent (e.g. multiple string implementation classes map to a
  // single String type).
  __ cmp(cid1, Operand(cid2));
  __ b(equal_may_be_generic, EQ);

  // Class ids are different. Check if we are comparing two string types (with
  // different representations), two integer types, two list types or two type
  // types.
  __ CompareImmediate(cid1, kNumPredefinedCids);
  __ b(not_equal, HI);

  // Check if both are integer types.
  JumpIfNotInteger(assembler, cid1, scratch, &not_integer);

  // First type is an integer. Check if the second is an integer too.
  JumpIfInteger(assembler, cid2, scratch, equal_not_generic);
  // Integer types are only equivalent to other integer types.
  __ b(not_equal);

  __ Bind(&not_integer);
  // Check if both are String types.
  JumpIfNotString(assembler, cid1, scratch,
                  testing_instance_cids ? &not_integer_or_string : not_equal);

  // First type is String. Check if the second is a string too.
  JumpIfString(assembler, cid2, scratch, equal_not_generic);
  // String types are only equivalent to other String types.
  __ b(not_equal);

  if (testing_instance_cids) {
    __ Bind(&not_integer_or_string);
    // Check if both are List types.
    JumpIfNotList(assembler, cid1, scratch, &not_integer_or_string_or_list);

    // First type is a List. Check if the second is a List too.
    JumpIfNotList(assembler, cid2, scratch, not_equal);
    ASSERT(compiler::target::Array::type_arguments_offset() ==
           compiler::target::GrowableObjectArray::type_arguments_offset());
    __ b(equal_may_be_generic);

    __ Bind(&not_integer_or_string_or_list);
    // Check if the first type is a Type. If it is not then types are not
    // equivalent because they have different class ids and they are not String
    // or integer or List or Type.
    JumpIfNotType(assembler, cid1, scratch, not_equal);

    // First type is a Type. Check if the second is a Type too.
    JumpIfType(assembler, cid2, scratch, equal_not_generic);
    // Type types are only equivalent to other Type types.
    __ b(not_equal);
  }
}

void AsmIntrinsifier::ObjectHaveSameRuntimeType(Assembler* assembler,
                                                Label* normal_ir_body) {
  __ ldp(R0, R1, Address(SP, 0 * target::kWordSize, Address::PairOffset));
  __ LoadClassIdMayBeSmi(R2, R1);
  __ LoadClassIdMayBeSmi(R1, R0);

  Label equal_may_be_generic, equal, not_equal;
  EquivalentClassIds(assembler, normal_ir_body, &equal_may_be_generic, &equal,
                     &not_equal, R1, R2, R0,
                     /* testing_instance_cids = */ true);

  __ Bind(&equal_may_be_generic);
  // Classes are equivalent and neither is a closure class.
  // Check if there are no type arguments. In this case we can return true.
  // Otherwise fall through into the runtime to handle comparison.
  __ LoadClassById(R0, R1);
  __ ldr(R0,
         FieldAddress(
             R0,
             target::Class::host_type_arguments_field_offset_in_words_offset()),
         kFourBytes);
  __ CompareImmediate(R0, target::Class::kNoTypeArguments);
  __ b(&equal, EQ);

  // Compare type arguments, host_type_arguments_field_offset_in_words in R0.
  __ ldp(R1, R2, Address(SP, 0 * target::kWordSize, Address::PairOffset));
  __ AddImmediate(R1, -kHeapObjectTag);
  __ ldr(R1, Address(R1, R0, UXTX, Address::Scaled), kObjectBytes);
  __ AddImmediate(R2, -kHeapObjectTag);
  __ ldr(R2, Address(R2, R0, UXTX, Address::Scaled), kObjectBytes);
  __ CompareObjectRegisters(R1, R2);
  __ b(normal_ir_body, NE);
  // Fall through to equal case if type arguments are equal.

  __ Bind(&equal);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ Ret();

  __ Bind(&not_equal);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::String_getHashCode(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ ldr(R0, FieldAddress(R0, target::String::hash_offset()),
         kUnsignedFourBytes);
  __ adds(R0, R0, Operand(R0));  // Smi tag the hash code, setting Z flag.
  __ b(normal_ir_body, EQ);
  __ ret();
  // Hash not yet computed.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Type_getHashCode(Assembler* assembler,
                                       Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ LoadCompressedSmi(R0, FieldAddress(R0, target::Type::hash_offset()));
  __ cbz(normal_ir_body, R0, kObjectBytes);
  __ ret();
  // Hash not yet computed.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Type_equality(Assembler* assembler,
                                    Label* normal_ir_body) {
  Label equal, not_equal, equiv_cids_may_be_generic, equiv_cids, check_legacy;

  __ ldp(R1, R2, Address(SP, 0 * target::kWordSize, Address::PairOffset));
  __ CompareObjectRegisters(R1, R2);
  __ b(&equal, EQ);

  // R1 might not be a Type object, so check that first (R2 should be though,
  // since this is a method on the Type class).
  __ LoadClassIdMayBeSmi(R0, R1);
  __ CompareImmediate(R0, kTypeCid);
  __ b(normal_ir_body, NE);

  // Check if types are syntactically equal.
  __ LoadTypeClassId(R3, R1);
  __ LoadTypeClassId(R4, R2);
  // We are not testing instance cids, but type class cids of Type instances.
  EquivalentClassIds(assembler, normal_ir_body, &equiv_cids_may_be_generic,
                     &equiv_cids, &not_equal, R3, R4, R0,
                     /* testing_instance_cids = */ false);

  __ Bind(&equiv_cids_may_be_generic);
  // Compare type arguments in Type instances.
  __ LoadCompressed(R3, FieldAddress(R1, target::Type::arguments_offset()));
  __ LoadCompressed(R4, FieldAddress(R2, target::Type::arguments_offset()));
  __ CompareObjectRegisters(R3, R4);
  __ b(normal_ir_body, NE);
  // Fall through to check nullability if type arguments are equal.

  // Check nullability.
  __ Bind(&equiv_cids);
  __ LoadAbstractTypeNullability(R1, R1);
  __ LoadAbstractTypeNullability(R2, R2);
  __ cmp(R1, Operand(R2));
  __ b(&check_legacy, NE);
  // Fall through to equal case if nullability is strictly equal.

  __ Bind(&equal);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ ret();

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
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AbstractType_getHashCode(Assembler* assembler,
                                               Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ LoadCompressedSmi(R0,
                       FieldAddress(R0, target::FunctionType::hash_offset()));
  __ cbz(normal_ir_body, R0, kObjectBytes);
  __ ret();
  // Hash not yet computed.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AbstractType_equality(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ ldp(R1, R2, Address(SP, 0 * target::kWordSize, Address::PairOffset));
  __ CompareObjectRegisters(R1, R2);
  __ b(normal_ir_body, NE);

  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

// Keep in sync with Instance::IdentityHashCode.
// Note int and double never reach here because they override _identityHashCode.
// Special cases are also not needed for null or bool because they were pre-set
// during VM isolate finalization.
void AsmIntrinsifier::Object_getHash(Assembler* assembler,
                                     Label* normal_ir_body) {
  Label not_yet_computed;
  __ ldr(R0, Address(SP, 0 * target::kWordSize));  // Object.
  __ ldr(
      R0,
      FieldAddress(R0, target::Object::tags_offset() +
                           target::UntaggedObject::kHashTagPos / kBitsPerByte),
      kUnsignedFourBytes);
  __ cbz(&not_yet_computed, R0);
  __ SmiTag(R0);
  __ ret();

  __ Bind(&not_yet_computed);
  __ LoadFromOffset(R1, THR, target::Thread::random_offset());
  __ AndImmediate(R2, R1, 0xffffffff);  // state_lo
  __ LsrImmediate(R3, R1, 32);          // state_hi
  __ LoadImmediate(R1, 0xffffda61);     // A
  __ mul(R1, R1, R2);
  __ add(R1, R1, Operand(R3));  // new_state = (A * state_lo) + state_hi
  __ StoreToOffset(R1, THR, target::Thread::random_offset());
  __ AndImmediate(R1, R1, 0x3fffffff);
  __ cbz(&not_yet_computed, R1);

  __ ldr(R0, Address(SP, 0 * target::kWordSize));  // Object.
  __ sub(R0, R0, Operand(kHeapObjectTag));
  __ LslImmediate(R3, R1, target::UntaggedObject::kHashTagPos);

  Label retry, already_set_in_r4;
  __ Bind(&retry);
  __ ldxr(R2, R0, kEightBytes);
  __ LsrImmediate(R4, R2, target::UntaggedObject::kHashTagPos);
  __ cbnz(&already_set_in_r4, R4);
  __ orr(R2, R2, Operand(R3));
  __ stxr(R4, R2, R0, kEightBytes);
  __ cbnz(&retry, R4);
  // Fall-through with R1 containing new hash value (untagged).
  __ SmiTag(R0, R1);
  __ ret();
  __ Bind(&already_set_in_r4);
  __ clrex();
  __ SmiTag(R0, R4);
  __ ret();
}

void GenerateSubstringMatchesSpecialization(Assembler* assembler,
                                            intptr_t receiver_cid,
                                            intptr_t other_cid,
                                            Label* return_true,
                                            Label* return_false) {
  __ SmiUntag(R1);
  __ LoadCompressedSmi(
      R8, FieldAddress(R0, target::String::length_offset()));  // this.length
  __ SmiUntag(R8);
  __ LoadCompressedSmi(
      R9, FieldAddress(R2, target::String::length_offset()));  // other.length
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

  // this.codeUnitAt(i + start)
  __ ldr(R10, Address(R0, 0),
         receiver_cid == kOneByteStringCid ? kUnsignedByte : kUnsignedTwoBytes);
  // other.codeUnitAt(i)
  __ ldr(R11, Address(R2, 0),
         other_cid == kOneByteStringCid ? kUnsignedByte : kUnsignedTwoBytes);
  __ cmp(R10, Operand(R11));
  __ b(return_false, NE);

  // i++, while (i < len)
  __ add(R3, R3, Operand(1));
  __ add(R0, R0, Operand(receiver_cid == kOneByteStringCid ? 1 : 2));
  __ add(R2, R2, Operand(other_cid == kOneByteStringCid ? 1 : 2));
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

  __ BranchIfNotSmi(R1, normal_ir_body);

  __ CompareClassId(R2, kOneByteStringCid);
  __ b(normal_ir_body, NE);

  __ CompareClassId(R0, kOneByteStringCid);
  __ b(normal_ir_body, NE);

  GenerateSubstringMatchesSpecialization(assembler, kOneByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&try_two_byte);
  __ CompareClassId(R0, kTwoByteStringCid);
  __ b(normal_ir_body, NE);

  GenerateSubstringMatchesSpecialization(assembler, kTwoByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&return_true);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(&return_false);
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseCharAt(Assembler* assembler,
                                       Label* normal_ir_body) {
  Label try_two_byte_string;

  __ ldr(R1, Address(SP, 0 * target::kWordSize));  // Index.
  __ ldr(R0, Address(SP, 1 * target::kWordSize));  // String.
  __ BranchIfNotSmi(R1, normal_ir_body);           // Index is not a Smi.
  // Range check.
  __ LoadCompressedSmi(R2, FieldAddress(R0, target::String::length_offset()));
  __ cmp(R1, Operand(R2));
  __ b(normal_ir_body, CS);  // Runtime throws exception.

  __ CompareClassId(R0, kOneByteStringCid);
  __ b(&try_two_byte_string, NE);
  __ SmiUntag(R1);
  __ AddImmediate(R0, target::OneByteString::data_offset() - kHeapObjectTag);
  __ ldr(R1, Address(R0, R1), kUnsignedByte);
  __ CompareImmediate(R1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ b(normal_ir_body, GE);
  __ ldr(R0, Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ AddImmediate(
      R0, target::Symbols::kNullCharCodeSymbolOffset * target::kWordSize);
  __ ldr(R0, Address(R0, R1, UXTX, Address::Scaled));
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(R0, kTwoByteStringCid);
  __ b(normal_ir_body, NE);
  ASSERT(kSmiTagShift == 1);
  __ AddImmediate(R0, target::TwoByteString::data_offset() - kHeapObjectTag);
#if !defined(DART_COMPRESSED_POINTERS)
  __ ldr(R1, Address(R0, R1), kUnsignedTwoBytes);
#else
  // Upper half of a compressed Smi is garbage.
  __ ldr(R1, Address(R0, R1, SXTW, Address::Unscaled), kUnsignedTwoBytes);
#endif
  __ CompareImmediate(R1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ b(normal_ir_body, GE);
  __ ldr(R0, Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ AddImmediate(
      R0, target::Symbols::kNullCharCodeSymbolOffset * target::kWordSize);
  __ ldr(R0, Address(R0, R1, UXTX, Address::Scaled));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseIsEmpty(Assembler* assembler,
                                        Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 0 * target::kWordSize));
  __ LoadCompressedSmi(R0, FieldAddress(R0, target::String::length_offset()));
  __ cmp(R0, Operand(target::ToRawSmi(0)), kObjectBytes);
  __ LoadObject(R0, CastHandle<Object>(TrueObject()));
  __ LoadObject(TMP, CastHandle<Object>(FalseObject()));
  __ csel(R0, TMP, R0, NE);
  __ ret();
}

void AsmIntrinsifier::OneByteString_getHashCode(Assembler* assembler,
                                                Label* normal_ir_body) {
  Label compute_hash;
  __ ldr(R1, Address(SP, 0 * target::kWordSize));  // OneByteString object.
  __ ldr(R0, FieldAddress(R1, target::String::hash_offset()),
         kUnsignedFourBytes);
  __ adds(R0, R0, Operand(R0));  // Smi tag the hash code, setting Z flag.
  __ b(&compute_hash, EQ);
  __ ret();  // Return if already computed.

  __ Bind(&compute_hash);
  __ LoadCompressedSmi(R2, FieldAddress(R1, target::String::length_offset()));
  __ SmiUntag(R2);

  __ mov(R3, ZR);
  __ AddImmediate(R6, R1,
                  target::OneByteString::data_offset() - kHeapObjectTag);
  // R1: Instance of OneByteString.
  // R2: String length, untagged integer.
  // R3: Loop counter, untagged integer.
  // R6: String data.
  // R0: Hash code, untagged integer.

  Label loop, done;
  __ Bind(&loop);
  __ cmp(R3, Operand(R2));
  __ b(&done, EQ);
  // Add to hash code: (hash_ is uint32)
  // Get one characters (ch).
  __ ldr(R7, Address(R6, R3), kUnsignedByte);
  // R7: ch.
  __ add(R3, R3, Operand(1));
  __ CombineHashes(R0, R7);
  __ cmp(R3, Operand(R2));
  __ b(&loop);

  __ Bind(&done);
  // Finalize. Allow a zero result to combine checks from empty string branch.
  __ FinalizeHashForSize(target::String::kHashBits, R0);

  // R1: Untagged address of header word (ldxr/stxr do not support offsets).
  __ sub(R1, R1, Operand(kHeapObjectTag));
  __ LslImmediate(R0, R0, target::UntaggedObject::kHashTagPos);
  Label retry;
  __ Bind(&retry);
  __ ldxr(R2, R1, kEightBytes);
  __ orr(R2, R2, Operand(R0));
  __ stxr(R4, R2, R1, kEightBytes);
  __ cbnz(&retry, R4);

  __ LsrImmediate(R0, R0, target::UntaggedObject::kHashTagPos);
  __ SmiTag(R0);
  __ ret();
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
  // negative length: call to runtime to produce error.
  __ tbnz(failure, length_reg, compiler::target::kBitsPerWord - 1);

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, failure, R0));
  __ mov(R6, length_reg);  // Save the length register.
  if (cid == kOneByteStringCid) {
    // Untag length.
    __ SmiUntag(length_reg, length_reg);
  } else {
    // Untag length and multiply by element size -> no-op.
    ASSERT(kSmiTagSize == 1);
  }
  const intptr_t fixed_size_plus_alignment_padding =
      target::String::InstanceSize() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ AddImmediate(length_reg, fixed_size_plus_alignment_padding);
  __ andi(length_reg, length_reg,
          Immediate(~(target::ObjectAlignment::kObjectAlignment - 1)));

  __ ldr(R0, Address(THR, target::Thread::top_offset()));

  // length_reg: allocation size.
  __ adds(R1, R0, Operand(length_reg));
  __ b(failure, CS);  // Fail on unsigned overflow.

  // Check if the allocation fits into the remaining space.
  // R0: potential new object start.
  // R1: potential next object start.
  // R2: allocation size.
  __ ldr(R7, Address(THR, target::Thread::end_offset()));
  __ cmp(R1, Operand(R7));
  __ b(failure, CS);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ str(R1, Address(THR, target::Thread::top_offset()));
  __ AddImmediate(R0, kHeapObjectTag);
  // Clear last double word to ensure string comparison doesn't need to
  // specially handle remainder of strings with lengths not factors of double
  // offsets.
  __ stp(ZR, ZR, Address(R1, -2 * target::kWordSize, Address::PairOffset));

  // Initialize the tags.
  // R0: new object start as a tagged pointer.
  // R1: new object end address.
  // R2: allocation size.
  {
    const intptr_t shift = target::UntaggedObject::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2;

    __ CompareImmediate(R2, target::UntaggedObject::kSizeTagMaxSizeTag);
    __ LslImmediate(R2, R2, shift);
    __ csel(R2, R2, ZR, LS);

    // Get the class index and insert it into the tags.
    // R2: size and bit tags.
    // This also clears the hash, which is in the high word of the tags.
    const uword tags =
        target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
    __ LoadImmediate(TMP, tags);
    __ orr(R2, R2, Operand(TMP));
    __ str(R2, FieldAddress(R0, target::Object::tags_offset()));  // Store tags.
  }

#if DART_COMPRESSED_POINTERS
  // Clear out padding caused by alignment gap between length and data.
  __ str(ZR, FieldAddress(R0, target::String::length_offset()));
#endif
  // Set the length field using the saved length (R6).
  __ StoreCompressedIntoObjectNoBarrier(
      R0, FieldAddress(R0, target::String::length_offset()), R6);
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
  __ BranchIfNotSmi(R3, normal_ir_body);  // 'start', 'end' not Smi.

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
  // R6: Pointer into R3.
  // R7: Pointer into R0.
  // R1: Scratch register.
  Label loop, done;
  __ cmp(R2, Operand(0));
  __ b(&done, LE);
  __ mov(R6, R3);
  __ mov(R7, R0);
  __ Bind(&loop);
  __ ldr(R1, Address(R6), kUnsignedByte);
  __ AddImmediate(R6, 1);
  __ sub(R2, R2, Operand(1));
  __ cmp(R2, Operand(0));
  __ str(R1, FieldAddress(R7, target::OneByteString::data_offset()),
         kUnsignedByte);
  __ AddImmediate(R7, 1);
  __ b(&loop, GT);

  __ Bind(&done);
  __ ret();
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
  __ str(R2, Address(R3, R1), kUnsignedByte);
  __ ret();
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
#if !defined(DART_COMPRESSED_POINTERS)
  __ str(R2, Address(R3, R1), kUnsignedTwoBytes);
#else
  // Upper half of a compressed Smi is garbage.
  __ str(R2, Address(R3, R1, SXTW, Address::Unscaled), kUnsignedTwoBytes);
#endif
  __ ret();
}

void AsmIntrinsifier::AllocateOneByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  Label ok;

  __ ldr(R2, Address(SP, 0 * target::kWordSize));  // Length.
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R2, R2);
#endif
  TryAllocateString(assembler, kOneByteStringCid, &ok, normal_ir_body);

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AllocateTwoByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  Label ok;

  __ ldr(R2, Address(SP, 0 * target::kWordSize));  // Length.
#if defined(DART_COMPRESSED_POINTERS)
  __ sxtw(R2, R2);
#endif
  TryAllocateString(assembler, kTwoByteStringCid, &ok, normal_ir_body);

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::OneByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 1 * target::kWordSize));  // This.
  __ ldr(R1, Address(SP, 0 * target::kWordSize));  // Other.

  StringEquality(assembler, R0, R1, R2, R3, R0, normal_ir_body,
                 kOneByteStringCid);
}

void AsmIntrinsifier::TwoByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ ldr(R0, Address(SP, 1 * target::kWordSize));  // This.
  __ ldr(R1, Address(SP, 0 * target::kWordSize));  // Other.

  StringEquality(assembler, R0, R1, R2, R3, R0, normal_ir_body,
                 kTwoByteStringCid);
}

void AsmIntrinsifier::IntrinsifyRegExpExecuteMatch(Assembler* assembler,
                                                   Label* normal_ir_body,
                                                   bool sticky) {
  if (FLAG_interpret_irregexp) return;

  const intptr_t kRegExpParamOffset = 2 * target::kWordSize;
  const intptr_t kStringParamOffset = 1 * target::kWordSize;
  // start_index smi is located at offset 0.

  // Incoming registers:
  // R0: Function. (Will be reloaded with the specialized matcher function.)
  // R4: Arguments descriptor. (Will be preserved.)
  // R5: Unknown. (Must be GC safe on tail call.)

  // Load the specialized function pointer into R0. Leverage the fact the
  // string CIDs as well as stored function pointers are in sequence.
  __ ldr(R2, Address(SP, kRegExpParamOffset));
  __ ldr(R1, Address(SP, kStringParamOffset));
  __ LoadClassId(R1, R1);
  __ AddImmediate(R1, -kOneByteStringCid);
#if !defined(DART_COMPRESSED_POINTERS)
  __ add(R1, R2, Operand(R1, LSL, target::kWordSizeLog2));
#else
  __ add(R1, R2, Operand(R1, LSL, target::kWordSizeLog2 - 1));
#endif
  __ LoadCompressed(FUNCTION_REG,
                    FieldAddress(R1, target::RegExp::function_offset(
                                         kOneByteStringCid, sticky)));

  // Registers are now set up for the lazy compile stub. It expects the function
  // in R0, the argument descriptor in R4, and IC-Data in R5.
  __ eor(R5, R5, Operand(R5));

  // Tail-call the function.
  __ LoadCompressed(
      CODE_REG, FieldAddress(FUNCTION_REG, target::Function::code_offset()));
  __ ldr(R1,
         FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
  __ br(R1);
}

void AsmIntrinsifier::UserTag_defaultTag(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ LoadIsolate(R0);
  __ ldr(R0, Address(R0, target::Isolate::default_tag_offset()));
  __ ret();
}

void AsmIntrinsifier::Profiler_getCurrentTag(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ LoadIsolate(R0);
  __ ldr(R0, Address(R0, target::Isolate::current_tag_offset()));
  __ ret();
}

void AsmIntrinsifier::Timeline_isDartStreamEnabled(Assembler* assembler,
                                                   Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ ret();
#else
  // Load TimelineStream*.
  __ ldr(R0, Address(THR, target::Thread::dart_stream_offset()));
  // Load uintptr_t from TimelineStream*.
  __ ldr(R0, Address(R0, target::TimelineStream::enabled_offset()));
  __ cmp(R0, Operand(0));
  __ LoadObject(R0, CastHandle<Object>(FalseObject()));
  __ LoadObject(TMP, CastHandle<Object>(TrueObject()));
  __ csel(R0, TMP, R0, NE);
  __ ret();
#endif
}

void AsmIntrinsifier::Timeline_getNextTaskId(Assembler* assembler,
                                             Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ LoadImmediate(R0, target::ToRawSmi(0));
  __ ret();
#else
  __ ldr(R0, Address(THR, target::Thread::next_task_id_offset()));
  __ add(R1, R0, Operand(1));
  __ str(R1, Address(THR, target::Thread::next_task_id_offset()));
  __ SmiTag(R0);  // Ignore loss of precision.
  __ ret();
#endif
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
