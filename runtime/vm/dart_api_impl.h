// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DART_API_IMPL_H_
#define VM_DART_API_IMPL_H_

#include "vm/allocation.h"
#include "vm/object.h"

namespace dart {

class ApiState;
class FinalizablePersistentHandle;
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


const char* CheckIsolateState(Isolate *isolate,
                              bool generating_snapshot = false);

void SetupErrorResult(Dart_Handle* handle);


class Api : AllStatic {
 public:
  // Creates a new local handle.
  static Dart_Handle NewHandle(Isolate* isolate, RawObject* raw);

  // Unwraps the raw object from the handle.
  static RawObject* UnwrapHandle(Dart_Handle object);

  // Unwraps a raw Type from the handle.  The handle will be null if
  // the object was not of the requested Type.
#define DECLARE_UNWRAP(Type)                                                  \
  static const Type& Unwrap##Type##Handle(Isolate* isolate,                   \
                                          Dart_Handle object);
  CLASS_LIST_NO_OBJECT(DECLARE_UNWRAP)
#undef DECLARE_UNWRAP

  // Validates and converts the passed in handle as a local handle.
  static LocalHandle* UnwrapAsLocalHandle(const ApiState& state,
                                          Dart_Handle object);

  // Validates and converts the passed in handle as a persistent handle.
  static PersistentHandle* UnwrapAsPersistentHandle(const ApiState& state,
                                                    Dart_Handle object);

  // Validates and converts the passed in handle as a weak persistent handle.
  static FinalizablePersistentHandle* UnwrapAsWeakPersistentHandle(
      const ApiState& state,
      Dart_Handle object);

  // Validates and converts the passed in handle as a prologue weak
  // persistent handle.
  static FinalizablePersistentHandle* UnwrapAsPrologueWeakPersistentHandle(
      const ApiState& state,
      Dart_Handle object);

  // Casts the internal Isolate* type to the external Dart_Isolate type.
  static Dart_Isolate CastIsolate(Isolate* isolate);

  // Gets the handle used to designate successful return.
  static Dart_Handle Success(Isolate* isolate);

  // Returns true if the handle holds a Smi.
  static bool IsSmi(Dart_Handle handle) {
    RawObject* raw = *(reinterpret_cast<RawObject**>(handle));
    return !raw->IsHeapObject();
  }

  // Returns the value of a Smi.
  static intptr_t SmiValue(Dart_Handle handle) {
    uword value = *(reinterpret_cast<uword*>(handle));
    return Smi::ValueFromRaw(value);
  }

  static intptr_t ClassId(Dart_Handle handle) {
    RawObject* raw = *(reinterpret_cast<RawObject**>(handle));
    if (!raw->IsHeapObject()) {
      return kSmi;
    }
    return raw->GetClassId();
  }

  // Generates a handle used to designate an error return.
  static Dart_Handle NewError(const char* format, ...);

  // Gets a handle to Null.
  static Dart_Handle Null(Isolate* isolate);

  // Gets a handle to True.
  static Dart_Handle True(Isolate* isolate);

  // Gets a handle to False
  static Dart_Handle False(Isolate* isolate);

  // Allocates space in the local zone.
  static uword Allocate(Isolate* isolate, intptr_t size);

  // Reallocates space in the local zone.
  static uword Reallocate(Isolate* isolate,
                          uword ptr,
                          intptr_t old_size,
                          intptr_t new_size);

  // Performs one-time initialization needed by the API.
  static void InitOnce();

 private:
  // Thread local key used by the API. Currently holds the current
  // ApiNativeScope if any.
  static ThreadLocalKey api_native_key_;

  friend class ApiNativeScope;
};

class IsolateSaver {
 public:
  explicit IsolateSaver(Isolate* current_isolate)
      : saved_isolate_(current_isolate) {
  }
  ~IsolateSaver() {
    Isolate::SetCurrent(saved_isolate_);
  }
 private:
  Isolate* saved_isolate_;

  DISALLOW_COPY_AND_ASSIGN(IsolateSaver);
};

}  // namespace dart.

#endif  // VM_DART_API_IMPL_H_
