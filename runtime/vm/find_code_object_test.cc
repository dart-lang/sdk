// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/object.h"
#include "vm/pages.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
static const int kScriptSize = 512 * KB;
static const int kLoopCount = 50000;
#elif defined(TARGET_ARCH_DBC)
static const int kScriptSize = 1 * MB;
static const int kLoopCount = 60000;
#else
static const int kScriptSize = 512 * KB;
static const int kLoopCount = 25000;
#endif
static char scriptChars[kScriptSize];

ISOLATE_UNIT_TEST_CASE(FindCodeObject) {
  const int kNumFunctions = 1024;

  // Get access to the code index table.
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);

  StackZone zone(thread);
  String& url = String::Handle(String::New("dart-test:FindCodeObject"));
  String& source = String::Handle();
  Script& script = Script::Handle();
  Library& lib = Library::Handle();
  Class& clsA = Class::Handle();
  Class& clsB = Class::Handle();
  String& function_name = String::Handle();
  Function& function = Function::Handle();
  char buffer[256];

  lib = Library::CoreLibrary();

  // Load up class A with 1024 functions.
  int written = OS::SNPrint(scriptChars, kScriptSize, "class A {");
  for (int i = 0; i < kNumFunctions; i++) {
    OS::SNPrint(buffer, 256,
                "static foo%d([int i=1,int j=2,int k=3]){return i+j+k;}", i);
    written += OS::SNPrint((scriptChars + written), (kScriptSize - written),
                           "%s", buffer);
  }
  OS::SNPrint((scriptChars + written), (kScriptSize - written), "}");
  source = String::New(scriptChars);
  script = Script::New(url, source, RawScript::kScriptTag);
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  clsA = lib.LookupClass(String::Handle(Symbols::New(thread, "A")));
  EXPECT(!clsA.IsNull());
  ClassFinalizer::ProcessPendingClasses();
  for (int i = 0; i < kNumFunctions; i++) {
    OS::SNPrint(buffer, 256, "foo%d", i);
    function_name = String::New(buffer);
    function = clsA.LookupStaticFunction(function_name);
    EXPECT(!function.IsNull());
    EXPECT(CompilerTest::TestCompileFunction(function));
    const Code& code = Code::ZoneHandle(function.CurrentCode());
    EXPECT(!code.IsNull())
    EXPECT(function.HasCode());
  }

  // Now load up class B with 1024 functions.
  written = OS::SNPrint(scriptChars, kScriptSize, "class B {");
  // Create one large function.
  OS::SNPrint(buffer, sizeof(buffer), "static moo0([var i=1]) { ");
  written += OS::SNPrint((scriptChars + written), (kScriptSize - written), "%s",
                         buffer);
  // Generate a large function so that the code for this function when
  // compiled will reside in a large page.
  for (int i = 0; i < kLoopCount; i++) {
    OS::SNPrint(buffer, sizeof(buffer), "i = i+i;");
    written += OS::SNPrint((scriptChars + written), (kScriptSize - written),
                           "%s", buffer);
  }
  OS::SNPrint(buffer, sizeof(buffer), "return i; }");
  written += OS::SNPrint((scriptChars + written), (kScriptSize - written), "%s",
                         buffer);
  for (int i = 1; i < kNumFunctions; i++) {
    OS::SNPrint(buffer, 256,
                "static moo%d([int i=1,int j=2,int k=3]){return i+j+k;}", i);
    written += OS::SNPrint((scriptChars + written), (kScriptSize - written),
                           "%s", buffer);
  }
  OS::SNPrint((scriptChars + written), (kScriptSize - written), "}");
  url = String::New("dart-test:FindCodeObject");
  source = String::New(scriptChars);
  script = Script::New(url, source, RawScript::kScriptTag);
  EXPECT(CompilerTest::TestCompileScript(lib, script));
  clsB = lib.LookupClass(String::Handle(Symbols::New(thread, "B")));
  EXPECT(!clsB.IsNull());
  ClassFinalizer::ProcessPendingClasses();
  for (int i = 0; i < kNumFunctions; i++) {
    OS::SNPrint(buffer, 256, "moo%d", i);
    function_name = String::New(buffer);
    function = clsB.LookupStaticFunction(function_name);
    EXPECT(!function.IsNull());
    EXPECT(CompilerTest::TestCompileFunction(function));
    const Code& code = Code::ZoneHandle(function.CurrentCode());
    EXPECT(!code.IsNull());
    EXPECT(function.HasCode());
  }

  // Now try and access these functions using the code index table.
  Code& code = Code::Handle();
  uword pc;
  OS::SNPrint(buffer, 256, "foo%d", 123);
  function_name = String::New(buffer);
  function = clsA.LookupStaticFunction(function_name);
  EXPECT(!function.IsNull());
  code = function.CurrentCode();
  EXPECT(code.Size() > 16);
  pc = code.PayloadStart() + 16;
  EXPECT(Code::LookupCode(pc) == code.raw());

  OS::SNPrint(buffer, 256, "moo%d", 54);
  function_name = String::New(buffer);
  function = clsB.LookupStaticFunction(function_name);
  EXPECT(!function.IsNull());
  code = function.CurrentCode();
  EXPECT(code.Size() > 16);
  pc = code.PayloadStart() + 16;
  EXPECT(Code::LookupCode(pc) == code.raw());

  // Lookup the large function
  OS::SNPrint(buffer, 256, "moo%d", 0);
  function_name = String::New(buffer);
  function = clsB.LookupStaticFunction(function_name);
  EXPECT(!function.IsNull());
  code = function.CurrentCode();
  EXPECT(code.Size() > 16);
  pc = code.PayloadStart() + 16;
  EXPECT(code.Size() > (PageSpace::kPageSizeInWords << kWordSizeLog2));
  EXPECT(Code::LookupCode(pc) == code.raw());
  EXPECT(code.Size() > (1 * MB));
  pc = code.PayloadStart() + (1 * MB);
  EXPECT(Code::LookupCode(pc) == code.raw());
}

}  // namespace dart
