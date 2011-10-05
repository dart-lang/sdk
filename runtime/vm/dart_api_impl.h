// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DART_API_IMPL_H_
#define VM_DART_API_IMPL_H_

#include "vm/allocation.h"

#define RETURN_FAILURE(msg) return Dart_ErrorResult(msg)
#define RETURN_CINT(retval) return Dart_ResultAsCIntptr(retval)
#define RETURN_CBOOLEAN(retval) return Dart_ResultAsCBoolean(retval)
#define RETURN_CSTRING(retval) return Dart_ResultAsCString(retval)
#define RETURN_OBJECT(obj) return Dart_ResultAsObject(Api::NewLocalHandle(obj))
#define RETURN_CINT64(retval) return Dart_ResultAsCInt64(retval)
#define RETURN_CDOUBLE(retval) return Dart_ResultAsCDouble(retval)

namespace dart {

// Forward declarations.
class Object;
class RawObject;
class LocalHandle;
class PersistentHandle;
class ApiState;

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

  // Allocate space in the local zone.
  static uword Allocate(intptr_t size);

  // Reallocate space in the local zone.
  static uword Reallocate(uword ptr, intptr_t old_size, intptr_t new_size);
};

}  // namespace dart.

#endif  // VM_DART_API_IMPL_H_
