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


static RawClass* CreateDummyClass(const String& class_name,
                                  const Script& script) {
  const Class& cls = Class::Handle(Class::New(
      Library::Handle(), class_name, script, TokenPosition::kNoSource));
  cls.set_is_synthesized_class();  // Dummy class for testing.
  return cls.raw();
}


static RawLibrary* CreateDummyLibrary(const String& library_name) {
  return Library::New(library_name);
}


static RawFunction* CreateFunction(const char* name) {
  Thread* thread = Thread::Current();
  const String& class_name = String::Handle(Symbols::New(thread, "ownerClass"));
  const String& lib_name = String::Handle(Symbols::New(thread, "ownerLibrary"));
  const Script& script = Script::Handle();
  const Class& owner_class =
      Class::Handle(CreateDummyClass(class_name, script));
  const Library& owner_library =
      Library::Handle(CreateDummyLibrary(lib_name));
  owner_class.set_library(owner_library);
  const String& function_name = String::ZoneHandle(Symbols::New(thread, name));
  return Function::New(function_name, RawFunction::kRegularFunction,
                       true, false, false, false, false, owner_class,
                       TokenPosition::kMinSource);
}


static void GenerateDummyCode(Assembler* assembler, const Object& result) {
  __ PushConstant(result);
  __ ReturnTOS();
}


static void MakeDummyInstanceCall(Assembler* assembler, const Object& result) {
  // Make a dummy function.
  Assembler _assembler_;
  GenerateDummyCode(&_assembler_, result);
  const char* dummy_function_name = "dummy_instance_function";
  const Function& dummy_instance_function =
      Function::Handle(CreateFunction(dummy_function_name));
  Code& code =
      Code::Handle(Code::FinalizeCode(dummy_instance_function, &_assembler_));
  dummy_instance_function.AttachCode(code);

  // Make a dummy ICData.
  const Array& dummy_arguments_descriptor =
      Array::Handle(ArgumentsDescriptor::New(2));
  const ICData& ic_data = ICData::Handle(ICData::New(
      dummy_instance_function,
      String::Handle(dummy_instance_function.name()),
      dummy_arguments_descriptor,
      Thread::kNoDeoptId,
      2,
      /* is_static_call= */ false));

  // Wire up the Function in the ICData.
  GrowableArray<intptr_t> cids(2);
  cids.Add(kSmiCid);
  cids.Add(kSmiCid);
  ic_data.AddCheck(cids, dummy_instance_function);

  // For the non-Smi tests.
  cids[0] = kBigintCid;
  ic_data.AddCheck(cids, dummy_instance_function);
  ICData* call_ic_data = &ICData::ZoneHandle(ic_data.Original());

  // Generate the instance call.
  const intptr_t call_ic_data_kidx = __ AddConstant(*call_ic_data);
  __ InstanceCall2(2, call_ic_data_kidx);
}


ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(Simple, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(Nop, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ Nop();
  __ Nop();
  __ Nop();
  __ Nop();
  __ Nop();
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(Nop, test) {
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
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AddTOS, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(AddTOSOverflow, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(Smi::kMaxValue)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ AddTOS();
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(42)));
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
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(AddTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(SubTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(30)));
  __ PushConstant(Smi::Handle(Smi::New(-12)));
  __ SubTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(SubTOS, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(SubTOSOverflow, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(Smi::kMinValue)));
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ SubTOS();
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(42)));
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
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(SubTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(MulTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(-6)));
  __ PushConstant(Smi::Handle(Smi::New(-7)));
  __ MulTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(MulTOS, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(MulTOSOverflow, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(Smi::kMaxValue)));
  __ PushConstant(Smi::Handle(Smi::New(-8)));
  __ MulTOS();
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(42)));
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
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(MulTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(BitOrTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(0x22)));
  __ PushConstant(Smi::Handle(Smi::New(0x08)));
  __ BitOrTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
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
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(BitOrTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(BitAndTOS, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(0x2a)));
  __ PushConstant(Smi::Handle(Smi::New(0xaa)));
  __ BitAndTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
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
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(BitAndTOSNonSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(EqualTOSTrue, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ EqualTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Bool::False());
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(EqualTOSTrue, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(EqualTOSFalse, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ EqualTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Bool::True());
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
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Bool::True());
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(EqualTOSNonSmi, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(LessThanTOSTrue, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ LessThanTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Bool::False());
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(LessThanTOSTrue, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(LessThanTOSFalse, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ LessThanTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Bool::False());
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
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Bool::True());
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(LessThanTOSNonSmi, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(GreaterThanTOSTrue, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ GreaterThanTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Bool::False());
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(GreaterThanTOSTrue, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(GreaterThanTOSFalse, assembler) {
  __ PushConstant(Smi::Handle(Smi::New(-42)));
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ GreaterThanTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Bool::False());
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
  // Shouldn't be skipped.
  MakeDummyInstanceCall(assembler, Bool::True());
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(GreaterThanTOSNonSmi, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


//  - Add, Sub, Mul, Div, Mod, Shl, Shr rA, rB, rC
//
//    Arithmetic operations on Smis. FP[rA] <- FP[rB] op FP[rC].
//    If these instructions can trigger a deoptimization, the following
//    instruction should be Deopt. If no deoptimization should be triggered,
//    the immediately following instruction is skipped.
ASSEMBLER_TEST_GENERATE(AddNoOverflow, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(20)));
  __ LoadConstant(1, Smi::Handle(Smi::New(22)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Add(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(-42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(AddNoOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(AddOverflow, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(Smi::kMaxValue)));
  __ LoadConstant(1, Smi::Handle(Smi::New(1)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Add(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(AddOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(SubNoOverflow, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(64)));
  __ LoadConstant(1, Smi::Handle(Smi::New(22)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Sub(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(-42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(SubNoOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(SubOverflow, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(Smi::kMinValue)));
  __ LoadConstant(1, Smi::Handle(Smi::New(1)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Sub(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(SubOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(MulNoOverflow, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-6)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-7)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Mul(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(-42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(MulNoOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(MulOverflow, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(Smi::kMaxValue)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-8)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Mul(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(MulOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(DivNoDeopt, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(27)));
  __ LoadConstant(1, Smi::Handle(Smi::New(3)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Div(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(-42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(DivNoDeopt, test) {
  EXPECT_EQ(9, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(DivZero, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(3)));
  __ LoadConstant(1, Smi::Handle(Smi::New(0)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Div(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(DivZero, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(DivCornerCase, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(Smi::kMinValue)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Div(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(DivCornerCase, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(ModPosPos, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(4)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Mod(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(-42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(ModPosPos, test) {
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(ModNegPos, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(4)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Mod(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(-42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(ModNegPos, test) {
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(ModPosNeg, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-4)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Mod(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(-42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(ModPosNeg, test) {
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(ModZero, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(3)));
  __ LoadConstant(1, Smi::Handle(Smi::New(0)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Mod(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(ModZero, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(ShlNoDeopt, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(21)));
  __ LoadConstant(1, Smi::Handle(Smi::New(1)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Shl(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(-42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(ShlNoDeopt, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(ShlOverflow, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(Smi::kMaxValue)));
  __ LoadConstant(1, Smi::Handle(Smi::New(1)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Shl(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(ShlOverflow, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(ShlNegShift, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(21)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Shl(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(ShlNegShift, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(ShrNoDeopt, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(84)));
  __ LoadConstant(1, Smi::Handle(Smi::New(1)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Shr(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(-42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(ShrNoDeopt, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(ShrNegShift, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(21)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ Shr(2, 0, 1);
  __ LoadConstant(2, Smi::Handle(Smi::New(42)));
  __ Return(2);
}


ASSEMBLER_TEST_RUN(ShrNegShift, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - BitOr, BitAnd, BitXor rA, rB, rC
//
//    FP[rA] <- FP[rB] op FP[rC]
ASSEMBLER_TEST_GENERATE(BitOr, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(0x2)));
  __ LoadConstant(1, Smi::Handle(Smi::New(0x28)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ BitOr(2, 0, 1);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(BitOr, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(BitAnd, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(0x2b)));
  __ LoadConstant(1, Smi::Handle(Smi::New(0x6a)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ BitAnd(2, 0, 1);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(BitAnd, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(BitXor, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(0x37)));
  __ LoadConstant(1, Smi::Handle(Smi::New(0x1d)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-1)));
  __ BitXor(2, 0, 1);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(BitXor, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
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
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
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
  __ PushConstant(Smi::Handle(Smi::New(37)));
  __ PushConstant(Smi::Handle(Smi::New(21)));
  __ StoreLocal(0);
  __ Push(0);
  __ AddTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
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
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
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
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
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
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(0)));
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
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(-1)));
  __ PopLocal(1);

  // Subtract 1 from FP[0].
  __ Push(0);
  __ PushConstant(Smi::Handle(Smi::New(1)));
  __ SubTOS();
  // Should be skipped.
  MakeDummyInstanceCall(assembler, Smi::Handle(Smi::New(-1)));

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


//  - CheckSmi rA
//
//    If FP[rA] is a Smi, then skip the next instruction.
ASSEMBLER_TEST_GENERATE(CheckSmiPass, assembler) {
  __ Frame(1);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ LoadConstant(0, Smi::Handle(Smi::New(0)));
  __ CheckSmi(0);
  __ PushConstant(Smi::Handle(Smi::New(-1)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(CheckSmiPass, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(CheckSmiFail, assembler) {
  __ Frame(1);
  __ PushConstant(Smi::Handle(Smi::New(-1)));
  __ LoadConstant(0, Bool::True());
  __ CheckSmi(0);
  __ PushConstant(Smi::Handle(Smi::New(42)));
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(CheckSmiFail, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_DBC)
