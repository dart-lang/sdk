// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debugger.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(Debugger_PrintBreakpointsToJSONArray) {
  const char* kScriptChars =
      "void main() {\n"
      "  print('won');\n"
      "  print('too');\n"
      "  print('free');\n"
      "  print('for');\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  Isolate* isolate = Isolate::Current();
  Debugger* debugger = isolate->debugger();
  const String& url = String::Handle(String::New(TestCase::url()));

  // Empty case.
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      debugger->PrintBreakpointsToJSONArray(&jsarr);
    }
    EXPECT_STREQ("[]", js.ToCString());
  }

  // Test with a couple of breakpoints.
  debugger->SetBreakpointAtLine(url, 2);
  debugger->SetBreakpointAtLine(url, 3);
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      debugger->PrintBreakpointsToJSONArray(&jsarr);
    }
    EXPECT_STREQ(
       "[{\"type\":\"Breakpoint\",\"id\":2,"
         "\"enabled\":true,\"resolved\":false,"
         "\"location\":{\"type\":\"Location\",\"libId\":12,"
                       "\"script\":\"dart:test-lib\",\"tokenPos\":12}},"
        "{\"type\":\"Breakpoint\",\"id\":1,"
         "\"enabled\":true,\"resolved\":false,"
         "\"location\":{\"type\":\"Location\",\"libId\":12,"
                       "\"script\":\"dart:test-lib\",\"tokenPos\":6}}]",
       js.ToCString());
  }
}

}  // namespace dart
