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
// PP: Caller's ObjectPool in JIT / global ObjectPool in AOT
// CODE_REG: Callee's Code in JIT / not passed in AOT
// R10: Arguments descriptor
// TOS: Return address
// The R10 and CODE_REG registers can be destroyed only if there is no
// slow-path, i.e. if the intrinsified method always executes a return.
// The RBP register should not be modified, because it is used by the profiler.
// The PP and THR registers (see constants_x64.h) must be preserved.

#define __ assembler->

// Tests if two top most arguments are smis, jumps to label not_smi if not.
// Topmost argument is in RAX.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ movq(RCX, Address(RSP, +2 * target::kWordSize));
  __ orq(RCX, RAX);
  __ testq(RCX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, not_smi);
}

void AsmIntrinsifier::Integer_shl(Assembler* assembler, Label* normal_ir_body) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(kSmiTag == 0);
  Label overflow;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // Shift value is in RAX. Compare with tagged Smi.
  __ OBJ(cmp)(RAX, Immediate(target::ToRawSmi(target::kSmiBits)));
  __ j(ABOVE_EQUAL, normal_ir_body, Assembler::kNearJump);

  __ SmiUntag(RAX);
  __ movq(RCX, RAX);  // Shift amount must be in RCX.
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // Value.

  // Overflow test - all the shifted-out bits must be same as the sign bit.
  __ movq(RDI, RAX);
  __ OBJ(shl)(RAX, RCX);
  __ OBJ(sar)(RAX, RCX);
  __ OBJ(cmp)(RAX, RDI);
  __ j(NOT_EQUAL, &overflow, Assembler::kNearJump);

  __ OBJ(shl)(RAX, RCX);  // Shift for result now we know there is no overflow.

  // RAX is a correctly tagged Smi.
  __ ret();

  __ Bind(&overflow);
  // Mint is rarely used on x64 (only for integers requiring 64 bit instead of
  // 63 or 31 bits as represented by Smi).
  __ Bind(normal_ir_body);
}

static void CompareIntegers(Assembler* assembler,
                            Label* normal_ir_body,
                            Condition true_condition) {
  Label true_label;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // RAX contains the right argument.
  __ OBJ(cmp)(Address(RSP, +2 * target::kWordSize), RAX);
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
  __ OBJ(cmp)(RAX, RCX);
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

void AsmIntrinsifier::Smi_bitLength(Assembler* assembler,
                                    Label* normal_ir_body) {
  ASSERT(kSmiTagShift == 1);
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));  // Index.
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RAX, RAX);
#endif
  // XOR with sign bit to complement bits if value is negative.
  __ movq(RCX, RAX);
  __ sarq(RCX, Immediate(63));  // All 0 or all 1.
  __ OBJ (xor)(RAX, RCX);
  // BSR does not write the destination register if source is zero.  Put a 1 in
  // the Smi tag bit to ensure BSR writes to destination register.
  __ orq(RAX, Immediate(kSmiTagMask));
  __ bsrq(RAX, RAX);
  __ SmiTag(RAX);
  __ ret();
}

void AsmIntrinsifier::Bigint_lsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  __ movq(RDI, Address(RSP, 4 * target::kWordSize));  // x_digits
  __ movq(R8, Address(RSP, 3 * target::kWordSize));   // x_used is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(R8, R8);
#endif
  __ subq(R8, Immediate(2));  // x_used > 0, Smi. R8 = x_used - 1, round up.
  __ sarq(R8, Immediate(2));  // R8 + 1 = number of digit pairs to read.
  __ movq(RCX, Address(RSP, 2 * target::kWordSize));  // n is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RCX, RCX);
#endif
  __ SmiUntag(RCX);
  __ movq(RBX, Address(RSP, 1 * target::kWordSize));  // r_digits
  __ movq(RSI, RCX);
  __ sarq(RSI, Immediate(6));  // RSI = n ~/ (2*_DIGIT_BITS).
  __ leaq(RBX,
          FieldAddress(RBX, RSI, TIMES_8, target::TypedData::payload_offset()));
  __ xorq(RAX, RAX);  // RAX = 0.
  __ movq(RDX,
          FieldAddress(RDI, R8, TIMES_8, target::TypedData::payload_offset()));
  __ shldq(RAX, RDX, RCX);
  __ movq(Address(RBX, R8, TIMES_8, 2 * kBytesPerBigIntDigit), RAX);
  Label last;
  __ cmpq(R8, Immediate(0));
  __ j(EQUAL, &last, Assembler::kNearJump);
  Label loop;
  __ Bind(&loop);
  __ movq(RAX, RDX);
  __ movq(RDX, FieldAddress(RDI, R8, TIMES_8,
                            target::TypedData::payload_offset() -
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
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RCX, RCX);
#endif
  __ SmiUntag(RCX);
  __ movq(RBX, Address(RSP, 1 * target::kWordSize));  // r_digits
  __ movq(RDX, RCX);
  __ sarq(RDX, Immediate(6));  // RDX = n ~/ (2*_DIGIT_BITS).
  __ movq(RSI, Address(RSP, 3 * target::kWordSize));  // x_used is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RSI, RSI);
#endif
  __ subq(RSI, Immediate(2));  // x_used > 0, Smi. RSI = x_used - 1, round up.
  __ sarq(RSI, Immediate(2));
  __ leaq(RDI,
          FieldAddress(RDI, RSI, TIMES_8, target::TypedData::payload_offset()));
  __ subq(RSI, RDX);  // RSI + 1 = number of digit pairs to read.
  __ leaq(RBX,
          FieldAddress(RBX, RSI, TIMES_8, target::TypedData::payload_offset()));
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
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(R8, R8);
#endif
  __ addq(R8, Immediate(2));  // used > 0, Smi. R8 = used + 1, round up.
  __ sarq(R8, Immediate(2));  // R8 = number of digit pairs to process.
  __ movq(RSI, Address(RSP, 3 * target::kWordSize));  // a_digits
  __ movq(RCX, Address(RSP, 2 * target::kWordSize));  // a_used is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RCX, RCX);
#endif
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
          FieldAddress(RDI, RDX, TIMES_8, target::TypedData::payload_offset()));
  __ adcq(RAX,
          FieldAddress(RSI, RDX, TIMES_8, target::TypedData::payload_offset()));
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::payload_offset()),
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
          FieldAddress(RDI, RDX, TIMES_8, target::TypedData::payload_offset()));
  __ adcq(RAX, Immediate(0));
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::payload_offset()),
          RAX);
  __ incq(RDX);  // Does not affect carry flag.
  __ decq(R8);   // Does not affect carry flag.
  __ j(NOT_ZERO, &carry_loop, Assembler::kNearJump);

  __ Bind(&last_carry);
  Label done;
  __ j(NOT_CARRY, &done);
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::payload_offset()),
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
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(R8, R8);
#endif
  __ addq(R8, Immediate(2));  // used > 0, Smi. R8 = used + 1, round up.
  __ sarq(R8, Immediate(2));  // R8 = number of digit pairs to process.
  __ movq(RSI, Address(RSP, 3 * target::kWordSize));  // a_digits
  __ movq(RCX, Address(RSP, 2 * target::kWordSize));  // a_used is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RCX, RCX);
#endif
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
          FieldAddress(RDI, RDX, TIMES_8, target::TypedData::payload_offset()));
  __ sbbq(RAX,
          FieldAddress(RSI, RDX, TIMES_8, target::TypedData::payload_offset()));
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::payload_offset()),
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
          FieldAddress(RDI, RDX, TIMES_8, target::TypedData::payload_offset()));
  __ sbbq(RAX, Immediate(0));
  __ movq(FieldAddress(RBX, RDX, TIMES_8, target::TypedData::payload_offset()),
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
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RAX, RAX);
#endif
  __ movq(RBX,
          FieldAddress(RCX, RAX, TIMES_2, target::TypedData::payload_offset()));
  __ testq(RBX, RBX);
  __ j(ZERO, &done, Assembler::kNearJump);

  // R8 = (SmiUntag(n) + 1)/2, no_op if n == 0
  __ movq(R8, Address(RSP, 1 * target::kWordSize));  // n is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(R8, R8);
#endif
  __ addq(R8, Immediate(2));
  __ sarq(R8, Immediate(2));  // R8 = number of digit pairs to process.
  __ j(ZERO, &done, Assembler::kNearJump);

  // RDI = mip = &m_digits[i >> 1]
  __ movq(RDI, Address(RSP, 5 * target::kWordSize));  // m_digits
  __ movq(RAX, Address(RSP, 4 * target::kWordSize));  // i is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RAX, RAX);
#endif
  __ leaq(RDI,
          FieldAddress(RDI, RAX, TIMES_2, target::TypedData::payload_offset()));

  // RSI = ajp = &a_digits[j >> 1]
  __ movq(RSI, Address(RSP, 3 * target::kWordSize));  // a_digits
  __ movq(RAX, Address(RSP, 2 * target::kWordSize));  // j is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RAX, RAX);
#endif
  __ leaq(RSI,
          FieldAddress(RSI, RAX, TIMES_2, target::TypedData::payload_offset()));

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
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RAX, RAX);
#endif
  __ leaq(RDI,
          FieldAddress(RDI, RAX, TIMES_2, target::TypedData::payload_offset()));

  // RBX = x = *xip++, return if x == 0
  Label x_zero;
  __ movq(RBX, Address(RDI, 0));
  __ cmpq(RBX, Immediate(0));
  __ j(EQUAL, &x_zero);
  __ addq(RDI, Immediate(2 * kBytesPerBigIntDigit));

  // RSI = ajp = &a_digits[i]
  __ movq(RSI, Address(RSP, 2 * target::kWordSize));  // a_digits
  __ leaq(RSI,
          FieldAddress(RSI, RAX, TIMES_4, target::TypedData::payload_offset()));

  // RDX:RAX = t = x*x + *ajp
  __ movq(RAX, RBX);
  __ mulq(RBX);
  __ addq(RAX, Address(RSI, 0));
  __ adcq(RDX, Immediate(0));

  // *ajp++ = low64(t)
  __ movq(Address(RSI, 0), RAX);
  __ addq(RSI, Immediate(2 * kBytesPerBigIntDigit));

  // int n = (used - i + 1)/2 - 1
  __ OBJ(mov)(R8, Address(RSP, 1 * target::kWordSize));  // used is Smi
  __ OBJ(sub)(R8, Address(RSP, 3 * target::kWordSize));  // i is Smi
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
  __ movq(RCX, FieldAddress(RDI, target::TypedData::payload_offset()));

  // RBX = dp = &digits[(i >> 1) - 1]
  __ movq(RBX, Address(RSP, 2 * target::kWordSize));  // digits
  __ movq(RAX, Address(RSP, 1 * target::kWordSize));  // i is Smi and odd.
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RAX, RAX);
#endif
  __ leaq(RBX, FieldAddress(
                   RBX, RAX, TIMES_2,
                   target::TypedData::payload_offset() - kBytesPerBigIntDigit));

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
  __ movq(FieldAddress(RDI, target::TypedData::payload_offset() +
                                2 * kBytesPerBigIntDigit),
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
  __ movq(RCX, FieldAddress(RDI, target::TypedData::payload_offset() +
                                     2 * kBytesPerBigIntDigit));

  // RAX = digits[i >> 1 .. (i >> 1) + 1]
  __ movq(RBX, Address(RSP, 2 * target::kWordSize));  // digits
  __ movq(RAX, Address(RSP, 1 * target::kWordSize));  // i is Smi
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RAX, RAX);
#endif
  __ movq(RAX,
          FieldAddress(RBX, RAX, TIMES_2, target::TypedData::payload_offset()));

  // RDX:RAX = t = rho*d
  __ mulq(RCX);

  // args[4 .. 5] = t mod DIGIT_BASE^2 = low64(t)
  __ movq(FieldAddress(RDI, target::TypedData::payload_offset() +
                                4 * kBytesPerBigIntDigit),
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
  __ OBJ(cvtsi2sd)(XMM1, RAX);
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
  __ OBJ(cvtsi2sd)(XMM1, RAX);
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
  __ OBJ(cvtsi2sd)(XMM1, RAX);
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
  __ OBJ(cvtsi2sd)(XMM0, RAX);
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

// Identity comparison.
void AsmIntrinsifier::ObjectEquals(Assembler* assembler,
                                   Label* normal_ir_body) {
  Label is_true;
  const intptr_t kReceiverOffset = 2;
  const intptr_t kArgumentOffset = 1;

  __ movq(RAX, Address(RSP, +kArgumentOffset * target::kWordSize));
  __ OBJ(cmp)(RAX, Address(RSP, +kReceiverOffset * target::kWordSize));
  __ j(EQUAL, &is_true, Assembler::kNearJump);
  __ LoadObject(RAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
  __ ret();
}

static void JumpIfInteger(Assembler* assembler, Register cid, Label* target) {
  assembler->RangeCheck(cid, kNoRegister, kSmiCid, kMintCid,
                        Assembler::kIfInRange, target);
}

static void JumpIfNotInteger(Assembler* assembler,
                             Register cid,
                             Label* target) {
  assembler->RangeCheck(cid, kNoRegister, kSmiCid, kMintCid,
                        Assembler::kIfNotInRange, target);
}

static void JumpIfString(Assembler* assembler, Register cid, Label* target) {
  assembler->RangeCheck(cid, kNoRegister, kOneByteStringCid,
                        kExternalTwoByteStringCid, Assembler::kIfInRange,
                        target);
}

static void JumpIfNotString(Assembler* assembler, Register cid, Label* target) {
  assembler->RangeCheck(cid, kNoRegister, kOneByteStringCid,
                        kExternalTwoByteStringCid, Assembler::kIfNotInRange,
                        target);
}

static void JumpIfNotList(Assembler* assembler, Register cid, Label* target) {
  assembler->RangeCheck(cid, kNoRegister, kArrayCid, kGrowableObjectArrayCid,
                        Assembler::kIfNotInRange, target);
}

static void JumpIfType(Assembler* assembler, Register cid, Label* target) {
  COMPILE_ASSERT((kFunctionTypeCid == kTypeCid + 1) &&
                 (kRecordTypeCid == kTypeCid + 2));
  assembler->RangeCheck(cid, kNoRegister, kTypeCid, kRecordTypeCid,
                        Assembler::kIfInRange, target);
}

static void JumpIfNotType(Assembler* assembler, Register cid, Label* target) {
  COMPILE_ASSERT((kFunctionTypeCid == kTypeCid + 1) &&
                 (kRecordTypeCid == kTypeCid + 2));
  assembler->RangeCheck(cid, kNoRegister, kTypeCid, kRecordTypeCid,
                        Assembler::kIfNotInRange, target);
}

// Return type quickly for simple types (not parameterized and not signature).
void AsmIntrinsifier::ObjectRuntimeType(Assembler* assembler,
                                        Label* normal_ir_body) {
  Label use_declaration_type, not_integer, not_double, not_string;
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ LoadClassIdMayBeSmi(RCX, RAX);

  // RCX: untagged cid of instance (RAX).
  __ cmpq(RCX, Immediate(kClosureCid));
  __ j(EQUAL, normal_ir_body);  // Instance is a closure.

  __ cmpq(RCX, Immediate(kRecordCid));
  __ j(EQUAL, normal_ir_body);  // Instance is a record.

  __ cmpl(RCX, Immediate(kNumPredefinedCids));
  __ j(ABOVE, &use_declaration_type);

  // If object is a instance of _Double return double type.
  __ cmpl(RCX, Immediate(kDoubleCid));
  __ j(NOT_EQUAL, &not_double);

  __ LoadIsolateGroup(RAX);
  __ movq(RAX, Address(RAX, target::IsolateGroup::object_store_offset()));
  __ movq(RAX, Address(RAX, target::ObjectStore::double_type_offset()));
  __ ret();

  __ Bind(&not_double);
  // If object is an integer (smi, mint or bigint) return int type.
  __ movl(RAX, RCX);
  JumpIfNotInteger(assembler, RAX, &not_integer);

  __ LoadIsolateGroup(RAX);
  __ movq(RAX, Address(RAX, target::IsolateGroup::object_store_offset()));
  __ movq(RAX, Address(RAX, target::ObjectStore::int_type_offset()));
  __ ret();

  __ Bind(&not_integer);
  // If object is a string (one byte, two byte or external variants) return
  // string type.
  __ movq(RAX, RCX);
  JumpIfNotString(assembler, RAX, &not_string);

  __ LoadIsolateGroup(RAX);
  __ movq(RAX, Address(RAX, target::IsolateGroup::object_store_offset()));
  __ movq(RAX, Address(RAX, target::ObjectStore::string_type_offset()));
  __ ret();

  __ Bind(&not_string);
  // If object is a type or function type, return Dart type.
  __ movq(RAX, RCX);
  JumpIfNotType(assembler, RAX, &use_declaration_type);

  __ LoadIsolateGroup(RAX);
  __ movq(RAX, Address(RAX, target::IsolateGroup::object_store_offset()));
  __ movq(RAX, Address(RAX, target::ObjectStore::type_type_offset()));
  __ ret();

  // Object is neither double, nor integer, nor string, nor type.
  __ Bind(&use_declaration_type);
  __ LoadClassById(RDI, RCX);
  __ movzxw(RCX, FieldAddress(RDI, target::Class::num_type_arguments_offset()));
  __ cmpq(RCX, Immediate(0));
  __ j(NOT_EQUAL, normal_ir_body, Assembler::kNearJump);
  __ LoadCompressed(
      RAX, FieldAddress(RDI, target::Class::declaration_type_offset()));
  __ CompareObject(RAX, NullObject());
  __ j(EQUAL, normal_ir_body, Assembler::kNearJump);  // Not yet set.
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
  __ cmpq(cid1, Immediate(kClosureCid));
  __ j(EQUAL, normal_ir_body);

  // Check if left hand side is a record. Records are handled in the runtime.
  __ cmpq(cid1, Immediate(kRecordCid));
  __ j(EQUAL, normal_ir_body);

  // Check whether class ids match. If class ids don't match types may still be
  // considered equivalent (e.g. multiple string implementation classes map to a
  // single String type).
  __ cmpq(cid1, cid2);
  __ j(EQUAL, equal_may_be_generic);

  // Class ids are different. Check if we are comparing two string types (with
  // different representations), two integer types, two list types or two type
  // types.
  __ cmpq(cid1, Immediate(kNumPredefinedCids));
  __ j(ABOVE_EQUAL, not_equal);

  // Check if both are integer types.
  __ movq(scratch, cid1);
  JumpIfNotInteger(assembler, scratch, &not_integer);

  // First type is an integer. Check if the second is an integer too.
  __ movq(scratch, cid2);
  JumpIfInteger(assembler, scratch, equal_not_generic);
  // Integer types are only equivalent to other integer types.
  __ jmp(not_equal);

  __ Bind(&not_integer);
  // Check if both are String types.
  __ movq(scratch, cid1);
  JumpIfNotString(assembler, scratch,
                  testing_instance_cids ? &not_integer_or_string : not_equal);

  // First type is a String. Check if the second is a String too.
  __ movq(scratch, cid2);
  JumpIfString(assembler, scratch, equal_not_generic);
  // String types are only equivalent to other String types.
  __ jmp(not_equal);

  if (testing_instance_cids) {
    __ Bind(&not_integer_or_string);
    // Check if both are List types.
    __ movq(scratch, cid1);
    JumpIfNotList(assembler, scratch, &not_integer_or_string_or_list);

    // First type is a List. Check if the second is a List too.
    __ movq(scratch, cid2);
    JumpIfNotList(assembler, scratch, not_equal);
    ASSERT(compiler::target::Array::type_arguments_offset() ==
           compiler::target::GrowableObjectArray::type_arguments_offset());
    __ jmp(equal_may_be_generic);

    __ Bind(&not_integer_or_string_or_list);
    // Check if the first type is a Type. If it is not then types are not
    // equivalent because they have different class ids and they are not String
    // or integer or List or Type.
    __ movq(scratch, cid1);
    JumpIfNotType(assembler, scratch, not_equal);

    // First type is a Type. Check if the second is a Type too.
    __ movq(scratch, cid2);
    JumpIfType(assembler, scratch, equal_not_generic);
    // Type types are only equivalent to other Type types.
    __ jmp(not_equal);
  }
}

void AsmIntrinsifier::ObjectHaveSameRuntimeType(Assembler* assembler,
                                                Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));
  __ LoadClassIdMayBeSmi(RCX, RAX);

  __ movq(RAX, Address(RSP, +2 * target::kWordSize));
  __ LoadClassIdMayBeSmi(RDX, RAX);

  Label equal_may_be_generic, equal, not_equal;
  EquivalentClassIds(assembler, normal_ir_body, &equal_may_be_generic, &equal,
                     &not_equal, RCX, RDX, RAX,
                     /* testing_instance_cids = */ true);

  __ Bind(&equal_may_be_generic);
  // Classes are equivalent and neither is a closure class.
  // Check if there are no type arguments. In this case we can return true.
  // Otherwise fall through into the runtime to handle comparison.
  __ LoadClassById(RAX, RCX);
  __ movl(
      RAX,
      FieldAddress(
          RAX,
          target::Class::host_type_arguments_field_offset_in_words_offset()));
  __ cmpl(RAX, Immediate(target::Class::kNoTypeArguments));
  __ j(EQUAL, &equal);

  // Compare type arguments, host_type_arguments_field_offset_in_words in RAX.
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));
  __ movq(RDX, Address(RSP, +2 * target::kWordSize));
  __ OBJ(mov)(RCX, FieldAddress(RCX, RAX, TIMES_COMPRESSED_WORD_SIZE, 0));
  __ OBJ(mov)(RDX, FieldAddress(RDX, RAX, TIMES_COMPRESSED_WORD_SIZE, 0));
  __ OBJ(cmp)(RCX, RDX);
  __ j(NOT_EQUAL, normal_ir_body, Assembler::kNearJump);
  // Fall through to equal case if type arguments are equal.

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

void AsmIntrinsifier::Type_equality(Assembler* assembler,
                                    Label* normal_ir_body) {
  Label equal, not_equal, equiv_cids_may_be_generic, equiv_cids, check_legacy;

  __ movq(RCX, Address(RSP, +1 * target::kWordSize));
  __ movq(RDX, Address(RSP, +2 * target::kWordSize));
  __ OBJ(cmp)(RCX, RDX);
  __ j(EQUAL, &equal);

  // RCX might not be a Type object, so check that first (RDX should be though,
  // since this is a method on the Type class).
  __ LoadClassIdMayBeSmi(RAX, RCX);
  __ cmpq(RAX, Immediate(kTypeCid));
  __ j(NOT_EQUAL, normal_ir_body);

  // Check if types are syntactically equal.
  __ LoadTypeClassId(RDI, RCX);
  __ LoadTypeClassId(RSI, RDX);
  // We are not testing instance cids, but type class cids of Type instances.
  EquivalentClassIds(assembler, normal_ir_body, &equiv_cids_may_be_generic,
                     &equiv_cids, &not_equal, RDI, RSI, RAX,
                     /* testing_instance_cids = */ false);

  __ Bind(&equiv_cids_may_be_generic);
  // Compare type arguments in Type instances.
  __ LoadCompressed(RDI, FieldAddress(RCX, target::Type::arguments_offset()));
  __ LoadCompressed(RSI, FieldAddress(RDX, target::Type::arguments_offset()));
  __ cmpq(RDI, RSI);
  __ j(NOT_EQUAL, normal_ir_body, Assembler::kNearJump);
  // Fall through to check nullability if type arguments are equal.

  // Check nullability.
  __ Bind(&equiv_cids);
  __ LoadAbstractTypeNullability(RCX, RCX);
  __ LoadAbstractTypeNullability(RDX, RDX);
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

void AsmIntrinsifier::AbstractType_getHashCode(Assembler* assembler,
                                               Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));  // AbstractType object.
  __ LoadCompressedSmi(RAX,
                       FieldAddress(RAX, target::AbstractType::hash_offset()));
  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagShift == 1);
  __ OBJ(test)(RAX, RAX);
  __ j(ZERO, normal_ir_body, Assembler::kNearJump);
  __ ret();
  __ Bind(normal_ir_body);
  // Hash not yet computed.
}

void AsmIntrinsifier::AbstractType_equality(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));
  __ movq(RDX, Address(RSP, +2 * target::kWordSize));
  __ OBJ(cmp)(RCX, RDX);
  __ j(NOT_EQUAL, normal_ir_body);

  __ LoadObject(RAX, CastHandle<Object>(TrueObject()));
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
  __ movq(RAX, Address(RSP, +1 * target::kWordSize));  // Object.
  __ movl(RAX, FieldAddress(RAX, target::Object::tags_offset() +
                                     target::UntaggedObject::kHashTagPos /
                                         kBitsPerByte));
  __ cmpl(RAX, Immediate(0));
  __ j(EQUAL, &not_yet_computed, Assembler::kNearJump);
  __ SmiTag(RAX);
  __ ret();

  __ Bind(&not_yet_computed);
  __ movq(RCX, Address(THR, target::Thread::random_offset()));
  __ movq(RBX, RCX);
  __ andq(RCX, Immediate(0xffffffff));   // state_lo
  __ shrq(RBX, Immediate(32));           // state_hi
  __ imulq(RCX, Immediate(0xffffda61));  // A
  __ addq(RCX, RBX);                     // new_state = (A* state_lo) + state_hi
  __ movq(Address(THR, target::Thread::random_offset()), RCX);
  __ andq(RCX, Immediate(0x3fffffff));
  __ cmpl(RCX, Immediate(0));
  __ j(EQUAL, &not_yet_computed);

  __ movq(RBX, Address(RSP, +1 * target::kWordSize));  // Object.
  __ MoveRegister(RDX, RCX);
  __ shlq(RDX, Immediate(32));

  Label retry, success, already_in_rax;
  __ Bind(&retry);
  // RAX is used by "cmpxchgq" as comparison value (if comparison succeeds the
  // store is performed).
  __ movq(RAX, FieldAddress(RBX, 0));
  __ TestImmediate(RAX, Immediate(0xffffffff00000000));
  __ BranchIf(NOT_ZERO, &already_in_rax);
  __ MoveRegister(RSI, RAX);
  __ orq(RSI, RDX);
  __ LockCmpxchgq(FieldAddress(RBX, 0), RSI);
  __ BranchIf(NOT_ZERO, &retry);
  // Fall-through with RCX containing new hash value (untagged)
  __ Bind(&success);
  __ SmiTag(RCX);
  __ MoveRegister(RAX, RCX);
  __ Ret();

  __ Bind(&already_in_rax);
  __ shrq(RAX, Immediate(32));
  __ SmiTag(RAX);
  __ Ret();
}

void GenerateSubstringMatchesSpecialization(Assembler* assembler,
                                            intptr_t receiver_cid,
                                            intptr_t other_cid,
                                            Label* return_true,
                                            Label* return_false) {
  __ SmiUntag(RBX);
  __ LoadCompressedSmi(R8, FieldAddress(RAX, target::String::length_offset()));
  __ SmiUntag(R8);
  __ LoadCompressedSmi(R9, FieldAddress(RCX, target::String::length_offset()));
  __ SmiUntag(R9);

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
  __ OBJ(cmp)(RCX, FieldAddress(RAX, target::String::length_offset()));
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
#if defined(DART_COMPRESSED_POINTERS)
  // The upper half of a compressed Smi contains undefined bits, but no x64
  // addressing mode will ignore these bits. We have already checked the index
  // is positive, so we just clear the upper bits, which is shorter than movsxd.
  __ orl(RCX, RCX);
#endif
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
  __ LoadCompressedSmi(RAX, FieldAddress(RAX, target::String::length_offset()));
  __ OBJ(cmp)(RAX, Immediate(target::ToRawSmi(0)));
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
  __ LoadCompressedSmi(RCX, FieldAddress(RBX, target::String::length_offset()));
  __ SmiUntag(RCX);
  __ xorq(RAX, RAX);
  __ xorq(RDI, RDI);
  // RBX: Instance of target::OneByteString.
  // RCX: String length, untagged integer.
  // RDI: Loop counter, untagged integer.
  // RAX: Hash code, untagged integer.
  Label loop, done;
  __ Bind(&loop);
  __ cmpq(RDI, RCX);
  __ j(EQUAL, &done, Assembler::kNearJump);
  // Add to hash code: (hash_ is uint32)
  // Get one characters (ch).
  __ movzxb(RDX, FieldAddress(RBX, RDI, TIMES_1,
                              target::OneByteString::data_offset()));
  // RDX: ch and temporary.
  __ CombineHashes(RAX, RDX);

  __ incq(RDI);
  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&done);
  // Finalize and fit to size kHashBits. Ensures hash is non-zero.
  __ FinalizeHashForSize(target::String::kHashBits, RAX);
  __ shlq(RAX, Immediate(target::UntaggedObject::kHashTagPos));
  // lock+orq is an atomic read-modify-write.
  __ lock();
  __ orq(FieldAddress(RBX, target::Object::tags_offset()), RAX);
  __ sarq(RAX, Immediate(target::UntaggedObject::kHashTagPos));
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

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, failure));
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
  // Clear last double word to ensure string comparison doesn't need to
  // specially handle remainder of strings with lengths not factors of double
  // offsets.
  ASSERT(target::kWordSize == 8);
  __ movq(Address(RCX, -1 * target::kWordSize), Immediate(0));
  __ movq(Address(RCX, -2 * target::kWordSize), Immediate(0));

  // Initialize the tags.
  // RAX: new object start as a tagged pointer.
  // RDI: allocation size.
  {
    Label size_tag_overflow, done;
    __ cmpq(RDI, Immediate(target::UntaggedObject::kSizeTagMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shlq(RDI, Immediate(target::UntaggedObject::kTagBitsSizeTagPos -
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
#if DART_COMPRESSED_POINTERS
  // Clear out padding caused by alignment gap between length and data.
  __ movq(FieldAddress(RAX, target::String::length_offset()),
          compiler::Immediate(0));
#endif
  __ StoreCompressedIntoObjectNoBarrier(
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
          ByteRegisterOf(RBX));
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
          ByteRegisterOf(RCX));
  __ ret();
}

void AsmIntrinsifier::WriteIntoTwoByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));  // Value.
  __ movq(RBX, Address(RSP, +2 * target::kWordSize));  // Index.
  __ movq(RAX, Address(RSP, +3 * target::kWordSize));  // target::TwoByteString.
  // Untag index and multiply by element size -> no-op.
  __ SmiUntag(RCX);
#if defined(DART_COMPRESSED_POINTERS)
  // The upper half of a compressed Smi contains undefined bits, but no x64
  // addressing mode will ignore these bits. We know the index is positive, so
  // we just clear the upper bits, which is shorter than movsxd.
  __ orl(RBX, RBX);
#endif
  __ movw(FieldAddress(RAX, RBX, TIMES_1, target::TwoByteString::data_offset()),
          RCX);
  __ ret();
}

void AsmIntrinsifier::AllocateOneByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ movq(RDI, Address(RSP, +1 * target::kWordSize));  // Length.
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RDI, RDI);
#endif
  Label ok;
  TryAllocateString(assembler, kOneByteStringCid, &ok, normal_ir_body, RDI);
  // RDI: Start address to copy from (untagged).

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AllocateTwoByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ movq(RDI, Address(RSP, +1 * target::kWordSize));  // Length.
#if defined(DART_COMPRESSED_POINTERS)
  __ movsxd(RDI, RDI);
#endif
  Label ok;
  TryAllocateString(assembler, kTwoByteStringCid, &ok, normal_ir_body, RDI);
  // RDI: Start address to copy from (untagged).

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::OneByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // This.
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));  // Other.

  StringEquality(assembler, RAX, RCX, RDI, RBX, RAX, normal_ir_body,
                 kOneByteStringCid);
}

void AsmIntrinsifier::TwoByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ movq(RAX, Address(RSP, +2 * target::kWordSize));  // This.
  __ movq(RCX, Address(RSP, +1 * target::kWordSize));  // Other.

  StringEquality(assembler, RAX, RCX, RDI, RBX, RAX, normal_ir_body,
                 kTwoByteStringCid);
}

void AsmIntrinsifier::IntrinsifyRegExpExecuteMatch(Assembler* assembler,
                                                   Label* normal_ir_body,
                                                   bool sticky) {
  if (FLAG_interpret_irregexp) return;

  const intptr_t kRegExpParamOffset = 3 * target::kWordSize;
  const intptr_t kStringParamOffset = 2 * target::kWordSize;
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
#if !defined(DART_COMPRESSED_POINTERS)
  __ movq(FUNCTION_REG, FieldAddress(RBX, RDI, TIMES_8,
                                     target::RegExp::function_offset(
                                         kOneByteStringCid, sticky)));
#else
  __ LoadCompressed(FUNCTION_REG, FieldAddress(RBX, RDI, TIMES_4,
                                               target::RegExp::function_offset(
                                                   kOneByteStringCid, sticky)));
#endif

  // Registers are now set up for the lazy compile stub. It expects the function
  // in RAX, the argument descriptor in R10, and IC-Data in RCX.
  __ xorq(RCX, RCX);

  // Tail-call the function.
  __ LoadCompressed(
      CODE_REG, FieldAddress(FUNCTION_REG, target::Function::code_offset()));
  __ movq(RDI,
          FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
  __ jmp(RDI);
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

void AsmIntrinsifier::Timeline_getNextTaskId(Assembler* assembler,
                                             Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ xorq(RAX, RAX);  // Return Smi 0.
  __ ret();
#else
  __ movq(RAX, Address(THR, target::Thread::next_task_id_offset()));
  __ movq(RBX, RAX);
  __ incq(RBX);
  __ movq(Address(THR, target::Thread::next_task_id_offset()), RBX);
  __ SmiTag(RAX);  // Ignore loss of precision.
  __ ret();
#endif
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_X64)
