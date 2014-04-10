/* Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "include/dart_api.h"

#if defined(ASSERT)
#error ASSERT already defined!
#endif


/* Native methods. */
void IfNull(Dart_NativeArguments arguments) {
  Dart_Handle object = Dart_GetNativeArgument(arguments, 0);
  if (Dart_IsNull(object)) {
    Dart_SetReturnValue(arguments, Dart_GetNativeArgument(arguments, 1));
  } else {
    Dart_SetReturnValue(arguments, object);
  }
}


void ThrowMeTheBall(Dart_NativeArguments arguments) {
  Dart_Handle object = Dart_GetNativeArgument(arguments, 0);
  Dart_ThrowException(object);
}


/* Native resolver for the extension library. */
Dart_NativeFunction ResolveName(Dart_Handle name,
                                int argc,
                                bool* auto_setup_scope) {
  /* assert(Dart_IsString(name)); */
  const char* c_name;
  Dart_Handle check_error;

  if (auto_setup_scope == NULL) {
    return NULL;
  }
  *auto_setup_scope = 1;
  check_error = Dart_StringToCString(name, &c_name);
  if (Dart_IsError(check_error)) {
    Dart_PropagateError(check_error);
  }
  if ((strcmp("TestExtension_IfNull", c_name) == 0) && (argc == 2)) {
    return IfNull;
  }
  if ((strcmp("TestExtension_ThrowMeTheBall", c_name) == 0) && (argc == 1)) {
    return ThrowMeTheBall;
  }
  return NULL;
}


/* Native entry point for the extension library. */
DART_EXPORT Dart_Handle test_extension_Init(Dart_Handle parent_library) {
  Dart_Handle result_code;
  if (Dart_IsError(parent_library)) {
    return parent_library;
  }

  result_code = Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if (Dart_IsError(result_code)) {
    return result_code;
  }

  return parent_library;
}
