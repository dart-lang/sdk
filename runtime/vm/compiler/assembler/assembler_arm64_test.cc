// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/compiler/assembler/assembler.h"
#include "vm/cpu.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {
namespace compiler {
#define __ assembler->

#if defined(PRODUCT)
#define EXPECT_DISASSEMBLY(expected)
#else
#define EXPECT_DISASSEMBLY(expected)                                           \
  EXPECT_STREQ(expected, test->RelativeDisassembly())
#endif

ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ add(R0, ZR, Operand(ZR));
  __ add(R0, R0, Operand(42));
  __ ret();
}

ASSEMBLER_TEST_RUN(Simple, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "add r0, zr, zr\n"
      "add r0, r0, #0x2a\n"
      "ret\n");
}

// Move wide immediate tests.
// movz
ASSEMBLER_TEST_GENERATE(Movz0, assembler) {
  __ movz(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movz0, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Movz1, assembler) {
  __ movz(R0, Immediate(42), 0);  // Overwritten by next instruction.
  __ movz(R0, Immediate(42), 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movz1, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42LL << 16, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r0, #0x2a lsl 16\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Movz2, assembler) {
  __ movz(R0, Immediate(42), 2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movz2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42LL << 32, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a lsl 32\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Movz3, assembler) {
  __ movz(R0, Immediate(42), 3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movz3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42LL << 48, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a lsl 48\n"
      "ret\n");
}

// movn
ASSEMBLER_TEST_GENERATE(Movn0, assembler) {
  __ movn(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movn0, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(~42LL, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Movn1, assembler) {
  __ movn(R0, Immediate(42), 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movn1, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(~(42LL << 16), EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x2a lsl 16\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Movn2, assembler) {
  __ movn(R0, Immediate(42), 2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movn2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(~(42LL << 32), EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x2a lsl 32\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Movn3, assembler) {
  __ movn(R0, Immediate(42), 3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movn3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(~(42LL << 48), EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x2a lsl 48\n"
      "ret\n");
}

// movk
ASSEMBLER_TEST_GENERATE(Movk0, assembler) {
  __ movz(R0, Immediate(1), 3);
  __ movk(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movk0, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42LL | (1LL << 48),
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x1 lsl 48\n"
      "movk r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Movk1, assembler) {
  __ movz(R0, Immediate(1), 0);
  __ movk(R0, Immediate(42), 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movk1, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ((42LL << 16) | 1,
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x1\n"
      "movk r0, #0x2a lsl 16\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Movk2, assembler) {
  __ movz(R0, Immediate(1), 0);
  __ movk(R0, Immediate(42), 2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movk2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ((42LL << 32) | 1,
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x1\n"
      "movk r0, #0x2a lsl 32\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Movk3, assembler) {
  __ movz(R0, Immediate(1), 0);
  __ movk(R0, Immediate(42), 3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movk3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ((42LL << 48) | 1,
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x1\n"
      "movk r0, #0x2a lsl 48\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(MovzBig, assembler) {
  __ movz(R0, Immediate(0x8000), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(MovzBig, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x8000, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x8000\n"
      "ret\n");
}

// add tests.
ASSEMBLER_TEST_GENERATE(AddReg, assembler) {
  __ movz(R0, Immediate(20), 0);
  __ movz(R1, Immediate(22), 0);
  __ add(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(AddReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x14\n"
      "movz r1, #0x16\n"
      "add r0, r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AddLSLReg, assembler) {
  __ movz(R0, Immediate(20), 0);
  __ movz(R1, Immediate(11), 0);
  __ add(R0, R0, Operand(R1, LSL, 1));
  __ ret();
}

ASSEMBLER_TEST_RUN(AddLSLReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x14\n"
      "movz r1, #0xb\n"
      "add r0, r0, r1 lsl #1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AddLSRReg, assembler) {
  __ movz(R0, Immediate(20), 0);
  __ movz(R1, Immediate(44), 0);
  __ add(R0, R0, Operand(R1, LSR, 1));
  __ ret();
}

ASSEMBLER_TEST_RUN(AddLSRReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x14\n"
      "movz r1, #0x2c\n"
      "add r0, r0, r1 lsr #1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AddASRReg, assembler) {
  __ movz(R0, Immediate(20), 0);
  __ movz(R1, Immediate(44), 0);
  __ add(R0, R0, Operand(R1, ASR, 1));
  __ ret();
}

ASSEMBLER_TEST_RUN(AddASRReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x14\n"
      "movz r1, #0x2c\n"
      "add r0, r0, r1 asr #1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AddASRNegReg, assembler) {
  __ movz(R0, Immediate(43), 0);
  __ movn(R1, Immediate(0), 0);         // R1 <- -1
  __ add(R1, ZR, Operand(R1, LSL, 3));  // R1 <- -8
  __ add(R0, R0, Operand(R1, ASR, 3));  // R0 <- 43 + (-8 >> 3)
  __ ret();
}

ASSEMBLER_TEST_RUN(AddASRNegReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2b\n"
      "movn r1, #0x0\n"
      "add r1, zr, r1 lsl #3\n"
      "add r0, r0, r1 asr #3\n"
      "ret\n");
}

// TODO(zra): test other sign extension modes.
ASSEMBLER_TEST_GENERATE(AddExtReg, assembler) {
  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(0xffff), 0);
  __ movk(R1, Immediate(0xffff), 1);     // R1 <- -1 (32-bit)
  __ add(R0, R0, Operand(R1, SXTW, 0));  // R0 <- R0 + (sign extended R1)
  __ ret();
}

ASSEMBLER_TEST_RUN(AddExtReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2b\n"
      "movz r1, #0xffff\n"
      "movk r1, #0xffff lsl 16\n"
      "add r0, r0, r1 sxtw\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AddCarryInOut, assembler) {
  __ LoadImmediate(R2, -1);
  __ LoadImmediate(R1, 1);
  __ LoadImmediate(R0, 0);
  __ adds(IP0, R2, Operand(R1));  // c_out = 1.
  __ adcs(IP0, R2, R0);           // c_in = 1, c_out = 1.
  __ adc(R0, R0, R0);             // c_in = 1.
  __ ret();
}

ASSEMBLER_TEST_RUN(AddCarryInOut, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r2, #0x0\n"
      "movz r1, #0x1\n"
      "movz r0, #0x0\n"
      "adds tmp, r2, r1\n"
      "adcs tmp, r2, r0\n"
      "adc r0, r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SubCarryInOut, assembler) {
  __ LoadImmediate(R1, 1);
  __ LoadImmediate(R0, 0);
  __ subs(IP0, R0, Operand(R1));  // c_out = 1.
  __ sbcs(IP0, R0, R0);           // c_in = 1, c_out = 1.
  __ sbc(R0, R0, R0);             // c_in = 1.
  __ ret();
}

ASSEMBLER_TEST_RUN(SubCarryInOut, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x1\n"
      "movz r0, #0x0\n"
      "subs tmp, r0, r1\n"
      "sbcs tmp, r0, r0\n"
      "sbc r0, r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Overflow, assembler) {
  __ LoadImmediate(R0, 0);
  __ LoadImmediate(R1, 1);
  __ LoadImmediate(R2, 0xFFFFFFFFFFFFFFFF);
  __ LoadImmediate(R3, 0x7FFFFFFFFFFFFFFF);
  __ adds(IP0, R2, Operand(R1));  // c_out = 1.
  __ adcs(IP0, R3, R0);           // c_in = 1, c_out = 1, v = 1.
  __ csinc(R0, R0, R0, VS);       // R0 = v ? R0 : R0 + 1.
  __ ret();
}

ASSEMBLER_TEST_RUN(Overflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0x1\n"
      "movn r2, #0x0\n"
      "mov r3, 0x7fffffffffffffff\n"
      "adds tmp, r2, r1\n"
      "adcs tmp, r3, r0\n"
      "csinc r0, r0, r0, vs\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(WordAddCarryInOut, assembler) {
  __ LoadImmediate(R2, -1);
  __ LoadImmediate(R1, 1);
  __ LoadImmediate(R0, 0);
  __ addsw(IP0, R2, Operand(R1));  // c_out = 1.
  __ adcsw(IP0, R2, R0);           // c_in = 1, c_out = 1.
  __ adcw(R0, R0, R0);             // c_in = 1.
  __ ret();
}

ASSEMBLER_TEST_RUN(WordAddCarryInOut, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r2, #0x0\n"
      "movz r1, #0x1\n"
      "movz r0, #0x0\n"
      "addws tmp, r2, r1\n"
      "adcws tmp, r2, r0\n"
      "adcw r0, r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(WordSubCarryInOut, assembler) {
  __ LoadImmediate(R1, 1);
  __ LoadImmediate(R0, 0);
  __ subsw(IP0, R0, Operand(R1));  // c_out = 1.
  __ sbcsw(IP0, R0, R0);           // c_in = 1, c_out = 1.
  __ sbcw(R0, R0, R0);             // c_in = 1.
  __ ret();
}

ASSEMBLER_TEST_RUN(WordSubCarryInOut, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x0FFFFFFFF, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x1\n"
      "movz r0, #0x0\n"
      "subws tmp, r0, r1\n"
      "sbcws tmp, r0, r0\n"
      "sbcw r0, r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(WordOverflow, assembler) {
  __ LoadImmediate(R0, 0);
  __ LoadImmediate(R1, 1);
  __ LoadImmediate(R2, 0xFFFFFFFF);
  __ LoadImmediate(R3, 0x7FFFFFFF);
  __ addsw(IP0, R2, Operand(R1));  // c_out = 1.
  __ adcsw(IP0, R3, R0);           // c_in = 1, c_out = 1, v = 1.
  __ csinc(R0, R0, R0, VS);        // R0 = v ? R0 : R0 + 1.
  __ ret();
}

ASSEMBLER_TEST_RUN(WordOverflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0x1\n"
      "mov r2, 0xffffffff\n"
      "mov r3, 0x7fffffff\n"
      "addws tmp, r2, r1\n"
      "adcws tmp, r3, r0\n"
      "csinc r0, r0, r0, vs\n"
      "ret\n");
}

// Loads and Stores.
ASSEMBLER_TEST_GENERATE(SimpleLoadStore, assembler) {
  __ SetupDartSP();

  __ sub(CSP, CSP,
         Operand(2 * target::kWordSize));  // Must not access beyond CSP.

  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  __ str(R1, Address(SP, -1 * target::kWordSize, Address::PreIndex));
  __ ldr(R0, Address(SP, 1 * target::kWordSize, Address::PostIndex));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(SimpleLoadStore, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "sub csp, csp, #0x10\n"
      "movz r0, #0x2b\n"
      "movz r1, #0x2a\n"
      "str r1, [sp, #-8]!\n"
      "ldr r0, [sp], #8 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SimpleLoadStoreHeapTag, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  __ add(R2, SP, Operand(1));
  __ str(R1, Address(R2, -1));
  __ ldr(R0, Address(R2, -1));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(SimpleLoadStoreHeapTag, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r0, #0x2b\n"
      "movz r1, #0x2a\n"
      "add r2, sp, #0x1\n"
      "str r1, [r2, #-1]\n"
      "ldr r0, [r2, #-1]\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadStoreLargeIndex, assembler) {
  __ SetupDartSP();

  __ sub(CSP, CSP,
         Operand(32 * target::kWordSize));  // Must not access beyond CSP.

  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  // Largest negative offset that can fit in the signed 9-bit immediate field.
  __ str(R1, Address(SP, -32 * target::kWordSize, Address::PreIndex));
  // Largest positive kWordSize aligned offset that we can fit.
  __ ldr(R0, Address(SP, 31 * target::kWordSize, Address::PostIndex));
  // Correction.
  __ add(SP, SP, Operand(target::kWordSize));  // Restore SP.
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreLargeIndex, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "sub csp, csp, #0x100\n"
      "movz r0, #0x2b\n"
      "movz r1, #0x2a\n"
      "str r1, [sp, #-256]!\n"
      "ldr r0, [sp], #248 !\n"
      "add sp, sp, #0x8\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadStoreLargeOffset, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  __ sub(SP, SP, Operand(512 * target::kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ str(R1, Address(SP, 512 * target::kWordSize, Address::Offset));
  __ add(SP, SP, Operand(512 * target::kWordSize));
  __ ldr(R0, Address(SP));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreLargeOffset, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r0, #0x2b\n"
      "movz r1, #0x2a\n"
      "sub sp, sp, #0x1000\n"
      "and csp, sp, 0xfffffffffffffff0\n"
      "str r1, [sp, #4096]\n"
      "add sp, sp, #0x1000\n"
      "ldr r0, [sp]\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadStoreExtReg, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  __ movz(R2, Immediate(0xfff8), 0);
  __ movk(R2, Immediate(0xffff), 1);  // R2 <- -8 (int32_t).
  // This should sign extend R2, and add to SP to get address,
  // i.e. SP - kWordSize.
  __ str(R1, Address(SP, R2, SXTW));
  __ sub(SP, SP, Operand(target::kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ ldr(R0, Address(SP));
  __ add(SP, SP, Operand(target::kWordSize));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreExtReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r0, #0x2b\n"
      "movz r1, #0x2a\n"
      "movz r2, #0xfff8\n"
      "movk r2, #0xffff lsl 16\n"
      "str r1, [sp, r2 sxtw]\n"
      "sub sp, sp, #0x8\n"
      "and csp, sp, 0xfffffffffffffff0\n"
      "ldr r0, [sp]\n"
      "add sp, sp, #0x8\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadStoreScaledReg, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  __ movz(R2, Immediate(10), 0);
  __ sub(SP, SP, Operand(10 * target::kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  // Store R1 into SP + R2 * kWordSize.
  __ str(R1, Address(SP, R2, UXTX, Address::Scaled));
  __ ldr(R0, Address(SP, R2, UXTX, Address::Scaled));
  __ add(SP, SP, Operand(10 * target::kWordSize));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreScaledReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r0, #0x2b\n"
      "movz r1, #0x2a\n"
      "movz r2, #0xa\n"
      "sub sp, sp, #0x50\n"
      "and csp, sp, 0xfffffffffffffff0\n"
      "str r1, [sp, r2 uxtx scaled]\n"
      "ldr r0, [sp, r2 uxtx scaled]\n"
      "add sp, sp, #0x50\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadSigned32Bit, assembler) {
  __ SetupDartSP();

  __ sub(CSP, CSP,
         Operand(2 * target::kWordSize));  // Must not access beyond CSP.

  __ LoadImmediate(R1, 0xffffffff);
  __ str(R1, Address(SP, -4, Address::PreIndex), kFourBytes);
  __ ldr(R0, Address(SP), kFourBytes);
  __ ldr(R1, Address(SP, 4, Address::PostIndex), kFourBytes);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadSigned32Bit, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "sub csp, csp, #0x10\n"
      "mov r1, 0xffffffff\n"
      "strw r1, [sp, #-4]!\n"
      "ldrsw r0, [sp]\n"
      "ldrsw r1, [sp], #4 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SimpleLoadStorePair, assembler) {
  __ SetupDartSP();

  __ sub(CSP, CSP,
         Operand(2 * target::kWordSize));  // Must not access beyond CSP.

  __ LoadImmediate(R2, 43);
  __ LoadImmediate(R3, 42);
  __ stp(R2, R3, Address(SP, -2 * target::kWordSize, Address::PairPreIndex));
  __ ldp(R0, R1, Address(SP, 2 * target::kWordSize, Address::PairPostIndex));
  __ sub(R0, R0, Operand(R1));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(SimpleLoadStorePair, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "sub csp, csp, #0x10\n"
      "movz r2, #0x2b\n"
      "movz r3, #0x2a\n"
      "stp r2, r3, [sp, #-16]!\n"
      "ldp r0, r1, [sp], #16 !\n"
      "sub r0, r0, r1\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadStorePairOffset, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R2, 43);
  __ LoadImmediate(R3, 42);
  __ sub(SP, SP, Operand(4 * target::kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ stp(R2, R3, Address::Pair(SP, 2 * target::kWordSize));
  __ ldp(R0, R1, Address::Pair(SP, 2 * target::kWordSize));
  __ add(SP, SP, Operand(4 * target::kWordSize));
  __ sub(R0, R0, Operand(R1));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStorePairOffset, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r2, #0x2b\n"
      "movz r3, #0x2a\n"
      "sub sp, sp, #0x20\n"
      "and csp, sp, 0xfffffffffffffff0\n"
      "stp r2, r3, [sp, #16]\n"
      "ldp r0, r1, [sp, #16]\n"
      "add sp, sp, #0x20\n"
      "sub r0, r0, r1\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadStorePairUnsigned32, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R2, 0xAABBCCDDEEFF9988);
  __ LoadImmediate(R3, 0xBBCCDDEEFF998877);
  __ sub(SP, SP, Operand(4 * target::kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ stp(R2, R3, Address(SP, 2 * sizeof(uint32_t), Address::PairOffset),
         kUnsignedFourBytes);
  __ ldp(R0, R1, Address(SP, 2 * sizeof(uint32_t), Address::PairOffset),
         kUnsignedFourBytes);
  __ add(SP, SP, Operand(4 * target::kWordSize));
  __ sub(R0, R0, Operand(R1));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStorePairUnsigned32, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-278523631, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r2, #0x9988\n"
      "movk r2, #0xeeff lsl 16\n"
      "movk r2, #0xccdd lsl 32\n"
      "movk r2, #0xaabb lsl 48\n"
      "movz r3, #0x8877\n"
      "movk r3, #0xff99 lsl 16\n"
      "movk r3, #0xddee lsl 32\n"
      "movk r3, #0xbbcc lsl 48\n"
      "sub sp, sp, #0x20\n"
      "and csp, sp, 0xfffffffffffffff0\n"
      "stpw r2, r3, [sp, #8]\n"
      "ldpw r0, r1, [sp, #8]\n"
      "add sp, sp, #0x20\n"
      "sub r0, r0, r1\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadStorePairSigned32, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R2, 0xAABBCCDDEEFF9988);
  __ LoadImmediate(R3, 0xBBCCDDEEFF998877);
  __ sub(SP, SP, Operand(4 * target::kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ stp(R2, R3, Address(SP, 2 * sizeof(int32_t), Address::PairOffset),
         kFourBytes);
  __ ldp(R0, R1, Address(SP, 2 * sizeof(int32_t), Address::PairOffset),
         kFourBytes);
  __ add(SP, SP, Operand(4 * target::kWordSize));
  __ sub(R0, R0, Operand(R1));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStorePairSigned32, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-278523631, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r2, #0x9988\n"
      "movk r2, #0xeeff lsl 16\n"
      "movk r2, #0xccdd lsl 32\n"
      "movk r2, #0xaabb lsl 48\n"
      "movz r3, #0x8877\n"
      "movk r3, #0xff99 lsl 16\n"
      "movk r3, #0xddee lsl 32\n"
      "movk r3, #0xbbcc lsl 48\n"
      "sub sp, sp, #0x20\n"
      "and csp, sp, 0xfffffffffffffff0\n"
      "stpw r2, r3, [sp, #8]\n"
      "ldpsw r0, r1, [sp, #8]\n"
      "add sp, sp, #0x20\n"
      "sub r0, r0, r1\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PushRegisterPair, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R2, 12);
  __ LoadImmediate(R3, 21);
  __ PushRegisterPair(R2, R3);
  __ Pop(R0);
  __ Pop(R1);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(PushRegisterPair, test) {
  EXPECT(test != nullptr);
  typedef int (*PushRegisterPair)() DART_UNUSED;
  EXPECT_EQ(12, EXECUTE_TEST_CODE_INT64(PushRegisterPair, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r2, #0xc\n"
      "movz r3, #0x15\n"
      "stp r2, r3, [sp, #-16]!\n"
      "ldr r0, [sp], #8 !\n"
      "ldr r1, [sp], #8 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PushRegisterPairReversed, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R3, 12);
  __ LoadImmediate(R2, 21);
  __ PushRegisterPair(R3, R2);
  __ Pop(R0);
  __ Pop(R1);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(PushRegisterPairReversed, test) {
  EXPECT(test != nullptr);
  typedef int (*PushRegisterPairReversed)() DART_UNUSED;
  EXPECT_EQ(12,
            EXECUTE_TEST_CODE_INT64(PushRegisterPairReversed, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r3, #0xc\n"
      "movz r2, #0x15\n"
      "stp r3, r2, [sp, #-16]!\n"
      "ldr r0, [sp], #8 !\n"
      "ldr r1, [sp], #8 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PopRegisterPair, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R2, 12);
  __ LoadImmediate(R3, 21);
  __ Push(R3);
  __ Push(R2);
  __ PopRegisterPair(R0, R1);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(PopRegisterPair, test) {
  EXPECT(test != nullptr);
  typedef int (*PopRegisterPair)() DART_UNUSED;
  EXPECT_EQ(12, EXECUTE_TEST_CODE_INT64(PopRegisterPair, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r2, #0xc\n"
      "movz r3, #0x15\n"
      "str r3, [sp, #-8]!\n"
      "str r2, [sp, #-8]!\n"
      "ldp r0, r1, [sp], #16 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(PopRegisterPairReversed, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R3, 12);
  __ LoadImmediate(R2, 21);
  __ Push(R3);
  __ Push(R2);
  __ PopRegisterPair(R1, R0);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(PopRegisterPairReversed, test) {
  EXPECT(test != nullptr);
  typedef int (*PopRegisterPairReversed)() DART_UNUSED;
  EXPECT_EQ(12,
            EXECUTE_TEST_CODE_INT64(PopRegisterPairReversed, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r3, #0xc\n"
      "movz r2, #0x15\n"
      "str r3, [sp, #-8]!\n"
      "str r2, [sp, #-8]!\n"
      "ldp r1, r0, [sp], #16 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadStoreDoublePair, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V1, 3.0);
  __ LoadDImmediate(V2, 4.0);
  __ PushDoublePair(V1, V2);
  __ LoadDImmediate(V1, 0.0);
  __ LoadDImmediate(V2, 0.0);
  __ PopDoublePair(V1, V2);
  __ fsubd(V0, V2, V1);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreDoublePair, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(1.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "fmovd v1, 3.000000\n"
      "fmovd v2, 4.000000\n"
      "fstpd v1, v2, [sp, #-16]!\n"
      "veor v1, v1, v1\n"
      "veor v2, v2, v2\n"
      "fldpd v1, v2, [sp], #16 !\n"
      "fsubd v0, v2, v1\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadStoreQuadPair, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V1, 3.0);
  __ LoadDImmediate(V2, 4.0);
  __ PushQuadPair(V1, V2);
  __ LoadDImmediate(V1, 0.0);
  __ LoadDImmediate(V2, 0.0);
  __ PopQuadPair(V1, V2);
  __ fsubd(V0, V2, V1);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreQuadPair, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(1.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "fmovd v1, 3.000000\n"
      "fmovd v2, 4.000000\n"
      "fstpq v1, v2, [sp, #-32]!\n"
      "veor v1, v1, v1\n"
      "veor v2, v2, v2\n"
      "fldpq v1, v2, [sp], #32 !\n"
      "fsubd v0, v2, v1\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Semaphore, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(40), 0);
  __ movz(R1, Immediate(42), 0);
  __ Push(R0);
  Label retry;
  __ Bind(&retry);
  __ ldxr(R0, SP);
  __ stxr(TMP, R1, SP);  // IP == 0, success
  __ cmp(TMP, Operand(0));
  __ b(&retry, NE);  // NE if context switch occurred between ldrex and strex.
  __ Pop(R0);        // 42
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(Semaphore, test) {
  EXPECT(test != nullptr);
  typedef intptr_t (*Semaphore)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Semaphore, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r0, #0x28\n"
      "movz r1, #0x2a\n"
      "str r0, [sp, #-8]!\n"
      "ldxr r0, sp\n"
      "stxr tmp, r1, sp\n"
      "cmp tmp, #0x0\n"
      "bne -12\n"
      "ldr r0, [sp], #8 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FailedSemaphore, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(40), 0);
  __ movz(R1, Immediate(42), 0);
  __ Push(R0);
  __ ldxr(R0, SP);
  __ clrex();            // Simulate a context switch.
  __ stxr(TMP, R1, SP);  // IP == 1, failure
  __ Pop(R0);            // 40
  __ add(R0, R0, Operand(TMP));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FailedSemaphore, test) {
  EXPECT(test != nullptr);
  typedef intptr_t (*FailedSemaphore)() DART_UNUSED;
  EXPECT_EQ(41, EXECUTE_TEST_CODE_INT64(FailedSemaphore, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r0, #0x28\n"
      "movz r1, #0x2a\n"
      "str r0, [sp, #-8]!\n"
      "ldxr r0, sp\n"
      "clrex\n"
      "stxr tmp, r1, sp\n"
      "ldr r0, [sp], #8 !\n"
      "add r0, r0, tmp\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Semaphore32, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(40), 0);
  __ add(R0, R0, Operand(R0, LSL, 32));
  __ Push(R0);

  __ movz(R0, Immediate(40), 0);
  __ movz(R1, Immediate(42), 0);

  Label retry;
  __ Bind(&retry);
  __ ldxr(R0, SP, kFourBytes);
  // 32 bit operation should ignore the high word of R0 that was pushed on the
  // stack.
  __ stxr(TMP, R1, SP, kFourBytes);  // IP == 0, success
  __ cmp(TMP, Operand(0));
  __ b(&retry, NE);  // NE if context switch occurred between ldrex and strex.
  __ Pop(R0);        // 42 + 42 * 2**32
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(Semaphore32, test) {
  EXPECT(test != nullptr);
  typedef intptr_t (*Semaphore32)() DART_UNUSED;
  // Lower word has been atomically switched from 40 to 42k, whereas upper word
  // is unchanged at 40.
  EXPECT_EQ(42 + (DART_INT64_C(40) << 32),
            EXECUTE_TEST_CODE_INT64(Semaphore32, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r0, #0x28\n"
      "add r0, r0, r0 lsl #32\n"
      "str r0, [sp, #-8]!\n"
      "movz r0, #0x28\n"
      "movz r1, #0x2a\n"
      "ldxrw r0, sp\n"
      "stxrw tmp, r1, sp\n"
      "cmp tmp, #0x0\n"
      "bne -12\n"
      "ldr r0, [sp], #8 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FailedSemaphore32, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(40), 0);
  __ add(R0, R0, Operand(R0, LSL, 32));
  __ Push(R0);

  __ movz(R0, Immediate(40), 0);
  __ movz(R1, Immediate(42), 0);

  __ ldxr(R0, SP, kFourBytes);
  __ clrex();                   // Simulate a context switch.
  __ stxr(TMP, R1, SP, kFourBytes);  // IP == 1, failure
  __ Pop(R0);                   // 40
  __ add(R0, R0, Operand(TMP));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FailedSemaphore32, test) {
  EXPECT(test != nullptr);
  typedef intptr_t (*FailedSemaphore32)() DART_UNUSED;
  // Lower word has had the failure code (1) added to it.  Upper word is
  // unchanged at 40.
  EXPECT_EQ(41 + (DART_INT64_C(40) << 32),
            EXECUTE_TEST_CODE_INT64(FailedSemaphore32, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz r0, #0x28\n"
      "add r0, r0, r0 lsl #32\n"
      "str r0, [sp, #-8]!\n"
      "movz r0, #0x28\n"
      "movz r1, #0x2a\n"
      "ldxrw r0, sp\n"
      "clrex\n"
      "stxrw tmp, r1, sp\n"
      "ldr r0, [sp], #8 !\n"
      "add r0, r0, tmp\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AtomicLoadClear, assembler) {
  __ mov(R1, R0);
  __ LoadImmediate(R2, 2);
  __ ldclr(/*value in*/ R2, /*value out*/ R0, /*address*/ R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(AtomicLoadClear, test) {
  typedef intptr_t (*AtomicLoadClear)(intptr_t) DART_UNUSED;
  intptr_t x = 42;
  EXPECT_EQ(42,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(AtomicLoadClear, test->entry(),
                                            reinterpret_cast<intptr_t>(&x)));
  EXPECT_EQ(40, x);

  EXPECT_DISASSEMBLY(
      "mov r1, r0\n"
      "movz r2, #0x2\n"
      "ldclr r2, r0, [r1]\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AtomicLoadSet, assembler) {
  __ mov(R1, R0);
  __ LoadImmediate(R2, 1);
  __ ldset(/*value in*/ R2, /*value out*/ R0, /*address*/ R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(AtomicLoadSet, test) {
  typedef intptr_t (*AtomicLoadSet)(intptr_t) DART_UNUSED;
  int64_t x = 42;
  EXPECT_EQ(42,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(AtomicLoadSet, test->entry(),
                                            reinterpret_cast<intptr_t>(&x)));
  EXPECT_EQ(43, x);

  EXPECT_DISASSEMBLY(
      "mov r1, r0\n"
      "movz r2, #0x1\n"
      "ldset r2, r0, [r1]\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadAcquireStoreRelease, assembler) {
  // We cannot really test that ldar/stlr have the barrier behavior, but at
  // least we can test that the load/store behavior is correct.
  Label failed, done;

  __ SetupDartSP();
  __ EnterFrame(0);

  // Test 64-bit ladr.
  __ PushImmediate(0x1122334455667788);
  __ ldar(R1, SP, kEightBytes);
  __ CompareImmediate(R1, 0x1122334455667788);
  __ BranchIf(NOT_EQUAL, &failed);
  __ Drop(1);

  // Test 32-bit ladr - must zero extend.
  __ PushImmediate(0x1122334455667788);
  __ ldar(R1, SP, kFourBytes);
  __ CompareImmediate(R1, 0x55667788);
  __ BranchIf(NOT_EQUAL, &failed);
  __ Drop(1);

  // Test 64-bit stlr.
  __ PushImmediate(0);
  __ LoadImmediate(R1, 0x1122334455667788);
  __ stlr(R1, SP, kEightBytes);
  __ Pop(R1);
  __ CompareImmediate(R1, 0x1122334455667788);
  __ BranchIf(NOT_EQUAL, &failed);

  // Test 32-bit stlr.
  __ PushImmediate(0);
  __ LoadImmediate(R1, 0x1122334455667788);
  __ stlr(R1, SP, kFourBytes);
  __ Pop(R1);
  __ CompareImmediate(R1, 0x55667788);
  __ BranchIf(NOT_EQUAL, &failed);

  __ LoadImmediate(R0, 0x42);
  __ b(&done);

  __ Bind(&failed);
  __ LoadImmediate(R0, 0x84);

  __ Bind(&done);
  __ LeaveFrame();
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadAcquireStoreRelease, test) {
  typedef intptr_t (*LoadAcquireStoreRelease)() DART_UNUSED;
  EXPECT_EQ(0x42,
            EXECUTE_TEST_CODE_INT64(LoadAcquireStoreRelease, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "stp fp, lr, [sp, #-16]!\n"
      "mov fp, sp\n"
      "movz tmp, #0x7788\n"
      "movk tmp, #0x5566 lsl 16\n"
      "movk tmp, #0x3344 lsl 32\n"
      "movk tmp, #0x1122 lsl 48\n"
      "str tmp, [sp, #-8]!\n"
      "ldar r1, sp\n"
      "movz tmp2, #0x7788\n"
      "movk tmp2, #0x5566 lsl 16\n"
      "movk tmp2, #0x3344 lsl 32\n"
      "movk tmp2, #0x1122 lsl 48\n"
      "cmp r1, tmp2\n"
      "bne +164\n"
      "add sp, sp, #0x8\n"
      "movz tmp, #0x7788\n"
      "movk tmp, #0x5566 lsl 16\n"
      "movk tmp, #0x3344 lsl 32\n"
      "movk tmp, #0x1122 lsl 48\n"
      "str tmp, [sp, #-8]!\n"
      "ldarw r1, sp\n"
      "movz tmp2, #0x7788\n"
      "movk tmp2, #0x5566 lsl 16\n"
      "cmp r1, tmp2\n"
      "bne +120\n"
      "add sp, sp, #0x8\n"
      "movz tmp, #0x0\n"
      "str tmp, [sp, #-8]!\n"
      "movz r1, #0x7788\n"
      "movk r1, #0x5566 lsl 16\n"
      "movk r1, #0x3344 lsl 32\n"
      "movk r1, #0x1122 lsl 48\n"
      "stlr r1, sp\n"
      "ldr r1, [sp], #8 !\n"
      "movz tmp2, #0x7788\n"
      "movk tmp2, #0x5566 lsl 16\n"
      "movk tmp2, #0x3344 lsl 32\n"
      "movk tmp2, #0x1122 lsl 48\n"
      "cmp r1, tmp2\n"
      "bne +60\n"
      "movz tmp, #0x0\n"
      "str tmp, [sp, #-8]!\n"
      "movz r1, #0x7788\n"
      "movk r1, #0x5566 lsl 16\n"
      "movk r1, #0x3344 lsl 32\n"
      "movk r1, #0x1122 lsl 48\n"
      "stlrw r1, sp\n"
      "ldr r1, [sp], #8 !\n"
      "movz tmp2, #0x7788\n"
      "movk tmp2, #0x5566 lsl 16\n"
      "cmp r1, tmp2\n"
      "bne +12\n"
      "movz r0, #0x42\n"
      "b +8\n"
      "movz r0, #0x84\n"
      "mov sp, fp\n"
      "ldp fp, lr, [sp], #16 !\n"
      "mov csp, sp\n"
      "ret\n");
}

// Logical register operations.
ASSEMBLER_TEST_GENERATE(AndRegs, assembler) {
  __ movz(R1, Immediate(43), 0);
  __ movz(R2, Immediate(42), 0);
  __ and_(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(AndRegs, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2b\n"
      "movz r2, #0x2a\n"
      "and r0, r1, r2\n"
      "ret\n");
}

constexpr uint64_t kU64MinusOne = 0xffffffffffffffffull;
constexpr uint64_t kU64MinInt32 = 0xffffffff80000000ull;
constexpr uint64_t kU64MaxInt32 = 0x000000007fffffffull;
constexpr uint64_t kU64MinInt64 = 0x8000000000000000ull;
constexpr uint64_t kU64MaxInt64 = 0x7fffffffffffffffull;

#define FOR_EACH_ASR_64_TEST_CONFIG(M)                                         \
  M(0ull, 0, 0ull)                                                             \
  M(1ull, 0, 1ull)                                                             \
  M(kU64MaxInt32, 0, kU64MaxInt32)                                             \
  M(kU64MaxInt64, 0, kU64MaxInt64)                                             \
  M(kU64MinInt32, 0, kU64MinInt32)                                             \
  M(kU64MinInt64, 0, kU64MinInt64)                                             \
  M(0ull, 1, 0ull)                                                             \
  M(1ull, 1, 0ull)                                                             \
  M(4ull, 1, 2ull)                                                             \
  M(0xffffull, 1, 0x7fffull)                                                   \
  M(0xffffffffull, 1, 0x7fffffffull)                                           \
  M(kU64MaxInt32, 1, 0x3fffffffull)                                            \
  M(kU64MaxInt64, 1, 0x3fffffffffffffffull)                                    \
  M(kU64MinInt32, 1, 0xffffffffc0000000ull)                                    \
  M(kU64MinInt64, 1, 0xc000000000000000ull)                                    \
  M(kU64MinusOne, 1, kU64MinusOne)                                             \
  M(1ull, 2, 0ull)                                                             \
  M(4ull, 2, 1ull)                                                             \
  M(0xffffull, 2, 0x3fffull)                                                   \
  M(0xffffffffull, 2, 0x3fffffffull)                                           \
  M(kU64MaxInt32, 2, 0x1fffffffull)                                            \
  M(kU64MaxInt64, 2, 0x1fffffffffffffffull)                                    \
  M(kU64MinInt32, 2, 0xffffffffe0000000ull)                                    \
  M(kU64MinInt64, 2, 0xe000000000000000ull)                                    \
  M(kU64MinusOne, 2, kU64MinusOne)                                             \
  M(0ull, 31, 0ull)                                                            \
  M(1ull, 31, 0ull)                                                            \
  M(4ull, 31, 0ull)                                                            \
  M(0xffffull, 31, 0ull)                                                       \
  M(0xffffffffull, 31, 1ull)                                                   \
  M(kU64MaxInt32, 31, 0ull)                                                    \
  M(kU64MaxInt64, 31, 0xffffffffull)                                           \
  M(kU64MinInt32, 31, kU64MinusOne)                                            \
  M(kU64MinInt64, 31, 0xffffffff00000000ull)                                   \
  M(kU64MinusOne, 31, kU64MinusOne)                                            \
  M(0ull, 32, 0ull)                                                            \
  M(1ull, 32, 0ull)                                                            \
  M(4ull, 32, 0ull)                                                            \
  M(0xffffull, 32, 0ull)                                                       \
  M(0xffffffffull, 32, 0ull)                                                   \
  M(kU64MaxInt64, 32, 0x7fffffffull)                                           \
  M(kU64MinInt32, 32, kU64MinusOne)                                            \
  M(kU64MinInt64, 32, 0xffffffff80000000ull)                                   \
  M(kU64MinusOne, 32, kU64MinusOne)                                            \
  M(0ull, 62, 0ull)                                                            \
  M(1ull, 62, 0ull)                                                            \
  M(4ull, 62, 0ull)                                                            \
  M(0xffffull, 62, 0ull)                                                       \
  M(0xffffffffull, 62, 0ull)                                                   \
  M(kU64MaxInt64, 62, 1ull)                                                    \
  M(kU64MinInt32, 62, kU64MinusOne)                                            \
  M(kU64MinInt64, 62, 0xfffffffffffffffeull)                                   \
  M(kU64MinusOne, 62, kU64MinusOne)                                            \
  M(0ull, 63, 0ull)                                                            \
  M(1ull, 63, 0ull)                                                            \
  M(4ull, 63, 0ull)                                                            \
  M(0xffffull, 63, 0ull)                                                       \
  M(0xffffffffull, 63, 0ull)                                                   \
  M(kU64MaxInt64, 63, 0ull)                                                    \
  M(kU64MinInt32, 63, kU64MinusOne)                                            \
  M(kU64MinInt64, 63, kU64MinusOne)                                            \
  M(kU64MinusOne, 63, kU64MinusOne)

#define FOR_EACH_LSR_64_TEST_CONFIG(M)                                         \
  M(0ull, 0, 0ull)                                                             \
  M(1ull, 0, 1ull)                                                             \
  M(kU64MaxInt32, 0, kU64MaxInt32)                                             \
  M(kU64MaxInt64, 0, kU64MaxInt64)                                             \
  M(kU64MinInt32, 0, kU64MinInt32)                                             \
  M(kU64MinInt64, 0, kU64MinInt64)                                             \
  M(0ull, 1, 0ull)                                                             \
  M(1ull, 1, 0ull)                                                             \
  M(4ull, 1, 2ull)                                                             \
  M(0xffffull, 1, 0x7fffull)                                                   \
  M(0xffffffffull, 1, 0x7fffffffull)                                           \
  M(kU64MaxInt32, 1, 0x3fffffffull)                                            \
  M(kU64MaxInt64, 1, 0x3fffffffffffffffull)                                    \
  M(kU64MinInt32, 1, 0x7fffffffc0000000ull)                                    \
  M(kU64MinInt64, 1, 0x4000000000000000ull)                                    \
  M(kU64MinusOne, 1, 0x7fffffffffffffffull)                                    \
  M(1ull, 2, 0ull)                                                             \
  M(4ull, 2, 1ull)                                                             \
  M(0xffffull, 2, 0x3fffull)                                                   \
  M(0xffffffffull, 2, 0x3fffffffull)                                           \
  M(kU64MaxInt32, 2, 0x1fffffffull)                                            \
  M(kU64MaxInt64, 2, 0x1fffffffffffffffull)                                    \
  M(kU64MinInt32, 2, 0x3fffffffe0000000ull)                                    \
  M(kU64MinInt64, 2, 0x2000000000000000ull)                                    \
  M(kU64MinusOne, 2, 0x3fffffffffffffffull)                                    \
  M(0ull, 31, 0ull)                                                            \
  M(1ull, 31, 0ull)                                                            \
  M(4ull, 31, 0ull)                                                            \
  M(0xffffull, 31, 0ull)                                                       \
  M(0xffffffffull, 31, 1ull)                                                   \
  M(kU64MaxInt32, 31, 0ull)                                                    \
  M(kU64MaxInt64, 31, 0xffffffffull)                                           \
  M(kU64MinInt32, 31, 0x1ffffffffull)                                          \
  M(kU64MinInt64, 31, 0x100000000ull)                                          \
  M(kU64MinusOne, 31, 0x1ffffffffull)                                          \
  M(0ull, 32, 0ull)                                                            \
  M(1ull, 32, 0ull)                                                            \
  M(4ull, 32, 0ull)                                                            \
  M(0xffffull, 32, 0ull)                                                       \
  M(0xffffffffull, 32, 0ull)                                                   \
  M(kU64MaxInt64, 32, 0x7fffffffull)                                           \
  M(kU64MinInt32, 32, 0xffffffffull)                                           \
  M(kU64MinInt64, 32, 0x80000000ull)                                           \
  M(kU64MinusOne, 32, 0xffffffffull)                                           \
  M(0ull, 62, 0ull)                                                            \
  M(1ull, 62, 0ull)                                                            \
  M(4ull, 62, 0ull)                                                            \
  M(0xffffull, 62, 0ull)                                                       \
  M(0xffffffffull, 62, 0ull)                                                   \
  M(kU64MaxInt64, 62, 1ull)                                                    \
  M(kU64MinInt32, 62, 3ull)                                                    \
  M(kU64MinInt64, 62, 2ull)                                                    \
  M(kU64MinusOne, 62, 3ull)                                                    \
  M(0ull, 63, 0ull)                                                            \
  M(1ull, 63, 0ull)                                                            \
  M(4ull, 63, 0ull)                                                            \
  M(0xffffull, 63, 0ull)                                                       \
  M(0xffffffffull, 63, 0ull)                                                   \
  M(kU64MaxInt64, 63, 0ull)                                                    \
  M(kU64MinInt32, 63, 1ull)                                                    \
  M(kU64MinInt64, 63, 1ull)                                                    \
  M(kU64MinusOne, 63, 1ull)

#define FOR_EACH_LSL_64_TEST_CONFIG(M)                                         \
  M(0ull, 0, 0ull)                                                             \
  M(1ull, 0, 1ull)                                                             \
  M(kU64MaxInt32, 0, kU64MaxInt32)                                             \
  M(kU64MaxInt64, 0, kU64MaxInt64)                                             \
  M(kU64MinInt32, 0, kU64MinInt32)                                             \
  M(kU64MinInt64, 0, kU64MinInt64)                                             \
  M(0ull, 1, 0ull)                                                             \
  M(1ull, 1, 2ull)                                                             \
  M(4ull, 1, 8ull)                                                             \
  M(0xffffull, 1, 0x1fffeull)                                                  \
  M(0xffffffffull, 1, 0x1fffffffeull)                                          \
  M(kU64MaxInt32, 1, 0xfffffffeull)                                            \
  M(kU64MaxInt64, 1, 0xfffffffffffffffeull)                                    \
  M(kU64MinInt32, 1, 0xffffffff00000000ull)                                    \
  M(kU64MinInt64, 1, 0ull)                                                     \
  M(kU64MinusOne, 1, 0xfffffffffffffffeull)                                    \
  M(1ull, 2, 4ull)                                                             \
  M(4ull, 2, 16ull)                                                            \
  M(0xffffull, 2, 0x3fffcull)                                                  \
  M(0xffffffffull, 2, 0x3fffffffcull)                                          \
  M(kU64MaxInt32, 2, 0x1fffffffcull)                                           \
  M(kU64MaxInt64, 2, 0xfffffffffffffffcull)                                    \
  M(kU64MinInt32, 2, 0xfffffffe00000000ull)                                    \
  M(kU64MinInt64, 2, 0ull)                                                     \
  M(kU64MinusOne, 2, 0xfffffffffffffffcull)                                    \
  M(0ull, 31, 0ull)                                                            \
  M(1ull, 31, 0x0000000080000000ull)                                           \
  M(4ull, 31, 0x0000000200000000ull)                                           \
  M(0xffffull, 31, 0x00007fff80000000ull)                                      \
  M(0xffffffffull, 31, 0x7fffffff80000000ull)                                  \
  M(kU64MaxInt32, 31, 0x3fffffff80000000ull)                                   \
  M(kU64MaxInt64, 31, 0xffffffff80000000ull)                                   \
  M(kU64MinInt32, 31, 0xc000000000000000ull)                                   \
  M(kU64MinInt64, 31, 0ull)                                                    \
  M(kU64MinusOne, 31, 0xffffffff80000000ull)                                   \
  M(0ull, 32, 0ull)                                                            \
  M(1ull, 32, 0x0000000100000000ull)                                           \
  M(4ull, 32, 0x0000000400000000ull)                                           \
  M(0xffffull, 32, 0x0000ffff00000000ull)                                      \
  M(0xffffffffull, 32, 0xffffffff00000000ull)                                  \
  M(kU64MaxInt64, 32, 0xffffffff00000000ull)                                   \
  M(kU64MinInt32, 32, 0x8000000000000000ull)                                   \
  M(kU64MinInt64, 32, 0ull)                                                    \
  M(kU64MinusOne, 32, 0xffffffff00000000ull)                                   \
  M(0ull, 62, 0ull)                                                            \
  M(1ull, 62, 0x4000000000000000ull)                                           \
  M(4ull, 62, 0ull)                                                            \
  M(0xffffull, 62, 0xc000000000000000ull)                                      \
  M(0xffffffffull, 62, 0xc000000000000000ull)                                  \
  M(kU64MaxInt64, 62, 0xc000000000000000ull)                                   \
  M(kU64MinInt32, 62, 0ull)                                                    \
  M(kU64MinInt64, 62, 0ull)                                                    \
  M(kU64MinusOne, 62, 0xc000000000000000ull)                                   \
  M(0ull, 63, 0ull)                                                            \
  M(1ull, 63, 0x8000000000000000ull)                                           \
  M(4ull, 63, 0ull)                                                            \
  M(0xffffull, 63, 0x8000000000000000ull)                                      \
  M(0xffffffffull, 63, 0x8000000000000000ull)                                  \
  M(kU64MaxInt64, 63, 0x8000000000000000ull)                                   \
  M(kU64MinInt32, 63, 0ull)                                                    \
  M(kU64MinInt64, 63, 0ull)                                                    \
  M(kU64MinusOne, 63, 0x8000000000000000ull)

#define SHIFT_64_IMMEDIATE_TEST(macro_op, val, shift, expected)                \
  ASSEMBLER_TEST_GENERATE(macro_op##_##val##_##shift, assembler) {             \
    __ LoadImmediate(R1, bit_cast<int64_t>(val));                              \
    __ macro_op(R0, R1, (shift));                                              \
    __ ret();                                                                  \
  }                                                                            \
                                                                               \
  ASSEMBLER_TEST_RUN(macro_op##_##val##_##shift, test) {                       \
    typedef int64_t (*Int64Return)() DART_UNUSED;                              \
    EXPECT_EQ((expected), bit_cast<uint64_t>(EXECUTE_TEST_CODE_INT64(          \
                              Int64Return, test->entry())));                   \
  }

#define ASR_64_IMMEDIATE_TEST(val, shift, expected)                            \
  SHIFT_64_IMMEDIATE_TEST(AsrImmediate, val, shift, expected)

#define LSR_64_IMMEDIATE_TEST(val, shift, expected)                            \
  SHIFT_64_IMMEDIATE_TEST(LsrImmediate, val, shift, expected)

#define LSL_64_IMMEDIATE_TEST(val, shift, expected)                            \
  SHIFT_64_IMMEDIATE_TEST(LslImmediate, val, shift, expected)

FOR_EACH_ASR_64_TEST_CONFIG(ASR_64_IMMEDIATE_TEST)
FOR_EACH_LSR_64_TEST_CONFIG(LSR_64_IMMEDIATE_TEST)
FOR_EACH_LSL_64_TEST_CONFIG(LSL_64_IMMEDIATE_TEST)

#undef LSL_64_IMMEDIATE_TEST
#undef LSR_64_IMMEDIATE_TEST
#undef ASR_64_IMMEDIATE_TEST
#undef SHIFT_64_IMMEDIATE_TEST
#undef FOR_EACH_LSL_64_TESTS_LIST
#undef FOR_EACH_LSR_64_TESTS_LIST
#undef FOR_EACH_ASR_64_TESTS_LIST

constexpr uint32_t kU32MinusOne = 0xffffffffu;
constexpr uint32_t kU32MinInt32 = 0x80000000u;
constexpr uint32_t kU32MaxInt32 = 0x7fffffffu;

#define FOR_EACH_ASR_32_TEST_CONFIG(M)                                         \
  M(0u, 0, 0u)                                                                 \
  M(1u, 0, 1u)                                                                 \
  M(kU32MaxInt32, 0, kU32MaxInt32)                                             \
  M(kU32MinInt32, 0, kU32MinInt32)                                             \
  M(0u, 1, 0u)                                                                 \
  M(1u, 1, 0u)                                                                 \
  M(4u, 1, 2u)                                                                 \
  M(0xffffu, 1, 0x7fffu)                                                       \
  M(0xffffffffu, 1, 0xffffffffu)                                               \
  M(kU32MaxInt32, 1, 0x3fffffffu)                                              \
  M(kU32MinInt32, 1, 0xc0000000u)                                              \
  M(kU32MinusOne, 1, 0xffffffffu)                                              \
  M(1u, 2, 0u)                                                                 \
  M(4u, 2, 1u)                                                                 \
  M(0xffffu, 2, 0x3fffu)                                                       \
  M(0xffffffffu, 2, 0xffffffffu)                                               \
  M(kU32MaxInt32, 2, 0x1fffffffu)                                              \
  M(kU32MinInt32, 2, 0xe0000000u)                                              \
  M(kU32MinusOne, 2, kU32MinusOne)                                             \
  M(0u, 31, 0u)                                                                \
  M(1u, 31, 0u)                                                                \
  M(4u, 31, 0u)                                                                \
  M(0xffffu, 31, 0u)                                                           \
  M(0xffffffffu, 31, 0xffffffffu)                                              \
  M(kU32MaxInt32, 31, 0u)                                                      \
  M(kU32MinInt32, 31, kU32MinusOne)                                            \
  M(kU32MinusOne, 31, kU32MinusOne)

#define FOR_EACH_LSR_32_TEST_CONFIG(M)                                         \
  M(0u, 0, 0u)                                                                 \
  M(1u, 0, 1u)                                                                 \
  M(kU32MaxInt32, 0, kU32MaxInt32)                                             \
  M(kU32MinInt32, 0, kU32MinInt32)                                             \
  M(0u, 1, 0u)                                                                 \
  M(1u, 1, 0u)                                                                 \
  M(4u, 1, 2u)                                                                 \
  M(0xffffu, 1, 0x7fffu)                                                       \
  M(0xffffffffu, 1, 0x7fffffffu)                                               \
  M(kU32MaxInt32, 1, 0x3fffffffu)                                              \
  M(kU32MinInt32, 1, 0x40000000u)                                              \
  M(kU32MinusOne, 1, 0x7fffffffu)                                              \
  M(1u, 2, 0u)                                                                 \
  M(4u, 2, 1u)                                                                 \
  M(0xffffu, 2, 0x3fffu)                                                       \
  M(0xffffffffu, 2, 0x3fffffffu)                                               \
  M(kU32MaxInt32, 2, 0x1fffffffu)                                              \
  M(kU32MinInt32, 2, 0x20000000u)                                              \
  M(kU32MinusOne, 2, 0x3fffffffu)                                              \
  M(0u, 31, 0u)                                                                \
  M(1u, 31, 0u)                                                                \
  M(4u, 31, 0u)                                                                \
  M(0xffffu, 31, 0u)                                                           \
  M(0xffffffffu, 31, 1u)                                                       \
  M(kU32MaxInt32, 31, 0u)                                                      \
  M(kU32MinInt32, 31, 1u)                                                      \
  M(kU32MinusOne, 31, 1u)

#define FOR_EACH_LSL_32_TEST_CONFIG(M)                                         \
  M(0u, 0, 0u)                                                                 \
  M(1u, 0, 1u)                                                                 \
  M(kU32MaxInt32, 0, kU32MaxInt32)                                             \
  M(kU32MinInt32, 0, kU32MinInt32)                                             \
  M(0u, 1, 0u)                                                                 \
  M(1u, 1, 2u)                                                                 \
  M(4u, 1, 8u)                                                                 \
  M(0xffffu, 1, 0x1fffeu)                                                      \
  M(0xffffffffu, 1, 0xfffffffeu)                                               \
  M(kU32MaxInt32, 1, 0xfffffffeu)                                              \
  M(kU32MinInt32, 1, 0x00000000u)                                              \
  M(kU32MinusOne, 1, 0xfffffffeu)                                              \
  M(1u, 2, 4u)                                                                 \
  M(4u, 2, 16u)                                                                \
  M(0xffffu, 2, 0x3fffcu)                                                      \
  M(0xffffffffu, 2, 0xfffffffcu)                                               \
  M(kU32MaxInt32, 2, 0xfffffffcu)                                              \
  M(kU32MinInt32, 2, 0x00000000u)                                              \
  M(kU32MinusOne, 2, 0xfffffffcu)                                              \
  M(0u, 31, 0u)                                                                \
  M(1u, 31, 0x80000000u)                                                       \
  M(4u, 31, 0x00000000u)                                                       \
  M(0xffffu, 31, 0x80000000u)                                                  \
  M(0xffffffffu, 31, 0x80000000u)                                              \
  M(kU32MaxInt32, 31, 0x80000000u)                                             \
  M(kU32MinInt32, 31, 0x00000000u)                                             \
  M(kU32MinusOne, 31, 0x80000000u)

#define SHIFT_32_IMMEDIATE_TEST(macro_op, val, shift, expected)                \
  ASSEMBLER_TEST_GENERATE(macro_op##a_##val##_##shift, assembler) {            \
    __ LoadImmediate(R1, bit_cast<int32_t>(val));                              \
    __ macro_op(R0, R1, (shift), kFourBytes);                                  \
    __ ret();                                                                  \
  }                                                                            \
                                                                               \
  ASSEMBLER_TEST_RUN(macro_op##a_##val##_##shift, test) {                      \
    typedef int32_t (*Int32Return)() DART_UNUSED;                              \
    EXPECT_EQ((expected), bit_cast<uint32_t>((int32_t)EXECUTE_TEST_CODE_INT64( \
                              Int32Return, test->entry())));                   \
  }

#define ASR_32_IMMEDIATE_TEST(val, shift, expected)                            \
  SHIFT_32_IMMEDIATE_TEST(AsrImmediate, val, shift, expected)

#define LSR_32_IMMEDIATE_TEST(val, shift, expected)                            \
  SHIFT_32_IMMEDIATE_TEST(LsrImmediate, val, shift, expected)

#define LSL_32_IMMEDIATE_TEST(val, shift, expected)                            \
  SHIFT_32_IMMEDIATE_TEST(LslImmediate, val, shift, expected)

FOR_EACH_ASR_32_TEST_CONFIG(ASR_32_IMMEDIATE_TEST)
FOR_EACH_LSR_32_TEST_CONFIG(LSR_32_IMMEDIATE_TEST)
FOR_EACH_LSL_32_TEST_CONFIG(LSL_32_IMMEDIATE_TEST)

#undef LSL_32_IMMEDIATE_TEST
#undef LSR_32_IMMEDIATE_TEST
#undef ASR_32_IMMEDIATE_TEST
#undef SHIFT_32_IMMEDIATE_TEST
#undef FOR_EACH_LSL_32_TESTS_LIST
#undef FOR_EACH_LSR_32_TESTS_LIST
#undef FOR_EACH_ASR_32_TESTS_LIST

ASSEMBLER_TEST_GENERATE(LslImmediate, assembler) {
  __ LslImmediate(R0, R0, 1);
  __ LslImmediate(R0, R0, 2);
  __ LslImmediate(R0, R0, 3);
  __ LslImmediate(R0, R0, 4);
  __ LslImmediate(R0, R0, 60);
  __ LslImmediate(R0, R0, 61);
  __ LslImmediate(R0, R0, 62);
  __ LslImmediate(R0, R0, 63);
  __ LslImmediate(R0, R0, 1, kFourBytes);
  __ LslImmediate(R0, R0, 2, kFourBytes);
  __ LslImmediate(R0, R0, 3, kFourBytes);
  __ LslImmediate(R0, R0, 4, kFourBytes);
  __ LslImmediate(R0, R0, 28, kFourBytes);
  __ LslImmediate(R0, R0, 29, kFourBytes);
  __ LslImmediate(R0, R0, 30, kFourBytes);
  __ LslImmediate(R0, R0, 31, kFourBytes);
}

ASSEMBLER_TEST_RUN(LslImmediate, test) {
  EXPECT_DISASSEMBLY(
      "lsl r0, r0, #1\n"
      "lsl r0, r0, #2\n"
      "lsl r0, r0, #3\n"
      "lsl r0, r0, #4\n"
      "lsl r0, r0, #60\n"
      "lsl r0, r0, #61\n"
      "lsl r0, r0, #62\n"
      "lsl r0, r0, #63\n"
      "lslw r0, r0, #1\n"
      "lslw r0, r0, #2\n"
      "lslw r0, r0, #3\n"
      "lslw r0, r0, #4\n"
      "lslw r0, r0, #28\n"
      "lslw r0, r0, #29\n"
      "lslw r0, r0, #30\n"
      "lslw r0, r0, #31\n");
}

ASSEMBLER_TEST_GENERATE(LsrImmediate, assembler) {
  __ LsrImmediate(R0, R0, 1);
  __ LsrImmediate(R0, R0, 2);
  __ LsrImmediate(R0, R0, 3);
  __ LsrImmediate(R0, R0, 4);
  __ LsrImmediate(R0, R0, 60);
  __ LsrImmediate(R0, R0, 61);
  __ LsrImmediate(R0, R0, 62);
  __ LsrImmediate(R0, R0, 63);
  __ LsrImmediate(R0, R0, 1, kFourBytes);
  __ LsrImmediate(R0, R0, 2, kFourBytes);
  __ LsrImmediate(R0, R0, 3, kFourBytes);
  __ LsrImmediate(R0, R0, 4, kFourBytes);
  __ LsrImmediate(R0, R0, 28, kFourBytes);
  __ LsrImmediate(R0, R0, 29, kFourBytes);
  __ LsrImmediate(R0, R0, 30, kFourBytes);
  __ LsrImmediate(R0, R0, 31, kFourBytes);
}

ASSEMBLER_TEST_RUN(LsrImmediate, test) {
  EXPECT_DISASSEMBLY(
      "lsr r0, r0, #1\n"
      "lsr r0, r0, #2\n"
      "lsr r0, r0, #3\n"
      "lsr r0, r0, #4\n"
      "lsr r0, r0, #60\n"
      "lsr r0, r0, #61\n"
      "lsr r0, r0, #62\n"
      "lsr r0, r0, #63\n"
      "lsrw r0, r0, #1\n"
      "lsrw r0, r0, #2\n"
      "lsrw r0, r0, #3\n"
      "lsrw r0, r0, #4\n"
      "lsrw r0, r0, #28\n"
      "lsrw r0, r0, #29\n"
      "lsrw r0, r0, #30\n"
      "lsrw r0, r0, #31\n");
}

ASSEMBLER_TEST_GENERATE(AsrImmediate, assembler) {
  __ AsrImmediate(R0, R0, 1);
  __ AsrImmediate(R0, R0, 2);
  __ AsrImmediate(R0, R0, 3);
  __ AsrImmediate(R0, R0, 4);
  __ AsrImmediate(R0, R0, 60);
  __ AsrImmediate(R0, R0, 61);
  __ AsrImmediate(R0, R0, 62);
  __ AsrImmediate(R0, R0, 63);
  __ AsrImmediate(R0, R0, 1, kFourBytes);
  __ AsrImmediate(R0, R0, 2, kFourBytes);
  __ AsrImmediate(R0, R0, 3, kFourBytes);
  __ AsrImmediate(R0, R0, 4, kFourBytes);
  __ AsrImmediate(R0, R0, 28, kFourBytes);
  __ AsrImmediate(R0, R0, 29, kFourBytes);
  __ AsrImmediate(R0, R0, 30, kFourBytes);
  __ AsrImmediate(R0, R0, 31, kFourBytes);
}

ASSEMBLER_TEST_RUN(AsrImmediate, test) {
  EXPECT_DISASSEMBLY(
      "asr r0, r0, #1\n"
      "asr r0, r0, #2\n"
      "asr r0, r0, #3\n"
      "asr r0, r0, #4\n"
      "asr r0, r0, #60\n"
      "asr r0, r0, #61\n"
      "asr r0, r0, #62\n"
      "asr r0, r0, #63\n"
      "asrw r0, r0, #1\n"
      "asrw r0, r0, #2\n"
      "asrw r0, r0, #3\n"
      "asrw r0, r0, #4\n"
      "asrw r0, r0, #28\n"
      "asrw r0, r0, #29\n"
      "asrw r0, r0, #30\n"
      "asrw r0, r0, #31\n");
}

ASSEMBLER_TEST_GENERATE(AndShiftRegs, assembler) {
  __ movz(R1, Immediate(42), 0);
  __ movz(R2, Immediate(21), 0);
  __ and_(R0, R1, Operand(R2, LSL, 1));
  __ ret();
}

ASSEMBLER_TEST_RUN(AndShiftRegs, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "movz r2, #0x15\n"
      "and r0, r1, r2 lsl #1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(BicRegs, assembler) {
  __ movz(R1, Immediate(42), 0);
  __ movz(R2, Immediate(5), 0);
  __ bic(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(BicRegs, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "movz r2, #0x5\n"
      "bic r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(OrrRegs, assembler) {
  __ movz(R1, Immediate(32), 0);
  __ movz(R2, Immediate(10), 0);
  __ orr(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(OrrRegs, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x20\n"
      "movz r2, #0xa\n"
      "orr r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(OrnRegs, assembler) {
  __ movz(R1, Immediate(32), 0);
  __ movn(R2, Immediate(0), 0);       // R2 <- 0xffffffffffffffff.
  __ movk(R2, Immediate(0xffd5), 0);  // R2 <- 0xffffffffffffffe5.
  __ orn(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(OrnRegs, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x20\n"
      "movn r2, #0x0\n"
      "movk r2, #0xffd5\n"
      "orn r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(EorRegs, assembler) {
  __ movz(R1, Immediate(0xffd5), 0);
  __ movz(R2, Immediate(0xffff), 0);
  __ eor(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(EorRegs, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0xffd5\n"
      "movz r2, #0xffff\n"
      "eor r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(EonRegs, assembler) {
  __ movz(R1, Immediate(0xffd5), 0);
  __ movn(R2, Immediate(0xffff), 0);
  __ eon(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(EonRegs, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0xffd5\n"
      "movn r2, #0xffff\n"
      "eon r0, r1, r2\n"
      "ret\n");
}

// Logical immediate operations.
ASSEMBLER_TEST_GENERATE(AndImm, assembler) {
  __ movz(R1, Immediate(42), 0);
  __ andi(R0, R1, Immediate(0xaaaaaaaaaaaaaaaaULL));
  __ ret();
}

ASSEMBLER_TEST_RUN(AndImm, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "and r0, r1, 0xaaaaaaaaaaaaaaaa\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AndImmCsp, assembler) {
  // Note we must maintain the ARM64 ABI invariants on CSP here.
  __ mov(TMP, CSP);
  __ sub(TMP2, CSP, Operand(31));
  __ andi(CSP, TMP2, Immediate(~15));
  __ mov(R0, CSP);
  __ sub(R0, TMP, Operand(R0));
  __ mov(CSP, TMP);
  __ ret();
}

ASSEMBLER_TEST_RUN(AndImmCsp, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(32, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov tmp, csp\n"
      "sub tmp2, csp, #0x1f\n"
      "and csp, tmp2, 0xfffffffffffffff0\n"
      "mov r0, csp\n"
      "sub r0, tmp, r0\n"
      "mov csp, tmp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AndOneImm, assembler) {
  __ movz(R1, Immediate(43), 0);
  __ andi(R0, R1, Immediate(1));
  __ ret();
}

ASSEMBLER_TEST_RUN(AndOneImm, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2b\n"
      "and r0, r1, 0x1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(OrrImm, assembler) {
  __ movz(R1, Immediate(0), 0);
  __ movz(R2, Immediate(0x3f), 0);
  __ movz(R3, Immediate(0xa), 0);
  __ orri(R1, R1, Immediate(0x0020002000200020ULL));
  __ orr(R1, R1, Operand(R3));
  __ and_(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(OrrImm, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x0\n"
      "movz r2, #0x3f\n"
      "movz r3, #0xa\n"
      "orr r1, r1, 0x20002000200020\n"
      "orr r1, r1, r3\n"
      "and r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(EorImm, assembler) {
  __ movn(R0, Immediate(0), 0);
  __ movk(R0, Immediate(0xffd5), 0);  // R0 < 0xffffffffffffffd5.
  __ movz(R1, Immediate(0x3f), 0);
  __ eori(R0, R0, Immediate(0x3f3f3f3f3f3f3f3fULL));
  __ and_(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(EorImm, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x0\n"
      "movk r0, #0xffd5\n"
      "movz r1, #0x3f\n"
      "eor r0, r0, 0x3f3f3f3f3f3f3f3f\n"
      "and r0, r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Clz, assembler) {
  Label error;

  __ clz(R1, ZR);
  __ cmp(R1, Operand(64));
  __ b(&error, NE);
  __ LoadImmediate(R2, 42);
  __ clz(R2, R2);
  __ cmp(R2, Operand(58));
  __ b(&error, NE);
  __ LoadImmediate(R0, -1);
  __ clz(R1, R0);
  __ cmp(R1, Operand(0));
  __ b(&error, NE);
  __ add(R0, ZR, Operand(R0, LSR, 3));
  __ clz(R1, R0);
  __ cmp(R1, Operand(3));
  __ b(&error, NE);
  __ mov(R0, ZR);
  __ ret();
  __ Bind(&error);
  __ LoadImmediate(R0, 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Clz, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "clz r1, zr\n"
      "cmp r1, #0x40\n"
      "bne +60\n"
      "movz r2, #0x2a\n"
      "clz r2, r2\n"
      "cmp r2, #0x3a\n"
      "bne +44\n"
      "movn r0, #0x0\n"
      "clz r1, r0\n"
      "cmp r1, #0x0\n"
      "bne +28\n"
      "add r0, zr, r0 lsr #3\n"
      "clz r1, r0\n"
      "cmp r1, #0x3\n"
      "bne +12\n"
      "mov r0, zr\n"
      "ret\n"
      "movz r0, #0x1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Clzw, assembler) {
  Label error;

  __ clzw(R1, ZR);
  __ cmp(R1, Operand(32));
  __ b(&error, NE);
  __ LoadImmediate(R2, 42);
  __ clzw(R2, R2);
  __ cmp(R2, Operand(26));
  __ b(&error, NE);
  __ LoadImmediate(R0, -1);
  __ clzw(R1, R0);
  __ cmp(R1, Operand(0));
  __ b(&error, NE);
  __ add(R0, ZR, Operand(R0, LSR, 35));
  __ clzw(R1, R0);
  __ cmp(R1, Operand(3));
  __ b(&error, NE);
  __ LoadImmediate(R0, 0xFFFFFFFF0FFFFFFF);
  __ clzw(R1, R0);
  __ cmp(R1, Operand(4));
  __ b(&error, NE);
  __ LoadImmediate(R0, 0xFFFFFFFF);
  __ clzw(R1, R0);
  __ cmp(R1, Operand(0));
  __ b(&error, NE);
  __ mov(R0, ZR);
  __ ret();
  __ Bind(&error);
  __ LoadImmediate(R0, 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Clzw, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "clzw r1, zr\n"
      "cmp r1, #0x20\n"
      "bne +92\n"
      "movz r2, #0x2a\n"
      "clzw r2, r2\n"
      "cmp r2, #0x1a\n"
      "bne +76\n"
      "movn r0, #0x0\n"
      "clzw r1, r0\n"
      "cmp r1, #0x0\n"
      "bne +60\n"
      "add r0, zr, r0 lsr #35\n"
      "clzw r1, r0\n"
      "cmp r1, #0x3\n"
      "bne +44\n"
      "mov r0, 0xffffffff0fffffff\n"
      "clzw r1, r0\n"
      "cmp r1, #0x4\n"
      "bne +28\n"
      "mov r0, 0xffffffff\n"
      "clzw r1, r0\n"
      "cmp r1, #0x0\n"
      "bne +12\n"
      "mov r0, zr\n"
      "ret\n"
      "movz r0, #0x1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Rbit, assembler) {
  const int64_t immediate = 0x0000000000000015;
  __ LoadImmediate(R0, immediate);
  __ rbit(R0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Rbit, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  const int64_t expected = 0xa800000000000000;
  EXPECT_EQ(expected, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x15\n"
      "rbit r0, r0\n"
      "ret\n");
}

// Comparisons, branching.
ASSEMBLER_TEST_GENERATE(BranchALForward, assembler) {
  Label l;
  __ movz(R0, Immediate(42), 0);
  __ b(&l, AL);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(BranchALForward, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "b +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(BranchALBackwards, assembler) {
  Label l, leave;
  __ movz(R0, Immediate(42), 0);
  __ b(&l, AL);

  __ movz(R0, Immediate(0), 0);
  __ Bind(&leave);
  __ ret();
  __ movz(R0, Immediate(0), 0);

  __ Bind(&l);
  __ b(&leave, AL);
  __ movz(R0, Immediate(0), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(BranchALBackwards, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "b +16\n"
      "movz r0, #0x0\n"
      "ret\n"
      "movz r0, #0x0\n"
      "b -8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmpEqBranch, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ movz(R1, Immediate(234), 0);
  __ movz(R2, Immediate(234), 0);

  __ cmp(R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpEqBranch, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0xea\n"
      "movz r2, #0xea\n"
      "cmp r1, r2\n"
      "beq +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmpEqBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, Immediate(0), 0);
  __ movz(R1, Immediate(233), 0);
  __ movz(R2, Immediate(234), 0);

  __ cmp(R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, Immediate(42), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpEqBranchNotTaken, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0xe9\n"
      "movz r2, #0xea\n"
      "cmp r1, r2\n"
      "beq +8\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmpEq1Branch, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ movz(R1, Immediate(1), 0);

  __ cmp(R1, Operand(1));
  __ b(&l, EQ);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpEq1Branch, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0x1\n"
      "cmp r1, #0x1\n"
      "beq +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmnEq1Branch, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ movn(R1, Immediate(0), 0);  // R1 <- -1

  __ cmn(R1, Operand(1));
  __ b(&l, EQ);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmnEq1Branch, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movn r1, #0x0\n"
      "cmn r1, #0x1\n"
      "beq +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmpLtBranch, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ movz(R1, Immediate(233), 0);
  __ movz(R2, Immediate(234), 0);

  __ cmp(R1, Operand(R2));
  __ b(&l, LT);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpLtBranch, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0xe9\n"
      "movz r2, #0xea\n"
      "cmp r1, r2\n"
      "blt +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmpLtBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, Immediate(0), 0);
  __ movz(R1, Immediate(235), 0);
  __ movz(R2, Immediate(234), 0);

  __ cmp(R1, Operand(R2));
  __ b(&l, LT);
  __ movz(R0, Immediate(42), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpLtBranchNotTaken, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0xeb\n"
      "movz r2, #0xea\n"
      "cmp r1, r2\n"
      "blt +8\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmpBranchIfZero, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ movz(R1, Immediate(0), 0);

  __ cbz(&l, R1);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpBranchIfZero, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0x0\n"
      "cbz r1, +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmpBranchIfZeroNotTaken, assembler) {
  Label l;

  __ movz(R0, Immediate(0), 0);
  __ movz(R1, Immediate(1), 0);

  __ cbz(&l, R1);
  __ movz(R0, Immediate(42), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpBranchIfZeroNotTaken, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0x1\n"
      "cbz r1, +8\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmpBranchIfNotZero, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ movz(R1, Immediate(1), 0);

  __ cbnz(&l, R1);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpBranchIfNotZero, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0x1\n"
      "cbnz r1, +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CmpBranchIfNotZeroNotTaken, assembler) {
  Label l;

  __ movz(R0, Immediate(0), 0);
  __ movz(R1, Immediate(0), 0);

  __ cbnz(&l, R1);
  __ movz(R0, Immediate(42), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpBranchIfNotZeroNotTaken, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0x0\n"
      "cbnz r1, +8\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

static constexpr int64_t kBits5And35 = (1 << 5) | (1ll << 35);

ASSEMBLER_TEST_GENERATE(TstBranchIfZero, assembler) {
  Label l, l2;

  __ movz(R0, Immediate(42), 0);
  __ LoadImmediate(R1, ~kBits5And35);

  __ tbz(&l, R1, 5);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);

  __ tbz(&l2, R1, 35);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l2);

  __ ret();
}

ASSEMBLER_TEST_RUN(TstBranchIfZero, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movn r1, #0x8 lsl 32\n"
      "movk r1, #0xffdf\n"
      "tbzw r1, #5, +8\n"
      "movz r0, #0x0\n"
      "tbz r1, #35, +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TstBranchIfZeroNotTaken, assembler) {
  Label l;

  __ movz(R0, Immediate(0), 0);
  __ LoadImmediate(R1, kBits5And35);

  __ tbz(&l, R1, 5);
  __ movz(R0, Immediate(42), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(TstBranchIfZeroNotTaken, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0x20\n"
      "movk r1, #0x8 lsl 32\n"
      "tbzw r1, #5, +8\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TstBranchIfNotZero, assembler) {
  Label l, l2;

  __ movz(R0, Immediate(42), 0);
  __ LoadImmediate(R1, kBits5And35);

  __ tbnz(&l, R1, 5);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);

  __ tbnz(&l2, R1, 35);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l2);

  __ ret();
}

ASSEMBLER_TEST_RUN(TstBranchIfNotZero, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0x20\n"
      "movk r1, #0x8 lsl 32\n"
      "tbnzw r1, #5, +8\n"
      "movz r0, #0x0\n"
      "tbnz r1, #35, +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TstBranchIfNotZeroNotTaken, assembler) {
  Label l;

  __ movz(R0, Immediate(0), 0);
  __ LoadImmediate(R1, ~kBits5And35);

  __ tbnz(&l, R1, 5);
  __ movz(R0, Immediate(42), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(TstBranchIfNotZeroNotTaken, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movn r1, #0x8 lsl 32\n"
      "movk r1, #0xffdf\n"
      "tbnzw r1, #5, +8\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TstBranchIfZeroFar, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ LoadImmediate(R1, ~kBits5And35);

  __ tbz(&l, R1, 5);

  const intptr_t kRange = 1 << 14;  // tbz has 14 bits of range.
  for (intptr_t i = 0; i < kRange; i++) {
    __ brk(0);
  }

  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(TstBranchIfZeroFar, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(TstBranchIfNotZeroFar, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ LoadImmediate(R1, kBits5And35);

  __ tbnz(&l, R1, 5);

  const intptr_t kRange = 1 << 14;  // tbnz has 14 bits of range.
  for (intptr_t i = 0; i < kRange; i++) {
    __ brk(0);
  }

  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(TstBranchIfNotZeroFar, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FcmpEqBranch, assembler) {
  Label l;

  __ LoadDImmediate(V0, 42.0);
  __ LoadDImmediate(V1, 234.0);
  __ LoadDImmediate(V2, 234.0);

  __ fcmpd(V1, V2);
  __ b(&l, EQ);
  __ LoadDImmediate(V0, 0.0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(FcmpEqBranch, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0x406d lsl 48\n"
      "fmovdr v1, tmp\n"
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0x406d lsl 48\n"
      "fmovdr v2, tmp\n"
      "fcmpd v1, v2\n"
      "beq +8\n"
      "veor v0, v0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TstBranchIfZeroFar1, assembler) {
  Label l;

  __ LoadImmediate(R0, 41);
  __ tbnz(&l, R0, 5);
  __ Stop("Hammertime");

  for (int i = 0; i < 0x10000; i++) {
    __ add(R0, R0, Operand(1));
    __ sub(R0, R0, Operand(1));
  }

  __ AddImmediate(R0, R0, -1);  // Not run.

  __ Bind(&l);
  __ AddImmediate(R0, R0, 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(TstBranchIfZeroFar1, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(TstBranchIfZeroFar2, assembler) {
  Label l;

  for (int i = 0; i < 0x10000; i++) {
    __ add(R0, R0, Operand(1));
    __ sub(R0, R0, Operand(1));
  }

  __ LoadImmediate(R0, 41);
  __ tbnz(&l, R0, 5);
  __ Stop("Hammertime");

  __ AddImmediate(R0, R0, -1);  // Not run.

  __ Bind(&l);
  __ AddImmediate(R0, R0, 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(TstBranchIfZeroFar2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(TstBranchIfZeroFar3, assembler) {
  Label l, l2;
  __ LoadImmediate(R0, 41);
  __ b(&l, AL);

  __ AddImmediate(R0, R0, -1);  // Not run.

  __ Bind(&l2);
  __ AddImmediate(R0, R0, 1);
  __ ret();

  for (int i = 0; i < 0x10000; i++) {
    __ add(R0, R0, Operand(1));
    __ sub(R0, R0, Operand(1));
  }

  __ Bind(&l);
  __ tbnz(&l2, R0, 5);
  __ Stop("Hammertime");
}

ASSEMBLER_TEST_RUN(TstBranchIfZeroFar3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FcmpEqBranchNotTaken, assembler) {
  Label l;

  __ LoadDImmediate(V0, 0.0);
  __ LoadDImmediate(V1, 233.0);
  __ LoadDImmediate(V2, 234.0);

  __ fcmpd(V1, V2);
  __ b(&l, EQ);
  __ LoadDImmediate(V0, 42.0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(FcmpEqBranchNotTaken, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "veor v0, v0, v0\n"
      "movz tmp, #0x2000 lsl 32\n"
      "movk tmp, #0x406d lsl 48\n"
      "fmovdr v1, tmp\n"
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0x406d lsl 48\n"
      "fmovdr v2, tmp\n"
      "fcmpd v1, v2\n"
      "beq +12\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FcmpLtBranch, assembler) {
  Label l;

  __ LoadDImmediate(V0, 42.0);
  __ LoadDImmediate(V1, 233.0);
  __ LoadDImmediate(V2, 234.0);

  __ fcmpd(V1, V2);
  __ b(&l, LT);
  __ LoadDImmediate(V0, 0.0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(FcmpLtBranch, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FcmpLtBranchNotTaken, assembler) {
  Label l;

  __ LoadDImmediate(V0, 0.0);
  __ LoadDImmediate(V1, 235.0);
  __ LoadDImmediate(V2, 234.0);

  __ fcmpd(V1, V2);
  __ b(&l, LT);
  __ LoadDImmediate(V0, 42.0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(FcmpLtBranchNotTaken, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "veor v0, v0, v0\n"
      "movz tmp, #0x6000 lsl 32\n"
      "movk tmp, #0x406d lsl 48\n"
      "fmovdr v1, tmp\n"
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0x406d lsl 48\n"
      "fmovdr v2, tmp\n"
      "fcmpd v1, v2\n"
      "blt +12\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FcmpzGtBranch, assembler) {
  Label l;

  __ LoadDImmediate(V0, 235.0);
  __ LoadDImmediate(V1, 233.0);

  __ fcmpdz(V1);
  __ b(&l, GT);
  __ LoadDImmediate(V0, 0.0);
  __ ret();
  __ Bind(&l);
  __ LoadDImmediate(V0, 42.0);
  __ ret();
}

ASSEMBLER_TEST_RUN(FcmpzGtBranch, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x6000 lsl 32\n"
      "movk tmp, #0x406d lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x2000 lsl 32\n"
      "movk tmp, #0x406d lsl 48\n"
      "fmovdr v1, tmp\n"
      "fcmpd v1, #0.0\n"
      "bgt +12\n"
      "veor v0, v0, v0\n"
      "ret\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AndsBranch, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ movz(R1, Immediate(2), 0);
  __ movz(R2, Immediate(1), 0);

  __ ands(R3, R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(AndsBranch, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0x2\n"
      "movz r2, #0x1\n"
      "ands r3, r1, r2\n"
      "beq +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AndsBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, Immediate(0), 0);
  __ movz(R1, Immediate(2), 0);
  __ movz(R2, Immediate(2), 0);

  __ ands(R3, R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, Immediate(42), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(AndsBranchNotTaken, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0x2\n"
      "movz r2, #0x2\n"
      "ands r3, r1, r2\n"
      "beq +8\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(BicsBranch, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ movz(R1, Immediate(2), 0);
  __ movz(R2, Immediate(2), 0);

  __ bics(R3, R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(BicsBranch, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0x2\n"
      "movz r2, #0x2\n"
      "bics r3, r1, r2\n"
      "beq +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(BicsBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, Immediate(0), 0);
  __ movz(R1, Immediate(2), 0);
  __ movz(R2, Immediate(1), 0);

  __ bics(R3, R1, Operand(R2));
  __ b(&l, EQ);
  __ movz(R0, Immediate(42), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(BicsBranchNotTaken, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0x2\n"
      "movz r2, #0x1\n"
      "bics r3, r1, r2\n"
      "beq +8\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AndisBranch, assembler) {
  Label l;

  __ movz(R0, Immediate(42), 0);
  __ movz(R1, Immediate(2), 0);

  __ andis(R3, R1, Immediate(1));
  __ b(&l, EQ);
  __ movz(R0, Immediate(0), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(AndisBranch, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0x2\n"
      "ands r3, r1, 0x1\n"
      "beq +8\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(AndisBranchNotTaken, assembler) {
  Label l;

  __ movz(R0, Immediate(0), 0);
  __ movz(R1, Immediate(2), 0);

  __ andis(R3, R1, Immediate(2));
  __ b(&l, EQ);
  __ movz(R0, Immediate(42), 0);
  __ Bind(&l);
  __ ret();
}

ASSEMBLER_TEST_RUN(AndisBranchNotTaken, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x0\n"
      "movz r1, #0x2\n"
      "ands r3, r1, 0x2\n"
      "beq +8\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

// Address of PC-rel offset, br, blr.
ASSEMBLER_TEST_GENERATE(AdrBr, assembler) {
  __ movz(R0, Immediate(123), 0);
  // R1 <- PC + 3*Instr::kInstrSize
  __ adr(R1, Immediate(3 * Instr::kInstrSize));
  __ br(R1);
  __ ret();

  // br goes here.
  __ movz(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(AdrBr, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(AdrBlr, assembler) {
  __ movz(R0, Immediate(123), 0);
  SPILLS_RETURN_ADDRESS_FROM_LR_TO_REGISTER(
      __ add(R3, ZR, Operand(LR)));  // Save LR.
  // R1 <- PC + 4*Instr::kInstrSize
  __ adr(R1, Immediate(4 * Instr::kInstrSize));
  __ blr(R1);
  RESTORES_RETURN_ADDRESS_FROM_REGISTER_TO_LR(__ add(LR, ZR, Operand(R3)));
  __ ret();

  // blr goes here.
  __ movz(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(AdrBlr, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

// Misc. arithmetic.
ASSEMBLER_TEST_GENERATE(Udiv, assembler) {
  __ movz(R0, Immediate(27), 0);
  __ movz(R1, Immediate(9), 0);
  __ udiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Udiv, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x1b\n"
      "movz r1, #0x9\n"
      "udiv r2, r0, r1\n"
      "mov r0, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Sdiv, assembler) {
  __ movz(R0, Immediate(27), 0);
  __ movz(R1, Immediate(9), 0);
  __ neg(R1, R1);
  __ sdiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Sdiv, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-3, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x1b\n"
      "movz r1, #0x9\n"
      "neg r1, r1\n"
      "sdiv r2, r0, r1\n"
      "mov r0, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Udiv_zero, assembler) {
  __ movz(R0, Immediate(27), 0);
  __ movz(R1, Immediate(0), 0);
  __ udiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Udiv_zero, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x1b\n"
      "movz r1, #0x0\n"
      "udiv r2, r0, r1\n"
      "mov r0, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Sdiv_zero, assembler) {
  __ movz(R0, Immediate(27), 0);
  __ movz(R1, Immediate(0), 0);
  __ sdiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Sdiv_zero, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x1b\n"
      "movz r1, #0x0\n"
      "sdiv r2, r0, r1\n"
      "mov r0, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Udiv_corner, assembler) {
  __ movz(R0, Immediate(0x8000), 3);  // R0 <- 0x8000000000000000
  __ movn(R1, Immediate(0), 0);       // R1 <- 0xffffffffffffffff
  __ udiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Udiv_corner, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x8000 lsl 48\n"
      "movn r1, #0x0\n"
      "udiv r2, r0, r1\n"
      "mov r0, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Sdiv_corner, assembler) {
  __ movz(R3, Immediate(0x8000), 3);  // R0 <- 0x8000000000000000
  __ movn(R1, Immediate(0), 0);       // R1 <- 0xffffffffffffffff
  __ sdiv(R2, R3, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Sdiv_corner, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(static_cast<int64_t>(0x8000000000000000),
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r3, #0x8000 lsl 48\n"
      "movn r1, #0x0\n"
      "sdiv r2, r3, r1\n"
      "mov r0, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Lslv, assembler) {
  __ movz(R1, Immediate(21), 0);
  __ movz(R2, Immediate(1), 0);
  __ lslv(R0, R1, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Lslv, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x15\n"
      "movz r2, #0x1\n"
      "lsl r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Lsrv, assembler) {
  __ movz(R1, Immediate(84), 0);
  __ movz(R2, Immediate(1), 0);
  __ lsrv(R0, R1, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Lsrv, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x54\n"
      "movz r2, #0x1\n"
      "lsr r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LShiftingV, assembler) {
  __ movz(R1, Immediate(1), 0);
  __ movz(R2, Immediate(63), 0);
  __ lslv(R1, R1, R2);
  __ lsrv(R0, R1, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(LShiftingV, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x1\n"
      "movz r2, #0x3f\n"
      "lsl r1, r1, r2\n"
      "lsr r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(RShiftingV, assembler) {
  __ movz(R1, Immediate(1), 0);
  __ movz(R2, Immediate(63), 0);
  __ lslv(R1, R1, R2);
  __ asrv(R0, R1, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(RShiftingV, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x1\n"
      "movz r2, #0x3f\n"
      "lsl r1, r1, r2\n"
      "asr r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Mult_pos, assembler) {
  __ movz(R1, Immediate(6), 0);
  __ movz(R2, Immediate(7), 0);
  __ mul(R0, R1, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Mult_pos, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x6\n"
      "movz r2, #0x7\n"
      "mul r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Mult_neg, assembler) {
  __ movz(R1, Immediate(6), 0);
  __ movz(R2, Immediate(7), 0);
  __ neg(R2, R2);
  __ mul(R0, R1, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Mult_neg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x6\n"
      "movz r2, #0x7\n"
      "neg r2, r2\n"
      "mul r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Smulh_pos, assembler) {
  __ movz(R1, Immediate(6), 0);
  __ movz(R2, Immediate(7), 0);
  __ smulh(R0, R1, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Smulh_pos, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x6\n"
      "movz r2, #0x7\n"
      "smulh r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Smulh_neg, assembler) {
  __ movz(R1, Immediate(6), 0);
  __ movz(R2, Immediate(7), 0);
  __ neg(R2, R2);
  __ smulh(R0, R1, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Smulh_neg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x6\n"
      "movz r2, #0x7\n"
      "neg r2, r2\n"
      "smulh r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Umulh, assembler) {
  __ movz(R1, Immediate(-1), 3);  // 0xffff000000000000
  __ movz(R2, Immediate(7), 3);   // 0x0007000000000000
  __ umulh(R0, R1, R2);           // 0x0006fff900000000
  __ ret();
}

ASSEMBLER_TEST_RUN(Umulh, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(static_cast<int64_t>(0x6fff900000000),
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0xffff lsl 48\n"
      "movz r2, #0x7 lsl 48\n"
      "umulh r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Umaddl, assembler) {
  __ movn(R1, Immediate(0), 0);  // W1 = 0xffffffff.
  __ movz(R2, Immediate(7), 0);  // W2 = 7.
  __ movz(R3, Immediate(8), 0);  // X3 = 8.
  __ umaddl(R0, R1, R2, R3);     // X0 = W1*W2 + X3 = 0x700000001.
  __ ret();
}

ASSEMBLER_TEST_RUN(Umaddl, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x700000001, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r1, #0x0\n"
      "movz r2, #0x7\n"
      "movz r3, #0x8\n"
      "umaddl r0, r1, r2, r3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Smaddl, assembler) {
  __ movn(R1, Immediate(1), 0);   // W1 = -2.
  __ movz(R2, Immediate(7), 0);   // W2 = 7.
  __ movz(R3, Immediate(20), 0);  // X3 = 20.
  __ smaddl(R0, R1, R2, R3);      // X0 = W1*W2 + X3 = 6.
  __ ret();
}

ASSEMBLER_TEST_RUN(Smaddl, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(6, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r1, #0x1\n"
      "movz r2, #0x7\n"
      "movz r3, #0x14\n"
      "smaddl r0, r1, r2, r3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Smaddl2, assembler) {
  __ movn(R1, Immediate(1), 0);  // W1 = -2.
  __ movn(R2, Immediate(0), 0);  // W2 = -1.
  __ smull(R0, R1, R2);          // X0 = W1*W2 = 2, alias of smaddl.
  __ ret();
}

ASSEMBLER_TEST_RUN(Smaddl2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r1, #0x1\n"
      "movn r2, #0x0\n"
      "smull r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Smaddl3, assembler) {
  __ movz(R1, Immediate(0xffff), 0);  // W1 = 0xffff.
  __ movz(R2, Immediate(0xffff), 0);  // W2 = 0xffff.
  __ smull(R0, R1, R2);               // X0 = W1*W2, alias of smaddl.
  __ ret();
}

ASSEMBLER_TEST_RUN(Smaddl3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0xfffe0001, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0xffff\n"
      "movz r2, #0xffff\n"
      "smull r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SmaddlOverflow, assembler) {
  Label return_ltuae;
  __ movz(R1, Immediate(0xffff), 0);  // W1 = 0xffff.
  __ AddImmediate(R1, 4);             // W1 = 0x10003.
  __ movz(R2, Immediate(0x7fff), 0);  // W2 = 0xffff.
  __ smull(R0, R1, R2);               // X0 = W1*W2, alias of smaddl.
  __ AsrImmediate(R3, R0, 31);
  __ cmp(R3, Operand(R0, ASR, 63));  // Detect signed 32 bit overflow.
  __ b(&return_ltuae, NE);
  __ ret();
  __ Bind(&return_ltuae);
  __ movz(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(SmaddlOverflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0xffff\n"
      "add r1, r1, #0x4\n"
      "movz r2, #0x7fff\n"
      "smull r0, r1, r2\n"
      "asr r3, r0, #31\n"
      "cmp r3, r0 asr #63\n"
      "bne +8\n"
      "ret\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SmaddlOverflow2, assembler) {
  Label return_ltuae;
  __ movz(R1, Immediate(0xffff), 0);  // W1 = 0xffff.
  __ movn(R2, Immediate(0xffff), 0);  // W2 = -0x10000.
  __ AddImmediate(R2, -3);            // W2 = -0x10003.
  __ smull(R0, R1, R2);               // X0 = W1*W2, alias of smaddl.
  __ AsrImmediate(R3, R0, 31);
  __ cmp(R3, Operand(R0, ASR, 63));  // Detect signed 32 bit overflow.
  __ b(&return_ltuae, NE);
  __ ret();
  __ Bind(&return_ltuae);
  __ movz(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(SmaddlOverflow2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0xffff\n"
      "movn r2, #0xffff\n"
      "sub r2, r2, #0x3\n"
      "smull r0, r1, r2\n"
      "asr r3, r0, #31\n"
      "cmp r3, r0 asr #63\n"
      "bne +8\n"
      "ret\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(SmaddlOverflow3, assembler) {
  Label return_ltuae;
  __ LoadImmediate(R1, 0x01007fff);
  __ LoadImmediate(R2, 0x01007fff);
  __ smull(R0, R1, R2);  // X0 = W1*W2, alias of smaddl.
  __ AsrImmediate(R3, R0, 31);
  __ cmp(R3, Operand(R0, ASR, 63));  // Detect signed 32 bit overflow.
  __ b(&return_ltuae, NE);
  __ ret();
  __ Bind(&return_ltuae);
  __ movz(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(SmaddlOverflow3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x7fff\n"
      "movk r1, #0x100 lsl 16\n"
      "movz r2, #0x7fff\n"
      "movk r2, #0x100 lsl 16\n"
      "smull r0, r1, r2\n"
      "asr r3, r0, #31\n"
      "cmp r3, r0 asr #63\n"
      "bne +8\n"
      "ret\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(NegNoOverflow, assembler) {
  Label return_ltuae;
  __ LoadImmediate(R1, 0x7fffffff);
  __ negsw(R0, R1);
  __ sxtw(R0, R0);
  __ b(&return_ltuae, VS);  // Branch on overflow set.
  __ ret();
  __ Bind(&return_ltuae);
  __ movz(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(NegNoOverflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x7fffffff, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov r1, 0x7fffffff\n"
      "negws r0, r1\n"
      "sxtw r0, r0\n"
      "bvs +8\n"
      "ret\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(NegNoOverflow2, assembler) {
  Label return_ltuae;
  __ LoadImmediate(R1, 0x7123);
  __ negsw(R0, R1);
  __ sxtw(R0, R0);
  __ b(&return_ltuae, VS);  // Branch on overflow set.
  __ ret();
  __ Bind(&return_ltuae);
  __ movz(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(NegNoOverflow2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x7123, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x7123\n"
      "negws r0, r1\n"
      "sxtw r0, r0\n"
      "bvs +8\n"
      "ret\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(NegOverflow, assembler) {
  Label return_ltuae;
  __ LoadImmediate(R1, -0x80000000ll);
  __ negsw(R0, R1);  // X0 = W1*W2, alias of smaddl.
  __ sxtw(R0, R0);
  __ b(&return_ltuae, VS);  // Branch on overflow set.
  __ ret();
  __ Bind(&return_ltuae);
  __ movz(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(NegOverflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov r1, 0xffffffff80000000\n"
      "negws r0, r1\n"
      "sxtw r0, r0\n"
      "bvs +8\n"
      "ret\n"
      "movz r0, #0x2a\n"
      "ret\n");
}

// Loading immediate values without the object pool.
ASSEMBLER_TEST_GENERATE(LoadImmediateSmall, assembler) {
  __ LoadImmediate(R0, 42);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateSmall, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMed, assembler) {
  __ LoadImmediate(R0, 0xf1234123);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMed, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0xf1234123, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x4123\n"
      "movk r0, #0xf123 lsl 16\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMed2, assembler) {
  __ LoadImmediate(R0, 0x4321f1234123);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMed2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x4321f1234123,
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x4123\n"
      "movk r0, #0xf123 lsl 16\n"
      "movk r0, #0x4321 lsl 32\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadImmediateLarge, assembler) {
  __ LoadImmediate(R0, 0x9287436598237465);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateLarge, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(static_cast<int64_t>(0x9287436598237465),
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x7465\n"
      "movk r0, #0x9823 lsl 16\n"
      "movk r0, #0x4365 lsl 32\n"
      "movk r0, #0x9287 lsl 48\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadImmediateSmallNeg, assembler) {
  __ LoadImmediate(R0, -42);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateSmallNeg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x29\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg, assembler) {
  __ LoadImmediate(R0, -0x1212341234);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMedNeg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x1212341234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x12 lsl 32\n"
      "movk r0, #0xedcb lsl 16\n"
      "movk r0, #0xedcc\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg2, assembler) {
  __ LoadImmediate(R0, -0x1212340000);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMedNeg2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x1212340000, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x12 lsl 32\n"
      "movk r0, #0xedcc lsl 16\n"
      "movk r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg3, assembler) {
  __ LoadImmediate(R0, -0x1200001234);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMedNeg3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x1200001234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x12 lsl 32\n"
      "movk r0, #0xedcc\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg4, assembler) {
  __ LoadImmediate(R0, -0x12341234);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMedNeg4, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x12341234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r0, #0x1234 lsl 16\n"
      "movk r0, #0xedcc\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadHalfWordUnaligned, assembler) {
  __ ldr(R1, Address(R0), kTwoBytes);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadHalfWordUnaligned, test) {
  EXPECT(test != nullptr);
  typedef intptr_t (*LoadHalfWordUnaligned)(intptr_t) DART_UNUSED;
  uint8_t buffer[4] = {
      0x89, 0xAB, 0xCD, 0xEF,
  };

  EXPECT_EQ(
      static_cast<int16_t>(static_cast<uint16_t>(0xAB89)),
      EXECUTE_TEST_CODE_INTPTR_INTPTR(LoadHalfWordUnaligned, test->entry(),
                                      reinterpret_cast<intptr_t>(&buffer[0])));
  EXPECT_EQ(
      static_cast<int16_t>(static_cast<uint16_t>(0xCDAB)),
      EXECUTE_TEST_CODE_INTPTR_INTPTR(LoadHalfWordUnaligned, test->entry(),
                                      reinterpret_cast<intptr_t>(&buffer[1])));
  EXPECT_DISASSEMBLY(
      "ldrsh r1, [r0]\n"
      "mov r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadHalfWordUnsignedUnaligned, assembler) {
  __ ldr(R1, Address(R0), kUnsignedTwoBytes);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadHalfWordUnsignedUnaligned, test) {
  EXPECT(test != nullptr);
  typedef intptr_t (*LoadHalfWordUnsignedUnaligned)(intptr_t) DART_UNUSED;
  uint8_t buffer[4] = {
      0x89, 0xAB, 0xCD, 0xEF,
  };

  EXPECT_EQ(0xAB89, EXECUTE_TEST_CODE_INTPTR_INTPTR(
                        LoadHalfWordUnsignedUnaligned, test->entry(),
                        reinterpret_cast<intptr_t>(&buffer[0])));
  EXPECT_EQ(0xCDAB, EXECUTE_TEST_CODE_INTPTR_INTPTR(
                        LoadHalfWordUnsignedUnaligned, test->entry(),
                        reinterpret_cast<intptr_t>(&buffer[1])));
  EXPECT_DISASSEMBLY(
      "ldrh r1, [r0]\n"
      "mov r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(StoreHalfWordUnaligned, assembler) {
  __ LoadImmediate(R1, 0xABCD);
  __ str(R1, Address(R0), kTwoBytes);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(StoreHalfWordUnaligned, test) {
  EXPECT(test != nullptr);
  typedef intptr_t (*StoreHalfWordUnaligned)(intptr_t) DART_UNUSED;
  uint8_t buffer[4] = {
      0, 0, 0, 0,
  };

  EXPECT_EQ(0xABCD, EXECUTE_TEST_CODE_INTPTR_INTPTR(
                        StoreHalfWordUnaligned, test->entry(),
                        reinterpret_cast<intptr_t>(&buffer[0])));
  EXPECT_EQ(0xCD, buffer[0]);
  EXPECT_EQ(0xAB, buffer[1]);
  EXPECT_EQ(0, buffer[2]);

  EXPECT_EQ(0xABCD, EXECUTE_TEST_CODE_INTPTR_INTPTR(
                        StoreHalfWordUnaligned, test->entry(),
                        reinterpret_cast<intptr_t>(&buffer[1])));
  EXPECT_EQ(0xCD, buffer[1]);
  EXPECT_EQ(0xAB, buffer[2]);
  EXPECT_EQ(0, buffer[3]);
  EXPECT_DISASSEMBLY(
      "movz r1, #0xabcd\n"
      "strh r1, [r0]\n"
      "mov r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(LoadWordUnaligned, assembler) {
  __ ldr(R1, Address(R0), kUnsignedFourBytes);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadWordUnaligned, test) {
  EXPECT(test != nullptr);
  typedef int32_t (*LoadWordUnaligned)(intptr_t) DART_UNUSED;
  uint8_t buffer[8] = {0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0};

  EXPECT_EQ(
      static_cast<int32_t>(0x78563412),
      EXECUTE_TEST_CODE_INT32_INTPTR(LoadWordUnaligned, test->entry(),
                                     reinterpret_cast<intptr_t>(&buffer[0])));
  EXPECT_EQ(
      static_cast<int32_t>(0x9A785634),
      EXECUTE_TEST_CODE_INT32_INTPTR(LoadWordUnaligned, test->entry(),
                                     reinterpret_cast<intptr_t>(&buffer[1])));
  EXPECT_EQ(
      static_cast<int32_t>(0xBC9A7856),
      EXECUTE_TEST_CODE_INT32_INTPTR(LoadWordUnaligned, test->entry(),
                                     reinterpret_cast<intptr_t>(&buffer[2])));
  EXPECT_EQ(
      static_cast<int32_t>(0xDEBC9A78),
      EXECUTE_TEST_CODE_INT32_INTPTR(LoadWordUnaligned, test->entry(),
                                     reinterpret_cast<intptr_t>(&buffer[3])));
  EXPECT_DISASSEMBLY(
      "ldrw r1, [r0]\n"
      "mov r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(StoreWordUnaligned, assembler) {
  __ LoadImmediate(R1, 0x12345678);
  __ str(R1, Address(R0), kUnsignedFourBytes);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(StoreWordUnaligned, test) {
  EXPECT(test != nullptr);
  typedef intptr_t (*StoreWordUnaligned)(intptr_t) DART_UNUSED;
  uint8_t buffer[8] = {0, 0, 0, 0, 0, 0, 0, 0};

  EXPECT_EQ(0x12345678, EXECUTE_TEST_CODE_INTPTR_INTPTR(
                            StoreWordUnaligned, test->entry(),
                            reinterpret_cast<intptr_t>(&buffer[0])));
  EXPECT_EQ(0x78, buffer[0]);
  EXPECT_EQ(0x56, buffer[1]);
  EXPECT_EQ(0x34, buffer[2]);
  EXPECT_EQ(0x12, buffer[3]);

  EXPECT_EQ(0x12345678, EXECUTE_TEST_CODE_INTPTR_INTPTR(
                            StoreWordUnaligned, test->entry(),
                            reinterpret_cast<intptr_t>(&buffer[1])));
  EXPECT_EQ(0x78, buffer[1]);
  EXPECT_EQ(0x56, buffer[2]);
  EXPECT_EQ(0x34, buffer[3]);
  EXPECT_EQ(0x12, buffer[4]);

  EXPECT_EQ(0x12345678, EXECUTE_TEST_CODE_INTPTR_INTPTR(
                            StoreWordUnaligned, test->entry(),
                            reinterpret_cast<intptr_t>(&buffer[2])));
  EXPECT_EQ(0x78, buffer[2]);
  EXPECT_EQ(0x56, buffer[3]);
  EXPECT_EQ(0x34, buffer[4]);
  EXPECT_EQ(0x12, buffer[5]);

  EXPECT_EQ(0x12345678, EXECUTE_TEST_CODE_INTPTR_INTPTR(
                            StoreWordUnaligned, test->entry(),
                            reinterpret_cast<intptr_t>(&buffer[3])));
  EXPECT_EQ(0x78, buffer[3]);
  EXPECT_EQ(0x56, buffer[4]);
  EXPECT_EQ(0x34, buffer[5]);
  EXPECT_EQ(0x12, buffer[6]);

  EXPECT_DISASSEMBLY(
      "movz r1, #0x5678\n"
      "movk r1, #0x1234 lsl 16\n"
      "strw r1, [r0]\n"
      "mov r0, r1\n"
      "ret\n");
}

static void EnterTestFrame(Assembler* assembler) {
  __ EnterFrame(0);
  __ Push(CODE_REG);
  __ Push(THR);
  __ Push(HEAP_BITS);
  __ Push(NULL_REG);
  __ TagAndPushPP();
  __ mov(CODE_REG, R0);
  __ mov(THR, R1);
  __ RestorePinnedRegisters();
  __ LoadPoolPointer(PP);
}

static void LeaveTestFrame(Assembler* assembler) {
  __ PopAndUntagPP();
  __ Pop(NULL_REG);
  __ Pop(HEAP_BITS);
  __ Pop(THR);
  __ Pop(CODE_REG);
  __ LeaveFrame();
}

// Loading immediate values with the object pool.
ASSEMBLER_TEST_GENERATE(LoadImmediatePPSmall, assembler) {
  __ SetupDartSP();
  EnterTestFrame(assembler);
  __ LoadImmediate(R0, 42);
  LeaveTestFrame(assembler);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediatePPSmall, test) {
  EXPECT_EQ(42, test->InvokeWithCodeAndThread<int64_t>());
}

ASSEMBLER_TEST_GENERATE(LoadImmediatePPMed, assembler) {
  __ SetupDartSP();
  EnterTestFrame(assembler);
  __ LoadImmediate(R0, 0xf1234123);
  LeaveTestFrame(assembler);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediatePPMed, test) {
  EXPECT_EQ(0xf1234123, test->InvokeWithCodeAndThread<int64_t>());
}

ASSEMBLER_TEST_GENERATE(LoadImmediatePPMed2, assembler) {
  __ SetupDartSP();
  EnterTestFrame(assembler);
  __ LoadImmediate(R0, 0x4321f1234124);
  LeaveTestFrame(assembler);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediatePPMed2, test) {
  EXPECT_EQ(0x4321f1234124, test->InvokeWithCodeAndThread<int64_t>());
}

ASSEMBLER_TEST_GENERATE(LoadImmediatePPLarge, assembler) {
  __ SetupDartSP();
  EnterTestFrame(assembler);
  __ LoadImmediate(R0, 0x9287436598237465);
  LeaveTestFrame(assembler);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediatePPLarge, test) {
  EXPECT_EQ(static_cast<int64_t>(0x9287436598237465),
            test->InvokeWithCodeAndThread<int64_t>());
}

// LoadObject null.
ASSEMBLER_TEST_GENERATE(LoadObjectNull, assembler) {
  __ SetupDartSP();
  EnterTestFrame(assembler);
  __ LoadObject(R0, Object::null_object());
  LeaveTestFrame(assembler);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadObjectNull, test) {
  EXPECT_EQ(static_cast<uword>(Object::null()),
            test->InvokeWithCodeAndThread<uword>());
}

// PushObject null.
ASSEMBLER_TEST_GENERATE(PushObjectNull, assembler) {
  __ SetupDartSP();
  EnterTestFrame(assembler);
  __ PushObject(Object::null_object());
  __ Pop(R0);
  LeaveTestFrame(assembler);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(PushObjectNull, test) {
  EXPECT_EQ(static_cast<uword>(Object::null()),
            test->InvokeWithCodeAndThread<uword>());
}

// CompareObject null.
ASSEMBLER_TEST_GENERATE(CompareObjectNull, assembler) {
  __ SetupDartSP();
  EnterTestFrame(assembler);
  __ LoadObject(R0, Object::bool_true());
  __ LoadObject(R1, Object::bool_false());
  __ ldr(R2, Address(THR, Thread::object_null_offset()));
  __ CompareObject(R2, Object::null_object());
  __ csel(R0, R0, R1, EQ);
  LeaveTestFrame(assembler);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(CompareObjectNull, test) {
  EXPECT_EQ(static_cast<uword>(Bool::True().ptr()),
            test->InvokeWithCodeAndThread<uword>());
}

ASSEMBLER_TEST_GENERATE(LoadObjectTrue, assembler) {
  __ SetupDartSP();
  EnterTestFrame(assembler);
  __ LoadObject(R0, Bool::True());
  LeaveTestFrame(assembler);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadObjectTrue, test) {
  EXPECT_EQ(static_cast<uword>(Bool::True().ptr()),
            test->InvokeWithCodeAndThread<uword>());
}

ASSEMBLER_TEST_GENERATE(LoadObjectFalse, assembler) {
  __ SetupDartSP();
  EnterTestFrame(assembler);
  __ LoadObject(R0, Bool::False());
  LeaveTestFrame(assembler);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadObjectFalse, test) {
  EXPECT_EQ(static_cast<uword>(Bool::False().ptr()),
            test->InvokeWithCodeAndThread<uword>());
}

ASSEMBLER_TEST_GENERATE(CSelTrue, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 1234);
  __ CompareRegisters(R1, R2);
  __ csel(R0, R1, R2, LT);
  __ ret();
}

ASSEMBLER_TEST_RUN(CSelTrue, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "movz r2, #0x4d2\n"
      "cmp r1, r2\n"
      "csel r0, r1, r2, lt\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CSelFalse, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 1234);
  __ CompareRegisters(R1, R2);
  __ csel(R0, R1, R2, GE);
  __ ret();
}

ASSEMBLER_TEST_RUN(CSelFalse, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "movz r2, #0x4d2\n"
      "cmp r1, r2\n"
      "csel r0, r1, r2, ge\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CsincFalse, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 1234);
  __ CompareRegisters(R1, R2);
  __ csinc(R0, R2, R1, GE);
  __ ret();
}

ASSEMBLER_TEST_RUN(CsincFalse, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(43, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(CsincTrue, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 1234);
  __ CompareRegisters(R1, R2);
  __ csinc(R0, R2, R1, LT);
  __ ret();
}

ASSEMBLER_TEST_RUN(CsincTrue, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "movz r2, #0x4d2\n"
      "cmp r1, r2\n"
      "cinc r0, r2, ge\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CsinvFalse, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 1234);
  __ CompareRegisters(R1, R2);
  __ csinv(R0, R2, R1, GE);
  __ ret();
}

ASSEMBLER_TEST_RUN(CsinvFalse, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(~42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "movz r2, #0x4d2\n"
      "cmp r1, r2\n"
      "csinv r0, r2, r1, ge\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CsinvTrue, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 1234);
  __ CompareRegisters(R1, R2);
  __ csinv(R0, R2, R1, LT);
  __ ret();
}

ASSEMBLER_TEST_RUN(CsinvTrue, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "movz r2, #0x4d2\n"
      "cmp r1, r2\n"
      "csinv r0, r2, r1, lt\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CsnegFalse, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 1234);
  __ CompareRegisters(R1, R2);
  __ csneg(R0, R2, R1, GE);
  __ ret();
}

ASSEMBLER_TEST_RUN(CsnegFalse, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "movz r2, #0x4d2\n"
      "cmp r1, r2\n"
      "csneg r0, r2, r1, ge\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CsnegTrue, assembler) {
  __ LoadImmediate(R1, 42);
  __ LoadImmediate(R2, 1234);
  __ CompareRegisters(R1, R2);
  __ csneg(R0, R2, R1, LT);
  __ ret();
}

ASSEMBLER_TEST_RUN(CsnegTrue, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x2a\n"
      "movz r2, #0x4d2\n"
      "cmp r1, r2\n"
      "csneg r0, r2, r1, lt\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Ubfx, assembler) {
  __ LoadImmediate(R1, 0x819);
  __ LoadImmediate(R0, 0x5a5a5a5a);  // Overwritten.
  __ ubfx(R0, R1, 4, 8);
  __ ret();
}

ASSEMBLER_TEST_RUN(Ubfx, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x81, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x819\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "ubfm r0, r1, #4, #11\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Sbfx, assembler) {
  __ LoadImmediate(R1, 0x819);
  __ LoadImmediate(R0, 0x5a5a5a5a);  // Overwritten.
  __ sbfx(R0, R1, 4, 8);
  __ ret();
}

ASSEMBLER_TEST_RUN(Sbfx, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x7f, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x819\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "sbfm r0, r1, #4, #11\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Bfi, assembler) {
  __ LoadImmediate(R1, 0x819);
  __ LoadImmediate(R0, 0x5a5a5a5a);
  __ bfi(R0, R1, 12, 5);
  __ ret();
}

ASSEMBLER_TEST_RUN(Bfi, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x5a5b9a5a, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x819\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "bfm r0, r1, #52, #4\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Ubfiz, assembler) {
  __ LoadImmediate(R1, 0xff1248ff);
  __ LoadImmediate(R0, 0x5a5a5a5a);
  // Take 30 low bits and place at position 1 in R0, zeroing the rest.
  __ ubfiz(R0, R1, 1, 30);
  __ ret();
}

ASSEMBLER_TEST_RUN(Ubfiz, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x7e2491fe, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x48ff\n"
      "movk r1, #0xff12 lsl 16\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "ubfm r0, r1, #63, #29\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Bfxil, assembler) {
  __ LoadImmediate(R1, 0x819);
  __ LoadImmediate(R0, 0x5a5a5a5a);
  __ bfxil(R0, R1, 4, 8);
  __ ret();
}

ASSEMBLER_TEST_RUN(Bfxil, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x5a5a5a81, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x819\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "bfm r0, r1, #4, #11\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Sbfiz, assembler) {
  __ LoadImmediate(R1, 0x819);
  __ LoadImmediate(R0, 0x5a5a5a5a);  // Overwritten.
  __ sbfiz(R0, R1, 4, 12);
  __ ret();
}

ASSEMBLER_TEST_RUN(Sbfiz, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x7e70, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0x819\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "sbfm r0, r1, #60, #11\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Sxtb, assembler) {
  __ LoadImmediate(R1, 0xff);
  __ LoadImmediate(R0, 0x5a5a5a5a);  // Overwritten.
  __ sxtb(R0, R1);
  __ LoadImmediate(R2, 0x2a);
  __ LoadImmediate(R1, 0x5a5a5a5a);  // Overwritten.
  __ sxtb(R1, R2);
  __ add(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(Sxtb, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x29, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r1, #0xff\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "sxtb r0, r1\n"
      "movz r2, #0x2a\n"
      "movz r1, #0x5a5a\n"
      "movk r1, #0x5a5a lsl 16\n"
      "sxtb r1, r2\n"
      "add r0, r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Sxth, assembler) {
  __ LoadImmediate(R1, 0xffff);
  __ LoadImmediate(R0, 0x5a5a5a5a);  // Overwritten.
  __ sxth(R0, R1);
  __ LoadImmediate(R2, 0x1002a);
  __ LoadImmediate(R1, 0x5a5a5a5a);  // Overwritten.
  __ sxth(R1, R2);
  __ add(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(Sxth, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x29, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov r1, 0xffff\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "sxth r0, r1\n"
      "movz r2, #0x2a\n"
      "movk r2, #0x1 lsl 16\n"
      "movz r1, #0x5a5a\n"
      "movk r1, #0x5a5a lsl 16\n"
      "sxth r1, r2\n"
      "add r0, r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Sxtw, assembler) {
  __ LoadImmediate(R1, 0xffffffffll);
  __ LoadImmediate(R0, 0x5a5a5a5a);  // Overwritten.
  __ sxtw(R0, R1);
  __ LoadImmediate(R2, 0x10000002all);
  __ LoadImmediate(R1, 0x5a5a5a5a);  // Overwritten.
  __ sxtw(R1, R2);
  __ add(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(Sxtw, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x29, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov r1, 0xffffffff\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "sxtw r0, r1\n"
      "movz r2, #0x2a\n"
      "movk r2, #0x1 lsl 32\n"
      "movz r1, #0x5a5a\n"
      "movk r1, #0x5a5a lsl 16\n"
      "sxtw r1, r2\n"
      "add r0, r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Uxtw, assembler) {
  __ LoadImmediate(R1, 0xffffffffll);
  __ LoadImmediate(R0, 0x5a5a5a5a);  // Overwritten.
  __ ubfiz(R0, R1, 0, 32);           // Zero extend word.
  __ LoadImmediate(R2, 0x10000002all);
  __ LoadImmediate(R1, 0x5a5a5a5a);  // Overwritten.
  __ ubfiz(R1, R2, 0, 32);           // Zero extend word.
  __ add(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(Uxtw, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0xffffffffll + 42,
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov r1, 0xffffffff\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "ubfm r0, r1, #0, #31\n"
      "movz r2, #0x2a\n"
      "movk r2, #0x1 lsl 32\n"
      "movz r1, #0x5a5a\n"
      "movk r1, #0x5a5a lsl 16\n"
      "ubfm r1, r2, #0, #31\n"
      "add r0, r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Uxtb, assembler) {
  __ LoadImmediate(R1, -1);
  __ LoadImmediate(R0, 0x5a5a5a5a);  // Overwritten.
  __ uxtb(R0, R1);
  __ LoadImmediate(R2, 0x12a);
  __ LoadImmediate(R1, 0x5a5a5a5a);  // Overwritten.
  __ uxtb(R1, R2);
  __ add(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(Uxtb, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0xff + 0x2a, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r1, #0x0\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "uxtb r0, r1\n"
      "movz r2, #0x12a\n"
      "movz r1, #0x5a5a\n"
      "movk r1, #0x5a5a lsl 16\n"
      "uxtb r1, r2\n"
      "add r0, r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Uxth, assembler) {
  __ LoadImmediate(R1, -1);
  __ LoadImmediate(R0, 0x5a5a5a5a);  // Overwritten.
  __ uxth(R0, R1);
  __ LoadImmediate(R2, 0x1002a);
  __ LoadImmediate(R1, 0x5a5a5a5a);  // Overwritten.
  __ uxth(R1, R2);
  __ add(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(Uxth, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0xffff + 0x2a, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movn r1, #0x0\n"
      "movz r0, #0x5a5a\n"
      "movk r0, #0x5a5a lsl 16\n"
      "uxth r0, r1\n"
      "movz r2, #0x2a\n"
      "movk r2, #0x1 lsl 16\n"
      "movz r1, #0x5a5a\n"
      "movk r1, #0x5a5a lsl 16\n"
      "uxth r1, r2\n"
      "add r0, r0, r1\n"
      "ret\n");
}

// Floating point move immediate, to/from integer register.
ASSEMBLER_TEST_GENERATE(Fmovdi, assembler) {
  __ LoadDImmediate(V0, 1.0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fmovdi, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(1.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v0, 1.000000\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fmovdi2, assembler) {
  __ LoadDImmediate(V0, 123412983.1324524315);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fmovdi2, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_FLOAT_EQ(123412983.1324524315,
                  EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()),
                  0.0001f);
  EXPECT_DISASSEMBLY(
      "movz tmp, #0xa19c\n"
      "movk tmp, #0xdc87 lsl 16\n"
      "movk tmp, #0x6c87 lsl 32\n"
      "movk tmp, #0x419d lsl 48\n"
      "fmovdr v0, tmp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fmovrd, assembler) {
  __ LoadDImmediate(V1, 1.0);
  __ fmovrd(R0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fmovrd, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  const int64_t one = bit_cast<int64_t, double>(1.0);
  EXPECT_EQ(one, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v1, 1.000000\n"
      "fmovrd r0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fmovdr, assembler) {
  __ LoadDImmediate(V1, 1.0);
  __ fmovrd(R1, V1);
  __ fmovdr(V0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fmovdr, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(1.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v1, 1.000000\n"
      "fmovrd r1, v1\n"
      "fmovdr v0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fmovrs, assembler) {
  __ LoadDImmediate(V2, 1.0);
  __ fcvtsd(V1, V2);
  __ fmovrs(R0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fmovrs, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  int64_t result = EXECUTE_TEST_CODE_INT64(Int64Return, test->entry());
  const uint32_t one = bit_cast<uint32_t, float>(1.0f);
  EXPECT_EQ(one, static_cast<uint32_t>(result));
  EXPECT_DISASSEMBLY(
      "fmovd v2, 1.000000\n"
      "fcvtsd v1, v2\n"
      "fmovrsw r0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fmovsr, assembler) {
  __ LoadImmediate(R2, bit_cast<uint32_t, float>(1.0f));
  __ fmovsr(V1, R2);
  __ fmovrs(R0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fmovsr, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  int64_t result = EXECUTE_TEST_CODE_INT64(Int64Return, test->entry());
  const uint32_t one = bit_cast<uint32_t, float>(1.0f);
  EXPECT_EQ(one, static_cast<uint32_t>(result));
  EXPECT_DISASSEMBLY(
      "mov r2, 0x3f800000\n"
      "fmovsrw v1, r2\n"
      "fmovrsw r0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdPrePostIndex, assembler) {
  __ SetupDartSP();

  __ sub(CSP, CSP,
         Operand(2 * target::kWordSize));  // Must not access beyond CSP.

  __ LoadDImmediate(V1, 42.0);
  __ fstrd(V1, Address(SP, -1 * target::kWordSize, Address::PreIndex));
  __ fldrd(V0, Address(SP, 1 * target::kWordSize, Address::PostIndex));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdPrePostIndex, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "sub csp, csp, #0x10\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fstrd v1, [sp, #-8]!\n"
      "fldrd v0, [sp], #8 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FldrsFstrsPrePostIndex, assembler) {
  __ SetupDartSP();

  __ sub(CSP, CSP,
         Operand(2 * target::kWordSize));  // Must not access beyond CSP.

  __ LoadDImmediate(V1, 42.0);
  __ fcvtsd(V2, V1);
  __ fstrs(V2, Address(SP, -1 * target::kWordSize, Address::PreIndex));
  __ fldrs(V3, Address(SP, 1 * target::kWordSize, Address::PostIndex));
  __ fcvtds(V0, V3);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrsFstrsPrePostIndex, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "sub csp, csp, #0x10\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fcvtsd v2, v1\n"
      "fstrs v2, [sp, #-8]!\n"
      "fldrs v3, [sp], #8 !\n"
      "fcvtds v0, v3\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FldrqFstrqPrePostIndex, assembler) {
  __ SetupDartSP();

  __ sub(CSP, CSP,
         Operand(2 * target::kWordSize));  // Must not access beyond CSP.

  __ LoadDImmediate(V1, 21.0);
  __ LoadDImmediate(V2, 21.0);
  __ LoadImmediate(R1, 42);
  __ Push(R1);
  __ PushDouble(V1);
  __ PushDouble(V2);
  __ fldrq(V3, Address(SP, 2 * target::kWordSize, Address::PostIndex));
  __ Pop(R0);
  __ fstrq(V3, Address(SP, -2 * target::kWordSize, Address::PreIndex));
  __ PopDouble(V0);
  __ PopDouble(V1);
  __ faddd(V0, V0, V1);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrqFstrqPrePostIndex, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "sub csp, csp, #0x10\n"
      "fmovd v1, 21.000000\n"
      "fmovd v2, 21.000000\n"
      "movz r1, #0x2a\n"
      "str r1, [sp, #-8]!\n"
      "fstrd v1, [sp, #-8]!\n"
      "fstrd v2, [sp, #-8]!\n"
      "fldrq v3, [sp], #16 !\n"
      "ldr r0, [sp], #8 !\n"
      "fstrq v3, [sp, #-16]!\n"
      "fldrd v0, [sp], #8 !\n"
      "fldrd v1, [sp], #8 !\n"
      "faddd v0, v0, v1\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtzsxd, assembler) {
  __ LoadDImmediate(V0, 42.5);
  __ fcvtzsxd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtzsxd, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtzs r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtzswd, assembler) {
  __ LoadDImmediate(V0, -42.5);
  __ fcvtzswd(R0, V0);
  __ sxtw(R0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtzswd, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0xc045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtzsw r0, v0\n"
      "sxtw r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtzsxd_overflow, assembler) {
  __ LoadDImmediate(V0, 1e20);
  __ fcvtzsxd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtzsxd_overflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMaxInt64, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Fcvtzsxd_overflow_negative, assembler) {
  __ LoadDImmediate(V0, -1e20);
  __ fcvtzsxd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtzsxd_overflow_negative, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMinInt64, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x8c40\n"
      "movk tmp, #0x78b5 lsl 16\n"
      "movk tmp, #0xaf1d lsl 32\n"
      "movk tmp, #0xc415 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtzs r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtzswd_overflow, assembler) {
  __ LoadDImmediate(V0, 1e10);
  __ fcvtzswd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtzswd_overflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMaxInt32, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x2000 lsl 16\n"
      "movk tmp, #0xa05f lsl 32\n"
      "movk tmp, #0x4202 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtzsw r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtzswd_overflow_negative, assembler) {
  __ LoadDImmediate(V0, -1e10);
  __ fcvtzswd(R0, V0);
  __ sxtw(R0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtzswd_overflow_negative, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMinInt32, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x2000 lsl 16\n"
      "movk tmp, #0xa05f lsl 32\n"
      "movk tmp, #0xc202 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtzsw r0, v0\n"
      "sxtw r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtpsxd, assembler) {
  __ LoadDImmediate(V0, 42.5);
  __ fcvtpsxd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtpsxd, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(43, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtps r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtpswd, assembler) {
  __ LoadDImmediate(V0, -42.5);
  __ fcvtpswd(R0, V0);
  __ sxtw(R0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtpswd, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0xc045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtpsw r0, v0\n"
      "sxtw r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtpsxd_overflow, assembler) {
  __ LoadDImmediate(V0, 1e20);
  __ fcvtpsxd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtpsxd_overflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMaxInt64, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x8c40\n"
      "movk tmp, #0x78b5 lsl 16\n"
      "movk tmp, #0xaf1d lsl 32\n"
      "movk tmp, #0x4415 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtps r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtpsxd_overflow_negative, assembler) {
  __ LoadDImmediate(V0, -1e20);
  __ fcvtpsxd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtpsxd_overflow_negative, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMinInt64, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x8c40\n"
      "movk tmp, #0x78b5 lsl 16\n"
      "movk tmp, #0xaf1d lsl 32\n"
      "movk tmp, #0xc415 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtps r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtpswd_overflow, assembler) {
  __ LoadDImmediate(V0, 1e10);
  __ fcvtpswd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtpswd_overflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMaxInt32, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x2000 lsl 16\n"
      "movk tmp, #0xa05f lsl 32\n"
      "movk tmp, #0x4202 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtpsw r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtpswd_overflow_negative, assembler) {
  __ LoadDImmediate(V0, -1e10);
  __ fcvtpswd(R0, V0);
  __ sxtw(R0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtpswd_overflow_negative, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMinInt32, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x2000 lsl 16\n"
      "movk tmp, #0xa05f lsl 32\n"
      "movk tmp, #0xc202 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtpsw r0, v0\n"
      "sxtw r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtmsxd, assembler) {
  __ LoadDImmediate(V0, 42.5);
  __ fcvtmsxd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtmsxd, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtms r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtmswd, assembler) {
  __ LoadDImmediate(V0, -42.5);
  __ fcvtmswd(R0, V0);
  __ sxtw(R0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtmswd, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-43, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0xc045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtmsw r0, v0\n"
      "sxtw r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtmsxd_overflow, assembler) {
  __ LoadDImmediate(V0, 1e20);
  __ fcvtmsxd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtmsxd_overflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMaxInt64, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x8c40\n"
      "movk tmp, #0x78b5 lsl 16\n"
      "movk tmp, #0xaf1d lsl 32\n"
      "movk tmp, #0x4415 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtms r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtmsxd_overflow_negative, assembler) {
  __ LoadDImmediate(V0, -1e20);
  __ fcvtmsxd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtmsxd_overflow_negative, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMinInt64, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x8c40\n"
      "movk tmp, #0x78b5 lsl 16\n"
      "movk tmp, #0xaf1d lsl 32\n"
      "movk tmp, #0xc415 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtms r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtmswd_overflow, assembler) {
  __ LoadDImmediate(V0, 1e10);
  __ fcvtmswd(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtmswd_overflow, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMaxInt32, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x2000 lsl 16\n"
      "movk tmp, #0xa05f lsl 32\n"
      "movk tmp, #0x4202 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtmsw r0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fcvtmswd_overflow_negative, assembler) {
  __ LoadDImmediate(V0, -1e10);
  __ fcvtmswd(R0, V0);
  __ sxtw(R0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtmswd_overflow_negative, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMinInt32, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x2000 lsl 16\n"
      "movk tmp, #0xa05f lsl 32\n"
      "movk tmp, #0xc202 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtmsw r0, v0\n"
      "sxtw r0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Scvtfdx, assembler) {
  __ LoadImmediate(R0, 42);
  __ scvtfdx(V0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Scvtfdx, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "scvtfd v0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Scvtfdw, assembler) {
  // Fill upper 32-bits with garbage.
  __ LoadImmediate(R0, 0x111111110000002A);
  __ scvtfdw(V0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Scvtfdw, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movk r0, #0x1111 lsl 32\n"
      "movk r0, #0x1111 lsl 48\n"
      "scvtfdw v0, r0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FabsdPos, assembler) {
  __ LoadDImmediate(V1, 42.0);
  __ fabsd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(FabsdPos, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fabsd v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FabsdNeg, assembler) {
  __ LoadDImmediate(V1, -42.0);
  __ fabsd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(FabsdNeg, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0xc045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fabsd v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FnegdPos, assembler) {
  __ LoadDImmediate(V1, 42.0);
  __ fnegd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(FnegdPos, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(-42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fnegd v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FnegdNeg, assembler) {
  __ LoadDImmediate(V1, -42.0);
  __ fnegd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(FnegdNeg, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0xc045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fnegd v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fsqrtd, assembler) {
  __ LoadDImmediate(V1, 64.0);
  __ fsqrtd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fsqrtd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(8.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4050 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fsqrtd v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fmuld, assembler) {
  __ LoadDImmediate(V1, 84.0);
  __ LoadDImmediate(V2, 0.5);
  __ fmuld(V0, V1, V2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fmuld, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4055 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fmovd v2, 0.500000\n"
      "fmuld v0, v1, v2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fdivd, assembler) {
  __ LoadDImmediate(V1, 84.0);
  __ LoadDImmediate(V2, 2.0);
  __ fdivd(V0, V1, V2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fdivd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4055 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fmovd v2, 2.000000\n"
      "fdivd v0, v1, v2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Faddd, assembler) {
  __ LoadDImmediate(V1, 41.5);
  __ LoadDImmediate(V2, 0.5);
  __ faddd(V0, V1, V2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Faddd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0xc000 lsl 32\n"
      "movk tmp, #0x4044 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fmovd v2, 0.500000\n"
      "faddd v0, v1, v2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Fsubd, assembler) {
  __ LoadDImmediate(V1, 42.5);
  __ LoadDImmediate(V2, 0.5);
  __ fsubd(V0, V1, V2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fsubd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fmovd v2, 0.500000\n"
      "fsubd v0, v1, v2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdHeapTag, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 43.0);
  __ LoadDImmediate(V1, 42.0);
  __ AddImmediate(SP, SP, -1 * target::kWordSize);
  __ add(R2, SP, Operand(1));
  __ fstrd(V1, Address(R2, -1));
  __ fldrd(V0, Address(R2, -1));
  __ AddImmediate(SP, 1 * target::kWordSize);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdHeapTag, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "sub sp, sp, #0x8\n"
      "add r2, sp, #0x1\n"
      "fstrd v1, [r2, #-1]\n"
      "fldrd v0, [r2, #-1]\n"
      "add sp, sp, #0x8\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdLargeIndex, assembler) {
  __ SetupDartSP();

  __ sub(CSP, CSP,
         Operand(32 * target::kWordSize));  // Must not access beyond CSP.

  __ LoadDImmediate(V0, 43.0);
  __ LoadDImmediate(V1, 42.0);
  // Largest negative offset that can fit in the signed 9-bit immediate field.
  __ fstrd(V1, Address(SP, -32 * target::kWordSize, Address::PreIndex));
  // Largest positive kWordSize aligned offset that we can fit.
  __ fldrd(V0, Address(SP, 31 * target::kWordSize, Address::PostIndex));
  // Correction.
  __ add(SP, SP, Operand(target::kWordSize));  // Restore SP.
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdLargeIndex, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "sub csp, csp, #0x100\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fstrd v1, [sp, #-256]!\n"
      "fldrd v0, [sp], #248 !\n"
      "add sp, sp, #0x8\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdLargeOffset, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 43.0);
  __ LoadDImmediate(V1, 42.0);
  __ sub(SP, SP, Operand(512 * target::kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ fstrd(V1, Address(SP, 512 * target::kWordSize));
  __ add(SP, SP, Operand(512 * target::kWordSize));
  __ fldrd(V0, Address(SP));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdLargeOffset, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "sub sp, sp, #0x1000\n"
      "and csp, sp, 0xfffffffffffffff0\n"
      "fstrd v1, [sp, #4096]\n"
      "add sp, sp, #0x1000\n"
      "fldrd v0, [sp]\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdExtReg, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 43.0);
  __ LoadDImmediate(V1, 42.0);
  __ movz(R2, Immediate(0xfff8), 0);
  __ movk(R2, Immediate(0xffff), 1);  // R2 <- -8 (int32_t).
  // This should sign extend R2, and add to SP to get address,
  // i.e. SP - kWordSize.
  __ fstrd(V1, Address(SP, R2, SXTW));
  __ sub(SP, SP, Operand(target::kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ fldrd(V0, Address(SP));
  __ add(SP, SP, Operand(target::kWordSize));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdExtReg, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "movz r2, #0xfff8\n"
      "movk r2, #0xffff lsl 16\n"
      "fstrd v1, [sp, r2 sxtw]\n"
      "sub sp, sp, #0x8\n"
      "and csp, sp, 0xfffffffffffffff0\n"
      "fldrd v0, [sp]\n"
      "add sp, sp, #0x8\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdScaledReg, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 43.0);
  __ LoadDImmediate(V1, 42.0);
  __ movz(R2, Immediate(10), 0);
  __ sub(SP, SP, Operand(10 * target::kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  // Store V1 into SP + R2 * kWordSize.
  __ fstrd(V1, Address(SP, R2, UXTX, Address::Scaled));
  __ fldrd(V0, Address(SP, R2, UXTX, Address::Scaled));
  __ add(SP, SP, Operand(10 * target::kWordSize));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdScaledReg, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "movz r2, #0xa\n"
      "sub sp, sp, #0x50\n"
      "and csp, sp, 0xfffffffffffffff0\n"
      "fstrd v1, [sp, r2 uxtx scaled]\n"
      "fldrd v0, [sp, r2 uxtx scaled]\n"
      "add sp, sp, #0x50\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(VinswVmovrs, assembler) {
  __ LoadImmediate(R0, 42);
  __ LoadImmediate(R1, 43);
  __ LoadImmediate(R2, 44);
  __ LoadImmediate(R3, 45);

  __ vinsw(V0, 0, R0);
  __ vinsw(V0, 1, R1);
  __ vinsw(V0, 2, R2);
  __ vinsw(V0, 3, R3);

  __ vmovrs(R4, V0, 0);
  __ vmovrs(R5, V0, 1);
  __ vmovrs(R6, V0, 2);
  __ vmovrs(R7, V0, 3);

  __ add(R0, R4, Operand(R5));
  __ add(R0, R0, Operand(R6));
  __ add(R0, R0, Operand(R7));
  __ ret();
}

ASSEMBLER_TEST_RUN(VinswVmovrs, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(174, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0x2b\n"
      "movz r2, #0x2c\n"
      "movz r3, #0x2d\n"
      "vinss v0[0], r0\n"
      "vinss v0[1], r1\n"
      "vinss v0[2], r2\n"
      "vinss v0[3], r3\n"
      "vmovrs r4, v0[0]\n"
      "vmovrs r5, v0[1]\n"
      "vmovrs r6, v0[2]\n"
      "vmovrs r7, v0[3]\n"
      "add r0, r4, r5\n"
      "add r0, r0, r6\n"
      "add r0, r0, r7\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(VinsxVmovrd, assembler) {
  __ LoadImmediate(R0, 42);
  __ LoadImmediate(R1, 43);

  __ vinsx(V0, 0, R0);
  __ vinsx(V0, 1, R1);

  __ vmovrd(R2, V0, 0);
  __ vmovrd(R3, V0, 1);

  __ add(R0, R2, Operand(R3));
  __ ret();
}

ASSEMBLER_TEST_RUN(VinsxVmovrd, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(85, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r0, #0x2a\n"
      "movz r1, #0x2b\n"
      "vinsd v0[0], r0\n"
      "vinsd v0[1], r1\n"
      "vmovrd r2, v0[0]\n"
      "vmovrd r3, v0[1]\n"
      "add r0, r2, r3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vnot, assembler) {
  __ LoadImmediate(R0, 0xfffffffe);
  __ LoadImmediate(R1, 0xffffffff);
  __ vinsw(V1, 0, R1);
  __ vinsw(V1, 1, R0);
  __ vinsw(V1, 2, R1);
  __ vinsw(V1, 3, R0);

  __ vnot(V0, V1);

  __ vmovrs(R2, V0, 0);
  __ vmovrs(R3, V0, 1);
  __ vmovrs(R4, V0, 2);
  __ vmovrs(R5, V0, 3);
  __ add(R0, R2, Operand(R3));
  __ add(R0, R0, Operand(R4));
  __ add(R0, R0, Operand(R5));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vnot, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov r0, 0xfffffffe\n"
      "mov r1, 0xffffffff\n"
      "vinss v1[0], r1\n"
      "vinss v1[1], r0\n"
      "vinss v1[2], r1\n"
      "vinss v1[3], r0\n"
      "vnot v0, v1\n"
      "vmovrs r2, v0[0]\n"
      "vmovrs r3, v0[1]\n"
      "vmovrs r4, v0[2]\n"
      "vmovrs r5, v0[3]\n"
      "add r0, r2, r3\n"
      "add r0, r0, r4\n"
      "add r0, r0, r5\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vabss, assembler) {
  __ LoadDImmediate(V1, 21.0);
  __ LoadDImmediate(V2, -21.0);

  __ fcvtsd(V1, V1);
  __ fcvtsd(V2, V2);

  __ veor(V3, V3, V3);
  __ vinss(V3, 1, V1, 0);
  __ vinss(V3, 3, V2, 0);

  __ vabss(V4, V3);

  __ vinss(V5, 0, V4, 1);
  __ vinss(V6, 0, V4, 3);

  __ fcvtds(V5, V5);
  __ fcvtds(V6, V6);

  __ faddd(V0, V5, V6);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vabss, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v1, 21.000000\n"
      "fmovd v2, -21.000000\n"
      "fcvtsd v1, v1\n"
      "fcvtsd v2, v2\n"
      "veor v3, v3, v3\n"
      "vinss v3[1], v1[0]\n"
      "vinss v3[3], v2[0]\n"
      "vabss v4, v3\n"
      "vinss v5[0], v4[1]\n"
      "vinss v6[0], v4[3]\n"
      "fcvtds v5, v5\n"
      "fcvtds v6, v6\n"
      "faddd v0, v5, v6\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vabsd, assembler) {
  __ LoadDImmediate(V1, 21.0);
  __ LoadDImmediate(V2, -21.0);

  __ vinsd(V3, 0, V1, 0);
  __ vinsd(V3, 1, V2, 0);

  __ vabsd(V4, V3);

  __ vinsd(V5, 0, V4, 0);
  __ vinsd(V6, 0, V4, 1);

  __ faddd(V0, V5, V6);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vabsd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v1, 21.000000\n"
      "fmovd v2, -21.000000\n"
      "vinsd v3[0], v1[0]\n"
      "vinsd v3[1], v2[0]\n"
      "vabsd v4, v3\n"
      "vinsd v5[0], v4[0]\n"
      "vinsd v6[0], v4[1]\n"
      "faddd v0, v5, v6\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vnegs, assembler) {
  __ LoadDImmediate(V1, 42.0);
  __ LoadDImmediate(V2, -84.0);

  __ fcvtsd(V1, V1);
  __ fcvtsd(V2, V2);

  __ veor(V3, V3, V3);
  __ vinss(V3, 1, V1, 0);
  __ vinss(V3, 3, V2, 0);

  __ vnegs(V4, V3);

  __ vinss(V5, 0, V4, 1);
  __ vinss(V6, 0, V4, 3);

  __ fcvtds(V5, V5);
  __ fcvtds(V6, V6);
  __ faddd(V0, V5, V6);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vnegs, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "movz tmp, #0xc055 lsl 48\n"
      "fmovdr v2, tmp\n"
      "fcvtsd v1, v1\n"
      "fcvtsd v2, v2\n"
      "veor v3, v3, v3\n"
      "vinss v3[1], v1[0]\n"
      "vinss v3[3], v2[0]\n"
      "vnegs v4, v3\n"
      "vinss v5[0], v4[1]\n"
      "vinss v6[0], v4[3]\n"
      "fcvtds v5, v5\n"
      "fcvtds v6, v6\n"
      "faddd v0, v5, v6\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vnegd, assembler) {
  __ LoadDImmediate(V1, 42.0);
  __ LoadDImmediate(V2, -84.0);

  __ vinsd(V3, 0, V1, 0);
  __ vinsd(V3, 1, V2, 0);

  __ vnegd(V4, V3);

  __ vinsd(V5, 0, V4, 0);
  __ vinsd(V6, 0, V4, 1);

  __ faddd(V0, V5, V6);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vnegd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      ""
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "movz tmp, #0xc055 lsl 48\n"
      "fmovdr v2, tmp\n"
      "vinsd v3[0], v1[0]\n"
      "vinsd v3[1], v2[0]\n"
      "vnegd v4, v3\n"
      "vinsd v5[0], v4[0]\n"
      "vinsd v6[0], v4[1]\n"
      "faddd v0, v5, v6\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vadds, assembler) {
  __ LoadDImmediate(V0, 0.0);
  __ LoadDImmediate(V1, 1.0);
  __ LoadDImmediate(V2, 2.0);
  __ LoadDImmediate(V3, 3.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);
  __ fcvtsd(V2, V2);
  __ fcvtsd(V3, V3);

  __ vinss(V4, 0, V0, 0);
  __ vinss(V4, 1, V1, 0);
  __ vinss(V4, 2, V2, 0);
  __ vinss(V4, 3, V3, 0);

  __ vadds(V5, V4, V4);

  __ vinss(V0, 0, V5, 0);
  __ vinss(V1, 0, V5, 1);
  __ vinss(V2, 0, V5, 2);
  __ vinss(V3, 0, V5, 3);

  __ fcvtds(V0, V0);
  __ fcvtds(V1, V1);
  __ fcvtds(V2, V2);
  __ fcvtds(V3, V3);

  __ faddd(V0, V0, V1);
  __ faddd(V0, V0, V2);
  __ faddd(V0, V0, V3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vadds, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(12.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "veor v0, v0, v0\n"
      "fmovd v1, 1.000000\n"
      "fmovd v2, 2.000000\n"
      "fmovd v3, 3.000000\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "fcvtsd v2, v2\n"
      "fcvtsd v3, v3\n"
      "vinss v4[0], v0[0]\n"
      "vinss v4[1], v1[0]\n"
      "vinss v4[2], v2[0]\n"
      "vinss v4[3], v3[0]\n"
      "vadds v5, v4, v4\n"
      "vinss v0[0], v5[0]\n"
      "vinss v1[0], v5[1]\n"
      "vinss v2[0], v5[2]\n"
      "vinss v3[0], v5[3]\n"
      "fcvtds v0, v0\n"
      "fcvtds v1, v1\n"
      "fcvtds v2, v2\n"
      "fcvtds v3, v3\n"
      "faddd v0, v0, v1\n"
      "faddd v0, v0, v2\n"
      "faddd v0, v0, v3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vsubs, assembler) {
  __ LoadDImmediate(V0, 0.0);
  __ LoadDImmediate(V1, 1.0);
  __ LoadDImmediate(V2, 2.0);
  __ LoadDImmediate(V3, 3.0);
  __ LoadDImmediate(V5, 0.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);
  __ fcvtsd(V2, V2);
  __ fcvtsd(V3, V3);

  __ vinss(V4, 0, V0, 0);
  __ vinss(V4, 1, V1, 0);
  __ vinss(V4, 2, V2, 0);
  __ vinss(V4, 3, V3, 0);

  __ vsubs(V5, V5, V4);

  __ vinss(V0, 0, V5, 0);
  __ vinss(V1, 0, V5, 1);
  __ vinss(V2, 0, V5, 2);
  __ vinss(V3, 0, V5, 3);

  __ fcvtds(V0, V0);
  __ fcvtds(V1, V1);
  __ fcvtds(V2, V2);
  __ fcvtds(V3, V3);

  __ faddd(V0, V0, V1);
  __ faddd(V0, V0, V2);
  __ faddd(V0, V0, V3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vsubs, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(-6.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "veor v0, v0, v0\n"
      "fmovd v1, 1.000000\n"
      "fmovd v2, 2.000000\n"
      "fmovd v3, 3.000000\n"
      "veor v5, v5, v5\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "fcvtsd v2, v2\n"
      "fcvtsd v3, v3\n"
      "vinss v4[0], v0[0]\n"
      "vinss v4[1], v1[0]\n"
      "vinss v4[2], v2[0]\n"
      "vinss v4[3], v3[0]\n"
      "vsubs v5, v5, v4\n"
      "vinss v0[0], v5[0]\n"
      "vinss v1[0], v5[1]\n"
      "vinss v2[0], v5[2]\n"
      "vinss v3[0], v5[3]\n"
      "fcvtds v0, v0\n"
      "fcvtds v1, v1\n"
      "fcvtds v2, v2\n"
      "fcvtds v3, v3\n"
      "faddd v0, v0, v1\n"
      "faddd v0, v0, v2\n"
      "faddd v0, v0, v3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vmuls, assembler) {
  __ LoadDImmediate(V0, 0.0);
  __ LoadDImmediate(V1, 1.0);
  __ LoadDImmediate(V2, 2.0);
  __ LoadDImmediate(V3, 3.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);
  __ fcvtsd(V2, V2);
  __ fcvtsd(V3, V3);

  __ vinss(V4, 0, V0, 0);
  __ vinss(V4, 1, V1, 0);
  __ vinss(V4, 2, V2, 0);
  __ vinss(V4, 3, V3, 0);

  __ vmuls(V5, V4, V4);

  __ vinss(V0, 0, V5, 0);
  __ vinss(V1, 0, V5, 1);
  __ vinss(V2, 0, V5, 2);
  __ vinss(V3, 0, V5, 3);

  __ fcvtds(V0, V0);
  __ fcvtds(V1, V1);
  __ fcvtds(V2, V2);
  __ fcvtds(V3, V3);

  __ faddd(V0, V0, V1);
  __ faddd(V0, V0, V2);
  __ faddd(V0, V0, V3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmuls, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(14.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "veor v0, v0, v0\n"
      "fmovd v1, 1.000000\n"
      "fmovd v2, 2.000000\n"
      "fmovd v3, 3.000000\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "fcvtsd v2, v2\n"
      "fcvtsd v3, v3\n"
      "vinss v4[0], v0[0]\n"
      "vinss v4[1], v1[0]\n"
      "vinss v4[2], v2[0]\n"
      "vinss v4[3], v3[0]\n"
      "vmuls v5, v4, v4\n"
      "vinss v0[0], v5[0]\n"
      "vinss v1[0], v5[1]\n"
      "vinss v2[0], v5[2]\n"
      "vinss v3[0], v5[3]\n"
      "fcvtds v0, v0\n"
      "fcvtds v1, v1\n"
      "fcvtds v2, v2\n"
      "fcvtds v3, v3\n"
      "faddd v0, v0, v1\n"
      "faddd v0, v0, v2\n"
      "faddd v0, v0, v3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vdivs, assembler) {
  __ LoadDImmediate(V0, 0.0);
  __ LoadDImmediate(V1, 1.0);
  __ LoadDImmediate(V2, 2.0);
  __ LoadDImmediate(V3, 3.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);
  __ fcvtsd(V2, V2);
  __ fcvtsd(V3, V3);

  __ vinss(V4, 0, V0, 0);
  __ vinss(V4, 1, V1, 0);
  __ vinss(V4, 2, V2, 0);
  __ vinss(V4, 3, V3, 0);

  __ vdivs(V5, V4, V4);

  __ vinss(V0, 0, V5, 0);
  __ vinss(V1, 0, V5, 1);
  __ vinss(V2, 0, V5, 2);
  __ vinss(V3, 0, V5, 3);

  __ fcvtds(V0, V0);
  __ fcvtds(V1, V1);
  __ fcvtds(V2, V2);
  __ fcvtds(V3, V3);

  __ faddd(V0, V1, V1);
  __ faddd(V0, V0, V2);
  __ faddd(V0, V0, V3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vdivs, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(4.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "veor v0, v0, v0\n"
      "fmovd v1, 1.000000\n"
      "fmovd v2, 2.000000\n"
      "fmovd v3, 3.000000\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "fcvtsd v2, v2\n"
      "fcvtsd v3, v3\n"
      "vinss v4[0], v0[0]\n"
      "vinss v4[1], v1[0]\n"
      "vinss v4[2], v2[0]\n"
      "vinss v4[3], v3[0]\n"
      "vdivs v5, v4, v4\n"
      "vinss v0[0], v5[0]\n"
      "vinss v1[0], v5[1]\n"
      "vinss v2[0], v5[2]\n"
      "vinss v3[0], v5[3]\n"
      "fcvtds v0, v0\n"
      "fcvtds v1, v1\n"
      "fcvtds v2, v2\n"
      "fcvtds v3, v3\n"
      "faddd v0, v1, v1\n"
      "faddd v0, v0, v2\n"
      "faddd v0, v0, v3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vaddd, assembler) {
  __ LoadDImmediate(V0, 2.0);
  __ LoadDImmediate(V1, 3.0);

  __ vinsd(V4, 0, V0, 0);
  __ vinsd(V4, 1, V1, 0);

  __ vaddd(V5, V4, V4);

  __ vinsd(V0, 0, V5, 0);
  __ vinsd(V1, 0, V5, 1);

  __ faddd(V0, V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vaddd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(10.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      ""
      "fmovd v0, 2.000000\n"
      "fmovd v1, 3.000000\n"
      "vinsd v4[0], v0[0]\n"
      "vinsd v4[1], v1[0]\n"
      "vaddd v5, v4, v4\n"
      "vinsd v0[0], v5[0]\n"
      "vinsd v1[0], v5[1]\n"
      "faddd v0, v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vsubd, assembler) {
  __ LoadDImmediate(V0, 2.0);
  __ LoadDImmediate(V1, 3.0);
  __ LoadDImmediate(V5, 0.0);

  __ vinsd(V4, 0, V0, 0);
  __ vinsd(V4, 1, V1, 0);

  __ vsubd(V5, V5, V4);

  __ vinsd(V0, 0, V5, 0);
  __ vinsd(V1, 0, V5, 1);

  __ faddd(V0, V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vsubd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(-5.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v0, 2.000000\n"
      "fmovd v1, 3.000000\n"
      "veor v5, v5, v5\n"
      "vinsd v4[0], v0[0]\n"
      "vinsd v4[1], v1[0]\n"
      "vsubd v5, v5, v4\n"
      "vinsd v0[0], v5[0]\n"
      "vinsd v1[0], v5[1]\n"
      "faddd v0, v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vmuld, assembler) {
  __ LoadDImmediate(V0, 2.0);
  __ LoadDImmediate(V1, 3.0);

  __ vinsd(V4, 0, V0, 0);
  __ vinsd(V4, 1, V1, 0);

  __ vmuld(V5, V4, V4);

  __ vinsd(V0, 0, V5, 0);
  __ vinsd(V1, 0, V5, 1);

  __ faddd(V0, V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmuld, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(13.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      ""
      "fmovd v0, 2.000000\n"
      "fmovd v1, 3.000000\n"
      "vinsd v4[0], v0[0]\n"
      "vinsd v4[1], v1[0]\n"
      "vmuld v5, v4, v4\n"
      "vinsd v0[0], v5[0]\n"
      "vinsd v1[0], v5[1]\n"
      "faddd v0, v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vdivd, assembler) {
  __ LoadDImmediate(V0, 2.0);
  __ LoadDImmediate(V1, 3.0);

  __ vinsd(V4, 0, V0, 0);
  __ vinsd(V4, 1, V1, 0);

  __ vdivd(V5, V4, V4);

  __ vinsd(V0, 0, V5, 0);
  __ vinsd(V1, 0, V5, 1);

  __ faddd(V0, V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vdivd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(2.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v0, 2.000000\n"
      "fmovd v1, 3.000000\n"
      "vinsd v4[0], v0[0]\n"
      "vinsd v4[1], v1[0]\n"
      "vdivd v5, v4, v4\n"
      "vinsd v0[0], v5[0]\n"
      "vinsd v1[0], v5[1]\n"
      "faddd v0, v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vdupd, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 21.0);
  __ vdupd(V1, V0, 0);

  const int dword_bytes = 1 << Log2OperandSizeBytes(kDWord);
  const int qword_bytes = 1 << Log2OperandSizeBytes(kQWord);

  __ sub(CSP, CSP, Operand(qword_bytes));  // Must not access beyond CSP.

  __ fstrq(V1, Address(SP, -1 * qword_bytes, Address::PreIndex));

  __ fldrd(V2, Address(SP, 1 * dword_bytes, Address::PostIndex));
  __ fldrd(V3, Address(SP, 1 * dword_bytes, Address::PostIndex));

  __ faddd(V0, V2, V3);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(Vdupd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      ""
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "fmovd v0, 21.000000\n"
      "vdupd v1, v0[0]\n"
      "sub csp, csp, #0x10\n"
      "fstrq v1, [sp, #-16]!\n"
      "fldrd v2, [sp], #8 !\n"
      "fldrd v3, [sp], #8 !\n"
      "faddd v0, v2, v3\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vdups, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 21.0);
  __ fcvtsd(V0, V0);
  __ vdups(V1, V0, 0);

  const int sword_bytes = 1 << Log2OperandSizeBytes(kSWord);
  const int qword_bytes = 1 << Log2OperandSizeBytes(kQWord);

  __ sub(CSP, CSP, Operand(qword_bytes));  // Must not access beyond CSP.

  __ fstrq(V1, Address(SP, -1 * qword_bytes, Address::PreIndex));

  __ fldrs(V3, Address(SP, 1 * sword_bytes, Address::PostIndex));
  __ fldrs(V2, Address(SP, 1 * sword_bytes, Address::PostIndex));
  __ fldrs(V1, Address(SP, 1 * sword_bytes, Address::PostIndex));
  __ fldrs(V0, Address(SP, 1 * sword_bytes, Address::PostIndex));

  __ fcvtds(V0, V0);
  __ fcvtds(V1, V1);
  __ fcvtds(V2, V2);
  __ fcvtds(V3, V3);

  __ faddd(V0, V1, V1);
  __ faddd(V0, V0, V2);
  __ faddd(V0, V0, V3);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(Vdups, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(84.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      ""
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "fmovd v0, 21.000000\n"
      "fcvtsd v0, v0\n"
      "vdups v1, v0[0]\n"
      "sub csp, csp, #0x10\n"
      "fstrq v1, [sp, #-16]!\n"
      "fldrs v3, [sp], #4 !\n"
      "fldrs v2, [sp], #4 !\n"
      "fldrs v1, [sp], #4 !\n"
      "fldrs v0, [sp], #4 !\n"
      "fcvtds v0, v0\n"
      "fcvtds v1, v1\n"
      "fcvtds v2, v2\n"
      "fcvtds v3, v3\n"
      "faddd v0, v1, v1\n"
      "faddd v0, v0, v2\n"
      "faddd v0, v0, v3\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vinsd, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V5, 42.0);
  __ vinsd(V1, 1, V5, 0);  // V1[1] <- V0[0].

  const int dword_bytes = 1 << Log2OperandSizeBytes(kDWord);
  const int qword_bytes = 1 << Log2OperandSizeBytes(kQWord);

  __ sub(CSP, CSP, Operand(qword_bytes));  // Must not access beyond CSP.

  __ fstrq(V1, Address(SP, -1 * qword_bytes, Address::PreIndex));

  __ fldrd(V2, Address(SP, 1 * dword_bytes, Address::PostIndex));
  __ fldrd(V3, Address(SP, 1 * dword_bytes, Address::PostIndex));

  __ fmovdd(V0, V3);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(Vinsd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      ""
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v5, tmp\n"
      "vinsd v1[1], v5[0]\n"
      "sub csp, csp, #0x10\n"
      "fstrq v1, [sp, #-16]!\n"
      "fldrd v2, [sp], #8 !\n"
      "fldrd v3, [sp], #8 !\n"
      "fmovdd v0, v3\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vinss, assembler) {
  __ SetupDartSP();
  // Set V1 parts 1 and 3 to 21.0.
  __ LoadDImmediate(V0, 21.0);
  __ fcvtsd(V0, V0);
  __ vinss(V1, 3, V0, 0);
  __ vinss(V1, 1, V0, 0);

  // Set V1 parts 0 and 2 to 0.0.
  __ LoadDImmediate(V0, 0.0);
  __ fcvtsd(V0, V0);
  __ vinss(V1, 2, V0, 0);
  __ vinss(V1, 0, V0, 0);

  const int sword_bytes = 1 << Log2OperandSizeBytes(kSWord);
  const int qword_bytes = 1 << Log2OperandSizeBytes(kQWord);

  __ sub(CSP, CSP, Operand(qword_bytes));  // Must not access beyond CSP.

  __ fstrq(V1, Address(SP, -1 * qword_bytes, Address::PreIndex));

  __ fldrs(V3, Address(SP, 1 * sword_bytes, Address::PostIndex));
  __ fldrs(V2, Address(SP, 1 * sword_bytes, Address::PostIndex));
  __ fldrs(V1, Address(SP, 1 * sword_bytes, Address::PostIndex));
  __ fldrs(V0, Address(SP, 1 * sword_bytes, Address::PostIndex));

  __ fcvtds(V0, V0);
  __ fcvtds(V1, V1);
  __ fcvtds(V2, V2);
  __ fcvtds(V3, V3);

  __ faddd(V0, V0, V1);
  __ faddd(V0, V0, V2);
  __ faddd(V0, V0, V3);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(Vinss, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "fmovd v0, 21.000000\n"
      "fcvtsd v0, v0\n"
      "vinss v1[3], v0[0]\n"
      "vinss v1[1], v0[0]\n"
      "veor v0, v0, v0\n"
      "fcvtsd v0, v0\n"
      "vinss v1[2], v0[0]\n"
      "vinss v1[0], v0[0]\n"
      "sub csp, csp, #0x10\n"
      "fstrq v1, [sp, #-16]!\n"
      "fldrs v3, [sp], #4 !\n"
      "fldrs v2, [sp], #4 !\n"
      "fldrs v1, [sp], #4 !\n"
      "fldrs v0, [sp], #4 !\n"
      "fcvtds v0, v0\n"
      "fcvtds v1, v1\n"
      "fcvtds v2, v2\n"
      "fcvtds v3, v3\n"
      "faddd v0, v0, v1\n"
      "faddd v0, v0, v2\n"
      "faddd v0, v0, v3\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vand, assembler) {
  __ LoadDImmediate(V1, 21.0);
  __ LoadImmediate(R0, 0xffffffff);

  // V0 <- (0, 0xffffffff, 0, 0xffffffff)
  __ fmovdr(V0, R0);
  __ vinss(V0, 2, V0, 0);

  // V1 <- (21.0, 21.0, 21.0, 21.0)
  __ fcvtsd(V1, V1);
  __ vdups(V1, V1, 0);

  __ vand(V2, V1, V0);

  __ vinss(V3, 0, V2, 0);
  __ vinss(V4, 0, V2, 1);
  __ vinss(V5, 0, V2, 2);
  __ vinss(V6, 0, V2, 3);

  __ fcvtds(V3, V3);
  __ fcvtds(V4, V4);
  __ fcvtds(V5, V5);
  __ fcvtds(V6, V6);

  __ vaddd(V0, V3, V4);
  __ vaddd(V0, V0, V5);
  __ vaddd(V0, V0, V6);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vand, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v1, 21.000000\n"
      "mov r0, 0xffffffff\n"
      "fmovdr v0, r0\n"
      "vinss v0[2], v0[0]\n"
      "fcvtsd v1, v1\n"
      "vdups v1, v1[0]\n"
      "vand v2, v1, v0\n"
      "vinss v3[0], v2[0]\n"
      "vinss v4[0], v2[1]\n"
      "vinss v5[0], v2[2]\n"
      "vinss v6[0], v2[3]\n"
      "fcvtds v3, v3\n"
      "fcvtds v4, v4\n"
      "fcvtds v5, v5\n"
      "fcvtds v6, v6\n"
      "vaddd v0, v3, v4\n"
      "vaddd v0, v0, v5\n"
      "vaddd v0, v0, v6\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vorr, assembler) {
  __ LoadDImmediate(V1, 10.5);
  __ fcvtsd(V1, V1);

  // V0 <- (0, 10.5, 0, 10.5)
  __ fmovdd(V0, V1);
  __ vinss(V0, 2, V0, 0);

  // V1 <- (10.5, 0, 10.5, 0)
  __ veor(V1, V1, V1);
  __ vinss(V1, 1, V0, 0);
  __ vinss(V1, 3, V0, 0);

  __ vorr(V2, V1, V0);

  __ vinss(V3, 0, V2, 0);
  __ vinss(V4, 0, V2, 1);
  __ vinss(V5, 0, V2, 2);
  __ vinss(V6, 0, V2, 3);

  __ fcvtds(V3, V3);
  __ fcvtds(V4, V4);
  __ fcvtds(V5, V5);
  __ fcvtds(V6, V6);

  __ vaddd(V0, V3, V4);
  __ vaddd(V0, V0, V5);
  __ vaddd(V0, V0, V6);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vorr, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v1, 10.500000\n"
      "fcvtsd v1, v1\n"
      "fmovdd v0, v1\n"
      "vinss v0[2], v0[0]\n"
      "veor v1, v1, v1\n"
      "vinss v1[1], v0[0]\n"
      "vinss v1[3], v0[0]\n"
      "vorr v2, v1, v0\n"
      "vinss v3[0], v2[0]\n"
      "vinss v4[0], v2[1]\n"
      "vinss v5[0], v2[2]\n"
      "vinss v6[0], v2[3]\n"
      "fcvtds v3, v3\n"
      "fcvtds v4, v4\n"
      "fcvtds v5, v5\n"
      "fcvtds v6, v6\n"
      "vaddd v0, v3, v4\n"
      "vaddd v0, v0, v5\n"
      "vaddd v0, v0, v6\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Veor, assembler) {
  __ LoadImmediate(R1, 0xffffffff);
  __ LoadImmediate(R2, ~21);

  __ vinsw(V1, 0, R1);
  __ vinsw(V1, 1, R2);
  __ vinsw(V1, 2, R1);
  __ vinsw(V1, 3, R2);

  __ vinsw(V2, 0, R1);
  __ vinsw(V2, 1, R1);
  __ vinsw(V2, 2, R1);
  __ vinsw(V2, 3, R1);

  __ veor(V0, V1, V2);

  __ vmovrs(R3, V0, 0);
  __ vmovrs(R4, V0, 1);
  __ vmovrs(R5, V0, 2);
  __ vmovrs(R6, V0, 3);

  __ add(R0, R3, Operand(R4));
  __ add(R0, R0, Operand(R5));
  __ add(R0, R0, Operand(R6));
  __ ret();
}

ASSEMBLER_TEST_RUN(Veor, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "mov r1, 0xffffffff\n"
      "movn r2, #0x15\n"
      "vinss v1[0], r1\n"
      "vinss v1[1], r2\n"
      "vinss v1[2], r1\n"
      "vinss v1[3], r2\n"
      "vinss v2[0], r1\n"
      "vinss v2[1], r1\n"
      "vinss v2[2], r1\n"
      "vinss v2[3], r1\n"
      "veor v0, v1, v2\n"
      "vmovrs r3, v0[0]\n"
      "vmovrs r4, v0[1]\n"
      "vmovrs r5, v0[2]\n"
      "vmovrs r6, v0[3]\n"
      "add r0, r3, r4\n"
      "add r0, r0, r5\n"
      "add r0, r0, r6\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vaddw, assembler) {
  __ LoadImmediate(R4, 21);

  __ vdupw(V1, R4);
  __ vdupw(V2, R4);

  __ vaddw(V0, V1, V2);

  __ vmovrs(R0, V0, 0);
  __ vmovrs(R1, V0, 1);
  __ vmovrs(R2, V0, 2);
  __ vmovrs(R3, V0, 3);
  __ add(R0, R0, Operand(R1));
  __ add(R0, R0, Operand(R2));
  __ add(R0, R0, Operand(R3));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vaddw, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(168, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r4, #0x15\n"
      "vdups v1, r4\n"
      "vdups v2, r4\n"
      "vaddw v0, v1, v2\n"
      "vmovrs r0, v0[0]\n"
      "vmovrs r1, v0[1]\n"
      "vmovrs r2, v0[2]\n"
      "vmovrs r3, v0[3]\n"
      "add r0, r0, r1\n"
      "add r0, r0, r2\n"
      "add r0, r0, r3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vsubw, assembler) {
  __ LoadImmediate(R4, 31);
  __ LoadImmediate(R5, 10);

  __ vdupw(V1, R4);
  __ vdupw(V2, R5);

  __ vsubw(V0, V1, V2);

  __ vmovrs(R0, V0, 0);
  __ vmovrs(R1, V0, 1);
  __ vmovrs(R2, V0, 2);
  __ vmovrs(R3, V0, 3);
  __ add(R0, R0, Operand(R1));
  __ add(R0, R0, Operand(R2));
  __ add(R0, R0, Operand(R3));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vsubw, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(84, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r4, #0x1f\n"
      "movz r5, #0xa\n"
      "vdups v1, r4\n"
      "vdups v2, r5\n"
      "vsubw v0, v1, v2\n"
      "vmovrs r0, v0[0]\n"
      "vmovrs r1, v0[1]\n"
      "vmovrs r2, v0[2]\n"
      "vmovrs r3, v0[3]\n"
      "add r0, r0, r1\n"
      "add r0, r0, r2\n"
      "add r0, r0, r3\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vaddx, assembler) {
  __ LoadImmediate(R4, 21);

  __ vdupx(V1, R4);
  __ vdupx(V2, R4);

  __ vaddx(V0, V1, V2);

  __ vmovrd(R0, V0, 0);
  __ vmovrd(R1, V0, 1);
  __ add(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vaddx, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(84, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r4, #0x15\n"
      "vdupd v1, r4\n"
      "vdupd v2, r4\n"
      "vaddx v0, v1, v2\n"
      "vmovrd r0, v0[0]\n"
      "vmovrd r1, v0[1]\n"
      "add r0, r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vsubx, assembler) {
  __ LoadImmediate(R4, 31);
  __ LoadImmediate(R5, 10);

  __ vdupx(V1, R4);
  __ vdupx(V2, R5);

  __ vsubx(V0, V1, V2);

  __ vmovrd(R0, V0, 0);
  __ vmovrd(R1, V0, 1);
  __ add(R0, R0, Operand(R1));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vsubx, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz r4, #0x1f\n"
      "movz r5, #0xa\n"
      "vdupd v1, r4\n"
      "vdupd v2, r5\n"
      "vsubx v0, v1, v2\n"
      "vmovrd r0, v0[0]\n"
      "vmovrd r1, v0[1]\n"
      "add r0, r0, r1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vceqs, assembler) {
  __ LoadDImmediate(V0, 42.0);
  __ LoadDImmediate(V1, -42.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);

  __ vdups(V2, V0, 0);
  __ vinss(V3, 0, V0, 0);
  __ vinss(V3, 1, V1, 0);
  __ vinss(V3, 2, V0, 0);
  __ vinss(V3, 3, V1, 0);

  __ vceqs(V4, V2, V3);

  __ vmovrs(R1, V4, 0);
  __ vmovrs(R2, V4, 1);
  __ vmovrs(R3, V4, 2);
  __ vmovrs(R4, V4, 3);

  __ addw(R0, R1, Operand(R2));
  __ addw(R0, R0, Operand(R3));
  __ addw(R0, R0, Operand(R4));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vceqs, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0xfffffffe, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0xc045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "vdups v2, v0[0]\n"
      "vinss v3[0], v0[0]\n"
      "vinss v3[1], v1[0]\n"
      "vinss v3[2], v0[0]\n"
      "vinss v3[3], v1[0]\n"
      "vceqs v4, v2, v3\n"
      "vmovrs r1, v4[0]\n"
      "vmovrs r2, v4[1]\n"
      "vmovrs r3, v4[2]\n"
      "vmovrs r4, v4[3]\n"
      "addw r0, r1, r2\n"
      "addw r0, r0, r3\n"
      "addw r0, r0, r4\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vceqd, assembler) {
  __ LoadDImmediate(V0, 42.0);
  __ LoadDImmediate(V1, -42.0);

  __ vdupd(V2, V0, 0);
  __ vinsd(V3, 0, V0, 0);
  __ vinsd(V3, 1, V1, 0);

  __ vceqd(V4, V2, V3);

  __ vmovrd(R1, V4, 0);
  __ vmovrd(R2, V4, 1);

  __ add(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vceqd, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0xc045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "vdupd v2, v0[0]\n"
      "vinsd v3[0], v0[0]\n"
      "vinsd v3[1], v1[0]\n"
      "vceqd v4, v2, v3\n"
      "vmovrd r1, v4[0]\n"
      "vmovrd r2, v4[1]\n"
      "add r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vcgts, assembler) {
  __ LoadDImmediate(V0, 42.0);
  __ LoadDImmediate(V1, -42.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);

  __ vdups(V2, V0, 0);
  __ vinss(V3, 0, V0, 0);
  __ vinss(V3, 1, V1, 0);
  __ vinss(V3, 2, V0, 0);
  __ vinss(V3, 3, V1, 0);

  __ vcgts(V4, V2, V3);

  __ vmovrs(R1, V4, 0);
  __ vmovrs(R2, V4, 1);
  __ vmovrs(R3, V4, 2);
  __ vmovrs(R4, V4, 3);

  __ addw(R0, R1, Operand(R2));
  __ addw(R0, R0, Operand(R3));
  __ addw(R0, R0, Operand(R4));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vcgts, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0xfffffffe, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0xc045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "vdups v2, v0[0]\n"
      "vinss v3[0], v0[0]\n"
      "vinss v3[1], v1[0]\n"
      "vinss v3[2], v0[0]\n"
      "vinss v3[3], v1[0]\n"
      "vcgts v4, v2, v3\n"
      "vmovrs r1, v4[0]\n"
      "vmovrs r2, v4[1]\n"
      "vmovrs r3, v4[2]\n"
      "vmovrs r4, v4[3]\n"
      "addw r0, r1, r2\n"
      "addw r0, r0, r3\n"
      "addw r0, r0, r4\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vcgtd, assembler) {
  __ LoadDImmediate(V0, 42.0);
  __ LoadDImmediate(V1, -42.0);

  __ vdupd(V2, V0, 0);
  __ vinsd(V3, 0, V0, 0);
  __ vinsd(V3, 1, V1, 0);

  __ vcgtd(V4, V2, V3);

  __ vmovrd(R1, V4, 0);
  __ vmovrd(R2, V4, 1);

  __ add(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vcgtd, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0xc045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "vdupd v2, v0[0]\n"
      "vinsd v3[0], v0[0]\n"
      "vinsd v3[1], v1[0]\n"
      "vcgtd v4, v2, v3\n"
      "vmovrd r1, v4[0]\n"
      "vmovrd r2, v4[1]\n"
      "add r0, r1, r2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vcges, assembler) {
  __ LoadDImmediate(V0, 42.0);
  __ LoadDImmediate(V1, 43.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);

  __ vdups(V2, V0, 0);
  __ vinss(V3, 0, V0, 0);
  __ vinss(V3, 1, V1, 0);
  __ vinss(V3, 2, V0, 0);
  __ vinss(V3, 3, V1, 0);

  __ vcges(V4, V2, V3);

  __ vmovrs(R1, V4, 0);
  __ vmovrs(R2, V4, 1);
  __ vmovrs(R3, V4, 2);
  __ vmovrs(R4, V4, 3);

  __ addw(R0, R1, Operand(R2));
  __ addw(R0, R0, Operand(R3));
  __ addw(R0, R0, Operand(R4));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vcges, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0xfffffffe, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "vdups v2, v0[0]\n"
      "vinss v3[0], v0[0]\n"
      "vinss v3[1], v1[0]\n"
      "vinss v3[2], v0[0]\n"
      "vinss v3[3], v1[0]\n"
      "vcges v4, v2, v3\n"
      "vmovrs r1, v4[0]\n"
      "vmovrs r2, v4[1]\n"
      "vmovrs r3, v4[2]\n"
      "vmovrs r4, v4[3]\n"
      "addw r0, r1, r2\n"
      "addw r0, r0, r3\n"
      "addw r0, r0, r4\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vcged, assembler) {
  __ LoadDImmediate(V0, 42.0);
  __ LoadDImmediate(V1, 43.0);

  __ vdupd(V2, V0, 0);
  __ vinsd(V3, 0, V0, 0);
  __ vinsd(V3, 1, V1, 0);

  __ vcged(V4, V2, V3);

  __ vmovrd(R1, V4, 0);
  __ vmovrd(R2, V4, 1);

  __ add(R0, R1, Operand(R2));
  __ ret();
}

ASSEMBLER_TEST_RUN(Vcged, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4045 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4045 lsl 48\n"
      "fmovdr v1, tmp\n"
      "vdupd v2, v0[0]\n"
      "vinsd v3[0], v0[0]\n"
      "vinsd v3[1], v1[0]\n"
      "vcged v4, v2, v3\n"
      "vmovrd r1, v4[0]\n"
      "vmovrd r2, v4[1]\n"
      "add r0, r1, r2\n"
      "ret\n");
}

// Verify that vmaxs(-0.0, 0.0) = 0.0
ASSEMBLER_TEST_GENERATE(Vmaxs_zero, assembler) {
  __ veor(V1, V1, V1);
  __ vnegd(V2, V1);
  __ vmaxs(V0, V2, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmaxs_zero, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  double d = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_EQ(true, !signbit(d) && (d == 0.0));
  EXPECT_DISASSEMBLY(
      "veor v1, v1, v1\n"
      "vnegd v2, v1\n"
      "vmaxs v0, v2, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vmaxs, assembler) {
  __ LoadDImmediate(V0, 10.5);
  __ LoadDImmediate(V1, 10.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);

  __ vdups(V2, V0, 0);
  __ vinss(V3, 0, V0, 0);
  __ vinss(V3, 1, V1, 0);
  __ vinss(V3, 2, V0, 0);
  __ vinss(V3, 3, V1, 0);

  __ vmaxs(V4, V2, V3);

  __ vinss(V0, 0, V4, 0);
  __ vinss(V1, 0, V4, 1);
  __ vinss(V2, 0, V4, 2);
  __ vinss(V3, 0, V4, 3);

  __ fcvtds(V0, V0);
  __ fcvtds(V1, V1);
  __ fcvtds(V2, V2);
  __ fcvtds(V3, V3);

  __ faddd(V0, V0, V1);
  __ faddd(V0, V0, V2);
  __ faddd(V0, V0, V3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmaxs, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v0, 10.500000\n"
      "fmovd v1, 10.000000\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "vdups v2, v0[0]\n"
      "vinss v3[0], v0[0]\n"
      "vinss v3[1], v1[0]\n"
      "vinss v3[2], v0[0]\n"
      "vinss v3[3], v1[0]\n"
      "vmaxs v4, v2, v3\n"
      "vinss v0[0], v4[0]\n"
      "vinss v1[0], v4[1]\n"
      "vinss v2[0], v4[2]\n"
      "vinss v3[0], v4[3]\n"
      "fcvtds v0, v0\n"
      "fcvtds v1, v1\n"
      "fcvtds v2, v2\n"
      "fcvtds v3, v3\n"
      "faddd v0, v0, v1\n"
      "faddd v0, v0, v2\n"
      "faddd v0, v0, v3\n"
      "ret\n");
}

// Verify that vmaxd(-0.0, 0.0) = 0.0
ASSEMBLER_TEST_GENERATE(Vmaxd_zero, assembler) {
  __ veor(V1, V1, V1);
  __ vnegd(V2, V1);
  __ vmaxd(V0, V2, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmaxd_zero, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  double d = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_EQ(true, !signbit(d) && (d == 0.0));
  EXPECT_DISASSEMBLY(
      "veor v1, v1, v1\n"
      "vnegd v2, v1\n"
      "vmaxd v0, v2, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vmaxd, assembler) {
  __ LoadDImmediate(V0, 21.0);
  __ LoadDImmediate(V1, 20.5);

  __ vdupd(V2, V0, 0);
  __ vinsd(V3, 0, V0, 0);
  __ vinsd(V3, 1, V1, 0);

  __ vmaxd(V4, V2, V3);

  __ vinsd(V0, 0, V4, 0);
  __ vinsd(V1, 0, V4, 1);

  __ faddd(V0, V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmaxd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v0, 21.000000\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4034 lsl 48\n"
      "fmovdr v1, tmp\n"
      "vdupd v2, v0[0]\n"
      "vinsd v3[0], v0[0]\n"
      "vinsd v3[1], v1[0]\n"
      "vmaxd v4, v2, v3\n"
      "vinsd v0[0], v4[0]\n"
      "vinsd v1[0], v4[1]\n"
      "faddd v0, v0, v1\n"
      "ret\n");
}

// Verify that vmins(-0.0, 0.0) = -0.0
ASSEMBLER_TEST_GENERATE(Vmins_zero, assembler) {
  __ veor(V1, V1, V1);
  __ vnegd(V2, V1);
  __ vmins(V0, V1, V2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmins_zero, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  double d = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  fprintf(stderr, "d: %f\n", d);
  EXPECT_EQ(true, signbit(d) && (d == 0.0));
  EXPECT_DISASSEMBLY(
      "veor v1, v1, v1\n"
      "vnegd v2, v1\n"
      "vmins v0, v1, v2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vmins, assembler) {
  __ LoadDImmediate(V0, 10.5);
  __ LoadDImmediate(V1, 11.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);

  __ vdups(V2, V0, 0);
  __ vinss(V3, 0, V0, 0);
  __ vinss(V3, 1, V1, 0);
  __ vinss(V3, 2, V0, 0);
  __ vinss(V3, 3, V1, 0);

  __ vmins(V4, V2, V3);

  __ vinss(V0, 0, V4, 0);
  __ vinss(V1, 0, V4, 1);
  __ vinss(V2, 0, V4, 2);
  __ vinss(V3, 0, V4, 3);

  __ fcvtds(V0, V0);
  __ fcvtds(V1, V1);
  __ fcvtds(V2, V2);
  __ fcvtds(V3, V3);

  __ faddd(V0, V0, V1);
  __ faddd(V0, V0, V2);
  __ faddd(V0, V0, V3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmins, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v0, 10.500000\n"
      "fmovd v1, 11.000000\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "vdups v2, v0[0]\n"
      "vinss v3[0], v0[0]\n"
      "vinss v3[1], v1[0]\n"
      "vinss v3[2], v0[0]\n"
      "vinss v3[3], v1[0]\n"
      "vmins v4, v2, v3\n"
      "vinss v0[0], v4[0]\n"
      "vinss v1[0], v4[1]\n"
      "vinss v2[0], v4[2]\n"
      "vinss v3[0], v4[3]\n"
      "fcvtds v0, v0\n"
      "fcvtds v1, v1\n"
      "fcvtds v2, v2\n"
      "fcvtds v3, v3\n"
      "faddd v0, v0, v1\n"
      "faddd v0, v0, v2\n"
      "faddd v0, v0, v3\n"
      "ret\n");
}

// Verify that vmind(-0.0, 0.0) = -0.0
ASSEMBLER_TEST_GENERATE(Vmind_zero, assembler) {
  __ veor(V1, V1, V1);
  __ vnegd(V2, V1);
  __ vmind(V0, V1, V2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmind_zero, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  double d = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  fprintf(stderr, "d: %f\n", d);
  EXPECT_EQ(true, signbit(d) && (d == 0.0));
  EXPECT_DISASSEMBLY(
      "veor v1, v1, v1\n"
      "vnegd v2, v1\n"
      "vmind v0, v1, v2\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vmind, assembler) {
  __ LoadDImmediate(V0, 21.0);
  __ LoadDImmediate(V1, 21.5);

  __ vdupd(V2, V0, 0);
  __ vinsd(V3, 0, V0, 0);
  __ vinsd(V3, 1, V1, 0);

  __ vmind(V4, V2, V3);

  __ vinsd(V0, 0, V4, 0);
  __ vinsd(V1, 0, V4, 1);

  __ faddd(V0, V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vmind, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "fmovd v0, 21.000000\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4035 lsl 48\n"
      "fmovdr v1, tmp\n"
      "vdupd v2, v0[0]\n"
      "vinsd v3[0], v0[0]\n"
      "vinsd v3[1], v1[0]\n"
      "vmind v4, v2, v3\n"
      "vinsd v0[0], v4[0]\n"
      "vinsd v1[0], v4[1]\n"
      "faddd v0, v0, v1\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vsqrts, assembler) {
  __ LoadDImmediate(V0, 64.0);
  __ LoadDImmediate(V1, 49.0);

  __ fcvtsd(V0, V0);
  __ fcvtsd(V1, V1);

  __ veor(V3, V3, V3);
  __ vinss(V3, 1, V0, 0);
  __ vinss(V3, 3, V1, 0);

  __ vsqrts(V4, V3);

  __ vinss(V5, 0, V4, 1);
  __ vinss(V6, 0, V4, 3);

  __ fcvtds(V5, V5);
  __ fcvtds(V6, V6);

  __ faddd(V0, V5, V6);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vsqrts, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(15.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4050 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4048 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fcvtsd v0, v0\n"
      "fcvtsd v1, v1\n"
      "veor v3, v3, v3\n"
      "vinss v3[1], v0[0]\n"
      "vinss v3[3], v1[0]\n"
      "vsqrts v4, v3\n"
      "vinss v5[0], v4[1]\n"
      "vinss v6[0], v4[3]\n"
      "fcvtds v5, v5\n"
      "fcvtds v6, v6\n"
      "faddd v0, v5, v6\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vsqrtd, assembler) {
  __ LoadDImmediate(V0, 64.0);
  __ LoadDImmediate(V1, 49.0);

  __ vinsd(V3, 0, V0, 0);
  __ vinsd(V3, 1, V1, 0);

  __ vsqrtd(V4, V3);

  __ vinsd(V5, 0, V4, 0);
  __ vinsd(V6, 0, V4, 1);

  __ faddd(V0, V5, V6);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vsqrtd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(15.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x4050 lsl 48\n"
      "fmovdr v0, tmp\n"
      "movz tmp, #0x8000 lsl 32\n"
      "movk tmp, #0x4048 lsl 48\n"
      "fmovdr v1, tmp\n"
      "vinsd v3[0], v0[0]\n"
      "vinsd v3[1], v1[0]\n"
      "vsqrtd v4, v3\n"
      "vinsd v5[0], v4[0]\n"
      "vinsd v6[0], v4[1]\n"
      "faddd v0, v5, v6\n"
      "ret\n");
}

// This is the same function as in the Simulator.
static float arm_recip_estimate(float a) {
  // From the ARM Architecture Reference Manual A2-85.
  if (isinf(a) || (fabs(a) >= exp2f(126)))
    return 0.0;
  else if (a == 0.0)
    return kPosInfinity;
  else if (isnan(a))
    return a;

  uint32_t a_bits = bit_cast<uint32_t, float>(a);
  // scaled = '0011 1111 1110' : a<22:0> : Zeros(29)
  uint64_t scaled = (static_cast<uint64_t>(0x3fe) << 52) |
                    ((static_cast<uint64_t>(a_bits) & 0x7fffff) << 29);
  // result_exp = 253 - UInt(a<30:23>)
  int32_t result_exp = 253 - ((a_bits >> 23) & 0xff);
  ASSERT((result_exp >= 1) && (result_exp <= 252));

  double scaled_d = bit_cast<double, uint64_t>(scaled);
  ASSERT((scaled_d >= 0.5) && (scaled_d < 1.0));

  // a in units of 1/512 rounded down.
  int32_t q = static_cast<int32_t>(scaled_d * 512.0);
  // reciprocal r.
  double r = 1.0 / ((static_cast<double>(q) + 0.5) / 512.0);
  // r in units of 1/256 rounded to nearest.
  int32_t s = static_cast<int32_t>(256.0 * r + 0.5);
  double estimate = static_cast<double>(s) / 256.0;
  ASSERT((estimate >= 1.0) && (estimate <= (511.0 / 256.0)));

  // result = sign : result_exp<7:0> : estimate<51:29>
  int32_t result_bits =
      (a_bits & 0x80000000) | ((result_exp & 0xff) << 23) |
      ((bit_cast<uint64_t, double>(estimate) >> 29) & 0x7fffff);
  return bit_cast<float, int32_t>(result_bits);
}

ASSEMBLER_TEST_GENERATE(Vrecpes, assembler) {
  __ LoadDImmediate(V1, 147.0);
  __ fcvtsd(V1, V1);
  __ vinss(V2, 0, V1, 0);
  __ vinss(V2, 1, V1, 0);
  __ vinss(V2, 2, V1, 0);
  __ vinss(V2, 3, V1, 0);
  __ vrecpes(V0, V2);
  __ fcvtds(V0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vrecpes, test) {
  EXPECT(test != nullptr);
  typedef double (*DoubleReturn)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ(arm_recip_estimate(147.0), res, 0.0001);
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x6000 lsl 32\n"
      "movk tmp, #0x4062 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fcvtsd v1, v1\n"
      "vinss v2[0], v1[0]\n"
      "vinss v2[1], v1[0]\n"
      "vinss v2[2], v1[0]\n"
      "vinss v2[3], v1[0]\n"
      "vrecpes v0, v2\n"
      "fcvtds v0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vrecpss, assembler) {
  __ LoadDImmediate(V1, 5.0);
  __ LoadDImmediate(V2, 10.0);

  __ fcvtsd(V1, V1);
  __ fcvtsd(V2, V2);

  __ vrecpss(V0, V1, V2);

  __ fcvtds(V0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vrecpss, test) {
  EXPECT(test != nullptr);
  typedef double (*DoubleReturn)() DART_UNUSED;
  double res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ(2.0 - 10.0 * 5.0, res, 0.0001);
  EXPECT_DISASSEMBLY(
      "fmovd v1, 5.000000\n"
      "fmovd v2, 10.000000\n"
      "fcvtsd v1, v1\n"
      "fcvtsd v2, v2\n"
      "vrecpss v0, v1, v2\n"
      "fcvtds v0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(VRecps, assembler) {
  __ LoadDImmediate(V0, 1.0 / 10.5);
  __ fcvtsd(V0, V0);

  __ vdups(V1, V0, 0);

  __ VRecps(V2, V1);

  __ vinss(V0, 0, V2, 0);
  __ vinss(V1, 0, V2, 1);
  __ vinss(V2, 0, V2, 2);
  __ vinss(V3, 0, V2, 3);

  __ fcvtds(V0, V0);
  __ fcvtds(V1, V1);
  __ fcvtds(V2, V2);
  __ fcvtds(V3, V3);

  __ faddd(V0, V0, V1);
  __ faddd(V0, V0, V2);
  __ faddd(V0, V0, V3);
  __ ret();
}

ASSEMBLER_TEST_RUN(VRecps, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  double res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ(42.0, res, 0.0001);
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x8618\n"
      "movk tmp, #0x1861 lsl 16\n"
      "movk tmp, #0x6186 lsl 32\n"
      "movk tmp, #0x3fb8 lsl 48\n"
      "fmovdr v0, tmp\n"
      "fcvtsd v0, v0\n"
      "vdups v1, v0[0]\n"
      "vrecpes v2, v1\n"
      "vrecpss v31, v1, v2\n"
      "vmuls v2, v2, v31\n"
      "vrecpss v31, v1, v2\n"
      "vmuls v2, v2, v31\n"
      "vinss v0[0], v2[0]\n"
      "vinss v1[0], v2[1]\n"
      "vinss v2[0], v2[2]\n"
      "vinss v3[0], v2[3]\n"
      "fcvtds v0, v0\n"
      "fcvtds v1, v1\n"
      "fcvtds v2, v2\n"
      "fcvtds v3, v3\n"
      "faddd v0, v0, v1\n"
      "faddd v0, v0, v2\n"
      "faddd v0, v0, v3\n"
      "ret\n");
}

static float arm_reciprocal_sqrt_estimate(float a) {
  // From the ARM Architecture Reference Manual A2-87.
  if (isinf(a) || (fabs(a) >= exp2f(126)))
    return 0.0;
  else if (a == 0.0)
    return kPosInfinity;
  else if (isnan(a))
    return a;

  uint32_t a_bits = bit_cast<uint32_t, float>(a);
  uint64_t scaled;
  if (((a_bits >> 23) & 1) != 0) {
    // scaled = '0 01111111101' : operand<22:0> : Zeros(29)
    scaled = (static_cast<uint64_t>(0x3fd) << 52) |
             ((static_cast<uint64_t>(a_bits) & 0x7fffff) << 29);
  } else {
    // scaled = '0 01111111110' : operand<22:0> : Zeros(29)
    scaled = (static_cast<uint64_t>(0x3fe) << 52) |
             ((static_cast<uint64_t>(a_bits) & 0x7fffff) << 29);
  }
  // result_exp = (380 - UInt(operand<30:23>) DIV 2;
  int32_t result_exp = (380 - ((a_bits >> 23) & 0xff)) / 2;

  double scaled_d = bit_cast<double, uint64_t>(scaled);
  ASSERT((scaled_d >= 0.25) && (scaled_d < 1.0));

  double r;
  if (scaled_d < 0.5) {
    // range 0.25 <= a < 0.5

    // a in units of 1/512 rounded down.
    int32_t q0 = static_cast<int32_t>(scaled_d * 512.0);
    // reciprocal root r.
    r = 1.0 / sqrt((static_cast<double>(q0) + 0.5) / 512.0);
  } else {
    // range 0.5 <= a < 1.0

    // a in units of 1/256 rounded down.
    int32_t q1 = static_cast<int32_t>(scaled_d * 256.0);
    // reciprocal root r.
    r = 1.0 / sqrt((static_cast<double>(q1) + 0.5) / 256.0);
  }
  // r in units of 1/256 rounded to nearest.
  int32_t s = static_cast<int>(256.0 * r + 0.5);
  double estimate = static_cast<double>(s) / 256.0;
  ASSERT((estimate >= 1.0) && (estimate <= (511.0 / 256.0)));

  // result = 0 : result_exp<7:0> : estimate<51:29>
  int32_t result_bits =
      ((result_exp & 0xff) << 23) |
      ((bit_cast<uint64_t, double>(estimate) >> 29) & 0x7fffff);
  return bit_cast<float, int32_t>(result_bits);
}

ASSEMBLER_TEST_GENERATE(Vrsqrtes, assembler) {
  __ LoadDImmediate(V1, 147.0);
  __ fcvtsd(V1, V1);

  __ vrsqrtes(V0, V1);

  __ fcvtds(V0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vrsqrtes, test) {
  EXPECT(test != nullptr);
  typedef double (*DoubleReturn)() DART_UNUSED;
  double res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ(arm_reciprocal_sqrt_estimate(147.0), res, 0.0001);
  EXPECT_DISASSEMBLY(
      "movz tmp, #0x6000 lsl 32\n"
      "movk tmp, #0x4062 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fcvtsd v1, v1\n"
      "vrsqrtes v0, v1\n"
      "fcvtds v0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(Vrsqrtss, assembler) {
  __ LoadDImmediate(V1, 5.0);
  __ LoadDImmediate(V2, 10.0);

  __ fcvtsd(V1, V1);
  __ fcvtsd(V2, V2);

  __ vrsqrtss(V0, V1, V2);

  __ fcvtds(V0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Vrsqrtss, test) {
  EXPECT(test != nullptr);
  typedef double (*DoubleReturn)() DART_UNUSED;
  double res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ((3.0 - 10.0 * 5.0) / 2.0, res, 0.0001);
  EXPECT_DISASSEMBLY(
      "fmovd v1, 5.000000\n"
      "fmovd v2, 10.000000\n"
      "fcvtsd v1, v1\n"
      "fcvtsd v2, v2\n"
      "vrsqrts v0, v1, v2\n"
      "fcvtds v0, v0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(ReciprocalSqrt, assembler) {
  __ LoadDImmediate(V1, 147000.0);
  __ fcvtsd(V1, V1);

  __ VRSqrts(V0, V1);

  __ fcvtds(V0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(ReciprocalSqrt, test) {
  EXPECT(test != nullptr);
  typedef double (*DoubleReturn)() DART_UNUSED;
  double res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ(1.0 / sqrt(147000.0), res, 0.0001);
  EXPECT_DISASSEMBLY(
      "movz tmp, #0xf1c0 lsl 32\n"
      "movk tmp, #0x4101 lsl 48\n"
      "fmovdr v1, tmp\n"
      "fcvtsd v1, v1\n"
      "vrsqrtes v0, v1\n"
      "vmuls v31, v0, v0\n"
      "vrsqrts v31, v1, v31\n"
      "vmuls v0, v0, v31\n"
      "vmuls v31, v0, v0\n"
      "vrsqrts v31, v1, v31\n"
      "vmuls v0, v0, v31\n"
      "fcvtds v0, v0\n"
      "ret\n");
}

// Called from assembler_test.cc.
// LR: return address.
// R0: value.
// R1: growable array.
// R2: current thread.
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ SetupDartSP();
  __ Push(CODE_REG);
  __ Push(THR);
  __ Push(HEAP_BITS);
  SPILLS_LR_TO_FRAME(__ Push(LR));
  __ mov(THR, R2);
  __ ldr(HEAP_BITS, Address(THR, Thread::write_barrier_mask_offset()));
  __ LslImmediate(HEAP_BITS, HEAP_BITS, 32);
  __ StoreCompressedIntoObject(
      R1, FieldAddress(R1, GrowableObjectArray::data_offset()), R0);
  RESTORES_LR_FROM_FRAME(__ Pop(LR));
  __ Pop(HEAP_BITS);
  __ Pop(THR);
  __ Pop(CODE_REG);
  __ RestoreCSP();
  __ ret();
}

// Push numbers from kMaxPushedNumber to 0 to the stack then drop top
// kMaxPushedNumber elements. This should leave just kMaxPushedNumber on the
// stack.
const intptr_t kMaxPushedNumber = 913;

ASSEMBLER_TEST_GENERATE(Drop, assembler) {
  __ SetupDartSP((kMaxPushedNumber + 1) * target::kWordSize);
  for (intptr_t i = kMaxPushedNumber; i >= 0; i--) {
    __ PushImmediate(i);
  }
  __ Drop(kMaxPushedNumber);
  __ PopRegister(R0);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(Drop, test) {
  EXPECT(test != nullptr);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(kMaxPushedNumber,
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(AndImmediate32Negative, assembler) {
  __ AndImmediate(R0, R0, -512, kFourBytes);
  __ ret();
}

ASSEMBLER_TEST_RUN(AndImmediate32Negative, test) {
  typedef intptr_t (*IntPtrReturn)(intptr_t) DART_UNUSED;
  EXPECT_EQ(0xfffffe00,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), -42));
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), 0));
  EXPECT_EQ(0,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), 42));
  EXPECT_DISASSEMBLY(
      "andw r0, r0, 0xfffffe00\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(OrImmediate32Negative, assembler) {
  __ OrImmediate(R0, R0, -512, kFourBytes);
  __ ret();
}

ASSEMBLER_TEST_RUN(OrImmediate32Negative, test) {
  typedef intptr_t (*IntPtrReturn)(intptr_t) DART_UNUSED;
  EXPECT_EQ(0xffffffd6,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), -42));
  EXPECT_EQ(0xfffffe00,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), 0));
  EXPECT_EQ(0xfffffe2a,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), 42));
  EXPECT_DISASSEMBLY(
      "orrw r0, r0, 0xfffffe00\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(XorImmediate32Negative, assembler) {
  __ XorImmediate(R0, R0, -512, kFourBytes);
  __ ret();
}

ASSEMBLER_TEST_RUN(XorImmediate32Negative, test) {
  typedef intptr_t (*IntPtrReturn)(intptr_t) DART_UNUSED;
  EXPECT_EQ(0x1d6,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), -42));
  EXPECT_EQ(0xfffffe00,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), 0));
  EXPECT_EQ(0xfffffe2a,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), 42));
  EXPECT_DISASSEMBLY(
      "eorw r0, r0, 0xfffffe00\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(TestImmediate32Negative, assembler) {
  Label on_zero;
  __ TestImmediate(R0, -512, kFourBytes);
  __ b(&on_zero, EQ);
  __ LoadImmediate(R0, 1);
  __ ret();
  __ Bind(&on_zero);
  __ LoadImmediate(R0, 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestImmediate32Negative, test) {
  typedef intptr_t (*IntPtrReturn)(intptr_t) DART_UNUSED;
  EXPECT_EQ(1,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), -42));
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), 0));
  EXPECT_EQ(0,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), 42));
  EXPECT_DISASSEMBLY(
      "tstw r0, 0xfffffe00\n"
      "beq +12\n"
      "movz r0, #0x1\n"
      "ret\n"
      "movz r0, #0x0\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(CompareImmediate32Negative, assembler) {
  Label on_zero;
  __ CompareImmediate(R0, -512, kFourBytes);
  __ b(&on_zero, LT);
  __ LoadImmediate(R0, 0);
  __ ret();
  __ Bind(&on_zero);
  __ LoadImmediate(R0, 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(CompareImmediate32Negative, test) {
  typedef intptr_t (*IntPtrReturn)(intptr_t) DART_UNUSED;
  EXPECT_EQ(1,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), -513));
  EXPECT_EQ(0,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), -512));
  EXPECT_EQ(0,
            EXECUTE_TEST_CODE_INTPTR_INTPTR(IntPtrReturn, test->entry(), -511));
  EXPECT_DISASSEMBLY(
      "cmnw r0, #0x200\n"
      "blt +12\n"
      "movz r0, #0x0\n"
      "ret\n"
      "movz r0, #0x1\n"
      "ret\n");
}

// can't call (tsan) runtime methods
#if !defined(TARGET_USES_THREAD_SANITIZER)

ASSEMBLER_TEST_GENERATE(StoreReleaseLoadAcquire, assembler) {
  __ SetupDartSP();
  __ Push(R1);
  __ LoadImmediate(R1, 0);
  __ Push(R1);
  __ mov(R1, R0);
  __ LoadImmediate(R0, 0);
  __ StoreRelease(R1, SP, 0);
  __ LoadAcquire(R0, SP, 0);
  __ Pop(R1);
  __ Pop(R1);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(StoreReleaseLoadAcquire, test) {
  typedef intptr_t (*StoreReleaseLoadAcquire)(intptr_t) DART_UNUSED;
  EXPECT_EQ(123, EXECUTE_TEST_CODE_INTPTR_INTPTR(StoreReleaseLoadAcquire,
                                                 test->entry(), 123));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "str r1, [sp, #-8]!\n"
      "movz r1, #0x0\n"
      "str r1, [sp, #-8]!\n"
      "mov r1, r0\n"
      "movz r0, #0x0\n"
      "stlr r1, sp\n"
      "ldar r0, sp\n"
      "ldr r1, [sp], #8 !\n"
      "ldr r1, [sp], #8 !\n"
      "mov csp, sp\n"
      "ret\n");
}

ASSEMBLER_TEST_GENERATE(StoreReleaseLoadAcquire1024, assembler) {
  __ SetupDartSP();
  __ Push(R1);
  __ LoadImmediate(R1, 0);
  __ Push(R1);
  __ mov(R1, R0);
  __ LoadImmediate(R0, 0);
  __ sub(SP, SP, Operand(1024 * target::kWordSize));
  __ StoreRelease(R1, SP, 1024);
  __ LoadAcquire(R0, SP, 1024);
  __ add(SP, SP, Operand(1024 * target::kWordSize));
  __ Pop(R1);
  __ Pop(R1);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(StoreReleaseLoadAcquire1024, test) {
  typedef intptr_t (*StoreReleaseLoadAcquire1024)(intptr_t) DART_UNUSED;
  EXPECT_EQ(123, EXECUTE_TEST_CODE_INTPTR_INTPTR(StoreReleaseLoadAcquire1024,
                                                 test->entry(), 123));
  EXPECT_DISASSEMBLY(
      "mov sp, csp\n"
      "sub csp, csp, #0x1000\n"
      "str r1, [sp, #-8]!\n"
      "movz r1, #0x0\n"
      "str r1, [sp, #-8]!\n"
      "mov r1, r0\n"
      "movz r0, #0x0\n"
      "sub sp, sp, #0x2000\n"
      "add tmp, sp, #0x400\n"
      "stlr r1, tmp\n"
      "add tmp2, sp, #0x400\n"
      "ldar r0, tmp2\n"
      "add sp, sp, #0x2000\n"
      "ldr r1, [sp], #8 !\n"
      "ldr r1, [sp], #8 !\n"
      "mov csp, sp\n"
      "ret\n");
}
#endif  // !defined(TARGET_USES_THREAD_SANITIZER)

static void RangeCheck(Assembler* assembler, Register value, Register temp) {
  const Register return_reg = CallingConventions::kReturnReg;
  Label in_range;
  __ RangeCheck(value, temp, kFirstErrorCid, kLastErrorCid,
                AssemblerBase::kIfInRange, &in_range);
  __ LoadImmediate(return_reg, Immediate(0));
  __ Ret();
  __ Bind(&in_range);
  __ LoadImmediate(return_reg, Immediate(1));
  __ Ret();
}

ASSEMBLER_TEST_GENERATE(RangeCheckNoTemp, assembler) {
  const Register value = CallingConventions::ArgumentRegisters[0];
  const Register temp = kNoRegister;
  RangeCheck(assembler, value, temp);
}

ASSEMBLER_TEST_RUN(RangeCheckNoTemp, test) {
  intptr_t result;
  result = test->Invoke<intptr_t, intptr_t>(kErrorCid);
  EXPECT_EQ(1, result);
  result = test->Invoke<intptr_t, intptr_t>(kUnwindErrorCid);
  EXPECT_EQ(1, result);
  result = test->Invoke<intptr_t, intptr_t>(kFunctionCid);
  EXPECT_EQ(0, result);
  result = test->Invoke<intptr_t, intptr_t>(kMintCid);
  EXPECT_EQ(0, result);
}

ASSEMBLER_TEST_GENERATE(RangeCheckWithTemp, assembler) {
  const Register value = CallingConventions::ArgumentRegisters[0];
  const Register temp = CallingConventions::ArgumentRegisters[1];
  RangeCheck(assembler, value, temp);
}

ASSEMBLER_TEST_RUN(RangeCheckWithTemp, test) {
  intptr_t result;
  result = test->Invoke<intptr_t, intptr_t>(kErrorCid);
  EXPECT_EQ(1, result);
  result = test->Invoke<intptr_t, intptr_t>(kUnwindErrorCid);
  EXPECT_EQ(1, result);
  result = test->Invoke<intptr_t, intptr_t>(kFunctionCid);
  EXPECT_EQ(0, result);
  result = test->Invoke<intptr_t, intptr_t>(kMintCid);
  EXPECT_EQ(0, result);
}

ASSEMBLER_TEST_GENERATE(RangeCheckWithTempReturnValue, assembler) {
  const Register value = CallingConventions::ArgumentRegisters[0];
  const Register temp = CallingConventions::ArgumentRegisters[1];
  const Register return_reg = CallingConventions::kReturnReg;
  Label in_range;
  __ RangeCheck(value, temp, kFirstErrorCid, kLastErrorCid,
                AssemblerBase::kIfInRange, &in_range);
  __ Bind(&in_range);
  __ mov(return_reg, value);
  __ Ret();
}

ASSEMBLER_TEST_RUN(RangeCheckWithTempReturnValue, test) {
  intptr_t result;
  result = test->Invoke<intptr_t, intptr_t>(kErrorCid);
  EXPECT_EQ(kErrorCid, result);
  result = test->Invoke<intptr_t, intptr_t>(kUnwindErrorCid);
  EXPECT_EQ(kUnwindErrorCid, result);
  result = test->Invoke<intptr_t, intptr_t>(kFunctionCid);
  EXPECT_EQ(kFunctionCid, result);
  result = test->Invoke<intptr_t, intptr_t>(kMintCid);
  EXPECT_EQ(kMintCid, result);
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
