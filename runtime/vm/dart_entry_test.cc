// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assembler.h"
#include "vm/assert.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/object.h"
#include "vm/resolver.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(TARGET_ARCH_IA32)  // only ia32 can run execution tests.

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
  Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(String::NewSymbol("A"))));
  EXPECT(!cls.IsNull());
  String& name = String::Handle(String::New("foo"));
  Function& function = Function::Handle(cls.LookupStaticFunction(name));
  EXPECT(!function.IsNull());

  EXPECT(CompilerTest::TestCompileFunction(function));
  EXPECT(function.HasCode());
  GrowableArray<const Object*> arguments;
  const Smi& retval = Smi::Handle(
      reinterpret_cast<RawSmi*>(DartEntry::InvokeStatic(function, arguments)));
  EXPECT_EQ(Smi::New(42), retval.raw());
}

#endif  // TARGET_ARCH_IA32.

}  // namespace dart
