// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef DART_ARCHIVE_MESSAGING_H_
#define DART_ARCHIVE_MESSAGING_H_

#include "dart_archive.h"

/**
 * Posts a reponse to the main Dart isolate. Only one response should be sent
 * for each request.
 *
 * [p] is the reply port for the isolate. [success] indicates whether or not the
 * request completed successfully; if not, [err] indicates the precise nature of
 * the error. [response] contains request-specific response data to send to
 * Dart; it may not be `NULL`, but it may be the Dart `null` value.
 */
void postResult(Dart_Port p, bool success, int err, Dart_CObject* response);

/**
 * Posts an error response to the main Dart isolate.
 *
 * This should be used when libarchive signals an error. The errno and error
 * message are taken from libarchive's built-in error information for [a].
 */
void postError(Dart_Port p, struct archive* a);

/**
 * Posts an invalid argument error response to the main Dart isolate.
 *
 * This should be used when the arguments sent by the Dart code have unexpected
 * types. Takes a `printf`-style [format] string for describing the error. Note
 * that the error string will be cut off at 256 characters.
 */
void postInvalidArgument(Dart_Port p, const char* format, ...);

/**
 * Posts a success response to the main Dart isolate. [response] is the
 * request-specific Dart object containing the response data. It may be `NULL`.
 */
void postSuccess(Dart_Port p, Dart_CObject* response);

/**
 * Checks [error], the return code of a libarchive call for error conditions,
 * and sends an appropriate error response if any are detected.
 * 
 * Returns `true` if an error is detected and the containing function should
 * short-circuit.
 */
bool checkError(Dart_Port p, struct archive* a, int result);

/**
 * Sends an error response if [pointer] is invalid. [name] is the name of the
 * object being allocated, for error reporting.
 * 
 * Returns `true` if an error is detected and the containing function should
 * short-circuit.
 */
bool checkPointerError(Dart_Port p, void* pointer, char* name);

/**
 * Like [checkError], but sends a success message with no attached data if no
 * error is detected. No further responses should be sent after calling this.
 */
void checkResult(Dart_Port p, struct archive* a, int result);

/**
 * Like [checkPointerError], but sends a success message with the pointer as a
 * Dart integer if no error is detected. No further responses should be sent
 * after calling this.
 */
void checkPointerResult(Dart_Port p, void* pointer, char* name);

/**
 * Checks that [object] is of the expected type [type]. If not, sends an
 * appropriate error response.
 *
 * Returns `true` if a type error is detected and the containing function should
 * short-circuit.
 */
bool checkType(Dart_Port p, Dart_CObject* object, enum Type type);

/**
 * Gets the [i]th argument from [request], which should be the Dart object
 * passed in to each handler function. If this fails (e.g. there isn't an [i]th
 * argument), it will return `NULL`.
 */
Dart_CObject* getArgument(Dart_Port p, Dart_CObject* request, int i);

/**
 * Like [getArgument], but also ensures that the argument is of type [type].
 */
Dart_CObject* getTypedArgument(Dart_Port p, Dart_CObject* request, int i,
                               enum Type type);

/**
 * Like [getArgument], but also ensures that the argument is an integer type
 * (`int32` or `int64`). [getInteger] should be used to extract the actual value
 * of the argument.
 */
Dart_CObject* getIntArgument(Dart_Port p, Dart_CObject* request, int i);

/**
 * Gets the integer value of [object], which should be an `int32` or an `int64`.
 * Note that this does not validate the type of its argument.
 */
int64_t getInteger(Dart_CObject* object);

/**
 * Like [getArgument], but also ensures that the argument is a string or null.
 * [getNullableString] should be used to extract the actual value of the
 * argument.
 */
Dart_CObject* getNullableStringArgument(Dart_Port p, Dart_CObject* request,
    int i);

/**
 * Gets the string value of [object] or `NULL` if it's null. Note that this does
 * not validate the type of its argument.
 */
char* getNullableString(Dart_CObject* object);

/**
 * Gets the module, name, and value, for a libarchive `set_option` function
 * call. Returns whether or not the arguments were parsed correctly.
 */
bool getOptionArguments(Dart_Port p, Dart_CObject* request, char** module,
    char** name, char** value);

/** Declares a null [Dart_CObject] named [name]. */
#define DART_NULL(name) \
  Dart_CObject name;    \
  name.type = kNull;

/**
 * Declares a [Dart_CObject] bool named [name] with value [val].
 *
 * [val] should be a C boolean.
 */
#define DART_BOOL(name, val) \
  Dart_CObject name;         \
  name.type = kBool;         \
  name.value.as_bool = val;

/**
 * Declares a [Dart_CObject] `int32` named [name] with value [val].
 *
 * [val] should be a C integer.
 */
#define DART_INT32(name, val) \
  Dart_CObject name;          \
  name.type = kInt32;         \
  name.value.as_int32 = val;

/**
 * Declares a [Dart_CObject] `int64` named [name] with value [val].
 *
 * [val] should be a C integer.
 */
#define DART_INT64(name, val) \
  Dart_CObject name;          \
  name.type = kInt64;         \
  name.value.as_int64 = val;

/**
 * Declares a [Dart_CObject] double named [name] with value [val].
 *
 * [val] should be a C float.
 */
#define DART_DOUBLE(name, val) \
  Dart_CObject name;           \
  name.type = kDouble;         \
  name.value.as_double = val;

/**
 * Declares a [Dart_CObject] string named [name] with value [val].
 *
 * [val] should be a C string or `NULL`.
 */
#define DART_STRING(name, val)  \
  Dart_CObject name;            \
  if (val == NULL) {            \
    name.type = kNull;          \
  } else {                      \
    name.type = kString;        \
    name.value.as_string = val; \
  }

#endif  // DART_ARCHIVE_MESSAGING_H_
