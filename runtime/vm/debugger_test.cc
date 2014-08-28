// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_api_impl.h"
#include "vm/debugger.h"
#include "vm/unit_test.h"

namespace dart {

// Search for the formatted string in buffer.
//
// TODO(turnidge): This function obscures the line number of failing
// EXPECTs.  Rework this.
static void ExpectSubstringF(const char* buff, const char* fmt, ...) {
  Isolate* isolate = Isolate::Current();

  va_list args;
  va_start(args, fmt);
  intptr_t len = OS::VSNPrint(NULL, 0, fmt, args);
  va_end(args);

  char* buffer = isolate->current_zone()->Alloc<char>(len + 1);
  va_list args2;
  va_start(args2, fmt);
  OS::VSNPrint(buffer, (len + 1), fmt, args2);
  va_end(args2);

  EXPECT_SUBSTRING(buffer, buff);
}


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
  Library& vmlib = Library::Handle();
  vmlib ^= Api::UnwrapHandle(lib);
  EXPECT(!vmlib.IsNull());

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
    ExpectSubstringF(
        js.ToCString(),
        "[{\"type\":\"Breakpoint\",\"id\":\"debug\\/breakpoints\\/2\","
        "\"breakpointNumber\":2,\"enabled\":true,\"resolved\":false,"
        "\"location\":{\"type\":\"Location\","
        "\"script\":{\"type\":\"@Script\","
        "\"id\":\"libraries\\/%" Pd "\\/scripts\\/test-lib\","
        "\"name\":\"test-lib\","
        "\"kind\":\"script\"},\"tokenPos\":14}},"
        "{\"type\":\"Breakpoint\",\"id\":\"debug\\/breakpoints\\/1\","
        "\"breakpointNumber\":1,\"enabled\":true,\"resolved\":false,"
        "\"location\":{\"type\":\"Location\","
        "\"script\":{\"type\":\"@Script\","
        "\"id\":\"libraries\\/%" Pd "\\/scripts\\/test-lib\","
        "\"name\":\"test-lib\","
        "\"kind\":\"script\"},\"tokenPos\":5}}]",
        vmlib.index(), vmlib.index());
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
  const DebuggerEvent* event = debugger->PauseEvent();
  EXPECT(event != NULL);
  EXPECT(event->type() == DebuggerEvent::kBreakpointReached);
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
