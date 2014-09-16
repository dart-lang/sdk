// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_debugger_api.h"
#include "include/dart_mirrors_api.h"
#include "platform/assert.h"
#include "vm/dart_api_impl.h"
#include "vm/lockers.h"
#include "vm/unit_test.h"

namespace dart {

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, use_osr);

static bool breakpoint_hit = false;
static int  breakpoint_hit_counter = 0;
static Dart_Handle script_lib = NULL;

static const bool verbose = true;

static void LoadScript(const char* source) {
  script_lib = TestCase::LoadTestScript(source, NULL);
  EXPECT_VALID(script_lib);
}


static void SetBreakpointAtEntry(const char* cname, const char* fname) {
  ASSERT(script_lib != NULL);
  ASSERT(!Dart_IsError(script_lib));
  ASSERT(Dart_IsLibrary(script_lib));
  Dart_Handle res = Dart_SetBreakpointAtEntry(script_lib,
                        NewString(cname),
                        NewString(fname));
  EXPECT(Dart_IsInteger(res));
}


static Dart_Handle Invoke(const char* func_name) {
  ASSERT(script_lib != NULL);
  ASSERT(!Dart_IsError(script_lib));
  ASSERT(Dart_IsLibrary(script_lib));
  return Dart_Invoke(script_lib, NewString(func_name), 0, NULL);
}


static char const* ToCString(Dart_Handle str) {
  EXPECT(Dart_IsString(str));
  char const* c_str = NULL;
  Dart_StringToCString(str, &c_str);
  return c_str;
}


static int64_t ToInt64(Dart_Handle h) {
  EXPECT(Dart_IsInteger(h));
  int64_t i = 0;
  Dart_Handle res = Dart_IntegerToInt64(h, &i);
  EXPECT_VALID(res);
  return i;
}


static double ToDouble(Dart_Handle h) {
  EXPECT(Dart_IsDouble(h));
  double d = 0.0;
  Dart_Handle res = Dart_DoubleValue(h, &d);
  EXPECT_VALID(res);
  return d;
}


static char const* BreakpointInfo(Dart_StackTrace trace) {
  static char info_str[128];
  Dart_ActivationFrame frame;
  Dart_Handle res = Dart_GetActivationFrame(trace, 0, &frame);
  EXPECT_TRUE(res);
  Dart_Handle func_name;
  Dart_Handle url;
  intptr_t line_number = 0;
  intptr_t library_id = 0;
  res = Dart_ActivationFrameInfo(
            frame, &func_name, &url, &line_number, &library_id);
  EXPECT_TRUE(res);
  OS::SNPrint(info_str, sizeof(info_str), "function %s (%s:%" Pd ")",
              ToCString(func_name), ToCString(url), line_number);
  return info_str;
}


static void PrintValue(Dart_Handle value, bool expand);


static void PrintObjectList(Dart_Handle list, const char* prefix, bool expand) {
  intptr_t list_length = 0;
  Dart_Handle retval = Dart_ListLength(list, &list_length);
  EXPECT_VALID(retval);
  for (int i = 0; i + 1 < list_length; i += 2) {
    Dart_Handle name_handle = Dart_ListGetAt(list, i);
    EXPECT_VALID(name_handle);
    EXPECT(Dart_IsString(name_handle));
    Dart_Handle value_handle = Dart_ListGetAt(list, i + 1);
    OS::Print("\n        %s %s = ", prefix, ToCString(name_handle));
    PrintValue(value_handle, expand);
  }
}


static void PrintObject(Dart_Handle obj, bool expand) {
  Dart_Handle obj_class = Dart_GetObjClass(obj);
  EXPECT_VALID(obj_class);
  EXPECT(!Dart_IsNull(obj_class));
  Dart_Handle class_name = Dart_ToString(obj_class);
  EXPECT_VALID(class_name);
  EXPECT(Dart_IsString(class_name));
  char const* class_name_str;
  Dart_StringToCString(class_name, &class_name_str);
  Dart_Handle fields = Dart_GetInstanceFields(obj);
  EXPECT_VALID(fields);
  EXPECT(Dart_IsList(fields));
  OS::Print("object of type '%s'", class_name_str);
  PrintObjectList(fields, "field", false);
  Dart_Handle statics = Dart_GetStaticFields(obj_class);
  EXPECT_VALID(obj_class);
  PrintObjectList(statics, "static field", false);
}


static void PrintValue(Dart_Handle value, bool expand) {
  if (Dart_IsNull(value)) {
    OS::Print("null");
  } else if (Dart_IsString(value)) {
    Dart_Handle str_value = Dart_ToString(value);
    EXPECT_VALID(str_value);
    EXPECT(Dart_IsString(str_value));
    OS::Print("\"%s\"", ToCString(str_value));
  } else if (Dart_IsNumber(value) || Dart_IsBoolean(value)) {
    Dart_Handle str_value = Dart_ToString(value);
    EXPECT_VALID(str_value);
    EXPECT(Dart_IsString(str_value));
    OS::Print("%s", ToCString(str_value));
  } else {
    PrintObject(value, expand);
  }
}


static void PrintActivationFrame(Dart_ActivationFrame frame) {
  Dart_Handle func_name;
  Dart_Handle res;
  res = Dart_ActivationFrameInfo(frame, &func_name, NULL, NULL, NULL);
  EXPECT_TRUE(res);
  EXPECT(Dart_IsString(func_name));
  const char* func_name_chars;
  Dart_StringToCString(func_name, &func_name_chars);
  OS::Print("    function %s\n", func_name_chars);
  Dart_Handle locals = Dart_GetLocalVariables(frame);
  EXPECT_VALID(locals);
  intptr_t list_length = 0;
  Dart_Handle ret = Dart_ListLength(locals, &list_length);
  EXPECT_VALID(ret);
  for (int i = 0; i + 1 < list_length; i += 2) {
    Dart_Handle name_handle = Dart_ListGetAt(locals, i);
    EXPECT_VALID(name_handle);
    EXPECT(Dart_IsString(name_handle));
    OS::Print("      local var %s = ", ToCString(name_handle));
    Dart_Handle value_handle = Dart_ListGetAt(locals, i + 1);
    EXPECT_VALID(value_handle);
    PrintValue(value_handle, true);
    OS::Print("\n");
  }
}


static Dart_Handle GetLocalVariable(Dart_ActivationFrame frame,
                                    const char* name) {
  Dart_Handle locals = Dart_GetLocalVariables(frame);
  EXPECT_VALID(locals);
  intptr_t list_length = 0;
  Dart_Handle ret = Dart_ListLength(locals, &list_length);
  EXPECT_VALID(ret);
  for (int i = 0; i + 1 < list_length; i += 2) {
    Dart_Handle name_handle = Dart_ListGetAt(locals, i);
    EXPECT_VALID(name_handle);
    EXPECT(Dart_IsString(name_handle));
    if (strcmp(ToCString(name_handle), name) == 0) {
      Dart_Handle value_handle = Dart_ListGetAt(locals, i + 1);
      EXPECT_VALID(value_handle);
      return value_handle;
    }
  }
  FAIL("local variable not found");
  return Dart_Null();
}


static void PrintStackTrace(Dart_StackTrace trace) {
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_TRUE(res);
  for (int i = 0; i < trace_len; i++) {
    Dart_ActivationFrame frame;
    res = Dart_GetActivationFrame(trace, i, &frame);
    EXPECT_TRUE(res);
    PrintActivationFrame(frame);
  }
}


static void VerifyListEquals(Dart_Handle expected,
                             Dart_Handle got,
                             bool skip_null_expects) {
  EXPECT(Dart_IsList(expected));
  EXPECT(Dart_IsList(got));
  Dart_Handle res;
  intptr_t expected_length;
  res = Dart_ListLength(expected, &expected_length);
  EXPECT_VALID(res);
  intptr_t got_length;
  res = Dart_ListLength(expected, &got_length);
  EXPECT_VALID(res);
  EXPECT_EQ(expected_length, got_length);
  for (intptr_t i = 0; i < expected_length; i++) {
    Dart_Handle expected_elem = Dart_ListGetAt(expected, i);
    EXPECT_VALID(expected_elem);
    Dart_Handle got_elem = Dart_ListGetAt(got, i);
    EXPECT_VALID(got_elem);
    bool equals;
    res = Dart_ObjectEquals(expected_elem, got_elem, &equals);
    EXPECT_VALID(res);
    EXPECT(equals || (Dart_IsNull(expected_elem) && skip_null_expects));
  }
}


static void VerifyStackFrame(Dart_ActivationFrame frame,
                             const char* expected_name,
                             Dart_Handle expected_locals,
                             bool skip_null_expects) {
  Dart_Handle func_name;
  Dart_Handle func;
  Dart_Handle res;
  res = Dart_ActivationFrameGetLocation(frame, &func_name, &func, NULL);
  EXPECT_TRUE(res);
  EXPECT(Dart_IsString(func_name));
  const char* func_name_chars;
  Dart_StringToCString(func_name, &func_name_chars);
  if (expected_name != NULL) {
    EXPECT_SUBSTRING(expected_name, func_name_chars);
  }
  EXPECT(Dart_IsFunction(func));
  const char* func_name_chars_from_func_handle;
  Dart_StringToCString(Dart_FunctionName(func),
                       &func_name_chars_from_func_handle);
  EXPECT_STREQ(func_name_chars, func_name_chars_from_func_handle);

  if (!Dart_IsNull(expected_locals)) {
    Dart_Handle locals = Dart_GetLocalVariables(frame);
    EXPECT_VALID(locals);
    VerifyListEquals(expected_locals, locals, skip_null_expects);
  }
}


static void VerifyStackTrace(Dart_StackTrace trace,
                             const char* func_names[],
                             Dart_Handle local_vars[],
                             int expected_frames,
                             bool skip_null_expects) {
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_TRUE(res);
  uintptr_t last_frame_pointer = 0;
  uintptr_t frame_pointer;
  for (int i = 0; i < trace_len; i++) {
    Dart_ActivationFrame frame;
    res = Dart_GetActivationFrame(trace, i, &frame);
    EXPECT_TRUE(res);

    res = Dart_ActivationFrameGetFramePointer(frame, &frame_pointer);
    EXPECT_TRUE(res);
    if (i > 0) {
      // We expect the stack to grow from high to low addresses.
      EXPECT_GT(frame_pointer, last_frame_pointer);
    }
    last_frame_pointer = frame_pointer;
    if (i < expected_frames) {
      VerifyStackFrame(frame, func_names[i], local_vars[i], skip_null_expects);
    } else {
      VerifyStackFrame(frame, NULL, Dart_Null(), skip_null_expects);
    }
  }
}


// TODO(hausner): Convert this one remaining use of the legacy
// breakpoint handler once Dart_SetBreakpointHandler goes away.
void TestBreakpointHandler(Dart_IsolateId isolate_id,
                           Dart_Breakpoint bpt,
                           Dart_StackTrace trace) {
  const char* expected_trace[] = {"A.foo", "main"};
  const intptr_t expected_trace_length = 2;
  breakpoint_hit = true;
  breakpoint_hit_counter++;
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_VALID(res);
  EXPECT_EQ(expected_trace_length, trace_len);
  for (int i = 0; i < trace_len; i++) {
    Dart_ActivationFrame frame;
    res = Dart_GetActivationFrame(trace, i, &frame);
    EXPECT_VALID(res);
    Dart_Handle func_name;
    res = Dart_ActivationFrameInfo(frame, &func_name, NULL, NULL, NULL);
    EXPECT_VALID(res);
    EXPECT(Dart_IsString(func_name));
    const char* name_chars;
    Dart_StringToCString(func_name, &name_chars);
    EXPECT_STREQ(expected_trace[i], name_chars);
    if (verbose) OS::Print("  >> %d: %s\n", i, name_chars);
  }
}


TEST_CASE(Debug_Breakpoint) {
  const char* kScriptChars =
      "void moo(s) { }        \n"
      "class A {              \n"
      "  static void foo() {  \n"
      "    moo('good news');  \n"
      "  }                    \n"
      "}                      \n"
      "void main() {          \n"
      "  A.foo();             \n"
      "}                      \n";

  LoadScript(kScriptChars);
  Dart_SetBreakpointHandler(&TestBreakpointHandler);
  SetBreakpointAtEntry("A", "foo");

  breakpoint_hit = false;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT(breakpoint_hit == true);
}

static const int stack_buffer_size = 1024;
static char stack_buffer[stack_buffer_size];

static void SaveStackTrace(Dart_StackTrace trace) {
  Dart_ActivationFrame frame;
  Dart_Handle func_name;

  char* buffer = stack_buffer;
  int buffer_size = stack_buffer_size;

  intptr_t trace_len;
  EXPECT_VALID(Dart_StackTraceLength(trace, &trace_len));

  for (intptr_t frame_index = 0; frame_index < trace_len; frame_index++) {
    EXPECT_VALID(Dart_GetActivationFrame(trace, frame_index, &frame));
    EXPECT_VALID(Dart_ActivationFrameInfo(frame, &func_name,
                                          NULL, NULL, NULL));
    int pos = OS::SNPrint(buffer, buffer_size, "[%" Pd "] %s { ",
                          frame_index, ToCString(func_name));
    buffer += pos;
    buffer_size -= pos;

    Dart_Handle locals = Dart_GetLocalVariables(frame);
    EXPECT_VALID(locals);
    intptr_t list_length = 0;
    EXPECT_VALID(Dart_ListLength(locals, &list_length));

    for (intptr_t i = 0; i + 1 < list_length; i += 2) {
      Dart_Handle name = Dart_ListGetAt(locals, i);
      EXPECT_VALID(name);
      EXPECT(Dart_IsString(name));

      Dart_Handle value = Dart_ListGetAt(locals, i + 1);
      EXPECT_VALID(value);
      Dart_Handle value_str = Dart_ToString(value);
      EXPECT_VALID(value_str);

      const char* name_cstr = NULL;
      const char* value_cstr = NULL;
      EXPECT_VALID(Dart_StringToCString(name, &name_cstr));
      EXPECT_VALID(Dart_StringToCString(value_str, &value_cstr));
      pos = OS::SNPrint(buffer, buffer_size, "%s = %s ",
                        name_cstr, value_cstr);
      buffer += pos;
      buffer_size -= pos;
    }
    pos = OS::SNPrint(buffer, buffer_size, "}\n");
    buffer += pos;
    buffer_size -= pos;
  }
}


static void InspectOptimizedStack_Breakpoint(Dart_IsolateId isolate_id,
                                             intptr_t bp_id,
                                             const Dart_CodeLocation& loc) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  SaveStackTrace(trace);
}


static void InspectStackTest(bool optimize) {
  const char* kScriptChars =
      "void breakpointNow() {\n"
      "}\n"
      "int helper(int a, int b, bool stop) {\n"
      "  if (b == 99 && stop) {\n"
      "    breakpointNow();\n"
      "  }\n"
      "  int c = a*b;\n"
      "  return c;\n"
      "}\n"
      "int anotherMiddleMan(int one, int two, bool stop) {\n"
      "  return helper(one, two, stop);\n"
      "}\n"
      "int middleMan(int x, int limit, bool stop) {\n"
      "  int value = 0;\n"
      "  for (int i = 0; i < limit; i++) {\n"
      "    value += anotherMiddleMan(x, i, stop);\n"
      "  }\n"
      "  return value;\n"
      "}\n"
      "int test(bool stop, int limit) {\n"
      "  return middleMan(5, limit, stop);\n"
      "}\n";

  LoadScript(kScriptChars);

  // Save/restore some compiler flags.
  Dart_Handle dart_args[2];
  int saved_threshold = FLAG_optimization_counter_threshold;
  const int kLowThreshold = 100;
  const int kHighThreshold = 10000;
  bool saved_osr = FLAG_use_osr;
  FLAG_use_osr = false;

  if (optimize) {
    // Warm up the code to make sure it gets optimized.  We ignore any
    // breakpoints that get hit during warm-up.
    FLAG_optimization_counter_threshold = kLowThreshold;
    dart_args[0] = Dart_False();
    dart_args[1] = Dart_NewInteger(kLowThreshold);
    EXPECT_VALID(Dart_Invoke(script_lib, NewString("test"), 2, dart_args));
  } else {
    // Try to ensure that none of the test code gets optimized.
    FLAG_optimization_counter_threshold = kHighThreshold;
  }

  // Set up the breakpoint.
  Dart_SetPausedEventHandler(InspectOptimizedStack_Breakpoint);
  SetBreakpointAtEntry("", "breakpointNow");

  // Run the code and inspect the stack.
  stack_buffer[0] = '\0';
  dart_args[0] = Dart_True();
  dart_args[1] = Dart_NewInteger(kLowThreshold);
  EXPECT_VALID(Dart_Invoke(script_lib, NewString("test"), 2, dart_args));
  if (optimize) {
    EXPECT_STREQ("[0] breakpointNow { }\n"
                 "[1] helper { a = 5 b = 99 stop = <optimized out> }\n"
                 "[2] anotherMiddleMan { one = <optimized out> "
                 "two = <optimized out> stop = <optimized out> }\n"
                 "[3] middleMan { x = 5 limit = 100 stop = true value = 24255"
                 " i = 99 }\n"
                 "[4] test { stop = true limit = 100 }\n",
                 stack_buffer);
  } else {
    EXPECT_STREQ("[0] breakpointNow { }\n"
                 "[1] helper { a = 5 b = 99 stop = true }\n"
                 "[2] anotherMiddleMan { one = 5 two = 99 stop = true }\n"
                 "[3] middleMan { x = 5 limit = 100 stop = true value = 24255"
                 " i = 99 }\n"
                 "[4] test { stop = true limit = 100 }\n",
                 stack_buffer);
  }

  FLAG_optimization_counter_threshold = saved_threshold;
  FLAG_use_osr = saved_osr;
}


TEST_CASE(Debug_InspectStack_NotOptimized) {
  InspectStackTest(false);
}


TEST_CASE(Debug_InspectStack_Optimized) {
  InspectStackTest(true);
}


static void InspectStackWithClosureTest(bool optimize) {
  const char* kScriptChars =
      "void breakpointNow() {\n"
      "}\n"
      "int helper(int a, int b, bool stop) {\n"
      "  if (b == 99 && stop) {\n"
      "    breakpointNow();\n"
      "  }\n"
      "  int c = a*b;\n"
      "  return c;\n"
      "}\n"
      "int anotherMiddleMan(func) {\n"
      "  return func(10);\n"
      "}\n"
      "int middleMan(int x, int limit, bool stop) {\n"
      "  int value = 0;\n"
      "  for (int i = 0; i < limit; i++) {\n"
      "    value += anotherMiddleMan((value) {\n"
      "      return helper((x * value), i, stop);\n"
      "    });\n"
      "  }\n"
      "  return value;\n"
      "}\n"
      "int test(bool stop, int limit) {\n"
      "  return middleMan(5, limit, stop);\n"
      "}\n";

  LoadScript(kScriptChars);

  // Save/restore some compiler flags.
  Dart_Handle dart_args[2];
  int saved_threshold = FLAG_optimization_counter_threshold;
  const int kLowThreshold = 100;
  const int kHighThreshold = 10000;
  bool saved_osr = FLAG_use_osr;
  FLAG_use_osr = false;

  if (optimize) {
    // Warm up the code to make sure it gets optimized.  We ignore any
    // breakpoints that get hit during warm-up.
    FLAG_optimization_counter_threshold = kLowThreshold;
    dart_args[0] = Dart_False();
    dart_args[1] = Dart_NewInteger(kLowThreshold);
    EXPECT_VALID(Dart_Invoke(script_lib, NewString("test"), 2, dart_args));
  } else {
    // Try to ensure that none of the test code gets optimized.
    FLAG_optimization_counter_threshold = kHighThreshold;
  }

  // Set up the breakpoint.
  Dart_SetPausedEventHandler(InspectOptimizedStack_Breakpoint);
  SetBreakpointAtEntry("", "breakpointNow");

  // Run the code and inspect the stack.
  stack_buffer[0] = '\0';
  dart_args[0] = Dart_True();
  dart_args[1] = Dart_NewInteger(kLowThreshold);
  EXPECT_VALID(Dart_Invoke(script_lib, NewString("test"), 2, dart_args));
  if (optimize) {
    EXPECT_STREQ("[0] breakpointNow { }\n"
                 "[1] helper { a = 50 b = 99 stop = <optimized out> }\n"
                 "[2] <anonymous closure> { x = 5 i = 99 stop = true"
                 " value = <optimized out> }\n"
                 "[3] anotherMiddleMan { func = <optimized out> }\n"
                 "[4] middleMan { x = 5 limit = 100 stop = true"
                 " value = 242550 i = 99 }\n"
                 "[5] test { stop = true limit = 100 }\n",
                 stack_buffer);
  } else {
    EXPECT_STREQ("[0] breakpointNow { }\n"
                 "[1] helper { a = 50 b = 99 stop = true }\n"
                 "[2] <anonymous closure> { x = 5 i = 99 stop = true"
                 " value = 10 }\n"
                 "[3] anotherMiddleMan {"
                 " func = Closure: (dynamic) => dynamic }\n"
                 "[4] middleMan { x = 5 limit = 100 stop = true"
                 " value = 242550 i = 99 }\n"
                 "[5] test { stop = true limit = 100 }\n",
                 stack_buffer);
  }

  FLAG_optimization_counter_threshold = saved_threshold;
  FLAG_use_osr = saved_osr;
}


TEST_CASE(Debug_InspectStackWithClosure_NotOptimized) {
  InspectStackWithClosureTest(false);
}


TEST_CASE(Debug_InspectStackWithClosure_Optimized) {
  InspectStackWithClosureTest(true);
}


void TestStepOutHandler(Dart_IsolateId isolate_id,
                        intptr_t bp_id,
                        const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  const char* expected_bpts[] = {"f1", "foo", "main"};
  const intptr_t expected_bpts_length = ARRAY_SIZE(expected_bpts);
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_VALID(res);
  EXPECT(breakpoint_hit_counter < expected_bpts_length);
  Dart_ActivationFrame frame;
  res = Dart_GetActivationFrame(trace, 0, &frame);
  EXPECT_VALID(res);
  Dart_Handle func_name;
  res = Dart_ActivationFrameInfo(frame, &func_name, NULL, NULL, NULL);
  EXPECT_VALID(res);
  EXPECT(Dart_IsString(func_name));
  const char* name_chars;
  Dart_StringToCString(func_name, &name_chars);
  if (breakpoint_hit_counter < expected_bpts_length) {
    EXPECT_STREQ(expected_bpts[breakpoint_hit_counter], name_chars);
  }
  if (verbose) {
    OS::Print("  >> bpt nr %d: %s\n", breakpoint_hit_counter, name_chars);
  }
  breakpoint_hit = true;
  breakpoint_hit_counter++;
  Dart_SetStepOut();
}


TEST_CASE(Debug_StepOut) {
  const char* kScriptChars =
      "f1() { return 1; }       \n"
      "f2() { return 2; }       \n"
      "                         \n"
      "foo() {                  \n"
      "  f1();                  \n"
      "  return f2();           \n"
      "}                        \n"
      "                         \n"
      "main() {                 \n"
      "  return foo();          \n"
      "}                        \n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&TestStepOutHandler);

  // Set a breakpoint in function f1, then repeatedly step out until
  // we get to main. We should see one breakpoint each in f1,
  // foo, main, but not in f2.
  SetBreakpointAtEntry("", "f1");

  breakpoint_hit = false;
  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT(Dart_IsInteger(retval));
  int64_t int_value = ToInt64(retval);
  EXPECT_EQ(2, int_value);
  EXPECT(breakpoint_hit == true);
}

static const char* step_into_expected_bpts[] = {
    "main",
      "foo",
        "f1",
      "foo",
      "foo",
        "X.kvmk",
          "f2",
        "X.kvmk",
        "X.kvmk",
      "foo",
    "main"
};

void TestStepIntoHandler(Dart_IsolateId isolate_id,
                         intptr_t bp_id,
                         const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  const intptr_t expected_bpts_length = ARRAY_SIZE(step_into_expected_bpts);
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_VALID(res);
  EXPECT(breakpoint_hit_counter < expected_bpts_length);
  Dart_ActivationFrame frame;
  res = Dart_GetActivationFrame(trace, 0, &frame);
  EXPECT_VALID(res);
  Dart_Handle func_name;
  res = Dart_ActivationFrameInfo(frame, &func_name, NULL, NULL, NULL);
  EXPECT_VALID(res);
  EXPECT(Dart_IsString(func_name));
  const char* name_chars;
  Dart_StringToCString(func_name, &name_chars);
  if (breakpoint_hit_counter < expected_bpts_length) {
    EXPECT_STREQ(step_into_expected_bpts[breakpoint_hit_counter], name_chars);
  }
  if (verbose) {
    OS::Print("  >> bpt nr %d: %s\n", breakpoint_hit_counter, name_chars);
  }
  breakpoint_hit = true;
  breakpoint_hit_counter++;
  Dart_SetStepInto();
}


TEST_CASE(Debug_StepInto) {
  const char* kScriptChars =
      "f1() { return 1; }       \n"
      "f2() { return 2; }       \n"
      "                         \n"
      "class X {                \n"
      "  kvmk(a, {b, c}) {      \n"
      "    return c + f2();     \n"
      "  }                      \n"
      "}                        \n"
      "                         \n"
      "foo() {                  \n"
      "  f1();                  \n"
      "  var o = new X();       \n"
      "  return o.kvmk(3, c:5); \n"
      "}                        \n"
      "                         \n"
      "main() {                 \n"
      "  return foo();          \n"
      "}                        \n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&TestStepIntoHandler);

  SetBreakpointAtEntry("", "main");
  breakpoint_hit = false;
  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT(Dart_IsInteger(retval));
  int64_t int_value = ToInt64(retval);
  EXPECT_EQ(7, int_value);
  EXPECT(breakpoint_hit == true);
  EXPECT(breakpoint_hit_counter == ARRAY_SIZE(step_into_expected_bpts));
}


static void StepIntoHandler(Dart_IsolateId isolate_id,
                            intptr_t bp_id,
                            const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  if (verbose) {
    OS::Print(">>> Breakpoint nr. %d in %s <<<\n",
              breakpoint_hit_counter, BreakpointInfo(trace));
    PrintStackTrace(trace);
  }
  breakpoint_hit = true;
  breakpoint_hit_counter++;
  Dart_SetStepInto();
}


TEST_CASE(Debug_IgnoreBP) {
  const char* kScriptChars =
      "class B {                \n"
      "  static var z = 0;      \n"
      "  var i = 100;           \n"
      "  var d = 3.14;          \n"
      "  var s = 'Dr Seuss';    \n"
      "}                        \n"
      "                         \n"
      "main() {                 \n"
      "  var x = new B();       \n"
      "  return x.i + 1;        \n"
      "}                        \n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&StepIntoHandler);

  SetBreakpointAtEntry("", "main");

  breakpoint_hit = false;
  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT(Dart_IsInteger(retval));
  int64_t int_value = ToInt64(retval);
  EXPECT_EQ(101, int_value);
  EXPECT(breakpoint_hit == true);
}


TEST_CASE(Debug_DeoptimizeFunction) {
  const char* kScriptChars =
      "foo(x) => 2 * x;                     \n"
      "                                     \n"
      "warmup() {                           \n"
      "  for (int i = 0; i < 5000; i++) {   \n"
      "    foo(i);                          \n"
      "  }                                  \n"
      "}                                    \n"
      "                                     \n"
      "main() {                             \n"
      "  return foo(99);                    \n"
      "}                                    \n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&StepIntoHandler);


  // Cause function foo to be optimized before we set a BP.
  Dart_Handle res = Invoke("warmup");
  EXPECT_VALID(res);

  // Now set breakpoint in main and then step into optimized function foo.
  SetBreakpointAtEntry("", "main");


  breakpoint_hit = false;
  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT(Dart_IsInteger(retval));
  int64_t int_value = ToInt64(retval);
  EXPECT_EQ(2 * 99, int_value);
  EXPECT(breakpoint_hit == true);
}


void TestSingleStepHandler(Dart_IsolateId isolate_id,
                           intptr_t bp_id,
                           const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  const char* expected_bpts[] = {
      "moo", "foo", "moo", "foo", "moo", "foo", "main"};
  const intptr_t expected_bpts_length = ARRAY_SIZE(expected_bpts);
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_VALID(res);
  EXPECT(breakpoint_hit_counter < expected_bpts_length);
  Dart_ActivationFrame frame;
  res = Dart_GetActivationFrame(trace, 0, &frame);
  EXPECT_VALID(res);
  Dart_Handle func_name;
  res = Dart_ActivationFrameInfo(frame, &func_name, NULL, NULL, NULL);
  EXPECT_VALID(res);
  EXPECT(Dart_IsString(func_name));
  const char* name_chars;
  Dart_StringToCString(func_name, &name_chars);
  if (verbose) {
    OS::Print("  >> bpt nr %d: %s\n", breakpoint_hit_counter, name_chars);
  }
  if (breakpoint_hit_counter < expected_bpts_length) {
    EXPECT_STREQ(expected_bpts[breakpoint_hit_counter], name_chars);
  }
  breakpoint_hit = true;
  breakpoint_hit_counter++;
  Dart_SetStepOver();
}


TEST_CASE(Debug_SingleStep) {
  const char* kScriptChars =
      "moo(s) { return 1; }      \n"
      "                          \n"
      "void foo() {              \n"
      "  moo('step one');        \n"
      "  moo('step two');        \n"
      "  moo('step three');      \n"
      "}                         \n"
      "                          \n"
      "void main() {             \n"
      "  foo();                  \n"
      "}                         \n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&TestSingleStepHandler);

  SetBreakpointAtEntry("", "moo");

  breakpoint_hit = false;
  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT(breakpoint_hit == true);
}


static void ClosureBreakpointHandler(Dart_IsolateId isolate_id,
                                     intptr_t bp_id,
                                     const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  const char* expected_trace[] = {"callback", "main"};
  const intptr_t expected_trace_length = 2;
  breakpoint_hit_counter++;
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_VALID(res);
  EXPECT_EQ(expected_trace_length, trace_len);
  for (int i = 0; i < trace_len; i++) {
    Dart_ActivationFrame frame;
    res = Dart_GetActivationFrame(trace, i, &frame);
    EXPECT_VALID(res);
    Dart_Handle func_name;
    res = Dart_ActivationFrameInfo(frame, &func_name, NULL, NULL, NULL);
    EXPECT_VALID(res);
    EXPECT(Dart_IsString(func_name));
    const char* name_chars;
    Dart_StringToCString(func_name, &name_chars);
    EXPECT_STREQ(expected_trace[i], name_chars);
    if (verbose) OS::Print("  >> %d: %s\n", i, name_chars);
  }
}


TEST_CASE(Debug_ClosureBreakpoint) {
  const char* kScriptChars =
      "callback(s) {          \n"
      "  return 111;          \n"
      "}                      \n"
      "                       \n"
      "main() {               \n"
      "  var h = callback;    \n"
      "  h('bla');            \n"
      "  callback('jada');    \n"
      "  return 442;          \n"
      "}                      \n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&ClosureBreakpointHandler);

  SetBreakpointAtEntry("", "callback");

  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  int64_t int_value = ToInt64(retval);
  EXPECT_EQ(442, int_value);
  EXPECT_EQ(2, breakpoint_hit_counter);
}


static void ExprClosureBreakpointHandler(Dart_IsolateId isolate_id,
                                         intptr_t bp_id,
                                         const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  static const char* expected_trace[] = {"<anonymous closure>", "main"};
  Dart_Handle add_locals = Dart_NewList(4);
  Dart_ListSetAt(add_locals, 0, NewString("a"));
  Dart_ListSetAt(add_locals, 1, Dart_NewInteger(10));
  Dart_ListSetAt(add_locals, 2, NewString("b"));
  Dart_ListSetAt(add_locals, 3, Dart_NewInteger(20));
  Dart_Handle expected_locals[] = {add_locals, Dart_Null()};
  breakpoint_hit_counter++;
  PrintStackTrace(trace);
  VerifyStackTrace(trace, expected_trace, expected_locals, 2, false);
}


TEST_CASE(Debug_ExprClosureBreakpoint) {
  const char* kScriptChars =
      "var c;                 \n"
      "                       \n"
      "main() {               \n"
      "  c = (a, b) {         \n"
      "    return a + b;      \n"
      "  };                   \n"
      "  return c(10, 20);    \n"
      "}                      \n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&ExprClosureBreakpointHandler);

  Dart_Handle script_url = NewString(TestCase::url());
  intptr_t line_no = 5;  // In closure 'add'.
  Dart_Handle res = Dart_SetBreakpoint(script_url, line_no);
  EXPECT_VALID(res);
  EXPECT(Dart_IsInteger(res));

  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  int64_t int_value = ToInt64(retval);
  EXPECT_EQ(30, int_value);
  EXPECT_EQ(1, breakpoint_hit_counter);
}


void TestBreakpointHandlerWithVerify(Dart_IsolateId isolate_id,
                                     Dart_Breakpoint bpt,
                                     Dart_StackTrace trace) {
  breakpoint_hit = true;
  breakpoint_hit_counter++;

  Dart_ActivationFrame frame;
  Dart_Handle res = Dart_GetActivationFrame(trace, 0, &frame);
  EXPECT_VALID(res);
  Dart_Handle func_name;
  intptr_t line_number = -1;
  res = Dart_ActivationFrameInfo(frame, &func_name, NULL, &line_number, NULL);
  EXPECT_NE(-1, line_number);
  if (verbose) OS::Print("Hit line %" Pd "\n", line_number);

  VerifyPointersVisitor::VerifyPointers();
}


static void NoopNativeFunction(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, Dart_True());
  Dart_ExitScope();
}


static Dart_NativeFunction NoopNativeResolver(Dart_Handle name,
                                              int arg_count,
                                              bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  return &NoopNativeFunction;
}


TEST_CASE(Debug_BreakpointStubPatching) {
  // Note changes to this script may require changes to the breakpoint line
  // numbers below.
  const char* kScriptChars =
      "bar(i) {}                       \n"
      "nat() native 'a';               \n"
      "foo(n) {                        \n"
      "  for(var i = 0; i < n; i++) {  \n"
      "    bar(i);                     \n"  // Static call.
      "    i++;                        \n"  // Instance call.
      "    i == null;                  \n"  // Equality.
      "    var x = i;                  \n"  // Debug step check.
      "    i is int;                   \n"  // Subtype test.
      "    y(z) => () => z + i;        \n"  // Allocate context.
      "    y(i)();                     \n"  // Closure call.
      "    nat();                      \n"  // Runtime call.
      "    return y;                   \n"  // Return.
      "  }                             \n"
      "}                               \n"
      "                                \n"
      "main() {                        \n"
      "  var i = 3;                    \n"
      "  foo(i);                       \n"
      "}                               \n";

  LoadScript(kScriptChars);
  Dart_Handle result = Dart_SetNativeResolver(script_lib,
                                              &NoopNativeResolver,
                                              NULL);
  EXPECT_VALID(result);
  Dart_SetBreakpointHandler(&TestBreakpointHandlerWithVerify);

  Dart_Handle script_url = NewString(TestCase::url());

  const intptr_t num_breakpoints = 9;
  intptr_t breakpoint_lines[num_breakpoints] =
      {5, 6, 7, 8, 9, 10, 11, 12, 13};

  for (intptr_t i = 0; i < num_breakpoints; i++) {
    result = Dart_SetBreakpoint(script_url, breakpoint_lines[i]);
    EXPECT_VALID(result);
    EXPECT(Dart_IsInteger(result));
  }

  breakpoint_hit = false;
  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT(breakpoint_hit == true);
  EXPECT_EQ(num_breakpoints, breakpoint_hit_counter);
}


static intptr_t bp_id_to_be_deleted;

static void DeleteBreakpointHandler(Dart_IsolateId isolate_id,
                                    intptr_t bp_id,
                                    const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  const char* expected_trace[] = {"foo", "main"};
  const intptr_t expected_trace_length = 2;
  breakpoint_hit_counter++;
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_VALID(res);
  EXPECT_EQ(expected_trace_length, trace_len);
  for (int i = 0; i < trace_len; i++) {
    Dart_ActivationFrame frame;
    res = Dart_GetActivationFrame(trace, i, &frame);
    EXPECT_VALID(res);
    Dart_Handle func_name;
    res = Dart_ActivationFrameInfo(frame, &func_name, NULL, NULL, NULL);
    EXPECT_VALID(res);
    EXPECT(Dart_IsString(func_name));
    const char* name_chars;
    Dart_StringToCString(func_name, &name_chars);
    EXPECT_STREQ(expected_trace[i], name_chars);
    if (verbose) OS::Print("  >> %d: %s\n", i, name_chars);
  }
  // Remove the breakpoint after we've hit it twice
  if (breakpoint_hit_counter == 2) {
    if (verbose) OS::Print("uninstalling breakpoint\n");
    EXPECT_EQ(bp_id_to_be_deleted, bp_id);
    Dart_Handle res = Dart_RemoveBreakpoint(bp_id);
    EXPECT_VALID(res);
  }
}


TEST_CASE(Debug_DeleteBreakpoint) {
  const char* kScriptChars =
      "moo(s) { }             \n"
      "                       \n"
      "foo() {                \n"
      "    moo('good news');  \n"
      "}                      \n"
      "                       \n"
      "void main() {          \n"
      "  foo();               \n"
      "  foo();               \n"
      "  foo();               \n"
      "}                      \n";

  LoadScript(kScriptChars);

  Dart_Handle script_url = NewString(TestCase::url());
  intptr_t line_no = 4;  // In function 'foo'.

  Dart_SetPausedEventHandler(&DeleteBreakpointHandler);

  Dart_Handle res = Dart_SetBreakpoint(script_url, line_no);
  EXPECT_VALID(res);
  EXPECT(Dart_IsInteger(res));
  int64_t bp_id = ToInt64(res);

  // Function main() calls foo() 3 times. On the second iteration, the
  // breakpoint is removed by the handler, so we expect the breakpoint
  // to fire twice only.
  bp_id_to_be_deleted = bp_id;
  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT_EQ(2, breakpoint_hit_counter);
}


static void InspectStaticFieldHandler(Dart_IsolateId isolate_id,
                                      intptr_t bp_id,
                                      const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  ASSERT(script_lib != NULL);
  ASSERT(!Dart_IsError(script_lib));
  ASSERT(Dart_IsLibrary(script_lib));
  Dart_Handle class_A = Dart_GetClass(script_lib, NewString("A"));
  EXPECT_VALID(class_A);

  const int expected_num_fields = 2;
  struct {
    const char* field_name;
    const char* field_value;
  } expected[] = {
    // Expected values at first breakpoint.
    { "bla", "yada yada yada"},
    { "u", "null" },
    // Expected values at second breakpoint.
    { "bla", "silence is golden" },
    { "u", "442" }
  };
  ASSERT(breakpoint_hit_counter < 2);
  int expected_idx = breakpoint_hit_counter * expected_num_fields;
  breakpoint_hit_counter++;

  Dart_Handle fields = Dart_GetStaticFields(class_A);
  ASSERT(!Dart_IsError(fields));
  ASSERT(Dart_IsList(fields));

  intptr_t list_length = 0;
  Dart_Handle retval = Dart_ListLength(fields, &list_length);
  EXPECT_VALID(retval);
  int num_fields = list_length / 2;
  OS::Print("Class A has %d fields:\n", num_fields);
  ASSERT(expected_num_fields == num_fields);

  for (int i = 0; i + 1 < list_length; i += 2) {
    Dart_Handle name_handle = Dart_ListGetAt(fields, i);
    EXPECT_VALID(name_handle);
    EXPECT(Dart_IsString(name_handle));
    char const* name;
    Dart_StringToCString(name_handle, &name);
    EXPECT_STREQ(expected[expected_idx].field_name, name);
    Dart_Handle value_handle = Dart_ListGetAt(fields, i + 1);
    EXPECT_VALID(value_handle);
    value_handle = Dart_ToString(value_handle);
    EXPECT_VALID(value_handle);
    EXPECT(Dart_IsString(value_handle));
    char const* value;
    Dart_StringToCString(value_handle, &value);
    EXPECT_STREQ(expected[expected_idx].field_value, value);
    OS::Print("  %s: %s\n", name, value);
    expected_idx++;
  }
}


TEST_CASE(Debug_InspectStaticField) {
  const char* kScriptChars =
    " class A {                                 \n"
    "   static var bla = 'yada yada yada';      \n"
    "   static var u;                           \n"
    " }                                         \n"
    "                                           \n"
    " debugBreak() { }                          \n"
    " main() {                                  \n"
    "   var a = new A();                        \n"
    "   debugBreak();                           \n"
    "   A.u = 442;                              \n"
    "   A.bla = 'silence is golden';            \n"
    "   debugBreak();                           \n"
    " }                                         \n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&InspectStaticFieldHandler);
  SetBreakpointAtEntry("", "debugBreak");

  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
}


TEST_CASE(Debug_InspectObject) {
  const char* kScriptChars =
    " class A {                                 \n"
    "   var a_field = 'a';                      \n"
    "   static var bla = 'yada yada yada';      \n"
    "   static var error = unresolvedName();    \n"
    "   var d = 42.1;                           \n"
    " }                                         \n"
    " class B extends A {                       \n"
    "   var oneDay = const Duration(hours: 24); \n"
    "   static var bla = 'blah blah';           \n"
    " }                                         \n"
    " get_b() { return new B(); }               \n"
    " get_int() { return 666; }                 \n";

  // Number of instance fields in an object of class B.
  const intptr_t kNumObjectFields = 3;

  LoadScript(kScriptChars);

  Dart_Handle object_b = Invoke("get_b");

  EXPECT_VALID(object_b);

  Dart_Handle fields = Dart_GetInstanceFields(object_b);
  EXPECT_VALID(fields);
  EXPECT(Dart_IsList(fields));
  intptr_t list_length = 0;
  Dart_Handle retval = Dart_ListLength(fields, &list_length);
  EXPECT_VALID(retval);
  int num_fields = list_length / 2;
  EXPECT_EQ(kNumObjectFields, num_fields);
  OS::Print("Object has %d fields:\n", num_fields);
  for (int i = 0; i + 1 < list_length; i += 2) {
    Dart_Handle name_handle = Dart_ListGetAt(fields, i);
    EXPECT_VALID(name_handle);
    EXPECT(Dart_IsString(name_handle));
    char const* name;
    Dart_StringToCString(name_handle, &name);
    Dart_Handle value_handle = Dart_ListGetAt(fields, i + 1);
    EXPECT_VALID(value_handle);
    value_handle = Dart_ToString(value_handle);
    EXPECT_VALID(value_handle);
    EXPECT(Dart_IsString(value_handle));
    char const* value;
    Dart_StringToCString(value_handle, &value);
    OS::Print("  %s: %s\n", name, value);
  }

  // Check that an integer value returns an empty list of fields.
  Dart_Handle triple_six = Invoke("get_int");
  EXPECT_VALID(triple_six);
  EXPECT(Dart_IsInteger(triple_six));
  int64_t int_value = ToInt64(triple_six);
  EXPECT_EQ(666, int_value);
  fields = Dart_GetInstanceFields(triple_six);
  EXPECT_VALID(fields);
  EXPECT(Dart_IsList(fields));
  retval = Dart_ListLength(fields, &list_length);
  EXPECT_EQ(0, list_length);

  // Check static field of class B (one field named 'bla')
  Dart_Handle class_B = Dart_GetObjClass(object_b);
  EXPECT_VALID(class_B);
  EXPECT(!Dart_IsNull(class_B));
  fields = Dart_GetStaticFields(class_B);
  EXPECT_VALID(fields);
  EXPECT(Dart_IsList(fields));
  list_length = 0;
  retval = Dart_ListLength(fields, &list_length);
  EXPECT_VALID(retval);
  EXPECT_EQ(2, list_length);
  Dart_Handle name_handle = Dart_ListGetAt(fields, 0);
  EXPECT_VALID(name_handle);
  EXPECT(Dart_IsString(name_handle));
  char const* name;
  Dart_StringToCString(name_handle, &name);
  EXPECT_STREQ("bla", name);
  Dart_Handle value_handle = Dart_ListGetAt(fields, 1);
  EXPECT_VALID(value_handle);
  value_handle = Dart_ToString(value_handle);
  EXPECT_VALID(value_handle);
  EXPECT(Dart_IsString(value_handle));
  char const* value;
  Dart_StringToCString(value_handle, &value);
  EXPECT_STREQ("blah blah", value);

  // Check static field of B's superclass.
  Dart_Handle class_A = Dart_GetSupertype(class_B);
  EXPECT_VALID(class_A);
  EXPECT(!Dart_IsNull(class_A));
  fields = Dart_GetStaticFields(class_A);
  EXPECT_VALID(fields);
  EXPECT(Dart_IsList(fields));
  list_length = 0;
  retval = Dart_ListLength(fields, &list_length);
  EXPECT_VALID(retval);
  EXPECT_EQ(4, list_length);
  // Static field "bla" should have value "yada yada yada".
  name_handle = Dart_ListGetAt(fields, 0);
  EXPECT_VALID(name_handle);
  EXPECT(Dart_IsString(name_handle));
  Dart_StringToCString(name_handle, &name);
  EXPECT_STREQ("bla", name);
  value_handle = Dart_ListGetAt(fields, 1);
  EXPECT_VALID(value_handle);
  value_handle = Dart_ToString(value_handle);
  EXPECT_VALID(value_handle);
  EXPECT(Dart_IsString(value_handle));
  Dart_StringToCString(value_handle, &value);
  EXPECT_STREQ("yada yada yada", value);
  // The static field "error" should result in a compile error.
  name_handle = Dart_ListGetAt(fields, 2);
  EXPECT_VALID(name_handle);
  EXPECT(Dart_IsString(name_handle));
  Dart_StringToCString(name_handle, &name);
  EXPECT_STREQ("error", name);
  value_handle = Dart_ListGetAt(fields, 3);
  EXPECT(Dart_IsError(value_handle));
}


static Dart_IsolateId test_isolate_id = ILLEGAL_ISOLATE_ID;
static int verify_callback = 0;
static void TestIsolateID(Dart_IsolateId isolate_id, Dart_IsolateEvent kind) {
  if (kind == kCreated) {
    EXPECT(test_isolate_id == ILLEGAL_ISOLATE_ID);
    test_isolate_id = isolate_id;
    Dart_Isolate isolate = Dart_GetIsolate(isolate_id);
    EXPECT(isolate == Dart_CurrentIsolate());
    verify_callback |= 0x1;  // Register create callback.
  } else if (kind == kInterrupted) {
    EXPECT(test_isolate_id == isolate_id);
    Dart_Isolate isolate = Dart_GetIsolate(isolate_id);
    EXPECT(isolate == Dart_CurrentIsolate());
    verify_callback |= 0x2;  // Register interrupt callback.
  } else if (kind == kShutdown) {
    EXPECT(test_isolate_id == isolate_id);
    Dart_Isolate isolate = Dart_GetIsolate(isolate_id);
    EXPECT(isolate == Dart_CurrentIsolate());
    verify_callback |= 0x4;  // Register shutdown callback.
  }
}


UNIT_TEST_CASE(Debug_IsolateID) {
  const char* kScriptChars =
      "void moo(s) { }        \n"
      "class A {              \n"
      "  static void foo() {  \n"
      "    moo('good news');  \n"
      "  }                    \n"
      "}                      \n"
      "void main() {          \n"
      "  A.foo();             \n"
      "}                      \n";

  Dart_SetIsolateEventHandler(&TestIsolateID);
  Dart_Isolate isolate = TestCase::CreateTestIsolate();
  ASSERT(isolate != NULL);
  Dart_EnterScope();
  LoadScript(kScriptChars);
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT(test_isolate_id != ILLEGAL_ISOLATE_ID);
  EXPECT(Dart_GetIsolate(test_isolate_id) == isolate);
  EXPECT(Dart_GetIsolateId(isolate) == test_isolate_id);
  Dart_ExitScope();
  Dart_ShutdownIsolate();
  EXPECT(verify_callback == 0x5);  // Only created and shutdown events.
}


static Monitor* sync = NULL;
static bool isolate_interrupted = false;
static bool pause_event_handled = false;
static Dart_IsolateId interrupt_isolate_id = ILLEGAL_ISOLATE_ID;
static volatile bool continue_isolate_loop = true;


static void InterruptIsolateHandler(Dart_IsolateId isolateId,
                                    intptr_t breakpointId,
                                    const Dart_CodeLocation& location) {
  MonitorLocker ml(sync);
  pause_event_handled = true;
  ml.Notify();
}

static void TestInterruptIsolate(Dart_IsolateId isolate_id,
                                 Dart_IsolateEvent kind) {
  if (kind == kCreated) {
    EXPECT(interrupt_isolate_id == ILLEGAL_ISOLATE_ID);
    // Indicate that the isolate has been created.
    {
      MonitorLocker ml(sync);
      interrupt_isolate_id = isolate_id;
      ml.Notify();
    }
  } else if (kind == kInterrupted) {
    // Indicate that isolate has been interrupted.
    {
      MonitorLocker ml(sync);
      isolate_interrupted = true;
      continue_isolate_loop = false;
      Dart_SetStepInto();
    }
  } else if (kind == kShutdown) {
    if (interrupt_isolate_id == isolate_id) {
      MonitorLocker ml(sync);
      interrupt_isolate_id = ILLEGAL_ISOLATE_ID;
      ml.Notify();
    }
  }
}


static void InterruptNativeFunction(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle val = Dart_NewBoolean(continue_isolate_loop);
  Dart_SetReturnValue(args, val);
  Dart_ExitScope();
}


static Dart_NativeFunction InterruptNativeResolver(Dart_Handle name,
                                                   int arg_count,
                                                   bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  return &InterruptNativeFunction;
}


static void InterruptIsolateRun(uword unused) {
  const char* kScriptChars =
      "void moo(s) { }              \n"
      "class A {                    \n"
      "  static check() native 'a'; \n"
      "  static void foo() {        \n"
      "    var loop = true;         \n"
      "    while (loop) {           \n"
      "      moo('good news');      \n"
      "      loop = check();        \n"
      "    }                        \n"
      "  }                          \n"
      "}                            \n"
      "void main() {                \n"
      "  A.foo();                   \n"
      "}                            \n";

  Dart_Isolate isolate = TestCase::CreateTestIsolate();
  ASSERT(isolate != NULL);
  Dart_EnterScope();
  LoadScript(kScriptChars);

  Dart_Handle result = Dart_SetNativeResolver(script_lib,
                                              &InterruptNativeResolver,
                                              NULL);
  EXPECT_VALID(result);

  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  Dart_ExitScope();
  Dart_ShutdownIsolate();
}


TEST_CASE(Debug_InterruptIsolate) {
  Dart_SetIsolateEventHandler(&TestInterruptIsolate);
  sync = new Monitor();
  EXPECT(interrupt_isolate_id == ILLEGAL_ISOLATE_ID);
  Dart_SetPausedEventHandler(InterruptIsolateHandler);
  int result = Thread::Start(InterruptIsolateRun, 0);
  EXPECT_EQ(0, result);

  // Wait for the test isolate to be created.
  {
    MonitorLocker ml(sync);
    while (interrupt_isolate_id == ILLEGAL_ISOLATE_ID) {
      ml.Wait();
    }
  }
  EXPECT(interrupt_isolate_id != ILLEGAL_ISOLATE_ID);

  Dart_Isolate isolate = Dart_GetIsolate(interrupt_isolate_id);
  EXPECT(isolate != NULL);
  Dart_InterruptIsolate(isolate);

  // Wait for the test isolate to be interrupted.
  {
    MonitorLocker ml(sync);
    while (!isolate_interrupted || !pause_event_handled) {
      ml.Wait();
    }
  }
  EXPECT(isolate_interrupted);
  EXPECT(pause_event_handled);

  // Wait for the test isolate to shutdown.
  {
    MonitorLocker ml(sync);
    while (interrupt_isolate_id != ILLEGAL_ISOLATE_ID) {
      ml.Wait();
    }
  }
  EXPECT(interrupt_isolate_id == ILLEGAL_ISOLATE_ID);
}


static void StackTraceDump1BreakpointHandler(
                Dart_IsolateId isolate_id,
                intptr_t bp_id,
                const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  const int kStackTraceLen = 4;
  static const char* expected_trace[kStackTraceLen] = {
    "local_to_main",
    "Test.local1_to_func1",
    "Test.func1",
    "main"
  };

  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_VALID(res);
  EXPECT_EQ(kStackTraceLen, trace_len);

  // Frame 0 corresponding to "local_to_main".
  Dart_Handle frame0_locals = Dart_NewList(8);
  Dart_ListSetAt(frame0_locals, 0, NewString("i"));
  Dart_ListSetAt(frame0_locals, 1, Dart_NewInteger(76));
  Dart_ListSetAt(frame0_locals, 2, NewString("j"));
  Dart_ListSetAt(frame0_locals, 3, Dart_NewInteger(119));
  Dart_ListSetAt(frame0_locals, 4, NewString("k"));
  Dart_ListSetAt(frame0_locals, 5, Dart_NewInteger(66));
  Dart_ListSetAt(frame0_locals, 6, NewString("l"));
  Dart_ListSetAt(frame0_locals, 7, Dart_NewInteger(99));

  // Frame 1 corresponding to "Test.local1_to_func1".
  Dart_Handle frame1_locals = Dart_NewList(14);
  Dart_ListSetAt(frame1_locals, 0, NewString("i"));
  Dart_ListSetAt(frame1_locals, 1, Dart_NewInteger(11));
  Dart_ListSetAt(frame1_locals, 2, NewString("j"));
  Dart_ListSetAt(frame1_locals, 3, Dart_NewInteger(22));
  Dart_ListSetAt(frame1_locals, 4, NewString("k"));
  Dart_ListSetAt(frame1_locals, 5, Dart_NewInteger(33));
  Dart_ListSetAt(frame1_locals, 6, NewString("l"));
  Dart_ListSetAt(frame1_locals, 7, Dart_NewInteger(44));
  Dart_ListSetAt(frame1_locals, 8, NewString("m"));
  Dart_ListSetAt(frame1_locals, 9, Dart_NewInteger(55));
  Dart_ListSetAt(frame1_locals, 10, NewString("func"));
  Dart_ListSetAt(frame1_locals, 11, Dart_Null());
  Dart_ListSetAt(frame1_locals, 12, NewString("n"));
  Dart_ListSetAt(frame1_locals, 13, Dart_Null());

  // Frame 2 corresponding to "Test.func1".
  Dart_Handle frame2_locals = Dart_NewList(18);
  Dart_ListSetAt(frame2_locals, 0, NewString("this"));
  Dart_ListSetAt(frame2_locals, 1, Dart_Null());
  Dart_ListSetAt(frame2_locals, 2, NewString("func"));
  Dart_ListSetAt(frame2_locals, 3, Dart_Null());
  Dart_ListSetAt(frame2_locals, 4, NewString("i"));
  Dart_ListSetAt(frame2_locals, 5, Dart_NewInteger(11));
  Dart_ListSetAt(frame2_locals, 6, NewString("j"));
  Dart_ListSetAt(frame2_locals, 7, Dart_NewInteger(22));
  Dart_ListSetAt(frame2_locals, 8, NewString("k"));
  Dart_ListSetAt(frame2_locals, 9, Dart_NewInteger(33));
  Dart_ListSetAt(frame2_locals, 10, NewString("l"));
  Dart_ListSetAt(frame2_locals, 11, Dart_NewInteger(44));
  Dart_ListSetAt(frame2_locals, 12, NewString("m"));
  Dart_ListSetAt(frame2_locals, 13, Dart_NewInteger(55));
  Dart_ListSetAt(frame2_locals, 14, NewString("local1_to_func1"));
  Dart_ListSetAt(frame2_locals, 15, Dart_Null());
  Dart_ListSetAt(frame2_locals, 16, NewString("sum"));
  Dart_ListSetAt(frame2_locals, 17, Dart_NewInteger(0));

  // Frame 3 corresponding to "main".
  Dart_Handle frame3_locals = Dart_NewList(14);
  Dart_ListSetAt(frame3_locals, 0, NewString("i"));
  Dart_ListSetAt(frame3_locals, 1, Dart_NewInteger(76));
  Dart_ListSetAt(frame3_locals, 2, NewString("j"));
  Dart_ListSetAt(frame3_locals, 3, Dart_NewInteger(119));
  Dart_ListSetAt(frame3_locals, 4, NewString("local_to_main"));
  Dart_ListSetAt(frame3_locals, 5, Dart_Null());
  Dart_ListSetAt(frame3_locals, 6, NewString("sum"));
  Dart_ListSetAt(frame3_locals, 7, Dart_NewInteger(0));
  Dart_ListSetAt(frame3_locals, 8, NewString("value"));
  Dart_ListSetAt(frame3_locals, 9, Dart_Null());
  Dart_ListSetAt(frame3_locals, 10, NewString("func1"));
  Dart_ListSetAt(frame3_locals, 11, Dart_Null());
  Dart_ListSetAt(frame3_locals, 12, NewString("main_local"));
  Dart_ListSetAt(frame3_locals, 13, Dart_Null());

  Dart_Handle expected_locals[] = {
    frame0_locals,
    frame1_locals,
    frame2_locals,
    frame3_locals
  };
  breakpoint_hit_counter++;
  VerifyStackTrace(trace, expected_trace, expected_locals,
                   kStackTraceLen, true);
}


TEST_CASE(Debug_StackTraceDump1) {
  const char* kScriptChars =
      "class Test {\n"
      "  Test(int local);\n"
      "\n"
      "  int func1(int func(int i, int j)) {\n"
      "    var i = 0;\n"
      "    var j = 0;\n"
      "    var k = 0;\n"
      "    var l = 0;\n"
      "    var m = 0;\n"
      "    int local1_to_func1(int func(int i, int j)) {\n"
      "      // Capture i and j here.\n"
      "      i = 11;\n"
      "      j = 22;\n"
      "      k = 33;\n"
      "      l = 44;\n"
      "      m = 55;\n"
      "      var n = func(i + j + k, l + m);\n"
      "      return n;\n"
      "    }\n"
      "    var sum = 0;\n"
      "    return local1_to_func1(func);\n"
      "  }\n"
      "\n"
      "  int local;\n"
      "}\n"
      "\n"
      "int main() {\n"
      "  var i = 10;\n"
      "  var j = 20;\n"
      "  int local_to_main(int k, int l) {\n"
      "    // Capture i and j here.\n"
      "    i = i + k;\n"
      "    j = j + l;\n"
      "    return i + j;\n"
      "  }\n"
      "  var sum = 0;\n"
      "  Test value = new Test(10);\n"
      "  var func1 = value.func1;\n"
      "  var main_local = local_to_main;\n"
      "  return func1(main_local);\n"
      "}\n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&StackTraceDump1BreakpointHandler);

  Dart_Handle script_url = NewString(TestCase::url());
  intptr_t line_no = 34;  // In closure 'local_to_main'.
  Dart_Handle res = Dart_SetBreakpoint(script_url, line_no);
  EXPECT_VALID(res);
  EXPECT(Dart_IsInteger(res));

  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  int64_t int_value = ToInt64(retval);
  EXPECT_EQ(195, int_value);
  EXPECT_EQ(1, breakpoint_hit_counter);
}


static void StackTraceDump2ExceptionHandler(Dart_IsolateId isolate_id,
                                            Dart_Handle exception_object,
                                            Dart_StackTrace trace) {
  const int kStackTraceLen = 5;
  static const char* expected_trace[kStackTraceLen] = {
    "Object._noSuchMethod",
    "Object.noSuchMethod",
    "Test.local1_to_func1",
    "Test.func1",
    "main"
  };

  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_VALID(res);
  EXPECT_EQ(kStackTraceLen, trace_len);

  // Frame 0 corresponding to "Object._noSuchMethod".
  Dart_Handle frame0_locals = Dart_NewList(12);
  Dart_ListSetAt(frame0_locals, 0, NewString("this"));
  Dart_ListSetAt(frame0_locals, 1, Dart_Null());
  Dart_ListSetAt(frame0_locals, 2, NewString("isMethod"));
  Dart_ListSetAt(frame0_locals, 3, Dart_Null());
  Dart_ListSetAt(frame0_locals, 4, NewString("memberName"));
  Dart_ListSetAt(frame0_locals, 5, Dart_Null());
  Dart_ListSetAt(frame0_locals, 6, NewString("type"));
  Dart_ListSetAt(frame0_locals, 7, Dart_Null());
  Dart_ListSetAt(frame0_locals, 8, NewString("arguments"));
  Dart_ListSetAt(frame0_locals, 9, Dart_Null());
  Dart_ListSetAt(frame0_locals, 10, NewString("namedArguments"));
  Dart_ListSetAt(frame0_locals, 11, Dart_Null());

  // Frame 1 corresponding to "Object.noSuchMethod".
  Dart_Handle frame1_locals = Dart_NewList(4);
  Dart_ListSetAt(frame1_locals, 0, NewString("this"));
  Dart_ListSetAt(frame1_locals, 1, Dart_Null());
  Dart_ListSetAt(frame1_locals, 2, NewString("invocation"));
  Dart_ListSetAt(frame1_locals, 3, Dart_Null());

  // Frame 2 corresponding to "Test.local1_to_func1".
  Dart_Handle frame2_locals = Dart_NewList(16);
  Dart_ListSetAt(frame2_locals, 0, NewString("i"));
  Dart_ListSetAt(frame2_locals, 1, Dart_NewInteger(11));
  Dart_ListSetAt(frame2_locals, 2, NewString("j"));
  Dart_ListSetAt(frame2_locals, 3, Dart_NewInteger(22));
  Dart_ListSetAt(frame2_locals, 4, NewString("k"));
  Dart_ListSetAt(frame2_locals, 5, Dart_NewInteger(33));
  Dart_ListSetAt(frame2_locals, 6, NewString("l"));
  Dart_ListSetAt(frame2_locals, 7, Dart_NewInteger(44));
  Dart_ListSetAt(frame2_locals, 8, NewString("m"));
  Dart_ListSetAt(frame2_locals, 9, Dart_NewInteger(55));
  Dart_ListSetAt(frame2_locals, 10, NewString("this"));
  Dart_ListSetAt(frame2_locals, 11, Dart_Null());
  Dart_ListSetAt(frame2_locals, 12, NewString("func"));
  Dart_ListSetAt(frame2_locals, 13, Dart_Null());
  Dart_ListSetAt(frame2_locals, 14, NewString("n"));
  Dart_ListSetAt(frame2_locals, 15, Dart_Null());

  // Frame 3 corresponding to "Test.func1".
  Dart_Handle frame3_locals = Dart_NewList(18);
  Dart_ListSetAt(frame3_locals, 0, NewString("this"));
  Dart_ListSetAt(frame3_locals, 1, Dart_Null());
  Dart_ListSetAt(frame3_locals, 2, NewString("func"));
  Dart_ListSetAt(frame3_locals, 3, Dart_Null());
  Dart_ListSetAt(frame3_locals, 4, NewString("i"));
  Dart_ListSetAt(frame3_locals, 5, Dart_NewInteger(11));
  Dart_ListSetAt(frame3_locals, 6, NewString("j"));
  Dart_ListSetAt(frame3_locals, 7, Dart_NewInteger(22));
  Dart_ListSetAt(frame3_locals, 8, NewString("k"));
  Dart_ListSetAt(frame3_locals, 9, Dart_NewInteger(33));
  Dart_ListSetAt(frame3_locals, 10, NewString("l"));
  Dart_ListSetAt(frame3_locals, 11, Dart_NewInteger(44));
  Dart_ListSetAt(frame3_locals, 12, NewString("m"));
  Dart_ListSetAt(frame3_locals, 13, Dart_NewInteger(55));
  Dart_ListSetAt(frame3_locals, 14, NewString("local1_to_func1"));
  Dart_ListSetAt(frame3_locals, 15, Dart_Null());
  Dart_ListSetAt(frame3_locals, 16, NewString("sum"));
  Dart_ListSetAt(frame3_locals, 17, Dart_NewInteger(0));

  // Frame 4 corresponding to "main".
  Dart_Handle frame4_locals = Dart_NewList(12);
  Dart_ListSetAt(frame4_locals, 0, NewString("i"));
  Dart_ListSetAt(frame4_locals, 1, Dart_NewInteger(10));
  Dart_ListSetAt(frame4_locals, 2, NewString("j"));
  Dart_ListSetAt(frame4_locals, 3, Dart_NewInteger(20));
  Dart_ListSetAt(frame4_locals, 4, NewString("local_to_main"));
  Dart_ListSetAt(frame4_locals, 5, Dart_Null());
  Dart_ListSetAt(frame4_locals, 6, NewString("sum"));
  Dart_ListSetAt(frame4_locals, 7, Dart_NewInteger(0));
  Dart_ListSetAt(frame4_locals, 8, NewString("value"));
  Dart_ListSetAt(frame4_locals, 9, Dart_Null());
  Dart_ListSetAt(frame4_locals, 10, NewString("func1"));
  Dart_ListSetAt(frame4_locals, 11, Dart_Null());

  Dart_Handle expected_locals[] = {
    frame0_locals,
    frame1_locals,
    frame2_locals,
    frame3_locals,
    frame4_locals
  };
  breakpoint_hit_counter++;
  VerifyStackTrace(trace, expected_trace, expected_locals,
                   kStackTraceLen, true);
}


TEST_CASE(Debug_StackTraceDump2) {
  const char* kScriptChars =
      "class Test {\n"
      "  Test(int local);\n"
      "\n"
      "  int func1(int func(int i, int j)) {\n"
      "    var i = 0;\n"
      "    var j = 0;\n"
      "    var k = 0;\n"
      "    var l = 0;\n"
      "    var m = 0;\n"
      "    int local1_to_func1(int func(int i, int j)) {\n"
      "      // Capture i and j here.\n"
      "      i = 11;\n"
      "      j = 22;\n"
      "      k = 33;\n"
      "      l = 44;\n"
      "      m = 55;\n"
      "      var n = junk(i + j + k, l + m);\n"
      "      return n;\n"
      "    }\n"
      "    var sum = 0;\n"
      "    return local1_to_func1(func);\n"
      "  }\n"
      "\n"
      "  int local;\n"
      "}\n"
      "\n"
      "int main() {\n"
      "  var i = 10;\n"
      "  var j = 20;\n"
      "  int local_to_main(int k, int l) {\n"
      "    // Capture i and j here.\n"
      "    return i + j;\n"
      "  }\n"
      "  var sum = 0;\n"
      "  Test value = new Test(10);\n"
      "  var func1 = value.func1;\n"
      "  return func1(local_to_main);\n"
      "}\n";

  LoadScript(kScriptChars);
  Dart_SetExceptionThrownHandler(&StackTraceDump2ExceptionHandler);
  breakpoint_hit_counter = 0;
  Dart_SetExceptionPauseInfo(kPauseOnAllExceptions);

  Dart_Handle retval = Invoke("main");
  EXPECT(Dart_IsError(retval));
  EXPECT(Dart_IsUnhandledExceptionError(retval));
  EXPECT_EQ(1, breakpoint_hit_counter);
}


void TestEvaluateHandler(Dart_IsolateId isolate_id,
                         intptr_t bp_id,
                         const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  intptr_t trace_len;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  EXPECT_VALID(res);
  EXPECT_EQ(1, trace_len);
  Dart_ActivationFrame frame;
  res = Dart_GetActivationFrame(trace, 0, &frame);
  EXPECT_VALID(res);

  // Get the local variable p and evaluate an expression in the
  // context of p.
  Dart_Handle p = GetLocalVariable(frame, "p");
  EXPECT_VALID(p);
  EXPECT(!Dart_IsNull(p));

  Dart_Handle r = Dart_EvaluateExpr(p, NewString("sqrt(x*x + y*this.y)"));
  EXPECT_VALID(r);
  EXPECT(Dart_IsNumber(r));
  EXPECT_EQ(5.0, ToDouble(r));

  // Set top-level variable to a new value.
  Dart_Handle h = Dart_EvaluateExpr(p, NewString("_factor = 10"));
  EXPECT_VALID(h);
  EXPECT(Dart_IsInteger(h));
  EXPECT_EQ(10, ToInt64(h));

  // Check that the side effect of the previous expression is
  // persistent.
  h = Dart_EvaluateExpr(p, NewString("_factor"));
  EXPECT_VALID(h);
  EXPECT(Dart_IsInteger(h));
  EXPECT_EQ(10, ToInt64(h));

  breakpoint_hit = true;
  breakpoint_hit_counter++;
}


TEST_CASE(Debug_EvaluateExpr) {
  const char* kScriptChars =
      "import 'dart:math';               \n"
      "main() {                          \n"
      "  var p = new Point(3, 4);        \n"
      "  l = [1, 2, 3];        /*BP*/    \n"
      "  m = {'\"': 'quote' ,            \n"
      "       \"\t\": 'tab' };           \n"
      "  return p;                       \n"
      "}                                 \n"
      "var _factor = 2;                  \n"
      "var l;                            \n"
      "var m;                            \n"
      "class Point {                     \n"
      "  var x, y;                       \n"
      "  Point(this.x, this.y);          \n"
      "}                                 \n";

  LoadScript(kScriptChars);
  Dart_SetPausedEventHandler(&TestEvaluateHandler);


  Dart_Handle script_url = NewString(TestCase::url());
  intptr_t line_no = 4;
  Dart_Handle res = Dart_SetBreakpoint(script_url, line_no);
  EXPECT_VALID(res);

  breakpoint_hit = false;
  Dart_Handle point = Invoke("main");
  EXPECT_VALID(point);
  EXPECT(breakpoint_hit == true);

  Dart_Handle r =
      Dart_EvaluateExpr(point, NewString("_factor * sqrt(x*x + y*y)"));
  EXPECT_VALID(r);
  EXPECT(Dart_IsDouble(r));
  EXPECT_EQ(50.0, ToDouble(r));

  Dart_Handle closure =
      Dart_EvaluateExpr(point, NewString("() => _factor * sqrt(x*x + y*y))"));
  EXPECT_VALID(closure);
  EXPECT(Dart_IsClosure(closure));
  r = Dart_InvokeClosure(closure, 0, NULL);
  EXPECT_EQ(50.0, ToDouble(r));

  r = Dart_EvaluateExpr(point,
                        NewString("(() => _factor * sqrt(x*x + y*y))()"));
  EXPECT_VALID(r);
  EXPECT(Dart_IsDouble(r));
  EXPECT_EQ(50.0, ToDouble(r));

  Dart_Handle len = Dart_EvaluateExpr(point, NewString("l.length"));
  EXPECT_VALID(len);
  EXPECT(Dart_IsNumber(len));
  EXPECT_EQ(3, ToInt64(len));

  Dart_Handle point_type =
      Dart_GetType(script_lib, NewString("Point"), 0, NULL);
  EXPECT_VALID(point_type);
  EXPECT(Dart_IsType(point_type));
  Dart_Handle elem = Dart_EvaluateExpr(point_type, NewString("m['\"']"));
  EXPECT_VALID(elem);
  EXPECT(Dart_IsString(elem));
  EXPECT_STREQ("quote", ToCString(elem));

  elem = Dart_EvaluateExpr(point_type, NewString("m[\"\\t\"]"));
  EXPECT_VALID(elem);
  EXPECT(Dart_IsString(elem));
  EXPECT_STREQ("tab", ToCString(elem));

  res = Dart_EvaluateExpr(script_lib, NewString("l..add(11)..add(-5)"));
  EXPECT_VALID(res);
  // List l now has 5 elements.

  len = Dart_EvaluateExpr(script_lib, NewString("l.length + 1"));
  EXPECT_VALID(len);
  EXPECT(Dart_IsNumber(len));
  EXPECT_EQ(6, ToInt64(len));

  closure = Dart_EvaluateExpr(script_lib, NewString("(x) => l.length + x"));
  EXPECT_VALID(closure);
  EXPECT(Dart_IsClosure(closure));
  Dart_Handle args[1] = { Dart_NewInteger(1) };
  len = Dart_InvokeClosure(closure, 1, args);
  EXPECT_VALID(len);
  EXPECT(Dart_IsNumber(len));
  EXPECT_EQ(6, ToInt64(len));

  len = Dart_EvaluateExpr(script_lib, NewString("((x) => l.length + x)(1)"));
  EXPECT_VALID(len);
  EXPECT(Dart_IsNumber(len));
  EXPECT_EQ(6, ToInt64(len));

  Dart_Handle error =
      Dart_EvaluateExpr(script_lib, NewString("new NonexistingType()"));
  EXPECT(Dart_IsError(error));
}


static void EvaluateInActivationOfEvaluateHandler(Dart_IsolateId isolate_id,
                                                  Dart_Handle exception_object,
                                                  Dart_StackTrace trace) {
  breakpoint_hit_counter++;
  Dart_ActivationFrame top_frame = 0;
  Dart_Handle result = Dart_GetActivationFrame(trace, 0, &top_frame);
  EXPECT_VALID(result);

  result = Dart_ActivationFrameEvaluate(top_frame, NewString("p.r"));
  EXPECT_VALID(result);
  EXPECT_EQ(5.0, ToDouble(result));
}


TEST_CASE(Debug_EvaluateInActivationOfEvaluate) {
  // This library deliberately declares no top-level variables or methods. This
  // exercises a path in eval where a library may have no top-level anonymous
  // classes.
  const char* kScriptChars =
      "import 'dart:math';               \n"
      "class Point {                     \n"
      "  var x, y;                       \n"
      "  Point(this.x, this.y);          \n"
      "  get r => sqrt(x*x + y*y);       \n"
      "}                                 \n";
  LoadScript(kScriptChars);
  Dart_FinalizeLoading(false);

  Dart_SetExceptionThrownHandler(&EvaluateInActivationOfEvaluateHandler);
  Dart_SetExceptionPauseInfo(kPauseOnAllExceptions);
  breakpoint_hit_counter = 0;

  Dart_Handle result = Dart_EvaluateExpr(script_lib, NewString(
      "() { var p = new Point(3, 4); throw p; } ())"));
  EXPECT(Dart_IsError(result));
  EXPECT_EQ(1, breakpoint_hit_counter);
}


static void UnhandledExceptionHandler(Dart_IsolateId isolate_id,
                                      Dart_Handle exception_object,
                                      Dart_StackTrace trace) {
  breakpoint_hit_counter++;
}


// Check that the debugger is not called when an exception is
// caught by Dart code.
TEST_CASE(Debug_BreakOnUnhandledException) {
  const char* kScriptChars =
      "main() {                        \n"
      "  try {                         \n"
      "    throw 'broccoli';           \n"
      "  } catch (e) {                 \n"
      "    return 'carrots';           \n"
      "  }                             \n"
      "  return 'zucchini';            \n"
      "}                               \n";

  LoadScript(kScriptChars);
  Dart_FinalizeLoading(false);
  Dart_SetExceptionThrownHandler(&UnhandledExceptionHandler);
  breakpoint_hit_counter = 0;

  // Check that the debugger is not called since the exception
  // is handled.
  Dart_SetExceptionPauseInfo(kPauseOnUnhandledExceptions);
  Dart_Handle res = Invoke("main");
  EXPECT_VALID(res);
  EXPECT(Dart_IsString(res));
  EXPECT_STREQ("carrots", ToCString(res));
  EXPECT_EQ(0, breakpoint_hit_counter);

  // Check that the debugger is called when "break on all
  // exceptions" is turned on.
  Dart_SetExceptionPauseInfo(kPauseOnAllExceptions);
  Dart_Handle res2 = Invoke("main");
  EXPECT_VALID(res2);
  EXPECT(Dart_IsString(res2));
  EXPECT_STREQ("carrots", ToCString(res2));
  EXPECT_EQ(1, breakpoint_hit_counter);
}


TEST_CASE(Debug_GetClosureInfo) {
  const char* kScriptChars =
      "void foo() { return 43; } \n"
      "                          \n"
      "main() {                  \n"
      "  return foo;             \n"
      "}                         \n";

  LoadScript(kScriptChars);
  Dart_Handle clo = Invoke("main");
  EXPECT_VALID(clo);
  EXPECT(Dart_IsClosure(clo));
  Dart_Handle name, sig;
  Dart_CodeLocation loc;
  loc.script_url = Dart_Null();
  loc.library_id = -1;
  loc.token_pos = -1;
  Dart_Handle res = Dart_GetClosureInfo(clo, &name, &sig, &loc);
  EXPECT_VALID(res);
  EXPECT_TRUE(res);
  EXPECT_VALID(name);
  EXPECT(Dart_IsString(name));
  EXPECT_STREQ("foo", ToCString(name));
  EXPECT(Dart_IsString(sig));
  EXPECT_STREQ("() => void", ToCString(sig));
  EXPECT(Dart_IsString(loc.script_url));
  EXPECT_STREQ("test-lib", ToCString(loc.script_url));
  EXPECT_EQ(0, loc.token_pos);
  EXPECT(loc.library_id > 0);
}


TEST_CASE(Debug_GetSupertype) {
  const char* kScriptChars =
      "class Test {\n"
      "}\n"
      "class Test1 extends Test {\n"
      "}\n"
      "class Test2<T> {\n"
      "}\n"
      "class Test3 extends Test2<int> {\n"
      "}\n"
      "class Test4<A, B> extends Test2<A> {\n"
      "}\n"
      "class Test5<A, B, C> extends Test4<A, B> {\n"
      "}\n"
      "var s = new Set();\n"
      "var l = new List();\n"
      "int main() {\n"
      "}\n";

  Isolate* isolate = Isolate::Current();
  LoadScript(kScriptChars);
  ASSERT(script_lib != NULL);
  ASSERT(Dart_IsLibrary(script_lib));
  Dart_Handle core_lib = Dart_LookupLibrary(NewString("dart:core"));

  Dart_Handle Test_name = Dart_NewStringFromCString("Test");
  Dart_Handle Test1_name = Dart_NewStringFromCString("Test1");
  Dart_Handle Test2_name = Dart_NewStringFromCString("Test2");
  Dart_Handle Test3_name = Dart_NewStringFromCString("Test3");
  Dart_Handle Test4_name = Dart_NewStringFromCString("Test4");
  Dart_Handle Test5_name = Dart_NewStringFromCString("Test5");
  Dart_Handle object_name = Dart_NewStringFromCString("Object");
  Dart_Handle int_name = Dart_NewStringFromCString("int");
  Dart_Handle set_name = Dart_NewStringFromCString("Set");
  Dart_Handle iterable_name = Dart_NewStringFromCString("IterableBase");
  Dart_Handle list_name = Dart_NewStringFromCString("List");

  Dart_Handle object_type = Dart_GetType(core_lib, object_name, 0, NULL);
  Dart_Handle int_type = Dart_GetType(core_lib, int_name, 0, NULL);
  EXPECT_VALID(int_type);
  Dart_Handle Test_type = Dart_GetType(script_lib, Test_name, 0, NULL);
  Dart_Handle Test1_type = Dart_GetType(script_lib, Test1_name, 0, NULL);
  Dart_Handle type_args = Dart_NewList(1);
  Dart_ListSetAt(type_args, 0, int_type);
  Dart_Handle Test2_int_type = Dart_GetType(script_lib,
                                            Test2_name,
                                            1,
                                            &type_args);
  Dart_Handle Test3_type = Dart_GetType(script_lib, Test3_name, 0, NULL);
  type_args = Dart_NewList(2);
  Dart_ListSetAt(type_args, 0, int_type);
  Dart_ListSetAt(type_args, 1, Test_type);
  Dart_Handle Test4_int_type = Dart_GetType(script_lib,
                                            Test4_name,
                                            2,
                                            &type_args);
  type_args = Dart_NewList(3);
  Dart_ListSetAt(type_args, 0, int_type);
  Dart_ListSetAt(type_args, 1, Test_type);
  Dart_ListSetAt(type_args, 2, int_type);
  Dart_Handle Test5_int_type = Dart_GetType(script_lib,
                                            Test5_name,
                                            3,
                                            &type_args);
  {
    Dart_Handle super_type = Dart_GetSupertype(object_type);
    EXPECT(super_type == Dart_Null());
  }
  {
    Dart_Handle super_type = Dart_GetSupertype(Test1_type);
    const Type& expected_type = Api::UnwrapTypeHandle(isolate, Test_type);
    const Type& actual_type = Api::UnwrapTypeHandle(isolate, super_type);
    EXPECT(expected_type.raw() == actual_type.raw());
  }
  {
    Dart_Handle super_type = Dart_GetSupertype(Test3_type);
    const Type& expected_type = Api::UnwrapTypeHandle(isolate, Test2_int_type);
    const Type& actual_type = Api::UnwrapTypeHandle(isolate, super_type);
    EXPECT(expected_type.raw() == actual_type.raw());
  }
  {
    Dart_Handle super_type = Dart_GetSupertype(Test4_int_type);
    const Type& expected_type = Api::UnwrapTypeHandle(isolate, Test2_int_type);
    const Type& actual_type = Api::UnwrapTypeHandle(isolate, super_type);
    EXPECT(expected_type.raw() == actual_type.raw());
  }
  {
    Dart_Handle super_type = Dart_GetSupertype(Test5_int_type);
    const Type& expected_type = Api::UnwrapTypeHandle(isolate, Test4_int_type);
    const Type& actual_type = Api::UnwrapTypeHandle(isolate, super_type);
    EXPECT(expected_type.raw() == actual_type.raw());
  }
  {
    Dart_Handle set_type = Dart_GetType(core_lib, set_name, 0, NULL);
    Dart_Handle super_type = Dart_GetSupertype(set_type);
    Dart_Handle iterable_type = Dart_GetType(core_lib, iterable_name, 0, NULL);
    const Type& expected_type = Api::UnwrapTypeHandle(isolate, iterable_type);
    const Type& actual_type = Api::UnwrapTypeHandle(isolate, super_type);
    EXPECT(expected_type.raw() == actual_type.raw());
  }
  {
    Dart_Handle list_type = Dart_GetType(core_lib, list_name, 0, NULL);
    Dart_Handle super_type = Dart_GetSupertype(list_type);
    EXPECT(!Dart_IsError(super_type));
    super_type = Dart_GetSupertype(super_type);
    EXPECT(!Dart_IsError(super_type));
    EXPECT(super_type == Dart_Null());
  }
}


TEST_CASE(Debug_ListSuperType) {
  const char* kScriptChars =
      "List testMain() {"
      "  List a = new List();"
      "  a.add(10);"
      "  a.add(20);"
      "  a.add(30);"
      "  return a;"
      "}"
      ""
      "List immutable() {"
      "  return const [0, 1, 2];"
      "}";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns an object of type List.
  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);

  // First ensure that the returned object is a list.
  Dart_Handle list_access_test_obj = result;
  EXPECT(Dart_IsList(list_access_test_obj));

  Dart_Handle list_type = Dart_InstanceGetType(list_access_test_obj);
  Dart_Handle super_type = Dart_GetSupertype(list_type);
  EXPECT(!Dart_IsError(super_type));
  super_type = Dart_GetSupertype(super_type);
  EXPECT(!Dart_IsError(super_type));
  EXPECT(super_type == Dart_Null());
}

TEST_CASE(Debug_ScriptGetTokenInfo_Basic) {
  const char* kScriptChars =
      "var foo;\n"
      "\n"
      "main() {\n"
      "}";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  intptr_t libId = -1;
  EXPECT_VALID(Dart_LibraryId(lib, &libId));
  Dart_Handle scriptUrl = NewString(TestCase::url());
  Dart_Handle tokens = Dart_ScriptGetTokenInfo(libId, scriptUrl);
  EXPECT_VALID(tokens);

  Dart_Handle tokens_string = Dart_ToString(tokens);
  EXPECT_VALID(tokens_string);
  const char* tokens_cstr = "";
  EXPECT_VALID(Dart_StringToCString(tokens_string, &tokens_cstr));
  EXPECT_STREQ(
      "[null, 1, 0, 1, 1, 5, 2, 8,"
      " null, 3, 5, 1, 6, 5, 7, 6, 8, 8,"
      " null, 4, 10, 1]",
      tokens_cstr);
}

TEST_CASE(Debug_ScriptGetTokenInfo_MultiLineInterpolation) {
  const char* kScriptChars =
      "var foo = 'hello world';\n"
      "\n"
      "void test() {\n"
      "  return '''\n"
      "foo=$foo"
      "''';\n"
      "}\n"
      "\n"
      "main() {\n"
      "}";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  intptr_t libId = -1;
  EXPECT_VALID(Dart_LibraryId(lib, &libId));
  Dart_Handle scriptUrl = NewString(TestCase::url());
  Dart_Handle tokens = Dart_ScriptGetTokenInfo(libId, scriptUrl);
  EXPECT_VALID(tokens);

  Dart_Handle tokens_string = Dart_ToString(tokens);
  EXPECT_VALID(tokens_string);
  const char* tokens_cstr = "";
  EXPECT_VALID(Dart_StringToCString(tokens_string, &tokens_cstr));
  EXPECT_STREQ(
      "[null, 1, 0, 1, 1, 5, 2, 9, 3, 11, 4, 24,"
      " null, 3, 7, 1, 8, 6, 9, 10, 10, 11, 11, 13,"
      " null, 4, 13, 3, 14, 10,"
      " null, 5, 17, 5, 18, 9, 19, 12,"
      " null, 6, 21, 1,"
      " null, 8, 24, 1, 25, 5, 26, 6, 27, 8,"
      " null, 9, 29, 1]",
      tokens_cstr);
}

}  // namespace dart
