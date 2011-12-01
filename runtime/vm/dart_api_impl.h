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

#define DARTSCOPE(isolate)                                                    \
  ASSERT(isolate != NULL);                                                    \
  Zone zone(isolate);                                                         \
  HANDLESCOPE(isolate);                                                       \

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
