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

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ add(R0, ZR, Operand(ZR));
  __ add(R0, R0, Operand(42));
  __ ret();
}

ASSEMBLER_TEST_RUN(Simple, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
}

ASSEMBLER_TEST_GENERATE(Movz1, assembler) {
  __ movz(R0, Immediate(42), 0);  // Overwritten by next instruction.
  __ movz(R0, Immediate(42), 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movz1, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42LL << 16, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Movz2, assembler) {
  __ movz(R0, Immediate(42), 2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movz2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42LL << 32, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Movz3, assembler) {
  __ movz(R0, Immediate(42), 3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movz3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42LL << 48, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

// movn
ASSEMBLER_TEST_GENERATE(Movn0, assembler) {
  __ movn(R0, Immediate(42), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movn0, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(~42LL, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Movn1, assembler) {
  __ movn(R0, Immediate(42), 1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movn1, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(~(42LL << 16), EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Movn2, assembler) {
  __ movn(R0, Immediate(42), 2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movn2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(~(42LL << 32), EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Movn3, assembler) {
  __ movn(R0, Immediate(42), 3);
  __ ret();
}

ASSEMBLER_TEST_RUN(Movn3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(~(42LL << 48), EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
}

ASSEMBLER_TEST_GENERATE(MovzBig, assembler) {
  __ movz(R0, Immediate(0x8000), 0);
  __ ret();
}

ASSEMBLER_TEST_RUN(MovzBig, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x8000, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
}

// Loads and Stores.
ASSEMBLER_TEST_GENERATE(SimpleLoadStore, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  __ str(R1, Address(SP, -1 * kWordSize, Address::PreIndex));
  __ ldr(R0, Address(SP, 1 * kWordSize, Address::PostIndex));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(SimpleLoadStore, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
}

ASSEMBLER_TEST_GENERATE(LoadStoreLargeIndex, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  // Largest negative offset that can fit in the signed 9-bit immediate field.
  __ str(R1, Address(SP, -32 * kWordSize, Address::PreIndex));
  // Largest positive kWordSize aligned offset that we can fit.
  __ ldr(R0, Address(SP, 31 * kWordSize, Address::PostIndex));
  // Correction.
  __ add(SP, SP, Operand(kWordSize));  // Restore SP.
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreLargeIndex, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadStoreLargeOffset, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  __ sub(SP, SP, Operand(512 * kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ str(R1, Address(SP, 512 * kWordSize, Address::Offset));
  __ add(SP, SP, Operand(512 * kWordSize));
  __ ldr(R0, Address(SP));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreLargeOffset, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
  __ sub(SP, SP, Operand(kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ ldr(R0, Address(SP));
  __ add(SP, SP, Operand(kWordSize));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreExtReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadStoreScaledReg, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(43), 0);
  __ movz(R1, Immediate(42), 0);
  __ movz(R2, Immediate(10), 0);
  __ sub(SP, SP, Operand(10 * kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  // Store R1 into SP + R2 * kWordSize.
  __ str(R1, Address(SP, R2, UXTX, Address::Scaled));
  __ ldr(R0, Address(SP, R2, UXTX, Address::Scaled));
  __ add(SP, SP, Operand(10 * kWordSize));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStoreScaledReg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadSigned32Bit, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R1, 0xffffffff);
  __ str(R1, Address(SP, -4, Address::PreIndex, kWord), kWord);
  __ ldr(R0, Address(SP), kWord);
  __ ldr(R1, Address(SP, 4, Address::PostIndex, kWord), kWord);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadSigned32Bit, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(SimpleLoadStorePair, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R2, 43);
  __ LoadImmediate(R3, 42);
  __ stp(R2, R3, Address(SP, -2 * kWordSize, Address::PairPreIndex));
  __ ldp(R0, R1, Address(SP, 2 * kWordSize, Address::PairPostIndex));
  __ sub(R0, R0, Operand(R1));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(SimpleLoadStorePair, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadStorePairOffset, assembler) {
  __ SetupDartSP();
  __ LoadImmediate(R2, 43);
  __ LoadImmediate(R3, 42);
  __ sub(SP, SP, Operand(4 * kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ stp(R2, R3, Address::Pair(SP, 2 * kWordSize));
  __ ldp(R0, R1, Address::Pair(SP, 2 * kWordSize));
  __ add(SP, SP, Operand(4 * kWordSize));
  __ sub(R0, R0, Operand(R1));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadStorePairOffset, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
  EXPECT(test != NULL);
  typedef intptr_t (*Semaphore)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Semaphore, test->entry()));
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
  EXPECT(test != NULL);
  typedef intptr_t (*FailedSemaphore)() DART_UNUSED;
  EXPECT_EQ(41, EXECUTE_TEST_CODE_INT64(FailedSemaphore, test->entry()));
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
  __ ldxr(R0, SP, kWord);
  // 32 bit operation should ignore the high word of R0 that was pushed on the
  // stack.
  __ stxr(TMP, R1, SP, kWord);  // IP == 0, success
  __ cmp(TMP, Operand(0));
  __ b(&retry, NE);  // NE if context switch occurred between ldrex and strex.
  __ Pop(R0);        // 42 + 42 * 2**32
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(Semaphore32, test) {
  EXPECT(test != NULL);
  typedef intptr_t (*Semaphore32)() DART_UNUSED;
  // Lower word has been atomically switched from 40 to 42k, whereas upper word
  // is unchanged at 40.
  EXPECT_EQ(42 + (40l << 32),
            EXECUTE_TEST_CODE_INT64(Semaphore32, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FailedSemaphore32, assembler) {
  __ SetupDartSP();
  __ movz(R0, Immediate(40), 0);
  __ add(R0, R0, Operand(R0, LSL, 32));
  __ Push(R0);

  __ movz(R0, Immediate(40), 0);
  __ movz(R1, Immediate(42), 0);

  __ ldxr(R0, SP, kWord);
  __ clrex();                   // Simulate a context switch.
  __ stxr(TMP, R1, SP, kWord);  // IP == 1, failure
  __ Pop(R0);                   // 40
  __ add(R0, R0, Operand(TMP));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FailedSemaphore32, test) {
  EXPECT(test != NULL);
  typedef intptr_t (*FailedSemaphore32)() DART_UNUSED;
  // Lower word has had the failure code (1) added to it.  Upper word is
  // unchanged at 40.
  EXPECT_EQ(41 + (40l << 32),
            EXECUTE_TEST_CODE_INT64(FailedSemaphore32, test->entry()));
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
}

ASSEMBLER_TEST_GENERATE(AndOneImm, assembler) {
  __ movz(R1, Immediate(43), 0);
  __ andi(R0, R1, Immediate(1));
  __ ret();
}

ASSEMBLER_TEST_RUN(AndOneImm, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
  __ add(R3, ZR, Operand(LR));  // Save LR.
  // R1 <- PC + 4*Instr::kInstrSize
  __ adr(R1, Immediate(4 * Instr::kInstrSize));
  __ blr(R1);
  __ add(LR, ZR, Operand(R3));
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
  EXPECT(test != NULL);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(3, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
  EXPECT(test != NULL);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-3, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Udiv_zero, assembler) {
  __ movz(R0, Immediate(27), 0);
  __ movz(R1, Immediate(0), 0);
  __ udiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Udiv_zero, test) {
  EXPECT(test != NULL);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Sdiv_zero, assembler) {
  __ movz(R0, Immediate(27), 0);
  __ movz(R1, Immediate(0), 0);
  __ sdiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Sdiv_zero, test) {
  EXPECT(test != NULL);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Udiv_corner, assembler) {
  __ movz(R0, Immediate(0x8000), 3);  // R0 <- 0x8000000000000000
  __ movn(R1, Immediate(0), 0);       // R1 <- 0xffffffffffffffff
  __ udiv(R2, R0, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Udiv_corner, test) {
  EXPECT(test != NULL);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Sdiv_corner, assembler) {
  __ movz(R3, Immediate(0x8000), 3);  // R0 <- 0x8000000000000000
  __ movn(R1, Immediate(0), 0);       // R1 <- 0xffffffffffffffff
  __ sdiv(R2, R3, R1);
  __ mov(R0, R2);
  __ ret();
}

ASSEMBLER_TEST_RUN(Sdiv_corner, test) {
  EXPECT(test != NULL);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(static_cast<int64_t>(0x8000000000000000),
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
}

// Loading immediate values without the object pool.
ASSEMBLER_TEST_GENERATE(LoadImmediateSmall, assembler) {
  __ LoadImmediate(R0, 42);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateSmall, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMed, assembler) {
  __ LoadImmediate(R0, 0xf1234123);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMed, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0xf1234123, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMed2, assembler) {
  __ LoadImmediate(R0, 0x4321f1234123);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMed2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(0x4321f1234123,
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediateLarge, assembler) {
  __ LoadImmediate(R0, 0x9287436598237465);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateLarge, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(static_cast<int64_t>(0x9287436598237465),
            EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediateSmallNeg, assembler) {
  __ LoadImmediate(R0, -42);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateSmallNeg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg, assembler) {
  __ LoadImmediate(R0, -0x1212341234);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMedNeg, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x1212341234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg2, assembler) {
  __ LoadImmediate(R0, -0x1212340000);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMedNeg2, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x1212340000, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg3, assembler) {
  __ LoadImmediate(R0, -0x1200001234);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMedNeg3, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x1200001234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadImmediateMedNeg4, assembler) {
  __ LoadImmediate(R0, -0x12341234);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadImmediateMedNeg4, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(-0x12341234, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(LoadHalfWordUnaligned, assembler) {
  __ LoadUnaligned(R1, R0, TMP, kHalfword);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadHalfWordUnaligned, test) {
  EXPECT(test != NULL);
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
}

ASSEMBLER_TEST_GENERATE(LoadHalfWordUnsignedUnaligned, assembler) {
  __ LoadUnaligned(R1, R0, TMP, kUnsignedHalfword);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadHalfWordUnsignedUnaligned, test) {
  EXPECT(test != NULL);
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
}

ASSEMBLER_TEST_GENERATE(StoreHalfWordUnaligned, assembler) {
  __ LoadImmediate(R1, 0xABCD);
  __ StoreUnaligned(R1, R0, TMP, kHalfword);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(StoreHalfWordUnaligned, test) {
  EXPECT(test != NULL);
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
}

ASSEMBLER_TEST_GENERATE(LoadWordUnaligned, assembler) {
  __ LoadUnaligned(R1, R0, TMP, kUnsignedWord);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadWordUnaligned, test) {
  EXPECT(test != NULL);
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
}

ASSEMBLER_TEST_GENERATE(StoreWordUnaligned, assembler) {
  __ LoadImmediate(R1, 0x12345678);
  __ StoreUnaligned(R1, R0, TMP, kUnsignedWord);
  __ mov(R0, R1);
  __ ret();
}

ASSEMBLER_TEST_RUN(StoreWordUnaligned, test) {
  EXPECT(test != NULL);
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
}

static void EnterTestFrame(Assembler* assembler) {
  __ EnterFrame(0);
  __ Push(CODE_REG);
  __ Push(THR);
  __ TagAndPushPP();
  __ ldr(CODE_REG, Address(R0, VMHandles::kOffsetOfRawPtrInHandle));
  __ mov(THR, R1);
  __ LoadPoolPointer(PP);
}

static void LeaveTestFrame(Assembler* assembler) {
  __ PopAndUntagPP();
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
  EXPECT_EQ(Object::null(), test->InvokeWithCodeAndThread<RawObject*>());
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
  EXPECT_EQ(Bool::True().raw(), test->InvokeWithCodeAndThread<RawObject*>());
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
  EXPECT_EQ(Bool::False().raw(), test->InvokeWithCodeAndThread<RawObject*>());
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
}

// Floating point move immediate, to/from integer register.
ASSEMBLER_TEST_GENERATE(Fmovdi, assembler) {
  __ LoadDImmediate(V0, 1.0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fmovdi, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(1.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
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
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdPrePostIndex, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V1, 42.0);
  __ fstrd(V1, Address(SP, -1 * kWordSize, Address::PreIndex));
  __ fldrd(V0, Address(SP, 1 * kWordSize, Address::PostIndex));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdPrePostIndex, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FldrsFstrsPrePostIndex, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V1, 42.0);
  __ fcvtsd(V2, V1);
  __ fstrs(V2, Address(SP, -1 * kWordSize, Address::PreIndex));
  __ fldrs(V3, Address(SP, 1 * kWordSize, Address::PostIndex));
  __ fcvtds(V0, V3);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrsFstrsPrePostIndex, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FldrqFstrqPrePostIndex, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V1, 21.0);
  __ LoadDImmediate(V2, 21.0);
  __ LoadImmediate(R1, 42);
  __ Push(R1);
  __ PushDouble(V1);
  __ PushDouble(V2);
  __ fldrq(V3, Address(SP, 2 * kWordSize, Address::PostIndex));
  __ Pop(R0);
  __ fstrq(V3, Address(SP, -2 * kWordSize, Address::PreIndex));
  __ PopDouble(V0);
  __ PopDouble(V1);
  __ faddd(V0, V0, V1);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrqFstrqPrePostIndex, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Fcvtzds, assembler) {
  __ LoadDImmediate(V0, 42.0);
  __ fcvtzds(R0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fcvtzds, test) {
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Scvtfdx, assembler) {
  __ LoadImmediate(R0, 42);
  __ scvtfdx(V0, R0);
  __ ret();
}

ASSEMBLER_TEST_RUN(Scvtfdx, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
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
}

ASSEMBLER_TEST_GENERATE(FabsdPos, assembler) {
  __ LoadDImmediate(V1, 42.0);
  __ fabsd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(FabsdPos, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FabsdNeg, assembler) {
  __ LoadDImmediate(V1, -42.0);
  __ fabsd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(FabsdNeg, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FnegdPos, assembler) {
  __ LoadDImmediate(V1, 42.0);
  __ fnegd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(FnegdPos, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(-42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FnegdNeg, assembler) {
  __ LoadDImmediate(V1, -42.0);
  __ fnegd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(FnegdNeg, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(Fsqrtd, assembler) {
  __ LoadDImmediate(V1, 64.0);
  __ fsqrtd(V0, V1);
  __ ret();
}

ASSEMBLER_TEST_RUN(Fsqrtd, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(8.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
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
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdHeapTag, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 43.0);
  __ LoadDImmediate(V1, 42.0);
  __ AddImmediate(SP, SP, -1 * kWordSize);
  __ add(R2, SP, Operand(1));
  __ fstrd(V1, Address(R2, -1));
  __ fldrd(V0, Address(R2, -1));
  __ AddImmediate(SP, 1 * kWordSize);
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdHeapTag, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdLargeIndex, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 43.0);
  __ LoadDImmediate(V1, 42.0);
  // Largest negative offset that can fit in the signed 9-bit immediate field.
  __ fstrd(V1, Address(SP, -32 * kWordSize, Address::PreIndex));
  // Largest positive kWordSize aligned offset that we can fit.
  __ fldrd(V0, Address(SP, 31 * kWordSize, Address::PostIndex));
  // Correction.
  __ add(SP, SP, Operand(kWordSize));  // Restore SP.
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdLargeIndex, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdLargeOffset, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 43.0);
  __ LoadDImmediate(V1, 42.0);
  __ sub(SP, SP, Operand(512 * kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ fstrd(V1, Address(SP, 512 * kWordSize, Address::Offset));
  __ add(SP, SP, Operand(512 * kWordSize));
  __ fldrd(V0, Address(SP));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdLargeOffset, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
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
  __ sub(SP, SP, Operand(kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  __ fldrd(V0, Address(SP));
  __ add(SP, SP, Operand(kWordSize));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdExtReg, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
}

ASSEMBLER_TEST_GENERATE(FldrdFstrdScaledReg, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 43.0);
  __ LoadDImmediate(V1, 42.0);
  __ movz(R2, Immediate(10), 0);
  __ sub(SP, SP, Operand(10 * kWordSize));
  __ andi(CSP, SP, Immediate(~15));  // Must not access beyond CSP.
  // Store V1 into SP + R2 * kWordSize.
  __ fstrd(V1, Address(SP, R2, UXTX, Address::Scaled));
  __ fldrd(V0, Address(SP, R2, UXTX, Address::Scaled));
  __ add(SP, SP, Operand(10 * kWordSize));
  __ RestoreCSP();
  __ ret();
}

ASSEMBLER_TEST_RUN(FldrdFstrdScaledReg, test) {
  typedef double (*DoubleReturn)() DART_UNUSED;
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry()));
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
  EXPECT(test != NULL);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(174, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
  EXPECT(test != NULL);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(85, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
  EXPECT(test != NULL);
  typedef int64_t (*Int64Return)() DART_UNUSED;
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INT64(Int64Return, test->entry()));
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
}

ASSEMBLER_TEST_GENERATE(Vdupd, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 21.0);
  __ vdupd(V1, V0, 0);

  const int dword_bytes = 1 << Log2OperandSizeBytes(kDWord);
  const int qword_bytes = 1 << Log2OperandSizeBytes(kQWord);
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
}

ASSEMBLER_TEST_GENERATE(Vdups, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 21.0);
  __ fcvtsd(V0, V0);
  __ vdups(V1, V0, 0);

  const int sword_bytes = 1 << Log2OperandSizeBytes(kSWord);
  const int qword_bytes = 1 << Log2OperandSizeBytes(kQWord);
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
}

ASSEMBLER_TEST_GENERATE(Vinsd, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V5, 42.0);
  __ vinsd(V1, 1, V5, 0);  // V1[1] <- V0[0].

  const int dword_bytes = 1 << Log2OperandSizeBytes(kDWord);
  const int qword_bytes = 1 << Log2OperandSizeBytes(kQWord);
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
}

ASSEMBLER_TEST_GENERATE(Vinss, assembler) {
  __ SetupDartSP();
  __ LoadDImmediate(V0, 21.0);
  __ fcvtsd(V0, V0);
  __ vinss(V1, 3, V0, 0);
  __ vinss(V1, 1, V0, 0);

  const int sword_bytes = 1 << Log2OperandSizeBytes(kSWord);
  const int qword_bytes = 1 << Log2OperandSizeBytes(kQWord);
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
  EXPECT(test != NULL);
  typedef double (*DoubleReturn)() DART_UNUSED;
  float res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ(arm_recip_estimate(147.0), res, 0.0001);
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
  EXPECT(test != NULL);
  typedef double (*DoubleReturn)() DART_UNUSED;
  double res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ(2.0 - 10.0 * 5.0, res, 0.0001);
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
  EXPECT(test != NULL);
  typedef double (*DoubleReturn)() DART_UNUSED;
  double res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ(arm_reciprocal_sqrt_estimate(147.0), res, 0.0001);
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
  EXPECT(test != NULL);
  typedef double (*DoubleReturn)() DART_UNUSED;
  double res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ((3.0 - 10.0 * 5.0) / 2.0, res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(ReciprocalSqrt, assembler) {
  __ LoadDImmediate(V1, 147000.0);
  __ fcvtsd(V1, V1);

  __ VRSqrts(V0, V1);

  __ fcvtds(V0, V0);
  __ ret();
}

ASSEMBLER_TEST_RUN(ReciprocalSqrt, test) {
  EXPECT(test != NULL);
  typedef double (*DoubleReturn)() DART_UNUSED;
  double res = EXECUTE_TEST_CODE_DOUBLE(DoubleReturn, test->entry());
  EXPECT_FLOAT_EQ(1.0 / sqrt(147000.0), res, 0.0001);
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
  __ Push(LR);
  __ mov(THR, R2);
  __ StoreIntoObject(R1, FieldAddress(R1, GrowableObjectArray::data_offset()),
                     R0);
  __ Pop(LR);
  __ Pop(THR);
  __ Pop(CODE_REG);
  __ RestoreCSP();
  __ ret();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
