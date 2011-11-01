// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DART_API_IMPL_H_
#define VM_DART_API_IMPL_H_

#include "vm/allocation.h"

namespace dart {

class ApiState;
class LocalHandle;
class Object;
class PersistentHandle;
class RawObject;

class Api : AllStatic {
 public:
  // Create new local handles.
  static Dart_Handle NewLocalHandle(const Object& object);

  // Unwrap the raw object from the handle.
  static RawObject* UnwrapHandle(Dart_Handle object);

  // Validate and convert the passed in handle as a local handle.
  static LocalHandle* UnwrapAsLocalHandle(const ApiState& state,
                                          Dart_Handle object);

  // Validate and convert the passed in handle as a persistent handle.
  static PersistentHandle* UnwrapAsPersistentHandle(const ApiState& state,
                                                    Dart_Handle object);

  // Get the handle used to designate successful return.
  static Dart_Handle Success();

  // Generate a handle used to designate an error return.
  static Dart_Handle Error(const char* msg);

  // Allocate space in the local zone.
  static uword Allocate(intptr_t size);

  // Reallocate space in the local zone.
  static uword Reallocate(uword ptr, intptr_t old_size, intptr_t new_size);
};

}  // namespace dart.

#endif  // VM_DART_API_IMPL_H_
