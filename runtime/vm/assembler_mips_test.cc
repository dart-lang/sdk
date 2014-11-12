// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ LoadImmediate(V0, 42);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Simple, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Addiu, assembler) {
  __ addiu(V0, ZR, Immediate(42));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Addiu, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Addiu_overflow, assembler) {
  __ LoadImmediate(V0, 0x7fffffff);
  __ addiu(V0, V0, Immediate(1));  // V0 is modified on overflow.
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Addiu_overflow, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(static_cast<int32_t>(0x80000000),
            EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Addu, assembler) {
  __ addiu(T2, ZR, Immediate(21));
  __ addiu(T3, ZR, Immediate(21));
  __ addu(V0, T2, T3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Addu, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Addu_overflow, assembler) {
  __ LoadImmediate(T2, 0x7fffffff);
  __ addiu(T3, R0, Immediate(1));
  __ addu(V0, T2, T3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Addu_overflow, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(static_cast<int32_t>(0x80000000),
            EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(And, assembler) {
  __ addiu(T2, ZR, Immediate(42));
  __ addiu(T3, ZR, Immediate(2));
  __ and_(V0, T2, T3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(And, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Andi, assembler) {
  __ addiu(T1, ZR, Immediate(42));
  __ andi(V0, T1, Immediate(2));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Andi, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Clo, assembler) {
  __ addiu(T1, ZR, Immediate(-1));
  __ clo(V0, T1);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Clo, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(32, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Clz, assembler) {
  __ addiu(T1, ZR, Immediate(0x7fff));
  __ clz(V0, T1);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Clz, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(17, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(MtloMflo, assembler) {
  __ LoadImmediate(T0, 42);
  __ mtlo(T0);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(MtloMflo, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(MthiMfhi, assembler) {
  __ LoadImmediate(T0, 42);
  __ mthi(T0);
  __ mfhi(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(MthiMfhi, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Divu, assembler) {
  __ addiu(T1, ZR, Immediate(27));
  __ addiu(T2, ZR, Immediate(9));
  __ divu(T1, T2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Divu, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Div, assembler) {
  __ addiu(T1, ZR, Immediate(27));
  __ addiu(T2, ZR, Immediate(9));
  __ div(T1, T2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Div, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Divu_corner, assembler) {
  __ LoadImmediate(T1, 0x80000000);
  __ LoadImmediate(T2, 0xffffffff);
  __ divu(T1, T2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Divu_corner, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Div_corner, assembler) {
  __ LoadImmediate(T1, 0x80000000);
  __ LoadImmediate(T2, 0xffffffff);
  __ div(T1, T2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Div_corner, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(static_cast<int32_t>(0x80000000),
            EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lb, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(T1, 0xff);
  __ sb(T1, Address(SP));
  __ lb(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lb, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lb_offset, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(T1, 0xff);
  __ sb(T1, Address(SP, 1));
  __ lb(V0, Address(SP, 1));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lb_offset, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lbu, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(T1, 0xff);
  __ sb(T1, Address(SP));
  __ lbu(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lbu, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(255, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lh, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(T1, 0xffff);
  __ sh(T1, Address(SP));
  __ lh(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lh, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lhu, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(T1, 0xffff);
  __ sh(T1, Address(SP));
  __ lhu(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lhu, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(65535, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lw, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(T1, -1);
  __ sw(T1, Address(SP));
  __ lw(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lw, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lui, assembler) {
  __ lui(V0, Immediate(42));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lui, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42 << 16, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sll, assembler) {
  __ LoadImmediate(T1, 21);
  __ sll(V0, T1, 1);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Sll, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Srl, assembler) {
  __ LoadImmediate(T1, 84);
  __ srl(V0, T1, 1);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Srl, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LShifting, assembler) {
  __ LoadImmediate(T1, 1);
  __ sll(T1, T1, 31);
  __ srl(V0, T1, 31);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(LShifting, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(RShifting, assembler) {
  __ LoadImmediate(T1, 1);
  __ sll(T1, T1, 31);
  __ sra(V0, T1, 31);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(RShifting, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sllv, assembler) {
  __ LoadImmediate(T1, 21);
  __ LoadImmediate(T2, 1);
  __ sllv(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Sllv, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Srlv, assembler) {
  __ LoadImmediate(T1, 84);
  __ LoadImmediate(T2, 1);
  __ srlv(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Srlv, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LShiftingV, assembler) {
  __ LoadImmediate(T1, 1);
  __ LoadImmediate(T2, 31);
  __ sllv(T1, T1, T2);
  __ srlv(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(LShiftingV, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(RShiftingV, assembler) {
  __ LoadImmediate(T1, 1);
  __ LoadImmediate(T2, 31);
  __ sllv(T1, T1, T2);
  __ srav(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(RShiftingV, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mult_pos, assembler) {
  __ LoadImmediate(T1, 6);
  __ LoadImmediate(T2, 7);
  __ mult(T1, T2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Mult_pos, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mult_neg, assembler) {
  __ LoadImmediate(T1, -6);
  __ LoadImmediate(T2, 7);
  __ mult(T1, T2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Mult_neg, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mult_neg_hi, assembler) {
  __ LoadImmediate(T1, -6);
  __ LoadImmediate(T2, 7);
  __ mult(T1, T2);
  __ mfhi(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Mult_neg_hi, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Multu_lo, assembler) {
  __ LoadImmediate(T1, 6);
  __ LoadImmediate(T2, 7);
  __ multu(T1, T2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Multu_lo, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Multu_hi, assembler) {
  __ LoadImmediate(T1, -1);
  __ LoadImmediate(T2, -1);
  __ multu(T1, T2);
  __ mfhi(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Multu_hi, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Madd_neg, assembler) {
  __ LoadImmediate(T1, -6);
  __ LoadImmediate(T2, 7);
  __ mult(T1, T2);
  __ madd(T1, T2);
  __ mflo(V0);
  __ mfhi(V1);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Madd_neg, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-84, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Subu, assembler) {
  __ LoadImmediate(T1, 737);
  __ LoadImmediate(T2, 695);
  __ subu(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Subu, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Or, assembler) {
  __ LoadImmediate(T1, 34);
  __ LoadImmediate(T2, 8);
  __ or_(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Or, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Nor, assembler) {
  __ LoadImmediate(T1, -47);
  __ LoadImmediate(T2, -60);
  __ nor(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Nor, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Xor, assembler) {
  __ LoadImmediate(T1, 51);
  __ LoadImmediate(T2, 25);
  __ xor_(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Xor, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Xori, assembler) {
  __ LoadImmediate(T0, 51);
  __ xori(V0, T0, Immediate(25));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Xori, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Slt, assembler) {
  __ LoadImmediate(T1, -1);
  __ LoadImmediate(T2, 0);
  __ slt(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Slt, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sltu, assembler) {
  __ LoadImmediate(T1, -1);
  __ LoadImmediate(T2, 0);
  __ sltu(V0, T1, T2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Sltu, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movz, assembler) {
  __ LoadImmediate(T1, 42);
  __ LoadImmediate(T2, 23);
  __ slt(T3, T1, T2);
  __ movz(V0, T1, T3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Movz, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movn, assembler) {
  __ LoadImmediate(T1, 42);
  __ LoadImmediate(T2, 23);
  __ slt(T3, T2, T1);
  __ movn(V0, T1, T3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Movn, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Jr_delay, assembler) {
  __ jr(RA);
  __ delay_slot()->ori(V0, ZR, Immediate(42));
}


ASSEMBLER_TEST_RUN(Jr_delay, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_backward, assembler) {
  Label l;

  __ LoadImmediate(T1, 0);
  __ LoadImmediate(T2, 1);
  __ Bind(&l);
  __ addiu(T1, T1, Immediate(1));
  __ beq(T1, T2, &l);
  __ ori(V0, T1, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_backward, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_backward_far, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T1, 0);
  __ LoadImmediate(T2, 1);
  __ Bind(&l);
  __ addiu(T1, T1, Immediate(1));
  __ beq(T1, T2, &l);
  __ ori(V0, T1, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_backward_far, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_backward_delay, assembler) {
  Label l;

  __ LoadImmediate(T1, 0);
  __ LoadImmediate(T2, 1);
  __ Bind(&l);
  __ addiu(T1, T1, Immediate(1));
  __ beq(T1, T2, &l);
  __ delay_slot()->addiu(T1, T1, Immediate(1));
  __ ori(V0, T1, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_backward_delay, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(4, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_taken, assembler) {
  Label l;

  __ LoadImmediate(T5, 1);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_taken, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_taken_far, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 1);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_taken_far, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_not_taken, assembler) {
  Label l;

  __ LoadImmediate(T5, 0);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ nop();
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_not_taken, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_not_taken_far, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 0);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ nop();
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_not_taken_far, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_not_taken_far2, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 0);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ nop();
  for (int i = 0; i < (1 << 15); i++) {
    __ nop();
  }
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_not_taken_far2, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_taken2, assembler) {
  Label l;

  __ LoadImmediate(T5, 1);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ nop();
  __ nop();
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_taken2, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_taken_far2, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 1);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ nop();
  __ nop();
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_taken_far2, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_taken_far3, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 1);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ nop();
  for (int i = 0; i < (1 << 15); i++) {
    __ nop();
  }
  __ nop();
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_taken_far3, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_taken_delay, assembler) {
  Label l;

  __ LoadImmediate(T5, 1);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ delay_slot()->ori(V0, V0, Immediate(1));
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_taken_delay, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(43, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beq_forward_not_taken_delay, assembler) {
  Label l;

  __ LoadImmediate(T5, 0);
  __ LoadImmediate(T6, 1);

  __ LoadImmediate(V0, 42);
  __ beq(T5, T6, &l);
  __ delay_slot()->ori(V0, V0, Immediate(1));
  __ addiu(V0, V0, Immediate(1));
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beq_forward_not_taken_delay, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(44, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Beql_backward_delay, assembler) {
  Label l;

  __ LoadImmediate(T5, 0);
  __ LoadImmediate(T6, 1);
  __ Bind(&l);
  __ addiu(T5, T5, Immediate(1));
  __ beql(T5, T6, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Beql_backward_delay, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgez, assembler) {
  Label l;

  __ LoadImmediate(T5, 3);
  __ Bind(&l);
  __ bgez(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(-1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgez, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgez_far, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 3);
  __ Bind(&l);
  __ bgez(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(-1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgez_far, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgez_far2, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 3);
  __ Bind(&l);
  for (int i = 0; i < (1 << 15); i++) {
    __ nop();
  }
  __ bgez(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(-1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgez_far2, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgez_taken_forward_far, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 1);

  __ LoadImmediate(V0, 42);
  __ bgez(T5, &l);
  __ nop();
  __ nop();
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgez_taken_forward_far, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgez_taken_forward_far2, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 1);

  __ LoadImmediate(V0, 42);
  __ bgez(T5, &l);
  __ nop();
  for (int i = 0; i < (1 << 15); i++) {
    __ nop();
  }
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgez_taken_forward_far2, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgez_not_taken_forward_far, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, -1);

  __ LoadImmediate(V0, 42);
  __ bgez(T5, &l);
  __ nop();
  __ nop();
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgez_not_taken_forward_far, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgez_not_taken_forward_far2, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, -1);

  __ LoadImmediate(V0, 42);
  __ bgez(T5, &l);
  __ nop();
  for (int i = 0; i < (1 << 15); i++) {
    __ nop();
  }
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgez_not_taken_forward_far2, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgezl, assembler) {
  Label l;

  __ LoadImmediate(T5, 3);
  __ Bind(&l);
  __ bgezl(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(-1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgezl, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Blez, assembler) {
  Label l;

  __ LoadImmediate(T5, -3);
  __ Bind(&l);
  __ blez(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Blez, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Blez_far, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, -3);
  __ Bind(&l);
  __ blez(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Blez_far, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Blez_far2, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, -3);
  __ Bind(&l);
  for (int i = 0; i < (1 << 15); i++) {
    __ nop();
  }
  __ blez(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Blez_far2, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Blez_taken_forward_far, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, -1);

  __ LoadImmediate(V0, 42);
  __ blez(T5, &l);
  __ nop();
  __ nop();
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Blez_taken_forward_far, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Blez_not_taken_forward_far, assembler) {
  Label l;

  __ set_use_far_branches(true);

  __ LoadImmediate(T5, 1);

  __ LoadImmediate(V0, 42);
  __ blez(T5, &l);
  __ nop();
  __ nop();
  __ LoadImmediate(V0, 0);
  __ Bind(&l);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Blez_not_taken_forward_far, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Blezl, assembler) {
  Label l;

  __ LoadImmediate(T5, -3);
  __ Bind(&l);
  __ blezl(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Blezl, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgtz, assembler) {
  Label l;

  __ LoadImmediate(T5, 3);
  __ Bind(&l);
  __ bgtz(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(-1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgtz, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bgtzl, assembler) {
  Label l;

  __ LoadImmediate(T5, 3);
  __ Bind(&l);
  __ bgtzl(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(-1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bgtzl, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bltz, assembler) {
  Label l;

  __ LoadImmediate(T5, -3);
  __ Bind(&l);
  __ bltz(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bltz, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bltzl, assembler) {
  Label l;

  __ LoadImmediate(T5, -3);
  __ Bind(&l);
  __ bltzl(T5, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bltzl, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bne, assembler) {
  Label l;

  __ LoadImmediate(T5, 3);
  __ Bind(&l);
  __ bne(T5, R0, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(-1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bne, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Bnel, assembler) {
  Label l;

  __ LoadImmediate(T5, 3);
  __ Bind(&l);
  __ bnel(T5, R0, &l);
  __ delay_slot()->addiu(T5, T5, Immediate(-1));
  __ ori(V0, T5, Immediate(0));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Bnel, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Label_link1, assembler) {
  Label l;

  __ bgez(ZR, &l);
  __ bgez(ZR, &l);
  __ bgez(ZR, &l);

  __ LoadImmediate(V0, 1);
  __ Bind(&l);
  __ mov(V0, ZR);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Label_link1, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Label_link2, assembler) {
  Label l;

  __ beq(ZR, ZR, &l);
  __ beq(ZR, ZR, &l);
  __ beq(ZR, ZR, &l);

  __ LoadImmediate(V0, 1);
  __ Bind(&l);
  __ mov(V0, ZR);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Label_link2, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Jalr_delay, assembler) {
  __ mov(T2, RA);
  __ jalr(T2, RA);
  __ delay_slot()->ori(V0, ZR, Immediate(42));
}


ASSEMBLER_TEST_RUN(Jalr_delay, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddOverflow_detect, assembler) {
  Register left = T0;
  Register right = T1;
  Register result = T2;
  Register overflow = T3;
  Register scratch = T4;
  Label error, done;

  __ LoadImmediate(V0, 1);  // Success value.

  __ LoadImmediate(left, 0x7fffffff);
  __ LoadImmediate(right, 1);
  __ AdduDetectOverflow(result, left, right, overflow);
  __ bgez(overflow, &error);  // INT_MAX + 1 overflows.

  __ LoadImmediate(left, 0x7fffffff);
  __ AdduDetectOverflow(result, left, left, overflow);
  __ bgez(overflow, &error);  // INT_MAX + INT_MAX overflows.

  __ LoadImmediate(left, 0x7fffffff);
  __ LoadImmediate(right, -1);
  __ AdduDetectOverflow(result, left, right, overflow);
  __ bltz(overflow, &error);  // INT_MAX - 1 does not overflow.

  __ LoadImmediate(left, -1);
  __ LoadImmediate(right, 1);
  __ AdduDetectOverflow(result, left, right, overflow);
  __ bltz(overflow, &error);  // -1 + 1 does not overflow.

  __ LoadImmediate(left, 123456);
  __ LoadImmediate(right, 654321);
  __ AdduDetectOverflow(result, left, right, overflow);
  __ bltz(overflow, &error);  // 123456 + 654321 does not overflow.

  __ LoadImmediate(left, 0x80000000);
  __ LoadImmediate(right, -1);
  __ AdduDetectOverflow(result, left, right, overflow);
  __ bgez(overflow, &error);  // INT_MIN - 1 overflows.

  // result has 0x7fffffff.
  __ AdduDetectOverflow(result, result, result, overflow, scratch);
  __ bgez(overflow, &error);  // INT_MAX + INT_MAX overflows.

  __ LoadImmediate(left, 0x80000000);
  __ LoadImmediate(right, 0x80000000);
  __ AdduDetectOverflow(result, left, right, overflow);
  __ bgez(overflow, &error);  // INT_MIN + INT_MIN overflows.

  __ LoadImmediate(left, -123456);
  __ LoadImmediate(right, -654321);
  __ AdduDetectOverflow(result, left, right, overflow);
  __ bltz(overflow, &error);  // -123456 + -654321 does not overflow.

  __ b(&done);
  __ Bind(&error);
  __ mov(V0, ZR);
  __ Bind(&done);
  __ Ret();
}


ASSEMBLER_TEST_RUN(AddOverflow_detect, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(SubOverflow_detect, assembler) {
  Register left = T0;
  Register right = T1;
  Register result = T2;
  Register overflow = T3;
  Label error, done;

  __ LoadImmediate(V0, 1);  // Success value.

  __ LoadImmediate(left, 0x80000000);
  __ LoadImmediate(right, 1);
  __ SubuDetectOverflow(result, left, right, overflow);
  __ bgez(overflow, &error);  // INT_MIN - 1 overflows.

  __ LoadImmediate(left, 0x7fffffff);
  __ LoadImmediate(right, 0x8000000);
  __ SubuDetectOverflow(result, left, left, overflow);
  __ bltz(overflow, &error);  // INT_MIN - INT_MAX does not overflow.

  __ LoadImmediate(left, 0x80000000);
  __ LoadImmediate(right, 0x80000000);
  __ SubuDetectOverflow(result, left, right, overflow);
  __ bltz(overflow, &error);  // INT_MIN - INT_MIN does not overflow.

  __ LoadImmediate(left, 0x7fffffff);
  __ LoadImmediate(right, 0x80000000);
  __ SubuDetectOverflow(result, left, right, overflow);
  __ bgez(overflow, &error);  // INT_MAX - INT_MIN overflows.

  __ LoadImmediate(left, 1);
  __ LoadImmediate(right, -1);
  __ SubuDetectOverflow(result, left, right, overflow);
  __ bltz(overflow, &error);  // 1 - -1 does not overflow.

  __ b(&done);
  __ Bind(&error);
  __ mov(V0, ZR);
  __ Bind(&done);
  __ Ret();
}


ASSEMBLER_TEST_RUN(SubOverflow_detect, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mtc1Mfc1, assembler) {
  __ mtc1(ZR, F0);
  __ mtc1(ZR, F1);
  __ mfc1(V0, F0);
  __ mfc1(V1, F1);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Mtc1Mfc1, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Addd, assembler) {
  __ LoadImmediate(D0, 1.0);
  __ LoadImmediate(D1, 2.0);
  __ addd(D0, D0, D1);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Addd, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(3.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Movd, assembler) {
  __ LoadImmediate(D1, 1.0);
  __ movd(D0, D1);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Movd, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(1.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Sdc1Ldc1, assembler) {
  __ AddImmediate(SP, -8 * kWordSize);
  __ LoadImmediate(T1, ~(8 - 1));
  __ and_(T0, SP, T1);  // Need 8 byte alignment.
  __ LoadImmediate(D1, 1.0);
  __ sdc1(D1, Address(T0));
  __ ldc1(D0, Address(T0));
  __ Ret();
}


ASSEMBLER_TEST_RUN(Sdc1Ldc1, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(1.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Addd_NaN, assembler) {
  __ LoadImmediate(D0, 1.0);
  // Double non-signaling NaN is 0x7FF8000000000000.
  __ LoadImmediate(T0, 0x7FF80000);
  __ mtc1(ZR, F2);  // Load upper bits of NaN.
  __ mtc1(T0, F3);  // Load lower bits of NaN.
  __ addd(D0, D0, D1);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Addd_NaN, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_EQ(isnan(res), true);
}


ASSEMBLER_TEST_GENERATE(Addd_Inf, assembler) {
  __ LoadImmediate(D0, 1.0);
  __ LoadImmediate(T0, 0x7FF00000);  // +inf
  __ mtc1(ZR, F2);
  __ mtc1(T0, F3);
  __ addd(D0, D0, D1);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Addd_Inf, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_EQ(isfinite(res), false);
}


ASSEMBLER_TEST_GENERATE(Subd, assembler) {
  __ LoadImmediate(D0, 2.5);
  __ LoadImmediate(D1, 1.5);
  __ subd(D0, D0, D1);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Subd, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(1.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Muld, assembler) {
  __ LoadImmediate(D0, 6.0);
  __ LoadImmediate(D1, 7.0);
  __ muld(D0, D0, D1);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Muld, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(42.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Divd, assembler) {
  __ LoadImmediate(D0, 42.0);
  __ LoadImmediate(D1, 7.0);
  __ divd(D0, D0, D1);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Divd, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(6.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Sqrtd, assembler) {
  __ LoadImmediate(D1, 36.0);
  __ sqrtd(D0, D1);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Sqrtd, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(6.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Cop1CUN, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.0);
  __ LoadImmediate(T0, 0x7FF80000);
  __ mtc1(ZR, F2);
  __ mtc1(T0, F3);
  __ LoadImmediate(V0, 42);
  __ cund(D0, D1);
  __ bc1t(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CUN, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1CUN_not_taken, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.0);
  __ LoadImmediate(D1, 42.0);
  __ LoadImmediate(V0, 42);
  __ cund(D0, D1);
  __ bc1t(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CUN_not_taken, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1CEq, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.5);
  __ LoadImmediate(D1, 42.5);
  __ LoadImmediate(V0, 42);
  __ ceqd(D0, D1);
  __ bc1t(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CEq, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1CEq_not_taken, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.0);
  __ LoadImmediate(D1, 42.5);
  __ LoadImmediate(V0, 42);
  __ ceqd(D0, D1);
  __ bc1t(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CEq_not_taken, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1CEq_false, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.0);
  __ LoadImmediate(D1, 42.5);
  __ LoadImmediate(V0, 42);
  __ ceqd(D0, D1);
  __ bc1f(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CEq_false, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1CEq_false_not_taken, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.5);
  __ LoadImmediate(D1, 42.5);
  __ LoadImmediate(V0, 42);
  __ ceqd(D0, D1);
  __ bc1f(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CEq_false_not_taken, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1COLT, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.0);
  __ LoadImmediate(D1, 42.5);
  __ LoadImmediate(V0, 42);
  __ coltd(D0, D1);
  __ bc1t(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1COLT, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1COLT_not_taken, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.5);
  __ LoadImmediate(D1, 42.0);
  __ LoadImmediate(V0, 42);
  __ coltd(D0, D1);
  __ bc1t(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1COLT_not_taken, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1COLE, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.0);
  __ LoadImmediate(D1, 42.0);
  __ LoadImmediate(V0, 42);
  __ coled(D0, D1);
  __ bc1t(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1COLE, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1COLE_not_taken, assembler) {
  Label is_true;

  __ LoadImmediate(D0, 42.5);
  __ LoadImmediate(D1, 42.0);
  __ LoadImmediate(V0, 42);
  __ coled(D0, D1);
  __ bc1t(&is_true);
  __ mov(V0, ZR);
  __ Bind(&is_true);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1COLE_not_taken, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1CvtDW, assembler) {
  __ LoadImmediate(T0, 42);
  __ mtc1(T0, F2);
  __ cvtdw(D0, F2);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CvtDW, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(42.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Cop1CvtDW_neg, assembler) {
  __ LoadImmediate(T0, -42);
  __ mtc1(T0, F2);
  __ cvtdw(D0, F2);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CvtDW_neg, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(-42.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Cop1CvtDL, assembler) {
  if (TargetCPUFeatures::mips_version() == MIPS32r2) {
    __ LoadImmediate(T0, 0x1);
    __ mtc1(ZR, F2);
    __ mtc1(T0, F3);  // D0 <- 0x100000000 = 4294967296
    __ cvtdl(D0, D1);
  } else {
    __ LoadImmediate(D0, 4294967296.0);
  }
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CvtDL, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(4294967296.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Cop1CvtDL_neg, assembler) {
  if (TargetCPUFeatures::mips_version() == MIPS32r2) {
    __ LoadImmediate(T0, 0xffffffff);
    __ mtc1(T0, F2);
    __ mtc1(T0, F3);  // D0 <- 0xffffffffffffffff = -1
    __ cvtdl(D0, D1);
  } else {
    __ LoadImmediate(D0, -1.0);
  }
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CvtDL_neg, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(-1.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Cop1CvtWD, assembler) {
  __ LoadImmediate(D1, 42.0);
  __ cvtwd(F0, D1);
  __ mfc1(V0, F0);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CvtWD, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1CvtWD_neg, assembler) {
  __ LoadImmediate(D1, -42.0);
  __ cvtwd(F0, D1);
  __ mfc1(V0, F0);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CvtWD_neg, test) {
  typedef int (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Cop1CvtSD, assembler) {
  __ LoadImmediate(D2, -42.42);
  __ cvtsd(F2, D2);
  __ cvtds(D0, F2);
  __ Ret();
}


ASSEMBLER_TEST_RUN(Cop1CvtSD, test) {
  typedef double (*SimpleCode)() DART_UNUSED;
  EXPECT(test != NULL);
  double res = EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry());
  EXPECT_FLOAT_EQ(-42.42, res, 0.001);
}


// Called from assembler_test.cc.
// RA: return address.
// A0: context.
// A1: value.
// A2: growable array.
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ sw(CTX, Address(SP, 1 * kWordSize));
  __ sw(RA, Address(SP, 0 * kWordSize));

  __ mov(CTX, A0);
  __ StoreIntoObject(A2,
                     FieldAddress(A2, GrowableObjectArray::data_offset()),
                     A1);
  __ lw(RA, Address(SP, 0 * kWordSize));
  __ lw(CTX, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
  __ Ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
