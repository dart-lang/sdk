// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"

const char* DartUtils::kBuiltinLibURL = "./dart:builtin-lib";
const char* DartUtils::kBuiltinLibSpec = "library { }";
const char* DartUtils::kIdFieldName = "_id";


int64_t DartUtils::GetIntegerValue(Dart_Handle value_obj) {
  ASSERT(Dart_IsInteger(value_obj));
  Dart_Result result = Dart_IntegerValue(value_obj);
  ASSERT(Dart_IsValidResult(result));
  return Dart_GetResultAsCInt64(result);
}

const char* DartUtils::GetStringValue(Dart_Handle str_obj) {
  Dart_Result result = Dart_StringToCString(str_obj);
  ASSERT(Dart_IsValidResult(result));
  return Dart_GetResultAsCString(result);
}


bool DartUtils::GetBooleanValue(Dart_Handle bool_obj) {
  Dart_Result result = Dart_BooleanValue(bool_obj);
  ASSERT(Dart_IsValidResult(result));
  return Dart_GetResultAsCBoolean(result);
}

void DartUtils::SetIntegerInstanceField(Dart_Handle handle,
                                        const char* name,
                                        intptr_t val) {
  Dart_Result result = Dart_SetInstanceField(handle,
                                             Dart_NewString(name),
                                             Dart_NewInteger(val));
  ASSERT(Dart_IsValidResult(result));
}

intptr_t DartUtils::GetIntegerInstanceField(Dart_Handle handle,
                                            const char* name) {
  Dart_Result result =
      Dart_GetInstanceField(handle, Dart_NewString(name));
  ASSERT(Dart_IsValidResult(result));
  intptr_t value = DartUtils::GetIntegerValue(Dart_GetResult(result));
  return value;
}

void DartUtils::SetStringInstanceField(Dart_Handle handle,
                                       const char* name,
                                       const char* val) {
  Dart_Result result = Dart_SetInstanceField(handle,
                                             Dart_NewString(name),
                                             Dart_NewString(val));
  ASSERT(Dart_IsValidResult(result));
}
