// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
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
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Addiu, assembler) {
  __ addiu(V0, ZR, Immediate(42));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Addiu, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Addiu_overflow, assembler) {
  __ LoadImmediate(V0, 0x7fffffff);
  __ addiu(V0, V0, Immediate(1));  // V0 is modified on overflow.
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Addiu_overflow, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(static_cast<int32_t>(0x80000000),
            EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Addu, assembler) {
  __ addiu(R2, ZR, Immediate(21));
  __ addiu(R3, ZR, Immediate(21));
  __ addu(V0, R2, R3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Addu, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Addu_overflow, assembler) {
  __ LoadImmediate(R2, 0x7fffffff);
  __ addiu(R3, R0, Immediate(1));
  __ addu(V0, R2, R3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Addu_overflow, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(static_cast<int32_t>(0x80000000),
            EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(And, assembler) {
  __ addiu(R2, ZR, Immediate(42));
  __ addiu(R3, ZR, Immediate(2));
  __ and_(V0, R2, R3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(And, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Andi, assembler) {
  __ addiu(R1, ZR, Immediate(42));
  __ andi(V0, R1, Immediate(2));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Andi, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Clo, assembler) {
  __ addiu(R1, ZR, Immediate(-1));
  __ clo(V0, R1);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Clo, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(32, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Clz, assembler) {
  __ addiu(R1, ZR, Immediate(0x7fff));
  __ clz(V0, R1);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Clz, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(17, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Divu, assembler) {
  __ addiu(R1, ZR, Immediate(27));
  __ addiu(R2, ZR, Immediate(9));
  __ divu(R1, R2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Divu, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Div, assembler) {
  __ addiu(R1, ZR, Immediate(27));
  __ addiu(R2, ZR, Immediate(9));
  __ div(R1, R2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Div, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Divu_zero, assembler) {
  __ addiu(R1, ZR, Immediate(27));
  __ addiu(R2, ZR, Immediate(0));
  __ divu(R1, R2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Divu_zero, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Div_zero, assembler) {
  __ addiu(R1, ZR, Immediate(27));
  __ addiu(R2, ZR, Immediate(0));
  __ div(R1, R2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Div_zero, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Divu_corner, assembler) {
  __ LoadImmediate(R1, 0x80000000);
  __ LoadImmediate(R2, 0xffffffff);
  __ divu(R1, R2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Divu_corner, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Div_corner, assembler) {
  __ LoadImmediate(R1, 0x80000000);
  __ LoadImmediate(R2, 0xffffffff);
  __ div(R1, R2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Div_corner, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(static_cast<int32_t>(0x80000000),
            EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lb, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(R1, 0xff);
  __ sb(R1, Address(SP));
  __ lb(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lb, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lb_offset, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(R1, 0xff);
  __ sb(R1, Address(SP, 1));
  __ lb(V0, Address(SP, 1));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lb_offset, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lbu, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(R1, 0xff);
  __ sb(R1, Address(SP));
  __ lbu(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lbu, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(255, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lh, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(R1, 0xffff);
  __ sh(R1, Address(SP));
  __ lh(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lh, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lhu, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(R1, 0xffff);
  __ sh(R1, Address(SP));
  __ lhu(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lhu, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(65535, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lw, assembler) {
  __ addiu(SP, SP, Immediate(-kWordSize * 30));
  __ LoadImmediate(R1, -1);
  __ sw(R1, Address(SP));
  __ lw(V0, Address(SP));
  __ addiu(SP, SP, Immediate(kWordSize * 30));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lw, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lui, assembler) {
  __ lui(V0, Immediate(42));
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Lui, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42 << 16, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sll, assembler) {
  __ LoadImmediate(R1, 21);
  __ sll(V0, R1, 1);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Sll, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Srl, assembler) {
  __ LoadImmediate(R1, 84);
  __ srl(V0, R1, 1);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Srl, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LShifting, assembler) {
  __ LoadImmediate(R1, 1);
  __ sll(R1, R1, 31);
  __ srl(V0, R1, 31);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(LShifting, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(RShifting, assembler) {
  __ LoadImmediate(R1, 1);
  __ sll(R1, R1, 31);
  __ sra(V0, R1, 31);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(RShifting, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sllv, assembler) {
  __ LoadImmediate(R1, 21);
  __ LoadImmediate(R2, 1);
  __ sllv(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Sllv, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Srlv, assembler) {
  __ LoadImmediate(R1, 84);
  __ LoadImmediate(R2, 1);
  __ srlv(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Srlv, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LShiftingV, assembler) {
  __ LoadImmediate(R1, 1);
  __ LoadImmediate(R2, 31);
  __ sllv(R1, R1, R2);
  __ srlv(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(LShiftingV, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(RShiftingV, assembler) {
  __ LoadImmediate(R1, 1);
  __ LoadImmediate(R2, 31);
  __ sllv(R1, R1, R2);
  __ srav(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(RShiftingV, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mult_pos, assembler) {
  __ LoadImmediate(R1, 6);
  __ LoadImmediate(R2, 7);
  __ mult(R1, R2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Mult_pos, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mult_neg, assembler) {
  __ LoadImmediate(R1, -6);
  __ LoadImmediate(R2, 7);
  __ mult(R1, R2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Mult_neg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mult_neg_hi, assembler) {
  __ LoadImmediate(R1, -6);
  __ LoadImmediate(R2, 7);
  __ mult(R1, R2);
  __ mfhi(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Mult_neg_hi, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Multu_lo, assembler) {
  __ LoadImmediate(R1, 6);
  __ LoadImmediate(R2, 7);
  __ multu(R1, R2);
  __ mflo(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Multu_lo, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Multu_hi, assembler) {
  __ LoadImmediate(R1, 65536);
  __ LoadImmediate(R2, 65536);
  __ multu(R1, R2);
  __ mfhi(V0);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Multu_hi, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Subu, assembler) {
  __ LoadImmediate(R1, 737);
  __ LoadImmediate(R2, 695);
  __ subu(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Subu, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Or, assembler) {
  __ LoadImmediate(R1, 34);
  __ LoadImmediate(R2, 8);
  __ or_(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Or, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Nor, assembler) {
  __ LoadImmediate(R1, -47);
  __ LoadImmediate(R2, -60);
  __ nor(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Nor, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Xor, assembler) {
  __ LoadImmediate(R1, 51);
  __ LoadImmediate(R2, 25);
  __ xor_(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Xor, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Slt, assembler) {
  __ LoadImmediate(R1, -1);
  __ LoadImmediate(R2, 0);
  __ slt(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Slt, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sltu, assembler) {
  __ LoadImmediate(R1, -1);
  __ LoadImmediate(R2, 0);
  __ sltu(V0, R1, R2);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Sltu, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movz, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 23);
  __ slt(R3, R1, R2);
  __ movz(V0, R1, R3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Movz, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movn, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 23);
  __ slt(R3, R2, R1);
  __ movn(V0, R1, R3);
  __ jr(RA);
}


ASSEMBLER_TEST_RUN(Movn, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Jr_delay, assembler) {
  __ jr(RA);
  __ delay_slot()->ori(V0, ZR, Immediate(42));
}


ASSEMBLER_TEST_RUN(Jr_delay, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Jalr_delay, assembler) {
  __ Move(R2, RA);
  __ jalr(R2, RA);
  __ delay_slot()->ori(V0, ZR, Immediate(42));
}


ASSEMBLER_TEST_RUN(Jalr_delay, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, test->entry()));
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
