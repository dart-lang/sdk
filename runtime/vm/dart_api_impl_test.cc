// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_api_impl.h"
#include "bin/builtin.h"
#include "include/dart_api.h"
#include "include/dart_mirrors_api.h"
#include "include/dart_native_api.h"
#include "include/dart_tools_api.h"
#include "platform/assert.h"
#include "platform/text_buffer.h"
#include "platform/utils.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart_api_state.h"
#include "vm/lockers.h"
#include "vm/timeline.h"
#include "vm/unit_test.h"
#include "vm/verifier.h"

namespace dart {

DECLARE_FLAG(bool, verify_acquired_data);
DECLARE_FLAG(bool, ignore_patch_signature_mismatch);
DECLARE_FLAG(bool, support_externalizable_strings);

#ifndef PRODUCT

TEST_CASE(ErrorHandleBasics) {
  const char* kScriptChars =
      "void testMain() {\n"
      "  throw new Exception(\"bad news\");\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  Dart_Handle instance = Dart_True();
  Dart_Handle error = Api::NewError("myerror");
  Dart_Handle exception = Dart_Invoke(lib, NewString("testMain"), 0, NULL);

  EXPECT_VALID(instance);
  EXPECT(Dart_IsError(error));
  EXPECT(Dart_IsError(exception));

  EXPECT(!Dart_ErrorHasException(instance));
  EXPECT(!Dart_ErrorHasException(error));
  EXPECT(Dart_ErrorHasException(exception));

  EXPECT_STREQ("", Dart_GetError(instance));
  EXPECT_STREQ("myerror", Dart_GetError(error));
  EXPECT_STREQ(
      "Unhandled exception:\n"
      "Exception: bad news\n"
      "#0      testMain (test-lib:2:3)",
      Dart_GetError(exception));

  EXPECT(Dart_IsError(Dart_ErrorGetException(instance)));
  EXPECT(Dart_IsError(Dart_ErrorGetException(error)));
  EXPECT_VALID(Dart_ErrorGetException(exception));

  EXPECT(Dart_IsError(Dart_ErrorGetStackTrace(instance)));
  EXPECT(Dart_IsError(Dart_ErrorGetStackTrace(error)));
  EXPECT_VALID(Dart_ErrorGetStackTrace(exception));
}

TEST_CASE(StackTraceInfo) {
  const char* kScriptChars =
      "bar() => throw new Error();\n"
      "foo() => bar();\n"
      "testMain() => foo();\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle error = Dart_Invoke(lib, NewString("testMain"), 0, NULL);

  EXPECT(Dart_IsError(error));

  Dart_StackTrace stacktrace;
  Dart_Handle result = Dart_GetStackTraceFromError(error, &stacktrace);
  EXPECT_VALID(result);

  intptr_t frame_count = 0;
  result = Dart_StackTraceLength(stacktrace, &frame_count);
  EXPECT_VALID(result);
  EXPECT_EQ(3, frame_count);

  Dart_Handle function_name;
  Dart_Handle script_url;
  intptr_t line_number = 0;
  intptr_t column_number = 0;
  const char* cstr = "";

  Dart_ActivationFrame frame;
  result = Dart_GetActivationFrame(stacktrace, 0, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("bar", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ("test-lib", cstr);
  EXPECT_EQ(1, line_number);
  EXPECT_EQ(10, column_number);

  result = Dart_GetActivationFrame(stacktrace, 1, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("foo", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ("test-lib", cstr);
  EXPECT_EQ(2, line_number);
  EXPECT_EQ(10, column_number);

  result = Dart_GetActivationFrame(stacktrace, 2, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("testMain", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ("test-lib", cstr);
  EXPECT_EQ(3, line_number);
  EXPECT_EQ(15, column_number);

  // Out-of-bounds frames.
  result = Dart_GetActivationFrame(stacktrace, frame_count, &frame);
  EXPECT(Dart_IsError(result));
  result = Dart_GetActivationFrame(stacktrace, -1, &frame);
  EXPECT(Dart_IsError(result));
}

TEST_CASE(DeepStackTraceInfo) {
  const char* kScriptChars =
      "foo(n) => n == 1 ? throw new Error() : foo(n-1);\n"
      "testMain() => foo(50);\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle error = Dart_Invoke(lib, NewString("testMain"), 0, NULL);

  EXPECT(Dart_IsError(error));

  Dart_StackTrace stacktrace;
  Dart_Handle result = Dart_GetStackTraceFromError(error, &stacktrace);
  EXPECT_VALID(result);

  intptr_t frame_count = 0;
  result = Dart_StackTraceLength(stacktrace, &frame_count);
  EXPECT_VALID(result);
  EXPECT_EQ(51, frame_count);
  // Test something bigger than the preallocated size to verify nothing was
  // truncated.
  EXPECT(51 > StackTrace::kPreallocatedStackdepth);

  Dart_Handle function_name;
  Dart_Handle script_url;
  intptr_t line_number = 0;
  intptr_t column_number = 0;
  const char* cstr = "";

  // Top frame at positioned at throw.
  Dart_ActivationFrame frame;
  result = Dart_GetActivationFrame(stacktrace, 0, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("foo", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ("test-lib", cstr);
  EXPECT_EQ(1, line_number);
  EXPECT_EQ(20, column_number);

  // Middle frames positioned at the recursive call.
  for (intptr_t frame_index = 1; frame_index < (frame_count - 1);
       frame_index++) {
    result = Dart_GetActivationFrame(stacktrace, frame_index, &frame);
    EXPECT_VALID(result);
    result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                      &line_number, &column_number);
    EXPECT_VALID(result);
    Dart_StringToCString(function_name, &cstr);
    EXPECT_STREQ("foo", cstr);
    Dart_StringToCString(script_url, &cstr);
    EXPECT_STREQ("test-lib", cstr);
    EXPECT_EQ(1, line_number);
    EXPECT_EQ(40, column_number);
  }

  // Bottom frame positioned at testMain().
  result = Dart_GetActivationFrame(stacktrace, frame_count - 1, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("testMain", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ("test-lib", cstr);
  EXPECT_EQ(2, line_number);
  EXPECT_EQ(15, column_number);

  // Out-of-bounds frames.
  result = Dart_GetActivationFrame(stacktrace, frame_count, &frame);
  EXPECT(Dart_IsError(result));
  result = Dart_GetActivationFrame(stacktrace, -1, &frame);
  EXPECT(Dart_IsError(result));
}

TEST_CASE(StackOverflowStackTraceInfo) {
  const char* kScriptChars =
      "class C {\n"
      "  static foo() => foo();\n"
      "}\n"
      "testMain() => C.foo();\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle error = Dart_Invoke(lib, NewString("testMain"), 0, NULL);

  EXPECT(Dart_IsError(error));

  Dart_StackTrace stacktrace;
  Dart_Handle result = Dart_GetStackTraceFromError(error, &stacktrace);
  EXPECT_VALID(result);

  intptr_t frame_count = 0;
  result = Dart_StackTraceLength(stacktrace, &frame_count);
  EXPECT_VALID(result);
  EXPECT_EQ(StackTrace::kPreallocatedStackdepth - 1, frame_count);

  Dart_Handle function_name;
  Dart_Handle script_url;
  intptr_t line_number = 0;
  intptr_t column_number = 0;
  const char* cstr = "";

  // Top frame at recursive call.
  Dart_ActivationFrame frame;
  result = Dart_GetActivationFrame(stacktrace, 0, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("C.foo", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ("test-lib", cstr);
  EXPECT_EQ(2, line_number);
  EXPECT_EQ(13, column_number);

  // Out-of-bounds frames.
  result = Dart_GetActivationFrame(stacktrace, frame_count, &frame);
  EXPECT(Dart_IsError(result));
  result = Dart_GetActivationFrame(stacktrace, -1, &frame);
  EXPECT(Dart_IsError(result));
}

TEST_CASE(OutOfMemoryStackTraceInfo) {
  const char* kScriptChars =
      "var number_of_ints = 134000000;\n"
      "testMain() {\n"
      "  new List<int>(number_of_ints)\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle error = Dart_Invoke(lib, NewString("testMain"), 0, NULL);

  EXPECT(Dart_IsError(error));

  Dart_StackTrace stacktrace;
  Dart_Handle result = Dart_GetStackTraceFromError(error, &stacktrace);
  EXPECT(Dart_IsError(result));  // No StackTrace for OutOfMemory.
}

void CurrentStackTraceNative(Dart_NativeArguments args) {
  Dart_EnterScope();

  Dart_StackTrace stacktrace;
  Dart_Handle result = Dart_GetStackTrace(&stacktrace);
  EXPECT_VALID(result);

  intptr_t frame_count = 0;
  result = Dart_StackTraceLength(stacktrace, &frame_count);
  EXPECT_VALID(result);
  EXPECT_EQ(52, frame_count);
  // Test something bigger than the preallocated size to verify nothing was
  // truncated.
  EXPECT(52 > StackTrace::kPreallocatedStackdepth);

  Dart_Handle function_name;
  Dart_Handle script_url;
  intptr_t line_number = 0;
  intptr_t column_number = 0;
  const char* cstr = "";

  // Top frame is inspectStack().
  Dart_ActivationFrame frame;
  result = Dart_GetActivationFrame(stacktrace, 0, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("inspectStack", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ("test-lib", cstr);
  EXPECT_EQ(1, line_number);
  EXPECT_EQ(47, column_number);

  // Second frame is foo() positioned at call to inspectStack().
  result = Dart_GetActivationFrame(stacktrace, 1, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("foo", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ("test-lib", cstr);
  EXPECT_EQ(2, line_number);
  EXPECT_EQ(20, column_number);

  // Middle frames positioned at the recursive call.
  for (intptr_t frame_index = 2; frame_index < (frame_count - 1);
       frame_index++) {
    result = Dart_GetActivationFrame(stacktrace, frame_index, &frame);
    EXPECT_VALID(result);
    result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                      &line_number, &column_number);
    EXPECT_VALID(result);
    Dart_StringToCString(function_name, &cstr);
    EXPECT_STREQ("foo", cstr);
    Dart_StringToCString(script_url, &cstr);
    EXPECT_STREQ("test-lib", cstr);
    EXPECT_EQ(2, line_number);
    EXPECT_EQ(37, column_number);
  }

  // Bottom frame positioned at testMain().
  result = Dart_GetActivationFrame(stacktrace, frame_count - 1, &frame);
  EXPECT_VALID(result);
  result = Dart_ActivationFrameInfo(frame, &function_name, &script_url,
                                    &line_number, &column_number);
  EXPECT_VALID(result);
  Dart_StringToCString(function_name, &cstr);
  EXPECT_STREQ("testMain", cstr);
  Dart_StringToCString(script_url, &cstr);
  EXPECT_STREQ("test-lib", cstr);
  EXPECT_EQ(3, line_number);
  EXPECT_EQ(15, column_number);

  // Out-of-bounds frames.
  result = Dart_GetActivationFrame(stacktrace, frame_count, &frame);
  EXPECT(Dart_IsError(result));
  result = Dart_GetActivationFrame(stacktrace, -1, &frame);
  EXPECT(Dart_IsError(result));

  Dart_SetReturnValue(args, Dart_NewInteger(42));
  Dart_ExitScope();
}

static Dart_NativeFunction CurrentStackTraceNativeLookup(
    Dart_Handle name,
    int argument_count,
    bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  return reinterpret_cast<Dart_NativeFunction>(&CurrentStackTraceNative);
}

TEST_CASE(CurrentStackTraceInfo) {
  const char* kScriptChars =
      "inspectStack() native 'CurrentStackTraceNatve';\n"
      "foo(n) => n == 1 ? inspectStack() : foo(n-1);\n"
      "testMain() => foo(50);\n";

  Dart_Handle lib =
      TestCase::LoadTestScript(kScriptChars, &CurrentStackTraceNativeLookup);
  Dart_Handle result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(42, value);
}

#endif  // !PRODUCT

TEST_CASE(ErrorHandleTypes) {
  const String& compile_message = String::Handle(String::New("CompileError"));
  const String& fatal_message = String::Handle(String::New("FatalError"));

  Dart_Handle not_error = NewString("NotError");
  Dart_Handle api_error = Api::NewError("Api%s", "Error");
  Dart_Handle exception_error =
      Dart_NewUnhandledExceptionError(NewString("ExceptionError"));
  Dart_Handle compile_error =
      Api::NewHandle(thread, LanguageError::New(compile_message));
  Dart_Handle fatal_error =
      Api::NewHandle(thread, UnwindError::New(fatal_message));

  EXPECT_VALID(not_error);
  EXPECT(Dart_IsError(api_error));
  EXPECT(Dart_IsError(exception_error));
  EXPECT(Dart_IsError(compile_error));
  EXPECT(Dart_IsError(fatal_error));

  EXPECT(!Dart_IsApiError(not_error));
  EXPECT(Dart_IsApiError(api_error));
  EXPECT(!Dart_IsApiError(exception_error));
  EXPECT(!Dart_IsApiError(compile_error));
  EXPECT(!Dart_IsApiError(fatal_error));

  EXPECT(!Dart_IsUnhandledExceptionError(not_error));
  EXPECT(!Dart_IsUnhandledExceptionError(api_error));
  EXPECT(Dart_IsUnhandledExceptionError(exception_error));
  EXPECT(!Dart_IsUnhandledExceptionError(compile_error));
  EXPECT(!Dart_IsUnhandledExceptionError(fatal_error));

  EXPECT(!Dart_IsCompilationError(not_error));
  EXPECT(!Dart_IsCompilationError(api_error));
  EXPECT(!Dart_IsCompilationError(exception_error));
  EXPECT(Dart_IsCompilationError(compile_error));
  EXPECT(!Dart_IsCompilationError(fatal_error));

  EXPECT(!Dart_IsFatalError(not_error));
  EXPECT(!Dart_IsFatalError(api_error));
  EXPECT(!Dart_IsFatalError(exception_error));
  EXPECT(!Dart_IsFatalError(compile_error));
  EXPECT(Dart_IsFatalError(fatal_error));

  EXPECT_STREQ("", Dart_GetError(not_error));
  EXPECT_STREQ("ApiError", Dart_GetError(api_error));
  EXPECT_SUBSTRING("Unhandled exception:\nExceptionError",
                   Dart_GetError(exception_error));
  EXPECT_STREQ("CompileError", Dart_GetError(compile_error));
  EXPECT_STREQ("FatalError", Dart_GetError(fatal_error));
}

TEST_CASE(UnhandleExceptionError) {
  const char* exception_cstr = "";

  // Test with an API Error.
  const char* kApiError = "Api Error Exception Test.";
  Dart_Handle api_error = Api::NewHandle(
      thread, ApiError::New(String::Handle(String::New(kApiError))));
  Dart_Handle exception_error = Dart_NewUnhandledExceptionError(api_error);
  EXPECT(!Dart_IsApiError(exception_error));
  EXPECT(Dart_IsUnhandledExceptionError(exception_error));
  EXPECT(Dart_IsString(Dart_ErrorGetException(exception_error)));
  EXPECT_VALID(Dart_StringToCString(Dart_ErrorGetException(exception_error),
                                    &exception_cstr));
  EXPECT_STREQ(kApiError, exception_cstr);

  // Test with a Compilation Error.
  const char* kCompileError = "CompileError Exception Test.";
  const String& compile_message = String::Handle(String::New(kCompileError));
  Dart_Handle compile_error =
      Api::NewHandle(thread, LanguageError::New(compile_message));
  exception_error = Dart_NewUnhandledExceptionError(compile_error);
  EXPECT(!Dart_IsApiError(exception_error));
  EXPECT(Dart_IsUnhandledExceptionError(exception_error));
  EXPECT(Dart_IsString(Dart_ErrorGetException(exception_error)));
  EXPECT_VALID(Dart_StringToCString(Dart_ErrorGetException(exception_error),
                                    &exception_cstr));
  EXPECT_STREQ(kCompileError, exception_cstr);

  // Test with a Fatal Error.
  const String& fatal_message =
      String::Handle(String::New("FatalError Exception Test."));
  Dart_Handle fatal_error =
      Api::NewHandle(thread, UnwindError::New(fatal_message));
  exception_error = Dart_NewUnhandledExceptionError(fatal_error);
  EXPECT(Dart_IsError(exception_error));
  EXPECT(!Dart_IsUnhandledExceptionError(exception_error));

  // Test with a Regular object.
  const char* kRegularString = "Regular String Exception Test.";
  Dart_Handle obj = Api::NewHandle(thread, String::New(kRegularString));
  exception_error = Dart_NewUnhandledExceptionError(obj);
  EXPECT(!Dart_IsApiError(exception_error));
  EXPECT(Dart_IsUnhandledExceptionError(exception_error));
  EXPECT(Dart_IsString(Dart_ErrorGetException(exception_error)));
  EXPECT_VALID(Dart_StringToCString(Dart_ErrorGetException(exception_error),
                                    &exception_cstr));
  EXPECT_STREQ(kRegularString, exception_cstr);
}

// Should we propagate the error via Dart_SetReturnValue?
static bool use_set_return = false;

// Should we propagate the error via Dart_ThrowException?
static bool use_throw_exception = false;

void PropagateErrorNative(Dart_NativeArguments args) {
  Dart_Handle closure = Dart_GetNativeArgument(args, 0);
  EXPECT(Dart_IsClosure(closure));
  Dart_Handle result = Dart_InvokeClosure(closure, 0, NULL);
  EXPECT(Dart_IsError(result));
  if (use_set_return) {
    Dart_SetReturnValue(args, result);
  } else if (use_throw_exception) {
    result = Dart_ThrowException(result);
    EXPECT_VALID(result);  // We do not expect to reach here.
    UNREACHABLE();
  } else {
    result = Dart_PropagateError(result);
    EXPECT_VALID(result);  // We do not expect to reach here.
    UNREACHABLE();
  }
}

static Dart_NativeFunction PropagateError_native_lookup(
    Dart_Handle name,
    int argument_count,
    bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  return reinterpret_cast<Dart_NativeFunction>(&PropagateErrorNative);
}

TEST_CASE(Dart_PropagateError) {
  const char* kScriptChars =
      "raiseCompileError() {\n"
      "  return missing_semicolon\n"
      "}\n"
      "\n"
      "void throwException() {\n"
      "  throw new Exception('myException');\n"
      "}\n"
      "\n"
      "void nativeFunc(closure) native 'Test_nativeFunc';\n"
      "\n"
      "void Func1() {\n"
      "  nativeFunc(() => raiseCompileError());\n"
      "}\n"
      "\n"
      "void Func2() {\n"
      "  nativeFunc(() => throwException());\n"
      "}\n";
  Dart_Handle lib =
      TestCase::LoadTestScript(kScriptChars, &PropagateError_native_lookup);
  Dart_Handle result;

  // Use Dart_PropagateError to propagate the error.
  use_throw_exception = false;
  use_set_return = false;

  result = Dart_Invoke(lib, NewString("Func1"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_SUBSTRING("semicolon expected", Dart_GetError(result));

  result = Dart_Invoke(lib, NewString("Func2"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("myException", Dart_GetError(result));

  // Use Dart_SetReturnValue to propagate the error.
  use_throw_exception = false;
  use_set_return = true;

  result = Dart_Invoke(lib, NewString("Func1"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_SUBSTRING("semicolon expected", Dart_GetError(result));

  result = Dart_Invoke(lib, NewString("Func2"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("myException", Dart_GetError(result));

  // Use Dart_ThrowException to propagate the error.
  use_throw_exception = true;
  use_set_return = false;

  result = Dart_Invoke(lib, NewString("Func1"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_SUBSTRING("semicolon expected", Dart_GetError(result));

  result = Dart_Invoke(lib, NewString("Func2"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("myException", Dart_GetError(result));
}

TEST_CASE(Dart_Error) {
  Dart_Handle error = Api::NewError("An %s", "error");
  EXPECT(Dart_IsError(error));
  EXPECT_STREQ("An error", Dart_GetError(error));
}

TEST_CASE(Null) {
  Dart_Handle null = Dart_Null();
  EXPECT_VALID(null);
  EXPECT(Dart_IsNull(null));

  Dart_Handle str = NewString("test");
  EXPECT_VALID(str);
  EXPECT(!Dart_IsNull(str));
}

TEST_CASE(EmptyString) {
  Dart_Handle empty = Dart_EmptyString();
  EXPECT_VALID(empty);
  EXPECT(!Dart_IsNull(empty));
}

TEST_CASE(IdentityEquals) {
  Dart_Handle five = Dart_NewInteger(5);
  Dart_Handle five_again = Dart_NewInteger(5);
  Dart_Handle mint = Dart_NewInteger(0xFFFFFFFF);
  Dart_Handle mint_again = Dart_NewInteger(0xFFFFFFFF);
  Dart_Handle abc = NewString("abc");
  Dart_Handle abc_again = NewString("abc");
  Dart_Handle xyz = NewString("xyz");
  Dart_Handle dart_core = NewString("dart:core");
  Dart_Handle dart_mirrors = NewString("dart:mirrors");

  // Same objects.
  EXPECT(Dart_IdentityEquals(five, five));
  EXPECT(Dart_IdentityEquals(mint, mint));
  EXPECT(Dart_IdentityEquals(abc, abc));
  EXPECT(Dart_IdentityEquals(xyz, xyz));

  // Equal objects with special spec rules.
  EXPECT(Dart_IdentityEquals(five, five_again));
  EXPECT(Dart_IdentityEquals(mint, mint_again));

  // Equal objects without special spec rules.
  EXPECT(!Dart_IdentityEquals(abc, abc_again));

  // Different objects.
  EXPECT(!Dart_IdentityEquals(five, mint));
  EXPECT(!Dart_IdentityEquals(abc, xyz));

  // Case where identical() is not the same as pointer equality.
  Dart_Handle nan1 = Dart_NewDouble(NAN);
  Dart_Handle nan2 = Dart_NewDouble(NAN);
  EXPECT(Dart_IdentityEquals(nan1, nan2));

  // Non-instance objects.
  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);
    Dart_Handle lib1 = Dart_LookupLibrary(dart_core);
    Dart_Handle lib2 = Dart_LookupLibrary(dart_mirrors);

    EXPECT(Dart_IdentityEquals(lib1, lib1));
    EXPECT(Dart_IdentityEquals(lib2, lib2));
    EXPECT(!Dart_IdentityEquals(lib1, lib2));

    // Mix instance and non-instance.
    EXPECT(!Dart_IdentityEquals(lib1, nan1));
    EXPECT(!Dart_IdentityEquals(nan1, lib1));
  }
}

TEST_CASE(IdentityHash) {
  Dart_Handle five = Dart_NewInteger(5);
  Dart_Handle five_again = Dart_NewInteger(5);
  Dart_Handle mint = Dart_NewInteger(0xFFFFFFFF);
  Dart_Handle mint_again = Dart_NewInteger(0xFFFFFFFF);
  Dart_Handle abc = NewString("abc");
  // Dart_Handle abc_again = NewString("abc");
  Dart_Handle xyz = NewString("xyz");
  Dart_Handle dart_core = NewString("dart:core");
  Dart_Handle dart_mirrors = NewString("dart:mirrors");

  // Same objects.
  EXPECT_EQ(Dart_IdentityHash(five), Dart_IdentityHash(five));
  EXPECT_EQ(Dart_IdentityHash(mint), Dart_IdentityHash(mint));
  EXPECT_EQ(Dart_IdentityHash(abc), Dart_IdentityHash(abc));
  EXPECT_EQ(Dart_IdentityHash(xyz), Dart_IdentityHash(xyz));

  // Equal objects with special spec rules.
  EXPECT_EQ(Dart_IdentityHash(five), Dart_IdentityHash(five_again));
  EXPECT_EQ(Dart_IdentityHash(mint), Dart_IdentityHash(mint_again));

  // Note abc and abc_again are not required to have equal identity hashes.

  // Case where identical() is not the same as pointer equality.
  Dart_Handle nan1 = Dart_NewDouble(NAN);
  Dart_Handle nan2 = Dart_NewDouble(NAN);
  EXPECT_EQ(Dart_IdentityHash(nan1), Dart_IdentityHash(nan2));

  // Non-instance objects.
  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);
    Dart_Handle lib1 = Dart_LookupLibrary(dart_core);
    Dart_Handle lib2 = Dart_LookupLibrary(dart_mirrors);

    EXPECT_EQ(Dart_IdentityHash(lib1), Dart_IdentityHash(lib1));
    EXPECT_EQ(Dart_IdentityHash(lib2), Dart_IdentityHash(lib2));
  }
}

TEST_CASE(ObjectEquals) {
  bool equal = false;
  Dart_Handle five = NewString("5");
  Dart_Handle five_again = NewString("5");
  Dart_Handle seven = NewString("7");

  // Same objects.
  EXPECT_VALID(Dart_ObjectEquals(five, five, &equal));
  EXPECT(equal);

  // Equal objects.
  EXPECT_VALID(Dart_ObjectEquals(five, five_again, &equal));
  EXPECT(equal);

  // Different objects.
  EXPECT_VALID(Dart_ObjectEquals(five, seven, &equal));
  EXPECT(!equal);

  // Case where identity is not equality.
  Dart_Handle nan = Dart_NewDouble(NAN);
  EXPECT_VALID(Dart_ObjectEquals(nan, nan, &equal));
  EXPECT(!equal);
}

TEST_CASE(InstanceValues) {
  EXPECT(Dart_IsInstance(NewString("test")));
  EXPECT(Dart_IsInstance(Dart_True()));

  // By convention, our Is*() functions exclude null.
  EXPECT(!Dart_IsInstance(Dart_Null()));
}

TEST_CASE(InstanceGetType) {
  Zone* zone = thread->zone();
  // Get the handle from a valid instance handle.
  Dart_Handle type = Dart_InstanceGetType(Dart_Null());
  EXPECT_VALID(type);
  EXPECT(Dart_IsType(type));
  const Type& null_type_obj = Api::UnwrapTypeHandle(zone, type);
  EXPECT(null_type_obj.raw() == Type::NullType());

  Dart_Handle instance = Dart_True();
  type = Dart_InstanceGetType(instance);
  EXPECT_VALID(type);
  EXPECT(Dart_IsType(type));
  const Type& bool_type_obj = Api::UnwrapTypeHandle(zone, type);
  EXPECT(bool_type_obj.raw() == Type::BoolType());

  Dart_Handle cls_name = Dart_TypeName(type);
  EXPECT_VALID(cls_name);
  const char* cls_name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(cls_name, &cls_name_cstr));
  EXPECT_STREQ("bool", cls_name_cstr);

  Dart_Handle qual_cls_name = Dart_QualifiedTypeName(type);
  EXPECT_VALID(qual_cls_name);
  const char* qual_cls_name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(qual_cls_name, &qual_cls_name_cstr));
  EXPECT_STREQ("Library:'dart:core' Class: bool", qual_cls_name_cstr);

  // Errors propagate.
  Dart_Handle error = Dart_NewApiError("MyError");
  Dart_Handle error_type = Dart_InstanceGetType(error);
  EXPECT_ERROR(error_type, "MyError");

  // Get the handle from a non-instance handle.
  Dart_Handle dart_core = NewString("dart:core");
  Dart_Handle obj = Dart_LookupLibrary(dart_core);
  Dart_Handle type_type = Dart_InstanceGetType(obj);
  EXPECT_ERROR(type_type,
               "Dart_InstanceGetType expects argument 'instance' to be of "
               "type Instance.");
}

TEST_CASE(BooleanValues) {
  Dart_Handle str = NewString("test");
  EXPECT(!Dart_IsBoolean(str));

  bool value = false;
  Dart_Handle result = Dart_BooleanValue(str, &value);
  EXPECT(Dart_IsError(result));

  Dart_Handle val1 = Dart_NewBoolean(true);
  EXPECT(Dart_IsBoolean(val1));

  result = Dart_BooleanValue(val1, &value);
  EXPECT_VALID(result);
  EXPECT(value);

  Dart_Handle val2 = Dart_NewBoolean(false);
  EXPECT(Dart_IsBoolean(val2));

  result = Dart_BooleanValue(val2, &value);
  EXPECT_VALID(result);
  EXPECT(!value);
}

TEST_CASE(BooleanConstants) {
  Dart_Handle true_handle = Dart_True();
  EXPECT_VALID(true_handle);
  EXPECT(Dart_IsBoolean(true_handle));

  bool value = false;
  Dart_Handle result = Dart_BooleanValue(true_handle, &value);
  EXPECT_VALID(result);
  EXPECT(value);

  Dart_Handle false_handle = Dart_False();
  EXPECT_VALID(false_handle);
  EXPECT(Dart_IsBoolean(false_handle));

  result = Dart_BooleanValue(false_handle, &value);
  EXPECT_VALID(result);
  EXPECT(!value);
}

TEST_CASE(DoubleValues) {
  const double kDoubleVal1 = 201.29;
  const double kDoubleVal2 = 101.19;
  Dart_Handle val1 = Dart_NewDouble(kDoubleVal1);
  EXPECT(Dart_IsDouble(val1));
  Dart_Handle val2 = Dart_NewDouble(kDoubleVal2);
  EXPECT(Dart_IsDouble(val2));
  double out1, out2;
  Dart_Handle result = Dart_DoubleValue(val1, &out1);
  EXPECT_VALID(result);
  EXPECT_EQ(kDoubleVal1, out1);
  result = Dart_DoubleValue(val2, &out2);
  EXPECT_VALID(result);
  EXPECT_EQ(kDoubleVal2, out2);
}

TEST_CASE(NumberValues) {
  // TODO(antonm): add various kinds of ints (smi, mint, bigint).
  const char* kScriptChars =
      "int getInt() { return 1; }\n"
      "double getDouble() { return 1.0; }\n"
      "bool getBool() { return false; }\n"
      "getNull() { return null; }\n";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Check int case.
  result = Dart_Invoke(lib, NewString("getInt"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsNumber(result));

  // Check double case.
  result = Dart_Invoke(lib, NewString("getDouble"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsNumber(result));

  // Check bool case.
  result = Dart_Invoke(lib, NewString("getBool"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNumber(result));

  // Check null case.
  result = Dart_Invoke(lib, NewString("getNull"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNumber(result));
}

TEST_CASE(IntegerValues) {
  const int64_t kIntegerVal1 = 100;
  const int64_t kIntegerVal2 = 0xffffffff;
  const char* kIntegerVal3 = "0x123456789123456789123456789";
  const uint64_t kIntegerVal4 = 0xffffffffffffffff;

  Dart_Handle val1 = Dart_NewInteger(kIntegerVal1);
  EXPECT(Dart_IsInteger(val1));
  bool fits = false;
  Dart_Handle result = Dart_IntegerFitsIntoInt64(val1, &fits);
  EXPECT_VALID(result);
  EXPECT(fits);

  Dart_Handle val2 = Dart_NewInteger(kIntegerVal2);
  EXPECT(Dart_IsInteger(val2));
  result = Dart_IntegerFitsIntoInt64(val2, &fits);
  EXPECT_VALID(result);
  EXPECT(fits);

  Dart_Handle val3 = Dart_NewIntegerFromHexCString(kIntegerVal3);
  EXPECT(Dart_IsInteger(val3));
  result = Dart_IntegerFitsIntoInt64(val3, &fits);
  EXPECT_VALID(result);
  EXPECT(!fits);

  int64_t out = 0;
  result = Dart_IntegerToInt64(val1, &out);
  EXPECT_VALID(result);
  EXPECT_EQ(kIntegerVal1, out);

  result = Dart_IntegerToInt64(val2, &out);
  EXPECT_VALID(result);
  EXPECT_EQ(kIntegerVal2, out);

  const char* chars = NULL;
  result = Dart_IntegerToHexCString(val3, &chars);
  EXPECT_VALID(result);
  EXPECT(!strcmp(kIntegerVal3, chars));

  Dart_Handle val4 = Dart_NewIntegerFromUint64(kIntegerVal4);
  EXPECT_VALID(val4);
  uint64_t out4 = 0;
  result = Dart_IntegerToUint64(val4, &out4);
  EXPECT_VALID(result);
  EXPECT_EQ(kIntegerVal4, out4);

  Dart_Handle val5 = Dart_NewInteger(-1);
  EXPECT_VALID(val5);
  uint64_t out5 = 0;
  result = Dart_IntegerToUint64(val5, &out5);
  EXPECT(Dart_IsError(result));
}

TEST_CASE(IntegerFitsIntoInt64) {
  Dart_Handle max = Dart_NewInteger(kMaxInt64);
  EXPECT(Dart_IsInteger(max));
  bool fits = false;
  Dart_Handle result = Dart_IntegerFitsIntoInt64(max, &fits);
  EXPECT_VALID(result);
  EXPECT(fits);

  Dart_Handle above_max = Dart_NewIntegerFromHexCString("0x8000000000000000");
  EXPECT(Dart_IsInteger(above_max));
  fits = true;
  result = Dart_IntegerFitsIntoInt64(above_max, &fits);
  EXPECT_VALID(result);
  EXPECT(!fits);

  Dart_Handle min = Dart_NewInteger(kMinInt64);
  EXPECT(Dart_IsInteger(min));
  fits = false;
  result = Dart_IntegerFitsIntoInt64(min, &fits);
  EXPECT_VALID(result);
  EXPECT(fits);

  Dart_Handle below_min = Dart_NewIntegerFromHexCString("-0x8000000000000001");
  EXPECT(Dart_IsInteger(below_min));
  fits = true;
  result = Dart_IntegerFitsIntoInt64(below_min, &fits);
  EXPECT_VALID(result);
  EXPECT(!fits);
}

TEST_CASE(IntegerFitsIntoUint64) {
  Dart_Handle max = Dart_NewIntegerFromUint64(kMaxUint64);
  EXPECT(Dart_IsInteger(max));
  bool fits = false;
  Dart_Handle result = Dart_IntegerFitsIntoUint64(max, &fits);
  EXPECT_VALID(result);
  EXPECT(fits);

  Dart_Handle above_max = Dart_NewIntegerFromHexCString("0x10000000000000000");
  EXPECT(Dart_IsInteger(above_max));
  fits = true;
  result = Dart_IntegerFitsIntoUint64(above_max, &fits);
  EXPECT_VALID(result);
  EXPECT(!fits);

  Dart_Handle min = Dart_NewInteger(0);
  EXPECT(Dart_IsInteger(min));
  fits = false;
  result = Dart_IntegerFitsIntoUint64(min, &fits);
  EXPECT_VALID(result);
  EXPECT(fits);

  Dart_Handle below_min = Dart_NewIntegerFromHexCString("-1");
  EXPECT(Dart_IsInteger(below_min));
  fits = true;
  result = Dart_IntegerFitsIntoUint64(below_min, &fits);
  EXPECT_VALID(result);
  EXPECT(!fits);
}

TEST_CASE(ArrayValues) {
  EXPECT(!Dart_IsList(Dart_Null()));
  const int kArrayLength = 10;
  Dart_Handle str = NewString("test");
  EXPECT(!Dart_IsList(str));
  Dart_Handle val = Dart_NewList(kArrayLength);
  EXPECT(Dart_IsList(val));
  intptr_t len = 0;
  Dart_Handle result = Dart_ListLength(val, &len);
  EXPECT_VALID(result);
  EXPECT_EQ(kArrayLength, len);

  // Check invalid array access.
  result = Dart_ListSetAt(val, (kArrayLength + 10), Dart_NewInteger(10));
  EXPECT(Dart_IsError(result));
  result = Dart_ListSetAt(val, -10, Dart_NewInteger(10));
  EXPECT(Dart_IsError(result));
  result = Dart_ListGetAt(val, (kArrayLength + 10));
  EXPECT(Dart_IsError(result));
  result = Dart_ListGetAt(val, -10);
  EXPECT(Dart_IsError(result));

  for (int i = 0; i < kArrayLength; i++) {
    result = Dart_ListSetAt(val, i, Dart_NewInteger(i));
    EXPECT_VALID(result);
  }
  for (int i = 0; i < kArrayLength; i++) {
    result = Dart_ListGetAt(val, i);
    EXPECT_VALID(result);
    int64_t value;
    result = Dart_IntegerToInt64(result, &value);
    EXPECT_VALID(result);
    EXPECT_EQ(i, value);
  }
}

TEST_CASE(IsString) {
  uint8_t latin1[] = {'o', 'n', 'e', 0xC2, 0xA2};

  Dart_Handle latin1str = Dart_NewStringFromUTF8(latin1, ARRAY_SIZE(latin1));
  EXPECT_VALID(latin1str);
  EXPECT(Dart_IsString(latin1str));
  EXPECT(Dart_IsStringLatin1(latin1str));
  EXPECT(!Dart_IsExternalString(latin1str));
  intptr_t len = -1;
  EXPECT_VALID(Dart_StringLength(latin1str, &len));
  EXPECT_EQ(4, len);
  intptr_t char_size;
  intptr_t str_len;
  void* peer;
  EXPECT_VALID(
      Dart_StringGetProperties(latin1str, &char_size, &str_len, &peer));
  EXPECT_EQ(1, char_size);
  EXPECT_EQ(4, str_len);
  EXPECT(!peer);

  uint8_t data8[] = {'o', 'n', 'e', 0x7F};

  Dart_Handle str8 = Dart_NewStringFromUTF8(data8, ARRAY_SIZE(data8));
  EXPECT_VALID(str8);
  EXPECT(Dart_IsString(str8));
  EXPECT(Dart_IsStringLatin1(str8));
  EXPECT(!Dart_IsExternalString(str8));

  uint8_t latin1_array[] = {0, 0, 0, 0, 0};
  len = 5;
  Dart_Handle result = Dart_StringToLatin1(str8, latin1_array, &len);
  EXPECT_VALID(result);
  EXPECT_EQ(4, len);
  EXPECT(latin1_array != NULL);
  for (intptr_t i = 0; i < len; i++) {
    EXPECT_EQ(data8[i], latin1_array[i]);
  }

  Dart_Handle ext8 =
      Dart_NewExternalLatin1String(data8, ARRAY_SIZE(data8), data8, NULL);
  EXPECT_VALID(ext8);
  EXPECT(Dart_IsString(ext8));
  EXPECT(Dart_IsExternalString(ext8));
  EXPECT_VALID(Dart_StringGetProperties(ext8, &char_size, &str_len, &peer));
  EXPECT_EQ(1, char_size);
  EXPECT_EQ(4, str_len);
  EXPECT_EQ(data8, peer);

  uint16_t data16[] = {'t', 'w', 'o', 0xFFFF};

  Dart_Handle str16 = Dart_NewStringFromUTF16(data16, ARRAY_SIZE(data16));
  EXPECT_VALID(str16);
  EXPECT(Dart_IsString(str16));
  EXPECT(!Dart_IsStringLatin1(str16));
  EXPECT(!Dart_IsExternalString(str16));
  EXPECT_VALID(Dart_StringGetProperties(str16, &char_size, &str_len, &peer));
  EXPECT_EQ(2, char_size);
  EXPECT_EQ(4, str_len);
  EXPECT(!peer);

  Dart_Handle ext16 =
      Dart_NewExternalUTF16String(data16, ARRAY_SIZE(data16), data16, NULL);
  EXPECT_VALID(ext16);
  EXPECT(Dart_IsString(ext16));
  EXPECT(Dart_IsExternalString(ext16));
  EXPECT_VALID(Dart_StringGetProperties(ext16, &char_size, &str_len, &peer));
  EXPECT_EQ(2, char_size);
  EXPECT_EQ(4, str_len);
  EXPECT_EQ(data16, peer);

  int32_t data32[] = {'f', 'o', 'u', 'r', 0x10FFFF};

  Dart_Handle str32 = Dart_NewStringFromUTF32(data32, ARRAY_SIZE(data32));
  EXPECT_VALID(str32);
  EXPECT(Dart_IsString(str32));
  EXPECT(!Dart_IsExternalString(str32));
}

TEST_CASE(NewString) {
  const char* ascii = "string";
  Dart_Handle ascii_str = NewString(ascii);
  EXPECT_VALID(ascii_str);
  EXPECT(Dart_IsString(ascii_str));

  const char* null = NULL;
  Dart_Handle null_str = NewString(null);
  EXPECT(Dart_IsError(null_str));

  uint8_t data[] = {0xE4, 0xBA, 0x8c};  // U+4E8C.
  Dart_Handle utf8_str = Dart_NewStringFromUTF8(data, ARRAY_SIZE(data));
  EXPECT_VALID(utf8_str);
  EXPECT(Dart_IsString(utf8_str));

  uint8_t invalid[] = {0xE4, 0xBA};  // underflow.
  Dart_Handle invalid_str =
      Dart_NewStringFromUTF8(invalid, ARRAY_SIZE(invalid));
  EXPECT(Dart_IsError(invalid_str));
}

TEST_CASE(MalformedStringToUTF8) {
  // 1D11E = treble clef
  // [0] should be high surrogate D834
  // [1] should be low surrogate DD1E
  // Strings are allowed to have individual or out of order surrogates, even
  // if that doesn't make sense as renderable characters.
  const char* kScriptChars =
      "String lowSurrogate() {"
      "  return '\\u{1D11E}'[1];"
      "}"
      "String highSurrogate() {"
      "  return '\\u{1D11E}'[0];"
      "}"
      "String reversed() => lowSurrogate() + highSurrogate();";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle str1 = Dart_Invoke(lib, NewString("lowSurrogate"), 0, NULL);
  EXPECT_VALID(str1);

  uint8_t* utf8_encoded = NULL;
  intptr_t utf8_length = 0;
  Dart_Handle result = Dart_StringToUTF8(str1, &utf8_encoded, &utf8_length);
  EXPECT_VALID(result);
  EXPECT_EQ(3, utf8_length);
  EXPECT_EQ(237, static_cast<intptr_t>(utf8_encoded[0]));
  EXPECT_EQ(180, static_cast<intptr_t>(utf8_encoded[1]));
  EXPECT_EQ(158, static_cast<intptr_t>(utf8_encoded[2]));

  Dart_Handle str2 = Dart_NewStringFromUTF8(utf8_encoded, utf8_length);
  EXPECT_VALID(str2);  // Standalone low surrogate, but still valid

  Dart_Handle reversed = Dart_Invoke(lib, NewString("reversed"), 0, NULL);
  EXPECT_VALID(reversed);  // This is also allowed.
  uint8_t* utf8_encoded_reversed = NULL;
  intptr_t utf8_length_reversed = 0;
  result = Dart_StringToUTF8(reversed, &utf8_encoded_reversed,
                             &utf8_length_reversed);
  EXPECT_VALID(result);
  EXPECT_EQ(6, utf8_length_reversed);
  uint8_t expected[6] = {237, 180, 158, 237, 160, 180};
  for (int i = 0; i < 6; i++) {
    EXPECT_EQ(expected[i], utf8_encoded_reversed[i]);
  }
}

// Helper class to ensure new gen GC is triggered without any side effects.
// The normal call to CollectGarbage(Heap::kNew) could potentially trigger
// an old gen collection if there is a promotion failure and this could
// perturb the test.
class GCTestHelper : public AllStatic {
 public:
  static void CollectNewSpace(Heap::ApiCallbacks api_callbacks) {
    bool invoke_api_callbacks = (api_callbacks == Heap::kInvokeApiCallbacks);
    Isolate::Current()->heap()->new_space()->Scavenge(invoke_api_callbacks);
  }

  static void WaitForGCTasks() {
    Thread* thread = Thread::Current();
    PageSpace* old_space = thread->isolate()->heap()->old_space();
    MonitorLocker ml(old_space->tasks_lock());
    while (old_space->tasks() > 0) {
      ml.WaitWithSafepointCheck(thread);
    }
  }
};

static void ExternalStringCallbackFinalizer(void* peer) {
  *static_cast<int*>(peer) *= 2;
}

TEST_CASE(ExternalStringCallback) {
  int peer8 = 40;
  int peer16 = 41;

  {
    Dart_EnterScope();

    uint8_t data8[] = {'h', 'e', 'l', 'l', 'o'};
    Dart_Handle obj8 = Dart_NewExternalLatin1String(
        data8, ARRAY_SIZE(data8), &peer8, ExternalStringCallbackFinalizer);
    EXPECT_VALID(obj8);

    uint16_t data16[] = {'h', 'e', 'l', 'l', 'o'};
    Dart_Handle obj16 = Dart_NewExternalUTF16String(
        data16, ARRAY_SIZE(data16), &peer16, ExternalStringCallbackFinalizer);
    EXPECT_VALID(obj16);

    Dart_ExitScope();
  }

  {
    TransitionNativeToVM transition(thread);
    EXPECT_EQ(40, peer8);
    EXPECT_EQ(41, peer16);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    GCTestHelper::WaitForGCTasks();
    EXPECT_EQ(40, peer8);
    EXPECT_EQ(41, peer16);
    Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
    GCTestHelper::WaitForGCTasks();
    EXPECT_EQ(80, peer8);
    EXPECT_EQ(82, peer16);
  }
}

TEST_CASE(ExternalStringPretenure) {
  {
    Dart_EnterScope();
    static const uint8_t big_data8[16 * MB] = {
        0,
    };
    Dart_Handle big8 = Dart_NewExternalLatin1String(
        big_data8, ARRAY_SIZE(big_data8), NULL, NULL);
    EXPECT_VALID(big8);
    static const uint16_t big_data16[16 * MB / 2] = {
        0,
    };
    Dart_Handle big16 = Dart_NewExternalUTF16String(
        big_data16, ARRAY_SIZE(big_data16), NULL, NULL);
    static const uint8_t small_data8[] = {'f', 'o', 'o'};
    Dart_Handle small8 = Dart_NewExternalLatin1String(
        small_data8, ARRAY_SIZE(small_data8), NULL, NULL);
    EXPECT_VALID(small8);
    static const uint16_t small_data16[] = {'b', 'a', 'r'};
    Dart_Handle small16 = Dart_NewExternalUTF16String(
        small_data16, ARRAY_SIZE(small_data16), NULL, NULL);
    EXPECT_VALID(small16);
    {
      CHECK_API_SCOPE(thread);
      HANDLESCOPE(thread);
      String& handle = String::Handle();
      handle ^= Api::UnwrapHandle(big8);
      EXPECT(handle.IsOld());
      handle ^= Api::UnwrapHandle(big16);
      EXPECT(handle.IsOld());
      handle ^= Api::UnwrapHandle(small8);
      EXPECT(handle.IsNew());
      handle ^= Api::UnwrapHandle(small16);
      EXPECT(handle.IsNew());
    }
    Dart_ExitScope();
  }
}

TEST_CASE(ExternalTypedDataPretenure) {
  {
    Dart_EnterScope();
    static const int kBigLength = 16 * MB / 8;
    int64_t* big_data = new int64_t[kBigLength]();
    Dart_Handle big =
        Dart_NewExternalTypedData(Dart_TypedData_kInt64, big_data, kBigLength);
    EXPECT_VALID(big);
    static const int kSmallLength = 16 * KB / 8;
    int64_t* small_data = new int64_t[kSmallLength]();
    Dart_Handle small = Dart_NewExternalTypedData(Dart_TypedData_kInt64,
                                                  small_data, kSmallLength);
    EXPECT_VALID(small);
    {
      CHECK_API_SCOPE(thread);
      HANDLESCOPE(thread);
      ExternalTypedData& handle = ExternalTypedData::Handle();
      handle ^= Api::UnwrapHandle(big);
      EXPECT(handle.IsOld());
      handle ^= Api::UnwrapHandle(small);
      EXPECT(handle.IsNew());
    }
    Dart_ExitScope();
    delete[] big_data;
    delete[] small_data;
  }
}

TEST_CASE(ListAccess) {
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

  // First ensure that the returned object is an array.
  Dart_Handle list_access_test_obj = result;

  EXPECT(Dart_IsList(list_access_test_obj));

  // Get length of array object.
  intptr_t len = 0;
  result = Dart_ListLength(list_access_test_obj, &len);
  EXPECT_VALID(result);
  EXPECT_EQ(3, len);

  // Access elements in the array.
  int64_t value;

  result = Dart_ListGetAt(list_access_test_obj, 0);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(10, value);

  result = Dart_ListGetAt(list_access_test_obj, 1);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(20, value);

  result = Dart_ListGetAt(list_access_test_obj, 2);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(30, value);

  // Set some elements in the array.
  result = Dart_ListSetAt(list_access_test_obj, 0, Dart_NewInteger(0));
  EXPECT_VALID(result);
  result = Dart_ListSetAt(list_access_test_obj, 1, Dart_NewInteger(1));
  EXPECT_VALID(result);
  result = Dart_ListSetAt(list_access_test_obj, 2, Dart_NewInteger(2));
  EXPECT_VALID(result);

  // Get length of array object.
  result = Dart_ListLength(list_access_test_obj, &len);
  EXPECT_VALID(result);
  EXPECT_EQ(3, len);

  // Now try and access these elements in the array.
  result = Dart_ListGetAt(list_access_test_obj, 0);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(0, value);

  result = Dart_ListGetAt(list_access_test_obj, 1);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(1, value);

  result = Dart_ListGetAt(list_access_test_obj, 2);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(2, value);

  uint8_t native_array[3];
  result = Dart_ListGetAsBytes(list_access_test_obj, 0, native_array, 3);
  EXPECT_VALID(result);
  EXPECT_EQ(0, native_array[0]);
  EXPECT_EQ(1, native_array[1]);
  EXPECT_EQ(2, native_array[2]);

  native_array[0] = 10;
  native_array[1] = 20;
  native_array[2] = 30;
  result = Dart_ListSetAsBytes(list_access_test_obj, 0, native_array, 3);
  EXPECT_VALID(result);
  result = Dart_ListGetAsBytes(list_access_test_obj, 0, native_array, 3);
  EXPECT_VALID(result);
  EXPECT_EQ(10, native_array[0]);
  EXPECT_EQ(20, native_array[1]);
  EXPECT_EQ(30, native_array[2]);
  result = Dart_ListGetAt(list_access_test_obj, 2);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(30, value);

  // Check if we get an exception when accessing beyond limit.
  result = Dart_ListGetAt(list_access_test_obj, 4);
  EXPECT(Dart_IsError(result));

  // Check if we can get a range of values.
  result = Dart_ListGetRange(list_access_test_obj, 8, 4, NULL);
  EXPECT(Dart_IsError(result));
  const int kRangeOffset = 1;
  const int kRangeLength = 2;
  Dart_Handle values[kRangeLength];

  result = Dart_ListGetRange(list_access_test_obj, 8, 4, values);
  EXPECT(Dart_IsError(result));

  result = Dart_ListGetRange(list_access_test_obj, kRangeOffset, kRangeLength,
                             values);
  EXPECT_VALID(result);

  result = Dart_IntegerToInt64(values[0], &value);
  EXPECT_VALID(result);
  EXPECT_EQ(20, value);

  result = Dart_IntegerToInt64(values[1], &value);
  EXPECT_VALID(result);
  EXPECT_EQ(30, value);

  // Check that we get an exception (and not a fatal error) when
  // calling ListSetAt and ListSetAsBytes with an immutable list.
  list_access_test_obj = Dart_Invoke(lib, NewString("immutable"), 0, NULL);
  EXPECT_VALID(list_access_test_obj);
  EXPECT(Dart_IsList(list_access_test_obj));

  result = Dart_ListSetAsBytes(list_access_test_obj, 0, native_array, 3);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_IsUnhandledExceptionError(result));

  result = Dart_ListSetAt(list_access_test_obj, 0, Dart_NewInteger(42));
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_IsUnhandledExceptionError(result));
}

TEST_CASE(MapAccess) {
  EXPECT(!Dart_IsMap(Dart_Null()));
  const char* kScriptChars =
      "Map testMain() {"
      "  return {"
      "    'a' : 1,"
      "    'b' : null,"
      "  };"
      "}";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns an object of type Map.
  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);

  // First ensure that the returned object is a map.
  Dart_Handle map = result;
  Dart_Handle a = NewString("a");
  Dart_Handle b = NewString("b");
  Dart_Handle c = NewString("c");

  EXPECT(Dart_IsMap(map));
  EXPECT(!Dart_IsMap(a));

  // Access values in the map.
  int64_t value;
  result = Dart_MapGetAt(map, a);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(value, 1);

  result = Dart_MapGetAt(map, b);
  EXPECT(Dart_IsNull(result));

  result = Dart_MapGetAt(map, c);
  EXPECT(Dart_IsNull(result));

  EXPECT(Dart_IsError(Dart_MapGetAt(a, a)));

  // Test for presence of keys.
  bool contains = false;
  result = Dart_MapContainsKey(map, a);
  EXPECT_VALID(result);
  result = Dart_BooleanValue(result, &contains);
  EXPECT_VALID(result);
  EXPECT(contains);

  contains = false;
  result = Dart_MapContainsKey(map, NewString("b"));
  EXPECT_VALID(result);
  result = Dart_BooleanValue(result, &contains);
  EXPECT_VALID(result);
  EXPECT(contains);

  contains = true;
  result = Dart_MapContainsKey(map, NewString("c"));
  EXPECT_VALID(result);
  result = Dart_BooleanValue(result, &contains);
  EXPECT_VALID(result);
  EXPECT(!contains);

  EXPECT(Dart_IsError(Dart_MapContainsKey(a, a)));

  // Enumerate keys. (Note literal maps guarantee key order.)
  Dart_Handle keys = Dart_MapKeys(map);
  EXPECT_VALID(keys);

  intptr_t len = 0;
  bool equals;
  result = Dart_ListLength(keys, &len);
  EXPECT_VALID(result);
  EXPECT_EQ(2, len);

  result = Dart_ListGetAt(keys, 0);
  EXPECT(Dart_IsString(result));
  equals = false;
  EXPECT_VALID(Dart_ObjectEquals(result, a, &equals));
  EXPECT(equals);

  result = Dart_ListGetAt(keys, 1);
  EXPECT(Dart_IsString(result));
  equals = false;
  EXPECT_VALID(Dart_ObjectEquals(result, b, &equals));
  EXPECT(equals);

  EXPECT(Dart_IsError(Dart_MapKeys(a)));
}

TEST_CASE(IsFuture) {
  const char* kScriptChars =
      "import 'dart:async';"
      "Future testMain() {"
      "  return new Completer().future;"
      "}";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns an object of type Future.
  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsFuture(result));

  EXPECT(!Dart_IsFuture(lib));  // Non-instance.
  Dart_Handle anInteger = Dart_NewInteger(0);
  EXPECT(!Dart_IsFuture(anInteger));
  Dart_Handle aString = NewString("I am not a Future");
  EXPECT(!Dart_IsFuture(aString));
  Dart_Handle null = Dart_Null();
  EXPECT(!Dart_IsFuture(null));
}

TEST_CASE(TypedDataViewListGetAsBytes) {
  const int kSize = 1000;

  const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "List main(int size) {\n"
      "  var a = new Int8List(size);\n"
      "  var view = new Int8List.view(a.buffer, 0, size);\n"
      "  return view;\n"
      "}\n";
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Test with a typed data view object.
  Dart_Handle dart_args[1];
  dart_args[0] = Dart_NewInteger(kSize);
  Dart_Handle view_obj = Dart_Invoke(lib, NewString("main"), 1, dart_args);
  EXPECT_VALID(view_obj);
  for (intptr_t i = 0; i < kSize; ++i) {
    EXPECT_VALID(Dart_ListSetAt(view_obj, i, Dart_NewInteger(i & 0xff)));
  }
  uint8_t* data = new uint8_t[kSize];
  EXPECT_VALID(Dart_ListGetAsBytes(view_obj, 0, data, kSize));
  for (intptr_t i = 0; i < kSize; ++i) {
    EXPECT_EQ(i & 0xff, data[i]);
  }

  Dart_Handle result = Dart_ListGetAsBytes(view_obj, 0, data, kSize + 1);
  EXPECT(Dart_IsError(result));
  delete[] data;
}

TEST_CASE(TypedDataViewListIsTypedData) {
  const int kSize = 1000;

  const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "List main(int size) {\n"
      "  var a = new Int8List(size);\n"
      "  var view = new Int8List.view(a.buffer, 0, size);\n"
      "  return view;\n"
      "}\n";
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Create a typed data view object.
  Dart_Handle dart_args[1];
  dart_args[0] = Dart_NewInteger(kSize);
  Dart_Handle view_obj = Dart_Invoke(lib, NewString("main"), 1, dart_args);
  EXPECT_VALID(view_obj);
  // Test that the API considers it a TypedData object.
  EXPECT(Dart_IsTypedData(view_obj));
}

TEST_CASE(TypedDataAccess) {
  EXPECT_EQ(Dart_TypedData_kInvalid, Dart_GetTypeOfTypedData(Dart_True()));
  EXPECT_EQ(Dart_TypedData_kInvalid,
            Dart_GetTypeOfExternalTypedData(Dart_False()));
  Dart_Handle byte_array1 = Dart_NewTypedData(Dart_TypedData_kUint8, 10);
  EXPECT_VALID(byte_array1);
  EXPECT_EQ(Dart_TypedData_kUint8, Dart_GetTypeOfTypedData(byte_array1));
  EXPECT_EQ(Dart_TypedData_kInvalid,
            Dart_GetTypeOfExternalTypedData(byte_array1));
  EXPECT(Dart_IsList(byte_array1));
  EXPECT(!Dart_IsTypedData(Dart_True()));
  EXPECT(Dart_IsTypedData(byte_array1));
  EXPECT(!Dart_IsByteBuffer(byte_array1));

  intptr_t length = 0;
  Dart_Handle result = Dart_ListLength(byte_array1, &length);
  EXPECT_VALID(result);
  EXPECT_EQ(10, length);

  result = Dart_ListSetAt(byte_array1, -1, Dart_NewInteger(1));
  EXPECT(Dart_IsError(result));

  result = Dart_ListSetAt(byte_array1, 10, Dart_NewInteger(1));
  EXPECT(Dart_IsError(result));

  // Set through the List API.
  for (intptr_t i = 0; i < 10; ++i) {
    EXPECT_VALID(Dart_ListSetAt(byte_array1, i, Dart_NewInteger(i + 1)));
  }
  for (intptr_t i = 0; i < 10; ++i) {
    // Get through the List API.
    Dart_Handle integer_obj = Dart_ListGetAt(byte_array1, i);
    EXPECT_VALID(integer_obj);
    int64_t int64_t_value = -1;
    EXPECT_VALID(Dart_IntegerToInt64(integer_obj, &int64_t_value));
    EXPECT_EQ(i + 1, int64_t_value);
  }

  Dart_Handle byte_array2 = Dart_NewTypedData(Dart_TypedData_kUint8, 10);
  bool is_equal = false;
  Dart_ObjectEquals(byte_array1, byte_array2, &is_equal);
  EXPECT(!is_equal);

  // Set through the List API.
  for (intptr_t i = 0; i < 10; ++i) {
    result = Dart_ListSetAt(byte_array1, i, Dart_NewInteger(i + 2));
    EXPECT_VALID(result);
    result = Dart_ListSetAt(byte_array2, i, Dart_NewInteger(i + 2));
    EXPECT_VALID(result);
  }
  for (intptr_t i = 0; i < 10; ++i) {
    // Get through the List API.
    Dart_Handle e1 = Dart_ListGetAt(byte_array1, i);
    Dart_Handle e2 = Dart_ListGetAt(byte_array2, i);
    is_equal = false;
    Dart_ObjectEquals(e1, e2, &is_equal);
    EXPECT(is_equal);
  }

  uint8_t data[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
  for (intptr_t i = 0; i < 10; ++i) {
    EXPECT_VALID(Dart_ListSetAt(byte_array1, i, Dart_NewInteger(10 - i)));
  }
  Dart_ListGetAsBytes(byte_array1, 0, data, 10);
  for (intptr_t i = 0; i < 10; ++i) {
    Dart_Handle integer_obj = Dart_ListGetAt(byte_array1, i);
    EXPECT_VALID(integer_obj);
    int64_t int64_t_value = -1;
    EXPECT_VALID(Dart_IntegerToInt64(integer_obj, &int64_t_value));
    EXPECT_EQ(10 - i, int64_t_value);
  }
}

TEST_CASE(ByteBufferAccess) {
  EXPECT(!Dart_IsByteBuffer(Dart_True()));
  Dart_Handle byte_array = Dart_NewTypedData(Dart_TypedData_kUint8, 10);
  EXPECT_VALID(byte_array);
  // Set through the List API.
  for (intptr_t i = 0; i < 10; ++i) {
    EXPECT_VALID(Dart_ListSetAt(byte_array, i, Dart_NewInteger(i + 1)));
  }
  Dart_Handle byte_buffer = Dart_NewByteBuffer(byte_array);
  EXPECT_VALID(byte_buffer);
  EXPECT(Dart_IsByteBuffer(byte_buffer));
  EXPECT(!Dart_IsTypedData(byte_buffer));

  Dart_Handle byte_buffer_data = Dart_GetDataFromByteBuffer(byte_buffer);
  EXPECT_VALID(byte_buffer_data);
  EXPECT(!Dart_IsByteBuffer(byte_buffer_data));
  EXPECT(Dart_IsTypedData(byte_buffer_data));

  intptr_t length = 0;
  Dart_Handle result = Dart_ListLength(byte_buffer_data, &length);
  EXPECT_VALID(result);
  EXPECT_EQ(10, length);

  for (intptr_t i = 0; i < 10; ++i) {
    // Get through the List API.
    Dart_Handle integer_obj = Dart_ListGetAt(byte_buffer_data, i);
    EXPECT_VALID(integer_obj);
    int64_t int64_t_value = -1;
    EXPECT_VALID(Dart_IntegerToInt64(integer_obj, &int64_t_value));
    EXPECT_EQ(i + 1, int64_t_value);
  }

  // Some negative tests.
  result = Dart_NewByteBuffer(Dart_True());
  EXPECT(Dart_IsError(result));
  result = Dart_NewByteBuffer(byte_buffer);
  EXPECT(Dart_IsError(result));
  result = Dart_GetDataFromByteBuffer(Dart_False());
  EXPECT(Dart_IsError(result));
  result = Dart_GetDataFromByteBuffer(byte_array);
  EXPECT(Dart_IsError(result));
}

static int kLength = 16;

static void ByteDataNativeFunction(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle byte_data = Dart_NewTypedData(Dart_TypedData_kByteData, kLength);
  EXPECT_VALID(byte_data);
  EXPECT_EQ(Dart_TypedData_kByteData, Dart_GetTypeOfTypedData(byte_data));
  Dart_SetReturnValue(args, byte_data);
  Dart_ExitScope();
}

static Dart_NativeFunction ByteDataNativeResolver(Dart_Handle name,
                                                  int arg_count,
                                                  bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  return &ByteDataNativeFunction;
}

TEST_CASE(ByteDataAccess) {
  const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "class Expect {\n"
      "  static equals(a, b) {\n"
      "    if (a != b) {\n"
      "      throw 'not equal. expected: $a, got: $b';\n"
      "    }\n"
      "  }\n"
      "}\n"
      "ByteData createByteData() native 'CreateByteData';"
      "ByteData main() {"
      "  var length = 16;"
      "  var a = createByteData();"
      "  Expect.equals(length, a.lengthInBytes);"
      "  for (int i = 0; i < length; i+=1) {"
      "    a.setInt8(i, 0x42);"
      "  }"
      "  for (int i = 0; i < length; i+=2) {"
      "    Expect.equals(0x4242, a.getInt16(i));"
      "  }"
      "  return a;"
      "}\n";
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  Dart_Handle result =
      Dart_SetNativeResolver(lib, &ByteDataNativeResolver, NULL);
  EXPECT_VALID(result);

  // Invoke 'main' function.
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
}

static const intptr_t kExtLength = 16;
static int8_t data[kExtLength] = {
    0x41, 0x42, 0x41, 0x42, 0x41, 0x42, 0x41, 0x42,
    0x41, 0x42, 0x41, 0x42, 0x41, 0x42, 0x41, 0x42,
};

static void ExternalByteDataNativeFunction(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle external_byte_data =
      Dart_NewExternalTypedData(Dart_TypedData_kByteData, data, 16);
  EXPECT_VALID(external_byte_data);
  EXPECT_EQ(Dart_TypedData_kByteData,
            Dart_GetTypeOfTypedData(external_byte_data));
  Dart_SetReturnValue(args, external_byte_data);
  Dart_ExitScope();
}

static Dart_NativeFunction ExternalByteDataNativeResolver(
    Dart_Handle name,
    int arg_count,
    bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  return &ExternalByteDataNativeFunction;
}

TEST_CASE(ExternalByteDataAccess) {
  // TODO(asiva): Once we have getInt16LE and getInt16BE support use the
  // appropriate getter instead of the host endian format used now.
  const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "class Expect {\n"
      "  static equals(a, b) {\n"
      "    if (a != b) {\n"
      "      throw 'not equal. expected: $a, got: $b';\n"
      "    }\n"
      "  }\n"
      "}\n"
      "ByteData createExternalByteData() native 'CreateExternalByteData';"
      "ByteData main() {"
      "  var length = 16;"
      "  var a = createExternalByteData();"
      "  Expect.equals(length, a.lengthInBytes);"
      "  for (int i = 0; i < length; i+=2) {"
      "    Expect.equals(0x4241, a.getInt16(i, Endianness.LITTLE_ENDIAN));"
      "  }"
      "  for (int i = 0; i < length; i+=2) {"
      "    a.setInt8(i, 0x24);"
      "    a.setInt8(i + 1, 0x28);"
      "  }"
      "  for (int i = 0; i < length; i+=2) {"
      "    Expect.equals(0x2824, a.getInt16(i, Endianness.LITTLE_ENDIAN));"
      "  }"
      "  return a;"
      "}\n";
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  Dart_Handle result =
      Dart_SetNativeResolver(lib, &ExternalByteDataNativeResolver, NULL);
  EXPECT_VALID(result);

  // Invoke 'main' function.
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  for (intptr_t i = 0; i < kExtLength; i += 2) {
    EXPECT_EQ(0x24, data[i]);
    EXPECT_EQ(0x28, data[i + 1]);
  }
}

#ifndef PRODUCT

static const intptr_t kOptExtLength = 16;
static int8_t opt_data[kOptExtLength] = {
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10,
};

static void OptExternalByteDataNativeFunction(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle external_byte_data =
      Dart_NewExternalTypedData(Dart_TypedData_kByteData, opt_data, 16);
  EXPECT_VALID(external_byte_data);
  EXPECT_EQ(Dart_TypedData_kByteData,
            Dart_GetTypeOfTypedData(external_byte_data));
  Dart_SetReturnValue(args, external_byte_data);
  Dart_ExitScope();
}

static Dart_NativeFunction OptExternalByteDataNativeResolver(
    Dart_Handle name,
    int arg_count,
    bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  return &OptExternalByteDataNativeFunction;
}

TEST_CASE(OptimizedExternalByteDataAccess) {
  const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "class Expect {\n"
      "  static equals(a, b) {\n"
      "    if (a != b) {\n"
      "      throw 'not equal. expected: $a, got: $b';\n"
      "    }\n"
      "  }\n"
      "}\n"
      "ByteData createExternalByteData() native 'CreateExternalByteData';"
      "access(ByteData a) {"
      "  Expect.equals(0x04030201, a.getUint32(0, Endianness.LITTLE_ENDIAN));"
      "  Expect.equals(0x08070605, a.getUint32(4, Endianness.LITTLE_ENDIAN));"
      "  Expect.equals(0x0c0b0a09, a.getUint32(8, Endianness.LITTLE_ENDIAN));"
      "  Expect.equals(0x100f0e0d, a.getUint32(12, Endianness.LITTLE_ENDIAN));"
      "}"
      "ByteData main() {"
      "  var length = 16;"
      "  var a = createExternalByteData();"
      "  Expect.equals(length, a.lengthInBytes);"
      "  for (int i = 0; i < 20; i++) {"
      "    access(a);"
      "  }"
      "  return a;"
      "}\n";
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  Dart_Handle result =
      Dart_SetNativeResolver(lib, &OptExternalByteDataNativeResolver, NULL);
  EXPECT_VALID(result);

  // Invoke 'main' function.
  int old_oct = FLAG_optimization_counter_threshold;
  FLAG_optimization_counter_threshold = 5;
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  FLAG_optimization_counter_threshold = old_oct;
}

#endif  // !PRODUCT

static void TestTypedDataDirectAccess() {
  Dart_Handle str = Dart_NewStringFromCString("junk");
  Dart_Handle byte_array = Dart_NewTypedData(Dart_TypedData_kUint8, 10);
  EXPECT_VALID(byte_array);
  Dart_Handle result;
  result = Dart_TypedDataAcquireData(byte_array, NULL, NULL, NULL);
  EXPECT_ERROR(result,
               "Dart_TypedDataAcquireData expects argument 'type'"
               " to be non-null.");
  Dart_TypedData_Type type;
  result = Dart_TypedDataAcquireData(byte_array, &type, NULL, NULL);
  EXPECT_ERROR(result,
               "Dart_TypedDataAcquireData expects argument 'data'"
               " to be non-null.");
  void* data;
  result = Dart_TypedDataAcquireData(byte_array, &type, &data, NULL);
  EXPECT_ERROR(result,
               "Dart_TypedDataAcquireData expects argument 'len'"
               " to be non-null.");
  intptr_t len;
  result = Dart_TypedDataAcquireData(Dart_Null(), &type, &data, &len);
  EXPECT_ERROR(result,
               "Dart_TypedDataAcquireData expects argument 'object'"
               " to be non-null.");
  result = Dart_TypedDataAcquireData(str, &type, &data, &len);
  EXPECT_ERROR(result,
               "Dart_TypedDataAcquireData expects argument 'object'"
               " to be of type 'TypedData'.");

  result = Dart_TypedDataReleaseData(Dart_Null());
  EXPECT_ERROR(result,
               "Dart_TypedDataReleaseData expects argument 'object'"
               " to be non-null.");
  result = Dart_TypedDataReleaseData(str);
  EXPECT_ERROR(result,
               "Dart_TypedDataReleaseData expects argument 'object'"
               " to be of type 'TypedData'.");
}

TEST_CASE(TypedDataDirectAccessUnverified) {
  FLAG_verify_acquired_data = false;
  TestTypedDataDirectAccess();
}

TEST_CASE(TypedDataDirectAccessVerified) {
  FLAG_verify_acquired_data = true;
  TestTypedDataDirectAccess();
}

static void TestDirectAccess(Dart_Handle lib,
                             Dart_Handle array,
                             Dart_TypedData_Type expected_type,
                             bool is_external) {
  Dart_Handle result;

  // Invoke the dart function that sets initial values.
  Dart_Handle dart_args[1];
  dart_args[0] = array;
  result = Dart_Invoke(lib, NewString("setMain"), 1, dart_args);
  EXPECT_VALID(result);

  // Now Get a direct access to this typed data object and check it's contents.
  const int kLength = 10;
  Dart_TypedData_Type type;
  void* data;
  intptr_t len;
  result = Dart_TypedDataAcquireData(array, &type, &data, &len);
  EXPECT_VALID(result);
  EXPECT_EQ(expected_type, type);
  EXPECT_EQ(kLength, len);
  int8_t* dataP = reinterpret_cast<int8_t*>(data);
  for (int i = 0; i < kLength; i++) {
    EXPECT_EQ(i, dataP[i]);
  }

  if (!is_external) {
    // Now try allocating a string with outstanding Acquires and it should
    // return an error.
    result = NewString("We expect an error here");
    EXPECT_ERROR(result,
                 "Internal Dart data pointers have been acquired, "
                 "please release them using Dart_TypedDataReleaseData.");
  }

  // Now modify the values in the directly accessible array and then check
  // it we see the changes back in dart.
  for (int i = 0; i < kLength; i++) {
    dataP[i] += 10;
  }

  // Release direct access to the typed data object.
  result = Dart_TypedDataReleaseData(array);
  EXPECT_VALID(result);

  // Invoke the dart function in order to check the modified values.
  result = Dart_Invoke(lib, NewString("testMain"), 1, dart_args);
  EXPECT_VALID(result);
}

static void TestTypedDataDirectAccess1() {
  const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "class Expect {\n"
      "  static equals(a, b) {\n"
      "    if (a != b) {\n"
      "      throw new Exception('not equal. expected: $a, got: $b');\n"
      "    }\n"
      "  }\n"
      "}\n"
      "void setMain(var a) {"
      "  for (var i = 0; i < 10; i++) {"
      "    a[i] = i;"
      "  }"
      "}\n"
      "bool testMain(var list) {"
      "  for (var i = 0; i < 10; i++) {"
      "    Expect.equals((10 + i), list[i]);"
      "  }\n"
      "  return true;"
      "}\n"
      "List main() {"
      "  var a = new Int8List(10);"
      "  return a;"
      "}\n";
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Test with an regular typed data object.
  Dart_Handle list_access_test_obj;
  list_access_test_obj = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(list_access_test_obj);
  TestDirectAccess(lib, list_access_test_obj, Dart_TypedData_kInt8, false);

  // Test with an external typed data object.
  uint8_t data[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  intptr_t data_length = ARRAY_SIZE(data);
  Dart_Handle ext_list_access_test_obj;
  ext_list_access_test_obj =
      Dart_NewExternalTypedData(Dart_TypedData_kUint8, data, data_length);
  EXPECT_VALID(ext_list_access_test_obj);
  TestDirectAccess(lib, ext_list_access_test_obj, Dart_TypedData_kUint8, true);
}

TEST_CASE(TypedDataDirectAccess1Unverified) {
  FLAG_verify_acquired_data = false;
  TestTypedDataDirectAccess1();
}

TEST_CASE(TypedDataDirectAccess1Verified) {
  FLAG_verify_acquired_data = true;
  TestTypedDataDirectAccess1();
}

static void TestTypedDataViewDirectAccess() {
  const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "class Expect {\n"
      "  static equals(a, b) {\n"
      "    if (a != b) {\n"
      "      throw 'not equal. expected: $a, got: $b';\n"
      "    }\n"
      "  }\n"
      "}\n"
      "void setMain(var list) {"
      "  Expect.equals(10, list.length);"
      "  for (var i = 0; i < 10; i++) {"
      "    list[i] = i;"
      "  }"
      "}\n"
      "bool testMain(var list) {"
      "  Expect.equals(10, list.length);"
      "  for (var i = 0; i < 10; i++) {"
      "    Expect.equals((10 + i), list[i]);"
      "  }"
      "  return true;"
      "}\n"
      "List main() {"
      "  var a = new Int8List(100);"
      "  var view = new Int8List.view(a.buffer, 50, 10);"
      "  return view;"
      "}\n";
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Test with a typed data view object.
  Dart_Handle list_access_test_obj;
  list_access_test_obj = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(list_access_test_obj);
  TestDirectAccess(lib, list_access_test_obj, Dart_TypedData_kInt8, false);
}

TEST_CASE(TypedDataViewDirectAccessUnverified) {
  FLAG_verify_acquired_data = false;
  TestTypedDataViewDirectAccess();
}

TEST_CASE(TypedDataViewDirectAccessVerified) {
  FLAG_verify_acquired_data = true;
  TestTypedDataViewDirectAccess();
}

static void TestByteDataDirectAccess() {
  const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "class Expect {\n"
      "  static equals(a, b) {\n"
      "    if (a != b) {\n"
      "      throw 'not equal. expected: $a, got: $b';\n"
      "    }\n"
      "  }\n"
      "}\n"
      "void setMain(var list) {"
      "  Expect.equals(10, list.length);"
      "  for (var i = 0; i < 10; i++) {"
      "    list.setInt8(i, i);"
      "  }"
      "}\n"
      "bool testMain(var list) {"
      "  Expect.equals(10, list.length);"
      "  for (var i = 0; i < 10; i++) {"
      "    Expect.equals((10 + i), list.getInt8(i));"
      "  }"
      "  return true;"
      "}\n"
      "ByteData main() {"
      "  var a = new Int8List(100);"
      "  var view = new ByteData.view(a.buffer, 50, 10);"
      "  return view;"
      "}\n";
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Test with a typed data view object.
  Dart_Handle list_access_test_obj;
  list_access_test_obj = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(list_access_test_obj);
  TestDirectAccess(lib, list_access_test_obj, Dart_TypedData_kByteData, false);
}

TEST_CASE(ByteDataDirectAccessUnverified) {
  FLAG_verify_acquired_data = false;
  TestByteDataDirectAccess();
}

TEST_CASE(ByteDataDirectAccessVerified) {
  FLAG_verify_acquired_data = true;
  TestByteDataDirectAccess();
}

static void ExternalTypedDataAccessTests(Dart_Handle obj,
                                         Dart_TypedData_Type expected_type,
                                         uint8_t data[],
                                         intptr_t data_length) {
  EXPECT_VALID(obj);
  EXPECT_EQ(expected_type, Dart_GetTypeOfExternalTypedData(obj));
  EXPECT(Dart_IsList(obj));

  void* raw_data = NULL;
  intptr_t len;
  Dart_TypedData_Type type;
  EXPECT_VALID(Dart_TypedDataAcquireData(obj, &type, &raw_data, &len));
  EXPECT(raw_data == data);
  EXPECT_EQ(data_length, len);
  EXPECT_EQ(expected_type, type);
  EXPECT_VALID(Dart_TypedDataReleaseData(obj));

  intptr_t list_length = 0;
  EXPECT_VALID(Dart_ListLength(obj, &list_length));
  EXPECT_EQ(data_length, list_length);

  // Load and check values from underlying array and API.
  for (intptr_t i = 0; i < list_length; ++i) {
    EXPECT_EQ(11 * i, data[i]);
    Dart_Handle elt = Dart_ListGetAt(obj, i);
    EXPECT_VALID(elt);
    int64_t value = 0;
    EXPECT_VALID(Dart_IntegerToInt64(elt, &value));
    EXPECT_EQ(data[i], value);
  }

  // Write values through the underlying array.
  for (intptr_t i = 0; i < data_length; ++i) {
    data[i] *= 2;
  }
  // Read them back through the API.
  for (intptr_t i = 0; i < list_length; ++i) {
    Dart_Handle elt = Dart_ListGetAt(obj, i);
    EXPECT_VALID(elt);
    int64_t value = 0;
    EXPECT_VALID(Dart_IntegerToInt64(elt, &value));
    EXPECT_EQ(22 * i, value);
  }

  // Write values through the API.
  for (intptr_t i = 0; i < list_length; ++i) {
    Dart_Handle value = Dart_NewInteger(33 * i);
    EXPECT_VALID(value);
    EXPECT_VALID(Dart_ListSetAt(obj, i, value));
  }
  // Read them back through the underlying array.
  for (intptr_t i = 0; i < data_length; ++i) {
    EXPECT_EQ(33 * i, data[i]);
  }
}

TEST_CASE(ExternalTypedDataAccess) {
  uint8_t data[] = {0, 11, 22, 33, 44, 55, 66, 77};
  intptr_t data_length = ARRAY_SIZE(data);

  Dart_Handle obj =
      Dart_NewExternalTypedData(Dart_TypedData_kUint8, data, data_length);
  ExternalTypedDataAccessTests(obj, Dart_TypedData_kUint8, data, data_length);
}

TEST_CASE(ExternalClampedTypedDataAccess) {
  uint8_t data[] = {0, 11, 22, 33, 44, 55, 66, 77};
  intptr_t data_length = ARRAY_SIZE(data);

  Dart_Handle obj = Dart_NewExternalTypedData(Dart_TypedData_kUint8Clamped,
                                              data, data_length);
  ExternalTypedDataAccessTests(obj, Dart_TypedData_kUint8Clamped, data,
                               data_length);
}

TEST_CASE(ExternalUint8ClampedArrayAccess) {
  const char* kScriptChars =
      "testClamped(List a) {\n"
      "  if (a[1] != 11) return false;\n"
      "  a[1] = 3;\n"
      "  if (a[1] != 3) return false;\n"
      "  a[1] = -12;\n"
      "  if (a[1] != 0) return false;\n"
      "  a[1] = 1200;\n"
      "  if (a[1] != 255) return false;\n"
      "  return true;\n"
      "}\n";

  uint8_t data[] = {0, 11, 22, 33, 44, 55, 66, 77};
  intptr_t data_length = ARRAY_SIZE(data);
  Dart_Handle obj = Dart_NewExternalTypedData(Dart_TypedData_kUint8Clamped,
                                              data, data_length);
  EXPECT_VALID(obj);
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle args[1];
  args[0] = obj;
  result = Dart_Invoke(lib, NewString("testClamped"), 1, args);

  // Check that result is true.
  EXPECT_VALID(result);
  EXPECT(Dart_IsBoolean(result));
  bool value = false;
  result = Dart_BooleanValue(result, &value);
  EXPECT_VALID(result);
  EXPECT(value);
}

static void NopCallback(void* isolate_callback_data,
                        Dart_WeakPersistentHandle handle,
                        void* peer) {}

static void UnreachedCallback(void* isolate_callback_data,
                              Dart_WeakPersistentHandle handle,
                              void* peer) {
  UNREACHABLE();
}

static void ExternalTypedDataFinalizer(void* isolate_callback_data,
                                       Dart_WeakPersistentHandle handle,
                                       void* peer) {
  *static_cast<int*>(peer) = 42;
}

TEST_CASE(ExternalTypedDataCallback) {
  int peer = 0;
  {
    Dart_EnterScope();
    uint8_t data[] = {1, 2, 3, 4};
    Dart_Handle obj = Dart_NewExternalTypedData(Dart_TypedData_kUint8, data,
                                                ARRAY_SIZE(data));
    Dart_NewWeakPersistentHandle(obj, &peer, sizeof(data),
                                 ExternalTypedDataFinalizer);
    EXPECT_VALID(obj);
    Dart_ExitScope();
  }
  {
    TransitionNativeToVM transition(thread);
    EXPECT(peer == 0);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    GCTestHelper::WaitForGCTasks();
    EXPECT(peer == 0);
    Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
    GCTestHelper::WaitForGCTasks();
    EXPECT(peer == 42);
  }
}

static void SlowFinalizer(void* isolate_callback_data,
                          Dart_WeakPersistentHandle handle,
                          void* peer) {
  OS::Sleep(10);
  intptr_t* count = reinterpret_cast<intptr_t*>(peer);
  (*count)++;
}

TEST_CASE(SlowFinalizer) {
  intptr_t count = 0;
  for (intptr_t i = 0; i < 10; i++) {
    Dart_EnterScope();
    Dart_Handle str1 = Dart_NewStringFromCString("Live fast");
    Dart_NewWeakPersistentHandle(str1, &count, 0, SlowFinalizer);
    Dart_Handle str2 = Dart_NewStringFromCString("Die young");
    Dart_NewWeakPersistentHandle(str2, &count, 0, SlowFinalizer);
    Dart_ExitScope();

    {
      TransitionNativeToVM transition(thread);
      Isolate::Current()->heap()->CollectAllGarbage();
    }
  }

  {
    TransitionNativeToVM transition(thread);
    GCTestHelper::WaitForGCTasks();
  }

  EXPECT_EQ(20, count);
}

static void CheckFloat32x4Data(Dart_Handle obj) {
  void* raw_data = NULL;
  intptr_t len;
  Dart_TypedData_Type type;
  EXPECT_VALID(Dart_TypedDataAcquireData(obj, &type, &raw_data, &len));
  EXPECT_EQ(Dart_TypedData_kFloat32x4, type);
  EXPECT_EQ(len, 10);
  float* float_data = reinterpret_cast<float*>(raw_data);
  for (int i = 0; i < len * 4; i++) {
    EXPECT_EQ(0.0, float_data[i]);
  }
  EXPECT_VALID(Dart_TypedDataReleaseData(obj));
}

TEST_CASE(Float32x4List) {
  const char* kScriptChars =
      "import 'dart:typed_data';\n"
      "Float32x4List float32x4() {\n"
      "  return new Float32x4List(10);\n"
      "}\n";
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  Dart_Handle obj = Dart_Invoke(lib, NewString("float32x4"), 0, NULL);
  EXPECT_VALID(obj);
  CheckFloat32x4Data(obj);

  obj = Dart_NewTypedData(Dart_TypedData_kFloat32x4, 10);
  EXPECT_VALID(obj);
  CheckFloat32x4Data(obj);

  int peer = 0;
  float data[] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
  // Push a scope so that we can collect the local handle created as part of
  // Dart_NewExternalTypedData.
  Dart_EnterScope();
  {
    Dart_Handle lcl =
        Dart_NewExternalTypedData(Dart_TypedData_kFloat32x4, data, 10);
    Dart_NewWeakPersistentHandle(lcl, &peer, sizeof(data),
                                 ExternalTypedDataFinalizer);
    CheckFloat32x4Data(lcl);
  }
  Dart_ExitScope();
  {
    TransitionNativeToVM transition(thread);
    Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
    GCTestHelper::WaitForGCTasks();
    EXPECT(peer == 42);
  }
}

// Unit test for entering a scope, creating a local handle and exiting
// the scope.
VM_UNIT_TEST_CASE(EnterExitScope) {
  TestIsolateScope __test_isolate__;

  Thread* thread = Thread::Current();
  EXPECT(thread != NULL);
  ApiLocalScope* scope = thread->api_top_scope();
  Dart_EnterScope();
  {
    EXPECT(thread->api_top_scope() != NULL);
    HANDLESCOPE(thread);
    const String& str1 = String::Handle(String::New("Test String"));
    Dart_Handle ref = Api::NewHandle(thread, str1.raw());
    String& str2 = String::Handle();
    str2 ^= Api::UnwrapHandle(ref);
    EXPECT(str1.Equals(str2));
  }
  Dart_ExitScope();
  EXPECT(scope == thread->api_top_scope());
}

// Unit test for creating and deleting persistent handles.
VM_UNIT_TEST_CASE(PersistentHandles) {
  const char* kTestString1 = "Test String1";
  const char* kTestString2 = "Test String2";
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  ApiLocalScope* scope = thread->api_top_scope();
  Dart_PersistentHandle handles[2000];
  Dart_EnterScope();
  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);
    Dart_Handle ref1 = Api::NewHandle(thread, String::New(kTestString1));
    for (int i = 0; i < 1000; i++) {
      handles[i] = Dart_NewPersistentHandle(ref1);
    }
    Dart_EnterScope();
    Dart_Handle ref2 = Api::NewHandle(thread, String::New(kTestString2));
    for (int i = 1000; i < 2000; i++) {
      handles[i] = Dart_NewPersistentHandle(ref2);
    }
    for (int i = 500; i < 1500; i++) {
      Dart_DeletePersistentHandle(handles[i]);
    }
    for (int i = 500; i < 1000; i++) {
      handles[i] = Dart_NewPersistentHandle(ref2);
    }
    for (int i = 1000; i < 1500; i++) {
      handles[i] = Dart_NewPersistentHandle(ref1);
    }
    VERIFY_ON_TRANSITION;
    Dart_ExitScope();
  }
  Dart_ExitScope();
  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    for (int i = 0; i < 500; i++) {
      String& str = String::Handle();
      str ^= PersistentHandle::Cast(handles[i])->raw();
      EXPECT(str.Equals(kTestString1));
    }
    for (int i = 500; i < 1000; i++) {
      String& str = String::Handle();
      str ^= PersistentHandle::Cast(handles[i])->raw();
      EXPECT(str.Equals(kTestString2));
    }
    for (int i = 1000; i < 1500; i++) {
      String& str = String::Handle();
      str ^= PersistentHandle::Cast(handles[i])->raw();
      EXPECT(str.Equals(kTestString1));
    }
    for (int i = 1500; i < 2000; i++) {
      String& str = String::Handle();
      str ^= PersistentHandle::Cast(handles[i])->raw();
      EXPECT(str.Equals(kTestString2));
    }
  }
  EXPECT(scope == thread->api_top_scope());
  EXPECT_EQ(2001, state->CountPersistentHandles());
  Dart_ShutdownIsolate();
}

// Test that we are able to create a persistent handle from a
// persistent handle.
VM_UNIT_TEST_CASE(NewPersistentHandle_FromPersistentHandle) {
  TestIsolateScope __test_isolate__;

  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  Thread* thread = Thread::Current();
  CHECK_API_SCOPE(thread);
  HANDLESCOPE(thread);

  // Start with a known persistent handle.
  Dart_PersistentHandle obj1 = Dart_NewPersistentHandle(Dart_True());
  EXPECT(state->IsValidPersistentHandle(obj1));

  // And use it to allocate a second persistent handle.
  Dart_Handle obj2 = Dart_HandleFromPersistent(obj1);
  Dart_PersistentHandle obj3 = Dart_NewPersistentHandle(obj2);
  EXPECT(state->IsValidPersistentHandle(obj3));

  // Make sure that the value transferred.
  Dart_Handle obj4 = Dart_HandleFromPersistent(obj3);
  EXPECT(Dart_IsBoolean(obj4));
  bool value = false;
  Dart_Handle result = Dart_BooleanValue(obj4, &value);
  EXPECT_VALID(result);
  EXPECT(value);
}

// Test that we can assign to a persistent handle.
VM_UNIT_TEST_CASE(AssignToPersistentHandle) {
  const char* kTestString1 = "Test String1";
  const char* kTestString2 = "Test String2";
  TestIsolateScope __test_isolate__;

  Thread* T = Thread::Current();
  CHECK_API_SCOPE(T);
  HANDLESCOPE(T);
  Isolate* isolate = T->isolate();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  String& str = String::Handle();

  // Start with a known persistent handle.
  Dart_Handle ref1 = Api::NewHandle(T, String::New(kTestString1));
  Dart_PersistentHandle obj = Dart_NewPersistentHandle(ref1);
  EXPECT(state->IsValidPersistentHandle(obj));
  str ^= PersistentHandle::Cast(obj)->raw();
  EXPECT(str.Equals(kTestString1));

  // Now create another local handle and assign it to the persistent handle.
  Dart_Handle ref2 = Api::NewHandle(T, String::New(kTestString2));
  Dart_SetPersistentHandle(obj, ref2);
  str ^= PersistentHandle::Cast(obj)->raw();
  EXPECT(str.Equals(kTestString2));

  // Now assign Null to the persistent handle and check.
  Dart_SetPersistentHandle(obj, Dart_Null());
  EXPECT(Dart_IsNull(obj));
}

static Dart_Handle AsHandle(Dart_PersistentHandle weak) {
  return Dart_HandleFromPersistent(weak);
}

static Dart_Handle AsHandle(Dart_WeakPersistentHandle weak) {
  return Dart_HandleFromWeakPersistent(weak);
}

static Dart_WeakPersistentHandle weak_new_ref = NULL;
static Dart_WeakPersistentHandle weak_old_ref = NULL;

static void WeakPersistentHandleCallback(void* isolate_callback_data,
                                         Dart_WeakPersistentHandle handle,
                                         void* peer) {
  if (handle == weak_new_ref) {
    weak_new_ref = NULL;
  } else if (handle == weak_old_ref) {
    weak_old_ref = NULL;
  }
}

TEST_CASE(WeakPersistentHandle) {
  Dart_Handle local_new_ref = Dart_Null();
  weak_new_ref = Dart_NewWeakPersistentHandle(local_new_ref, NULL, 0,
                                              WeakPersistentHandleCallback);

  Dart_Handle local_old_ref = Dart_Null();
  weak_old_ref = Dart_NewWeakPersistentHandle(local_old_ref, NULL, 0,
                                              WeakPersistentHandleCallback);

  {
    Dart_EnterScope();

    // Create an object in new space.
    Dart_Handle new_ref = NewString("new string");
    EXPECT_VALID(new_ref);

    // Create an object in old space.
    Dart_Handle old_ref;
    {
      CHECK_API_SCOPE(thread);
      HANDLESCOPE(thread);
      old_ref = Api::NewHandle(thread, String::New("old string", Heap::kOld));
      EXPECT_VALID(old_ref);
    }

    // Create a weak ref to the new space object.
    weak_new_ref = Dart_NewWeakPersistentHandle(new_ref, NULL, 0,
                                                WeakPersistentHandleCallback);
    EXPECT_VALID(AsHandle(weak_new_ref));
    EXPECT(!Dart_IsNull(AsHandle(weak_new_ref)));

    // Create a weak ref to the old space object.
    weak_old_ref = Dart_NewWeakPersistentHandle(old_ref, NULL, 0,
                                                WeakPersistentHandleCallback);
    EXPECT_VALID(AsHandle(weak_old_ref));
    EXPECT(!Dart_IsNull(AsHandle(weak_old_ref)));

    {
      TransitionNativeToVM transition(thread);
      // Garbage collect new space.
      GCTestHelper::CollectNewSpace(Heap::kIgnoreApiCallbacks);
    }

    // Nothing should be invalidated or cleared.
    EXPECT_VALID(new_ref);
    EXPECT(!Dart_IsNull(new_ref));
    EXPECT_VALID(old_ref);
    EXPECT(!Dart_IsNull(old_ref));

    EXPECT_VALID(AsHandle(weak_new_ref));
    EXPECT(!Dart_IsNull(AsHandle(weak_new_ref)));
    EXPECT(Dart_IdentityEquals(new_ref, AsHandle(weak_new_ref)));

    EXPECT_VALID(AsHandle(weak_old_ref));
    EXPECT(!Dart_IsNull(AsHandle(weak_old_ref)));
    EXPECT(Dart_IdentityEquals(old_ref, AsHandle(weak_old_ref)));

    {
      TransitionNativeToVM transition(thread);
      // Garbage collect old space.
      Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    }

    // Nothing should be invalidated or cleared.
    EXPECT_VALID(new_ref);
    EXPECT(!Dart_IsNull(new_ref));
    EXPECT_VALID(old_ref);
    EXPECT(!Dart_IsNull(old_ref));

    EXPECT_VALID(AsHandle(weak_new_ref));
    EXPECT(!Dart_IsNull(AsHandle(weak_new_ref)));
    EXPECT(Dart_IdentityEquals(new_ref, AsHandle(weak_new_ref)));

    EXPECT_VALID(AsHandle(weak_old_ref));
    EXPECT(!Dart_IsNull(AsHandle(weak_old_ref)));
    EXPECT(Dart_IdentityEquals(old_ref, AsHandle(weak_old_ref)));

    // Delete local (strong) references.
    Dart_ExitScope();
  }

  {
    TransitionNativeToVM transition(thread);
    // Garbage collect new space again.
    GCTestHelper::CollectNewSpace(Heap::kIgnoreApiCallbacks);
    GCTestHelper::WaitForGCTasks();
  }

  {
    Dart_EnterScope();
    // Weak ref to new space object should now be cleared.
    EXPECT(weak_new_ref == NULL);
    EXPECT_VALID(AsHandle(weak_old_ref));
    EXPECT(!Dart_IsNull(AsHandle(weak_old_ref)));
    Dart_ExitScope();
  }

  {
    TransitionNativeToVM transition(thread);
    // Garbage collect old space again.
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    GCTestHelper::WaitForGCTasks();
  }

  {
    Dart_EnterScope();
    // Weak ref to old space object should now be cleared.
    EXPECT(weak_new_ref == NULL);
    EXPECT(weak_old_ref == NULL);
    Dart_ExitScope();
  }

  {
    TransitionNativeToVM transition(thread);
    // Garbage collect one last time to revisit deleted handles.
    Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  }
}

TEST_CASE(WeakPersistentHandleErrors) {
  Dart_EnterScope();

  // NULL callback.
  Dart_Handle obj1 = NewString("new string");
  EXPECT_VALID(obj1);
  Dart_WeakPersistentHandle ref1 =
      Dart_NewWeakPersistentHandle(obj1, NULL, 0, NULL);
  EXPECT_EQ(ref1, static_cast<void*>(NULL));

  // Immediate object.
  Dart_Handle obj2 = Dart_NewInteger(0);
  EXPECT_VALID(obj2);
  Dart_WeakPersistentHandle ref2 =
      Dart_NewWeakPersistentHandle(obj2, NULL, 0, WeakPersistentHandleCallback);
  EXPECT_EQ(ref2, static_cast<void*>(NULL));

  Dart_ExitScope();
}

static void WeakPersistentHandlePeerFinalizer(void* isolate_callback_data,
                                              Dart_WeakPersistentHandle handle,
                                              void* peer) {
  *static_cast<int*>(peer) = 42;
}

TEST_CASE(WeakPersistentHandleCallback) {
  Dart_WeakPersistentHandle weak_ref = NULL;
  int peer = 0;
  {
    Dart_EnterScope();
    Dart_Handle obj = NewString("new string");
    EXPECT_VALID(obj);
    weak_ref = Dart_NewWeakPersistentHandle(obj, &peer, 0,
                                            WeakPersistentHandlePeerFinalizer);
    EXPECT_VALID(AsHandle(weak_ref));
    EXPECT(peer == 0);
    Dart_ExitScope();
  }
  {
    TransitionNativeToVM transition(thread);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    EXPECT(peer == 0);
    GCTestHelper::CollectNewSpace(Heap::kIgnoreApiCallbacks);
    GCTestHelper::WaitForGCTasks();
    EXPECT(peer == 42);
  }
}

TEST_CASE(WeakPersistentHandleNoCallback) {
  Dart_WeakPersistentHandle weak_ref = NULL;
  int peer = 0;
  {
    Dart_EnterScope();
    Dart_Handle obj = NewString("new string");
    EXPECT_VALID(obj);
    weak_ref = Dart_NewWeakPersistentHandle(obj, &peer, 0,
                                            WeakPersistentHandlePeerFinalizer);
    Dart_ExitScope();
  }
  // A finalizer is not invoked on a deleted handle.  Therefore, the
  // peer value should not change after the referent is collected.
  Dart_Isolate isolate = reinterpret_cast<Dart_Isolate>(Isolate::Current());
  Dart_DeleteWeakPersistentHandle(isolate, weak_ref);
  EXPECT(peer == 0);
  {
    TransitionNativeToVM transition(thread);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    EXPECT(peer == 0);
    GCTestHelper::CollectNewSpace(Heap::kIgnoreApiCallbacks);
    GCTestHelper::WaitForGCTasks();
    EXPECT(peer == 0);
  }
}

VM_UNIT_TEST_CASE(WeakPersistentHandlesCallbackShutdown) {
  TestCase::CreateTestIsolate();
  Dart_EnterScope();
  Dart_Handle ref = Dart_True();
  int peer = 1234;
  Dart_NewWeakPersistentHandle(ref, &peer, 0,
                               WeakPersistentHandlePeerFinalizer);
  Dart_ExitScope();
  Dart_ShutdownIsolate();
  EXPECT(peer == 42);
}

TEST_CASE(WeakPersistentHandleExternalAllocationSize) {
  Heap* heap = Isolate::Current()->heap();
  EXPECT(heap->ExternalInWords(Heap::kNew) == 0);
  EXPECT(heap->ExternalInWords(Heap::kOld) == 0);
  Dart_WeakPersistentHandle weak1 = NULL;
  static const intptr_t kWeak1ExternalSize = 1 * KB;
  {
    Dart_EnterScope();
    Dart_Handle obj = NewString("weakly referenced string");
    EXPECT_VALID(obj);
    weak1 = Dart_NewWeakPersistentHandle(obj, NULL, kWeak1ExternalSize,
                                         NopCallback);
    EXPECT_VALID(AsHandle(weak1));
    Dart_ExitScope();
  }
  Dart_PersistentHandle strong_ref = NULL;
  Dart_WeakPersistentHandle weak2 = NULL;
  static const intptr_t kWeak2ExternalSize = 2 * KB;
  {
    Dart_EnterScope();
    Dart_Handle obj = NewString("strongly referenced string");
    EXPECT_VALID(obj);
    strong_ref = Dart_NewPersistentHandle(obj);
    weak2 = Dart_NewWeakPersistentHandle(obj, NULL, kWeak2ExternalSize,
                                         NopCallback);
    EXPECT_VALID(AsHandle(strong_ref));
    Dart_ExitScope();
  }
  {
    TransitionNativeToVM transition(thread);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    EXPECT(heap->ExternalInWords(Heap::kNew) ==
           (kWeak1ExternalSize + kWeak2ExternalSize) / kWordSize);
    // Collect weakly referenced string, and promote strongly referenced string.
    GCTestHelper::CollectNewSpace(Heap::kIgnoreApiCallbacks);
    GCTestHelper::CollectNewSpace(Heap::kIgnoreApiCallbacks);
    GCTestHelper::WaitForGCTasks();
    EXPECT(heap->ExternalInWords(Heap::kNew) == 0);
    EXPECT(heap->ExternalInWords(Heap::kOld) == kWeak2ExternalSize / kWordSize);
  }
  Dart_Isolate isolate = reinterpret_cast<Dart_Isolate>(Isolate::Current());
  Dart_DeleteWeakPersistentHandle(isolate, weak1);
  Dart_DeleteWeakPersistentHandle(isolate, weak2);
  Dart_DeletePersistentHandle(strong_ref);
  {
    TransitionNativeToVM transition(thread);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    GCTestHelper::WaitForGCTasks();
    EXPECT(heap->ExternalInWords(Heap::kOld) == 0);
  }
}

TEST_CASE(WeakPersistentHandleExternalAllocationSizeNewspaceGC) {
  Dart_Isolate isolate = reinterpret_cast<Dart_Isolate>(Isolate::Current());
  Heap* heap = Isolate::Current()->heap();
  Dart_WeakPersistentHandle weak1 = NULL;
  // Large enough to exceed any new space limit. Not actually allocated.
  const intptr_t kWeak1ExternalSize = 500 * MB;
  {
    Dart_EnterScope();
    Dart_Handle obj = NewString("weakly referenced string");
    EXPECT_VALID(obj);
    // Triggers a scavenge immediately, since kWeak1ExternalSize is above limit.
    weak1 = Dart_NewWeakPersistentHandle(obj, NULL, kWeak1ExternalSize,
                                         NopCallback);
    EXPECT_VALID(AsHandle(weak1));
    // ... but the object is still alive and not yet promoted, so external size
    // in new space is still above the limit. Thus, even the following tiny
    // external allocation will trigger another scavenge.
    Dart_WeakPersistentHandle trigger =
        Dart_NewWeakPersistentHandle(obj, NULL, 1, NopCallback);
    EXPECT_VALID(AsHandle(trigger));
    Dart_DeleteWeakPersistentHandle(isolate, trigger);
    // After the two scavenges above, 'obj' should now be promoted, hence its
    // external size charged to old space.
    {
      CHECK_API_SCOPE(thread);
      HANDLESCOPE(thread);
      String& handle = String::Handle(thread->zone());
      handle ^= Api::UnwrapHandle(obj);
      EXPECT(handle.IsOld());
    }
    EXPECT(heap->ExternalInWords(Heap::kNew) == 0);
    EXPECT(heap->ExternalInWords(Heap::kOld) == kWeak1ExternalSize / kWordSize);
    Dart_ExitScope();
  }
  Dart_DeleteWeakPersistentHandle(isolate, weak1);
  {
    TransitionNativeToVM transition(thread);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    GCTestHelper::WaitForGCTasks();
    EXPECT(heap->ExternalInWords(Heap::kOld) == 0);
  }
}

TEST_CASE(WeakPersistentHandleExternalAllocationSizeOldspaceGC) {
  // Check that external allocation in old space can trigger GC.
  Isolate* isolate = Isolate::Current();
  Dart_EnterScope();
  Dart_Handle live = Api::NewHandle(thread, String::New("live", Heap::kOld));
  EXPECT_VALID(live);
  Dart_WeakPersistentHandle weak = NULL;
  EXPECT_EQ(0, isolate->heap()->ExternalInWords(Heap::kOld));
  const intptr_t kSmallExternalSize = 1 * KB;
  {
    Dart_EnterScope();
    Dart_Handle dead = Api::NewHandle(thread, String::New("dead", Heap::kOld));
    EXPECT_VALID(dead);
    weak = Dart_NewWeakPersistentHandle(dead, NULL, kSmallExternalSize,
                                        NopCallback);
    EXPECT_VALID(AsHandle(weak));
    Dart_ExitScope();
  }
  EXPECT_EQ(kSmallExternalSize,
            isolate->heap()->ExternalInWords(Heap::kOld) * kWordSize);
  // Large enough to trigger GC in old space. Not actually allocated.
  const intptr_t kHugeExternalSize = (kWordSize == 4) ? 513 * MB : 1025 * MB;
  Dart_NewWeakPersistentHandle(live, NULL, kHugeExternalSize, NopCallback);
  // Expect small garbage to be collected.
  EXPECT_EQ(kHugeExternalSize,
            isolate->heap()->ExternalInWords(Heap::kOld) * kWordSize);
  Dart_ExitScope();
}

TEST_CASE(WeakPersistentHandleExternalAllocationSizeOddReferents) {
  Heap* heap = Isolate::Current()->heap();
  Dart_WeakPersistentHandle weak1 = NULL;
  static const intptr_t kWeak1ExternalSize = 1 * KB;
  Dart_WeakPersistentHandle weak2 = NULL;
  static const intptr_t kWeak2ExternalSize = 2 * KB;
  EXPECT_EQ(0, heap->ExternalInWords(Heap::kOld));
  {
    Dart_EnterScope();
    Dart_Handle dart_true = Dart_True();  // VM heap object.
    EXPECT_VALID(dart_true);
    weak1 = Dart_NewWeakPersistentHandle(dart_true, NULL, kWeak1ExternalSize,
                                         UnreachedCallback);
    EXPECT_VALID(AsHandle(weak1));
    Dart_Handle zero = Dart_False();  // VM heap object.
    EXPECT_VALID(zero);
    weak2 = Dart_NewWeakPersistentHandle(zero, NULL, kWeak2ExternalSize,
                                         UnreachedCallback);
    EXPECT_VALID(AsHandle(weak2));
    // Both should be charged to old space.
    EXPECT(heap->ExternalInWords(Heap::kOld) ==
           (kWeak1ExternalSize + kWeak2ExternalSize) / kWordSize);
    Dart_ExitScope();
  }
  Dart_Isolate isolate = reinterpret_cast<Dart_Isolate>(Isolate::Current());
  Dart_DeleteWeakPersistentHandle(isolate, weak1);
  Dart_DeleteWeakPersistentHandle(isolate, weak2);
  EXPECT_EQ(0, heap->ExternalInWords(Heap::kOld));
  {
    TransitionNativeToVM transition(thread);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    EXPECT_EQ(0, heap->ExternalInWords(Heap::kOld));
  }
}

static Dart_WeakPersistentHandle weak1 = NULL;
static Dart_WeakPersistentHandle weak2 = NULL;
static Dart_WeakPersistentHandle weak3 = NULL;

static void ImplicitReferencesCallback(void* isolate_callback_data,
                                       Dart_WeakPersistentHandle handle,
                                       void* peer) {
  if (handle == weak1) {
    weak1 = NULL;
  } else if (handle == weak2) {
    weak2 = NULL;
  } else if (handle == weak3) {
    weak3 = NULL;
  }
}

TEST_CASE(ImplicitReferencesOldSpace) {
  Dart_PersistentHandle strong = NULL;
  Dart_WeakPersistentHandle strong_weak = NULL;

  Dart_EnterScope();
  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);

    Dart_Handle local =
        Api::NewHandle(thread, String::New("strongly reachable", Heap::kOld));
    strong = Dart_NewPersistentHandle(local);
    strong_weak = Dart_NewWeakPersistentHandle(local, NULL, 0, NopCallback);

    EXPECT(!Dart_IsNull(AsHandle(strong)));
    EXPECT_VALID(AsHandle(strong));
    EXPECT(!Dart_IsNull(AsHandle(strong_weak)));
    EXPECT_VALID(AsHandle(strong_weak));
    EXPECT(Dart_IdentityEquals(AsHandle(strong), AsHandle(strong_weak)))

    weak1 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(thread, String::New("weakly reachable 1", Heap::kOld)),
        NULL, 0, ImplicitReferencesCallback);
    EXPECT(!Dart_IsNull(AsHandle(weak1)));
    EXPECT_VALID(AsHandle(weak1));

    weak2 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(thread, String::New("weakly reachable 2", Heap::kOld)),
        NULL, 0, ImplicitReferencesCallback);
    EXPECT(!Dart_IsNull(AsHandle(weak2)));
    EXPECT_VALID(AsHandle(weak2));

    weak3 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(thread, String::New("weakly reachable 3", Heap::kOld)),
        NULL, 0, ImplicitReferencesCallback);
    EXPECT(!Dart_IsNull(AsHandle(weak3)));
    EXPECT_VALID(AsHandle(weak3));
  }
  Dart_ExitScope();

  {
    Dart_EnterScope();
    EXPECT_VALID(AsHandle(strong_weak));
    EXPECT_VALID(AsHandle(weak1));
    EXPECT_VALID(AsHandle(weak2));
    EXPECT_VALID(AsHandle(weak3));
    Dart_ExitScope();
  }

  {
    TransitionNativeToVM transition(thread);
    GCTestHelper::CollectNewSpace(Heap::kIgnoreApiCallbacks);
  }

  {
    Dart_EnterScope();
    // New space collection should not affect old space objects
    EXPECT_VALID(AsHandle(strong_weak));
    EXPECT(!Dart_IsNull(AsHandle(weak1)));
    EXPECT(!Dart_IsNull(AsHandle(weak2)));
    EXPECT(!Dart_IsNull(AsHandle(weak3)));
    Dart_ExitScope();
  }
}

TEST_CASE(ImplicitReferencesNewSpace) {
  Dart_PersistentHandle strong = NULL;
  Dart_WeakPersistentHandle strong_weak = NULL;

  Dart_EnterScope();
  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);

    Dart_Handle local =
        Api::NewHandle(thread, String::New("strongly reachable", Heap::kOld));
    strong = Dart_NewPersistentHandle(local);
    strong_weak = Dart_NewWeakPersistentHandle(local, NULL, 0, NopCallback);

    EXPECT(!Dart_IsNull(AsHandle(strong)));
    EXPECT_VALID(AsHandle(strong));
    EXPECT(!Dart_IsNull(AsHandle(strong_weak)));
    EXPECT_VALID(AsHandle(strong_weak));
    EXPECT(Dart_IdentityEquals(AsHandle(strong), AsHandle(strong_weak)))

    weak1 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(thread, String::New("weakly reachable 1", Heap::kNew)),
        NULL, 0, ImplicitReferencesCallback);
    EXPECT(!Dart_IsNull(AsHandle(weak1)));
    EXPECT_VALID(AsHandle(weak1));

    weak2 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(thread, String::New("weakly reachable 2", Heap::kNew)),
        NULL, 0, ImplicitReferencesCallback);
    EXPECT(!Dart_IsNull(AsHandle(weak2)));
    EXPECT_VALID(AsHandle(weak2));

    weak3 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(thread, String::New("weakly reachable 3", Heap::kNew)),
        NULL, 0, ImplicitReferencesCallback);
    EXPECT(!Dart_IsNull(AsHandle(weak3)));
    EXPECT_VALID(AsHandle(weak3));
  }
  Dart_ExitScope();

  {
    Dart_EnterScope();
    EXPECT_VALID(AsHandle(strong_weak));
    EXPECT_VALID(AsHandle(weak1));
    EXPECT_VALID(AsHandle(weak2));
    EXPECT_VALID(AsHandle(weak3));
    Dart_ExitScope();
  }

  {
    TransitionNativeToVM transition(thread);
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  }

  {
    Dart_EnterScope();
    // Old space collection should not affect old space objects.
    EXPECT(!Dart_IsNull(AsHandle(weak1)));
    EXPECT(!Dart_IsNull(AsHandle(weak2)));
    EXPECT(!Dart_IsNull(AsHandle(weak3)));
    Dart_ExitScope();
  }
}

static int global_prologue_callback_status;

static void PrologueCallbackTimes2() {
  global_prologue_callback_status *= 2;
}

static void PrologueCallbackTimes3() {
  global_prologue_callback_status *= 3;
}

static int global_epilogue_callback_status;

static void EpilogueCallbackNOP() {}

static void EpilogueCallbackTimes4() {
  global_epilogue_callback_status *= 4;
}

static void EpilogueCallbackTimes5() {
  global_epilogue_callback_status *= 5;
}

TEST_CASE(SetGarbageCollectionCallbacks) {
  // GC callback addition testing.

  // Add GC callbacks.
  EXPECT_VALID(
      Dart_SetGcCallbacks(&PrologueCallbackTimes2, &EpilogueCallbackTimes4));

  // Add the same callbacks again.  This is an error.
  EXPECT(Dart_IsError(
      Dart_SetGcCallbacks(&PrologueCallbackTimes2, &EpilogueCallbackTimes4)));

  // Add another callback. This is an error.
  EXPECT(Dart_IsError(
      Dart_SetGcCallbacks(&PrologueCallbackTimes3, &EpilogueCallbackTimes5)));

  // GC callback removal testing.

  // Remove GC callbacks.
  EXPECT_VALID(Dart_SetGcCallbacks(NULL, NULL));

  // Remove GC callbacks whennone exist.  This is an error.
  EXPECT(Dart_IsError(Dart_SetGcCallbacks(NULL, NULL)));

  EXPECT_VALID(
      Dart_SetGcCallbacks(&PrologueCallbackTimes2, &EpilogueCallbackTimes4));
  EXPECT(Dart_IsError(Dart_SetGcCallbacks(&PrologueCallbackTimes2, NULL)));
  EXPECT(Dart_IsError(Dart_SetGcCallbacks(NULL, &EpilogueCallbackTimes4)));
}

TEST_CASE(SingleGarbageCollectionCallback) {
  // Add a prologue callback.
  EXPECT_VALID(
      Dart_SetGcCallbacks(&PrologueCallbackTimes2, &EpilogueCallbackNOP));

  {
    TransitionNativeToVM transition(thread);

    // Garbage collect new space ignoring callbacks.  This should not
    // invoke the prologue callback.  No status values should change.
    global_prologue_callback_status = 3;
    global_epilogue_callback_status = 7;
    GCTestHelper::CollectNewSpace(Heap::kIgnoreApiCallbacks);
    EXPECT_EQ(3, global_prologue_callback_status);
    EXPECT_EQ(7, global_epilogue_callback_status);

    // Garbage collect new space invoking callbacks.  This should
    // invoke the prologue callback.  No status values should change.
    global_prologue_callback_status = 3;
    global_epilogue_callback_status = 7;
    GCTestHelper::CollectNewSpace(Heap::kInvokeApiCallbacks);
    EXPECT_EQ(6, global_prologue_callback_status);
    EXPECT_EQ(7, global_epilogue_callback_status);

    // Garbage collect old space ignoring callbacks.  This should invoke
    // the prologue callback.  The prologue status value should change.
    global_prologue_callback_status = 3;
    global_epilogue_callback_status = 7;
    Isolate::Current()->heap()->CollectGarbage(
        Heap::kOld, Heap::kIgnoreApiCallbacks, Heap::kGCTestCase);
    EXPECT_EQ(3, global_prologue_callback_status);
    EXPECT_EQ(7, global_epilogue_callback_status);

    // Garbage collect old space.  This should invoke the prologue
    // callback.  The prologue status value should change.
    global_prologue_callback_status = 3;
    global_epilogue_callback_status = 7;
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    EXPECT_EQ(6, global_prologue_callback_status);
    EXPECT_EQ(7, global_epilogue_callback_status);

    // Garbage collect old space again.  Callbacks are persistent so the
    // prologue status value should change again.
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    EXPECT_EQ(12, global_prologue_callback_status);
    EXPECT_EQ(7, global_epilogue_callback_status);
  }

  // Add an epilogue callback.
  EXPECT_VALID(Dart_SetGcCallbacks(NULL, NULL));
  EXPECT_VALID(
      Dart_SetGcCallbacks(&PrologueCallbackTimes2, &EpilogueCallbackTimes4));

  {
    TransitionNativeToVM transition(thread);
    // Garbage collect new space.  This should not invoke the prologue
    // or the epilogue callback.  No status values should change.
    global_prologue_callback_status = 3;
    global_epilogue_callback_status = 7;
    GCTestHelper::CollectNewSpace(Heap::kIgnoreApiCallbacks);
    EXPECT_EQ(3, global_prologue_callback_status);
    EXPECT_EQ(7, global_epilogue_callback_status);

    // Garbage collect new space.  This should invoke the prologue and
    // the epilogue callback.  The prologue and epilogue status values
    // should change.
    GCTestHelper::CollectNewSpace(Heap::kInvokeApiCallbacks);
    EXPECT_EQ(6, global_prologue_callback_status);
    EXPECT_EQ(28, global_epilogue_callback_status);

    // Garbage collect old space.  This should invoke the prologue and
    // the epilogue callbacks.  The prologue and epilogue status values
    // should change.
    global_prologue_callback_status = 3;
    global_epilogue_callback_status = 7;
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    EXPECT_EQ(6, global_prologue_callback_status);
    EXPECT_EQ(28, global_epilogue_callback_status);

    // Garbage collect old space again without invoking callbacks.
    // Nothing should change.
    Isolate::Current()->heap()->CollectGarbage(
        Heap::kOld, Heap::kIgnoreApiCallbacks, Heap::kGCTestCase);
    EXPECT_EQ(6, global_prologue_callback_status);
    EXPECT_EQ(28, global_epilogue_callback_status);

    // Garbage collect old space again.  Callbacks are persistent so the
    // prologue and epilogue status values should change again.
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    EXPECT_EQ(12, global_prologue_callback_status);
    EXPECT_EQ(112, global_epilogue_callback_status);
  }

  // Remove the prologue and epilogue callbacks
  EXPECT_VALID(Dart_SetGcCallbacks(NULL, NULL));

  {
    TransitionNativeToVM transition(thread);
    // Garbage collect old space.  No callbacks should be invoked.  No
    // status values should change.
    global_prologue_callback_status = 3;
    global_epilogue_callback_status = 7;
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
    EXPECT_EQ(3, global_prologue_callback_status);
    EXPECT_EQ(7, global_epilogue_callback_status);
  }
}

// Unit test for creating multiple scopes and local handles within them.
// Ensure that the local handles get all cleaned out when exiting the
// scope.
VM_UNIT_TEST_CASE(LocalHandles) {
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  EXPECT(isolate != NULL);
  ApiLocalScope* scope = thread->api_top_scope();
  Dart_Handle handles[300];
  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Smi& val = Smi::Handle();

    // Start a new scope and allocate some local handles.
    Dart_EnterScope();
    for (int i = 0; i < 100; i++) {
      handles[i] = Api::NewHandle(thread, Smi::New(i));
    }
    EXPECT_EQ(100, thread->CountLocalHandles());
    for (int i = 0; i < 100; i++) {
      val ^= Api::UnwrapHandle(handles[i]);
      EXPECT_EQ(i, val.Value());
    }
    // Start another scope and allocate some more local handles.
    {
      Dart_EnterScope();
      for (int i = 100; i < 200; i++) {
        handles[i] = Api::NewHandle(thread, Smi::New(i));
      }
      EXPECT_EQ(200, thread->CountLocalHandles());
      for (int i = 100; i < 200; i++) {
        val ^= Api::UnwrapHandle(handles[i]);
        EXPECT_EQ(i, val.Value());
      }

      // Start another scope and allocate some more local handles.
      {
        Dart_EnterScope();
        for (int i = 200; i < 300; i++) {
          handles[i] = Api::NewHandle(thread, Smi::New(i));
        }
        EXPECT_EQ(300, thread->CountLocalHandles());
        for (int i = 200; i < 300; i++) {
          val ^= Api::UnwrapHandle(handles[i]);
          EXPECT_EQ(i, val.Value());
        }
        EXPECT_EQ(300, thread->CountLocalHandles());
        VERIFY_ON_TRANSITION;
        Dart_ExitScope();
      }
      EXPECT_EQ(200, thread->CountLocalHandles());
      Dart_ExitScope();
    }
    EXPECT_EQ(100, thread->CountLocalHandles());
    Dart_ExitScope();
  }
  EXPECT_EQ(0, thread->CountLocalHandles());
  EXPECT(scope == thread->api_top_scope());
  Dart_ShutdownIsolate();
}

// Unit test for creating multiple scopes and allocating objects in the
// zone for the scope. Ensure that the memory is freed when the scope
// exits.
VM_UNIT_TEST_CASE(LocalZoneMemory) {
  TestCase::CreateTestIsolate();
  Thread* thread = Thread::Current();
  EXPECT(thread != NULL);
  ApiLocalScope* scope = thread->api_top_scope();
  {
    // Start a new scope and allocate some memory.
    Dart_EnterScope();
    for (int i = 0; i < 100; i++) {
      Dart_ScopeAllocate(16);
    }
    EXPECT_EQ(1600, thread->ZoneSizeInBytes());
    // Start another scope and allocate some more memory.
    {
      Dart_EnterScope();
      for (int i = 0; i < 100; i++) {
        Dart_ScopeAllocate(16);
      }
      EXPECT_EQ(3200, thread->ZoneSizeInBytes());
      {
        // Start another scope and allocate some more memory.
        {
          Dart_EnterScope();
          for (int i = 0; i < 200; i++) {
            Dart_ScopeAllocate(16);
          }
          EXPECT_EQ(6400, thread->ZoneSizeInBytes());
          Dart_ExitScope();
        }
      }
      EXPECT_EQ(3200, thread->ZoneSizeInBytes());
      Dart_ExitScope();
    }
    EXPECT_EQ(1600, thread->ZoneSizeInBytes());
    Dart_ExitScope();
  }
  EXPECT_EQ(0, thread->ZoneSizeInBytes());
  EXPECT(scope == thread->api_top_scope());
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(Isolates) {
  // This test currently assumes that the Dart_Isolate type is an opaque
  // representation of Isolate*.
  Dart_Isolate iso_1 = TestCase::CreateTestIsolate();
  EXPECT_EQ(iso_1, Api::CastIsolate(Isolate::Current()));
  Dart_Isolate isolate = Dart_CurrentIsolate();
  EXPECT_EQ(iso_1, isolate);
  Dart_ExitIsolate();
  EXPECT(NULL == Dart_CurrentIsolate());
  Dart_Isolate iso_2 = TestCase::CreateTestIsolate();
  EXPECT_EQ(iso_2, Dart_CurrentIsolate());
  Dart_ExitIsolate();
  EXPECT(NULL == Dart_CurrentIsolate());
  Dart_EnterIsolate(iso_2);
  EXPECT_EQ(iso_2, Dart_CurrentIsolate());
  Dart_ShutdownIsolate();
  EXPECT(NULL == Dart_CurrentIsolate());
  Dart_EnterIsolate(iso_1);
  EXPECT_EQ(iso_1, Dart_CurrentIsolate());
  Dart_ShutdownIsolate();
  EXPECT(NULL == Dart_CurrentIsolate());
}

VM_UNIT_TEST_CASE(CurrentIsolateData) {
  intptr_t mydata = 12345;
  char* err;
  Dart_Isolate isolate =
      Dart_CreateIsolate(NULL, NULL, bin::core_isolate_snapshot_data,
                         bin::core_isolate_snapshot_instructions, NULL,
                         reinterpret_cast<void*>(mydata), &err);
  EXPECT(isolate != NULL);
  EXPECT_EQ(mydata, reinterpret_cast<intptr_t>(Dart_CurrentIsolateData()));
  EXPECT_EQ(mydata, reinterpret_cast<intptr_t>(Dart_IsolateData(isolate)));
  Dart_ShutdownIsolate();
}

VM_UNIT_TEST_CASE(IsolateSetCheckedMode) {
  const char* kScriptChars =
      "int bad1() {\n"
      "  int foo = 'string';\n"
      "  return foo;\n"
      "}\n"
      "\n"
      "int good1() {\n"
      "  int five = 5;\n"
      "  return five;"
      "}\n";

  // Create an isolate with checked mode flags.
  Dart_IsolateFlags api_flags;
  Isolate::FlagsInitialize(&api_flags);
  api_flags.enable_type_checks = true;
  api_flags.enable_asserts = true;
  api_flags.enable_error_on_bad_type = true;
  api_flags.enable_error_on_bad_override = true;

  char* err;
  Dart_Isolate isolate = Dart_CreateIsolate(
      NULL, NULL, bin::core_isolate_snapshot_data,
      bin::core_isolate_snapshot_instructions, &api_flags, NULL, &err);
  if (isolate == NULL) {
    OS::Print("Creation of isolate failed '%s'\n", err);
    free(err);
  }
  EXPECT(isolate != NULL);

  {
    Dart_EnterScope();
    Dart_Handle url = NewString(TestCase::url());
    Dart_Handle source = NewString(kScriptChars);
    Dart_Handle result = Dart_SetLibraryTagHandler(TestCase::library_handler);
    EXPECT_VALID(result);
    Dart_Handle lib = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
    EXPECT_VALID(lib);
    result = Dart_FinalizeLoading(false);
    EXPECT_VALID(result);
    result = Dart_Invoke(lib, NewString("bad1"), 0, NULL);
    EXPECT_ERROR(result,
                 "Unhandled exception:\n"
                 "type 'String' is not a subtype of type 'int' of 'foo'");

    result = Dart_Invoke(lib, NewString("good1"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
  }

  EXPECT(isolate != NULL);

  // Shutdown the isolate.
  Dart_ShutdownIsolate();
}

TEST_CASE(DebugName) {
  Dart_Handle debug_name = Dart_DebugName();
  EXPECT_VALID(debug_name);
  EXPECT(Dart_IsString(debug_name));
}

static void MyMessageNotifyCallback(Dart_Isolate dest_isolate) {}

VM_UNIT_TEST_CASE(SetMessageCallbacks) {
  Dart_Isolate dart_isolate = TestCase::CreateTestIsolate();
  Dart_SetMessageNotifyCallback(&MyMessageNotifyCallback);
  Isolate* isolate = reinterpret_cast<Isolate*>(dart_isolate);
  EXPECT_EQ(&MyMessageNotifyCallback, isolate->message_notify_callback());
  Dart_ShutdownIsolate();
}

TEST_CASE(SetStickyError) {
  const char* kScriptChars = "main() => throw 'HI';";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle retobj = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT(Dart_IsError(retobj));
  EXPECT(Dart_IsUnhandledExceptionError(retobj));
  EXPECT(!Dart_HasStickyError());
  EXPECT(Dart_GetStickyError() == Dart_Null());
  Dart_SetStickyError(retobj);
  EXPECT(Dart_HasStickyError());
  EXPECT(Dart_GetStickyError() != Dart_Null());
  Dart_SetStickyError(Dart_Null());
  EXPECT(!Dart_HasStickyError());
  EXPECT(Dart_GetStickyError() == Dart_Null());
}

TEST_CASE(TypeGetNonParamtericTypes) {
  const char* kScriptChars =
      "class MyClass0 {\n"
      "}\n"
      "\n"
      "class MyClass1 implements MyInterface1 {\n"
      "}\n"
      "\n"
      "class MyClass2 implements MyInterface0, MyInterface1 {\n"
      "}\n"
      "\n"
      "abstract class MyInterface0 {\n"
      "}\n"
      "\n"
      "abstract class MyInterface1 implements MyInterface0 {\n"
      "}\n"
      "MyClass0 getMyClass0() { return new MyClass0(); }\n"
      "MyClass1 getMyClass1() { return new MyClass1(); }\n"
      "MyClass2 getMyClass2() { return new MyClass2(); }\n"
      "Type getMyClass0Type() { return new MyClass0().runtimeType; }\n"
      "Type getMyClass1Type() { return new MyClass1().runtimeType; }\n"
      "Type getMyClass2Type() { return new MyClass2().runtimeType; }\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  bool instanceOf = false;

  // First get the type objects of these non parameterized types.
  Dart_Handle type0 = Dart_GetType(lib, NewString("MyClass0"), 0, NULL);
  EXPECT_VALID(type0);
  Dart_Handle type1 = Dart_GetType(lib, NewString("MyClass1"), 0, NULL);
  EXPECT_VALID(type1);
  Dart_Handle type2 = Dart_GetType(lib, NewString("MyClass2"), 0, NULL);
  EXPECT_VALID(type2);
  Dart_Handle type3 = Dart_GetType(lib, NewString("MyInterface0"), 0, NULL);
  EXPECT_VALID(type3);
  Dart_Handle type4 = Dart_GetType(lib, NewString("MyInterface1"), 0, NULL);
  EXPECT_VALID(type4);

  // Now create objects of these non parameterized types and check
  // that the validity of the type of the created object.
  // MyClass0 type.
  Dart_Handle type0_obj = Dart_Invoke(lib, NewString("getMyClass0"), 0, NULL);
  EXPECT_VALID(type0_obj);
  EXPECT_VALID(Dart_ObjectIsType(type0_obj, type0, &instanceOf));
  EXPECT(instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type0_obj, type1, &instanceOf));
  EXPECT(!instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type0_obj, type2, &instanceOf));
  EXPECT(!instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type0_obj, type3, &instanceOf));
  EXPECT(!instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type0_obj, type4, &instanceOf));
  EXPECT(!instanceOf);
  type0_obj = Dart_Invoke(lib, NewString("getMyClass0Type"), 0, NULL);
  EXPECT_VALID(type0_obj);
  EXPECT(Dart_IdentityEquals(type0, type0_obj));

  // MyClass1 type.
  Dart_Handle type1_obj = Dart_Invoke(lib, NewString("getMyClass1"), 0, NULL);
  EXPECT_VALID(type1_obj);
  EXPECT_VALID(Dart_ObjectIsType(type1_obj, type1, &instanceOf));
  EXPECT(instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type1_obj, type0, &instanceOf));
  EXPECT(!instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type1_obj, type2, &instanceOf));
  EXPECT(!instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type1_obj, type3, &instanceOf));
  EXPECT(instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type1_obj, type4, &instanceOf));
  EXPECT(instanceOf);
  type1_obj = Dart_Invoke(lib, NewString("getMyClass1Type"), 0, NULL);
  EXPECT_VALID(type1_obj);
  EXPECT(Dart_IdentityEquals(type1, type1_obj));

  // MyClass2 type.
  Dart_Handle type2_obj = Dart_Invoke(lib, NewString("getMyClass2"), 0, NULL);
  EXPECT_VALID(type2_obj);
  EXPECT_VALID(Dart_ObjectIsType(type2_obj, type2, &instanceOf));
  EXPECT(instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type2_obj, type0, &instanceOf));
  EXPECT(!instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type2_obj, type1, &instanceOf));
  EXPECT(!instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type2_obj, type3, &instanceOf));
  EXPECT(instanceOf);
  EXPECT_VALID(Dart_ObjectIsType(type2_obj, type4, &instanceOf));
  EXPECT(instanceOf);
  type2_obj = Dart_Invoke(lib, NewString("getMyClass2Type"), 0, NULL);
  EXPECT_VALID(type2_obj);
  EXPECT(Dart_IdentityEquals(type2, type2_obj));
}

TEST_CASE(TypeGetParameterizedTypes) {
  const char* kScriptChars =
      "class MyClass0<A, B> {\n"
      "}\n"
      "\n"
      "class MyClass1<A, C> {\n"
      "}\n"
      "MyClass0 getMyClass0() {\n"
      "  return new MyClass0<int, double>();\n"
      "}\n"
      "Type getMyClass0Type() {\n"
      "  return new MyClass0<int, double>().runtimeType;\n"
      "}\n"
      "MyClass1 getMyClass1() {\n"
      "  return new MyClass1<List<int>, List>();\n"
      "}\n"
      "Type getMyClass1Type() {\n"
      "  return new MyClass1<List<int>, List>().runtimeType;\n"
      "}\n"
      "MyClass0 getMyClass0_1() {\n"
      "  return new MyClass0<double, int>();\n"
      "}\n"
      "Type getMyClass0_1Type() {\n"
      "  return new MyClass0<double, int>().runtimeType;\n"
      "}\n"
      "MyClass1 getMyClass1_1() {\n"
      "  return new MyClass1<List<int>, List<double>>();\n"
      "}\n"
      "Type getMyClass1_1Type() {\n"
      "  return new MyClass1<List<int>, List<double>>().runtimeType;\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  bool instanceOf = false;

  // First get type objects of some of the basic types used in the test.
  Dart_Handle int_type = Dart_GetType(lib, NewString("int"), 0, NULL);
  EXPECT_VALID(int_type);
  Dart_Handle double_type = Dart_GetType(lib, NewString("double"), 0, NULL);
  EXPECT_VALID(double_type);
  Dart_Handle list_type = Dart_GetType(lib, NewString("List"), 0, NULL);
  EXPECT_VALID(list_type);
  Dart_Handle type_args = Dart_NewList(1);
  EXPECT_VALID(Dart_ListSetAt(type_args, 0, int_type));
  Dart_Handle list_int_type =
      Dart_GetType(lib, NewString("List"), 1, &type_args);
  EXPECT_VALID(list_int_type);

  // Now instantiate MyClass0 and MyClass1 types with the same type arguments
  // used in the code above.
  type_args = Dart_NewList(2);
  EXPECT_VALID(Dart_ListSetAt(type_args, 0, int_type));
  EXPECT_VALID(Dart_ListSetAt(type_args, 1, double_type));
  Dart_Handle myclass0_type =
      Dart_GetType(lib, NewString("MyClass0"), 2, &type_args);
  EXPECT_VALID(myclass0_type);

  type_args = Dart_NewList(2);
  EXPECT_VALID(Dart_ListSetAt(type_args, 0, list_int_type));
  EXPECT_VALID(Dart_ListSetAt(type_args, 1, list_type));
  Dart_Handle myclass1_type =
      Dart_GetType(lib, NewString("MyClass1"), 2, &type_args);
  EXPECT_VALID(myclass1_type);

  // Now create objects of the type and validate the object type matches
  // the one returned above. Also get the runtime type of the object and
  // verify that it matches the type returned above.
  // MyClass0<int, double> type.
  Dart_Handle type0_obj = Dart_Invoke(lib, NewString("getMyClass0"), 0, NULL);
  EXPECT_VALID(type0_obj);
  EXPECT_VALID(Dart_ObjectIsType(type0_obj, myclass0_type, &instanceOf));
  EXPECT(instanceOf);
  type0_obj = Dart_Invoke(lib, NewString("getMyClass0Type"), 0, NULL);
  EXPECT_VALID(type0_obj);
  EXPECT(Dart_IdentityEquals(type0_obj, myclass0_type));

  // MyClass1<List<int>, List> type.
  Dart_Handle type1_obj = Dart_Invoke(lib, NewString("getMyClass1"), 0, NULL);
  EXPECT_VALID(type1_obj);
  EXPECT_VALID(Dart_ObjectIsType(type1_obj, myclass1_type, &instanceOf));
  EXPECT(instanceOf);
  type1_obj = Dart_Invoke(lib, NewString("getMyClass1Type"), 0, NULL);
  EXPECT_VALID(type1_obj);
  EXPECT(Dart_IdentityEquals(type1_obj, myclass1_type));

  // MyClass0<double, int> type.
  type0_obj = Dart_Invoke(lib, NewString("getMyClass0_1"), 0, NULL);
  EXPECT_VALID(type0_obj);
  EXPECT_VALID(Dart_ObjectIsType(type0_obj, myclass0_type, &instanceOf));
  EXPECT(!instanceOf);
  type0_obj = Dart_Invoke(lib, NewString("getMyClass0_1Type"), 0, NULL);
  EXPECT_VALID(type0_obj);
  EXPECT(!Dart_IdentityEquals(type0_obj, myclass0_type));

  // MyClass1<List<int>, List<double>> type.
  type1_obj = Dart_Invoke(lib, NewString("getMyClass1_1"), 0, NULL);
  EXPECT_VALID(type1_obj);
  EXPECT_VALID(Dart_ObjectIsType(type1_obj, myclass1_type, &instanceOf));
  EXPECT(instanceOf);
  type1_obj = Dart_Invoke(lib, NewString("getMyClass1_1Type"), 0, NULL);
  EXPECT_VALID(type1_obj);
  EXPECT(!Dart_IdentityEquals(type1_obj, myclass1_type));
}

static void TestFieldOk(Dart_Handle container,
                        Dart_Handle name,
                        bool final,
                        const char* initial_value) {
  Dart_Handle result;

  // Make sure we have the right initial value.
  result = Dart_GetField(container, name);
  EXPECT_VALID(result);
  const char* value = "";
  EXPECT_VALID(Dart_StringToCString(result, &value));
  EXPECT_STREQ(initial_value, value);

  // Use a unique expected value.
  static int counter = 0;
  char buffer[256];
  OS::SNPrint(buffer, 256, "Expected%d", ++counter);

  // Try to change the field value.
  result = Dart_SetField(container, name, NewString(buffer));
  if (final) {
    EXPECT(Dart_IsError(result));
  } else {
    EXPECT_VALID(result);
  }

  // Make sure we have the right final value.
  result = Dart_GetField(container, name);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_StringToCString(result, &value));
  if (final) {
    EXPECT_STREQ(initial_value, value);
  } else {
    EXPECT_STREQ(buffer, value);
  }
}

static void TestFieldNotFound(Dart_Handle container, Dart_Handle name) {
  EXPECT(Dart_IsError(Dart_GetField(container, name)));
  EXPECT(Dart_IsError(Dart_SetField(container, name, Dart_Null())));
}

TEST_CASE(FieldAccess) {
  const char* kScriptChars =
      "class BaseFields {\n"
      "  BaseFields()\n"
      "    : this.inherited_fld = 'inherited' {\n"
      "  }\n"
      "  var inherited_fld;\n"
      "  static var non_inherited_fld;\n"
      "}\n"
      "\n"
      "class Fields extends BaseFields {\n"
      "  Fields()\n"
      "    : this.instance_fld = 'instance',\n"
      "      this._instance_fld = 'hidden instance',\n"
      "      this.final_instance_fld = 'final instance',\n"
      "      this._final_instance_fld = 'hidden final instance' {\n"
      "    instance_getset_fld = 'instance getset';\n"
      "    _instance_getset_fld = 'hidden instance getset';\n"
      "  }\n"
      "\n"
      "  static Init() {\n"
      "    static_fld = 'static';\n"
      "    _static_fld = 'hidden static';\n"
      "    static_getset_fld = 'static getset';\n"
      "    _static_getset_fld = 'hidden static getset';\n"
      "  }\n"
      "\n"
      "  var instance_fld;\n"
      "  var _instance_fld;\n"
      "  final final_instance_fld;\n"
      "  final _final_instance_fld;\n"
      "  static var static_fld;\n"
      "  static var _static_fld;\n"
      "  static const const_static_fld = 'const static';\n"
      "  static const _const_static_fld = 'hidden const static';\n"
      "\n"
      "  get instance_getset_fld { return _gs_fld1; }\n"
      "  void set instance_getset_fld(var value) { _gs_fld1 = value; }\n"
      "  get _instance_getset_fld { return _gs_fld2; }\n"
      "  void set _instance_getset_fld(var value) { _gs_fld2 = value; }\n"
      "  var _gs_fld1;\n"
      "  var _gs_fld2;\n"
      "\n"
      "  static get static_getset_fld { return _gs_fld3; }\n"
      "  static void set static_getset_fld(var value) { _gs_fld3 = value; }\n"
      "  static get _static_getset_fld { return _gs_fld4; }\n"
      "  static void set _static_getset_fld(var value) { _gs_fld4 = value; }\n"
      "  static var _gs_fld3;\n"
      "  static var _gs_fld4;\n"
      "}\n"
      "var top_fld;\n"
      "var _top_fld;\n"
      "const const_top_fld = 'const top';\n"
      "const _const_top_fld = 'hidden const top';\n"
      "\n"
      "get top_getset_fld { return _gs_fld5; }\n"
      "void set top_getset_fld(var value) { _gs_fld5 = value; }\n"
      "get _top_getset_fld { return _gs_fld6; }\n"
      "void set _top_getset_fld(var value) { _gs_fld6 = value; }\n"
      "var _gs_fld5;\n"
      "var _gs_fld6;\n"
      "\n"
      "Fields test() {\n"
      "  Fields.Init();\n"
      "  top_fld = 'top';\n"
      "  _top_fld = 'hidden top';\n"
      "  top_getset_fld = 'top getset';\n"
      "  _top_getset_fld = 'hidden top getset';\n"
      "  return new Fields();\n"
      "}\n";
  const char* kImportedScriptChars =
      "library library_name;\n"
      "var imported_fld = 'imported';\n"
      "var _imported_fld = 'hidden imported';\n"
      "get imported_getset_fld { return _gs_fld1; }\n"
      "void set imported_getset_fld(var value) { _gs_fld1 = value; }\n"
      "get _imported_getset_fld { return _gs_fld2; }\n"
      "void set _imported_getset_fld(var value) { _gs_fld2 = value; }\n"
      "var _gs_fld1;\n"
      "var _gs_fld2;\n"
      "void test2() {\n"
      "  imported_getset_fld = 'imported getset';\n"
      "  _imported_getset_fld = 'hidden imported getset';\n"
      "}\n";

  // Shared setup.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle type = Dart_GetType(lib, NewString("Fields"), 0, NULL);
  EXPECT_VALID(type);
  Dart_Handle instance = Dart_Invoke(lib, NewString("test"), 0, NULL);
  EXPECT_VALID(instance);
  Dart_Handle name;

  // Load imported lib.
  Dart_Handle url = NewString("library_url");
  Dart_Handle source = NewString(kImportedScriptChars);
  Dart_Handle imported_lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  Dart_Handle prefix = Dart_EmptyString();
  EXPECT_VALID(imported_lib);
  Dart_Handle result = Dart_LibraryImportLibrary(lib, imported_lib, prefix);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);
  result = Dart_Invoke(imported_lib, NewString("test2"), 0, NULL);
  EXPECT_VALID(result);

  // Instance field.
  name = NewString("instance_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(type, name);
  TestFieldOk(instance, name, false, "instance");

  // Hidden instance field.
  name = NewString("_instance_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(type, name);
  TestFieldOk(instance, name, false, "hidden instance");

  // Final instance field.
  name = NewString("final_instance_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(type, name);
  TestFieldOk(instance, name, true, "final instance");

  // Hidden final instance field.
  name = NewString("_final_instance_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(type, name);
  TestFieldOk(instance, name, true, "hidden final instance");

  // Inherited field.
  name = NewString("inherited_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(type, name);
  TestFieldOk(instance, name, false, "inherited");

  // Instance get/set field.
  name = NewString("instance_getset_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(type, name);
  TestFieldOk(instance, name, false, "instance getset");

  // Hidden instance get/set field.
  name = NewString("_instance_getset_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(type, name);
  TestFieldOk(instance, name, false, "hidden instance getset");

  // Static field.
  name = NewString("static_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(type, name, false, "static");

  // Hidden static field.
  name = NewString("_static_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(type, name, false, "hidden static");

  // Static final field.
  name = NewString("const_static_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(type, name, true, "const static");

  // Hidden static const field.
  name = NewString("_const_static_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(type, name, true, "hidden const static");

  // Static non-inherited field.  Not found at any level.
  name = NewString("non_inherited_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldNotFound(type, name);

  // Static get/set field.
  name = NewString("static_getset_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(type, name, false, "static getset");

  // Hidden static get/set field.
  name = NewString("_static_getset_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(type, name, false, "hidden static getset");

  // Top-Level field.
  name = NewString("top_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "top");

  // Hidden top-level field.
  name = NewString("_top_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "hidden top");

  // Top-Level final field.
  name = NewString("const_top_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, true, "const top");

  // Hidden top-level final field.
  name = NewString("_const_top_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, true, "hidden const top");

  // Top-Level get/set field.
  name = NewString("top_getset_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "top getset");

  // Hidden top-level get/set field.
  name = NewString("_top_getset_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "hidden top getset");

  // Imported top-Level field.
  name = NewString("imported_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "imported");

  // Hidden imported top-level field.  Not found at any level.
  name = NewString("_imported_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldNotFound(lib, name);

  // Imported top-Level get/set field.
  name = NewString("imported_getset_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "imported getset");

  // Hidden imported top-level get/set field.  Not found at any level.
  name = NewString("_imported_getset_fld");
  TestFieldNotFound(type, name);
  TestFieldNotFound(instance, name);
  TestFieldNotFound(lib, name);
}

TEST_CASE(SetField_FunnyValue) {
  const char* kScriptChars = "var top;\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle name = NewString("top");
  bool value;

  // Test that you can set the field to a good value.
  EXPECT_VALID(Dart_SetField(lib, name, Dart_True()));
  Dart_Handle result = Dart_GetField(lib, name);
  EXPECT_VALID(result);
  EXPECT(Dart_IsBoolean(result));
  EXPECT_VALID(Dart_BooleanValue(result, &value));
  EXPECT(value);

  // Test that you can set the field to null
  EXPECT_VALID(Dart_SetField(lib, name, Dart_Null()));
  result = Dart_GetField(lib, name);
  EXPECT_VALID(result);
  EXPECT(Dart_IsNull(result));

  // Pass a non-instance handle.
  result = Dart_SetField(lib, name, lib);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_SetField expects argument 'value' to be of type Instance.",
               Dart_GetError(result));

  // Pass an error handle.  The error is contagious.
  result = Dart_SetField(lib, name, Api::NewError("myerror"));
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("myerror", Dart_GetError(result));
}

void NativeFieldLookup(Dart_NativeArguments args) {
  UNREACHABLE();
}

static Dart_NativeFunction native_field_lookup(Dart_Handle name,
                                               int argument_count,
                                               bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  return reinterpret_cast<Dart_NativeFunction>(&NativeFieldLookup);
}

TEST_CASE(InjectNativeFields1) {
  const char* kScriptChars =
      "class NativeFields extends NativeFieldsWrapper {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static const int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  Dart_Handle result;

  const int kNumNativeFields = 4;

  // Create a test library.
  Dart_Handle lib =
      TestCase::LoadTestScript(kScriptChars, NULL, USER_TEST_URI, false);

  // Create a native wrapper class with native fields.
  result = Dart_CreateNativeWrapperClass(lib, NewString("NativeFieldsWrapper"),
                                         kNumNativeFields);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  // Load up a test script in the test library.

  // Invoke a function which returns an object of type NativeFields.
  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  CHECK_API_SCOPE(thread);
  HANDLESCOPE(thread);
  Instance& obj = Instance::Handle();
  obj ^= Api::UnwrapHandle(result);
  const Class& cls = Class::Handle(obj.clazz());
  // We expect the newly created "NativeFields" object to have
  // 2 dart instance fields (fld1, fld2) and a reference to the native fields.
  // Hence the size of an instance of "NativeFields" should be
  // (1 + 2) * kWordSize + size of object header.
  // We check to make sure the instance size computed by the VM matches
  // our expectations.
  intptr_t header_size = sizeof(RawObject);
  EXPECT_EQ(
      Utils::RoundUp(((1 + 2) * kWordSize) + header_size, kObjectAlignment),
      cls.instance_size());
  EXPECT_EQ(kNumNativeFields, cls.num_native_fields());
}

TEST_CASE(InjectNativeFields2) {
  const char* kScriptChars =
      "class NativeFields extends NativeFieldsWrapper {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static const int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle lib =
      TestCase::LoadTestScript(kScriptChars, NULL, USER_TEST_URI, false);

  // Invoke a function which returns an object of type NativeFields.
  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);

  // We expect this to fail as class "NativeFields" extends
  // "NativeFieldsWrapper" and there is no definition of it either
  // in the dart code or through the native field injection mechanism.
  EXPECT(Dart_IsError(result));
}

TEST_CASE(InjectNativeFields3) {
  const char* kScriptChars =
      "import 'dart:nativewrappers';"
      "class NativeFields extends NativeFieldWrapperClass2 {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static const int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  Dart_Handle result;
  const int kNumNativeFields = 2;

  // Load up a test script in the test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, native_field_lookup);

  // Invoke a function which returns an object of type NativeFields.
  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  CHECK_API_SCOPE(thread);
  HANDLESCOPE(thread);
  Instance& obj = Instance::Handle();
  obj ^= Api::UnwrapHandle(result);
  const Class& cls = Class::Handle(obj.clazz());
  // We expect the newly created "NativeFields" object to have
  // 2 dart instance fields (fld1, fld2) and a reference to the native fields.
  // Hence the size of an instance of "NativeFields" should be
  // (1 + 2) * kWordSize + size of object header.
  // We check to make sure the instance size computed by the VM matches
  // our expectations.
  intptr_t header_size = sizeof(RawObject);
  EXPECT_EQ(
      Utils::RoundUp(((1 + 2) * kWordSize) + header_size, kObjectAlignment),
      cls.instance_size());
  EXPECT_EQ(kNumNativeFields, cls.num_native_fields());
}

TEST_CASE(InjectNativeFields4) {
  const char* kScriptChars =
      "import 'dart:nativewrappers';"
      "class NativeFields extends NativeFieldWrapperClass2 {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static const int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  Dart_Handle result;
  // Load up a test script in the test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns an object of type NativeFields.
  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);

  USE(result);
#if 0
  // TODO(12455) Need better validation.
  // We expect the test script to fail finalization with the error below:
  EXPECT(Dart_IsError(result));
  Dart_Handle expected_error = DartUtils::NewError(
      "'dart:test-lib': Error: line 1 pos 36: "
      "class 'NativeFields' is trying to extend a native fields class, "
      "but library '%s' has no native resolvers",
      TestCase::url());
  EXPECT_SUBSTRING(Dart_GetError(expected_error), Dart_GetError(result));
#endif
}

static const int kTestNumNativeFields = 2;
static const intptr_t kNativeField1Value = 30;
static const intptr_t kNativeField2Value = 40;

void TestNativeFieldsAccess_init(Dart_NativeArguments args) {
  Dart_Handle receiver = Dart_GetNativeArgument(args, 0);
  Dart_SetNativeInstanceField(receiver, 0, kNativeField1Value);
  Dart_SetNativeInstanceField(receiver, 1, kNativeField2Value);
}

void TestNativeFieldsAccess_access(Dart_NativeArguments args) {
  intptr_t field_values[kTestNumNativeFields];
  Dart_Handle result = Dart_GetNativeFieldsOfArgument(
      args, 0, kTestNumNativeFields, field_values);
  EXPECT_VALID(result);
  EXPECT_EQ(kNativeField1Value, field_values[0]);
  EXPECT_EQ(kNativeField2Value, field_values[1]);
  result = Dart_GetNativeFieldsOfArgument(args, 1, kTestNumNativeFields,
                                          field_values);
  EXPECT_VALID(result);
  EXPECT_EQ(0, field_values[0]);
  EXPECT_EQ(0, field_values[1]);
}

static Dart_NativeFunction TestNativeFieldsAccess_lookup(Dart_Handle name,
                                                         int argument_count,
                                                         bool* auto_scope) {
  ASSERT(auto_scope != NULL);
  *auto_scope = true;
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  if (!obj.IsString()) {
    return NULL;
  }
  const char* function_name = obj.ToCString();
  ASSERT(function_name != NULL);
  if (!strcmp(function_name, "TestNativeFieldsAccess_init")) {
    return reinterpret_cast<Dart_NativeFunction>(&TestNativeFieldsAccess_init);
  } else if (!strcmp(function_name, "TestNativeFieldsAccess_access")) {
    return reinterpret_cast<Dart_NativeFunction>(
        &TestNativeFieldsAccess_access);
  } else {
    return NULL;
  }
}

TEST_CASE(TestNativeFieldsAccess) {
  const char* kScriptChars =
      "import 'dart:nativewrappers';"
      "class NativeFields extends NativeFieldWrapperClass2 {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static const int fld4 = 10;\n"
      "  int initNativeFlds() native 'TestNativeFieldsAccess_init';\n"
      "  int accessNativeFlds(int i) native 'TestNativeFieldsAccess_access';\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  obj.initNativeFlds();\n"
      "  obj.accessNativeFlds(null);\n"
      "  return obj;\n"
      "}\n";

  // Load up a test script in the test library.
  Dart_Handle lib =
      TestCase::LoadTestScript(kScriptChars, TestNativeFieldsAccess_lookup);

  // Invoke a function which returns an object of type NativeFields.
  Dart_Handle result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
}

TEST_CASE(InjectNativeFieldsSuperClass) {
  const char* kScriptChars =
      "import 'dart:nativewrappers';"
      "class NativeFieldsSuper extends NativeFieldWrapperClass1 {\n"
      "  NativeFieldsSuper() : fld1 = 42 {}\n"
      "  int fld1;\n"
      "}\n"
      "class NativeFields extends NativeFieldsSuper {\n"
      "  fld() => fld1;\n"
      "}\n"
      "int testMain() {\n"
      "  NativeFields obj = new NativeFields();\n"
      "  return obj.fld();\n"
      "}\n";
  Dart_Handle result;
  // Load up a test script in the test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, native_field_lookup);

  // Invoke a function which returns an object of type NativeFields.
  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);

  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(42, value);
}

static void TestNativeFields(Dart_Handle retobj) {
  // Access and set various instance fields of the object.
  Dart_Handle result = Dart_GetField(retobj, NewString("fld3"));
  EXPECT(Dart_IsError(result));
  result = Dart_GetField(retobj, NewString("fld0"));
  EXPECT_VALID(result);
  EXPECT(Dart_IsNull(result));
  result = Dart_GetField(retobj, NewString("fld1"));
  EXPECT_VALID(result);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(10, value);
  result = Dart_GetField(retobj, NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(20, value);
  result = Dart_SetField(retobj, NewString("fld2"), Dart_NewInteger(40));
  EXPECT(Dart_IsError(result));
  result = Dart_SetField(retobj, NewString("fld1"), Dart_NewInteger(40));
  EXPECT_VALID(result);
  result = Dart_GetField(retobj, NewString("fld1"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(40, value);

  // Now access and set various native instance fields of the returned object.
  const int kNativeFld0 = 0;
  const int kNativeFld1 = 1;
  const int kNativeFld2 = 2;
  const int kNativeFld3 = 3;
  const int kNativeFld4 = 4;
  int field_count = 0;
  intptr_t field_value = 0;
  EXPECT_VALID(Dart_GetNativeInstanceFieldCount(retobj, &field_count));
  EXPECT_EQ(4, field_count);
  result = Dart_GetNativeInstanceField(retobj, kNativeFld4, &field_value);
  EXPECT(Dart_IsError(result));
  result = Dart_GetNativeInstanceField(retobj, kNativeFld0, &field_value);
  EXPECT_VALID(result);
  EXPECT_EQ(0, field_value);
  result = Dart_GetNativeInstanceField(retobj, kNativeFld1, &field_value);
  EXPECT_VALID(result);
  EXPECT_EQ(0, field_value);
  result = Dart_GetNativeInstanceField(retobj, kNativeFld2, &field_value);
  EXPECT_VALID(result);
  EXPECT_EQ(0, field_value);
  result = Dart_GetNativeInstanceField(retobj, kNativeFld3, &field_value);
  EXPECT_VALID(result);
  EXPECT_EQ(0, field_value);
  result = Dart_SetNativeInstanceField(retobj, kNativeFld4, 40);
  EXPECT(Dart_IsError(result));
  result = Dart_SetNativeInstanceField(retobj, kNativeFld0, 4);
  EXPECT_VALID(result);
  result = Dart_SetNativeInstanceField(retobj, kNativeFld1, 40);
  EXPECT_VALID(result);
  result = Dart_SetNativeInstanceField(retobj, kNativeFld2, 400);
  EXPECT_VALID(result);
  result = Dart_SetNativeInstanceField(retobj, kNativeFld3, 4000);
  EXPECT_VALID(result);
  result = Dart_GetNativeInstanceField(retobj, kNativeFld3, &field_value);
  EXPECT_VALID(result);
  EXPECT_EQ(4000, field_value);

  // Now re-access various dart instance fields of the returned object
  // to ensure that there was no corruption while setting native fields.
  result = Dart_GetField(retobj, NewString("fld1"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(40, value);
  result = Dart_GetField(retobj, NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(20, value);
}

TEST_CASE(NativeFieldAccess) {
  const char* kScriptChars =
      "class NativeFields extends NativeFieldsWrapper {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld0;\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static const int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  const int kNumNativeFields = 4;

  // Create a test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, native_field_lookup,
                                             USER_TEST_URI, false);

  // Create a native wrapper class with native fields.
  Dart_Handle result = Dart_CreateNativeWrapperClass(
      lib, NewString("NativeFieldsWrapper"), kNumNativeFields);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  // Load up a test script in it.

  // Invoke a function which returns an object of type NativeFields.
  Dart_Handle retobj = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(retobj);

  // Now access and set various instance fields of the returned object.
  TestNativeFields(retobj);

  // Test that accessing an error handle propagates the error.
  Dart_Handle error = Api::NewError("myerror");
  intptr_t field_value = 0;

  result = Dart_GetNativeInstanceField(error, 0, &field_value);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("myerror", Dart_GetError(result));

  result = Dart_SetNativeInstanceField(error, 0, 1);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("myerror", Dart_GetError(result));
}

TEST_CASE(ImplicitNativeFieldAccess) {
  const char* kScriptChars =
      "import 'dart:nativewrappers';"
      "class NativeFields extends NativeFieldWrapperClass4 {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld0;\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static const int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  // Load up a test script in the test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, native_field_lookup);

  // Invoke a function which returns an object of type NativeFields.
  Dart_Handle retobj = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(retobj);

  // Now access and set various instance fields of the returned object.
  TestNativeFields(retobj);
}

TEST_CASE(NegativeNativeFieldAccess) {
  const char* kScriptChars =
      "class NativeFields {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static const int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain1() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n"
      "Function testMain2() {\n"
      "  return () {};\n"
      "}\n";
  Dart_Handle result;
  CHECK_API_SCOPE(thread);
  HANDLESCOPE(thread);

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns an object of type NativeFields.
  Dart_Handle retobj = Dart_Invoke(lib, NewString("testMain1"), 0, NULL);
  EXPECT_VALID(retobj);

  // Now access and set various native instance fields of the returned object.
  // All of these tests are expected to return failure as there are no
  // native fields in an instance of NativeFields.
  const int kNativeFld0 = 0;
  const int kNativeFld1 = 1;
  const int kNativeFld2 = 2;
  const int kNativeFld3 = 3;
  const int kNativeFld4 = 4;
  intptr_t value = 0;
  result = Dart_GetNativeInstanceField(retobj, kNativeFld4, &value);
  EXPECT(Dart_IsError(result));
  result = Dart_GetNativeInstanceField(retobj, kNativeFld0, &value);
  EXPECT(Dart_IsError(result));
  result = Dart_GetNativeInstanceField(retobj, kNativeFld1, &value);
  EXPECT(Dart_IsError(result));
  result = Dart_GetNativeInstanceField(retobj, kNativeFld2, &value);
  EXPECT(Dart_IsError(result));
  result = Dart_SetNativeInstanceField(retobj, kNativeFld4, 40);
  EXPECT(Dart_IsError(result));
  result = Dart_SetNativeInstanceField(retobj, kNativeFld3, 40);
  EXPECT(Dart_IsError(result));
  result = Dart_SetNativeInstanceField(retobj, kNativeFld0, 400);
  EXPECT(Dart_IsError(result));

  // Invoke a function which returns a closure object.
  retobj = Dart_Invoke(lib, NewString("testMain2"), 0, NULL);
  EXPECT_VALID(retobj);

  result = Dart_GetNativeInstanceField(retobj, kNativeFld4, &value);
  EXPECT(Dart_IsError(result));
  result = Dart_GetNativeInstanceField(retobj, kNativeFld0, &value);
  EXPECT(Dart_IsError(result));
  result = Dart_GetNativeInstanceField(retobj, kNativeFld1, &value);
  EXPECT(Dart_IsError(result));
  result = Dart_GetNativeInstanceField(retobj, kNativeFld2, &value);
  EXPECT(Dart_IsError(result));
  result = Dart_SetNativeInstanceField(retobj, kNativeFld4, 40);
  EXPECT(Dart_IsError(result));
  result = Dart_SetNativeInstanceField(retobj, kNativeFld3, 40);
  EXPECT(Dart_IsError(result));
  result = Dart_SetNativeInstanceField(retobj, kNativeFld0, 400);
  EXPECT(Dart_IsError(result));
}

TEST_CASE(NegativeNativeFieldInIsolateMessage) {
  const char* kScriptChars =
      "import 'dart:isolate';\n"
      "import 'dart:nativewrappers';\n"
      "echo(msg) {\n"
      "  var data = msg[0];\n"
      "  var reply = msg[1];\n"
      "  reply.send('echoing ${data(1)}}');\n"
      "}\n"
      "class Test extends NativeFieldWrapperClass2 {\n"
      "  Test(this.i, this.j);\n"
      "  int i, j;\n"
      "}\n"
      "main() {\n"
      "  var port = new RawReceivePort();\n"
      "  var obj = new Test(1,2);\n"
      "  var msg = [obj, port.sendPort];\n"
      "  var snd = Isolate.spawn(echo, msg);\n"
      "  port.handler = (msg) {\n"
      "    port.close();\n"
      "    print('from worker ${msg}');\n"
      "  };\n"
      "}\n";

  CHECK_API_SCOPE(thread);
  HANDLESCOPE(thread);

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke 'main' which should spawn an isolate and try to send an
  // object with native fields over to the spawned isolate. This
  // should result in an unhandled exception which is checked.
  Dart_Handle retobj = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT(Dart_IsError(retobj));
}

TEST_CASE(GetStaticField_RunsInitializer) {
  const char* kScriptChars =
      "class TestClass  {\n"
      "  static const int fld1 = 7;\n"
      "  static int fld2 = 11;\n"
      "  static void testMain() {\n"
      "  }\n"
      "}\n";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle type = Dart_GetType(lib, NewString("TestClass"), 0, NULL);
  EXPECT_VALID(type);

  // Invoke a function which returns an object.
  result = Dart_Invoke(type, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);

  // For uninitialized fields, the getter is returned
  result = Dart_GetField(type, NewString("fld1"));
  EXPECT_VALID(result);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(7, value);

  result = Dart_GetField(type, NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(11, value);

  // Overwrite fld2
  result = Dart_SetField(type, NewString("fld2"), Dart_NewInteger(13));
  EXPECT_VALID(result);

  // We now get the new value for fld2, not the initializer
  result = Dart_GetField(type, NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(13, value);
}

TEST_CASE(GetField_CheckIsolate) {
  const char* kScriptChars =
      "class TestClass  {\n"
      "  static int fld2 = 11;\n"
      "  static void testMain() {\n"
      "  }\n"
      "}\n";
  Dart_Handle result;
  int64_t value = 0;

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle type = Dart_GetType(lib, NewString("TestClass"), 0, NULL);
  EXPECT_VALID(type);

  result = Dart_GetField(type, NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(11, value);
}

TEST_CASE(SetField_CheckIsolate) {
  const char* kScriptChars =
      "class TestClass  {\n"
      "  static int fld2 = 11;\n"
      "  static void testMain() {\n"
      "  }\n"
      "}\n";
  Dart_Handle result;
  int64_t value = 0;

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle type = Dart_GetType(lib, NewString("TestClass"), 0, NULL);
  EXPECT_VALID(type);

  result = Dart_SetField(type, NewString("fld2"), Dart_NewInteger(13));
  EXPECT_VALID(result);

  result = Dart_GetField(type, NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(13, value);
}

TEST_CASE(New) {
  const char* kScriptChars =
      "class MyClass {\n"
      "  MyClass() : foo = 7 {}\n"
      "  MyClass.named(value) : foo = value {}\n"
      "  MyClass._hidden(value) : foo = -value {}\n"
      "  MyClass.exception(value) : foo = value {\n"
      "    throw 'ConstructorDeath';\n"
      "  }\n"
      "  factory MyClass.multiply(value) {\n"
      "    return new MyClass.named(value * 100);\n"
      "  }\n"
      "  factory MyClass.nullo() {\n"
      "    return null;\n"
      "  }\n"
      "  var foo;\n"
      "}\n"
      "\n"
      "abstract class MyExtraHop {\n"
      "  factory MyExtraHop.hop(value) = MyClass.named;\n"
      "}\n"
      "\n"
      "abstract class MyInterface {\n"
      "  factory MyInterface.named(value) = MyExtraHop.hop;\n"
      "  factory MyInterface.multiply(value) = MyClass.multiply;\n"
      "  MyInterface.notfound(value);\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle type = Dart_GetType(lib, NewString("MyClass"), 0, NULL);
  EXPECT_VALID(type);
  Dart_Handle intf = Dart_GetType(lib, NewString("MyInterface"), 0, NULL);
  EXPECT_VALID(intf);
  Dart_Handle args[1];
  args[0] = Dart_NewInteger(11);
  Dart_Handle bad_args[1];
  bad_args[0] = Dart_NewApiError("myerror");

  // Allocate and Invoke the unnamed constructor passing in Dart_Null.
  Dart_Handle result = Dart_New(type, Dart_Null(), 0, NULL);
  EXPECT_VALID(result);
  bool instanceOf = false;
  EXPECT_VALID(Dart_ObjectIsType(result, type, &instanceOf));
  EXPECT(instanceOf);
  int64_t int_value = 0;
  Dart_Handle foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(7, int_value);

  // Allocate without a constructor.
  Dart_Handle obj = Dart_Allocate(type);
  EXPECT_VALID(obj);
  instanceOf = false;
  EXPECT_VALID(Dart_ObjectIsType(obj, type, &instanceOf));
  EXPECT(instanceOf);
  foo = Dart_GetField(obj, NewString("foo"));
  EXPECT(Dart_IsNull(foo));

  // Allocate and Invoke the unnamed constructor passing in an empty string.
  result = Dart_New(type, Dart_EmptyString(), 0, NULL);
  EXPECT_VALID(result);
  instanceOf = false;
  EXPECT_VALID(Dart_ObjectIsType(result, type, &instanceOf));
  EXPECT(instanceOf);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(7, int_value);

  // Allocate object and invoke the unnamed constructor with an empty string.
  obj = Dart_Allocate(type);
  EXPECT_VALID(obj);
  instanceOf = false;
  EXPECT_VALID(Dart_ObjectIsType(obj, type, &instanceOf));
  EXPECT(instanceOf);
  // Use the empty string to invoke the unnamed constructor.
  result = Dart_InvokeConstructor(obj, Dart_EmptyString(), 0, NULL);
  EXPECT_VALID(result);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(7, int_value);
  // use Dart_Null to invoke the unnamed constructor.
  result = Dart_InvokeConstructor(obj, Dart_Null(), 0, NULL);
  EXPECT_VALID(result);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(7, int_value);

  // Invoke a named constructor.
  result = Dart_New(type, NewString("named"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, type, &instanceOf));
  EXPECT(instanceOf);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(11, int_value);

  // Allocate object and invoke a named constructor.
  obj = Dart_Allocate(type);
  EXPECT_VALID(obj);
  instanceOf = false;
  EXPECT_VALID(Dart_ObjectIsType(obj, type, &instanceOf));
  EXPECT(instanceOf);
  result = Dart_InvokeConstructor(obj, NewString("named"), 1, args);
  EXPECT_VALID(result);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(11, int_value);

  // Invoke a hidden named constructor.
  result = Dart_New(type, NewString("_hidden"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, type, &instanceOf));
  EXPECT(instanceOf);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(-11, int_value);

  // Allocate object and invoke a hidden named constructor.
  obj = Dart_Allocate(type);
  EXPECT_VALID(obj);
  instanceOf = false;
  EXPECT_VALID(Dart_ObjectIsType(obj, type, &instanceOf));
  EXPECT(instanceOf);
  result = Dart_InvokeConstructor(obj, NewString("_hidden"), 1, args);
  EXPECT_VALID(result);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(-11, int_value);

  // Allocate object and Invoke a constructor which throws an exception.
  obj = Dart_Allocate(type);
  EXPECT_VALID(obj);
  instanceOf = false;
  EXPECT_VALID(Dart_ObjectIsType(obj, type, &instanceOf));
  EXPECT(instanceOf);
  result = Dart_InvokeConstructor(obj, NewString("exception"), 1, args);
  EXPECT_ERROR(result, "ConstructorDeath");

  // Invoke a factory constructor.
  result = Dart_New(type, NewString("multiply"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, type, &instanceOf));
  EXPECT(instanceOf);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(1100, int_value);

  // Invoke a factory constructor which returns null.
  result = Dart_New(type, NewString("nullo"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsNull(result));

  // Pass an error class object.  Error is passed through.
  result = Dart_New(Dart_NewApiError("myerror"), NewString("named"), 1, args);
  EXPECT_ERROR(result, "myerror");

  // Pass a bad class object.
  result = Dart_New(Dart_Null(), NewString("named"), 1, args);
  EXPECT_ERROR(result, "Dart_New expects argument 'type' to be non-null.");

  // Pass a negative arg count.
  result = Dart_New(type, NewString("named"), -1, args);
  EXPECT_ERROR(
      result,
      "Dart_New expects argument 'number_of_arguments' to be non-negative.");

  // Pass the wrong arg count.
  result = Dart_New(type, NewString("named"), 0, NULL);
  EXPECT_ERROR(
      result,
      "Dart_New: wrong argument count for constructor 'MyClass.named': "
      "0 passed, 1 expected.");

  // Pass a bad argument.  Error is passed through.
  result = Dart_New(type, NewString("named"), 1, bad_args);
  EXPECT_ERROR(result, "myerror");

  // Pass a bad constructor name.
  result = Dart_New(type, Dart_NewInteger(55), 1, args);
  EXPECT_ERROR(
      result,
      "Dart_New expects argument 'constructor_name' to be of type String.");

  // Invoke a missing constructor.
  result = Dart_New(type, NewString("missing"), 1, args);
  EXPECT_ERROR(result,
               "Dart_New: could not find constructor 'MyClass.missing'.");

  // Invoke a constructor which throws an exception.
  result = Dart_New(type, NewString("exception"), 1, args);
  EXPECT_ERROR(result, "ConstructorDeath");

  // Invoke two-hop redirecting factory constructor.
  result = Dart_New(intf, NewString("named"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, type, &instanceOf));
  EXPECT(instanceOf);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(11, int_value);

  // Invoke one-hop redirecting factory constructor.
  result = Dart_New(intf, NewString("multiply"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, type, &instanceOf));
  EXPECT(instanceOf);
  int_value = 0;
  foo = Dart_GetField(result, NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(1100, int_value);

  // Invoke a constructor that is missing in the interface.
  result = Dart_New(intf, Dart_Null(), 0, NULL);
  EXPECT_ERROR(result, "Dart_New: could not find constructor 'MyInterface.'.");

  // Invoke abstract constructor that is present in the interface.
  result = Dart_New(intf, NewString("notfound"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, type, &instanceOf));
  EXPECT(!instanceOf);
}

TEST_CASE(New_Issue2971) {
  // Issue 2971: We were unable to use Dart_New to construct an
  // instance of List, due to problems implementing interface
  // factories.
  Dart_Handle core_lib = Dart_LookupLibrary(NewString("dart:core"));
  EXPECT_VALID(core_lib);
  Dart_Handle list_type = Dart_GetType(core_lib, NewString("List"), 0, NULL);
  EXPECT_VALID(list_type);

  const int kNumArgs = 1;
  Dart_Handle args[kNumArgs];
  args[0] = Dart_NewInteger(1);
  Dart_Handle list_obj = Dart_New(list_type, Dart_Null(), kNumArgs, args);
  EXPECT_VALID(list_obj);
  EXPECT(Dart_IsList(list_obj));
}

static Dart_Handle PrivateLibName(Dart_Handle lib, const char* str) {
  EXPECT(Dart_IsLibrary(lib));
  Thread* thread = Thread::Current();
  const Library& library_obj = Api::UnwrapLibraryHandle(thread->zone(), lib);
  const String& name = String::Handle(String::New(str));
  return Api::NewHandle(thread, library_obj.PrivateName(name));
}

TEST_CASE(Invoke) {
  const char* kScriptChars =
      "class BaseMethods {\n"
      "  inheritedMethod(arg) => 'inherited $arg';\n"
      "  static nonInheritedMethod(arg) => 'noninherited $arg';\n"
      "}\n"
      "\n"
      "class Methods extends BaseMethods {\n"
      "  instanceMethod(arg) => 'instance $arg';\n"
      "  _instanceMethod(arg) => 'hidden instance $arg';\n"
      "  static staticMethod(arg) => 'static $arg';\n"
      "  static _staticMethod(arg) => 'hidden static $arg';\n"
      "}\n"
      "\n"
      "topMethod(arg) => 'top $arg';\n"
      "_topMethod(arg) => 'hidden top $arg';\n"
      "\n"
      "Methods test() {\n"
      "  return new Methods();\n"
      "}\n";

  // Shared setup.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle type = Dart_GetType(lib, NewString("Methods"), 0, NULL);
  EXPECT_VALID(type);
  Dart_Handle instance = Dart_Invoke(lib, NewString("test"), 0, NULL);
  EXPECT_VALID(instance);
  Dart_Handle args[1];
  args[0] = NewString("!!!");
  Dart_Handle bad_args[2];
  bad_args[0] = NewString("bad1");
  bad_args[1] = NewString("bad2");
  Dart_Handle result;
  Dart_Handle name;
  const char* str;

  // Instance method.
  name = NewString("instanceMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(type, name, 1, args)));
  result = Dart_Invoke(instance, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("instance !!!", str);

  // Instance method, wrong arg count.
  EXPECT_ERROR(Dart_Invoke(instance, name, 2, bad_args),
               "Class 'Methods' has no instance method 'instanceMethod'"
               " with matching arguments");

  name = PrivateLibName(lib, "_instanceMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(type, name, 1, args)));
  result = Dart_Invoke(instance, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("hidden instance !!!", str);

  // Inherited method.
  name = NewString("inheritedMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(type, name, 1, args)));
  result = Dart_Invoke(instance, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("inherited !!!", str);

  // Static method.
  name = NewString("staticMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  result = Dart_Invoke(type, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("static !!!", str);

  // Static method, wrong arg count.
  EXPECT_ERROR(Dart_Invoke(type, name, 2, bad_args),
               "did not find static method 'Methods.staticMethod'");

  // Hidden static method.
  name = NewString("_staticMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  result = Dart_Invoke(type, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("hidden static !!!", str);

  // Static non-inherited method.  Not found at any level.
  name = NewString("non_inheritedMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(type, name, 1, args)));

  // Top-Level method.
  name = NewString("topMethod");
  EXPECT(Dart_IsError(Dart_Invoke(type, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  result = Dart_Invoke(lib, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("top !!!", str);

  // Top-level method, wrong arg count.
  EXPECT_ERROR(Dart_Invoke(lib, name, 2, bad_args),
               "Dart_Invoke: wrong argument count for function 'topMethod': "
               "2 passed, 1 expected.");

  // Hidden top-level method.
  name = NewString("_topMethod");
  EXPECT(Dart_IsError(Dart_Invoke(type, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  result = Dart_Invoke(lib, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("hidden top !!!", str);
}

TEST_CASE(Invoke_PrivateStatic) {
  const char* kScriptChars =
      "class Methods {\n"
      "  static _staticMethod(arg) => 'hidden static $arg';\n"
      "}\n"
      "\n";

  // Shared setup.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle type = Dart_GetType(lib, NewString("Methods"), 0, NULL);
  Dart_Handle result;
  EXPECT_VALID(type);
  Dart_Handle name = NewString("_staticMethod");
  EXPECT_VALID(name);

  Dart_Handle args[1];
  args[0] = NewString("!!!");
  result = Dart_Invoke(type, name, 1, args);
  EXPECT_VALID(result);

  const char* str = NULL;
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("hidden static !!!", str);
}

TEST_CASE(Invoke_FunnyArgs) {
  const char* kScriptChars = "test(arg) => 'hello $arg';\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle func_name = NewString("test");
  Dart_Handle args[1];
  const char* str;

  // Make sure that valid args yield valid results.
  args[0] = NewString("!!!");
  Dart_Handle result = Dart_Invoke(lib, func_name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("hello !!!", str);

  // Make sure that null is legal.
  args[0] = Dart_Null();
  result = Dart_Invoke(lib, func_name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("hello null", str);

  // Pass an error handle as the target.  The error is propagated.
  result = Dart_Invoke(Api::NewError("myerror"), func_name, 1, args);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("myerror", Dart_GetError(result));

  // Pass an error handle as the function name.  The error is propagated.
  result = Dart_Invoke(lib, Api::NewError("myerror"), 1, args);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("myerror", Dart_GetError(result));

  // Pass a non-instance handle as a parameter..
  args[0] = lib;
  result = Dart_Invoke(lib, func_name, 1, args);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_Invoke expects arguments[0] to be an Instance handle.",
               Dart_GetError(result));

  // Pass an error handle as a parameter.  The error is propagated.
  args[0] = Api::NewError("myerror");
  result = Dart_Invoke(lib, func_name, 1, args);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("myerror", Dart_GetError(result));
}

TEST_CASE(Invoke_Null) {
  Dart_Handle result = Dart_Invoke(Dart_Null(), NewString("toString"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));

  const char* value = "";
  EXPECT_VALID(Dart_StringToCString(result, &value));
  EXPECT_STREQ("null", value);

  Dart_Handle function_name = NewString("NoNoNo");
  result = Dart_Invoke(Dart_Null(), function_name, 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
}

TEST_CASE(InvokeNoSuchMethod) {
  const char* kScriptChars =
      "import 'dart:_internal' as _internal;\n"
      "class Expect {\n"
      "  static equals(a, b) {\n"
      "    if (a != b) {\n"
      "      throw 'not equal. expected: $a, got: $b';\n"
      "    }\n"
      "  }\n"
      "}\n"
      "class TestClass {\n"
      "  static int fld1 = 0;\n"
      "  void noSuchMethod(Invocation invocation) {\n"
      "    var name = _internal.Symbol.getName(invocation.memberName);\n"
      "    if (name == 'fld') {\n"
      "      Expect.equals(true, invocation.isGetter);\n"
      "      Expect.equals(false, invocation.isMethod);\n"
      "      Expect.equals(false, invocation.isSetter);\n"
      "    } else if (name == 'setfld') {\n"
      "      Expect.equals(true, invocation.isSetter);\n"
      "      Expect.equals(false, invocation.isMethod);\n"
      "      Expect.equals(false, invocation.isGetter);\n"
      "    } else if (name == 'method') {\n"
      "      Expect.equals(true, invocation.isMethod);\n"
      "      Expect.equals(false, invocation.isSetter);\n"
      "      Expect.equals(false, invocation.isGetter);\n"
      "    }\n"
      "    TestClass.fld1 += 1;\n"
      "  }\n"
      "  static TestClass testMain() {\n"
      "    return new TestClass();\n"
      "  }\n"
      "}\n";
  Dart_Handle result;
  Dart_Handle instance;
  // Create a test library and Load up a test script in it.
  // The test library must have a dart: url so it can import dart:_internal.
  Dart_Handle lib = TestCase::LoadCoreTestScript(kScriptChars, NULL);
  Dart_Handle type = Dart_GetType(lib, NewString("TestClass"), 0, NULL);
  EXPECT_VALID(type);

  // Invoke a function which returns an object.
  instance = Dart_Invoke(type, NewString("testMain"), 0, NULL);
  EXPECT_VALID(instance);

  // Try to get a field that does not exist, should call noSuchMethod.
  result = Dart_GetField(instance, NewString("fld"));
  EXPECT_VALID(result);

  // Try to set a field that does not exist, should call noSuchMethod.
  result = Dart_SetField(instance, NewString("setfld"), Dart_NewInteger(13));
  EXPECT_VALID(result);

  // Try to invoke a method that does not exist, should call noSuchMethod.
  result = Dart_Invoke(instance, NewString("method"), 0, NULL);
  EXPECT_VALID(result);

  result = Dart_GetField(type, NewString("fld1"));
  EXPECT_VALID(result);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(3, value);
}

TEST_CASE(Invoke_CrossLibrary) {
  const char* kLibrary1Chars =
      "library library1_name;\n"
      "void local() {}\n"
      "void _local() {}\n";
  const char* kLibrary2Chars =
      "library library2_name;\n"
      "void imported() {}\n"
      "void _imported() {}\n";

  // Load lib1
  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle lib1 = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib1);

  // Load lib2
  url = NewString("library2_url");
  source = NewString(kLibrary2Chars);
  Dart_Handle lib2 = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib2);

  // Import lib2 from lib1
  Dart_Handle result = Dart_LibraryImportLibrary(lib1, lib2, Dart_Null());
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  // We can invoke both private and non-private local functions.
  EXPECT_VALID(Dart_Invoke(lib1, NewString("local"), 0, NULL));
  EXPECT_VALID(Dart_Invoke(lib1, NewString("_local"), 0, NULL));

  // We can only invoke non-private imported functions.
  EXPECT_VALID(Dart_Invoke(lib1, NewString("imported"), 0, NULL));
  EXPECT_ERROR(Dart_Invoke(lib1, NewString("_imported"), 0, NULL),
               "did not find top-level function '_imported'");
}

TEST_CASE(InvokeClosure) {
  const char* kScriptChars =
      "class InvokeClosure {\n"
      "  InvokeClosure(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  Function method1(int i) {\n"
      "    f(int j) => j + i + fld1 + fld2 + fld4; \n"
      "    return f;\n"
      "  }\n"
      "  static Function method2(int i) {\n"
      "    n(int j) => true + i + fld4; \n"
      "    return n;\n"
      "  }\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static const int fld4 = 10;\n"
      "}\n"
      "Function testMain1() {\n"
      "  InvokeClosure obj = new InvokeClosure(10, 20);\n"
      "  return obj.method1(10);\n"
      "}\n"
      "Function testMain2() {\n"
      "  return InvokeClosure.method2(10);\n"
      "}\n";
  Dart_Handle result;
  CHECK_API_SCOPE(thread);
  HANDLESCOPE(thread);

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns a closure.
  Dart_Handle retobj = Dart_Invoke(lib, NewString("testMain1"), 0, NULL);
  EXPECT_VALID(retobj);

  EXPECT(Dart_IsClosure(retobj));
  EXPECT(!Dart_IsClosure(Dart_NewInteger(101)));

  // Now invoke the closure and check the result.
  Dart_Handle dart_arguments[1];
  dart_arguments[0] = Dart_NewInteger(1);
  result = Dart_InvokeClosure(retobj, 1, dart_arguments);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(51, value);

  // Invoke closure with wrong number of args, should result in exception.
  result = Dart_InvokeClosure(retobj, 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));

  // Invoke a function which returns a closure.
  retobj = Dart_Invoke(lib, NewString("testMain2"), 0, NULL);
  EXPECT_VALID(retobj);

  EXPECT(Dart_IsClosure(retobj));
  EXPECT(!Dart_IsClosure(NewString("abcdef")));

  // Now invoke the closure and check the result (should be an exception).
  dart_arguments[0] = Dart_NewInteger(1);
  result = Dart_InvokeClosure(retobj, 1, dart_arguments);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
}

void ExceptionNative(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_ThrowException(NewString("Hello from ExceptionNative!"));
  UNREACHABLE();
}

static Dart_NativeFunction native_lookup(Dart_Handle name,
                                         int argument_count,
                                         bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  return reinterpret_cast<Dart_NativeFunction>(&ExceptionNative);
}

TEST_CASE(ThrowException) {
  const char* kScriptChars = "int test() native \"ThrowException_native\";";
  Dart_Handle result;
  intptr_t size = thread->ZoneSizeInBytes();
  Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

  // Load up a test script which extends the native wrapper class.
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, reinterpret_cast<Dart_NativeEntryResolver>(native_lookup));

  // Throwing an exception here should result in an error.
  result = Dart_ThrowException(NewString("This doesn't work"));
  EXPECT_ERROR(result, "No Dart frames on stack, cannot throw exception");
  EXPECT(!Dart_ErrorHasException(result));

  // Invoke 'test' and check for an uncaught exception.
  result = Dart_Invoke(lib, NewString("test"), 0, NULL);
  EXPECT_ERROR(result, "Hello from ExceptionNative!");
  EXPECT(Dart_ErrorHasException(result));

  Dart_ExitScope();  // Exit the Dart API scope.
  EXPECT_EQ(size, thread->ZoneSizeInBytes());
}

static intptr_t kNativeArgumentNativeField1Value = 30;
static intptr_t kNativeArgumentNativeField2Value = 40;
static intptr_t native_arg_str_peer = 100;
static void NativeArgumentCreate(Dart_NativeArguments args) {
  Dart_Handle lib = Dart_LookupLibrary(NewString(TestCase::url()));
  Dart_Handle type = Dart_GetType(lib, NewString("MyObject"), 0, NULL);
  EXPECT_VALID(type);

  // Allocate without a constructor.
  const int num_native_fields = 2;
  const intptr_t native_fields[] = {kNativeArgumentNativeField1Value,
                                    kNativeArgumentNativeField2Value};
  // Allocate and Setup native fields.
  Dart_Handle obj =
      Dart_AllocateWithNativeFields(type, num_native_fields, native_fields);
  EXPECT_VALID(obj);

  kNativeArgumentNativeField1Value *= 2;
  kNativeArgumentNativeField2Value *= 2;
  Dart_SetReturnValue(args, obj);
}

static void NativeArgumentAccess(Dart_NativeArguments args) {
  const int kNumNativeFields = 2;

  // Test different argument types with a valid descriptor set.
  {
    const char* cstr = NULL;
    intptr_t native_fields1[kNumNativeFields];
    intptr_t native_fields2[kNumNativeFields];
    const Dart_NativeArgument_Descriptor arg_descriptors[9] = {
        {Dart_NativeArgument_kNativeFields, 0},
        {Dart_NativeArgument_kInt32, 1},
        {Dart_NativeArgument_kUint64, 2},
        {Dart_NativeArgument_kBool, 3},
        {Dart_NativeArgument_kDouble, 4},
        {Dart_NativeArgument_kString, 5},
        {Dart_NativeArgument_kString, 6},
        {Dart_NativeArgument_kNativeFields, 7},
        {Dart_NativeArgument_kInstance, 7},
    };
    Dart_NativeArgument_Value arg_values[9];
    arg_values[0].as_native_fields.num_fields = kNumNativeFields;
    arg_values[0].as_native_fields.values = native_fields1;
    arg_values[7].as_native_fields.num_fields = kNumNativeFields;
    arg_values[7].as_native_fields.values = native_fields2;
    Dart_Handle result =
        Dart_GetNativeArguments(args, 9, arg_descriptors, arg_values);
    EXPECT_VALID(result);

    EXPECT(arg_values[0].as_native_fields.values[0] == 30);
    EXPECT(arg_values[0].as_native_fields.values[1] == 40);

    EXPECT(arg_values[1].as_int32 == 77);

    EXPECT(arg_values[2].as_uint64 == 0xffffffffffffffffLL);

    EXPECT(arg_values[3].as_bool == true);

    EXPECT(arg_values[4].as_double == 3.14);

    EXPECT_VALID(arg_values[5].as_string.dart_str);
    EXPECT(Dart_IsString(arg_values[5].as_string.dart_str));
    EXPECT_VALID(Dart_StringToCString(arg_values[5].as_string.dart_str, &cstr));
    EXPECT_STREQ("abcdefg", cstr);
    EXPECT(arg_values[5].as_string.peer == NULL);

    EXPECT(arg_values[6].as_string.dart_str == NULL);
    EXPECT(arg_values[6].as_string.peer ==
           reinterpret_cast<void*>(&native_arg_str_peer));

    EXPECT(arg_values[7].as_native_fields.values[0] == 60);
    EXPECT(arg_values[7].as_native_fields.values[1] == 80);

    EXPECT_VALID(arg_values[8].as_instance);
    EXPECT(Dart_IsInstance(arg_values[8].as_instance));
    int field_count = 0;
    EXPECT_VALID(Dart_GetNativeInstanceFieldCount(arg_values[8].as_instance,
                                                  &field_count));
    EXPECT(field_count == 2);
  }

  // Test with an invalid descriptor set (invalid type).
  {
    const Dart_NativeArgument_Descriptor arg_descriptors[8] = {
        {Dart_NativeArgument_kInt32, 1},
        {Dart_NativeArgument_kUint64, 2},
        {Dart_NativeArgument_kString, 3},
        {Dart_NativeArgument_kDouble, 4},
        {Dart_NativeArgument_kString, 5},
        {Dart_NativeArgument_kString, 6},
        {Dart_NativeArgument_kNativeFields, 0},
        {Dart_NativeArgument_kNativeFields, 7},
    };
    Dart_NativeArgument_Value arg_values[8];
    Dart_Handle result =
        Dart_GetNativeArguments(args, 8, arg_descriptors, arg_values);
    EXPECT(Dart_IsError(result));
  }

  // Test with an invalid range error.
  {
    const Dart_NativeArgument_Descriptor arg_descriptors[8] = {
        {Dart_NativeArgument_kInt32, 2},
        {Dart_NativeArgument_kUint64, 2},
        {Dart_NativeArgument_kBool, 3},
        {Dart_NativeArgument_kDouble, 4},
        {Dart_NativeArgument_kString, 5},
        {Dart_NativeArgument_kString, 6},
        {Dart_NativeArgument_kNativeFields, 0},
        {Dart_NativeArgument_kNativeFields, 7},
    };
    Dart_NativeArgument_Value arg_values[8];
    Dart_Handle result =
        Dart_GetNativeArguments(args, 8, arg_descriptors, arg_values);
    EXPECT(Dart_IsError(result));
  }

  Dart_SetIntegerReturnValue(args, 0);
}

static Dart_NativeFunction native_args_lookup(Dart_Handle name,
                                              int argument_count,
                                              bool* auto_scope_setup) {
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  if (!obj.IsString()) {
    return NULL;
  }
  ASSERT(auto_scope_setup != NULL);
  *auto_scope_setup = true;
  const char* function_name = obj.ToCString();
  ASSERT(function_name != NULL);
  if (!strcmp(function_name, "NativeArgument_Create")) {
    return reinterpret_cast<Dart_NativeFunction>(&NativeArgumentCreate);
  } else if (!strcmp(function_name, "NativeArgument_Access")) {
    return reinterpret_cast<Dart_NativeFunction>(&NativeArgumentAccess);
  }
  return NULL;
}

TEST_CASE(GetNativeArguments) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "import 'dart:nativewrappers';"
      "class MyObject extends NativeFieldWrapperClass2 {"
      "  static MyObject createObject() native 'NativeArgument_Create';"
      "  int accessFields(int arg1,"
      "                   int arg2,"
      "                   bool arg3,"
      "                   double arg4,"
      "                   String arg5,"
      "                   String arg6,"
      "                   MyObject arg7) native 'NativeArgument_Access';"
      "}"
      "int testMain(String extstr) {"
      "  String str = 'abcdefg';"
      "  MyObject obj1 = MyObject.createObject();"
      "  MyObject obj2 = MyObject.createObject();"
      "  return obj1.accessFields(77,"
      "                           0xffffffffffffffff,"
      "                           true,"
      "                           3.14,"
      "                           str,"
      "                           extstr,"
      "                           obj2);"
      "}";

  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars,
      reinterpret_cast<Dart_NativeEntryResolver>(native_args_lookup));

  intptr_t size;
  Dart_Handle ascii_str = NewString("string");
  EXPECT_VALID(ascii_str);
  EXPECT_VALID(Dart_StringStorageSize(ascii_str, &size));
  uint8_t ext_ascii_str[10];
  Dart_Handle extstr = Dart_MakeExternalString(
      ascii_str, ext_ascii_str, size,
      reinterpret_cast<void*>(&native_arg_str_peer), NULL);

  Dart_Handle args[1];
  args[0] = extstr;
  Dart_Handle result = Dart_Invoke(lib, NewString("testMain"), 1, args);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));

  FLAG_support_externalizable_strings = saved_flag;
}

static void NativeArgumentCounter(Dart_NativeArguments args) {
  Dart_EnterScope();
  int count = Dart_GetNativeArgumentCount(args);
  Dart_SetReturnValue(args, Dart_NewInteger(count));
  Dart_ExitScope();
}

static Dart_NativeFunction gnac_lookup(Dart_Handle name,
                                       int argument_count,
                                       bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  return reinterpret_cast<Dart_NativeFunction>(&NativeArgumentCounter);
}

TEST_CASE(GetNativeArgumentCount) {
  const char* kScriptChars =
      "class MyObject {"
      "  int method1(int i, int j) native 'Name_Does_Not_Matter';"
      "}"
      "testMain() {"
      "  MyObject obj = new MyObject();"
      "  return obj.method1(77, 125);"
      "}";

  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, reinterpret_cast<Dart_NativeEntryResolver>(gnac_lookup));

  Dart_Handle result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));

  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(3, value);
}

TEST_CASE(GetType) {
  const char* kScriptChars =
      "library testlib;\n"
      "class Class {\n"
      "  static var name = 'Class';\n"
      "}\n"
      "\n"
      "class _Class {\n"
      "  static var name = '_Class';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Lookup a class.
  Dart_Handle type = Dart_GetType(lib, NewString("Class"), 0, NULL);
  EXPECT_VALID(type);
  Dart_Handle name = Dart_GetField(type, NewString("name"));
  EXPECT_VALID(name);
  const char* name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(name, &name_cstr));
  EXPECT_STREQ("Class", name_cstr);

  // Lookup a private class.
  type = Dart_GetType(lib, NewString("_Class"), 0, NULL);
  EXPECT_VALID(type);
  name = Dart_GetField(type, NewString("name"));
  EXPECT_VALID(name);
  name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(name, &name_cstr));
  EXPECT_STREQ("_Class", name_cstr);

  // Lookup a class that does not exist.
  type = Dart_GetType(lib, NewString("DoesNotExist"), 0, NULL);
  EXPECT(Dart_IsError(type));
  EXPECT_STREQ("Type 'DoesNotExist' not found in library 'testlib'.",
               Dart_GetError(type));

  // Lookup a class from an error library.  The error propagates.
  type = Dart_GetType(Api::NewError("myerror"), NewString("Class"), 0, NULL);
  EXPECT(Dart_IsError(type));
  EXPECT_STREQ("myerror", Dart_GetError(type));

  // Lookup a type using an error class name.  The error propagates.
  type = Dart_GetType(lib, Api::NewError("myerror"), 0, NULL);
  EXPECT(Dart_IsError(type));
  EXPECT_STREQ("myerror", Dart_GetError(type));
}

TEST_CASE(InstanceOf) {
  const char* kScriptChars =
      "class OtherClass {\n"
      "  static returnNull() { return null; }\n"
      "}\n"
      "class InstanceOfTest {\n"
      "  InstanceOfTest() {}\n"
      "  static InstanceOfTest testMain() {\n"
      "    return new InstanceOfTest();\n"
      "  }\n"
      "}\n";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Fetch InstanceOfTest class.
  Dart_Handle type = Dart_GetType(lib, NewString("InstanceOfTest"), 0, NULL);
  EXPECT_VALID(type);

  // Invoke a function which returns an object of type InstanceOf..
  Dart_Handle instanceOfTestObj =
      Dart_Invoke(type, NewString("testMain"), 0, NULL);
  EXPECT_VALID(instanceOfTestObj);

  // Now check instanceOfTestObj reported as an instance of
  // InstanceOfTest class.
  bool is_instance = false;
  result = Dart_ObjectIsType(instanceOfTestObj, type, &is_instance);
  EXPECT_VALID(result);
  EXPECT(is_instance);

  // Fetch OtherClass and check if instanceOfTestObj is instance of it.
  Dart_Handle otherType = Dart_GetType(lib, NewString("OtherClass"), 0, NULL);
  EXPECT_VALID(otherType);

  result = Dart_ObjectIsType(instanceOfTestObj, otherType, &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  // Check that primitives are not instances of InstanceOfTest class.
  result = Dart_ObjectIsType(NewString("a string"), otherType, &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  result = Dart_ObjectIsType(Dart_NewInteger(42), otherType, &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  result = Dart_ObjectIsType(Dart_NewBoolean(true), otherType, &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  // Check that null is not an instance of InstanceOfTest class.
  Dart_Handle null = Dart_Invoke(otherType, NewString("returnNull"), 0, NULL);
  EXPECT_VALID(null);

  result = Dart_ObjectIsType(null, otherType, &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  // Check that error is returned if null is passed as a class argument.
  result = Dart_ObjectIsType(null, null, &is_instance);
  EXPECT(Dart_IsError(result));
}

static Dart_Handle library_handler(Dart_LibraryTag tag,
                                   Dart_Handle library,
                                   Dart_Handle url) {
  if (tag == Dart_kCanonicalizeUrl) {
    return url;
  }
  return Api::Success();
}

TEST_CASE(LoadScript) {
  const char* kScriptChars =
      "main() {"
      "  return 12345;"
      "}";
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  Dart_Handle error = Dart_NewApiError("incoming error");
  Dart_Handle result;

  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);

  result = Dart_LoadScript(Dart_Null(), Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript expects argument 'url' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadScript(Dart_True(), Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript expects argument 'url' to be of type String.",
               Dart_GetError(result));

  result = Dart_LoadScript(error, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadScript(url, Dart_True(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadScript expects argument 'resolved_url' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadScript(url, error, source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadScript(url, Dart_Null(), Dart_Null(), 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript expects argument 'source' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadScript(url, Dart_Null(), Dart_True(), 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadScript expects argument 'source' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadScript(url, Dart_Null(), error, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  // Load a script successfully.
  result = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);
  Dart_FinalizeLoading(false);

  result = Dart_Invoke(result, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(12345, value);

  // Further calls to LoadScript are errors.
  result = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadScript: "
      "A script has already been loaded from 'test-lib'.",
      Dart_GetError(result));
}

TEST_CASE(RootLibrary) {
  const char* kScriptChars =
      "library testlib;"
      "main() {"
      "  return 12345;"
      "}";

  Dart_Handle root_lib = Dart_RootLibrary();
  EXPECT_VALID(root_lib);
  EXPECT(Dart_IsNull(root_lib));

  // Load a script.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  EXPECT_VALID(Dart_LoadScript(url, Dart_Null(), source, 0, 0));

  root_lib = Dart_RootLibrary();
  Dart_Handle lib_name = Dart_LibraryName(root_lib);
  EXPECT_VALID(lib_name);
  EXPECT(!Dart_IsNull(root_lib));
  const char* name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(lib_name, &name_cstr));
  EXPECT_STREQ("testlib", name_cstr);

  Dart_Handle lib_uri = Dart_LibraryUrl(root_lib);
  EXPECT_VALID(lib_uri);
  EXPECT(!Dart_IsNull(lib_uri));
  const char* uri_cstr = "";
  EXPECT_VALID(Dart_StringToCString(lib_uri, &uri_cstr));
  EXPECT_STREQ(TestCase::url(), uri_cstr);

  Dart_Handle core_uri = Dart_NewStringFromCString("dart:core");
  Dart_Handle core_lib = Dart_LookupLibrary(core_uri);
  EXPECT_VALID(core_lib);
  EXPECT(Dart_IsLibrary(core_lib));

  Dart_Handle result = Dart_SetRootLibrary(core_uri);  // Not a library.
  EXPECT(Dart_IsError(result));
  root_lib = Dart_RootLibrary();
  lib_uri = Dart_LibraryUrl(root_lib);
  EXPECT_VALID(Dart_StringToCString(lib_uri, &uri_cstr));
  EXPECT_STREQ(TestCase::url(), uri_cstr);  // Root library didn't change.

  result = Dart_SetRootLibrary(core_lib);
  EXPECT_VALID(result);
  root_lib = Dart_RootLibrary();
  lib_uri = Dart_LibraryUrl(root_lib);
  EXPECT_VALID(Dart_StringToCString(lib_uri, &uri_cstr));
  EXPECT_STREQ("dart:core", uri_cstr);  // Root library did change.

  result = Dart_SetRootLibrary(Dart_Null());
  EXPECT_VALID(result);
  root_lib = Dart_RootLibrary();
  EXPECT(Dart_IsNull(root_lib));  // Root library did change.
}

static int index = 0;

static Dart_Handle import_library_handler(Dart_LibraryTag tag,
                                          Dart_Handle library,
                                          Dart_Handle url) {
  if (tag == Dart_kCanonicalizeUrl) {
    return url;
  }
  EXPECT(Dart_IsString(url));
  const char* cstr = NULL;
  EXPECT_VALID(Dart_StringToCString(url, &cstr));
  switch (index) {
    case 0:
      EXPECT_STREQ("./weird.dart", cstr);
      break;
    case 1:
      EXPECT_STREQ("abclaladef", cstr);
      break;
    case 2:
      EXPECT_STREQ("winner", cstr);
      break;
    case 3:
      EXPECT_STREQ("abclaladef/extra_weird.dart", cstr);
      break;
    case 4:
      EXPECT_STREQ("winnerwinner", cstr);
      break;
    default:
      EXPECT(false);
      return Api::NewError("invalid callback");
  }
  index += 1;
  return Api::Success();
}

TEST_CASE(LoadScript_CompileError) {
  const char* kScriptChars = ")";
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  Dart_Handle result = Dart_SetLibraryTagHandler(import_library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT(strstr(Dart_GetError(result), "unexpected token ')'"));
}

TEST_CASE(LookupLibrary) {
  const char* kScriptChars =
      "import 'library1_dart';"
      "main() {}";
  const char* kLibrary1Chars =
      "library library1_dart;"
      "import 'library2_dart';";

  // Create a test library and Load up a test script in it.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  Dart_Handle result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);

  url = NewString("library1_dart");
  source = NewString(kLibrary1Chars);
  result = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);

  result = Dart_LookupLibrary(url);
  EXPECT_VALID(result);

  result = Dart_LookupLibrary(Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LookupLibrary expects argument 'url' to be non-null.",
               Dart_GetError(result));

  result = Dart_LookupLibrary(Dart_True());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LookupLibrary expects argument 'url' to be of type String.",
      Dart_GetError(result));

  result = Dart_LookupLibrary(Dart_NewApiError("incoming error"));
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  url = NewString("noodles.dart");
  result = Dart_LookupLibrary(url);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LookupLibrary: library 'noodles.dart' not found.",
               Dart_GetError(result));
}

TEST_CASE(LibraryName) {
  const char* kLibrary1Chars = "library library1_name;";
  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  Dart_Handle error = Dart_NewApiError("incoming error");
  EXPECT_VALID(lib);

  Dart_Handle result = Dart_LibraryName(Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LibraryName expects argument 'library' to be non-null.",
               Dart_GetError(result));

  result = Dart_LibraryName(Dart_True());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LibraryName expects argument 'library' to be of type Library.",
      Dart_GetError(result));

  result = Dart_LibraryName(error);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LibraryName(lib);
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));
  const char* cstr = NULL;
  EXPECT_VALID(Dart_StringToCString(result, &cstr));
  EXPECT_STREQ("library1_name", cstr);
}

#ifndef PRODUCT

TEST_CASE(LibraryId) {
  const char* kLibrary1Chars = "library library1_name;";
  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  Dart_Handle error = Dart_NewApiError("incoming error");
  EXPECT_VALID(lib);
  intptr_t libraryId = -1;

  Dart_Handle result = Dart_LibraryId(Dart_Null(), &libraryId);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LibraryId expects argument 'library' to be non-null.",
               Dart_GetError(result));

  result = Dart_LibraryId(Dart_True(), &libraryId);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LibraryId expects argument 'library' to be of type Library.",
      Dart_GetError(result));

  result = Dart_LibraryId(error, &libraryId);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LibraryId(lib, &libraryId);
  EXPECT_VALID(result);
  Dart_Handle libFromId = Dart_GetLibraryFromId(libraryId);
  EXPECT(Dart_IsLibrary(libFromId));
  result = Dart_LibraryName(libFromId);
  EXPECT(Dart_IsString(result));
  const char* cstr = NULL;
  EXPECT_VALID(Dart_StringToCString(result, &cstr));
  EXPECT_STREQ("library1_name", cstr);
}

#endif  // !PRODUCT

TEST_CASE(LibraryUrl) {
  const char* kLibrary1Chars = "library library1_name;";
  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  Dart_Handle error = Dart_NewApiError("incoming error");
  EXPECT_VALID(lib);

  Dart_Handle result = Dart_LibraryUrl(Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LibraryUrl expects argument 'library' to be non-null.",
               Dart_GetError(result));

  result = Dart_LibraryUrl(Dart_True());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LibraryUrl expects argument 'library' to be of type Library.",
      Dart_GetError(result));

  result = Dart_LibraryUrl(error);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LibraryUrl(lib);
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));
  const char* cstr = NULL;
  EXPECT_VALID(Dart_StringToCString(result, &cstr));
  EXPECT_STREQ("library1_url", cstr);
}

TEST_CASE(LibraryGetClassNames) {
  const char* kLibraryChars =
      "library library_name;\n"
      "\n"
      "class A {}\n"
      "class B {}\n"
      "abstract class C {}\n"
      "class _A {}\n"
      "class _B {}\n"
      "abstract class _C {}\n"
      "\n"
      "_compare(String a, String b) => a.compareTo(b);\n"
      "sort(list) => list.sort(_compare);\n";

  Dart_Handle url = NewString("library_url");
  Dart_Handle source = NewString(kLibraryChars);
  Dart_Handle lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  Dart_Handle list = Dart_LibraryGetClassNames(lib);
  EXPECT_VALID(list);
  EXPECT(Dart_IsList(list));

  // Sort the list.
  const int kNumArgs = 1;
  Dart_Handle args[1];
  args[0] = list;
  EXPECT_VALID(Dart_Invoke(lib, NewString("sort"), kNumArgs, args));

  Dart_Handle list_string = Dart_ToString(list);
  EXPECT_VALID(list_string);
  const char* list_cstr = "";
  EXPECT_VALID(Dart_StringToCString(list_string, &list_cstr));
  EXPECT_STREQ("[A, B, C, _A, _B, _C]", list_cstr);
}

TEST_CASE(GetFunctionNames) {
  const char* kLibraryChars =
      "library library_name;\n"
      "\n"
      "void A() {}\n"
      "get B => 11;\n"
      "set C(x) { }\n"
      "var D;\n"
      "void _A() {}\n"
      "get _B => 11;\n"
      "set _C(x) { }\n"
      "var _D;\n"
      "\n"
      "class MyClass {\n"
      "  void A2() {}\n"
      "  get B2 => 11;\n"
      "  set C2(x) { }\n"
      "  var D2;\n"
      "  void _A2() {}\n"
      "  get _B2 => 11;\n"
      "  set _C2(x) { }\n"
      "  var _D2;\n"
      "}\n"
      "\n"
      "_compare(String a, String b) => a.compareTo(b);\n"
      "sort(list) => list.sort(_compare);\n";

  // Get the functions from a library.
  Dart_Handle url = NewString("library_url");
  Dart_Handle source = NewString(kLibraryChars);
  Dart_Handle lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  Dart_Handle list = Dart_GetFunctionNames(lib);
  EXPECT_VALID(list);
  EXPECT(Dart_IsList(list));

  // Sort the list.
  const int kNumArgs = 1;
  Dart_Handle args[1];
  args[0] = list;
  EXPECT_VALID(Dart_Invoke(lib, NewString("sort"), kNumArgs, args));

  Dart_Handle list_string = Dart_ToString(list);
  EXPECT_VALID(list_string);
  const char* list_cstr = "";
  EXPECT_VALID(Dart_StringToCString(list_string, &list_cstr));
  EXPECT_STREQ("[A, B, C=, _A, _B, _C=, _compare, sort]", list_cstr);

  // Get the functions from a class.
  Dart_Handle cls = Dart_GetClass(lib, NewString("MyClass"));
  EXPECT_VALID(cls);

  list = Dart_GetFunctionNames(cls);
  EXPECT_VALID(list);
  EXPECT(Dart_IsList(list));

  // Sort the list.
  args[0] = list;
  EXPECT_VALID(Dart_Invoke(lib, NewString("sort"), kNumArgs, args));

  // Check list contents.
  list_string = Dart_ToString(list);
  EXPECT_VALID(list_string);
  list_cstr = "";
  EXPECT_VALID(Dart_StringToCString(list_string, &list_cstr));
  EXPECT_STREQ("[A2, B2, C2=, MyClass, _A2, _B2, _C2=]", list_cstr);
}

TEST_CASE(LibraryImportLibrary) {
  const char* kLibrary1Chars = "library library1_name;";
  const char* kLibrary2Chars = "library library2_name;";
  Dart_Handle error = Dart_NewApiError("incoming error");
  Dart_Handle result;

  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle lib1 = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib1);

  url = NewString("library2_url");
  source = NewString(kLibrary2Chars);
  Dart_Handle lib2 = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib2);

  result = Dart_LibraryImportLibrary(Dart_Null(), lib2, Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LibraryImportLibrary expects argument 'library' to be non-null.",
      Dart_GetError(result));

  result = Dart_LibraryImportLibrary(Dart_True(), lib2, Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LibraryImportLibrary expects argument 'library' to be of "
      "type Library.",
      Dart_GetError(result));

  result = Dart_LibraryImportLibrary(error, lib2, Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LibraryImportLibrary(lib1, Dart_Null(), Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LibraryImportLibrary expects argument 'import' to be non-null.",
      Dart_GetError(result));

  result = Dart_LibraryImportLibrary(lib1, Dart_True(), Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LibraryImportLibrary expects argument 'import' to be of "
      "type Library.",
      Dart_GetError(result));

  result = Dart_LibraryImportLibrary(lib1, error, Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LibraryImportLibrary(lib1, lib2, Dart_Null());
  EXPECT_VALID(result);
}

TEST_CASE(ImportLibraryWithPrefix) {
  const char* kLibrary1Chars =
      "library library1_name;"
      "int bar() => 42;";
  Dart_Handle url1 = NewString("library1_url");
  Dart_Handle source1 = NewString(kLibrary1Chars);
  Dart_Handle lib1 = Dart_LoadLibrary(url1, Dart_Null(), source1, 0, 0);
  EXPECT_VALID(lib1);
  EXPECT(Dart_IsLibrary(lib1));

  const char* kLibrary2Chars =
      "library library2_name;"
      "int foobar() => foo.bar();";
  Dart_Handle url2 = NewString("library2_url");
  Dart_Handle source2 = NewString(kLibrary2Chars);
  Dart_Handle lib2 = Dart_LoadLibrary(url2, Dart_Null(), source2, 0, 0);
  EXPECT_VALID(lib2);
  EXPECT(Dart_IsLibrary(lib2));

  Dart_Handle prefix = NewString("foo");
  Dart_Handle result = Dart_LibraryImportLibrary(lib2, lib1, prefix);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  // Lib1 is imported under a library prefix and therefore 'foo' should
  // not be found directly in lib2.
  Dart_Handle method_name = NewString("foo");
  result = Dart_Invoke(lib2, method_name, 0, NULL);
  EXPECT_ERROR(result, "Dart_Invoke: did not find top-level function 'foo'");

  // Check that lib1 is available under the prefix in lib2.
  method_name = NewString("foobar");
  result = Dart_Invoke(lib2, method_name, 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(42, value);
}

TEST_CASE(LoadLibrary) {
  const char* kLibrary1Chars = "library library1_name;";
  Dart_Handle error = Dart_NewApiError("incoming error");
  Dart_Handle result;

  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);

  result = Dart_LoadLibrary(Dart_Null(), Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadLibrary expects argument 'url' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadLibrary(Dart_True(), Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadLibrary expects argument 'url' to be of type String.",
               Dart_GetError(result));

  result = Dart_LoadLibrary(error, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadLibrary(url, Dart_True(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadLibrary expects argument 'resolved_url' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadLibrary(url, error, source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadLibrary(url, Dart_Null(), Dart_Null(), 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadLibrary expects argument 'source' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadLibrary(url, Dart_Null(), Dart_True(), 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadLibrary expects argument 'source' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadLibrary(url, Dart_Null(), error, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  // Success.
  result = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);
  EXPECT(Dart_IsLibrary(result));

  // Duplicate library load fails.
  result = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadLibrary: library 'library1_url' has already been loaded.",
      Dart_GetError(result));
}

TEST_CASE(LoadLibrary_CompileError) {
  const char* kLibrary1Chars =
      "library library1_name;"
      ")";
  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle result = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT(strstr(Dart_GetError(result), "unexpected token ')'"));
}

TEST_CASE(LoadSource) {
  const char* kLibrary1Chars = "library library1_name;";
  const char* kSourceChars = "part of library1_name;\n// Something innocuous";
  const char* kBadSourceChars = ")";
  Dart_Handle error = Dart_NewApiError("incoming error");
  Dart_Handle result;

  // Load up a library.
  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));

  url = NewString("source_url");
  source = NewString(kSourceChars);

  result = Dart_LoadSource(Dart_Null(), url, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadSource expects argument 'library' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadSource(Dart_True(), url, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadSource expects argument 'library' to be of type Library.",
      Dart_GetError(result));

  result = Dart_LoadSource(error, url, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadSource(lib, Dart_Null(), Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadSource expects argument 'url' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadSource(lib, Dart_True(), Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadSource expects argument 'url' to be of type String.",
               Dart_GetError(result));

  result = Dart_LoadSource(lib, error, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadSource(lib, url, Dart_True(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadSource expects argument 'resolved_url' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadSource(lib, url, error, source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadSource(lib, url, Dart_Null(), Dart_Null(), 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadSource expects argument 'source' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadSource(lib, url, Dart_Null(), Dart_True(), 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadSource expects argument 'source' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadSource(lib, error, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  // Success.
  result = Dart_LoadSource(lib, url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);
  EXPECT(Dart_IsLibrary(result));
  EXPECT(Dart_IdentityEquals(lib, result));

  // Duplicate calls are okay.
  result = Dart_LoadSource(lib, url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);
  EXPECT(Dart_IsLibrary(result));
  EXPECT(Dart_IdentityEquals(lib, result));

  // Language errors are detected.
  source = NewString(kBadSourceChars);
  result = Dart_LoadSource(lib, url, Dart_Null(), source, 0, 0);
  EXPECT(Dart_IsError(result));
}

TEST_CASE(LoadSource_LateLoad) {
  const char* kLibrary1Chars =
      "library library1_name;\n"
      "class OldClass {\n"
      "  foo() => 'foo';\n"
      "}\n";
  const char* kSourceChars =
      "part of library1_name;\n"
      "class NewClass extends OldClass{\n"
      "  bar() => 'bar';\n"
      "}\n";
  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));
  Dart_Handle result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  // Call a dynamic function on OldClass.
  Dart_Handle type = Dart_GetType(lib, NewString("OldClass"), 0, NULL);
  EXPECT_VALID(type);
  Dart_Handle recv = Dart_New(type, Dart_Null(), 0, NULL);
  result = Dart_Invoke(recv, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));
  const char* result_cstr = "";
  EXPECT_VALID(Dart_StringToCString(result, &result_cstr));
  EXPECT_STREQ("foo", result_cstr);

  // Load a source file late.
  url = NewString("source_url");
  source = NewString(kSourceChars);
  EXPECT_VALID(Dart_LoadSource(lib, url, Dart_Null(), source, 0, 0));
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  // Call a dynamic function on NewClass in the updated library.
  type = Dart_GetType(lib, NewString("NewClass"), 0, NULL);
  EXPECT_VALID(type);
  recv = Dart_New(type, Dart_Null(), 0, NULL);
  result = Dart_Invoke(recv, NewString("bar"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));
  result_cstr = "";
  EXPECT_VALID(Dart_StringToCString(result, &result_cstr));
  EXPECT_STREQ("bar", result_cstr);
}

TEST_CASE(LoadPatch) {
  const char* kLibrary1Chars = "library library1_name;";
  const char* kSourceChars =
      "part of library1_name;\n"
      "external int foo();";
  const char* kPatchChars = "@patch int foo() => 42;";

  // Load up a library.
  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));

  url = NewString("source_url");
  source = NewString(kSourceChars);

  Dart_Handle result = Dart_LoadSource(lib, url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);

  url = NewString("patch_url");
  source = NewString(kPatchChars);

  result = Dart_LibraryLoadPatch(lib, url, source);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(42, value);
}

TEST_CASE(LoadPatchSignatureMismatch) {
  // This tests the sort of APIs with intentional signature mismatches we need
  // for typed Dart-JavaScript interop where we emulated JavaScript semantics
  // for optional arguments.
  const char* kLibrary1Chars = "library library1_name;";
  const char* kSourceChars =
      "part of library1_name;\n"
      "external int foo([int x]);\n"
      "class Foo<T extends Foo> {\n"
      "  external static int addDefault10([int x, int y]);\n"
      "}";
  const char* kPatchChars =
      "const _UNDEFINED = const Object();\n"
      "@patch foo([x=_UNDEFINED]) => identical(x, _UNDEFINED) ? 42 : x;\n"
      "@patch class Foo<T> {\n"
      "  static addDefault10([x=_UNDEFINED, y=_UNDEFINED]) {\n"
      "    if (identical(x, _UNDEFINED)) x = 10;\n"
      "    if (identical(y, _UNDEFINED)) y = 10;\n"
      "    return x + y;\n"
      "  }\n"
      "}";

  bool old_flag_value = FLAG_ignore_patch_signature_mismatch;
  FLAG_ignore_patch_signature_mismatch = true;

  // Load up a library.
  Dart_Handle url = NewString("library1_url");
  Dart_Handle source = NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));

  url = NewString("source_url");
  source = NewString(kSourceChars);

  Dart_Handle result = Dart_LoadSource(lib, url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);

  url = NewString("patch_url");
  source = NewString(kPatchChars);

  result = Dart_LibraryLoadPatch(lib, url, source);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  // Test a top level method
  {
    result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
    EXPECT_VALID(result);
    EXPECT(Dart_IsInteger(result));
    int64_t value = 0;
    EXPECT_VALID(Dart_IntegerToInt64(result, &value));
    EXPECT_EQ(42, value);
  }

  {
    Dart_Handle dart_args[1];
    dart_args[0] = Dart_Null();
    result = Dart_Invoke(lib, NewString("foo"), 1, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsNull(result));
  }

  {
    Dart_Handle dart_args[1];
    dart_args[0] = Dart_NewInteger(100);
    result = Dart_Invoke(lib, NewString("foo"), 1, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsInteger(result));
    int64_t value = 0;
    EXPECT_VALID(Dart_IntegerToInt64(result, &value));
    EXPECT_EQ(100, value);
  }

  // Test static method
  Dart_Handle type = Dart_GetType(lib, NewString("Foo"), 0, NULL);
  EXPECT_VALID(type);

  {
    result = Dart_Invoke(type, NewString("addDefault10"), 0, NULL);
    EXPECT_VALID(result);
    EXPECT(Dart_IsInteger(result));
    int64_t value = 0;
    EXPECT_VALID(Dart_IntegerToInt64(result, &value));
    EXPECT_EQ(20, value);
  }

  {
    Dart_Handle dart_args[1];
    dart_args[0] = Dart_NewInteger(100);
    result = Dart_Invoke(type, NewString("addDefault10"), 1, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsInteger(result));
    int64_t value = 0;
    EXPECT_VALID(Dart_IntegerToInt64(result, &value));
    EXPECT_EQ(110, value);
  }

  {
    Dart_Handle dart_args[2];
    dart_args[0] = Dart_NewInteger(100);
    dart_args[1] = Dart_NewInteger(100);
    result = Dart_Invoke(type, NewString("addDefault10"), 2, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsInteger(result));
    int64_t value = 0;
    EXPECT_VALID(Dart_IntegerToInt64(result, &value));
    EXPECT_EQ(200, value);
  }

  FLAG_ignore_patch_signature_mismatch = old_flag_value;
}

static void PatchNativeFunction(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, Dart_Null());
  Dart_ExitScope();
}

static Dart_NativeFunction PatchNativeResolver(Dart_Handle name,
                                               int arg_count,
                                               bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  return &PatchNativeFunction;
}

TEST_CASE(ParsePatchLibrary) {
  const char* kLibraryChars =
      "library patched_library;\n"
      "class A {\n"
      "  final fvalue;\n"
      "  var _f;\n"
      "  callFunc(x, y) => x(y);\n"
      "  external void method(var value);\n"
      "  get field => _field;\n"
      "}\n"
      "class B {\n"
      "  var val;\n"
      "  external B.named(x);\n"
      "  external B(v);\n"
      "}\n"
      "class C {\n"
      "  external int method();\n"
      "}\n"
      "\n"
      "external int unpatched();\n"
      "external int topLevel(var value);\n"
      "external int topLevel2(var value);\n"
      "external int get topLevelGetter;\n"
      "external void set topLevelSetter(int value);\n";

  const char* kPatchChars =
      "@patch class A {\n"
      "  var _g;\n"
      "  A() : fvalue = 13;\n"
      "  get _field => _g;\n"
      "  @patch void method(var value) {\n"
      "    int closeYourEyes(var eggs) { return eggs * -1; }\n"
      "    value = callFunc(closeYourEyes, value);\n"
      "    _g = value * 5;\n"
      "  }\n"
      "}\n"
      "@patch class B {\n"
      "  B._internal(x) : val = x;\n"
      "  @patch factory B.named(x) { return new B._internal(x); }\n"
      "  @patch factory B(v) native \"const_B_factory\";\n"
      "}\n"
      "var _topLevelValue = -1;\n"
      "@patch int topLevel(var value) => value * value;\n"
      "@patch int set topLevelSetter(value) { _topLevelValue = value; }\n"
      "@patch int get topLevelGetter => 2 * _topLevelValue;\n"
      // Allow top level methods named patch.
      "patch(x) => x*3;\n";  // NOLINT

  const char* kPatchClassOnlyChars =
      "@patch class C {\n"
      "  @patch int method() {\n"
      "    return 42;\n"
      "  }\n"
      "}\n";  // NOLINT

  const char* kPatchNoClassChars = "@patch topLevel2(x) => x * 2;\n";

  const char* kScriptChars =
      "import 'theLibrary';\n"
      "e1() => unpatched();\n"
      "m1() => topLevel(2);\n"
      "m2() {\n"
      "  topLevelSetter = 20;\n"
      "  return topLevelGetter;\n"
      "}\n"
      "m3() => patch(7);\n"
      "m4() {\n"
      "  var a = new A();\n"
      "  a.method(5);\n"
      "  return a.field;\n"
      "}\n"
      "m5() => new B(3);\n"
      "m6() {\n"
      "  var b = new B.named(8);\n"
      "  return b.val;\n"
      "}\n";  // NOLINT

  bin::Builtin::SetNativeResolver(bin::Builtin::kBuiltinLibrary);
  bin::Builtin::SetNativeResolver(bin::Builtin::kIOLibrary);

  Dart_Handle result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);

  Dart_Handle url = NewString("theLibrary");
  Dart_Handle source = NewString(kLibraryChars);
  result = Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);

  const char* patchNames[] = {"main library patch", "patch class only",
                              "patch no class"};
  const char* patches[] = {kPatchChars, kPatchClassOnlyChars,
                           kPatchNoClassChars};
  const String& lib_url = String::Handle(String::New("theLibrary"));

  const Library& lib = Library::Handle(Library::LookupLibrary(thread, lib_url));

  for (int i = 0; i < 3; i++) {
    const String& patch_url = String::Handle(String::New(patchNames[i]));
    const String& patch_source = String::Handle(String::New(patches[i]));
    const Script& patch_script = Script::Handle(
        Script::New(patch_url, patch_source, RawScript::kPatchTag));

    const Error& err = Error::Handle(lib.Patch(patch_script));
    if (!err.IsNull()) {
      OS::Print("Patching error: %s\n", err.ToErrorCString());
      EXPECT(false);
    }
  }
  result = Dart_SetNativeResolver(result, &PatchNativeResolver, NULL);
  EXPECT_VALID(result);

  Dart_Handle script_url = NewString("theScript");
  source = NewString(kScriptChars);
  Dart_Handle test_script =
      Dart_LoadScript(script_url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(test_script);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  // Make sure that we can compile all of the patched code.
  result = Dart_CompileAll();
  EXPECT_VALID(result);

  result = Dart_Invoke(test_script, NewString("e1"), 0, NULL);
  EXPECT_ERROR(result, "No top-level method 'unpatched'");

  int64_t value = 0;
  result = Dart_Invoke(test_script, NewString("m1"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(4, value);

  value = 0;
  result = Dart_Invoke(test_script, NewString("m2"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(40, value);

  value = 0;
  result = Dart_Invoke(test_script, NewString("m3"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(21, value);

  value = 0;
  result = Dart_Invoke(test_script, NewString("m4"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(-25, value);

  result = Dart_Invoke(test_script, NewString("m5"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsNull(result));

  value = 0;
  result = Dart_Invoke(test_script, NewString("m6"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(8, value);

  // Make sure all source files show up in the patched library.
  const Array& lib_scripts = Array::Handle(lib.LoadedScripts());
  EXPECT_EQ(4, lib_scripts.Length());
}

static void MyNativeFunction1(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, Dart_NewInteger(654321));
  Dart_ExitScope();
}

static void MyNativeFunction2(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_SetReturnValue(args, Dart_NewInteger(123456));
  Dart_ExitScope();
}

static Dart_NativeFunction MyNativeResolver1(Dart_Handle name,
                                             int arg_count,
                                             bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  return &MyNativeFunction1;
}

static Dart_NativeFunction MyNativeResolver2(Dart_Handle name,
                                             int arg_count,
                                             bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  return &MyNativeFunction2;
}

TEST_CASE(SetNativeResolver) {
  const char* kScriptChars =
      "class Test {"
      "  static foo() native \"SomeNativeFunction\";\n"
      "  static bar() native \"SomeNativeFunction2\";\n"
      "  static baz() native \"SomeNativeFunction3\";\n"
      "}";
  Dart_Handle error = Dart_NewApiError("incoming error");
  Dart_Handle result;

  // Load a test script.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);
  EXPECT(Dart_IsLibrary(lib));
  Dart_Handle type = Dart_GetType(lib, NewString("Test"), 0, NULL);
  EXPECT_VALID(type);

  result = Dart_SetNativeResolver(Dart_Null(), &MyNativeResolver1, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_SetNativeResolver expects argument 'library' to be non-null.",
      Dart_GetError(result));

  result = Dart_SetNativeResolver(Dart_True(), &MyNativeResolver1, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_SetNativeResolver expects argument 'library' to be of "
      "type Library.",
      Dart_GetError(result));

  result = Dart_SetNativeResolver(error, &MyNativeResolver1, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_SetNativeResolver(lib, &MyNativeResolver1, NULL);
  EXPECT_VALID(result);

  // Call a function and make sure native resolution works.
  result = Dart_Invoke(type, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(654321, value);

  // A second call succeeds.
  result = Dart_SetNativeResolver(lib, &MyNativeResolver2, NULL);
  EXPECT_VALID(result);

  // 'foo' has already been resolved so gets the old value.
  result = Dart_Invoke(type, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(654321, value);

  // 'bar' has not yet been resolved so gets the new value.
  result = Dart_Invoke(type, NewString("bar"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(123456, value);

  // A NULL resolver is okay, but resolution will fail.
  result = Dart_SetNativeResolver(lib, NULL, NULL);
  EXPECT_VALID(result);

  EXPECT_ERROR(Dart_Invoke(type, NewString("baz"), 0, NULL),
               "native function 'SomeNativeFunction3' (0 arguments) "
               "cannot be found");
}

// Test that an imported name does not clash with the same name defined
// in the importing library.
TEST_CASE(ImportLibrary2) {
  const char* kScriptChars =
      "import 'library1_dart';\n"
      "var foo;\n"
      "main() { foo = 0; }\n";
  const char* kLibrary1Chars =
      "library library1_dart;\n"
      "import 'library2_dart';\n"
      "var foo;\n";
  const char* kLibrary2Chars =
      "library library2_dart;\n"
      "import 'library1_dart';\n"
      "var foo;\n";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, Dart_Null(), source, 0, 0);

  url = NewString("library1_dart");
  source = NewString(kLibrary1Chars);
  Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);

  url = NewString("library2_dart");
  source = NewString(kLibrary2Chars);
  Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);

  Dart_FinalizeLoading(false);

  result = Dart_Invoke(result, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
}

// Test that if the same name is imported from two libraries, it is
// an error if that name is referenced.
TEST_CASE(ImportLibrary3) {
  const char* kScriptChars =
      "import 'library2_dart';\n"
      "import 'library1_dart';\n"
      "var foo_top = 10;  // foo has dup def. So should be an error.\n"
      "main() { foo = 0; }\n";
  const char* kLibrary1Chars =
      "library library1_dart;\n"
      "var foo;";
  const char* kLibrary2Chars =
      "library library2_dart;\n"
      "var foo;";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);

  url = NewString("library2_dart");
  source = NewString(kLibrary2Chars);
  Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);

  url = NewString("library1_dart");
  source = NewString(kLibrary1Chars);
  Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  result = Dart_Invoke(result, NewString("main"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_SUBSTRING("NoSuchMethodError", Dart_GetError(result));
}

// Test that if the same name is imported from two libraries, it is
// not an error if that name is not used.
TEST_CASE(ImportLibrary4) {
  const char* kScriptChars =
      "import 'library2_dart';\n"
      "import 'library1_dart';\n"
      "main() {  }\n";
  const char* kLibrary1Chars =
      "library library1_dart;\n"
      "var foo;";
  const char* kLibrary2Chars =
      "library library2_dart;\n"
      "var foo;";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(result);

  url = NewString("library2_dart");
  source = NewString(kLibrary2Chars);
  Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);

  url = NewString("library1_dart");
  source = NewString(kLibrary1Chars);
  Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  Dart_FinalizeLoading(false);

  result = Dart_Invoke(result, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
}

TEST_CASE(ImportLibrary5) {
  const char* kScriptChars =
      "import 'lib.dart';\n"
      "abstract class Y {\n"
      "  void set handler(void callback(List<int> x));\n"
      "}\n"
      "void main() {}\n";
  const char* kLibraryChars =
      "library lib.dart;\n"
      "abstract class X {\n"
      "  void set handler(void callback(List<int> x));\n"
      "}\n";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, Dart_Null(), source, 0, 0);

  url = NewString("lib.dart");
  source = NewString(kLibraryChars);
  Dart_LoadLibrary(url, Dart_Null(), source, 0, 0);
  Dart_FinalizeLoading(false);

  result = Dart_Invoke(result, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
}

void NewNativePort_send123(Dart_Port dest_port_id, Dart_CObject* message) {
  // Gets a send port message.
  EXPECT_NOTNULL(message);
  EXPECT_EQ(Dart_CObject_kArray, message->type);
  EXPECT_EQ(Dart_CObject_kSendPort, message->value.as_array.values[0]->type);

  // Post integer value.
  Dart_CObject* response =
      reinterpret_cast<Dart_CObject*>(Dart_ScopeAllocate(sizeof(Dart_CObject)));
  response->type = Dart_CObject_kInt32;
  response->value.as_int32 = 123;
  Dart_PostCObject(message->value.as_array.values[0]->value.as_send_port.id,
                   response);
}

void NewNativePort_send321(Dart_Port dest_port_id, Dart_CObject* message) {
  // Gets a null message.
  EXPECT_NOTNULL(message);
  EXPECT_EQ(Dart_CObject_kArray, message->type);
  EXPECT_EQ(Dart_CObject_kSendPort, message->value.as_array.values[0]->type);

  // Post integer value.
  Dart_CObject* response =
      reinterpret_cast<Dart_CObject*>(Dart_ScopeAllocate(sizeof(Dart_CObject)));
  response->type = Dart_CObject_kInt32;
  response->value.as_int32 = 321;
  Dart_PostCObject(message->value.as_array.values[0]->value.as_send_port.id,
                   response);
}

TEST_CASE(IllegalNewSendPort) {
  Dart_Handle error = Dart_NewSendPort(ILLEGAL_PORT);
  EXPECT(Dart_IsError(error));
  EXPECT(Dart_IsApiError(error));
}

TEST_CASE(IllegalPost) {
  Dart_Handle message = Dart_True();
  bool success = Dart_Post(ILLEGAL_PORT, message);
  EXPECT(!success);
}

VM_UNIT_TEST_CASE(NewNativePort) {
  // Create a port with a bogus handler.
  Dart_Port error_port = Dart_NewNativePort("Foo", NULL, true);
  EXPECT_EQ(ILLEGAL_PORT, error_port);

  // Create the port w/o a current isolate, just to make sure that works.
  Dart_Port port_id1 =
      Dart_NewNativePort("Port123", NewNativePort_send123, true);

  TestIsolateScope __test_isolate__;
  const char* kScriptChars =
      "import 'dart:isolate';\n"
      "void callPort(SendPort port) {\n"
      "  var receivePort = new RawReceivePort();\n"
      "  var replyPort = receivePort.sendPort;\n"
      "  port.send([replyPort]);\n"
      "  receivePort.handler = (message) {\n"
      "    receivePort.close();\n"
      "    throw new Exception(message);\n"
      "  };\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_EnterScope();

  // Create a port w/ a current isolate, to make sure that works too.
  Dart_Port port_id2 =
      Dart_NewNativePort("Port321", NewNativePort_send321, true);

  Dart_Handle send_port1 = Dart_NewSendPort(port_id1);
  EXPECT_VALID(send_port1);
  Dart_Handle send_port2 = Dart_NewSendPort(port_id2);
  EXPECT_VALID(send_port2);

  // Test first port.
  Dart_Handle dart_args[1];
  dart_args[0] = send_port1;
  Dart_Handle result = Dart_Invoke(lib, NewString("callPort"), 1, dart_args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Exception: 123\n", Dart_GetError(result));

  // result second port.
  dart_args[0] = send_port2;
  result = Dart_Invoke(lib, NewString("callPort"), 1, dart_args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Exception: 321\n", Dart_GetError(result));

  Dart_ExitScope();

  // Delete the native ports.
  EXPECT(Dart_CloseNativePort(port_id1));
  EXPECT(Dart_CloseNativePort(port_id2));
}

void NewNativePort_sendInteger123(Dart_Port dest_port_id,
                                  Dart_CObject* message) {
  // Gets a send port message.
  EXPECT_NOTNULL(message);
  EXPECT_EQ(Dart_CObject_kArray, message->type);
  EXPECT_EQ(Dart_CObject_kSendPort, message->value.as_array.values[0]->type);

  // Post integer value.
  Dart_PostInteger(message->value.as_array.values[0]->value.as_send_port.id,
                   123);
}

void NewNativePort_sendInteger321(Dart_Port dest_port_id,
                                  Dart_CObject* message) {
  // Gets a null message.
  EXPECT_NOTNULL(message);
  EXPECT_EQ(Dart_CObject_kArray, message->type);
  EXPECT_EQ(Dart_CObject_kSendPort, message->value.as_array.values[0]->type);

  // Post integer value.
  Dart_PostInteger(message->value.as_array.values[0]->value.as_send_port.id,
                   321);
}

TEST_CASE(NativePortPostInteger) {
  const char* kScriptChars =
      "import 'dart:isolate';\n"
      "void callPort(SendPort port) {\n"
      "  var receivePort = new RawReceivePort();\n"
      "  var replyPort = receivePort.sendPort;\n"
      "  port.send([replyPort]);\n"
      "  receivePort.handler = (message) {\n"
      "    receivePort.close();\n"
      "    throw new Exception(message);\n"
      "  };\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_EnterScope();

  Dart_Port port_id1 =
      Dart_NewNativePort("Port123", NewNativePort_sendInteger123, true);
  Dart_Port port_id2 =
      Dart_NewNativePort("Port321", NewNativePort_sendInteger321, true);

  Dart_Handle send_port1 = Dart_NewSendPort(port_id1);
  EXPECT_VALID(send_port1);
  Dart_Handle send_port2 = Dart_NewSendPort(port_id2);
  EXPECT_VALID(send_port2);

  // Test first port.
  Dart_Handle dart_args[1];
  dart_args[0] = send_port1;
  Dart_Handle result = Dart_Invoke(lib, NewString("callPort"), 1, dart_args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Exception: 123\n", Dart_GetError(result));

  // result second port.
  dart_args[0] = send_port2;
  result = Dart_Invoke(lib, NewString("callPort"), 1, dart_args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Exception: 321\n", Dart_GetError(result));

  Dart_ExitScope();

  // Delete the native ports.
  EXPECT(Dart_CloseNativePort(port_id1));
  EXPECT(Dart_CloseNativePort(port_id2));
}

void NewNativePort_nativeReceiveNull(Dart_Port dest_port_id,
                                     Dart_CObject* message) {
  EXPECT_NOTNULL(message);

  if ((message->type == Dart_CObject_kArray) &&
      (message->value.as_array.values[0]->type == Dart_CObject_kSendPort)) {
    // Post integer value.
    Dart_PostInteger(message->value.as_array.values[0]->value.as_send_port.id,
                     123);
  } else {
    EXPECT_EQ(message->type, Dart_CObject_kNull);
  }
}

TEST_CASE(NativePortReceiveNull) {
  const char* kScriptChars =
      "import 'dart:isolate';\n"
      "void callPort(SendPort port) {\n"
      "  var receivePort = new RawReceivePort();\n"
      "  var replyPort = receivePort.sendPort;\n"
      "  port.send(null);\n"
      "  port.send([replyPort]);\n"
      "  receivePort.handler = (message) {\n"
      "    receivePort.close();\n"
      "    throw new Exception(message);\n"
      "  };\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_EnterScope();

  Dart_Port port_id1 =
      Dart_NewNativePort("PortNull", NewNativePort_nativeReceiveNull, true);
  Dart_Handle send_port1 = Dart_NewSendPort(port_id1);
  EXPECT_VALID(send_port1);

  // Test first port.
  Dart_Handle dart_args[1];
  dart_args[0] = send_port1;
  Dart_Handle result = Dart_Invoke(lib, NewString("callPort"), 1, dart_args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Exception: 123\n", Dart_GetError(result));

  Dart_ExitScope();

  // Delete the native ports.
  EXPECT(Dart_CloseNativePort(port_id1));
}

void NewNativePort_nativeReceiveInteger(Dart_Port dest_port_id,
                                        Dart_CObject* message) {
  EXPECT_NOTNULL(message);

  if ((message->type == Dart_CObject_kArray) &&
      (message->value.as_array.values[0]->type == Dart_CObject_kSendPort)) {
    // Post integer value.
    Dart_PostInteger(message->value.as_array.values[0]->value.as_send_port.id,
                     123);
  } else {
    EXPECT_EQ(message->type, Dart_CObject_kInt32);
    EXPECT_EQ(message->value.as_int32, 321);
  }
}

TEST_CASE(NativePortReceiveInteger) {
  const char* kScriptChars =
      "import 'dart:isolate';\n"
      "void callPort(SendPort port) {\n"
      "  var receivePort = new RawReceivePort();\n"
      "  var replyPort = receivePort.sendPort;\n"
      "  port.send(321);\n"
      "  port.send([replyPort]);\n"
      "  receivePort.handler = (message) {\n"
      "    receivePort.close();\n"
      "    throw new Exception(message);\n"
      "  };\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_EnterScope();

  Dart_Port port_id1 =
      Dart_NewNativePort("PortNull", NewNativePort_nativeReceiveInteger, true);
  Dart_Handle send_port1 = Dart_NewSendPort(port_id1);
  EXPECT_VALID(send_port1);

  // Test first port.
  Dart_Handle dart_args[1];
  dart_args[0] = send_port1;
  Dart_Handle result = Dart_Invoke(lib, NewString("callPort"), 1, dart_args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Exception: 123\n", Dart_GetError(result));

  Dart_ExitScope();

  // Delete the native ports.
  EXPECT(Dart_CloseNativePort(port_id1));
}

static Dart_Isolate RunLoopTestCallback(const char* script_name,
                                        const char* main,
                                        const char* package_root,
                                        const char* package_config,
                                        Dart_IsolateFlags* flags,
                                        void* data,
                                        char** error) {
  const char* kScriptChars =
      "import 'builtin';\n"
      "import 'dart:isolate';\n"
      "void main(shouldThrowException) {\n"
      "  var rp = new RawReceivePort();\n"
      "  rp.handler = (msg) {\n"
      "    rp.close();\n"
      "    if (shouldThrowException) {\n"
      "      throw new Exception('ExceptionFromTimer');\n"
      "    }\n"
      "  };\n"
      "  rp.sendPort.send(1);\n"
      "}\n";

  if (Dart_CurrentIsolate() != NULL) {
    Dart_ExitIsolate();
  }
  Dart_Isolate isolate = TestCase::CreateTestIsolate(script_name);
  ASSERT(isolate != NULL);
  if (Dart_IsServiceIsolate(isolate)) {
    return isolate;
  }
  Dart_EnterScope();
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  Dart_Handle result = Dart_SetLibraryTagHandler(TestCase::library_handler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);
  Dart_ExitScope();
  Dart_ExitIsolate();
  bool retval = Dart_IsolateMakeRunnable(isolate);
  EXPECT(retval);
  return isolate;
}

// Common code for RunLoop_Success/RunLoop_Failure.
static void RunLoopTest(bool throw_exception) {
  Dart_IsolateCreateCallback saved = Isolate::CreateCallback();
  Isolate::SetCreateCallback(RunLoopTestCallback);
  Dart_Isolate isolate =
      RunLoopTestCallback(NULL, NULL, NULL, NULL, NULL, NULL, NULL);

  Dart_EnterIsolate(isolate);
  Dart_EnterScope();
  Dart_Handle lib = Dart_LookupLibrary(NewString(TestCase::url()));
  EXPECT_VALID(lib);

  Dart_Handle result;
  Dart_Handle args[1];
  args[0] = (throw_exception ? Dart_True() : Dart_False());
  result = Dart_Invoke(lib, NewString("main"), 1, args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  if (throw_exception) {
    EXPECT_ERROR(result, "Exception: ExceptionFromTimer");
  } else {
    EXPECT_VALID(result);
  }

  Dart_ExitScope();
  Dart_ShutdownIsolate();

  Isolate::SetCreateCallback(saved);
}

VM_UNIT_TEST_CASE(RunLoop_Success) {
  RunLoopTest(false);
}

VM_UNIT_TEST_CASE(RunLoop_Exception) {
  RunLoopTest(true);
}

// Utility functions and variables for test case IsolateInterrupt starts here.
static Monitor* sync = NULL;
static Dart_Isolate shared_isolate = NULL;
static bool main_entered = false;

void MarkMainEntered(Dart_NativeArguments args) {
  Dart_EnterScope();  // Start a Dart API scope for invoking API functions.
  // Indicate that main has been entered.
  {
    MonitorLocker ml(sync);
    main_entered = true;
    ml.Notify();
  }
  Dart_SetReturnValue(args, Dart_Null());
  Dart_ExitScope();
}

static Dart_NativeFunction IsolateInterruptTestNativeLookup(
    Dart_Handle name,
    int argument_count,
    bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  return reinterpret_cast<Dart_NativeFunction>(&MarkMainEntered);
}

void BusyLoop_start(uword unused) {
  const char* kScriptChars =
      "class Native {\n"
      "  static void markMainEntered() native 'MarkMainEntered';\n"
      "}\n"
      "\n"
      "void main() {\n"
      "  Native.markMainEntered();\n"
      "  while (true) {\n"  // Infinite empty loop.
      "  }\n"
      "}\n";

  // Tell the other thread that shared_isolate is created.
  Dart_Handle lib;
  {
    MonitorLocker ml(sync);
    char* error = NULL;
    shared_isolate = Dart_CreateIsolate(
        NULL, NULL, bin::core_isolate_snapshot_data,
        bin::core_isolate_snapshot_instructions, NULL, NULL, &error);
    EXPECT(shared_isolate != NULL);
    Dart_EnterScope();
    Dart_Handle url = NewString(TestCase::url());
    Dart_Handle source = NewString(kScriptChars);
    Dart_Handle result = Dart_SetLibraryTagHandler(TestCase::library_handler);
    EXPECT_VALID(result);
    lib = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
    EXPECT_VALID(lib);
    result = Dart_FinalizeLoading(false);
    EXPECT_VALID(result);
    result =
        Dart_SetNativeResolver(lib, &IsolateInterruptTestNativeLookup, NULL);
    DART_CHECK_VALID(result);

    ml.Notify();
  }

  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Unhandled exception:\nfoo\n", Dart_GetError(result));

  Dart_ExitScope();
  Dart_ShutdownIsolate();

  // Tell the other thread that we are done.
  {
    MonitorLocker ml(sync);
    shared_isolate = NULL;
    ml.Notify();
  }
}

static void* saved_callback_data;
static void IsolateShutdownTestCallback(void* callback_data) {
  saved_callback_data = callback_data;
}

VM_UNIT_TEST_CASE(IsolateShutdown) {
  Dart_IsolateShutdownCallback saved = Isolate::ShutdownCallback();
  Isolate::SetShutdownCallback(IsolateShutdownTestCallback);

  saved_callback_data = NULL;

  void* my_data = reinterpret_cast<void*>(12345);

  // Create an isolate.
  char* err;
  Dart_Isolate isolate = Dart_CreateIsolate(
      NULL, NULL, bin::core_isolate_snapshot_data,
      bin::core_isolate_snapshot_instructions, NULL, my_data, &err);
  if (isolate == NULL) {
    OS::Print("Creation of isolate failed '%s'\n", err);
    free(err);
  }
  EXPECT(isolate != NULL);

  // The shutdown callback has not been called.
  EXPECT_EQ(0, reinterpret_cast<intptr_t>(saved_callback_data));

  // Shutdown the isolate.
  Dart_ShutdownIsolate();

  // The shutdown callback has been called.
  EXPECT_EQ(12345, reinterpret_cast<intptr_t>(saved_callback_data));

  Isolate::SetShutdownCallback(saved);
}

static int64_t add_result = 0;
static void IsolateShutdownRunDartCodeTestCallback(void* callback_data) {
  Dart_EnterScope();
  Dart_Handle lib = Dart_RootLibrary();
  EXPECT_VALID(lib);
  Dart_Handle arg1 = Dart_NewInteger(90);
  EXPECT_VALID(arg1);
  Dart_Handle arg2 = Dart_NewInteger(9);
  EXPECT_VALID(arg2);
  Dart_Handle dart_args[2] = {arg1, arg2};
  Dart_Handle result = Dart_Invoke(lib, NewString("add"), 2, dart_args);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &add_result);
  EXPECT_VALID(result);
  Dart_ExitScope();
}

VM_UNIT_TEST_CASE(IsolateShutdownRunDartCode) {
  const char* kScriptChars =
      "int add(int a, int b) {\n"
      "  return a + b;\n"
      "}\n"
      "\n"
      "void main() {\n"
      "  add(4, 5);\n"
      "}\n";

  // Create an isolate.
  char* err;
  Dart_Isolate isolate = Dart_CreateIsolate(
      NULL, NULL, bin::core_isolate_snapshot_data,
      bin::core_isolate_snapshot_instructions, NULL, NULL, &err);
  if (isolate == NULL) {
    OS::Print("Creation of isolate failed '%s'\n", err);
    free(err);
  }
  EXPECT(isolate != NULL);

  Isolate::SetShutdownCallback(IsolateShutdownRunDartCodeTestCallback);

  {
    Dart_EnterScope();
    Dart_Handle url = NewString(TestCase::url());
    Dart_Handle source = NewString(kScriptChars);
    Dart_Handle result = Dart_SetLibraryTagHandler(TestCase::library_handler);
    EXPECT_VALID(result);
    Dart_Handle lib = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
    EXPECT_VALID(lib);
    result = Dart_FinalizeLoading(false);
    EXPECT_VALID(result);
    result = Dart_Invoke(lib, NewString("main"), 0, NULL);
    EXPECT_VALID(result);
    Dart_ExitScope();
  }

  // The shutdown callback has not been called.
  EXPECT_EQ(0, add_result);

  EXPECT(isolate != NULL);

  // Shutdown the isolate.
  Dart_ShutdownIsolate();

  // The shutdown callback has been called and ran Dart code.
  EXPECT_EQ(99, add_result);
}

static int64_t GetValue(Dart_Handle arg) {
  EXPECT_VALID(arg);
  EXPECT(Dart_IsInteger(arg));
  int64_t value;
  EXPECT_VALID(Dart_IntegerToInt64(arg, &value));
  return value;
}

static void NativeFoo1(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t i = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(1, i);
  Dart_Handle arg = Dart_GetNativeArgument(args, 0);
  EXPECT_VALID(arg);
  Dart_SetReturnValue(args, Dart_NewInteger(1));
  Dart_ExitScope();
}

static void NativeFoo2(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t i = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(2, i);
  Dart_Handle arg1 = Dart_GetNativeArgument(args, 1);
  EXPECT_VALID(arg1);
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(arg1, &value));
  int64_t integer_value = 0;
  Dart_Handle result = Dart_GetNativeIntegerArgument(args, 1, &integer_value);
  EXPECT_VALID(result);
  EXPECT_EQ(value, integer_value);
  double double_value;
  result = Dart_GetNativeDoubleArgument(args, 1, &double_value);
  EXPECT_VALID(result);
  bool bool_value;
  result = Dart_GetNativeBooleanArgument(args, 1, &bool_value);
  EXPECT(Dart_IsError(result));
  Dart_SetReturnValue(args, Dart_NewInteger(GetValue(arg1)));
  Dart_ExitScope();
}

static void NativeFoo3(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t i = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(3, i);
  Dart_Handle arg1 = Dart_GetNativeArgument(args, 1);
  Dart_Handle arg2 = Dart_GetNativeArgument(args, 2);
  Dart_SetReturnValue(args, Dart_NewInteger(GetValue(arg1) + GetValue(arg2)));
  Dart_ExitScope();
}

static void NativeFoo4(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t i = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(4, i);
  Dart_Handle arg1 = Dart_GetNativeArgument(args, 1);
  Dart_Handle arg2 = Dart_GetNativeArgument(args, 2);
  Dart_Handle arg3 = Dart_GetNativeArgument(args, 3);
  Dart_SetReturnValue(
      args, Dart_NewInteger(GetValue(arg1) + GetValue(arg2) + GetValue(arg3)));
  Dart_ExitScope();
}

static Dart_NativeFunction MyNativeClosureResolver(Dart_Handle name,
                                                   int arg_count,
                                                   bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  if (!obj.IsString()) {
    return NULL;
  }
  const char* function_name = obj.ToCString();
  const char* kNativeFoo1 = "NativeFoo1";
  const char* kNativeFoo2 = "NativeFoo2";
  const char* kNativeFoo3 = "NativeFoo3";
  const char* kNativeFoo4 = "NativeFoo4";
  if (!strncmp(function_name, kNativeFoo1, strlen(kNativeFoo1))) {
    return &NativeFoo1;
  } else if (!strncmp(function_name, kNativeFoo2, strlen(kNativeFoo2))) {
    return &NativeFoo2;
  } else if (!strncmp(function_name, kNativeFoo3, strlen(kNativeFoo3))) {
    return &NativeFoo3;
  } else if (!strncmp(function_name, kNativeFoo4, strlen(kNativeFoo4))) {
    return &NativeFoo4;
  } else {
    UNREACHABLE();
    return NULL;
  }
}

TEST_CASE(NativeFunctionClosure) {
  const char* kScriptChars =
      "class Test {"
      "  int foo1() native \"NativeFoo1\";\n"
      "  int foo2(int i) native \"NativeFoo2\";\n"
      "  int foo3([int k = 10000, int l = 1]) native \"NativeFoo3\";\n"
      "  int foo4(int i,"
      "           [int j = 10, int k = 1]) native \"NativeFoo4\";\n"
      "  int bar1() { var func = foo1; return func(); }\n"
      "  int bar2(int i) { var func = foo2; return func(i); }\n"
      "  int bar30() { var func = foo3; return func(); }\n"
      "  int bar31(int i) { var func = foo3; return func(i); }\n"
      "  int bar32(int i, int j) { var func = foo3; return func(i, j); }\n"
      "  int bar41(int i) {\n"
      "    var func = foo4; return func(i); }\n"
      "  int bar42(int i, int j) {\n"
      "    var func = foo4; return func(i, j); }\n"
      "  int bar43(int i, int j, int k) {\n"
      "    var func = foo4; return func(i, j, k); }\n"
      "}\n"
      "class Expect {\n"
      "  static equals(a, b) {\n"
      "    if (a != b) {\n"
      "      throw 'not equal. expected: $a, got: $b';\n"
      "    }\n"
      "  }\n"
      "}\n"
      "int testMain() {\n"
      "  Test obj = new Test();\n"
      "  Expect.equals(1, obj.foo1());\n"
      "  Expect.equals(1, obj.bar1());\n"
      "\n"
      "  Expect.equals(10, obj.foo2(10));\n"
      "  Expect.equals(10, obj.bar2(10));\n"
      "\n"
      "  Expect.equals(10001, obj.foo3());\n"
      "  Expect.equals(10001, obj.bar30());\n"
      "  Expect.equals(2, obj.foo3(1));\n"
      "  Expect.equals(2, obj.bar31(1));\n"
      "  Expect.equals(4, obj.foo3(2, 2));\n"
      "  Expect.equals(4, obj.bar32(2, 2));\n"
      "\n"
      "  Expect.equals(12, obj.foo4(1));\n"
      "  Expect.equals(12, obj.bar41(1));\n"
      "  Expect.equals(3, obj.foo4(1, 1));\n"
      "  Expect.equals(3, obj.bar42(1, 1));\n"
      "  Expect.equals(6, obj.foo4(2, 2, 2));\n"
      "  Expect.equals(6, obj.bar43(2, 2, 2));\n"
      "\n"
      "  return 0;\n"
      "}\n";

  Dart_Handle result;

  // Load a test script.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));
  result = Dart_SetNativeResolver(lib, &MyNativeClosureResolver, NULL);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(0, value);
}

static void StaticNativeFoo1(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t i = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(0, i);
  Dart_SetReturnValue(args, Dart_NewInteger(0));
  Dart_ExitScope();
}

static void StaticNativeFoo2(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t i = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(1, i);
  Dart_Handle arg = Dart_GetNativeArgument(args, 0);
  Dart_SetReturnValue(args, Dart_NewInteger(GetValue(arg)));
  Dart_ExitScope();
}

static void StaticNativeFoo3(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t i = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(2, i);
  Dart_Handle arg1 = Dart_GetNativeArgument(args, 0);
  Dart_Handle arg2 = Dart_GetNativeArgument(args, 1);
  Dart_SetReturnValue(args, Dart_NewInteger(GetValue(arg1) + GetValue(arg2)));
  Dart_ExitScope();
}

static void StaticNativeFoo4(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t i = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(3, i);
  Dart_Handle arg1 = Dart_GetNativeArgument(args, 0);
  Dart_Handle arg2 = Dart_GetNativeArgument(args, 1);
  Dart_Handle arg3 = Dart_GetNativeArgument(args, 2);
  Dart_SetReturnValue(
      args, Dart_NewInteger(GetValue(arg1) + GetValue(arg2) + GetValue(arg3)));
  Dart_ExitScope();
}

static Dart_NativeFunction MyStaticNativeClosureResolver(
    Dart_Handle name,
    int arg_count,
    bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = false;
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  if (!obj.IsString()) {
    return NULL;
  }
  const char* function_name = obj.ToCString();
  const char* kNativeFoo1 = "StaticNativeFoo1";
  const char* kNativeFoo2 = "StaticNativeFoo2";
  const char* kNativeFoo3 = "StaticNativeFoo3";
  const char* kNativeFoo4 = "StaticNativeFoo4";
  if (!strncmp(function_name, kNativeFoo1, strlen(kNativeFoo1))) {
    return &StaticNativeFoo1;
  } else if (!strncmp(function_name, kNativeFoo2, strlen(kNativeFoo2))) {
    return &StaticNativeFoo2;
  } else if (!strncmp(function_name, kNativeFoo3, strlen(kNativeFoo3))) {
    return &StaticNativeFoo3;
  } else if (!strncmp(function_name, kNativeFoo4, strlen(kNativeFoo4))) {
    return &StaticNativeFoo4;
  } else {
    UNREACHABLE();
    return NULL;
  }
}

TEST_CASE(NativeStaticFunctionClosure) {
  const char* kScriptChars =
      "class Test {"
      "  static int foo1() native \"StaticNativeFoo1\";\n"
      "  static int foo2(int i) native \"StaticNativeFoo2\";\n"
      "  static int foo3([int k = 10000, int l = 1])"
      " native \"StaticNativeFoo3\";\n"
      "  static int foo4(int i, [int j = 10, int k = 1])"
      " native \"StaticNativeFoo4\";\n"
      "  int bar1() { var func = foo1; return func(); }\n"
      "  int bar2(int i) { var func = foo2; return func(i); }\n"
      "  int bar30() { var func = foo3; return func(); }\n"
      "  int bar31(int i) { var func = foo3; return func(i); }\n"
      "  int bar32(int i, int j) { var func = foo3; return func(i, j); }\n"
      "  int bar41(int i) {\n"
      "    var func = foo4; return func(i); }\n"
      "  int bar42(int i, int j) {\n"
      "    var func = foo4; return func(i, j); }\n"
      "  int bar43(int i, int j, int k) {\n"
      "    var func = foo4; return func(i, j, k); }\n"
      "}\n"
      "class Expect {\n"
      "  static equals(a, b) {\n"
      "    if (a != b) {\n"
      "      throw 'not equal. expected: $a, got: $b';\n"
      "    }\n"
      "  }\n"
      "}\n"
      "int testMain() {\n"
      "  Test obj = new Test();\n"
      "  Expect.equals(0, Test.foo1());\n"
      "  Expect.equals(0, obj.bar1());\n"
      "\n"
      "  Expect.equals(10, Test.foo2(10));\n"
      "  Expect.equals(10, obj.bar2(10));\n"
      "\n"
      "  Expect.equals(10001, Test.foo3());\n"
      "  Expect.equals(10001, obj.bar30());\n"
      "  Expect.equals(2, Test.foo3(1));\n"
      "  Expect.equals(2, obj.bar31(1));\n"
      "  Expect.equals(4, Test.foo3(2, 2));\n"
      "  Expect.equals(4, obj.bar32(2, 2));\n"
      "\n"
      "  Expect.equals(12, Test.foo4(1));\n"
      "  Expect.equals(12, obj.bar41(1));\n"
      "  Expect.equals(3, Test.foo4(1, 1));\n"
      "  Expect.equals(3, obj.bar42(1, 1));\n"
      "  Expect.equals(6, Test.foo4(2, 2, 2));\n"
      "  Expect.equals(6, obj.bar43(2, 2, 2));\n"
      "\n"
      "  return 0;\n"
      "}\n";

  Dart_Handle result;

  // Load a test script.
  Dart_Handle url = NewString(TestCase::url());
  Dart_Handle source = NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, Dart_Null(), source, 0, 0);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));
  result = Dart_SetNativeResolver(lib, &MyStaticNativeClosureResolver, NULL);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(0, value);
}

TEST_CASE(RangeLimits) {
  uint8_t chars8[1] = {'a'};
  uint16_t chars16[1] = {'a'};
  int32_t chars32[1] = {'a'};

  EXPECT_ERROR(Dart_NewList(-1),
               "expects argument 'length' to be in the range");
  EXPECT_ERROR(Dart_NewList(Array::kMaxElements + 1),
               "expects argument 'length' to be in the range");
  EXPECT_ERROR(Dart_NewStringFromUTF8(chars8, -1),
               "expects argument 'length' to be in the range");
  EXPECT_ERROR(Dart_NewStringFromUTF8(chars8, OneByteString::kMaxElements + 1),
               "expects argument 'length' to be in the range");
  EXPECT_ERROR(Dart_NewStringFromUTF16(chars16, -1),
               "expects argument 'length' to be in the range");
  EXPECT_ERROR(
      Dart_NewStringFromUTF16(chars16, TwoByteString::kMaxElements + 1),
      "expects argument 'length' to be in the range");
  EXPECT_ERROR(Dart_NewStringFromUTF32(chars32, -1),
               "expects argument 'length' to be in the range");
  EXPECT_ERROR(
      Dart_NewStringFromUTF32(chars32, TwoByteString::kMaxElements + 1),
      "expects argument 'length' to be in the range");
}

TEST_CASE(NewString_Null) {
  Dart_Handle str = Dart_NewStringFromUTF8(NULL, 0);
  EXPECT_VALID(str);
  EXPECT(Dart_IsString(str));
  intptr_t len = -1;
  EXPECT_VALID(Dart_StringLength(str, &len));
  EXPECT_EQ(0, len);

  str = Dart_NewStringFromUTF16(NULL, 0);
  EXPECT_VALID(str);
  EXPECT(Dart_IsString(str));
  len = -1;
  EXPECT_VALID(Dart_StringLength(str, &len));
  EXPECT_EQ(0, len);

  str = Dart_NewStringFromUTF32(NULL, 0);
  EXPECT_VALID(str);
  EXPECT(Dart_IsString(str));
  len = -1;
  EXPECT_VALID(Dart_StringLength(str, &len));
  EXPECT_EQ(0, len);
}

// Try to allocate a peer with a handles to objects of prohibited
// subtypes.
TEST_CASE(InvalidGetSetPeer) {
  void* out = &out;
  EXPECT(Dart_IsError(Dart_GetPeer(Dart_Null(), &out)));
  EXPECT(out == &out);
  EXPECT(Dart_IsError(Dart_SetPeer(Dart_Null(), &out)));
  out = &out;
  EXPECT(Dart_IsError(Dart_GetPeer(Dart_True(), &out)));
  EXPECT(out == &out);
  EXPECT(Dart_IsError(Dart_SetPeer(Dart_True(), &out)));
  out = &out;
  EXPECT(Dart_IsError(Dart_GetPeer(Dart_False(), &out)));
  EXPECT(out == &out);
  EXPECT(Dart_IsError(Dart_SetPeer(Dart_False(), &out)));
  out = &out;
  Dart_Handle smi = Dart_NewInteger(0);
  EXPECT(Dart_IsError(Dart_GetPeer(smi, &out)));
  EXPECT(out == &out);
  EXPECT(Dart_IsError(Dart_SetPeer(smi, &out)));
  out = &out;
  Dart_Handle big = Dart_NewIntegerFromHexCString("0x10000000000000000");
  EXPECT(Dart_IsError(Dart_GetPeer(big, &out)));
  EXPECT(out == &out);
  EXPECT(Dart_IsError(Dart_SetPeer(big, &out)));
  Dart_Handle dbl = Dart_NewDouble(0.0);
  EXPECT(Dart_IsError(Dart_GetPeer(dbl, &out)));
  EXPECT(out == &out);
  EXPECT(Dart_IsError(Dart_SetPeer(dbl, &out)));
}

// Allocates an object in new space and assigns it a peer.  Removes
// the peer and checks that the count of peer objects is decremented
// by one.
TEST_CASE(OneNewSpacePeer) {
  Isolate* isolate = Isolate::Current();
  Dart_Handle str = NewString("a string");
  EXPECT_VALID(str);
  EXPECT(Dart_IsString(str));
  EXPECT_EQ(0, isolate->heap()->PeerCount());
  void* out = &out;
  EXPECT_VALID(Dart_GetPeer(str, &out));
  EXPECT(out == NULL);
  int peer = 1234;
  EXPECT_VALID(Dart_SetPeer(str, &peer));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  out = &out;
  EXPECT_VALID(Dart_GetPeer(str, &out));
  EXPECT(out == reinterpret_cast<void*>(&peer));
  EXPECT_VALID(Dart_SetPeer(str, NULL));
  out = &out;
  EXPECT_VALID(Dart_GetPeer(str, &out));
  EXPECT(out == NULL);
  EXPECT_EQ(0, isolate->heap()->PeerCount());
}

// Allocates an object in new space and assigns it a peer.  Allows the
// peer referent to be garbage collected and checks that the count of
// peer objects is decremented by one.
TEST_CASE(CollectOneNewSpacePeer) {
  Isolate* isolate = Isolate::Current();
  Dart_EnterScope();
  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);
    Dart_Handle str = NewString("a string");
    EXPECT_VALID(str);
    EXPECT(Dart_IsString(str));
    EXPECT_EQ(0, isolate->heap()->PeerCount());
    void* out = &out;
    EXPECT_VALID(Dart_GetPeer(str, &out));
    EXPECT(out == NULL);
    int peer = 1234;
    EXPECT_VALID(Dart_SetPeer(str, &peer));
    EXPECT_EQ(1, isolate->heap()->PeerCount());
    out = &out;
    EXPECT_VALID(Dart_GetPeer(str, &out));
    EXPECT(out == reinterpret_cast<void*>(&peer));
    {
      TransitionNativeToVM transition(thread);
      isolate->heap()->CollectGarbage(Heap::kNew);
      EXPECT_EQ(1, isolate->heap()->PeerCount());
    }
    out = &out;
    EXPECT_VALID(Dart_GetPeer(str, &out));
    EXPECT(out == reinterpret_cast<void*>(&peer));
  }
  Dart_ExitScope();
  {
    TransitionNativeToVM transition(thread);
    isolate->heap()->CollectGarbage(Heap::kNew);
    EXPECT_EQ(0, isolate->heap()->PeerCount());
  }
}

// Allocates two objects in new space and assigns them peers.  Removes
// the peers and checks that the count of peer objects is decremented
// by two.
TEST_CASE(TwoNewSpacePeers) {
  Isolate* isolate = Isolate::Current();
  Dart_Handle s1 = NewString("s1");
  EXPECT_VALID(s1);
  EXPECT(Dart_IsString(s1));
  void* o1 = &o1;
  EXPECT_VALID(Dart_GetPeer(s1, &o1));
  EXPECT(o1 == NULL);
  EXPECT_EQ(0, isolate->heap()->PeerCount());
  int p1 = 1234;
  EXPECT_VALID(Dart_SetPeer(s1, &p1));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  EXPECT_VALID(Dart_GetPeer(s1, &o1));
  EXPECT(o1 == reinterpret_cast<void*>(&p1));
  Dart_Handle s2 = NewString("a string");
  EXPECT_VALID(s2);
  EXPECT(Dart_IsString(s2));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  void* o2 = &o2;
  EXPECT(Dart_GetPeer(s2, &o2));
  EXPECT(o2 == NULL);
  int p2 = 5678;
  EXPECT_VALID(Dart_SetPeer(s2, &p2));
  EXPECT_EQ(2, isolate->heap()->PeerCount());
  EXPECT_VALID(Dart_GetPeer(s2, &o2));
  EXPECT(o2 == reinterpret_cast<void*>(&p2));
  EXPECT_VALID(Dart_SetPeer(s1, NULL));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  EXPECT(Dart_GetPeer(s1, &o1));
  EXPECT(o1 == NULL);
  EXPECT_VALID(Dart_SetPeer(s2, NULL));
  EXPECT_EQ(0, isolate->heap()->PeerCount());
  EXPECT(Dart_GetPeer(s2, &o2));
  EXPECT(o2 == NULL);
}

// Allocates two objects in new space and assigns them a peer.  Allow
// the peer referents to be garbage collected and check that the count
// of peer objects is decremented by two.
TEST_CASE(CollectTwoNewSpacePeers) {
  Isolate* isolate = Isolate::Current();
  Dart_EnterScope();
  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);
    Dart_Handle s1 = NewString("s1");
    EXPECT_VALID(s1);
    EXPECT(Dart_IsString(s1));
    EXPECT_EQ(0, isolate->heap()->PeerCount());
    void* o1 = &o1;
    EXPECT(Dart_GetPeer(s1, &o1));
    EXPECT(o1 == NULL);
    int p1 = 1234;
    EXPECT_VALID(Dart_SetPeer(s1, &p1));
    EXPECT_EQ(1, isolate->heap()->PeerCount());
    EXPECT_VALID(Dart_GetPeer(s1, &o1));
    EXPECT(o1 == reinterpret_cast<void*>(&p1));
    Dart_Handle s2 = NewString("s2");
    EXPECT_VALID(s2);
    EXPECT(Dart_IsString(s2));
    EXPECT_EQ(1, isolate->heap()->PeerCount());
    void* o2 = &o2;
    EXPECT(Dart_GetPeer(s2, &o2));
    EXPECT(o2 == NULL);
    int p2 = 5678;
    EXPECT_VALID(Dart_SetPeer(s2, &p2));
    EXPECT_EQ(2, isolate->heap()->PeerCount());
    EXPECT_VALID(Dart_GetPeer(s2, &o2));
    EXPECT(o2 == reinterpret_cast<void*>(&p2));
  }
  Dart_ExitScope();
  {
    TransitionNativeToVM transition(thread);
    isolate->heap()->CollectGarbage(Heap::kNew);
    EXPECT_EQ(0, isolate->heap()->PeerCount());
  }
}

// Allocates several objects in new space.  Performs successive
// garbage collections and checks that the peer count is stable.
TEST_CASE(CopyNewSpacePeers) {
  const int kPeerCount = 10;
  Isolate* isolate = Isolate::Current();
  Dart_Handle s[kPeerCount];
  for (int i = 0; i < kPeerCount; ++i) {
    s[i] = NewString("a string");
    EXPECT_VALID(s[i]);
    EXPECT(Dart_IsString(s[i]));
    void* o = &o;
    EXPECT_VALID(Dart_GetPeer(s[i], &o));
    EXPECT(o == NULL);
  }
  EXPECT_EQ(0, isolate->heap()->PeerCount());
  int p[kPeerCount];
  for (int i = 0; i < kPeerCount; ++i) {
    EXPECT_VALID(Dart_SetPeer(s[i], &p[i]));
    EXPECT_EQ(i + 1, isolate->heap()->PeerCount());
    void* o = &o;
    EXPECT_VALID(Dart_GetPeer(s[i], &o));
    EXPECT(o == reinterpret_cast<void*>(&p[i]));
  }
  EXPECT_EQ(kPeerCount, isolate->heap()->PeerCount());
  {
    TransitionNativeToVM transition(thread);
    isolate->heap()->CollectGarbage(Heap::kNew);
    EXPECT_EQ(kPeerCount, isolate->heap()->PeerCount());
    isolate->heap()->CollectGarbage(Heap::kNew);
    EXPECT_EQ(kPeerCount, isolate->heap()->PeerCount());
  }
}

// Allocates an object in new space and assigns it a peer.  Promotes
// the peer to old space.  Removes the peer and check that the count
// of peer objects is decremented by one.
TEST_CASE(OnePromotedPeer) {
  Isolate* isolate = Isolate::Current();
  Dart_Handle str = NewString("a string");
  EXPECT_VALID(str);
  EXPECT(Dart_IsString(str));
  EXPECT_EQ(0, isolate->heap()->PeerCount());
  void* out = &out;
  EXPECT(Dart_GetPeer(str, &out));
  EXPECT(out == NULL);
  int peer = 1234;
  EXPECT_VALID(Dart_SetPeer(str, &peer));
  out = &out;
  EXPECT(Dart_GetPeer(str, &out));
  EXPECT(out == reinterpret_cast<void*>(&peer));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  {
    TransitionNativeToVM transition(thread);
    isolate->heap()->CollectGarbage(Heap::kNew);
    isolate->heap()->CollectGarbage(Heap::kNew);
  }
  {
    CHECK_API_SCOPE(thread);
    HANDLESCOPE(thread);
    String& handle = String::Handle();
    handle ^= Api::UnwrapHandle(str);
    EXPECT(handle.IsOld());
  }
  EXPECT_VALID(Dart_GetPeer(str, &out));
  EXPECT(out == reinterpret_cast<void*>(&peer));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  EXPECT_VALID(Dart_SetPeer(str, NULL));
  out = &out;
  EXPECT_VALID(Dart_GetPeer(str, &out));
  EXPECT(out == NULL);
  EXPECT_EQ(0, isolate->heap()->PeerCount());
}

// Allocates an object in old space and assigns it a peer.  Removes
// the peer and checks that the count of peer objects is decremented
// by one.
TEST_CASE(OneOldSpacePeer) {
  Isolate* isolate = Isolate::Current();
  Dart_Handle str = Api::NewHandle(thread, String::New("str", Heap::kOld));
  EXPECT_VALID(str);
  EXPECT(Dart_IsString(str));
  EXPECT_EQ(0, isolate->heap()->PeerCount());
  void* out = &out;
  EXPECT(Dart_GetPeer(str, &out));
  EXPECT(out == NULL);
  int peer = 1234;
  EXPECT_VALID(Dart_SetPeer(str, &peer));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  out = &out;
  EXPECT_VALID(Dart_GetPeer(str, &out));
  EXPECT(out == reinterpret_cast<void*>(&peer));
  {
    TransitionNativeToVM transition(thread);
    isolate->heap()->CollectGarbage(Heap::kOld);
    EXPECT_EQ(1, isolate->heap()->PeerCount());
  }
  EXPECT_VALID(Dart_GetPeer(str, &out));
  EXPECT(out == reinterpret_cast<void*>(&peer));
  EXPECT_VALID(Dart_SetPeer(str, NULL));
  out = &out;
  EXPECT_VALID(Dart_GetPeer(str, &out));
  EXPECT(out == NULL);
  EXPECT_EQ(0, isolate->heap()->PeerCount());
}

// Allocates an object in old space and assigns it a peer.  Allow the
// peer referent to be garbage collected and check that the count of
// peer objects is decremented by one.
TEST_CASE(CollectOneOldSpacePeer) {
  Isolate* isolate = Isolate::Current();
  Dart_EnterScope();
  {
    Thread* T = Thread::Current();
    CHECK_API_SCOPE(T);
    HANDLESCOPE(T);
    Dart_Handle str = Api::NewHandle(T, String::New("str", Heap::kOld));
    EXPECT_VALID(str);
    EXPECT(Dart_IsString(str));
    EXPECT_EQ(0, isolate->heap()->PeerCount());
    void* out = &out;
    EXPECT(Dart_GetPeer(str, &out));
    EXPECT(out == NULL);
    int peer = 1234;
    EXPECT_VALID(Dart_SetPeer(str, &peer));
    EXPECT_EQ(1, isolate->heap()->PeerCount());
    out = &out;
    EXPECT_VALID(Dart_GetPeer(str, &out));
    EXPECT(out == reinterpret_cast<void*>(&peer));
    {
      TransitionNativeToVM transition(thread);
      isolate->heap()->CollectGarbage(Heap::kOld);
      EXPECT_EQ(1, isolate->heap()->PeerCount());
    }
    EXPECT_VALID(Dart_GetPeer(str, &out));
    EXPECT(out == reinterpret_cast<void*>(&peer));
  }
  Dart_ExitScope();
  {
    TransitionNativeToVM transition(thread);
    isolate->heap()->CollectGarbage(Heap::kOld);
    EXPECT_EQ(0, isolate->heap()->PeerCount());
  }
}

// Allocates two objects in old space and assigns them peers.  Removes
// the peers and checks that the count of peer objects is decremented
// by two.
TEST_CASE(TwoOldSpacePeers) {
  Isolate* isolate = Isolate::Current();
  Dart_Handle s1 = Api::NewHandle(thread, String::New("s1", Heap::kOld));
  EXPECT_VALID(s1);
  EXPECT(Dart_IsString(s1));
  EXPECT_EQ(0, isolate->heap()->PeerCount());
  void* o1 = &o1;
  EXPECT(Dart_GetPeer(s1, &o1));
  EXPECT(o1 == NULL);
  int p1 = 1234;
  EXPECT_VALID(Dart_SetPeer(s1, &p1));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  o1 = &o1;
  EXPECT_VALID(Dart_GetPeer(s1, &o1));
  EXPECT(o1 == reinterpret_cast<void*>(&p1));
  Dart_Handle s2 = Api::NewHandle(thread, String::New("s2", Heap::kOld));
  EXPECT_VALID(s2);
  EXPECT(Dart_IsString(s2));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  void* o2 = &o2;
  EXPECT(Dart_GetPeer(s2, &o2));
  EXPECT(o2 == NULL);
  int p2 = 5678;
  EXPECT_VALID(Dart_SetPeer(s2, &p2));
  EXPECT_EQ(2, isolate->heap()->PeerCount());
  o2 = &o2;
  EXPECT_VALID(Dart_GetPeer(s2, &o2));
  EXPECT(o2 == reinterpret_cast<void*>(&p2));
  EXPECT_VALID(Dart_SetPeer(s1, NULL));
  EXPECT_EQ(1, isolate->heap()->PeerCount());
  o1 = &o1;
  EXPECT(Dart_GetPeer(s1, &o1));
  EXPECT(o1 == NULL);
  EXPECT_VALID(Dart_SetPeer(s2, NULL));
  EXPECT_EQ(0, isolate->heap()->PeerCount());
  o2 = &o2;
  EXPECT_VALID(Dart_GetPeer(s2, &o2));
  EXPECT(o2 == NULL);
}

// Allocates two objects in old space and assigns them a peer.  Allows
// the peer referents to be garbage collected and checks that the
// count of peer objects is decremented by two.
TEST_CASE(CollectTwoOldSpacePeers) {
  Isolate* isolate = Isolate::Current();
  Dart_EnterScope();
  {
    Thread* T = Thread::Current();
    CHECK_API_SCOPE(T);
    HANDLESCOPE(T);
    Dart_Handle s1 = Api::NewHandle(T, String::New("s1", Heap::kOld));
    EXPECT_VALID(s1);
    EXPECT(Dart_IsString(s1));
    EXPECT_EQ(0, isolate->heap()->PeerCount());
    void* o1 = &o1;
    EXPECT(Dart_GetPeer(s1, &o1));
    EXPECT(o1 == NULL);
    int p1 = 1234;
    EXPECT_VALID(Dart_SetPeer(s1, &p1));
    EXPECT_EQ(1, isolate->heap()->PeerCount());
    o1 = &o1;
    EXPECT_VALID(Dart_GetPeer(s1, &o1));
    EXPECT(o1 == reinterpret_cast<void*>(&p1));
    Dart_Handle s2 = Api::NewHandle(T, String::New("s2", Heap::kOld));
    EXPECT_VALID(s2);
    EXPECT(Dart_IsString(s2));
    EXPECT_EQ(1, isolate->heap()->PeerCount());
    void* o2 = &o2;
    EXPECT(Dart_GetPeer(s2, &o2));
    EXPECT(o2 == NULL);
    int p2 = 5678;
    EXPECT_VALID(Dart_SetPeer(s2, &p2));
    EXPECT_EQ(2, isolate->heap()->PeerCount());
    o2 = &o2;
    EXPECT_VALID(Dart_GetPeer(s2, &o2));
    EXPECT(o2 == reinterpret_cast<void*>(&p2));
  }
  Dart_ExitScope();
  {
    TransitionNativeToVM transition(thread);
    isolate->heap()->CollectGarbage(Heap::kOld);
    EXPECT_EQ(0, isolate->heap()->PeerCount());
  }
}

// Test API call to make strings external.
static void MakeExternalCback(void* peer) {
  *static_cast<int*>(peer) *= 2;
}

TEST_CASE(MakeExternalString) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  static int peer8 = 40;
  static int peer16 = 41;
  static int canonical_str_peer = 42;
  intptr_t length = 0;
  intptr_t expected_length = 0;
  {
    Dart_EnterScope();

    // First test some negative conditions.
    uint8_t data8[] = {'h', 'e', 'l', 'l', 'o'};
    const char* err = "string";
    Dart_Handle err_str = NewString(err);
    Dart_Handle ext_err_str =
        Dart_NewExternalLatin1String(data8, ARRAY_SIZE(data8), NULL, NULL);
    Dart_Handle result = Dart_MakeExternalString(Dart_Null(), data8,
                                                 ARRAY_SIZE(data8), NULL, NULL);
    EXPECT(Dart_IsError(result));  // Null string object passed in.
    result =
        Dart_MakeExternalString(err_str, NULL, ARRAY_SIZE(data8), NULL, NULL);
    EXPECT(Dart_IsError(result));  // Null array pointer passed in.
    result = Dart_MakeExternalString(err_str, data8, 1, NULL, NULL);
    EXPECT(Dart_IsError(result));  // Invalid length passed in.

    const intptr_t kLength = 10;
    intptr_t size = 0;

    // Test with an external string.
    result = Dart_MakeExternalString(ext_err_str, data8, ARRAY_SIZE(data8),
                                     NULL, NULL);
    EXPECT(Dart_IsString(result));
    EXPECT(Dart_IsExternalString(result));

    // Test with an empty string.
    Dart_Handle empty_str = NewString("");
    EXPECT(Dart_IsString(empty_str));
    EXPECT(!Dart_IsExternalString(empty_str));
    uint8_t ext_empty_str[kLength];
    Dart_Handle str =
        Dart_MakeExternalString(empty_str, ext_empty_str, kLength, NULL, NULL);
    EXPECT(Dart_IsString(str));
    EXPECT(Dart_IsString(empty_str));
    EXPECT(Dart_IsStringLatin1(str));
    EXPECT(Dart_IsStringLatin1(empty_str));
    EXPECT(Dart_IsExternalString(str));
    EXPECT(Dart_IsExternalString(empty_str));
    EXPECT_VALID(Dart_StringLength(str, &length));
    EXPECT_EQ(0, length);

    // Test with single character canonical string, it should not become
    // external string but the peer should be setup for it.
    Dart_Handle canonical_str =
        Api::NewHandle(thread, Symbols::New(thread, "*"));
    EXPECT(Dart_IsString(canonical_str));
    EXPECT(!Dart_IsExternalString(canonical_str));
    uint8_t ext_canonical_str[kLength];
    str = Dart_MakeExternalString(canonical_str, ext_canonical_str, kLength,
                                  &canonical_str_peer, MakeExternalCback);
    EXPECT(Dart_IsString(str));
    EXPECT(!Dart_IsExternalString(canonical_str));
    EXPECT_EQ(canonical_str, str);
    EXPECT(Dart_IsString(canonical_str));
    EXPECT(!Dart_IsExternalString(canonical_str));
    void* peer;
    EXPECT_VALID(Dart_StringGetProperties(str, &size, &length, &peer));
    EXPECT_EQ(1, size);
    EXPECT_EQ(1, length);
    EXPECT_EQ(reinterpret_cast<void*>(&canonical_str_peer), peer);

    // Test with a one byte ascii string.
    const char* ascii = "?unseen";
    expected_length = strlen(ascii);
    Dart_Handle ascii_str = NewString(ascii);
    EXPECT_VALID(ascii_str);
    EXPECT(Dart_IsString(ascii_str));
    EXPECT(Dart_IsStringLatin1(ascii_str));
    EXPECT(!Dart_IsExternalString(ascii_str));
    EXPECT_VALID(Dart_StringLength(ascii_str, &length));
    EXPECT_EQ(expected_length, length);

    uint8_t ext_ascii_str[kLength];
    EXPECT_VALID(Dart_StringStorageSize(ascii_str, &size));
    str = Dart_MakeExternalString(ascii_str, ext_ascii_str, size, &peer8,
                                  MakeExternalCback);
    EXPECT(Dart_IsString(str));
    EXPECT(Dart_IsString(ascii_str));
    EXPECT(Dart_IsStringLatin1(str));
    EXPECT(Dart_IsStringLatin1(ascii_str));
    EXPECT(Dart_IsExternalString(str));
    EXPECT(Dart_IsExternalString(ascii_str));
    EXPECT_VALID(Dart_StringLength(str, &length));
    EXPECT_EQ(expected_length, length);
    EXPECT_VALID(Dart_StringLength(ascii_str, &length));
    EXPECT_EQ(expected_length, length);
    EXPECT(Dart_IdentityEquals(str, ascii_str));
    for (intptr_t i = 0; i < length; i++) {
      EXPECT_EQ(ascii[i], ext_ascii_str[i]);
    }

    uint8_t data[] = {0xE4, 0xBA, 0x8c};  // U+4E8C.
    expected_length = 1;
    Dart_Handle utf16_str = Dart_NewStringFromUTF8(data, ARRAY_SIZE(data));
    EXPECT_VALID(utf16_str);
    EXPECT(Dart_IsString(utf16_str));
    EXPECT(!Dart_IsStringLatin1(utf16_str));
    EXPECT(!Dart_IsExternalString(utf16_str));
    EXPECT_VALID(Dart_StringLength(utf16_str, &length));
    EXPECT_EQ(expected_length, length);

    // Test with a two byte string.
    uint16_t ext_utf16_str[kLength];
    EXPECT_VALID(Dart_StringStorageSize(utf16_str, &size));
    str = Dart_MakeExternalString(utf16_str, ext_utf16_str, size, &peer16,
                                  MakeExternalCback);
    EXPECT(Dart_IsString(str));
    EXPECT(Dart_IsString(utf16_str));
    EXPECT(!Dart_IsStringLatin1(str));
    EXPECT(!Dart_IsStringLatin1(utf16_str));
    EXPECT(Dart_IsExternalString(str));
    EXPECT(Dart_IsExternalString(utf16_str));
    EXPECT_VALID(Dart_StringLength(str, &length));
    EXPECT_EQ(expected_length, length);
    EXPECT_VALID(Dart_StringLength(utf16_str, &length));
    EXPECT_EQ(expected_length, length);
    EXPECT(Dart_IdentityEquals(str, utf16_str));
    for (intptr_t i = 0; i < length; i++) {
      EXPECT_EQ(0x4e8c, ext_utf16_str[i]);
    }

    Zone* zone = thread->zone();
    // Test with a symbol (hash value should be preserved on externalization).
    const char* symbol_ascii = "?unseen";
    expected_length = strlen(symbol_ascii);
    Dart_Handle symbol_str = Api::NewHandle(
        thread, Symbols::New(thread, symbol_ascii, expected_length));
    EXPECT_VALID(symbol_str);
    EXPECT(Dart_IsString(symbol_str));
    EXPECT(Dart_IsStringLatin1(symbol_str));
    EXPECT(!Dart_IsExternalString(symbol_str));
    EXPECT_VALID(Dart_StringLength(symbol_str, &length));
    EXPECT_EQ(expected_length, length);
    EXPECT(Api::UnwrapStringHandle(zone, symbol_str).HasHash());

    uint8_t ext_symbol_ascii[kLength];
    EXPECT_VALID(Dart_StringStorageSize(symbol_str, &size));
    str = Dart_MakeExternalString(symbol_str, ext_symbol_ascii, size, &peer8,
                                  MakeExternalCback);
    EXPECT(Api::UnwrapStringHandle(zone, str).HasHash());
    EXPECT(Api::UnwrapStringHandle(zone, str).Hash() ==
           Api::UnwrapStringHandle(zone, symbol_str).Hash());
    EXPECT(Dart_IsString(str));
    EXPECT(Dart_IsString(symbol_str));
    EXPECT(Dart_IsStringLatin1(str));
    EXPECT(Dart_IsStringLatin1(symbol_str));
    EXPECT(Dart_IsExternalString(str));
    EXPECT(Dart_IsExternalString(symbol_str));
    EXPECT_VALID(Dart_StringLength(str, &length));
    EXPECT_EQ(expected_length, length);
    EXPECT_VALID(Dart_StringLength(symbol_str, &length));
    EXPECT_EQ(expected_length, length);
    EXPECT(Dart_IdentityEquals(str, symbol_str));
    for (intptr_t i = 0; i < length; i++) {
      EXPECT_EQ(symbol_ascii[i], ext_symbol_ascii[i]);
    }

    Dart_ExitScope();
  }
  EXPECT_EQ(40, peer8);
  EXPECT_EQ(41, peer16);
  EXPECT_EQ(42, canonical_str_peer);
  {
    TransitionNativeToVM transition(thread);
    Isolate::Current()->heap()->CollectAllGarbage();
    GCTestHelper::WaitForGCTasks();
  }
  EXPECT_EQ(80, peer8);
  EXPECT_EQ(82, peer16);
  EXPECT_EQ(42, canonical_str_peer);  // "*" Symbol is not removed on GC.

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(ExternalizeConstantStrings) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "String testMain() {\n"
      "  return 'constant string';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle result = Dart_Invoke(lib, NewString("testMain"), 0, NULL);
  const char* expected_str = "constant string";
  const intptr_t kExpectedLen = 15;
  uint8_t ext_str[kExpectedLen];
  Dart_Handle str =
      Dart_MakeExternalString(result, ext_str, kExpectedLen, NULL, NULL);

  EXPECT(Dart_IsExternalString(str));
  for (intptr_t i = 0; i < kExpectedLen; i++) {
    EXPECT_EQ(expected_str[i], ext_str[i]);
  }

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(LazyLoadDeoptimizes) {
  const char* kLoadFirst =
      "library L;\n"
      "start(a) {\n"
      "  var obj = (a == 1) ? createB() : new A();\n"
      "  for (int i = 0; i < 4000; i++) {\n"
      "    var res = obj.foo();\n"
      "    if (a == 1) { if (res != 1) throw 'Error'; }\n"
      "    else if (res != 2) throw 'Error'; \n"
      "  }\n"
      "}\n"
      "\n"
      "createB() => new B();"
      "\n"
      "class A {\n"
      "  foo() => goo();\n"
      "  goo() => 2;\n"
      "}\n";
  const char* kLoadSecond =
      "part of L;"
      "class B extends A {\n"
      "  goo() => 1;\n"
      "}\n";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle lib1 = TestCase::LoadTestScript(kLoadFirst, NULL);
  Dart_Handle dart_args[1];
  dart_args[0] = Dart_NewInteger(0);
  result = Dart_Invoke(lib1, NewString("start"), 1, dart_args);
  EXPECT_VALID(result);

  Dart_Handle source = NewString(kLoadSecond);
  Dart_Handle url = NewString(TestCase::url());
  Dart_LoadSource(TestCase::lib(), url, Dart_Null(), source, 0, 0);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);

  dart_args[0] = Dart_NewInteger(1);
  result = Dart_Invoke(lib1, NewString("start"), 1, dart_args);
  EXPECT_VALID(result);
}

// Test external strings and optimized code.
static void ExternalStringDeoptimize_Finalize(void* peer) {
  delete[] reinterpret_cast<char*>(peer);
}

static void A_change_str_native(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle str = Dart_GetNativeArgument(args, 0);
  EXPECT(Dart_IsString(str));
  void* peer;
  Dart_Handle str_arg = Dart_GetNativeStringArgument(args, 0, &peer);
  EXPECT(Dart_IsString(str_arg));
  EXPECT(!peer);
  intptr_t size = 0;
  EXPECT_VALID(Dart_StringStorageSize(str, &size));
  intptr_t arg_size = 0;
  EXPECT_VALID(Dart_StringStorageSize(str_arg, &arg_size));
  EXPECT_EQ(size, arg_size);
  char* str_data = new char[size];
  Dart_Handle result = Dart_MakeExternalString(
      str, str_data, size, str_data, &ExternalStringDeoptimize_Finalize);
  EXPECT_VALID(result);
  EXPECT(Dart_IsExternalString(result));
  Dart_ExitScope();
}

static Dart_NativeFunction ExternalStringDeoptimize_native_lookup(
    Dart_Handle name,
    int argument_count,
    bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  return reinterpret_cast<Dart_NativeFunction>(&A_change_str_native);
}

// Do not use guarding mechanism on externalizable classes, since their class
// can change on the fly,
TEST_CASE(GuardExternalizedString) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "main() {\n"
      "  var a = new A('hello');\n"
      "  var res = runOne(a);\n"
      "  if (res != 10640000) return -1;\n"
      "  change_str(a.f);\n"
      "  res = runOne(a);\n"
      "  return res;\n"
      "}\n"
      "runOne(a) {\n"
      "  var sum = 0;\n"
      "  for (int i = 0; i < 20000; i++) {\n"
      "    for (int j = 0; j < a.f.length; j++) {\n"
      "      sum += a.f.codeUnitAt(j);\n"
      "    }\n"
      "  }\n"
      "  return sum;\n"
      "}\n"
      "class A {\n"
      "  var f;\n"
      "  A(this.f);\n"
      "}\n"
      "change_str(String s) native 'A_change_str';\n"
      "";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, &ExternalStringDeoptimize_native_lookup);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(10640000, value);

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(ExternalStringDeoptimize) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "String str = 'A';\n"
      "class A {\n"
      "  static change_str(String s) native 'A_change_str';\n"
      "}\n"
      "sum_chars(String s, bool b) {\n"
      "  var result = 0;\n"
      "  for (var i = 0; i < s.length; i++) {\n"
      "    if (b && i == 0) A.change_str(str);\n"
      "    result += s.codeUnitAt(i);"
      "  }\n"
      "  return result;\n"
      "}\n"
      "main() {\n"
      "  str = '$str$str';\n"
      "  for (var i = 0; i < 2000; i++) sum_chars(str, false);\n"
      "  var x = sum_chars(str, false);\n"
      "  var y = sum_chars(str, true);\n"
      "  return x + y;\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, &ExternalStringDeoptimize_native_lookup);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(260, value);

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(ExternalStringPolymorphicDeoptimize) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "const strA = 'AAAA';\n"
      "class A {\n"
      "  static change_str(String s) native 'A_change_str';\n"
      "}\n"
      "compare(a, b, [i = 0]) {\n"
      "  return a.codeUnitAt(i) == b.codeUnitAt(i);\n"
      "}\n"
      "compareA(b, [i = 0]) {\n"
      "  return compare(strA, b, i);\n"
      "}\n"
      "main() {\n"
      "  var externalA = 'AA' + 'AA';\n"
      "  A.change_str(externalA);\n"
      "  compare('AA' + 'AA', strA);\n"
      "  compare(externalA, strA);\n"
      "  for (var i = 0; i < 10000; i++) compareA(strA);\n"
      "  A.change_str(strA);\n"
      "  return compareA('AA' + 'AA');\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, &ExternalStringDeoptimize_native_lookup);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  bool value = false;
  result = Dart_BooleanValue(result, &value);
  EXPECT_VALID(result);
  EXPECT(value);

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(ExternalStringLoadElimination) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "class A {\n"
      "  static change_str(String s) native 'A_change_str';\n"
      "}\n"
      "double_char0(str) {\n"
      "  return str.codeUnitAt(0) + str.codeUnitAt(0);\n"
      "}\n"
      "main() {\n"
      "  var externalA = 'AA' + 'AA';\n"
      "  A.change_str(externalA);\n"
      "  for (var i = 0; i < 10000; i++) double_char0(externalA);\n"
      "  var result = double_char0(externalA);\n"
      "  return result == 130;\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, &ExternalStringDeoptimize_native_lookup);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  bool value = false;
  result = Dart_BooleanValue(result, &value);
  EXPECT_VALID(result);
  EXPECT(value);

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(ExternalStringGuardFieldDeoptimize) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "const strA = 'AAAA';\n"
      "class A {\n"
      "  static change_str(String s) native 'A_change_str';\n"
      "}\n"
      "class G { var f = 'A'; }\n"
      "final guard = new G();\n"
      "var shouldExternalize = false;\n"
      "ext() { if (shouldExternalize) A.change_str(strA); }\n"
      "compare(a, b, [i = 0]) {\n"
      "  guard.f = a;\n"
      "  ext();"
      "  return a.codeUnitAt(i) == b.codeUnitAt(i);\n"
      "}\n"
      "compareA(b, [i = 0]) {\n"
      "  return compare(strA, b, i);\n"
      "}\n"
      "main() {\n"
      "  var externalA = 'AA' + 'AA';\n"
      "  A.change_str(externalA);\n"
      "  compare('AA' + 'AA', strA);\n"
      "  for (var i = 0; i < 10000; i++) compareA(strA);\n"
      "  shouldExternalize = true;\n"
      "  return compareA('AA' + 'AA');\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, &ExternalStringDeoptimize_native_lookup);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  bool value = false;
  result = Dart_BooleanValue(result, &value);
  EXPECT_VALID(result);
  EXPECT(value);

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(ExternalStringStaticFieldDeoptimize) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "const strA = 'AAAA';\n"
      "class A {\n"
      "  static change_str(String s) native 'A_change_str';\n"
      "}\n"
      "class G { static final f = strA; }\n"
      "compare(a, b, [i = 0]) {\n"
      "  return a.codeUnitAt(i) == b.codeUnitAt(i);\n"
      "}\n"
      "compareA(b, [i = 0]) {\n"
      "  return compare(G.f, b, i);\n"
      "}\n"
      "main() {\n"
      "  var externalA = 'AA' + 'AA';\n"
      "  A.change_str(externalA);\n"
      "  compare('AA' + 'AA', strA);\n"
      "  for (var i = 0; i < 10000; i++) compareA(strA);\n"
      "  A.change_str(G.f);"
      "  return compareA('AA' + 'AA');\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, &ExternalStringDeoptimize_native_lookup);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  bool value = false;
  result = Dart_BooleanValue(result, &value);
  EXPECT_VALID(result);
  EXPECT(value);

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(ExternalStringTrimDoubleParse) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "String str = 'A';\n"
      "class A {\n"
      "  static change_str(String s) native 'A_change_str';\n"
      "}\n"
      "main() {\n"
      "  var externalOneByteString = ' 0.2\\xA0 ';\n;"
      "  A.change_str(externalOneByteString);\n"
      "  var externalTwoByteString = ' \\u{2029}0.6\\u{2029} ';\n"
      "  A.change_str(externalTwoByteString);\n"
      "  var x = double.parse(externalOneByteString);\n"
      "  var y = double.parse(externalTwoByteString);\n"
      "  return ((x + y) * 10).toInt();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, &ExternalStringDeoptimize_native_lookup);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(8, value);

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(ExternalStringDoubleParse) {
  const bool saved_flag = FLAG_support_externalizable_strings;
  FLAG_support_externalizable_strings = true;

  const char* kScriptChars =
      "String str = 'A';\n"
      "class A {\n"
      "  static change_str(String s) native 'A_change_str';\n"
      "}\n"
      "main() {\n"
      "  var externalOneByteString = '0.2';\n;"
      "  A.change_str(externalOneByteString);\n"
      "  var externalTwoByteString = '0.6';\n"
      "  A.change_str(externalTwoByteString);\n"
      "  var x = double.parse(externalOneByteString);\n"
      "  var y = double.parse(externalTwoByteString);\n"
      "  return ((x + y) * 10).toInt();\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, &ExternalStringDeoptimize_native_lookup);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(8, value);

  FLAG_support_externalizable_strings = saved_flag;
}

TEST_CASE(ExternalStringIndexOf) {
  const char* kScriptChars =
      "main(String pattern) {\n"
      "  var str = 'Hello World';\n"
      "  return str.indexOf(pattern);\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  uint8_t data8[] = {'W'};
  Dart_Handle ext8 =
      Dart_NewExternalLatin1String(data8, ARRAY_SIZE(data8), data8, NULL);
  EXPECT_VALID(ext8);
  EXPECT(Dart_IsString(ext8));
  EXPECT(Dart_IsExternalString(ext8));

  Dart_Handle dart_args[1];
  dart_args[0] = ext8;
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 1, dart_args);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(6, value);
}

TEST_CASE(StringFromExternalTypedData) {
  const char* kScriptChars =
      "test(external) {\n"
      "  var str1 = new String.fromCharCodes(external);\n"
      "  var str2 = new String.fromCharCodes(new List.from(external));\n"
      "  if (str2 != str1) throw 'FAIL';\n"
      "  return str1;\n"
      "}\n"
      "testView8(external) {\n"
      "  return test(external.buffer.asUint8List());\n"
      "}\n"
      "testView16(external) {\n"
      "  return test(external.buffer.asUint16List());\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  {
    uint8_t data[64];
    for (int i = 0; i < 64; i++) {
      data[i] = i * 4;
    }
    // LATIN-1 in external Uint8List.
    Dart_Handle external =
        Dart_NewExternalTypedData(Dart_TypedData_kUint8, data, 64);
    EXPECT_VALID(external);
    Dart_Handle dart_args[1];
    dart_args[0] = external;
    Dart_Handle result = Dart_Invoke(lib, NewString("test"), 1, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsString(result));

    result = Dart_Invoke(lib, NewString("testView8"), 1, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsString(result));
  }

  {
    uint16_t data[64];
    for (int i = 0; i < 64; i++) {
      data[i] = i * 4;
    }
    // LATIN-1 in external Uint16List.
    Dart_Handle external =
        Dart_NewExternalTypedData(Dart_TypedData_kUint16, data, 64);
    EXPECT_VALID(external);
    Dart_Handle dart_args[1];
    dart_args[0] = external;
    Dart_Handle result = Dart_Invoke(lib, NewString("test"), 1, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsString(result));

    result = Dart_Invoke(lib, NewString("testView16"), 1, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsString(result));
  }

  {
    uint16_t data[64];
    for (int i = 0; i < 64; i++) {
      data[i] = 0x2000 + i * 4;
    }
    // Non-LATIN-1 in external Uint16List.
    Dart_Handle external =
        Dart_NewExternalTypedData(Dart_TypedData_kUint16, data, 64);
    EXPECT_VALID(external);
    Dart_Handle dart_args[1];
    dart_args[0] = external;
    Dart_Handle result = Dart_Invoke(lib, NewString("test"), 1, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsString(result));

    result = Dart_Invoke(lib, NewString("testView16"), 1, dart_args);
    EXPECT_VALID(result);
    EXPECT(Dart_IsString(result));
  }
}

#ifndef PRODUCT

TEST_CASE(Timeline_Dart_TimelineDuration) {
  Isolate* isolate = Isolate::Current();
  // Grab embedder stream.
  TimelineStream* stream = Timeline::GetEmbedderStream();
  // Make sure it is enabled.
  stream->set_enabled(true);
  // Add a duration event.
  Dart_TimelineEvent("testDurationEvent", 0, 1, Dart_Timeline_Event_Duration, 0,
                     NULL, NULL);
  // Check that it is in the output.
  TimelineEventRecorder* recorder = Timeline::recorder();
  Timeline::ReclaimCachedBlocksFromThreads();
  JSONStream js;
  IsolateTimelineEventFilter filter(isolate->main_port());
  recorder->PrintJSON(&js, &filter);
  EXPECT_SUBSTRING("testDurationEvent", js.ToCString());
}

TEST_CASE(Timeline_Dart_TimelineInstant) {
  Isolate* isolate = Isolate::Current();
  // Grab embedder stream.
  TimelineStream* stream = Timeline::GetEmbedderStream();
  // Make sure it is enabled.
  stream->set_enabled(true);
  Dart_TimelineEvent("testInstantEvent", 0, 1, Dart_Timeline_Event_Instant, 0,
                     NULL, NULL);
  // Check that it is in the output.
  TimelineEventRecorder* recorder = Timeline::recorder();
  Timeline::ReclaimCachedBlocksFromThreads();
  JSONStream js;
  IsolateTimelineEventFilter filter(isolate->main_port());
  recorder->PrintJSON(&js, &filter);
  EXPECT_SUBSTRING("testInstantEvent", js.ToCString());
}

TEST_CASE(Timeline_Dart_TimelineAsyncDisabled) {
  // Grab embedder stream.
  TimelineStream* stream = Timeline::GetEmbedderStream();
  // Make sure it is disabled.
  stream->set_enabled(false);
  int64_t async_id = 99;
  Dart_TimelineEvent("testAsyncEvent", 0, async_id,
                     Dart_Timeline_Event_Async_Begin, 0, NULL, NULL);
  // Check that testAsync is not in the output.
  TimelineEventRecorder* recorder = Timeline::recorder();
  Timeline::ReclaimCachedBlocksFromThreads();
  JSONStream js;
  TimelineEventFilter filter;
  recorder->PrintJSON(&js, &filter);
  EXPECT_NOTSUBSTRING("testAsyncEvent", js.ToCString());
}

TEST_CASE(Timeline_Dart_TimelineAsync) {
  Isolate* isolate = Isolate::Current();
  // Grab embedder stream.
  TimelineStream* stream = Timeline::GetEmbedderStream();
  // Make sure it is enabled.
  stream->set_enabled(true);
  int64_t async_id = 99;
  Dart_TimelineEvent("testAsyncEvent", 0, async_id,
                     Dart_Timeline_Event_Async_Begin, 0, NULL, NULL);

  // Check that it is in the output.
  TimelineEventRecorder* recorder = Timeline::recorder();
  Timeline::ReclaimCachedBlocksFromThreads();
  JSONStream js;
  IsolateTimelineEventFilter filter(isolate->main_port());
  recorder->PrintJSON(&js, &filter);
  EXPECT_SUBSTRING("testAsyncEvent", js.ToCString());
}

struct AppendData {
  uint8_t* buffer;
  intptr_t buffer_length;
};

static void AppendStreamConsumer(Dart_StreamConsumer_State state,
                                 const char* stream_name,
                                 const uint8_t* buffer,
                                 intptr_t buffer_length,
                                 void* user_data) {
  if (state == Dart_StreamConsumer_kFinish) {
    return;
  }
  AppendData* data = reinterpret_cast<AppendData*>(user_data);
  if (state == Dart_StreamConsumer_kStart) {
    // Initialize append data.
    data->buffer = NULL;
    data->buffer_length = 0;
    return;
  }
  ASSERT(state == Dart_StreamConsumer_kData);

  // Grow buffer.
  data->buffer = reinterpret_cast<uint8_t*>(
      realloc(data->buffer, data->buffer_length + buffer_length));
  // Copy new data.
  memmove(&data->buffer[data->buffer_length], buffer, buffer_length);
  // Update length.
  data->buffer_length += buffer_length;
}

TEST_CASE(Timeline_Dart_TimelineGetTrace) {
  const char* kScriptChars =
      "foo() => 'a';\n"
      "main() => foo();\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  const char* buffer = NULL;
  intptr_t buffer_length = 0;
  bool success = false;

  // Enable recording of all streams.
  Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_ALL);

  // Invoke main, which will be compiled resulting in a compiler event in
  // the timeline.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Grab the trace.
  AppendData data;
  success = Dart_GlobalTimelineGetTrace(AppendStreamConsumer, &data);
  EXPECT(success);
  buffer = reinterpret_cast<char*>(data.buffer);
  buffer_length = data.buffer_length;
  EXPECT(buffer_length > 0);
  EXPECT(buffer != NULL);

  // Response starts with a '{' character and not a '['.
  EXPECT(buffer[0] == '{');
  // Response ends with a '}' character and not a ']'.
  EXPECT(buffer[buffer_length - 1] == '\0');
  EXPECT(buffer[buffer_length - 2] == '}');

  // Heartbeat test.
  EXPECT_SUBSTRING("\"cat\":\"Compiler\"", buffer);
  EXPECT_SUBSTRING("\"name\":\"CompileFunction\"", buffer);
  EXPECT_SUBSTRING("\"function\":\"::_main\"", buffer);

  // Free buffer allocated by AppendStreamConsumer
  free(data.buffer);
}

TEST_CASE(Timeline_Dart_TimelineGetTraceOnlyDartEvents) {
  const char* kScriptChars =
      "import 'dart:developer';\n"
      ""
      "main() {\n"
      "  Timeline.startSync('DART_NAME');\n"
      "  Timeline.finishSync();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  const char* buffer = NULL;
  intptr_t buffer_length = 0;
  bool success = false;

  // Enable recording of the Dart stream.
  Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_DART);

  // Invoke main, which will add a new timeline event from Dart.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Grab the trace.
  AppendData data;
  data.buffer = NULL;
  data.buffer_length = 0;
  success = Dart_GlobalTimelineGetTrace(AppendStreamConsumer, &data);
  EXPECT(success);
  buffer = reinterpret_cast<char*>(data.buffer);
  buffer_length = data.buffer_length;
  EXPECT(buffer_length > 0);
  EXPECT(buffer != NULL);

  // Response starts with a '{' character and not a '['.
  EXPECT(buffer[0] == '{');
  // Response ends with a '}' character and not a ']'.
  EXPECT(buffer[buffer_length - 1] == '\0');
  EXPECT(buffer[buffer_length - 2] == '}');

  // Heartbeat test.
  EXPECT_SUBSTRING("\"cat\":\"Dart\"", buffer);
  EXPECT_SUBSTRING("\"name\":\"DART_NAME\"", buffer);

  // Free buffer allocated by AppendStreamConsumer
  free(data.buffer);
}

TEST_CASE(Timeline_Dart_TimelineGetTraceWithDartEvents) {
  const char* kScriptChars =
      "import 'dart:developer';\n"
      "\n"
      "main() {\n"
      "  Timeline.startSync('DART_NAME');\n"
      "  Timeline.finishSync();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  const char* buffer = NULL;
  intptr_t buffer_length = 0;
  bool success = false;

  // Enable recording of all streams.
  Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_ALL);

  // Invoke main, which will be compiled resulting in a compiler event in
  // the timeline.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Grab the trace.
  AppendData data;
  success = Dart_GlobalTimelineGetTrace(AppendStreamConsumer, &data);
  EXPECT(success);
  buffer = reinterpret_cast<char*>(data.buffer);
  buffer_length = data.buffer_length;
  EXPECT(buffer_length > 0);
  EXPECT(buffer != NULL);

  // Response starts with a '{' character and not a '['.
  EXPECT(buffer[0] == '{');
  // Response ends with a '}' character and not a ']'.
  EXPECT(buffer[buffer_length - 1] == '\0');
  EXPECT(buffer[buffer_length - 2] == '}');

  // Heartbeat test.
  EXPECT_SUBSTRING("\"cat\":\"Compiler\"", buffer);
  EXPECT_SUBSTRING("\"name\":\"CompileFunction\"", buffer);
  EXPECT_SUBSTRING("\"function\":\"::_main\"", buffer);
  EXPECT_SUBSTRING("\"cat\":\"Dart\"", buffer);
  EXPECT_SUBSTRING("\"name\":\"DART_NAME\"", buffer);

  // Free buffer allocated by AppendStreamConsumer
  free(data.buffer);
}

TEST_CASE(Timeline_Dart_TimelineGetTraceGlobalOverride) {
  const char* kScriptChars =
      "foo() => 'a';\n"
      "main() => foo();\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  const char* buffer = NULL;
  intptr_t buffer_length = 0;
  bool success = false;

  // Enable recording of all streams across the entire vm.
  Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_ALL);

  // Invoke main, which will be compiled resulting in a compiler event in
  // the timeline.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Grab the trace.
  AppendData data;
  success = Dart_GlobalTimelineGetTrace(AppendStreamConsumer, &data);
  EXPECT(success);
  buffer = reinterpret_cast<char*>(data.buffer);
  buffer_length = data.buffer_length;
  EXPECT(buffer_length > 0);
  EXPECT(buffer != NULL);

  // Response starts with a '{' character and not a '['.
  EXPECT(buffer[0] == '{');
  // Response ends with a '}' character and not a ']'.
  EXPECT(buffer[buffer_length - 1] == '\0');
  EXPECT(buffer[buffer_length - 2] == '}');

  // Heartbeat test.
  EXPECT_SUBSTRING("\"cat\":\"Compiler\"", buffer);
  EXPECT_SUBSTRING("\"name\":\"CompileFunction\"", buffer);
  EXPECT_SUBSTRING("\"function\":\"::_main\"", buffer);

  // Free buffer allocated by AppendStreamConsumer
  free(data.buffer);
}

static const char* arg_names[] = {"arg0"};

static const char* arg_values[] = {"value0"};

TEST_CASE(Timeline_Dart_GlobalTimelineGetTrace) {
  const char* kScriptChars =
      "bar() => 'z';\n"
      "foo() => 'a';\n"
      "main() => foo();\n";

  // Enable all streams.
  Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_ALL |
                                        DART_TIMELINE_STREAM_VM);
  Dart_Handle lib;
  {
    // Add something to the VM stream.
    TimelineDurationScope tds(Timeline::GetVMStream(), "TestVMDuration");
    lib = TestCase::LoadTestScript(kScriptChars, NULL);
  }

  {
    // Add something to the embedder stream.
    Dart_TimelineEvent("TRACE_EVENT", Dart_TimelineGetMicros(), 0,
                       Dart_Timeline_Event_Begin, 1, &arg_names[0],
                       &arg_values[0]);
    // Add counter to the embedder stream.
    Dart_TimelineEvent("COUNTER_EVENT", Dart_TimelineGetMicros(), 0,
                       Dart_Timeline_Event_Counter, 0, NULL, NULL);
    Dart_SetThreadName("CUSTOM THREAD NAME");
  }

  // Invoke main, which will be compiled resulting in a compiler event in
  // the timeline.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  const char* buffer = NULL;
  intptr_t buffer_length = 0;
  bool success = false;

  // Grab the global trace.
  AppendData data;
  {
    Thread* T = Thread::Current();
    StackZone zone(T);
    success = Dart_GlobalTimelineGetTrace(AppendStreamConsumer, &data);
    EXPECT(success);
    // The call should do no zone allocation.
    EXPECT(zone.SizeInBytes() == 0);
  }
  buffer = reinterpret_cast<char*>(data.buffer);
  buffer_length = data.buffer_length;
  EXPECT(buffer_length > 0);
  EXPECT(buffer != NULL);

  // Response starts with a '{' character and not a '['.
  EXPECT(buffer[0] == '{');
  // Response ends with a '}' character and not a ']'.
  EXPECT(buffer[buffer_length - 1] == '\0');
  EXPECT(buffer[buffer_length - 2] == '}');

  // Heartbeat test.
  EXPECT_SUBSTRING("\"name\":\"TestVMDuration\"", buffer);
  EXPECT_SUBSTRING("\"cat\":\"Compiler\"", buffer);
  EXPECT_SUBSTRING("\"name\":\"CompileFunction\"", buffer);
  EXPECT_SUBSTRING("\"function\":\"::_main\"", buffer);
  EXPECT_NOTSUBSTRING("\"function\":\"::_bar\"", buffer);
  EXPECT_SUBSTRING("TRACE_EVENT", buffer);
  EXPECT_SUBSTRING("arg0", buffer);
  EXPECT_SUBSTRING("value0", buffer);
  EXPECT_SUBSTRING("COUNTER_EVENT", buffer);
  EXPECT_SUBSTRING("CUSTOM THREAD NAME", buffer);

  // Free buffer allocated by AppendStreamConsumer
  free(data.buffer);
  data.buffer = NULL;
  data.buffer_length = 0;

  // Retrieving the global trace resulted in all open blocks being reclaimed.
  // Add some new events and verify that both sets of events are present
  // in the resulting trace.
  {
    // Add something to the VM stream.
    TimelineDurationScope tds(Timeline::GetVMStream(), "TestVMDuration2");
    // Invoke bar, which will be compiled resulting in a compiler event in
    // the timeline.
    result = Dart_Invoke(lib, NewString("bar"), 0, NULL);
  }

  // Grab the global trace.
  {
    Thread* T = Thread::Current();
    StackZone zone(T);
    success = Dart_GlobalTimelineGetTrace(AppendStreamConsumer, &data);
    EXPECT(success);
    EXPECT(zone.SizeInBytes() == 0);
  }
  buffer = reinterpret_cast<char*>(data.buffer);
  buffer_length = data.buffer_length;
  EXPECT(buffer_length > 0);
  EXPECT(buffer != NULL);
  // Response starts with a '{' character and not a '['.
  EXPECT(buffer[0] == '{');
  // Response ends with a '}' character and not a ']'.
  EXPECT(buffer[buffer_length - 1] == '\0');
  EXPECT(buffer[buffer_length - 2] == '}');

  // Heartbeat test for old events.
  EXPECT_SUBSTRING("\"name\":\"TestVMDuration\"", buffer);
  EXPECT_SUBSTRING("\"cat\":\"Compiler\"", buffer);
  EXPECT_SUBSTRING("\"name\":\"CompileFunction\"", buffer);
  EXPECT_SUBSTRING("\"function\":\"::_main\"", buffer);

  // Heartbeat test for new events.
  EXPECT_SUBSTRING("\"name\":\"TestVMDuration2\"", buffer);
  EXPECT_SUBSTRING("\"function\":\"::_bar\"", buffer);

  // Free buffer allocated by AppendStreamConsumer
  free(data.buffer);
}

class GlobalTimelineThreadData {
 public:
  GlobalTimelineThreadData()
      : monitor_(new Monitor()), data_(new AppendData()), running_(true) {}

  ~GlobalTimelineThreadData() {
    delete monitor_;
    monitor_ = NULL;
    free(data_->buffer);
    data_->buffer = NULL;
    data_->buffer_length = 0;
    delete data_;
    data_ = NULL;
  }

  Monitor* monitor() const { return monitor_; }
  bool running() const { return running_; }
  AppendData* data() const { return data_; }
  uint8_t* buffer() const { return data_->buffer; }
  intptr_t buffer_length() const { return data_->buffer_length; }

  void set_running(bool running) { running_ = running; }

 private:
  Monitor* monitor_;
  AppendData* data_;
  bool running_;
};

static void GlobalTimelineThread(uword parameter) {
  GlobalTimelineThreadData* data =
      reinterpret_cast<GlobalTimelineThreadData*>(parameter);
  Thread* T = Thread::Current();
  // When there is no current Thread, then Zone allocation will fail.
  EXPECT(T == NULL);
  {
    MonitorLocker ml(data->monitor());
    bool success =
        Dart_GlobalTimelineGetTrace(AppendStreamConsumer, data->data());
    EXPECT(success);
    data->set_running(false);
    ml.Notify();
  }
}

// This test is the same as the one above except that the calls to
// Dart_GlobalTimelineGetTrace are made from a fresh thread. This ensures that
// we can call the function from a thread for which we have not set up a
// Thread object.
TEST_CASE(Timeline_Dart_GlobalTimelineGetTrace_Threaded) {
  const char* kScriptChars =
      "bar() => 'z';\n"
      "foo() => 'a';\n"
      "main() => foo();\n";

  // Enable all streams.
  Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_ALL |
                                        DART_TIMELINE_STREAM_VM);
  Dart_Handle lib;
  {
    // Add something to the VM stream.
    TimelineDurationScope tds(Timeline::GetVMStream(), "TestVMDuration");
    lib = TestCase::LoadTestScript(kScriptChars, NULL);
  }

  // Invoke main, which will be compiled resulting in a compiler event in
  // the timeline.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  const char* buffer = NULL;
  intptr_t buffer_length = 0;

  // Run Dart_GlobalTimelineGetTrace on a fresh thread.
  GlobalTimelineThreadData data;
  int err = OSThread::Start("Timeline test thread", GlobalTimelineThread,
                            reinterpret_cast<uword>(&data));
  EXPECT(err == 0);
  {
    MonitorLocker ml(data.monitor());
    while (data.running()) {
      ml.Wait();
    }
    buffer = reinterpret_cast<char*>(data.buffer());
    buffer_length = data.buffer_length();
  }
  EXPECT(buffer_length > 0);
  EXPECT(buffer != NULL);

  // Response starts with a '{' character and not a '['.
  EXPECT(buffer[0] == '{');
  // Response ends with a '}' character and not a ']'.
  EXPECT(buffer[buffer_length - 1] == '\0');
  EXPECT(buffer[buffer_length - 2] == '}');

  // Heartbeat test.
  EXPECT_SUBSTRING("\"name\":\"TestVMDuration\"", buffer);
  EXPECT_SUBSTRING("\"cat\":\"Compiler\"", buffer);
  EXPECT_SUBSTRING("\"name\":\"CompileFunction\"", buffer);
  EXPECT_SUBSTRING("\"function\":\"::_main\"", buffer);
  EXPECT_NOTSUBSTRING("\"function\":\"::_bar\"", buffer);

  // Retrieving the global trace resulted in all open blocks being reclaimed.
  // Add some new events and verify that both sets of events are present
  // in the resulting trace.
  {
    // Add something to the VM stream.
    TimelineDurationScope tds(Timeline::GetVMStream(), "TestVMDuration2");
    // Invoke bar, which will be compiled resulting in a compiler event in
    // the timeline.
    result = Dart_Invoke(lib, NewString("bar"), 0, NULL);
  }

  // Grab the global trace.
  GlobalTimelineThreadData data2;
  err = OSThread::Start("Timeline test thread", GlobalTimelineThread,
                        reinterpret_cast<uword>(&data2));
  EXPECT(err == 0);
  {
    MonitorLocker ml(data2.monitor());
    while (data2.running()) {
      ml.Wait();
    }
    buffer = reinterpret_cast<char*>(data2.buffer());
    buffer_length = data2.buffer_length();
  }

  EXPECT(buffer_length > 0);
  EXPECT(buffer != NULL);
  // Response starts with a '{' character and not a '['.
  EXPECT(buffer[0] == '{');
  // Response ends with a '}' character and not a ']'.
  EXPECT(buffer[buffer_length - 1] == '\0');
  EXPECT(buffer[buffer_length - 2] == '}');

  // Heartbeat test for old events.
  EXPECT_SUBSTRING("\"name\":\"TestVMDuration\"", buffer);
  EXPECT_SUBSTRING("\"cat\":\"Compiler\"", buffer);
  EXPECT_SUBSTRING("\"name\":\"CompileFunction\"", buffer);
  EXPECT_SUBSTRING("\"function\":\"::_main\"", buffer);

  // Heartbeat test for new events.
  EXPECT_SUBSTRING("\"name\":\"TestVMDuration2\"", buffer);
  EXPECT_SUBSTRING("\"function\":\"::_bar\"", buffer);
}

static bool start_called = false;
static bool stop_called = false;

static void StartRecording() {
  start_called = true;
}

static void StopRecording() {
  stop_called = true;
}

TEST_CASE(Timeline_Dart_EmbedderTimelineStartStopRecording) {
  Dart_SetEmbedderTimelineCallbacks(StartRecording, StopRecording);

  EXPECT(!start_called);
  EXPECT(!stop_called);
  Timeline::SetStreamEmbedderEnabled(true);
  EXPECT(start_called);
  EXPECT(!stop_called);

  start_called = false;
  stop_called = false;
  EXPECT(!start_called);
  EXPECT(!stop_called);
  Timeline::SetStreamEmbedderEnabled(false);
  EXPECT(!start_called);
  EXPECT(stop_called);
}

TEST_CASE(Dart_LoadLibraryPatch_1) {
  const char* kScriptChars1 =
      "class A {\n"
      "  int foo() { return 10; }\n"
      "  external int zoo();\n"
      "  external static int moo();\n"
      "}\n"
      "main() { new A().foo(); }\n"
      "foozoo() { new A().zoo(); }\n"
      "foomoo() { A.moo(); }\n";

  const char* kScriptChars2 =
      "@patch class A {\n"
      "  @patch int zoo() { return 1; }\n"
      "  @patch static int moo() { return 1; }\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars1, NULL);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  Dart_Handle url = NewString("test-lib-patch");
  Dart_Handle source = NewString(kScriptChars2);
  result = Dart_LibraryLoadPatch(lib, url, source);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("foozoo"), 0, NULL);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("foomoo"), 0, NULL);
  EXPECT_VALID(result);
}

TEST_CASE(Dart_LoadLibraryPatch_Error1) {
  const char* kScriptChars1 =
      "class A {\n"
      "  int foo() { return 10; }\n"
      "  external int zoo();\n"
      "}\n"
      "main() { new A().foo(); }\n"
      "foozoo() { new A().zoo(); }\n";

  const char* kScriptChars2 =
      "@patch class A {\n"
      "  @patch int zoo() { return 1; }\n"
      "  @patch int fld1;\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars1, NULL);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  Dart_Handle url = NewString("test-lib-patch");
  Dart_Handle source = NewString(kScriptChars2);
  // We don't expect to be able to patch in this case as new fields
  // are being added.
  result = Dart_LibraryLoadPatch(lib, url, source);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("foozoo"), 0, NULL);
  EXPECT(Dart_IsError(result));
}

TEST_CASE(Dart_LoadLibraryPatch_Error2) {
  const char* kScriptChars1 =
      "class A {\n"
      "  int foo() { return 10; }\n"
      "  int zoo() { return 20; }\n"
      "}\n"
      "main() { new A().foo(); }\n"
      "foozoo() { new A().zoo(); }\n";

  const char* kScriptChars2 =
      "@patch class A {\n"
      "  @patch int zoo() { return 1; }\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars1, NULL);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  Dart_Handle url = NewString("test-lib-patch");
  Dart_Handle source = NewString(kScriptChars2);
  // We don't expect to be able to patch in this case as a non external
  // method is being patched.
  result = Dart_LibraryLoadPatch(lib, url, source);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("foozoo"), 0, NULL);
  EXPECT(Dart_IsError(result));
  OS::Print("Patched class executed\n");
}

TEST_CASE(Dart_LoadLibraryPatch_Error3) {
  const char* kScriptChars1 =
      "class A {\n"
      "  int foo() { return 10; }\n"
      "  external int zoo();\n"
      "}\n"
      "main() { new A().foo(); }\n"
      "foozoo() { new A().zoo(); }\n";

  const char* kScriptChars2 =
      "@patch class A {\n"
      "  @patch int zoo() { return 1; }\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars1, NULL);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  // We invoke the foozoo method to ensure that code for 'zoo' is generated
  // which throws NoSuchMethod.
  result = Dart_Invoke(lib, NewString("foozoo"), 0, NULL);
  EXPECT(Dart_IsError(result));
  Dart_Handle url = NewString("test-lib-patch");
  Dart_Handle source = NewString(kScriptChars2);
  // We don't expect to be able to patch in this case as the function being
  // patched has already executed.
  result = Dart_LibraryLoadPatch(lib, url, source);
  EXPECT_VALID(result);
  result = Dart_FinalizeLoading(false);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("foozoo"), 0, NULL);
  EXPECT(Dart_IsError(result));
}

#endif  // !PRODUCT

}  // namespace dart
