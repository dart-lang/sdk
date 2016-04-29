// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#include "vm/assembler.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(Simple, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
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

}  // namespace dart

#endif  // defined(TARGET_ARCH_DBC)
