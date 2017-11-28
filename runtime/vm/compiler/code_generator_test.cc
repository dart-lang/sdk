// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "platform/assert.h"
#include "vm/ast.h"
#include "vm/class_finalizer.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/globals.h"
#include "vm/native_entry.h"
#include "vm/native_entry_test.h"
#include "vm/runtime_entry.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

static const TokenPosition kPos = TokenPosition::kMinSource;

CODEGEN_TEST_GENERATE(SimpleReturnCodegen, test) {
  test->node_sequence()->Add(new ReturnNode(kPos));
}
CODEGEN_TEST_RUN(SimpleReturnCodegen, Instance::null())

CODEGEN_TEST_GENERATE(SmiReturnCodegen, test) {
  LiteralNode* l = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3)));
  test->node_sequence()->Add(new ReturnNode(kPos, l));
}
CODEGEN_TEST_RUN(SmiReturnCodegen, Smi::New(3))

CODEGEN_TEST2_GENERATE(SimpleStaticCallCodegen, function, test) {
  // Wrap the SmiReturnCodegen test above as a static function and call it.
  ArgumentListNode* no_arguments = new ArgumentListNode(kPos);
  test->node_sequence()->Add(
      new ReturnNode(kPos, new StaticCallNode(kPos, function, no_arguments,
                                              StaticCallNode::kStatic)));
}
CODEGEN_TEST2_RUN(SimpleStaticCallCodegen, SmiReturnCodegen, Smi::New(3))

// Helper to allocate and return a LocalVariable.
static LocalVariable* NewTestLocalVariable(const char* name) {
  const String& variable_name =
      String::ZoneHandle(Symbols::New(Thread::Current(), name));
  const Type& variable_type = Type::ZoneHandle(Type::DynamicType());
  return new LocalVariable(kPos, kPos, variable_name, variable_type);
}

CODEGEN_TEST_GENERATE(ReturnParameterCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  const int num_params = 1;
  LocalVariable* parameter = NewTestLocalVariable("parameter");
  LocalScope* local_scope = node_seq->scope();
  local_scope->InsertParameterAt(0, parameter);
  ASSERT(local_scope->num_variables() == num_params);
  const Function& function = test->function();
  function.set_num_fixed_parameters(num_params);
  ASSERT(!function.HasOptionalParameters());
  node_seq->Add(new ReturnNode(kPos, new LoadLocalNode(kPos, parameter)));
}

CODEGEN_TEST2_GENERATE(StaticCallReturnParameterCodegen, function, test) {
  // Wrap and call the ReturnParameterCodegen test above as a static function.
  SequenceNode* node_seq = test->node_sequence();
  ArgumentListNode* arguments = new ArgumentListNode(kPos);
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3))));
  node_seq->Add(new ReturnNode(
      kPos,
      new StaticCallNode(kPos, function, arguments, StaticCallNode::kStatic)));
}
CODEGEN_TEST2_RUN(StaticCallReturnParameterCodegen,
                  ReturnParameterCodegen,
                  Smi::New(3))

CODEGEN_TEST_GENERATE(SmiParamSumCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  const int num_params = 2;
  LocalVariable* param1 = NewTestLocalVariable("param1");
  LocalVariable* param2 = NewTestLocalVariable("param2");
  const int num_locals = 1;
  LocalVariable* sum = NewTestLocalVariable("sum");
  LocalScope* local_scope = node_seq->scope();
  local_scope->InsertParameterAt(0, param1);
  local_scope->InsertParameterAt(1, param2);
  local_scope->AddVariable(sum);
  ASSERT(local_scope->num_variables() == num_params + num_locals);
  const Function& function = test->function();
  function.set_num_fixed_parameters(num_params);
  ASSERT(!function.HasOptionalParameters());
  BinaryOpNode* add =
      new BinaryOpNode(kPos, Token::kADD, new LoadLocalNode(kPos, param1),
                       new LoadLocalNode(kPos, param2));
  node_seq->Add(new StoreLocalNode(kPos, sum, add));
  node_seq->Add(new ReturnNode(kPos, new LoadLocalNode(kPos, sum)));
}

CODEGEN_TEST2_GENERATE(StaticCallSmiParamSumCodegen, function, test) {
  // Wrap and call the SmiParamSumCodegen test above as a static function.
  SequenceNode* node_seq = test->node_sequence();
  ArgumentListNode* arguments = new ArgumentListNode(kPos);
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3))));
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(2))));
  node_seq->Add(new ReturnNode(
      kPos,
      new StaticCallNode(kPos, function, arguments, StaticCallNode::kStatic)));
}
CODEGEN_TEST2_RUN(StaticCallSmiParamSumCodegen, SmiParamSumCodegen, Smi::New(5))

CODEGEN_TEST_GENERATE(SmiAddCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  LiteralNode* a = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3)));
  LiteralNode* b = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(2)));
  BinaryOpNode* add_node = new BinaryOpNode(kPos, Token::kADD, a, b);
  node_seq->Add(new ReturnNode(kPos, add_node));
}
CODEGEN_TEST_RUN(SmiAddCodegen, Smi::New(5))

CODEGEN_TEST_GENERATE(GenericAddCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  LiteralNode* a =
      new LiteralNode(kPos, Double::ZoneHandle(Double::New(12.2, Heap::kOld)));
  LiteralNode* b = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(2)));
  BinaryOpNode* add_node_1 = new BinaryOpNode(kPos, Token::kADD, a, b);
  LiteralNode* c =
      new LiteralNode(kPos, Double::ZoneHandle(Double::New(0.8, Heap::kOld)));
  BinaryOpNode* add_node_2 = new BinaryOpNode(kPos, Token::kADD, add_node_1, c);
  node_seq->Add(new ReturnNode(kPos, add_node_2));
}
CODEGEN_TEST_RUN(GenericAddCodegen, Double::New(15.0))

CODEGEN_TEST_GENERATE(SmiBinaryOpCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  LiteralNode* a = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(4)));
  LiteralNode* b = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(2)));
  LiteralNode* c = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3)));
  BinaryOpNode* sub_node =
      new BinaryOpNode(kPos, Token::kSUB, a, b);  // 4 - 2 -> 2.
  BinaryOpNode* mul_node =
      new BinaryOpNode(kPos, Token::kMUL, sub_node, c);  // 2 * 3 -> 6.
  BinaryOpNode* div_node =
      new BinaryOpNode(kPos, Token::kTRUNCDIV, mul_node, b);  // 6 ~/ 2 -> 3.
  node_seq->Add(new ReturnNode(kPos, div_node));
}
CODEGEN_TEST_RUN(SmiBinaryOpCodegen, Smi::New(3))

CODEGEN_TEST_GENERATE(BoolNotCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  LiteralNode* b = new LiteralNode(kPos, Bool::False());
  UnaryOpNode* not_node = new UnaryOpNode(kPos, Token::kNOT, b);
  node_seq->Add(new ReturnNode(kPos, not_node));
}
CODEGEN_TEST_RUN(BoolNotCodegen, Bool::True().raw())

CODEGEN_TEST_GENERATE(BoolAndCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  LiteralNode* a = new LiteralNode(kPos, Bool::True());
  LiteralNode* b = new LiteralNode(kPos, Bool::False());
  BinaryOpNode* and_node = new BinaryOpNode(kPos, Token::kAND, a, b);
  node_seq->Add(new ReturnNode(kPos, and_node));
}
CODEGEN_TEST_RUN(BoolAndCodegen, Bool::False().raw())

CODEGEN_TEST_GENERATE(BinaryOpCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  LiteralNode* a =
      new LiteralNode(kPos, Double::ZoneHandle(Double::New(12, Heap::kOld)));
  LiteralNode* b = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(2)));
  LiteralNode* c =
      new LiteralNode(kPos, Double::ZoneHandle(Double::New(0.5, Heap::kOld)));
  BinaryOpNode* sub_node = new BinaryOpNode(kPos, Token::kSUB, a, b);
  BinaryOpNode* mul_node = new BinaryOpNode(kPos, Token::kMUL, sub_node, c);
  BinaryOpNode* div_node = new BinaryOpNode(kPos, Token::kDIV, mul_node, b);
  node_seq->Add(new ReturnNode(kPos, div_node));
}
CODEGEN_TEST_RUN(BinaryOpCodegen, Double::New(2.5));

CODEGEN_TEST_GENERATE(SmiUnaryOpCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  LiteralNode* a = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(12)));
  UnaryOpNode* neg_node = new UnaryOpNode(kPos, Token::kNEGATE, a);
  node_seq->Add(new ReturnNode(kPos, neg_node));
}
CODEGEN_TEST_RUN(SmiUnaryOpCodegen, Smi::New(-12))

CODEGEN_TEST_GENERATE(DoubleUnaryOpCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  LiteralNode* a =
      new LiteralNode(kPos, Double::ZoneHandle(Double::New(12.0, Heap::kOld)));
  UnaryOpNode* neg_node = new UnaryOpNode(kPos, Token::kNEGATE, a);
  node_seq->Add(new ReturnNode(kPos, neg_node));
}
CODEGEN_TEST_RUN(DoubleUnaryOpCodegen, Double::New(-12.0))

static Library& MakeTestLibrary(const char* url) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  const String& lib_url = String::ZoneHandle(zone, Symbols::New(thread, url));
  Library& lib = Library::ZoneHandle(zone, Library::New(lib_url));
  lib.Register(thread);
  Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
  ASSERT(!core_lib.IsNull());
  const Namespace& core_ns = Namespace::Handle(
      zone, Namespace::New(core_lib, Array::Handle(zone), Array::Handle(zone)));
  lib.AddImport(core_ns);
  return lib;
}

static RawClass* LookupClass(const Library& lib, const char* name) {
  const String& cls_name =
      String::ZoneHandle(Symbols::New(Thread::Current(), name));
  return lib.LookupClass(cls_name);
}

CODEGEN_TEST_GENERATE(StaticCallCodegen, test) {
  const char* kScriptChars =
      "class A {\n"
      "  static bar() { return 42; }\n"
      "  static fly() { return 5; }\n"
      "}\n";

  String& url = String::Handle(String::New("dart-test:CompileScript"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script =
      Script::Handle(Script::New(url, source, RawScript::kScriptTag));
  Library& lib = MakeTestLibrary("TestLib");
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  Class& cls = Class::Handle(LookupClass(lib, "A"));
  EXPECT(!cls.IsNull());

  // 'bar' will not be compiled.
  String& function_bar_name = String::Handle(String::New("bar"));
  Function& function_bar =
      Function::ZoneHandle(cls.LookupStaticFunction(function_bar_name));
  EXPECT(!function_bar.IsNull());
  EXPECT(!function_bar.HasCode());

  // 'fly' will be compiled.
  String& function_fly_name = String::Handle(String::New("fly"));
  Function& function_fly =
      Function::ZoneHandle(cls.LookupStaticFunction(function_fly_name));
  EXPECT(!function_fly.IsNull());
  EXPECT(CompilerTest::TestCompileFunction(function_fly));
  EXPECT(function_fly.HasCode());

  ArgumentListNode* no_arguments = new ArgumentListNode(kPos);
  StaticCallNode* call_bar = new StaticCallNode(
      kPos, function_bar, no_arguments, StaticCallNode::kStatic);
  StaticCallNode* call_fly = new StaticCallNode(
      kPos, function_fly, no_arguments, StaticCallNode::kStatic);

  BinaryOpNode* add_node =
      new BinaryOpNode(kPos, Token::kADD, call_bar, call_fly);

  test->node_sequence()->Add(new ReturnNode(kPos, add_node));
}
CODEGEN_TEST_RUN(StaticCallCodegen, Smi::New(42 + 5))

CODEGEN_TEST_GENERATE(InstanceCallCodegen, test) {
  const char* kScriptChars =
      "class A {\n"
      "  A() {}\n"
      "  int bar() { return 42; }\n"
      "}\n";

  String& url = String::Handle(String::New("dart-test:CompileScript"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script =
      Script::Handle(Script::New(url, source, RawScript::kScriptTag));
  Library& lib = MakeTestLibrary("TestLib");
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  Class& cls = Class::ZoneHandle(LookupClass(lib, "A"));
  EXPECT(!cls.IsNull());

  String& constructor_name = String::Handle(String::New("A."));
  Function& constructor =
      Function::ZoneHandle(cls.LookupConstructor(constructor_name));
  EXPECT(!constructor.IsNull());

  // The unit test creates an instance of class A and calls function 'bar'.
  String& function_bar_name =
      String::ZoneHandle(Symbols::New(Thread::Current(), "bar"));
  ArgumentListNode* no_arguments = new ArgumentListNode(kPos);
  const TypeArguments& no_type_arguments = TypeArguments::ZoneHandle();
  InstanceCallNode* call_bar =
      new InstanceCallNode(kPos,
                           new ConstructorCallNode(kPos, no_type_arguments,
                                                   constructor, no_arguments),
                           function_bar_name, no_arguments);

  test->node_sequence()->Add(new ReturnNode(kPos, call_bar));
}
CODEGEN_TEST_RUN(InstanceCallCodegen, Smi::New(42))

// Test allocation of dart objects.
CODEGEN_TEST_GENERATE(AllocateNewObjectCodegen, test) {
  const char* kScriptChars =
      "class A {\n"
      "  A() {}\n"
      "  static bar() { return 42; }\n"
      "}\n";

  String& url = String::Handle(String::New("dart-test:CompileScript"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script =
      Script::Handle(Script::New(url, source, RawScript::kScriptTag));
  Library& lib = MakeTestLibrary("TestLib");
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  Class& cls = Class::ZoneHandle(LookupClass(lib, "A"));
  EXPECT(!cls.IsNull());

  String& constructor_name = String::Handle(String::New("A."));
  Function& constructor =
      Function::ZoneHandle(cls.LookupConstructor(constructor_name));
  EXPECT(!constructor.IsNull());

  const TypeArguments& no_type_arguments = TypeArguments::ZoneHandle();
  ArgumentListNode* no_arguments = new ArgumentListNode(kPos);
  test->node_sequence()->Add(
      new ReturnNode(kPos, new ConstructorCallNode(kPos, no_type_arguments,
                                                   constructor, no_arguments)));
}

CODEGEN_TEST_RAW_RUN(AllocateNewObjectCodegen, function) {
  const Object& result = Object::Handle(
      DartEntry::InvokeFunction(function, Object::empty_array()));
  EXPECT(!result.IsError());
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->libraries());
  ASSERT(!libs.IsNull());
  // App lib is the last one that was loaded.
  intptr_t num_libs = libs.Length();
  Library& app_lib = Library::Handle();
  app_lib ^= libs.At(num_libs - 1);
  ASSERT(!app_lib.IsNull());
  const Class& cls = Class::Handle(app_lib.LookupClass(
      String::Handle(Symbols::New(Thread::Current(), "A"))));
  EXPECT_EQ(cls.raw(), result.clazz());
}

}  // namespace dart
