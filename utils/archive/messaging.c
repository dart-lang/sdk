// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <stdarg.h>

#include "messaging.h"

void postResult(Dart_Port p, bool success, int err, Dart_CObject* response) {
  DART_BOOL(wrapped_success, success);
  DART_INT32(wrapped_err, err);
  
  Dart_CObject* values[3];
  values[0] = &wrapped_success;
  values[1] = &wrapped_err;
  values[2] = response;

  Dart_CObject full_response;
  full_response.type = kArray;
  full_response.value.as_array.values = values;
  full_response.value.as_array.length = 3;

  Dart_PostCObject(p, &full_response);
}

void postError(Dart_Port p, struct archive* a) {
  DART_STRING(error_string, (char*) archive_error_string(a));
  postResult(p, false, archive_errno(a), &error_string);
}

void postInvalidArgument(Dart_Port p, const char* format, ...) {
  va_list args;
  char buffer[256];

  va_start(args, format);
  vsnprintf(buffer, 256, format, args);
  va_end(args);

  DART_STRING(error_string, buffer);
  postResult(p, false, EINVAL, &error_string);
}

void postSuccess(Dart_Port p, Dart_CObject* response) {
  if (response != NULL) {
    postResult(p, true, 0, response);
    return;
  }

  DART_NULL(null_response);
  postResult(p, true, 0, &null_response);
}

bool checkError(Dart_Port p, struct archive* a, int result) {
  if (result == ARCHIVE_OK) return false;
  // TODO(nweiz): What should we do about non-fatal warnings?
  if (result == ARCHIVE_WARN) return false;
  postError(p, a);
}

bool checkPointerError(Dart_Port p, void* pointer, char* name) {
  if (pointer != NULL) return false;
  char buffer[100];
  snprintf(buffer, 100, "Failed to allocate memory for %s.", name);
  DART_STRING(error_string, buffer);
  postResult(p, false, ENOMEM, &error_string);
  return true;
}

bool checkType(Dart_Port p, Dart_CObject* object, enum Type type) {
  if (object->type == type) return false;
  postInvalidArgument(p, "Invalid argument: expected type %d, was type %d.",
    type, object->type);
  return true;
}

void checkResult(Dart_Port p, struct archive* a, int result) {
  if (checkError(p, a, result)) return;
  postSuccess(p, NULL);
}

void checkPointerResult(Dart_Port p, void* pointer, char* name) {
  if (checkPointerError(p, pointer, name)) return;
  DART_INT64(result, (intptr_t) pointer);
  postSuccess(p, &result);
}

Dart_CObject* getArgument(Dart_Port p, Dart_CObject* request, int i) {
  if (checkType(p, request, kArray)) return NULL;

  i += 2; // Skip over the message name and archive id.
  if (request->value.as_array.length > i) {
    return request->value.as_array.values[i];
  }

  postInvalidArgument(p, "Invalid argument: expected at least %d arguments, " \
    "were %d.", i - 2, request->value.as_array.length - 2);
  return NULL;
}

Dart_CObject* getTypedArgument(Dart_Port p, Dart_CObject* request, int i,
                               enum Type type) {
  Dart_CObject* arg = getArgument(p, request, i);
  if (arg == NULL) return NULL;
  if (checkType(p, arg, type)) return NULL;
  return arg;
}

Dart_CObject* getIntArgument(Dart_Port p, Dart_CObject* request, int i) {
  Dart_CObject* arg = getArgument(p, request, i);
  if (arg == NULL) return NULL;
  if (arg->type == kInt64) return arg;
  if (arg->type == kInt32) return arg;
  postInvalidArgument(p, "Invalid argument %d: expected integer, was type %d.",
    i+1, arg->type);
  return NULL;
}

int64_t getInteger(Dart_CObject* object) {
  assert(object->type == kInt64 || object->type == kInt32);
  if (object->type == kInt64) return object->value.as_int64;
  if (object->type == kInt32) return (int64_t) object->value.as_int32;
}

Dart_CObject* getNullableStringArgument(Dart_Port p, Dart_CObject* request,
    int i) {
  Dart_CObject* arg = getArgument(p, request, i);
  if (arg == NULL) return NULL;
  if (arg->type == kNull) return arg;
  if (arg->type == kString) return arg;
  postInvalidArgument(p, "Invalid argument %d: expected string or null, was " \
    "type %d.", i+1, arg->type);
  return NULL;
}

char* getNullableString(Dart_CObject* object) {
  assert(object->type == kNull || object->type == kString);
  if (object->type == kString) return object->value.as_string;
  return NULL;
}
