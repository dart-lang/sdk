// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <string.h>

#include "../include/dart_api.h"

#define EXPORT_SYMBOL __attribute__ ((visibility ("default")))

extern "C" Dart_NativeFunction ResolveName(Dart_Handle name, int argc);

extern "C" EXPORT_SYMBOL Dart_Handle test_extension_Init(Dart_Handle library) {
  if (Dart_IsError(library)) return library;
  Dart_Handle check_return = Dart_SetNativeResolver(library, ResolveName);
  if (Dart_IsError(check_return)) return check_return;
  return Dart_Null();
}

extern "C" void IfNull(Dart_NativeArguments arguments) {
  Dart_Handle object = Dart_GetNativeArgument(arguments, 0);
  if (Dart_IsNull(object)) {
    Dart_SetReturnValue(arguments, Dart_GetNativeArgument(arguments, 1));
  } else {
    Dart_SetReturnValue(arguments, object);
  }
}

extern "C" Dart_NativeFunction ResolveName(Dart_Handle name, int argc) {
  assert(Dart_IsString8(name));
  const char* cname;
  Dart_Handle check_error;

  check_error = Dart_StringToCString(name, &cname);
  if (Dart_IsError(check_error)) {
    Dart_PropagateError(check_error);
  }
  if (!strcmp("Cat_IfNull", cname) && argc == 2) {
    return IfNull;
  }
  return NULL;
}
