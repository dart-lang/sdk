// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

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
  Thread* thread = Thread::Current();
  const String& class_name = String::Handle(Symbols::New(thread, "ownerClass"));
  const Script& script = Script::Handle();
  const Class& owner_class = Class::Handle(Class::New(
      Library::Handle(), class_name, script, TokenPosition::kNoSource));
  const String& function_name =
      String::Handle(Symbols::New(thread, "callerFunction"));
  const Function& function = Function::Handle(Function::New(
      function_name, RawFunction::kRegularFunction, true, false, false, false,
      false, owner_class, TokenPosition::kNoSource));

  const String& target_name = String::Handle(String::New("targetFunction"));
  const Array& args_descriptor =
      Array::Handle(ArgumentsDescriptor::New(1, Object::null_array()));
  const ICData& ic_data = ICData::ZoneHandle(
      ICData::New(function, target_name, args_descriptor, 15, 1, false));

  // Code accessing pp is generated, but not executed. Uninitialized pp is OK.
  __ set_constant_pool_allowed(true);

  __ LoadObject(RBX, ic_data);
  __ CallPatchable(*StubCode::OneArgCheckInlineCache_entry());
  __ ret();
}


ASSEMBLER_TEST_RUN(IcDataAccess, test) {
  uword return_address = test->entry() + CodePatcher::InstanceCallSizeInBytes();
  ICData& ic_data = ICData::Handle();
  CodePatcher::GetInstanceCallAt(return_address, test->code(), &ic_data);
  EXPECT_STREQ("targetFunction",
               String::Handle(ic_data.target_name()).ToCString());
  EXPECT_EQ(1, ic_data.NumArgsTested());
  EXPECT_EQ(0, ic_data.NumberOfChecks());
}

}  // namespace dart

#endif  // TARGET_ARCH_X64
