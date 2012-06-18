// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/code_patcher.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/native_entry.h"
#include "vm/native_entry_test.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

CODEGEN_TEST_GENERATE(NativePatchStaticCall, test) {
  SequenceNode* node_seq = test->node_sequence();
  const int num_params = 0;
  const bool has_opt_params = false;
  const String& native_name =
      String::ZoneHandle(String::NewSymbol("TestStaticCallPatching"));
  NativeFunction native_function = reinterpret_cast<NativeFunction>(
      NATIVE_ENTRY_FUNCTION(TestStaticCallPatching));
  node_seq->Add(new ReturnNode(Scanner::kDummyTokenIndex,
                               new NativeBodyNode(Scanner::kDummyTokenIndex,
                                                  native_name,
                                                  native_function,
                                                  num_params,
                                                  has_opt_params,
                                                  false)));
}

CODEGEN_TEST2_GENERATE(PatchStaticCall, function, test) {
  SequenceNode* node_seq = test->node_sequence();
  ArgumentListNode* arguments = new ArgumentListNode(Scanner::kDummyTokenIndex);
  node_seq->Add(new ReturnNode(Scanner::kDummyTokenIndex,
                               new StaticCallNode(Scanner::kDummyTokenIndex,
                                                  function, arguments)));
}

CODEGEN_TEST2_RUN(PatchStaticCall, NativePatchStaticCall, Instance::null());

#define __ assembler->

ASSEMBLER_TEST_GENERATE(IcDataAccess, assembler) {
  const String& function_name =
      String::ZoneHandle(String::NewSymbol("callerFunction"));
  const Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kFunction, true, false, 0));

  const String& target_name = String::Handle(String::New("targetFunction"));
  ICData& ic_data = ICData::ZoneHandle(
      ICData::New(function, target_name, 15, 1));
  __ LoadObject(ECX, ic_data);
  __ LoadObject(EDX, CodeGenerator::ArgumentsDescriptor(1, Array::Handle()));
  ExternalLabel target_label(
      "InlineCache", StubCode::OneArgCheckInlineCacheEntryPoint());
  __ call(&target_label);
  __ ret();
}


ASSEMBLER_TEST_RUN(IcDataAccess, entry) {
  uword return_address = entry + CodePatcher::InstanceCallSizeInBytes();
  const ICData& ic_data = ICData::Handle(
      CodePatcher::GetInstanceCallIcDataAt(return_address));
  EXPECT_STREQ("targetFunction",
      String::Handle(ic_data.target_name()).ToCString());
  EXPECT_EQ(1, ic_data.num_args_tested());
  EXPECT_EQ(0, ic_data.NumberOfChecks());
}

}  // namespace dart

#endif  // TARGET_ARCH_IA32
