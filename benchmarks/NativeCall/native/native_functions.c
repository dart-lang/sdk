// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// TODO(dartbug.com/40579): This requires static linking to either link
// dart.exe or dart_precompiled_runtime.exe on Windows.
// The sample currently fails on Windows in AOT mode.
#include "include/dart_api.h"

#define ENSURE(X)                                                              \
  if (!(X)) {                                                                  \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, "Check failed: " #X);   \
    exit(1);                                                                   \
  }

#define ENSURE_VALID(X) ENSURE(!Dart_IsError(X))

//
// Functions under test.
//

void Function1Uint8(Dart_NativeArguments args) {
  int64_t arg = 0;
  Dart_GetNativeIntegerArgument(args, /*index=*/0, &arg);
  Dart_SetIntegerReturnValue(args, arg + 42);
}

void Function20Int64(Dart_NativeArguments args) {
  int64_t arg = 0;
  int64_t result = 0;
  for (int i = 0; i < 20; i++) {
    Dart_GetNativeIntegerArgument(args, /*index=*/i, &arg);
    result += arg;
  }
  Dart_SetIntegerReturnValue(args, result);
}

void Function1Double(Dart_NativeArguments args) {
  double arg = 0.0;
  Dart_GetNativeDoubleArgument(args, /*index=*/0, &arg);
  Dart_SetDoubleReturnValue(args, arg + 42.0);
}

void Function20Double(Dart_NativeArguments args) {
  double arg = 0;
  double result = 0;
  for (int i = 0; i < 20; i++) {
    Dart_GetNativeDoubleArgument(args, /*index=*/i, &arg);
    result += arg;
  }
  Dart_SetDoubleReturnValue(args, result);
}

void Function1Handle(Dart_NativeArguments args) {
  Dart_Handle arg = Dart_GetNativeArgument(args, /*index=*/0);
  Dart_SetReturnValue(args, arg);
}

void Function20Handle(Dart_NativeArguments args) {
  Dart_Handle arg = Dart_GetNativeArgument(args, /*index=*/0);
  Dart_SetReturnValue(args, arg);
}

//
// Test helpers.
//

DART_EXPORT Dart_Handle GetRootLibraryUrl() {
  Dart_Handle root_lib = Dart_RootLibrary();
  Dart_Handle lib_url = Dart_LibraryUrl(root_lib);
  ENSURE_VALID(lib_url);
  return lib_url;
}

Dart_NativeFunction NativeEntryResolver(Dart_Handle name,
                                        int num_of_arguments,
                                        bool* auto_setup_scope) {
  ENSURE(Dart_IsString(name));

  ENSURE(auto_setup_scope != NULL);
  *auto_setup_scope = true;

  const char* name_str = NULL;
  ENSURE_VALID(Dart_StringToCString(name, &name_str));

  if (strcmp(name_str, "Function1Uint8") == 0 && num_of_arguments == 1) {
    return &Function1Uint8;
  } else if (strcmp(name_str, "Function20Int64") == 0 &&
             num_of_arguments == 20) {
    return &Function20Int64;
  } else if (strcmp(name_str, "Function1Double") == 0 &&
             num_of_arguments == 1) {
    return &Function1Double;
  } else if (strcmp(name_str, "Function20Double") == 0 &&
             num_of_arguments == 20) {
    return &Function20Double;
  } else if (strcmp(name_str, "Function1Handle") == 0 &&
             num_of_arguments == 1) {
    return &Function1Handle;
  } else if (strcmp(name_str, "Function20Handle") == 0 &&
             num_of_arguments == 20) {
    return &Function20Handle;
  }

  // Unreachable in benchmark.
  ENSURE(false);
}

DART_EXPORT void SetNativeResolverForTest(Dart_Handle url) {
  Dart_Handle library = Dart_LookupLibrary(url);
  ENSURE_VALID(library);
  Dart_Handle result =
      Dart_SetNativeResolver(library, &NativeEntryResolver, NULL);
  ENSURE_VALID(result);
}
