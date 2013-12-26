// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debugger.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(Debugger_PrintBreakpointsToJSONArray) {
  const char* kScriptChars =
      "main() {\n"
      "  var x = new StringBuffer();\n"
      "  x.add('won');\n"
      "  x.add('too');\n"
      "  return x.toString();\n"
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
         "\"location\":{\"type\":\"Location\","
                       "\"script\":\"dart:test-lib\",\"tokenPos\":14}},"
        "{\"type\":\"Breakpoint\",\"id\":1,"
         "\"enabled\":true,\"resolved\":false,"
         "\"location\":{\"type\":\"Location\","
                       "\"script\":\"dart:test-lib\",\"tokenPos\":5}}]",
       js.ToCString());
  }
}


static bool saw_paused_event = false;

static void InspectPausedEvent(Dart_IsolateId isolate_id,
                               intptr_t bp_id,
                               const Dart_CodeLocation& loc) {
  Isolate* isolate = Isolate::Current();
  Debugger* debugger = isolate->debugger();

  // The debugger knows that it is paused, and why.
  EXPECT(debugger->IsPaused());
  const Debugger::DebuggerEvent* event = debugger->PauseEvent();
  EXPECT(event != NULL);
  EXPECT(event->type == Debugger::kBreakpointReached);
  saw_paused_event = true;
}


TEST_CASE(Debugger_PauseEvent) {
  const char* kScriptChars =
      "main() {\n"
      "  var x = new StringBuffer();\n"
      "  x.write('won');\n"
      "  x.write('too');\n"
      "  return x.toString();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  Isolate* isolate = Isolate::Current();
  Debugger* debugger = isolate->debugger();
  const String& url = String::Handle(String::New(TestCase::url()));

  // No pause event.
  EXPECT(!debugger->IsPaused());
  EXPECT(debugger->PauseEvent() == NULL);

  saw_paused_event = false;
  Dart_SetPausedEventHandler(InspectPausedEvent);

  // Set a breakpoint and run.
  debugger->SetBreakpointAtLine(url, 2);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));

  // We ran the code in InspectPausedEvent.
  EXPECT(saw_paused_event);
}



}  // namespace dart
