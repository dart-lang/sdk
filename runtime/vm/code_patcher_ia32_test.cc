// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/code_patcher.h"
#include "vm/dart_entry.h"
#include "vm/ic_data.h"
#include "vm/instructions.h"
#include "vm/native_entry.h"
#include "vm/native_entry_test.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

static const intptr_t kPos = 1;  // Dummy token index in non-existing source.

CODEGEN_TEST_GENERATE(NativePatchStaticCall, test) {
  SequenceNode* node_seq = test->node_sequence();
  const int num_params = 0;
  const bool has_opt_params = false;
  const String& native_name =
      String::ZoneHandle(String::NewSymbol("TestStaticCallPatching"));
  NativeFunction native_function = reinterpret_cast<NativeFunction>(
      NATIVE_ENTRY_FUNCTION(TestStaticCallPatching));
  node_seq->Add(new ReturnNode(kPos,
                               new NativeBodyNode(kPos,
                                                  native_name,
                                                  native_function,
                                                  num_params,
                                                  has_opt_params)));
}

CODEGEN_TEST2_GENERATE(PatchStaticCall, function, test) {
  SequenceNode* node_seq = test->node_sequence();
  ArgumentListNode* arguments = new ArgumentListNode(kPos);
  node_seq->Add(new ReturnNode(kPos,
                               new StaticCallNode(kPos, function, arguments)));
}

CODEGEN_TEST2_RUN(PatchStaticCall, NativePatchStaticCall, Instance::null());

#define __ assembler->

ASSEMBLER_TEST_GENERATE(InsertCall, assembler) {
  __ nop();
  __ nop();
  __ nop();
  __ nop();
  __ nop();
  __ ret();
}


ASSEMBLER_TEST_RUN(InsertCall, entry) {
  CodePatcher::InsertCall(entry, &StubCode::MegamorphicLookupLabel());
  Call call(entry);
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(), call.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(InsertJump, assembler) {
  __ nop();
  __ nop();
  __ nop();
  __ nop();
  __ nop();
  __ ret();
}


ASSEMBLER_TEST_RUN(InsertJump, entry) {
  CodePatcher::InsertJump(entry, &StubCode::MegamorphicLookupLabel());
  Jump jump(entry);
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(), jump.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(IcDataAccess, assembler) {
  const String& function_name = String::Handle(String::New("Vermicelles"));
  ICData ic_data(function_name, 1);
  EXPECT(!Array::Handle(ic_data.data()).IsNull());
  __ LoadObject(ECX, Array::ZoneHandle(ic_data.data()));
  __ LoadObject(EDX, CodeGenerator::ArgumentsDescriptor(1, Array::Handle()));
  __ call(&StubCode::CallInstanceFunctionLabel());
  __ ret();
}


ASSEMBLER_TEST_RUN(IcDataAccess, entry) {
  uword return_address = entry + CodePatcher::InstanceCallSizeInBytes();
  const Array& array = Array::Handle(
      CodePatcher::GetInstanceCallIcDataAt(return_address));
  EXPECT(!array.IsNull());
  ICData ic_data(array);
  EXPECT_STREQ("Vermicelles",
      String::Handle(ic_data.FunctionName()).ToCString());
  EXPECT_EQ(1, ic_data.NumberOfArgumentsChecked());
  EXPECT_EQ(0, ic_data.NumberOfChecks());
  const String& new_function_name = String::Handle(String::New("Rigi"));
  ICData new_ic_data(new_function_name, 1);
  EXPECT_STREQ("Rigi", String::Handle(new_ic_data.FunctionName()).ToCString());
  CodePatcher::SetInstanceCallIcDataAt(return_address,
                                       Array::ZoneHandle(new_ic_data.data()));
  const Array& new_array = Array::Handle(
      CodePatcher::GetInstanceCallIcDataAt(return_address));
  ICData test_ic_data(new_array);
  EXPECT_STREQ("Rigi", String::Handle(test_ic_data.FunctionName()).ToCString());
}

}  // namespace dart

#endif  // TARGET_ARCH_IA32
