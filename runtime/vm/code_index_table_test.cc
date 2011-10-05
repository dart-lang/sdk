// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_index_table.h"

#include "vm/assert.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(TARGET_ARCH_IA32)  // Compiler only implemented on IA32 now.

TEST_CASE(CodeIndexTable) {
  const int kScriptSize = 512 * KB;
  const int kNumFunctions = 1024;
  char scriptChars[kScriptSize];
  String& url = String::Handle(String::New("dart-test:CodeIndexTable"));
  String& source = String::Handle();
  Script& script = Script::Handle();
  Library& lib = Library::Handle();
  Class& clsA = Class::Handle();
  Class& clsB = Class::Handle();
  String& function_name = String::Handle();
  Function& function = Function::Handle();
  char buffer[256];

  // Get access to the code index table.
  ASSERT(Isolate::Current() != NULL);
  CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
  ASSERT(code_index_table != NULL);

  lib = Library::CoreLibrary();

  // Load up class A with 1024 functions.
  int written = OS::SNPrint(scriptChars, kScriptSize, "class A {");
  for (int i = 0; i < kNumFunctions; i++) {
    OS::SNPrint(buffer,
                256,
                "static foo%d(int i=1,int j=2,int k=3){return i+j+k;}", i);
    written += OS::SNPrint((scriptChars + written),
                           (kScriptSize - written),
                           "%s",
                           buffer);
  }
  OS::SNPrint((scriptChars + written), (kScriptSize - written), "}");
  source = String::New(scriptChars);
  script = Script::New(url, source, RawScript::kSource);
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  clsA = lib.LookupClass(String::Handle(String::NewSymbol("A")));
  EXPECT(!clsA.IsNull());
  ClassFinalizer::FinalizePendingClasses();
  for (int i = 0; i < kNumFunctions; i++) {
    OS::SNPrint(buffer, 256, "foo%d", i);
    function_name = String::New(buffer);
    function = clsA.LookupStaticFunction(function_name);
    EXPECT(!function.IsNull());
    EXPECT(CompilerTest::TestCompileFunction(function));
    EXPECT(function.HasCode());
  }

  // Now load up class B with 1024 functions.
  written = OS::SNPrint(scriptChars, kScriptSize, "class B {");
  // Create one large function.
  OS::SNPrint(buffer, sizeof(buffer), "static moo0(int i=1) { return ");
  written += OS::SNPrint((scriptChars + written),
                         (kScriptSize - written),
                         "%s",
                         buffer);
  // Currently this causes about 750KB of code to be allocated.  The
  // nesting level of binary operations is reduced from 50000 so this
  // test will pass on Windows. Larger nesting leads to stack overflow
  // in debug mode in the code generation visitor even when the stack
  // reserved size is set to 2MB.
  for (int i = 0; i < 35000; i++) {
    OS::SNPrint(buffer, sizeof(buffer), "i+");
    written += OS::SNPrint((scriptChars + written),
                           (kScriptSize - written),
                           "%s",
                           buffer);
  }
  OS::SNPrint(buffer, sizeof(buffer), "i; }");
  written += OS::SNPrint((scriptChars + written),
                         (kScriptSize - written),
                         "%s",
                         buffer);
  for (int i = 1; i < kNumFunctions; i++) {
    OS::SNPrint(buffer,
                256,
                "static moo%d(int i=1,int j=2,int k=3){return i+j+k;}", i);
    written += OS::SNPrint((scriptChars + written),
                           (kScriptSize - written),
                           "%s",
                           buffer);
  }
  OS::SNPrint((scriptChars + written), (kScriptSize - written), "}");
  url = String::New("dart-test:CodeIndexTable");
  source = String::New(scriptChars);
  script = Script::New(url, source, RawScript::kSource);
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  clsB = lib.LookupClass(String::Handle(String::NewSymbol("B")));
  EXPECT(!clsB.IsNull());
  ClassFinalizer::FinalizePendingClasses();
  for (int i = 0; i < kNumFunctions; i++) {
    OS::SNPrint(buffer, 256, "moo%d", i);
    function_name = String::New(buffer);
    function = clsB.LookupStaticFunction(function_name);
    EXPECT(!function.IsNull());
    EXPECT(CompilerTest::TestCompileFunction(function));
    EXPECT(function.HasCode());
  }

  // Now try and access these functions using the code index table.
  Code& code = Code::Handle();
  uword pc;
  OS::SNPrint(buffer, 256, "foo%d", 123);
  function_name = String::New(buffer);
  function = clsA.LookupStaticFunction(function_name);
  EXPECT(!function.IsNull());
  code = function.code();
  EXPECT(code.Size() > 16);
  pc = code.EntryPoint() + 16;
  EXPECT(code_index_table->LookupFunction(pc) == function.raw());
  EXPECT(code_index_table->LookupCode(pc) == code.raw());

  OS::SNPrint(buffer, 256, "moo%d", 54);
  function_name = String::New(buffer);
  function = clsB.LookupStaticFunction(function_name);
  EXPECT(!function.IsNull());
  code = function.code();
  EXPECT(code.Size() > 16);
  pc = code.EntryPoint() + 16;
  EXPECT(code_index_table->LookupFunction(pc) == function.raw());
  EXPECT(code_index_table->LookupCode(pc) == code.raw());

  // Lookup the large function
  OS::SNPrint(buffer, 256, "moo%d", 0);
  function_name = String::New(buffer);
  function = clsB.LookupStaticFunction(function_name);
  EXPECT(!function.IsNull());
  code = function.code();
  EXPECT(code.Size() > 16);
  pc = code.EntryPoint() + 16;
  EXPECT(code_index_table->LookupFunction(pc) == function.raw());
  EXPECT(code_index_table->LookupCode(pc) == code.raw());
  EXPECT(code.Size() > 750 * KB);
  pc = code.EntryPoint() + 750 * KB;
  EXPECT(code_index_table->LookupFunction(pc) == function.raw());
  EXPECT(code_index_table->LookupCode(pc) == code.raw());
}

#endif  // TARGET_ARCH_IA32

}  // namespace dart
