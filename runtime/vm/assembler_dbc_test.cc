// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#include "vm/assembler.h"
#include "vm/stack_frame.h"
#include "vm/unit_test.h"

namespace dart {

static RawObject* ExecuteTest(const Code& code) {
  Thread* thread = Thread::Current();
  TransitionToGenerated transition(thread);
  return Simulator::Current()->Call(
      code,
      Array::Handle(ArgumentsDescriptor::New(0)),
      Array::Handle(Array::New(0)),
      thread);
}


#define EXECUTE_TEST_CODE_INTPTR(code)                                         \
    Smi::Value(Smi::RawCast(ExecuteTest(code)))
#define EXECUTE_TEST_CODE_BOOL(code)                                           \
    (Bool::RawCast(ExecuteTest(code)) == Bool::True().raw())
#define EXECUTE_TEST_CODE_OBJECT(code)                                         \
    Object::Handle(ExecuteTest(code))

#define __ assembler->


ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(Simple, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


// Called from assembler_test.cc.
// FP[-kParamEndSlotFromFp - 1]: growable array
// FP[-kParamEndSlotFromFp - 2]: value
ASSEMBLER_TEST_GENERATE(StoreIntoObject, assembler) {
  __ Frame(2);
  __ Move(0, -kParamEndSlotFromFp - 1);
  __ Move(1, -kParamEndSlotFromFp - 2);
  __ StoreField(0, GrowableObjectArray::data_offset() / kWordSize, 1);
  __ Return(0);
}


//  - AddTOS; SubTOS; MulTOS; BitOrTOS; BitAndTOS; EqualTOS; LessThanTOS;
//    GreaterThanTOS;
//
//    Smi fast-path for a corresponding method. Checks if SP[0] and SP[-1] are
//    both smis and result of SP[0] <op> SP[-1] is a smi - if this is true
//    then pops operands and pushes result on the stack and skips the next
//    instruction (which implements a slow path fallback).
ASSEMBLER_TEST_GENERATE(AddTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ PushConstant(Smi::Handle(Smi::New(84)));
  __ AddTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AddTOS, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(AddTOSOverflow, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(Smi::kMaxValue)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ AddTOS();
  __ PushConstant(Smi::Handle(Smi::New(42)));  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AddTOSOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(AddTOSNonSmi, assembler) {
  const String& numstr =
      String::Handle(String::New("98765432198765432100", Heap::kOld));
  __ PushConstant(Integer::Handle(Integer::New(numstr, Heap::kOld)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ AddTOS();
  __ PushConstant(Smi::Handle(Smi::New(42)));  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AddTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(SubTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(30)));
  __ PushConstant(Smi::Handle(Smi::New(-12)));
  __ SubTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(SubTOS, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(SubTOSOverflow, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(Smi::kMinValue)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ SubTOS();
  __ PushConstant(Smi::Handle(Smi::New(42)));  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(SubTOSOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(SubTOSNonSmi, assembler) {
  const String& numstr =
      String::Handle(String::New("98765432198765432100", Heap::kOld));
  __ PushConstant(Integer::Handle(Integer::New(numstr, Heap::kOld)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ SubTOS();
  __ PushConstant(Smi::Handle(Smi::New(42)));  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(SubTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(MulTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(-6)));
  __ PushConstant(Smi::Handle(Smi::New(-7)));
  __ MulTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(MulTOS, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(MulTOSOverflow, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(Smi::kMaxValue)));
  __ PushConstant(Smi::Handle(Smi::New(-8)));
  __ MulTOS();
  __ PushConstant(Smi::Handle(Smi::New(42)));  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(MulTOSOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(MulTOSNonSmi, assembler) {
  const String& numstr =
      String::Handle(String::New("98765432198765432100", Heap::kOld));
  __ PushConstant(Integer::Handle(Integer::New(numstr, Heap::kOld)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ MulTOS();
  __ PushConstant(Smi::Handle(Smi::New(42)));  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(MulTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(BitOrTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(0x22)));
  __ PushConstant(Smi::Handle(Smi::New(0x08)));
  __ BitOrTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(BitOrTOS, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(BitOrTOSNonSmi, assembler) {
  const String& numstr =
      String::Handle(String::New("98765432198765432100", Heap::kOld));
  __ PushConstant(Integer::Handle(Integer::New(numstr, Heap::kOld)));
  __ PushConstant(Smi::Handle(Smi::New(0x08)));
  __ BitOrTOS();
  __ PushConstant(Smi::Handle(Smi::New(42)));  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(BitOrTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(BitAndTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(0x2a)));
  __ PushConstant(Smi::Handle(Smi::New(0xaa)));
  __ BitAndTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(BitAndTOS, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(BitAndTOSNonSmi, assembler) {
  const String& numstr =
      String::Handle(String::New("98765432198765432100", Heap::kOld));
  __ PushConstant(Integer::Handle(Integer::New(numstr, Heap::kOld)));
  __ PushConstant(Smi::Handle(Smi::New(0x08)));
  __ BitAndTOS();
  __ PushConstant(Smi::Handle(Smi::New(42)));  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(BitAndTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(EqualTOSTrue, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ EqualTOS();
  __ PushConstant(Bool::False());  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(EqualTOSTrue, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(EqualTOSFalse, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ EqualTOS();
  __ PushConstant(Bool::True());  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(EqualTOSFalse, test) {
  EXPECT(!EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(EqualTOSNonSmi, assembler) {
  const String& numstr =
      String::Handle(String::New("98765432198765432100", Heap::kOld));
  __ PushConstant(Integer::Handle(Integer::New(numstr, Heap::kOld)));
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ EqualTOS();
  __ PushConstant(Bool::True());  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(EqualTOSNonSmi, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(LessThanTOSTrue, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ LessThanTOS();
  __ PushConstant(Bool::False());  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(LessThanTOSTrue, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(LessThanTOSFalse, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ LessThanTOS();
  __ PushConstant(Bool::False());  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(LessThanTOSFalse, test) {
  EXPECT(!EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(LessThanTOSNonSmi, assembler) {
  const String& numstr =
      String::Handle(String::New("98765432198765432100", Heap::kOld));
  __ PushConstant(Integer::Handle(Integer::New(numstr, Heap::kOld)));
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ LessThanTOS();
  __ PushConstant(Bool::True());  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(LessThanTOSNonSmi, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(GreaterThanTOSTrue, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ GreaterThanTOS();
  __ PushConstant(Bool::False());  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(GreaterThanTOSTrue, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(GreaterThanTOSFalse, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ GreaterThanTOS();
  __ PushConstant(Bool::False());  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(GreaterThanTOSFalse, test) {
  EXPECT(!EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(GreaterThanTOSNonSmi, assembler) {
  const String& numstr =
      String::Handle(String::New("98765432198765432100", Heap::kOld));
  __ PushConstant(Integer::Handle(Integer::New(numstr, Heap::kOld)));
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ GreaterThanTOS();
  __ PushConstant(Bool::True());  // Shouldn't be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(GreaterThanTOSNonSmi, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


//  - IfNeStrictTOS; IfEqStrictTOS; IfNeStrictNumTOS; IfEqStrictNumTOS
//
//    Skips the next instruction unless the given condition holds. 'Num'
//    variants perform number check while non-Num variants just compare
//    RawObject pointers.
//
//    Used to implement conditional jump:
//
//        IfNeStrictTOS
//        Jump T         ;; jump if not equal
ASSEMBLER_TEST_GENERATE(IfNeStrictTOSTaken, assembler) {
  Label branch_taken;
  const Array& array1 = Array::Handle(Array::New(1, Heap::kOld));
  const Array& array2 = Array::Handle(Array::New(2, Heap::kOld));
  __ PushConstant(array1);
  __ PushConstant(array2);
  __ IfNeStrictTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(IfNeStrictTOSTaken, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfNeStrictTOSNotTaken, assembler) {
  Label branch_taken;
  const Array& array1 = Array::Handle(Array::New(1, Heap::kOld));
  __ PushConstant(array1);
  __ PushConstant(array1);
  __ IfNeStrictTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}

ASSEMBLER_TEST_RUN(IfNeStrictTOSNotTaken, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


// TODO(zra): Also add tests that use Mint, Bignum.
ASSEMBLER_TEST_GENERATE(IfNeStrictNumTOSTaken, assembler) {
  Label branch_taken;
  __ PushConstant(Smi::Handle(Smi::New(-1)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ IfNeStrictNumTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(IfNeStrictNumTOSTaken, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfNeStrictNumTOSNotTaken, assembler) {
  Label branch_taken;
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ IfNeStrictNumTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}

ASSEMBLER_TEST_RUN(IfNeStrictNumTOSNotTaken, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfNeStrictNumTOSTakenDouble, assembler) {
  Label branch_taken;
  __ PushConstant(Double::Handle(Double::New(-1.0, Heap::kOld)));
  __ PushConstant(Double::Handle(Double::New(1.0, Heap::kOld)));
  __ IfNeStrictNumTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(IfNeStrictNumTOSTakenDouble, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfNeStrictNumTOSNotTakenDouble, assembler) {
  Label branch_taken;
  __ PushConstant(Double::Handle(Double::New(1.0, Heap::kOld)));
  __ PushConstant(Double::Handle(Double::New(1.0, Heap::kOld)));
  __ IfNeStrictNumTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}

ASSEMBLER_TEST_RUN(IfNeStrictNumTOSNotTakenDouble, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfEqStrictTOSTaken, assembler) {
  Label branch_taken;
  const Array& array1 = Array::Handle(Array::New(1, Heap::kOld));
  __ PushConstant(array1);
  __ PushConstant(array1);
  __ IfEqStrictTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(IfEqStrictTOSTaken, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfEqStrictTOSNotTaken, assembler) {
  Label branch_taken;
  const Array& array1 = Array::Handle(Array::New(1, Heap::kOld));
  const Array& array2 = Array::Handle(Array::New(2, Heap::kOld));
  __ PushConstant(array1);
  __ PushConstant(array2);
  __ IfEqStrictTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}

ASSEMBLER_TEST_RUN(IfEqStrictTOSNotTaken, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


// TODO(zra): Also add tests that use Mint, Bignum.
ASSEMBLER_TEST_GENERATE(IfEqStrictNumTOSTaken, assembler) {
  Label branch_taken;
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ IfEqStrictNumTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(IfEqStrictNumTOSTaken, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfEqStrictNumTOSNotTaken, assembler) {
  Label branch_taken;
  __ PushConstant(Smi::Handle(Smi::New(-1)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ IfEqStrictNumTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(IfEqStrictNumTOSNotTaken, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfEqStrictNumTOSTakenDouble, assembler) {
  Label branch_taken;
  __ PushConstant(Double::Handle(Double::New(1.0, Heap::kOld)));
  __ PushConstant(Double::Handle(Double::New(1.0, Heap::kOld)));
  __ IfEqStrictNumTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(IfEqStrictNumTOSTakenDouble, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfEqStrictNumTOSNotTakenDouble, assembler) {
  Label branch_taken;
  __ PushConstant(Double::Handle(Double::New(-1.0, Heap::kOld)));
  __ PushConstant(Double::Handle(Double::New(1.0, Heap::kOld)));
  __ IfEqStrictNumTOS();
  __ Jump(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(IfEqStrictNumTOSNotTakenDouble, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - BooleanNegateTOS
//
//    SP[0] = !SP[0]
ASSEMBLER_TEST_GENERATE(BooleanNegateTOSTrue, assembler) {
  __ PushConstant(Bool::True());
  __ BooleanNegateTOS();
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(BooleanNegateTOSTrue, test) {
  EXPECT(!EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(BooleanNegateTOSFalse, assembler) {
  __ PushConstant(Bool::False());
  __ BooleanNegateTOS();
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(BooleanNegateTOSFalse, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


//  - AssertBoolean A
//
//    Assert that TOS is a boolean (A = 1) or that TOS is not null (A = 0).
ASSEMBLER_TEST_GENERATE(AssertBooleanTrue, assembler) {
  __ PushConstant(Bool::True());
  __ AssertBoolean(1);
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AssertBooleanTrue, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(AssertBooleanFalse, assembler) {
  __ PushConstant(Bool::False());
  __ AssertBoolean(1);
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AssertBooleanFalse, test) {
  EXPECT(!EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(AssertBooleanNotNull, assembler) {
  __ PushConstant(Bool::True());
  __ AssertBoolean(0);
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AssertBooleanNotNull, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(AssertBooleanFail1, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ AssertBoolean(1);
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AssertBooleanFail1, test) {
  EXPECT(EXECUTE_TEST_CODE_OBJECT(test->code()).IsError());
}


ASSEMBLER_TEST_GENERATE(AssertBooleanFail2, assembler) {
  __ PushConstant(Object::null_object());
  __ AssertBoolean(0);
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AssertBooleanFail2, test) {
  EXPECT(EXECUTE_TEST_CODE_OBJECT(test->code()).IsError());
}


//  - Drop1; DropR n; Drop n
//
//    Drop 1 or n values from the stack, if instruction is DropR push the first
//    dropped value to the stack;
ASSEMBLER_TEST_GENERATE(Drop1, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ Drop1();
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(Drop1, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(Drop, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ Drop(11);
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(Drop, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(DropR, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(41)));
  __ DropR(11);
  __ AddTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(DropR, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - Frame D
//
//    Reserve and initialize with null space for D local variables.
ASSEMBLER_TEST_GENERATE(FrameInitialized1, assembler) {
  __ Frame(1);
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(FrameInitialized1, test) {
  EXPECT(EXECUTE_TEST_CODE_OBJECT(test->code()).IsNull());
}


ASSEMBLER_TEST_GENERATE(FrameInitialized, assembler) {
  Label error;
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ Frame(4);
  __ PushConstant(Object::null_object());
  __ IfNeStrictTOS();
  __ Jump(&error);
  __ PushConstant(Object::null_object());
  __ IfNeStrictTOS();
  __ Jump(&error);
  __ PushConstant(Object::null_object());
  __ IfNeStrictTOS();
  __ Jump(&error);
  __ PushConstant(Object::null_object());
  __ IfNeStrictTOS();
  __ Jump(&error);
  __ ReturnTOS();

  // If a frame slot was not initialized to null.
  __ Bind(&error);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(FrameInitialized, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - StoreLocal rX; PopLocal rX
//
//    Store top of the stack into FP[rX] and pop it if needed.
//
//  - Push rX
//
//    Push FP[rX] to the stack.
ASSEMBLER_TEST_GENERATE(StoreLocalPush, assembler) {
  __ Frame(1);
  __ PushConstant(Smi::Handle(Smi::New(21)));
  __ StoreLocal(0);
  __ Push(0);
  __ AddTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(StoreLocalPush, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(PopLocalPush, assembler) {
  __ Frame(1);
  __ PushConstant(Smi::Handle(Smi::New(21)));
  __ PopLocal(0);
  __ Push(0);
  __ Push(0);
  __ AddTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(PopLocalPush, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(LoadConstantPush, assembler) {
  __ Frame(1);
  __ LoadConstant(0, Smi::Handle(Smi::New(21)));
  __ Push(0);
  __ Push(0);
  __ AddTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(LoadConstantPush, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - Move rA, rX
//
//    FP[rA] <- FP[rX]
//    Note: rX is signed so it can be used to address parameters which are
//    at negative indices with respect to FP.
ASSEMBLER_TEST_GENERATE(MoveLocalLocal, assembler) {
  __ Frame(2);
  __ PushConstant(Smi::Handle(Smi::New(21)));
  __ PopLocal(0);
  __ Move(1, 0);
  __ Push(0);
  __ Push(1);
  __ AddTOS();
  __ PushConstant(Smi::Handle(Smi::New(0)));  // Should be skipped.
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(MoveLocalLocal, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - Return R; ReturnTOS
//
//    Return to the caller using either a value from the given register or a
//    value from the top-of-stack as a result.
ASSEMBLER_TEST_GENERATE(Return1, assembler) {
  __ Frame(1);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ StoreLocal(0);
  __ Return(0);
}


ASSEMBLER_TEST_RUN(Return1, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(Return2, assembler) {
  __ Frame(2);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ StoreLocal(1);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(Return2, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(Loop, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(0)));

  Label loop_entry, error;
  __ Bind(&loop_entry);
  // Add 1 to FP[1].
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ Push(1);
  __ AddTOS();
  __ Jump(&error);
  __ PopLocal(1);

  // Subtract 1 from FP[0].
  __ Push(0);
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ SubTOS();
  __ Jump(&error);

  // Jump to loop_entry if FP[0] != 0.
  __ StoreLocal(0);
  __ PushConstant(Smi::Handle(Smi::New(0)));
  __ IfNeStrictNumTOS();
  __ Jump(&loop_entry);

  __ Return(1);

  __ Bind(&error);
  __ LoadConstant(1, Smi::Handle(Smi::New(-42)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(Loop, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - LoadClassIdTOS, LoadClassId rA, D
//
//    LoadClassIdTOS loads the class id from the object at SP[0] and stores it
//    to SP[0]. LoadClassId loads the class id from FP[rA] and stores it to
//    FP[D].
ASSEMBLER_TEST_GENERATE(LoadClassIdTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ LoadClassIdTOS();
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(LoadClassIdTOS, test) {
  EXPECT_EQ(kSmiCid, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(LoadClassId, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadClassId(1, 0);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(LoadClassId, test) {
  EXPECT_EQ(kSmiCid, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - CreateArrayTOS
//
//    Allocate array of length SP[0] with type arguments SP[-1].
ASSEMBLER_TEST_GENERATE(CreateArrayTOS, assembler) {
  __ PushConstant(Object::null_object());
  __ PushConstant(Smi::Handle(Smi::New(10)));
  __ CreateArrayTOS();
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(CreateArrayTOS, test) {
  const Object& obj = EXECUTE_TEST_CODE_OBJECT(test->code());
  EXPECT(obj.IsArray());
  Array& array = Array::Handle();
  array ^= obj.raw();
  EXPECT_EQ(10, array.Length());
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_DBC)
