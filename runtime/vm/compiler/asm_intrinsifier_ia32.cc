// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// The intrinsic code below is executed before a method has built its frame.
// The return address is on the stack and the arguments below it.
// Registers EDX (arguments descriptor) and ECX (function) must be preserved.
// Each intrinsification method returns true if the corresponding
// Dart method was intrinsified.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/asm_intrinsifier.h"
#include "vm/compiler/assembler/assembler.h"

namespace dart {
namespace compiler {

// When entering intrinsics code:
// ECX: IC Data
// EDX: Arguments descriptor
// TOS: Return address
// The ECX, EDX registers can be destroyed only if there is no slow-path, i.e.
// if the intrinsified method always executes a return.
// The EBP register should not be modified, because it is used by the profiler.
// The THR register (see constants_ia32.h) must be preserved.

#define __ assembler->

// Tests if two top most arguments are smis, jumps to label not_smi if not.
// Topmost argument is in EAX.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ movl(EBX, Address(ESP, +2 * target::kWordSize));
  __ orl(EBX, EAX);
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, not_smi, Assembler::kNearJump);
}

void AsmIntrinsifier::Integer_shl(Assembler* assembler, Label* normal_ir_body) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(kSmiTag == 0);
  Label overflow;
  TestBothArgumentsSmis(assembler, normal_ir_body);
  // Shift value is in EAX. Compare with tagged Smi.
  __ cmpl(EAX, Immediate(target::ToRawSmi(target::kSmiBits)));
  __ j(ABOVE_EQUAL, normal_ir_body, Assembler::kNearJump);

  __ SmiUntag(EAX);
  __ movl(ECX, EAX);  // Shift amount must be in ECX.
  __ movl(EAX, Address(ESP, +2 * target::kWordSize));  // Value.

  // Overflow test - all the shifted-out bits must be same as the sign bit.
  __ movl(EBX, EAX);
  __ shll(EAX, ECX);
  __ sarl(EAX, ECX);
  __ cmpl(EAX, EBX);
  __ j(NOT_EQUAL, &overflow, Assembler::kNearJump);

  __ shll(EAX, ECX);  // Shift for result now we know there is no overflow.

  // EAX is a correctly tagged Smi.
  __ ret();

  __ Bind(&overflow);
  // Arguments are Smi but the shift produced an overflow to Mint.
  __ cmpl(EBX, Immediate(0));
  // TODO(srdjan): Implement negative values, for now fall through.
  __ j(LESS, normal_ir_body, Assembler::kNearJump);
  __ SmiUntag(EBX);
  __ movl(EAX, EBX);
  __ shll(EBX, ECX);
  __ xorl(EDI, EDI);
  __ shldl(EDI, EAX, ECX);
  // Result in EDI (high) and EBX (low).
  const Class& mint_class = MintClass();
  __ TryAllocate(mint_class, normal_ir_body, Assembler::kNearJump,
                 EAX,   // Result register.
                 ECX);  // temp
  // EBX and EDI are not objects but integer values.
  __ movl(FieldAddress(EAX, target::Mint::value_offset()), EBX);
  __ movl(FieldAddress(EAX, target::Mint::value_offset() + target::kWordSize),
          EDI);
  __ ret();
  __ Bind(normal_ir_body);
}

static void Push64SmiOrMint(Assembler* assembler,
                            Register reg,
                            Register tmp,
                            Label* not_smi_or_mint) {
  Label not_smi, done;
  __ testl(reg, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
  __ SmiUntag(reg);
  // Sign extend to 64 bit
  __ movl(tmp, reg);
  __ sarl(tmp, Immediate(31));
  __ pushl(tmp);
  __ pushl(reg);
  __ jmp(&done);
  __ Bind(&not_smi);
  __ CompareClassId(reg, kMintCid, tmp);
  __ j(NOT_EQUAL, not_smi_or_mint);
  // Mint.
  __ pushl(FieldAddress(reg, target::Mint::value_offset() + target::kWordSize));
  __ pushl(FieldAddress(reg, target::Mint::value_offset()));
  __ Bind(&done);
}

static void CompareIntegers(Assembler* assembler,
                            Label* normal_ir_body,
                            Condition true_condition) {
  Label try_mint_smi, is_true, is_false, drop_two_fall_through, fall_through;
  TestBothArgumentsSmis(assembler, &try_mint_smi);
  // EAX contains the right argument.
  __ cmpl(Address(ESP, +2 * target::kWordSize), EAX);
  __ j(true_condition, &is_true, Assembler::kNearJump);
  __ Bind(&is_false);
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();

  // 64-bit comparison
  Condition hi_true_cond, hi_false_cond, lo_false_cond;
  switch (true_condition) {
    case LESS:
    case LESS_EQUAL:
      hi_true_cond = LESS;
      hi_false_cond = GREATER;
      lo_false_cond = (true_condition == LESS) ? ABOVE_EQUAL : ABOVE;
      break;
    case GREATER:
    case GREATER_EQUAL:
      hi_true_cond = GREATER;
      hi_false_cond = LESS;
      lo_false_cond = (true_condition == GREATER) ? BELOW_EQUAL : BELOW;
      break;
    default:
      UNREACHABLE();
      hi_true_cond = hi_false_cond = lo_false_cond = OVERFLOW;
  }
  __ Bind(&try_mint_smi);
  // Note that EDX and ECX must be preserved in case we fall through to main
  // method.
  // EAX contains the right argument.
  __ movl(EBX, Address(ESP, +2 * target::kWordSize));  // Left argument.
  // Push left as 64 bit integer.
  Push64SmiOrMint(assembler, EBX, EDI, normal_ir_body);
  // Push right as 64 bit integer.
  Push64SmiOrMint(assembler, EAX, EDI, &drop_two_fall_through);
  __ popl(EBX);       // Right.LO.
  __ popl(ECX);       // Right.HI.
  __ popl(EAX);       // Left.LO.
  __ popl(EDX);       // Left.HI.
  __ cmpl(EDX, ECX);  // cmpl left.HI, right.HI.
  __ j(hi_false_cond, &is_false, Assembler::kNearJump);
  __ j(hi_true_cond, &is_true, Assembler::kNearJump);
  __ cmpl(EAX, EBX);  // cmpl left.LO, right.LO.
  __ j(lo_false_cond, &is_false, Assembler::kNearJump);
  // Else is true.
  __ jmp(&is_true);

  __ Bind(&drop_two_fall_through);
  __ Drop(2);
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
  // For integer receiver '===' check first.
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ cmpl(EAX, Address(ESP, +2 * target::kWordSize));
  __ j(EQUAL, &true_label, Assembler::kNearJump);
  __ movl(EBX, Address(ESP, +2 * target::kWordSize));
  __ orl(EAX, EBX);
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &check_for_mint, Assembler::kNearJump);
  // Both arguments are smi, '===' is good enough.
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);
  __ movl(EAX, Address(ESP, +2 * target::kWordSize));  // Receiver.
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &receiver_not_smi);

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint never contains a value that can be
  // represented by Smi.
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));  // Right argument.
  __ CompareClassId(EAX, kDoubleCid, EDI);
  __ j(EQUAL, normal_ir_body);
  __ LoadObject(EAX,
                CastHandle<Object>(FalseObject()));  // Smi == Mint -> false.
  __ ret();

  __ Bind(&receiver_not_smi);
  // EAX:: receiver.
  __ CompareClassId(EAX, kMintCid, EDI);
  __ j(NOT_EQUAL, normal_ir_body);
  // Receiver is Mint, return false if right is Smi.
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));  // Right argument.
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body);
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
  // TODO(srdjan): Implement Mint == Mint comparison.

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Integer_equal(Assembler* assembler,
                                    Label* normal_ir_body) {
  Integer_equalToInteger(assembler, normal_ir_body);
}

// Argument is Smi (receiver).
void AsmIntrinsifier::Smi_bitLength(Assembler* assembler,
                                    Label* normal_ir_body) {
  ASSERT(kSmiTagShift == 1);
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));  // Receiver.
  // XOR with sign bit to complement bits if value is negative.
  __ movl(ECX, EAX);
  __ sarl(ECX, Immediate(31));  // All 0 or all 1.
  __ xorl(EAX, ECX);
  // BSR does not write the destination register if source is zero.  Put a 1 in
  // the Smi tag bit to ensure BSR writes to destination register.
  __ orl(EAX, Immediate(kSmiTagMask));
  __ bsrl(EAX, EAX);
  __ SmiTag(EAX);
  __ ret();
}

void AsmIntrinsifier::Bigint_lsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // Preserve THR to free ESI.
  __ pushl(THR);
  ASSERT(THR == ESI);

  __ movl(EDI, Address(ESP, 5 * target::kWordSize));  // x_digits
  __ movl(ECX, Address(ESP, 3 * target::kWordSize));  // n is Smi
  __ SmiUntag(ECX);
  __ movl(EBX, Address(ESP, 2 * target::kWordSize));  // r_digits
  __ movl(ESI, ECX);
  __ sarl(ESI, Immediate(5));  // ESI = n ~/ _DIGIT_BITS.
  __ leal(EBX,
          FieldAddress(EBX, ESI, TIMES_4, target::TypedData::payload_offset()));
  __ movl(ESI, Address(ESP, 4 * target::kWordSize));  // x_used > 0, Smi.
  __ SmiUntag(ESI);
  __ decl(ESI);
  __ xorl(EAX, EAX);  // EAX = 0.
  __ movl(EDX,
          FieldAddress(EDI, ESI, TIMES_4, target::TypedData::payload_offset()));
  __ shldl(EAX, EDX, ECX);
  __ movl(Address(EBX, ESI, TIMES_4, kBytesPerBigIntDigit), EAX);
  Label last;
  __ cmpl(ESI, Immediate(0));
  __ j(EQUAL, &last, Assembler::kNearJump);
  Label loop;
  __ Bind(&loop);
  __ movl(EAX, EDX);
  __ movl(EDX, FieldAddress(
                   EDI, ESI, TIMES_4,
                   target::TypedData::payload_offset() - kBytesPerBigIntDigit));
  __ shldl(EAX, EDX, ECX);
  __ movl(Address(EBX, ESI, TIMES_4, 0), EAX);
  __ decl(ESI);
  __ j(NOT_ZERO, &loop, Assembler::kNearJump);
  __ Bind(&last);
  __ shldl(EDX, ESI, ECX);  // ESI == 0.
  __ movl(Address(EBX, 0), EDX);

  // Restore THR and return.
  __ popl(THR);
  __ LoadObject(EAX, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_rsh(Assembler* assembler, Label* normal_ir_body) {
  // static void _rsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // Preserve THR to free ESI.
  __ pushl(THR);
  ASSERT(THR == ESI);

  __ movl(EDI, Address(ESP, 5 * target::kWordSize));  // x_digits
  __ movl(ECX, Address(ESP, 3 * target::kWordSize));  // n is Smi
  __ SmiUntag(ECX);
  __ movl(EBX, Address(ESP, 2 * target::kWordSize));  // r_digits
  __ movl(EDX, ECX);
  __ sarl(EDX, Immediate(5));                         // EDX = n ~/ _DIGIT_BITS.
  __ movl(ESI, Address(ESP, 4 * target::kWordSize));  // x_used > 0, Smi.
  __ SmiUntag(ESI);
  __ decl(ESI);
  // EDI = &x_digits[x_used - 1].
  __ leal(EDI,
          FieldAddress(EDI, ESI, TIMES_4, target::TypedData::payload_offset()));
  __ subl(ESI, EDX);
  // EBX = &r_digits[x_used - 1 - (n ~/ 32)].
  __ leal(EBX,
          FieldAddress(EBX, ESI, TIMES_4, target::TypedData::payload_offset()));
  __ negl(ESI);
  __ movl(EDX, Address(EDI, ESI, TIMES_4, 0));
  Label last;
  __ cmpl(ESI, Immediate(0));
  __ j(EQUAL, &last, Assembler::kNearJump);
  Label loop;
  __ Bind(&loop);
  __ movl(EAX, EDX);
  __ movl(EDX, Address(EDI, ESI, TIMES_4, kBytesPerBigIntDigit));
  __ shrdl(EAX, EDX, ECX);
  __ movl(Address(EBX, ESI, TIMES_4, 0), EAX);
  __ incl(ESI);
  __ j(NOT_ZERO, &loop, Assembler::kNearJump);
  __ Bind(&last);
  __ shrdl(EDX, ESI, ECX);  // ESI == 0.
  __ movl(Address(EBX, 0), EDX);

  // Restore THR and return.
  __ popl(THR);
  __ LoadObject(EAX, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_absAdd(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absAdd(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // Preserve THR to free ESI.
  __ pushl(THR);
  ASSERT(THR == ESI);

  __ movl(EDI, Address(ESP, 6 * target::kWordSize));  // digits
  __ movl(EAX, Address(ESP, 5 * target::kWordSize));  // used is Smi
  __ SmiUntag(EAX);                                   // used > 0.
  __ movl(ESI, Address(ESP, 4 * target::kWordSize));  // a_digits
  __ movl(ECX, Address(ESP, 3 * target::kWordSize));  // a_used is Smi
  __ SmiUntag(ECX);                                   // a_used > 0.
  __ movl(EBX, Address(ESP, 2 * target::kWordSize));  // r_digits

  // Precompute 'used - a_used' now so that carry flag is not lost later.
  __ subl(EAX, ECX);
  __ incl(EAX);  // To account for the extra test between loops.
  __ pushl(EAX);

  __ xorl(EDX, EDX);  // EDX = 0, carry flag = 0.
  Label add_loop;
  __ Bind(&add_loop);
  // Loop a_used times, ECX = a_used, ECX > 0.
  __ movl(EAX,
          FieldAddress(EDI, EDX, TIMES_4, target::TypedData::payload_offset()));
  __ adcl(EAX,
          FieldAddress(ESI, EDX, TIMES_4, target::TypedData::payload_offset()));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, target::TypedData::payload_offset()),
          EAX);
  __ incl(EDX);  // Does not affect carry flag.
  __ decl(ECX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &add_loop, Assembler::kNearJump);

  Label last_carry;
  __ popl(ECX);
  __ decl(ECX);                                   // Does not affect carry flag.
  __ j(ZERO, &last_carry, Assembler::kNearJump);  // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop used - a_used times, ECX = used - a_used, ECX > 0.
  __ movl(EAX,
          FieldAddress(EDI, EDX, TIMES_4, target::TypedData::payload_offset()));
  __ adcl(EAX, Immediate(0));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, target::TypedData::payload_offset()),
          EAX);
  __ incl(EDX);  // Does not affect carry flag.
  __ decl(ECX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &carry_loop, Assembler::kNearJump);

  __ Bind(&last_carry);
  __ movl(EAX, Immediate(0));
  __ adcl(EAX, Immediate(0));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, target::TypedData::payload_offset()),
          EAX);

  // Restore THR and return.
  __ popl(THR);
  __ LoadObject(EAX, NullObject());
  __ ret();
}

void AsmIntrinsifier::Bigint_absSub(Assembler* assembler,
                                    Label* normal_ir_body) {
  // static void _absSub(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // Preserve THR to free ESI.
  __ pushl(THR);
  ASSERT(THR == ESI);

  __ movl(EDI, Address(ESP, 6 * target::kWordSize));  // digits
  __ movl(EAX, Address(ESP, 5 * target::kWordSize));  // used is Smi
  __ SmiUntag(EAX);                                   // used > 0.
  __ movl(ESI, Address(ESP, 4 * target::kWordSize));  // a_digits
  __ movl(ECX, Address(ESP, 3 * target::kWordSize));  // a_used is Smi
  __ SmiUntag(ECX);                                   // a_used > 0.
  __ movl(EBX, Address(ESP, 2 * target::kWordSize));  // r_digits

  // Precompute 'used - a_used' now so that carry flag is not lost later.
  __ subl(EAX, ECX);
  __ incl(EAX);  // To account for the extra test between loops.
  __ pushl(EAX);

  __ xorl(EDX, EDX);  // EDX = 0, carry flag = 0.
  Label sub_loop;
  __ Bind(&sub_loop);
  // Loop a_used times, ECX = a_used, ECX > 0.
  __ movl(EAX,
          FieldAddress(EDI, EDX, TIMES_4, target::TypedData::payload_offset()));
  __ sbbl(EAX,
          FieldAddress(ESI, EDX, TIMES_4, target::TypedData::payload_offset()));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, target::TypedData::payload_offset()),
          EAX);
  __ incl(EDX);  // Does not affect carry flag.
  __ decl(ECX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &sub_loop, Assembler::kNearJump);

  Label done;
  __ popl(ECX);
  __ decl(ECX);                             // Does not affect carry flag.
  __ j(ZERO, &done, Assembler::kNearJump);  // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop used - a_used times, ECX = used - a_used, ECX > 0.
  __ movl(EAX,
          FieldAddress(EDI, EDX, TIMES_4, target::TypedData::payload_offset()));
  __ sbbl(EAX, Immediate(0));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, target::TypedData::payload_offset()),
          EAX);
  __ incl(EDX);  // Does not affect carry flag.
  __ decl(ECX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &carry_loop, Assembler::kNearJump);

  __ Bind(&done);
  // Restore THR and return.
  __ popl(THR);
  __ LoadObject(EAX, NullObject());
  __ ret();
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

  Label no_op;
  // EBX = x, no_op if x == 0
  __ movl(ECX, Address(ESP, 7 * target::kWordSize));  // x_digits
  __ movl(EAX, Address(ESP, 6 * target::kWordSize));  // xi is Smi
  __ movl(EBX,
          FieldAddress(ECX, EAX, TIMES_2, target::TypedData::payload_offset()));
  __ testl(EBX, EBX);
  __ j(ZERO, &no_op, Assembler::kNearJump);

  // EDX = SmiUntag(n), no_op if n == 0
  __ movl(EDX, Address(ESP, 1 * target::kWordSize));
  __ SmiUntag(EDX);
  __ j(ZERO, &no_op, Assembler::kNearJump);

  // Preserve THR to free ESI.
  __ pushl(THR);
  ASSERT(THR == ESI);

  // EDI = mip = &m_digits[i >> 1]
  __ movl(EDI, Address(ESP, 6 * target::kWordSize));  // m_digits
  __ movl(EAX, Address(ESP, 5 * target::kWordSize));  // i is Smi
  __ leal(EDI,
          FieldAddress(EDI, EAX, TIMES_2, target::TypedData::payload_offset()));

  // ESI = ajp = &a_digits[j >> 1]
  __ movl(ESI, Address(ESP, 4 * target::kWordSize));  // a_digits
  __ movl(EAX, Address(ESP, 3 * target::kWordSize));  // j is Smi
  __ leal(ESI,
          FieldAddress(ESI, EAX, TIMES_2, target::TypedData::payload_offset()));

  // Save n
  __ pushl(EDX);
  Address n_addr = Address(ESP, 0 * target::kWordSize);

  // ECX = c = 0
  __ xorl(ECX, ECX);

  Label muladd_loop;
  __ Bind(&muladd_loop);
  // x:   EBX
  // mip: EDI
  // ajp: ESI
  // c:   ECX
  // t:   EDX:EAX (not live at loop entry)
  // n:   ESP[0]

  // uint32_t mi = *mip++
  __ movl(EAX, Address(EDI, 0));
  __ addl(EDI, Immediate(kBytesPerBigIntDigit));

  // uint64_t t = x*mi
  __ mull(EBX);       // t = EDX:EAX = EAX * EBX
  __ addl(EAX, ECX);  // t += c
  __ adcl(EDX, Immediate(0));

  // uint32_t aj = *ajp; t += aj
  __ addl(EAX, Address(ESI, 0));
  __ adcl(EDX, Immediate(0));

  // *ajp++ = low32(t)
  __ movl(Address(ESI, 0), EAX);
  __ addl(ESI, Immediate(kBytesPerBigIntDigit));

  // c = high32(t)
  __ movl(ECX, EDX);

  // while (--n > 0)
  __ decl(n_addr);  // --n
  __ j(NOT_ZERO, &muladd_loop, Assembler::kNearJump);

  Label done;
  __ testl(ECX, ECX);
  __ j(ZERO, &done, Assembler::kNearJump);

  // *ajp += c
  __ addl(Address(ESI, 0), ECX);
  __ j(NOT_CARRY, &done, Assembler::kNearJump);

  Label propagate_carry_loop;
  __ Bind(&propagate_carry_loop);
  __ addl(ESI, Immediate(kBytesPerBigIntDigit));
  __ incl(Address(ESI, 0));  // c == 0 or 1
  __ j(CARRY, &propagate_carry_loop, Assembler::kNearJump);

  __ Bind(&done);
  __ Drop(1);  // n
  // Restore THR and return.
  __ popl(THR);

  __ Bind(&no_op);
  __ movl(EAX, Immediate(target::ToRawSmi(1)));  // One digit processed.
  __ ret();
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

  // EDI = xip = &x_digits[i >> 1]
  __ movl(EDI, Address(ESP, 4 * target::kWordSize));  // x_digits
  __ movl(EAX, Address(ESP, 3 * target::kWordSize));  // i is Smi
  __ leal(EDI,
          FieldAddress(EDI, EAX, TIMES_2, target::TypedData::payload_offset()));

  // EBX = x = *xip++, return if x == 0
  Label x_zero;
  __ movl(EBX, Address(EDI, 0));
  __ cmpl(EBX, Immediate(0));
  __ j(EQUAL, &x_zero, Assembler::kNearJump);
  __ addl(EDI, Immediate(kBytesPerBigIntDigit));

  // Preserve THR to free ESI.
  __ pushl(THR);
  ASSERT(THR == ESI);

  // ESI = ajp = &a_digits[i]
  __ movl(ESI, Address(ESP, 3 * target::kWordSize));  // a_digits
  __ leal(ESI,
          FieldAddress(ESI, EAX, TIMES_4, target::TypedData::payload_offset()));

  // EDX:EAX = t = x*x + *ajp
  __ movl(EAX, EBX);
  __ mull(EBX);
  __ addl(EAX, Address(ESI, 0));
  __ adcl(EDX, Immediate(0));

  // *ajp++ = low32(t)
  __ movl(Address(ESI, 0), EAX);
  __ addl(ESI, Immediate(kBytesPerBigIntDigit));

  // int n = used - i - 1
  __ movl(EAX, Address(ESP, 2 * target::kWordSize));  // used is Smi
  __ subl(EAX, Address(ESP, 4 * target::kWordSize));  // i is Smi
  __ SmiUntag(EAX);
  __ decl(EAX);
  __ pushl(EAX);  // Save n on stack.

  // uint64_t c = high32(t)
  __ pushl(Immediate(0));  // push high32(c) == 0
  __ pushl(EDX);           // push low32(c) == high32(t)

  Address n_addr = Address(ESP, 2 * target::kWordSize);
  Address ch_addr = Address(ESP, 1 * target::kWordSize);
  Address cl_addr = Address(ESP, 0 * target::kWordSize);

  Label loop, done;
  __ Bind(&loop);
  // x:   EBX
  // xip: EDI
  // ajp: ESI
  // c:   ESP[1]:ESP[0]
  // t:   ECX:EDX:EAX (not live at loop entry)
  // n:   ESP[2]

  // while (--n >= 0)
  __ decl(Address(ESP, 2 * target::kWordSize));  // --n
  __ j(NEGATIVE, &done, Assembler::kNearJump);

  // uint32_t xi = *xip++
  __ movl(EAX, Address(EDI, 0));
  __ addl(EDI, Immediate(kBytesPerBigIntDigit));

  // uint96_t t = ECX:EDX:EAX = 2*x*xi + aj + c
  __ mull(EBX);       // EDX:EAX = EAX * EBX
  __ xorl(ECX, ECX);  // ECX = 0
  __ shldl(ECX, EDX, Immediate(1));
  __ shldl(EDX, EAX, Immediate(1));
  __ shll(EAX, Immediate(1));     // ECX:EDX:EAX <<= 1
  __ addl(EAX, Address(ESI, 0));  // t += aj
  __ adcl(EDX, Immediate(0));
  __ adcl(ECX, Immediate(0));
  __ addl(EAX, cl_addr);  // t += low32(c)
  __ adcl(EDX, ch_addr);  // t += high32(c) << 32
  __ adcl(ECX, Immediate(0));

  // *ajp++ = low32(t)
  __ movl(Address(ESI, 0), EAX);
  __ addl(ESI, Immediate(kBytesPerBigIntDigit));

  // c = high64(t)
  __ movl(cl_addr, EDX);
  __ movl(ch_addr, ECX);

  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&done);
  // uint64_t t = aj + c
  __ movl(EAX, cl_addr);  // t = c
  __ movl(EDX, ch_addr);
  __ addl(EAX, Address(ESI, 0));  // t += *ajp
  __ adcl(EDX, Immediate(0));

  // *ajp++ = low32(t)
  // *ajp = high32(t)
  __ movl(Address(ESI, 0), EAX);
  __ movl(Address(ESI, kBytesPerBigIntDigit), EDX);

  // Restore THR and return.
  __ Drop(3);
  __ popl(THR);
  __ Bind(&x_zero);
  __ movl(EAX, Immediate(target::ToRawSmi(1)));  // One digit processed.
  __ ret();
}

void AsmIntrinsifier::Bigint_estimateQuotientDigit(Assembler* assembler,
                                                   Label* normal_ir_body) {
  // Pseudo code:
  // static int _estQuotientDigit(Uint32List args, Uint32List digits, int i) {
  //   uint32_t yt = args[_YT];  // _YT == 1.
  //   uint32_t* dp = &digits[i >> 1];  // i is Smi.
  //   uint32_t dh = dp[0];  // dh == digits[i >> 1].
  //   uint32_t qd;
  //   if (dh == yt) {
  //     qd = DIGIT_MASK;
  //   } else {
  //     dl = dp[-1];  // dl == digits[(i - 1) >> 1].
  //     qd = dh:dl / yt;  // No overflow possible, because dh < yt.
  //   }
  //   args[_QD] = qd;  // _QD == 2.
  //   return 1;
  // }

  // EDI = args
  __ movl(EDI, Address(ESP, 3 * target::kWordSize));  // args

  // ECX = yt = args[1]
  __ movl(ECX, FieldAddress(EDI, target::TypedData::payload_offset() +
                                     kBytesPerBigIntDigit));

  // EBX = dp = &digits[i >> 1]
  __ movl(EBX, Address(ESP, 2 * target::kWordSize));  // digits
  __ movl(EAX, Address(ESP, 1 * target::kWordSize));  // i is Smi
  __ leal(EBX,
          FieldAddress(EBX, EAX, TIMES_2, target::TypedData::payload_offset()));

  // EDX = dh = dp[0]
  __ movl(EDX, Address(EBX, 0));

  // EAX = qd = DIGIT_MASK = -1
  __ movl(EAX, Immediate(-1));

  // Return qd if dh == yt
  Label return_qd;
  __ cmpl(EDX, ECX);
  __ j(EQUAL, &return_qd, Assembler::kNearJump);

  // EAX = dl = dp[-1]
  __ movl(EAX, Address(EBX, -kBytesPerBigIntDigit));

  // EAX = qd = dh:dl / yt = EDX:EAX / ECX
  __ divl(ECX);

  __ Bind(&return_qd);
  // args[2] = qd
  __ movl(FieldAddress(EDI, target::TypedData::payload_offset() +
                                2 * kBytesPerBigIntDigit),
          EAX);

  __ movl(EAX, Immediate(target::ToRawSmi(1)));  // One digit processed.
  __ ret();
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

  // EDI = args
  __ movl(EDI, Address(ESP, 3 * target::kWordSize));  // args

  // ECX = rho = args[2]
  __ movl(ECX, FieldAddress(EDI, target::TypedData::payload_offset() +
                                     2 * kBytesPerBigIntDigit));

  // EAX = digits[i >> 1]
  __ movl(EBX, Address(ESP, 2 * target::kWordSize));  // digits
  __ movl(EAX, Address(ESP, 1 * target::kWordSize));  // i is Smi
  __ movl(EAX,
          FieldAddress(EBX, EAX, TIMES_2, target::TypedData::payload_offset()));

  // EDX:EAX = t = rho*d
  __ mull(ECX);

  // args[4] = t mod DIGIT_BASE = low32(t)
  __ movl(FieldAddress(EDI, target::TypedData::payload_offset() +
                                4 * kBytesPerBigIntDigit),
          EAX);

  __ movl(EAX, Immediate(target::ToRawSmi(1)));  // One digit processed.
  __ ret();
}

// Check if the last argument is a double, jump to label 'is_smi' if smi
// (easy to convert to double), otherwise jump to label 'not_double_smi',
// Returns the last argument in EAX.
static void TestLastArgumentIsDouble(Assembler* assembler,
                                     Label* is_smi,
                                     Label* not_double_smi) {
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(ZERO, is_smi, Assembler::kNearJump);  // Jump if Smi.
  __ CompareClassId(EAX, kDoubleCid, EBX);
  __ j(NOT_EQUAL, not_double_smi, Assembler::kNearJump);
  // Fall through if double.
}

// Both arguments on stack, arg0 (left) is a double, arg1 (right) is of unknown
// type. Return true or false object in the register EAX. Any NaN argument
// returns false. Any non-double arg1 causes control flow to fall through to the
// slow case (compiled method body).
static void CompareDoubles(Assembler* assembler,
                           Label* normal_ir_body,
                           Condition true_condition) {
  Label is_false, is_true, is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, normal_ir_body);
  // Both arguments are double, right operand is in EAX.
  __ movsd(XMM1, FieldAddress(EAX, target::Double::value_offset()));
  __ Bind(&double_op);
  __ movl(EAX, Address(ESP, +2 * target::kWordSize));  // Left argument.
  __ movsd(XMM0, FieldAddress(EAX, target::Double::value_offset()));
  __ comisd(XMM0, XMM1);
  __ j(PARITY_EVEN, &is_false, Assembler::kNearJump);  // NaN -> false;
  __ j(true_condition, &is_true, Assembler::kNearJump);
  // Fall through false.
  __ Bind(&is_false);
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();
  __ Bind(&is_smi);
  __ SmiUntag(EAX);
  __ cvtsi2sd(XMM1, EAX);
  __ jmp(&double_op);
  __ Bind(normal_ir_body);
}

// arg0 is Double, arg1 is unknown.
void AsmIntrinsifier::Double_greaterThan(Assembler* assembler,
                                         Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, ABOVE);
}

// arg0 is Double, arg1 is unknown.
void AsmIntrinsifier::Double_greaterEqualThan(Assembler* assembler,
                                              Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, ABOVE_EQUAL);
}

// arg0 is Double, arg1 is unknown.
void AsmIntrinsifier::Double_lessThan(Assembler* assembler,
                                      Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, BELOW);
}

// arg0 is Double, arg1 is unknown.
void AsmIntrinsifier::Double_equal(Assembler* assembler,
                                   Label* normal_ir_body) {
  CompareDoubles(assembler, normal_ir_body, EQUAL);
}

// arg0 is Double, arg1 is unknown.
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
  // Both arguments are double, right operand is in EAX.
  __ movsd(XMM1, FieldAddress(EAX, target::Double::value_offset()));
  __ Bind(&double_op);
  __ movl(EAX, Address(ESP, +2 * target::kWordSize));  // Left argument.
  __ movsd(XMM0, FieldAddress(EAX, target::Double::value_offset()));
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
  __ TryAllocate(double_class, normal_ir_body, Assembler::kNearJump,
                 EAX,  // Result register.
                 EBX);
  __ movsd(FieldAddress(EAX, target::Double::value_offset()), XMM0);
  __ ret();
  __ Bind(&is_smi);
  __ SmiUntag(EAX);
  __ cvtsi2sd(XMM1, EAX);
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

// Left is double, right is integer (Mint or Smi)
void AsmIntrinsifier::Double_mulFromInteger(Assembler* assembler,
                                            Label* normal_ir_body) {
  // Only smis allowed.
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body, Assembler::kNearJump);
  // Is Smi.
  __ SmiUntag(EAX);
  __ cvtsi2sd(XMM1, EAX);
  __ movl(EAX, Address(ESP, +2 * target::kWordSize));
  __ movsd(XMM0, FieldAddress(EAX, target::Double::value_offset()));
  __ mulsd(XMM0, XMM1);
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kNearJump,
                 EAX,  // Result register.
                 EBX);
  __ movsd(FieldAddress(EAX, target::Double::value_offset()), XMM0);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::DoubleFromInteger(Assembler* assembler,
                                        Label* normal_ir_body) {
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body, Assembler::kNearJump);
  // Is Smi.
  __ SmiUntag(EAX);
  __ cvtsi2sd(XMM0, EAX);
  const Class& double_class = DoubleClass();
  __ TryAllocate(double_class, normal_ir_body, Assembler::kNearJump,
                 EAX,  // Result register.
                 EBX);
  __ movsd(FieldAddress(EAX, target::Double::value_offset()), XMM0);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::Double_getIsNaN(Assembler* assembler,
                                      Label* normal_ir_body) {
  Label is_true;
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ movsd(XMM0, FieldAddress(EAX, target::Double::value_offset()));
  __ comisd(XMM0, XMM0);
  __ j(PARITY_EVEN, &is_true, Assembler::kNearJump);  // NaN -> true;
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();
}

void AsmIntrinsifier::Double_getIsInfinite(Assembler* assembler,
                                           Label* normal_ir_body) {
  Label not_inf;
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ movl(EBX, FieldAddress(EAX, target::Double::value_offset()));

  // If the low word isn't zero, then it isn't infinity.
  __ cmpl(EBX, Immediate(0));
  __ j(NOT_EQUAL, &not_inf, Assembler::kNearJump);
  // Check the high word.
  __ movl(EBX, FieldAddress(
                   EAX, target::Double::value_offset() + target::kWordSize));
  // Mask off sign bit.
  __ andl(EBX, Immediate(0x7FFFFFFF));
  // Compare with +infinity.
  __ cmpl(EBX, Immediate(0x7FF00000));
  __ j(NOT_EQUAL, &not_inf, Assembler::kNearJump);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(&not_inf);
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
}

void AsmIntrinsifier::Double_getIsNegative(Assembler* assembler,
                                           Label* normal_ir_body) {
  Label is_false, is_true, is_zero;
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ movsd(XMM0, FieldAddress(EAX, target::Double::value_offset()));
  __ xorpd(XMM1, XMM1);  // 0.0 -> XMM1.
  __ comisd(XMM0, XMM1);
  __ j(PARITY_EVEN, &is_false, Assembler::kNearJump);  // NaN -> false.
  __ j(EQUAL, &is_zero, Assembler::kNearJump);  // Check for negative zero.
  __ j(ABOVE_EQUAL, &is_false, Assembler::kNearJump);  // >= 0 -> false.
  __ Bind(&is_true);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();
  __ Bind(&is_false);
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_zero);
  // Check for negative zero (get the sign bit).
  __ movmskpd(EAX, XMM0);
  __ testl(EAX, Immediate(1));
  __ j(NOT_ZERO, &is_true, Assembler::kNearJump);
  __ jmp(&is_false, Assembler::kNearJump);
}

// Identity comparison.
void AsmIntrinsifier::ObjectEquals(Assembler* assembler,
                                   Label* normal_ir_body) {
  Label is_true;
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ cmpl(EAX, Address(ESP, +2 * target::kWordSize));
  __ j(EQUAL, &is_true, Assembler::kNearJump);
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
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
  Label use_declaration_type, not_double, not_integer, not_string;
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ LoadClassIdMayBeSmi(EDI, EAX);

  __ cmpl(EDI, Immediate(kClosureCid));
  __ j(EQUAL, normal_ir_body);  // Instance is a closure.

  __ cmpl(EDI, Immediate(kRecordCid));
  __ j(EQUAL, normal_ir_body);  // Instance is a record.

  __ cmpl(EDI, Immediate(kNumPredefinedCids));
  __ j(ABOVE, &use_declaration_type);

  // If object is a instance of _Double return double type.
  __ cmpl(EDI, Immediate(kDoubleCid));
  __ j(NOT_EQUAL, &not_double);

  __ LoadIsolateGroup(EAX);
  __ movl(EAX, Address(EAX, target::IsolateGroup::object_store_offset()));
  __ movl(EAX, Address(EAX, target::ObjectStore::double_type_offset()));
  __ ret();

  __ Bind(&not_double);
  // If object is an integer (smi, mint or bigint) return int type.
  __ movl(EAX, EDI);
  JumpIfNotInteger(assembler, EAX, &not_integer);

  __ LoadIsolateGroup(EAX);
  __ movl(EAX, Address(EAX, target::IsolateGroup::object_store_offset()));
  __ movl(EAX, Address(EAX, target::ObjectStore::int_type_offset()));
  __ ret();

  __ Bind(&not_integer);
  // If object is a string (one byte, two byte or external variants) return
  // string type.
  __ movl(EAX, EDI);
  JumpIfNotString(assembler, EAX, &not_string);

  __ LoadIsolateGroup(EAX);
  __ movl(EAX, Address(EAX, target::IsolateGroup::object_store_offset()));
  __ movl(EAX, Address(EAX, target::ObjectStore::string_type_offset()));
  __ ret();

  __ Bind(&not_string);
  // If object is a type or function type, return Dart type.
  __ movl(EAX, EDI);
  JumpIfNotType(assembler, EAX, &use_declaration_type);

  __ LoadIsolateGroup(EAX);
  __ movl(EAX, Address(EAX, target::IsolateGroup::object_store_offset()));
  __ movl(EAX, Address(EAX, target::ObjectStore::type_type_offset()));
  __ ret();

  // Object is neither double, nor integer, nor string, nor type.
  __ Bind(&use_declaration_type);
  __ LoadClassById(EBX, EDI);
  __ movzxw(EDI, FieldAddress(EBX, target::Class::num_type_arguments_offset()));
  __ cmpl(EDI, Immediate(0));
  __ j(NOT_EQUAL, normal_ir_body, Assembler::kNearJump);
  __ movl(EAX, FieldAddress(EBX, target::Class::declaration_type_offset()));
  __ CompareObject(EAX, NullObject());
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
  __ cmpl(cid1, Immediate(kClosureCid));
  __ j(EQUAL, normal_ir_body);

  // Check if left hand side is a record. Records are handled in the runtime.
  __ cmpl(cid1, Immediate(kRecordCid));
  __ j(EQUAL, normal_ir_body);

  // Check whether class ids match. If class ids don't match types may still be
  // considered equivalent (e.g. multiple string implementation classes map to a
  // single String type).
  __ cmpl(cid1, cid2);
  __ j(EQUAL, equal_may_be_generic);

  // Class ids are different. Check if we are comparing two string types (with
  // different representations), two integer types, two list types or two type
  // types.
  __ cmpl(cid1, Immediate(kNumPredefinedCids));
  __ j(ABOVE_EQUAL, not_equal);

  // Check if both are integer types.
  __ movl(scratch, cid1);
  JumpIfNotInteger(assembler, scratch, &not_integer);

  // First type is an integer. Check if the second is an integer too.
  __ movl(scratch, cid2);
  JumpIfInteger(assembler, scratch, equal_not_generic);
  // Integer types are only equivalent to other integer types.
  __ jmp(not_equal);

  __ Bind(&not_integer);
  // Check if both are String types.
  __ movl(scratch, cid1);
  JumpIfNotString(assembler, scratch,
                  testing_instance_cids ? &not_integer_or_string : not_equal);

  // First type is a String. Check if the second is a String too.
  __ movl(scratch, cid2);
  JumpIfString(assembler, scratch, equal_not_generic);
  // String types are only equivalent to other String types.
  __ jmp(not_equal);

  if (testing_instance_cids) {
    __ Bind(&not_integer_or_string);
    // Check if both are List types.
    __ movl(scratch, cid1);
    JumpIfNotList(assembler, scratch, &not_integer_or_string_or_list);

    // First type is a List. Check if the second is a List too.
    __ movl(scratch, cid2);
    JumpIfNotList(assembler, scratch, not_equal);
    ASSERT(compiler::target::Array::type_arguments_offset() ==
           compiler::target::GrowableObjectArray::type_arguments_offset());
    __ jmp(equal_may_be_generic);

    __ Bind(&not_integer_or_string_or_list);
    // Check if the first type is a Type. If it is not then types are not
    // equivalent because they have different class ids and they are not String
    // or integer or List or Type.
    __ movl(scratch, cid1);
    JumpIfNotType(assembler, scratch, not_equal);

    // First type is a Type. Check if the second is a Type too.
    __ movl(scratch, cid2);
    JumpIfType(assembler, scratch, equal_not_generic);
    // Type types are only equivalent to other Type types.
    __ jmp(not_equal);
  }
}

void AsmIntrinsifier::ObjectHaveSameRuntimeType(Assembler* assembler,
                                                Label* normal_ir_body) {
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));
  __ LoadClassIdMayBeSmi(EDI, EAX);

  __ movl(EAX, Address(ESP, +2 * target::kWordSize));
  __ LoadClassIdMayBeSmi(EBX, EAX);

  Label equal_may_be_generic, equal, not_equal;
  EquivalentClassIds(assembler, normal_ir_body, &equal_may_be_generic, &equal,
                     &not_equal, EDI, EBX, EAX,
                     /* testing_instance_cids = */ true);

  __ Bind(&equal_may_be_generic);
  // Classes are equivalent and neither is a closure class.
  // Check if there are no type arguments. In this case we can return true.
  // Otherwise fall through into the runtime to handle comparison.
  __ LoadClassById(EAX, EDI);
  __ movl(
      EAX,
      FieldAddress(
          EAX,
          target::Class::host_type_arguments_field_offset_in_words_offset()));
  __ cmpl(EAX, Immediate(target::Class::kNoTypeArguments));
  __ j(EQUAL, &equal);

  // Compare type arguments, host_type_arguments_field_offset_in_words in EAX.
  __ movl(EDI, Address(ESP, +1 * target::kWordSize));
  __ movl(EBX, Address(ESP, +2 * target::kWordSize));
  __ movl(EDI, FieldAddress(EDI, EAX, TIMES_4, 0));
  __ movl(EBX, FieldAddress(EBX, EAX, TIMES_4, 0));
  __ cmpl(EDI, EBX);
  __ j(NOT_EQUAL, normal_ir_body, Assembler::kNearJump);
  // Fall through to equal case if type arguments are equal.

  __ Bind(&equal);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(&not_equal);
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::String_getHashCode(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));  // String object.
  __ movl(EAX, FieldAddress(EAX, target::String::hash_offset()));
  __ cmpl(EAX, Immediate(0));
  __ j(EQUAL, normal_ir_body, Assembler::kNearJump);
  __ ret();
  __ Bind(normal_ir_body);
  // Hash not yet computed.
}

void AsmIntrinsifier::Type_equality(Assembler* assembler,
                                    Label* normal_ir_body) {
  Label equal, not_equal, equiv_cids_may_be_generic, equiv_cids, check_legacy;

  __ movl(EDI, Address(ESP, +1 * target::kWordSize));
  __ movl(EBX, Address(ESP, +2 * target::kWordSize));
  __ cmpl(EDI, EBX);
  __ j(EQUAL, &equal);

  // EDI might not be a Type object, so check that first (EBX should be though,
  // since this is a method on the Type class).
  __ LoadClassIdMayBeSmi(EAX, EDI);
  __ cmpl(EAX, Immediate(kTypeCid));
  __ j(NOT_EQUAL, normal_ir_body);

  // Check if types are syntactically equal.
  __ LoadTypeClassId(ECX, EDI);
  __ LoadTypeClassId(EDX, EBX);
  // We are not testing instance cids, but type class cids of Type instances.
  EquivalentClassIds(assembler, normal_ir_body, &equiv_cids_may_be_generic,
                     &equiv_cids, &not_equal, ECX, EDX, EAX,
                     /* testing_instance_cids = */ false);

  __ Bind(&equiv_cids_may_be_generic);
  // Compare type arguments in Type instances.
  __ movl(ECX, FieldAddress(EDI, target::Type::arguments_offset()));
  __ movl(EDX, FieldAddress(EBX, target::Type::arguments_offset()));
  __ cmpl(ECX, EDX);
  __ j(NOT_EQUAL, normal_ir_body, Assembler::kNearJump);
  // Fall through to check nullability if type arguments are equal.

  // Check nullability.
  __ Bind(&equiv_cids);
  __ LoadAbstractTypeNullability(EDI, EDI);
  __ LoadAbstractTypeNullability(EBX, EBX);
  __ cmpl(EDI, EBX);
  __ j(NOT_EQUAL, &check_legacy, Assembler::kNearJump);
  // Fall through to equal case if nullability is strictly equal.

  __ Bind(&equal);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();

  // At this point the nullabilities are different, so they can only be
  // syntactically equivalent if they're both either kNonNullable or kLegacy.
  // These are the two largest values of the enum, so we can just do a < check.
  ASSERT(target::Nullability::kNullable < target::Nullability::kNonNullable &&
         target::Nullability::kNonNullable < target::Nullability::kLegacy);
  __ Bind(&check_legacy);
  __ cmpl(EDI, Immediate(target::Nullability::kNonNullable));
  __ j(LESS, &not_equal, Assembler::kNearJump);
  __ cmpl(EBX, Immediate(target::Nullability::kNonNullable));
  __ j(GREATER_EQUAL, &equal, Assembler::kNearJump);

  __ Bind(&not_equal);
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AbstractType_getHashCode(Assembler* assembler,
                                               Label* normal_ir_body) {
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));  // AbstractType object.
  __ movl(EAX, FieldAddress(EAX, target::AbstractType::hash_offset()));
  __ testl(EAX, EAX);
  __ j(EQUAL, normal_ir_body, Assembler::kNearJump);
  __ ret();
  __ Bind(normal_ir_body);
  // Hash not yet computed.
}

void AsmIntrinsifier::AbstractType_equality(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ movl(EDI, Address(ESP, +1 * target::kWordSize));
  __ movl(EBX, Address(ESP, +2 * target::kWordSize));
  __ cmpl(EDI, EBX);
  __ j(NOT_EQUAL, normal_ir_body);

  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();

  __ Bind(normal_ir_body);
}

// bool _substringMatches(int start, String other)
void AsmIntrinsifier::StringBaseSubstringMatches(Assembler* assembler,
                                                 Label* normal_ir_body) {
  // For precompilation, not implemented on IA32.
}

void AsmIntrinsifier::Object_getHash(Assembler* assembler,
                                     Label* normal_ir_body) {
  UNREACHABLE();
}

void AsmIntrinsifier::StringBaseCharAt(Assembler* assembler,
                                       Label* normal_ir_body) {
  Label try_two_byte_string;
  __ movl(EBX, Address(ESP, +1 * target::kWordSize));  // Index.
  __ movl(EAX, Address(ESP, +2 * target::kWordSize));  // String.
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body, Assembler::kNearJump);  // Non-smi index.
  // Range check.
  __ cmpl(EBX, FieldAddress(EAX, target::String::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, normal_ir_body, Assembler::kNearJump);
  __ CompareClassId(EAX, kOneByteStringCid, EDI);
  __ j(NOT_EQUAL, &try_two_byte_string, Assembler::kNearJump);
  __ SmiUntag(EBX);
  __ movzxb(EBX, FieldAddress(EAX, EBX, TIMES_1,
                              target::OneByteString::data_offset()));
  __ cmpl(EBX, Immediate(target::Symbols::kNumberOfOneCharCodeSymbols));
  __ j(GREATER_EQUAL, normal_ir_body);
  __ movl(EAX, Immediate(SymbolsPredefinedAddress()));
  __ movl(EAX, Address(EAX, EBX, TIMES_4,
                       target::Symbols::kNullCharCodeSymbolOffset *
                           target::kWordSize));
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(EAX, kTwoByteStringCid, EDI);
  __ j(NOT_EQUAL, normal_ir_body, Assembler::kNearJump);
  ASSERT(kSmiTagShift == 1);
  __ movzxw(EBX, FieldAddress(EAX, EBX, TIMES_1,
                              target::TwoByteString::data_offset()));
  __ cmpl(EBX, Immediate(target::Symbols::kNumberOfOneCharCodeSymbols));
  __ j(GREATER_EQUAL, normal_ir_body);
  __ movl(EAX, Immediate(SymbolsPredefinedAddress()));
  __ movl(EAX, Address(EAX, EBX, TIMES_4,
                       target::Symbols::kNullCharCodeSymbolOffset *
                           target::kWordSize));
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::StringBaseIsEmpty(Assembler* assembler,
                                        Label* normal_ir_body) {
  Label is_true;
  // Get length.
  __ movl(EAX, Address(ESP, +1 * target::kWordSize));  // String object.
  __ movl(EAX, FieldAddress(EAX, target::String::length_offset()));
  __ cmpl(EAX, Immediate(target::ToRawSmi(0)));
  __ j(EQUAL, &is_true, Assembler::kNearJump);
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();
}

void AsmIntrinsifier::OneByteString_getHashCode(Assembler* assembler,
                                                Label* normal_ir_body) {
  Label compute_hash;
  __ movl(EBX, Address(ESP, +1 * target::kWordSize));  // OneByteString object.
  __ movl(EAX, FieldAddress(EBX, target::String::hash_offset()));
  __ cmpl(EAX, Immediate(0));
  __ j(EQUAL, &compute_hash, Assembler::kNearJump);
  __ ret();

  __ Bind(&compute_hash);
  // Hash not yet computed, use algorithm of class StringHasher.
  __ movl(ECX, FieldAddress(EBX, target::String::length_offset()));
  __ SmiUntag(ECX);
  __ xorl(EAX, EAX);
  __ xorl(EDI, EDI);
  // EBX: Instance of OneByteString.
  // ECX: String length, untagged integer.
  // EDI: Loop counter, untagged integer.
  // EAX: Hash code, untagged integer.
  Label loop, done;
  __ Bind(&loop);
  __ cmpl(EDI, ECX);
  __ j(EQUAL, &done, Assembler::kNearJump);
  // Add to hash code: (hash_ is uint32)
  // Get one characters (ch).
  __ movzxb(EDX, FieldAddress(EBX, EDI, TIMES_1,
                              target::OneByteString::data_offset()));
  // EDX: ch and temporary.
  __ CombineHashes(EAX, EDX);

  __ incl(EDI);
  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&done);
  // Finalize and fit to size kHashBits. Ensures hash is non-zero.
  __ FinalizeHashForSize(target::String::kHashBits, EAX, EDX);
  __ SmiTag(EAX);
  __ StoreIntoSmiField(FieldAddress(EBX, target::String::hash_offset()), EAX);
  __ ret();
}

// Allocates a _OneByteString or _TwoByteString. The content is not initialized.
// 'length_reg' contains the desired length as a _Smi or _Mint.
// Returns new string as tagged pointer in EAX.
static void TryAllocateString(Assembler* assembler,
                              classid_t cid,
                              intptr_t max_elements,
                              Label* ok,
                              Label* failure,
                              Register length_reg) {
  ASSERT(cid == kOneByteStringCid || cid == kTwoByteStringCid);
  // _Mint length: call to runtime to produce error.
  __ BranchIfNotSmi(length_reg, failure);
  // negative length: call to runtime to produce error.
  // Too big: call to runtime to allocate old.
  __ cmpl(length_reg, Immediate(target::ToRawSmi(max_elements)));
  __ j(ABOVE, failure);

  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, failure, EAX));
  if (length_reg != EDI) {
    __ movl(EDI, length_reg);
  }
  Label pop_and_fail;
  __ pushl(EDI);  // Preserve length.
  if (cid == kOneByteStringCid) {
    __ SmiUntag(EDI);
  } else {
    // Untag length and multiply by element size -> no-op.
  }
  const intptr_t fixed_size_plus_alignment_padding =
      target::String::InstanceSize() +
      target::ObjectAlignment::kObjectAlignment - 1;
  __ leal(EDI, Address(EDI, TIMES_1,
                       fixed_size_plus_alignment_padding));  // EDI is untagged.
  __ andl(EDI, Immediate(-target::ObjectAlignment::kObjectAlignment));

  __ movl(EAX, Address(THR, target::Thread::top_offset()));
  __ movl(EBX, EAX);

  // EDI: allocation size.
  __ addl(EBX, EDI);
  __ j(CARRY, &pop_and_fail);

  // Check if the allocation fits into the remaining space.
  // EAX: potential new object start.
  // EBX: potential next object start.
  // EDI: allocation size.
  __ cmpl(EBX, Address(THR, target::Thread::end_offset()));
  __ j(ABOVE_EQUAL, &pop_and_fail);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ movl(Address(THR, target::Thread::top_offset()), EBX);
  __ addl(EAX, Immediate(kHeapObjectTag));
  // Clear last double word to ensure string comparison doesn't need to
  // specially handle remainder of strings with lengths not factors of double
  // offsets.
  ASSERT(target::kWordSize == 4);
  __ movl(Address(EBX, -1 * target::kWordSize), Immediate(0));
  __ movl(Address(EBX, -2 * target::kWordSize), Immediate(0));
  // Initialize the tags.
  // EAX: new object start as a tagged pointer.
  // EBX: new object end address.
  // EDI: allocation size.
  {
    Label size_tag_overflow, done;
    __ cmpl(EDI, Immediate(target::UntaggedObject::kSizeTagMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shll(EDI, Immediate(target::UntaggedObject::kTagBitsSizeTagPos -
                           target::ObjectAlignment::kObjectAlignmentLog2));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&size_tag_overflow);
    __ xorl(EDI, EDI);
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    const uword tags =
        target::MakeTagWordForNewSpaceObject(cid, /*instance_size=*/0);
    __ orl(EDI, Immediate(tags));
    __ movl(FieldAddress(EAX, target::Object::tags_offset()), EDI);  // Tags.
  }

  // Set the length field.
  __ popl(EDI);
  __ StoreIntoObjectNoBarrier(
      EAX, FieldAddress(EAX, target::String::length_offset()), EDI);
  // Clear hash.
  __ ZeroInitSmiField(FieldAddress(EAX, target::String::hash_offset()));
  __ jmp(ok, Assembler::kNearJump);

  __ Bind(&pop_and_fail);
  __ popl(EDI);
  __ jmp(failure);
}

// Arg0: OneByteString (receiver)
// Arg1: Start index as Smi.
// Arg2: End index as Smi.
// The indexes must be valid.
void AsmIntrinsifier::OneByteString_substringUnchecked(Assembler* assembler,
                                                       Label* normal_ir_body) {
  const intptr_t kStringOffset = 3 * target::kWordSize;
  const intptr_t kStartIndexOffset = 2 * target::kWordSize;
  const intptr_t kEndIndexOffset = 1 * target::kWordSize;
  Label ok;
  __ movl(EAX, Address(ESP, +kStartIndexOffset));
  __ movl(EDI, Address(ESP, +kEndIndexOffset));
  __ orl(EAX, EDI);
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, normal_ir_body);  // 'start', 'end' not Smi.

  __ subl(EDI, Address(ESP, +kStartIndexOffset));
  TryAllocateString(assembler, kOneByteStringCid,
                    target::OneByteString::kMaxNewSpaceElements, &ok,
                    normal_ir_body, EDI);
  __ Bind(&ok);
  // EAX: new string as tagged pointer.
  // Copy string.
  __ movl(EDI, Address(ESP, +kStringOffset));
  __ movl(EBX, Address(ESP, +kStartIndexOffset));
  __ SmiUntag(EBX);
  __ leal(EDI, FieldAddress(EDI, EBX, TIMES_1,
                            target::OneByteString::data_offset()));
  // EDI: Start address to copy from (untagged).
  // EBX: Untagged start index.
  __ movl(ECX, Address(ESP, +kEndIndexOffset));
  __ SmiUntag(ECX);
  __ subl(ECX, EBX);
  __ xorl(EDX, EDX);
  // EDI: Start address to copy from (untagged).
  // ECX: Untagged number of bytes to copy.
  // EAX: Tagged result string.
  // EDX: Loop counter.
  // EBX: Scratch register.
  Label loop, check;
  __ jmp(&check, Assembler::kNearJump);
  __ Bind(&loop);
  __ movzxb(EBX, Address(EDI, EDX, TIMES_1, 0));
  __ movb(FieldAddress(EAX, EDX, TIMES_1, target::OneByteString::data_offset()),
          BL);
  __ incl(EDX);
  __ Bind(&check);
  __ cmpl(EDX, ECX);
  __ j(LESS, &loop, Assembler::kNearJump);
  __ ret();
  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::WriteIntoOneByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ movl(ECX, Address(ESP, +1 * target::kWordSize));  // Value.
  __ movl(EBX, Address(ESP, +2 * target::kWordSize));  // Index.
  __ movl(EAX, Address(ESP, +3 * target::kWordSize));  // OneByteString.
  __ SmiUntag(EBX);
  __ SmiUntag(ECX);
  __ movb(FieldAddress(EAX, EBX, TIMES_1, target::OneByteString::data_offset()),
          CL);
  __ ret();
}

void AsmIntrinsifier::WriteIntoTwoByteString(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ movl(ECX, Address(ESP, +1 * target::kWordSize));  // Value.
  __ movl(EBX, Address(ESP, +2 * target::kWordSize));  // Index.
  __ movl(EAX, Address(ESP, +3 * target::kWordSize));  // TwoByteString.
  // Untag index and multiply by element size -> no-op.
  __ SmiUntag(ECX);
  __ movw(FieldAddress(EAX, EBX, TIMES_1, target::TwoByteString::data_offset()),
          ECX);
  __ ret();
}

void AsmIntrinsifier::AllocateOneByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ movl(EDI, Address(ESP, +1 * target::kWordSize));  // Length.
  Label ok;
  TryAllocateString(assembler, kOneByteStringCid,
                    target::OneByteString::kMaxNewSpaceElements, &ok,
                    normal_ir_body, EDI);
  // EDI: Start address to copy from (untagged).

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::AllocateTwoByteString(Assembler* assembler,
                                            Label* normal_ir_body) {
  __ movl(EDI, Address(ESP, +1 * target::kWordSize));  // Length.
  Label ok;
  TryAllocateString(assembler, kTwoByteStringCid,
                    target::TwoByteString::kMaxNewSpaceElements, &ok,
                    normal_ir_body, EDI);
  // EDI: Start address to copy from (untagged).

  __ Bind(&ok);
  __ ret();

  __ Bind(normal_ir_body);
}

void AsmIntrinsifier::OneByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ movl(EAX, Address(ESP, +2 * target::kWordSize));  // This.
  __ movl(EBX, Address(ESP, +1 * target::kWordSize));  // Other.

  StringEquality(assembler, EAX, EBX, EDI, ECX, EAX, normal_ir_body,
                 kOneByteStringCid);
}

void AsmIntrinsifier::TwoByteString_equality(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ movl(EAX, Address(ESP, +2 * target::kWordSize));  // This.
  __ movl(EBX, Address(ESP, +1 * target::kWordSize));  // Other.

  StringEquality(assembler, EAX, EBX, EDI, ECX, EAX, normal_ir_body,
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
  // EAX: Function. (Will be loaded with the specialized matcher function.)
  // ECX: Unknown. (Must be GC safe on tail call.)
  // EDX: Arguments descriptor. (Will be preserved.)

  // Load the specialized function pointer into EAX. Leverage the fact the
  // string CIDs as well as stored function pointers are in sequence.
  __ movl(EBX, Address(ESP, kRegExpParamOffset));
  __ movl(EDI, Address(ESP, kStringParamOffset));
  __ LoadClassId(EDI, EDI);
  __ SubImmediate(EDI, Immediate(kOneByteStringCid));
  __ movl(FUNCTION_REG, FieldAddress(EBX, EDI, TIMES_4,
                                     target::RegExp::function_offset(
                                         kOneByteStringCid, sticky)));

  // Registers are now set up for the lazy compile stub. It expects the function
  // in EAX, the argument descriptor in EDX, and IC-Data in ECX.
  __ xorl(ECX, ECX);

  // Tail-call the function.
  __ jmp(FieldAddress(FUNCTION_REG, target::Function::entry_point_offset()));
}

void AsmIntrinsifier::UserTag_defaultTag(Assembler* assembler,
                                         Label* normal_ir_body) {
  __ LoadIsolate(EAX);
  __ movl(EAX, Address(EAX, target::Isolate::default_tag_offset()));
  __ ret();
}

void AsmIntrinsifier::Profiler_getCurrentTag(Assembler* assembler,
                                             Label* normal_ir_body) {
  __ LoadIsolate(EAX);
  __ movl(EAX, Address(EAX, target::Isolate::current_tag_offset()));
  __ ret();
}

void AsmIntrinsifier::Timeline_isDartStreamEnabled(Assembler* assembler,
                                                   Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
#else
  Label true_label;
  // Load TimelineStream*.
  __ movl(EAX, Address(THR, target::Thread::dart_stream_offset()));
  // Load uintptr_t from TimelineStream*.
  __ movl(EAX, Address(EAX, target::TimelineStream::enabled_offset()));
  __ cmpl(EAX, Immediate(0));
  __ j(NOT_ZERO, &true_label, Assembler::kNearJump);
  // Not enabled.
  __ LoadObject(EAX, CastHandle<Object>(FalseObject()));
  __ ret();
  // Enabled.
  __ Bind(&true_label);
  __ LoadObject(EAX, CastHandle<Object>(TrueObject()));
  __ ret();
#endif
}

void AsmIntrinsifier::Timeline_getNextTaskId(Assembler* assembler,
                                             Label* normal_ir_body) {
#if !defined(SUPPORT_TIMELINE)
  __ LoadImmediate(EAX, target::ToRawSmi(0));
  __ ret();
#else
  __ movl(EBX, Address(THR, target::Thread::next_task_id_offset()));
  __ movl(ECX, Address(THR, target::Thread::next_task_id_offset() + 4));
  __ movl(EAX, EBX);
  __ SmiTag(EAX);  // Ignore loss of precision.
  __ addl(EBX, Immediate(1));
  __ adcl(ECX, Immediate(0));
  __ movl(Address(THR, target::Thread::next_task_id_offset()), EBX);
  __ movl(Address(THR, target::Thread::next_task_id_offset() + 4), ECX);
  __ ret();
#endif
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_IA32)
