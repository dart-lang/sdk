// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/isolate.h"
#include "vm/dart_entry.h"
#include "vm/native_entry.h"
#include "vm/native_entry_test.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

#define __ assembler->

namespace dart {

DECLARE_RUNTIME_ENTRY(TestSmiSub);
DECLARE_LEAF_RUNTIME_ENTRY(RawObject*, TestLeafSmiAdd, RawObject*, RawObject*);


static Function* CreateFunction(const char* name) {
  const String& class_name = String::Handle(Symbols::New("ownerClass"));
  const Script& script = Script::Handle();
  const Class& owner_class =
      Class::Handle(Class::New(class_name, script, Scanner::kNoSourcePos));
  const Library& lib = Library::Handle(Library::New(class_name));
  owner_class.set_library(lib);
  const String& function_name = String::ZoneHandle(Symbols::New(name));
  Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kRegularFunction,
                    true, false, false, false, false, owner_class, 0));
  return &function;
}


// Test calls to stub code which calls into the runtime.
static void GenerateCallToCallRuntimeStub(Assembler* assembler,
                                          int value1, int value2) {
  const int argc = 2;
  const Smi& smi1 = Smi::ZoneHandle(Smi::New(value1));
  const Smi& smi2 = Smi::ZoneHandle(Smi::New(value2));
  const Context& context = Context::ZoneHandle(Context::New(0, Heap::kOld));
  ASSERT(context.isolate() == Isolate::Current());
  __ EnterStubFrame(true);
  __ LoadObject(CTX, context, PP);
  __ PushObject(Object::null_object(), PP);  // Push Null obj for return value.
  __ PushObject(smi1, PP);  // Push argument 1 smi1.
  __ PushObject(smi2, PP);  // Push argument 2 smi2.
  ASSERT(kTestSmiSubRuntimeEntry.argument_count() == argc);
  __ CallRuntime(kTestSmiSubRuntimeEntry, argc);  // Call SmiSub runtime func.
  __ AddImmediate(RSP, Immediate(argc * kWordSize), PP);
  __ popq(RAX);  // Pop return value from return slot.
  __ LeaveStubFrame();
  __ ret();
}


TEST_CASE(CallRuntimeStubCode) {
  extern const Function& RegisterFakeFunction(const char* name,
                                              const Code& code);
  const int value1 = 10;
  const int value2 = 20;
  const char* kName = "Test_CallRuntimeStubCode";
  Assembler _assembler_;
  GenerateCallToCallRuntimeStub(&_assembler_, value1, value2);
  const Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_CallRuntimeStubCode"), &_assembler_));
  const Function& function = RegisterFakeFunction(kName, code);
  Smi& result = Smi::Handle();
  result ^= DartEntry::InvokeFunction(function, Object::empty_array());
  EXPECT_EQ((value1 - value2), result.Value());
}


// Test calls to stub code which calls into a leaf runtime entry.
static void GenerateCallToCallLeafRuntimeStub(Assembler* assembler,
                                              int value1,
                                              int value2) {
  const Smi& smi1 = Smi::ZoneHandle(Smi::New(value1));
  const Smi& smi2 = Smi::ZoneHandle(Smi::New(value2));
  __ enter(Immediate(0));
  __ ReserveAlignedFrameSpace(0);
  __ LoadObject(CallingConventions::kArg1Reg, smi1, PP);
  __ LoadObject(CallingConventions::kArg2Reg, smi2, PP);
  __ CallRuntime(kTestLeafSmiAddRuntimeEntry, 2);  // Call SmiAdd runtime func.
  __ leave();
  __ ret();  // Return value is in RAX.
}


TEST_CASE(CallLeafRuntimeStubCode) {
  extern const Function& RegisterFakeFunction(const char* name,
                                              const Code& code);
  const int value1 = 10;
  const int value2 = 20;
  const char* kName = "Test_CallLeafRuntimeStubCode";
  Assembler _assembler_;
  GenerateCallToCallLeafRuntimeStub(&_assembler_, value1, value2);
  const Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_CallLeafRuntimeStubCode"), &_assembler_));
  const Function& function = RegisterFakeFunction(kName, code);
  Smi& result = Smi::Handle();
  result ^= DartEntry::InvokeFunction(function, Object::empty_array());
  EXPECT_EQ((value1 + value2), result.Value());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
