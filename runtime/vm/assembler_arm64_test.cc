// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ add(R0, ZR, Operand(ZR));
  __ add(R0, R0, Operand(42));
  __ ret();
}


ASSEMBLER_TEST_RUN(Simple, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Move wide immediate tests.
// movz
ASSEMBLER_TEST_GENERATE(Movz0, assembler) {
  __ movz(R0, 42, 0);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movz0, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movz1, assembler) {
  __ movz(R0, 42, 0);  // Overwritten by next instruction.
  __ movz(R0, 42, 1);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movz1, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42LL << 16, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movz2, assembler) {
  __ movz(R0, 42, 2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movz2, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42LL << 32, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movz3, assembler) {
  __ movz(R0, 42, 3);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movz3, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42LL << 48, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// movn
ASSEMBLER_TEST_GENERATE(Movn0, assembler) {
  __ movn(R0, 42, 0);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movn0, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(~42LL, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movn1, assembler) {
  __ movn(R0, 42, 1);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movn1, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(~(42LL << 16), EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movn2, assembler) {
  __ movn(R0, 42, 2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movn2, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(~(42LL << 32), EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movn3, assembler) {
  __ movn(R0, 42, 3);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movn3, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(~(42LL << 48), EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}

// movk
ASSEMBLER_TEST_GENERATE(Movk0, assembler) {
  __ movz(R0, 1, 3);
  __ movk(R0, 42, 0);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movk0, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(
      42LL | (1LL << 48), EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movk1, assembler) {
  __ movz(R0, 1, 0);
  __ movk(R0, 42, 1);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movk1, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(
      (42LL << 16) | 1, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movk2, assembler) {
  __ movz(R0, 1, 0);
  __ movk(R0, 42, 2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movk2, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(
      (42LL << 32) | 1, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Movk3, assembler) {
  __ movz(R0, 1, 0);
  __ movk(R0, 42, 3);
  __ ret();
}


ASSEMBLER_TEST_RUN(Movk3, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(
      (42LL << 48) | 1, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(MovzBig, assembler) {
  __ movz(R0, 0x8000, 0);
  __ ret();
}


ASSEMBLER_TEST_RUN(MovzBig, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0x8000, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// add tests.
ASSEMBLER_TEST_GENERATE(AddReg, assembler) {
  __ movz(R0, 20, 0);
  __ movz(R1, 22, 0);
  __ add(R0, R0, Operand(R1));
  __ ret();
}


ASSEMBLER_TEST_RUN(AddReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddLSLReg, assembler) {
  __ movz(R0, 20, 0);
  __ movz(R1, 11, 0);
  __ add(R0, R0, Operand(R1, LSL, 1));
  __ ret();
}


ASSEMBLER_TEST_RUN(AddLSLReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddLSRReg, assembler) {
  __ movz(R0, 20, 0);
  __ movz(R1, 44, 0);
  __ add(R0, R0, Operand(R1, LSR, 1));
  __ ret();
}


ASSEMBLER_TEST_RUN(AddLSRReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddASRReg, assembler) {
  __ movz(R0, 20, 0);
  __ movz(R1, 44, 0);
  __ add(R0, R0, Operand(R1, ASR, 1));
  __ ret();
}


ASSEMBLER_TEST_RUN(AddASRReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AddASRNegReg, assembler) {
  __ movz(R0, 43, 0);
  __ movn(R1, 0, 0);  // R1 <- -1
  __ add(R1, ZR, Operand(R1, LSL, 3));  // R1 <- -8
  __ add(R0, R0, Operand(R1, ASR, 3));  // R0 <- 43 + (-8 >> 3)
  __ ret();
}


ASSEMBLER_TEST_RUN(AddASRNegReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// TODO(zra): test other sign extension modes.
ASSEMBLER_TEST_GENERATE(AddExtReg, assembler) {
  __ movz(R0, 43, 0);
  __ movz(R1, 0xffff, 0);
  __ movk(R1, 0xffff, 1);  // R1 <- -1 (32-bit)
  __ add(R0, R0, Operand(R1, SXTW, 0));  // R0 <- R0 + (sign extended R1)
  __ ret();
}


ASSEMBLER_TEST_RUN(AddExtReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Loads and Stores.
ASSEMBLER_TEST_GENERATE(SimpleLoadStore, assembler) {
  __ movz(R0, 43, 0);
  __ movz(R1, 42, 0);
  __ str(R1, Address(SP, -1*kWordSize, Address::PreIndex));
  __ ldr(R0, Address(SP, 1*kWordSize, Address::PostIndex));
  __ ret();
}


ASSEMBLER_TEST_RUN(SimpleLoadStore, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(SimpleLoadStoreHeapTag, assembler) {
  __ movz(R0, 43, 0);
  __ movz(R1, 42, 0);
  __ add(R2, SP, Operand(1));
  __ str(R1, Address(R2, -1));
  __ ldr(R0, Address(R2, -1));
  __ ret();
}


ASSEMBLER_TEST_RUN(SimpleLoadStoreHeapTag, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadStoreLargeIndex, assembler) {
  __ movz(R0, 43, 0);
  __ movz(R1, 42, 0);
  // Largest negative offset that can fit in the signed 9-bit immediate field.
  __ str(R1, Address(SP, -32*kWordSize, Address::PreIndex));
  // Largest positive kWordSize aligned offset that we can fit.
  __ ldr(R0, Address(SP, 31*kWordSize, Address::PostIndex));
  // Correction.
  __ add(SP, SP, Operand(kWordSize));  // Restore SP.
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadStoreLargeIndex, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadStoreLargeOffset, assembler) {
  __ movz(R0, 43, 0);
  __ movz(R1, 42, 0);
  __ sub(SP, SP, Operand(512*kWordSize));
  __ str(R1, Address(SP, 512*kWordSize, Address::Offset));
  __ add(SP, SP, Operand(512*kWordSize));
  __ ldr(R0, Address(SP));
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadStoreLargeOffset, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadStoreExtReg, assembler) {
  __ movz(R0, 43, 0);
  __ movz(R1, 42, 0);
  __ movz(R2, 0xfff8, 0);
  __ movk(R2, 0xffff, 1);  // R2 <- -8 (int32_t).
  // This should sign extend R2, and add to SP to get address,
  // i.e. SP - kWordSize.
  __ str(R1, Address(SP, R2, SXTW));
  __ sub(SP, SP, Operand(kWordSize));
  __ ldr(R0, Address(SP));
  __ add(SP, SP, Operand(kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadStoreExtReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadStoreScaledReg, assembler) {
  __ movz(R0, 43, 0);
  __ movz(R1, 42, 0);
  __ movz(R2, 10, 0);
  __ sub(SP, SP, Operand(10*kWordSize));
  // Store R1 into SP + R2 * kWordSize.
  __ str(R1, Address(SP, R2, UXTX, Address::Scaled));
  __ ldr(R0, Address(SP, R2, UXTX, Address::Scaled));
  __ add(SP, SP, Operand(10*kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadStoreScaledReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Logical register operations.
ASSEMBLER_TEST_GENERATE(AndRegs, assembler) {
  __ movz(R1, 43, 0);
  __ movz(R2, 42, 0);
  __ and_(R0, R1, Operand(R2));
  __ ret();
}


ASSEMBLER_TEST_RUN(AndRegs, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AndShiftRegs, assembler) {
  __ movz(R1, 42, 0);
  __ movz(R2, 21, 0);
  __ and_(R0, R1, Operand(R2, LSL, 1));
  __ ret();
}


ASSEMBLER_TEST_RUN(AndShiftRegs, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(BicRegs, assembler) {
  __ movz(R1, 42, 0);
  __ movz(R2, 5, 0);
  __ bic(R0, R1, Operand(R2));
  __ ret();
}


ASSEMBLER_TEST_RUN(BicRegs, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(OrrRegs, assembler) {
  __ movz(R1, 32, 0);
  __ movz(R2, 10, 0);
  __ orr(R0, R1, Operand(R2));
  __ ret();
}


ASSEMBLER_TEST_RUN(OrrRegs, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(OrnRegs, assembler) {
  __ movz(R1, 32, 0);
  __ movn(R2, 0, 0);  // R2 <- 0xffffffffffffffff.
  __ movk(R2, 0xffd5, 0);  // R2 <- 0xffffffffffffffe5.
  __ orn(R0, R1, Operand(R2));
  __ ret();
}


ASSEMBLER_TEST_RUN(OrnRegs, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(EorRegs, assembler) {
  __ movz(R1, 0xffd5, 0);
  __ movz(R2, 0xffff, 0);
  __ eor(R0, R1, Operand(R2));
  __ ret();
}


ASSEMBLER_TEST_RUN(EorRegs, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(EonRegs, assembler) {
  __ movz(R1, 0xffd5, 0);
  __ movn(R2, 0xffff, 0);
  __ eon(R0, R1, Operand(R2));
  __ ret();
}


ASSEMBLER_TEST_RUN(EonRegs, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Logical immediate operations.
ASSEMBLER_TEST_GENERATE(AndImm, assembler) {
  __ movz(R1, 42, 0);
  __ andi(R0, R1, 0xaaaaaaaaaaaaaaaaULL);
  __ ret();
}


ASSEMBLER_TEST_RUN(AndImm, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AndOneImm, assembler) {
  __ movz(R1, 43, 0);
  __ andi(R0, R1, 1);
  __ ret();
}


ASSEMBLER_TEST_RUN(AndOneImm, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(OrrImm, assembler) {
  __ movz(R1, 0, 0);
  __ movz(R2, 0x3f, 0);
  __ movz(R3, 0xa, 0);
  __ orri(R1, R1, 0x0020002000200020ULL);
  __ orr(R1, R1, Operand(R3));
  __ and_(R0, R1, Operand(R2));
  __ ret();
}


ASSEMBLER_TEST_RUN(OrrImm, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(EorImm, assembler) {
  __ movn(R0, 0, 0);
  __ movk(R0, 0xffd5, 0);  // R0 < 0xffffffffffffffd5.
  __ movz(R1, 0x3f, 0);
  __ eori(R0, R0, 0x3f3f3f3f3f3f3f3fULL);
  __ and_(R0, R0, Operand(R1));
  __ ret();
}


ASSEMBLER_TEST_RUN(EorImm, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Comparisons, branching.
ASSEMBLER_TEST_GENERATE(BranchALForward, assembler) {
  Label l;
  __ movz(R0, 42, 0);
  __ b(&l, AL);
  __ movz(R0, 0, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(BranchALForward, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(BranchALBackwards, assembler) {
  Label l, leave;
  __ movz(R0, 42, 0);
  __ b(&l, AL);

  __ movz(R0, 0, 0);
  __ Bind(&leave);
  __ ret();
  __ movz(R0, 0, 0);

  __ Bind(&l);
  __ b(&leave, AL);
  __ movz(R0, 0, 0);
  __ ret();
}


ASSEMBLER_TEST_RUN(BranchALBackwards, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(CmpEqBranch, assembler) {
  Label l;

  __ movz(R0, 42, 0);
  __ movz(R1, 234, 0);
  __ movz(R2, 234, 0);

  __ cmp(R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, 0, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(CmpEqBranch, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(CmpEqBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, 0, 0);
  __ movz(R1, 233, 0);
  __ movz(R2, 234, 0);

  __ cmp(R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, 42, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(CmpEqBranchNotTaken, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(CmpEq1Branch, assembler) {
  Label l;

  __ movz(R0, 42, 0);
  __ movz(R1, 1, 0);

  __ cmp(R1, Operand(1));
  __ b(&l, EQ);
  __ movz(R0, 0, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(CmpEq1Branch, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(CmnEq1Branch, assembler) {
  Label l;

  __ movz(R0, 42, 0);
  __ movn(R1, 0, 0);  // R1 <- -1

  __ cmn(R1, Operand(1));
  __ b(&l, EQ);
  __ movz(R0, 0, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(CmnEq1Branch, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(CmpLtBranch, assembler) {
  Label l;

  __ movz(R0, 42, 0);
  __ movz(R1, 233, 0);
  __ movz(R2, 234, 0);

  __ cmp(R1, Operand(R2));
  __ b(&l, LT);
  __ movz(R0, 0, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(CmpLtBranch, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(CmpLtBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, 0, 0);
  __ movz(R1, 235, 0);
  __ movz(R2, 234, 0);

  __ cmp(R1, Operand(R2));
  __ b(&l, LT);
  __ movz(R0, 42, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(CmpLtBranchNotTaken, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AndsBranch, assembler) {
  Label l;

  __ movz(R0, 42, 0);
  __ movz(R1, 2, 0);
  __ movz(R2, 1, 0);

  __ ands(R3, R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, 0, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(AndsBranch, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AndsBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, 0, 0);
  __ movz(R1, 2, 0);
  __ movz(R2, 2, 0);

  __ ands(R3, R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, 42, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(AndsBranchNotTaken, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(BicsBranch, assembler) {
  Label l;

  __ movz(R0, 42, 0);
  __ movz(R1, 2, 0);
  __ movz(R2, 2, 0);

  __ bics(R3, R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, 0, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(BicsBranch, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(BicsBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, 0, 0);
  __ movz(R1, 2, 0);
  __ movz(R2, 1, 0);

  __ bics(R3, R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, 42, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(BicsBranchNotTaken, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AndisBranch, assembler) {
  Label l;

  __ movz(R0, 42, 0);
  __ movz(R1, 2, 0);

  __ andis(R3, R1, 1);
  __ b(&l, EQ);
  __ movz(R0, 0, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(AndisBranch, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AndisBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, 0, 0);
  __ movz(R1, 2, 0);

  __ andis(R3, R1, 2);
  __ b(&l, EQ);
  __ movz(R0, 42, 0);
  __ Bind(&l);
  __ ret();
}


ASSEMBLER_TEST_RUN(AndisBranchNotTaken, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Address of PC-rel offset, br, blr.
ASSEMBLER_TEST_GENERATE(AdrBr, assembler) {
  __ movz(R0, 123, 0);
  __ adr(R1, 3 * Instr::kInstrSize);  // R1 <- PC + 3*Instr::kInstrSize
  __ br(R1);
  __ ret();

  // br goes here.
  __ movz(R0, 42, 0);
  __ ret();
}


ASSEMBLER_TEST_RUN(AdrBr, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(AdrBlr, assembler) {
  __ movz(R0, 123, 0);
  __ add(R3, ZR, Operand(LR));  // Save LR.
  __ adr(R1, 4 * Instr::kInstrSize);  // R1 <- PC + 4*Instr::kInstrSize
  __ blr(R1);
  __ add(LR, ZR, Operand(R3));
  __ ret();

  // blr goes here.
  __ movz(R0, 42, 0);
  __ ret();
}


ASSEMBLER_TEST_RUN(AdrBlr, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Misc. arithmetic.
ASSEMBLER_TEST_GENERATE(Udiv, assembler) {
  __ movz(R0, 27, 0);
  __ movz(R1, 9, 0);
  __ udiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Udiv, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)();
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT64(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sdiv, assembler) {
  __ movz(R0, 27, 0);
  __ movz(R1, 9, 0);
  __ neg(R1, R1);
  __ sdiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Sdiv, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)();
  EXPECT_EQ(-3, EXECUTE_TEST_CODE_INT64(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Udiv_zero, assembler) {
  __ movz(R0, 27, 0);
  __ movz(R1, 0, 0);
  __ udiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Udiv_zero, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)();
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sdiv_zero, assembler) {
  __ movz(R0, 27, 0);
  __ movz(R1, 0, 0);
  __ sdiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Sdiv_zero, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)();
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Udiv_corner, assembler) {
  __ movz(R0, 0x8000, 3);  // R0 <- 0x8000000000000000
  __ movn(R1, 0, 0);  // R1 <- 0xffffffffffffffff
  __ udiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Udiv_corner, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)();
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Sdiv_corner, assembler) {
  __ movz(R3, 0x8000, 3);  // R0 <- 0x8000000000000000
  __ movn(R1, 0, 0);  // R1 <- 0xffffffffffffffff
  __ sdiv(R2, R3, R1);
  __ mov(R0, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Sdiv_corner, test) {
  EXPECT(test != NULL);
  typedef int (*Tst)();
  EXPECT_EQ(static_cast<int64_t>(0x8000000000000000),
            EXECUTE_TEST_CODE_INT64(Tst, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lslv, assembler) {
  __ movz(R1, 21, 0);
  __ movz(R2, 1, 0);
  __ lslv(R0, R1, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Lslv, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Lsrv, assembler) {
  __ movz(R1, 84, 0);
  __ movz(R2, 1, 0);
  __ lsrv(R0, R1, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Lsrv, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LShiftingV, assembler) {
  __ movz(R1, 1, 0);
  __ movz(R2, 63, 0);
  __ lslv(R1, R1, R2);
  __ lsrv(R0, R1, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(LShiftingV, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(RShiftingV, assembler) {
  __ movz(R1, 1, 0);
  __ movz(R2, 63, 0);
  __ lslv(R1, R1, R2);
  __ asrv(R0, R1, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(RShiftingV, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mult_pos, assembler) {
  __ movz(R1, 6, 0);
  __ movz(R2, 7, 0);
  __ mul(R0, R1, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Mult_pos, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Mult_neg, assembler) {
  __ movz(R1, 6, 0);
  __ movz(R2, 7, 0);
  __ neg(R2, R2);
  __ mul(R0, R1, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Mult_neg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Smulh_pos, assembler) {
  __ movz(R1, 6, 0);
  __ movz(R2, 7, 0);
  __ smulh(R0, R1, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Smulh_pos, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Smulh_neg, assembler) {
  __ movz(R1, 6, 0);
  __ movz(R2, 7, 0);
  __ neg(R2, R2);
  __ smulh(R0, R1, R2);
  __ ret();
}


ASSEMBLER_TEST_RUN(Smulh_neg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Loading immediate values without the object pool.
ASSEMBLER_TEST_GENERATE(LoadImmediateSmall, assembler) {
  __ LoadImmediate(R0, 42, kNoRegister);
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediateSmall, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediateMed, assembler) {
  __ LoadImmediate(R0, 0xf1234123, kNoRegister);
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediateMed, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0xf1234123, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediateMed2, assembler) {
  __ LoadImmediate(R0, 0x4321f1234123, kNoRegister);
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediateMed2, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0x4321f1234123, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediateLarge, assembler) {
  __ LoadImmediate(R0, 0x9287436598237465, kNoRegister);
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediateLarge, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(static_cast<int64_t>(0x9287436598237465),
            EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediateSmallNeg, assembler) {
  __ LoadImmediate(R0, -42, kNoRegister);
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediateSmallNeg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg, assembler) {
  __ LoadImmediate(R0, -0x1212341234, kNoRegister);
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediateMedNeg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-0x1212341234, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg2, assembler) {
  __ LoadImmediate(R0, -0x1212340000, kNoRegister);
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediateMedNeg2, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-0x1212340000, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg3, assembler) {
  __ LoadImmediate(R0, -0x1200001234, kNoRegister);
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediateMedNeg3, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-0x1200001234, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg4, assembler) {
  __ LoadImmediate(R0, -0x12341234, kNoRegister);
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediateMedNeg4, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(-0x12341234, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Loading immediate values with the object pool.
ASSEMBLER_TEST_GENERATE(LoadImmediatePPSmall, assembler) {
  __ TagAndPushPP();  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ LoadImmediate(R0, 42, PP);
  __ PopAndUntagPP();
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediatePPSmall, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediatePPMed, assembler) {
  __ TagAndPushPP();  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ LoadImmediate(R0, 0xf1234123, PP);
  __ PopAndUntagPP();
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediatePPMed, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0xf1234123, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediatePPMed2, assembler) {
  __ TagAndPushPP();  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ LoadImmediate(R0, 0x4321f1234124, PP);
  __ PopAndUntagPP();
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediatePPMed2, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(0x4321f1234124, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadImmediatePPLarge, assembler) {
  __ TagAndPushPP();  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ LoadImmediate(R0, 0x9287436598237465, PP);
  __ PopAndUntagPP();
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadImmediatePPLarge, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(static_cast<int64_t>(0x9287436598237465),
            EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// LoadObject null.
ASSEMBLER_TEST_GENERATE(LoadObjectNull, assembler) {
  __ TagAndPushPP();  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ LoadObject(R0, Object::null_object(), PP);
  __ PopAndUntagPP();
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadObjectNull, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(reinterpret_cast<int64_t>(Object::null()),
            EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadObjectTrue, assembler) {
  __ TagAndPushPP();  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ LoadObject(R0, Bool::True(), PP);
  __ PopAndUntagPP();
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadObjectTrue, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(reinterpret_cast<int64_t>(Bool::True().raw()),
            EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(LoadObjectFalse, assembler) {
  __ TagAndPushPP();  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ LoadObject(R0, Bool::False(), PP);
  __ PopAndUntagPP();
  __ ret();
}


ASSEMBLER_TEST_RUN(LoadObjectFalse, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(reinterpret_cast<int64_t>(Bool::False().raw()),
            EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(CSelTrue, assembler) {
  __ LoadImmediate(R1, 42, kNoRegister);
  __ LoadImmediate(R2, 1234, kNoRegister);
  __ CompareRegisters(R1, R2);
  __ csel(R0, R1, R2, LT);
  __ ret();
}


ASSEMBLER_TEST_RUN(CSelTrue, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(CSelFalse, assembler) {
  __ LoadImmediate(R1, 42, kNoRegister);
  __ LoadImmediate(R2, 1234, kNoRegister);
  __ CompareRegisters(R1, R2);
  __ csel(R0, R1, R2, GE);
  __ ret();
}


ASSEMBLER_TEST_RUN(CSelFalse, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(1234, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


// Floating point move immediate, to/from integer register.
ASSEMBLER_TEST_GENERATE(Fmovdi, assembler) {
  __ LoadDImmediate(V0, 1.0, kNoPP);
  __ ret();
}


ASSEMBLER_TEST_RUN(Fmovdi, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(1.0, EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Fmovdi2, assembler) {
  __ LoadDImmediate(V0, 123412983.1324524315, kNoPP);
  __ ret();
}


ASSEMBLER_TEST_RUN(Fmovdi2, test) {
  typedef int (*SimpleCode)();
  EXPECT_FLOAT_EQ(123412983.1324524315,
      EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry()), 0.0001f);
}


ASSEMBLER_TEST_GENERATE(Fmovrd, assembler) {
  __ LoadDImmediate(V1, 1.0, kNoPP);
  __ fmovrd(R0, V1);
  __ ret();
}


ASSEMBLER_TEST_RUN(Fmovrd, test) {
  typedef int (*SimpleCode)();
  const int64_t one = bit_cast<int64_t, double>(1.0);
  EXPECT_EQ(one, EXECUTE_TEST_CODE_INT64(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(Fmovdr, assembler) {
  __ LoadDImmediate(V1, 1.0, kNoPP);
  __ fmovrd(R1, V1);
  __ fmovdr(V0, R1);
  __ ret();
}


ASSEMBLER_TEST_RUN(Fmovdr, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(1.0, EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(FldrdFstrdPrePostIndex, assembler) {
  __ LoadDImmediate(V1, 42.0, kNoPP);
  __ fstrd(V1, Address(SP, -1*kWordSize, Address::PreIndex));
  __ fldrd(V0, Address(SP, 1*kWordSize, Address::PostIndex));
  __ ret();
}


ASSEMBLER_TEST_RUN(FldrdFstrdPrePostIndex, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(FldrdFstrdHeapTag, assembler) {
  __ LoadDImmediate(V0, 43.0, kNoPP);
  __ LoadDImmediate(V1, 42.0, kNoPP);
  __ AddImmediate(SP, SP, -1 * kWordSize, kNoPP);
  __ add(R2, SP, Operand(1));
  __ fstrd(V1, Address(R2, -1));
  __ fldrd(V0, Address(R2, -1));
  __ AddImmediate(SP, SP, 1 * kWordSize, kNoPP);
  __ ret();
}


ASSEMBLER_TEST_RUN(FldrdFstrdHeapTag, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(FldrdFstrdLargeIndex, assembler) {
  __ LoadDImmediate(V0, 43.0, kNoPP);
  __ LoadDImmediate(V1, 42.0, kNoPP);
  // Largest negative offset that can fit in the signed 9-bit immediate field.
  __ fstrd(V1, Address(SP, -32*kWordSize, Address::PreIndex));
  // Largest positive kWordSize aligned offset that we can fit.
  __ fldrd(V0, Address(SP, 31*kWordSize, Address::PostIndex));
  // Correction.
  __ add(SP, SP, Operand(kWordSize));  // Restore SP.
  __ ret();
}


ASSEMBLER_TEST_RUN(FldrdFstrdLargeIndex, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(FldrdFstrdLargeOffset, assembler) {
  __ LoadDImmediate(V0, 43.0, kNoPP);
  __ LoadDImmediate(V1, 42.0, kNoPP);
  __ sub(SP, SP, Operand(512*kWordSize));
  __ fstrd(V1, Address(SP, 512*kWordSize, Address::Offset));
  __ add(SP, SP, Operand(512*kWordSize));
  __ fldrd(V0, Address(SP));
  __ ret();
}


ASSEMBLER_TEST_RUN(FldrdFstrdLargeOffset, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(FldrdFstrdExtReg, assembler) {
  __ LoadDImmediate(V0, 43.0, kNoPP);
  __ LoadDImmediate(V1, 42.0, kNoPP);
  __ movz(R2, 0xfff8, 0);
  __ movk(R2, 0xffff, 1);  // R2 <- -8 (int32_t).
  // This should sign extend R2, and add to SP to get address,
  // i.e. SP - kWordSize.
  __ fstrd(V1, Address(SP, R2, SXTW));
  __ sub(SP, SP, Operand(kWordSize));
  __ fldrd(V0, Address(SP));
  __ add(SP, SP, Operand(kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(FldrdFstrdExtReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry()));
}


ASSEMBLER_TEST_GENERATE(FldrdFstrdScaledReg, assembler) {
  __ LoadDImmediate(V0, 43.0, kNoPP);
  __ LoadDImmediate(V1, 42.0, kNoPP);
  __ movz(R2, 10, 0);
  __ sub(SP, SP, Operand(10*kWordSize));
  // Store V1 into SP + R2 * kWordSize.
  __ fstrd(V1, Address(SP, R2, UXTX, Address::Scaled));
  __ fldrd(V0, Address(SP, R2, UXTX, Address::Scaled));
  __ add(SP, SP, Operand(10*kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(FldrdFstrdScaledReg, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(SimpleCode, test->entry()));
}


// Called from assembler_test.cc.
// LR: return address.
// R0: context.
// R1: value.
// R2: growable array.
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ TagAndPushPP();
  __ LoadPoolPointer(PP);
  __ Push(CTX);
  __ Push(LR);
  __ mov(CTX, R0);
  __ StoreIntoObject(R2,
                     FieldAddress(R2, GrowableObjectArray::data_offset()),
                     R1);
  __ Pop(LR);
  __ Pop(CTX);
  __ PopAndUntagPP();
  __ ret();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
