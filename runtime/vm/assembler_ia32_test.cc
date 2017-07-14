// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ movl(EAX, Immediate(42));
  __ ret();
}

ASSEMBLER_TEST_RUN(Simple, test) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, reinterpret_cast<SimpleCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(ReadArgument, assembler) {
  __ movl(EAX, Address(ESP, kWordSize));
  __ ret();
}

ASSEMBLER_TEST_RUN(ReadArgument, test) {
  typedef int (*ReadArgumentCode)(int n);
  EXPECT_EQ(42, reinterpret_cast<ReadArgumentCode>(test->entry())(42));
  EXPECT_EQ(87, reinterpret_cast<ReadArgumentCode>(test->entry())(87));
}

ASSEMBLER_TEST_GENERATE(AddressingModes, assembler) {
  __ movl(EAX, Address(ESP, 0));
  __ movl(EAX, Address(EBP, 0));
  __ movl(EAX, Address(EAX, 0));

  __ movl(EAX, Address(ESP, kWordSize));
  __ movl(EAX, Address(EBP, kWordSize));
  __ movl(EAX, Address(EAX, kWordSize));

  __ movl(EAX, Address(ESP, -kWordSize));
  __ movl(EAX, Address(EBP, -kWordSize));
  __ movl(EAX, Address(EAX, -kWordSize));

  __ movl(EAX, Address(ESP, 256 * kWordSize));
  __ movl(EAX, Address(EBP, 256 * kWordSize));
  __ movl(EAX, Address(EAX, 256 * kWordSize));

  __ movl(EAX, Address(ESP, -256 * kWordSize));
  __ movl(EAX, Address(EBP, -256 * kWordSize));
  __ movl(EAX, Address(EAX, -256 * kWordSize));

  __ movl(EAX, Address(EAX, TIMES_1));
  __ movl(EAX, Address(EAX, TIMES_2));
  __ movl(EAX, Address(EAX, TIMES_4));
  __ movl(EAX, Address(EAX, TIMES_8));

  __ movl(EAX, Address(EBP, TIMES_2));
  __ movl(EAX, Address(EAX, TIMES_2));

  __ movl(EAX, Address(EBP, TIMES_2, kWordSize));
  __ movl(EAX, Address(EAX, TIMES_2, kWordSize));

  __ movl(EAX, Address(EBP, TIMES_2, 256 * kWordSize));
  __ movl(EAX, Address(EAX, TIMES_2, 256 * kWordSize));

  __ movl(EAX, Address(EAX, EBP, TIMES_2, 0));
  __ movl(EAX, Address(EAX, EAX, TIMES_2, 0));
  __ movl(EAX, Address(EBP, EBP, TIMES_2, 0));
  __ movl(EAX, Address(EBP, EAX, TIMES_2, 0));
  __ movl(EAX, Address(ESP, EBP, TIMES_2, 0));
  __ movl(EAX, Address(ESP, EAX, TIMES_2, 0));

  __ movl(EAX, Address(EAX, EBP, TIMES_2, kWordSize));
  __ movl(EAX, Address(EAX, EAX, TIMES_2, kWordSize));
  __ movl(EAX, Address(EBP, EBP, TIMES_2, kWordSize));
  __ movl(EAX, Address(EBP, EAX, TIMES_2, kWordSize));
  __ movl(EAX, Address(ESP, EBP, TIMES_2, kWordSize));
  __ movl(EAX, Address(ESP, EAX, TIMES_2, kWordSize));

  __ movl(EAX, Address(EAX, EBP, TIMES_2, 256 * kWordSize));
  __ movl(EAX, Address(EAX, EAX, TIMES_2, 256 * kWordSize));
  __ movl(EAX, Address(EBP, EBP, TIMES_2, 256 * kWordSize));
  __ movl(EAX, Address(EBP, EAX, TIMES_2, 256 * kWordSize));
  __ movl(EAX, Address(ESP, EBP, TIMES_2, 256 * kWordSize));
  __ movl(EAX, Address(ESP, EAX, TIMES_2, 256 * kWordSize));
}

ASSEMBLER_TEST_RUN(AddressingModes, test) {
  // Avoid running the code since it is constructed to lead to crashes.
}

ASSEMBLER_TEST_GENERATE(JumpAroundCrash, assembler) {
  Label done;
  // Make sure all the condition jumps work.
  for (Condition condition = OVERFLOW; condition <= GREATER;
       condition = static_cast<Condition>(condition + 1)) {
    __ j(condition, &done);
  }
  // This isn't strictly necessary, but we do an unconditional
  // jump around the crashing code anyway.
  __ jmp(&done);

  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);

  __ Bind(&done);
  __ ret();
}

ASSEMBLER_TEST_RUN(JumpAroundCrash, test) {
  Instr* instr = Instr::At(test->entry());
  EXPECT(!instr->IsBreakPoint());
  typedef void (*JumpAroundCrashCode)();
  reinterpret_cast<JumpAroundCrashCode>(test->entry())();
}

ASSEMBLER_TEST_GENERATE(NearJumpAroundCrash, assembler) {
  Label done;
  // Make sure all the condition jumps work.
  for (Condition condition = OVERFLOW; condition <= GREATER;
       condition = static_cast<Condition>(condition + 1)) {
    __ j(condition, &done, Assembler::kNearJump);
  }
  // This isn't strictly necessary, but we do an unconditional
  // jump around the crashing code anyway.
  __ jmp(&done, Assembler::kNearJump);

  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);

  __ Bind(&done);
  __ ret();
}

ASSEMBLER_TEST_RUN(NearJumpAroundCrash, test) {
  typedef void (*NearJumpAroundCrashCode)();
  reinterpret_cast<NearJumpAroundCrashCode>(test->entry())();
}

ASSEMBLER_TEST_GENERATE(SimpleLoop, assembler) {
  __ movl(EAX, Immediate(0));
  __ movl(ECX, Immediate(0));
  Label loop;
  __ Bind(&loop);
  __ addl(EAX, Immediate(2));
  __ incl(ECX);
  __ cmpl(ECX, Immediate(87));
  __ j(LESS, &loop);
  __ ret();
}

ASSEMBLER_TEST_RUN(SimpleLoop, test) {
  typedef int (*SimpleLoopCode)();
  EXPECT_EQ(2 * 87, reinterpret_cast<SimpleLoopCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(Cmpb, assembler) {
  Label done;
  __ movl(EAX, Immediate(1));
  __ pushl(Immediate(0xffffff11));
  __ cmpb(Address(ESP, 0), Immediate(0x11));
  __ j(EQUAL, &done, Assembler::kNearJump);
  __ movl(EAX, Immediate(0));
  __ Bind(&done);
  __ popl(ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Cmpb, test) {
  typedef int (*CmpbCode)();
  EXPECT_EQ(1, reinterpret_cast<CmpbCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(Testb, assembler) {
  __ movl(EAX, Immediate(1));
  __ movl(ECX, Immediate(0));
  __ pushl(Immediate(0xffffff11));
  __ testb(Address(ESP, 0), Immediate(0x10));
  // Fail if zero flag set.
  __ cmove(EAX, ECX);
  __ testb(Address(ESP, 0), Immediate(0x20));
  // Fail if zero flag not set.
  __ cmovne(EAX, ECX);
  __ popl(ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Testb, test) {
  typedef int (*TestbCode)();
  EXPECT_EQ(1, reinterpret_cast<TestbCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(Increment, assembler) {
  __ movl(EAX, Immediate(0));
  __ pushl(EAX);
  __ incl(Address(ESP, 0));
  __ movl(ECX, Address(ESP, 0));
  __ incl(ECX);
  __ popl(EAX);
  __ movl(EAX, ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Increment, test) {
  typedef int (*IncrementCode)();
  EXPECT_EQ(2, reinterpret_cast<IncrementCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(Decrement, assembler) {
  __ movl(EAX, Immediate(2));
  __ pushl(EAX);
  __ decl(Address(ESP, 0));
  __ movl(ECX, Address(ESP, 0));
  __ decl(ECX);
  __ popl(EAX);
  __ movl(EAX, ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Decrement, test) {
  typedef int (*DecrementCode)();
  EXPECT_EQ(0, reinterpret_cast<DecrementCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(AddressBinOp, assembler) {
  __ movl(EAX, Address(ESP, kWordSize));
  __ addl(EAX, Address(ESP, kWordSize));
  __ incl(EAX);
  __ subl(EAX, Address(ESP, kWordSize));
  __ imull(EAX, Address(ESP, kWordSize));
  __ ret();
}

ASSEMBLER_TEST_RUN(AddressBinOp, test) {
  typedef int (*AddressBinOpCode)(int a);
  EXPECT_EQ((2 + 2 + 1 - 2) * 2,
            reinterpret_cast<AddressBinOpCode>(test->entry())(2));
}

ASSEMBLER_TEST_GENERATE(SignedMultiply, assembler) {
  __ movl(EAX, Immediate(2));
  __ movl(ECX, Immediate(4));
  __ imull(EAX, ECX);
  __ imull(EAX, Immediate(1000));
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedMultiply, test) {
  typedef int (*SignedMultiply)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(OverflowSignedMultiply, assembler) {
  __ movl(EDX, Immediate(0));
  __ movl(EAX, Immediate(0x0fffffff));
  __ movl(ECX, Immediate(0x0fffffff));
  __ imull(EAX, ECX);
  __ imull(EAX, EDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(OverflowSignedMultiply, test) {
  typedef int (*OverflowSignedMultiply)();
  EXPECT_EQ(0, reinterpret_cast<OverflowSignedMultiply>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(SignedMultiply1, assembler) {
  __ pushl(EBX);  // preserve EBX.
  __ movl(EBX, Immediate(2));
  __ movl(ECX, Immediate(4));
  __ imull(EBX, ECX);
  __ imull(EBX, Immediate(1000));
  __ movl(EAX, EBX);
  __ popl(EBX);  // restore EBX.
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedMultiply1, test) {
  typedef int (*SignedMultiply1)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply1>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(Negate, assembler) {
  __ movl(ECX, Immediate(42));
  __ negl(ECX);
  __ movl(EAX, ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Negate, test) {
  typedef int (*Negate)();
  EXPECT_EQ(-42, reinterpret_cast<Negate>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(BitScanReverse, assembler) {
  __ movl(ECX, Address(ESP, kWordSize));
  __ movl(EAX, Immediate(666));  // Marker for conditional write.
  __ bsrl(EAX, ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(BitScanReverse, test) {
  typedef int (*Bsr)(int input);
  Bsr call = reinterpret_cast<Bsr>(test->entry());
  EXPECT_EQ(666, call(0));
  EXPECT_EQ(0, call(1));
  EXPECT_EQ(1, call(2));
  EXPECT_EQ(1, call(3));
  EXPECT_EQ(2, call(4));
  EXPECT_EQ(5, call(42));
  EXPECT_EQ(31, call(-1));
}

ASSEMBLER_TEST_GENERATE(MoveExtend, assembler) {
  __ pushl(EBX);  // preserve EBX.
  __ movl(EDX, Immediate(0x1234ffff));
  __ movzxb(EAX, DL);   // EAX = 0xff
  __ movsxw(EBX, EDX);  // EBX = -1
  __ movzxw(ECX, EDX);  // ECX = 0xffff
  __ addl(EBX, ECX);
  __ addl(EAX, EBX);
  __ popl(EBX);  // restore EBX.
  __ ret();
}

ASSEMBLER_TEST_RUN(MoveExtend, test) {
  typedef int (*MoveExtend)();
  EXPECT_EQ(0xff - 1 + 0xffff, reinterpret_cast<MoveExtend>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(MoveExtendMemory, assembler) {
  __ pushl(EBX);  // preserve EBX.
  __ movl(EDX, Immediate(0x1234ffff));

  __ pushl(EDX);
  __ movzxb(EAX, Address(ESP, 0));  // EAX = 0xff
  __ movsxw(EBX, Address(ESP, 0));  // EBX = -1
  __ movzxw(ECX, Address(ESP, 0));  // ECX = 0xffff
  __ addl(ESP, Immediate(kWordSize));

  __ addl(EBX, ECX);
  __ addl(EAX, EBX);
  __ popl(EBX);  // restore EBX.
  __ ret();
}

ASSEMBLER_TEST_RUN(MoveExtendMemory, test) {
  typedef int (*MoveExtendMemory)();
  EXPECT_EQ(0xff - 1 + 0xffff,
            reinterpret_cast<MoveExtendMemory>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(Bitwise, assembler) {
  __ movl(ECX, Immediate(42));
  __ xorl(ECX, ECX);
  __ orl(ECX, Immediate(0x100));
  __ movl(EAX, Immediate(0x648));
  __ orl(ECX, EAX);  // 0x748.
  __ movl(EAX, Immediate(0xfff0));
  __ andl(ECX, EAX);  // 0x740.
  __ pushl(Immediate(0xF6FF));
  __ andl(ECX, Address(ESP, 0));  // 0x640.
  __ popl(EAX);                   // Discard.
  __ movl(EAX, Immediate(1));
  __ orl(ECX, EAX);  // 0x641.
  __ pushl(Immediate(0x7));
  __ orl(ECX, Address(ESP, 0));  // 0x647.
  __ popl(EAX);                  // Discard.
  __ xorl(ECX, Immediate(0));    // 0x647.
  __ pushl(Immediate(0x1C));
  __ xorl(ECX, Address(ESP, 0));  // 0x65B.
  __ popl(EAX);                   // Discard.
  __ movl(EAX, Address(ESP, kWordSize));
  __ movl(EDX, Immediate(0xB0));
  __ orl(Address(EAX, 0), EDX);
  __ movl(EAX, ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Bitwise, test) {
  typedef int (*Bitwise)(int* value);
  int value = 0xA;
  const int result = reinterpret_cast<Bitwise>(test->entry())(&value);
  EXPECT_EQ(0x65B, result);
  EXPECT_EQ(0xBA, value);
}

ASSEMBLER_TEST_GENERATE(LogicalOps, assembler) {
  Label donetest1;
  __ movl(EAX, Immediate(4));
  __ andl(EAX, Immediate(2));
  __ cmpl(EAX, Immediate(0));
  __ j(EQUAL, &donetest1);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest1);

  Label donetest2;
  __ movl(ECX, Immediate(4));
  __ andl(ECX, Immediate(4));
  __ cmpl(ECX, Immediate(0));
  __ j(NOT_EQUAL, &donetest2);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest2);

  Label donetest3;
  __ movl(EAX, Immediate(0));
  __ orl(EAX, Immediate(0));
  __ cmpl(EAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest3);

  Label donetest4;
  __ movl(EAX, Immediate(4));
  __ orl(EAX, Immediate(0));
  __ cmpl(EAX, Immediate(0));
  __ j(NOT_EQUAL, &donetest4);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest4);

  Label donetest5;
  __ movl(EAX, Immediate(1));
  __ shll(EAX, Immediate(1));
  __ cmpl(EAX, Immediate(2));
  __ j(EQUAL, &donetest5);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest5);

  Label donetest6;
  __ movl(EAX, Immediate(1));
  __ shll(EAX, Immediate(3));
  __ cmpl(EAX, Immediate(8));
  __ j(EQUAL, &donetest6);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest6);

  Label donetest7;
  __ movl(EAX, Immediate(2));
  __ shrl(EAX, Immediate(1));
  __ cmpl(EAX, Immediate(1));
  __ j(EQUAL, &donetest7);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest7);

  Label donetest8;
  __ movl(EAX, Immediate(8));
  __ shrl(EAX, Immediate(3));
  __ cmpl(EAX, Immediate(1));
  __ j(EQUAL, &donetest8);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest8);

  Label donetest9;
  __ movl(EAX, Immediate(1));
  __ movl(ECX, Immediate(3));
  __ shll(EAX, ECX);
  __ cmpl(EAX, Immediate(8));
  __ j(EQUAL, &donetest9);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest9);

  Label donetest10;
  __ movl(EAX, Immediate(8));
  __ movl(ECX, Immediate(3));
  __ shrl(EAX, ECX);
  __ cmpl(EAX, Immediate(1));
  __ j(EQUAL, &donetest10);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest10);

  Label donetest11;
  __ movl(EAX, Immediate(1));
  __ shll(EAX, Immediate(31));
  __ shrl(EAX, Immediate(3));
  __ cmpl(EAX, Immediate(0x10000000));
  __ j(EQUAL, &donetest11);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest11);

  Label donetest12;
  __ movl(EAX, Immediate(1));
  __ shll(EAX, Immediate(31));
  __ sarl(EAX, Immediate(3));
  __ cmpl(EAX, Immediate(0xf0000000));
  __ j(EQUAL, &donetest12);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest12);

  Label donetest13;
  __ movl(EAX, Immediate(1));
  __ movl(ECX, Immediate(3));
  __ shll(EAX, Immediate(31));
  __ sarl(EAX, ECX);
  __ cmpl(EAX, Immediate(0xf0000000));
  __ j(EQUAL, &donetest13);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest13);

  Label donetest14;
  __ subl(ESP, Immediate(kWordSize));
  __ movl(Address(ESP, 0), Immediate(0x80000000));
  __ movl(EAX, Immediate(0));
  __ movl(ECX, Immediate(3));
  __ sarl(Address(ESP, 0), ECX);
  __ shrdl(Address(ESP, 0), EAX, ECX);
  __ cmpl(Address(ESP, 0), Immediate(0x1e000000));
  __ j(EQUAL, &donetest14);
  __ int3();
  __ Bind(&donetest14);
  __ addl(ESP, Immediate(kWordSize));

  Label donetest15;
  __ subl(ESP, Immediate(kWordSize));
  __ movl(Address(ESP, 0), Immediate(0xFF000000));
  __ movl(EAX, Immediate(-1));
  __ movl(ECX, Immediate(2));
  __ shll(Address(ESP, 0), ECX);
  __ shldl(Address(ESP, 0), EAX, ECX);
  __ cmpl(Address(ESP, 0), Immediate(0xF0000003));
  __ j(EQUAL, &donetest15);
  __ int3();
  __ Bind(&donetest15);
  __ addl(ESP, Immediate(kWordSize));

  Label donetest16;
  __ movl(EDX, Immediate(0x80000000));
  __ movl(EAX, Immediate(0));
  __ movl(ECX, Immediate(3));
  __ sarl(EDX, Immediate(3));
  __ shrdl(EDX, EAX, Immediate(3));
  __ cmpl(EDX, Immediate(0x1e000000));
  __ j(EQUAL, &donetest16);
  __ int3();
  __ Bind(&donetest16);

  Label donetest17;
  __ movl(EDX, Immediate(0xFF000000));
  __ movl(EAX, Immediate(-1));
  __ shll(EDX, Immediate(2));
  __ shldl(EDX, EAX, Immediate(2));
  __ cmpl(EDX, Immediate(0xF0000003));
  __ j(EQUAL, &donetest17);
  __ int3();
  __ Bind(&donetest17);

  __ movl(EAX, Immediate(0));
  __ ret();
}

ASSEMBLER_TEST_RUN(LogicalOps, test) {
  typedef int (*LogicalOpsCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalOpsCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(LogicalTest, assembler) {
  __ pushl(EBX);  // save EBX.
  Label donetest1;
  __ movl(EAX, Immediate(4));
  __ movl(ECX, Immediate(2));
  __ testl(EAX, ECX);
  __ j(EQUAL, &donetest1);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest1);

  Label donetest2;
  __ movl(EDX, Immediate(4));
  __ movl(ECX, Immediate(4));
  __ testl(EDX, ECX);
  __ j(NOT_EQUAL, &donetest2);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest2);

  Label donetest3;
  __ movl(EAX, Immediate(0));
  __ testl(EAX, Immediate(0));
  __ j(EQUAL, &donetest3);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest3);

  Label donetest4;
  __ movl(EBX, Immediate(4));
  __ testl(EBX, Immediate(4));
  __ j(NOT_EQUAL, &donetest4);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest4);

  Label donetest5;
  __ movl(EBX, Immediate(0xff));
  __ testl(EBX, Immediate(0xff));
  __ j(NOT_EQUAL, &donetest5);
  // Be sure to skip this crashing code.
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);
  __ Bind(&donetest5);

  __ movl(EAX, Immediate(0));
  __ popl(EBX);  // restore EBX.
  __ ret();
}

ASSEMBLER_TEST_RUN(LogicalTest, test) {
  typedef int (*LogicalTestCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalTestCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(CompareSwapEQ, assembler) {
  __ movl(EAX, Immediate(0));
  __ pushl(EAX);
  __ movl(EAX, Immediate(4));
  __ movl(ECX, Immediate(0));
  __ movl(Address(ESP, 0), EAX);
  __ LockCmpxchgl(Address(ESP, 0), ECX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(CompareSwapEQ, test) {
  typedef int (*CompareSwapEQCode)();
  EXPECT_EQ(0, reinterpret_cast<CompareSwapEQCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(CompareSwapNEQ, assembler) {
  __ movl(EAX, Immediate(0));
  __ pushl(EAX);
  __ movl(EAX, Immediate(2));
  __ movl(ECX, Immediate(4));
  __ movl(Address(ESP, 0), ECX);
  __ LockCmpxchgl(Address(ESP, 0), ECX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(CompareSwapNEQ, test) {
  typedef int (*CompareSwapNEQCode)();
  EXPECT_EQ(4, reinterpret_cast<CompareSwapNEQCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(SignedDivide, assembler) {
  __ movl(EAX, Immediate(-87));
  __ movl(EDX, Immediate(123));
  __ cdq();
  __ movl(ECX, Immediate(42));
  __ idivl(ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SignedDivide, test) {
  typedef int (*SignedDivide)();
  EXPECT_EQ(-87 / 42, reinterpret_cast<SignedDivide>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(UnsignedDivide, assembler) {
  __ movl(EAX, Immediate(0xffffffbe));
  __ movl(EDX, Immediate(0x41));
  __ movl(ECX, Immediate(-1));
  __ divl(ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(UnsignedDivide, test) {
  typedef int (*UnsignedDivide)();
  EXPECT_EQ(0x42, reinterpret_cast<UnsignedDivide>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(Exchange, assembler) {
  __ movl(EAX, Immediate(123456789));
  __ movl(EDX, Immediate(987654321));
  __ xchgl(EAX, EDX);
  __ subl(EAX, EDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Exchange, test) {
  typedef int (*Exchange)();
  EXPECT_EQ(987654321 - 123456789, reinterpret_cast<Exchange>(test->entry())());
}

static int ComputeStackSpaceReservation(int needed, int fixed) {
  return (OS::ActivationFrameAlignment() > 1)
             ? Utils::RoundUp(needed + fixed, OS::ActivationFrameAlignment()) -
                   fixed
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
  int space = ComputeStackSpaceReservation(0, 4);
  __ AddImmediate(ESP, Immediate(-space));
  __ call(&call1);
  __ AddImmediate(ESP, Immediate(space));
  space = ComputeStackSpaceReservation(4, 4);
  __ AddImmediate(ESP, Immediate(-space));
  __ movl(Address(ESP, 0), EAX);
  __ call(&call2);
  __ AddImmediate(ESP, Immediate(space));
  __ ret();
}

ASSEMBLER_TEST_RUN(CallSimpleLeaf, test) {
  typedef int (*CallSimpleLeafCode)();
  EXPECT_EQ(42 + 87, reinterpret_cast<CallSimpleLeafCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(JumpSimpleLeaf, assembler) {
  ExternalLabel call1(reinterpret_cast<uword>(LeafReturn42));
  Label L;
  int space = ComputeStackSpaceReservation(0, 4);
  __ AddImmediate(ESP, Immediate(-space));
  __ call(&L);
  __ AddImmediate(ESP, Immediate(space));
  __ ret();
  __ Bind(&L);
  __ jmp(&call1);
}

ASSEMBLER_TEST_RUN(JumpSimpleLeaf, test) {
  typedef int (*JumpSimpleLeafCode)();
  EXPECT_EQ(42, reinterpret_cast<JumpSimpleLeafCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(JumpConditionalSimpleLeaf, assembler) {
  ExternalLabel call1(reinterpret_cast<uword>(LeafReturn42));
  Label L;
  int space = ComputeStackSpaceReservation(0, 4);
  __ AddImmediate(ESP, Immediate(-space));
  __ call(&L);
  __ AddImmediate(ESP, Immediate(space));
  __ ret();
  __ Bind(&L);
  __ cmpl(EAX, EAX);
  __ j(EQUAL, &call1);
  __ int3();
}

ASSEMBLER_TEST_RUN(JumpConditionalSimpleLeaf, test) {
  typedef int (*JumpConditionalSimpleLeafCode)();
  EXPECT_EQ(42,
            reinterpret_cast<JumpConditionalSimpleLeafCode>(test->entry())());
}

ASSEMBLER_TEST_GENERATE(SingleFPMoves, assembler) {
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(234.0f)));
  __ movd(XMM0, EAX);
  __ movss(XMM1, XMM0);
  __ movss(XMM2, XMM1);
  __ movss(XMM3, XMM2);
  __ movss(XMM4, XMM3);
  __ movss(XMM5, XMM4);
  __ movss(XMM6, XMM5);
  __ movss(XMM7, XMM6);
  __ pushl(EAX);
  __ movl(Address(ESP, 0), Immediate(0));
  __ movss(Address(ESP, 0), XMM7);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SingleFPMoves, test) {
  typedef float (*SingleFPMovesCode)();
  float res = reinterpret_cast<SingleFPMovesCode>(test->entry())();
  EXPECT_EQ(234.0f, res);
}

ASSEMBLER_TEST_GENERATE(SingleFPMoves2, assembler) {
  __ pushl(EBX);  // preserve EBX.
  __ pushl(ECX);  // preserve ECX.
  __ movl(EBX, Immediate(bit_cast<int32_t, float>(234.0f)));
  __ movd(XMM0, EBX);
  __ movss(XMM1, XMM0);
  __ movd(ECX, XMM1);
  __ pushl(ECX);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ popl(ECX);
  __ popl(EBX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SingleFPMoves2, test) {
  typedef float (*SingleFPMoves2Code)();
  float res = reinterpret_cast<SingleFPMoves2Code>(test->entry())();
  EXPECT_EQ(234.0f, res);
}

ASSEMBLER_TEST_GENERATE(SingleFPUStackMoves, assembler) {
  __ movl(EAX, Immediate(1131020288));  // 234.0f
  __ pushl(EAX);
  __ flds(Address(ESP, 0));
  __ xorl(ECX, ECX);
  __ pushl(ECX);
  __ fstps(Address(ESP, 0));
  __ popl(EAX);
  __ popl(ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SingleFPUStackMoves, test) {
  typedef int (*SingleFPUStackMovesCode)();
  int res = reinterpret_cast<SingleFPUStackMovesCode>(test->entry())();
  EXPECT_EQ(234.0f, (bit_cast<float, int>(res)));
}

ASSEMBLER_TEST_GENERATE(SingleFPOperations, assembler) {
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, EAX);
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(3.4f)));
  __ movd(XMM1, EAX);
  __ addss(XMM0, XMM1);  // 15.7f
  __ mulss(XMM0, XMM1);  // 53.38f
  __ subss(XMM0, XMM1);  // 49.98f
  __ divss(XMM0, XMM1);  // 14.7f
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SingleFPOperations, test) {
  typedef float (*SingleFPOperationsCode)();
  float res = reinterpret_cast<SingleFPOperationsCode>(test->entry())();
  EXPECT_FLOAT_EQ(14.7f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(PackedFPOperations, assembler) {
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, EAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(3.4f)));
  __ movd(XMM1, EAX);
  __ shufps(XMM1, XMM1, Immediate(0x0));
  __ addps(XMM0, XMM1);                    // 15.7f
  __ mulps(XMM0, XMM1);                    // 53.38f
  __ subps(XMM0, XMM1);                    // 49.98f
  __ divps(XMM0, XMM1);                    // 14.7f
  __ shufps(XMM0, XMM0, Immediate(0x55));  // Copy second lane into all 4 lanes.
  __ pushl(EAX);
  // Copy the low lane at ESP.
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedFPOperations, test) {
  typedef float (*PackedFPOperationsCode)();
  float res = reinterpret_cast<PackedFPOperationsCode>(test->entry())();
  EXPECT_FLOAT_EQ(14.7f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(PackedIntOperations, assembler) {
  __ movl(EAX, Immediate(0x2));
  __ movd(XMM0, EAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ movl(EAX, Immediate(0x1));
  __ movd(XMM1, EAX);
  __ shufps(XMM1, XMM1, Immediate(0x0));
  __ addpl(XMM0, XMM1);  // 0x3
  __ addpl(XMM0, XMM0);  // 0x6
  __ subpl(XMM0, XMM1);  // 0x5
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedIntOperations, test) {
  typedef uint32_t (*PackedIntOperationsCode)();
  uint32_t res = reinterpret_cast<PackedIntOperationsCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x5), res);
}

ASSEMBLER_TEST_GENERATE(PackedFPOperations2, assembler) {
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ movd(XMM0, EAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));

  __ movaps(XMM1, XMM0);                   // Copy XMM0
  __ reciprocalps(XMM1);                   // 0.25
  __ sqrtps(XMM1);                         // 0.5
  __ rsqrtps(XMM0);                        // ~0.5
  __ subps(XMM0, XMM1);                    // ~0.0
  __ shufps(XMM0, XMM0, Immediate(0x00));  // Copy second lane into all 4 lanes.
  __ pushl(EAX);
  // Copy the low lane at ESP.
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedFPOperations2, test) {
  typedef float (*PackedFPOperations2Code)();
  float res = reinterpret_cast<PackedFPOperations2Code>(test->entry())();
  EXPECT_FLOAT_EQ(0.0f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(PackedCompareEQ, assembler) {
  __ set1ps(XMM0, EAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, EAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppseq(XMM0, XMM1);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareEQ, test) {
  typedef uint32_t (*PackedCompareEQCode)();
  uint32_t res = reinterpret_cast<PackedCompareEQCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
}

ASSEMBLER_TEST_GENERATE(PackedCompareNEQ, assembler) {
  __ set1ps(XMM0, EAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, EAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsneq(XMM0, XMM1);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareNEQ, test) {
  typedef uint32_t (*PackedCompareNEQCode)();
  uint32_t res = reinterpret_cast<PackedCompareNEQCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0xFFFFFFFF), res);
}

ASSEMBLER_TEST_GENERATE(PackedCompareLT, assembler) {
  __ set1ps(XMM0, EAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, EAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppslt(XMM0, XMM1);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareLT, test) {
  typedef uint32_t (*PackedCompareLTCode)();
  uint32_t res = reinterpret_cast<PackedCompareLTCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0xFFFFFFFF), res);
}

ASSEMBLER_TEST_GENERATE(PackedCompareLE, assembler) {
  __ set1ps(XMM0, EAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, EAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsle(XMM0, XMM1);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareLE, test) {
  typedef uint32_t (*PackedCompareLECode)();
  uint32_t res = reinterpret_cast<PackedCompareLECode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0xFFFFFFFF), res);
}

ASSEMBLER_TEST_GENERATE(PackedCompareNLT, assembler) {
  __ set1ps(XMM0, EAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, EAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsnlt(XMM0, XMM1);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareNLT, test) {
  typedef uint32_t (*PackedCompareNLTCode)();
  uint32_t res = reinterpret_cast<PackedCompareNLTCode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
}

ASSEMBLER_TEST_GENERATE(PackedCompareNLE, assembler) {
  __ set1ps(XMM0, EAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, EAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ cmppsnle(XMM0, XMM1);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedCompareNLE, test) {
  typedef uint32_t (*PackedCompareNLECode)();
  uint32_t res = reinterpret_cast<PackedCompareNLECode>(test->entry())();
  EXPECT_EQ(static_cast<uword>(0x0), res);
}

ASSEMBLER_TEST_GENERATE(PackedNegate, assembler) {
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, EAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ negateps(XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xAA));  // Copy third lane into all 4 lanes.
  __ pushl(EAX);
  // Copy the low lane at ESP.
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedNegate, test) {
  typedef float (*PackedNegateCode)();
  float res = reinterpret_cast<PackedNegateCode>(test->entry())();
  EXPECT_FLOAT_EQ(-12.3f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(PackedAbsolute, assembler) {
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(-15.3f)));
  __ movd(XMM0, EAX);
  __ shufps(XMM0, XMM0, Immediate(0x0));
  __ absps(XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xAA));  // Copy third lane into all 4 lanes.
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedAbsolute, test) {
  typedef float (*PackedAbsoluteCode)();
  float res = reinterpret_cast<PackedAbsoluteCode>(test->entry())();
  EXPECT_FLOAT_EQ(15.3f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(PackedSetWZero, assembler) {
  __ set1ps(XMM0, EAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ zerowps(XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xFF));  // Copy the W lane which is now 0.0.
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedSetWZero, test) {
  typedef float (*PackedSetWZeroCode)();
  float res = reinterpret_cast<PackedSetWZeroCode>(test->entry())();
  EXPECT_FLOAT_EQ(0.0f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(PackedMin, assembler) {
  __ set1ps(XMM0, EAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, EAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ minps(XMM0, XMM1);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedMin, test) {
  typedef float (*PackedMinCode)();
  float res = reinterpret_cast<PackedMinCode>(test->entry())();
  EXPECT_FLOAT_EQ(2.0f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(PackedMax, assembler) {
  __ set1ps(XMM0, EAX, Immediate(bit_cast<int32_t, float>(2.0f)));
  __ set1ps(XMM1, EAX, Immediate(bit_cast<int32_t, float>(4.0f)));
  __ maxps(XMM0, XMM1);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant1 = {0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0};
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant2 = {0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant2)));
  __ orps(XMM0, XMM1);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant1 = {0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0, 0xF0F0F0F0};
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } constant2 = {0x0F0FFF0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  __ andps(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant2)));
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant1 = {0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  __ notps(XMM0);
  // Copy the low lane at ESP.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM0 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  // XMM0 = 7.0f, 8.0f, 3.0f, 4.0f.
  __ movhlps(XMM0, XMM1);
  __ xorps(XMM1, XMM1);
  // XMM1 = 7.0f, 8.0f, 3.0f, 4.0f.
  __ movaps(XMM1, XMM0);
  __ shufps(XMM0, XMM0, Immediate(0x00));  // 7.0f.
  __ shufps(XMM1, XMM1, Immediate(0x55));  // 8.0f.
  __ addss(XMM0, XMM1);                    // 15.0f.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM0 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  // XMM0 = 1.0f, 2.0f, 5.0f, 6.0f
  __ movlhps(XMM0, XMM1);
  __ xorps(XMM1, XMM1);
  // XMM1 = 1.0f, 2.0f, 5.0f, 6.0f
  __ movaps(XMM1, XMM0);
  __ shufps(XMM0, XMM0, Immediate(0xAA));  // 5.0f.
  __ shufps(XMM1, XMM1, Immediate(0xFF));  // 6.0f.
  __ addss(XMM0, XMM1);                    // 11.0f.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM0 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  // XMM0 = 1.0f, 5.0f, 2.0f, 6.0f.
  __ unpcklps(XMM0, XMM1);
  // XMM1 = 1.0f, 5.0f, 2.0f, 6.0f.
  __ movaps(XMM1, XMM0);
  __ shufps(XMM0, XMM0, Immediate(0x55));
  __ shufps(XMM1, XMM1, Immediate(0xFF));
  __ addss(XMM0, XMM1);  // 11.0f.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM0 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  // XMM0 = 3.0f, 7.0f, 4.0f, 8.0f.
  __ unpckhps(XMM0, XMM1);
  // XMM1 = 3.0f, 7.0f, 4.0f, 8.0f.
  __ movaps(XMM1, XMM0);
  __ shufps(XMM0, XMM0, Immediate(0x00));
  __ shufps(XMM1, XMM1, Immediate(0xAA));
  __ addss(XMM0, XMM1);  // 7.0f.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM0 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  // XMM0 = 1.0f, 2.0f, 5.0f, 6.0f.
  __ unpcklpd(XMM0, XMM1);
  // XMM1 = 1.0f, 2.0f, 5.0f, 6.0f.
  __ movaps(XMM1, XMM0);
  __ shufps(XMM0, XMM0, Immediate(0x00));
  __ shufps(XMM1, XMM1, Immediate(0xAA));
  __ addss(XMM0, XMM1);  // 6.0f.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant0 = {1.0, 2.0, 3.0, 4.0};
  static const struct ALIGN16 {
    float a;
    float b;
    float c;
    float d;
  } constant1 = {5.0, 6.0, 7.0, 8.0};
  // XMM0 = 1.0f, 2.0f, 3.0f, 4.0f.
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  // XMM1 = 5.0f, 6.0f, 7.0f, 8.0f.
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  // XMM0 = 3.0f, 4.0f, 7.0f, 8.0f.
  __ unpckhpd(XMM0, XMM1);
  // XMM1 = 3.0f, 4.0f, 7.0f, 8.0f.
  __ movaps(XMM1, XMM0);
  __ shufps(XMM0, XMM0, Immediate(0x55));
  __ shufps(XMM1, XMM1, Immediate(0xFF));
  __ addss(XMM0, XMM1);  // 12.0f.
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedUnpackHighPair, test) {
  typedef float (*PackedUnpackHighPair)();
  float res = reinterpret_cast<PackedUnpackHighPair>(test->entry())();
  EXPECT_FLOAT_EQ(12.0f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(PackedDoubleAdd, assembler) {
  static const struct ALIGN16 {
    double a;
    double b;
  } constant0 = {1.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  __ addpd(XMM0, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {1.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  __ subpd(XMM0, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {1.0, 2.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ negatepd(XMM0);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {-1.0, 2.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ abspd(XMM0);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {3.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  __ mulpd(XMM0, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {9.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  __ divpd(XMM0, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {16.0, 2.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ sqrtpd(XMM0);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {9.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  __ minpd(XMM0, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {9.0, 2.0};
  static const struct ALIGN16 {
    double a;
    double b;
  } constant1 = {3.0, 4.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant1)));
  __ maxpd(XMM0, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {2.0, 9.0};
  __ movups(XMM0, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  // Splat Y across all lanes.
  __ shufpd(XMM0, XMM0, Immediate(0x33));
  // Splat X across all lanes.
  __ shufpd(XMM0, XMM0, Immediate(0x0));
  // Set return value.
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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
  } constant0 = {9.0, 2.0};
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ cvtpd2ps(XMM0, XMM1);
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
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
  } constant0 = {9.0f, 2.0f, 3.0f, 4.0f};
  __ movups(XMM1, Address::Absolute(reinterpret_cast<uword>(&constant0)));
  __ cvtps2pd(XMM0, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(PackedSingleToDouble, test) {
  typedef double (*PackedSingleToDouble)();
  double res = reinterpret_cast<PackedSingleToDouble>(test->entry())();
  EXPECT_FLOAT_EQ(9.0f, res, 0.000001f);
}

ASSEMBLER_TEST_GENERATE(SingleFPOperationsStack, assembler) {
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, EAX);
  __ addss(XMM0, Address(ESP, kWordSize));  // 15.7f
  __ mulss(XMM0, Address(ESP, kWordSize));  // 53.38f
  __ subss(XMM0, Address(ESP, kWordSize));  // 49.98f
  __ divss(XMM0, Address(ESP, kWordSize));  // 14.7f
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SingleFPOperationsStack, test) {
  typedef float (*SingleFPOperationsStackCode)(float f);
  float res = reinterpret_cast<SingleFPOperationsStackCode>(test->entry())(3.4);
  EXPECT_FLOAT_EQ(14.7f, res, 0.001f);
}

ASSEMBLER_TEST_GENERATE(DoubleFPMoves, assembler) {
  int64_t l = bit_cast<int64_t, double>(1024.67);
  __ movl(EAX, Immediate(Utils::High32Bits(l)));
  __ pushl(EAX);
  __ movl(EAX, Immediate(Utils::Low32Bits(l)));
  __ pushl(EAX);
  __ movsd(XMM0, Address(ESP, 0));
  __ movsd(XMM1, XMM0);
  __ movsd(XMM2, XMM1);
  __ movsd(XMM3, XMM2);
  __ movsd(XMM4, XMM3);
  __ movsd(XMM5, XMM4);
  __ movsd(XMM6, XMM5);
  __ movsd(XMM7, XMM6);
  __ movl(Address(ESP, 0), Immediate(0));
  __ movl(Address(ESP, kWordSize), Immediate(0));
  __ movsd(XMM0, Address(ESP, 0));
  __ movsd(Address(ESP, 0), XMM7);
  __ movsd(XMM7, Address(ESP, 0));
  __ movaps(XMM6, XMM7);
  __ movaps(XMM5, XMM6);
  __ movaps(XMM4, XMM5);
  __ movaps(XMM3, XMM4);
  __ movaps(XMM2, XMM3);
  __ movaps(XMM1, XMM2);
  __ movaps(XMM0, XMM1);
  __ movl(Address(ESP, 0), Immediate(0));
  __ movl(Address(ESP, kWordSize), Immediate(0));
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleFPMoves, test) {
  typedef double (*DoubleFPMovesCode)();
  double res = reinterpret_cast<DoubleFPMovesCode>(test->entry())();
  EXPECT_FLOAT_EQ(1024.67, res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(DoubleFPUStackMoves, assembler) {
  int64_t l = bit_cast<int64_t, double>(1024.67);
  __ movl(EAX, Immediate(Utils::High32Bits(l)));
  __ pushl(EAX);
  __ movl(EAX, Immediate(Utils::Low32Bits(l)));
  __ pushl(EAX);
  __ fldl(Address(ESP, 0));
  __ movl(Address(ESP, 0), Immediate(0));
  __ movl(Address(ESP, kWordSize), Immediate(0));
  __ fstpl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleFPUStackMoves, test) {
  typedef int64_t (*DoubleFPUStackMovesCode)();
  int64_t res = reinterpret_cast<DoubleFPUStackMovesCode>(test->entry())();
  EXPECT_FLOAT_EQ(1024.67, (bit_cast<double, int64_t>(res)), 0.001);
}

ASSEMBLER_TEST_GENERATE(DoubleFPOperations, assembler) {
  int64_t l = bit_cast<int64_t, double>(12.3);
  __ movl(EAX, Immediate(Utils::High32Bits(l)));
  __ pushl(EAX);
  __ movl(EAX, Immediate(Utils::Low32Bits(l)));
  __ pushl(EAX);
  __ movsd(XMM0, Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  l = bit_cast<int64_t, double>(3.4);
  __ movl(EAX, Immediate(Utils::High32Bits(l)));
  __ pushl(EAX);
  __ movl(EAX, Immediate(Utils::Low32Bits(l)));
  __ pushl(EAX);
  __ movsd(XMM1, Address(ESP, 0));
  __ addsd(XMM0, XMM1);  // 15.7
  __ mulsd(XMM0, XMM1);  // 53.38
  __ subsd(XMM0, XMM1);  // 49.98
  __ divsd(XMM0, XMM1);  // 14.7
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleFPOperations, test) {
  typedef double (*DoubleFPOperationsCode)();
  double res = reinterpret_cast<DoubleFPOperationsCode>(test->entry())();
  EXPECT_FLOAT_EQ(14.7, res, 0.001);
}

ASSEMBLER_TEST_GENERATE(DoubleFPOperationsStack, assembler) {
  int64_t l = bit_cast<int64_t, double>(12.3);
  __ movl(EAX, Immediate(Utils::High32Bits(l)));
  __ pushl(EAX);
  __ movl(EAX, Immediate(Utils::Low32Bits(l)));
  __ pushl(EAX);
  __ movsd(XMM0, Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);

  __ addsd(XMM0, Address(ESP, kWordSize));  // 15.7
  __ mulsd(XMM0, Address(ESP, kWordSize));  // 53.38
  __ subsd(XMM0, Address(ESP, kWordSize));  // 49.98
  __ divsd(XMM0, Address(ESP, kWordSize));  // 14.7

  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleFPOperationsStack, test) {
  typedef double (*DoubleFPOperationsStackCode)(double d);
  double res =
      reinterpret_cast<DoubleFPOperationsStackCode>(test->entry())(3.4);
  EXPECT_FLOAT_EQ(14.7, res, 0.001);
}

ASSEMBLER_TEST_GENERATE(IntToDoubleConversion, assembler) {
  __ movl(EDX, Immediate(6));
  __ cvtsi2sd(XMM1, EDX);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM1);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(IntToDoubleConversion, test) {
  typedef double (*IntToDoubleConversionCode)();
  double res = reinterpret_cast<IntToDoubleConversionCode>(test->entry())();
  EXPECT_FLOAT_EQ(6.0, res, 0.001);
}

ASSEMBLER_TEST_GENERATE(IntToDoubleConversion2, assembler) {
  __ filds(Address(ESP, kWordSize));
  __ ret();
}

ASSEMBLER_TEST_RUN(IntToDoubleConversion2, test) {
  typedef double (*IntToDoubleConversion2Code)(int i);
  double res = reinterpret_cast<IntToDoubleConversion2Code>(test->entry())(3);
  EXPECT_FLOAT_EQ(3.0, res, 0.001);
}

ASSEMBLER_TEST_GENERATE(Int64ToDoubleConversion, assembler) {
  __ movl(EAX, Immediate(0));
  __ movl(EDX, Immediate(6));
  __ pushl(EAX);
  __ pushl(EDX);
  __ fildl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Int64ToDoubleConversion, test) {
  typedef double (*Int64ToDoubleConversionCode)();
  double res = reinterpret_cast<Int64ToDoubleConversionCode>(test->entry())();
  EXPECT_EQ(6.0, res);
}

ASSEMBLER_TEST_GENERATE(NegativeInt64ToDoubleConversion, assembler) {
  __ movl(EAX, Immediate(0xFFFFFFFF));
  __ movl(EDX, Immediate(0xFFFFFFFA));
  __ pushl(EAX);
  __ pushl(EDX);
  __ fildl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(NegativeInt64ToDoubleConversion, test) {
  typedef double (*NegativeInt64ToDoubleConversionCode)();
  double res =
      reinterpret_cast<NegativeInt64ToDoubleConversionCode>(test->entry())();
  EXPECT_EQ(-6.0, res);
}

ASSEMBLER_TEST_GENERATE(IntToFloatConversion, assembler) {
  __ movl(EDX, Immediate(6));
  __ cvtsi2ss(XMM1, EDX);
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM1);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(IntToFloatConversion, test) {
  typedef float (*IntToFloatConversionCode)();
  float res = reinterpret_cast<IntToFloatConversionCode>(test->entry())();
  EXPECT_FLOAT_EQ(6.0, res, 0.001);
}

ASSEMBLER_TEST_GENERATE(FloatToIntConversionRound, assembler) {
  __ movsd(XMM1, Address(ESP, kWordSize));
  __ cvtss2si(EDX, XMM1);
  __ movl(EAX, EDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(FloatToIntConversionRound, test) {
  typedef int (*FloatToIntConversionRoundCode)(float f);
  int res =
      reinterpret_cast<FloatToIntConversionRoundCode>(test->entry())(12.3);
  EXPECT_EQ(12, res);
  res = reinterpret_cast<FloatToIntConversionRoundCode>(test->entry())(12.8);
  EXPECT_EQ(13, res);
}

ASSEMBLER_TEST_GENERATE(FloatToIntConversionTrunc, assembler) {
  __ movsd(XMM1, Address(ESP, kWordSize));
  __ cvttss2si(EDX, XMM1);
  __ movl(EAX, EDX);
  __ ret();
}

ASSEMBLER_TEST_RUN(FloatToIntConversionTrunc, test) {
  typedef int (*FloatToIntConversionTruncCode)(float f);
  int res =
      reinterpret_cast<FloatToIntConversionTruncCode>(test->entry())(12.3);
  EXPECT_EQ(12, res);
  res = reinterpret_cast<FloatToIntConversionTruncCode>(test->entry())(12.8);
  EXPECT_EQ(12, res);
}

ASSEMBLER_TEST_GENERATE(FloatToDoubleConversion, assembler) {
  __ movl(EAX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM1, EAX);
  __ xorl(EAX, EAX);
  __ cvtss2sd(XMM2, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM2);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(FloatToDoubleConversion, test) {
  typedef double (*FloatToDoubleConversionCode)();
  double res = reinterpret_cast<FloatToDoubleConversionCode>(test->entry())();
  EXPECT_FLOAT_EQ(12.3, res, 0.001);
}

ASSEMBLER_TEST_GENERATE(FloatCompare, assembler) {
  // Count errors in EAX. EAX is zero if no errors found.
  Label is_nan, is_above, is_ok, cont_1, cont_2;
  // Test 12.3f vs 12.5f.
  __ xorl(EAX, EAX);
  __ movl(EDX, Immediate(bit_cast<int32_t, float>(12.3f)));
  __ movd(XMM0, EDX);
  __ movl(EDX, Immediate(bit_cast<int32_t, float>(12.5f)));
  __ movd(XMM1, EDX);
  __ comiss(XMM0, XMM1);
  __ j(PARITY_EVEN, &is_nan);
  __ Bind(&cont_1);
  __ j(ABOVE, &is_above);
  __ Bind(&cont_2);
  __ j(BELOW, &is_ok);
  __ incl(EAX);
  __ Bind(&is_ok);

  // Test NaN.
  Label is_nan_ok;
  // Create NaN by dividing 0.0f/0.0f.
  __ movl(EDX, Immediate(bit_cast<int32_t, float>(0.0f)));
  __ movd(XMM1, EDX);
  __ divss(XMM1, XMM1);
  __ comiss(XMM1, XMM1);
  __ j(PARITY_EVEN, &is_nan_ok);
  __ incl(EAX);
  __ Bind(&is_nan_ok);

  // EAX is 0 if all tests passed.
  __ ret();

  __ Bind(&is_nan);
  __ incl(EAX);
  __ jmp(&cont_1);

  __ Bind(&is_above);
  __ incl(EAX);
  __ jmp(&cont_2);
}

ASSEMBLER_TEST_RUN(FloatCompare, test) {
  typedef int (*FloatCompareCode)();
  int res = reinterpret_cast<FloatCompareCode>(test->entry())();
  EXPECT_EQ(0, res);
}

ASSEMBLER_TEST_GENERATE(DoubleCompare, assembler) {
  int64_t a = bit_cast<int64_t, double>(12.3);
  int64_t b = bit_cast<int64_t, double>(12.5);

  __ movl(EDX, Immediate(Utils::High32Bits(a)));
  __ pushl(EDX);
  __ movl(EDX, Immediate(Utils::Low32Bits(a)));
  __ pushl(EDX);
  __ movsd(XMM0, Address(ESP, 0));
  __ popl(EDX);
  __ popl(EDX);

  __ movl(EDX, Immediate(Utils::High32Bits(b)));
  __ pushl(EDX);
  __ movl(EDX, Immediate(Utils::Low32Bits(b)));
  __ pushl(EDX);
  __ movsd(XMM1, Address(ESP, 0));
  __ popl(EDX);
  __ popl(EDX);

  // Count errors in EAX. EAX is zero if no errors found.
  Label is_nan, is_above, is_ok, cont_1, cont_2;
  // Test 12.3 vs 12.5.
  __ xorl(EAX, EAX);
  __ comisd(XMM0, XMM1);
  __ j(PARITY_EVEN, &is_nan);
  __ Bind(&cont_1);
  __ j(ABOVE, &is_above);
  __ Bind(&cont_2);
  __ j(BELOW, &is_ok);
  __ incl(EAX);
  __ Bind(&is_ok);

  // Test NaN.
  Label is_nan_ok;
  // Create NaN by dividing 0.0d/0.0d.
  int64_t zero = bit_cast<int64_t, double>(0.0);
  __ movl(EDX, Immediate(Utils::High32Bits(zero)));
  __ pushl(EDX);
  __ movl(EDX, Immediate(Utils::Low32Bits(zero)));
  __ pushl(EDX);
  __ movsd(XMM1, Address(ESP, 0));
  __ popl(EDX);
  __ popl(EDX);

  __ divsd(XMM1, XMM1);
  __ comisd(XMM1, XMM1);
  __ j(PARITY_EVEN, &is_nan_ok);
  __ incl(EAX);
  __ Bind(&is_nan_ok);

  // EAX is 0 if all tests passed.
  __ ret();

  __ Bind(&is_nan);
  __ incl(EAX);
  __ jmp(&cont_1);

  __ Bind(&is_above);
  __ incl(EAX);
  __ jmp(&cont_2);
}

ASSEMBLER_TEST_RUN(DoubleCompare, test) {
  typedef int (*DoubleCompareCode)();
  int res = reinterpret_cast<DoubleCompareCode>(test->entry())();
  EXPECT_EQ(0, res);
}

ASSEMBLER_TEST_GENERATE(DoubleToFloatConversion, assembler) {
  int64_t l = bit_cast<int64_t, double>(12.3);
  __ movl(EAX, Immediate(Utils::High32Bits(l)));
  __ pushl(EAX);
  __ movl(EAX, Immediate(Utils::Low32Bits(l)));
  __ pushl(EAX);
  __ movsd(XMM0, Address(ESP, 0));
  __ cvtsd2ss(XMM1, XMM0);
  __ movss(Address(ESP, 0), XMM1);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleToFloatConversion, test) {
  typedef float (*DoubleToFloatConversionCode)();
  float res = reinterpret_cast<DoubleToFloatConversionCode>(test->entry())();
  EXPECT_FLOAT_EQ(12.3f, res, 0.001);
}

ASSEMBLER_TEST_GENERATE(DoubleToIntConversionRound, assembler) {
  __ movsd(XMM3, Address(ESP, kWordSize));
  __ cvtsd2si(EAX, XMM3);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleToIntConversionRound, test) {
  typedef int (*DoubleToIntConversionRoundCode)(double d);
  int res =
      reinterpret_cast<DoubleToIntConversionRoundCode>(test->entry())(12.3);
  EXPECT_EQ(12, res);
  res = reinterpret_cast<DoubleToIntConversionRoundCode>(test->entry())(12.8);
  EXPECT_EQ(13, res);
}

ASSEMBLER_TEST_GENERATE(DoubleToIntConversionTrunc, assembler) {
  __ movsd(XMM3, Address(ESP, kWordSize));
  __ cvttsd2si(EAX, XMM3);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleToIntConversionTrunc, test) {
  typedef int (*DoubleToIntConversionTruncCode)(double d);
  int res =
      reinterpret_cast<DoubleToIntConversionTruncCode>(test->entry())(12.3);
  EXPECT_EQ(12, res);
  res = reinterpret_cast<DoubleToIntConversionTruncCode>(test->entry())(12.8);
  EXPECT_EQ(12, res);
}

ASSEMBLER_TEST_GENERATE(DoubleToDoubleTrunc, assembler) {
  __ movsd(XMM3, Address(ESP, kWordSize));
  __ roundsd(XMM2, XMM3, Assembler::kRoundToZero);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM2);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
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

static const double kDoubleConst = 3.226;

ASSEMBLER_TEST_GENERATE(GlobalAddress, assembler) {
  __ movsd(XMM0, Address::Absolute(reinterpret_cast<uword>(&kDoubleConst)));
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(GlobalAddress, test) {
  typedef double (*GlobalAddressCode)();
  double res = reinterpret_cast<GlobalAddressCode>(test->entry())();
  EXPECT_FLOAT_EQ(kDoubleConst, res, 0.000001);
}

ASSEMBLER_TEST_GENERATE(Sine, assembler) {
  __ flds(Address(ESP, kWordSize));
  __ fsin();
  __ ret();
}

ASSEMBLER_TEST_RUN(Sine, test) {
  typedef float (*SineCode)(float f);
  const float kFloatConst = 0.7;
  float res = reinterpret_cast<SineCode>(test->entry())(kFloatConst);
  EXPECT_FLOAT_EQ(sin(kFloatConst), res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(Cosine, assembler) {
  __ flds(Address(ESP, kWordSize));
  __ fcos();
  __ ret();
}

ASSEMBLER_TEST_RUN(Cosine, test) {
  typedef float (*CosineCode)(float f);
  const float kFloatConst = 0.7;
  float res = reinterpret_cast<CosineCode>(test->entry())(kFloatConst);
  EXPECT_FLOAT_EQ(cos(kFloatConst), res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(SinCos, assembler) {
  __ fldl(Address(ESP, kWordSize));
  __ fsincos();
  __ subl(ESP, Immediate(2 * kWordSize));
  __ fstpl(Address(ESP, 0));  // cos result.
  __ movsd(XMM0, Address(ESP, 0));
  __ fstpl(Address(ESP, 0));  // sin result.
  __ movsd(XMM1, Address(ESP, 0));
  __ subsd(XMM1, XMM0);  // sin - cos.
  __ movsd(Address(ESP, 0), XMM1);
  __ fldl(Address(ESP, 0));
  __ addl(ESP, Immediate(2 * kWordSize));
  __ ret();
}

ASSEMBLER_TEST_RUN(SinCos, test) {
  typedef double (*SinCosCode)(double d);
  const double arg = 1.2345;
  const double expected = sin(arg) - cos(arg);
  double res = reinterpret_cast<SinCosCode>(test->entry())(arg);
  EXPECT_FLOAT_EQ(expected, res, 0.000001);
}

ASSEMBLER_TEST_GENERATE(Tangent, assembler) {
  __ fldl(Address(ESP, kWordSize));
  __ fptan();
  __ ffree(0);
  __ fincstp();
  __ ret();
}

ASSEMBLER_TEST_RUN(Tangent, test) {
  typedef double (*TangentCode)(double d);
  const double kDoubleConst = 0.6108652375000001;
  double res = reinterpret_cast<TangentCode>(test->entry())(kDoubleConst);
  EXPECT_FLOAT_EQ(tan(kDoubleConst), res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(SquareRootFloat, assembler) {
  __ movss(XMM0, Address(ESP, kWordSize));
  __ sqrtss(XMM1, XMM0);
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM1);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SquareRootFloat, test) {
  typedef float (*SquareRootFloatCode)(float f);
  const float kFloatConst = 0.7;
  float res = reinterpret_cast<SquareRootFloatCode>(test->entry())(kFloatConst);
  EXPECT_FLOAT_EQ(sqrt(kFloatConst), res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(SquareRootDouble, assembler) {
  __ movsd(XMM0, Address(ESP, kWordSize));
  __ sqrtsd(XMM1, XMM0);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM1);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(SquareRootDouble, test) {
  typedef double (*SquareRootDoubleCode)(double d);
  const double kDoubleConst = .7;
  double res =
      reinterpret_cast<SquareRootDoubleCode>(test->entry())(kDoubleConst);
  EXPECT_FLOAT_EQ(sqrt(kDoubleConst), res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(FloatNegate, assembler) {
  __ movss(XMM0, Address(ESP, kWordSize));
  __ FloatNegate(XMM0);
  __ pushl(EAX);
  __ movss(Address(ESP, 0), XMM0);
  __ flds(Address(ESP, 0));
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(FloatNegate, test) {
  typedef float (*FloatNegateCode)(float f);
  const float kFloatConst = 12.345;
  float res = reinterpret_cast<FloatNegateCode>(test->entry())(kFloatConst);
  EXPECT_FLOAT_EQ(-kFloatConst, res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(DoubleNegate, assembler) {
  __ movsd(XMM0, Address(ESP, kWordSize));
  __ DoubleNegate(XMM0);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleNegate, test) {
  typedef double (*DoubleNegateCode)(double f);
  const double kDoubleConst = 12.345;
  double res = reinterpret_cast<DoubleNegateCode>(test->entry())(kDoubleConst);
  EXPECT_FLOAT_EQ(-kDoubleConst, res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(LongMulReg, assembler) {
  __ movl(ECX, Address(ESP, kWordSize));
  __ movl(EAX, Address(ESP, 2 * kWordSize));
  __ imull(ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(LongMulReg, test) {
  typedef int64_t (*LongMulRegCode)(int a, int b);
  const int a = -12;
  const int b = 13;
  const int64_t mul_res = a * b;
  int64_t res = reinterpret_cast<LongMulRegCode>(test->entry())(a, b);
  EXPECT_EQ(mul_res, res);
}

ASSEMBLER_TEST_GENERATE(LongMulAddress, assembler) {
  __ movl(EAX, Address(ESP, 2 * kWordSize));
  __ imull(Address(ESP, kWordSize));
  __ ret();
}

ASSEMBLER_TEST_RUN(LongMulAddress, test) {
  typedef int64_t (*LongMulAddressCode)(int a, int b);
  const int a = -12;
  const int b = 13;
  const int64_t mul_res = a * b;
  int64_t res = reinterpret_cast<LongMulAddressCode>(test->entry())(a, b);
  EXPECT_EQ(mul_res, res);
}

ASSEMBLER_TEST_GENERATE(LongUnsignedMulReg, assembler) {
  __ movl(ECX, Address(ESP, kWordSize));
  __ movl(EAX, Address(ESP, 2 * kWordSize));
  __ mull(ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(LongUnsignedMulReg, test) {
  typedef uint64_t (*LongUnsignedMulRegCode)(uint32_t a, uint32_t b);
  uint32_t a = 3;
  uint32_t b = 13;
  uint64_t mul_res = a * b;
  uint64_t res = reinterpret_cast<LongUnsignedMulRegCode>(test->entry())(a, b);
  EXPECT_EQ(mul_res, res);
  a = 4021288948u;
  b = 13;
  res = reinterpret_cast<LongUnsignedMulRegCode>(test->entry())(a, b);
  mul_res = static_cast<uint64_t>(a) * static_cast<uint64_t>(b);
  EXPECT_EQ(mul_res, res);
}

ASSEMBLER_TEST_GENERATE(LongUnsignedMulAddress, assembler) {
  __ movl(EAX, Address(ESP, 2 * kWordSize));
  __ mull(Address(ESP, kWordSize));
  __ ret();
}

ASSEMBLER_TEST_RUN(LongUnsignedMulAddress, test) {
  typedef uint64_t (*LongUnsignedMulAddressCode)(uint32_t a, uint32_t b);
  uint32_t a = 12;
  uint32_t b = 13;
  uint64_t mul_res = a * b;
  uint64_t res =
      reinterpret_cast<LongUnsignedMulAddressCode>(test->entry())(a, b);
  EXPECT_EQ(mul_res, res);
  a = 4294967284u;
  b = 13;
  res = reinterpret_cast<LongUnsignedMulAddressCode>(test->entry())(a, b);
  mul_res = static_cast<uint64_t>(a) * static_cast<uint64_t>(b);
  EXPECT_EQ(mul_res, res);
}

ASSEMBLER_TEST_GENERATE(LongAddReg, assembler) {
  // Preserve clobbered callee-saved register (EBX).
  __ pushl(EBX);
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // left low.
  __ movl(EDX, Address(ESP, 3 * kWordSize));  // left high.
  __ movl(ECX, Address(ESP, 4 * kWordSize));  // right low.
  __ movl(EBX, Address(ESP, 5 * kWordSize));  // right high
  __ addl(EAX, ECX);
  __ adcl(EDX, EBX);
  __ popl(EBX);
  // Result is in EAX/EDX.
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
  __ movl(EAX, Address(ESP, 1 * kWordSize));  // left low.
  __ movl(EDX, Address(ESP, 2 * kWordSize));  // left high.
  __ addl(EAX, Address(ESP, 3 * kWordSize));  // low.
  __ adcl(EDX, Address(ESP, 4 * kWordSize));  // high.
  // Result is in EAX/EDX.
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
  // Preserve clobbered callee-saved register (EBX).
  __ pushl(EBX);
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // left low.
  __ movl(EDX, Address(ESP, 3 * kWordSize));  // left high.
  __ movl(ECX, Address(ESP, 4 * kWordSize));  // right low.
  __ movl(EBX, Address(ESP, 5 * kWordSize));  // right high
  __ subl(EAX, ECX);
  __ sbbl(EDX, EBX);
  __ popl(EBX);
  // Result is in EAX/EDX.
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
  __ movl(EAX, Address(ESP, 1 * kWordSize));  // left low.
  __ movl(EDX, Address(ESP, 2 * kWordSize));  // left high.
  __ subl(EAX, Address(ESP, 3 * kWordSize));  // low.
  __ sbbl(EDX, Address(ESP, 4 * kWordSize));  // high.
  // Result is in EAX/EDX.
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

ASSEMBLER_TEST_GENERATE(LongSubAddress2, assembler) {
  // Preserve clobbered callee-saved register (EBX).
  __ pushl(EBX);
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // left low.
  __ movl(EDX, Address(ESP, 3 * kWordSize));  // left high.
  __ movl(ECX, Address(ESP, 4 * kWordSize));  // right low.
  __ movl(EBX, Address(ESP, 5 * kWordSize));  // right high
  __ subl(ESP, Immediate(2 * kWordSize));
  __ movl(Address(ESP, 0 * kWordSize), EAX);  // left low.
  __ movl(Address(ESP, 1 * kWordSize), EDX);  // left high.
  __ subl(Address(ESP, 0 * kWordSize), ECX);
  __ sbbl(Address(ESP, 1 * kWordSize), EBX);
  __ movl(EAX, Address(ESP, 0 * kWordSize));
  __ movl(EDX, Address(ESP, 1 * kWordSize));
  __ addl(ESP, Immediate(2 * kWordSize));
  __ popl(EBX);
  // Result is in EAX/EDX.
  __ ret();
}

ASSEMBLER_TEST_RUN(LongSubAddress2, test) {
  typedef int64_t (*LongSubAddress2Code)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongSubAddress2Code>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
  a = 600000;
  b = 2147483647;
  res = reinterpret_cast<LongSubAddress2Code>(test->entry())(a, b);
  EXPECT_EQ((a - b), res);
}

ASSEMBLER_TEST_GENERATE(LongAddAddress2, assembler) {
  // Preserve clobbered callee-saved register (EBX).
  __ pushl(EBX);
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // left low.
  __ movl(EDX, Address(ESP, 3 * kWordSize));  // left high.
  __ movl(ECX, Address(ESP, 4 * kWordSize));  // right low.
  __ movl(EBX, Address(ESP, 5 * kWordSize));  // right high
  __ subl(ESP, Immediate(2 * kWordSize));
  __ movl(Address(ESP, 0 * kWordSize), EAX);  // left low.
  __ movl(Address(ESP, 1 * kWordSize), EDX);  // left high.
  __ addl(Address(ESP, 0 * kWordSize), ECX);
  __ adcl(Address(ESP, 1 * kWordSize), EBX);
  __ movl(EAX, Address(ESP, 0 * kWordSize));
  __ movl(EDX, Address(ESP, 1 * kWordSize));
  __ addl(ESP, Immediate(2 * kWordSize));
  __ popl(EBX);
  // Result is in EAX/EDX.
  __ ret();
}

ASSEMBLER_TEST_RUN(LongAddAddress2, test) {
  typedef int64_t (*LongAddAddress2Code)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongAddAddress2Code>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
  a = 600000;
  b = 2147483647;
  res = reinterpret_cast<LongAddAddress2Code>(test->entry())(a, b);
  EXPECT_EQ((a + b), res);
}

// Testing only the lower 64-bit value of 'cvtdq2pd'.
ASSEMBLER_TEST_GENERATE(IntegerToDoubleConversion, assembler) {
  __ movsd(XMM1, Address(ESP, kWordSize));
  __ cvtdq2pd(XMM2, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM2);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(IntegerToDoubleConversion, test) {
  typedef double (*IntegerToDoubleConversionCode)(int32_t);
  const int32_t val = -12;
  double res =
      reinterpret_cast<IntegerToDoubleConversionCode>(test->entry())(val);
  EXPECT_FLOAT_EQ(static_cast<double>(val), res, 0.001);
}

// Implement with truncation.
ASSEMBLER_TEST_GENERATE(FPUStoreLong, assembler) {
  __ fldl(Address(ESP, kWordSize));
  __ pushl(EAX);
  __ pushl(EAX);
  __ fnstcw(Address(ESP, 0));
  __ movzxw(EAX, Address(ESP, 0));
  __ orl(EAX, Immediate(0x0c00));
  __ movw(Address(ESP, kWordSize), EAX);
  __ fldcw(Address(ESP, kWordSize));
  __ pushl(EAX);
  __ pushl(EAX);
  __ fistpl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EDX);
  __ fldcw(Address(ESP, 0));
  __ addl(ESP, Immediate(kWordSize * 2));
  __ ret();
}

ASSEMBLER_TEST_RUN(FPUStoreLong, test) {
  typedef int64_t (*FPUStoreLongCode)(double d);
  double val = 12.2;
  int64_t res = reinterpret_cast<FPUStoreLongCode>(test->entry())(val);
  EXPECT_EQ(static_cast<int64_t>(val), res);
  val = -12.2;
  res = reinterpret_cast<FPUStoreLongCode>(test->entry())(val);
  EXPECT_EQ(static_cast<int64_t>(val), res);
  val = 12.8;
  res = reinterpret_cast<FPUStoreLongCode>(test->entry())(val);
  EXPECT_EQ(static_cast<int64_t>(val), res);
  val = -12.8;
  res = reinterpret_cast<FPUStoreLongCode>(test->entry())(val);
  EXPECT_EQ(static_cast<int64_t>(val), res);
}

ASSEMBLER_TEST_GENERATE(XorpdZeroing, assembler) {
  __ movsd(XMM0, Address(ESP, kWordSize));
  __ xorpd(XMM0, XMM0);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(XorpdZeroing, test) {
  typedef double (*XorpdZeroingCode)(double d);
  double res = reinterpret_cast<XorpdZeroingCode>(test->entry())(12.56e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(Pxor, assembler) {
  __ movsd(XMM0, Address(ESP, kWordSize));
  __ pxor(XMM0, XMM0);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Pxor, test) {
  typedef double (*PxorCode)(double d);
  double res = reinterpret_cast<PxorCode>(test->entry())(12.3456e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0);
}

ASSEMBLER_TEST_GENERATE(Orpd, assembler) {
  __ movsd(XMM0, Address(ESP, kWordSize));
  __ xorpd(XMM1, XMM1);
  __ DoubleNegate(XMM1);
  __ orpd(XMM0, XMM1);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(Orpd, test) {
  typedef double (*OrpdCode)(double d);
  double res = reinterpret_cast<OrpdCode>(test->entry())(12.56e3);
  EXPECT_FLOAT_EQ(-12.56e3, res, 0.0);
}

ASSEMBLER_TEST_GENERATE(Pextrd0, assembler) {
  if (TargetCPUFeatures::sse4_1_supported()) {
    __ movsd(XMM0, Address(ESP, kWordSize));
    __ pextrd(EAX, XMM0, Immediate(0));
  }
  __ ret();
}

ASSEMBLER_TEST_RUN(Pextrd0, test) {
  if (TargetCPUFeatures::sse4_1_supported()) {
    typedef int32_t (*PextrdCode0)(double d);
    int32_t res = reinterpret_cast<PextrdCode0>(test->entry())(123456789);
    EXPECT_EQ(0x54000000, res);
  }
}

ASSEMBLER_TEST_GENERATE(Pextrd1, assembler) {
  if (TargetCPUFeatures::sse4_1_supported()) {
    __ movsd(XMM0, Address(ESP, kWordSize));
    __ pextrd(EAX, XMM0, Immediate(1));
  }
  __ ret();
}

ASSEMBLER_TEST_RUN(Pextrd1, test) {
  if (TargetCPUFeatures::sse4_1_supported()) {
    typedef int32_t (*PextrdCode1)(double d);
    int32_t res = reinterpret_cast<PextrdCode1>(test->entry())(123456789);
    EXPECT_EQ(0x419d6f34, res);
  }
}

ASSEMBLER_TEST_GENERATE(Pmovsxdq, assembler) {
  if (TargetCPUFeatures::sse4_1_supported()) {
    __ movsd(XMM0, Address(ESP, kWordSize));
    __ pmovsxdq(XMM0, XMM0);
    __ pextrd(EAX, XMM0, Immediate(1));
  }
  __ ret();
}

ASSEMBLER_TEST_RUN(Pmovsxdq, test) {
  if (TargetCPUFeatures::sse4_1_supported()) {
    typedef int32_t (*PmovsxdqCode)(double d);
    int32_t res = reinterpret_cast<PmovsxdqCode>(test->entry())(123456789);
    EXPECT_EQ(0, res);
  }
}

ASSEMBLER_TEST_GENERATE(Pcmpeqq, assembler) {
  if (TargetCPUFeatures::sse4_1_supported()) {
    __ movsd(XMM0, Address(ESP, kWordSize));
    __ xorpd(XMM1, XMM1);
    __ pcmpeqq(XMM0, XMM1);
    __ movd(EAX, XMM0);
  }
  __ ret();
}

ASSEMBLER_TEST_RUN(Pcmpeqq, test) {
  if (TargetCPUFeatures::sse4_1_supported()) {
    typedef int32_t (*PcmpeqqCode)(double d);
    int32_t res = reinterpret_cast<PcmpeqqCode>(test->entry())(0);
    EXPECT_EQ(-1, res);
  }
}

ASSEMBLER_TEST_GENERATE(AndPd, assembler) {
  __ movsd(XMM0, Address(ESP, kWordSize));
  __ andpd(XMM0, XMM0);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(AndPd, test) {
  typedef double (*AndpdCode)(double d);
  double res = reinterpret_cast<AndpdCode>(test->entry())(12.56e3);
  EXPECT_FLOAT_EQ(12.56e3, res, 0.0);
}

ASSEMBLER_TEST_GENERATE(Movq, assembler) {
  __ movq(XMM0, Address(ESP, kWordSize));
  __ subl(ESP, Immediate(kDoubleSize));
  __ movq(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ addl(ESP, Immediate(kDoubleSize));
  __ ret();
}

ASSEMBLER_TEST_RUN(Movq, test) {
  typedef double (*MovqCode)(double d);
  double res = reinterpret_cast<MovqCode>(test->entry())(12.34e5);
  EXPECT_FLOAT_EQ(12.34e5, res, 0.0);
}

ASSEMBLER_TEST_GENERATE(DoubleAbs, assembler) {
  __ movsd(XMM0, Address(ESP, kWordSize));
  __ DoubleAbs(XMM0);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM0);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(DoubleAbs, test) {
  typedef double (*DoubleAbsCode)(double d);
  double val = -12.45;
  double res = reinterpret_cast<DoubleAbsCode>(test->entry())(val);
  EXPECT_FLOAT_EQ(-val, res, 0.001);
  val = 12.45;
  res = reinterpret_cast<DoubleAbsCode>(test->entry())(val);
  EXPECT_FLOAT_EQ(val, res, 0.001);
}

ASSEMBLER_TEST_GENERATE(ExtractSignBits, assembler) {
  __ movsd(XMM0, Address(ESP, kWordSize));
  __ movmskpd(EAX, XMM0);
  __ andl(EAX, Immediate(0x1));
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

// Return -1 if signed, 1 if not signed and 0 otherwise.
ASSEMBLER_TEST_GENERATE(ConditionalMovesSign, assembler) {
  // Preserve clobbered callee-saved register (EBX).
  __ pushl(EBX);

  __ movl(EDX, Address(ESP, 2 * kWordSize));
  __ xorl(EAX, EAX);
  __ movl(EBX, Immediate(1));
  __ movl(ECX, Immediate(-1));
  __ testl(EDX, EDX);
  __ cmovs(EAX, ECX);  // return -1.
  __ testl(EDX, EDX);
  __ cmovns(EAX, EBX);  // return 1.

  // Restore callee-saved register (EBX) and return.
  __ popl(EBX);
  __ ret();
}

ASSEMBLER_TEST_RUN(ConditionalMovesSign, test) {
  typedef int (*ConditionalMovesSignCode)(int i);
  int res = reinterpret_cast<ConditionalMovesSignCode>(test->entry())(785);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ConditionalMovesSignCode>(test->entry())(-12);
  EXPECT_EQ(-1, res);
}

// Return 1 if overflow, 0 if no overflow.
ASSEMBLER_TEST_GENERATE(ConditionalMovesNoOverflow, assembler) {
  __ movl(EDX, Address(ESP, 1 * kWordSize));
  __ addl(EDX, Address(ESP, 2 * kWordSize));
  __ movl(EAX, Immediate(1));
  __ movl(ECX, Immediate(0));
  __ cmovno(EAX, ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(ConditionalMovesNoOverflow, test) {
  typedef int (*ConditionalMovesNoOverflowCode)(int i, int j);
  int res = reinterpret_cast<ConditionalMovesNoOverflowCode>(test->entry())(
      0x7fffffff, 2);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ConditionalMovesNoOverflowCode>(test->entry())(1, 1);
  EXPECT_EQ(0, res);
}

// Return 1 if equal, 0 if not equal.
ASSEMBLER_TEST_GENERATE(ConditionalMovesEqual, assembler) {
  __ xorl(EAX, EAX);
  __ movl(ECX, Immediate(1));
  __ movl(EDX, Address(ESP, 1 * kWordSize));
  __ cmpl(EDX, Immediate(785));
  __ cmove(EAX, ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(ConditionalMovesEqual, test) {
  typedef int (*ConditionalMovesEqualCode)(int i);
  int res = reinterpret_cast<ConditionalMovesEqualCode>(test->entry())(785);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ConditionalMovesEqualCode>(test->entry())(-12);
  EXPECT_EQ(0, res);
}

// Return 1 if not equal, 0 if equal.
ASSEMBLER_TEST_GENERATE(ConditionalMovesNotEqual, assembler) {
  __ xorl(EAX, EAX);
  __ movl(ECX, Immediate(1));
  __ movl(EDX, Address(ESP, 1 * kWordSize));
  __ cmpl(EDX, Immediate(785));
  __ cmovne(EAX, ECX);
  __ ret();
}

ASSEMBLER_TEST_RUN(ConditionalMovesNotEqual, test) {
  typedef int (*ConditionalMovesNotEqualCode)(int i);
  int res = reinterpret_cast<ConditionalMovesNotEqualCode>(test->entry())(785);
  EXPECT_EQ(0, res);
  res = reinterpret_cast<ConditionalMovesNotEqualCode>(test->entry())(-12);
  EXPECT_EQ(1, res);
}

ASSEMBLER_TEST_GENERATE(ConditionalMovesCompare, assembler) {
  __ movl(EDX, Immediate(1));   // Greater equal.
  __ movl(ECX, Immediate(-1));  // Less
  __ movl(EAX, Address(ESP, 1 * kWordSize));
  __ cmpl(EAX, Address(ESP, 2 * kWordSize));
  __ cmovlessl(EAX, ECX);
  __ cmovgel(EAX, EDX);
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

ASSEMBLER_TEST_GENERATE(TestLoadDoubleConstant, assembler) {
  __ LoadDoubleConstant(XMM3, -12.34);
  __ pushl(EAX);
  __ pushl(EAX);
  __ movsd(Address(ESP, 0), XMM3);
  __ fldl(Address(ESP, 0));
  __ popl(EAX);
  __ popl(EAX);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestLoadDoubleConstant, test) {
  typedef double (*TestLoadDoubleConstantCode)();
  double res = reinterpret_cast<TestLoadDoubleConstantCode>(test->entry())();
  EXPECT_FLOAT_EQ(-12.34, res, 0.0001);
}

ASSEMBLER_TEST_GENERATE(TestObjectCompare, assembler) {
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Object& obj = Object::ZoneHandle(object_store->smi_class());
  Label fail;
  __ LoadObject(EAX, obj);
  __ CompareObject(EAX, obj);
  __ j(NOT_EQUAL, &fail);
  __ LoadObject(ECX, obj);
  __ CompareObject(ECX, obj);
  __ j(NOT_EQUAL, &fail);
  __ movl(EAX, Immediate(1));  // OK
  __ ret();
  __ Bind(&fail);
  __ movl(EAX, Immediate(0));  // Fail.
  __ ret();
}

ASSEMBLER_TEST_RUN(TestObjectCompare, test) {
  typedef bool (*TestObjectCompare)();
  bool res = reinterpret_cast<TestObjectCompare>(test->entry())();
  EXPECT_EQ(true, res);
}

ASSEMBLER_TEST_GENERATE(TestSetCC, assembler) {
  __ movl(EAX, Immediate(0xFFFFFFFF));
  __ cmpl(EAX, EAX);
  __ setcc(NOT_EQUAL, AL);
  __ ret();
}

ASSEMBLER_TEST_RUN(TestSetCC, test) {
  typedef uword (*TestSetCC)();
  uword res = reinterpret_cast<TestSetCC>(test->entry())();
  EXPECT_EQ(0xFFFFFF00, res);
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
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}

ASSEMBLER_TEST_RUN(TestNop, test) {
  typedef int (*TestNop)();
  int res = reinterpret_cast<TestNop>(test->entry())();
  EXPECT_EQ(36, res);  // 36 nop bytes emitted.
}

ASSEMBLER_TEST_GENERATE(TestAlign0, assembler) {
  __ Align(4, 0);
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
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
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
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
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
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
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}

ASSEMBLER_TEST_RUN(TestAlignLarge, test) {
  typedef int (*TestAlignLarge)();
  int res = reinterpret_cast<TestAlignLarge>(test->entry())();
  EXPECT_EQ(16, res);  // 16 bytes emitted.
}

ASSEMBLER_TEST_GENERATE(TestRepMovsBytes, assembler) {
  // Preserve registers.
  __ pushl(ESI);
  __ pushl(EDI);
  __ pushl(ECX);
  __ movl(ESI, Address(ESP, 4 * kWordSize));  // from.
  __ movl(EDI, Address(ESP, 5 * kWordSize));  // to.
  __ movl(ECX, Address(ESP, 6 * kWordSize));  // count.
  __ rep_movsb();
  __ popl(ECX);
  __ popl(EDI);
  __ popl(ESI);
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
  delete[] to;
}

// Called from assembler_test.cc.
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ pushl(THR);
  __ movl(EAX, Address(ESP, 2 * kWordSize));
  __ movl(ECX, Address(ESP, 3 * kWordSize));
  __ movl(THR, Address(ESP, 4 * kWordSize));
  __ pushl(EAX);
  __ StoreIntoObject(ECX, FieldAddress(ECX, GrowableObjectArray::data_offset()),
                     EAX);
  __ popl(EAX);
  __ popl(THR);
  __ ret();
}

ASSEMBLER_TEST_GENERATE(BitTest, assembler) {
  __ movl(EAX, Immediate(4));
  __ movl(ECX, Immediate(2));
  __ bt(EAX, ECX);
  Label ok;
  __ j(CARRY, &ok);
  __ int3();
  __ Bind(&ok);
  __ movl(EAX, Immediate(1));
  __ ret();
}

ASSEMBLER_TEST_RUN(BitTest, test) {
  typedef int (*BitTest)();
  EXPECT_EQ(1, reinterpret_cast<BitTest>(test->entry())());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
