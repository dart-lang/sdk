// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstdio>
#include <cstdlib>
#include <cstring>

// TODO(dartbug.com/40579): This requires static linking to either link
// dart.exe or dartaotruntime.exe on Windows.
// The sample currently fails on Windows in AOT mode.
#include "include/dart_api.h"
#include "include/dart_native_api.h"

static bool is_dartaotruntime = true;

bool IsTreeShaken(const char* name, Dart_Handle handle, const char* error) {
  // No tree shaking in the JIT runtime.
  if (!is_dartaotruntime) return false;
  if (Dart_IsApiError(handle)) {
    // All tree-shaking related API errors should include the expected name.
    if (strstr(error, name) == nullptr) return false;
    // Node was tree shaken (e.g., 'Class C not found in library...').
    if (strstr(error, " not found in ") != nullptr) return true;
    // Constructor was tree shaken.
    if (strstr(error, "Dart_New: could not find ") != nullptr) return true;
  } else if (Dart_IsUnhandledExceptionError(handle)) {
    // TFA replaces operations with a throw in some cases. If obfuscation
    // is turned on and the member has no entry point annotation, then its
    // name may be obfuscated in the result and so cannot be depended on.
    if (strstr(error, "Attempt to execute code removed by ") != nullptr) {
      return true;
    }
    // All other tree-shaking related unhandled exceptions are NSM errors
    // that should include the expected name.
    if (strstr(error, name) == nullptr) return false;
    if (strstr(error, "NoSuchMethodError: ") == nullptr) {
      return false;
    }
    if (strstr(error, "No top-level method '") != nullptr) return true;
    if (strstr(error, "No top-level getter '") != nullptr) return true;
    if (strstr(error, "No top-level setter '") != nullptr) return true;
    if (strstr(error, "No static method '") != nullptr) return true;
    if (strstr(error, "No static getter '") != nullptr) return true;
    if (strstr(error, "No static setter '") != nullptr) return true;
    if (strstr(error, "' has no instance method '") != nullptr) return true;
    if (strstr(error, "' has no instance getter '") != nullptr) return true;
    if (strstr(error, "' has no instance setter '") != nullptr) return true;
  }
  // Not an tree shaking-related error.
  return false;
}

#if defined(_MSC_VER)
#define FATAL(fmt, ...)                                                        \
  do {                                                                         \
    fprintf(stderr, "Failed at %s:%d: " fmt "!\n", __FILE__, __LINE__,         \
            __VA_ARGS__);                                                      \
    abort();                                                                   \
  } while (false)
#else
#define FATAL(fmt, ...)                                                        \
  do {                                                                         \
    fprintf(stderr, "Failed at %s:%d: " fmt "!\n", __FILE__, __LINE__,         \
            ##__VA_ARGS__);                                                    \
    abort();                                                                   \
  } while (false)
#endif

#define CHECK(H)                                                               \
  do {                                                                         \
    fprintf(stderr, "Checking %s...\n", #H);                                   \
    Dart_Handle __handle__ = H;                                                \
    if (Dart_IsError(__handle__)) {                                            \
      const char* message = Dart_GetError(__handle__);                         \
      FATAL("\n%s", message);                                                  \
    } else {                                                                   \
      fprintf(stderr, "  Check passed.\n\n");                                  \
    }                                                                          \
  } while (false)

#define ASSERT_SUBSTRING(needle, haystack)                                     \
  do {                                                                         \
    if (strstr(haystack, needle) == nullptr) {                                 \
      FATAL("expected '%s' within:\n%s\n", needle, haystack);                  \
    }                                                                          \
  } while (false)

#define FAIL(name, result)                                                     \
  do {                                                                         \
    fprintf(stderr, "Expect failure to access '%s'\n", name);                  \
    if (!Dart_IsError(result)) {                                               \
      FATAL("No error for accessing %s", name);                                \
    }                                                                          \
    const char* error = Dart_GetError(result);                                 \
    if (IsTreeShaken(name, result, error)) {                                   \
      fprintf(stderr, "  Received error due to tree shaking: %s\n\n", error);  \
    } else if (!Dart_IsApiError(result)) {                                     \
      FATAL("Not an API error for accessing %s: %s", name, error);             \
    } else {                                                                   \
      ASSERT_SUBSTRING(name, error);                                           \
      ASSERT_SUBSTRING("ERROR: ", error);                                      \
      ASSERT_SUBSTRING("' from native code, it must be annotated.", error);    \
      fprintf(stderr, "  Received expected error: %s\n\n", error);             \
    }                                                                          \
  } while (false)

// Some invalid accesses are allowed in AOT since we don't retain @pragma
// annotations. Only use this if there's no other way to detect missing
// annotations, e.g., a function with no code signals that the precompiler
// did not preserve the code object because the function is not annotated
// as a "call" entry point.
#define FAIL_UNLESS_PRECOMPILED(name, result)                                  \
  do {                                                                         \
    if (!is_dartaotruntime) {                                                  \
      FAIL(name, result);                                                      \
    } else {                                                                   \
      CHECK(result);                                                           \
    }                                                                          \
  } while (false);

#define FAIL_CLOSURIZE_CONSTRUCTOR(name, result)                               \
  do {                                                                         \
    fprintf(stderr, "Expect failure to closurize constructor '%s'\n", name);   \
    if (!Dart_IsError(result)) {                                               \
      FATAL("No error for closurizing %s", name);                              \
    }                                                                          \
    const char* error = Dart_GetError(result);                                 \
    if (!Dart_IsUnhandledExceptionError(result)) {                             \
      FATAL("Not an unhandled exception error for closurizing %s: %s", name,   \
            error);                                                            \
    } else {                                                                   \
      ASSERT_SUBSTRING(name, error);                                           \
      ASSERT_SUBSTRING("No static getter", error);                             \
      fprintf(stderr, "  Received expected error: %s\n\n", error);             \
    }                                                                          \
  } while (false)

#define TEST_FIELDS(target)                                                    \
  do {                                                                         \
    /* Since the fields start off initialized to a non-null value and then */  \
    /* are updated with a null value, check invocation prior to set.       */  \
    FAIL("fld0", Dart_GetField(target, Dart_NewStringFromCString("fld0")));    \
    FAIL("fld0",                                                               \
         Dart_Invoke(target, Dart_NewStringFromCString("fld0"), 0, nullptr));  \
    FAIL("fld0", Dart_SetField(target, Dart_NewStringFromCString("fld0"),      \
                               Dart_Null()));                                  \
    CHECK(Dart_GetField(target, Dart_NewStringFromCString("fld1")));           \
    CHECK(Dart_Invoke(target, Dart_NewStringFromCString("fld1"), 0, nullptr)); \
    CHECK(Dart_SetField(target, Dart_NewStringFromCString("fld1"),             \
                        Dart_Null()));                                         \
    CHECK(Dart_GetField(target, Dart_NewStringFromCString("fld2")));           \
    CHECK(Dart_Invoke(target, Dart_NewStringFromCString("fld2"), 0, nullptr)); \
    if (Dart_IsLibrary(target) || Dart_IsType(target)) {                       \
      /* There are no implicit setters for static fields, so the pragma     */ \
      /* must be checked; in precompiled mode, that means a false positive. */ \
      FAIL_UNLESS_PRECOMPILED(                                                 \
          "fld2", Dart_SetField(target, Dart_NewStringFromCString("fld2"),     \
                                Dart_Null()));                                 \
    } else {                                                                   \
      FAIL("fld2", Dart_SetField(target, Dart_NewStringFromCString("fld2"),    \
                                 Dart_Null()));                                \
    }                                                                          \
    FAIL("fld3", Dart_GetField(target, Dart_NewStringFromCString("fld3")));    \
    FAIL("fld3",                                                               \
         Dart_Invoke(target, Dart_NewStringFromCString("fld3"), 0, nullptr));  \
    CHECK(Dart_SetField(target, Dart_NewStringFromCString("fld3"),             \
                        Dart_Null()));                                         \
  } while (false)

#define TEST_GETTERS(target)                                                   \
  do {                                                                         \
    FAIL("get1", Dart_GetField(target, Dart_NewStringFromCString("get1")));    \
    CHECK(Dart_GetField(target, Dart_NewStringFromCString("get2")));           \
    CHECK(Dart_GetField(target, Dart_NewStringFromCString("get3")));           \
  } while (false)

#define TEST_SETTERS(target, value)                                            \
  do {                                                                         \
    FAIL("set1",                                                               \
         Dart_SetField(target, Dart_NewStringFromCString("set1"), value));     \
    CHECK(Dart_SetField(target, Dart_NewStringFromCString("set2"), value));    \
    CHECK(Dart_SetField(target, Dart_NewStringFromCString("set3"), value));    \
  } while (false)

DART_EXPORT void RunTests() {
  is_dartaotruntime = Dart_IsPrecompiledRuntime();

  Dart_Handle lib = Dart_RootLibrary();

  //////// Test class access.

  FAIL("C", Dart_GetClass(lib, Dart_NewStringFromCString("C")));

  Dart_Handle D_class = Dart_GetClass(lib, Dart_NewStringFromCString("D"));
  CHECK(D_class);

  Dart_Handle F_class = Dart_GetClass(lib, Dart_NewStringFromCString("F"));
  CHECK(F_class);

  //////// Test allocation and constructor invocation.

  CHECK(Dart_Allocate(D_class));

  FAIL("D.", Dart_New(D_class, Dart_Null(), 0, nullptr));

  CHECK(Dart_New(D_class, Dart_NewStringFromCString("defined"), 0, nullptr));
  Dart_Handle D =
      Dart_New(D_class, Dart_NewStringFromCString("fact"), 0, nullptr);
  CHECK(D);

  //////// Test actions against methods

  fprintf(stderr, "\n\nTesting methods with library target\n\n\n");

  FAIL("noop", Dart_Invoke(lib, Dart_NewStringFromCString("noop"), 0, nullptr));

  FAIL("fn0", Dart_Invoke(lib, Dart_NewStringFromCString("fn0"), 0, nullptr));

  CHECK(Dart_Invoke(lib, Dart_NewStringFromCString("fn1"), 0, nullptr));
  FAIL("fn1_get",
       Dart_Invoke(lib, Dart_NewStringFromCString("fn1_get"), 0, nullptr));
  CHECK(Dart_Invoke(lib, Dart_NewStringFromCString("fn1_call"), 0, nullptr));

  FAIL("fn0", Dart_GetField(lib, Dart_NewStringFromCString("fn0")));

  CHECK(Dart_GetField(lib, Dart_NewStringFromCString("fn1")));
  CHECK(Dart_GetField(lib, Dart_NewStringFromCString("fn1_get")));
  FAIL("fn1_call", Dart_GetField(lib, Dart_NewStringFromCString("fn1_call")));

  fprintf(stderr, "\n\nTesting methods with class target\n\n\n");

  FAIL_CLOSURIZE_CONSTRUCTOR(
      "defined", Dart_GetField(D_class, Dart_NewStringFromCString("defined")));
  FAIL_CLOSURIZE_CONSTRUCTOR(
      "fact", Dart_GetField(D_class, Dart_NewStringFromCString("fact")));

  FAIL("fn0", Dart_Invoke(D, Dart_NewStringFromCString("fn0"), 0, nullptr));

  FAIL("fn2",
       Dart_Invoke(D_class, Dart_NewStringFromCString("fn2"), 0, nullptr));

  CHECK(Dart_Invoke(D_class, Dart_NewStringFromCString("fn3"), 0, nullptr));
  CHECK(
      Dart_Invoke(D_class, Dart_NewStringFromCString("fn3_call"), 0, nullptr));
  FAIL("fn3_get",
       Dart_Invoke(D_class, Dart_NewStringFromCString("fn3_get"), 0, nullptr));

  FAIL("fn2", Dart_GetField(D_class, Dart_NewStringFromCString("fn2")));

  CHECK(Dart_GetField(D_class, Dart_NewStringFromCString("fn3")));
  FAIL("fn3_call",
       Dart_GetField(D_class, Dart_NewStringFromCString("fn3_call")));
  CHECK(Dart_GetField(D_class, Dart_NewStringFromCString("fn3_get")));

  fprintf(stderr, "\n\nTesting methods with instance target\n\n\n");

  CHECK(Dart_Invoke(D, Dart_NewStringFromCString("fn1"), 0, nullptr));
  FAIL("fn1_get",
       Dart_Invoke(D, Dart_NewStringFromCString("fn1_get"), 0, nullptr));
  CHECK(Dart_Invoke(D, Dart_NewStringFromCString("fn1_call"), 0, nullptr));

  FAIL("fn0", Dart_GetField(D, Dart_NewStringFromCString("fn0")));

  CHECK(Dart_GetField(D, Dart_NewStringFromCString("fn1")));
  CHECK(Dart_GetField(D, Dart_NewStringFromCString("fn1_get")));
  FAIL("fn1_call", Dart_GetField(D, Dart_NewStringFromCString("fn1_call")));

  //////// Test actions against fields

  fprintf(stderr, "\n\nTesting fields with library target\n\n\n");
  TEST_FIELDS(lib);

  fprintf(stderr, "\n\nTesting fields with class target\n\n\n");
  TEST_FIELDS(F_class);

  fprintf(stderr, "\n\nTesting fields with instance target\n\n\n");
  TEST_FIELDS(D);

  //////// Test actions against getter and setter functions.

  fprintf(stderr, "\n\nTesting getters with library target\n\n\n");
  TEST_GETTERS(lib);

  fprintf(stderr, "\n\nTesting getters with class target\n\n\n");
  TEST_GETTERS(F_class);

  fprintf(stderr, "\n\nTesting getters with instance target\n\n\n");
  TEST_GETTERS(D);

  Dart_Handle test_value =
      Dart_GetField(lib, Dart_NewStringFromCString("testValue"));
  CHECK(test_value);

  fprintf(stderr, "\n\nTesting setters with library target\n\n\n");
  TEST_SETTERS(lib, test_value);

  fprintf(stderr, "\n\nTesting setters with class target\n\n\n");
  TEST_SETTERS(F_class, test_value);

  fprintf(stderr, "\n\nTesting setters with instance target\n\n\n");
  TEST_SETTERS(D, test_value);
}
