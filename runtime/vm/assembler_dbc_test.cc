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
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgs = 0;
  return Simulator::Current()->Call(
      code, Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArgs)),
      Array::Handle(Array::New(0)), thread);
}


#define EXECUTE_TEST_CODE_INTPTR(code)                                         \
  Smi::Value(Smi::RawCast(ExecuteTest(code)))
#define EXECUTE_TEST_CODE_BOOL(code)                                           \
  (Bool::RawCast(ExecuteTest(code)) == Bool::True().raw())
#define EXECUTE_TEST_CODE_OBJECT(code) Object::Handle(ExecuteTest(code))
#define EXECUTE_TEST_CODE_DOUBLE(code)                                         \
  bit_cast<double, RawObject*>(ExecuteTest(code))

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
  const Library& owner_library = Library::Handle(CreateDummyLibrary(lib_name));
  owner_class.set_library(owner_library);
  const String& function_name = String::ZoneHandle(Symbols::New(thread, name));
  return Function::New(function_name, RawFunction::kRegularFunction, true,
                       false, false, false, false, owner_class,
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
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgs = 2;
  const Array& dummy_arguments_descriptor =
      Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArgs));
  const ICData& ic_data = ICData::Handle(ICData::New(
      dummy_instance_function, String::Handle(dummy_instance_function.name()),
      dummy_arguments_descriptor, Thread::kNoDeoptId, 2,
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
  __ Nop(0);
  __ Nop(0);
  __ Nop(0);
  __ Nop(0);
  __ Nop(0);
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


//  - OneByteStringFromCharCode rA, rX
//
//    Load the one-character symbol with the char code given by the Smi
//    in FP[rX] into FP[rA].
ASSEMBLER_TEST_GENERATE(OneByteStringFromCharCode, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::ZoneHandle(Smi::New(65)));
  __ OneByteStringFromCharCode(1, 0);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(OneByteStringFromCharCode, test) {
  EXPECT_EQ(Symbols::New(Thread::Current(), "A"),
            EXECUTE_TEST_CODE_OBJECT(test->code()).raw());
}


//  - StringToCharCode rA, rX
//
//    Load and smi-encode the single char code of the string in FP[rX] into
//    FP[rA]. If the string's length is not 1, load smi -1 instead.
//
ASSEMBLER_TEST_GENERATE(StringToCharCode, assembler) {
  __ Frame(2);
  __ LoadConstant(0, String::ZoneHandle(String::New("A", Heap::kOld)));
  __ StringToCharCode(1, 0);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(StringToCharCode, test) {
  EXPECT_EQ(65, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(StringToCharCodeIllegalLength, assembler) {
  __ Frame(2);
  __ LoadConstant(0, String::ZoneHandle(String::New("AAA", Heap::kOld)));
  __ StringToCharCode(1, 0);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(StringToCharCodeIllegalLength, test) {
  EXPECT_EQ(-1, EXECUTE_TEST_CODE_INTPTR(test->code()));
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


//  - Neg rA , rD
//
//    FP[rA] <- -FP[rD]. Assumes FP[rD] is a Smi. If there is no overflow the
//    immediately following instruction is skipped.
ASSEMBLER_TEST_GENERATE(NegPos, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Neg(1, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(NegPos, test) {
  EXPECT_EQ(-42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(NegNeg, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Neg(1, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(NegNeg, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(NegOverflow, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(Smi::kMinValue)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Neg(1, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(NegOverflow, test) {
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


//  - BitNot rA, rD
//
//    FP[rA] <- ~FP[rD]. As above, assumes FP[rD] is a Smi.
ASSEMBLER_TEST_GENERATE(BitNot, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(~42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ BitNot(1, 0);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(BitNot, test) {
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


//  - TestSmi rA, rD
//
//    If FP[rA] & FP[rD] != 0, then skip the next instruction. FP[rA] and FP[rD]
//    must be Smis.
ASSEMBLER_TEST_GENERATE(TestSmiTrue, assembler) {
  Label branch_taken;
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(7)));
  __ LoadConstant(1, Smi::Handle(Smi::New(3)));
  __ TestSmi(0, 1);
  __ Jump(&branch_taken);
  __ PushConstant(Bool::True());
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Bool::False());
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(TestSmiTrue, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(TestSmiFalse, assembler) {
  Label branch_taken;
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(8)));
  __ LoadConstant(1, Smi::Handle(Smi::New(4)));
  __ TestSmi(0, 1);
  __ Jump(&branch_taken);
  __ PushConstant(Bool::True());
  __ ReturnTOS();
  __ Bind(&branch_taken);
  __ PushConstant(Bool::False());
  __ ReturnTOS();
}


ASSEMBLER_TEST_RUN(TestSmiFalse, test) {
  EXPECT(!EXECUTE_TEST_CODE_BOOL(test->code()));
}


//  - TestCids rA, D
//
//    The next D instructions must be Nops whose D field encodes a class id. If
//    the class id of FP[rA] matches, jump to PC + N + 1 if the matching Nop's
//    A != 0 or PC + N + 2 if the matching Nop's A = 0. If no match is found,
//    jump to PC + N.
ASSEMBLER_TEST_GENERATE(TestCidsTrue, assembler) {
  Label true_branch, no_match_branch;
  __ Frame(2);
  __ LoadConstant(0, Object::Handle(String::New("Hi", Heap::kOld)));
  const intptr_t num_cases = 2;
  __ TestCids(0, num_cases);
  __ Nop(0, static_cast<uint16_t>(kSmiCid));            // Smi    => false
  __ Nop(1, static_cast<uint16_t>(kOneByteStringCid));  // String => true
  __ Jump(&no_match_branch);
  __ Jump(&true_branch);
  __ LoadConstant(1, Smi::Handle(Smi::New(0)));  // false branch
  __ Return(1);
  __ Bind(&true_branch);
  __ LoadConstant(1, Smi::Handle(Smi::New(1)));
  __ Return(1);
  __ Bind(&no_match_branch);
  __ LoadConstant(1, Smi::Handle(Smi::New(2)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(TestCidsTrue, test) {
  EXPECT_EQ(1, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(TestCidsFalse, assembler) {
  Label true_branch, no_match_branch;
  __ Frame(2);
  __ LoadConstant(0, Object::Handle(Smi::New(42)));
  const intptr_t num_cases = 2;
  __ TestCids(0, num_cases);
  __ Nop(0, static_cast<uint16_t>(kSmiCid));            // Smi    => false
  __ Nop(1, static_cast<uint16_t>(kOneByteStringCid));  // String => true
  __ Jump(&no_match_branch);
  __ Jump(&true_branch);
  __ LoadConstant(1, Smi::Handle(Smi::New(0)));  // false branch
  __ Return(1);
  __ Bind(&true_branch);
  __ LoadConstant(1, Smi::Handle(Smi::New(1)));
  __ Return(1);
  __ Bind(&no_match_branch);
  __ LoadConstant(1, Smi::Handle(Smi::New(2)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(TestCidsFalse, test) {
  EXPECT_EQ(0, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(TestCidsNoMatch, assembler) {
  Label true_branch, no_match_branch;
  __ Frame(2);
  __ LoadConstant(0, Object::Handle(Array::New(1, Heap::kOld)));
  const intptr_t num_cases = 2;
  __ TestCids(0, num_cases);
  __ Nop(0, static_cast<uint16_t>(kSmiCid));            // Smi    => false
  __ Nop(1, static_cast<uint16_t>(kOneByteStringCid));  // String => true
  __ Jump(&no_match_branch);
  __ Jump(&true_branch);
  __ LoadConstant(1, Smi::Handle(Smi::New(0)));  // false branch
  __ Return(1);
  __ Bind(&true_branch);
  __ LoadConstant(1, Smi::Handle(Smi::New(1)));
  __ Return(1);
  __ Bind(&no_match_branch);
  __ LoadConstant(1, Smi::Handle(Smi::New(2)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(TestCidsNoMatch, test) {
  EXPECT_EQ(2, EXECUTE_TEST_CODE_INTPTR(test->code()));
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


//  - CheckClassId rA, D
//
//    If the object at FP[rA]'s class id matches the class id in PP[D], then
//    skip the following instruction.
ASSEMBLER_TEST_GENERATE(CheckClassIdSmiPass, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadClassId(1, 0);
  __ CheckClassId(1, kSmiCid);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(CheckClassIdSmiPass, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(CheckClassIdNonSmiPass, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Bool::True());
  __ LoadClassId(1, 0);
  __ CheckClassId(1, kBoolCid);
  __ LoadConstant(0, Bool::False());
  __ Return(0);
}


ASSEMBLER_TEST_RUN(CheckClassIdNonSmiPass, test) {
  EXPECT(EXECUTE_TEST_CODE_BOOL(test->code()));
}


ASSEMBLER_TEST_GENERATE(CheckClassIdFail, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadClassId(1, 0);
  __ CheckClassId(1, kBoolCid);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(CheckClassIdFail, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - If<Cond>Null rA
//
//    Cond is Eq or Ne. Skips the next instruction unless the given condition
//    holds.
ASSEMBLER_TEST_GENERATE(IfEqNullNotNull, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ IfEqNull(0);
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(IfEqNullNotNull, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfEqNullIsNull, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Object::null_object());
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ IfEqNull(0);
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(IfEqNullIsNull, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfNeNullIsNull, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Object::null_object());
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ IfNeNull(0);
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(IfNeNullIsNull, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfNeNullNotNull, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ IfNeNull(0);
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(IfNeNullNotNull, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}

//  - If<Cond> rA, rD
//
//    Cond is Le, Lt, Ge, Gt, unsigned variants ULe, ULt, UGe, UGt, and
//    unboxed double variants DEq, DNe, DLe, DLt, DGe, DGt.
//    Skips the next instruction unless FP[rA] <Cond> FP[rD]. Assumes that
//    FP[rA] and FP[rD] are Smis or unboxed doubles as indicated by <Cond>.
ASSEMBLER_TEST_GENERATE(IfLeTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-5)));
  __ LoadConstant(2, Smi::Handle(Smi::New(100)));
  __ IfLe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfLeTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfLeFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(100)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-5)));
  __ IfLe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfLeFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfLtTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-5)));
  __ LoadConstant(2, Smi::Handle(Smi::New(100)));
  __ IfLt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfLtTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfLtFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(100)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-5)));
  __ IfLt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfLtFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfGeTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(100)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-5)));
  __ IfGe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfGeTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfGeFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-5)));
  __ LoadConstant(2, Smi::Handle(Smi::New(100)));
  __ IfGe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfGeFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfGtTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(100)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-5)));
  __ IfGt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfGtTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfGtFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-5)));
  __ LoadConstant(2, Smi::Handle(Smi::New(100)));
  __ IfGt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfGtFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


#if defined(ARCH_IS_64_BIT)
ASSEMBLER_TEST_GENERATE(IfDNeTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDNe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDNeTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDNeFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDNe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDNeFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDNeNan, assembler) {
  const double not_a_number = bit_cast<double, intptr_t>(0x7FF8000000000000LL);
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Double::Handle(Double::New(not_a_number, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(not_a_number, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDNe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDNeNan, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDEqTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDEq(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDEqTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDEqFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDEq(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDEqFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDEqNan, assembler) {
  const double not_a_number = bit_cast<double, intptr_t>(0x7FF8000000000000LL);
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(not_a_number, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(not_a_number, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDEq(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDEqNan, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDLeTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDLe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDLeTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDLeFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDLe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDLeFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDLeNan, assembler) {
  const double not_a_number = bit_cast<double, intptr_t>(0x7FF8000000000000LL);
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(not_a_number, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDLe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDLeNan, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDLtTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDLt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDLtTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDLtFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDLt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDLtFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDLtNan, assembler) {
  const double not_a_number = bit_cast<double, intptr_t>(0x7FF8000000000000LL);
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(not_a_number, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDLt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDLtNan, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDGeTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDGe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDGeTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDGeFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDGe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDGeFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDGeNan, assembler) {
  const double not_a_number = bit_cast<double, intptr_t>(0x7FF8000000000000LL);
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(not_a_number, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDGe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDGeNan, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDGtTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDGt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDGtTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDGtFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(-5.0, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDGt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDGtFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfDGtNan, assembler) {
  const double not_a_number = bit_cast<double, intptr_t>(0x7FF8000000000000LL);
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Double::Handle(Double::New(not_a_number, Heap::kOld)));
  __ LoadConstant(2, Double::Handle(Double::New(100.0, Heap::kOld)));
  __ UnboxDouble(1, 1);
  __ UnboxDouble(2, 2);
  __ IfDGt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfDGtNan, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}
#endif  // defined(ARCH_IS_64_BIT)


ASSEMBLER_TEST_GENERATE(IfULeTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(5)));
  __ LoadConstant(2, Smi::Handle(Smi::New(100)));
  __ IfULe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfULeTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfULeFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(100)));
  __ LoadConstant(2, Smi::Handle(Smi::New(5)));
  __ IfULe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfULeFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfULeNegTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(5)));
  __ LoadConstant(2, Smi::Handle(Smi::New(-5)));
  __ IfULe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfULeNegTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfULtTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(5)));
  __ LoadConstant(2, Smi::Handle(Smi::New(100)));
  __ IfULt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfULtTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfULtFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(100)));
  __ LoadConstant(2, Smi::Handle(Smi::New(5)));
  __ IfULt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfULtFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfUGeTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(100)));
  __ LoadConstant(2, Smi::Handle(Smi::New(5)));
  __ IfUGe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfUGeTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfUGeFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(5)));
  __ LoadConstant(2, Smi::Handle(Smi::New(100)));
  __ IfUGe(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfUGeFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfUGtTrue, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ LoadConstant(1, Smi::Handle(Smi::New(100)));
  __ LoadConstant(2, Smi::Handle(Smi::New(5)));
  __ IfUGt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfUGtTrue, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(IfUGtFalse, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(5)));
  __ LoadConstant(2, Smi::Handle(Smi::New(100)));
  __ IfUGt(1, 2);
  __ LoadConstant(0, Smi::Handle(Smi::New(-1)));
  __ Return(0);
}


ASSEMBLER_TEST_RUN(IfUGtFalse, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - Min, Max rA, rB, rC
//
//    FP[rA] <- {min, max}(FP[rB], FP[rC]). Assumes that FP[rB], and FP[rC] are
//    Smis.
ASSEMBLER_TEST_GENERATE(Min, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(500)));
  __ Min(2, 0, 1);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(Min, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(Max, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ LoadConstant(1, Smi::Handle(Smi::New(5)));
  __ Max(2, 0, 1);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(Max, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


#if defined(ARCH_IS_64_BIT)
//  - UnboxDouble rA, rD
//
//    Unbox the double in FP[rD] into FP[rA]. Assumes FP[rD] is a double.
//
//  - CheckedUnboxDouble rA, rD
//
//    Unboxes FP[rD] into FP[rA] and skips the following instruction unless
//    FP[rD] is not a double or a Smi. When FP[rD] is a Smi, converts it to a
//    double.
ASSEMBLER_TEST_GENERATE(Unbox, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Double::Handle(Double::New(42.0, Heap::kOld)));
  __ UnboxDouble(1, 0);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(Unbox, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(CheckedUnboxDouble, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Double::Handle(Double::New(42.0, Heap::kOld)));
  __ CheckedUnboxDouble(1, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(0)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(CheckedUnboxDouble, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(CheckedUnboxSmi, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ CheckedUnboxDouble(1, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(0)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(CheckedUnboxSmi, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(CheckedUnboxFail, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Bool::True());
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ CheckedUnboxDouble(1, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(CheckedUnboxFail, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


//  - DAdd, DSub, DMul, DDiv rA, rB, rC
//
//    Arithmetic operations on unboxed doubles. FP[rA] <- FP[rB] op FP[rC].
ASSEMBLER_TEST_GENERATE(DAdd, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Double::Handle(Double::New(41.0, Heap::kOld)));
  __ LoadConstant(1, Double::Handle(Double::New(1.0, Heap::kOld)));
  __ UnboxDouble(0, 0);
  __ UnboxDouble(1, 1);
  __ DAdd(2, 1, 0);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(DAdd, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(DSub, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Double::Handle(Double::New(1.0, Heap::kOld)));
  __ LoadConstant(1, Double::Handle(Double::New(43.0, Heap::kOld)));
  __ UnboxDouble(0, 0);
  __ UnboxDouble(1, 1);
  __ DSub(2, 1, 0);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(DSub, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(DMul, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Double::Handle(Double::New(6.0, Heap::kOld)));
  __ LoadConstant(1, Double::Handle(Double::New(7.0, Heap::kOld)));
  __ UnboxDouble(0, 0);
  __ UnboxDouble(1, 1);
  __ DMul(2, 1, 0);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(DMul, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(DDiv, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Double::Handle(Double::New(2.0, Heap::kOld)));
  __ LoadConstant(1, Double::Handle(Double::New(84.0, Heap::kOld)));
  __ UnboxDouble(0, 0);
  __ UnboxDouble(1, 1);
  __ DDiv(2, 1, 0);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(DDiv, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(DNeg, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Double::Handle(Double::New(-42.0, Heap::kOld)));
  __ UnboxDouble(0, 0);
  __ DNeg(1, 0);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(DNeg, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(DSqrt, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Double::Handle(Double::New(36.0, Heap::kOld)));
  __ UnboxDouble(0, 0);
  __ DSqrt(1, 0);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(DSqrt, test) {
  EXPECT_EQ(6.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


//  - SmiToDouble rA, rD
//
//    Convert the Smi in FP[rD] to an unboxed double in FP[rA].
//
//  - DoubleToSmi rA, rD
//
//    If the unboxed double in FP[rD] can be converted to a Smi in FP[rA], then
//    this instruction does so, and skips the following instruction. Otherwise,
//    the following instruction is not skipped.
ASSEMBLER_TEST_GENERATE(SmiToDouble, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Smi::Handle(Smi::New(42)));
  __ SmiToDouble(1, 0);
  __ Return(1);
}


ASSEMBLER_TEST_RUN(SmiToDouble, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(DoubleToSmi, assembler) {
  __ Frame(2);
  __ LoadConstant(0, Double::Handle(Double::New(42.0, Heap::kOld)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ UnboxDouble(0, 0);
  __ DoubleToSmi(1, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(DoubleToSmi, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(DoubleToSmiNearMax, assembler) {
  const double m = static_cast<double>(Smi::kMaxValue - 1000);
  __ Frame(2);
  __ LoadConstant(0, Double::Handle(Double::New(m, Heap::kOld)));
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ UnboxDouble(0, 0);
  __ DoubleToSmi(0, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(DoubleToSmiNearMax, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(DoubleToSmiNearMin, assembler) {
  const double m = static_cast<double>(Smi::kMinValue);
  __ Frame(2);
  __ LoadConstant(0, Double::Handle(Double::New(m, Heap::kOld)));
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ UnboxDouble(0, 0);
  __ DoubleToSmi(0, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(DoubleToSmiNearMin, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(DoubleToSmiFailPos, assembler) {
  const double pos_overflow = static_cast<double>(Smi::kMaxValue + 1);
  __ Frame(2);
  __ LoadConstant(0, Double::Handle(Double::New(pos_overflow, Heap::kOld)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ UnboxDouble(0, 0);
  __ DoubleToSmi(1, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(DoubleToSmiFailPos, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(DoubleToSmiFailNeg, assembler) {
  const double neg_overflow = static_cast<double>(Smi::kMinValue - 1000);
  __ Frame(2);
  __ LoadConstant(0, Double::Handle(Double::New(neg_overflow, Heap::kOld)));
  __ LoadConstant(1, Smi::Handle(Smi::New(-1)));
  __ UnboxDouble(0, 0);
  __ DoubleToSmi(1, 0);
  __ LoadConstant(1, Smi::Handle(Smi::New(42)));
  __ Return(1);
}


ASSEMBLER_TEST_RUN(DoubleToSmiFailNeg, test) {
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INTPTR(test->code()));
}


ASSEMBLER_TEST_GENERATE(DMin, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Double::Handle(Double::New(42.0, Heap::kOld)));
  __ LoadConstant(1, Double::Handle(Double::New(500.0, Heap::kOld)));
  __ UnboxDouble(0, 0);
  __ UnboxDouble(1, 1);
  __ DMin(2, 0, 1);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(DMin, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}


ASSEMBLER_TEST_GENERATE(DMax, assembler) {
  __ Frame(3);
  __ LoadConstant(0, Double::Handle(Double::New(42.0, Heap::kOld)));
  __ LoadConstant(1, Double::Handle(Double::New(5.0, Heap::kOld)));
  __ UnboxDouble(0, 0);
  __ UnboxDouble(1, 1);
  __ DMax(2, 0, 1);
  __ Return(2);
}


ASSEMBLER_TEST_RUN(DMax, test) {
  EXPECT_EQ(42.0, EXECUTE_TEST_CODE_DOUBLE(test->code()));
}

#endif  // defined(ARCH_IS_64_BIT)

}  // namespace dart

#endif  // defined(TARGET_ARCH_DBC)
