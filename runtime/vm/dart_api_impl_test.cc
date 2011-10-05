// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"

#include "vm/assert.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/unit_test.h"
#include "vm/utils.h"
#include "vm/verifier.h"

namespace dart {

UNIT_TEST_CASE(BooleanValues) {
  Dart_CreateIsolate(NULL, NULL);
  Dart_EnterScope();  // Enter a Dart API scope for the unit test.

  Dart_Handle str = Dart_NewString("test");
  EXPECT(!Dart_IsBoolean(str));
  Dart_Handle val1 = Dart_NewBoolean(true);
  EXPECT(Dart_IsBoolean(val1));
  Dart_Handle val2 = Dart_NewBoolean(false);
  EXPECT(Dart_IsBoolean(val2));
  Dart_Result result = Dart_BooleanValue(val1);
  EXPECT(Dart_IsValidResult(result) && Dart_GetResultAsCBoolean(result));
  result = Dart_BooleanValue(val2);
  EXPECT(Dart_IsValidResult(result) && !Dart_GetResultAsCBoolean(result));

  Dart_ExitScope();  // Exit the Dart API scope.
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(DoubleValues) {
  Dart_CreateIsolate(NULL, NULL);
  Dart_EnterScope();  // Enter a Dart API scope for the unit test.

  const double kDoubleVal1 = 201.29;
  const double kDoubleVal2 = 101.19;
  Dart_Handle val1 = Dart_NewDouble(kDoubleVal1);
  EXPECT(Dart_IsDouble(val1));
  Dart_Handle val2 = Dart_NewDouble(kDoubleVal2);
  EXPECT(Dart_IsDouble(val2));
  Dart_Result result = Dart_DoubleValue(val1);
  EXPECT(Dart_IsValidResult(result));
  EXPECT_EQ(kDoubleVal1, Dart_GetResultAsCDouble(result));
  result = Dart_DoubleValue(val2);
  EXPECT(Dart_IsValidResult(result));
  EXPECT_EQ(kDoubleVal2, Dart_GetResultAsCDouble(result));

  Dart_ExitScope();  // Exit the Dart API scope.
  Dart_ShutdownIsolate();
}


#if defined(TARGET_ARCH_IA32)  // only ia32 can run execution tests.

UNIT_TEST_CASE(NumberValues) {
  // TODO(antonm): add various kinds of ints (smi, mint, bigint).
  const char* kScriptChars =
      "class NumberValuesHelper {\n"
      "  static int getInt() { return 1; }\n"
      "  static double getDouble() { return 1.0; }\n"
      "  static bool getBool() { return false; }\n"
      "  static getNull() { return null; }\n"
      "}\n";
  Dart_Result result;
  Dart_Handle handle;

  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    Dart_Handle class_name = Dart_NewString("NumberValuesHelper");
    // Check int case.
    result = Dart_InvokeStatic(lib,
                               class_name,
                               Dart_NewString("getInt"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    handle = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(handle));
    EXPECT(Dart_IsNumber(handle));

    // Check double case.
    result = Dart_InvokeStatic(lib,
                               class_name,
                               Dart_NewString("getDouble"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    handle = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(handle));
    EXPECT(Dart_IsNumber(handle));

    // Check bool case.
    result = Dart_InvokeStatic(lib,
                               class_name,
                               Dart_NewString("getBool"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    handle = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(handle));
    EXPECT(!Dart_IsNumber(handle));

    // Check null case.
    result = Dart_InvokeStatic(lib,
                               class_name,
                               Dart_NewString("getNull"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    handle = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(handle));
    EXPECT(!Dart_IsNumber(handle));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}

#endif


UNIT_TEST_CASE(IntegerValues) {
  Dart_CreateIsolate(NULL, NULL);
  Dart_EnterScope();  // Enter a Dart API scope for the unit test.

  const int64_t kIntegerVal1 = 100;
  const int64_t kIntegerVal2 = 0xffffffff;
  const char* kIntegerVal3 = "0x123456789123456789123456789";

  Dart_Handle val1 = Dart_NewInteger(kIntegerVal1);
  EXPECT(Dart_IsInteger(val1));
  Dart_Result fits = Dart_IntegerFitsIntoInt64(val1);
  EXPECT(Dart_IsValidResult(fits));
  EXPECT(Dart_GetResultAsCBoolean(fits));

  Dart_Handle val2 = Dart_NewInteger(kIntegerVal2);
  EXPECT(Dart_IsInteger(val2));
  fits = Dart_IntegerFitsIntoInt64(val2);
  EXPECT(Dart_IsValidResult(fits));
  EXPECT(Dart_GetResultAsCBoolean(fits));

  Dart_Handle val3 = Dart_NewIntegerFromHexCString(kIntegerVal3);
  EXPECT(Dart_IsInteger(val3));
  fits = Dart_IntegerFitsIntoInt64(val3);
  EXPECT(Dart_IsValidResult(fits));
  EXPECT(!Dart_GetResultAsCBoolean(fits));

  Dart_Result result = Dart_IntegerValue(val1);
  EXPECT(Dart_IsValidResult(result));
  EXPECT_EQ(kIntegerVal1, Dart_GetResultAsCInt64(result));

  result = Dart_IntegerValue(val2);
  EXPECT(Dart_IsValidResult(result));
  EXPECT_EQ(kIntegerVal2, Dart_GetResultAsCInt64(result));

  result = Dart_IntegerValue(val3);
  EXPECT(Dart_IsValidResult(result));
  EXPECT(!strcmp(kIntegerVal3, Dart_GetResultAsCString(result)));

  Dart_ExitScope();  // Exit the Dart API scope.
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(ArrayValues) {
  Dart_CreateIsolate(NULL, NULL);
  Dart_EnterScope();  // Enter a Dart API scope for the unit test.

  const int kArrayLength = 10;
  Dart_Handle str = Dart_NewString("test");
  EXPECT(!Dart_IsArray(str));
  Dart_Handle val = Dart_NewArray(kArrayLength);
  EXPECT(Dart_IsArray(val));
  Dart_Result result = Dart_GetLength(val);
  EXPECT(Dart_IsValidResult(result));
  EXPECT_EQ(kArrayLength, Dart_GetResultAsCIntptr(result));

  // Check invalid array access.
  result = Dart_ArraySetAt(val, (kArrayLength + 10), Dart_NewInteger(10));
  EXPECT(!Dart_IsValidResult(result));
  result = Dart_ArraySetAt(val, -10, Dart_NewInteger(10));
  EXPECT(!Dart_IsValidResult(result));
  result = Dart_ArrayGetAt(val, (kArrayLength + 10));
  EXPECT(!Dart_IsValidResult(result));
  result = Dart_ArrayGetAt(val, -10);
  EXPECT(!Dart_IsValidResult(result));

  for (int i = 0; i < kArrayLength; i++) {
    result = Dart_ArraySetAt(val, i, Dart_NewInteger(i));
    EXPECT(Dart_IsValidResult(result));
  }
  for (int i = 0; i < kArrayLength; i++) {
    result = Dart_ArrayGetAt(val, i);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle val_obj = Dart_GetResult(result);
    result = Dart_IntegerValue(val_obj);
    EXPECT(Dart_IsValidResult(result));
    EXPECT_EQ(i, Dart_GetResultAsCInt64(result));
  }

  Dart_ExitScope();  // Exit the Dart API scope.
  Dart_ShutdownIsolate();
}


// Unit test for entering a scope, creating a local handle and exiting
// the scope.
UNIT_TEST_CASE(EnterExitScope) {
  Dart_CreateIsolate(NULL, NULL);
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  Dart_EnterScope();
  {
    EXPECT(state->top_scope() != NULL);
    Zone zone;
    HandleScope hs;
    const String& str1 = String::Handle(String::New("Test String"));
    Dart_Handle ref = Api::NewLocalHandle(str1);
    String& str2 = String::Handle();
    str2 ^= Api::UnwrapHandle(ref);
    EXPECT(str1.Equals(str2));
  }
  Dart_ExitScope();
  EXPECT(scope == state->top_scope());
  Dart_ShutdownIsolate();
}


// Unit test for creating and deleting persistent handles.
UNIT_TEST_CASE(PersistentHandles) {
  const char* kTestString1 = "Test String1";
  const char* kTestString2 = "Test String2";
  Dart_CreateIsolate(NULL, NULL);
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  Dart_Handle handles[2000];
  Dart_EnterScope();
  {
    Zone zone;
    HandleScope hs;
    const String& str1 = String::Handle(String::New(kTestString1));
    Dart_Handle ref1 = Api::NewLocalHandle(str1);
    for (int i = 0; i < 1000; i++) {
      handles[i] = Dart_NewPersistentHandle(ref1);
    }
    Dart_EnterScope();
    const String& str2 = String::Handle(String::New(kTestString2));
    Dart_Handle ref2 = Api::NewLocalHandle(str2);
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
    Zone zone;
    HandleScope hs;
    for (int i = 0; i < 500; i++) {
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(handles[i]);
      EXPECT(str.Equals(kTestString1, strlen(kTestString1)));
    }
    for (int i = 500; i < 1000; i++) {
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(handles[i]);
      EXPECT(str.Equals(kTestString2, strlen(kTestString2)));
    }
    for (int i = 1000; i < 1500; i++) {
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(handles[i]);
      EXPECT(str.Equals(kTestString1, strlen(kTestString1)));
    }
    for (int i = 1500; i < 2000; i++) {
      String& str = String::Handle();
      str ^= Api::UnwrapHandle(handles[i]);
      EXPECT(str.Equals(kTestString2, strlen(kTestString2)));
    }
  }
  EXPECT(scope == state->top_scope());
  EXPECT_EQ(2000, state->CountPersistentHandles());
  Dart_ShutdownIsolate();
}


// Unit test for creating multiple scopes and local handles within them.
// Ensure that the local handles get all cleaned out when exiting the
// scope.
UNIT_TEST_CASE(LocalHandles) {
  Dart_CreateIsolate(NULL, NULL);
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  Dart_Handle handles[300];
  {
    Zone zone;
    HandleScope hs;
    Smi& val = Smi::Handle();

    // Start a new scope and allocate some local handles.
    Dart_EnterScope();
    for (int i = 0; i < 100; i++) {
      val ^= Smi::New(i);
      handles[i] = Api::NewLocalHandle(val);
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
        val ^= Smi::New(i);
        handles[i] = Api::NewLocalHandle(val);
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
          val ^= Smi::New(i);
          handles[i] = Api::NewLocalHandle(val);
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
  Dart_CreateIsolate(NULL, NULL);
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  {
    // Start a new scope and allocate some memory.
    Dart_EnterScope();
    for (int i = 0; i < 100; i++) {
      Api::Allocate(16);
    }
    EXPECT_EQ(1600, state->ZoneSizeInBytes());
    // Start another scope and allocate some more memory.
    {
      Dart_EnterScope();
      for (int i = 0; i < 100; i++) {
        Api::Allocate(16);
      }
      EXPECT_EQ(3200, state->ZoneSizeInBytes());
      {
        // Start another scope and allocate some more memory.
        {
          Dart_EnterScope();
          for (int i = 0; i < 200; i++) {
            Api::Allocate(16);
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
  Dart_Isolate iso_1 = Dart_CreateIsolate(NULL, NULL);
  EXPECT_EQ(iso_1, Isolate::Current());
  Dart_Isolate isolate = Dart_CurrentIsolate();
  EXPECT_EQ(iso_1, isolate);
  Dart_ExitIsolate();
  EXPECT(NULL == Isolate::Current());
  EXPECT(NULL == Dart_CurrentIsolate());
  Dart_Isolate iso_2 = Dart_CreateIsolate(NULL, NULL);
  EXPECT_EQ(iso_2, Isolate::Current());
  Dart_ExitIsolate();
  EXPECT(NULL == Isolate::Current());
  Dart_EnterIsolate(iso_2);
  EXPECT_EQ(iso_2, Isolate::Current());
  Dart_ShutdownIsolate();
  EXPECT(NULL == Isolate::Current());
  Dart_EnterIsolate(iso_1);
  EXPECT_EQ(iso_1, Isolate::Current());
  Dart_ShutdownIsolate();
  EXPECT(NULL == Isolate::Current());
}


#if defined(TARGET_ARCH_IA32)  // only ia32 can run execution tests.

UNIT_TEST_CASE(FieldAccess) {
  const char* kScriptChars =
      "class Fields  {\n"
      "  Fields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "class FieldsTest {\n"
      "  static Fields testMain() {\n"
      "    Fields obj = new Fields(10, 20);\n"
      "    return obj;\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("FieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));

    // Now access and set various static fields of Fields class.
    result = Dart_GetClass(lib, Dart_NewString("Fields"));
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle cls = Dart_GetResult(result);
    result = Dart_GetStaticField(cls, Dart_NewString("fld1"));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld3"));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetStaticField(cls, Dart_NewString("fld4"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(10, Dart_GetResultAsCInt64(result));
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("fld4"),
                                 Dart_NewInteger(20));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetStaticField(cls, Dart_NewString("fld3"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("fld3"),
                                 Dart_NewInteger(200));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(200, Dart_GetResultAsCInt64(result));

    // Now access and set various instance fields of the returned object.
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld3"));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(10, Dart_GetResultAsCInt64(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld2"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(20, Dart_GetResultAsCInt64(result));
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("fld2"),
                                   Dart_NewInteger(40));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("fld1"),
                                   Dart_NewInteger(40));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(40, Dart_GetResultAsCInt64(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(HiddenFieldAccess) {
  const char* kScriptChars =
      "class HiddenFields  {\n"
      "  HiddenFields(int i, int j) : _fld1 = i, _fld2 = j {}\n"
      "  int _fld1;\n"
      "  final int _fld2;\n"
      "  static int _fld3;\n"
      "  static final int _fld4 = 10;\n"
      "}\n"
      "class HiddenFieldsTest {\n"
      "  static HiddenFields testMain() {\n"
      "    HiddenFields obj = new HiddenFields(10, 20);\n"
      "    return obj;\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load up a test script which extends the native wrapper class.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("HiddenFieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));

    // Now access and set various static fields of HiddenFields class.
    result = Dart_GetClass(lib, Dart_NewString("HiddenFields"));
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle cls = Dart_GetResult(result);
    result = Dart_GetStaticField(cls, Dart_NewString("_fld1"));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld3"));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetStaticField(cls, Dart_NewString("_fld4"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(10, Dart_GetResultAsCInt64(result));
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("_fld4"),
                                 Dart_NewInteger(20));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetStaticField(cls, Dart_NewString("_fld3"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("_fld3"),
                                 Dart_NewInteger(200));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(200, Dart_GetResultAsCInt64(result));

    // Now access and set various instance fields of the returned object.
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld3"));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld1"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(10, Dart_GetResultAsCInt64(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld2"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(20, Dart_GetResultAsCInt64(result));
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("_fld2"),
                                   Dart_NewInteger(40));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("_fld1"),
                                   Dart_NewInteger(40));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld1"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(40, Dart_GetResultAsCInt64(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(InjectNativeFields1) {
  const char* kScriptChars =
      "class NativeFields extends NativeFieldsWrapper {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "class NativeFieldsTest {\n"
      "  static NativeFields testMain() {\n"
      "    NativeFields obj = new NativeFields(10, 20);\n"
      "    return obj;\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Zone zone;
    HandleScope scope;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.
    const int kNumNativeFields = 4;

    // Create a test library.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Create a native wrapper class with native fields.
    result = Dart_CreateNativeWrapperClass(
        lib,
        Dart_NewString("NativeFieldsWrapper"),
        kNumNativeFields);

    // Load up a test script in the test library.

    // Invoke a function which returns an object of type NativeFields.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("NativeFieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));
    Instance& obj = Instance::Handle();
    obj ^= Api::UnwrapHandle(retobj);
    const Class& cls = Class::Handle(obj.clazz());
    // We expect the newly created "NativeFields" object to have
    // 2 dart instance fields (fld1, fld2) and kNumNativeFields native fields.
    // Hence the size of an instance of "NativeFields" should be
    // (kNumNativeFields + 2) * kWordSize + sizeof the header word.
    // We check to make sure the instance size computed by the VM matches
    // our expectations.
    EXPECT_EQ(Utils::RoundUp(((kNumNativeFields + 2) * kWordSize) + kWordSize,
                             kObjectAlignment),
              cls.instance_size());

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(InjectNativeFields2) {
  const char* kScriptChars =
      "class NativeFields extends NativeFieldsWrapper {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "class NativeFieldsTest {\n"
      "  static NativeFields testMain() {\n"
      "    NativeFields obj = new NativeFields(10, 20);\n"
      "    return obj;\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object of type NativeFields.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("NativeFieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    // We expect this to fail as class "NativeFields" extends
    // "NativeFieldsWrapper" and there is no definition of it either
    // in the dart code or through the native field injection mechanism.
    EXPECT(!Dart_IsValidResult(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(NativeFieldAccess) {
  const char* kScriptChars =
      "class NativeFields extends NativeFieldsWrapper {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "class NativeFieldsTest {\n"
      "  static NativeFields testMain() {\n"
      "    NativeFields obj = new NativeFields(10, 20);\n"
      "    return obj;\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.
    const int kNumNativeFields = 4;

    // Create a test library.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Create a native wrapper class with native fields.
    result = Dart_CreateNativeWrapperClass(
        lib,
        Dart_NewString("NativeFieldsWrapper"),
        kNumNativeFields);

    // Load up a test script in it.

    // Invoke a function which returns an object of type NativeFields.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("NativeFieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));

    // Now access and set various instance fields of the returned object.
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld3"));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(10, Dart_GetResultAsCInt64(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld2"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(20, Dart_GetResultAsCInt64(result));
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("fld2"),
                                   Dart_NewInteger(40));
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("fld1"),
                                   Dart_NewInteger(40));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(40, Dart_GetResultAsCInt64(result));

    // Now access and set various native instance fields of the returned object.
    const int kNativeFld0 = 0;
    const int kNativeFld1 = 1;
    const int kNativeFld2 = 2;
    const int kNativeFld3 = 3;
    const int kNativeFld4 = 4;
    result = Dart_GetNativeInstanceField(retobj, kNativeFld4);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld0);
    EXPECT(Dart_IsValidResult(result));
    EXPECT_EQ(0, Dart_GetResultAsCIntptr(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld1);
    EXPECT(Dart_IsValidResult(result));
    EXPECT_EQ(0, Dart_GetResultAsCIntptr(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld2);
    EXPECT(Dart_IsValidResult(result));
    EXPECT_EQ(0, Dart_GetResultAsCIntptr(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld4, 40);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld0, 4);
    EXPECT(Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld1, 40);
    EXPECT(Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld2, 400);
    EXPECT(Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld3, 4000);
    EXPECT(Dart_IsValidResult(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld3);
    EXPECT(Dart_IsValidResult(result));
    EXPECT_EQ(4000, Dart_GetResultAsCIntptr(result));

    // Now re-access various dart instance fields of the returned object
    // to ensure that there was no corruption while setting native fields.
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(40, Dart_GetResultAsCInt64(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld2"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(20, Dart_GetResultAsCInt64(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(NegativeNativeFieldAccess) {
  const char* kScriptChars =
      "class NativeFields {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static int fld3;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "class NativeFieldsTest {\n"
      "  static NativeFields testMain1() {\n"
      "    NativeFields obj = new NativeFields(10, 20);\n"
      "    return obj;\n"
      "  }\n"
      "  static Function testMain2() {\n"
      "    return function() {};\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Zone zone;
    HandleScope scope;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object of type NativeFields.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("NativeFieldsTest"),
                               Dart_NewString("testMain1"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));


    // Now access and set various native instance fields of the returned object.
    // All of these tests are expected to return failure as there are no
    // native fields in an instance of NativeFields.
    const int kNativeFld0 = 0;
    const int kNativeFld1 = 1;
    const int kNativeFld2 = 2;
    const int kNativeFld3 = 3;
    const int kNativeFld4 = 4;
    result = Dart_GetNativeInstanceField(retobj, kNativeFld4);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld0);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld1);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld2);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld4, 40);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld3, 40);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld0, 400);
    EXPECT(!Dart_IsValidResult(result));

    // Invoke a function which returns a closure object.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("NativeFieldsTest"),
                               Dart_NewString("testMain2"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld4);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld0);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld1);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_GetNativeInstanceField(retobj, kNativeFld2);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld4, 40);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld3, 40);
    EXPECT(!Dart_IsValidResult(result));
    result = Dart_SetNativeInstanceField(retobj, kNativeFld0, 400);
    EXPECT(!Dart_IsValidResult(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(GetStaticField_RunsInitializer) {
  const char* kScriptChars =
      "class TestClass  {\n"
      "  static final int fld1 = 7;\n"
      "  static int fld2 = 11;\n"
      "  static void testMain() {\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("TestClass"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);

    result = Dart_GetClass(lib, Dart_NewString("TestClass"));
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle cls = Dart_GetResult(result);

    // For uninitialized fields, the getter is returned
    result = Dart_GetStaticField(cls, Dart_NewString("fld1"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(7, Dart_GetResultAsCInt64(result));

    result = Dart_GetStaticField(cls, Dart_NewString("fld2"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(11, Dart_GetResultAsCInt64(result));

    // Overwrite fld2
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("fld2"),
                                 Dart_NewInteger(13));
    EXPECT(Dart_IsValidResult(result));

    // We now get the new value for fld2, not the initializer
    result = Dart_GetStaticField(cls, Dart_NewString("fld2"));
    EXPECT(Dart_IsValidResult(result));
    result = Dart_IntegerValue(Dart_GetResult(result));
    EXPECT_EQ(13, Dart_GetResultAsCInt64(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(StaticFieldNotFound) {
  const char* kScriptChars =
      "class TestClass  {\n"
      "  static void testMain() {\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("TestClass"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);

    result = Dart_GetClass(lib, Dart_NewString("TestClass"));
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle cls = Dart_GetResult(result);

    result = Dart_GetStaticField(cls, Dart_NewString("not_found"));
    EXPECT(!Dart_IsValidResult(result));
    EXPECT_STREQ("Specified field is not found in the class",
                 Dart_GetErrorCString(result));

    result = Dart_SetStaticField(cls,
                                 Dart_NewString("not_found"),
                                 Dart_NewInteger(13));
    EXPECT(!Dart_IsValidResult(result));
    EXPECT_STREQ("Specified field is not found in the class",
                 Dart_GetErrorCString(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(InvokeDynamic) {
  const char* kScriptChars =
      "class InvokeDynamic {\n"
      "  InvokeDynamic(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int method1(int i) { return i + fld1 + fld2 + fld4; }\n"
      "  static int method2(int i) { return i + fld4; }\n"
      "  int fld1;\n"
      "  final int fld2;\n"
      "  static final int fld4 = 10;\n"
      "}\n"
      "class InvokeDynamicTest {\n"
      "  static InvokeDynamic testMain() {\n"
      "    InvokeDynamic obj = new InvokeDynamic(10, 20);\n"
      "    return obj;\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Zone zone;
    HandleScope scope;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object of type InvokeDynamic.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("InvokeDynamicTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));


    // Now invoke a dynamic method and check the result.
    Dart_Handle dart_arguments[1];
    dart_arguments[0] = Dart_NewInteger(1);
    result = Dart_InvokeDynamic(retobj,
                                Dart_NewString("method1"),
                                1,
                                dart_arguments);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle obj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(obj));
    EXPECT(Dart_IsInteger(obj));
    result = Dart_IntegerValue(obj);
    EXPECT_EQ(41, Dart_GetResultAsCInt64(result));

    result = Dart_InvokeDynamic(retobj, Dart_NewString("method2"), 0, NULL);
    EXPECT(!Dart_IsValidResult(result));

    result = Dart_InvokeDynamic(retobj, Dart_NewString("method1"), 0, NULL);
    EXPECT(!Dart_IsValidResult(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(InvokeClosure) {
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
      "class InvokeClosureTest {\n"
      "  static Function testMain1() {\n"
      "    InvokeClosure obj = new InvokeClosure(10, 20);\n"
      "    return obj.method1(10);\n"
      "  }\n"
      "  static Function testMain2() {\n"
      "    return InvokeClosure.method2(10);\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Zone zone;
    HandleScope scope;
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns a closure.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("InvokeClosureTest"),
                               Dart_NewString("testMain1"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));

    EXPECT(Dart_IsClosure(retobj));
    EXPECT(!Dart_IsClosure(Dart_NewInteger(101)));

    // Now invoke the closure and check the result.
    Dart_Handle dart_arguments[1];
    dart_arguments[0] = Dart_NewInteger(1);
    result = Dart_InvokeClosure(retobj, 1, dart_arguments);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle obj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(obj));
    EXPECT(Dart_IsInteger(obj));
    result = Dart_IntegerValue(obj);
    EXPECT_EQ(51, Dart_GetResultAsCInt64(result));

    // Invoke closure with wrong number of args, should result in exception.
    result = Dart_InvokeClosure(retobj, 0, NULL);
    EXPECT(Dart_IsValidResult(result));
    obj = Dart_GetResult(result);
    EXPECT(Dart_ExceptionOccurred(obj));

    // Invoke a function which returns a closure.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("InvokeClosureTest"),
                               Dart_NewString("testMain2"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));

    EXPECT(Dart_IsClosure(retobj));
    EXPECT(!Dart_IsClosure(Dart_NewString("abcdef")));

    // Now invoke the closure and check the result (should be an exception).
    dart_arguments[0] = Dart_NewInteger(1);
    result = Dart_InvokeClosure(retobj, 1, dart_arguments);
    retobj = Dart_GetResult(result);
    EXPECT(Dart_ExceptionOccurred(retobj));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


void ExceptionNative(Dart_NativeArguments args) {
  Dart_Handle param = Dart_GetNativeArgument(args, 0);
  Dart_EnterScope();  // Start a Dart API scope for invoking API functions.
  char* str = reinterpret_cast<char*>(Api::Allocate(1024));
  str[0] = 0;
  Dart_ThrowException(param);
  UNREACHABLE();
}


static Dart_NativeFunction native_lookup(Dart_Handle name, int argument_count) {
  return reinterpret_cast<Dart_NativeFunction>(&ExceptionNative);
}


UNIT_TEST_CASE(ThrowException) {
  const char* kScriptChars =
      "class ThrowException {\n"
      "  ThrowException(int i) : fld1 = i {}\n"
      "  int method1(int i) native \"ThrowException_native\";"
      "  int method2() {\n"
      "     try { method1(10); } catch(var a) { return 5; } return 10;\n"
      "  }\n"
      "  int fld1;\n"
      "}\n"
      "class ThrowExceptionTest {\n"
      "  static ThrowException testMain() {\n"
      "    ThrowException obj = new ThrowException(10);\n"
      "    return obj;\n"
      "  }\n"
      "}\n";
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  Isolate* isolate = Isolate::Current();
  EXPECT(isolate != NULL);
  ApiState* state = isolate->api_state();
  EXPECT(state != NULL);
  {
    intptr_t size = state->ZoneSizeInBytes();
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Load up a test script which extends the native wrapper class.
    Dart_Handle lib = TestCase::LoadTestScript(
        kScriptChars,
        reinterpret_cast<Dart_NativeEntryResolver>(native_lookup));

    // Invoke a function which returns an object of type ThrowException.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("ThrowExceptionTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle retobj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(retobj));

    // Throwing an exception here should result in an error.
    result = Dart_ThrowException(retobj);
    EXPECT(!Dart_IsValidResult(result));

    // Now invoke method2 which invokes a natve method where it is
    // ok to throw an exception, check the result which would indicate
    // if an exception was thrown or not.
    result = Dart_InvokeDynamic(retobj, Dart_NewString("method2"), 0, NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle obj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(obj));
    EXPECT(Dart_IsInteger(obj));
    result = Dart_IntegerValue(obj);
    EXPECT_EQ(5, Dart_GetResultAsCInt64(result));

    Dart_ExitScope();  // Exit the Dart API scope.
    EXPECT_EQ(size, state->ZoneSizeInBytes());
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(InstanceOf) {
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
  Dart_Result result;

  Dart_CreateIsolate(NULL, NULL);
  {
    Dart_EnterScope();  // Start a Dart API scope for invoking API functions.

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object of type InstanceOf..
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("InstanceOfTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle instanceOfTestObj = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(instanceOfTestObj));

    // Fetch InstanceOfTest class.
    result = Dart_GetClass(lib, Dart_NewString("InstanceOfTest"));
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle cls = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(cls));

    // Now check instanceOfTestObj reported as an instance of
    // InstanceOfTest class.
    result = Dart_IsInstanceOf(instanceOfTestObj, cls);
    EXPECT(Dart_IsValidResult(result));
    EXPECT(Dart_GetResultAsCBoolean(result));

    // Fetch OtherClass and check if instanceOfTestObj is instance of it.
    result = Dart_GetClass(lib, Dart_NewString("OtherClass"));
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle otherClass = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(otherClass));

    result = Dart_IsInstanceOf(instanceOfTestObj, otherClass);
    EXPECT(Dart_IsValidResult(result));
    EXPECT(!Dart_GetResultAsCBoolean(result));

    // Check that primitives are not instances of InstanceOfTest class.
    result = Dart_IsInstanceOf(Dart_NewString("a string"), otherClass);
    EXPECT(Dart_IsValidResult(result));
    EXPECT(!Dart_GetResultAsCBoolean(result));

    result = Dart_IsInstanceOf(Dart_NewInteger(42), otherClass);
    EXPECT(Dart_IsValidResult(result));
    EXPECT(!Dart_GetResultAsCBoolean(result));

    result = Dart_IsInstanceOf(Dart_NewBoolean(true), otherClass);
    EXPECT(Dart_IsValidResult(result));
    EXPECT(!Dart_GetResultAsCBoolean(result));

    // Check that null is not an instance of InstanceOfTest class.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("OtherClass"),
                               Dart_NewString("returnNull"),
                               0,
                               NULL);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle null = Dart_GetResult(result);
    EXPECT(!Dart_ExceptionOccurred(null));

    result = Dart_IsInstanceOf(null, otherClass);
    EXPECT(Dart_IsValidResult(result));
    EXPECT(!Dart_GetResultAsCBoolean(result));

    // Check that error is returned if null is passed as a class argument.
    result = Dart_IsInstanceOf(null, null);
    EXPECT(!Dart_IsValidResult(result));

    Dart_ExitScope();  // Exit the Dart API scope.
  }
  Dart_ShutdownIsolate();
}


UNIT_TEST_CASE(NullReceiver) {
  Dart_CreateIsolate(NULL, NULL);
  Dart_EnterScope();  // Enter a Dart API scope for the unit test.
  {
    Zone zone;
    HandleScope hs;

    Dart_Handle function_name = Dart_NewString("toString");
    const int number_of_arguments = 0;
    Dart_Handle null_receiver = Api::NewLocalHandle(Object::Handle());
    Dart_Handle dart_arguments[0];
    Dart_Result result = Dart_InvokeDynamic(null_receiver,
                                            function_name,
                                            number_of_arguments,
                                            dart_arguments);
    EXPECT(Dart_IsValidResult(result));
    Dart_Handle retobj = Dart_GetResult(result);
    EXPECT(Dart_IsString(retobj));

    // Should throw a NullPointerException. Disabled due to bug 5415268.
    /*
    Dart_Handle function_name2 = Dart_NewString("NoNoNo");
    result = Dart_InvokeDynamic(null_receiver,
                                function_name2,
                                number_of_arguments,
                                dart_arguments);
    EXPECT(Dart_IsValidResult(result));
    retobj = Dart_GetResult(result);
    EXPECT(Dart_ExceptionOccurred(retobj)); */
  }
  Dart_ExitScope();  // Exit the Dart API scope.
  Dart_ShutdownIsolate();
}

#endif  // TARGET_ARCH_IA32.

}  // namespace dart
