// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#include <string.h>

#include "include/dart_api.h"

Dart_NativeFunction ResolveName(Dart_Handle name, int argc);

DART_EXPORT Dart_Handle test_extension_Init(Dart_Handle parent_library) {
  if (Dart_IsError(parent_library)) { return parent_library; }

  Dart_Handle result_code = Dart_SetNativeResolver(parent_library, ResolveName);
  if (Dart_IsError(result_code)) return result_code;

  return parent_library;
}

void IfNull(Dart_NativeArguments arguments) {
  Dart_Handle object = Dart_GetNativeArgument(arguments, 0);
  if (Dart_IsNull(object)) {
    Dart_SetReturnValue(arguments, Dart_GetNativeArgument(arguments, 1));
  } else {
    Dart_SetReturnValue(arguments, object);
  }
}

Dart_NativeFunction ResolveName(Dart_Handle name, int argc) {
  assert(Dart_IsString(name));
  const char* cname;
  Dart_Handle check_error;

  check_error = Dart_StringToCString(name, &cname);
  if (Dart_IsError(check_error)) {
    Dart_PropagateError(check_error);
  }
  if (!strcmp("TestExtension_IfNull", cname) && argc == 2) {
    return IfNull;
  }
  return NULL;
}
