// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "./include/dart_api.h"
#include "./include/dart_native_api.h"

#define CHECK(H) DART_CHECK_VALID(H)

#define ASSERT(E)                                                              \
  if (!(E)) {                                                                  \
    fprintf(stderr, "Assertion \"" #E "\" failed!");                           \
    abort();                                                                   \
  }

Dart_Handle GetCurrentLibrary() {
  Dart_Handle libraries = Dart_GetLoadedLibraries();
  CHECK(libraries);
  intptr_t length = 0;
  CHECK(Dart_ListLength(libraries, &length));
  for (intptr_t i = 0; i < length; ++i) {
    Dart_Handle library = Dart_ListGetAt(libraries, i);
    CHECK(library);
    Dart_Handle url = Dart_LibraryUrl(library);
    CHECK(url);
    const char* url_str;
    CHECK(Dart_StringToCString(url, &url_str));
    if (strstr(url_str, "entrypoints_verification_test")) {
      return library;
    }
  }
  fprintf(stderr, "Could not find current library!");
  abort();
}

void Fail(const char* name, Dart_Handle result) {
  ASSERT(Dart_IsApiError(result));
  const char* error = Dart_GetError(result);
  ASSERT(strstr(error, name));
  ASSERT(strstr(error, "It is illegal to access"));
}

void FailClosurize(const char* name, Dart_Handle result) {
  ASSERT(Dart_IsApiError(result));
  const char* error = Dart_GetError(result);
  ASSERT(strstr(error, name));
  ASSERT(strstr(error, "Entry-points do not allow closurizing methods"));
}

void TestFields(Dart_Handle target) {
  Fail("fld0", Dart_GetField(target, Dart_NewStringFromCString("fld0")));
  Fail("fld0",
       Dart_SetField(target, Dart_NewStringFromCString("fld0"), Dart_Null()));

  Dart_Handle result =
      Dart_Invoke(target, Dart_NewStringFromCString("fld0"), 0, nullptr);
  FailClosurize("fld0", result);

  CHECK(Dart_GetField(target, Dart_NewStringFromCString("fld1")));
  CHECK(Dart_SetField(target, Dart_NewStringFromCString("fld1"), Dart_Null()));
  FailClosurize("fld1", Dart_Invoke(target, Dart_NewStringFromCString("fld1"),
                                    0, nullptr));

  CHECK(Dart_GetField(target, Dart_NewStringFromCString("fld2")));
  Fail("fld2",
       Dart_SetField(target, Dart_NewStringFromCString("fld2"), Dart_Null()));
  FailClosurize("fld2", Dart_Invoke(target, Dart_NewStringFromCString("fld2"),
                                    0, nullptr));

  Fail("fld3", Dart_GetField(target, Dart_NewStringFromCString("fld3")));
  CHECK(Dart_SetField(target, Dart_NewStringFromCString("fld3"), Dart_Null()));
  FailClosurize("fld3", Dart_Invoke(target, Dart_NewStringFromCString("fld3"),
                                    0, nullptr));
}

void RunTests(Dart_NativeArguments arguments) {
  Dart_Handle lib = GetCurrentLibrary();

  //////// Test allocation and constructor invocation.

  Fail("C", Dart_GetClass(lib, Dart_NewStringFromCString("C")));

  Dart_Handle D_class = Dart_GetClass(lib, Dart_NewStringFromCString("D"));
  CHECK(D_class);

  CHECK(Dart_Allocate(D_class));

  Fail("D.", Dart_New(D_class, Dart_Null(), 0, nullptr));

  CHECK(Dart_New(D_class, Dart_NewStringFromCString("defined"), 0, nullptr));
  Dart_Handle D =
      Dart_New(D_class, Dart_NewStringFromCString("fact"), 0, nullptr);
  CHECK(D);

  //////// Test actions against methods

  Fail("fn0", Dart_Invoke(D, Dart_NewStringFromCString("fn0"), 0, nullptr));

  CHECK(Dart_Invoke(D, Dart_NewStringFromCString("fn1"), 0, nullptr));

  Fail("get_fn0", Dart_GetField(D, Dart_NewStringFromCString("fn0")));

  Fail("get_fn1", Dart_GetField(D, Dart_NewStringFromCString("fn1")));

  Fail("fn2",
       Dart_Invoke(D_class, Dart_NewStringFromCString("fn2"), 0, nullptr));

  CHECK(Dart_Invoke(D_class, Dart_NewStringFromCString("fn3"), 0, nullptr));

  FailClosurize("fn2",
                Dart_GetField(D_class, Dart_NewStringFromCString("fn2")));

  FailClosurize("fn3",
                Dart_GetField(D_class, Dart_NewStringFromCString("fn3")));

  Fail("fn0", Dart_Invoke(lib, Dart_NewStringFromCString("fn0"), 0, nullptr));

  CHECK(Dart_Invoke(lib, Dart_NewStringFromCString("fn1"), 0, nullptr));

  FailClosurize("fn0", Dart_GetField(lib, Dart_NewStringFromCString("fn0")));

  FailClosurize("fn1", Dart_GetField(lib, Dart_NewStringFromCString("fn1")));

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
