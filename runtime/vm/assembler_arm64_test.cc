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

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
