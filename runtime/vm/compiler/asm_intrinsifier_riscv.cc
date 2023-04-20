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
  __ lx(A0, Address(SP, 0 * target::kWordSize));
  __ SmiUntag(A0);

  // XOR with sign bit to complement bits if value is negative.
  __ srai(A1, A0, XLEN - 1);
  __ xor_(A0, A0, A1);

  __ CountLeadingZeroes(A0, A0);

  __ li(TMP, XLEN);
  __ sub(A0, TMP, A0);
  __ SmiTag(A0);
  __ ret();
}

void AsmIntrinsifier::Bigint_lsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _lsh(Uint32List src_digits, int src_used,
  //                  int shift_amount,
  //                  Uint32List result_digits)

  Label loop, done;
  __ lx(T0, Address(SP, 3 * target::kWordSize));  // src_digits
  __ lx(T1, Address(SP, 2 * target::kWordSize));  // src_used
  __ lx(T2, Address(SP, 1 * target::kWordSize));  // shift_amount
  __ lx(T3, Address(SP, 0 * target::kWordSize));  // result_digits

#if XLEN == 32
  // 1 word = 1 digit
  __ SmiUntag(T1);
#else
  // 1 word = 2 digits
  __ addi(T1, T1, target::ToRawSmi(1));  // Round up to even
  __ srai(T1, T1, kSmiTagSize + 1);
#endif
  __ SmiUntag(T2);

  __ srai(T4, T2, target::kBitsPerWordLog2);  // T4 = word shift
  __ andi(T5, T2, target::kBitsPerWord - 1);  // T5 = bit shift
  __ li(T6, target::kBitsPerWord);
  __ sub(T6, T6, T5);  // T6 = carry bit shift

  __ slli(TMP, T1, target::kWordSizeLog2);
  __ add(T0, T0, TMP);
  __ subi(T0, T0, target::kWordSize);  // T0 = &src_digits[src_used - 1]

  __ add(TMP, T1, T4);
  __ slli(TMP, TMP, target::kWordSizeLog2);
  __ add(T3, T3, TMP);  // T3 = &dst_digits[src_used + word_shift]

  __ li(T2, 0);  // carry

  __ Bind(&loop);
  __ beqz(T1, &done, Assembler::kNearJump);
  __ lx(TMP, FieldAddress(T0, target::TypedData::payload_offset()));
  __ srl(TMP2, TMP, T6);
  __ or_(TMP2, TMP2, T2);
  __ sx(TMP2, FieldAddress(T3, target::TypedData::payload_offset()));
  __ sll(T2, TMP, T5);
  __ subi(T0, T0, target::kWordSize);
  __ subi(T3, T3, target::kWordSize);
  __ subi(T1, T1, 1);
  __ j(&loop);

  __ Bind(&done);
  __ sx(T2, FieldAddress(T3, target::TypedData::payload_offset()));
  __ LoadObject(A0, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_rsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _rsh(Uint32List src_digits, int src_used,
  //                  int shift_amount,
  //                  Uint32List result_digits)

  Label loop, done;
  __ lx(T0, Address(SP, 3 * target::kWordSize));  // src_digits
  __ lx(T1, Address(SP, 2 * target::kWordSize));  // src_used
  __ lx(T2, Address(SP, 1 * target::kWordSize));  // shift_amount
  __ lx(T3, Address(SP, 0 * target::kWordSize));  // result_digits

#if XLEN == 32
  // 1 word = 1 digit
  __ SmiUntag(T1);
#else
  // 1 word = 2 digits
  __ addi(T1, T1, target::ToRawSmi(1));  // Round up to even
  __ srai(T1, T1, kSmiTagSize + 1);
#endif
  __ SmiUntag(T2);

  __ srai(T4, T2, target::kBitsPerWordLog2);  // T4 = word shift
  __ andi(T5, T2, target::kBitsPerWord - 1);  // T5 = bit shift
  __ li(T6, target::kBitsPerWord);
  __ sub(T6, T6, T5);  // T6 = carry bit shift
  __ sub(T1, T1, T4);  // T1 = words to process

  __ slli(TMP, T4, target::kWordSizeLog2);
  __ add(T0, T0, TMP);  // T0 = &src_digits[word_shift]

  // T2 = carry
  __ lx(T2, FieldAddress(T0, target::TypedData::payload_offset()));
  __ srl(T2, T2, T5);
  __ addi(T0, T0, target::kWordSize);
  __ subi(T1, T1, 1);

  __ Bind(&loop);
  __ beqz(T1, &done, Assembler::kNearJump);
  __ lx(TMP, FieldAddress(T0, target::TypedData::payload_offset()));
  __ sll(TMP2, TMP, T6);
  __ or_(TMP2, TMP2, T2);
  __ sx(TMP2, FieldAddress(T3, target::TypedData::payload_offset()));
  __ srl(T2, TMP, T5);
  __ addi(T0, T0, target::kWordSize);
  __ addi(T3, T3, target::kWordSize);
  __ subi(T1, T1, 1);
  __ j(&loop);

  __ Bind(&done);
  __ sx(T2, FieldAddress(T3, target::TypedData::payload_offset()));
  __ LoadObject(A0, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_absAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absAdd(Uint32List longer_digits, int longer_used,
  //                     Uint32List shorter_digits, int shorter_used,
  //                     Uint32List result_digits)

  Label first_loop, second_loop, last_carry, done;
  __ lx(T0, Address(SP, 4 * target::kWordSize));  // longer_digits
  __ lx(T1, Address(SP, 3 * target::kWordSize));  // longer_used
  __ lx(T2, Address(SP, 2 * target::kWordSize));  // shorter_digits
  __ lx(T3, Address(SP, 1 * target::kWordSize));  // shorter_used
  __ lx(T4, Address(SP, 0 * target::kWordSize));  // result_digits

#if XLEN == 32
  // 1 word = 1 digit
  __ SmiUntag(T1);
  __ SmiUntag(T3);
#else
  // 1 word = 2 digits
  __ addi(T1, T1, target::ToRawSmi(1));  // Round up to even
  __ srai(T1, T1, kSmiTagSize + 1);
  __ addi(T3, T3, target::ToRawSmi(1));  // Round up to even
  __ srai(T3, T3, kSmiTagSize + 1);
#endif
  __ li(T5, 0);  // Carry

  __ Bind(&first_loop);
  __ beqz(T3, &second_loop);
  __ lx(A0, FieldAddress(T0, target::TypedData::payload_offset()));
  __ lx(A1, FieldAddress(T2, target::TypedData::payload_offset()));
  __ add(A0, A0, A1);
  __ sltu(TMP, A0, A1);  // Carry
  __ add(A0, A0, T5);
  __ sltu(TMP2, A0, T5);  // Carry
  __ add(T5, TMP, TMP2);
  __ sx(A0, FieldAddress(T4, target::TypedData::payload_offset()));
  __ addi(T0, T0, target::kWordSize);
  __ addi(T2, T2, target::kWordSize);
  __ addi(T4, T4, target::kWordSize);
  __ subi(T1, T1, 1);
  __ subi(T3, T3, 1);
  __ j(&first_loop);

  __ Bind(&second_loop);
  __ beqz(T1, &last_carry);
  __ lx(A0, FieldAddress(T0, target::TypedData::payload_offset()));
  __ add(TMP, A0, T5);
  __ sltu(T5, TMP, A0);  // Carry
  __ sx(TMP, FieldAddress(T4, target::TypedData::payload_offset()));
  __ addi(T0, T0, target::kWordSize);
  __ addi(T4, T4, target::kWordSize);
  __ subi(T1, T1, 1);
  __ j(&second_loop);

  __ Bind(&last_carry);
  __ beqz(T5, &done);
  __ sx(T5, FieldAddress(T4, target::TypedData::payload_offset()));

  __ Bind(&done);
  __ LoadObject(A0, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_absSub(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absSub(Uint32List longer_digits, int longer_used,
  //                     Uint32List shorter_digits, int shorter_used,
  //                     Uint32List result_digits)
  Label first_loop, second_loop, last_borrow, done;
  __ lx(T0, Address(SP, 4 * target::kWordSize));  // longer_digits
  __ lx(T1, Address(SP, 3 * target::kWordSize));  // longer_used
  __ lx(T2, Address(SP, 2 * target::kWordSize));  // shorter_digits
  __ lx(T3, Address(SP, 1 * target::kWordSize));  // shorter_used
  __ lx(T4, Address(SP, 0 * target::kWordSize));  // result_digits

#if XLEN == 32
  // 1 word = 1 digit
  __ SmiUntag(T1);
  __ SmiUntag(T3);
#else
  // 1 word = 2 digits
  __ addi(T1, T1, target::ToRawSmi(1));  // Round up to even
  __ srai(T1, T1, kSmiTagSize + 1);
  __ addi(T3, T3, target::ToRawSmi(1));  // Round up to even
  __ srai(T3, T3, kSmiTagSize + 1);
#endif
  __ li(T5, 0);  // Borrow

  __ Bind(&first_loop);
  __ beqz(T3, &second_loop);
  __ lx(A0, FieldAddress(T0, target::TypedData::payload_offset()));
  __ lx(A1, FieldAddress(T2, target::TypedData::payload_offset()));
  __ sltu(TMP, A0, A1);  // Borrow
  __ sub(A0, A0, A1);
  __ sltu(TMP2, A0, T5);  // Borrow
  __ sub(A0, A0, T5);
  __ add(T5, TMP, TMP2);
  __ sx(A0, FieldAddress(T4, target::TypedData::payload_offset()));
  __ addi(T0, T0, target::kWordSize);
  __ addi(T2, T2, target::kWordSize);
  __ addi(T4, T4, target::kWordSize);
  __ subi(T1, T1, 1);
  __ subi(T3, T3, 1);
  __ j(&first_loop);

  __ Bind(&second_loop);
  __ beqz(T1, &last_borrow);
  __ lx(A0, FieldAddress(T0, target::TypedData::payload_offset()));
  __ sltu(TMP, A0, T5);  // Borrow
  __ sub(A0, A0, T5);
  __ mv(T5, TMP);
  __ sx(A0, FieldAddress(T4, target::TypedData::payload_offset()));
  __ addi(T0, T0, target::kWordSize);
  __ addi(T4, T4, target::kWordSize);
  __ subi(T1, T1, 1);
  __ j(&second_loop);

  __ Bind(&last_borrow);
  __ beqz(T5, &done);
  __ neg(T5, T5);
  __ sx(T5, FieldAddress(T4, target::TypedData::payload_offset()));

  __ Bind(&done);
  __ LoadObject(A0, NullObject());
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
  __ lx(T0, Address(SP, 6 * target::kWordSize));  // x_digits
  __ lx(T1, Address(SP, 5 * target::kWordSize));  // xi
  __ lx(T2, Address(SP, 4 * target::kWordSize));  // m_digits
  __ lx(T3, Address(SP, 3 * target::kWordSize));  // i
  __ lx(T4, Address(SP, 2 * target::kWordSize));  // a_digits
  __ lx(T5, Address(SP, 1 * target::kWordSize));  // j
  __ lx(T6, Address(SP, 0 * target::kWordSize));  // n

  // R3 = x, no_op if x == 0
  // T0 = xi as Smi, R1 = x_digits.
  __ slli(T1, T1, 1);
  __ add(T0, T0, T1);
  __ lx(T0, FieldAddress(T0, target::TypedData::payload_offset()));
  __ beqz(T0, &done);

  // R6 = (SmiUntag(n) + 1)/2, no_op if n == 0
#if XLEN == 32
  // 1 word = 1 digit
  __ SmiUntag(T6);
#else
  // 1 word = 2 digits
  __ addi(T6, T6, target::ToRawSmi(1));
  __ srai(T6, T6, 2);
#endif
  __ beqz(T6, &done);

  // R4 = mip = &m_digits[i >> 1]
  // R0 = i as Smi, R1 = m_digits.
  __ slli(T3, T3, 1);
  __ add(T2, T2, T3);

  // R5 = ajp = &a_digits[j >> 1]
  // R0 = j as Smi, R1 = a_digits.
  __ slli(T5, T5, 1);
  __ add(T4, T4, T5);

  // T1 = c = 0
  __ li(T1, 0);

  Label muladd_loop;
  __ Bind(&muladd_loop);
  // x:   T0
  // mip: T2
  // ajp: T4
  // c:   T1
  // n:   T6
  // t:   A7:A6 (not live at loop entry)

  // uint64_t mi = *mip++
  __ lx(A0, FieldAddress(T2, target::TypedData::payload_offset()));
  __ addi(T2, T2, target::kWordSize);

  // uint64_t aj = *ajp
  __ lx(A1, FieldAddress(T4, target::TypedData::payload_offset()));

  // uint128_t t = x*mi + aj + c
  // Macro-op fusion: when both products are required, the recommended sequence
  // is high first.
  __ mulhu(A7, A0, T0);  // A7 = high64(A0*T0), t = A7:A6 = x*mi.
  __ mul(A6, A0, T0);    // A6 = low64(A0*T0).

  __ add(A6, A6, A1);
  __ sltu(TMP, A6, A1);  // Carry
  __ add(A7, A7, TMP);   // t += aj

  __ add(A6, A6, T1);
  __ sltu(TMP, A6, T1);  // Carry
  __ add(A7, A7, TMP);   // t += c

  __ mv(T1, A7);  // c = high64(t)

  // *ajp++ = low64(t) = R0
  __ sx(A6, FieldAddress(T4, target::TypedData::payload_offset()));
  __ addi(T4, T4, target::kWordSize);

  // while (--n > 0)
  __ subi(T6, T6, 1);  // --n
  __ bnez(T6, &muladd_loop);

  __ beqz(T1, &done);

  // *ajp++ += c
  __ lx(A0, FieldAddress(T4, target::TypedData::payload_offset()));
  __ add(A0, A0, T1);
  __ sltu(T1, A0, T1);  // Carry
  __ sx(A0, FieldAddress(T4, target::TypedData::payload_offset()));
  __ addi(T4, T4, target::kWordSize);
  __ beqz(T1, &done);

  Label propagate_carry_loop;
  __ Bind(&propagate_carry_loop);
  __ lx(A0, FieldAddress(T4, target::TypedData::payload_offset()));
  __ add(A0, A0, T1);
  __ sltu(T1, A0, T1);  // Carry
  __ sx(A0, FieldAddress(T4, target::TypedData::payload_offset()));
  __ addi(T4, T4, target::kWordSize);
  __ bnez(T1, &propagate_carry_loop);

  __ Bind(&done);
  // Result = One or two digits processed.
  __ li(A0, target::ToRawSmi(target::kWordSize / kBytesPerBigIntDigit));
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

  // T2 = xip = &x_digits[i >> 1]
  // T0 = i as Smi, T1 = x_digits
  __ lx(T0, Address(SP, 2 * target::kWordSize));
  __ lx(T1, Address(SP, 3 * target::kWordSize));
  __ slli(TMP, T0, 1);
  __ add(T1, T1, TMP);
  __ addi(T2, T1, target::TypedData::payload_offset() - kHeapObjectTag);

  // T1 = x = *xip++, return if x == 0
  Label x_zero;
  __ lx(T1, Address(T2, 0));
  __ addi(T2, T2, target::kWordSize);
  __ beqz(T1, &x_zero);

  // T3 = ajp = &a_digits[i]
  __ lx(A1, Address(SP, 1 * target::kWordSize));  // a_digits
  __ slli(TMP, T0, 2);
  __ add(A1, A1, TMP);  // j == 2*i, i is Smi.
  __ addi(T3, A1, target::TypedData::payload_offset() - kHeapObjectTag);

  // T4:A1 = t = x*x + *ajp
  __ lx(A0, Address(T3, 0));
  __ mul(A1, T1, T1);    // A1 = low64(T1*T1).
  __ mulhu(T4, T1, T1);  // T4 = high64(T1*T1).
  __ add(A1, A1, A0);    // T4:A1 += *ajp.
  __ sltu(TMP, A1, A0);
  __ add(T4, T4, TMP);  // T4 = low64(c) = high64(t).
  __ li(T5, 0);         // T5 = high64(c) = 0.

  // *ajp++ = low64(t) = A1
  __ sx(A1, Address(T3, 0));
  __ addi(T3, T3, target::kWordSize);

  __ lx(A0, Address(SP, 0 * target::kWordSize));  // used is Smi
#if XLEN == 32
  // int n = used - i - 2;
  __ sub(T6, A0, T0);
  __ SmiUntag(T6);
  __ subi(T6, T6, 2);
#else
  // int n = (used - i + 1)/2 - 1
  __ sub(T6, A0, T0);
  __ addi(T6, T6, 2);
  __ srai(T6, T6, 2);
  __ subi(T6, T6, 2);
#endif

  Label loop, done;
  __ bltz(T6, &done);  // while (--n >= 0)

  __ Bind(&loop);
  // x:   T1
  // xip: T2
  // ajp: T3
  // c:   T5:T4
  // t:   T0:A1:A0 (not live at loop entry)
  // n:   T6

  // uint64_t xi = *xip++
  __ lx(T0, Address(T2, 0));
  __ addi(T2, T2, target::kWordSize);

  // uint192_t t = T0:A1:A0 = 2*x*xi + aj + c
  __ mul(A0, T0, T1);    // A0 = low64(T0*T1) = low64(x*xi).
  __ mulhu(A1, T0, T1);  // A1 = high64(T0*T1) = high64(x*xi).

  __ mv(TMP, A0);
  __ add(A0, A0, A0);
  __ sltu(TMP, A0, TMP);
  __ mv(TMP2, A1);
  __ add(A1, A1, A1);
  __ sltu(TMP2, A1, TMP2);
  __ add(A1, A1, TMP);
  __ sltu(TMP, A1, TMP);
  __ add(T0, TMP, TMP2);  // T0:A1:A0 = A1:A0 + A1:A0 = 2*x*xi.

  __ add(A0, A0, T4);
  __ sltu(TMP, A0, T4);
  __ add(A1, A1, T5);
  __ sltu(TMP2, A1, T5);
  __ add(A1, A1, TMP);
  __ sltu(TMP, A1, TMP);
  __ add(T0, T0, TMP);
  __ add(T0, T0, TMP2);  // T0:A1:A0 += c.

  __ lx(T5, Address(T3, 0));  // T5 = aj = *ajp.
  __ add(A0, A0, T5);
  __ sltu(TMP, A0, T5);
  __ add(T4, A1, TMP);
  __ sltu(TMP, T4, A1);
  __ add(T5, T0, TMP);  // T5:T4:A0 = 2*x*xi + aj + c.

  // *ajp++ = low64(t) = A0
  __ sx(A0, Address(T3, 0));
  __ addi(T3, T3, target::kWordSize);

  // while (--n >= 0)
  __ subi(T6, T6, 1);  // --n
  __ bgez(T6, &loop);

  __ Bind(&done);
  // uint64_t aj = *ajp
  __ lx(A0, Address(T3, 0));

  // uint128_t t = aj + c
  __ add(T4, T4, A0);
  __ sltu(TMP, T4, A0);
  __ add(T5, T5, TMP);

  // *ajp = low64(t) = T4
  // *(ajp + 1) = high64(t) = T5
  __ sx(T4, Address(T3, 0));
  __ sx(T5, Address(T3, target::kWordSize));

  __ Bind(&x_zero);
  // Result = One or two digits processed.
  __ li(A0, target::ToRawSmi(target::kWordSize / kBytesPerBigIntDigit));
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

  __ lx(T4, Address(SP, 2 * target::kWordSize));  // args

#if XLEN == 32
  // ECX = yt = args[1]
  __ lx(T3, FieldAddress(T4, target::TypedData::payload_offset() +
                                 kBytesPerBigIntDigit));
#else
  // T3 = yt = args[0..1]
  __ lx(T3, FieldAddress(T4, target::TypedData::payload_offset()));
#endif

  __ lx(A0, Address(SP, 0 * target::kWordSize));  // A0 = i as Smi
  __ lx(T1, Address(SP, 1 * target::kWordSize));  // T1 = digits
  __ slli(TMP, A0, 1);
  __ add(T1, T1, TMP);
#if XLEN == 32
  // EBX = dp = &digits[i >> 1]
  __ lx(T2, FieldAddress(T1, target::TypedData::payload_offset()));
#else
  // T2 = dh = digits[(i >> 1) - 1 .. i >> 1]
  __ lx(T2, FieldAddress(T1, target::TypedData::payload_offset() -
                                 kBytesPerBigIntDigit));
#endif

  // A0 = qd = (DIGIT_MASK << 32) | DIGIT_MASK = -1
  __ li(A0, -1);

  // Return qd if dh == yt
  Label return_qd;
  __ beq(T2, T3, &return_qd);

#if XLEN == 32
  // EAX = dl = dp[-1]
  __ lx(T1, FieldAddress(T1, target::TypedData::payload_offset() -
                                 kBytesPerBigIntDigit));
#else
  // T1 = dl = digits[(i >> 1) - 3 .. (i >> 1) - 2]
  __ lx(T1, FieldAddress(T1, target::TypedData::payload_offset() -
                                 3 * kBytesPerBigIntDigit));
#endif

  // T5 = yth = yt >> 32
  __ srli(T5, T3, target::kWordSize * 4);

  // T6 = qh = dh / yth
  __ divu(T6, T2, T5);

  // A6:A1 = ph:pl = yt*qh
  __ mulhu(A6, T3, T6);
  __ mul(A1, T3, T6);

  // A7 = tl = (dh << 32)|(dl >> 32)
  __ slli(A7, T2, target::kWordSize * 4);
  __ srli(TMP, T1, target::kWordSize * 4);
  __ or_(A7, A7, TMP);

  // S3 = th = dh >> 32
  __ srli(S3, T2, target::kWordSize * 4);

  // while ((ph > th) || ((ph == th) && (pl > tl)))
  Label qh_adj_loop, qh_adj, qh_ok;
  __ Bind(&qh_adj_loop);
  __ bgtu(A6, S3, &qh_adj);
  __ bne(A6, S3, &qh_ok);
  __ bleu(A1, A7, &qh_ok);

  __ Bind(&qh_adj);
  // if (pl < yt) --ph
  __ sltu(TMP, A1, T3);
  __ sub(A6, A6, TMP);

  // pl -= yt
  __ sub(A1, A1, T3);

  // --qh
  __ subi(T6, T6, 1);

  // Continue while loop.
  __ j(&qh_adj_loop);

  __ Bind(&qh_ok);
  // A0 = qd = qh << 32
  __ slli(A0, T6, target::kWordSize * 4);

  // tl = (pl << 32)
  __ slli(A7, A1, target::kWordSize * 4);

  // th = (ph << 32)|(pl >> 32);
  __ slli(S3, A6, target::kWordSize * 4);
  __ srli(TMP, A1, target::kWordSize * 4);
  __ or_(S3, S3, TMP);

  // if (tl > dl) ++th
  __ sltu(TMP, T1, A7);
  __ add(S3, S3, TMP);

  // dl -= tl
  __ sub(T1, T1, A7);

  // dh -= th
  __ sub(T2, T2, S3);

  // T6 = ql = ((dh << 32)|(dl >> 32)) / yth
  __ slli(T6, T2, target::kWordSize * 4);
  __ srli(TMP, T1, target::kWordSize * 4);
  __ or_(T6, T6, TMP);
  __ divu(T6, T6, T5);

  // A6:A1 = ph:pl = yt*ql
  __ mulhu(A6, T3, T6);
  __ mul(A1, T3, T6);

  // while ((ph > dh) || ((ph == dh) && (pl > dl))) {
  Label ql_adj_loop, ql_adj, ql_ok;
  __ Bind(&ql_adj_loop);
  __ bgtu(A6, T2, &ql_adj);
  __ bne(A6, T2, &ql_ok);
  __ bleu(A1, T1, &ql_ok);

  __ Bind(&ql_adj);
  // if (pl < yt) --ph
  __ sltu(TMP, A1, T3);
  __ sub(A6, A6, TMP);

  // pl -= yt
  __ sub(A1, A1, T3);

  // --ql
  __ subi(T6, T6, 1);

  // Continue while loop.
  __ j(&ql_adj_loop);

  __ Bind(&ql_ok);
  // qd |= ql;
  __ or_(A0, A0, T6);

  __ Bind(&return_qd);
  // args[2..3] = qd
  __ sx(A0, FieldAddress(T4, target::TypedData::payload_offset() +
                                 2 * kBytesPerBigIntDigit));

  // Result = One or two digits processed.
  __ li(A0, target::ToRawSmi(target::kWordSize / kBytesPerBigIntDigit));
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

  __ lx(T0, Address(SP, 2 * target::kWordSize));  // args
  __ lx(T1, Address(SP, 1 * target::kWordSize));  // digits
  __ lx(T2, Address(SP, 0 * target::kWordSize));  // i as Smi

  // T3 = rho = args[2..3]
  __ lx(T3, FieldAddress(T0, target::TypedData::payload_offset() +
                                 2 * kBytesPerBigIntDigit));

  // T4 = digits[i >> 1 .. (i >> 1) + 1]
  __ slli(T2, T2, 1);
  __ add(T1, T1, T2);
  __ lx(T4, FieldAddress(T1, target::TypedData::payload_offset()));

  // T5 = rho*d mod DIGIT_BASE
  __ mul(T5, T4, T3);  // T5 = low64(T4*T3).

  // args[4 .. 5] = T5
  __ sx(T5, FieldAddress(T0, target::TypedData::payload_offset() +
                                 4 * kBytesPerBigIntDigit));

  // Result = One or two digits processed.
  __ li(A0, target::ToRawSmi(target::kWordSize / kBytesPerBigIntDigit));
  __ ret();
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
  // Only smis allowed.
  __ lx(A1, Address(SP, 0 * target::kWordSize));
  __ BranchIfNotSmi(A1, normal_ir_body, Assembler::kNearJump);
  // Is Smi.
  __ SmiUntag(A1);
#if XLEN == 32
  __ fcvtdw(FA1, A1);
#else
  __ fcvtdl(FA1, A1);
#endif
  __ lx(A0, Address(SP, 1 * target::kWordSize));
  __ LoadDFieldFromOffset(FA0, A0, target::Double::value_offset());
  __ fmuld(FA0, FA0, FA1);
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kNearJump, A0, A1);
  __ StoreDFieldToOffset(FA0, A0, target::Double::value_offset());
  __ ret();
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
  __ TryAllocate(double_class, normal_ir_body, Assembler::kNearJump, A0, TMP);
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
  __ lx(A0, Address(SP, 0 * target::kWordSize));
  __ LoadClassIdMayBeSmi(A1, A0);

  __ CompareImmediate(A1, kClosureCid);
  __ BranchIf(EQ, normal_ir_body,
              Assembler::kNearJump);  // Instance is a closure.

  __ CompareImmediate(A1, kRecordCid);
  __ BranchIf(EQ, normal_ir_body,
              Assembler::kNearJump);  // Instance is a record.

  __ CompareImmediate(A1, kNumPredefinedCids);
  __ BranchIf(HI, &use_declaration_type, Assembler::kNearJump);

  __ LoadIsolateGroup(A0);
  __ LoadFromOffset(A0, A0, target::IsolateGroup::object_store_offset());

  __ CompareImmediate(A1, kDoubleCid);
  __ BranchIf(NE, &not_double, Assembler::kNearJump);
  __ LoadFromOffset(A0, A0, target::ObjectStore::double_type_offset());
  __ ret();

  __ Bind(&not_double);
  JumpIfNotInteger(assembler, A1, TMP, &not_integer);
  __ LoadFromOffset(A0, A0, target::ObjectStore::int_type_offset());
  __ ret();

  __ Bind(&not_integer);
  JumpIfNotString(assembler, A1, TMP, &not_string);
  __ LoadFromOffset(A0, A0, target::ObjectStore::string_type_offset());
  __ ret();

  __ Bind(&not_string);
  JumpIfNotType(assembler, A1, TMP, &use_declaration_type);
  __ LoadFromOffset(A0, A0, target::ObjectStore::type_type_offset());
  __ ret();

  __ Bind(&use_declaration_type);
  __ LoadClassById(T2, A1);
  __ lh(T3, FieldAddress(T2, target::Class::num_type_arguments_offset()));
  __ bnez(T3, normal_ir_body, Assembler::kNearJump);

  __ LoadCompressed(A0,
                    FieldAddress(T2, target::Class::declaration_type_offset()));
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
  __ beq(cid1, cid2, equal_may_be_generic);

  // Class ids are different. Check if we are comparing two string types (with
  // different representations), two integer types, two list types or two type
  // types.
  __ CompareImmediate(cid1, kNumPredefinedCids);
  __ BranchIf(HI, not_equal);

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
  __ lx(A0, Address(SP, 1 * target::kWordSize));
  __ lx(A1, Address(SP, 0 * target::kWordSize));
  __ LoadClassIdMayBeSmi(T2, A1);
  __ LoadClassIdMayBeSmi(A1, A0);

  Label equal_may_be_generic, equal, not_equal;
  EquivalentClassIds(assembler, normal_ir_body, &equal_may_be_generic, &equal,
                     &not_equal, A1, T2, TMP,
                     /* testing_instance_cids = */ true);

  __ Bind(&equal_may_be_generic);
  // Classes are equivalent and neither is a closure class.
  // Check if there are no type arguments. In this case we can return true.
  // Otherwise fall through into the runtime to handle comparison.
  __ LoadClassById(A0, A1);
  __ lw(T0,
        FieldAddress(
            A0,
            target::Class::host_type_arguments_field_offset_in_words_offset()));
  __ CompareImmediate(T0, target::Class::kNoTypeArguments);
  __ BranchIf(EQ, &equal, Assembler::kNearJump);

  // Compare type arguments, host_type_arguments_field_offset_in_words in A0.
  __ lx(A0, Address(SP, 1 * target::kWordSize));
  __ lx(A1, Address(SP, 0 * target::kWordSize));
  __ slli(T0, T0, target::kCompressedWordSizeLog2);
  __ add(A0, A0, T0);
  __ add(A1, A1, T0);
  __ lx(A0, FieldAddress(A0, 0));
  __ lx(A1, FieldAddress(A1, 0));
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
  __ lx(A0, Address(SP, 0 * target::kWordSize));

#if defined(HASH_IN_OBJECT_HEADER)
  // uint32_t field in header.
  __ lwu(A0, FieldAddress(A0, target::String::hash_offset()));
  __ SmiTag(A0);
#else
  // Smi field.
  __ lx(A0, FieldAddress(A0, target::String::hash_offset()));
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
  Label equal, not_equal, equiv_cids_may_be_generic, equiv_cids, check_legacy;

  __ lx(A0, Address(SP, 1 * target::kWordSize));
  __ lx(A1, Address(SP, 0 * target::kWordSize));
  __ beq(A1, A0, &equal);

  // A1 might not be a Type object, so check that first (A0 should be though,
  // since this is a method on the Type class).
  __ LoadClassIdMayBeSmi(T3, A1);
  __ CompareImmediate(T3, kTypeCid);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);

  // Check if types are syntactically equal.
  __ LoadTypeClassId(T3, A1);
  __ LoadTypeClassId(T4, A0);
  // We are not testing instance cids, but type class cids of Type instances.
  EquivalentClassIds(assembler, normal_ir_body, &equiv_cids_may_be_generic,
                     &equiv_cids, &not_equal, T3, T4, TMP,
                     /* testing_instance_cids = */ false);

  __ Bind(&equiv_cids_may_be_generic);
  // Compare type arguments in Type instances.
  __ LoadCompressed(T3, FieldAddress(A1, target::Type::arguments_offset()));
  __ LoadCompressed(T4, FieldAddress(A0, target::Type::arguments_offset()));
  __ CompareObjectRegisters(T3, T4);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);
  // Fall through to check nullability if type arguments are equal.

  // Check nullability.
  __ Bind(&equiv_cids);
  __ LoadAbstractTypeNullability(A0, A0);
  __ LoadAbstractTypeNullability(A1, A1);
  __ bne(A0, A1, &check_legacy);
  // Fall through to equal case if nullability is strictly equal.

  __ Bind(&equal);
  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

  // At this point the nullabilities are different, so they can only be
  // syntactically equivalent if they're both either kNonNullable or kLegacy.
  // These are the two largest values of the enum, so we can just do a < check.
  ASSERT(target::Nullability::kNullable < target::Nullability::kNonNullable &&
         target::Nullability::kNonNullable < target::Nullability::kLegacy);
  __ Bind(&check_legacy);
  __ CompareImmediate(A1, target::Nullability::kNonNullable);
  __ BranchIf(LT, &not_equal);
  __ CompareImmediate(A0, target::Nullability::kNonNullable);
  __ BranchIf(GE, &equal);

  __ Bind(&not_equal);
  __ LoadObject(A0, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AbstractType_getHashCode(Assembler* assembler,
                                               Label* normal_ir_body) {
  __ lx(A0, Address(SP, 0 * target::kWordSize));
  __ LoadCompressed(A0, FieldAddress(A0, target::FunctionType::hash_offset()));
  __ beqz(A0, normal_ir_body, Assembler::kNearJump);
  __ ret();
  // Hash not yet computed.
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AbstractType_equality(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ lx(A0, Address(SP, 1 * target::kWordSize));
  __ lx(A1, Address(SP, 0 * target::kWordSize));
  __ bne(A0, A1, normal_ir_body, Assembler::kNearJump);

  __ LoadObject(A0, CastHandle<Object>(TrueObject()));
  __ ret();

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
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);

  __ CompareClassId(A0, kOneByteStringCid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);

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

  __ lx(A1, Address(SP, 0 * target::kWordSize));  // Index.
  __ lx(A0, Address(SP, 1 * target::kWordSize));  // String.
  __ BranchIfNotSmi(A1, normal_ir_body,
                    Assembler::kNearJump);  // Index is not a Smi.
  // Range check.
  __ lx(TMP, FieldAddress(A0, target::String::length_offset()));
  __ bgeu(A1, TMP, normal_ir_body);  // Runtime throws exception.

  __ CompareClassId(A0, kOneByteStringCid, TMP);
  __ BranchIf(NE, &try_two_byte_string);
  __ SmiUntag(A1);
  __ add(A0, A0, A1);
  __ lbu(A1, FieldAddress(A0, target::OneByteString::data_offset()));
  __ CompareImmediate(A1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ BranchIf(GE, normal_ir_body, Assembler::kNearJump);
  __ lx(A0, Address(THR, target::Thread::predefined_symbols_address_offset()));
  __ slli(A1, A1, target::kWordSizeLog2);
  __ add(A0, A0, A1);
  __ lx(A0, Address(A0, target::Symbols::kNullCharCodeSymbolOffset *
                            target::kWordSize));
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(A0, kTwoByteStringCid, TMP);
  __ BranchIf(NE, normal_ir_body, Assembler::kNearJump);
  ASSERT(kSmiTagShift == 1);
  __ add(A0, A0, A1);
  __ lhu(A1, FieldAddress(A0, target::TwoByteString::data_offset()));
  __ CompareImmediate(A1, target::Symbols::kNumberOfOneCharCodeSymbols);
  __ BranchIf(GE, normal_ir_body, Assembler::kNearJump);
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
#if defined(HASH_IN_OBJECT_HEADER)
  // uint32_t field in header.
  __ lwu(A0, FieldAddress(A1, target::String::hash_offset()));
  __ SmiTag(A0);
#else
  // Smi field.
  __ lx(A0, FieldAddress(A1, target::String::hash_offset()));
#endif
  __ beqz(A0, &compute_hash);
  __ ret();  // Return if already computed.

  __ Bind(&compute_hash);
  __ lx(T0, FieldAddress(A1, target::String::length_offset()));
  __ SmiUntag(T0);

  __ mv(T1, ZR);
  __ addi(T2, A1, target::OneByteString::data_offset() - kHeapObjectTag);

  // A1: Instance of OneByteString.
  // T0: String length, untagged integer.
  // T1: Loop counter, untagged integer.
  // T2: String data.
  // A0: Hash code, untagged integer.

  Label loop, done;
  __ Bind(&loop);
  __ beq(T1, T0, &done);
  // Add to hash code: (hash_ is uint32)
  // Get one characters (ch).
  __ lbu(T3, Address(T2, 0));
  __ addi(T2, T2, 1);
  // T3: ch.
  __ addi(T1, T1, 1);
  __ CombineHashes(A0, T3);
  __ j(&loop);

  __ Bind(&done);
  // Finalize. Allow a zero result to combine checks from empty string branch.
  __ FinalizeHashForSize(target::String::kHashBits, A0);
#if defined(HASH_IN_OBJECT_HEADER)
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
#else
  __ SmiTag(A0);
  __ sx(A0, FieldAddress(A1, target::String::hash_offset()));
#endif
  __ ret();
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

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, failure, TMP));
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
  // Clear last double word to ensure string comparison doesn't need to
  // specially handle remainder of strings with lengths not factors of double
  // offsets.
  __ sx(ZR, Address(T1, -1 * target::kWordSize));
  __ sx(ZR, Address(T1, -2 * target::kWordSize));

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
#if !defined(HASH_IN_OBJECT_HEADER)
  // Clear hash.
  __ StoreIntoObjectNoBarrier(
      A0, FieldAddress(A0, target::String::hash_offset()), ZR);
#endif
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

void AsmIntrinsifier::OneByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ lx(A0, Address(SP, 1 * target::kWordSize));  // This.
  __ lx(A1, Address(SP, 0 * target::kWordSize));  // Other.

  StringEquality(assembler, A0, A1, T2, TMP2, A0, normal_ir_body,
                 kOneByteStringCid);
}

void AsmIntrinsifier::TwoByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ lx(A0, Address(SP, 1 * target::kWordSize));  // This.
  __ lx(A1, Address(SP, 0 * target::kWordSize));  // Other.

  StringEquality(assembler, A0, A1, T2, TMP2, A0, normal_ir_body,
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
  __ lx(FUNCTION_REG, FieldAddress(T1, target::RegExp::function_offset(
                                           kOneByteStringCid, sticky)));

  // Registers are now set up for the lazy compile stub. It expects the function
  // in T0, the argument descriptor in S4, and IC-Data in S5.
  __ li(S5, 0);

  // Tail-call the function.
  __ lx(CODE_REG, FieldAddress(FUNCTION_REG, target::Function::code_offset()));
  __ lx(T1, FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
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

void AsmIntrinsifier::Timeline_getNextTaskId(Assembler* assembler,
                                             Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ LoadImmediate(A0, target::ToRawSmi(0));
  __ ret();
#elif XLEN == 64
  __ ld(A0, Address(THR, target::Thread::next_task_id_offset()));
  __ addi(A1, A0, 1);
  __ sd(A1, Address(THR, target::Thread::next_task_id_offset()));
  __ SmiTag(A0);  // Ignore loss of precision.
  __ ret();
#else
  __ lw(T0, Address(THR, target::Thread::next_task_id_offset()));
  __ lw(T1, Address(THR, target::Thread::next_task_id_offset() + 4));
  __ SmiTag(A0, T0);  // Ignore loss of precision.
  __ addi(T2, T0, 1);
  __ sltu(T3, T2, T0);  // Carry.
  __ add(T1, T1, T3);
  __ sw(T2, Address(THR, target::Thread::next_task_id_offset()));
  __ sw(T1, Address(THR, target::Thread::next_task_id_offset() + 4));
  __ ret();
#endif
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_RISCV)
