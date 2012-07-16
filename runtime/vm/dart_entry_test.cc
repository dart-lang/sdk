// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/assembler.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/object.h"
#include "vm/resolver.h"
#include "vm/unit_test.h"

namespace dart {

// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

TEST_CASE(DartEntry) {
  const char* kScriptChars =
      "class A {\n"
      "  static foo() { return 42; }\n"
      "}\n";
  String& url = String::Handle(String::New("dart-test:DartEntry"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script = Script::Handle(Script::New(url, source, RawScript::kScript));
  Library& lib = Library::Handle(Library::CoreLibrary());
  EXPECT_EQ(true, CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::FinalizePendingClasses());
  Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(String::NewSymbol("A"))));
  EXPECT(!cls.IsNull());
  String& name = String::Handle(String::New("foo"));
  Function& function = Function::Handle(cls.LookupStaticFunction(name));
  EXPECT(!function.IsNull());

  EXPECT(CompilerTest::TestCompileFunction(function));
  EXPECT(function.HasCode());
  GrowableArray<const Object*> arguments;
  const Array& kNoArgumentNames = Array::Handle();
  const Smi& retval = Smi::Handle(
      reinterpret_cast<RawSmi*>(DartEntry::InvokeStatic(function,
                                                        arguments,
                                                        kNoArgumentNames)));
  EXPECT_EQ(Smi::New(42), retval.raw());
}


TEST_CASE(InvokeStatic_CompileError) {
  const char* kScriptChars =
      "class A {\n"
      "  static foo() { return ++++; }\n"
      "}\n";
  String& url = String::Handle(String::New("dart-test:DartEntry"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script = Script::Handle(Script::New(url, source, RawScript::kScript));
  Library& lib = Library::Handle(Library::CoreLibrary());
  EXPECT_EQ(true, CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::FinalizePendingClasses());
  Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(String::NewSymbol("A"))));
  EXPECT(!cls.IsNull());
  String& name = String::Handle(String::New("foo"));
  Function& function = Function::Handle(cls.LookupStaticFunction(name));
  EXPECT(!function.IsNull());
  GrowableArray<const Object*> arguments;
  const Array& kNoArgumentNames = Array::Handle();
  const Object& retval = Object::Handle(
      DartEntry::InvokeStatic(function, arguments, kNoArgumentNames));
  EXPECT(retval.IsError());
  Error& error = Error::Handle();
  error ^= retval.raw();
  EXPECT_SUBSTRING("++++", error.ToErrorCString());
}


TEST_CASE(InvokeDynamic_CompileError) {
  const char* kScriptChars =
      "class A {\n"
      "  foo() { return ++++; }\n"
      "}\n";
  String& url = String::Handle(String::New("dart-test:DartEntry"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script = Script::Handle(Script::New(url, source, RawScript::kScript));
  Library& lib = Library::Handle(Library::CoreLibrary());
  EXPECT_EQ(true, CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::FinalizePendingClasses());
  Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(String::NewSymbol("A"))));
  EXPECT(!cls.IsNull());

  // Invoke the constructor.
  const Instance& instance = Instance::Handle(Instance::New(cls));
  GrowableArray<const Object*> constructor_arguments(2);
  constructor_arguments.Add(&instance);
  constructor_arguments.Add(&Smi::Handle(Smi::New(Function::kCtorPhaseAll)));
  String& constructor_name = String::Handle(String::NewSymbol("A."));
  Function& constructor =
      Function::Handle(cls.LookupConstructor(constructor_name));
  ASSERT(!constructor.IsNull());
  const Array& kNoArgumentNames = Array::Handle();
  DartEntry::InvokeStatic(constructor, constructor_arguments, kNoArgumentNames);

  // Call foo.
  String& name = String::Handle(String::New("foo"));
  Function& function = Function::Handle(cls.LookupDynamicFunction(name));
  EXPECT(!function.IsNull());
  GrowableArray<const Object*> arguments;
  const Object& retval = Object::Handle(
      DartEntry::InvokeDynamic(
          instance, function, arguments, kNoArgumentNames));
  EXPECT(retval.IsError());
  Error& error = Error::Handle();
  error ^= retval.raw();
  EXPECT_SUBSTRING("++++", error.ToErrorCString());
}

#endif  // TARGET_ARCH_IA32 || TARGET_ARCH_X64.

}  // namespace dart
