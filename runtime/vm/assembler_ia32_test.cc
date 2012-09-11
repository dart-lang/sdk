// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->


ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ movl(EAX, Immediate(42));
  __ ret();
}


ASSEMBLER_TEST_RUN(Simple, entry) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, reinterpret_cast<SimpleCode>(entry)());
}


ASSEMBLER_TEST_GENERATE(ReadArgument, assembler) {
  __ movl(EAX, Address(ESP, kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(ReadArgument, entry) {
  typedef int (*ReadArgumentCode)(int n);
  EXPECT_EQ(42, reinterpret_cast<ReadArgumentCode>(entry)(42));
  EXPECT_EQ(87, reinterpret_cast<ReadArgumentCode>(entry)(87));
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
  __ movl(EAX, Immediate(0));
  __ movl(Address(EAX, 0), EAX);

  __ Bind(&done);
  __ ret();
}


ASSEMBLER_TEST_RUN(JumpAroundCrash, entry) {
  Instr* instr = Instr::At(entry);
  EXPECT(!instr->IsBreakPoint());
  typedef void (*JumpAroundCrashCode)();
  reinterpret_cast<JumpAroundCrashCode>(entry)();
}


ASSEMBLER_TEST_GENERATE(NearJumpAroundCrash, assembler) {
  Label done;
  // Make sure all the condition jumps work.
  for (Condition condition = OVERFLOW;
       condition <= GREATER;
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


ASSEMBLER_TEST_RUN(NearJumpAroundCrash, entry) {
  typedef void (*NearJumpAroundCrashCode)();
  reinterpret_cast<NearJumpAroundCrashCode>(entry)();
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


ASSEMBLER_TEST_RUN(SimpleLoop, entry) {
  typedef int (*SimpleLoopCode)();
  EXPECT_EQ(2 * 87, reinterpret_cast<SimpleLoopCode>(entry)());
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


ASSEMBLER_TEST_RUN(Increment, entry) {
  typedef int (*IncrementCode)();
  EXPECT_EQ(2, reinterpret_cast<IncrementCode>(entry)());
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


ASSEMBLER_TEST_RUN(Decrement, entry) {
  typedef int (*DecrementCode)();
  EXPECT_EQ(0, reinterpret_cast<DecrementCode>(entry)());
}


ASSEMBLER_TEST_GENERATE(AddressBinOp, assembler) {
  __ movl(EAX, Address(ESP, kWordSize));
  __ addl(EAX, Address(ESP, kWordSize));
  __ incl(EAX);
  __ subl(EAX, Address(ESP, kWordSize));
  __ imull(EAX, Address(ESP, kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(AddressBinOp, entry) {
  typedef int (*AddressBinOpCode)(int a);
  EXPECT_EQ((2 + 2 + 1 - 2) * 2, reinterpret_cast<AddressBinOpCode>(entry)(2));
}


ASSEMBLER_TEST_GENERATE(SignedMultiply, assembler) {
  __ movl(EAX, Immediate(2));
  __ movl(ECX, Immediate(4));
  __ imull(EAX, ECX);
  __ imull(EAX, Immediate(1000));
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedMultiply, entry) {
  typedef int (*SignedMultiply)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply>(entry)());
}


ASSEMBLER_TEST_GENERATE(OverflowSignedMultiply, assembler) {
  __ movl(EDX, Immediate(0));
  __ movl(EAX, Immediate(0x0fffffff));
  __ movl(ECX, Immediate(0x0fffffff));
  __ imull(EAX, ECX);
  __ imull(EAX, EDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(OverflowSignedMultiply, entry) {
  typedef int (*OverflowSignedMultiply)();
  EXPECT_EQ(0, reinterpret_cast<OverflowSignedMultiply>(entry)());
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


ASSEMBLER_TEST_RUN(SignedMultiply1, entry) {
  typedef int (*SignedMultiply1)();
  EXPECT_EQ(8000, reinterpret_cast<SignedMultiply1>(entry)());
}


ASSEMBLER_TEST_GENERATE(Negate, assembler) {
  __ movl(ECX, Immediate(42));
  __ negl(ECX);
  __ movl(EAX, ECX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Negate, entry) {
  typedef int (*Negate)();
  EXPECT_EQ(-42, reinterpret_cast<Negate>(entry)());
}


ASSEMBLER_TEST_GENERATE(MoveExtend, assembler) {
  __ pushl(EBX);  // preserve EBX.
  __ movl(EDX, Immediate(0x1234ffff));
  __ movzxb(EAX, DL);  // EAX = 0xff
  __ movsxw(EBX, EDX);  // EBX = -1
  __ movzxw(ECX, EDX);  // ECX = 0xffff
  __ addl(EBX, ECX);
  __ addl(EAX, EBX);
  __ popl(EBX);  // restore EBX.
  __ ret();
}


ASSEMBLER_TEST_RUN(MoveExtend, entry) {
  typedef int (*MoveExtend)();
  EXPECT_EQ(0xff - 1 + 0xffff, reinterpret_cast<MoveExtend>(entry)());
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


ASSEMBLER_TEST_RUN(MoveExtendMemory, entry) {
  typedef int (*MoveExtendMemory)();
  EXPECT_EQ(0xff - 1 + 0xffff, reinterpret_cast<MoveExtendMemory>(entry)());
}


ASSEMBLER_TEST_GENERATE(Bitwise, assembler) {
  __ movl(ECX, Immediate(42));
  __ xorl(ECX, ECX);
  __ orl(ECX, Immediate(256));
  __ movl(EAX, Immediate(4));
  __ orl(ECX, EAX);
  __ movl(EAX, Immediate(0xfff0));
  __ andl(ECX, EAX);
  __ movl(EAX, Immediate(1));
  __ orl(ECX, EAX);
  __ xorl(ECX, Immediate(0));
  __ movl(EAX, ECX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Bitwise, entry) {
  typedef int (*Bitwise)();
  EXPECT_EQ(256 + 1, reinterpret_cast<Bitwise>(entry)());
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

  __ movl(EAX, Immediate(0));
  __ ret();
}


ASSEMBLER_TEST_RUN(LogicalOps, entry) {
  typedef int (*LogicalOpsCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalOpsCode>(entry)());
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


ASSEMBLER_TEST_RUN(LogicalTest, entry) {
  typedef int (*LogicalTestCode)();
  EXPECT_EQ(0, reinterpret_cast<LogicalTestCode>(entry)());
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


ASSEMBLER_TEST_RUN(CompareSwapEQ, entry) {
  typedef int (*CompareSwapEQCode)();
  EXPECT_EQ(0, reinterpret_cast<CompareSwapEQCode>(entry)());
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


ASSEMBLER_TEST_RUN(CompareSwapNEQ, entry) {
  typedef int (*CompareSwapNEQCode)();
  EXPECT_EQ(4, reinterpret_cast<CompareSwapNEQCode>(entry)());
}


ASSEMBLER_TEST_GENERATE(SignedDivide, assembler) {
  __ movl(EAX, Immediate(-87));
  __ movl(EDX, Immediate(123));
  __ cdq();
  __ movl(ECX, Immediate(42));
  __ idivl(ECX);
  __ ret();
}


ASSEMBLER_TEST_RUN(SignedDivide, entry) {
  typedef int (*SignedDivide)();
  EXPECT_EQ(-87 / 42, reinterpret_cast<SignedDivide>(entry)());
}


ASSEMBLER_TEST_GENERATE(Exchange, assembler) {
  __ movl(EAX, Immediate(123456789));
  __ movl(EDX, Immediate(987654321));
  __ xchgl(EAX, EDX);
  __ subl(EAX, EDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(Exchange, entry) {
  typedef int (*Exchange)();
  EXPECT_EQ(987654321 - 123456789, reinterpret_cast<Exchange>(entry)());
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


ASSEMBLER_TEST_RUN(CallSimpleLeaf, entry) {
  typedef int (*CallSimpleLeafCode)();
  EXPECT_EQ(42 + 87, reinterpret_cast<CallSimpleLeafCode>(entry)());
}


ASSEMBLER_TEST_GENERATE(JumpSimpleLeaf, assembler) {
  ExternalLabel call1("LeafReturn42", reinterpret_cast<uword>(LeafReturn42));
  Label L;
  int space = ComputeStackSpaceReservation(0, 4);
  __ AddImmediate(ESP, Immediate(-space));
  __ call(&L);
  __ AddImmediate(ESP, Immediate(space));
  __ ret();
  __ Bind(&L);
  __ jmp(&call1);
}


ASSEMBLER_TEST_RUN(JumpSimpleLeaf, entry) {
  typedef int (*JumpSimpleLeafCode)();
  EXPECT_EQ(42, reinterpret_cast<JumpSimpleLeafCode>(entry)());
}


ASSEMBLER_TEST_GENERATE(JumpConditionalSimpleLeaf, assembler) {
  ExternalLabel call1("LeafReturn42", reinterpret_cast<uword>(LeafReturn42));
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


ASSEMBLER_TEST_RUN(JumpConditionalSimpleLeaf, entry) {
  typedef int (*JumpConditionalSimpleLeafCode)();
  EXPECT_EQ(42, reinterpret_cast<JumpConditionalSimpleLeafCode>(entry)());
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


ASSEMBLER_TEST_RUN(SingleFPMoves, entry) {
  typedef float (*SingleFPMovesCode)();
  float res = reinterpret_cast<SingleFPMovesCode>(entry)();
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


ASSEMBLER_TEST_RUN(SingleFPMoves2, entry) {
  typedef float (*SingleFPMoves2Code)();
  float res = reinterpret_cast<SingleFPMoves2Code>(entry)();
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


ASSEMBLER_TEST_RUN(SingleFPUStackMoves, entry) {
  typedef int (*SingleFPUStackMovesCode)();
  int res = reinterpret_cast<SingleFPUStackMovesCode>(entry)();
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


ASSEMBLER_TEST_RUN(SingleFPOperations, entry) {
  typedef float (*SingleFPOperationsCode)();
  float res = reinterpret_cast<SingleFPOperationsCode>(entry)();
  EXPECT_FLOAT_EQ(14.7f, res, 0.001f);
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


ASSEMBLER_TEST_RUN(SingleFPOperationsStack, entry) {
  typedef float (*SingleFPOperationsStackCode)(float f);
  float res = reinterpret_cast<SingleFPOperationsStackCode>(entry)(3.4);
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


ASSEMBLER_TEST_RUN(DoubleFPMoves, entry) {
  typedef double (*DoubleFPMovesCode)();
  double res = reinterpret_cast<DoubleFPMovesCode>(entry)();
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


ASSEMBLER_TEST_RUN(DoubleFPUStackMoves, entry) {
  typedef int64_t (*DoubleFPUStackMovesCode)();
  int64_t res = reinterpret_cast<DoubleFPUStackMovesCode>(entry)();
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


ASSEMBLER_TEST_RUN(DoubleFPOperations, entry) {
  typedef double (*DoubleFPOperationsCode)();
  double res = reinterpret_cast<DoubleFPOperationsCode>(entry)();
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


ASSEMBLER_TEST_RUN(DoubleFPOperationsStack, entry) {
  typedef double (*DoubleFPOperationsStackCode)(double d);
  double res = reinterpret_cast<DoubleFPOperationsStackCode>(entry)(3.4);
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


ASSEMBLER_TEST_RUN(IntToDoubleConversion, entry) {
  typedef double (*IntToDoubleConversionCode)();
  double res = reinterpret_cast<IntToDoubleConversionCode>(entry)();
  EXPECT_FLOAT_EQ(6.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(IntToDoubleConversion2, assembler) {
  __ filds(Address(ESP, kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(IntToDoubleConversion2, entry) {
  typedef double (*IntToDoubleConversion2Code)(int i);
  double res = reinterpret_cast<IntToDoubleConversion2Code>(entry)(3);
  EXPECT_FLOAT_EQ(3.0, res, 0.001);
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


ASSEMBLER_TEST_RUN(IntToFloatConversion, entry) {
  typedef float (*IntToFloatConversionCode)();
  float res = reinterpret_cast<IntToFloatConversionCode>(entry)();
  EXPECT_FLOAT_EQ(6.0, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(FloatToIntConversionRound, assembler) {
  __ movsd(XMM1, Address(ESP, kWordSize));
  __ cvtss2si(EDX, XMM1);
  __ movl(EAX, EDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(FloatToIntConversionRound, entry) {
  typedef int (*FloatToIntConversionRoundCode)(float f);
  int res = reinterpret_cast<FloatToIntConversionRoundCode>(entry)(12.3);
  EXPECT_EQ(12, res);
  res = reinterpret_cast<FloatToIntConversionRoundCode>(entry)(12.8);
  EXPECT_EQ(13, res);
}


ASSEMBLER_TEST_GENERATE(FloatToIntConversionTrunc, assembler) {
  __ movsd(XMM1, Address(ESP, kWordSize));
  __ cvttss2si(EDX, XMM1);
  __ movl(EAX, EDX);
  __ ret();
}


ASSEMBLER_TEST_RUN(FloatToIntConversionTrunc, entry) {
  typedef int (*FloatToIntConversionTruncCode)(float f);
  int res = reinterpret_cast<FloatToIntConversionTruncCode>(entry)(12.3);
  EXPECT_EQ(12, res);
  res = reinterpret_cast<FloatToIntConversionTruncCode>(entry)(12.8);
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


ASSEMBLER_TEST_RUN(FloatToDoubleConversion, entry) {
  typedef double (*FloatToDoubleConversionCode)();
  double res = reinterpret_cast<FloatToDoubleConversionCode>(entry)();
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


ASSEMBLER_TEST_RUN(FloatCompare, entry) {
  typedef int (*FloatCompareCode)();
  int res = reinterpret_cast<FloatCompareCode>(entry)();
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


ASSEMBLER_TEST_RUN(DoubleCompare, entry) {
  typedef int (*DoubleCompareCode)();
  int res = reinterpret_cast<DoubleCompareCode>(entry)();
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


ASSEMBLER_TEST_RUN(DoubleToFloatConversion, entry) {
  typedef float (*DoubleToFloatConversionCode)();
  float res = reinterpret_cast<DoubleToFloatConversionCode>(entry)();
  EXPECT_FLOAT_EQ(12.3f, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(DoubleToIntConversionRound, assembler) {
  __ movsd(XMM3, Address(ESP, kWordSize));
  __ cvtsd2si(EAX, XMM3);
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleToIntConversionRound, entry) {
  typedef int (*DoubleToIntConversionRoundCode)(double d);
  int res = reinterpret_cast<DoubleToIntConversionRoundCode>(entry)(12.3);
  EXPECT_EQ(12, res);
  res = reinterpret_cast<DoubleToIntConversionRoundCode>(entry)(12.8);
  EXPECT_EQ(13, res);
}


ASSEMBLER_TEST_GENERATE(DoubleToIntConversionTrunc, assembler) {
  __ movsd(XMM3, Address(ESP, kWordSize));
  __ cvttsd2si(EAX, XMM3);
  __ ret();
}


ASSEMBLER_TEST_RUN(DoubleToIntConversionTrunc, entry) {
  typedef int (*DoubleToIntConversionTruncCode)(double d);
  int res = reinterpret_cast<DoubleToIntConversionTruncCode>(entry)(12.3);
  EXPECT_EQ(12, res);
  res = reinterpret_cast<DoubleToIntConversionTruncCode>(entry)(12.8);
  EXPECT_EQ(12, res);
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


ASSEMBLER_TEST_RUN(GlobalAddress, entry) {
  typedef double (*GlobalAddressCode)();
  double res = reinterpret_cast<GlobalAddressCode>(entry)();
  EXPECT_FLOAT_EQ(kDoubleConst, res, 0.000001);
}


ASSEMBLER_TEST_GENERATE(Sine, assembler) {
  __ flds(Address(ESP, kWordSize));
  __ fsin();
  __ ret();
}


ASSEMBLER_TEST_RUN(Sine, entry) {
  typedef float (*SineCode)(float f);
  const float kFloatConst = 0.7;
  float res = reinterpret_cast<SineCode>(entry)(kFloatConst);
  EXPECT_FLOAT_EQ(sin(kFloatConst), res, 0.0001);
}


ASSEMBLER_TEST_GENERATE(Cosine, assembler) {
  __ flds(Address(ESP, kWordSize));
  __ fcos();
  __ ret();
}


ASSEMBLER_TEST_RUN(Cosine, entry) {
  typedef float (*CosineCode)(float f);
  const float kFloatConst = 0.7;
  float res = reinterpret_cast<CosineCode>(entry)(kFloatConst);
  EXPECT_FLOAT_EQ(cos(kFloatConst), res, 0.0001);
}


ASSEMBLER_TEST_GENERATE(Tangent, assembler) {
  __ fldl(Address(ESP, kWordSize));
  __ fptan();
  __ ffree(0);
  __ fincstp();
  __ ret();
}


ASSEMBLER_TEST_RUN(Tangent, entry) {
  typedef double (*TangentCode)(double d);
  const double kDoubleConst = 0.6108652375000001;
  double res = reinterpret_cast<TangentCode>(entry)(kDoubleConst);
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


ASSEMBLER_TEST_RUN(SquareRootFloat, entry) {
  typedef float (*SquareRootFloatCode)(float f);
  const float kFloatConst = 0.7;
  float res = reinterpret_cast<SquareRootFloatCode>(entry)(kFloatConst);
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


ASSEMBLER_TEST_RUN(SquareRootDouble, entry) {
  typedef double (*SquareRootDoubleCode)(double d);
  const double kDoubleConst = .7;
  double res = reinterpret_cast<SquareRootDoubleCode>(entry)(kDoubleConst);
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


ASSEMBLER_TEST_RUN(FloatNegate, entry) {
  typedef float (*FloatNegateCode)(float f);
  const float kFloatConst = 12.345;
  float res = reinterpret_cast<FloatNegateCode>(entry)(kFloatConst);
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


ASSEMBLER_TEST_RUN(DoubleNegate, entry) {
  typedef double (*DoubleNegateCode)(double f);
  const double kDoubleConst = 12.345;
  double res = reinterpret_cast<DoubleNegateCode>(entry)(kDoubleConst);
  EXPECT_FLOAT_EQ(-kDoubleConst, res, 0.0001);
}


ASSEMBLER_TEST_GENERATE(LongMulReg, assembler) {
  __ movl(ECX, Address(ESP, kWordSize));
  __ movl(EAX, Address(ESP, 2 * kWordSize));
  __ imull(ECX);
  __ ret();
}


ASSEMBLER_TEST_RUN(LongMulReg, entry) {
  typedef int64_t (*LongMulRegCode)(int a, int b);
  const int a = -12;
  const int b = 13;
  const int64_t mul_res = a * b;
  int64_t res = reinterpret_cast<LongMulRegCode>(entry)(a, b);
  EXPECT_EQ(mul_res, res);
}


ASSEMBLER_TEST_GENERATE(LongMulAddress, assembler) {
  __ movl(EAX, Address(ESP, 2 * kWordSize));
  __ imull(Address(ESP, kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(LongMulAddress, entry) {
  typedef int64_t (*LongMulAddressCode)(int a, int b);
  const int a = -12;
  const int b = 13;
  const int64_t mul_res = a * b;
  int64_t res = reinterpret_cast<LongMulAddressCode>(entry)(a, b);
  EXPECT_EQ(mul_res, res);
}


ASSEMBLER_TEST_GENERATE(LongUnsignedMulReg, assembler) {
  __ movl(ECX, Address(ESP, kWordSize));
  __ movl(EAX, Address(ESP, 2 * kWordSize));
  __ mull(ECX);
  __ ret();
}


ASSEMBLER_TEST_RUN(LongUnsignedMulReg, entry) {
  typedef uint64_t (*LongUnsignedMulRegCode)(uint32_t a, uint32_t b);
  uint32_t a = 3;
  uint32_t b = 13;
  uint64_t mul_res = a * b;
  uint64_t res = reinterpret_cast<LongUnsignedMulRegCode>(entry)(a, b);
  EXPECT_EQ(mul_res, res);
  a = 4021288948u;
  b = 13;
  res = reinterpret_cast<LongUnsignedMulRegCode>(entry)(a, b);
  mul_res =  static_cast<uint64_t>(a) * static_cast<uint64_t>(b);
  EXPECT_EQ(mul_res, res);
}


ASSEMBLER_TEST_GENERATE(LongUnsignedMulAddress, assembler) {
  __ movl(EAX, Address(ESP, 2 * kWordSize));
  __ mull(Address(ESP, kWordSize));
  __ ret();
}


ASSEMBLER_TEST_RUN(LongUnsignedMulAddress, entry) {
  typedef uint64_t (*LongUnsignedMulAddressCode)(uint32_t a, uint32_t b);
  uint32_t a = 12;
  uint32_t b = 13;
  uint64_t mul_res = a * b;
  uint64_t res = reinterpret_cast<LongUnsignedMulAddressCode>(entry)(a, b);
  EXPECT_EQ(mul_res, res);
  a = 4294967284u;
  b = 13;
  res = reinterpret_cast<LongUnsignedMulAddressCode>(entry)(a, b);
  mul_res =  static_cast<uint64_t>(a) * static_cast<uint64_t>(b);
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


ASSEMBLER_TEST_RUN(LongAddReg, entry) {
  typedef int64_t (*LongAddRegCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongAddRegCode>(entry)(a, b);
  EXPECT_EQ((a + b), res);
  a = 2147483647;
  b = 600000;
  res = reinterpret_cast<LongAddRegCode>(entry)(a, b);
  EXPECT_EQ((a + b), res);
}


ASSEMBLER_TEST_GENERATE(LongAddAddress, assembler) {
  // Preserve clobbered callee-saved register (EBX).
  __ movl(EAX, Address(ESP, 1 * kWordSize));  // left low.
  __ movl(EDX, Address(ESP, 2 * kWordSize));  // left high.
  __ addl(EAX, Address(ESP, 3 * kWordSize));  // low.
  __ adcl(EDX, Address(ESP, 4 * kWordSize));  // high.
  // Result is in EAX/EDX.
  __ ret();
}


ASSEMBLER_TEST_RUN(LongAddAddress, entry) {
  typedef int64_t (*LongAddAddressCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongAddAddressCode>(entry)(a, b);
  EXPECT_EQ((a + b), res);
  a = 2147483647;
  b = 600000;
  res = reinterpret_cast<LongAddAddressCode>(entry)(a, b);
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


ASSEMBLER_TEST_RUN(LongSubReg, entry) {
  typedef int64_t (*LongSubRegCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongSubRegCode>(entry)(a, b);
  EXPECT_EQ((a - b), res);
  a = 600000;
  b = 2147483647;
  res = reinterpret_cast<LongSubRegCode>(entry)(a, b);
  EXPECT_EQ((a - b), res);
}


ASSEMBLER_TEST_GENERATE(LongSubAddress, assembler) {
  // Preserve clobbered callee-saved register (EBX).
  __ movl(EAX, Address(ESP, 1 * kWordSize));  // left low.
  __ movl(EDX, Address(ESP, 2 * kWordSize));  // left high.
  __ subl(EAX, Address(ESP, 3 * kWordSize));  // low.
  __ sbbl(EDX, Address(ESP, 4 * kWordSize));  // high.
  // Result is in EAX/EDX.
  __ ret();
}


ASSEMBLER_TEST_RUN(LongSubAddress, entry) {
  typedef int64_t (*LongSubAddressCode)(int64_t a, int64_t b);
  int64_t a = 12;
  int64_t b = 14;
  int64_t res = reinterpret_cast<LongSubAddressCode>(entry)(a, b);
  EXPECT_EQ((a - b), res);
  a = 600000;
  b = 2147483647;
  res = reinterpret_cast<LongSubAddressCode>(entry)(a, b);
  EXPECT_EQ((a - b), res);
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


ASSEMBLER_TEST_RUN(IntegerToDoubleConversion, entry) {
  typedef double (*IntegerToDoubleConversionCode)(int32_t);
  const int32_t val = -12;
  double res = reinterpret_cast<IntegerToDoubleConversionCode>(entry)(val);
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


ASSEMBLER_TEST_RUN(FPUStoreLong, entry) {
  typedef int64_t (*FPUStoreLongCode)(double d);
  double val = 12.2;
  int64_t res = reinterpret_cast<FPUStoreLongCode>(entry)(val);
  EXPECT_EQ(static_cast<int64_t>(val), res);
  val = -12.2;
  res = reinterpret_cast<FPUStoreLongCode>(entry)(val);
  EXPECT_EQ(static_cast<int64_t>(val), res);
  val = 12.8;
  res = reinterpret_cast<FPUStoreLongCode>(entry)(val);
  EXPECT_EQ(static_cast<int64_t>(val), res);
  val = -12.8;
  res = reinterpret_cast<FPUStoreLongCode>(entry)(val);
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


ASSEMBLER_TEST_RUN(XorpdZeroing, entry) {
  typedef double (*XorpdZeroingCode)(double d);
  double res = reinterpret_cast<XorpdZeroingCode>(entry)(12.56e3);
  EXPECT_FLOAT_EQ(0.0, res, 0.0001);
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


ASSEMBLER_TEST_RUN(DoubleAbs, entry) {
  typedef double (*DoubleAbsCode)(double d);
  double val = -12.45;
  double res =  reinterpret_cast<DoubleAbsCode>(entry)(val);
  EXPECT_FLOAT_EQ(-val, res, 0.001);
  val = 12.45;
  res =  reinterpret_cast<DoubleAbsCode>(entry)(val);
  EXPECT_FLOAT_EQ(val, res, 0.001);
}


ASSEMBLER_TEST_GENERATE(ExtractSignBits, assembler) {
  __ movsd(XMM0, Address(ESP, kWordSize));
  __ movmskpd(EAX, XMM0);
  __ ret();
}


ASSEMBLER_TEST_RUN(ExtractSignBits, entry) {
  typedef int (*ExtractSignBits)(double d);
  int res = reinterpret_cast<ExtractSignBits>(entry)(1.0);
  EXPECT_EQ(0, res);
  res = reinterpret_cast<ExtractSignBits>(entry)(-1.0);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ExtractSignBits>(entry)(-0.0);
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


ASSEMBLER_TEST_RUN(ConditionalMovesSign, entry) {
  typedef int (*ConditionalMovesSignCode)(int i);
  int res = reinterpret_cast<ConditionalMovesSignCode>(entry)(785);
  EXPECT_EQ(1, res);
  res = reinterpret_cast<ConditionalMovesSignCode>(entry)(-12);
  EXPECT_EQ(-1, res);
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


ASSEMBLER_TEST_RUN(TestLoadDoubleConstant, entry) {
  typedef double (*TestLoadDoubleConstantCode)();
  double res = reinterpret_cast<TestLoadDoubleConstantCode>(entry)();
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
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestNop, entry) {
  typedef int (*TestNop)();
  int res = reinterpret_cast<TestNop>(entry)();
  EXPECT_EQ(36, res);  // 36 nop bytes emitted.
}


ASSEMBLER_TEST_GENERATE(TestAlign0, assembler) {
  __ Align(4, 0);
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
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
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
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
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
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
  __ movl(EAX, Immediate(assembler->CodeSize()));  // Return code size.
  __ ret();
}


ASSEMBLER_TEST_RUN(TestAlignLarge, entry) {
  typedef int (*TestAlignLarge)();
  int res = reinterpret_cast<TestAlignLarge>(entry)();
  EXPECT_EQ(16, res);  // 16 bytes emitted.
}


// Called from assembler_test.cc.
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ pushl(CTX);
  __ movl(CTX, Address(ESP, 2 * kWordSize));
  __ movl(EAX, Address(ESP, 3 * kWordSize));
  __ movl(ECX, Address(ESP, 4 * kWordSize));
  __ pushl(EAX);
  __ StoreIntoObject(ECX,
                     FieldAddress(ECX, GrowableObjectArray::data_offset()),
                     EAX);
  __ popl(EAX);
  __ popl(CTX);
  __ ret();
}


}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
