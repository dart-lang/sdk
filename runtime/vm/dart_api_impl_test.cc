// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/class_finalizer.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/thread.h"
#include "vm/unit_test.h"
#include "vm/verifier.h"

namespace dart {

// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

TEST_CASE(ErrorHandleBasics) {
  const char* kScriptChars =
      "void testMain() {\n"
      "  throw new Exception(\"bad news\");\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  Dart_Handle instance = Dart_True();
  Dart_Handle error = Api::NewError("myerror");
  Dart_Handle exception = Dart_Invoke(lib,
                                      Dart_NewString("testMain"),
                                      0,
                                      NULL);

  EXPECT(!Dart_IsError(instance));
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
      " 0. Function: '::testMain' url: 'dart:test-lib' line:2 col:3",
      Dart_GetError(exception));

  EXPECT(Dart_IsError(Dart_ErrorGetException(instance)));
  EXPECT(Dart_IsError(Dart_ErrorGetException(error)));
  EXPECT_VALID(Dart_ErrorGetException(exception));

  EXPECT(Dart_IsError(Dart_ErrorGetStacktrace(instance)));
  EXPECT(Dart_IsError(Dart_ErrorGetStacktrace(error)));
  EXPECT_VALID(Dart_ErrorGetStacktrace(exception));
}


TEST_CASE(ErrorHandleTypes) {
  Isolate* isolate = Isolate::Current();
  const String& compile_message = String::Handle(String::New("CompileError"));
  const String& fatal_message = String::Handle(String::New("FatalError"));

  Dart_Handle not_error = Dart_NewString("NotError");
  Dart_Handle api_error = Dart_NewApiError("Api%s", "Error");
  Dart_Handle exception_error =
      Dart_NewUnhandledExceptionError(Dart_NewString("ExceptionError"));
  Dart_Handle compile_error =
      Api::NewHandle(isolate, LanguageError::New(compile_message));
  Dart_Handle fatal_error =
      Api::NewHandle(isolate, UnwindError::New(fatal_message));

  EXPECT(!Dart_IsError(not_error));
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


void PropagateErrorNative(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle closure = Dart_GetNativeArgument(args, 0);
  EXPECT(Dart_IsClosure(closure));
  Dart_Handle result = Dart_InvokeClosure(closure, 0, NULL);
  EXPECT(Dart_IsError(result));
  result = Dart_PropagateError(result);
  EXPECT_VALID(result);  // We do not expect to reach here.
  UNREACHABLE();
}


static Dart_NativeFunction PropagateError_native_lookup(
    Dart_Handle name, int argument_count) {
  return reinterpret_cast<Dart_NativeFunction>(&PropagateErrorNative);
}


TEST_CASE(Dart_PropagateError) {
  const char* kScriptChars =
      "void raiseCompileError() {\n"
      "  return badIdent;\n"
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
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, &PropagateError_native_lookup);
  Dart_Handle result;

  result = Dart_Invoke(lib, Dart_NewString("Func1"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(!Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("badIdent", Dart_GetError(result));

  result = Dart_Invoke(lib, Dart_NewString("Func2"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("myException", Dart_GetError(result));
}

#endif


TEST_CASE(Dart_Error) {
  Dart_Handle error = Dart_Error("An %s", "error");
  EXPECT(Dart_IsError(error));
  EXPECT_STREQ("An error", Dart_GetError(error));
}


TEST_CASE(Null) {
  Dart_Handle null = Dart_Null();
  EXPECT_VALID(null);
  EXPECT(Dart_IsNull(null));

  Dart_Handle str = Dart_NewString("test");
  EXPECT_VALID(str);
  EXPECT(!Dart_IsNull(str));
}


TEST_CASE(IdentityEquals) {
  Dart_Handle five = Dart_NewString("5");
  Dart_Handle five_again = Dart_NewString("5");
  Dart_Handle seven = Dart_NewString("7");

  // Same objects.
  EXPECT(Dart_IdentityEquals(five, five));

  // Equal objects.
  EXPECT(!Dart_IdentityEquals(five, five_again));

  // Different objects.
  EXPECT(!Dart_IdentityEquals(five, seven));

  // Non-instance objects.
  {
    Isolate* isolate = Isolate::Current();
    DARTSCOPE_NOCHECKS(isolate);
    Dart_Handle class1 = Api::NewHandle(isolate, Object::null_class());
    Dart_Handle class2 = Api::NewHandle(isolate, Object::class_class());

    EXPECT(Dart_IdentityEquals(class1, class1));

    EXPECT(!Dart_IdentityEquals(class1, class2));
  }
}


// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

TEST_CASE(ObjectEquals) {
  bool equal = false;
  Dart_Handle five = Dart_NewString("5");
  Dart_Handle five_again = Dart_NewString("5");
  Dart_Handle seven = Dart_NewString("7");

  // Same objects.
  EXPECT_VALID(Dart_ObjectEquals(five, five, &equal));
  EXPECT(equal);

  // Equal objects.
  EXPECT_VALID(Dart_ObjectEquals(five, five_again, &equal));
  EXPECT(equal);

  // Different objects.
  EXPECT_VALID(Dart_ObjectEquals(five, seven, &equal));
  EXPECT(!equal);
}

#endif


TEST_CASE(InstanceValues) {
  EXPECT(Dart_IsInstance(Dart_NewString("test")));
  EXPECT(Dart_IsInstance(Dart_True()));

  // By convention, our Is*() functions exclude null.
  EXPECT(!Dart_IsInstance(Dart_Null()));
}


TEST_CASE(InstanceGetClass) {
  // Get the handle from a valid instance handle.
  Dart_Handle instance = Dart_True();
  Dart_Handle cls = Dart_InstanceGetClass(instance);
  EXPECT_VALID(cls);
  EXPECT(Dart_IsClass(cls));
  Dart_Handle cls_name = Dart_ClassName(cls);
  EXPECT_VALID(cls_name);
  const char* cls_name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(cls_name, &cls_name_cstr));
  EXPECT_STREQ("Bool", cls_name_cstr);

  // Errors propagate.
  Dart_Handle error = Dart_NewApiError("MyError");
  Dart_Handle error_cls = Dart_InstanceGetClass(error);
  EXPECT_ERROR(error_cls, "MyError");

  // Get the handle from a non-instance handle
  ASSERT(Dart_IsClass(cls));
  Dart_Handle cls_cls = Dart_InstanceGetClass(cls);
  EXPECT_ERROR(cls_cls,
               "Dart_InstanceGetClass expects argument 'instance' to be of "
               "type Instance.");
}


TEST_CASE(BooleanValues) {
  Dart_Handle str = Dart_NewString("test");
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


// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

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
  result = Dart_Invoke(lib, Dart_NewString("getInt"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsNumber(result));

  // Check double case.
  result = Dart_Invoke(lib, Dart_NewString("getDouble"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsNumber(result));

  // Check bool case.
  result = Dart_Invoke(lib, Dart_NewString("getBool"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNumber(result));

  // Check null case.
  result = Dart_Invoke(lib, Dart_NewString("getNull"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(!Dart_IsNumber(result));
}

#endif


TEST_CASE(IntegerValues) {
  const int64_t kIntegerVal1 = 100;
  const int64_t kIntegerVal2 = 0xffffffff;
  const char* kIntegerVal3 = "0x123456789123456789123456789";

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

  Dart_Handle min = Dart_NewInteger(kMaxInt64);
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
  Dart_Handle max = Dart_NewIntegerFromHexCString("0xFFFFFFFFFFFFFFFF");
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
  const int kArrayLength = 10;
  Dart_Handle str = Dart_NewString("test");
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
  uint8_t data8[] = { 'o', 'n', 'e', 0xFF };

  Dart_Handle str8 = Dart_NewString8(data8, ARRAY_SIZE(data8));
  EXPECT_VALID(str8);
  EXPECT(Dart_IsString(str8));
  EXPECT(Dart_IsString8(str8));
  EXPECT(Dart_IsString16(str8));
  EXPECT(!Dart_IsExternalString(str8));

  Dart_Handle ext8 = Dart_NewExternalString8(data8, ARRAY_SIZE(data8),
                                             NULL, NULL);
  EXPECT_VALID(ext8);
  EXPECT(Dart_IsString(ext8));
  EXPECT(Dart_IsString8(ext8));
  EXPECT(Dart_IsString16(ext8));
  EXPECT(Dart_IsExternalString(ext8));

  uint16_t data16[] = { 't', 'w', 'o', 0xFFFF };

  Dart_Handle str16 = Dart_NewString16(data16, ARRAY_SIZE(data16));
  EXPECT_VALID(str16);
  EXPECT(Dart_IsString(str16));
  EXPECT(!Dart_IsString8(str16));
  EXPECT(Dart_IsString16(str16));
  EXPECT(!Dart_IsExternalString(str16));

  Dart_Handle ext16 = Dart_NewExternalString16(data16, ARRAY_SIZE(data16),
                                               NULL, NULL);
  EXPECT_VALID(ext16);
  EXPECT(Dart_IsString(ext16));
  EXPECT(!Dart_IsString8(ext16));
  EXPECT(Dart_IsString16(ext16));
  EXPECT(Dart_IsExternalString(ext16));

  uint32_t data32[] = { 'f', 'o', 'u', 'r', 0x10FFFF };

  Dart_Handle str32 = Dart_NewString32(data32, ARRAY_SIZE(data32));
  EXPECT_VALID(str32);
  EXPECT(Dart_IsString(str32));
  EXPECT(!Dart_IsString8(str32));
  EXPECT(!Dart_IsString16(str32));
  EXPECT(!Dart_IsExternalString(str32));

  Dart_Handle ext32 = Dart_NewExternalString32(data32, ARRAY_SIZE(data32),
                                               NULL, NULL);
  EXPECT_VALID(ext32);
  EXPECT(Dart_IsString(ext32));
  EXPECT(!Dart_IsString8(ext32));
  EXPECT(!Dart_IsString16(ext32));
  EXPECT(Dart_IsExternalString(ext32));
}


TEST_CASE(ExternalStringGetPeer) {
  Dart_Handle result;

  uint8_t data8[] = { 'o', 'n', 'e', 0xFF };
  int peer_data = 123;
  void* peer = NULL;

  // Success.
  Dart_Handle ext8 = Dart_NewExternalString8(data8, ARRAY_SIZE(data8),
                                             &peer_data, NULL);
  EXPECT_VALID(ext8);

  result = Dart_ExternalStringGetPeer(ext8, &peer);
  EXPECT_VALID(result);
  EXPECT_EQ(&peer_data, peer);

  // NULL peer.
  result = Dart_ExternalStringGetPeer(ext8, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_ExternalStringGetPeer expects argument 'peer' to be "
               "non-null.", Dart_GetError(result));

  // String is not external.
  peer = NULL;
  Dart_Handle str8 = Dart_NewString8(data8, ARRAY_SIZE(data8));
  EXPECT_VALID(str8);
  result = Dart_ExternalStringGetPeer(str8, &peer);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_ExternalStringGetPeer expects argument 'object' to be "
               "an external String.", Dart_GetError(result));
  EXPECT(peer == NULL);

  // Not a String.
  peer = NULL;
  result = Dart_ExternalStringGetPeer(Dart_True(), &peer);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_ExternalStringGetPeer expects argument 'object' to be "
               "of type String.", Dart_GetError(result));
  EXPECT(peer == NULL);
}


// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

static void ExternalStringCallbackFinalizer(void* peer) {
  *static_cast<int*>(peer) *= 2;
}


TEST_CASE(ExternalStringCallback) {
  int peer8 = 40;
  int peer16 = 41;
  int peer32 = 42;

  {
    Dart_EnterScope();

    uint8_t data8[] = { 'h', 'e', 'l', 'l', 'o' };
    Dart_Handle obj8 = Dart_NewExternalString8(
        data8,
        ARRAY_SIZE(data8),
        &peer8,
        ExternalStringCallbackFinalizer);
    EXPECT_VALID(obj8);
    void* api_peer8 = NULL;
    EXPECT_VALID(Dart_ExternalStringGetPeer(obj8, &api_peer8));
    EXPECT_EQ(api_peer8, &peer8);

    uint16_t data16[] = { 'h', 'e', 'l', 'l', 'o' };
    Dart_Handle obj16 = Dart_NewExternalString16(
        data16,
        ARRAY_SIZE(data16),
        &peer16,
        ExternalStringCallbackFinalizer);
    EXPECT_VALID(obj16);
    void* api_peer16 = NULL;
    EXPECT_VALID(Dart_ExternalStringGetPeer(obj16, &api_peer16));
    EXPECT_EQ(api_peer16, &peer16);

    uint32_t data32[] = { 'h', 'e', 'l', 'l', 'o' };
    Dart_Handle obj32 = Dart_NewExternalString32(
        data32,
        ARRAY_SIZE(data32),
        &peer32,
        ExternalStringCallbackFinalizer);
    EXPECT_VALID(obj32);
    void* api_peer32 = NULL;
    EXPECT_VALID(Dart_ExternalStringGetPeer(obj32, &api_peer32));
    EXPECT_EQ(api_peer32, &peer32);

    Dart_ExitScope();
  }

  EXPECT_EQ(40, peer8);
  EXPECT_EQ(41, peer16);
  EXPECT_EQ(42, peer32);
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(40, peer8);
  EXPECT_EQ(41, peer16);
  EXPECT_EQ(42, peer32);
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
  EXPECT_EQ(80, peer8);
  EXPECT_EQ(82, peer16);
  EXPECT_EQ(84, peer32);
}


TEST_CASE(ListAccess) {
  const char* kScriptChars =
      "List testMain() {"
      "  List a = new List();"
      "  a.add(10);"
      "  a.add(20);"
      "  a.add(30);"
      "  return a;"
      "}";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns an object of type List.
  result = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);

  // First ensure that the returned object is an array.
  Dart_Handle ListAccessTestObj = result;

  EXPECT(Dart_IsList(ListAccessTestObj));

  // Get length of array object.
  intptr_t len = 0;
  result = Dart_ListLength(ListAccessTestObj, &len);
  EXPECT_VALID(result);
  EXPECT_EQ(3, len);

  // Access elements in the array.
  int64_t value;

  result = Dart_ListGetAt(ListAccessTestObj, 0);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(10, value);

  result = Dart_ListGetAt(ListAccessTestObj, 1);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(20, value);

  result = Dart_ListGetAt(ListAccessTestObj, 2);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(30, value);

  // Set some elements in the array.
  result = Dart_ListSetAt(ListAccessTestObj, 0, Dart_NewInteger(0));
  EXPECT_VALID(result);
  result = Dart_ListSetAt(ListAccessTestObj, 1, Dart_NewInteger(1));
  EXPECT_VALID(result);
  result = Dart_ListSetAt(ListAccessTestObj, 2, Dart_NewInteger(2));
  EXPECT_VALID(result);

  // Get length of array object.
  result = Dart_ListLength(ListAccessTestObj, &len);
  EXPECT_VALID(result);
  EXPECT_EQ(3, len);

  // Now try and access these elements in the array.
  result = Dart_ListGetAt(ListAccessTestObj, 0);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(0, value);

  result = Dart_ListGetAt(ListAccessTestObj, 1);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(1, value);

  result = Dart_ListGetAt(ListAccessTestObj, 2);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(2, value);

  uint8_t native_array[3];
  result = Dart_ListGetAsBytes(ListAccessTestObj, 0, native_array, 3);
  EXPECT_VALID(result);
  EXPECT_EQ(0, native_array[0]);
  EXPECT_EQ(1, native_array[1]);
  EXPECT_EQ(2, native_array[2]);

  native_array[0] = 10;
  native_array[1] = 20;
  native_array[2] = 30;
  result = Dart_ListSetAsBytes(ListAccessTestObj, 0, native_array, 3);
  EXPECT_VALID(result);
  result = Dart_ListGetAsBytes(ListAccessTestObj, 0, native_array, 3);
  EXPECT_VALID(result);
  EXPECT_EQ(10, native_array[0]);
  EXPECT_EQ(20, native_array[1]);
  EXPECT_EQ(30, native_array[2]);
  result = Dart_ListGetAt(ListAccessTestObj, 2);
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(30, value);

  // Check if we get an exception when accessing beyond limit.
  result = Dart_ListGetAt(ListAccessTestObj, 4);
  EXPECT(Dart_IsError(result));
}


TEST_CASE(ByteArrayAccess) {
  Dart_Handle byte_array1 = Dart_NewByteArray(10);
  EXPECT_VALID(byte_array1);
  EXPECT(Dart_IsByteArray(byte_array1));
  EXPECT(Dart_IsList(byte_array1));

  intptr_t length = 0;
  Dart_Handle result = Dart_ListLength(byte_array1, &length);
  EXPECT_VALID(result);
  EXPECT_EQ(10, length);

  result = Dart_ListSetAt(byte_array1, -1, Dart_NewInteger(1));
  EXPECT(Dart_IsError(result));
  result = Dart_ByteArraySetUint8At(byte_array1, -1, 1);
  EXPECT(Dart_IsError(result));

  result = Dart_ListSetAt(byte_array1, 10, Dart_NewInteger(1));
  EXPECT(Dart_IsError(result));
  result = Dart_ByteArraySetUint8At(byte_array1, 10, 1);
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
    // Get through the ByteArray API.
    uint8_t uint8_t_value = 0xFF;
    EXPECT_VALID(Dart_ByteArrayGetUint8At(byte_array1, i, &uint8_t_value));
    EXPECT_EQ(i + 1, uint8_t_value);
  }

  // Set through the ByteArray API.
  for (intptr_t i = 0; i < 10; ++i) {
    EXPECT_VALID(Dart_ByteArraySetUint8At(byte_array1, i, i + 2));
  }
  for (intptr_t i = 0; i < 10; ++i) {
    // Get through the List API.
    Dart_Handle integer_obj = Dart_ListGetAt(byte_array1, i);
    EXPECT_VALID(integer_obj);
    int64_t int64_t_value = -1;
    EXPECT_VALID(Dart_IntegerToInt64(integer_obj, &int64_t_value));
    EXPECT_EQ(i + 2, int64_t_value);
    // Get through the ByteArray API.
    uint8_t uint8_t_value = 0xFF;
    EXPECT_VALID(Dart_ByteArrayGetUint8At(byte_array1, i, &uint8_t_value));
    EXPECT_EQ(i + 2, uint8_t_value);
  }

  Dart_Handle byte_array2 = Dart_NewByteArray(10);
  bool is_equal = false;
  Dart_ObjectEquals(byte_array1, byte_array2, &is_equal);
  EXPECT(!is_equal);

  // Set through the List API.
  for (intptr_t i = 0; i < 10; ++i) {
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
    // Get through the ByteArray API.
    uint8_t v1 = 0xFF;
    uint8_t v2 = 0XFF;
    EXPECT_VALID(Dart_ByteArrayGetUint8At(byte_array1, i, &v1));
    EXPECT_VALID(Dart_ByteArrayGetUint8At(byte_array2, i, &v2));
    EXPECT_NE(v1, 0xFF);
    EXPECT_NE(v2, 0xFF);
    EXPECT_EQ(v1, v2);
  }

  byte_array2 = Dart_NewByteArray(10);
  is_equal = false;
  Dart_ObjectEquals(byte_array1, byte_array2, &is_equal);
  EXPECT(!is_equal);

  // Set through the ByteArray API.
  for (intptr_t i = 0; i < 10; ++i) {
    result = Dart_ByteArraySetUint8At(byte_array2, i, i + 2);
    EXPECT_VALID(result);
  }
  for (intptr_t i = 0; i < 10; ++i) {
    // Get through the List API.
    Dart_Handle e1 = Dart_ListGetAt(byte_array1, i);
    Dart_Handle e2 = Dart_ListGetAt(byte_array2, i);
    is_equal = false;
    Dart_ObjectEquals(e1, e2, &is_equal);
    EXPECT(is_equal);
    // Get through the ByteArray API.
    uint8_t v1 = 0xFF;
    uint8_t v2 = 0XFF;
    EXPECT_VALID(Dart_ByteArrayGetUint8At(byte_array1, i, &v1));
    EXPECT_VALID(Dart_ByteArrayGetUint8At(byte_array2, i, &v2));
    EXPECT_NE(v1, 0xFF);
    EXPECT_NE(v2, 0xFF);
    EXPECT_EQ(v1, v2);
  }

  uint8_t data[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
  result = Dart_ListSetAsBytes(byte_array1, 0, data, 10);
  EXPECT_VALID(result);
  for (intptr_t i = 0; i < 10; ++i) {
    Dart_Handle integer_obj = Dart_ListGetAt(byte_array1, i);
    EXPECT_VALID(integer_obj);
    int64_t int64_t_value = -1;
    EXPECT_VALID(Dart_IntegerToInt64(integer_obj, &int64_t_value));
    EXPECT_EQ(i, int64_t_value);
    uint8_t uint8_t_value = 0xFF;
    EXPECT_VALID(Dart_ByteArrayGetUint8At(byte_array1, i, &uint8_t_value));
    EXPECT_EQ(i, uint8_t_value);
  }

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
    uint8_t uint8_t_value = 0xFF;
    EXPECT_VALID(Dart_ByteArrayGetUint8At(byte_array1, i, &uint8_t_value));
    EXPECT_EQ(10 - i, uint8_t_value);
  }

  for (intptr_t i = 0; i < 10; ++i) {
    EXPECT_VALID(Dart_ByteArraySetUint8At(byte_array1, i, 10 + i));
  }
  Dart_ListGetAsBytes(byte_array1, 0, data, 10);
  for (intptr_t i = 0; i < 10; ++i) {
    Dart_Handle integer_obj = Dart_ListGetAt(byte_array1, i);
    EXPECT_VALID(integer_obj);
    int64_t int64_t_value = -1;
    EXPECT_VALID(Dart_IntegerToInt64(integer_obj, &int64_t_value));
    EXPECT_EQ(10 + i, int64_t_value);
    uint8_t uint8_t_value = 0xFF;
    EXPECT_VALID(Dart_ByteArrayGetUint8At(byte_array1, i, &uint8_t_value));
    EXPECT_EQ(10 + i, uint8_t_value);
  }
}


TEST_CASE(ByteArrayAlignedMultiByteAccess) {
  intptr_t length = 16;
  Dart_Handle byte_array = Dart_NewByteArray(length);
  intptr_t api_length = 0;
  EXPECT_VALID(Dart_ListLength(byte_array, &api_length));
  EXPECT_EQ(length, api_length);

  // 4-byte aligned sets.

  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 0, FLT_MIN));
  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 4, FLT_MAX));

  float float_value = 0.0f;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 0, &float_value));
  EXPECT_EQ(FLT_MIN, float_value);

  float_value = 0.0f;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 4, &float_value));
  EXPECT_EQ(FLT_MAX, float_value);

  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 0, 0.0f));
  float_value = FLT_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 0, &float_value));
  EXPECT_EQ(0.0f, float_value);

  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 4, 1.0f));
  float_value = FLT_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 4, &float_value));
  EXPECT_EQ(1.0f, float_value);

  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 0, -1.0f));
  float_value = FLT_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 0, &float_value));
  EXPECT_EQ(-1.0f, float_value);

  // 8-byte aligned sets.

  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 0, DBL_MIN));
  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 8, DBL_MAX));

  double double_value = 0.0;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 0, &double_value));
  EXPECT_EQ(DBL_MIN, double_value);

  double_value = 0.0;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 8, &double_value));
  EXPECT_EQ(DBL_MAX, double_value);

  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 0, 0.0));
  double_value = DBL_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 0, &double_value));
  EXPECT_EQ(0.0, double_value);

  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 8, 1.0));
  double_value = DBL_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 8, &double_value));
  EXPECT_EQ(1.0, double_value);
}


TEST_CASE(ByteArrayMisalignedMultiByteAccess) {
  intptr_t length = 17;
  Dart_Handle byte_array = Dart_NewByteArray(length);
  intptr_t api_length = 0;
  EXPECT_VALID(Dart_ListLength(byte_array, &api_length));
  EXPECT_EQ(length, api_length);

  // 4-byte misaligned sets.

  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 1, FLT_MIN));
  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 5, FLT_MAX));

  float float_value = 0.0f;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 1, &float_value));
  EXPECT_EQ(FLT_MIN, float_value);

  float_value = 0.0f;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 5, &float_value));
  EXPECT_EQ(FLT_MAX, float_value);

  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 1, 0.0f));
  float_value = FLT_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 1, &float_value));
  EXPECT_EQ(0.0f, float_value);

  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 5, -0.0f));
  float_value = FLT_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 5, &float_value));
  EXPECT_EQ(-0.0f, float_value);

  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 5, 1.0f));
  float_value = FLT_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 5, &float_value));
  EXPECT_EQ(1.0f, float_value);

  EXPECT_VALID(Dart_ByteArraySetFloat32At(byte_array, 1, -1.0f));
  float_value = FLT_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat32At(byte_array, 1, &float_value));
  EXPECT_EQ(-1.0f, float_value);

  // 8-byte misaligned sets.

  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 1, DBL_MIN));
  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 9, DBL_MAX));

  double double_value = 0.0;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 1, &double_value));
  EXPECT_EQ(DBL_MIN, double_value);

  double_value = 0.0;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 9, &double_value));
  EXPECT_EQ(DBL_MAX, double_value);

  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 1, 0.0));
  double_value = DBL_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 1, &double_value));
  EXPECT_EQ(0.0, double_value);

  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 9, -0.0));
  double_value = DBL_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 9, &double_value));
  EXPECT_EQ(-0.0, double_value);

  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 9, 1.0));
  double_value = DBL_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 9, &double_value));
  EXPECT_EQ(1.0, double_value);

  EXPECT_VALID(Dart_ByteArraySetFloat64At(byte_array, 1, -1.0));
  double_value = DBL_MAX;
  EXPECT_VALID(Dart_ByteArrayGetFloat64At(byte_array, 1, &double_value));
  EXPECT_EQ(-1.0, double_value);
}


TEST_CASE(ExternalByteArrayAccess) {
  uint8_t data[] = { 0, 11, 22, 33, 44, 55, 66, 77 };
  intptr_t data_length = ARRAY_SIZE(data);

  Dart_Handle obj = Dart_NewExternalByteArray(data, data_length, NULL, NULL);
  EXPECT_VALID(obj);
  EXPECT(Dart_IsByteArray(obj));
  EXPECT(Dart_IsList(obj));

  void* peer = &data;  // just a non-NULL value
  EXPECT_VALID(Dart_ExternalByteArrayGetPeer(obj, &peer));
  EXPECT(peer == NULL);

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


static void ExternalByteArrayCallbackFinalizer(void* peer) {
  *static_cast<int*>(peer) = 42;
}


TEST_CASE(ExternalByteArrayCallback) {
  int peer = 0;
  {
    Dart_EnterScope();
    uint8_t data[] = { 1, 2, 3, 4 };
    Dart_Handle obj = Dart_NewExternalByteArray(
        data,
        ARRAY_SIZE(data),
        &peer,
        ExternalByteArrayCallbackFinalizer);
    EXPECT_VALID(obj);
    void* api_peer = NULL;
    EXPECT_VALID(Dart_ExternalByteArrayGetPeer(obj, &api_peer));
    EXPECT_EQ(api_peer, &peer);
    Dart_ExitScope();
  }
  EXPECT(peer == 0);
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT(peer == 0);
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
  EXPECT(peer == 42);
}

#endif


// Unit test for entering a scope, creating a local handle and exiting
// the scope.
UNIT_TEST_CASE(EnterExitScope) {
  TestIsolateScope __test_isolate__;

  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  Dart_EnterScope();
  {
    EXPECT(state->top_scope() != NULL);
    DARTSCOPE_NOCHECKS(isolate);
    const String& str1 = String::Handle(String::New("Test String"));
    Dart_Handle ref = Api::NewHandle(isolate, str1.raw());
    String& str2 = String::Handle();
    str2 ^= Api::UnwrapHandle(ref);
    EXPECT(str1.Equals(str2));
  }
  Dart_ExitScope();
  EXPECT(scope == state->top_scope());
}


// Unit test for creating and deleting persistent handles.
UNIT_TEST_CASE(PersistentHandles) {
  const char* kTestString1 = "Test String1";
  const char* kTestString2 = "Test String2";
  TestCase::CreateTestIsolate();
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  Dart_Handle handles[2000];
  Dart_EnterScope();
  {
    DARTSCOPE_NOCHECKS(isolate);
    Dart_Handle ref1 = Api::NewHandle(isolate, String::New(kTestString1));
    for (int i = 0; i < 1000; i++) {
      handles[i] = Dart_NewPersistentHandle(ref1);
    }
    Dart_EnterScope();
    Dart_Handle ref2 = Api::NewHandle(isolate, String::New(kTestString2));
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
    DARTSCOPE_NOCHECKS(isolate);
    for (int i = 0; i < 500; i++) {
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(handles[i]);
      EXPECT(str.Equals(kTestString1));
    }
    for (int i = 500; i < 1000; i++) {
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(handles[i]);
      EXPECT(str.Equals(kTestString2));
    }
    for (int i = 1000; i < 1500; i++) {
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(handles[i]);
      EXPECT(str.Equals(kTestString1));
    }
    for (int i = 1500; i < 2000; i++) {
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(handles[i]);
      EXPECT(str.Equals(kTestString2));
    }
  }
  EXPECT(scope == state->top_scope());
  EXPECT_EQ(2000, state->CountPersistentHandles());
  Dart_ShutdownIsolate();
}


// Test that we are able to create a persistent handle from a
// persistent handle.
UNIT_TEST_CASE(NewPersistentHandle_FromPersistentHandle) {
  TestIsolateScope __test_isolate__;

  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);

  // Start with a known persistent handle.
  Dart_Handle obj1 = Dart_True();
  EXPECT(state->IsValidPersistentHandle(obj1));

  // And use it to allocate a second persistent handle.
  Dart_Handle obj2 = Dart_NewPersistentHandle(obj1);
  EXPECT(state->IsValidPersistentHandle(obj2));

  // Make sure that the value transferred.
  EXPECT(Dart_IsBoolean(obj2));
  bool value = false;
  Dart_Handle result = Dart_BooleanValue(obj2, &value);
  EXPECT_VALID(result);
  EXPECT(value);
}


// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)

TEST_CASE(WeakPersistentHandle) {
  Dart_Handle weak_new_ref = Dart_Null();
  EXPECT(Dart_IsNull(weak_new_ref));

  Dart_Handle weak_old_ref = Dart_Null();
  EXPECT(Dart_IsNull(weak_old_ref));

  {
    Dart_EnterScope();

    // create an object in new space
    Dart_Handle new_ref = Dart_NewString("new string");
    EXPECT_VALID(new_ref);

    // create an object in old space
    Dart_Handle old_ref;
    {
      Isolate* isolate = Isolate::Current();
      DARTSCOPE(isolate);
      old_ref = Api::NewHandle(isolate, String::New("old string", Heap::kOld));
      EXPECT_VALID(old_ref);
    }

    // create a weak ref to the new space object
    weak_new_ref = Dart_NewWeakPersistentHandle(new_ref, NULL, NULL);
    EXPECT_VALID(weak_new_ref);
    EXPECT(!Dart_IsNull(weak_new_ref));

    // create a weak ref to the old space object
    weak_old_ref = Dart_NewWeakPersistentHandle(old_ref, NULL, NULL);
    EXPECT_VALID(weak_old_ref);
    EXPECT(!Dart_IsNull(weak_old_ref));

    // garbage collect new space
    Isolate::Current()->heap()->CollectGarbage(Heap::kNew);

    // nothing should be invalidated or cleared
    EXPECT_VALID(new_ref);
    EXPECT(!Dart_IsNull(new_ref));
    EXPECT_VALID(old_ref);
    EXPECT(!Dart_IsNull(old_ref));

    EXPECT_VALID(weak_new_ref);
    EXPECT(!Dart_IsNull(weak_new_ref));
    EXPECT(Dart_IdentityEquals(new_ref, weak_new_ref));

    EXPECT_VALID(weak_old_ref);
    EXPECT(!Dart_IsNull(weak_old_ref));
    EXPECT(Dart_IdentityEquals(old_ref, weak_old_ref));

    // garbage collect old space
    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);

    // nothing should be invalidated or cleared
    EXPECT_VALID(new_ref);
    EXPECT(!Dart_IsNull(new_ref));
    EXPECT_VALID(old_ref);
    EXPECT(!Dart_IsNull(old_ref));

    EXPECT_VALID(weak_new_ref);
    EXPECT(!Dart_IsNull(weak_new_ref));
    EXPECT(Dart_IdentityEquals(new_ref, weak_new_ref));

    EXPECT_VALID(weak_old_ref);
    EXPECT(!Dart_IsNull(weak_old_ref));
    EXPECT(Dart_IdentityEquals(old_ref, weak_old_ref));

    // delete local (strong) references
    Dart_ExitScope();
  }

  // garbage collect new space again
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);

  // weak ref to new space object should now be cleared
  EXPECT_VALID(weak_new_ref);
  EXPECT(Dart_IsNull(weak_new_ref));
  EXPECT_VALID(weak_old_ref);
  EXPECT(!Dart_IsNull(weak_old_ref));

  // garbage collect old space again
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);

  // weak ref to old space object should now be cleared
  EXPECT_VALID(weak_new_ref);
  EXPECT(Dart_IsNull(weak_new_ref));
  EXPECT_VALID(weak_old_ref);
  EXPECT(Dart_IsNull(weak_old_ref));

  Dart_DeletePersistentHandle(weak_new_ref);
  Dart_DeletePersistentHandle(weak_old_ref);

  // garbage collect one last time to revisit deleted handles
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
}


static void WeakPersistentHandlePeerFinalizer(Dart_Handle handle, void* peer) {
  *static_cast<int*>(peer) = 42;
}


TEST_CASE(WeakPersistentHandleCallback) {
  Dart_Handle weak_ref = Dart_Null();
  EXPECT(Dart_IsNull(weak_ref));
  int* peer = new int();
  {
    Dart_EnterScope();
    Dart_Handle obj = Dart_NewString("new string");
    EXPECT_VALID(obj);
    weak_ref = Dart_NewWeakPersistentHandle(obj, peer,
                                            WeakPersistentHandlePeerFinalizer);
    Dart_ExitScope();
  }
  EXPECT_VALID(weak_ref);
  EXPECT(*peer == 0);
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT(*peer == 0);
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
  EXPECT(*peer == 42);
  delete peer;
  Dart_DeletePersistentHandle(weak_ref);
}


TEST_CASE(ObjectGroups) {
  Dart_Handle strong = Dart_Null();
  EXPECT(Dart_IsNull(strong));

  Dart_Handle weak1 = Dart_Null();
  EXPECT(Dart_IsNull(weak1));

  Dart_Handle weak2 = Dart_Null();
  EXPECT(Dart_IsNull(weak2));

  Dart_Handle weak3 = Dart_Null();
  EXPECT(Dart_IsNull(weak3));

  Dart_Handle weak4 = Dart_Null();
  EXPECT(Dart_IsNull(weak4));

  Dart_EnterScope();
  {
    Isolate* isolate = Isolate::Current();
    DARTSCOPE(isolate);

    strong = Dart_NewPersistentHandle(
        Api::NewHandle(isolate, String::New("strongly reachable", Heap::kOld)));
    EXPECT_VALID(strong);
    EXPECT(!Dart_IsNull(strong));

    weak1 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 1", Heap::kOld)),
        NULL, NULL);
    EXPECT_VALID(weak1);
    EXPECT(!Dart_IsNull(weak1));

    weak2 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 2", Heap::kOld)),
        NULL, NULL);
    EXPECT_VALID(weak2);
    EXPECT(!Dart_IsNull(weak2));

    weak3 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 3", Heap::kOld)),
        NULL, NULL);
    EXPECT_VALID(weak3);
    EXPECT(!Dart_IsNull(weak3));

    weak4 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 4", Heap::kOld)),
        NULL, NULL);
    EXPECT_VALID(weak4);
    EXPECT(!Dart_IsNull(weak4));
  }
  Dart_ExitScope();

  EXPECT_VALID(strong);

  EXPECT_VALID(weak1);
  EXPECT_VALID(weak2);
  EXPECT_VALID(weak3);
  EXPECT_VALID(weak4);

  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);

  // New space collection should not affect old space objects
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(!Dart_IsNull(weak2));
  EXPECT(!Dart_IsNull(weak3));
  EXPECT(!Dart_IsNull(weak4));

  {
    Dart_Handle array1[] = { weak1, strong };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array1, ARRAY_SIZE(array1),
                                          array1, ARRAY_SIZE(array1)));

    Dart_Handle array2[] = { weak2, weak1 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array2, ARRAY_SIZE(array2),
                                          array2, ARRAY_SIZE(array2)));

    Dart_Handle array3[] = { weak3, weak2 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array3, ARRAY_SIZE(array3),
                                          array3, ARRAY_SIZE(array3)));

    Dart_Handle array4[] = { weak4, weak3 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array4, ARRAY_SIZE(array4),
                                          array4, ARRAY_SIZE(array4)));

    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  }

  // All weak references should be preserved.
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(!Dart_IsNull(weak2));
  EXPECT(!Dart_IsNull(weak3));
  EXPECT(!Dart_IsNull(weak4));

  {
    Dart_Handle array1[] = { weak1, strong };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array1, ARRAY_SIZE(array1),
                                          array1, ARRAY_SIZE(array1)));

    Dart_Handle array2[] = { weak2, weak1 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array2, ARRAY_SIZE(array2),
                                          array2, ARRAY_SIZE(array2)));

    Dart_Handle array3[] = { weak2 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array3, ARRAY_SIZE(array3),
                                          array3, ARRAY_SIZE(array3)));

    // Strong reference to weak3 to retain weak3 and weak4.
    Dart_Handle weak3_strong_ref = Dart_NewPersistentHandle(weak3);
    EXPECT_VALID(weak3_strong_ref);

    Dart_Handle array4[] = { weak4, weak3 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array4, ARRAY_SIZE(array4),
                                          array4, ARRAY_SIZE(array4)));

    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);

    // Delete strong reference to weak3.
    Dart_DeletePersistentHandle(weak3_strong_ref);
  }

  // All weak references should be preserved.
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(!Dart_IsNull(weak2));
  EXPECT(!Dart_IsNull(weak3));
  EXPECT(!Dart_IsNull(weak4));

  {
    Dart_Handle array1[] = { weak1, strong };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array1, ARRAY_SIZE(array1),
                                          array1, ARRAY_SIZE(array1)));

    Dart_Handle array2[] = { weak2, weak1 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array2, ARRAY_SIZE(array2),
                                          array2, ARRAY_SIZE(array2)));

    Dart_Handle array3[] = { weak2 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array3, ARRAY_SIZE(array3),
                                          array3, ARRAY_SIZE(array3)));

    Dart_Handle array4[] = { weak4, weak3 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array4, ARRAY_SIZE(array4),
                                          array4, ARRAY_SIZE(array4)));

    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  }

  // Only weak1 and weak2 should be preserved.
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(!Dart_IsNull(weak2));
  EXPECT(Dart_IsNull(weak3));
  EXPECT(Dart_IsNull(weak4));

  {
    Dart_Handle array1[] = { weak1, strong };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array1, ARRAY_SIZE(array1),
                                          array1, ARRAY_SIZE(array1)));

    // weak3 is cleared so weak2 is unreferenced and should be cleared
    Dart_Handle array2[] = { weak2, weak3 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array2, ARRAY_SIZE(array2),
                                          array2, ARRAY_SIZE(array2)));

    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  }

  // Only weak1 should be preserved, weak3 should not preserve weak2.
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(Dart_IsNull(weak2));
  EXPECT(Dart_IsNull(weak3));  // was cleared, should remain cleared
  EXPECT(Dart_IsNull(weak4));  // was cleared, should remain cleared

  {
    // weak{2,3,4} are cleared and should have no effect on weak1
    Dart_Handle array1[] = { strong, weak2, weak3, weak4 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array1, ARRAY_SIZE(array1),
                                          array1, ARRAY_SIZE(array1)));

    // weak1 is weakly reachable and should be cleared
    Dart_Handle array2[] = { weak1 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(array2, ARRAY_SIZE(array2),
                                          array2, ARRAY_SIZE(array2)));

    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  }

  // All weak references should now be cleared.
  EXPECT(Dart_IsNull(weak1));
  EXPECT(Dart_IsNull(weak2));
  EXPECT(Dart_IsNull(weak3));
  EXPECT(Dart_IsNull(weak4));
}


TEST_CASE(PrologueWeakPersistentHandles) {
  Dart_Handle old_pwph = Dart_Null();
  EXPECT(Dart_IsNull(old_pwph));
  Dart_Handle new_pwph = Dart_Null();
  EXPECT(Dart_IsNull(new_pwph));
  Dart_EnterScope();
  {
    Isolate* isolate = Isolate::Current();
    DARTSCOPE(isolate);
    new_pwph = Dart_NewPrologueWeakPersistentHandle(
        Api::NewHandle(isolate,
                       String::New("new space prologue weak", Heap::kNew)),
        NULL, NULL);
    EXPECT_VALID(new_pwph);
    EXPECT(!Dart_IsNull(new_pwph));
    old_pwph = Dart_NewPrologueWeakPersistentHandle(
        Api::NewHandle(isolate,
                       String::New("old space prologue weak", Heap::kOld)),
        NULL, NULL);
    EXPECT_VALID(old_pwph);
    EXPECT(!Dart_IsNull(old_pwph));
  }
  Dart_ExitScope();
  EXPECT_VALID(new_pwph);
  EXPECT(!Dart_IsNull(new_pwph));
  EXPECT(Dart_IsPrologueWeakPersistentHandle(new_pwph));
  EXPECT_VALID(old_pwph);
  EXPECT(!Dart_IsNull(old_pwph));
  EXPECT(Dart_IsPrologueWeakPersistentHandle(old_pwph));
  // Garbage collect new space without invoking API callbacks.
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew,
                                             Heap::kIgnoreApiCallbacks);
  // Both prologue weak handles should be preserved.
  EXPECT(!Dart_IsNull(new_pwph));
  EXPECT(!Dart_IsNull(old_pwph));
  // Garbage collect old space without invoking API callbacks.
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld,
                                             Heap::kIgnoreApiCallbacks);
  // Both prologue weak handles should be preserved.
  EXPECT(!Dart_IsNull(new_pwph));
  EXPECT(!Dart_IsNull(old_pwph));
  // Garbage collect new space invoking API callbacks.
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew,
                                             Heap::kInvokeApiCallbacks);
  // The prologue weak handle with a new space referent should now be
  // cleared.  The old space referent should be preserved.
  EXPECT(Dart_IsNull(new_pwph));
  EXPECT(!Dart_IsNull(old_pwph));
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld,
                                             Heap::kInvokeApiCallbacks);
  // The prologue weak handle with an old space referent should now be
  // cleared.  The new space referent should remain cleared.
  EXPECT(Dart_IsNull(new_pwph));
  EXPECT(Dart_IsNull(old_pwph));
}


TEST_CASE(ImplicitReferencesOldSpace) {
  Dart_Handle strong = Dart_Null();
  EXPECT(Dart_IsNull(strong));

  Dart_Handle weak1 = Dart_Null();
  EXPECT(Dart_IsNull(weak1));

  Dart_Handle weak2 = Dart_Null();
  EXPECT(Dart_IsNull(weak2));

  Dart_Handle weak3 = Dart_Null();
  EXPECT(Dart_IsNull(weak3));

  Dart_EnterScope();
  {
    Isolate* isolate = Isolate::Current();
    DARTSCOPE(isolate);

    strong = Dart_NewPersistentHandle(
        Api::NewHandle(isolate, String::New("strongly reachable", Heap::kOld)));
    EXPECT(!Dart_IsNull(strong));
    EXPECT_VALID(strong);

    weak1 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 1", Heap::kOld)),
        NULL, NULL);
    EXPECT(!Dart_IsNull(weak1));
    EXPECT_VALID(weak1);

    weak2 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 2", Heap::kOld)),
        NULL, NULL);
    EXPECT(!Dart_IsNull(weak2));
    EXPECT_VALID(weak2);

    weak3 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 3", Heap::kOld)),
        NULL, NULL);
    EXPECT(!Dart_IsNull(weak3));
    EXPECT_VALID(weak3);
  }
  Dart_ExitScope();

  EXPECT_VALID(strong);

  EXPECT_VALID(weak1);
  EXPECT_VALID(weak2);
  EXPECT_VALID(weak3);

  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);

  // New space collection should not affect old space objects
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(!Dart_IsNull(weak2));
  EXPECT(!Dart_IsNull(weak3));

  // A strongly referenced key should preserve all the values.
  {
    Dart_Handle keys[] = { strong };
    Dart_Handle values[] = { weak1, weak2, weak3 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(keys, ARRAY_SIZE(keys),
                                          values, ARRAY_SIZE(values)));

    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  }

  // All weak references should be preserved.
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(!Dart_IsNull(weak2));
  EXPECT(!Dart_IsNull(weak3));

  // Key membership does not imply a strong reference.
  {
    Dart_Handle keys[] = { strong, weak3 };
    Dart_Handle values[] = { weak1, weak2 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(keys, ARRAY_SIZE(keys),
                                          values, ARRAY_SIZE(values)));

    Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  }

  // All weak references except weak3 should be preserved.
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(!Dart_IsNull(weak2));
  EXPECT(Dart_IsNull(weak3));
}


TEST_CASE(ImplicitReferencesNewSpace) {
  Dart_Handle strong = Dart_Null();
  EXPECT(Dart_IsNull(strong));

  Dart_Handle weak1 = Dart_Null();
  EXPECT(Dart_IsNull(weak1));

  Dart_Handle weak2 = Dart_Null();
  EXPECT(Dart_IsNull(weak2));

  Dart_Handle weak3 = Dart_Null();
  EXPECT(Dart_IsNull(weak3));

  Dart_EnterScope();
  {
    Isolate* isolate = Isolate::Current();
    DARTSCOPE(isolate);

    strong = Dart_NewPersistentHandle(
        Api::NewHandle(isolate, String::New("strongly reachable", Heap::kNew)));
    EXPECT(!Dart_IsNull(strong));
    EXPECT_VALID(strong);

    weak1 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 1", Heap::kNew)),
        NULL, NULL);
    EXPECT(!Dart_IsNull(weak1));
    EXPECT_VALID(weak1);

    weak2 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 2", Heap::kNew)),
        NULL, NULL);
    EXPECT(!Dart_IsNull(weak2));
    EXPECT_VALID(weak2);

    weak3 = Dart_NewWeakPersistentHandle(
        Api::NewHandle(isolate, String::New("weakly reachable 3", Heap::kNew)),
        NULL, NULL);
    EXPECT(!Dart_IsNull(weak3));
    EXPECT_VALID(weak3);
  }
  Dart_ExitScope();

  EXPECT_VALID(strong);

  EXPECT_VALID(weak1);
  EXPECT_VALID(weak2);
  EXPECT_VALID(weak3);

  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);

  // Old space collection should not affect old space objects.
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(!Dart_IsNull(weak2));
  EXPECT(!Dart_IsNull(weak3));

  // A strongly referenced key should preserve all the values.
  {
    Dart_Handle keys[] = { strong };
    Dart_Handle values[] = { weak1, weak2, weak3 };
    EXPECT_VALID(Dart_NewWeakReferenceSet(keys, ARRAY_SIZE(keys),
                                          values, ARRAY_SIZE(values)));

    Isolate::Current()->heap()->CollectGarbage(Heap::kNew,
                                               Heap::kInvokeApiCallbacks);
  }

  // All weak references should be preserved.
  EXPECT(!Dart_IsNull(weak1));
  EXPECT(!Dart_IsNull(weak2));
  EXPECT(!Dart_IsNull(weak3));

  Isolate::Current()->heap()->CollectGarbage(Heap::kNew,
                                             Heap::kIgnoreApiCallbacks);

  // No weak references should be preserved.
  EXPECT(Dart_IsNull(weak1));
  EXPECT(Dart_IsNull(weak2));
  EXPECT(Dart_IsNull(weak3));
}


static int global_prologue_callback_status;


static void PrologueCallbackTimes2() {
  global_prologue_callback_status *= 2;
}


static void PrologueCallbackTimes3() {
  global_prologue_callback_status *= 3;
}


static int global_epilogue_callback_status;


static void EpilogueCallbackTimes4() {
  global_epilogue_callback_status *= 4;
}


static void EpilogueCallbackTimes5() {
  global_epilogue_callback_status *= 5;
}


TEST_CASE(AddGarbageCollectionCallbacks) {
  // Add a prologue callback.
  EXPECT_VALID(Dart_AddGcPrologueCallback(&PrologueCallbackTimes2));

  // Add the same prologue callback again.  This is an error.
  EXPECT(Dart_IsError(Dart_AddGcPrologueCallback(&PrologueCallbackTimes2)));

  // Add another prologue callback.
  EXPECT_VALID(Dart_AddGcPrologueCallback(&PrologueCallbackTimes3));

  // Add the same prologue callback again.  This is an error.
  EXPECT(Dart_IsError(Dart_AddGcPrologueCallback(&PrologueCallbackTimes3)));

  // Add an epilogue callback.
  EXPECT_VALID(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes4));

  // Add the same epilogue callback again.  This is an error.
  EXPECT(Dart_IsError(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes4)));

  // Add annother epilogue callback.
  EXPECT_VALID(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes5));

  // Add the same epilogue callback again.  This is an error.
  EXPECT(Dart_IsError(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes5)));
}


TEST_CASE(RemoveGarbageCollectionCallbacks) {
  // Remove a prologue callback that has not been added.  This is an error.
  EXPECT(Dart_IsError(Dart_RemoveGcPrologueCallback(&PrologueCallbackTimes2)));

  // Add a prologue callback.
  EXPECT_VALID(Dart_AddGcPrologueCallback(&PrologueCallbackTimes2));

  // Remove a prologue callback.
  EXPECT_VALID(Dart_RemoveGcPrologueCallback(&PrologueCallbackTimes2));

  // Remove a prologue callback again.  This is an error.
  EXPECT(Dart_IsError(Dart_RemoveGcPrologueCallback(&PrologueCallbackTimes2)));

  // Add two prologue callbacks.
  EXPECT_VALID(Dart_AddGcPrologueCallback(&PrologueCallbackTimes2));
  EXPECT_VALID(Dart_AddGcPrologueCallback(&PrologueCallbackTimes3));

  // Remove two prologue callbacks.
  EXPECT_VALID(Dart_RemoveGcPrologueCallback(&PrologueCallbackTimes3));
  EXPECT_VALID(Dart_RemoveGcPrologueCallback(&PrologueCallbackTimes2));

  // Remove epilogue callbacks again.  This is an error.
  EXPECT(Dart_IsError(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes4)));
  EXPECT(Dart_IsError(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes5)));

  // Remove a epilogue callback that has not been added.  This is an error.
  EXPECT(Dart_IsError(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes5)));

  // Add a epilogue callback.
  EXPECT_VALID(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes4));

  // Remove a epilogue callback.
  EXPECT_VALID(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes4));

  // Remove a epilogue callback again.  This is an error.
  EXPECT(Dart_IsError(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes4)));

  // Add two epilogue callbacks.
  EXPECT_VALID(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes4));
  EXPECT_VALID(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes5));

  // Remove two epilogue callbacks.
  EXPECT_VALID(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes5));
  EXPECT_VALID(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes4));

  // Remove epilogue callbacks again.  This is an error.
  EXPECT(Dart_IsError(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes4)));
  EXPECT(Dart_IsError(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes5)));
}


TEST_CASE(SingleGarbageCollectionCallback) {
  // Add a prologue callback.
  EXPECT_VALID(Dart_AddGcPrologueCallback(&PrologueCallbackTimes2));

  // Garbage collect new space ignoring callbacks.  This should not
  // invoke the prologue callback.  No status values should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
  EXPECT_EQ(3, global_prologue_callback_status);
  EXPECT_EQ(7, global_epilogue_callback_status);

  // Garbage collect new space invoking callbacks.  This should
  // invoke the prologue callback.  No status values should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew,
                                             Heap::kInvokeApiCallbacks);
  EXPECT_EQ(6, global_prologue_callback_status);
  EXPECT_EQ(7, global_epilogue_callback_status);

  // Garbage collect old space ignoring callbacks.  This should invoke
  // the prologue callback.  The prologue status value should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld,
                                             Heap::kIgnoreApiCallbacks);
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
  // prolog status value should change again.
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(12, global_prologue_callback_status);
  EXPECT_EQ(7, global_epilogue_callback_status);

  // Add an epilogue callback.
  EXPECT_VALID(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes4));

  // Garbage collect new space.  This should not invoke the prologue
  // or the epilogue callback.  No status values should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
  EXPECT_EQ(3, global_prologue_callback_status);
  EXPECT_EQ(7, global_epilogue_callback_status);

  // Garbage collect new space.  This should invoke the prologue and
  // the epilogue callback.  The prologue and epilogue status values
  // should change.
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew,
                                             Heap::kInvokeApiCallbacks);
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
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld,
                                             Heap::kIgnoreApiCallbacks);
  EXPECT_EQ(6, global_prologue_callback_status);
  EXPECT_EQ(28, global_epilogue_callback_status);

  // Garbage collect old space again.  Callbacks are persistent so the
  // prologue and epilogue status values should change again.
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(12, global_prologue_callback_status);
  EXPECT_EQ(112, global_epilogue_callback_status);

  // Remove the prologue and epilogue callbacks
  EXPECT_VALID(Dart_RemoveGcPrologueCallback(&PrologueCallbackTimes2));
  EXPECT_VALID(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes4));

  // Garbage collect old space.  No callbacks should be invoked.  No
  // status values should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(3, global_prologue_callback_status);
  EXPECT_EQ(7, global_epilogue_callback_status);
}

TEST_CASE(MultipleGarbageCollectionCallbacks) {
  // Add prologue callbacks.
  EXPECT_VALID(Dart_AddGcPrologueCallback(&PrologueCallbackTimes2));
  EXPECT_VALID(Dart_AddGcPrologueCallback(&PrologueCallbackTimes3));

  // Add an epilogue callback.
  EXPECT_VALID(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes4));

  // Garbage collect new space.  This should not invoke the prologue
  // or epilogue callbacks.  No status values should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kNew);
  EXPECT_EQ(3, global_prologue_callback_status);
  EXPECT_EQ(7, global_epilogue_callback_status);

  // Garbage collect old space.  This should invoke both prologue
  // callbacks and the epilogue callback.  The prologue and epilogue
  // status values should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(18, global_prologue_callback_status);
  EXPECT_EQ(28, global_epilogue_callback_status);

  // Add another GC epilogue callback.
  EXPECT_VALID(Dart_AddGcEpilogueCallback(&EpilogueCallbackTimes5));

  // Garbage collect old space.  This should invoke both prologue
  // callbacks and both epilogue callbacks.  The prologue and epilogue
  // status values should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(18, global_prologue_callback_status);
  EXPECT_EQ(140, global_epilogue_callback_status);

  // Remove an epilogue callback.
  EXPECT_VALID(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes4));

  // Garbage collect old space.  This should invoke both prologue
  // callbacks and the remaining epilogue callback.  The prologue and
  // epilogue status values should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(18, global_prologue_callback_status);
  EXPECT_EQ(35, global_epilogue_callback_status);

  // Remove the remaining epilogue callback.
  EXPECT_VALID(Dart_RemoveGcEpilogueCallback(&EpilogueCallbackTimes5));

  // Garbage collect old space.  This should invoke both prologue
  // callbacks.  The prologue status value should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(18, global_prologue_callback_status);
  EXPECT_EQ(7, global_epilogue_callback_status);

  // Remove a prologue callback.
  EXPECT_VALID(Dart_RemoveGcPrologueCallback(&PrologueCallbackTimes3));

  // Garbage collect old space.  This should invoke the remaining
  // prologue callback.  The prologue status value should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(6, global_prologue_callback_status);
  EXPECT_EQ(7, global_epilogue_callback_status);

  // Remove the remaining prologue callback.
  EXPECT_VALID(Dart_RemoveGcPrologueCallback(&PrologueCallbackTimes2));

  // Garbage collect old space.  No callbacks should be invoked.  No
  // status values should change.
  global_prologue_callback_status = 3;
  global_epilogue_callback_status = 7;
  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  EXPECT_EQ(3, global_prologue_callback_status);
  EXPECT_EQ(7, global_epilogue_callback_status);
}

#endif


// Unit test for creating multiple scopes and local handles within them.
// Ensure that the local handles get all cleaned out when exiting the
// scope.
UNIT_TEST_CASE(LocalHandles) {
  TestCase::CreateTestIsolate();
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  Dart_Handle handles[300];
  {
    DARTSCOPE_NOCHECKS(isolate);
    Smi& val = Smi::Handle();

    // Start a new scope and allocate some local handles.
    Dart_EnterScope();
    for (int i = 0; i < 100; i++) {
      handles[i] = Api::NewHandle(isolate, Smi::New(i));
    }
    EXPECT_EQ(100, state->CountLocalHandles());
    for (int i = 0; i < 100; i++) {
      val ^= Api::UnwrapHandle(handles[i]);
      EXPECT_EQ(i, val.Value());
    }
    // Start another scope and allocate some more local handles.
    {
      Dart_EnterScope();
      for (int i = 100; i < 200; i++) {
        handles[i] = Api::NewHandle(isolate, Smi::New(i));
      }
      EXPECT_EQ(200, state->CountLocalHandles());
      for (int i = 100; i < 200; i++) {
        val ^= Api::UnwrapHandle(handles[i]);
        EXPECT_EQ(i, val.Value());
      }

      // Start another scope and allocate some more local handles.
      {
        Dart_EnterScope();
        for (int i = 200; i < 300; i++) {
          handles[i] = Api::NewHandle(isolate, Smi::New(i));
        }
        EXPECT_EQ(300, state->CountLocalHandles());
        for (int i = 200; i < 300; i++) {
          val ^= Api::UnwrapHandle(handles[i]);
          EXPECT_EQ(i, val.Value());
        }
        EXPECT_EQ(300, state->CountLocalHandles());
        VERIFY_ON_TRANSITION;
        Dart_ExitScope();
      }
      EXPECT_EQ(200, state->CountLocalHandles());
      Dart_ExitScope();
    }
    EXPECT_EQ(100, state->CountLocalHandles());
    Dart_ExitScope();
  }
  EXPECT_EQ(0, state->CountLocalHandles());
  EXPECT(scope == state->top_scope());
  Dart_ShutdownIsolate();
}


// Unit test for creating multiple scopes and allocating objects in the
// zone for the scope. Ensure that the memory is freed when the scope
// exits.
UNIT_TEST_CASE(LocalZoneMemory) {
  TestCase::CreateTestIsolate();
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  {
    // Start a new scope and allocate some memory.
    Dart_EnterScope();
    for (int i = 0; i < 100; i++) {
      Api::Allocate(isolate, 16);
    }
    EXPECT_EQ(1600, state->ZoneSizeInBytes());
    // Start another scope and allocate some more memory.
    {
      Dart_EnterScope();
      for (int i = 0; i < 100; i++) {
        Api::Allocate(isolate, 16);
      }
      EXPECT_EQ(3200, state->ZoneSizeInBytes());
      {
        // Start another scope and allocate some more memory.
        {
          Dart_EnterScope();
          for (int i = 0; i < 200; i++) {
            Api::Allocate(isolate, 16);
          }
          EXPECT_EQ(6400, state->ZoneSizeInBytes());
          Dart_ExitScope();
        }
      }
      EXPECT_EQ(3200, state->ZoneSizeInBytes());
      Dart_ExitScope();
    }
    EXPECT_EQ(1600, state->ZoneSizeInBytes());
    Dart_ExitScope();
  }
  EXPECT_EQ(0, state->ZoneSizeInBytes());
  EXPECT(scope == state->top_scope());
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(Isolates) {
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


TEST_CASE(DebugName) {
  Dart_Handle debug_name = Dart_DebugName();
  EXPECT_VALID(debug_name);
  EXPECT(Dart_IsString(debug_name));
}


static void MyMessageNotifyCallback(Dart_Isolate dest_isolate) {
}


UNIT_TEST_CASE(SetMessageCallbacks) {
  Dart_Isolate dart_isolate = TestCase::CreateTestIsolate();
  Dart_SetMessageNotifyCallback(&MyMessageNotifyCallback);
  Isolate* isolate = reinterpret_cast<Isolate*>(dart_isolate);
  EXPECT_EQ(&MyMessageNotifyCallback, isolate->message_notify_callback());
  Dart_ShutdownIsolate();
}


// Only ia32 and x64 can run execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)


TEST_CASE(ClassBasics) {
  const char* kScriptChars =
      "class MyClass {\n"
      "}\n"
      "class MyDefault {\n"
      "}\n"
      "interface MyInterface default MyDefault {\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("MyClass"));
  Dart_Handle interface = Dart_GetClass(lib, Dart_NewString("MyInterface"));

  // Test Dart_IsClass and Dart_IsInterface.
  EXPECT(Dart_IsClass(cls));
  EXPECT(!Dart_IsClass(interface));
  EXPECT(!Dart_IsClass(Dart_True()));

  EXPECT(!Dart_IsInterface(cls));
  EXPECT(Dart_IsInterface(interface));
  EXPECT(!Dart_IsInterface(Dart_True()));

  EXPECT(!Dart_IsInterface(cls));
  EXPECT(Dart_IsInterface(interface));
  EXPECT(!Dart_IsInterface(Dart_True()));

  // Test Dart_ClassName
  Dart_Handle cls_name = Dart_ClassName(cls);
  EXPECT_VALID(cls_name);
  const char* cls_name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(cls_name, &cls_name_cstr));
  EXPECT_STREQ("MyClass", cls_name_cstr);

  cls_name = Dart_ClassName(interface);
  EXPECT_VALID(cls_name);
  cls_name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(cls_name, &cls_name_cstr));
  EXPECT_STREQ("MyInterface", cls_name_cstr);

  EXPECT_ERROR(Dart_ClassName(Dart_True()),
               "Dart_ClassName expects argument 'clazz' to be of type Class.");
  EXPECT_ERROR(Dart_ClassName(Dart_NewApiError("MyError")), "MyError");

  // Test Dart_ClassGetLibrary
  Dart_Handle cls_lib = Dart_ClassGetLibrary(cls);
  Dart_Handle cls_lib_name = Dart_LibraryName(cls_lib);
  EXPECT_VALID(cls_lib_name);
  const char* cls_lib_name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(cls_lib_name, &cls_lib_name_cstr));
  EXPECT_STREQ(TestCase::url(), cls_lib_name_cstr);

  EXPECT_ERROR(
      Dart_ClassGetLibrary(Dart_True()),
      "Dart_ClassGetLibrary expects argument 'clazz' to be of type Class.");
  EXPECT_ERROR(Dart_ClassGetLibrary(Dart_NewApiError("MyError")), "MyError");


  Dart_Handle dflt = Dart_ClassGetDefault(interface);
  EXPECT_VALID(dflt);
  EXPECT(Dart_IsClass(dflt));
  Dart_Handle dflt_name = Dart_ClassName(dflt);
  EXPECT_VALID(dflt_name);
  const char* dflt_name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(dflt_name, &dflt_name_cstr));
  EXPECT_STREQ("MyDefault", dflt_name_cstr);

  EXPECT(Dart_IsNull(Dart_ClassGetDefault(cls)));
  EXPECT_ERROR(
      Dart_ClassGetDefault(Dart_True()),
      "Dart_ClassGetDefault expects argument 'clazz' to be of type Class.");
  EXPECT_ERROR(Dart_ClassGetDefault(Dart_NewApiError("MyError")), "MyError");
}


#define CHECK_INTERFACE(handle, name)                                   \
  {                                                                     \
    Dart_Handle tmp = (handle);                                         \
    EXPECT_VALID(tmp);                                                  \
    EXPECT(Dart_IsInterface(tmp));                                      \
    Dart_Handle intf_name = Dart_ClassName(tmp);                        \
    EXPECT_VALID(intf_name);                                            \
    const char* intf_name_cstr = "";                                    \
    EXPECT_VALID(Dart_StringToCString(intf_name, &intf_name_cstr));     \
    EXPECT_STREQ((name), intf_name_cstr);                               \
  }


TEST_CASE(ClassGetInterfaces) {
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
      "interface MyInterface0 {\n"
      "}\n"
      "\n"
      "interface MyInterface1 extends MyInterface0 {\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  Dart_Handle cls0 = Dart_GetClass(lib, Dart_NewString("MyClass0"));
  Dart_Handle cls1 = Dart_GetClass(lib, Dart_NewString("MyClass1"));
  Dart_Handle cls2 = Dart_GetClass(lib, Dart_NewString("MyClass2"));
  Dart_Handle intf0 = Dart_GetClass(lib, Dart_NewString("MyInterface0"));
  Dart_Handle intf1 = Dart_GetClass(lib, Dart_NewString("MyInterface1"));

  intptr_t len = -1;
  EXPECT_VALID(Dart_ClassGetInterfaceCount(cls0, &len));
  EXPECT_EQ(0, len);

  EXPECT_ERROR(Dart_ClassGetInterfaceAt(cls0, 0),
               "Dart_ClassGetInterfaceAt: argument 'index' out of bounds");

  len = -1;
  EXPECT_VALID(Dart_ClassGetInterfaceCount(cls1, &len));
  EXPECT_EQ(1, len);
  CHECK_INTERFACE(Dart_ClassGetInterfaceAt(cls1, 0), "MyInterface1");

  EXPECT_ERROR(Dart_ClassGetInterfaceAt(cls1, -1),
               "Dart_ClassGetInterfaceAt: argument 'index' out of bounds");
  EXPECT_ERROR(Dart_ClassGetInterfaceAt(cls1, 1),
               "Dart_ClassGetInterfaceAt: argument 'index' out of bounds");

  len = -1;
  EXPECT_VALID(Dart_ClassGetInterfaceCount(cls2, &len));
  EXPECT_EQ(2, len);

  // TODO(turnidge): The test relies on the ordering here.  Sort this.
  CHECK_INTERFACE(Dart_ClassGetInterfaceAt(cls2, 0), "MyInterface0");
  CHECK_INTERFACE(Dart_ClassGetInterfaceAt(cls2, 1), "MyInterface1");

  len = -1;
  EXPECT_VALID(Dart_ClassGetInterfaceCount(intf0, &len));
  EXPECT_EQ(0, len);

  len = -1;
  EXPECT_VALID(Dart_ClassGetInterfaceCount(intf1, &len));
  EXPECT_EQ(1, len);
  CHECK_INTERFACE(Dart_ClassGetInterfaceAt(intf1, 0), "MyInterface0");

  // Error cases.
  EXPECT_ERROR(Dart_ClassGetInterfaceCount(Dart_True(), &len),
               "Dart_ClassGetInterfaceCount expects argument 'clazz' to be of "
               "type Class.");
  EXPECT_ERROR(Dart_ClassGetInterfaceCount(Dart_NewApiError("MyError"), &len),
               "MyError");
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
  result = Dart_SetField(container, name, Dart_NewString(buffer));
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


static void TestFieldNotFound(Dart_Handle container,
                              Dart_Handle name) {
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
      "  static final final_static_fld = 'final static';\n"
      "  static final _final_static_fld = 'hidden final static';\n"
      "\n"
      "  get instance_getset_fld() { return _gs_fld1; }\n"
      "  void set instance_getset_fld(var value) { _gs_fld1 = value; }\n"
      "  get _instance_getset_fld() { return _gs_fld2; }\n"
      "  void set _instance_getset_fld(var value) { _gs_fld2 = value; }\n"
      "  var _gs_fld1;\n"
      "  var _gs_fld2;\n"
      "\n"
      "  static get static_getset_fld() { return _gs_fld3; }\n"
      "  static void set static_getset_fld(var value) { _gs_fld3 = value; }\n"
      "  static get _static_getset_fld() { return _gs_fld4; }\n"
      "  static void set _static_getset_fld(var value) { _gs_fld4 = value; }\n"
      "  static var _gs_fld3;\n"
      "  static var _gs_fld4;\n"
      "}\n"
      "var top_fld;\n"
      "var _top_fld;\n"
      "final final_top_fld = 'final top';\n"
      "final _final_top_fld = 'hidden final top';\n"
      "\n"
      "get top_getset_fld() { return _gs_fld5; }\n"
      "void set top_getset_fld(var value) { _gs_fld5 = value; }\n"
      "get _top_getset_fld() { return _gs_fld6; }\n"
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
      "#library('library_name');\n"
      "var imported_fld = 'imported';\n"
      "var _imported_fld = 'hidden imported';\n"
      "get imported_getset_fld() { return _gs_fld1; }\n"
      "void set imported_getset_fld(var value) { _gs_fld1 = value; }\n"
      "get _imported_getset_fld() { return _gs_fld2; }\n"
      "void set _imported_getset_fld(var value) { _gs_fld2 = value; }\n"
      "var _gs_fld1;\n"
      "var _gs_fld2;\n"
      "void test2() {\n"
      "  imported_getset_fld = 'imported getset';\n"
      "  _imported_getset_fld = 'hidden imported getset';\n"
      "}\n";

  // Shared setup.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("Fields"));
  EXPECT_VALID(cls);
  Dart_Handle instance = Dart_Invoke(lib, Dart_NewString("test"), 0, NULL);
  EXPECT_VALID(instance);
  Dart_Handle name;

  // Load imported lib.
  Dart_Handle url = Dart_NewString("library_url");
  Dart_Handle source = Dart_NewString(kImportedScriptChars);
  Dart_Handle imported_lib = Dart_LoadLibrary(url, source);
  EXPECT_VALID(imported_lib);
  Dart_Handle result = Dart_LibraryImportLibrary(lib, imported_lib);
  EXPECT_VALID(result);
  result = Dart_Invoke(imported_lib, Dart_NewString("test2"), 0, NULL);
  EXPECT_VALID(result);

  // Instance field.
  name = Dart_NewString("instance_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(cls, name);
  TestFieldOk(instance, name, false, "instance");

  // Hidden instance field.
  name = Dart_NewString("_instance_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(cls, name);
  TestFieldOk(instance, name, false, "hidden instance");

  // Final instance field.
  name = Dart_NewString("final_instance_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(cls, name);
  TestFieldOk(instance, name, true, "final instance");

  // Hidden final instance field.
  name = Dart_NewString("_final_instance_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(cls, name);
  TestFieldOk(instance, name, true, "hidden final instance");

  // Inherited field.
  name = Dart_NewString("inherited_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(cls, name);
  TestFieldOk(instance, name, false, "inherited");

  // Instance get/set field.
  name = Dart_NewString("instance_getset_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(cls, name);
  TestFieldOk(instance, name, false, "instance getset");

  // Hidden instance get/set field.
  name = Dart_NewString("_instance_getset_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(cls, name);
  TestFieldOk(instance, name, false, "hidden instance getset");

  // Static field.
  name = Dart_NewString("static_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(cls, name, false, "static");

  // Hidden static field.
  name = Dart_NewString("_static_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(cls, name, false, "hidden static");

  // Static final field.
  name = Dart_NewString("final_static_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(cls, name, true, "final static");

  // Hidden static final field.
  name = Dart_NewString("_final_static_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(cls, name, true, "hidden final static");

  // Static non-inherited field.  Not found at any level.
  name = Dart_NewString("non_inherited_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldNotFound(cls, name);

  // Static get/set field.
  name = Dart_NewString("static_getset_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(cls, name, false, "static getset");

  // Hidden static get/set field.
  name = Dart_NewString("_static_getset_fld");
  TestFieldNotFound(lib, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(cls, name, false, "hidden static getset");

  // Top-Level field.
  name = Dart_NewString("top_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "top");

  // Hidden top-level field.
  name = Dart_NewString("_top_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "hidden top");

  // Top-Level final field.
  name = Dart_NewString("final_top_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, true, "final top");

  // Hidden top-level final field.
  name = Dart_NewString("_final_top_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, true, "hidden final top");

  // Top-Level get/set field.
  name = Dart_NewString("top_getset_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "top getset");

  // Hidden top-level get/set field.
  name = Dart_NewString("_top_getset_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "hidden top getset");

  // Imported top-Level field.
  name = Dart_NewString("imported_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "imported");

  // Hidden imported top-level field.  Not found at any level.
  name = Dart_NewString("_imported_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldNotFound(lib, name);

  // Imported top-Level get/set field.
  name = Dart_NewString("imported_getset_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldOk(lib, name, false, "imported getset");

  // Hidden imported top-level get/set field.  Not found at any level.
  name = Dart_NewString("_imported_getset_fld");
  TestFieldNotFound(cls, name);
  TestFieldNotFound(instance, name);
  TestFieldNotFound(lib, name);
}


TEST_CASE(SetField_FunnyValue) {
  const char* kScriptChars =
      "var top;\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle name = Dart_NewString("top");
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
                                               int argument_count) {
  return reinterpret_cast<Dart_NativeFunction>(&NativeFieldLookup);
}


TEST_CASE(InjectNativeFields1) {
  const char* kScriptChars =
      "class NativeFields extends NativeFieldsWrapper {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  Dart_Handle result;

  const int kNumNativeFields = 4;

  // Create a test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars,
                                             native_field_lookup);

  // Create a native wrapper class with native fields.
  result = Dart_CreateNativeWrapperClass(
      lib,
      Dart_NewString("NativeFieldsWrapper"),
      kNumNativeFields);

  // Load up a test script in the test library.

  // Invoke a function which returns an object of type NativeFields.
  result = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  DARTSCOPE_NOCHECKS(Isolate::Current());
  Instance& obj = Instance::Handle();
  obj ^= Api::UnwrapHandle(result);
  const Class& cls = Class::Handle(obj.clazz());
  // We expect the newly created "NativeFields" object to have
  // 2 dart instance fields (fld1, fld2) and kNumNativeFields native fields.
  // Hence the size of an instance of "NativeFields" should be
  // (kNumNativeFields + 2) * kWordSize + size of object header.
  // We check to make sure the instance size computed by the VM matches
  // our expectations.
  intptr_t header_size = sizeof(RawObject);
  EXPECT_EQ(Utils::RoundUp(((kNumNativeFields + 2) * kWordSize) + header_size,
                           kObjectAlignment),
            cls.instance_size());
}


TEST_CASE(InjectNativeFields2) {
  const char* kScriptChars =
      "class NativeFields extends NativeFieldsWrapper {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns an object of type NativeFields.
  result = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);

  // We expect this to fail as class "NativeFields" extends
  // "NativeFieldsWrapper" and there is no definition of it either
  // in the dart code or through the native field injection mechanism.
  EXPECT(Dart_IsError(result));
}


TEST_CASE(InjectNativeFields3) {
  const char* kScriptChars =
      "#import('dart:nativewrappers');"
      "class NativeFields extends NativeFieldWrapperClass2 {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  Dart_Handle result;
  const int kNumNativeFields = 2;

  // Load up a test script in the test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars,
                                             native_field_lookup);

  // Invoke a function which returns an object of type NativeFields.
  result = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  DARTSCOPE_NOCHECKS(Isolate::Current());
  Instance& obj = Instance::Handle();
  obj ^= Api::UnwrapHandle(result);
  const Class& cls = Class::Handle(obj.clazz());
  // We expect the newly created "NativeFields" object to have
  // 2 dart instance fields (fld1, fld2) and kNumNativeFields native fields.
  // Hence the size of an instance of "NativeFields" should be
  // (kNumNativeFields + 2) * kWordSize + size of object header.
  // We check to make sure the instance size computed by the VM matches
  // our expectations.
  intptr_t header_size = sizeof(RawObject);
  EXPECT_EQ(Utils::RoundUp(((kNumNativeFields + 2) * kWordSize) + header_size,
                           kObjectAlignment),
            cls.instance_size());
}


TEST_CASE(InjectNativeFields4) {
  const char* kScriptChars =
      "#import('dart:nativewrappers');"
      "class NativeFields extends NativeFieldWrapperClass2 {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  Dart_Handle result;
  // Load up a test script in the test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns an object of type NativeFields.
  result = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);

  // We expect the test script to fail finalization with the error below:
  EXPECT(Dart_IsError(result));
  Dart_Handle expected_error = Dart_Error(
      "'dart:test-lib': Error: line 1 pos 38: "
      "class 'NativeFields' is trying to extend a native fields class, "
      "but library '%s' has no native resolvers",
      TestCase::url());
  EXPECT_SUBSTRING(Dart_GetError(expected_error), Dart_GetError(result));
}


static void TestNativeFields(Dart_Handle retobj) {
  // Access and set various instance fields of the object.
  Dart_Handle result = Dart_GetField(retobj, Dart_NewString("fld3"));
  EXPECT(Dart_IsError(result));
  result = Dart_GetField(retobj, Dart_NewString("fld0"));
  EXPECT_VALID(result);
  EXPECT(Dart_IsNull(result));
  result = Dart_GetField(retobj, Dart_NewString("fld1"));
  EXPECT_VALID(result);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(10, value);
  result = Dart_GetField(retobj, Dart_NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(20, value);
  result = Dart_SetField(retobj,
                         Dart_NewString("fld2"),
                         Dart_NewInteger(40));
  EXPECT(Dart_IsError(result));
  result = Dart_SetField(retobj,
                         Dart_NewString("fld1"),
                         Dart_NewInteger(40));
  EXPECT_VALID(result);
  result = Dart_GetField(retobj, Dart_NewString("fld1"));
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
  result = Dart_GetField(retobj, Dart_NewString("fld1"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(40, value);
  result = Dart_GetField(retobj, Dart_NewString("fld2"));
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
      "  static final int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  const int kNumNativeFields = 4;

  // Create a test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars,
                                             native_field_lookup);

  // Create a native wrapper class with native fields.
  Dart_Handle result = Dart_CreateNativeWrapperClass(
      lib,
      Dart_NewString("NativeFieldsWrapper"),
      kNumNativeFields);
  EXPECT_VALID(result);

  // Load up a test script in it.

  // Invoke a function which returns an object of type NativeFields.
  Dart_Handle retobj = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
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
      "#import('dart:nativewrappers');"
      "class NativeFields extends NativeFieldWrapperClass4 {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld0;\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n";
  // Load up a test script in the test library.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars,
                                             native_field_lookup);

  // Invoke a function which returns an object of type NativeFields.
  Dart_Handle retobj = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
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
      "  static final int fld4 = 10;\n"
      "}\n"
      "NativeFields testMain1() {\n"
      "  NativeFields obj = new NativeFields(10, 20);\n"
      "  return obj;\n"
      "}\n"
      "Function testMain2() {\n"
      "  return function() {};\n"
      "}\n";
  Dart_Handle result;
  DARTSCOPE_NOCHECKS(Isolate::Current());

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns an object of type NativeFields.
  Dart_Handle retobj = Dart_Invoke(lib, Dart_NewString("testMain1"), 0, NULL);
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
  retobj = Dart_Invoke(lib, Dart_NewString("testMain2"), 0, NULL);
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


TEST_CASE(GetStaticField_RunsInitializer) {
  const char* kScriptChars =
      "class TestClass  {\n"
      "  static final int fld1 = 7;\n"
      "  static int fld2 = 11;\n"
      "  static void testMain() {\n"
      "  }\n"
      "}\n";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("TestClass"));
  EXPECT_VALID(cls);

  // Invoke a function which returns an object.
  result = Dart_Invoke(cls, Dart_NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);

  // For uninitialized fields, the getter is returned
  result = Dart_GetField(cls, Dart_NewString("fld1"));
  EXPECT_VALID(result);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(7, value);

  result = Dart_GetField(cls, Dart_NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(11, value);

  // Overwrite fld2
  result = Dart_SetField(cls,
                         Dart_NewString("fld2"),
                         Dart_NewInteger(13));
  EXPECT_VALID(result);

  // We now get the new value for fld2, not the initializer
  result = Dart_GetField(cls, Dart_NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(13, value);
}


TEST_CASE(New) {
  const char* kScriptChars =
      "class MyClass implements MyInterface {\n"
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
      "  factory MyInterface.multiply(value) {  // won't get called.\n"
      "    return new MyClass.named(value * 1000);\n"
      "  }\n"
      "  factory MyInterface2.unused(value) {\n"
      "    return new MyClass2(-value);\n"
      "  }\n"
      "  factory MyInterface2.multiply(value) {\n"
      "    return new MyClass2(value * 10000);\n"
      "  }\n"
      "  var foo;\n"
      "}\n"
      "\n"
      "class MyClass2 implements MyInterface2 {\n"
      "  MyClass2(value) : bar = value {}\n"
      "  var bar;\n"
      "}\n"
      "\n"
      "interface MyInterface default MyClass {\n"
      "  MyInterface.named(value);\n"
      "  MyInterface.multiply(value);\n"
      "  MyInterface.notfound(value);\n"
      "}\n"
      "\n"
      "interface MyInterface2 default MyClass {\n"
      "  MyInterface2.multiply(value);\n"
      "  MyInterface2.notfound(value);\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("MyClass"));
  EXPECT_VALID(cls);
  Dart_Handle cls2 = Dart_GetClass(lib, Dart_NewString("MyClass2"));
  EXPECT_VALID(cls2);
  Dart_Handle intf = Dart_GetClass(lib, Dart_NewString("MyInterface"));
  EXPECT_VALID(intf);
  Dart_Handle intf2 = Dart_GetClass(lib, Dart_NewString("MyInterface2"));
  EXPECT_VALID(intf2);
  Dart_Handle args[1];
  args[0] = Dart_NewInteger(11);
  Dart_Handle bad_args[1];
  bad_args[0] = Dart_Error("myerror");

  // Invoke the unnamed constructor.
  Dart_Handle result = Dart_New(cls, Dart_Null(), 0, NULL);
  EXPECT_VALID(result);
  bool instanceof = false;
  EXPECT_VALID(Dart_ObjectIsType(result, cls, &instanceof));
  EXPECT(instanceof);
  int64_t int_value = 0;
  Dart_Handle foo = Dart_GetField(result, Dart_NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(7, int_value);

  // Invoke the unnamed constructor with an empty string.
  result = Dart_New(cls, Dart_NewString(""), 0, NULL);
  EXPECT_VALID(result);
  instanceof = false;
  EXPECT_VALID(Dart_ObjectIsType(result, cls, &instanceof));
  EXPECT(instanceof);
  int_value = 0;
  foo = Dart_GetField(result, Dart_NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(7, int_value);

  // Invoke a named constructor.
  result = Dart_New(cls, Dart_NewString("named"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, cls, &instanceof));
  EXPECT(instanceof);
  int_value = 0;
  foo = Dart_GetField(result, Dart_NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(11, int_value);

  // Invoke a hidden named constructor.
  result = Dart_New(cls, Dart_NewString("_hidden"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, cls, &instanceof));
  EXPECT(instanceof);
  int_value = 0;
  foo = Dart_GetField(result, Dart_NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(-11, int_value);

  // Invoke a factory constructor.
  result = Dart_New(cls, Dart_NewString("multiply"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, cls, &instanceof));
  EXPECT(instanceof);
  int_value = 0;
  foo = Dart_GetField(result, Dart_NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(1100, int_value);

  // Invoke a factory constructor which returns null.
  result = Dart_New(cls, Dart_NewString("nullo"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsNull(result));

  // Pass an error class object.  Error is passed through.
  result = Dart_New(Dart_Error("myerror"), Dart_NewString("named"), 1, args);
  EXPECT_ERROR(result, "myerror");

  // Pass a bad class object.
  result = Dart_New(Dart_Null(), Dart_NewString("named"), 1, args);
  EXPECT_ERROR(result, "Dart_New expects argument 'clazz' to be non-null.");

  // Pass a negative arg count.
  result = Dart_New(cls, Dart_NewString("named"), -1, args);
  EXPECT_ERROR(
      result,
      "Dart_New expects argument 'number_of_arguments' to be non-negative.");

  // Pass the wrong arg count.
  result = Dart_New(cls, Dart_NewString("named"), 0, NULL);
  EXPECT_ERROR(
      result,
      "Dart_New: wrong argument count for constructor 'MyClass.named': "
      "expected 1 but saw 0.");

  // Pass a bad argument.  Error is passed through.
  result = Dart_New(cls, Dart_NewString("named"), 1, bad_args);
  EXPECT_ERROR(result, "myerror");

  // Pass a bad constructor name.
  result = Dart_New(cls, Dart_NewInteger(55), 1, args);
  EXPECT_ERROR(
      result,
      "Dart_New expects argument 'constructor_name' to be of type String.");

  // Invoke a missing constructor.
  result = Dart_New(cls, Dart_NewString("missing"), 1, args);
  EXPECT_ERROR(result,
               "Dart_New: could not find constructor 'MyClass.missing'.");

  // Invoke a constructor which throws an exception.
  result = Dart_New(cls, Dart_NewString("exception"), 1, args);
  EXPECT_ERROR(result, "ConstructorDeath");

  // MyInterface has default class MyClass.
  //
  // MyClass *implements* MyInterface.
  //
  // Therefore the constructor call:
  //
  //   MyInterface.foo()
  //
  // Becomes:
  //
  //   MyClass.foo() from the class MyClass.

  // Invoke an interface constructor.
  result = Dart_New(intf, Dart_NewString("named"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, cls, &instanceof));
  EXPECT(instanceof);
  int_value = 0;
  foo = Dart_GetField(result, Dart_NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(11, int_value);

  // Invoke an interface constructor which in turn calls a factory
  // constructor.
  result = Dart_New(intf, Dart_NewString("multiply"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, cls, &instanceof));
  EXPECT(instanceof);
  int_value = 0;
  foo = Dart_GetField(result, Dart_NewString("foo"));
  EXPECT_VALID(Dart_IntegerToInt64(foo, &int_value));
  EXPECT_EQ(1100, int_value);

  // Invoke a constructor that is missing in the interface but present
  // in the default class.
  result = Dart_New(intf, Dart_Null(), 0, NULL);
  EXPECT_ERROR(result,
               "Dart_New: could not find constructor 'MyInterface.'.");

  // Invoke a constructor that is present in the interface but missing
  // in the default class.
  result = Dart_New(intf, Dart_NewString("notfound"), 1, args);
  EXPECT_ERROR(result,
               "Dart_New: could not find constructor 'MyClass.notfound'.");

  // MyInterface2 has default class MyClass.
  //
  // MyClass *does not implement* MyInterface2.
  //
  // Therefore the constructor call:
  //
  //   new MyInterface2.foo()
  //
  // Becomes:
  //
  //   new MyInterface2.foo() from the class MyClass.

  // Invoke an interface constructor which in turn calls a factory
  // constructor.
  result = Dart_New(intf2, Dart_NewString("multiply"), 1, args);
  EXPECT_VALID(result);
  EXPECT_VALID(Dart_ObjectIsType(result, cls2, &instanceof));
  EXPECT(instanceof);
  int_value = 0;
  Dart_Handle bar = Dart_GetField(result, Dart_NewString("bar"));
  EXPECT_VALID(Dart_IntegerToInt64(bar, &int_value));
  EXPECT_EQ(110000, int_value);

  // Invoke a constructor that is missing in the interface but present
  // in the default class.
  result = Dart_New(intf2, Dart_NewString("unused"), 1, args);
  EXPECT_ERROR(result,
               "Dart_New: could not find constructor 'MyInterface2.unused'.");

  // Invoke a constructor that is present in the interface but missing
  // in the default class.
  result = Dart_New(intf2, Dart_NewString("notfound"), 1, args);
  EXPECT_ERROR(result,
               "Dart_New: could not find factory 'MyInterface2.notfound' "
               "in class 'MyClass'.");
}


TEST_CASE(New_Issue2971) {
  // Issue 2971: We were unable to use Dart_New to construct an
  // instance of List, due to problems implementing interface
  // factories.
  Dart_Handle core_lib = Dart_LookupLibrary(Dart_NewString("dart:core"));
  EXPECT_VALID(core_lib);
  Dart_Handle list_class = Dart_GetClass(core_lib, Dart_NewString("List"));
  EXPECT_VALID(list_class);

  const int kNumArgs = 1;
  Dart_Handle args[kNumArgs];
  args[0] = Dart_NewInteger(1);
  Dart_Handle list_obj = Dart_New(list_class, Dart_Null(), kNumArgs, args);
  EXPECT_VALID(list_obj);
  EXPECT(Dart_IsList(list_obj));
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
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("Methods"));
  EXPECT_VALID(cls);
  Dart_Handle instance = Dart_Invoke(lib, Dart_NewString("test"), 0, NULL);
  EXPECT_VALID(instance);
  Dart_Handle args[1];
  args[0] = Dart_NewString("!!!");
  Dart_Handle bad_args[2];
  bad_args[0] = Dart_NewString("bad1");
  bad_args[1] = Dart_NewString("bad2");
  Dart_Handle result;
  Dart_Handle name;
  const char* str;

  // Instance method.
  name = Dart_NewString("instanceMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(cls, name, 1, args)));
  result = Dart_Invoke(instance, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("instance !!!", str);

  // Instance method, wrong arg count.
  EXPECT_ERROR(Dart_Invoke(instance, name, 2, bad_args),
               "did not find instance method 'Methods.instanceMethod'");

  // Hidden instance method.
  name = Dart_NewString("_instanceMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(cls, name, 1, args)));
  result = Dart_Invoke(instance, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("hidden instance !!!", str);

  // Inherited method.
  name = Dart_NewString("inheritedMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(cls, name, 1, args)));
  result = Dart_Invoke(instance, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("inherited !!!", str);

  // Static method.
  name = Dart_NewString("staticMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  result = Dart_Invoke(cls, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("static !!!", str);

  // Static method, wrong arg count.
  EXPECT_ERROR(Dart_Invoke(cls, name, 2, bad_args),
               "did not find static method 'Methods.staticMethod'");

  // Hidden static method.
  name = Dart_NewString("_staticMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  result = Dart_Invoke(cls, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("hidden static !!!", str);

  // Static non-inherited method.  Not found at any level.
  name = Dart_NewString("non_inheritedMethod");
  EXPECT(Dart_IsError(Dart_Invoke(lib, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(cls, name, 1, args)));

  // Top-Level method.
  name = Dart_NewString("topMethod");
  EXPECT(Dart_IsError(Dart_Invoke(cls, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  result = Dart_Invoke(lib, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("top !!!", str);

  // Top-level method, wrong arg count.
  EXPECT_ERROR(Dart_Invoke(lib, name, 2, bad_args),
               "did not find top-level function 'topMethod'");

  // Hidden top-level method.
  name = Dart_NewString("_topMethod");
  EXPECT(Dart_IsError(Dart_Invoke(cls, name, 1, args)));
  EXPECT(Dart_IsError(Dart_Invoke(instance, name, 1, args)));
  result = Dart_Invoke(lib, name, 1, args);
  EXPECT_VALID(result);
  result = Dart_StringToCString(result, &str);
  EXPECT_STREQ("hidden top !!!", str);
}


TEST_CASE(Invoke_FunnyArgs) {
  const char* kScriptChars =
      "test(arg) => 'hello $arg';\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle func_name = Dart_NewString("test");
  Dart_Handle args[1];
  const char* str;

  // Make sure that valid args yield valid results.
  args[0] = Dart_NewString("!!!");
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
  result = Dart_Invoke(Api::NewError("myerror"),
                       func_name, 1, args);
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
  Dart_Handle result = Dart_Invoke(Dart_Null(),
                                   Dart_NewString("toString"),
                                   0,
                                   NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));

  const char* value = "";
  EXPECT_VALID(Dart_StringToCString(result, &value));
  EXPECT_STREQ("null", value);

  // Should throw a NullPointerException. Disabled due to bug 5415268.
  /*
    Dart_Handle function_name2 = Dart_NewString("NoNoNo");
    result = Dart_Invoke(null_receiver,
    function_name2,
    number_of_arguments,
    dart_arguments);
    EXPECT(Dart_IsError(result));
    EXPECT(Dart_ErrorHasException(result)); */
}


TEST_CASE(Invoke_CrossLibrary) {
  const char* kLibrary1Chars =
      "#library('library1_name');\n"
      "void local() {}\n"
      "void _local() {}\n";
  const char* kLibrary2Chars =
      "#library('library2_name');\n"
      "void imported() {}\n"
      "void _imported() {}\n";

  // Load lib1
  Dart_Handle url = Dart_NewString("library1_url");
  Dart_Handle source = Dart_NewString(kLibrary1Chars);
  Dart_Handle lib1 = Dart_LoadLibrary(url, source);
  EXPECT_VALID(lib1);

  // Load lib2
  url = Dart_NewString("library2_url");
  source = Dart_NewString(kLibrary2Chars);
  Dart_Handle lib2 = Dart_LoadLibrary(url, source);
  EXPECT_VALID(lib2);

  // Import lib2 from lib1
  Dart_Handle result = Dart_LibraryImportLibrary(lib1, lib2);
  EXPECT_VALID(result);

  // We can invoke both private and non-private local functions.
  EXPECT_VALID(Dart_Invoke(lib1, Dart_NewString("local"), 0, NULL));
  EXPECT_VALID(Dart_Invoke(lib1, Dart_NewString("_local"), 0, NULL));

  // We can only invoke non-private imported functions.
  EXPECT_VALID(Dart_Invoke(lib1, Dart_NewString("imported"), 0, NULL));
  EXPECT_ERROR(Dart_Invoke(lib1, Dart_NewString("_imported"), 0, NULL),
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
      "  static final int fld4 = 10;\n"
      "}\n"
      "Function testMain1() {\n"
      "  InvokeClosure obj = new InvokeClosure(10, 20);\n"
      "  return obj.method1(10);\n"
      "}\n"
      "Function testMain2() {\n"
      "  return InvokeClosure.method2(10);\n"
      "}\n";
  Dart_Handle result;
  DARTSCOPE_NOCHECKS(Isolate::Current());

  // Create a test library and Load up a test script in it.
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Invoke a function which returns a closure.
  Dart_Handle retobj = Dart_Invoke(lib, Dart_NewString("testMain1"), 0, NULL);
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
  retobj = Dart_Invoke(lib, Dart_NewString("testMain2"), 0, NULL);
  EXPECT_VALID(retobj);

  EXPECT(Dart_IsClosure(retobj));
  EXPECT(!Dart_IsClosure(Dart_NewString("abcdef")));

  // Now invoke the closure and check the result (should be an exception).
  dart_arguments[0] = Dart_NewInteger(1);
  result = Dart_InvokeClosure(retobj, 1, dart_arguments);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
}


void ExceptionNative(Dart_NativeArguments args) {
  Dart_Handle param = Dart_GetNativeArgument(args, 0);
  Dart_EnterScope();  // Start a Dart API scope for invoking API functions.
  Dart_ThrowException(param);
  UNREACHABLE();
}


static Dart_NativeFunction native_lookup(Dart_Handle name, int argument_count) {
  return reinterpret_cast<Dart_NativeFunction>(&ExceptionNative);
}


TEST_CASE(ThrowException) {
  const char* kScriptChars =
      "class ThrowException {\n"
      "  ThrowException(int i) : fld1 = i {}\n"
      "  int method1(int i) native \"ThrowException_native\";"
      "  int method2() {\n"
      "     try { method1(10); } catch(var a) { return 5; } return 10;\n"
      "  }\n"
      "  int fld1;\n"
      "}\n"
      "ThrowException testMain() {\n"
      "  ThrowException obj = new ThrowException(10);\n"
      "  return obj;\n"
      "}\n";
  Dart_Handle result;
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  intptr_t size = state->ZoneSizeInBytes();
  Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

  // Load up a test script which extends the native wrapper class.
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars,
      reinterpret_cast<Dart_NativeEntryResolver>(native_lookup));

  // Invoke a function which returns an object of type ThrowException.
  Dart_Handle retobj = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
  EXPECT_VALID(retobj);

  // Throwing an exception here should result in an error.
  result = Dart_ThrowException(retobj);
  EXPECT(Dart_IsError(result));

  // Now invoke method2 which invokes a natve method where it is
  // ok to throw an exception, check the result which would indicate
  // if an exception was thrown or not.
  result = Dart_Invoke(retobj, Dart_NewString("method2"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_EQ(5, value);

  Dart_ExitScope();  // Exit the Dart API scope.
  EXPECT_EQ(size, state->ZoneSizeInBytes());
}


void NativeArgumentCounter(Dart_NativeArguments args) {
  Dart_EnterScope();
  int count = Dart_GetNativeArgumentCount(args);
  Dart_SetReturnValue(args, Dart_NewInteger(count));
  Dart_ExitScope();
}


static Dart_NativeFunction gnac_lookup(Dart_Handle name, int argument_count) {
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
      kScriptChars,
      reinterpret_cast<Dart_NativeEntryResolver>(gnac_lookup));

  Dart_Handle result = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));

  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(3, value);
}


TEST_CASE(GetClass) {
  const char* kScriptChars =
      "class Class {\n"
      "  static var name = 'Class';\n"
      "}\n"
      "\n"
      "class _Class {\n"
      "  static var name = '_Class';\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Lookup a class.
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("Class"));
  EXPECT_VALID(cls);
  Dart_Handle name = Dart_GetField(cls, Dart_NewString("name"));
  EXPECT_VALID(name);
  const char* name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(name, &name_cstr));
  EXPECT_STREQ("Class", name_cstr);

  // Lookup a private class.
  cls = Dart_GetClass(lib, Dart_NewString("_Class"));
  EXPECT_VALID(cls);
  name = Dart_GetField(cls, Dart_NewString("name"));
  EXPECT_VALID(name);
  name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(name, &name_cstr));
  EXPECT_STREQ("_Class", name_cstr);

  // Lookup a class that does not exist.
  cls = Dart_GetClass(lib, Dart_NewString("DoesNotExist"));
  EXPECT(Dart_IsError(cls));
  EXPECT_STREQ("Class 'DoesNotExist' not found in library 'dart:test-lib'.",
               Dart_GetError(cls));

  // Lookup a class from an error library.  The error propagates.
  cls = Dart_GetClass(Api::NewError("myerror"), Dart_NewString("Class"));
  EXPECT(Dart_IsError(cls));
  EXPECT_STREQ("myerror", Dart_GetError(cls));

  // Lookup a class using an error class name.  The error propagates.
  cls = Dart_GetClass(lib, Api::NewError("myerror"));
  EXPECT(Dart_IsError(cls));
  EXPECT_STREQ("myerror", Dart_GetError(cls));
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
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("InstanceOfTest"));
  EXPECT_VALID(cls);

  // Invoke a function which returns an object of type InstanceOf..
  Dart_Handle instanceOfTestObj =
      Dart_Invoke(cls, Dart_NewString("testMain"), 0, NULL);
  EXPECT_VALID(instanceOfTestObj);

  // Now check instanceOfTestObj reported as an instance of
  // InstanceOfTest class.
  bool is_instance = false;
  result = Dart_ObjectIsType(instanceOfTestObj, cls, &is_instance);
  EXPECT_VALID(result);
  EXPECT(is_instance);

  // Fetch OtherClass and check if instanceOfTestObj is instance of it.
  Dart_Handle otherClass = Dart_GetClass(lib, Dart_NewString("OtherClass"));
  EXPECT_VALID(otherClass);

  result = Dart_ObjectIsType(instanceOfTestObj, otherClass, &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  // Check that primitives are not instances of InstanceOfTest class.
  result = Dart_ObjectIsType(Dart_NewString("a string"), otherClass,
                             &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  result = Dart_ObjectIsType(Dart_NewInteger(42), otherClass, &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  result = Dart_ObjectIsType(Dart_NewBoolean(true), otherClass, &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  // Check that null is not an instance of InstanceOfTest class.
  Dart_Handle null = Dart_Invoke(otherClass,
                                 Dart_NewString("returnNull"),
                                 0,
                                 NULL);
  EXPECT_VALID(null);

  result = Dart_ObjectIsType(null, otherClass, &is_instance);
  EXPECT_VALID(result);
  EXPECT(!is_instance);

  // Check that error is returned if null is passed as a class argument.
  result = Dart_ObjectIsType(null, null, &is_instance);
  EXPECT(Dart_IsError(result));
}


static Dart_Handle library_handler(Dart_LibraryTag tag,
                                   Dart_Handle library,
                                   Dart_Handle url) {
  if (tag == kCanonicalizeUrl) {
    return url;
  }
  return Api::Success(Isolate::Current());
}


TEST_CASE(LoadScript) {
  const char* kScriptChars =
      "main() {"
      "  return 12345;"
      "}";
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  Dart_Handle error = Dart_Error("incoming error");
  Dart_Handle result;

  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);

  result = Dart_LoadScript(Dart_Null(), source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript expects argument 'url' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadScript(Dart_True(), source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript expects argument 'url' to be of type String.",
               Dart_GetError(result));

  result = Dart_LoadScript(error, source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadScript(url, Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript expects argument 'source' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadScript(url, Dart_True());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadScript expects argument 'source' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadScript(url, error);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  // Load a script successfully.
  result = Dart_LoadScript(url, source);
  EXPECT_VALID(result);

  result = Dart_Invoke(result, Dart_NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(12345, value);

  // Further calls to LoadScript are errors.
  result = Dart_LoadScript(url, source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript: "
               "A script has already been loaded from 'dart:test-lib'.",
               Dart_GetError(result));
}


TEST_CASE(RootLibrary) {
  const char* kScriptChars =
      "main() {"
      "  return 12345;"
      "}";

  Dart_Handle root_lib = Dart_RootLibrary();
  EXPECT_VALID(root_lib);
  EXPECT(Dart_IsNull(root_lib));

  // Load a script.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  EXPECT_VALID(Dart_LoadScript(url, source));

  root_lib = Dart_RootLibrary();
  Dart_Handle lib_name = Dart_LibraryName(root_lib);
  EXPECT_VALID(lib_name);
  EXPECT(!Dart_IsNull(root_lib));
  const char* name_cstr = "";
  EXPECT_VALID(Dart_StringToCString(lib_name, &name_cstr));
  EXPECT_STREQ(TestCase::url(), name_cstr);
}


static const char* var_mapping[] = {
  "GOOGLE3", ".",
  "ABC", "lala",
  "var1", "",
  "var2", "winner",
};
static int index = 0;


static Dart_Handle import_library_handler(Dart_LibraryTag tag,
                                          Dart_Handle library,
                                          Dart_Handle url) {
  if (tag == kCanonicalizeUrl) {
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
  return Api::Success(Isolate::Current());
}


TEST_CASE(LoadImportScript) {
  const char* kScriptChars =
      "#import('$GOOGLE3/weird.dart');"
      "#import('abc${ABC}def');"
      "#import('${var1}$var2');"
      "#import('abc${ABC}def/extra_weird.dart');"
      "#import('$var2$var2');"
      "main() {"
      "  return 12345;"
      "}";
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  intptr_t length = (sizeof(var_mapping) / sizeof(var_mapping[0]));
  Dart_Handle import_map = Dart_NewList(length);
  for (intptr_t i = 0; i < length; i++) {
    Dart_ListSetAt(import_map, i, Dart_NewString(var_mapping[i]));
  }
  Dart_Handle result = Dart_SetLibraryTagHandler(import_library_handler);
  EXPECT_VALID(result);
  result = Dart_SetImportMap(import_map);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);
  EXPECT(!Dart_IsError(result));
}


TEST_CASE(LoadImportScriptError1) {
  const char* kScriptChars =
      "#import('abc${DEF}def/extra_weird.dart');"
      "main() {"
      "  return 12345;"
      "}";
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  Dart_Handle result = Dart_SetLibraryTagHandler(import_library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);
  EXPECT(Dart_IsError(result));
  EXPECT(strstr(Dart_GetError(result),
                "import variable 'DEF' has not been defined"));
}


TEST_CASE(LoadImportScriptError2) {
  const char* kScriptChars =
      "#import('abc${ABC/extra_weird.dart');"
      "main() {"
      "  return 12345;"
      "}";
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  intptr_t length = (sizeof(var_mapping) / sizeof(var_mapping[0]));
  Dart_Handle import_map = Dart_NewList(length);
  for (intptr_t i = 0; i < length; i++) {
    Dart_ListSetAt(import_map, i, Dart_NewString(var_mapping[i]));
  }
  Dart_Handle result = Dart_SetLibraryTagHandler(import_library_handler);
  EXPECT_VALID(result);
  result = Dart_SetImportMap(import_map);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);
  EXPECT(Dart_IsError(result));
  EXPECT(strstr(Dart_GetError(result), "'}' expected"));
}


TEST_CASE(LoadScript_CompileError) {
  const char* kScriptChars =
      ")";
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  Dart_Handle result = Dart_SetLibraryTagHandler(import_library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);
  EXPECT(Dart_IsError(result));
  EXPECT(strstr(Dart_GetError(result), "unexpected token ')'"));
}


TEST_CASE(LookupLibrary) {
  const char* kScriptChars =
      "#import('library1.dart');"
      "main() {}";
  const char* kLibrary1Chars =
      "#library('library1.dart');"
      "#import('library2.dart');";

  // Create a test library and Load up a test script in it.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  Dart_Handle result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);
  EXPECT_VALID(result);

  url = Dart_NewString("library1.dart");
  source = Dart_NewString(kLibrary1Chars);
  result = Dart_LoadLibrary(url, source);
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

  result = Dart_LookupLibrary(Dart_Error("incoming error"));
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  url = Dart_NewString("noodles.dart");
  result = Dart_LookupLibrary(url);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LookupLibrary: library 'noodles.dart' not found.",
               Dart_GetError(result));
}


TEST_CASE(LibraryName) {
  const char* kLibrary1Chars =
      "#library('library1_name');";
  Dart_Handle url = Dart_NewString("library1_url");
  Dart_Handle source = Dart_NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, source);
  Dart_Handle error = Dart_Error("incoming error");
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


TEST_CASE(LibraryUrl) {
  const char* kLibrary1Chars =
      "#library('library1_name');";
  Dart_Handle url = Dart_NewString("library1_url");
  Dart_Handle source = Dart_NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, source);
  Dart_Handle error = Dart_Error("incoming error");
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
      "#library('library_name');\n"
      "\n"
      "class A {}\n"
      "class B {}\n"
      "class D {}\n"
      "interface C {}\n"
      "interface E {}\n"
      "\n"
      "_compare(String a, String b) => a.compareTo(b);\n"
      "sort(list) => list.sort(_compare);\n";

  Dart_Handle url = Dart_NewString("library_url");
  Dart_Handle source = Dart_NewString(kLibraryChars);
  Dart_Handle lib = Dart_LoadLibrary(url, source);
  EXPECT_VALID(lib);

  Dart_Handle list = Dart_LibraryGetClassNames(lib);
  EXPECT_VALID(list);
  EXPECT(Dart_IsList(list));

  // Sort the list.
  const int kNumArgs = 1;
  Dart_Handle args[1];
  args[0] = list;
  EXPECT_VALID(Dart_Invoke(lib, Dart_NewString("sort"), kNumArgs, args));

  Dart_Handle list_string = Dart_ToString(list);
  EXPECT_VALID(list_string);
  const char* list_cstr = "";
  EXPECT_VALID(Dart_StringToCString(list_string, &list_cstr));
  EXPECT_STREQ("[A, B, C, D, E]", list_cstr);
}


TEST_CASE(LibraryImportLibrary) {
  const char* kLibrary1Chars =
      "#library('library1_name');";
  const char* kLibrary2Chars =
      "#library('library2_name');";
  Dart_Handle error = Dart_Error("incoming error");
  Dart_Handle result;

  Dart_Handle url = Dart_NewString("library1_url");
  Dart_Handle source = Dart_NewString(kLibrary1Chars);
  Dart_Handle lib1 = Dart_LoadLibrary(url, source);
  EXPECT_VALID(lib1);

  url = Dart_NewString("library2_url");
  source = Dart_NewString(kLibrary2Chars);
  Dart_Handle lib2 = Dart_LoadLibrary(url, source);
  EXPECT_VALID(lib2);

  result = Dart_LibraryImportLibrary(Dart_Null(), lib2);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LibraryImportLibrary expects argument 'library' to be non-null.",
      Dart_GetError(result));

  result = Dart_LibraryImportLibrary(Dart_True(), lib2);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LibraryImportLibrary expects argument 'library' to be of "
               "type Library.",
               Dart_GetError(result));

  result = Dart_LibraryImportLibrary(error, lib2);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LibraryImportLibrary(lib1, Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LibraryImportLibrary expects argument 'import' to be non-null.",
      Dart_GetError(result));

  result = Dart_LibraryImportLibrary(lib1, Dart_True());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LibraryImportLibrary expects argument 'import' to be of "
               "type Library.",
               Dart_GetError(result));

  result = Dart_LibraryImportLibrary(lib1, error);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LibraryImportLibrary(lib1, lib2);
  EXPECT_VALID(result);
}



TEST_CASE(LoadLibrary) {
  const char* kLibrary1Chars =
      "#library('library1_name');";
  Dart_Handle error = Dart_Error("incoming error");
  Dart_Handle result;

  Dart_Handle url = Dart_NewString("library1_url");
  Dart_Handle source = Dart_NewString(kLibrary1Chars);

  result = Dart_LoadLibrary(Dart_Null(), source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadLibrary expects argument 'url' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadLibrary(Dart_True(), source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadLibrary expects argument 'url' to be of type String.",
               Dart_GetError(result));

  result = Dart_LoadLibrary(error, source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadLibrary(url, Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadLibrary expects argument 'source' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadLibrary(url, Dart_True());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadLibrary expects argument 'source' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadLibrary(url, error);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  // Success.
  result = Dart_LoadLibrary(url, source);
  EXPECT_VALID(result);
  EXPECT(Dart_IsLibrary(result));

  // Duplicate library load fails.
  result = Dart_LoadLibrary(url, source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadLibrary: library 'library1_url' has already been loaded.",
      Dart_GetError(result));
}


TEST_CASE(LoadLibrary_CompileError) {
  const char* kLibrary1Chars =
      "#library('library1_name');"
      ")";
  Dart_Handle url = Dart_NewString("library1_url");
  Dart_Handle source = Dart_NewString(kLibrary1Chars);
  Dart_Handle result = Dart_LoadLibrary(url, source);
  EXPECT(Dart_IsError(result));
  EXPECT(strstr(Dart_GetError(result), "unexpected token ')'"));
}


TEST_CASE(LoadSource) {
  const char* kLibrary1Chars =
      "#library('library1_name');";
  const char* kSourceChars =
      "// Something innocuous";
  const char* kBadSourceChars =
      ")";
  Dart_Handle error = Dart_Error("incoming error");
  Dart_Handle result;

  // Load up a library.
  Dart_Handle url = Dart_NewString("library1_url");
  Dart_Handle source = Dart_NewString(kLibrary1Chars);
  Dart_Handle lib = Dart_LoadLibrary(url, source);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));

  url = Dart_NewString("source_url");
  source = Dart_NewString(kSourceChars);

  result = Dart_LoadSource(Dart_Null(), url, source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadSource expects argument 'library' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadSource(Dart_True(), url, source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadSource expects argument 'library' to be of type Library.",
      Dart_GetError(result));

  result = Dart_LoadSource(error, url, source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadSource(lib, Dart_Null(), source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadSource expects argument 'url' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadSource(lib, Dart_True(), source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadSource expects argument 'url' to be of type String.",
               Dart_GetError(result));

  result = Dart_LoadSource(lib, error, source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadSource(lib, url, Dart_Null());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadSource expects argument 'source' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadSource(lib, url, Dart_True());
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadSource expects argument 'source' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadSource(lib, error, source);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  // Success.
  result = Dart_LoadSource(lib, url, source);
  EXPECT_VALID(result);
  EXPECT(Dart_IsLibrary(result));
  EXPECT(Dart_IdentityEquals(lib, result));

  // Duplicate calls are okay.
  result = Dart_LoadSource(lib, url, source);
  EXPECT_VALID(result);
  EXPECT(Dart_IsLibrary(result));
  EXPECT(Dart_IdentityEquals(lib, result));

  // Language errors are detected.
  source = Dart_NewString(kBadSourceChars);
  result = Dart_LoadSource(lib, url, source);
  EXPECT(Dart_IsError(result));
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
                                             int arg_count) {
  return &MyNativeFunction1;
}


static Dart_NativeFunction MyNativeResolver2(Dart_Handle name,
                                             int arg_count) {
  return &MyNativeFunction2;
}


TEST_CASE(SetNativeResolver) {
  const char* kScriptChars =
      "class Test {"
      "  static foo() native \"SomeNativeFunction\";"
      "  static bar() native \"SomeNativeFunction2\";"
      "  static baz() native \"SomeNativeFunction3\";"
      "}";
  Dart_Handle error = Dart_Error("incoming error");
  Dart_Handle result;

  // Load a test script.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, source);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("Test"));
  EXPECT_VALID(cls);

  result = Dart_SetNativeResolver(Dart_Null(), &MyNativeResolver1);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_SetNativeResolver expects argument 'library' to be non-null.",
      Dart_GetError(result));

  result = Dart_SetNativeResolver(Dart_True(), &MyNativeResolver1);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_SetNativeResolver expects argument 'library' to be of "
               "type Library.",
               Dart_GetError(result));

  result = Dart_SetNativeResolver(error, &MyNativeResolver1);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_SetNativeResolver(lib, &MyNativeResolver1);
  EXPECT_VALID(result);

  // Call a function and make sure native resolution works.
  result = Dart_Invoke(cls, Dart_NewString("foo"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(654321, value);

  // A second call succeeds.
  result = Dart_SetNativeResolver(lib, &MyNativeResolver2);
  EXPECT_VALID(result);

  // 'foo' has already been resolved so gets the old value.
  result = Dart_Invoke(cls, Dart_NewString("foo"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(654321, value);

  // 'bar' has not yet been resolved so gets the new value.
  result = Dart_Invoke(cls, Dart_NewString("bar"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(123456, value);

  // A NULL resolver is okay, but resolution will fail.
  result = Dart_SetNativeResolver(lib, NULL);
  EXPECT_VALID(result);

  EXPECT_ERROR(Dart_Invoke(cls, Dart_NewString("baz"), 0, NULL),
               "native function 'SomeNativeFunction3' cannot be found");
}


TEST_CASE(ImportLibrary1) {
  const char* kScriptChars =
      "#import('library1.dart');"
      "#import('library2.dart');"
      "var foo;  // library2 defines foo, so should be error."
      "main() {}";
  const char* kLibrary1Chars =
      "#library('library1.dart');"
      "#import('library2.dart');"
      "var foo1;";
  const char* kLibrary2Chars =
      "#library('library2.dart');"
      "var foo;";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);

  url = Dart_NewString("library1.dart");
  source = Dart_NewString(kLibrary1Chars);
  Dart_LoadLibrary(url, source);

  url = Dart_NewString("library2.dart");
  source = Dart_NewString(kLibrary2Chars);
  Dart_LoadLibrary(url, source);

  result = Dart_Invoke(result, Dart_NewString("main"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Duplicate definition : 'foo' is defined in"
               " 'library2.dart' and 'dart:test-lib'",
               Dart_GetError(result));
}


TEST_CASE(ImportLibrary2) {
  const char* kScriptChars =
      "#import('library1.dart');"
      "var foo;"
      "main() {}";
  const char* kLibrary1Chars =
      "#library('library1.dart');"
      "#import('library2.dart');"
      "var foo1;";
  const char* kLibrary2Chars =
      "#library('library2.dart');"
      "#import('library1.dart');"
      "var foo;";
  Dart_Handle result;
  // Create a test library and Load up a test script in it.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);

  url = Dart_NewString("library1.dart");
  source = Dart_NewString(kLibrary1Chars);
  Dart_LoadLibrary(url, source);

  url = Dart_NewString("library2.dart");
  source = Dart_NewString(kLibrary2Chars);
  Dart_LoadLibrary(url, source);

  result = Dart_Invoke(result, Dart_NewString("main"), 0, NULL);
  EXPECT_VALID(result);
}


TEST_CASE(ImportLibrary3) {
  const char* kScriptChars =
      "#import('library2.dart');"
      "#import('library1.dart');"
      "var foo_top = 10;  // foo has dup def. So should be an error."
      "main() {}";
  const char* kLibrary1Chars =
      "#library('library1.dart');"
      "var foo;";
  const char* kLibrary2Chars =
      "#library('library2.dart');"
      "var foo;";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);

  url = Dart_NewString("library2.dart");
  source = Dart_NewString(kLibrary2Chars);
  Dart_LoadLibrary(url, source);

  url = Dart_NewString("library1.dart");
  source = Dart_NewString(kLibrary1Chars);
  Dart_LoadLibrary(url, source);

  result = Dart_Invoke(result, Dart_NewString("main"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Duplicate definition : 'foo' is defined in"
               " 'library2.dart' and 'library1.dart'",
               Dart_GetError(result));
}


TEST_CASE(ImportLibrary4) {
  const char* kScriptChars =
      "#import('libraryA.dart');"
      "#import('libraryB.dart');"
      "#import('libraryD.dart');"
      "#import('libraryE.dart');"
      "var fooApp;"
      "main() {}";
  const char* kLibraryAChars =
      "#library('libraryA.dart');"
      "#import('libraryC.dart');"
      "var fooA;";
  const char* kLibraryBChars =
      "#library('libraryB.dart');"
      "#import('libraryC.dart');"
      "var fooB;";
  const char* kLibraryCChars =
      "#library('libraryC.dart');"
      "var fooC;";
  const char* kLibraryDChars =
      "#library('libraryD.dart');"
      "#import('libraryF.dart');"
      "var fooD;";
  const char* kLibraryEChars =
      "#library('libraryE.dart');"
      "#import('libraryC.dart');"
      "#import('libraryF.dart');"
      "var fooE = 10;  //fooC has duplicate def. so should be an error.";
  const char* kLibraryFChars =
      "#library('libraryF.dart');"
      "var fooC;";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);

  url = Dart_NewString("libraryA.dart");
  source = Dart_NewString(kLibraryAChars);
  Dart_LoadLibrary(url, source);

  url = Dart_NewString("libraryC.dart");
  source = Dart_NewString(kLibraryCChars);
  Dart_LoadLibrary(url, source);

  url = Dart_NewString("libraryB.dart");
  source = Dart_NewString(kLibraryBChars);
  Dart_LoadLibrary(url, source);

  url = Dart_NewString("libraryD.dart");
  source = Dart_NewString(kLibraryDChars);
  Dart_LoadLibrary(url, source);

  url = Dart_NewString("libraryF.dart");
  source = Dart_NewString(kLibraryFChars);
  Dart_LoadLibrary(url, source);

  url = Dart_NewString("libraryE.dart");
  source = Dart_NewString(kLibraryEChars);
  Dart_LoadLibrary(url, source);

  result = Dart_Invoke(result, Dart_NewString("main"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Duplicate definition : 'fooC' is defined in"
               " 'libraryC.dart' and 'libraryF.dart'",
               Dart_GetError(result));
}


TEST_CASE(ImportLibrary5) {
  const char* kScriptChars =
      "#import('lib.dart');"
      "interface Y {"
      "  void set handler(void callback(List<int> x));"
      "}"
      "void main() {}";
  const char* kLibraryChars =
      "#library('lib.dart');"
      "interface X {"
      "  void set handler(void callback(List<int> x));"
      "}";
  Dart_Handle result;

  // Create a test library and Load up a test script in it.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  result = Dart_LoadScript(url, source);

  url = Dart_NewString("lib.dart");
  source = Dart_NewString(kLibraryChars);
  Dart_LoadLibrary(url, source);

  result = Dart_Invoke(result, Dart_NewString("main"), 0, NULL);
  EXPECT_VALID(result);
}


void NewNativePort_send123(Dart_Port dest_port_id,
                           Dart_Port reply_port_id,
                           Dart_CObject *message) {
  // Gets a null message.
  EXPECT_NOTNULL(message);
  EXPECT_EQ(Dart_CObject::kNull, message->type);

  // Post integer value.
  Dart_CObject* response =
      reinterpret_cast<Dart_CObject*>(Dart_ScopeAllocate(sizeof(Dart_CObject)));
  response->type = Dart_CObject::kInt32;
  response->value.as_int32 = 123;
  Dart_PostCObject(reply_port_id, response);
}


void NewNativePort_send321(Dart_Port dest_port_id,
                           Dart_Port reply_port_id,
                           Dart_CObject* message) {
  // Gets a null message.
  EXPECT_NOTNULL(message);
  EXPECT_EQ(Dart_CObject::kNull, message->type);

  // Post integer value.
  Dart_CObject* response =
      reinterpret_cast<Dart_CObject*>(Dart_ScopeAllocate(sizeof(Dart_CObject)));
  response->type = Dart_CObject::kInt32;
  response->value.as_int32 = 321;
  Dart_PostCObject(reply_port_id, response);
}


UNIT_TEST_CASE(NewNativePort) {
  // Create a port with a bogus handler.
  Dart_Port error_port = Dart_NewNativePort("Foo", NULL, true);
  EXPECT_EQ(kIllegalPort, error_port);

  // Create the port w/o a current isolate, just to make sure that works.
  Dart_Port port_id1 =
      Dart_NewNativePort("Port123", NewNativePort_send123, true);

  TestIsolateScope __test_isolate__;
  const char* kScriptChars =
      "#import('dart:isolate');\n"
      "void callPort(SendPort port) {\n"
      "    port.call(null).then((message) {\n"
      "      throw new Exception(message);\n"
      "    });\n"
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
  Dart_Handle result =
      Dart_Invoke(lib, Dart_NewString("callPort"), 1, dart_args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Exception: 123\n", Dart_GetError(result));

  // result second port.
  dart_args[0] = send_port2;
  result = Dart_Invoke(lib, Dart_NewString("callPort"), 1, dart_args);
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


static bool RunLoopTestCallback(const char* script_name,
                                const char* main,
                                void* data,
                                char** error) {
  const char* kScriptChars =
      "#import('builtin');\n"
      "#import('dart:isolate');\n"
      "class MyIsolate extends Isolate {\n"
      "  MyIsolate() : super() { }\n"
      "  void main() {\n"
      "    port.receive((message, replyTo) {\n"
      "      if (message) {\n"
      "        throw new Exception('MakeChildExit');\n"
      "      } else {\n"
      "        replyTo.call('hello');\n"
      "        port.close();\n"
      "      }\n"
      "    });\n"
      "  }\n"
      "}\n"
      "\n"
      "void main(exc_child, exc_parent) {\n"
      "  new MyIsolate().spawn().then((port) {\n"
      "    port.call(exc_child).then((message) {\n"
      "      if (message != 'hello') throw new Exception('ShouldNotHappen');\n"
      "      if (exc_parent) throw new Exception('MakeParentExit');\n"
      "    });\n"
      "  });\n"
      "}\n";

  if (Dart_CurrentIsolate() != NULL) {
    Dart_ExitIsolate();
  }
  Dart_Isolate isolate = TestCase::CreateTestIsolate();
  ASSERT(isolate != NULL);
  Dart_EnterScope();
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  Dart_Handle result = Dart_SetLibraryTagHandler(TestCase::library_handler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, source);
  EXPECT_VALID(lib);
  Dart_ExitScope();
  return true;
}


// Common code for RunLoop_Success/RunLoop_Failure.
static void RunLoopTest(bool throw_exception_child,
                        bool throw_exception_parent) {
  Dart_IsolateCreateCallback saved = Isolate::CreateCallback();
  Isolate::SetCreateCallback(RunLoopTestCallback);
  RunLoopTestCallback(NULL, NULL, NULL, NULL);

  Dart_EnterScope();
  Dart_Handle lib = Dart_LookupLibrary(Dart_NewString(TestCase::url()));
  EXPECT_VALID(lib);

  Dart_Handle result;
  Dart_Handle args[2];
  args[0] = (throw_exception_child ? Dart_True() : Dart_False());
  args[1] = (throw_exception_parent ? Dart_True() : Dart_False());
  result = Dart_Invoke(lib, Dart_NewString("main"), 2, args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  if (throw_exception_parent) {
    EXPECT_ERROR(result, "Exception: MakeParentExit");
  } else {
    EXPECT_VALID(result);
  }

  Dart_ExitScope();
  Dart_ShutdownIsolate();

  Isolate::SetCreateCallback(saved);
}


UNIT_TEST_CASE(RunLoop_Success) {
  RunLoopTest(false, false);
}


// This test exits the vm.  Listed as FAIL in vm.status.
UNIT_TEST_CASE(RunLoop_ExceptionChild) {
  RunLoopTest(true, false);
}


UNIT_TEST_CASE(RunLoop_ExceptionParent) {
  RunLoopTest(false, true);
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
    Dart_Handle name, int argument_count) {
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
    sync->Enter();
    char* error = NULL;
    shared_isolate = Dart_CreateIsolate(NULL, NULL, NULL, NULL, &error);
    EXPECT(shared_isolate != NULL);
    Dart_EnterScope();
    Dart_Handle url = Dart_NewString(TestCase::url());
    Dart_Handle source = Dart_NewString(kScriptChars);
    Dart_Handle result = Dart_SetLibraryTagHandler(TestCase::library_handler);
    EXPECT_VALID(result);
    lib = Dart_LoadScript(url, source);
    EXPECT_VALID(lib);
    result = Dart_SetNativeResolver(lib, &IsolateInterruptTestNativeLookup);
    DART_CHECK_VALID(result);

    sync->Notify();
    sync->Exit();
  }

  Dart_Handle result = Dart_Invoke(lib, Dart_NewString("main"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  EXPECT_SUBSTRING("Unhandled exception:\nfoo\n",
                   Dart_GetError(result));

  Dart_ExitScope();
  Dart_ShutdownIsolate();

  // Tell the other thread that we are done (don't use MonitorLocker
  // as there is no current isolate any more).
  sync->Enter();
  shared_isolate = NULL;
  sync->Notify();
  sync->Exit();
}


// This callback handles isolate interrupts for the IsolateInterrupt
// test.  It ignores the first two interrupts and throws an exception
// on the third interrupt.
const int kInterruptCount = 10;
static int interrupt_count = 0;
static bool IsolateInterruptTestCallback() {
  OS::Print(" ========== Interrupt callback called #%d\n", interrupt_count + 1);
  {
    MonitorLocker ml(sync);
    interrupt_count++;
    ml.Notify();
  }
  if (interrupt_count == kInterruptCount) {
    Dart_EnterScope();
    Dart_Handle lib = Dart_LookupLibrary(Dart_NewString(TestCase::url()));
    EXPECT_VALID(lib);
    Dart_Handle exc = Dart_NewString("foo");
    EXPECT_VALID(exc);
    Dart_Handle result = Dart_ThrowException(exc);
    EXPECT_VALID(result);
    UNREACHABLE();  // Dart_ThrowException only returns if it gets an error.
    return false;
  }
  ASSERT(interrupt_count < kInterruptCount);
  return true;
}


TEST_CASE(IsolateInterrupt) {
  Dart_IsolateInterruptCallback saved = Isolate::InterruptCallback();
  Isolate::SetInterruptCallback(IsolateInterruptTestCallback);

  sync = new Monitor();
  int result = Thread::Start(BusyLoop_start, 0);
  EXPECT_EQ(0, result);

  {
    MonitorLocker ml(sync);
    // Wait for the other isolate to enter main.
    while (!main_entered) {
      ml.Wait();
    }
  }

  // Send a number of interrupts to the other isolate. All but the
  // last allow execution to continue. The last causes an exception in
  // the isolate.
  for (int i = 0; i < kInterruptCount; i++) {
    // Space out the interrupts a bit.
    OS::Sleep(i + 1);
    Dart_InterruptIsolate(shared_isolate);
    {
      MonitorLocker ml(sync);
      // Wait for interrupt_count to be increased.
      while (interrupt_count == i) {
        ml.Wait();
      }
      OS::Print(" ========== Interrupt processed #%d\n", interrupt_count);
    }
  }

  {
    MonitorLocker ml(sync);
    // Wait for our isolate to finish.
    while (shared_isolate != NULL) {
      ml.Wait();
    }
  }

  // We should have received the expected number of interrupts.
  EXPECT_EQ(kInterruptCount, interrupt_count);

  // Give the spawned thread enough time to properly exit.
  Isolate::SetInterruptCallback(saved);
}


static int64_t GetValue(Dart_Handle arg) {
  EXPECT(!Dart_IsError(arg));
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
  EXPECT(!Dart_IsError(arg));
  Dart_SetReturnValue(args, Dart_NewInteger(1));
  Dart_ExitScope();
}


static void NativeFoo2(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t i = Dart_GetNativeArgumentCount(args);
  EXPECT_EQ(2, i);
  Dart_Handle arg = Dart_GetNativeArgument(args, 1);
  Dart_SetReturnValue(args, Dart_NewInteger(GetValue(arg)));
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
  Dart_SetReturnValue(args, Dart_NewInteger(GetValue(arg1) +
                                            GetValue(arg2) +
                                            GetValue(arg3)));
  Dart_ExitScope();
}


static Dart_NativeFunction MyNativeClosureResolver(Dart_Handle name,
                                                   int arg_count) {
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
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, source);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));
  result = Dart_SetNativeResolver(lib, &MyNativeClosureResolver);
  EXPECT_VALID(result);

  result = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
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
  Dart_SetReturnValue(args, Dart_NewInteger(GetValue(arg1) +
                                            GetValue(arg2) +
                                            GetValue(arg3)));
  Dart_ExitScope();
}


static Dart_NativeFunction MyStaticNativeClosureResolver(Dart_Handle name,
                                                         int arg_count) {
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
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  result = Dart_SetLibraryTagHandler(library_handler);
  EXPECT_VALID(result);
  Dart_Handle lib = Dart_LoadScript(url, source);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));
  result = Dart_SetNativeResolver(lib, &MyStaticNativeClosureResolver);
  EXPECT_VALID(result);

  result = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerToInt64(result, &value));
  EXPECT_EQ(0, value);
}

#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64).

}  // namespace dart
