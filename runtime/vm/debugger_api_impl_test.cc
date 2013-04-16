// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_debugger_api.h"
#include "platform/assert.h"
#include "vm/dart_api_impl.h"
#include "vm/thread.h"
#include "vm/unit_test.h"

namespace dart {

// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

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
  OS::SNPrint(info_str, sizeof(info_str), "function %s (%s:%"Pd")",
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
  Dart_Handle res;
  res = Dart_ActivationFrameInfo(frame, &func_name, NULL, NULL, NULL);
  EXPECT_TRUE(res);
  EXPECT(Dart_IsString(func_name));
  const char* func_name_chars;
  Dart_StringToCString(func_name, &func_name_chars);
  if (expected_name != NULL) {
    EXPECT_SUBSTRING(expected_name, func_name_chars);
  }

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
  for (int i = 0; i < trace_len; i++) {
    Dart_ActivationFrame frame;
    res = Dart_GetActivationFrame(trace, i, &frame);
    EXPECT_TRUE(res);
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


void TestStepOutHandler(Dart_IsolateId isolate_id,
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
  int64_t int_value = 0;
  Dart_IntegerToInt64(retval, &int_value);
  EXPECT_EQ(2, int_value);
  EXPECT(breakpoint_hit == true);
}


void TestStepIntoHandler(Dart_IsolateId isolate_id,
                         const Dart_CodeLocation& location) {
  Dart_StackTrace trace;
  Dart_GetStackTrace(&trace);
  const char* expected_bpts[] = {
      "main",
        "foo",
          "f1",
        "foo",
          "X.X.",
        "foo",
          "X.kvmk",
            "f2",
          "X.kvmk",
        "foo",
      "main"
  };
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

  // Set a breakpoint in function f1, then repeatedly step out until
  // we get to main. We should see one breakpoint each in f1,
  // foo, main, but not in f2.
  SetBreakpointAtEntry("", "main");

  breakpoint_hit = false;
  breakpoint_hit_counter = 0;
  Dart_Handle retval = Invoke("main");
  EXPECT_VALID(retval);
  EXPECT(Dart_IsInteger(retval));
  int64_t int_value = 0;
  Dart_IntegerToInt64(retval, &int_value);
  EXPECT_EQ(7, int_value);
  EXPECT(breakpoint_hit == true);
}


static void StepIntoHandler(Dart_IsolateId isolate_id,
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
  int64_t int_value = 0;
  Dart_IntegerToInt64(retval, &int_value);
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
  int64_t int_value = 0;
  Dart_IntegerToInt64(retval, &int_value);
  EXPECT_EQ(2 * 99, int_value);
  EXPECT(breakpoint_hit == true);
}


void TestSingleStepHandler(Dart_IsolateId isolate_id,
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
  int64_t int_value = 0;
  Dart_IntegerToInt64(retval, &int_value);
  EXPECT_EQ(442, int_value);
  EXPECT_EQ(2, breakpoint_hit_counter);
}


static void ExprClosureBreakpointHandler(Dart_IsolateId isolate_id,
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
  int64_t int_value = 0;
  Dart_IntegerToInt64(retval, &int_value);
  EXPECT_EQ(30, int_value);
  EXPECT_EQ(1, breakpoint_hit_counter);
}


static intptr_t bp_id_to_be_deleted;

static void DeleteBreakpointHandler(Dart_IsolateId isolate_id,
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
    Dart_Handle res = Dart_RemoveBreakpoint(bp_id_to_be_deleted);
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
  int64_t bp_id = 0;
  Dart_IntegerToInt64(res, &bp_id);

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
  int64_t int_value = 0;
  Dart_IntegerToInt64(triple_six, &int_value);
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
  Dart_Handle class_A = Dart_GetSuperclass(class_B);
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


TEST_CASE(Debug_LookupSourceLine) {
  const char* kScriptChars =
  /*1*/  "class A {                 \n"
  /*2*/  "  static void foo() {     \n"
  /*3*/  "    moo('good news');     \n"
  /*4*/  "  }                       \n"
  /*5*/  "}                         \n"
  /*6*/  "                          \n"
  /*7*/  "void main() {             \n"
  /*8*/  "  A.foo();                \n"
  /*9*/  "}                         \n"
  /*10*/ "                          \n";

  LoadScript(kScriptChars);

  const Library& test_lib =
      Library::CheckedHandle(Api::UnwrapHandle(script_lib));
  const String& script_url = String::Handle(String::New(TestCase::url()));
  Function& func = Function::Handle();

  for (int line = 7; line <= 9; line++) {
    func = test_lib.LookupFunctionInSource(script_url, line);
    EXPECT(!func.IsNull());
    EXPECT_STREQ("main", String::Handle(func.name()).ToCString());
  }

  for (int line = 2; line <= 4; line++) {
    func = test_lib.LookupFunctionInSource(script_url, 3);
    EXPECT(!func.IsNull());
    EXPECT_STREQ("foo", String::Handle(func.name()).ToCString());
  }

  // The VM generates an implicit constructor for class A and
  // locates it at the token position of the keyword 'class'.
  func = test_lib.LookupFunctionInSource(script_url, 1);
  EXPECT(!func.IsNull());
  EXPECT_STREQ("A.", String::Handle(func.name()).ToCString());

  func = test_lib.LookupFunctionInSource(script_url, 6);
  EXPECT(func.IsNull());
  func = test_lib.LookupFunctionInSource(script_url, 10);
  EXPECT(func.IsNull());

  Dart_Handle libs = Dart_GetLibraryIds();
  EXPECT(Dart_IsList(libs));
  intptr_t num_libs;
  Dart_ListLength(libs, &num_libs);
  EXPECT(num_libs > 0);
  for (int i = 0; i < num_libs; i++) {
    Dart_Handle lib_id = Dart_ListGetAt(libs, i);
    EXPECT(Dart_IsInteger(lib_id));
    int64_t id = 0;
    Dart_IntegerToInt64(lib_id, &id);
    Dart_Handle lib_url = Dart_GetLibraryURL(id);
    char const* chars;
    Dart_StringToCString(lib_url, &chars);
    OS::Print("Lib %d: %s\n", i, chars);

    Dart_Handle scripts = Dart_GetScriptURLs(lib_url);
    EXPECT(Dart_IsList(scripts));
    intptr_t num_scripts;
    Dart_ListLength(scripts, &num_scripts);
    EXPECT(num_scripts >= 0);
    for (int i = 0; i < num_scripts; i++) {
      Dart_Handle script_url = Dart_ListGetAt(scripts, i);
      char const* chars;
      Dart_StringToCString(script_url, &chars);
      OS::Print("  script %d: '%s'\n", i + 1, chars);
    }
  }

  Dart_Handle lib_url = NewString(TestCase::url());
  Dart_Handle source = Dart_ScriptGetSource((num_libs - 1), lib_url);
  EXPECT(Dart_IsString(source));
  char const* source_chars;
  Dart_StringToCString(source, &source_chars);
  OS::Print("\n=== source: ===\n%s", source_chars);
  EXPECT_STREQ(kScriptChars, source_chars);
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
  Dart_ExitScope();
  Dart_ShutdownIsolate();
  EXPECT(verify_callback == 0x5);  // Only created and shutdown events.
}


static Monitor* sync = NULL;
static bool isolate_interrupted = false;
static Dart_IsolateId interrupt_isolate_id = ILLEGAL_ISOLATE_ID;
static volatile bool continue_isolate_loop = true;


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
      ml.Notify();
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
                                                   int arg_count) {
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
                                              &InterruptNativeResolver);
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
    while (!isolate_interrupted) {
      ml.Wait();
    }
  }
  EXPECT(isolate_interrupted);

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
  int64_t int_value = 0;
  Dart_IntegerToInt64(retval, &int_value);
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

#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64).

}  // namespace dart
