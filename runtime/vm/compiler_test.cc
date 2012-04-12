// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

// Compiler only implemented on IA32 and X64 now.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

TEST_CASE(CompileScript) {
  const char* kScriptChars =
      "class A {\n"
      "  static foo() { return 42; }\n"
      "}\n";
  String& url = String::Handle(String::New("dart-test:CompileScript"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script = Script::Handle(Script::New(url, source, RawScript::kSource));
  Library& lib = Library::Handle(Library::CoreLibrary());
  EXPECT(CompilerTest::TestCompileScript(lib, script));
}


TEST_CASE(CompileFunction) {
  const char* kScriptChars =
            "class A {\n"
            "  static foo() { return 42; }\n"
            "  static moo() {\n"
            "    // A.foo();\n"
            "  }\n"
            "}\n";
  String& url = String::Handle(String::New("dart-test:CompileFunction"));
  String& source = String::Handle(String::New(kScriptChars));
  Script& script = Script::Handle(Script::New(url, source, RawScript::kSource));
  Library& lib = Library::Handle(Library::CoreLibrary());
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  EXPECT(ClassFinalizer::FinalizePendingClasses());
  Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(String::NewSymbol("A"))));
  EXPECT(!cls.IsNull());
  String& function_foo_name = String::Handle(String::New("foo"));
  Function& function_foo =
      Function::Handle(cls.LookupStaticFunction(function_foo_name));
  EXPECT(!function_foo.IsNull());

  EXPECT(CompilerTest::TestCompileFunction(function_foo));
  EXPECT(function_foo.HasCode());

  String& function_moo_name = String::Handle(String::New("moo"));
  Function& function_moo =
      Function::Handle(cls.LookupStaticFunction(function_moo_name));
  EXPECT(!function_moo.IsNull());

  EXPECT(CompilerTest::TestCompileFunction(function_moo));
  EXPECT(function_moo.HasCode());
}

#endif  // TARGET_ARCH_IA32 || TARGET_ARCH_X64

}  // namespace dart
