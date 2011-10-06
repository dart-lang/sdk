// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/code_index_table.h"
#include "vm/isolate.h"
#include "vm/dart_entry.h"
#include "vm/native_entry.h"
#include "vm/native_entry_test.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

#define __ assembler->

namespace dart {

DECLARE_RUNTIME_ENTRY(TestSmiSub);


// Add function to a class and that class to the class dictionary so that
// frame walking can be used.
static const Function& RegisterFakeFunction(const char* name,
                                            const Code& code) {
  const String& function_name = String::ZoneHandle(String::NewSymbol(name));
  const Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kFunction, true, false, 0));
  Class& cls = Class::ZoneHandle();
  const Script& script = Script::Handle();
  cls = Class::New(function_name, script);
  const Array& functions = Array::Handle(Array::New(1));
  functions.SetAt(0, function);
  cls.SetFunctions(functions);
  Library& lib = Library::Handle(Library::CoreLibrary());
  lib.AddClass(cls);
  function.SetCode(code);
  CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
  ASSERT(code_index_table != NULL);
  code_index_table->AddFunction(function);
  return function;
}


// Test calls to stub code which calls into the runtime.
static void GenerateCallToCallRuntimeStub(Assembler* assembler,
                                          int value1, int value2) {
  const int argc = 2;
  const Smi& smi1 = Smi::ZoneHandle(Smi::New(value1));
  const Smi& smi2 = Smi::ZoneHandle(Smi::New(value2));
  const Object& result = Object::ZoneHandle();
  const Context& context = Context::ZoneHandle(Context::New(0));
  ASSERT(context.isolate() == Isolate::Current());
  __ enter(Immediate(0));
  __ LoadObject(CTX, context);
  __ PushObject(result);  // Push Null object for return value.
  __ PushObject(smi1);  // Push argument 1 smi1.
  __ PushObject(smi2);  // Push argument 2 smi2.
  ASSERT(kTestSmiSubRuntimeEntry.argument_count() == argc);
  __ CallRuntimeFromStub(kTestSmiSubRuntimeEntry);  // Call SmiSub runtime func.
  __ AddImmediate(ESP, Immediate(argc * kWordSize));
  __ popl(EAX);  // Pop return value from return slot.
  __ leave();
  __ ret();
}


TEST_CASE(CallRuntimeStubCode) {
  const int value1 = 10;
  const int value2 = 20;
  const char* kName = "Test_CallRuntimeStubCode";
  Assembler _assembler_;
  GenerateCallToCallRuntimeStub(&_assembler_, value1, value2);
  const Code& code = Code::Handle(
      Code::FinalizeCode("Test_CallRuntimeStubCode", &_assembler_));
  const Function& function = RegisterFakeFunction(kName, code);
  GrowableArray<const Object*>  arguments;
  const Array& kNoArgumentNames = Array::Handle();
  Smi& result = Smi::Handle();
  result ^= DartEntry::InvokeStatic(function, arguments, kNoArgumentNames);
  EXPECT_EQ((value1 - value2), result.Value());
}


// Test calls to stub code which calls a native C function.
static void GenerateCallToCallNativeCFunctionStub(Assembler* assembler,
                                                  int value1, int value2) {
  const int argc = 2;
  const Smi& smi1 = Smi::ZoneHandle(Smi::New(value1));
  const Smi& smi2 = Smi::ZoneHandle(Smi::New(value2));
  const Object& result = Object::ZoneHandle();
  const String& native_name = String::ZoneHandle(String::New("TestSmiSub"));
  Dart_NativeFunction native_function =
      NativeTestEntry_Lookup(native_name, argc);
  const Context& context = Context::ZoneHandle(Context::New(0));
  ASSERT(context.isolate() == Isolate::Current());
  __ enter(Immediate(0));
  __ LoadObject(CTX, context);
  __ PushObject(smi1);  // Push argument 1 smi1.
  __ PushObject(smi2);  // Push argument 2 smi2.
  __ PushObject(result);  // Push Null object for return value.
  // Pass a pointer to the first argument in EAX.
  __ leal(EAX, Address(ESP, 2 * kWordSize));
  __ movl(ECX, Immediate(reinterpret_cast<uword>(native_function)));
  __ movl(EDX, Immediate(argc));
  __ call(&StubCode::CallNativeCFunctionLabel());
  __ popl(EAX);  // Pop return value from return slot.
  __ AddImmediate(ESP, Immediate(argc * kWordSize));
  __ leave();
  __ ret();
}


TEST_CASE(CallNativeCFunctionStubCode) {
  const int value1 = 15;
  const int value2 = 20;
  const char* kName = "Test_CallNativeCFunctionStubCode";
  Assembler _assembler_;
  GenerateCallToCallNativeCFunctionStub(&_assembler_, value1, value2);
  const Code& code = Code::Handle(
      Code::FinalizeCode(kName, &_assembler_));
  const Function& function = RegisterFakeFunction(kName, code);
  GrowableArray<const Object*>  arguments;
  const Array& kNoArgumentNames = Array::Handle();
  Smi& result = Smi::Handle();
  result ^= DartEntry::InvokeStatic(function, arguments, kNoArgumentNames);
  EXPECT_EQ((value1 - value2), result.Value());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
