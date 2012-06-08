// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
  __ pushq(RDI);  // First argument is passed in register rdi.
  __ movq(RAX, Address(RSP, 0));
  __ popq(RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(ReadArgument, entry) {
  typedef int64_t (*ReadArgumentCode)(int64_t n);
  ReadArgumentCode id = reinterpret_cast<ReadArgumentCode>(entry);
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
}


ASSEMBLER_TEST_RUN(AddressingModes, entry) {
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


ASSEMBLER_TEST_RUN(JumpAroundCrash, entry) {
  Instr* instr = Instr::At(entry);
  EXPECT(!instr->IsBreakPoint());
  typedef void (*JumpAroundCrashCode)();
  reinterpret_cast<JumpAroundCrashCode>(entry)();
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


ASSEMBLER_TEST_RUN(SimpleLoop, entry) {
  typedef int (*SimpleLoopCode)();
  EXPECT_EQ(2 * 87, reinterpret_cast<SimpleLoopCode>(entry)());
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


ASSEMBLER_TEST_RUN(Increment, entry) {
  typedef int (*IncrementCode)();
  EXPECT_EQ(3, reinterpret_cast<IncrementCode>(entry)());
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


ASSEMBLER_TEST_RUN(IncrementLong, entry) {
  typedef int64_t (*IncrementCodeLong)();
  EXPECT_EQ(0x100000001, reinterpret_cast<IncrementCodeLong>(entry)());
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


ASSEMBLER_TEST_RUN(Decrement, entry) {
  typedef int (*DecrementCode)();
  EXPECT_EQ(0, reinterpret_cast<DecrementCode>(entry)());
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


ASSEMBLER_TEST_RUN(DecrementLong, entry) {
  typedef int64_t (*DecrementCodeLong)();
  EXPECT_EQ(0xffffffff, reinterpret_cast<DecrementCodeLong>(entry)());
}


ASSEMBLER_TEST_GENERATE(SignedMultiply, assembler) {
  __ movl(RAX, Immediate(2));
  __ movl(RCX, Immediate(4));
  __ imull(RAX, RCX);
  __ imull(RAX, Immediate(1000));
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiply, entry) {
  typedef int (*SignedMultiply)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply>(entry)());
}


ASSEMBLER_TEST_GENERATE(SignedMultiply64, assembler) {
  __ movq(RAX, Immediate(2));
  __ movq(RCX, Immediate(4));
  __ imulq(RAX, RCX);
  __ movq(R8, Immediate(2));
  __ movq(R9, Immediate(4));
  __ imulq(R8, R9);
  __ addq(RAX, R8);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiply64, entry) {
  typedef int64_t (*SignedMultiply64)();
  EXPECT_EQ(16, reinterpret_cast<SignedMultiply64>(entry)());
}


static const int64_t kLargeConstant = 0x1234567887654321;
static const int64_t kAnotherLargeConstant = 987654321987654321LL;
static const int64_t kProductLargeConstants = 0x5bbb29a7f52fbbd1;


ASSEMBLER_TEST_GENERATE(SignedMultiplyLong, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ movq(RCX, Immediate(kAnotherLargeConstant));
  __ imulq(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiplyLong, entry) {
  typedef int64_t (*SignedMultiplyLong)();
  EXPECT_EQ(kProductLargeConstants,
            reinterpret_cast<SignedMultiplyLong>(entry)());
}


ASSEMBLER_TEST_GENERATE(OverflowSignedMultiply, assembler) {
  __ movl(RDX, Immediate(0));
  __ movl(RAX, Immediate(0x0fffffff));
  __ movl(RCX, Immediate(0x0fffffff));
  __ imull(RAX, RCX);
  __ imull(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(OverflowSignedMultiply, entry) {
  typedef int (*OverflowSignedMultiply)();
  EXPECT_EQ(0, reinterpret_cast<OverflowSignedMultiply>(entry)());
}


ASSEMBLER_TEST_GENERATE(SignedMultiply1, assembler) {
  __ movl(RDX, Immediate(2));
  __ movl(RCX, Immediate(4));
  __ imull(RDX, RCX);
  __ imull(RDX, Immediate(1000));
  __ movl(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiply1, entry) {
  typedef int (*SignedMultiply1)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply1>(entry)());
}


ASSEMBLER_TEST_GENERATE(SignedDivide, assembler) {
  __ movl(RAX, Immediate(-87));
  __ movl(RDX, Immediate(123));
  __ cdq();
  __ movl(RCX, Immediate(42));
  __ idivl(RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedDivide, entry) {
  typedef int32_t (*SignedDivide)();
  EXPECT_EQ(-87 / 42, reinterpret_cast<SignedDivide>(entry)());
}


ASSEMBLER_TEST_GENERATE(SignedDivideLong, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ movq(RDX, Immediate(123));
  __ cqo();  // Clear RDX.
  __ movq(RCX, Immediate(42));
  __ idivq(RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedDivideLong, entry) {
  typedef int64_t (*SignedDivideLong)();
  EXPECT_EQ(kLargeConstant / 42, reinterpret_cast<SignedDivideLong>(entry)());
}


ASSEMBLER_TEST_GENERATE(Negate, assembler) {
  __ movl(RCX, Immediate(42));
  __ negl(RCX);
  __ movl(RAX, RCX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Negate, entry) {
  typedef int (*Negate)();
  EXPECT_EQ(-42, reinterpret_cast<Negate>(entry)());
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


ASSEMBLER_TEST_RUN(MoveExtend, entry) {
  typedef int (*MoveExtend)();
  EXPECT_EQ(0xff - 1 + 0xffff, reinterpret_cast<MoveExtend>(entry)());
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


ASSEMBLER_TEST_RUN(MoveExtendMemory, entry) {
  typedef int (*MoveExtendMemory)();
  EXPECT_EQ(0xff - 1 + 0xffff, reinterpret_cast<MoveExtendMemory>(entry)());
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


ASSEMBLER_TEST_RUN(Bitwise, entry) {
  typedef int (*Bitwise)();
  EXPECT_EQ(256 + 1, reinterpret_cast<Bitwise>(entry)());
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

  __ movl(RAX, Immediate(0));
  __ ret();
}


ASSEMBLER_TEST_RUN(LogicalOps, entry) {
  typedef int (*LogicalOpsCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalOpsCode>(entry)());
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


ASSEMBLER_TEST_RUN(LogicalTestL, entry) {
  typedef int (*LogicalTestCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalTestCode>(entry)());
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


ASSEMBLER_TEST_RUN(LogicalTestQ, entry) {
  typedef int (*LogicalTestCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalTestCode>(entry)());
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


ASSEMBLER_TEST_RUN(CompareSwapEQ, entry) {
  typedef int (*CompareSwapEQCode)();
  EXPECT_EQ(0, reinterpret_cast<CompareSwapEQCode>(entry)());
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


ASSEMBLER_TEST_RUN(CompareSwapNEQ, entry) {
  typedef int (*CompareSwapNEQCode)();
  EXPECT_EQ(4, reinterpret_cast<CompareSwapNEQCode>(entry)());
}


ASSEMBLER_TEST_GENERATE(Exchange, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ movq(RDX, Immediate(kAnotherLargeConstant));
  __ xchgq(RAX, RDX);
  __ subq(RAX, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Exchange, entry) {
  typedef int64_t (*Exchange)();
  EXPECT_EQ(kAnotherLargeConstant - kLargeConstant,
            reinterpret_cast<Exchange>(entry)());
}


ASSEMBLER_TEST_GENERATE(LargeConstant, assembler) {
  __ movq(RAX, Immediate(kLargeConstant));
  __ ret();
}


ASSEMBLER_TEST_RUN(LargeConstant, entry) {
  typedef int64_t (*LargeConstantCode)();
  EXPECT_EQ(kLargeConstant, reinterpret_cast<LargeConstantCode>(entry)());
}


static int ComputeStackSpaceReservation(int needed, int fixed) {
  static const int kFrameAlignment = OS::ActivationFrameAlignment();
  return (kFrameAlignment > 0)
      ? Utils::RoundUp(needed + fixed, kFrameAlignment) - fixed
      : needed;
}


static int LeafReturn42() {
  return 42;
}


static int LeafReturnArgument(int x) {
  return x + 87;
}


ASSEMBLER_TEST_GENERATE(CallSimpleLeaf, assembler) {
  ExternalLabel call1("LeafReturn42", reinterpret_cast<uword>(LeafReturn42));
  ExternalLabel call2("LeafReturnArgument",
                      reinterpret_cast<uword>(LeafReturnArgument));
  int space = ComputeStackSpaceReservation(0, 8);
  __ AddImmediate(RSP, Immediate(-space));
  __ call(&call1);
  __ AddImmediate(RSP, Immediate(space));
  space = ComputeStackSpaceReservation(0, 8);
  __ AddImmediate(RSP, Immediate(-space));
  __ movl(RDI, RAX);
  __ call(&call2);
  __ AddImmediate(RSP, Immediate(space));
  __ ret();
}


ASSEMBLER_TEST_RUN(CallSimpleLeaf, entry) {
  typedef int (*CallSimpleLeafCode)();
  EXPECT_EQ(42 + 87, reinterpret_cast<CallSimpleLeafCode>(entry)());
}


ASSEMBLER_TEST_GENERATE(JumpSimpleLeaf, assembler) {
  ExternalLabel call1("LeafReturn42", reinterpret_cast<uword>(LeafReturn42));
  Label L;
  int space = ComputeStackSpaceReservation(0, 8);
  __ AddImmediate(RSP, Immediate(-space));
  __ call(&L);
  __ AddImmediate(RSP, Immediate(space));
  __ ret();
  __ Bind(&L);
  __ jmp(&call1);
}


ASSEMBLER_TEST_RUN(JumpSimpleLeaf, entry) {
  typedef int (*JumpSimpleLeafCode)();
  EXPECT_EQ(42, reinterpret_cast<JumpSimpleLeafCode>(entry)());
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
  __ movss(XMM4, Address(RAX, 0));
  __ movss(XMM0, Address(RAX, 0));
  __ popq(RAX);
  __ popq(R15);  // Callee saved.
  __ ret();
}


ASSEMBLER_TEST_RUN(SingleFPMoves, entry) {
  typedef float (*SingleFPMovesCode)();
  EXPECT_EQ(234, reinterpret_cast<SingleFPMovesCode>(entry)());
}


ASSEMBLER_TEST_GENERATE(SingleFPMoves2, assembler) {
  __ movq(RAX, Immediate(bit_cast<int32_t, float>(234.0f)));
  __ movd(XMM0, RAX);
  __ movss(XMM1, XMM0);
  __ pushq(RAX);
  __ movq(Address(RSP, 0), Immediate(0));
  __ movss(XMM0, Address(RSP, 0));
  __ movss(Address(RSP, 0), XMM1);
  __ movss(XMM0, Address(RSP, 0));
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SingleFPMoves2, entry) {
  typedef float (*SingleFPMoves2Code)();
  EXPECT_EQ(234, reinterpret_cast<SingleFPMoves2Code>(entry)());
}


ASSEMBLER_TEST_GENERATE(SingleFPOperations, assembler) {
  __ pushq(RBX);
  __ pushq(RCX);
  __ movq(RBX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, RBX);
  __ movq(RCX, Immediate(bit_cast<int32_t, float>(3.4f)));
  __ movd(XMM1, RCX);
  __ addss(XMM0, XMM1);  // 15.7f
  __ mulss(XMM0, XMM1);  // 53.38f
  __ subss(XMM0, XMM1);  // 49.98f
  __ divss(XMM0, XMM1);  // 14.7f
  __ popq(RCX);
  __ popq(RBX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SingleFPOperations, entry) {
  typedef float (*SingleFPOperationsCode)();
  float res = reinterpret_cast<SingleFPOperationsCode>(entry)();
  EXPECT_FLOAT_EQ(14.7f, res, 0.001f);
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
  __ movq(Address(RSP, 0), Immediate(0));
  __ movsd(XMM0, Address(RSP, 0));
  __ movsd(Address(RSP, 0), XMM7);
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
  __ movsd(XMM0, Address(RSP, 0));
  __ popq(RAX);
  __ popq(R15);  // Callee saved.
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleFPMoves, entry) {
  typedef double (*DoubleFPMovesCode)();
  EXPECT_FLOAT_EQ(1024.67, reinterpret_cast<DoubleFPMovesCode>(entry)(), 0.001);
}


ASSEMBLER_TEST_GENERATE(DoubleFPOperations, assembler) {
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(12.3)));
  __ pushq(RAX);
  __ movsd(XMM0, Address(RSP, 0));
  __ movq(RAX, Immediate(bit_cast<int64_t, double>(3.4)));
  __ movq(Address(RSP, 0), RAX);
  __ movsd(XMM1, Address(RSP, 0));
  __ addsd(XMM0, XMM1);  // 15.7
  __ mulsd(XMM0, XMM1);  // 53.38
  __ subsd(XMM0, XMM1);  // 49.98
  __ divsd(XMM0, XMM1);  // 14.7
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleFPOperations, entry) {
  typedef double (*SingleFPOperationsCode)();
  double res = reinterpret_cast<SingleFPOperationsCode>(entry)();
  EXPECT_FLOAT_EQ(14.7, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(IntToDoubleConversion, assembler) {
  __ movl(RDX, Immediate(6));
  __ cvtsi2sd(XMM0, RDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(IntToDoubleConversion, entry) {
  typedef double (*IntToDoubleConversionCode)();
  double res = reinterpret_cast<IntToDoubleConversionCode>(entry)();
  EXPECT_FLOAT_EQ(6.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(TestObjectCompare, assembler) {
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Object& obj = Object::ZoneHandle(object_store->smi_class());
  Label fail;
  __ LoadObject(RAX, obj);
  __ CompareObject(RAX, obj);
  __ j(NOT_EQUAL, &fail);
  __ LoadObject(RCX, obj);
  __ CompareObject(RCX, obj);
  __ j(NOT_EQUAL, &fail);
  __ movl(RAX, Immediate(1));  // OK
  __ ret();
  __ Bind(&fail);
  __ movl(RAX, Immediate(0));  // Fail.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestObjectCompare, entry) {
  typedef bool (*TestObjectCompare)();
  bool res = reinterpret_cast<TestObjectCompare>(entry)();
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


ASSEMBLER_TEST_RUN(TestNop, entry) {
  typedef int (*TestNop)();
  int res = reinterpret_cast<TestNop>(entry)();
  EXPECT_EQ(36, res);  // 36 nop bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAlign0, assembler) {
  __ Align(4, 0);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAlign0, entry) {
  typedef int (*TestAlign0)();
  int res = reinterpret_cast<TestAlign0>(entry)();
  EXPECT_EQ(0, res);  // 0 bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAlign1, assembler) {
  __ nop(1);
  __ Align(4, 0);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAlign1, entry) {
  typedef int (*TestAlign1)();
  int res = reinterpret_cast<TestAlign1>(entry)();
  EXPECT_EQ(4, res);  // 4 bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAlign1Offset1, assembler) {
  __ nop(1);
  __ Align(4, 1);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAlign1Offset1, entry) {
  typedef int (*TestAlign1Offset1)();
  int res = reinterpret_cast<TestAlign1Offset1>(entry)();
  EXPECT_EQ(3, res);  // 3 bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAlignLarge, assembler) {
  __ nop(1);
  __ Align(16, 0);
  __ movq(RAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAlignLarge, entry) {
  typedef int (*TestAlignLarge)();
  int res = reinterpret_cast<TestAlignLarge>(entry)();
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
  __ popq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAdds, entry) {
  typedef int (*TestAdds)();
  int res = reinterpret_cast<TestAdds>(entry)();
  EXPECT_EQ(10, res);
}


ASSEMBLER_TEST_GENERATE(TestNot, assembler) {
  __ movq(RAX, Immediate(0xFFFFFFFF00000000));
  __ notq(RAX);
  __ ret();
}


ASSEMBLER_TEST_RUN(TestNot, entry) {
  typedef int (*TestNot)();
  unsigned int res = reinterpret_cast<TestNot>(entry)();
  EXPECT_EQ(0xFFFFFFFF, res);
}


ASSEMBLER_TEST_GENERATE(XorpdZeroing, assembler) {
  __ movsd(XMM0, Address(RSP, kWordSize));
  __ xorpd(XMM0, Address(RSP, kWordSize));
  __ movq(RAX, Immediate(999));
  __ ret();
}


ASSEMBLER_TEST_RUN(XorpdZeroing, entry) {
  typedef double (*XorpdZeroingCode)(double d);
  double res = reinterpret_cast<XorpdZeroingCode>(entry)(12.56e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0001);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
