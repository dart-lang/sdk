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

#define __ assembler->

ASSEMBLER_TEST_GENERATE(IcDataAccess, assembler) {
  const String& class_name = String::Handle(Symbols::New("ownerClass"));
  const Script& script = Script::Handle();
  const Class& owner_class =
      Class::Handle(Class::New(class_name, script, Scanner::kNoSourcePos));
  const String& function_name = String::Handle(Symbols::New("callerFunction"));
  const Function& function = Function::Handle(
      Function::New(function_name, RawFunction::kRegularFunction,
                    true, false, false, false, false, owner_class, 0));

  const String& target_name = String::Handle(String::New("targetFunction"));
  const Array& args_descriptor =
      Array::Handle(ArgumentsDescriptor::New(1, Object::null_array()));
  const ICData& ic_data = ICData::ZoneHandle(ICData::New(function,
                                                         target_name,
                                                         args_descriptor,
                                                         15,
                                                         1));

  __ LoadObject(R5, ic_data);
  StubCode* stub_code = Isolate::Current()->stub_code();
  ExternalLabel target_label(stub_code->OneArgCheckInlineCacheEntryPoint());
  __ BranchLinkPatchable(&target_label);
  __ Ret();
}


ASSEMBLER_TEST_RUN(IcDataAccess, test) {
  uword return_address =
      test->entry() + test->code().Size() - Instr::kInstrSize;
  ICData& ic_data = ICData::Handle();
  CodePatcher::GetInstanceCallAt(return_address, test->code(), &ic_data);
  EXPECT_STREQ("targetFunction",
      String::Handle(ic_data.target_name()).ToCString());
  EXPECT_EQ(1, ic_data.NumArgsTested());
  EXPECT_EQ(0, ic_data.NumberOfChecks());
}

}  // namespace dart

#endif  // TARGET_ARCH_ARM
