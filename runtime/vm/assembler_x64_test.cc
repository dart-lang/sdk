// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/assembler.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->


ASSEMBLER_TEST_GENERATE(ReadArgument, assembler) {
  __ pushq(CallingConventions::kArg1Reg);
  __ movq(RAX, Address(RSP, 0));
  __ popq(RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(ReadArgument, test) {
  typedef int64_t (*ReadArgumentCode)(int64_t n);
  ReadArgumentCode id = reinterpret_cast<ReadArgumentCode>(test->entry());
  EXPECT_EQ(42, id(42));
  EXPECT_EQ(87, id(87));
  static const int64_t kLargeConstant = 0x1234567812345678LL;
  EXPECT_EQ(kLargeConstant, id(kLargeConstant));
}


ASSEMBLER_TEST_GENERATE(AddressingModes, assembler) {
  __ movq(RAX, Address(RSP, 0));
  __ movq(RAX, Address(RBP, 0));
  __ movq(RAX, Address(RAX, 0));
  __ movq(RAX, Address(R10, 0));
  __ movq(RAX, Address(R12, 0));
  __ movq(RAX, Address(R13, 0));
  __ movq(R10, Address(RAX, 0));

  __ movq(RAX, Address(RSP, kWordSize));
  __ movq(RAX, Address(RBP, kWordSize));
  __ movq(RAX, Address(RAX, kWordSize));
  __ movq(RAX, Address(R10, kWordSize));
  __ movq(RAX, Address(R12, kWordSize));
  __ movq(RAX, Address(R13, kWordSize));

  __ movq(RAX, Address(RSP, -kWordSize));
  __ movq(RAX, Address(RBP, -kWordSize));
  __ movq(RAX, Address(RAX, -kWordSize));
  __ movq(RAX, Address(R10, -kWordSize));
  __ movq(RAX, Address(R12, -kWordSize));
  __ movq(RAX, Address(R13, -kWordSize));

  __ movq(RAX, Address(RSP, 256 * kWordSize));
  __ movq(RAX, Address(RBP, 256 * kWordSize));
  __ movq(RAX, Address(RAX, 256 * kWordSize));
  __ movq(RAX, Address(R10, 256 * kWordSize));
  __ movq(RAX, Address(R12, 256 * kWordSize));
  __ movq(RAX, Address(R13, 256 * kWordSize));

  __ movq(RAX, Address(RSP, -256 * kWordSize));
  __ movq(RAX, Address(RBP, -256 * kWordSize));
  __ movq(RAX, Address(RAX, -256 * kWordSize));
  __ movq(RAX, Address(R10, -256 * kWordSize));
  __ movq(RAX, Address(R12, -256 * kWordSize));
  __ movq(RAX, Address(R13, -256 * kWordSize));

  __ movq(RAX, Address(RAX, TIMES_1, 0));
  __ movq(RAX, Address(RAX, TIMES_2, 0));
  __ movq(RAX, Address(RAX, TIMES_4, 0));
  __ movq(RAX, Address(RAX, TIMES_8, 0));

  __ movq(RAX, Address(RBP, TIMES_2, 0));
  __ movq(RAX, Address(RAX, TIMES_2, 0));
  __ movq(RAX, Address(R10, TIMES_2, 0));
  __ movq(RAX, Address(R12, TIMES_2, 0));
  __ movq(RAX, Address(R13, TIMES_2, 0));

  __ movq(RAX, Address(RBP, TIMES_2, kWordSize));
  __ movq(RAX, Address(RAX, TIMES_2, kWordSize));
  __ movq(RAX, Address(R10, TIMES_2, kWordSize));
  __ movq(RAX, Address(R12, TIMES_2, kWordSize));
  __ movq(RAX, Address(R13, TIMES_2, kWordSize));

  __ movq(RAX, Address(RBP, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RAX, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R10, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R12, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R13, TIMES_2, 256 * kWordSize));

  __ movq(RAX, Address(RAX, RBP, TIMES_2, 0));
  __ movq(RAX, Address(RAX, RAX, TIMES_2, 0));
  __ movq(RAX, Address(RAX, R10, TIMES_2, 0));
  __ movq(RAX, Address(RAX, R12, TIMES_2, 0));
  __ movq(RAX, Address(RAX, R13, TIMES_2, 0));

  __ movq(RAX, Address(RBP, RBP, TIMES_2, 0));
  __ movq(RAX, Address(RBP, RAX, TIMES_2, 0));
  __ movq(RAX, Address(RBP, R10, TIMES_2, 0));
  __ movq(RAX, Address(RBP, R12, TIMES_2, 0));
  __ movq(RAX, Address(RBP, R13, TIMES_2, 0));

  __ movq(RAX, Address(RSP, RBP, TIMES_2, 0));
  __ movq(RAX, Address(RSP, RAX, TIMES_2, 0));
  __ movq(RAX, Address(RSP, R10, TIMES_2, 0));
  __ movq(RAX, Address(RSP, R12, TIMES_2, 0));
  __ movq(RAX, Address(RSP, R13, TIMES_2, 0));

  __ movq(RAX, Address(R10, RBP, TIMES_2, 0));
  __ movq(RAX, Address(R10, RAX, TIMES_2, 0));
  __ movq(RAX, Address(R10, R10, TIMES_2, 0));
  __ movq(RAX, Address(R10, R12, TIMES_2, 0));
  __ movq(RAX, Address(R10, R13, TIMES_2, 0));

  __ movq(RAX, Address(R12, RBP, TIMES_2, 0));
  __ movq(RAX, Address(R12, RAX, TIMES_2, 0));
  __ movq(RAX, Address(R12, R10, TIMES_2, 0));
  __ movq(RAX, Address(R12, R12, TIMES_2, 0));
  __ movq(RAX, Address(R12, R13, TIMES_2, 0));

  __ movq(RAX, Address(R13, RBP, TIMES_2, 0));
  __ movq(RAX, Address(R13, RAX, TIMES_2, 0));
  __ movq(RAX, Address(R13, R10, TIMES_2, 0));
  __ movq(RAX, Address(R13, R12, TIMES_2, 0));
  __ movq(RAX, Address(R13, R13, TIMES_2, 0));

  __ movq(RAX, Address(RAX, RBP, TIMES_2, kWordSize));
  __ movq(RAX, Address(RAX, RAX, TIMES_2, kWordSize));
  __ movq(RAX, Address(RAX, R10, TIMES_2, kWordSize));
  __ movq(RAX, Address(RAX, R12, TIMES_2, kWordSize));
  __ movq(RAX, Address(RAX, R13, TIMES_2, kWordSize));

  __ movq(RAX, Address(RBP, RBP, TIMES_2, kWordSize));
  __ movq(RAX, Address(RBP, RAX, TIMES_2, kWordSize));
  __ movq(RAX, Address(RBP, R10, TIMES_2, kWordSize));
  __ movq(RAX, Address(RBP, R12, TIMES_2, kWordSize));
  __ movq(RAX, Address(RBP, R13, TIMES_2, kWordSize));

  __ movq(RAX, Address(RSP, RBP, TIMES_2, kWordSize));
  __ movq(RAX, Address(RSP, RAX, TIMES_2, kWordSize));
  __ movq(RAX, Address(RSP, R10, TIMES_2, kWordSize));
  __ movq(RAX, Address(RSP, R12, TIMES_2, kWordSize));
  __ movq(RAX, Address(RSP, R13, TIMES_2, kWordSize));

  __ movq(RAX, Address(R10, RBP, TIMES_2, kWordSize));
  __ movq(RAX, Address(R10, RAX, TIMES_2, kWordSize));
  __ movq(RAX, Address(R10, R10, TIMES_2, kWordSize));
  __ movq(RAX, Address(R10, R12, TIMES_2, kWordSize));
  __ movq(RAX, Address(R10, R13, TIMES_2, kWordSize));

  __ movq(RAX, Address(R12, RBP, TIMES_2, kWordSize));
  __ movq(RAX, Address(R12, RAX, TIMES_2, kWordSize));
  __ movq(RAX, Address(R12, R10, TIMES_2, kWordSize));
  __ movq(RAX, Address(R12, R12, TIMES_2, kWordSize));
  __ movq(RAX, Address(R12, R13, TIMES_2, kWordSize));

  __ movq(RAX, Address(R13, RBP, TIMES_2, kWordSize));
  __ movq(RAX, Address(R13, RAX, TIMES_2, kWordSize));
  __ movq(RAX, Address(R13, R10, TIMES_2, kWordSize));
  __ movq(RAX, Address(R13, R12, TIMES_2, kWordSize));
  __ movq(RAX, Address(R13, R13, TIMES_2, kWordSize));

  __ movq(RAX, Address(RAX, RBP, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RAX, RAX, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RAX, R10, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RAX, R12, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RAX, R13, TIMES_2, 256 * kWordSize));

  __ movq(RAX, Address(RBP, RBP, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RBP, RAX, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RBP, R10, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RBP, R12, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RBP, R13, TIMES_2, 256 * kWordSize));

  __ movq(RAX, Address(RSP, RBP, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RSP, RAX, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RSP, R10, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RSP, R12, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(RSP, R13, TIMES_2, 256 * kWordSize));

  __ movq(RAX, Address(R10, RBP, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R10, RAX, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R10, R10, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R10, R12, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R10, R13, TIMES_2, 256 * kWordSize));

  __ movq(RAX, Address(R12, RBP, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R12, RAX, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R12, R10, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R12, R12, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R12, R13, TIMES_2, 256 * kWordSize));

  __ movq(RAX, Address(R13, RBP, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R13, RAX, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R13, R10, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R13, R12, TIMES_2, 256 * kWordSize));
  __ movq(RAX, Address(R13, R13, TIMES_2, 256 * kWordSize));

  __ movq(RAX, Address::AddressBaseImm32(RSP, 0));
  __ movq(RAX, Address::AddressBaseImm32(RBP, 0));
  __ movq(RAX, Address::AddressBaseImm32(RAX, 0));
  __ movq(RAX, Address::AddressBaseImm32(R10, 0));
  __ movq(RAX, Address::AddressBaseImm32(R12, 0));
  __ movq(RAX, Address::AddressBaseImm32(R13, 0));
  __ movq(R10, Address::AddressBaseImm32(RAX, 0));

  __ movq(RAX, Address::AddressBaseImm32(RSP, kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(RBP, kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(RAX, kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R10, kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R12, kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R13, kWordSize));

  __ movq(RAX, Address::AddressBaseImm32(RSP, -kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(RBP, -kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(RAX, -kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R10, -kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R12, -kWordSize));
  __ movq(RAX, Address::AddressBaseImm32(R13, -kWordSize));
}


ASSEMBLER_TEST_RUN(AddressingModes, test) {
  // Avoid running the code since it is constructed to lead to crashes.
}


ASSEMBLER_TEST_GENERATE(JumpAroundCrash, assembler) {
  Label done;
  // Make sure all the condition jumps work.
  for (Condition condition = OVERFLOW;
       condition <= GREATER;
       condition = static_cast<Condition>(condition + 1)) {
    __ j(condition, &done);
  }
  // This isn't strictly necessary, but we do an unconditional
  // jump around the crashing code anyway.
  __ jmp(&done);

  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);

  __ Bind(&done);
  __ ret();
}


ASSEMBLER_TEST_RUN(JumpAroundCrash, test) {
  Instr* instr = Instr::At(test->entry());
  EXPECT(!instr->IsBreakPoint());
  typedef void (*JumpAroundCrashCode)();
  reinterpret_cast<JumpAroundCrashCode>(test->entry())();
}


ASSEMBLER_TEST_GENERATE(SimpleLoop, assembler) {
  __ movq(RAX, Immediate(0));
  __ movq(RCX, Immediate(0));
  Label loop;
  __ Bind(&loop);
  __ addq(RAX, Immediate(2));
  __ incq(RCX);
  __ cmpq(RCX, Immediate(87));
  __ j(LESS, &loop);
  __ ret();
}


ASSEMBLER_TEST_RUN(SimpleLoop, test) {
  typedef int (*SimpleLoopCode)();
  EXPECT_EQ(2 * 87, reinterpret_cast<SimpleLoopCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(Cmpb, assembler) {
  Label done;
  __ movq(RAX, Immediate(1));
  __ pushq(Immediate(0xffffff11));
  __ cmpb(Address(RSP, 0), Immediate(0x11));
  __ j(EQUAL, &done, Assembler::kNearJump);
  __ movq(RAX, Immediate(0));
  __ Bind(&done);
  __ popq(RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Cmpb, test) {
  typedef int (*CmpbCode)();
  EXPECT_EQ(1, reinterpret_cast<CmpbCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(Increment, assembler) {
  __ movq(RAX, Immediate(0));
  __ pushq(RAX);
  __ incl(Address(RSP, 0));
  __ incq(Address(RSP, 0));
  __ movq(RCX, Address(RSP, 0));
  __ incq(RCX);
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Increment, test) {
  typedef int (*IncrementCode)();
  EXPECT_EQ(3, reinterpret_cast<IncrementCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(IncrementLong, assembler) {
  __ movq(RAX, Immediate(0xffffffff));
  __ pushq(RAX);
  __ incq(Address(RSP, 0));
  __ movq(RCX, Address(RSP, 0));
  __ incq(RCX);
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(IncrementLong, test) {
  typedef int64_t (*IncrementCodeLong)();
  EXPECT_EQ(0x100000001, reinterpret_cast<IncrementCodeLong>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(Decrement, assembler) {
  __ movq(RAX, Immediate(3));
  __ pushq(RAX);
  __ decl(Address(RSP, 0));
  __ decq(Address(RSP, 0));
  __ movq(RCX, Address(RSP, 0));
  __ decq(RCX);
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Decrement, test) {
  typedef int (*DecrementCode)();
  EXPECT_EQ(0, reinterpret_cast<DecrementCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(DecrementLong, assembler) {
  __ movq(RAX, Immediate(0x100000001));
  __ pushq(RAX);
  __ decq(Address(RSP, 0));
  __ movq(RCX, Address(RSP, 0));
  __ decq(RCX);
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(DecrementLong, test) {
  typedef int64_t (*DecrementCodeLong)();
  EXPECT_EQ(0xffffffff, reinterpret_cast<DecrementCodeLong>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(SignedMultiply, assembler) {
  __ movl(RAX, Immediate(2));
  __ movl(RCX, Immediate(4));
  __ imull(RAX, RCX);
  __ imull(RAX, Immediate(1000));
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiply, test) {
  typedef int (*SignedMultiply)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(UnsignedMultiply, assembler) {
  __ movl(RAX, Immediate(-1));  // RAX = 0xFFFFFFFF
  __ movl(RCX, Immediate(16));  // RCX = 0x10
  __ mull(RCX);  // RDX:RAX = RAX * RCX = 0x0FFFFFFFF0
  __ movq(RAX, RDX);  // Return high32(0x0FFFFFFFF0) == 0x0F
  __ ret();
}


ASSEMBLER_TEST_RUN(UnsignedMultiply, test) {
  typedef int (*UnsignedMultiply)();
  EXPECT_EQ(15, reinterpret_cast<UnsignedMultiply>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(SignedMultiply64, assembler) {
  __ pushq(R15);  // Callee saved.
  __ movq(RAX, Immediate(2));
  __ movq(RCX, Immediate(4));
  __ imulq(RAX, RCX);

  __ movq(R8, Immediate(2));
  __ movq(R9, Immediate(4));
  __ pushq(R9);
  __ imulq(R8, Address(RSP, 0));
  __ popq(R9);
  __ addq(RAX, R8);

  __ movq(R10, Immediate(2));
  __ movq(R11, Immediate(4));
  __ imulq(R10, R11);
  __ addq(RAX, R10);

  __ movq(R15, Immediate(2));
  __ imulq(R15, Immediate(4));
  __ addq(RAX, R15);
  __ popq(R15);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiply64, test) {
  typedef int64_t (*SignedMultiply64)();
  EXPECT_EQ(32, reinterpret_cast<SignedMultiply64>(test->entry())());
}


static const int64_t kLargeConstant = 0x1234567887654321;
static const int64_t kAnotherLargeConstant = 987654321987654321LL;
static const int64_t kProductLargeConstants = 0x5bbb29a7f52fbbd1;


ASSEMBLER_TEST_GENERATE(SignedMultiplyLong, assembler) {
  Label done;
  __ movq(RAX, Immediate(kLargeConstant));
  __ movq(RCX, Immediate(kAnotherLargeConstant));
  __ imulq(RAX, RCX);
  __ imulq(RCX, Immediate(kLargeConstant));
  __ cmpq(RAX, RCX);
  __ j(EQUAL, &done);
  __ int3();
  __ Bind(&done);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiplyLong, test) {
  typedef int64_t (*SignedMultiplyLong)();
  EXPECT_EQ(kProductLargeConstants,
            reinterpret_cast<SignedMultiplyLong>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(OverflowSignedMultiply, assembler) {
  __ movl(RDX, Immediate(0));
  __ movl(RAX, Immediate(0x0fffffff));
  __ movl(RCX, Immediate(0x0fffffff));
  __ imull(RAX, RCX);
  __ imull(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(OverflowSignedMultiply, test) {
  typedef int (*OverflowSignedMultiply)();
  EXPECT_EQ(0, reinterpret_cast<OverflowSignedMultiply>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(SignedMultiply1, assembler) {
  __ movl(RDX, Immediate(2));
  __ movl(RCX, Immediate(4));
  __ imull(RDX, RCX);
  __ imull(RDX, Immediate(1000));
  __ movl(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiply1, test) {
  typedef int (*SignedMultiply1)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply1>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(SignedMultiply2, assembler) {
  __ pushq(R15);  // Callee saved.
  __ movl(R15, Immediate(2));
  __ imull(R15, Immediate(1000));
  __ movl(RAX, R15);
  __ popq(R15);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiply2, test) {
  typedef int (*SignedMultiply2)();
  EXPECT_EQ(2000, reinterpret_cast<SignedMultiply2>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(SignedDivide, assembler) {
  __ movl(RAX, Immediate(-87));
  __ movl(RDX, Immediate(123));
  __ cdq();
  __ movl(RCX, Immediate(42));
  __ idivl(RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedDivide, test) {
  typedef int32_t (*SignedDivide)();
  EXPECT_EQ(-87 / 42, reinterpret_cast<SignedDivide>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(UnsignedDivide, assembler) {
  const int32_t low = 0;
  const int32_t high = 0xf0000000;
  const int32_t divisor = 0xffffffff;
  __ movl(RAX, Immediate(low));
  __ movl(RDX, Immediate(high));
  __ movl(RCX, Immediate(divisor));
  __ divl(RCX);  // RAX = RDX:RAX / RCX =
                 //     = 0xf000000000000000 / 0xffffffff = 0xf0000000
  __ ret();
}


ASSEMBLER_TEST_RUN(UnsignedDivide, test) {
  typedef uint32_t (*UnsignedDivide)();
  EXPECT_EQ(0xf0000000, reinterpret_cast<UnsignedDivide>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(SignedDivideLong, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ movq(RDX, Immediate(123));
  __ cqo();  // Clear RDX.
  __ movq(RCX, Immediate(42));
  __ idivq(RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedDivideLong, test) {
  typedef int64_t (*SignedDivideLong)();
  EXPECT_EQ(kLargeConstant / 42,
            reinterpret_cast<SignedDivideLong>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(Negate, assembler) {
  __ movl(RCX, Immediate(42));
  __ negl(RCX);
  __ movl(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Negate, test) {
  typedef int (*Negate)();
  EXPECT_EQ(-42, reinterpret_cast<Negate>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(MoveExtend, assembler) {
  __ movq(RDX, Immediate(0xffff));
  __ movzxb(RAX, RDX);  // RAX = 0xff
  __ movsxw(R8, RDX);   // R8 = -1
  __ movzxw(RCX, RDX);  // RCX = 0xffff
  __ addq(R8, RCX);
  __ addq(RAX, R8);
  __ ret();
}


ASSEMBLER_TEST_RUN(MoveExtend, test) {
  typedef int (*MoveExtend)();
  EXPECT_EQ(0xff - 1 + 0xffff, reinterpret_cast<MoveExtend>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(MoveExtend32, assembler) {
  __ movq(RDX, Immediate(0xffffffff));
  __ movsxd(RDX, RDX);
  __ movq(RAX, Immediate(0x7fffffff));
  __ movsxd(RAX, RAX);
  __ addq(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(MoveExtend32, test) {
  typedef intptr_t (*MoveExtend)();
  EXPECT_EQ(0x7ffffffe, reinterpret_cast<MoveExtend>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(MoveExtendMemory, assembler) {
  __ movq(RDX, Immediate(0x123456781234ffff));

  __ pushq(RDX);
  __ movzxb(RAX, Address(RSP, 0));  // RAX = 0xff
  __ movsxw(R8, Address(RSP, 0));   // R8 = -1
  __ movzxw(RCX, Address(RSP, 0));  // RCX = 0xffff
  __ addq(RSP, Immediate(kWordSize));

  __ addq(R8, RCX);
  __ addq(RAX, R8);
  __ ret();
}


ASSEMBLER_TEST_RUN(MoveExtendMemory, test) {
  typedef int (*MoveExtendMemory)();
  EXPECT_EQ(0xff - 1 + 0xffff,
            reinterpret_cast<MoveExtendMemory>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(MoveExtend32Memory, assembler) {
  __ pushq(Immediate(0xffffffff));
  __ pushq(Immediate(0x7fffffff));
  __ movsxd(RDX, Address(RSP, kWordSize));
  __ movsxd(RAX, Address(RSP, 0));
  __ addq(RSP, Immediate(kWordSize * 2));

  __ addq(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(MoveExtend32Memory, test) {
  typedef intptr_t (*MoveExtend)();
  EXPECT_EQ(0x7ffffffe, reinterpret_cast<MoveExtend>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(MoveWord, assembler) {
  __ xorq(RAX, RAX);
  __ pushq(Immediate(0));
  __ movq(RAX, RSP);
  __ movq(RCX, Immediate(-1));
  __ movw(Address(RAX, 0), RCX);
  __ movzxw(RAX, Address(RAX, 0));  // RAX = 0xffff
  __ addq(RSP, Immediate(kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(MoveWord, test) {
  typedef int (*MoveWord)();
  EXPECT_EQ(0xffff, reinterpret_cast<MoveWord>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(MoveWordRex, assembler) {
  __ pushq(Immediate(0));
  __ movq(R8, RSP);
  __ movq(R9, Immediate(-1));
  __ movw(Address(R8, 0), R9);
  __ movzxw(R8, Address(R8, 0));  // 0xffff
  __ xorq(RAX, RAX);
  __ addq(RAX, R8);  // RAX = 0xffff
  __ addq(RSP, Immediate(kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(MoveWordRex, test) {
  typedef int (*MoveWordRex)();
  EXPECT_EQ(0xffff, reinterpret_cast<MoveWordRex>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(LongAddReg, assembler) {
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Address(RSP, 0));  // left low.
  __ movl(RDX, Address(RSP, 4));  // left high.
  __ movl(RCX, Address(RSP, 8));  // right low.
  __ movl(R8, Address(RSP, 12));  // right high
  __ addl(RAX, RCX);
  __ adcl(RDX, R8);
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ popq(RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(LongAddReg, test) {
  typedef int64_t (*LongAddRegCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongAddRegCode>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
  a = 2147483647;
  b = 600000;
  res = reinterpret_cast<LongAddRegCode>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
}


ASSEMBLER_TEST_GENERATE(LongAddAddress, assembler) {
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Address(RSP, 0));  // left low.
  __ movl(RDX, Address(RSP, 4));  // left high.
  __ addl(RAX, Address(RSP, 8));  // low.
  __ adcl(RDX, Address(RSP, 12));  // high.
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ popq(RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(LongAddAddress, test) {
  typedef int64_t (*LongAddAddressCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongAddAddressCode>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
  a = 2147483647;
  b = 600000;
  res = reinterpret_cast<LongAddAddressCode>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
}


ASSEMBLER_TEST_GENERATE(LongSubReg, assembler) {
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Address(RSP, 0));  // left low.
  __ movl(RDX, Address(RSP, 4));  // left high.
  __ movl(RCX, Address(RSP, 8));  // right low.
  __ movl(R8, Address(RSP, 12));  // right high
  __ subl(RAX, RCX);
  __ sbbl(RDX, R8);
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ popq(RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(LongSubReg, test) {
  typedef int64_t (*LongSubRegCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongSubRegCode>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
  a = 600000;
  b = 2147483647;
  res = reinterpret_cast<LongSubRegCode>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
}


ASSEMBLER_TEST_GENERATE(LongSubAddress, assembler) {
  __ pushq(CallingConventions::kArg2Reg);
  __ pushq(CallingConventions::kArg1Reg);
  __ movl(RAX, Address(RSP, 0));  // left low.
  __ movl(RDX, Address(RSP, 4));  // left high.
  __ subl(RAX, Address(RSP, 8));  // low.
  __ sbbl(RDX, Address(RSP, 12));  // high.
  // Result is in RAX/RDX.
  __ movl(Address(RSP, 0), RAX);  // result low.
  __ movl(Address(RSP, 4), RDX);  // result high.
  __ popq(RAX);
  __ popq(RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(LongSubAddress, test) {
  typedef int64_t (*LongSubAddressCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongSubAddressCode>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
  a = 600000;
  b = 2147483647;
  res = reinterpret_cast<LongSubAddressCode>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
}


ASSEMBLER_TEST_GENERATE(Bitwise, assembler) {
  __ movl(RCX, Immediate(42));
  __ xorl(RCX, RCX);
  __ orl(RCX, Immediate(256));
  __ movl(RAX, Immediate(4));
  __ orl(RCX, RAX);
  __ movl(RAX, Immediate(0xfff0));
  __ andl(RCX, RAX);
  __ movl(RAX, Immediate(1));
  __ orl(RCX, RAX);
  __ movl(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Bitwise, test) {
  typedef int (*Bitwise)();
  EXPECT_EQ(256 + 1, reinterpret_cast<Bitwise>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(Bitwise64, assembler) {
  Label error;
  __ movq(RAX, Immediate(42));
  __ pushq(RAX);
  __ xorq(RAX, Address(RSP, 0));
  __ popq(RCX);
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &error);
  __ movq(RCX, Immediate(0xFF));
  __ movq(RAX, Immediate(0x5));
  __ xorq(RCX, RAX);
  __ cmpq(RCX, Immediate(0xFF ^ 0x5));
  __ j(NOT_EQUAL, &error);
  __ pushq(Immediate(0xFF));
  __ movq(RCX, Immediate(0x5));
  __ xorq(Address(RSP, 0), RCX);
  __ popq(RCX);
  __ cmpq(RCX, Immediate(0xFF ^ 0x5));
  __ j(NOT_EQUAL, &error);
  __ xorq(RCX, RCX);
  __ orq(RCX, Immediate(256));
  __ movq(RAX, Immediate(4));
  __ orq(RCX, RAX);
  __ movq(RAX, Immediate(0xfff0));
  __ andq(RCX, RAX);
  __ movq(RAX, Immediate(1));
  __ pushq(RAX);
  __ orq(RCX, Address(RSP, 0));
  __ xorq(RCX, Immediate(0));
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
  __ Bind(&error);
  __ movq(RAX, Immediate(-1));
  __ ret();
}


ASSEMBLER_TEST_RUN(Bitwise64, test) {
  typedef int (*Bitwise64)();
  EXPECT_EQ(256 + 1, reinterpret_cast<Bitwise64>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(LogicalOps, assembler) {
  Label donetest1;
  __ movl(RAX, Immediate(4));
  __ andl(RAX, Immediate(2));
  __ cmpl(RAX, Immediate(0));
  __ j(EQUAL, &donetest1);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest1);

  Label donetest2;
  __ movl(RCX, Immediate(4));
  __ andl(RCX, Immediate(4));
  __ cmpl(RCX, Immediate(0));
  __ j(NOT_EQUAL, &donetest2);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest2);

  Label donetest3;
  __ movl(RAX, Immediate(0));
  __ orl(RAX, Immediate(0));
  __ cmpl(RAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest3);

  Label donetest4;
  __ movl(RAX, Immediate(4));
  __ orl(RAX, Immediate(0));
  __ cmpl(RAX, Immediate(0));
  __ j(NOT_EQUAL, &donetest4);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest4);

  Label donetest5;
  __ pushq(RAX);
  __ movl(RAX, Immediate(0xff));
  __ movl(Address(RSP, 0), RAX);
  __ cmpl(Address(RSP, 0), Immediate(0xff));
  __ j(EQUAL, &donetest5);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest5);
  __ popq(RAX);

  Label donetest6;
  __ movl(RAX, Immediate(1));
  __ shll(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(8));
  __ j(EQUAL, &donetest6);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest6);

  Label donetest7;
  __ movl(RAX, Immediate(2));
  __ shrl(RAX, Immediate(1));
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest7);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest7);

  Label donetest8;
  __ movl(RAX, Immediate(8));
  __ shrl(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest8);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest8);

  Label donetest9;
  __ movl(RAX, Immediate(1));
  __ movl(RCX, Immediate(3));
  __ shll(RAX, RCX);
  __ cmpl(RAX, Immediate(8));
  __ j(EQUAL, &donetest9);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest9);

  Label donetest10;
  __ movl(RAX, Immediate(8));
  __ movl(RCX, Immediate(3));
  __ shrl(RAX, RCX);
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest10);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest10);

  Label donetest6a;
  __ movl(RAX, Immediate(1));
  __ shlq(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(8));
  __ j(EQUAL, &donetest6a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest6a);

  Label donetest7a;
  __ movl(RAX, Immediate(2));
  __ shrq(RAX, Immediate(1));
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest7a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest7a);

  Label donetest8a;
  __ movl(RAX, Immediate(8));
  __ shrq(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest8a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest8a);

  Label donetest9a;
  __ movl(RAX, Immediate(1));
  __ movl(RCX, Immediate(3));
  __ shlq(RAX, RCX);
  __ cmpl(RAX, Immediate(8));
  __ j(EQUAL, &donetest9a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest9a);

  Label donetest10a;
  __ movl(RAX, Immediate(8));
  __ movl(RCX, Immediate(3));
  __ shrq(RAX, RCX);
  __ cmpl(RAX, Immediate(1));
  __ j(EQUAL, &donetest10a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest10a);

  Label donetest11a;
  __ movl(RAX, Immediate(1));
  __ shlq(RAX, Immediate(31));
  __ shrq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(0x10000000));
  __ j(EQUAL, &donetest11a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest11a);

  Label donetest12a;
  __ movl(RAX, Immediate(1));
  __ shlq(RAX, Immediate(31));
  __ sarl(RAX, Immediate(3));
  __ cmpl(RAX, Immediate(0xfffffffff0000000));
  __ j(EQUAL, &donetest12a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest12a);

  Label donetest13a;
  __ movl(RAX, Immediate(1));
  __ movl(RCX, Immediate(3));
  __ shlq(RAX, Immediate(31));
  __ sarl(RAX, RCX);
  __ cmpl(RAX, Immediate(0xfffffffff0000000));
  __ j(EQUAL, &donetest13a);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest13a);

  Label donetest15a;
  const int32_t left = 0xff000000;
  const int32_t right = 0xffffffff;
  const int32_t shifted = 0xf0000003;
  __ movl(RDX, Immediate(left));
  __ movl(RAX, Immediate(right));
  __ movl(RCX, Immediate(2));
  __ shll(RDX, RCX);  // RDX = 0xff000000 << 2 == 0xfc000000
  __ shldl(RDX, RAX, Immediate(2));  // RDX = high32(0xfc000000:0xffffffff << 2)
                                     //     = 0xf0000003
  __ cmpl(RDX, Immediate(shifted));
  __ j(EQUAL, &donetest15a);
  __ int3();
  __ Bind(&donetest15a);

  __ movl(RAX, Immediate(0));
  __ ret();
}


ASSEMBLER_TEST_RUN(LogicalOps, test) {
  typedef int (*LogicalOpsCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalOpsCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(LogicalOps64, assembler) {
  Label donetest1;
  __ movq(RAX, Immediate(4));
  __ andq(RAX, Immediate(2));
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &donetest1);
  __ int3();
  __ Bind(&donetest1);

  Label donetest2;
  __ movq(RCX, Immediate(4));
  __ pushq(RCX);
  __ andq(RCX, Address(RSP, 0));
  __ popq(RAX);
  __ cmpq(RCX, Immediate(0));
  __ j(NOT_EQUAL, &donetest2);
  __ int3();
  __ Bind(&donetest2);

  Label donetest3;
  __ movq(RAX, Immediate(0));
  __ orq(RAX, Immediate(0));
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  __ int3();
  __ Bind(&donetest3);

  Label donetest4;
  __ movq(RAX, Immediate(4));
  __ orq(RAX, Immediate(0));
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &donetest4);
  __ int3();
  __ Bind(&donetest4);

  Label donetest5;
  __ pushq(RAX);
  __ movq(RAX, Immediate(0xff));
  __ movq(Address(RSP, 0), RAX);
  __ cmpq(Address(RSP, 0), Immediate(0xff));
  __ j(EQUAL, &donetest5);
  __ int3();
  __ Bind(&donetest5);
  __ popq(RAX);

  Label donetest6;
  __ movq(RAX, Immediate(1));
  __ shlq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(8));
  __ j(EQUAL, &donetest6);
  __ int3();
  __ Bind(&donetest6);

  Label donetest7;
  __ movq(RAX, Immediate(2));
  __ shrq(RAX, Immediate(1));
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest7);
  __ int3();
  __ Bind(&donetest7);

  Label donetest8;
  __ movq(RAX, Immediate(8));
  __ shrq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest8);
  __ int3();
  __ Bind(&donetest8);

  Label donetest9;
  __ movq(RAX, Immediate(1));
  __ movq(RCX, Immediate(3));
  __ shlq(RAX, RCX);
  __ cmpq(RAX, Immediate(8));
  __ j(EQUAL, &donetest9);
  __ int3();
  __ Bind(&donetest9);

  Label donetest10;
  __ movq(RAX, Immediate(8));
  __ movq(RCX, Immediate(3));
  __ shrq(RAX, RCX);
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest10);
  __ int3();
  __ Bind(&donetest10);

  Label donetest6a;
  __ movq(RAX, Immediate(1));
  __ shlq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(8));
  __ j(EQUAL, &donetest6a);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest6a);

  Label donetest7a;
  __ movq(RAX, Immediate(2));
  __ shrq(RAX, Immediate(1));
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest7a);
  __ int3();
  __ Bind(&donetest7a);

  Label donetest8a;
  __ movq(RAX, Immediate(8));
  __ shrq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest8a);
  __ int3();
  __ Bind(&donetest8a);

  Label donetest9a;
  __ movq(RAX, Immediate(1));
  __ movq(RCX, Immediate(3));
  __ shlq(RAX, RCX);
  __ cmpq(RAX, Immediate(8));
  __ j(EQUAL, &donetest9a);
  __ int3();
  __ Bind(&donetest9a);

  Label donetest10a;
  __ movq(RAX, Immediate(8));
  __ movq(RCX, Immediate(3));
  __ shrq(RAX, RCX);
  __ cmpq(RAX, Immediate(1));
  __ j(EQUAL, &donetest10a);
  __ int3();
  __ Bind(&donetest10a);

  Label donetest11a;
  __ movq(RAX, Immediate(1));
  __ shlq(RAX, Immediate(31));
  __ shrq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(0x10000000));
  __ j(EQUAL, &donetest11a);
  __ int3();
  __ Bind(&donetest11a);

  Label donetest12a;
  __ movq(RAX, Immediate(1));
  __ shlq(RAX, Immediate(63));
  __ sarq(RAX, Immediate(3));
  __ cmpq(RAX, Immediate(0xf000000000000000));
  __ j(EQUAL, &donetest12a);
  __ int3();
  __ Bind(&donetest12a);

  Label donetest13a;
  __ movq(RAX, Immediate(1));
  __ movq(RCX, Immediate(3));
  __ shlq(RAX, Immediate(63));
  __ sarq(RAX, RCX);
  __ cmpq(RAX, Immediate(0xf000000000000000));
  __ j(EQUAL, &donetest13a);
  __ int3();
  __ Bind(&donetest13a);

  Label donetest14, donetest15;
  __ pushq(R15);  // Callee saved.
  __ movq(R15, Immediate(0xf000000000000001));
  __ andq(R15, Immediate(-1));
  __ andq(R15, Immediate(0x8000000000000001));
  __ orq(R15, Immediate(2));
  __ orq(R15, Immediate(0xf800000000000000));
  __ xorq(R15, Immediate(1));
  __ xorq(R15, Immediate(0x0800000000000000));
  __ cmpq(R15, Immediate(0xf000000000000002));
  __ j(EQUAL, &donetest14);
  __ int3();
  __ Bind(&donetest14);
  __ andq(R15, Immediate(2));
  __ cmpq(R15, Immediate(2));
  __ j(EQUAL, &donetest15);
  __ int3();
  __ Bind(&donetest15);
  __ popq(R15);  // Callee saved.

  __ movq(RAX, Immediate(0));
  __ ret();
}


ASSEMBLER_TEST_RUN(LogicalOps64, test) {
  typedef int (*LogicalOpsCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalOpsCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(LogicalTestL, assembler) {
  Label donetest1;
  __ movl(RAX, Immediate(4));
  __ movl(RCX, Immediate(2));
  __ testl(RAX, RCX);
  __ j(EQUAL, &donetest1);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest1);

  Label donetest2;
  __ movl(RDX, Immediate(4));
  __ movl(RCX, Immediate(4));
  __ testl(RDX, RCX);
  __ j(NOT_EQUAL, &donetest2);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest2);

  Label donetest3;
  __ movl(RAX, Immediate(0));
  __ testl(RAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest3);

  Label donetest4;
  __ movl(RCX, Immediate(4));
  __ testl(RCX, Immediate(4));
  __ j(NOT_EQUAL, &donetest4);
  // Be sure to skip this crashing code.
  __ movl(RAX, Immediate(0));
  __ movl(Address(RAX, 0), RAX);
  __ Bind(&donetest4);

  __ movl(RAX, Immediate(0));
  __ ret();
}


ASSEMBLER_TEST_RUN(LogicalTestL, test) {
  typedef int (*LogicalTestCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalTestCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(LogicalTestQ, assembler) {
  Label donetest1;
  __ movq(RAX, Immediate(4));
  __ movq(RCX, Immediate(2));
  __ testq(RAX, RCX);
  __ j(EQUAL, &donetest1);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest1);

  Label donetest2;
  __ movq(RDX, Immediate(4));
  __ movq(RCX, Immediate(4));
  __ testq(RDX, RCX);
  __ j(NOT_EQUAL, &donetest2);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest2);

  Label donetest3;
  __ movq(RAX, Immediate(0));
  __ testq(RAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest3);

  Label donetest4;
  __ movq(RCX, Immediate(4));
  __ testq(RCX, Immediate(4));
  __ j(NOT_EQUAL, &donetest4);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest4);

  Label donetest5;
  __ movq(RCX, Immediate(0xff));
  __ testq(RCX, Immediate(0xff));
  __ j(NOT_EQUAL, &donetest5);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest5);

  Label donetest6;
  __ movq(RAX, Immediate(0xff));
  __ testq(RAX, Immediate(0xff));
  __ j(NOT_EQUAL, &donetest6);
  // Be sure to skip this crashing code.
  __ movq(RAX, Immediate(0));
  __ movq(Address(RAX, 0), RAX);
  __ Bind(&donetest6);

  __ movq(RAX, Immediate(0));
  __ ret();
}


ASSEMBLER_TEST_RUN(LogicalTestQ, test) {
  typedef int (*LogicalTestCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalTestCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(CompareSwapEQ, assembler) {
  __ movq(RAX, Immediate(0));
  __ pushq(RAX);
  __ movq(RAX, Immediate(4));
  __ movq(RCX, Immediate(0));
  __ movq(Address(RSP, 0), RAX);
  __ lock_cmpxchgq(Address(RSP, 0), RCX);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(CompareSwapEQ, test) {
  typedef int (*CompareSwapEQCode)();
  EXPECT_EQ(0, reinterpret_cast<CompareSwapEQCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(CompareSwapNEQ, assembler) {
  __ movq(RAX, Immediate(0));
  __ pushq(RAX);
  __ movq(RAX, Immediate(2));
  __ movq(RCX, Immediate(4));
  __ movq(Address(RSP, 0), RCX);
  __ lock_cmpxchgq(Address(RSP, 0), RCX);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(CompareSwapNEQ, test) {
  typedef int (*CompareSwapNEQCode)();
  EXPECT_EQ(4, reinterpret_cast<CompareSwapNEQCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(Exchange, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ movq(RDX, Immediate(kAnotherLargeConstant));
  __ xchgq(RAX, RDX);
  __ subq(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Exchange, test) {
  typedef int64_t (*Exchange)();
  EXPECT_EQ(kAnotherLargeConstant - kLargeConstant,
            reinterpret_cast<Exchange>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(LargeConstant, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ ret();
}


ASSEMBLER_TEST_RUN(LargeConstant, test) {
  typedef int64_t (*LargeConstantCode)();
  EXPECT_EQ(kLargeConstant,
            reinterpret_cast<LargeConstantCode>(test->entry())());
}


static int ComputeStackSpaceReservation(int needed, int fixed) {
  return (OS::ActivationFrameAlignment() > 1)
      ? Utils::RoundUp(needed + fixed, OS::ActivationFrameAlignment()) - fixed
      : needed;
}


static int LeafReturn42() {
  return 42;
}


static int LeafReturnArgument(int x) {
  return x + 87;
}


ASSEMBLER_TEST_GENERATE(CallSimpleLeaf, assembler) {
  ExternalLabel call1(reinterpret_cast<uword>(LeafReturn42));
  ExternalLabel call2(reinterpret_cast<uword>(LeafReturnArgument));
  int space = ComputeStackSpaceReservation(0, 8);
  __ subq(RSP, Immediate(space));
  __ call(&call1);
  __ addq(RSP, Immediate(space));
  space = ComputeStackSpaceReservation(0, 8);
  __ subq(RSP, Immediate(space));
  __ movl(CallingConventions::kArg1Reg, RAX);
  __ call(&call2);
  __ addq(RSP, Immediate(space));
  __ ret();
}


ASSEMBLER_TEST_RUN(CallSimpleLeaf, test) {
  typedef int (*CallSimpleLeafCode)();
  EXPECT_EQ(42 + 87, reinterpret_cast<CallSimpleLeafCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(JumpSimpleLeaf, assembler) {
  ExternalLabel call1(reinterpret_cast<uword>(LeafReturn42));
  Label L;
  int space = ComputeStackSpaceReservation(0, 8);
  __ subq(RSP, Immediate(space));
  __ call(&L);
  __ addq(RSP, Immediate(space));
  __ ret();
  __ Bind(&L);
  __ jmp(&call1);
}


ASSEMBLER_TEST_RUN(JumpSimpleLeaf, test) {
  typedef int (*JumpSimpleLeafCode)();
  EXPECT_EQ(42, reinterpret_cast<JumpSimpleLeafCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(SingleFPMoves, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(234.0f)));
  __ movd(XMM0, RAX);
  __ movss(XMM1, XMM0);
  __ movss(XMM2, XMM1);
  __ movss(XMM3, XMM2);
  __ movss(XMM4, XMM3);
  __ movss(XMM5, XMM4);
  __ movss(XMM6, XMM5);
  __ movss(XMM7, XMM6);
  __ movss(XMM8, XMM7);
  __ movss(XMM9, XMM8);
  __ movss(XMM10, XMM9);
  __ movss(XMM11, XMM10);
  __ movss(XMM12, XMM11);
  __ movss(XMM13, XMM12);
  __ movss(XMM14, XMM13);
  __ movss(XMM15, XMM14);
  __ pushq(R15);  // Callee saved.
  __ pushq(RAX);
  __ movq(Address(RSP, 0), Immediate(0));
  __ movss(XMM0, Address(RSP, 0));
  __ movss(Address(RSP, 0), XMM7);
  __ movss(XMM1, Address(RSP, 0));
  __ movq(R10, RSP);
  __ movss(Address(R10, 0), XMM1);
  __ movss(XMM2, Address(R10, 0));
  __ movq(R15, RSP);
  __ movss(Address(R15, 0), XMM2);
  __ movss(XMM3, Address(R15, 0));
  __ movq(RAX, RSP);
  __ movss(Address(RAX, 0), XMM3);
  __ movss(XMM1, Address(RAX, 0));
  __ movss(XMM15, Address(RAX, 0));
  __ movss(XMM14, XMM15);
  __ movss(XMM13, XMM14);
  __ movss(XMM12, XMM13);
  __ movss(XMM11, XMM12);
  __ movss(XMM10, XMM11);
  __ movss(XMM9, XMM10);
  __ movss(XMM8, XMM9);
  __ movss(XMM7, XMM8);
  __ movss(XMM6, XMM7);
  __ movss(XMM5, XMM6);
  __ movss(XMM4, XMM5);
  __ movss(XMM3, XMM4);
  __ movss(XMM2, XMM3);
  __ movss(XMM1, XMM2);
  __ movss(XMM0, XMM1);
  __ popq(RAX);
  __ popq(R15);  // Callee saved.
  __ ret();
}


ASSEMBLER_TEST_RUN(SingleFPMoves, test) {
  typedef float (*SingleFPMovesCode)();
  EXPECT_EQ(234, reinterpret_cast<SingleFPMovesCode>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(SingleFPMoves2, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(234.0f)));
  __ movd(XMM0, RAX);
  __ movd(XMM8, RAX);
  __ movss(XMM1, XMM8);
  __ pushq(RAX);
  __ movq(Address(RSP, 0), Immediate(0));
  __ movss(XMM0, Address(RSP, 0));
  __ movss(Address(RSP, 0), XMM1);
  __ movss(XMM0, Address(RSP, 0));
  __ movq(Address(RSP, 0), Immediate(0));
  __ movss(XMM9, XMM8);
  __ movss(Address(RSP, 0), XMM9);
  __ movss(XMM8, Address(RSP, 0));
  __ movss(XMM0, XMM8);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SingleFPMoves2, test) {
  typedef float (*SingleFPMoves2Code)();
  EXPECT_EQ(234, reinterpret_cast<SingleFPMoves2Code>(test->entry())());
}


ASSEMBLER_TEST_GENERATE(PackedDoubleAdd, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 1.0, 2.0 };
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = { 3.0, 4.0 };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ addpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleAdd, test) {
  typedef double (*PackedDoubleAdd)();
  double res = reinterpret_cast<PackedDoubleAdd>(test->entry())();
  EXPECT_FLOAT_EQ(4.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleSub, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 1.0, 2.0 };
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = { 3.0, 4.0 };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ subpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleSub, test) {
  typedef double (*PackedDoubleSub)();
  double res = reinterpret_cast<PackedDoubleSub>(test->entry())();
  EXPECT_FLOAT_EQ(-2.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleNegate, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 1.0, 2.0 };
  __ pushq(PP);  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ negatepd(XMM10);
  __ movaps(XMM0, XMM10);
  __ popq(PP);  // Restore caller's pool pointer.
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleNegate, test) {
  typedef double (*PackedDoubleNegate)();
  double res = reinterpret_cast<PackedDoubleNegate>(test->entry())();
  EXPECT_FLOAT_EQ(-1.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleAbsolute, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { -1.0, 2.0 };
  __ pushq(PP);  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ abspd(XMM10);
  __ movaps(XMM0, XMM10);
  __ popq(PP);  // Restore caller's pool pointer.
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleAbsolute, test) {
  typedef double (*PackedDoubleAbsolute)();
  double res = reinterpret_cast<PackedDoubleAbsolute>(test->entry())();
  EXPECT_FLOAT_EQ(1.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleMul, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 3.0, 2.0 };
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = { 3.0, 4.0 };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ mulpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleMul, test) {
  typedef double (*PackedDoubleMul)();
  double res = reinterpret_cast<PackedDoubleMul>(test->entry())();
  EXPECT_FLOAT_EQ(9.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleDiv, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 9.0, 2.0 };
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = { 3.0, 4.0 };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ divpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleDiv, test) {
  typedef double (*PackedDoubleDiv)();
  double res = reinterpret_cast<PackedDoubleDiv>(test->entry())();
  EXPECT_FLOAT_EQ(3.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleSqrt, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 16.0, 2.0 };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ sqrtpd(XMM10);
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleSqrt, test) {
  typedef double (*PackedDoubleSqrt)();
  double res = reinterpret_cast<PackedDoubleSqrt>(test->entry())();
  EXPECT_FLOAT_EQ(4.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleMin, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 9.0, 2.0 };
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = { 3.0, 4.0 };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ minpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleMin, test) {
  typedef double (*PackedDoubleMin)();
  double res = reinterpret_cast<PackedDoubleMin>(test->entry())();
  EXPECT_FLOAT_EQ(3.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleMax, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 9.0, 2.0 };
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = { 3.0, 4.0 };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM11, Address(RAX, 0));
  __ maxpd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleMax, test) {
  typedef double (*PackedDoubleMax)();
  double res = reinterpret_cast<PackedDoubleMax>(test->entry())();
  EXPECT_FLOAT_EQ(9.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleShuffle, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 2.0, 9.0 };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM10, Address(RAX, 0));
  // Splat Y across all lanes.
  __ shufpd(XMM10, XMM10, Immediate(0x33));
  // Splat X across all lanes.
  __ shufpd(XMM10, XMM10, Immediate(0x0));
  // Set return value.
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleShuffle, test) {
  typedef double (*PackedDoubleShuffle)();
  double res = reinterpret_cast<PackedDoubleShuffle>(test->entry())();
  EXPECT_FLOAT_EQ(9.0, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedDoubleToSingle, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = { 9.0, 2.0 };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM11, Address(RAX, 0));
  __ cvtpd2ps(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedDoubleToSingle, test) {
  typedef float (*PackedDoubleToSingle)();
  float res = reinterpret_cast<PackedDoubleToSingle>(test->entry())();
  EXPECT_FLOAT_EQ(9.0f, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(PackedSingleToDouble, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = { 9.0f, 2.0f, 3.0f, 4.0f };
  __ movq(RAX, Immediate(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM11, Address(RAX, 0));
  __ cvtps2pd(XMM10, XMM11);
  __ movaps(XMM0, XMM10);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedSingleToDouble, test) {
  typedef double (*PackedSingleToDouble)();
  double res = reinterpret_cast<PackedSingleToDouble>(test->entry())();
  EXPECT_FLOAT_EQ(9.0f, res, 0.000001f);
}


ASSEMBLER_TEST_GENERATE(SingleFPOperations, assembler) {
  __ pushq(RBX);
  __ pushq(RCX);
  __ movq(RBX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, RBX);
  __ movd(XMM8, RBX);
  __ movq(RCX, Immediate(bit_cast<int32_t, float>(3.4f)));
  __ movd(XMM1, RCX);
  __ movd(XMM9, RCX);
  __ addss(XMM0, XMM1);  // 15.7f
  __ mulss(XMM0, XMM1);  // 53.38f
  __ subss(XMM0, XMM1);  // 49.98f
  __ divss(XMM0, XMM1);  // 14.7f
  __ addss(XMM8, XMM9);  // 15.7f
  __ mulss(XMM8, XMM9);  // 53.38f
  __ subss(XMM8, XMM9);  // 49.98f
  __ divss(XMM8, XMM9);  // 14.7f
  __ subss(XMM0, XMM8);  // 0.0f
  __ popq(RCX);
  __ popq(RBX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SingleFPOperations, test) {
  typedef float (*SingleFPOperationsCode)();
  float res = reinterpret_cast<SingleFPOperationsCode>(test->entry())();
  EXPECT_FLOAT_EQ(0.0f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(PackedFPOperations, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM10, RAX);
  __ shufps(XMM10, XMM10, Immediate(0x0));
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(3.4f)));
  __ movd(XMM9, RAX);
  __ shufps(XMM9, XMM9, Immediate(0x0));
  __ addps(XMM10, XMM9);  // 15.7f
  __ mulps(XMM10, XMM9);  // 53.38f
  __ subps(XMM10, XMM9);  // 49.98f
  __ divps(XMM10, XMM9);  // 14.7f
  __ movaps(XMM0, XMM10);
  __ shufps(XMM0, XMM0, Immediate(0x55));  // Copy second lane into all 4 lanes.
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedFPOperations, test) {
  typedef float (*PackedFPOperationsCode)();
  float res = reinterpret_cast<PackedFPOperationsCode>(test->entry())();
  EXPECT_FLOAT_EQ(14.7f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedIntOperations, assembler) {
  __ movl(RAX, Immediate(0x2));
  __ movd(XMM0, RAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ movl(RAX, Immediate(0x1));
  __ movd(XMM1, RAX);
  __ shufps(XMM1, XMM1, Immediate(0x0));
  __ addpl(XMM0, XMM1);  // 0x3
  __ addpl(XMM0, XMM0);  // 0x6
  __ subpl(XMM0, XMM1);  // 0x5
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedIntOperations, test) {
  typedef uint32_t (*PackedIntOperationsCode)();
  uint32_t res = reinterpret_cast<PackedIntOperationsCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x5), res);
}


ASSEMBLER_TEST_GENERATE(PackedFPOperations2, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ movd(XMM0, RAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));

  __ movaps(XMM11, XMM0);  // Copy XMM0
  __ reciprocalps(XMM11);  // 0.25
  __ sqrtps(XMM11);  // 0.5
  __ rsqrtps(XMM0);  // ~0.5
  __ subps(XMM0, XMM11);  // ~0.0
  __ shufps(XMM0, XMM0, Immediate(0x00));  // Copy second lane into all 4 lanes.
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedFPOperations2, test) {
  typedef float (*PackedFPOperations2Code)();
  float res = reinterpret_cast<PackedFPOperations2Code>(test->entry())();
  EXPECT_FLOAT_EQ(0.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedCompareEQ, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppseq(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedCompareEQ, test) {
  typedef uint32_t (*PackedCompareEQCode)();
  uint32_t res = reinterpret_cast<PackedCompareEQCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
}


ASSEMBLER_TEST_GENERATE(PackedCompareNEQ, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsneq(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedCompareNEQ, test) {
  typedef uint32_t (*PackedCompareNEQCode)();
  uint32_t res = reinterpret_cast<PackedCompareNEQCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0xFFFFFFFF), res);
}


ASSEMBLER_TEST_GENERATE(PackedCompareLT, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppslt(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedCompareLT, test) {
  typedef uint32_t (*PackedCompareLTCode)();
  uint32_t res = reinterpret_cast<PackedCompareLTCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0xFFFFFFFF), res);
}


ASSEMBLER_TEST_GENERATE(PackedCompareLE, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsle(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedCompareLE, test) {
  typedef uint32_t (*PackedCompareLECode)();
  uint32_t res = reinterpret_cast<PackedCompareLECode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0xFFFFFFFF), res);
}


ASSEMBLER_TEST_GENERATE(PackedCompareNLT, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsnlt(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedCompareNLT, test) {
  typedef uint32_t (*PackedCompareNLTCode)();
  uint32_t res = reinterpret_cast<PackedCompareNLTCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
}


ASSEMBLER_TEST_GENERATE(PackedCompareNLE, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsnle(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedCompareNLE, test) {
  typedef uint32_t (*PackedCompareNLECode)();
  uint32_t res = reinterpret_cast<PackedCompareNLECode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
}


ASSEMBLER_TEST_GENERATE(PackedNegate, assembler) {
  __ pushq(PP);  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ movl(RAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, RAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ negateps(XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xAA));  // Copy third lane into all 4 lanes.
  __ popq(PP);  // Restore caller's pool pointer.
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedNegate, test) {
  typedef float (*PackedNegateCode)();
  float res = reinterpret_cast<PackedNegateCode>(test->entry())();
  EXPECT_FLOAT_EQ(-12.3f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedAbsolute, assembler) {
  __ pushq(PP);  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ movl(RAX, Immediate(bit_cast<int32_t, float>(-15.3f)));
  __ movd(XMM0, RAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ absps(XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xAA));  // Copy third lane into all 4 lanes.
  __ popq(PP);  // Restore caller's pool pointer.
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedAbsolute, test) {
  typedef float (*PackedAbsoluteCode)();
  float res = reinterpret_cast<PackedAbsoluteCode>(test->entry())();
  EXPECT_FLOAT_EQ(15.3f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedSetWZero, assembler) {
  __ pushq(PP);  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ zerowps(XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xFF));  // Copy the W lane which is now 0.0.
  __ popq(PP);  // Restore caller's pool pointer.
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedSetWZero, test) {
  typedef float (*PackedSetWZeroCode)();
  float res = reinterpret_cast<PackedSetWZeroCode>(test->entry())();
  EXPECT_FLOAT_EQ(0.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedMin, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ minps(XMM0, XMM1);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedMin, test) {
  typedef float (*PackedMinCode)();
  float res = reinterpret_cast<PackedMinCode>(test->entry())();
  EXPECT_FLOAT_EQ(2.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedMax, assembler) {
  __ set1ps(XMM0, RAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, RAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ maxps(XMM0, XMM1);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedMax, test) {
  typedef float (*PackedMaxCode)();
  float res = reinterpret_cast<PackedMaxCode>(test->entry())();
  EXPECT_FLOAT_EQ(4.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedLogicalOr, assembler) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant1 =
      { 0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0 };
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant2 =
      { 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F };
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM0, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant2)));
  __ movups(XMM1, Address(RAX, 0));
  __ orps(XMM0, XMM1);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedLogicalOr, test) {
  typedef uint32_t (*PackedLogicalOrCode)();
  uint32_t res = reinterpret_cast<PackedLogicalOrCode>(test->entry())();
  EXPECT_EQ(0xFFFFFFFF, res);
}


ASSEMBLER_TEST_GENERATE(PackedLogicalAnd, assembler) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant1 =
      { 0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0 };
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant2 =
      { 0x0F0FFF0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F };
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM0, Address(RAX, 0));
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant2)));
  __ andps(XMM0, Address(RAX, 0));
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedLogicalAnd, test) {
  typedef uint32_t (*PackedLogicalAndCode)();
  uint32_t res = reinterpret_cast<PackedLogicalAndCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0000F000), res);
}


ASSEMBLER_TEST_GENERATE(PackedLogicalNot, assembler) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant1 =
      { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF };
  __ pushq(PP);  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ LoadImmediate(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)), PP);
  __ movups(XMM9, Address(RAX, 0));
  __ notps(XMM9);
  __ movaps(XMM0, XMM9);
  __ pushq(RAX);
  __ movss(Address(RSP, 0), XMM0);
  __ popq(RAX);
  __ popq(PP);  // Restore caller's pool pointer.
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedLogicalNot, test) {
  typedef uint32_t (*PackedLogicalNotCode)();
  uint32_t res = reinterpret_cast<PackedLogicalNotCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
}


ASSEMBLER_TEST_GENERATE(PackedMoveHighLow, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = { 1.0, 2.0, 3.0, 4.0 };
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = { 5.0, 6.0, 7.0, 8.0 };
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 7.0f, 8.0f, 3.0f, 4.0f.
  __ movhlps(XMM9, XMM1);
  __ xorps(XMM1, XMM1);
  // XMM1 = 7.0f, 8.0f, 3.0f, 4.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x00));  // 7.0f.
  __ shufps(XMM1, XMM1, Immediate(0x55));  // 8.0f.
  __ addss(XMM9, XMM1);  // 15.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedMoveHighLow, test) {
  typedef float (*PackedMoveHighLow)();
  float res = reinterpret_cast<PackedMoveHighLow>(test->entry())();
  EXPECT_FLOAT_EQ(15.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedMoveLowHigh, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = { 1.0, 2.0, 3.0, 4.0 };
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = { 5.0, 6.0, 7.0, 8.0 };
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 1.0f, 2.0f, 5.0f, 6.0f
  __ movlhps(XMM9, XMM1);
  __ xorps(XMM1, XMM1);
  // XMM1 = 1.0f, 2.0f, 5.0f, 6.0f
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0xAA));  // 5.0f.
  __ shufps(XMM1, XMM1, Immediate(0xFF));  // 6.0f.
  __ addss(XMM9, XMM1);  // 11.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedMoveLowHigh, test) {
  typedef float (*PackedMoveLowHigh)();
  float res = reinterpret_cast<PackedMoveLowHigh>(test->entry())();
  EXPECT_FLOAT_EQ(11.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedUnpackLow, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = { 1.0, 2.0, 3.0, 4.0 };
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = { 5.0, 6.0, 7.0, 8.0 };
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 1.0f, 5.0f, 2.0f, 6.0f.
  __ unpcklps(XMM9, XMM1);
  // XMM1 = 1.0f, 5.0f, 2.0f, 6.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x55));
  __ shufps(XMM1, XMM1, Immediate(0xFF));
  __ addss(XMM9, XMM1);  // 11.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedUnpackLow, test) {
  typedef float (*PackedUnpackLow)();
  float res = reinterpret_cast<PackedUnpackLow>(test->entry())();
  EXPECT_FLOAT_EQ(11.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedUnpackHigh, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = { 1.0, 2.0, 3.0, 4.0 };
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = { 5.0, 6.0, 7.0, 8.0 };
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 3.0f, 7.0f, 4.0f, 8.0f.
  __ unpckhps(XMM9, XMM1);
  // XMM1 = 3.0f, 7.0f, 4.0f, 8.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x00));
  __ shufps(XMM1, XMM1, Immediate(0xAA));
  __ addss(XMM9, XMM1);  // 7.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedUnpackHigh, test) {
  typedef float (*PackedUnpackHigh)();
  float res = reinterpret_cast<PackedUnpackHigh>(test->entry())();
  EXPECT_FLOAT_EQ(7.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedUnpackLowPair, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = { 1.0, 2.0, 3.0, 4.0 };
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = { 5.0, 6.0, 7.0, 8.0 };
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 1.0f, 2.0f, 5.0f, 6.0f.
  __ unpcklpd(XMM9, XMM1);
  // XMM1 = 1.0f, 2.0f, 5.0f, 6.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x00));
  __ shufps(XMM1, XMM1, Immediate(0xAA));
  __ addss(XMM9, XMM1);  // 6.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedUnpackLowPair, test) {
  typedef float (*PackedUnpackLowPair)();
  float res = reinterpret_cast<PackedUnpackLowPair>(test->entry())();
  EXPECT_FLOAT_EQ(6.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(PackedUnpackHighPair, assembler) {
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant0 = { 1.0, 2.0, 3.0, 4.0 };
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = { 5.0, 6.0, 7.0, 8.0 };
  // XMM9 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant0)));
  __ movups(XMM9, Address(RAX, 0));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(&constant1)));
  __ movups(XMM1, Address(RAX, 0));
  // XMM9 = 3.0f, 4.0f, 7.0f, 8.0f.
  __ unpckhpd(XMM9, XMM1);
  // XMM1 = 3.0f, 4.0f, 7.0f, 8.0f.
  __ movaps(XMM1, XMM9);
  __ shufps(XMM9, XMM9, Immediate(0x55));
  __ shufps(XMM1, XMM1, Immediate(0xFF));
  __ addss(XMM9, XMM1);  // 12.0f.
  __ movaps(XMM0, XMM9);
  __ ret();
}


ASSEMBLER_TEST_RUN(PackedUnpackHighPair, test) {
  typedef float (*PackedUnpackHighPair)();
  float res = reinterpret_cast<PackedUnpackHighPair>(test->entry())();
  EXPECT_FLOAT_EQ(12.0f, res, 0.001f);
}


ASSEMBLER_TEST_GENERATE(DoubleFPMoves, assembler) {
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(1024.67)));
  __ pushq(R15);  // Callee saved.
  __ pushq(RAX);
  __ movsd(XMM0, Address(RSP, 0));
  __ movsd(XMM1, XMM0);
  __ movsd(XMM2, XMM1);
  __ movsd(XMM3, XMM2);
  __ movsd(XMM4, XMM3);
  __ movsd(XMM5, XMM4);
  __ movsd(XMM6, XMM5);
  __ movsd(XMM7, XMM6);
  __ movsd(XMM8, XMM7);
  __ movsd(XMM9, XMM8);
  __ movsd(XMM10, XMM9);
  __ movsd(XMM11, XMM10);
  __ movsd(XMM12, XMM11);
  __ movsd(XMM13, XMM12);
  __ movsd(XMM14, XMM13);
  __ movsd(XMM15, XMM14);
  __ movq(Address(RSP, 0), Immediate(0));
  __ movsd(XMM0, Address(RSP, 0));
  __ movsd(Address(RSP, 0), XMM15);
  __ movsd(XMM1, Address(RSP, 0));
  __ movq(R10, RSP);
  __ movsd(Address(R10, 0), XMM1);
  __ movsd(XMM2, Address(R10, 0));
  __ movq(R15, RSP);
  __ movsd(Address(R15, 0), XMM2);
  __ movsd(XMM3, Address(R15, 0));
  __ movq(RAX, RSP);
  __ movsd(Address(RAX, 0), XMM3);
  __ movsd(XMM4, Address(RAX, 0));
  __ movsd(XMM15, Address(RSP, 0));
  __ movaps(XMM14, XMM15);
  __ movaps(XMM13, XMM14);
  __ movaps(XMM12, XMM13);
  __ movaps(XMM11, XMM12);
  __ movaps(XMM10, XMM11);
  __ movaps(XMM9, XMM10);
  __ movaps(XMM8, XMM9);
  __ movaps(XMM7, XMM8);
  __ movaps(XMM6, XMM7);
  __ movaps(XMM5, XMM6);
  __ movaps(XMM4, XMM5);
  __ movaps(XMM3, XMM4);
  __ movaps(XMM2, XMM3);
  __ movaps(XMM1, XMM2);
  __ movaps(XMM0, XMM1);
  __ popq(RAX);
  __ popq(R15);  // Callee saved.
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleFPMoves, test) {
  typedef double (*DoubleFPMovesCode)();
  EXPECT_FLOAT_EQ(1024.67,
                  reinterpret_cast<DoubleFPMovesCode>(test->entry())(), 0.001);
}


ASSEMBLER_TEST_GENERATE(DoubleFPOperations, assembler) {
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(12.3)));
  __ pushq(RAX);
  __ movsd(XMM0, Address(RSP, 0));
  __ movsd(XMM8, Address(RSP, 0));
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(3.4)));
  __ movq(Address(RSP, 0), RAX);
  __ movsd(XMM12, Address(RSP, 0));
  __ addsd(XMM8, XMM12);  // 15.7
  __ mulsd(XMM8, XMM12);  // 53.38
  __ subsd(XMM8, XMM12);  // 49.98
  __ divsd(XMM8, XMM12);  // 14.7
  __ sqrtsd(XMM8, XMM8);  // 3.834
  __ movsd(XMM1, Address(RSP, 0));
  __ addsd(XMM0, XMM1);  // 15.7
  __ mulsd(XMM0, XMM1);  // 53.38
  __ subsd(XMM0, XMM1);  // 49.98
  __ divsd(XMM0, XMM1);  // 14.7
  __ sqrtsd(XMM0, XMM0);  // 3.834057902
  __ addsd(XMM0, XMM8);  // 7.6681
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleFPOperations, test) {
  typedef double (*SingleFPOperationsCode)();
  double res = reinterpret_cast<SingleFPOperationsCode>(test->entry())();
  EXPECT_FLOAT_EQ(7.668, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Int32ToDoubleConversion, assembler) {
  // Fill upper bits with garbage.
  __ movq(R11, Immediate(0x1111111100000006));
  __ cvtsi2sdl(XMM0, R11);
  // Fill upper bits with garbage.
  __ movq(R11, Immediate(0x2222222200000008));
  __ cvtsi2sdl(XMM8, R11);
  __ subsd(XMM0, XMM8);
  __ ret();
}


ASSEMBLER_TEST_RUN(Int32ToDoubleConversion, test) {
  typedef double (*Int32ToDoubleConversion)();
  double res = reinterpret_cast<Int32ToDoubleConversion>(test->entry())();
  EXPECT_FLOAT_EQ(-2.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(Int64ToDoubleConversion, assembler) {
  __ movq(RDX, Immediate(12LL << 32));
  __ cvtsi2sdq(XMM0, RDX);
  __ movsd(XMM15, XMM0);  // Move to high register
  __ addsd(XMM0, XMM0);  // Stomp XMM0
  __ movsd(XMM0, XMM15);  // Move back to XMM0
  __ ret();
}


ASSEMBLER_TEST_RUN(Int64ToDoubleConversion, test) {
  typedef double (*Int64ToDoubleConversionCode)();
  double res = reinterpret_cast<Int64ToDoubleConversionCode>(test->entry())();
  EXPECT_FLOAT_EQ(static_cast<double>(12LL << 32), res, 0.001);
}


ASSEMBLER_TEST_GENERATE(DoubleToInt64Conversion, assembler) {
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(12.3)));
  __ pushq(RAX);
  __ movsd(XMM9, Address(RSP, 0));
  __ movsd(XMM6, Address(RSP, 0));
  __ popq(RAX);
  __ cvttsd2siq(R10, XMM6);
  __ cvttsd2siq(RDX, XMM6);
  __ cvttsd2siq(R10, XMM9);
  __ cvttsd2siq(RDX, XMM9);
  __ subq(RDX, R10);
  __ movq(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleToInt64Conversion, test) {
  typedef int64_t (*DoubleToInt64ConversionCode)();
  int64_t res = reinterpret_cast<DoubleToInt64ConversionCode>(test->entry())();
  EXPECT_EQ(0, res);
}


ASSEMBLER_TEST_GENERATE(TestObjectCompare, assembler) {
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Object& obj = Object::ZoneHandle(object_store->smi_class());
  Label fail;
  __ EnterFrame(0);
  __ pushq(PP);  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ LoadObject(RAX, obj, PP);
  __ CompareObject(RAX, obj, PP);
  __ j(NOT_EQUAL, &fail);
  __ LoadObject(RCX, obj, PP);
  __ CompareObject(RCX, obj, PP);
  __ j(NOT_EQUAL, &fail);
  const Smi& smi = Smi::ZoneHandle(Smi::New(15));
  __ LoadObject(RCX, smi, PP);
  __ CompareObject(RCX, smi, PP);
  __ j(NOT_EQUAL, &fail);
  __ pushq(RAX);
  __ StoreObject(Address(RSP, 0), obj, PP);
  __ popq(RCX);
  __ CompareObject(RCX, obj, PP);
  __ j(NOT_EQUAL, &fail);
  __ pushq(RAX);
  __ StoreObject(Address(RSP, 0), smi, PP);
  __ popq(RCX);
  __ CompareObject(RCX, smi, PP);
  __ j(NOT_EQUAL, &fail);
  __ movl(RAX, Immediate(1));  // OK
  __ popq(PP);  // Restore caller's pool pointer.
  __ LeaveFrame();
  __ ret();
  __ Bind(&fail);
  __ movl(RAX, Immediate(0));  // Fail.
  __ popq(PP);  // Restore caller's pool pointer.
  __ LeaveFrame();
  __ ret();
}


ASSEMBLER_TEST_RUN(TestObjectCompare, test) {
  typedef bool (*TestObjectCompare)();
  bool res = reinterpret_cast<TestObjectCompare>(test->entry())();
  EXPECT_EQ(true, res);
}


ASSEMBLER_TEST_GENERATE(TestNop, assembler) {
  __ nop(1);
  __ nop(2);
  __ nop(3);
  __ nop(4);
  __ nop(5);
  __ nop(6);
  __ nop(7);
  __ nop(8);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestNop, test) {
  typedef int (*TestNop)();
  int res = reinterpret_cast<TestNop>(test->entry())();
  EXPECT_EQ(36, res);  // 36 nop bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAlign0, assembler) {
  __ Align(4, 0);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAlign0, test) {
  typedef int (*TestAlign0)();
  int res = reinterpret_cast<TestAlign0>(test->entry())();
  EXPECT_EQ(0, res);  // 0 bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAlign1, assembler) {
  __ nop(1);
  __ Align(4, 0);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAlign1, test) {
  typedef int (*TestAlign1)();
  int res = reinterpret_cast<TestAlign1>(test->entry())();
  EXPECT_EQ(4, res);  // 4 bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAlign1Offset1, assembler) {
  __ nop(1);
  __ Align(4, 1);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAlign1Offset1, test) {
  typedef int (*TestAlign1Offset1)();
  int res = reinterpret_cast<TestAlign1Offset1>(test->entry())();
  EXPECT_EQ(3, res);  // 3 bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAlignLarge, assembler) {
  __ nop(1);
  __ Align(16, 0);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAlignLarge, test) {
  typedef int (*TestAlignLarge)();
  int res = reinterpret_cast<TestAlignLarge>(test->entry())();
  EXPECT_EQ(16, res);  // 16 bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAdds, assembler) {
  __ movq(RAX, Immediate(4));
  __ pushq(RAX);
  __ addq(Address(RSP, 0), Immediate(5));
  // TOS: 9
  __ addq(Address(RSP, 0), Immediate(-2));
  // TOS: 7
  __ movq(RCX, Immediate(3));
  __ addq(Address(RSP, 0), RCX);
  // TOS: 10
  __ movq(RAX, Immediate(10));
  __ addq(RAX, Address(RSP, 0));
  // RAX: 20
  __ popq(RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAdds, test) {
  typedef int (*TestAdds)();
  int res = reinterpret_cast<TestAdds>(test->entry())();
  EXPECT_EQ(20, res);
}


ASSEMBLER_TEST_GENERATE(TestNot, assembler) {
  __ movq(RAX, Immediate(0xFFFFFFFF00000000));
  __ notq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(TestNot, test) {
  typedef int (*TestNot)();
  unsigned int res = reinterpret_cast<TestNot>(test->entry())();
  EXPECT_EQ(0xFFFFFFFF, res);
}


ASSEMBLER_TEST_GENERATE(TestNotInt32, assembler) {
  __ movq(RAX, Immediate(0x0));
  __ notl(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(TestNotInt32, test) {
  typedef int (*TestNot)();
  unsigned int res = reinterpret_cast<TestNot>(test->entry())();
  EXPECT_EQ(0xFFFFFFFF, res);
}


ASSEMBLER_TEST_GENERATE(XorpdZeroing, assembler) {
  __ pushq(RAX);
  __ movsd(Address(RSP, 0), XMM0);
  __ xorpd(XMM0, Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(XorpdZeroing, test) {
  typedef double (*XorpdZeroingCode)(double d);
  double res = reinterpret_cast<XorpdZeroingCode>(test->entry())(12.56e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0001);
}


ASSEMBLER_TEST_GENERATE(XorpdZeroing2, assembler) {
  Label done;
  __ xorpd(XMM15, XMM15);
  __ xorpd(XMM0, XMM0);
  __ xorpd(XMM0, XMM15);
  __ comisd(XMM0, XMM15);
  __ j(ZERO, &done);
  __ int3();
  __ Bind(&done);
  __ ret();
}


ASSEMBLER_TEST_RUN(XorpdZeroing2, test) {
  typedef double (*XorpdZeroing2Code)(double d);
  double res = reinterpret_cast<XorpdZeroing2Code>(test->entry())(12.56e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0001);
}


ASSEMBLER_TEST_GENERATE(Pxor, assembler) {
  __ pxor(XMM0, XMM0);
  __ ret();
}


ASSEMBLER_TEST_RUN(Pxor, test) {
  typedef double (*PxorCode)(double d);
  double res = reinterpret_cast<PxorCode>(test->entry())(12.3456e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0);
}


ASSEMBLER_TEST_GENERATE(SquareRootDouble, assembler) {
  __ sqrtsd(XMM0, XMM0);
  __ ret();
}


ASSEMBLER_TEST_RUN(SquareRootDouble, test) {
  typedef double (*SquareRootDoubleCode)(double d);
  const double kDoubleConst = .7;
  double res =
      reinterpret_cast<SquareRootDoubleCode>(test->entry())(kDoubleConst);
  EXPECT_FLOAT_EQ(sqrt(kDoubleConst), res, 0.0001);
}


// Called from assembler_test.cc.
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ pushq(PP);  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ pushq(CTX);
  __ movq(CTX, CallingConventions::kArg1Reg);
  __ StoreIntoObject(CallingConventions::kArg3Reg,
                     FieldAddress(CallingConventions::kArg3Reg,
                                  GrowableObjectArray::data_offset()),
                     CallingConventions::kArg2Reg);
  __ popq(CTX);
  __ popq(PP);  // Restore caller's pool pointer.
  __ ret();
}


ASSEMBLER_TEST_GENERATE(DoubleFPUStackMoves, assembler) {
  int64_t l = bit_cast<int64_t, double>(1024.67);
  __ movq(RAX, Immediate(l));
  __ pushq(RAX);
  __ fldl(Address(RSP, 0));
  __ movq(Address(RSP, 0), Immediate(0));
  __ fstpl(Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleFPUStackMoves, test) {
  typedef int64_t (*DoubleFPUStackMovesCode)();
  int64_t res = reinterpret_cast<DoubleFPUStackMovesCode>(test->entry())();
  EXPECT_FLOAT_EQ(1024.67, (bit_cast<double, int64_t>(res)), 0.001);
}


ASSEMBLER_TEST_GENERATE(Sine, assembler) {
  __ pushq(RAX);
  __ movsd(Address(RSP, 0), XMM0);
  __ fldl(Address(RSP, 0));
  __ fsin();
  __ fstpl(Address(RSP, 0));
  __ movsd(XMM0, Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Sine, test) {
  typedef double (*SineCode)(double d);
  const double kDoubleConst = 0.7;
  double res = reinterpret_cast<SineCode>(test->entry())(kDoubleConst);
  EXPECT_FLOAT_EQ(sin(kDoubleConst), res, 0.0001);
}


ASSEMBLER_TEST_GENERATE(Cosine, assembler) {
  __ pushq(RAX);
  __ movsd(Address(RSP, 0), XMM0);
  __ fldl(Address(RSP, 0));
  __ fcos();
  __ fstpl(Address(RSP, 0));
  __ movsd(XMM0, Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Cosine, test) {
  typedef double (*CosineCode)(double f);
  const double kDoubleConst = 0.7;
  double res = reinterpret_cast<CosineCode>(test->entry())(kDoubleConst);
  EXPECT_FLOAT_EQ(cos(kDoubleConst), res, 0.0001);
}


ASSEMBLER_TEST_GENERATE(IntToDoubleConversion, assembler) {
  __ movq(RDX, Immediate(6));
  __ cvtsi2sdq(XMM0, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(IntToDoubleConversion, test) {
  typedef double (*IntToDoubleConversionCode)();
  double res = reinterpret_cast<IntToDoubleConversionCode>(test->entry())();
  EXPECT_FLOAT_EQ(6.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(IntToDoubleConversion2, assembler) {
  __ pushq(CallingConventions::kArg1Reg);
  __ fildl(Address(RSP, 0));
  __ fstpl(Address(RSP, 0));
  __ movsd(XMM0, Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(IntToDoubleConversion2, test) {
  typedef double (*IntToDoubleConversion2Code)(int i);
  double res = reinterpret_cast<IntToDoubleConversion2Code>(test->entry())(3);
  EXPECT_FLOAT_EQ(3.0, res, 0.001);
}

ASSEMBLER_TEST_GENERATE(DoubleToDoubleTrunc, assembler) {
  __ roundsd(XMM0, XMM0, Assembler::kRoundToZero);
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleToDoubleTrunc, test) {
  typedef double (*DoubleToDoubleTruncCode)(double d);
  double res = reinterpret_cast<DoubleToDoubleTruncCode>(test->entry())(12.3);
  EXPECT_EQ(12.0, res);
  res = reinterpret_cast<DoubleToDoubleTruncCode>(test->entry())(12.8);
  EXPECT_EQ(12.0, res);
  res = reinterpret_cast<DoubleToDoubleTruncCode>(test->entry())(-12.3);
  EXPECT_EQ(-12.0, res);
  res = reinterpret_cast<DoubleToDoubleTruncCode>(test->entry())(-12.8);
  EXPECT_EQ(-12.0, res);
}


ASSEMBLER_TEST_GENERATE(DoubleAbs, assembler) {
  __ pushq(PP);  // Save caller's pool pointer and load a new one here.
  __ LoadPoolPointer(PP);
  __ DoubleAbs(XMM0);
  __ popq(PP);  // Restore caller's pool pointer.
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleAbs, test) {
  typedef double (*DoubleAbsCode)(double d);
  double val = -12.45;
  double res =  reinterpret_cast<DoubleAbsCode>(test->entry())(val);
  EXPECT_FLOAT_EQ(-val, res, 0.001);
  val = 12.45;
  res =  reinterpret_cast<DoubleAbsCode>(test->entry())(val);
  EXPECT_FLOAT_EQ(val, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(ExtractSignBits, assembler) {
  __ movmskpd(RAX, XMM0);
  __ andq(RAX, Immediate(0x1));
  __ ret();
}


ASSEMBLER_TEST_RUN(ExtractSignBits, test) {
  typedef int (*ExtractSignBits)(double d);
  int res = reinterpret_cast<ExtractSignBits>(test->entry())(1.0);
  EXPECT_EQ(0, res);
  res = reinterpret_cast<ExtractSignBits>(test->entry())(-1.0);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ExtractSignBits>(test->entry())(-0.0);
  EXPECT_EQ(1, res);
}


ASSEMBLER_TEST_GENERATE(TestSetCC, assembler) {
  __ movq(RAX, Immediate(0xFFFFFFFF));
  __ cmpq(RAX, RAX);
  __ setcc(NOT_EQUAL, AL);
  __ ret();
}


ASSEMBLER_TEST_RUN(TestSetCC, test) {
  typedef uword (*TestSetCC)();
  uword res = reinterpret_cast<TestSetCC>(test->entry())();
  EXPECT_EQ(0xFFFFFF00, res);
}


ASSEMBLER_TEST_GENERATE(TestRepMovsBytes, assembler) {
  __ pushq(RSI);
  __ pushq(RDI);
  __ pushq(CallingConventions::kArg1Reg);  // from.
  __ pushq(CallingConventions::kArg2Reg);  // to.
  __ pushq(CallingConventions::kArg3Reg);  // count.
  __ movq(RSI, Address(RSP, 2 * kWordSize));  // from.
  __ movq(RDI, Address(RSP, 1 * kWordSize));  // to.
  __ movq(RCX, Address(RSP, 0 * kWordSize));  // count.
  __ rep_movsb();
  // Remove saved arguments.
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RAX);
  __ popq(RDI);
  __ popq(RSI);
  __ ret();
}


ASSEMBLER_TEST_RUN(TestRepMovsBytes, test) {
  const char* from = "0123456789";
  const char* to = new char[10];
  typedef void (*TestRepMovsBytes)(const char* from, const char* to, int count);
  reinterpret_cast<TestRepMovsBytes>(test->entry())(from, to, 10);
  EXPECT_EQ(to[0], '0');
  for (int i = 0; i < 10; i++) {
    EXPECT_EQ(from[i], to[i]);
  }
  delete [] to;
}


ASSEMBLER_TEST_GENERATE(ConditionalMovesCompare, assembler) {
  __ cmpq(CallingConventions::kArg1Reg, CallingConventions::kArg2Reg);
  __ movq(RDX, Immediate(1));  // Greater equal.
  __ movq(RCX, Immediate(-1));  // Less
  __ cmovlessq(RAX, RCX);
  __ cmovgeq(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(ConditionalMovesCompare, test) {
  typedef int (*ConditionalMovesCompareCode)(int i, int j);
  int res = reinterpret_cast<ConditionalMovesCompareCode>(test->entry())(10, 5);
  EXPECT_EQ(1, res);  // Greater equal.
  res = reinterpret_cast<ConditionalMovesCompareCode>(test->entry())(5, 5);
  EXPECT_EQ(1, res);  // Greater equal.
  res = reinterpret_cast<ConditionalMovesCompareCode>(test->entry())(2, 5);
  EXPECT_EQ(-1, res);  // Less.
}


ASSEMBLER_TEST_GENERATE(BitTest, assembler) {
  __ movq(RAX, Immediate(4));
  __ movq(R11, Immediate(2));
  __ btq(RAX, R11);
  Label ok;
  __ j(CARRY, &ok);
  __ int3();
  __ Bind(&ok);
  __ movq(RAX, Immediate(1));
  __ ret();
}


ASSEMBLER_TEST_RUN(BitTest, test) {
  typedef int (*BitTest)();
  EXPECT_EQ(1, reinterpret_cast<BitTest>(test->entry())());
}


// Return 1 if equal, 0 if not equal.
ASSEMBLER_TEST_GENERATE(ConditionalMovesEqual, assembler) {
  __ movq(RDX, CallingConventions::kArg1Reg);
  __ xorq(RAX, RAX);
  __ movq(RCX, Immediate(1));
  __ cmpq(RDX, Immediate(785));
  __ cmoveq(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(ConditionalMovesEqual, test) {
  typedef int (*ConditionalMovesEqualCode)(int i);
  int res = reinterpret_cast<ConditionalMovesEqualCode>(test->entry())(785);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ConditionalMovesEqualCode>(test->entry())(-12);
  EXPECT_EQ(0, res);
}


// Return 1 if overflow, 0 if no overflow.
ASSEMBLER_TEST_GENERATE(ConditionalMovesNoOverflow, assembler) {
  __ movq(RDX, CallingConventions::kArg1Reg);
  __ addq(RDX, CallingConventions::kArg2Reg);
  __ movq(RAX, Immediate(1));
  __ movq(RCX, Immediate(0));
  __ cmovnoq(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(ConditionalMovesNoOverflow, test) {
  typedef int (*ConditionalMovesNoOverflowCode)(int64_t i, int64_t j);
  int res = reinterpret_cast<ConditionalMovesNoOverflowCode>(
      test->entry())(0x7fffffffffffffff, 2);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ConditionalMovesNoOverflowCode>(test->entry())(1, 1);
  EXPECT_EQ(0, res);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
