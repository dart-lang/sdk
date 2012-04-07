// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

#include "vm/ast.h"
#include "vm/assembler.h"
#include "vm/code_descriptors.h"
#include "vm/code_generator.h"
#include "vm/dart_entry.h"
#include "vm/unit_test.h"

namespace dart {

static const intptr_t kPos = Scanner::kDummyTokenIndex;


CODEGEN_TEST_GENERATE(StackmapCodegen, test) {
  Assembler assembler;
  const String& function_name = String::ZoneHandle(String::NewSymbol("test"));
  const Function& function = Function::Handle(
      Function::New(function_name, RawFunction::kFunction, true, false, 0));
  function.set_result_type(Type::Handle(Type::DynamicType()));
  Class& cls = Class::ZoneHandle();
  const Script& script = Script::Handle();
  cls = Class::New(function_name, script, Scanner::kDummyTokenIndex);
  const Array& functions = Array::Handle(Array::New(1));
  functions.SetAt(0, function);
  cls.SetFunctions(functions);
  Library& lib = Library::Handle(Library::CoreLibrary());
  lib.AddClass(cls);
  ParsedFunction parsed_function(function);
  LiteralNode* l = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(1)));
  test->node_sequence()->Add(new ReturnNode(kPos, l));
  l = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(2)));
  test->node_sequence()->Add(new ReturnNode(kPos, l));
  l = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3)));
  test->node_sequence()->Add(new ReturnNode(kPos, l));
  parsed_function.set_node_sequence(test->node_sequence());
  parsed_function.set_instantiator(NULL);
  parsed_function.set_default_parameter_values(Array::Handle());
  parsed_function.AllocateVariables();
  bool retval;
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    CodeGenerator code_gen(&assembler, parsed_function);

    // Build some stack map entries.
    StackmapBuilder* builder = new StackmapBuilder();
    EXPECT(builder != NULL);
    builder->SetSlotAsObject(0);
    EXPECT(builder->IsSlotObject(0));
    builder->AddEntry(0);  // Add a stack map entry at pc offset 0.
    builder->SetSlotAsValue(1);
    EXPECT(!builder->IsSlotObject(1));
    builder->SetSlotAsObject(2);
    builder->AddEntry(1);  // Add a stack map entry at pc offset 1.
    EXPECT(builder->IsSlotObject(2));
    builder->SetSlotRangeAsObject(3, 5);
    for (intptr_t i = 3; i <= 5; i++) {
      EXPECT(builder->IsSlotObject(i));
    }
    builder->AddEntry(2);  // Add a stack map entry at pc offset 2.
    builder->SetSlotRangeAsValue(6, 9);
    for (intptr_t i = 6; i <= 9; i++) {
      EXPECT(!builder->IsSlotObject(i));
    }
    builder->SetSlotAsObject(10);
    builder->AddEntry(3);  // Add a stack map entry at pc offset 3.
    code_gen.GenerateCode();
    const char* function_fullname = function.ToFullyQualifiedCString();
    const Code& code =
        Code::Handle(Code::FinalizeCode(function_fullname, &assembler));
    const Array& stack_maps = Array::Handle(builder->FinalizeStackmaps(code));
    code.set_stackmaps(stack_maps);
    function.SetCode(code);
    const Array& stack_map_list = Array::Handle(code.stackmaps());
    EXPECT(!stack_map_list.IsNull());
    Stackmap& stack_map = Stackmap::Handle();
    EXPECT_EQ(4, stack_map_list.Length());

    // Validate the first stack map entry.
    stack_map ^= stack_map_list.At(0);
    EXPECT(stack_map.IsObject(0));
    EXPECT_EQ(0, stack_map.Minimum());
    EXPECT_EQ(0, stack_map.Maximum());

    // Validate the second stack map entry.
    stack_map ^= stack_map_list.At(1);
    EXPECT(stack_map.IsObject(0));
    EXPECT(!stack_map.IsObject(1));
    EXPECT(stack_map.IsObject(2));
    EXPECT_EQ(0, stack_map.Minimum());
    EXPECT_EQ(2, stack_map.Maximum());

    // Validate the third stack map entry.
    stack_map ^= stack_map_list.At(2);
    EXPECT(stack_map.IsObject(0));
    EXPECT(!stack_map.IsObject(1));
    for (intptr_t i = 2; i <= 5; i++) {
      EXPECT(stack_map.IsObject(i));
    }
    EXPECT_EQ(0, stack_map.Minimum());
    EXPECT_EQ(5, stack_map.Maximum());

    // Validate the fourth stack map entry.
    stack_map ^= stack_map_list.At(3);
    EXPECT(stack_map.IsObject(0));
    EXPECT(!stack_map.IsObject(1));
    for (intptr_t i = 2; i <= 5; i++) {
      EXPECT(stack_map.IsObject(i));
    }
    for (intptr_t i = 6; i <= 9; i++) {
      EXPECT(!stack_map.IsObject(i));
    }
    EXPECT(stack_map.IsObject(10));
    EXPECT_EQ(0, stack_map.Minimum());
    EXPECT_EQ(10, stack_map.Maximum());
    retval = true;
  } else {
    retval = false;
  }
  EXPECT(retval);
  isolate->set_long_jump_base(base);
}
CODEGEN_TEST_RUN(StackmapCodegen, Smi::New(1))

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32 || defined(TARGET_ARCH_X64)
