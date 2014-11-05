// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"

#include "vm/ast.h"
#include "vm/assembler.h"
#include "vm/code_descriptors.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/native_entry.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

static const intptr_t kPos = Scanner::kNoSourcePos;


CODEGEN_TEST_GENERATE(StackmapCodegen, test) {
  ParsedFunction* parsed_function =
      new ParsedFunction(Isolate::Current(), test->function());
  LiteralNode* l = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(1)));
  test->node_sequence()->Add(new ReturnNode(kPos, l));
  l = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(2)));
  test->node_sequence()->Add(new ReturnNode(kPos, l));
  l = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3)));
  test->node_sequence()->Add(new ReturnNode(kPos, l));
  parsed_function->SetNodeSequence(test->node_sequence());
  parsed_function->set_instantiator(NULL);
  parsed_function->set_default_parameter_values(Object::null_array());
  parsed_function->EnsureExpressionTemp();
  test->node_sequence()->scope()->AddVariable(
      parsed_function->expression_temp_var());
  test->node_sequence()->scope()->AddVariable(
      parsed_function->current_context_var());
  parsed_function->AllocateVariables();
  bool retval;
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Build a stackmap table and some stackmap table entries.
    const intptr_t kStackSlotCount = 11;
    StackmapTableBuilder* stackmap_table_builder = new StackmapTableBuilder();
    EXPECT(stackmap_table_builder != NULL);

    BitmapBuilder* stack_bitmap = new BitmapBuilder();
    EXPECT(stack_bitmap != NULL);
    EXPECT_EQ(0, stack_bitmap->Length());
    stack_bitmap->Set(0, true);
    EXPECT_EQ(1, stack_bitmap->Length());
    stack_bitmap->SetLength(kStackSlotCount);
    EXPECT_EQ(kStackSlotCount, stack_bitmap->Length());

    bool expectation0[kStackSlotCount] = { true };
    for (intptr_t i = 0; i < kStackSlotCount; ++i) {
      EXPECT_EQ(expectation0[i], stack_bitmap->Get(i));
    }
    // Add a stack map entry at pc offset 0.
    stackmap_table_builder->AddEntry(0, stack_bitmap, 0);

    stack_bitmap = new BitmapBuilder();
    EXPECT(stack_bitmap != NULL);
    EXPECT_EQ(0, stack_bitmap->Length());
    stack_bitmap->Set(0, true);
    stack_bitmap->Set(1, false);
    stack_bitmap->Set(2, true);
    EXPECT_EQ(3, stack_bitmap->Length());
    stack_bitmap->SetLength(kStackSlotCount);
    EXPECT_EQ(kStackSlotCount, stack_bitmap->Length());

    bool expectation1[kStackSlotCount] = { true, false, true };
    for (intptr_t i = 0; i < kStackSlotCount; ++i) {
      EXPECT_EQ(expectation1[i], stack_bitmap->Get(i));
    }
    // Add a stack map entry at pc offset 1.
    stackmap_table_builder->AddEntry(1, stack_bitmap, 0);

    stack_bitmap = new BitmapBuilder();
    EXPECT(stack_bitmap != NULL);
    EXPECT_EQ(0, stack_bitmap->Length());
    stack_bitmap->Set(0, true);
    stack_bitmap->Set(1, false);
    stack_bitmap->Set(2, true);
    stack_bitmap->SetRange(3, 5, true);
    EXPECT_EQ(6, stack_bitmap->Length());
    stack_bitmap->SetLength(kStackSlotCount);
    EXPECT_EQ(kStackSlotCount, stack_bitmap->Length());

    bool expectation2[kStackSlotCount] =
        { true, false, true, true, true, true };
    for (intptr_t i = 0; i < kStackSlotCount; ++i) {
      EXPECT_EQ(expectation2[i], stack_bitmap->Get(i));
    }
    // Add a stack map entry at pc offset 2.
    stackmap_table_builder->AddEntry(2, stack_bitmap, 0);

    stack_bitmap = new BitmapBuilder();
    EXPECT(stack_bitmap != NULL);
    EXPECT_EQ(0, stack_bitmap->Length());
    stack_bitmap->Set(0, true);
    stack_bitmap->Set(1, false);
    stack_bitmap->Set(2, true);
    stack_bitmap->SetRange(3, 5, true);
    stack_bitmap->SetRange(6, 9, false);
    stack_bitmap->Set(10, true);
    EXPECT_EQ(11, stack_bitmap->Length());
    stack_bitmap->SetLength(kStackSlotCount);
    EXPECT_EQ(kStackSlotCount, stack_bitmap->Length());

    bool expectation3[kStackSlotCount] =
        { true, false, true, true, true, true, false, false,
          false, false, true };
    for (intptr_t i = 0; i < kStackSlotCount; ++i) {
      EXPECT_EQ(expectation3[i], stack_bitmap->Get(i));
    }
    // Add a stack map entry at pc offset 3.
    stackmap_table_builder->AddEntry(3, stack_bitmap, 0);

    const Error& error =
        Error::Handle(Compiler::CompileParsedFunction(parsed_function));
    EXPECT(error.IsNull());
    const Code& code = Code::Handle(test->function().CurrentCode());

    const Array& stack_maps =
        Array::Handle(stackmap_table_builder->FinalizeStackmaps(code));
    code.set_stackmaps(stack_maps);
    const Array& stack_map_list = Array::Handle(code.stackmaps());
    EXPECT(!stack_map_list.IsNull());
    Stackmap& stack_map = Stackmap::Handle();
    EXPECT_EQ(4, stack_map_list.Length());

    // Validate the first stack map entry.
    stack_map ^= stack_map_list.At(0);
    EXPECT_EQ(kStackSlotCount, stack_map.Length());
    for (intptr_t i = 0; i < kStackSlotCount; ++i) {
      EXPECT_EQ(expectation0[i], stack_map.IsObject(i));
    }

    // Validate the second stack map entry.
    stack_map ^= stack_map_list.At(1);
    EXPECT_EQ(kStackSlotCount, stack_map.Length());
    for (intptr_t i = 0; i < kStackSlotCount; ++i) {
      EXPECT_EQ(expectation1[i], stack_map.IsObject(i));
    }

    // Validate the third stack map entry.
    stack_map ^= stack_map_list.At(2);
    EXPECT_EQ(kStackSlotCount, stack_map.Length());
    for (intptr_t i = 0; i < kStackSlotCount; ++i) {
      EXPECT_EQ(expectation2[i], stack_map.IsObject(i));
    }

    // Validate the fourth stack map entry.
    stack_map ^= stack_map_list.At(3);
    EXPECT_EQ(kStackSlotCount, stack_map.Length());
    for (intptr_t i = 0; i < kStackSlotCount; ++i) {
      EXPECT_EQ(expectation3[i], stack_map.IsObject(i));
    }
    retval = true;
  } else {
    retval = false;
  }
  EXPECT(retval);
}
CODEGEN_TEST_RUN(StackmapCodegen, Smi::New(1))


static void NativeFunc(Dart_NativeArguments args) {
  Dart_Handle i = Dart_GetNativeArgument(args, 0);
  Dart_Handle k = Dart_GetNativeArgument(args, 1);
  int64_t value = -1;
  EXPECT_VALID(Dart_IntegerToInt64(i, &value));
  EXPECT_EQ(10, value);
  EXPECT_VALID(Dart_IntegerToInt64(k, &value));
  EXPECT_EQ(20, value);
  Isolate::Current()->heap()->CollectAllGarbage();
}


static Dart_NativeFunction native_resolver(Dart_Handle name,
                                           int argument_count,
                                           bool* auto_setup_scope) {
  ASSERT(auto_setup_scope);
  *auto_setup_scope = false;
  return reinterpret_cast<Dart_NativeFunction>(&NativeFunc);
}


TEST_CASE(StackmapGC) {
  const char* kScriptChars =
      "class A {"
      "  static void func(var i, var k) native 'NativeFunc';"
      "  static foo() {"
      "    var i;"
      "    var s1;"
      "    var k;"
      "    var s2;"
      "    var s3;"
      "    i = 10; s1 = 'abcd'; k = 20; s2 = 'B'; s3 = 'C';"
      "    func(i, k);"
      "    return i + k; }"
      "  static int moo() {"
      "    var i = A.foo();"
      "    Expect.equals(30, i);"
      "  }\n"
      "}\n";
  // First setup the script and compile the script.
  TestCase::LoadTestScript(kScriptChars, native_resolver);
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  const String& name = String::Handle(String::New(TestCase::url()));
  const Library& lib = Library::Handle(Library::LookupLibrary(name));
  EXPECT(!lib.IsNull());
  Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New("A"))));
  EXPECT(!cls.IsNull());

  // Now compile the two functions 'A.foo' and 'A.moo'
  String& function_moo_name = String::Handle(String::New("moo"));
  Function& function_moo =
      Function::Handle(cls.LookupStaticFunction(function_moo_name));
  EXPECT(CompilerTest::TestCompileFunction(function_moo));
  EXPECT(function_moo.HasCode());

  String& function_foo_name = String::Handle(String::New("foo"));
  Function& function_foo =
      Function::Handle(cls.LookupStaticFunction(function_foo_name));
  EXPECT(CompilerTest::TestCompileFunction(function_foo));
  EXPECT(function_foo.HasCode());

  // Build and setup a stackmap for the call to 'func' in 'A.foo' in order
  // to test the traversal of stack maps when a GC happens.
  StackmapTableBuilder* stackmap_table_builder = new StackmapTableBuilder();
  EXPECT(stackmap_table_builder != NULL);
  BitmapBuilder* stack_bitmap = new BitmapBuilder();
  EXPECT(stack_bitmap != NULL);
  stack_bitmap->Set(0, false);  // var i.
  stack_bitmap->Set(1, true);  // var s1.
  stack_bitmap->Set(2, false);  // var k.
  stack_bitmap->Set(3, true);  // var s2.
  stack_bitmap->Set(4, true);  // var s3.
  const Code& code = Code::Handle(function_foo.unoptimized_code());
  // Search for the pc of the call to 'func'.
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  int call_count = 0;
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kUnoptStaticCall);
  while (iter.MoveNext()) {
    stackmap_table_builder->AddEntry(iter.Pc() - code.EntryPoint(),
                                     stack_bitmap,
                                     0);
    ++call_count;
  }
  // We can't easily check that we put the stackmap at the correct pc, but
  // we did if there was exactly one call seen.
  EXPECT(call_count == 1);
  const Array& stack_maps =
      Array::Handle(stackmap_table_builder->FinalizeStackmaps(code));
  code.set_stackmaps(stack_maps);

  // Now invoke 'A.moo' and it will trigger a GC when the native function
  // is called, this should then cause the stack map of function 'A.foo'
  // to be traversed and the appropriate objects visited.
  const Object& result = Object::Handle(
      DartEntry::InvokeFunction(function_foo, Object::empty_array()));
  EXPECT(!result.IsError());
}

}  // namespace dart
