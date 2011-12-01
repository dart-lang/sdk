// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DART_API_IMPL_H_
#define VM_DART_API_IMPL_H_

#include "vm/allocation.h"
#include "vm/object.h"

namespace dart {

class ApiState;
class LocalHandle;
class PersistentHandle;

const char* CanonicalFunction(const char* func);

#define CURRENT_FUNC CanonicalFunction(__FUNCTION__)

// Checks that the current isolate is not NULL.
#define CHECK_ISOLATE(isolate)                                                \
  do {                                                                        \
    if ((isolate) == NULL) {                                                  \
      FATAL1("%s expects there to be a current isolate. Did you "             \
             "forget to call Dart_CreateIsolate or Dart_EnterIsolate?",       \
            CURRENT_FUNC);                                                    \
    }                                                                         \
  } while (0)

// Checks that the current isolate is NULL.
#define CHECK_NO_ISOLATE(isolate)                                             \
  do {                                                                        \
    if ((isolate) != NULL) {                                                  \
      FATAL1("%s expects there to be no current isolate. Did you "            \
             "forget to call Dart_ExitIsolate?", CURRENT_FUNC);               \
    }                                                                         \
  } while (0)

// Checks that the current isolate is not NULL and that it has an API scope.
#define CHECK_ISOLATE_SCOPE(isolate)                                          \
  do {                                                                        \
    Isolate* tmp = (isolate);                                                 \
    CHECK_ISOLATE(tmp);                                                       \
    ApiState* state = tmp->api_state();                                       \
    ASSERT(state);                                                            \
    if (state->top_scope() == NULL) {                                         \
      FATAL1("%s expects to find a current scope. Did you forget to call "    \
           "Dart_EnterScope?", CURRENT_FUNC);                                 \
    }                                                                         \
  } while (0)

#define DARTSCOPE_NOCHECKS(isolate)                                           \
  Isolate* __temp_isolate__ = (isolate);                                      \
  ASSERT(__temp_isolate__ != NULL);                                           \
  Zone zone(__temp_isolate__);                                                \
  HANDLESCOPE(__temp_isolate__);

#define DARTSCOPE(isolate)                                                    \
  Isolate* __temp_isolate__ = (isolate);                                      \
  CHECK_ISOLATE_SCOPE(__temp_isolate__);                                      \
  Zone zone(__temp_isolate__);                                                \
  HANDLESCOPE(__temp_isolate__);

class Api : AllStatic {
 public:
  // Creates a new local handle.
  static Dart_Handle NewLocalHandle(const Object& object);

  // Unwraps the raw object from the handle.
  static RawObject* UnwrapHandle(Dart_Handle object);

  // Unwraps a raw Type from the handle.  The handle will be null if
  // the object was not of the requested Type.
#define DECLARE_UNWRAP(Type)                                                  \
  static const Type& Unwrap##Type##Handle(Dart_Handle object);
  CLASS_LIST_NO_OBJECT(DECLARE_UNWRAP)
#undef DECLARE_UNWRAP

  // Validates and converts the passed in handle as a local handle.
  static LocalHandle* UnwrapAsLocalHandle(const ApiState& state,
                                          Dart_Handle object);

  // Validates and converts the passed in handle as a persistent handle.
  static PersistentHandle* UnwrapAsPersistentHandle(const ApiState& state,
                                                    Dart_Handle object);

  // Cast the internal Isolate* type to the external Dart_Isolate type.
  static Dart_Isolate CastIsolate(Isolate* isolate);

  // Cast a message byte array to the external Dart_Message type.
  static Dart_Message CastMessage(uint8_t* message);

  // Gets the handle used to designate successful return.
  static Dart_Handle Success();

  // Generates a handle used to designate an error return.
  static Dart_Handle Error(const char* format, ...);

  // Generates an error handle from an unhandled exception.
  static Dart_Handle ErrorFromException(const Object& obj);

  // Gets a handle to Null.
  static Dart_Handle Null();

  // Gets a handle to True.
  static Dart_Handle True();

  // Gets a handle to False
  static Dart_Handle False();

  // Allocates space in the local zone.
  static uword Allocate(intptr_t size);

  // Reallocates space in the local zone.
  static uword Reallocate(uword ptr, intptr_t old_size, intptr_t new_size);
};

}  // namespace dart.

#endif  // VM_DART_API_IMPL_H_
