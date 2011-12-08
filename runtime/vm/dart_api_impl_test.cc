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

#if defined(TARGET_ARCH_IA32)  // only ia32 can run execution tests.

UNIT_TEST_CASE(ErrorHandles) {
  const char* kScriptChars =
      "class TestClass  {\n"
      "  static void testMain() {\n"
      "    throw new Exception(\"bad news\");\n"
      "  }\n"
      "}\n";

  TestIsolateScope __test_isolate__;

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  Dart_Handle instance = Dart_True();
  Dart_Handle error = Api::Error("myerror");
  Dart_Handle exception = Dart_InvokeStatic(lib,
                                            Dart_NewString("TestClass"),
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
      " 0. Function: 'TestClass.testMain' url: 'dart:test-lib' line:3 col:5\n",
      Dart_GetError(exception));

  EXPECT(Dart_IsError(Dart_ErrorGetException(instance)));
  EXPECT(Dart_IsError(Dart_ErrorGetException(error)));
  EXPECT_VALID(Dart_ErrorGetException(exception));

  EXPECT(Dart_IsError(Dart_ErrorGetStacktrace(instance)));
  EXPECT(Dart_IsError(Dart_ErrorGetStacktrace(error)));
  EXPECT_VALID(Dart_ErrorGetStacktrace(exception));
}

#endif


UNIT_TEST_CASE(Dart_Error) {
  TestIsolateScope __test_isolate__;

  Dart_Handle error = Dart_Error("An %s", "error");
  EXPECT(Dart_IsError(error));
  EXPECT_STREQ("An error", Dart_GetError(error));
}


UNIT_TEST_CASE(Null) {
  TestIsolateScope __test_isolate__;

  Dart_Handle null = Dart_Null();
  EXPECT_VALID(null);
  EXPECT(Dart_IsNull(null));

  Dart_Handle str = Dart_NewString("test");
  EXPECT_VALID(str);
  EXPECT(!Dart_IsNull(str));
}


UNIT_TEST_CASE(IsSame) {
  TestIsolateScope __test_isolate__;

  bool same = false;
  Dart_Handle five = Dart_NewString("5");
  Dart_Handle five_again = Dart_NewString("5");
  Dart_Handle seven = Dart_NewString("7");

  // Same objects.
  EXPECT_VALID(Dart_IsSame(five, five, &same));
  EXPECT(same);

  // Equal objects.
  EXPECT_VALID(Dart_IsSame(five, five_again, &same));
  EXPECT(!same);

  // Different objects.
  EXPECT_VALID(Dart_IsSame(five, seven, &same));
  EXPECT(!same);

  // Non-instance objects.
  {
    DARTSCOPE_NOCHECKS(Isolate::Current());
    const Object& cls1 = Object::Handle(Object::null_class());
    const Object& cls2 = Object::Handle(Object::class_class());
    Dart_Handle class1 = Api::NewLocalHandle(cls1);
    Dart_Handle class2 = Api::NewLocalHandle(cls2);

    EXPECT_VALID(Dart_IsSame(class1, class1, &same));
    EXPECT(same);

    EXPECT_VALID(Dart_IsSame(class1, class2, &same));
    EXPECT(!same);
  }
}


#if defined(TARGET_ARCH_IA32)  // only ia32 can run execution tests.

UNIT_TEST_CASE(ObjectEquals) {
  TestIsolateScope __test_isolate__;

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

UNIT_TEST_CASE(BooleanValues) {
  TestIsolateScope __test_isolate__;

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


UNIT_TEST_CASE(BooleanConstants) {
  TestIsolateScope __test_isolate__;

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


UNIT_TEST_CASE(DoubleValues) {
  TestIsolateScope __test_isolate__;

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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    Dart_Handle class_name = Dart_NewString("NumberValuesHelper");
    // Check int case.
    result = Dart_InvokeStatic(lib,
                               class_name,
                               Dart_NewString("getInt"),
                               0,
                               NULL);
    EXPECT_VALID(result);
    EXPECT(Dart_IsNumber(result));

    // Check double case.
    result = Dart_InvokeStatic(lib,
                               class_name,
                               Dart_NewString("getDouble"),
                               0,
                               NULL);
    EXPECT_VALID(result);
    EXPECT(Dart_IsNumber(result));

    // Check bool case.
    result = Dart_InvokeStatic(lib,
                               class_name,
                               Dart_NewString("getBool"),
                               0,
                               NULL);
    EXPECT_VALID(result);
    EXPECT(!Dart_IsNumber(result));

    // Check null case.
    result = Dart_InvokeStatic(lib,
                               class_name,
                               Dart_NewString("getNull"),
                               0,
                               NULL);
    EXPECT_VALID(result);
    EXPECT(!Dart_IsNumber(result));
  }
}

#endif


UNIT_TEST_CASE(IntegerValues) {
  TestIsolateScope __test_isolate__;

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
  result = Dart_IntegerValue(val1, &out);
  EXPECT_VALID(result);
  EXPECT_EQ(kIntegerVal1, out);

  result = Dart_IntegerValue(val2, &out);
  EXPECT_VALID(result);
  EXPECT_EQ(kIntegerVal2, out);

  const char* chars = NULL;
  result = Dart_IntegerValueHexCString(val3, &chars);
  EXPECT_VALID(result);
  EXPECT(!strcmp(kIntegerVal3, chars));
}


UNIT_TEST_CASE(ArrayValues) {
  TestIsolateScope __test_isolate__;

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
    result = Dart_IntegerValue(result, &value);
    EXPECT_VALID(result);
    EXPECT_EQ(i, value);
  }
}


UNIT_TEST_CASE(IsString) {
  TestIsolateScope __test_isolate__;

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


UNIT_TEST_CASE(ExternalStringGetPeer) {
  TestIsolateScope __test_isolate__;
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
               "non-NULL.", Dart_GetError(result));

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


#if defined(TARGET_ARCH_IA32)  // only ia32 can run execution tests.

UNIT_TEST_CASE(ListAccess) {
  const char* kScriptChars =
      "class ListAccessTest {"
      "  ListAccessTest() {}"
      "  static List testMain() {"
      "    List a = new List();"
      "    a.add(10);"
      "    a.add(20);"
      "    a.add(30);"
      "    return a;"
      "  }"
      "}";
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object of type InstanceOf..
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("ListAccessTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
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
    result = Dart_IntegerValue(result, &value);
    EXPECT_VALID(result);
    EXPECT_EQ(10, value);

    result = Dart_ListGetAt(ListAccessTestObj, 1);
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_VALID(result);
    EXPECT_EQ(20, value);

    result = Dart_ListGetAt(ListAccessTestObj, 2);
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
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
    result = Dart_IntegerValue(result, &value);
    EXPECT_VALID(result);
    EXPECT_EQ(0, value);

    result = Dart_ListGetAt(ListAccessTestObj, 1);
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_VALID(result);
    EXPECT_EQ(1, value);

    result = Dart_ListGetAt(ListAccessTestObj, 2);
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
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
    result = Dart_IntegerValue(result, &value);
    EXPECT_VALID(result);
    EXPECT_EQ(30, value);

    // Check if we get an exception when accessing beyond limit.
    result = Dart_ListGetAt(ListAccessTestObj, 4);
    EXPECT(Dart_IsError(result));
  }
}

#endif  // TARGET_ARCH_IA32.


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
    Dart_Handle ref = Api::NewLocalHandle(str1);
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


static bool MyPostMessageCallback(Dart_Isolate dest_isolate,
                                  Dart_Port send_port,
                                  Dart_Port reply_port,
                                  Dart_Message message) {
  return true;
}


static void MyClosePortCallback(Dart_Isolate dest_isolate,
                                Dart_Port port) {
}


UNIT_TEST_CASE(SetMessageCallbacks) {
  Dart_Isolate dart_isolate = TestCase::CreateTestIsolate();
  Dart_SetMessageCallbacks(&MyPostMessageCallback, &MyClosePortCallback);
  Isolate* isolate = reinterpret_cast<Isolate*>(dart_isolate);
  EXPECT_EQ(&MyPostMessageCallback, isolate->post_message_callback());
  EXPECT_EQ(&MyClosePortCallback, isolate->close_port_callback());
  Dart_ShutdownIsolate();
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object.
    Dart_Handle retobj = Dart_InvokeStatic(lib,
                                           Dart_NewString("FieldsTest"),
                                           Dart_NewString("testMain"),
                                           0,
                                           NULL);
    EXPECT_VALID(retobj);

    // Now access and set various static fields of Fields class.
    Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("Fields"));
    EXPECT_VALID(cls);
    result = Dart_GetStaticField(cls, Dart_NewString("fld1"));
    EXPECT(Dart_IsError(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld3"));
    EXPECT(Dart_IsError(result));
    result = Dart_GetStaticField(cls, Dart_NewString("fld4"));
    EXPECT_VALID(result);
    int64_t value = 0;
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(10, value);
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("fld4"),
                                 Dart_NewInteger(20));
    EXPECT(Dart_IsError(result));
    result = Dart_GetStaticField(cls, Dart_NewString("fld3"));
    EXPECT_VALID(result);
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("fld3"),
                                 Dart_NewInteger(200));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(200, value);

    // Now access and set various instance fields of the returned object.
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld3"));
    EXPECT(Dart_IsError(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(10, value);
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld2"));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(20, value);
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("fld2"),
                                   Dart_NewInteger(40));
    EXPECT(Dart_IsError(result));
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("fld1"),
                                   Dart_NewInteger(40));
    EXPECT_VALID(result);
    result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(40, value);
  }
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    // Load up a test script which extends the native wrapper class.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object.
    Dart_Handle retobj = Dart_InvokeStatic(lib,
                                           Dart_NewString("HiddenFieldsTest"),
                                           Dart_NewString("testMain"),
                                           0,
                                           NULL);
    EXPECT_VALID(retobj);

    // Now access and set various static fields of HiddenFields class.
    Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("HiddenFields"));
    EXPECT_VALID(cls);
    result = Dart_GetStaticField(cls, Dart_NewString("_fld1"));
    EXPECT(Dart_IsError(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld3"));
    EXPECT(Dart_IsError(result));
    result = Dart_GetStaticField(cls, Dart_NewString("_fld4"));
    EXPECT_VALID(result);
    int64_t value = 0;
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(10, value);
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("_fld4"),
                                 Dart_NewInteger(20));
    EXPECT(Dart_IsError(result));
    result = Dart_GetStaticField(cls, Dart_NewString("_fld3"));
    EXPECT_VALID(result);
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("_fld3"),
                                 Dart_NewInteger(200));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(200, value);

    // Now access and set various instance fields of the returned object.
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld3"));
    EXPECT(Dart_IsError(result));
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld1"));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(10, value);
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld2"));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(20, value);
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("_fld2"),
                                   Dart_NewInteger(40));
    EXPECT(Dart_IsError(result));
    result = Dart_SetInstanceField(retobj,
                                   Dart_NewString("_fld1"),
                                   Dart_NewInteger(40));
    EXPECT_VALID(result);
    result = Dart_GetInstanceField(retobj, Dart_NewString("_fld1"));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(40, value);
  }
}


void NativeFieldLookup(Dart_NativeArguments args) {
  UNREACHABLE();
}


static Dart_NativeFunction native_field_lookup(Dart_Handle name,
                                               int argument_count) {
  return reinterpret_cast<Dart_NativeFunction>(&NativeFieldLookup);
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
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
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("NativeFieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
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
    EXPECT(Dart_IsError(result));
  }
}


UNIT_TEST_CASE(InjectNativeFields3) {
  const char* kScriptChars =
      "#import('dart:nativewrappers');"
      "class NativeFields extends NativeFieldWrapperClass2 {\n"
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    const int kNumNativeFields = 2;

    // Load up a test script in the test library.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars,
                                               native_field_lookup);

    // Invoke a function which returns an object of type NativeFields.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("NativeFieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
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
}


UNIT_TEST_CASE(InjectNativeFields4) {
  const char* kScriptChars =
      "#import('dart:nativewrappers');"
      "class NativeFields extends NativeFieldWrapperClass2 {\n"
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    // Load up a test script in the test library.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object of type NativeFields.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("NativeFieldsTest"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);
    // We expect the test script to fail finalization with the error below:
    EXPECT(Dart_IsError(result));
    Dart_Handle expected_error = Dart_Error(
        "'dart:test-lib': Error: class 'NativeFields' is trying to extend a "
        "native fields class, but library '%s' has no native resolvers",
        TestCase::url());
    EXPECT_STREQ(Dart_GetError(expected_error), Dart_GetError(result));
  }
}


static void TestNativeFields(Dart_Handle retobj) {
  // Access and set various instance fields of the object.
  Dart_Handle result = Dart_GetInstanceField(retobj, Dart_NewString("fld3"));
  EXPECT(Dart_IsError(result));
  result = Dart_GetInstanceField(retobj, Dart_NewString("fld0"));
  EXPECT_VALID(result);
  EXPECT(Dart_IsNull(result));
  result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
  EXPECT_VALID(result);
  int64_t value = 0;
  result = Dart_IntegerValue(result, &value);
  EXPECT_EQ(10, value);
  result = Dart_GetInstanceField(retobj, Dart_NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerValue(result, &value);
  EXPECT_EQ(20, value);
  result = Dart_SetInstanceField(retobj,
                                 Dart_NewString("fld2"),
                                 Dart_NewInteger(40));
  EXPECT(Dart_IsError(result));
  result = Dart_SetInstanceField(retobj,
                                 Dart_NewString("fld1"),
                                 Dart_NewInteger(40));
  EXPECT_VALID(result);
  result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
  EXPECT_VALID(result);
  result = Dart_IntegerValue(result, &value);
  EXPECT_EQ(40, value);

  // Now access and set various native instance fields of the returned object.
  const int kNativeFld0 = 0;
  const int kNativeFld1 = 1;
  const int kNativeFld2 = 2;
  const int kNativeFld3 = 3;
  const int kNativeFld4 = 4;
  intptr_t field_value = 0;
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
  result = Dart_GetInstanceField(retobj, Dart_NewString("fld1"));
  EXPECT_VALID(result);
  result = Dart_IntegerValue(result, &value);
  EXPECT_EQ(40, value);
  result = Dart_GetInstanceField(retobj, Dart_NewString("fld2"));
  EXPECT_VALID(result);
  result = Dart_IntegerValue(result, &value);
  EXPECT_EQ(20, value);
}


UNIT_TEST_CASE(NativeFieldAccess) {
  const char* kScriptChars =
      "class NativeFields extends NativeFieldsWrapper {\n"
      "  NativeFields(int i, int j) : fld1 = i, fld2 = j {}\n"
      "  int fld0;\n"
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    const int kNumNativeFields = 4;

    // Create a test library.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars,
                                               native_field_lookup);

    // Create a native wrapper class with native fields.
    result = Dart_CreateNativeWrapperClass(
        lib,
        Dart_NewString("NativeFieldsWrapper"),
        kNumNativeFields);

    // Load up a test script in it.

    // Invoke a function which returns an object of type NativeFields.
    Dart_Handle retobj = Dart_InvokeStatic(lib,
                                           Dart_NewString("NativeFieldsTest"),
                                           Dart_NewString("testMain"),
                                           0,
                                           NULL);
    EXPECT_VALID(retobj);

    // Now access and set various instance fields of the returned object.
    TestNativeFields(retobj);
  }
}


UNIT_TEST_CASE(ImplicitNativeFieldAccess) {
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
      "class NativeFieldsTest {\n"
      "  static NativeFields testMain() {\n"
      "    NativeFields obj = new NativeFields(10, 20);\n"
      "    return obj;\n"
      "  }\n"
      "}\n";
  TestIsolateScope __test_isolate__;
  {
    // Load up a test script in the test library.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars,
                                               native_field_lookup);

    // Invoke a function which returns an object of type NativeFields.
    Dart_Handle retobj = Dart_InvokeStatic(lib,
                                           Dart_NewString("NativeFieldsTest"),
                                           Dart_NewString("testMain"),
                                           0,
                                           NULL);
    EXPECT_VALID(retobj);

    // Now access and set various instance fields of the returned object.
    TestNativeFields(retobj);
  }
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    DARTSCOPE_NOCHECKS(Isolate::Current());

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object of type NativeFields.
    Dart_Handle retobj = Dart_InvokeStatic(lib,
                                           Dart_NewString("NativeFieldsTest"),
                                           Dart_NewString("testMain1"),
                                           0,
                                           NULL);
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
    retobj = Dart_InvokeStatic(lib,
                               Dart_NewString("NativeFieldsTest"),
                               Dart_NewString("testMain2"),
                               0,
                               NULL);
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
}


UNIT_TEST_CASE(GetStaticField_RunsInitializer) {
  const char* kScriptChars =
      "class TestClass  {\n"
      "  static final int fld1 = 7;\n"
      "  static int fld2 = 11;\n"
      "  static void testMain() {\n"
      "  }\n"
      "}\n";
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("TestClass"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);

    Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("TestClass"));
    EXPECT_VALID(cls);

    // For uninitialized fields, the getter is returned
    result = Dart_GetStaticField(cls, Dart_NewString("fld1"));
    EXPECT_VALID(result);
    int64_t value = 0;
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(7, value);

    result = Dart_GetStaticField(cls, Dart_NewString("fld2"));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(11, value);

    // Overwrite fld2
    result = Dart_SetStaticField(cls,
                                 Dart_NewString("fld2"),
                                 Dart_NewInteger(13));
    EXPECT_VALID(result);

    // We now get the new value for fld2, not the initializer
    result = Dart_GetStaticField(cls, Dart_NewString("fld2"));
    EXPECT_VALID(result);
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(13, value);
  }
}


UNIT_TEST_CASE(StaticFieldNotFound) {
  const char* kScriptChars =
      "class TestClass  {\n"
      "  static void testMain() {\n"
      "  }\n"
      "}\n";
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function.
    result = Dart_InvokeStatic(lib,
                               Dart_NewString("TestClass"),
                               Dart_NewString("testMain"),
                               0,
                               NULL);

    Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("TestClass"));
    EXPECT_VALID(cls);

    result = Dart_GetStaticField(cls, Dart_NewString("not_found"));
    EXPECT(Dart_IsError(result));
    EXPECT_STREQ("Specified field is not found in the class",
                 Dart_GetError(result));

    result = Dart_SetStaticField(cls,
                                 Dart_NewString("not_found"),
                                 Dart_NewInteger(13));
    EXPECT(Dart_IsError(result));
    EXPECT_STREQ("Specified field is not found in the class",
                 Dart_GetError(result));
  }
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    DARTSCOPE_NOCHECKS(Isolate::Current());

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object of type InvokeDynamic.
    Dart_Handle retobj = Dart_InvokeStatic(lib,
                                           Dart_NewString("InvokeDynamicTest"),
                                           Dart_NewString("testMain"),
                                           0,
                                           NULL);
    EXPECT_VALID(retobj);


    // Now invoke a dynamic method and check the result.
    Dart_Handle dart_arguments[1];
    dart_arguments[0] = Dart_NewInteger(1);
    result = Dart_InvokeDynamic(retobj,
                                Dart_NewString("method1"),
                                1,
                                dart_arguments);
    EXPECT_VALID(result);
    EXPECT(Dart_IsInteger(result));
    int64_t value = 0;
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(41, value);

    result = Dart_InvokeDynamic(retobj, Dart_NewString("method2"), 0, NULL);
    EXPECT(Dart_IsError(result));

    result = Dart_InvokeDynamic(retobj, Dart_NewString("method1"), 0, NULL);
    EXPECT(Dart_IsError(result));
  }
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    DARTSCOPE_NOCHECKS(Isolate::Current());

    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns a closure.
    Dart_Handle retobj = Dart_InvokeStatic(lib,
                                           Dart_NewString("InvokeClosureTest"),
                                           Dart_NewString("testMain1"),
                                           0,
                                           NULL);
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
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(51, value);

    // Invoke closure with wrong number of args, should result in exception.
    result = Dart_InvokeClosure(retobj, 0, NULL);
    EXPECT(Dart_IsError(result));
    EXPECT(Dart_ErrorHasException(result));

    // Invoke a function which returns a closure.
    retobj = Dart_InvokeStatic(lib,
                               Dart_NewString("InvokeClosureTest"),
                               Dart_NewString("testMain2"),
                               0,
                               NULL);
    EXPECT_VALID(retobj);

    EXPECT(Dart_IsClosure(retobj));
    EXPECT(!Dart_IsClosure(Dart_NewString("abcdef")));

    // Now invoke the closure and check the result (should be an exception).
    dart_arguments[0] = Dart_NewInteger(1);
    result = Dart_InvokeClosure(retobj, 1, dart_arguments);
    EXPECT(Dart_IsError(result));
    EXPECT(Dart_ErrorHasException(result));
  }
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;

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
    Dart_Handle retobj = Dart_InvokeStatic(lib,
                                           Dart_NewString("ThrowExceptionTest"),
                                           Dart_NewString("testMain"),
                                           0,
                                           NULL);
    EXPECT_VALID(retobj);

    // Throwing an exception here should result in an error.
    result = Dart_ThrowException(retobj);
    EXPECT(Dart_IsError(result));

    // Now invoke method2 which invokes a natve method where it is
    // ok to throw an exception, check the result which would indicate
    // if an exception was thrown or not.
    result = Dart_InvokeDynamic(retobj, Dart_NewString("method2"), 0, NULL);
    EXPECT_VALID(result);
    EXPECT(Dart_IsInteger(result));
    int64_t value = 0;
    result = Dart_IntegerValue(result, &value);
    EXPECT_EQ(5, value);

    Dart_ExitScope();  // Exit the Dart API scope.
    EXPECT_EQ(size, state->ZoneSizeInBytes());
  }
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


UNIT_TEST_CASE(GetNativeArgumentCount) {
  const char* kScriptChars =
      "class MyObject {"
      "  int method1(int i, int j) native 'Name_Does_Not_Matter';"
      "}"
      "class Test {"
      "  static testMain() {"
      "    MyObject obj = new MyObject();"
      "    return obj.method1(77, 125);"
      "  }"
      "}";

  TestIsolateScope __test_isolate__;
  {
    Dart_Handle lib = TestCase::LoadTestScript(
        kScriptChars,
        reinterpret_cast<Dart_NativeEntryResolver>(gnac_lookup));

    Dart_Handle result = Dart_InvokeStatic(lib,
                                           Dart_NewString("Test"),
                                           Dart_NewString("testMain"),
                                           0,
                                           NULL);
    EXPECT_VALID(result);
    EXPECT(Dart_IsInteger(result));

    int64_t value = 0;
    result = Dart_IntegerValue(result, &value);
    EXPECT_VALID(result);
    EXPECT_EQ(3, value);
  }
}


UNIT_TEST_CASE(GetClass) {
  const char* kScriptChars =
      "class DoesExist {"
      "}";

  TestIsolateScope __test_isolate__;

  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Lookup a class that does exist.
  Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("DoesExist"));
  EXPECT_VALID(cls);

  // Lookup a class that does not exist.
  cls = Dart_GetClass(lib, Dart_NewString("DoesNotExist"));
  EXPECT(Dart_IsError(cls));
  EXPECT_STREQ("Class 'DoesNotExist' not found in library 'dart:test-lib'.",
               Dart_GetError(cls));
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
  Dart_Handle result;

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);

    // Invoke a function which returns an object of type InstanceOf..
    Dart_Handle instanceOfTestObj =
        Dart_InvokeStatic(lib,
                          Dart_NewString("InstanceOfTest"),
                          Dart_NewString("testMain"),
                          0,
                          NULL);
    EXPECT_VALID(instanceOfTestObj);

    // Fetch InstanceOfTest class.
    Dart_Handle cls = Dart_GetClass(lib, Dart_NewString("InstanceOfTest"));
    EXPECT_VALID(cls);

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
    Dart_Handle null = Dart_InvokeStatic(lib,
                                         Dart_NewString("OtherClass"),
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
}


UNIT_TEST_CASE(NullReceiver) {
  TestIsolateScope __test_isolate__;
  {
    DARTSCOPE_NOCHECKS(Isolate::Current());

    Dart_Handle function_name = Dart_NewString("toString");
    const int number_of_arguments = 0;
    Dart_Handle null_receiver = Api::NewLocalHandle(Object::Handle());
    Dart_Handle result = Dart_InvokeDynamic(null_receiver,
                                            function_name,
                                            number_of_arguments,
                                            NULL);
    EXPECT_VALID(result);
    EXPECT(Dart_IsString(result));

    // Should throw a NullPointerException. Disabled due to bug 5415268.
    /*
    Dart_Handle function_name2 = Dart_NewString("NoNoNo");
    result = Dart_InvokeDynamic(null_receiver,
                                function_name2,
                                number_of_arguments,
                                dart_arguments);
    EXPECT(Dart_IsError(result));
    EXPECT(Dart_ErrorHasException(result)); */
  }
}


static Dart_Handle library_handler(Dart_LibraryTag tag,
                                   Dart_Handle library,
                                   Dart_Handle url) {
  if (tag == kCanonicalizeUrl) {
    return url;
  }
  return Api::Success();
}


UNIT_TEST_CASE(LoadScript) {
  const char* kScriptChars =
      "main() {"
      "  return 12345;"
      "}";

  TestIsolateScope __test_isolate__;

  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  Dart_Handle error = Dart_Error("incoming error");
  Dart_Handle result;

  result = Dart_LoadScript(Dart_Null(), source, library_handler);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript expects argument 'url' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadScript(Dart_True(), source, library_handler);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript expects argument 'url' to be of type String.",
               Dart_GetError(result));

  result = Dart_LoadScript(error, source, library_handler);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  result = Dart_LoadScript(url, Dart_Null(), library_handler);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript expects argument 'source' to be non-null.",
               Dart_GetError(result));

  result = Dart_LoadScript(url, Dart_True(), library_handler);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ(
      "Dart_LoadScript expects argument 'source' to be of type String.",
      Dart_GetError(result));

  result = Dart_LoadScript(url, error, library_handler);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("incoming error", Dart_GetError(result));

  // Load a script successfully.
  result = Dart_LoadScript(url, source, library_handler);
  EXPECT_VALID(result);

  result = Dart_InvokeStatic(result,
                             Dart_NewString(""),
                             Dart_NewString("main"),
                             0,
                             NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerValue(result, &value));
  EXPECT_EQ(12345, value);

  // Further calls to LoadScript are errors.
  result = Dart_LoadScript(url, source, library_handler);
  EXPECT(Dart_IsError(result));
  EXPECT_STREQ("Dart_LoadScript: "
               "A script has already been loaded from 'dart:test-lib'.",
               Dart_GetError(result));
}


UNIT_TEST_CASE(LoadScript_CompileError) {
  const char* kScriptChars =
      ")";

  TestIsolateScope __test_isolate__;

  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  Dart_Handle result = Dart_LoadScript(url, source, library_handler);
  EXPECT(Dart_IsError(result));
  EXPECT(strstr(Dart_GetError(result), "unexpected token ')'"));
}


UNIT_TEST_CASE(LookupLibrary) {
  const char* kScriptChars =
      "#import('library1.dart');"
      "main() {}";
  const char* kLibrary1Chars =
      "#library('library1.dart');"
      "#import('library2.dart');";

  TestIsolateScope __test_isolate__;

  // Create a test library and Load up a test script in it.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  Dart_Handle result = Dart_LoadScript(url, source, library_handler);
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


UNIT_TEST_CASE(LibraryUrl) {
  const char* kLibrary1Chars =
      "#library('library1_name');";

  TestIsolateScope __test_isolate__;

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


UNIT_TEST_CASE(LibraryImportLibrary) {
  const char* kLibrary1Chars =
      "#library('library1_name');";
  const char* kLibrary2Chars =
      "#library('library2_name');";

  TestIsolateScope __test_isolate__;

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



UNIT_TEST_CASE(LoadLibrary) {
  const char* kLibrary1Chars =
      "#library('library1_name');";

  TestIsolateScope __test_isolate__;

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


UNIT_TEST_CASE(LoadLibrary_CompileError) {
  const char* kLibrary1Chars =
      "#library('library1_name');"
      ")";

  TestIsolateScope __test_isolate__;

  Dart_Handle url = Dart_NewString("library1_url");
  Dart_Handle source = Dart_NewString(kLibrary1Chars);
  Dart_Handle result = Dart_LoadLibrary(url, source);
  EXPECT(Dart_IsError(result));
  EXPECT(strstr(Dart_GetError(result), "unexpected token ')'"));
}


UNIT_TEST_CASE(LoadSource) {
  const char* kLibrary1Chars =
      "#library('library1_name');";
  const char* kSourceChars =
      "// Something innocuous";
  const char* kBadSourceChars =
      ")";

  TestIsolateScope __test_isolate__;

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
  bool same = false;
  EXPECT_VALID(Dart_IsSame(lib, result, &same));
  EXPECT(same);

  // Duplicate calls are okay.
  result = Dart_LoadSource(lib, url, source);
  EXPECT_VALID(result);
  EXPECT(Dart_IsLibrary(result));
  same = false;
  EXPECT_VALID(Dart_IsSame(lib, result, &same));
  EXPECT(same);

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


UNIT_TEST_CASE(SetNativeResolver) {
  const char* kScriptChars =
      "class Test {"
      "  static foo() native \"SomeNativeFunction\";"
      "  static bar() native \"SomeNativeFunction2\";"
      "  static baz() native \"SomeNativeFunction3\";"
      "}";

  TestIsolateScope __test_isolate__;

  Dart_Handle error = Dart_Error("incoming error");
  Dart_Handle result;

  // Load a test script.
  Dart_Handle url = Dart_NewString(TestCase::url());
  Dart_Handle source = Dart_NewString(kScriptChars);
  Dart_Handle lib = Dart_LoadScript(url, source, library_handler);
  EXPECT_VALID(lib);
  EXPECT(Dart_IsLibrary(lib));

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
  result = Dart_InvokeStatic(lib,
                             Dart_NewString("Test"),
                             Dart_NewString("foo"),
                             0,
                             NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  int64_t value = 0;
  EXPECT_VALID(Dart_IntegerValue(result, &value));
  EXPECT_EQ(654321, value);

  // A second call succeeds.
  result = Dart_SetNativeResolver(lib, &MyNativeResolver2);
  EXPECT_VALID(result);

  // 'foo' has already been resolved so gets the old value.
  result = Dart_InvokeStatic(lib,
                             Dart_NewString("Test"),
                             Dart_NewString("foo"),
                             0,
                             NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  value = 0;
  EXPECT_VALID(Dart_IntegerValue(result, &value));
  EXPECT_EQ(654321, value);

  // 'bar' has not yet been resolved so gets the new value.
  result = Dart_InvokeStatic(lib,
                             Dart_NewString("Test"),
                             Dart_NewString("bar"),
                             0,
                             NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsInteger(result));
  value = 0;
  EXPECT_VALID(Dart_IntegerValue(result, &value));
  EXPECT_EQ(123456, value);

  // A NULL resolver is okay, but resolution will fail.
  result = Dart_SetNativeResolver(lib, NULL);
  EXPECT_VALID(result);

  result = Dart_InvokeStatic(lib,
                             Dart_NewString("Test"),
                             Dart_NewString("baz"),
                             0,
                             NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(strstr(Dart_GetError(result),
                "native function 'SomeNativeFunction3' cannot be found"));
}


UNIT_TEST_CASE(ImportLibrary1) {
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

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle url = Dart_NewString(TestCase::url());
    Dart_Handle source = Dart_NewString(kScriptChars);
    result = Dart_LoadScript(url, source, library_handler);

    url = Dart_NewString("library1.dart");
    source = Dart_NewString(kLibrary1Chars);
    Dart_LoadLibrary(url, source);

    url = Dart_NewString("library2.dart");
    source = Dart_NewString(kLibrary2Chars);
    Dart_LoadLibrary(url, source);

    result = Dart_InvokeStatic(result,
                               Dart_NewString(""),
                               Dart_NewString("main"),
                               0,
                               NULL);
    EXPECT(Dart_IsError(result));
    EXPECT_STREQ("Duplicate definition : 'foo' is defined in"
                 " 'library2.dart' and 'dart:test-lib'\n",
                 Dart_GetError(result));
  }
}


UNIT_TEST_CASE(ImportLibrary2) {
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

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle url = Dart_NewString(TestCase::url());
    Dart_Handle source = Dart_NewString(kScriptChars);
    result = Dart_LoadScript(url, source, library_handler);

    url = Dart_NewString("library1.dart");
    source = Dart_NewString(kLibrary1Chars);
    Dart_LoadLibrary(url, source);

    url = Dart_NewString("library2.dart");
    source = Dart_NewString(kLibrary2Chars);
    Dart_LoadLibrary(url, source);

    result = Dart_InvokeStatic(result,
                               Dart_NewString(""),
                               Dart_NewString("main"),
                               0,
                               NULL);
    EXPECT_VALID(result);
  }
}


UNIT_TEST_CASE(ImportLibrary3) {
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

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle url = Dart_NewString(TestCase::url());
    Dart_Handle source = Dart_NewString(kScriptChars);
    result = Dart_LoadScript(url, source, library_handler);

    url = Dart_NewString("library2.dart");
    source = Dart_NewString(kLibrary2Chars);
    Dart_LoadLibrary(url, source);

    url = Dart_NewString("library1.dart");
    source = Dart_NewString(kLibrary1Chars);
    Dart_LoadLibrary(url, source);

    result = Dart_InvokeStatic(result,
                               Dart_NewString(""),
                               Dart_NewString("main"),
                               0,
                               NULL);
    EXPECT(Dart_IsError(result));
    EXPECT_STREQ("Duplicate definition : 'foo' is defined in"
                 " 'library1.dart' and 'library2.dart'\n",
                 Dart_GetError(result));
  }
}


UNIT_TEST_CASE(ImportLibrary4) {
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

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle url = Dart_NewString(TestCase::url());
    Dart_Handle source = Dart_NewString(kScriptChars);
    result = Dart_LoadScript(url, source, library_handler);

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

    result = Dart_InvokeStatic(result,
                               Dart_NewString(""),
                               Dart_NewString("main"),
                               0,
                               NULL);
    EXPECT(Dart_IsError(result));
    EXPECT_STREQ("Duplicate definition : 'fooC' is defined in"
                 " 'libraryF.dart' and 'libraryC.dart'\n",
                 Dart_GetError(result));
  }
}


UNIT_TEST_CASE(ImportLibrary5) {
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

  TestIsolateScope __test_isolate__;
  {
    // Create a test library and Load up a test script in it.
    Dart_Handle url = Dart_NewString(TestCase::url());
    Dart_Handle source = Dart_NewString(kScriptChars);
    result = Dart_LoadScript(url, source, library_handler);

    url = Dart_NewString("lib.dart");
    source = Dart_NewString(kLibraryChars);
    Dart_LoadLibrary(url, source);

    result = Dart_InvokeStatic(result,
                               Dart_NewString(""),
                               Dart_NewString("main"),
                               0,
                               NULL);
    EXPECT_VALID(result);
  }
}


static bool RunLoopTestCallback(void* data, char** error) {
  const char* kScriptChars =
      "#import('builtin');\n"
      "class MyIsolate extends Isolate {\n"
      "  MyIsolate() : super() { }\n"
      "  void main() {\n"
      "    port.receive((message, replyTo) {\n"
      "      if (message) {\n"
      "        throw new Exception('MakeVMExit');\n"
      "      } else {\n"
      "        replyTo.call('hello');\n"
      "        port.close();\n"
      "      }\n"
      "    });\n"
      "  }\n"
      "}\n"
      "\n"
      "void main(message) {\n"
      "  new MyIsolate().spawn().then((port) {\n"
      "    port.call(message).receive((message, replyTo) {\n"
      "      if (message != 'hello') throw new Exception('ShouldNotHappen');\n"
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
  Dart_Handle lib = Dart_LoadScript(url, source, TestCase::library_handler);
  EXPECT_VALID(lib);
  Dart_ExitScope();
  return true;
}


// Common code for RunLoop_Success/RunLoop_Failure.
static void RunLoopTest(bool throw_exception) {
  Dart_IsolateCreateCallback saved = Isolate::CreateCallback();
  Isolate::SetCreateCallback(RunLoopTestCallback);
  RunLoopTestCallback(NULL, NULL);

  Dart_EnterScope();
  Dart_Handle lib = Dart_LookupLibrary(Dart_NewString(TestCase::url()));
  EXPECT_VALID(lib);

  Dart_Handle result;
  Dart_Handle args[1];
  args[0] = (throw_exception ? Dart_True() : Dart_False());
  result = Dart_InvokeStatic(lib,
                             Dart_NewString(""),
                             Dart_NewString("main"),
                             1,
                             args);
  EXPECT_VALID(result);
  result = Dart_RunLoop();
  EXPECT_VALID(result);

  Dart_ExitScope();
  Dart_ShutdownIsolate();

  Isolate::SetCreateCallback(saved);
}


UNIT_TEST_CASE(RunLoop_Success) {
  RunLoopTest(false);
}


UNIT_TEST_CASE(RunLoop_Exception) {
  RunLoopTest(true);
}

#endif  // TARGET_ARCH_IA32.

}  // namespace dart
