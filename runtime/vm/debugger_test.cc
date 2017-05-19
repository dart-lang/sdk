// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/debugger.h"
#include "vm/message.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, background_compilation);
DECLARE_FLAG(bool, enable_inlining_annotations);
DECLARE_FLAG(bool, prune_dead_locals);
DECLARE_FLAG(bool, remove_script_timestamps_for_test);
DECLARE_FLAG(bool, trace_rewind);
DECLARE_FLAG(int, optimization_counter_threshold);

// Search for the formatted string in buffer.
//
// TODO(turnidge): This function obscures the line number of failing
// EXPECTs.  Rework this.
static void ExpectSubstringF(const char* buff, const char* fmt, ...) {
  va_list args;
  va_start(args, fmt);
  intptr_t len = OS::VSNPrint(NULL, 0, fmt, args);
  va_end(args);

  char* buffer = Thread::Current()->zone()->Alloc<char>(len + 1);
  va_list args2;
  va_start(args2, fmt);
  OS::VSNPrint(buffer, (len + 1), fmt, args2);
  va_end(args2);

  EXPECT_SUBSTRING(buffer, buff);
}

TEST_CASE(Debugger_GetBreakpointsById) {
  const char* kScriptChars =
      "main() {\n"
      "  var x = new StringBuffer();\n"
      "  x.add('won');\n"
      "  x.add('too');\n"
      "  return x.toString();\n"
      "}\n";
  SetFlagScope<bool> sfs(&FLAG_remove_script_timestamps_for_test, true);
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  Isolate* isolate = Isolate::Current();
  Debugger* debugger = isolate->debugger();

  // Test with one loaded breakpoint, one latent breakpoint.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle result = Dart_SetBreakpoint(url, 2);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t bp_id1 = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &bp_id1));

  result = Dart_SetBreakpoint(NewString("not_yet_loaded_script_uri"), 4);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t bp_id2 = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &bp_id2));

  EXPECT(debugger->GetBreakpointById(bp_id1) != NULL);
  EXPECT(debugger->GetBreakpointById(bp_id2) != NULL);
}

TEST_CASE(Debugger_RemoveBreakpoint) {
  const char* kScriptChars =
      "main() {\n"
      "  var x = new StringBuffer();\n"
      "  x.add('won');\n"
      "  x.add('too');\n"
      "  return x.toString();\n"
      "}\n";
  SetFlagScope<bool> sfs(&FLAG_remove_script_timestamps_for_test, true);
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  Isolate* isolate = Isolate::Current();
  Debugger* debugger = isolate->debugger();

  // Test with one loaded breakpoint, one latent breakpoint.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle result = Dart_SetBreakpoint(url, 2);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t bp_id1 = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &bp_id1));

  result = Dart_SetBreakpoint(NewString("not_yet_loaded_script_uri"), 4);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t bp_id2 = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &bp_id2));

  EXPECT(debugger->GetBreakpointById(bp_id1) != NULL);
  EXPECT(debugger->GetBreakpointById(bp_id2) != NULL);

  debugger->RemoveBreakpoint(bp_id1);
  debugger->RemoveBreakpoint(bp_id2);

  EXPECT(debugger->GetBreakpointById(bp_id1) == NULL);
  EXPECT(debugger->GetBreakpointById(bp_id2) == NULL);
}

TEST_CASE(Debugger_PrintBreakpointsToJSONArray) {
  const char* kScriptChars =
      "main() {\n"
      "  var x = new StringBuffer();\n"
      "  x.add('won');\n"
      "  x.add('too');\n"
      "  return x.toString();\n"
      "}\n";
  SetFlagScope<bool> sfs(&FLAG_remove_script_timestamps_for_test, true);
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);
  Library& vmlib = Library::Handle();
  vmlib ^= Api::UnwrapHandle(lib);
  EXPECT(!vmlib.IsNull());
  const String& private_key = String::Handle(vmlib.private_key());

  Isolate* isolate = Isolate::Current();
  Debugger* debugger = isolate->debugger();

  // Empty case.
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      debugger->PrintBreakpointsToJSONArray(&jsarr);
    }
    EXPECT_STREQ("[]", js.ToCString());
  }

  // Test with a couple of loaded breakpoints, one latent breakpoint.
  Dart_Handle url = NewString(TestCase::url());
  EXPECT_VALID(Dart_SetBreakpoint(url, 2));
  EXPECT_VALID(Dart_SetBreakpoint(url, 3));
  EXPECT_VALID(Dart_SetBreakpoint(NewString("not_yet_loaded_script_uri"), 4));
  {
    JSONStream js;
    {
      JSONArray jsarr(&js);
      debugger->PrintBreakpointsToJSONArray(&jsarr);
    }
    ExpectSubstringF(
        js.ToCString(),
        "[{\"type\":\"Breakpoint\",\"fixedId\":true,\"id\":\"breakpoints\\/"
        "2\",\"breakpointNumber\":2,\"resolved\":false,\"location\":{\"type\":"
        "\"UnresolvedSourceLocation\",\"script\":{\"type\":\"@Script\","
        "\"fixedId\":true,\"id\":\"libraries\\/%s\\/scripts\\/"
        "test-lib\\/"
        "0\",\"uri\":\"test-lib\",\"_kind\":\"script\"},\"line\":3}},{\"type\":"
        "\"Breakpoint\",\"fixedId\":true,\"id\":\"breakpoints\\/"
        "1\",\"breakpointNumber\":1,\"resolved\":false,\"location\":{\"type\":"
        "\"UnresolvedSourceLocation\",\"script\":{\"type\":\"@Script\","
        "\"fixedId\":true,\"id\":\"libraries\\/%s\\/scripts\\/"
        "test-lib\\/"
        "0\",\"uri\":\"test-lib\",\"_kind\":\"script\"},\"line\":2}},{\"type\":"
        "\"Breakpoint\",\"fixedId\":true,\"id\":\"breakpoints\\/"
        "3\",\"breakpointNumber\":3,\"resolved\":false,\"location\":{\"type\":"
        "\"UnresolvedSourceLocation\",\"scriptUri\":\"not_yet_loaded_script_"
        "uri\",\"line\":4}}]",
        private_key.ToCString(), private_key.ToCString());
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
  const ServiceEvent* event = debugger->PauseEvent();
  EXPECT(event != NULL);
  EXPECT(event->kind() == ServiceEvent::kPauseBreakpoint);
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

  // No pause event.
  EXPECT(!debugger->IsPaused());
  EXPECT(debugger->PauseEvent() == NULL);

  saw_paused_event = false;
  Dart_SetPausedEventHandler(InspectPausedEvent);

  // Set a breakpoint and run.
  EXPECT_VALID(Dart_SetBreakpoint(NewString(TestCase::url()), 2));
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));

  // We ran the code in InspectPausedEvent.
  EXPECT(saw_paused_event);
}


static uint8_t* malloc_allocator(uint8_t* ptr,
                                 intptr_t old_size,
                                 intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


const char* rewind_frame_index = "-1";


// Build and send a fake resume OOB message for testing purposes.
void SendResumeMessage(Isolate* isolate) {
  // Format is: [ oob_type, port, seq, method_name, [keys], [values] ]
  Dart_CObject msg;
  Dart_CObject* list_values[6];
  msg.type = Dart_CObject_kArray;
  msg.value.as_array.length = 6;
  msg.value.as_array.values = list_values;

  Dart_CObject oob;
  oob.type = Dart_CObject_kInt32;
  oob.value.as_int32 = Message::kServiceOOBMsg;
  list_values[0] = &oob;

  Dart_CObject reply_port;
  reply_port.type = Dart_CObject_kNull;
  list_values[1] = &reply_port;

  Dart_CObject seq;
  seq.type = Dart_CObject_kNull;
  list_values[2] = &seq;

  Dart_CObject method_name;
  method_name.type = Dart_CObject_kString;
  method_name.value.as_string = const_cast<char*>("resume");
  list_values[3] = &method_name;

  const int kParamCount = 3;
  Dart_CObject param_keys;
  Dart_CObject* param_keys_list[kParamCount];
  param_keys.type = Dart_CObject_kArray;
  param_keys.value.as_array.values = param_keys_list;
  param_keys.value.as_array.length = kParamCount;
  list_values[4] = &param_keys;

  Dart_CObject param_values;
  Dart_CObject* param_values_list[kParamCount];
  param_values.type = Dart_CObject_kArray;
  param_values.value.as_array.values = param_values_list;
  param_values.value.as_array.length = kParamCount;
  list_values[5] = &param_values;

  Dart_CObject param0_name;
  param0_name.type = Dart_CObject_kString;
  param0_name.value.as_string = const_cast<char*>("isolateId");
  param_keys_list[0] = &param0_name;

  Dart_CObject param0_value;
  param0_value.type = Dart_CObject_kString;
  const char* isolate_id = Thread::Current()->zone()->PrintToString(
      ISOLATE_SERVICE_ID_FORMAT_STRING,
      static_cast<int64_t>(isolate->main_port()));
  param0_value.value.as_string = const_cast<char*>(isolate_id);
  param_values_list[0] = &param0_value;

  Dart_CObject param1_name;
  param1_name.type = Dart_CObject_kString;
  param1_name.value.as_string = const_cast<char*>("step");
  param_keys_list[1] = &param1_name;

  Dart_CObject param1_value;
  param1_value.type = Dart_CObject_kString;
  param1_value.value.as_string = const_cast<char*>("Rewind");
  param_values_list[1] = &param1_value;

  Dart_CObject param2_name;
  param2_name.type = Dart_CObject_kString;
  param2_name.value.as_string = const_cast<char*>("frameIndex");
  param_keys_list[2] = &param2_name;

  Dart_CObject param2_value;
  param2_value.type = Dart_CObject_kString;
  param2_value.value.as_string = const_cast<char*>(rewind_frame_index);
  param_values_list[2] = &param2_value;

  {
    uint8_t* buffer = NULL;
    ApiMessageWriter writer(&buffer, &malloc_allocator);
    bool success = writer.WriteCMessage(&msg);
    ASSERT(success);

    // Post the message at the given port.
    success = PortMap::PostMessage(new Message(isolate->main_port(), buffer,
                                               writer.BytesWritten(),
                                               Message::kOOBPriority));
    ASSERT(success);
  }
}


static void RewindOnce(Dart_IsolateId isolate_id,
                       intptr_t bp_id,
                       const Dart_CodeLocation& loc) {
  bool first_time = !saw_paused_event;
  saw_paused_event = true;
  if (first_time) {
    Thread* T = Thread::Current();
    Isolate* I = T->isolate();
    // TODO(turnidge): It is weird that the isolate can get to this
    // point in our tests without being marked runnable. Clear this up
    // at some point.
    I->set_is_runnable(true);
    SendResumeMessage(I);
    I->PauseEventHandler();
  }
}


TEST_CASE(Debugger_RewindOneFrame_Unoptimized) {
  SetFlagScope<bool> sfs(&FLAG_trace_rewind, true);

  // These variables are global state used by RewindOnce.
  saw_paused_event = false;
  rewind_frame_index = "1";

  const char* kScriptChars =
      "import 'dart:developer';\n"
      "\n"
      "var msg = new StringBuffer();\n"
      "\n"
      "foo() {\n"
      "  msg.write('enter(foo) ');\n"
      "  debugger();\n"
      "  msg.write('exit(foo) ');\n"
      "}\n"
      "\n"
      "main() {\n"
      "  msg.write('enter(main) ');\n"
      "  foo();\n"
      "  msg.write('exit(main) ');\n"
      "  return msg.toString();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  Dart_SetPausedEventHandler(RewindOnce);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  const char* result_cstr;
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));
  EXPECT_VALID(Dart_StringToCString(result, &result_cstr));
  EXPECT_STREQ("enter(main) enter(foo) enter(foo) exit(foo) exit(main) ",
               result_cstr);
  EXPECT(saw_paused_event);
}


TEST_CASE(Debugger_RewindTwoFrames_Unoptimized) {
  SetFlagScope<bool> sfs(&FLAG_trace_rewind, true);

  // These variables are global state used by RewindOnce.
  saw_paused_event = false;
  rewind_frame_index = "2";

  const char* kScriptChars =
      "import 'dart:developer';\n"
      "\n"
      "var msg = new StringBuffer();\n"
      "\n"
      "foo() {\n"
      "  msg.write('enter(foo) ');\n"
      "  debugger();\n"
      "  msg.write('exit(foo) ');\n"
      "}\n"
      "\n"
      "bar() {\n"
      "  msg.write('enter(bar) ');\n"
      "  foo();\n"
      "  msg.write('exit(bar) ');\n"
      "}\n"
      "\n"
      "main() {\n"
      "  msg.write('enter(main) ');\n"
      "  bar();\n"
      "  msg.write('exit(main) ');\n"
      "  return msg.toString();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  Dart_SetPausedEventHandler(RewindOnce);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  const char* result_cstr;
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));
  EXPECT_VALID(Dart_StringToCString(result, &result_cstr));
  EXPECT_STREQ(
      "enter(main) enter(bar) enter(foo) enter(bar) enter(foo) "
      "exit(foo) exit(bar) exit(main) ",
      result_cstr);
  EXPECT(saw_paused_event);
}


TEST_CASE(Debugger_Rewind_Optimized) {
  SetFlagScope<bool> sfs1(&FLAG_trace_rewind, true);
  SetFlagScope<bool> sfs2(&FLAG_prune_dead_locals, false);
  SetFlagScope<bool> sfs3(&FLAG_enable_inlining_annotations, true);
  SetFlagScope<bool> sfs4(&FLAG_background_compilation, false);
  SetFlagScope<int> sfs5(&FLAG_optimization_counter_threshold, 10);

  // These variables are global state used by RewindOnce.
  saw_paused_event = false;
  rewind_frame_index = "2";

  const char* kScriptChars =
      "import 'dart:developer';\n"
      "\n"
      "const alwaysInline = \"AlwaysInline\";\n"
      "const noInline = \"NeverInline\";\n"
      "\n"
      "var msg = new StringBuffer();\n"
      "int i;\n"
      "\n"
      "@noInline\n"
      "foo() {\n"
      "  msg.write('enter(foo) ');\n"
      "  if (i > 15) {\n"
      "    debugger();\n"
      "    msg.write('exit(foo) ');\n"
      "    return true;\n"
      "  } else {\n"
      "    msg.write('exit(foo) ');\n"
      "    return false;\n"
      "  }\n"
      "}\n"
      "\n"
      "@alwaysInline\n"
      "bar3() {\n"
      "  msg.write('enter(bar3) ');\n"
      "  var result = foo();\n"
      "  msg.write('exit(bar3) ');\n"
      "  return result;\n"
      "}\n"
      "\n"
      "@alwaysInline\n"
      "bar2() {\n"
      "  msg.write('enter(bar2) ');\n"
      "  var result = bar3();\n"
      "  msg.write('exit(bar2) ');\n"
      "  return result;\n"
      "}\n"
      "\n"
      "@alwaysInline\n"
      "bar1() {\n"
      "  msg.write('enter(bar1) ');\n"
      "  var result = bar2();\n"
      "  msg.write('exit(bar1) ');\n"
      "  return result;\n"
      "}\n"
      "\n"
      "main() {\n"
      "  for (i = 0; i < 20; i++) {\n"
      "    msg.clear();\n"
      "    if (bar1()) break;\n;"
      "  }\n"
      "  return msg.toString();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT_VALID(lib);

  Dart_SetPausedEventHandler(RewindOnce);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  const char* result_cstr;
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));
  EXPECT_VALID(Dart_StringToCString(result, &result_cstr));
  EXPECT_STREQ(
      "enter(bar1) enter(bar2) enter(bar3) enter(foo) "
      "enter(bar3) enter(foo) "
      "exit(foo) exit(bar3) exit(bar2) exit(bar1) ",
      result_cstr);
  EXPECT(saw_paused_event);
}

#endif  // !PRODUCT

}  // namespace dart
