// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/native_entry.h"
#include "vm/native_entry_test.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

#define __ assembler->

namespace dart {

static Function* CreateFunction(const char* name) {
  const String& class_name =
      String::Handle(Symbols::New(Thread::Current(), "ownerClass"));
  const Script& script = Script::Handle();
  const Library& lib = Library::Handle(Library::New(class_name));
  const Class& owner_class = Class::Handle(
      Class::New(lib, class_name, script, TokenPosition::kNoSource));
  const String& function_name =
      String::ZoneHandle(Symbols::New(Thread::Current(), name));
  Function& function = Function::ZoneHandle(Function::New(
      function_name, RawFunction::kRegularFunction, true, false, false, false,
      false, owner_class, TokenPosition::kMinSource));
  return &function;
}

// Test calls to stub code which calls into the runtime.
static void GenerateCallToCallRuntimeStub(Assembler* assembler, int length) {
  const int argc = 2;
  const Smi& smi_length = Smi::ZoneHandle(Smi::New(length));
  __ enter(Immediate(0));
  __ PushObject(Object::null_object());  // Push Null object for return value.
  __ PushObject(smi_length);             // Push argument 1: length.
  __ PushObject(Object::null_object());  // Push argument 2: type arguments.
  ASSERT(kAllocateArrayRuntimeEntry.argument_count() == argc);
  __ CallRuntime(kAllocateArrayRuntimeEntry, argc);
  __ AddImmediate(ESP, Immediate(argc * kWordSize));
  __ popl(EAX);  // Pop return value from return slot.
  __ leave();
  __ ret();
}

TEST_CASE(CallRuntimeStubCode) {
  extern const Function& RegisterFakeFunction(const char* name,
                                              const Code& code);
  const int length = 10;
  const char* kName = "Test_CallRuntimeStubCode";
  Assembler _assembler_;
  GenerateCallToCallRuntimeStub(&_assembler_, length);
  const Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_CallRuntimeStubCode"), &_assembler_));
  const Function& function = RegisterFakeFunction(kName, code);
  Array& result = Array::Handle();
  result ^= DartEntry::InvokeFunction(function, Object::empty_array());
  EXPECT_EQ(length, result.Length());
}

// Test calls to stub code which calls into a leaf runtime entry.
static void GenerateCallToCallLeafRuntimeStub(Assembler* assembler,
                                              const char* value1,
                                              const char* value2) {
  const Bigint& bigint1 =
      Bigint::ZoneHandle(Bigint::NewFromCString(value1, Heap::kOld));
  const Bigint& bigint2 =
      Bigint::ZoneHandle(Bigint::NewFromCString(value2, Heap::kOld));
  __ enter(Immediate(0));
  __ ReserveAlignedFrameSpace(2 * kWordSize);
  __ LoadObject(EAX, bigint1);
  __ movl(Address(ESP, 0), EAX);  // Push argument 1 bigint1.
  __ LoadObject(EAX, bigint2);
  __ movl(Address(ESP, kWordSize), EAX);  // Push argument 2 bigint2.
  __ CallRuntime(kBigintCompareRuntimeEntry, 2);
  __ SmiTag(EAX);
  __ leave();
  __ ret();  // Return value is in EAX.
}

TEST_CASE(CallLeafRuntimeStubCode) {
  extern const Function& RegisterFakeFunction(const char* name,
                                              const Code& code);
  const char* value1 = "0xAAABBCCDDAABBCCDD";
  const char* value2 = "0xAABBCCDDAABBCCDD";
  const char* kName = "Test_CallLeafRuntimeStubCode";
  Assembler _assembler_;
  GenerateCallToCallLeafRuntimeStub(&_assembler_, value1, value2);
  const Code& code = Code::Handle(Code::FinalizeCode(
      *CreateFunction("Test_CallLeafRuntimeStubCode"), &_assembler_));
  const Function& function = RegisterFakeFunction(kName, code);
  Smi& result = Smi::Handle();
  result ^= DartEntry::InvokeFunction(function, Object::empty_array());
  EXPECT_EQ(1, result.Value());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
