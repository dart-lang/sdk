// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "./include/dart_api.h"
#include "./include/dart_native_api.h"

#define CHECK(H)                                                               \
  do {                                                                         \
    Dart_Handle __handle__ = H;                                                \
    if (Dart_IsError(__handle__)) {                                            \
      const char* message = Dart_GetError(__handle__);                         \
      fprintf(stderr, "Check \"" #H "\" failed: %s", message);                 \
      abort();                                                                 \
    }                                                                          \
  } while (false)

#define ASSERT(E)                                                              \
  if (!(E)) {                                                                  \
    fprintf(stderr, "Assertion \"" #E "\" failed at %s:%d!\n", __FILE__,       \
            __LINE__);                                                         \
    abort();                                                                   \
  }

bool isDartPrecompiledRuntime = true;

// Some invalid accesses are allowed in AOT since we don't retain @pragma
// annotations. Therefore we skip the negative tests in AOT.
#define FAIL(name, result)                                                     \
  if (!isDartPrecompiledRuntime) {                                             \
    Fail(name, result);                                                        \
  }

void Fail(const char* name, Dart_Handle result) {
  ASSERT(Dart_IsApiError(result));
  const char* error = Dart_GetError(result);
  ASSERT(strstr(error, name));
  ASSERT(strstr(error, "It is illegal to access"));
}

#define FAIL_INVOKE_FIELD(name, result)                                        \
  if (!isDartPrecompiledRuntime) {                                             \
    FailInvokeField(name, result);                                             \
  }

void FailInvokeField(const char* name, Dart_Handle result) {
  ASSERT(Dart_IsApiError(result));
  const char* error = Dart_GetError(result);
  ASSERT(strstr(error, name));
  ASSERT(strstr(error, "Entry-points do not allow invoking fields"));
}

void FailClosurizeConstructor(const char* name, Dart_Handle result) {
  ASSERT(Dart_IsUnhandledExceptionError(result));
  const char* error = Dart_GetError(result);
  ASSERT(strstr(error, name));
  ASSERT(strstr(error, "No static getter"));
}

void TestFields(Dart_Handle target) {
  FAIL("fld0", Dart_GetField(target, Dart_NewStringFromCString("fld0")));
  FAIL("fld0",
       Dart_SetField(target, Dart_NewStringFromCString("fld0"), Dart_Null()));

  FAIL_INVOKE_FIELD(
      "fld0",
      Dart_Invoke(target, Dart_NewStringFromCString("fld0"), 0, nullptr));

  CHECK(Dart_GetField(target, Dart_NewStringFromCString("fld1")));
  CHECK(Dart_SetField(target, Dart_NewStringFromCString("fld1"), Dart_Null()));
  FAIL_INVOKE_FIELD(
      "fld1",
      Dart_Invoke(target, Dart_NewStringFromCString("fld1"), 0, nullptr));

  CHECK(Dart_GetField(target, Dart_NewStringFromCString("fld2")));
  FAIL("fld2",
       Dart_SetField(target, Dart_NewStringFromCString("fld2"), Dart_Null()));
  FAIL_INVOKE_FIELD(
      "fld2",
      Dart_Invoke(target, Dart_NewStringFromCString("fld2"), 0, nullptr));

  FAIL("fld3", Dart_GetField(target, Dart_NewStringFromCString("fld3")));
  CHECK(Dart_SetField(target, Dart_NewStringFromCString("fld3"), Dart_Null()));
  FAIL_INVOKE_FIELD(
      "fld3",
      Dart_Invoke(target, Dart_NewStringFromCString("fld3"), 0, nullptr));
}

void RunTests(Dart_NativeArguments arguments) {
  Dart_Handle lib = Dart_RootLibrary();

  //////// Test allocation and constructor invocation.

  FAIL("C", Dart_GetClass(lib, Dart_NewStringFromCString("C")));

  Dart_Handle D_class = Dart_GetClass(lib, Dart_NewStringFromCString("D"));
  CHECK(D_class);

  CHECK(Dart_Allocate(D_class));

  FAIL("D.", Dart_New(D_class, Dart_Null(), 0, nullptr));

  CHECK(Dart_New(D_class, Dart_NewStringFromCString("defined"), 0, nullptr));
  Dart_Handle D =
      Dart_New(D_class, Dart_NewStringFromCString("fact"), 0, nullptr);
  CHECK(D);

  //////// Test actions against methods

  FailClosurizeConstructor(
      "defined", Dart_GetField(D_class, Dart_NewStringFromCString("defined")));
  FailClosurizeConstructor(
      "fact", Dart_GetField(D_class, Dart_NewStringFromCString("fact")));

  FAIL("fn0", Dart_Invoke(D, Dart_NewStringFromCString("fn0"), 0, nullptr));

  CHECK(Dart_Invoke(D, Dart_NewStringFromCString("fn1"), 0, nullptr));
  FAIL("fn1", Dart_Invoke(D, Dart_NewStringFromCString("fn1_get"), 0, nullptr));
  CHECK(Dart_Invoke(D, Dart_NewStringFromCString("fn1_call"), 0, nullptr));

  FAIL("fn0", Dart_GetField(D, Dart_NewStringFromCString("fn0")));

  CHECK(Dart_GetField(D, Dart_NewStringFromCString("fn1")));
  CHECK(Dart_GetField(D, Dart_NewStringFromCString("fn1_get")));
  FAIL("fn1", Dart_GetField(D, Dart_NewStringFromCString("fn1_call")));

  FAIL("fn2",
       Dart_Invoke(D_class, Dart_NewStringFromCString("fn2"), 0, nullptr));

  CHECK(Dart_Invoke(D_class, Dart_NewStringFromCString("fn3"), 0, nullptr));
  CHECK(
      Dart_Invoke(D_class, Dart_NewStringFromCString("fn3_call"), 0, nullptr));
  FAIL("fn3",
       Dart_Invoke(D_class, Dart_NewStringFromCString("fn3_get"), 0, nullptr));

  FAIL("fn2", Dart_GetField(D_class, Dart_NewStringFromCString("fn2")));

  CHECK(Dart_GetField(D_class, Dart_NewStringFromCString("fn3")));
  FAIL("fn3_call",
       Dart_GetField(D_class, Dart_NewStringFromCString("fn3_call")));
  CHECK(Dart_GetField(D_class, Dart_NewStringFromCString("fn3_get")));

  FAIL("fn0", Dart_Invoke(lib, Dart_NewStringFromCString("fn0"), 0, nullptr));

  CHECK(Dart_Invoke(lib, Dart_NewStringFromCString("fn1"), 0, nullptr));
  FAIL("fn1",
       Dart_Invoke(lib, Dart_NewStringFromCString("fn1_get"), 0, nullptr));
  CHECK(Dart_Invoke(lib, Dart_NewStringFromCString("fn1_call"), 0, nullptr));

  FAIL("fn0", Dart_GetField(lib, Dart_NewStringFromCString("fn0")));

  CHECK(Dart_GetField(lib, Dart_NewStringFromCString("fn1")));
  CHECK(Dart_GetField(lib, Dart_NewStringFromCString("fn1_get")));
  FAIL("fn1", Dart_GetField(lib, Dart_NewStringFromCString("fn1_call")));

  //////// Test actions against fields

  TestFields(D);

  Dart_Handle F_class = Dart_GetClass(lib, Dart_NewStringFromCString("F"));
  TestFields(F_class);

  TestFields(lib);
}

Dart_NativeFunction ResolveName(Dart_Handle name,
                                int argc,
                                bool* auto_setup_scope) {
  if (auto_setup_scope == NULL) {
    return NULL;
  }
  *auto_setup_scope = true;
  return RunTests;
}

DART_EXPORT Dart_Handle
entrypoints_verification_test_extension_Init(Dart_Handle parent_library) {
  isDartPrecompiledRuntime = Dart_IsPrecompiledRuntime();

  if (Dart_IsError(parent_library)) {
    return parent_library;
  }

  Dart_Handle result_code =
      Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if (Dart_IsError(result_code)) {
    return result_code;
  }

  return Dart_Null();
}
