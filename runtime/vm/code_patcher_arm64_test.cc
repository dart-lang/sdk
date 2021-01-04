// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/code_patcher.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/native_entry.h"
#include "vm/native_entry_test.h"
#include "vm/runtime_entry.h"
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
      function_name, FunctionLayout::kRegularFunction, true, false, false,
      false, false, owner_class, TokenPosition::kNoSource));

  const String& target_name = String::Handle(String::New("targetFunction"));
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgs = 1;
  const Array& args_descriptor = Array::Handle(ArgumentsDescriptor::NewBoxed(
      kTypeArgsLen, kNumArgs, Object::null_array()));
  const ICData& ic_data = ICData::ZoneHandle(ICData::New(
      function, target_name, args_descriptor, 15, 1, ICData::kInstance));
  const Code& stub = StubCode::OneArgCheckInlineCache();

  // Code is generated, but not executed. Just parsed with CodePatcher.
  __ set_constant_pool_allowed(true);  // Uninitialized pp is OK.
  SPILLS_LR_TO_FRAME({});              // Clobbered LR is OK.

  compiler::ObjectPoolBuilder& op = __ object_pool_builder();
  const intptr_t ic_data_index =
      op.AddObject(ic_data, ObjectPool::Patchability::kPatchable);
  const intptr_t stub_index =
      op.AddObject(stub, ObjectPool::Patchability::kPatchable);
  ASSERT((ic_data_index + 1) == stub_index);
  __ LoadDoubleWordFromPoolIndex(R5, CODE_REG, ic_data_index);
  __ Call(compiler::FieldAddress(
      CODE_REG, Code::entry_point_offset(Code::EntryKind::kMonomorphic)));
  RESTORES_LR_FROM_FRAME({});  // Clobbered LR is OK.
  __ ret();
}

ASSEMBLER_TEST_RUN(IcDataAccess, test) {
  uword end = test->payload_start() + test->code().Size();
  uword return_address = end - Instr::kInstrSize;
  ICData& ic_data = ICData::Handle();
  CodePatcher::GetInstanceCallAt(return_address, test->code(), &ic_data);
  EXPECT_STREQ("targetFunction",
               String::Handle(ic_data.target_name()).ToCString());
  EXPECT_EQ(1, ic_data.NumArgsTested());
  EXPECT_EQ(0, ic_data.NumberOfChecks());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
