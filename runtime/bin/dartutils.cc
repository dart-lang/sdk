// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"

const char* DartUtils::kBuiltinLibURL = "./dart:builtin-lib";
const char* DartUtils::kBuiltinLibSpec = "library { }";
const char* DartUtils::kIdFieldName = "_id";


int64_t DartUtils::GetIntegerValue(Dart_Handle value_obj) {
  ASSERT(Dart_IsInteger(value_obj));
  int64_t value = 0;
  Dart_Handle result = Dart_IntegerValue(value_obj, &value);
  ASSERT(!Dart_IsError(result));
  return value;
}

const char* DartUtils::GetStringValue(Dart_Handle str_obj) {
  const char* cstring = NULL;
  Dart_Handle result = Dart_StringToCString(str_obj, &cstring);
  ASSERT(!Dart_IsError(result));
  return cstring;
}


bool DartUtils::GetBooleanValue(Dart_Handle bool_obj) {
  bool value = false;
  Dart_Handle result = Dart_BooleanValue(bool_obj, &value);
  ASSERT(!Dart_IsError(result));
  return value;
}

void DartUtils::SetIntegerInstanceField(Dart_Handle handle,
                                        const char* name,
                                        intptr_t val) {
  Dart_Handle result = Dart_SetInstanceField(handle,
                                             Dart_NewString(name),
                                             Dart_NewInteger(val));
  ASSERT(!Dart_IsError(result));
}

intptr_t DartUtils::GetIntegerInstanceField(Dart_Handle handle,
                                            const char* name) {
  Dart_Handle result =
      Dart_GetInstanceField(handle, Dart_NewString(name));
  ASSERT(!Dart_IsError(result));
  intptr_t value = DartUtils::GetIntegerValue(result);
  return value;
}

void DartUtils::SetStringInstanceField(Dart_Handle handle,
                                       const char* name,
                                       const char* val) {
  Dart_Handle result = Dart_SetInstanceField(handle,
                                             Dart_NewString(name),
                                             Dart_NewString(val));
  ASSERT(!Dart_IsError(result));
}
