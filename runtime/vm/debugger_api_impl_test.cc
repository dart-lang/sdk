// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_debugger_api.h"

#include "vm/assert.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(TARGET_ARCH_IA32)  // Only ia32 can run execution tests.


static bool breakpoint_hit = false;

static const bool verbose = false;

#define EXPECT_NOT_ERROR(handle)                                              \
  if (Dart_IsError(handle)) {                                                 \
    OS::Print("Error: %s\n", Dart_GetError(handle));                          \
  }                                                                           \
  EXPECT(!Dart_IsError(handle));


void TestBreakpointHandler(Dart_Breakpoint bpt, Dart_StackTrace trace) {
  const char* expected_trace[] = {"A.foo", "main"};
  const intptr_t expected_trace_length = 2;
  breakpoint_hit = true;
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_NOT_ERROR(res);
  EXPECT_EQ(expected_trace_length, trace_len);
  for (int i = 0; i < trace_len; i++) {
    Dart_ActivationFrame frame;
    res = Dart_GetActivationFrame(trace, i, &frame);
    EXPECT_NOT_ERROR(res);
    Dart_Handle func_name;
    res = Dart_ActivationFrameInfo(frame, &func_name, NULL, NULL);
    EXPECT_NOT_ERROR(res);
    EXPECT(Dart_IsString(func_name));
    const char* name_chars;
    Dart_StringToCString(func_name, &name_chars);
    EXPECT_STREQ(expected_trace[i], name_chars);
    if (verbose) printf("  >> %d: %s\n", i, name_chars);
  }
}


UNIT_TEST_CASE(Breakpoint) {
  const char* kScriptChars =
      "void moo(s) { }\n"
      "class A {\n"
      "  static void foo() {\n"
      "    moo('good news');\n"
      "  }\n"
      "}\n"
      "void main() {\n"
      "  A.foo();\n"
      "}\n";

  TestIsolateScope __test_isolate__;

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT(!Dart_IsError(lib));

  Dart_SetBreakpointHandler(&TestBreakpointHandler);

  Dart_Handle c_name = Dart_NewString("A");
  Dart_Handle f_name = Dart_NewString("foo");
  Dart_Breakpoint bpt;
  Dart_Handle res = Dart_SetBreakpointAtEntry(lib, c_name, f_name, &bpt);
  EXPECT_NOT_ERROR(res);

  breakpoint_hit = false;
  Dart_Handle retval = Dart_InvokeStatic(lib,
                           Dart_NewString(""),
                           Dart_NewString("main"),
                           0,
                           NULL);
  EXPECT(!Dart_IsError(retval));
  EXPECT(breakpoint_hit == true);
}

#endif  // TARGET_ARCH_IA32.

}  // namespace dart
