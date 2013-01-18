// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/code_patcher.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/native_entry.h"
#include "vm/native_entry_test.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

CODEGEN_TEST_GENERATE(NativePatchStaticCall, test) {
  SequenceNode* node_seq = test->node_sequence();
  const String& native_name =
      String::ZoneHandle(Symbols::New("TestStaticCallPatching"));
  NativeFunction native_function =
      reinterpret_cast<NativeFunction>(TestStaticCallPatching);
  test->function().set_is_native(true);
  node_seq->Add(new ReturnNode(Scanner::kDummyTokenIndex,
                               new NativeBodyNode(Scanner::kDummyTokenIndex,
                                                  test->function(),
                                                  native_name,
                                                  native_function)));
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
  UNIMPLEMENTED();
}


ASSEMBLER_TEST_RUN(IcDataAccess, entry) {
  uword return_address = entry + CodePatcher::InstanceCallSizeInBytes();
  ICData& ic_data = ICData::Handle();
  CodePatcher::GetInstanceCallAt(return_address, &ic_data, NULL);
  EXPECT_STREQ("targetFunction",
      String::Handle(ic_data.target_name()).ToCString());
  EXPECT_EQ(1, ic_data.num_args_tested());
  EXPECT_EQ(0, ic_data.NumberOfChecks());
}

}  // namespace dart

#endif  // TARGET_ARCH_ARM
