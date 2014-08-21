// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/ast.h"
#include "vm/assembler.h"
#include "vm/class_finalizer.h"
#include "vm/code_generator.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/native_entry.h"
#include "vm/native_entry_test.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

static const intptr_t kPos = Scanner::kNoSourcePos;


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
      new ReturnNode(kPos, new StaticCallNode(kPos, function, no_arguments)));
}
CODEGEN_TEST2_RUN(SimpleStaticCallCodegen, SmiReturnCodegen, Smi::New(3))


// Helper to allocate and return a LocalVariable.
static LocalVariable* NewTestLocalVariable(const char* name) {
  const String& variable_name = String::ZoneHandle(Symbols::New(name));
  const Type& variable_type = Type::ZoneHandle(Type::DynamicType());
  return new LocalVariable(kPos, variable_name, variable_type);
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
  node_seq->Add(new ReturnNode(kPos,
                               new StaticCallNode(kPos, function, arguments)));
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
  BinaryOpNode* add = new BinaryOpNode(kPos,
                                       Token::kADD,
                                       new LoadLocalNode(kPos, param1),
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
  node_seq->Add(new ReturnNode(kPos,
                               new StaticCallNode(kPos, function, arguments)));
}
CODEGEN_TEST2_RUN(StaticCallSmiParamSumCodegen,
                  SmiParamSumCodegen,
                  Smi::New(5))


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


// Tested Dart code:
//   int dec(int a, [int b = 1]) native: "TestSmiSub";
// The native entry TestSmiSub implements dec natively.
CODEGEN_TEST_GENERATE(NativeDecCodegen, test) {
  // A NativeBodyNode, preceded by an EnterNode and followed by a ReturnNode,
  // implements the body of a native Dart function. Let's take this native
  // function as an example: int dec(int a, int b = 1) native;
  // Since this function has an optional parameter, its prologue will copy
  // incoming parameters to locals.
  SequenceNode* node_seq = test->node_sequence();
  const int num_fixed_params = 1;
  const int num_opt_params = 1;
  const int num_params = num_fixed_params + num_opt_params;
  LocalScope* local_scope = node_seq->scope();
  local_scope->InsertParameterAt(0, NewTestLocalVariable("a"));
  local_scope->InsertParameterAt(1, NewTestLocalVariable("b"));
  ASSERT(local_scope->num_variables() == num_params);
  const Array& default_values = Array::ZoneHandle(Array::New(num_opt_params));
  default_values.SetAt(0, Smi::ZoneHandle(Smi::New(1)));  // b = 1.
  test->set_default_parameter_values(default_values);
  const Function& function = test->function();
  function.set_is_native(true);
  function.set_num_fixed_parameters(num_fixed_params);
  function.SetNumOptionalParameters(num_opt_params, true);
  const String& native_name =
      String::ZoneHandle(Symbols::New("TestSmiSub"));
  NativeFunction native_function =
      reinterpret_cast<NativeFunction>(TestSmiSub);
  node_seq->Add(
      new ReturnNode(kPos,
                     new NativeBodyNode(kPos,
                                        function,
                                        native_name,
                                        native_function,
                                        local_scope,
                                        false /* not bootstrap native */)));
}


// Tested Dart code:
//   return dec(5);
CODEGEN_TEST2_GENERATE(StaticDecCallCodegen, function, test) {
  SequenceNode* node_seq = test->node_sequence();
  ArgumentListNode* arguments = new ArgumentListNode(kPos);
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(5))));
  node_seq->Add(new ReturnNode(kPos,
                               new StaticCallNode(kPos, function, arguments)));
}
CODEGEN_TEST2_RUN(StaticDecCallCodegen, NativeDecCodegen, Smi::New(4))


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
  const String& lib_url = String::ZoneHandle(Symbols::New(url));
  Library& lib = Library::ZoneHandle(Library::New(lib_url));
  lib.Register();
  Library& core_lib = Library::Handle(Library::CoreLibrary());
  ASSERT(!core_lib.IsNull());
  const Namespace& core_ns = Namespace::Handle(
      Namespace::New(core_lib, Array::Handle(), Array::Handle()));
  lib.AddImport(core_ns);
  return lib;
}


static RawClass* LookupClass(const Library& lib, const char* name) {
  const String& cls_name = String::ZoneHandle(Symbols::New(name));
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
  Script& script = Script::Handle(Script::New(url,
                                              source,
                                              RawScript::kScriptTag));
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
  StaticCallNode* call_bar =
      new StaticCallNode(kPos, function_bar, no_arguments);
  StaticCallNode* call_fly =
      new StaticCallNode(kPos, function_fly, no_arguments);

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
  Script& script = Script::Handle(Script::New(url,
                                              source,
                                              RawScript::kScriptTag));
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
  String& function_bar_name = String::ZoneHandle(Symbols::New("bar"));
  ArgumentListNode* no_arguments = new ArgumentListNode(kPos);
  const TypeArguments& no_type_arguments = TypeArguments::ZoneHandle();
  InstanceCallNode* call_bar = new InstanceCallNode(
      kPos,
      new ConstructorCallNode(
          kPos, no_type_arguments, constructor, no_arguments),
      function_bar_name,
      no_arguments);

  test->node_sequence()->Add(new ReturnNode(kPos, call_bar));
}
CODEGEN_TEST_RUN(InstanceCallCodegen, Smi::New(42))


// Tested Dart code:
//   int sum(int a, int b,
//           [int c = 10, int d = 21, int e = -32]) native: "TestSmiSum";
// The native entry TestSmiSum implements sum natively.
CODEGEN_TEST_GENERATE(NativeSumCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  const int num_fixed_params = 2;
  const int num_opt_params = 3;
  const int num_params = num_fixed_params + num_opt_params;
  LocalScope* local_scope = node_seq->scope();
  local_scope->InsertParameterAt(0, NewTestLocalVariable("a"));
  local_scope->InsertParameterAt(1, NewTestLocalVariable("b"));
  local_scope->InsertParameterAt(2, NewTestLocalVariable("c"));
  local_scope->InsertParameterAt(3, NewTestLocalVariable("d"));
  local_scope->InsertParameterAt(4, NewTestLocalVariable("e"));
  ASSERT(local_scope->num_variables() == num_params);
  const Array& default_values = Array::ZoneHandle(Array::New(num_opt_params));
  default_values.SetAt(0, Smi::ZoneHandle(Smi::New(10)));
  default_values.SetAt(1, Smi::ZoneHandle(Smi::New(21)));
  default_values.SetAt(2, Smi::ZoneHandle(Smi::New(-32)));
  test->set_default_parameter_values(default_values);
  const Function& function = test->function();
  function.set_is_native(true);
  function.set_num_fixed_parameters(num_fixed_params);
  function.SetNumOptionalParameters(num_opt_params, true);
  function.set_parameter_types(Array::Handle(Array::New(num_params)));
  function.set_parameter_names(Array::Handle(Array::New(num_params)));
  const Type& param_type = Type::Handle(Type::DynamicType());
  for (int i = 0; i < num_params; i++) {
    function.SetParameterTypeAt(i, param_type);
  }
  const String& native_name =
      String::ZoneHandle(Symbols::New("TestSmiSum"));
  NativeFunction native_function =
      reinterpret_cast<NativeFunction>(TestSmiSum);
  node_seq->Add(
      new ReturnNode(kPos,
                     new NativeBodyNode(kPos,
                                        function,
                                        native_name,
                                        native_function,
                                        local_scope,
                                        false /* Not bootstrap native */)));
}


// Tested Dart code, calling function sum declared above:
//   return sum(1, 3);
// Optional arguments are not passed and hence are set to their default values.
CODEGEN_TEST2_GENERATE(StaticSumCallNoOptCodegen, function, test) {
  SequenceNode* node_seq = test->node_sequence();
  ArgumentListNode* arguments = new ArgumentListNode(kPos);
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(1))));
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3))));
  node_seq->Add(new ReturnNode(kPos,
                               new StaticCallNode(kPos, function, arguments)));
}
CODEGEN_TEST2_RUN(StaticSumCallNoOptCodegen,
                  NativeSumCodegen,
                  Smi::New(1 + 3 + 10 + 21 - 32))


// Tested Dart code, calling function sum declared above:
//   return sum(1, 3, 5);
// Only one out of three optional arguments is passed in; the second and third
// arguments are hence set to their default values.
CODEGEN_TEST2_GENERATE(StaticSumCallOneOptCodegen, function, test) {
  SequenceNode* node_seq = test->node_sequence();
  ArgumentListNode* arguments = new ArgumentListNode(kPos);
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(1))));
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3))));
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(5))));
  node_seq->Add(new ReturnNode(kPos,
                               new StaticCallNode(kPos, function, arguments)));
}
CODEGEN_TEST2_RUN(StaticSumCallOneOptCodegen,
                  NativeSumCodegen,
                  Smi::New(1 + 3 + 5 + 21 - 32))


// Tested Dart code, calling function sum declared above:
//   return sum(0, 1, 1, 2, 3);
// Optional arguments are passed in.
CODEGEN_TEST2_GENERATE(StaticSumCallTenFiboCodegen, function, test) {
  SequenceNode* node_seq = test->node_sequence();
  ArgumentListNode* arguments = new ArgumentListNode(kPos);
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(0))));
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(1))));
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(1))));
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(2))));
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3))));
  node_seq->Add(new ReturnNode(kPos,
                               new StaticCallNode(kPos, function, arguments)));
}
CODEGEN_TEST2_RUN(
    StaticSumCallTenFiboCodegen,
    NativeSumCodegen,
    Smi::New(0 + 1 + 1 + 2 + 3))


// Tested Dart code:
//   int sum(a, b, c) native: "TestNonNullSmiSum";
// The native entry TestNonNullSmiSum implements sum natively.
CODEGEN_TEST_GENERATE(NativeNonNullSumCodegen, test) {
  SequenceNode* node_seq = test->node_sequence();
  const int num_params = 3;
  LocalScope* local_scope = node_seq->scope();
  local_scope->InsertParameterAt(0, NewTestLocalVariable("a"));
  local_scope->InsertParameterAt(1, NewTestLocalVariable("b"));
  local_scope->InsertParameterAt(2, NewTestLocalVariable("c"));
  ASSERT(local_scope->num_variables() == num_params);
  const Function& function = test->function();
  function.set_is_native(true);
  function.set_num_fixed_parameters(num_params);
  ASSERT(!function.HasOptionalParameters());
  function.set_parameter_types(Array::Handle(Array::New(num_params)));
  function.set_parameter_names(Array::Handle(Array::New(num_params)));
  const Type& param_type = Type::Handle(Type::DynamicType());
  for (int i = 0; i < num_params; i++) {
    function.SetParameterTypeAt(i, param_type);
  }
  const String& native_name =
      String::ZoneHandle(Symbols::New("TestNonNullSmiSum"));
  NativeFunction native_function =
      reinterpret_cast<NativeFunction>(TestNonNullSmiSum);
  node_seq->Add(
      new ReturnNode(kPos,
                     new NativeBodyNode(kPos,
                                        function,
                                        native_name,
                                        native_function,
                                        local_scope,
                                        false /* Not bootstrap native */)));
}


// Tested Dart code, calling function sum declared above:
//   return sum(1, null, 3);
CODEGEN_TEST2_GENERATE(StaticNonNullSumCallCodegen, function, test) {
  SequenceNode* node_seq = test->node_sequence();
  ArgumentListNode* arguments = new ArgumentListNode(kPos);
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(1))));
  arguments->Add(new LiteralNode(kPos, Instance::ZoneHandle()));
  arguments->Add(new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3))));
  node_seq->Add(new ReturnNode(kPos,
                               new StaticCallNode(kPos, function, arguments)));
}
CODEGEN_TEST2_RUN(StaticNonNullSumCallCodegen,
                  NativeNonNullSumCodegen,
                  Smi::New(1 + 3))


// Test allocation of dart objects.
CODEGEN_TEST_GENERATE(AllocateNewObjectCodegen, test) {
  const char* kScriptChars =
      "class A {\n"
      "  A() {}\n"
      "  static bar() { return 42; }\n"
      "}\n";

  String& url = String::Handle(String::New("dart-test:CompileScript"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script = Script::Handle(Script::New(url,
                                              source,
                                              RawScript::kScriptTag));
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
  test->node_sequence()->Add(new ReturnNode(kPos, new ConstructorCallNode(
      kPos, no_type_arguments, constructor, no_arguments)));
}


CODEGEN_TEST_RAW_RUN(AllocateNewObjectCodegen, function) {
  const Object& result = Object::Handle(
      DartEntry::InvokeFunction(function, Object::empty_array()));
  EXPECT(!result.IsError());
  const GrowableObjectArray& libs =  GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->libraries());
  ASSERT(!libs.IsNull());
  // App lib is the last one that was loaded.
  intptr_t num_libs = libs.Length();
  Library& app_lib = Library::Handle();
  app_lib ^= libs.At(num_libs - 1);
  ASSERT(!app_lib.IsNull());
  const Class& cls = Class::Handle(
      app_lib.LookupClass(String::Handle(Symbols::New("A"))));
  EXPECT_EQ(cls.raw(), result.clazz());
}

}  // namespace dart
