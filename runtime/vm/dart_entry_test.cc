// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/object.h"
#include "vm/resolver.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(DartEntry) {
  const char* kScriptChars =
      "class A {\n"
      "  static foo() { return 42; }\n"
      "}\n";
  String& url = String::Handle(String::New("dart-test:DartEntry"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script =
      Script::Handle(Script::New(url, source, RawScript::kScriptTag));
  Library& lib = Library::Handle(Library::CoreLibrary());
  EXPECT_EQ(true, CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  Class& cls =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "A"))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  String& name = String::Handle(String::New("foo"));
  Function& function = Function::Handle(cls.LookupStaticFunction(name));
  EXPECT(!function.IsNull());

  EXPECT(CompilerTest::TestCompileFunction(function));
  EXPECT(function.HasCode());
  const Smi& retval = Smi::Handle(reinterpret_cast<RawSmi*>(
      DartEntry::InvokeFunction(function, Object::empty_array())));
  EXPECT_EQ(Smi::New(42), retval.raw());
}

TEST_CASE(InvokeStatic_CompileError) {
  const char* kScriptChars =
      "class A {\n"
      "  static foo() { return ++++; }\n"
      "}\n";
  String& url = String::Handle(String::New("dart-test:DartEntry"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script =
      Script::Handle(Script::New(url, source, RawScript::kScriptTag));
  Library& lib = Library::Handle(Library::CoreLibrary());
  EXPECT_EQ(true, CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  Class& cls =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "A"))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  String& name = String::Handle(String::New("foo"));
  Function& function = Function::Handle(cls.LookupStaticFunction(name));
  EXPECT(!function.IsNull());
  const Object& retval = Object::Handle(
      DartEntry::InvokeFunction(function, Object::empty_array()));
  EXPECT(retval.IsError());
  EXPECT_SUBSTRING("++++", Error::Cast(retval).ToErrorCString());
}

TEST_CASE(InvokeDynamic_CompileError) {
  const char* kScriptChars =
      "class A {\n"
      "  foo() { return ++++; }\n"
      "}\n";
  String& url = String::Handle(String::New("dart-test:DartEntry"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script =
      Script::Handle(Script::New(url, source, RawScript::kScriptTag));
  Library& lib = Library::Handle(Library::CoreLibrary());
  EXPECT_EQ(true, CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  Class& cls =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "A"))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.

  // Invoke the constructor.
  const Instance& instance = Instance::Handle(Instance::New(cls));
  const Array& constructor_arguments = Array::Handle(Array::New(1));
  constructor_arguments.SetAt(0, instance);
  String& constructor_name = String::Handle(Symbols::New(thread, "A."));
  Function& constructor =
      Function::Handle(cls.LookupConstructor(constructor_name));
  ASSERT(!constructor.IsNull());
  DartEntry::InvokeFunction(constructor, constructor_arguments);

  // Call foo.
  String& name = String::Handle(String::New("foo"));
  Function& function = Function::Handle(cls.LookupDynamicFunction(name));
  EXPECT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, instance);
  const Object& retval =
      Object::Handle(DartEntry::InvokeFunction(function, args));
  EXPECT(retval.IsError());
  EXPECT_SUBSTRING("++++", Error::Cast(retval).ToErrorCString());
}

}  // namespace dart
