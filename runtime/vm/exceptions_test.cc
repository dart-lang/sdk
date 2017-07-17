// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/dart_api_impl.h"
#include "vm/unit_test.h"

namespace dart {

#define FUNCTION_NAME(name) UnhandledExcp_##name
#define REGISTER_FUNCTION(name, count) {"" #name, FUNCTION_NAME(name), count},

void FUNCTION_NAME(Unhandled_equals)(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  const Instance& expected = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const Instance& actual = Instance::CheckedHandle(arguments->NativeArgAt(1));
  if (!expected.CanonicalizeEquals(actual)) {
    OS::Print("expected: '%s' actual: '%s'\n", expected.ToCString(),
              actual.ToCString());
    FATAL("Unhandled_equals fails.\n");
  }
}

void FUNCTION_NAME(Unhandled_invoke)(Dart_NativeArguments args) {
  // Invoke the specified entry point.
  Dart_Handle cls = Dart_GetClass(TestCase::lib(), NewString("Second"));
  Dart_Handle result = Dart_Invoke(cls, NewString("method2"), 0, NULL);
  ASSERT(Dart_IsError(result));
  ASSERT(Dart_ErrorHasException(result));
  return;
}

void FUNCTION_NAME(Unhandled_invoke2)(Dart_NativeArguments args) {
  // Invoke the specified entry point.
  Dart_Handle cls = Dart_GetClass(TestCase::lib(), NewString("Second"));
  Dart_Handle result = Dart_Invoke(cls, NewString("method2"), 0, NULL);
  ASSERT(Dart_IsError(result));
  ASSERT(Dart_ErrorHasException(result));
  Dart_Handle exception = Dart_ErrorGetException(result);
  ASSERT(!Dart_IsError(exception));
  Dart_ThrowException(exception);
  UNREACHABLE();
  return;
}

// List all native functions implemented in the vm or core boot strap dart
// libraries so that we can resolve the native function to it's entry
// point.
#define UNHANDLED_NATIVE_LIST(V)                                               \
  V(Unhandled_equals, 2)                                                       \
  V(Unhandled_invoke, 0)                                                       \
  V(Unhandled_invoke2, 0)

static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} BuiltinEntries[] = {UNHANDLED_NATIVE_LIST(REGISTER_FUNCTION)};

static Dart_NativeFunction native_lookup(Dart_Handle name,
                                         int argument_count,
                                         bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  ASSERT(obj.IsString());
  const char* function_name = obj.ToCString();
  ASSERT(function_name != NULL);
  int num_entries = sizeof(BuiltinEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(BuiltinEntries[i]);
    if (!strcmp(function_name, entry->name_) &&
        (argument_count == entry->argument_count_)) {
      return reinterpret_cast<Dart_NativeFunction>(entry->function_);
    }
  }
  return NULL;
}

// Unit test case to verify unhandled exceptions.
TEST_CASE(UnhandledExceptions) {
  const char* kScriptChars =
      "class UnhandledExceptions {\n"
      "  static equals(var obj1, var obj2) native \"Unhandled_equals\";"
      "  static invoke() native \"Unhandled_invoke\";\n"
      "  static invoke2() native \"Unhandled_invoke2\";\n"
      "}\n"
      "class Second {\n"
      "  Second() { }\n"
      "  static int method1(int param) {\n"
      "    UnhandledExceptions.invoke();\n"
      "    return 2;\n"
      "  }\n"
      "  static int method2() {\n"
      "    throw new Second();\n"
      "  }\n"
      "  static int method3(int param) {\n"
      "    try {\n"
      "      UnhandledExceptions.invoke2();\n"
      "    } on Second catch (e) {\n"
      "      return 3;\n"
      "    }\n"
      "    return 2;\n"
      "  }\n"
      "}\n"
      "testMain() {\n"
      "  UnhandledExceptions.equals(2, Second.method1(1));\n"
      "  UnhandledExceptions.equals(3, Second.method3(1));\n"
      "}";
  Dart_Handle lib = TestCase::LoadTestScript(
      kScriptChars, reinterpret_cast<Dart_NativeEntryResolver>(native_lookup));
  EXPECT_VALID(Dart_Invoke(lib, NewString("testMain"), 0, NULL));
}

}  // namespace dart
