// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"

#include "vm/bigint_operations.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debuginfo.h"
#include "vm/exceptions.h"
#include "vm/growable_array.h"
#include "vm/message.h"
#include "vm/native_entry.h"
#include "vm/native_message_handler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"
#include "vm/timer.h"
#include "vm/verifier.h"

namespace dart {

ThreadLocalKey Api::api_native_key_ = Thread::kUnsetThreadLocalKey;

const char* CanonicalFunction(const char* func) {
  if (strncmp(func, "dart::", 6) == 0) {
    return func + 6;
  } else {
    return func;
  }
}

#define RETURN_TYPE_ERROR(isolate, dart_handle, Type)                         \
  do {                                                                        \
    const Object& tmp =                                                       \
        Object::Handle(isolate, Api::UnwrapHandle((dart_handle)));            \
    if (tmp.IsNull()) {                                                       \
      return Api::NewError("%s expects argument '%s' to be non-null.",        \
                           CURRENT_FUNC, #dart_handle);                       \
    } else if (tmp.IsError()) {                                               \
      return dart_handle;                                                     \
    } else {                                                                  \
      return Api::NewError("%s expects argument '%s' to be of type %s.",      \
                           CURRENT_FUNC, #dart_handle, #Type);                \
    }                                                                         \
  } while (0)


// Return error if isolate is in an inconsistent state.
// Return NULL when no error condition exists.
const char* CheckIsolateState(Isolate* isolate, bool generating_snapshot) {
  bool success = true;
  if (!ClassFinalizer::AllClassesFinalized()) {
    success = (generating_snapshot) ?
        ClassFinalizer::FinalizePendingClassesForSnapshotCreation() :
        ClassFinalizer::FinalizePendingClasses();
  }
  if (success) {
    success = isolate->object_store()->PreallocateObjects();
    if (success) {
      return NULL;
    }
  }
  // Make a copy of the error message as the original message string
  // may get deallocated when we return back from the Dart API call.
  const Error& err = Error::Handle(isolate->object_store()->sticky_error());
  const char* errmsg = err.ToErrorCString();
  intptr_t errlen = strlen(errmsg) + 1;
  char* msg = reinterpret_cast<char*>(Api::Allocate(isolate, errlen));
  OS::SNPrint(msg, errlen, "%s", errmsg);
  return msg;
}


void SetupErrorResult(Isolate* isolate, Dart_Handle* handle) {
  *handle = Api::NewHandle(
      isolate, Isolate::Current()->object_store()->sticky_error());
}


Dart_Handle Api::NewHandle(Isolate* isolate, RawObject* raw) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  ASSERT(scope != NULL);
  LocalHandles* local_handles = scope->local_handles();
  ASSERT(local_handles != NULL);
  LocalHandle* ref = local_handles->AllocateHandle();
  ref->set_raw(raw);
  return reinterpret_cast<Dart_Handle>(ref);
}

RawObject* Api::UnwrapHandle(Dart_Handle object) {
#ifdef DEBUG
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ASSERT(state->IsValidPrologueWeakPersistentHandle(object) ||
         state->IsValidWeakPersistentHandle(object) ||
         state->IsValidPersistentHandle(object) ||
         state->IsValidLocalHandle(object));
  ASSERT(FinalizablePersistentHandle::raw_offset() == 0 &&
         PersistentHandle::raw_offset() == 0 &&
         LocalHandle::raw_offset() == 0);
#endif
  return *(reinterpret_cast<RawObject**>(object));
}

#define DEFINE_UNWRAP(Type)                                                   \
  const Type& Api::Unwrap##Type##Handle(Isolate* iso,                         \
                                        Dart_Handle dart_handle) {            \
    const Object& tmp = Object::Handle(iso, Api::UnwrapHandle(dart_handle));  \
    Type& typed_handle = Type::Handle(iso);                                   \
    if (tmp.Is##Type()) {                                                     \
      typed_handle ^= tmp.raw();                                              \
    }                                                                         \
    return typed_handle;                                                      \
  }
CLASS_LIST_NO_OBJECT(DEFINE_UNWRAP)
#undef DEFINE_UNWRAP


LocalHandle* Api::UnwrapAsLocalHandle(const ApiState& state,
                                      Dart_Handle object) {
  ASSERT(state.IsValidLocalHandle(object));
  return reinterpret_cast<LocalHandle*>(object);
}


PersistentHandle* Api::UnwrapAsPersistentHandle(const ApiState& state,
                                                Dart_Handle object) {
  ASSERT(state.IsValidPersistentHandle(object));
  return reinterpret_cast<PersistentHandle*>(object);
}


FinalizablePersistentHandle* Api::UnwrapAsWeakPersistentHandle(
    const ApiState& state,
    Dart_Handle object) {
  ASSERT(state.IsValidWeakPersistentHandle(object));
  return reinterpret_cast<FinalizablePersistentHandle*>(object);
}


FinalizablePersistentHandle* Api::UnwrapAsPrologueWeakPersistentHandle(
    const ApiState& state,
    Dart_Handle object) {
  ASSERT(state.IsValidPrologueWeakPersistentHandle(object));
  return reinterpret_cast<FinalizablePersistentHandle*>(object);
}


Dart_Isolate Api::CastIsolate(Isolate* isolate) {
  return reinterpret_cast<Dart_Isolate>(isolate);
}


Dart_Handle Api::Success(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  PersistentHandle* true_handle = state->True();
  return reinterpret_cast<Dart_Handle>(true_handle);
}


Dart_Handle Api::NewError(const char* format, ...) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE_NOCHECKS(isolate);

  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);

  char* buffer = reinterpret_cast<char*>(zone.Allocate(len + 1));
  va_list args2;
  va_start(args2, format);
  OS::VSNPrint(buffer, (len + 1), format, args2);
  va_end(args2);

  const String& message = String::Handle(isolate, String::New(buffer));
  return Api::NewHandle(isolate, ApiError::New(message));
}


Dart_Handle Api::Null(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  PersistentHandle* null_handle = state->Null();
  return reinterpret_cast<Dart_Handle>(null_handle);
}


Dart_Handle Api::True(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  PersistentHandle* true_handle = state->True();
  return reinterpret_cast<Dart_Handle>(true_handle);
}


Dart_Handle Api::False(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  PersistentHandle* false_handle = state->False();
  return reinterpret_cast<Dart_Handle>(false_handle);
}


uword Api::Allocate(Isolate* isolate, intptr_t size) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  ASSERT(scope != NULL);
  return scope->zone()->Allocate(size);
}


uword Api::Reallocate(Isolate* isolate,
                      uword ptr,
                      intptr_t old_size,
                      intptr_t new_size) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  ASSERT(scope != NULL);
  return scope->zone()->Reallocate(ptr, old_size, new_size);
}


void Api::InitOnce() {
  ASSERT(api_native_key_ == Thread::kUnsetThreadLocalKey);
  api_native_key_ = Thread::CreateThreadLocal();
  ASSERT(api_native_key_ != Thread::kUnsetThreadLocalKey);
}


// --- Handles ---


DART_EXPORT bool Dart_IsError(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  return obj.IsError();
}


DART_EXPORT const char* Dart_GetError(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  if (obj.IsError()) {
    Error& error = Error::Handle(isolate);
    error ^= obj.raw();
    const char* str = error.ToErrorCString();
    intptr_t len = strlen(str) + 1;
    char* str_copy = reinterpret_cast<char*>(Api::Allocate(isolate, len));
    strncpy(str_copy, str, len);
    return str_copy;
  } else {
    return "";
  }
}


DART_EXPORT bool Dart_ErrorHasException(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  return obj.IsUnhandledException();
}


DART_EXPORT Dart_Handle Dart_ErrorGetException(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  if (obj.IsUnhandledException()) {
    UnhandledException& error = UnhandledException::Handle(isolate);
    error ^= obj.raw();
    return Api::NewHandle(isolate, error.exception());
  } else if (obj.IsError()) {
    return Api::NewError("This error is not an unhandled exception error.");
  } else {
    return Api::NewError("Can only get exceptions from error handles.");
  }
}


DART_EXPORT Dart_Handle Dart_ErrorGetStacktrace(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  if (obj.IsUnhandledException()) {
    UnhandledException& error = UnhandledException::Handle(isolate);
    error ^= obj.raw();
    return Api::NewHandle(isolate, error.stacktrace());
  } else if (obj.IsError()) {
    return Api::NewError("This error is not an unhandled exception error.");
  } else {
    return Api::NewError("Can only get stacktraces from error handles.");
  }
}


// TODO(turnidge): This clones Api::NewError.  I need to use va_copy to
// fix this but not sure if it available on all of our builds.
DART_EXPORT Dart_Handle Dart_Error(const char* format, ...) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);

  char* buffer = reinterpret_cast<char*>(zone.Allocate(len + 1));
  va_list args2;
  va_start(args2, format);
  OS::VSNPrint(buffer, (len + 1), format, args2);
  va_end(args2);

  const String& message = String::Handle(isolate, String::New(buffer));
  return Api::NewHandle(isolate, ApiError::New(message));
}


DART_EXPORT Dart_Handle Dart_PropagateError(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  const Object& error = Object::Handle(isolate, Api::UnwrapHandle(handle));
  if (!error.IsError()) {
    return Api::NewError(
        "%s expects argument 'handle' to be an error handle.  "
        "Did you forget to check Dart_IsError first?",
        CURRENT_FUNC);
  }
  if (isolate->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // propagate an error here.
    return Api::NewError("No Dart frames on stack, cannot propagate error.");
  }

  // Unwind all the API scopes till the exit frame before propagating.
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  state->UnwindScopes(isolate->top_exit_frame_info());
  Exceptions::PropagateError(error);
  UNREACHABLE();

  return Api::NewError("Cannot reach here.  Internal error.");
}


DART_EXPORT void _Dart_ReportErrorHandle(const char* file,
                                           int line,
                                           const char* handle,
                                           const char* message) {
  fprintf(stderr, "%s:%d: error handle: '%s':\n    '%s'\n",
          file, line, handle, message);
  OS::Abort();
}


DART_EXPORT Dart_Handle Dart_ToString(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (obj.IsString()) {
    return Api::NewHandle(isolate, obj.raw());
  } else if (obj.IsInstance()) {
    Instance& receiver = Instance::Handle(isolate);
    receiver ^= obj.raw();
    return Api::NewHandle(isolate, DartLibraryCalls::ToString(receiver));
  } else {
    // This is a VM internal object. Call the C++ method of printing.
    return Api::NewHandle(isolate, String::New(obj.ToCString()));
  }
}


DART_EXPORT Dart_Handle Dart_IsSame(Dart_Handle obj1, Dart_Handle obj2,
                                    bool* value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& expected = Object::Handle(isolate, Api::UnwrapHandle(obj1));
  const Object& actual = Object::Handle(isolate, Api::UnwrapHandle(obj2));
  *value = (expected.raw() == actual.raw());
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_NewPersistentHandle(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  DARTSCOPE_NOCHECKS(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  const Object& old_ref = Object::Handle(isolate, Api::UnwrapHandle(object));
  PersistentHandle* new_ref = state->persistent_handles().AllocateHandle();
  new_ref->set_raw(old_ref);
  return reinterpret_cast<Dart_Handle>(new_ref);
}

static Dart_Handle AllocateFinalizableHandle(
    Isolate* isolate,
    FinalizablePersistentHandles* handles,
    Dart_Handle object,
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback) {
  const Object& ref = Object::Handle(isolate, Api::UnwrapHandle(object));
  FinalizablePersistentHandle* finalizable_ref = handles->AllocateHandle();
  finalizable_ref->set_raw(ref);
  finalizable_ref->set_peer(peer);
  finalizable_ref->set_callback(callback);
  return reinterpret_cast<Dart_Handle>(finalizable_ref);
}


DART_EXPORT Dart_Handle Dart_NewWeakPersistentHandle(
    Dart_Handle object,
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  DARTSCOPE_NOCHECKS(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  return AllocateFinalizableHandle(isolate,
                                   &state->weak_persistent_handles(),
                                   object,
                                   peer,
                                   callback);
}


DART_EXPORT Dart_Handle Dart_NewPrologueWeakPersistentHandle(
    Dart_Handle object,
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  DARTSCOPE_NOCHECKS(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  return AllocateFinalizableHandle(isolate,
                                   &state->prologue_weak_persistent_handles(),
                                   object,
                                   peer,
                                   callback);
}


DART_EXPORT void Dart_DeletePersistentHandle(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  if (state->IsValidPrologueWeakPersistentHandle(object)) {
    FinalizablePersistentHandle* prologue_weak_ref =
        Api::UnwrapAsPrologueWeakPersistentHandle(*state, object);
    state->prologue_weak_persistent_handles().FreeHandle(prologue_weak_ref);
    return;
  }
  if (state->IsValidWeakPersistentHandle(object)) {
    FinalizablePersistentHandle* weak_ref =
        Api::UnwrapAsWeakPersistentHandle(*state, object);
    state->weak_persistent_handles().FreeHandle(weak_ref);
    return;
  }
  PersistentHandle* ref = Api::UnwrapAsPersistentHandle(*state, object);
  ASSERT(!state->IsProtectedHandle(ref));
  if (!state->IsProtectedHandle(ref)) {
    state->persistent_handles().FreeHandle(ref);
  }
}


DART_EXPORT bool Dart_IsWeakPersistentHandle(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  return state->IsValidWeakPersistentHandle(object);
}


DART_EXPORT bool Dart_IsPrologueWeakPersistentHandle(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  return state->IsValidPrologueWeakPersistentHandle(object);
}


DART_EXPORT Dart_Handle Dart_NewWeakReferenceSet(Dart_Handle* keys,
                                                 intptr_t num_keys,
                                                 Dart_Handle* values,
                                                 intptr_t num_values) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  if (keys == NULL) {
    return Api::NewError("%s expects argument 'keys' to be non-null.",
                         CURRENT_FUNC);
  }
  if (num_keys <= 0) {
    return Api::NewError(
        "%s expects argument 'num_keys' to be greater than 0.",
        CURRENT_FUNC);
  }
  if (values == NULL) {
    return Api::NewError("%s expects argument 'values' to be non-null.",
                         CURRENT_FUNC);
  }
  if (num_values <= 0) {
    return Api::NewError(
        "%s expects argument 'num_values' to be greater than 0.",
        CURRENT_FUNC);
  }

  WeakReference* reference = new WeakReference(keys, num_keys,
                                               values, num_values);
  state->DelayWeakReference(reference);
  return Api::Success(isolate);
}


// --- Garbage Collection Callbacks --


DART_EXPORT Dart_Handle Dart_AddGcPrologueCallback(
    Dart_GcPrologueCallback callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  GcPrologueCallbacks& callbacks = isolate->gc_prologue_callbacks();
  if (callbacks.Contains(callback)) {
    return Api::NewError(
        "%s permits only one instance of 'callback' to be present in the "
        "prologue callback list.",
        CURRENT_FUNC);
  }
  callbacks.Add(callback);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_RemoveGcPrologueCallback(
    Dart_GcPrologueCallback callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  GcPrologueCallbacks& callbacks = isolate->gc_prologue_callbacks();
  if (!callbacks.Contains(callback)) {
    return Api::NewError(
        "%s expects 'callback' to be present in the prologue callback list.",
        CURRENT_FUNC);
  }
  callbacks.Remove(callback);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_AddGcEpilogueCallback(
    Dart_GcEpilogueCallback callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  GcEpilogueCallbacks& callbacks = isolate->gc_epilogue_callbacks();
  if (callbacks.Contains(callback)) {
    return Api::NewError(
        "%s permits only one instance of 'callback' to be present in the "
        "epilogue callback list.",
        CURRENT_FUNC);
  }
  callbacks.Add(callback);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_RemoveGcEpilogueCallback(
    Dart_GcEpilogueCallback callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  GcEpilogueCallbacks& callbacks = isolate->gc_epilogue_callbacks();
  if (!callbacks.Contains(callback)) {
    return Api::NewError(
        "%s expects 'callback' to be present in the epilogue callback list.",
        CURRENT_FUNC);
  }
  callbacks.Remove(callback);
  return Api::Success(isolate);
}


// --- Initialization and Globals ---


DART_EXPORT bool Dart_Initialize(Dart_IsolateCreateCallback create,
                                 Dart_IsolateInterruptCallback interrupt) {
  return Dart::InitOnce(create, interrupt);
}

DART_EXPORT bool Dart_SetVMFlags(int argc, const char** argv) {
  return Flags::ProcessCommandLineFlags(argc, argv);
}

DART_EXPORT bool Dart_IsVMFlagSet(const char* flag_name) {
  if (Flags::Lookup(flag_name) != NULL) {
    return true;
  }
  return false;
}


// --- Isolates ---


DART_EXPORT Dart_Isolate Dart_CreateIsolate(const char* name_prefix,
                                            const uint8_t* snapshot,
                                            void* callback_data,
                                            char** error) {
  Isolate* isolate = Dart::CreateIsolate(name_prefix);
  {
    DARTSCOPE_NOCHECKS(isolate);
    const Error& error_obj =
        Error::Handle(isolate,
                      Dart::InitializeIsolate(snapshot, callback_data));
    if (error_obj.IsNull()) {
      START_TIMER(time_total_runtime);
      return reinterpret_cast<Dart_Isolate>(isolate);
    }
    *error = strdup(error_obj.ToErrorCString());
  }
  Dart::ShutdownIsolate();
  return reinterpret_cast<Dart_Isolate>(NULL);
}


DART_EXPORT void Dart_ShutdownIsolate() {
  CHECK_ISOLATE(Isolate::Current());
  STOP_TIMER(time_total_runtime);
  Dart::ShutdownIsolate();
}


DART_EXPORT Dart_Isolate Dart_CurrentIsolate() {
  return Api::CastIsolate(Isolate::Current());
}


DART_EXPORT void Dart_EnterIsolate(Dart_Isolate dart_isolate) {
  CHECK_NO_ISOLATE(Isolate::Current());
  Isolate* isolate = reinterpret_cast<Isolate*>(dart_isolate);
  Isolate::SetCurrent(isolate);
}


DART_EXPORT void Dart_ExitIsolate() {
  CHECK_ISOLATE(Isolate::Current());
  Isolate::SetCurrent(NULL);
}


static uint8_t* ApiReallocate(uint8_t* ptr,
                              intptr_t old_size,
                              intptr_t new_size) {
  uword new_ptr = Api::Reallocate(Isolate::Current(),
                                  reinterpret_cast<uword>(ptr),
                                  old_size,
                                  new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


DART_EXPORT Dart_Handle Dart_CreateSnapshot(uint8_t** buffer,
                                            intptr_t* size) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  TIMERSCOPE(time_creating_snapshot);
  if (buffer == NULL) {
    return Api::NewError("%s expects argument 'buffer' to be non-null.",
                         CURRENT_FUNC);
  }
  if (size == NULL) {
    return Api::NewError("%s expects argument 'size' to be non-null.",
                         CURRENT_FUNC);
  }
  const char* msg = CheckIsolateState(isolate,
                                      ClassFinalizer::kGeneratingSnapshot);
  if (msg != NULL) {
    return Api::NewError(msg);
  }
  // Since this is only a snapshot the root library should not be set.
  isolate->object_store()->set_root_library(Library::Handle(isolate));
  SnapshotWriter writer(Snapshot::kFull, buffer, ApiReallocate);
  writer.WriteFullSnapshot();
  *size = writer.BytesWritten();
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_CreateScriptSnapshot(uint8_t** buffer,
                                                  intptr_t* size) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  TIMERSCOPE(time_creating_snapshot);
  if (buffer == NULL) {
    return Api::NewError("%s expects argument 'buffer' to be non-null.",
                         CURRENT_FUNC);
  }
  if (size == NULL) {
    return Api::NewError("%s expects argument 'size' to be non-null.",
                         CURRENT_FUNC);
  }
  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }
  Library& library =
      Library::Handle(isolate, isolate->object_store()->root_library());
  if (library.IsNull()) {
    return
        Api::NewError("%s expects the isolate to have a script loaded in it.",
                      CURRENT_FUNC);
  }
  ScriptSnapshotWriter writer(buffer, ApiReallocate);
  writer.WriteScriptSnapshot(library);
  *size = writer.BytesWritten();
  return Api::Success(isolate);
}


DART_EXPORT void Dart_InterruptIsolate(Dart_Isolate isolate) {
  if (isolate == NULL) {
    FATAL1("%s expects argument 'isolate' to be non-null.",  CURRENT_FUNC);
  }
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  iso->ScheduleInterrupts(Isolate::kApiInterrupt);
}


// --- Messages and Ports ---


DART_EXPORT void Dart_SetMessageNotifyCallback(
    Dart_MessageNotifyCallback message_notify_callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  isolate->set_message_notify_callback(message_notify_callback);
}


struct RunLoopData {
  Monitor* monitor;
  bool done;
};


static void RunLoopDone(uword param) {
  RunLoopData* data = reinterpret_cast<RunLoopData*>(param);
  ASSERT(data->monitor != NULL);
  MonitorLocker ml(data->monitor);
  data->done = true;
  ml.Notify();
}


DART_EXPORT Dart_Handle Dart_RunLoop() {
  Isolate* isolate = Isolate::Current();

  DARTSCOPE(isolate);
  Monitor monitor;
  MonitorLocker ml(&monitor);
  {
    SwitchIsolateScope switch_scope(NULL);

    RunLoopData data;
    data.monitor = &monitor;
    data.done = false;
    isolate->message_handler()->Run(
        Dart::thread_pool(),
        NULL, RunLoopDone, reinterpret_cast<uword>(&data));
    while (!data.done) {
      ml.Wait();
    }
  }
  const Object& obj = Object::Handle(isolate->object_store()->sticky_error());
  isolate->object_store()->clear_sticky_error();
  if (obj.IsError()) {
    return Api::NewHandle(isolate, obj.raw());
  }
  ASSERT(obj.IsNull());
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_HandleMessage() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (!isolate->message_handler()->HandleNextMessage()) {
    // TODO(turnidge): Clear sticky error here?
    return Api::NewHandle(isolate, isolate->object_store()->sticky_error());
  }
  return Api::Success(isolate);
}


DART_EXPORT bool Dart_HasLivePorts() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate);
  return isolate->message_handler()->HasLivePorts();
}


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


DART_EXPORT bool Dart_PostIntArray(Dart_Port port_id,
                                   intptr_t len,
                                   intptr_t* data) {
  uint8_t* buffer = NULL;
  ApiMessageWriter writer(&buffer, &allocator);

  writer.WriteMessage(len, data);

  // Post the message at the given port.
  return PortMap::PostMessage(new Message(
      port_id, Message::kIllegalPort, buffer, Message::kNormalPriority));
}


DART_EXPORT bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message) {
  uint8_t* buffer = NULL;
  ApiMessageWriter writer(&buffer, allocator);

  writer.WriteCMessage(message);

  // Post the message at the given port.
  return PortMap::PostMessage(new Message(
      port_id, Message::kIllegalPort, buffer, Message::kNormalPriority));
}


DART_EXPORT bool Dart_Post(Dart_Port port_id, Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  DARTSCOPE_NOCHECKS(isolate);
  const Object& object = Object::Handle(isolate, Api::UnwrapHandle(handle));
  uint8_t* data = NULL;
  SnapshotWriter writer(Snapshot::kMessage, &data, &allocator);
  writer.WriteObject(object.raw());
  writer.FinalizeBuffer();
  return PortMap::PostMessage(new Message(
      port_id, Message::kIllegalPort, data, Message::kNormalPriority));
}


DART_EXPORT Dart_Port Dart_NewNativePort(const char* name,
                                         Dart_NativeMessageHandler handler,
                                         bool handle_concurrently) {
  if (name == NULL) {
    name = "<UnnamedNativePort>";
  }
  if (handler == NULL) {
    OS::PrintErr("%s expects argument 'handler' to be non-null.\n",
                 CURRENT_FUNC);
    return kIllegalPort;
  }
  // Start the native port without a current isolate.
  IsolateSaver saver(Isolate::Current());
  Isolate::SetCurrent(NULL);

  NativeMessageHandler* nmh = new NativeMessageHandler(name, handler);
  Dart_Port port_id = PortMap::CreatePort(nmh);
  nmh->Run(Dart::thread_pool(), NULL, NULL, NULL);
  return port_id;
}


DART_EXPORT bool Dart_CloseNativePort(Dart_Port native_port_id) {
  // Close the native port without a current isolate.
  IsolateSaver saver(Isolate::Current());
  Isolate::SetCurrent(NULL);

  // TODO(turnidge): Check that the port is native before trying to close.
  return PortMap::ClosePort(native_port_id);
}


DART_EXPORT Dart_Handle Dart_NewSendPort(Dart_Port port_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return Api::NewHandle(isolate, DartLibraryCalls::NewSendPort(port_id));
}


DART_EXPORT Dart_Handle Dart_GetReceivePort(Dart_Port port_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Library& isolate_lib = Library::Handle(isolate, Library::IsolateLibrary());
  ASSERT(!isolate_lib.IsNull());
  const String& public_class_name =
      String::Handle(isolate, String::New("_ReceivePortImpl"));
  const String& class_name =
      String::Handle(isolate, isolate_lib.PrivateName(public_class_name));
  const String& function_name =
      String::Handle(isolate, String::NewSymbol("_get_or_create"));
  const int kNumArguments = 1;
  const Array& kNoArgumentNames = Array::Handle(isolate);
  const Function& function = Function::Handle(
      isolate,
      Resolver::ResolveStatic(isolate_lib,
                              class_name,
                              function_name,
                              kNumArguments,
                              kNoArgumentNames,
                              Resolver::kIsQualified));
  GrowableArray<const Object*> arguments(kNumArguments);
  arguments.Add(&Integer::Handle(isolate, Integer::New(port_id)));
  return Api::NewHandle(
      isolate, DartEntry::InvokeStatic(function, arguments, kNoArgumentNames));
}


DART_EXPORT Dart_Port Dart_GetMainPortId() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  return isolate->main_port();
}

// --- Scopes ----


DART_EXPORT void Dart_EnterScope() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* new_scope = new ApiLocalScope(state->top_scope(),
                                               reinterpret_cast<uword>(&state));
  ASSERT(new_scope != NULL);
  state->set_top_scope(new_scope);  // New scope is now the top scope.
}


DART_EXPORT void Dart_ExitScope() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE_SCOPE(isolate);
  ApiState* state = isolate->api_state();
  ApiLocalScope* scope = state->top_scope();

  state->set_top_scope(scope->previous());  // Reset top scope to previous.
  delete scope;  // Free up the old scope which we have just exited.
}


DART_EXPORT uint8_t* Dart_ScopeAllocate(intptr_t size) {
  ApiZone* zone;
  Isolate* isolate = Isolate::Current();
  if (isolate != NULL) {
    ApiState* state = isolate->api_state();
    if (state == NULL) return NULL;
    ApiLocalScope* scope = state->top_scope();
    zone = scope->zone();
  } else {
    ApiNativeScope* scope = ApiNativeScope::Current();
    if (scope == NULL) return NULL;
    zone = scope->zone();
  }
  return reinterpret_cast<uint8_t*>(zone->Allocate(size));
}


// --- Objects ----


DART_EXPORT Dart_Handle Dart_Null() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE_SCOPE(isolate);
  return Api::Null(isolate);
}


DART_EXPORT bool Dart_IsNull(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsNull();
}


DART_EXPORT Dart_Handle Dart_ObjectEquals(Dart_Handle obj1, Dart_Handle obj2,
                                          bool* value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Instance& expected =
      Instance::CheckedHandle(isolate, Api::UnwrapHandle(obj1));
  const Instance& actual =
      Instance::CheckedHandle(isolate, Api::UnwrapHandle(obj2));
  const Object& result =
      Object::Handle(isolate, DartLibraryCalls::Equals(expected, actual));
  if (result.IsBool()) {
    Bool& b = Bool::Handle(isolate);
    b ^= result.raw();
    *value = b.value();
    return Api::Success(isolate);
  } else if (result.IsError()) {
    return Api::NewHandle(isolate, result.raw());
  } else {
    return Api::NewError("Expected boolean result from ==");
  }
}


// TODO(iposva): This call actually implements IsInstanceOfClass.
// Do we also need a real Dart_IsInstanceOf, which should take an instance
// rather than an object and a type rather than a class?
DART_EXPORT Dart_Handle Dart_ObjectIsType(Dart_Handle object,
                                          Dart_Handle clazz,
                                          bool* value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Class& cls = Class::CheckedHandle(isolate, Api::UnwrapHandle(clazz));
  if (cls.IsNull()) {
    return Api::NewError("instanceof check against null class");
  }
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  Instance& instance = Instance::Handle(isolate);
  instance ^= obj.raw();
  // Finalize all classes.
  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }
  const Type& type = Type::Handle(isolate, Type::NewNonParameterizedType(cls));
  Error& malformed_type_error = Error::Handle(isolate);
  *value = instance.IsInstanceOf(
      type, TypeArguments::Handle(isolate), &malformed_type_error);
  ASSERT(malformed_type_error.IsNull());  // Type was created here from a class.
  return Api::Success(isolate);
}


// --- Numbers ----


// TODO(iposva): The argument should be an instance.
DART_EXPORT bool Dart_IsNumber(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsNumber();
}


// --- Integers ----


DART_EXPORT bool Dart_IsInteger(Dart_Handle object) {
  // Fast path for Smis.
  if (Api::IsSmi(object)) {
    return true;
  }

  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsInteger();
}


DART_EXPORT Dart_Handle Dart_IntegerFitsIntoInt64(Dart_Handle integer,
                                                  bool* fits) {
  // Fast path for Smis.
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (Api::IsSmi(integer)) {
    *fits = true;
    return Api::Success(isolate);
  }

  DARTSCOPE_NOCHECKS(isolate);
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  if (int_obj.IsSmi() || int_obj.IsMint()) {
    *fits = true;
  } else {
    ASSERT(int_obj.IsBigint());
#if defined(DEBUG)
    Bigint& bigint = Bigint::Handle(isolate);
    bigint ^= int_obj.raw();
    ASSERT(!BigintOperations::FitsIntoMint(bigint));
#endif
    *fits = false;
  }
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_IntegerFitsIntoUint64(Dart_Handle integer,
                                                   bool* fits) {
  // Fast path for Smis.
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (Api::IsSmi(integer)) {
    *fits = (Api::SmiValue(integer) >= 0);
    return Api::Success(isolate);
  }

  DARTSCOPE_NOCHECKS(isolate);
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  if (int_obj.IsSmi() || int_obj.IsMint()) {
    *fits = !int_obj.IsNegative();
  } else {
    ASSERT(int_obj.IsBigint());
    Bigint& bigint = Bigint::Handle(isolate);
    bigint ^= int_obj.raw();
    *fits = BigintOperations::FitsIntoUint64(bigint);
  }
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_NewInteger(int64_t value) {
  // Fast path for Smis.
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (Smi::IsValid64(value)) {
    NOHANDLESCOPE(isolate);
    return Api::NewHandle(isolate, Smi::New(value));
  }

  DARTSCOPE_NOCHECKS(isolate);
  return Api::NewHandle(isolate, Integer::New(value));
}


DART_EXPORT Dart_Handle Dart_NewIntegerFromHexCString(const char* str) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& str_obj = String::Handle(isolate, String::New(str));
  return Api::NewHandle(isolate, Integer::New(str_obj));
}


DART_EXPORT Dart_Handle Dart_IntegerToInt64(Dart_Handle integer,
                                            int64_t* value) {
  // Fast path for Smis.
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (Api::IsSmi(integer)) {
    *value = Api::SmiValue(integer);
    return Api::Success(isolate);
  }

  DARTSCOPE_NOCHECKS(isolate);
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  if (int_obj.IsSmi() || int_obj.IsMint()) {
    *value = int_obj.AsInt64Value();
    return Api::Success(isolate);
  } else {
    ASSERT(int_obj.IsBigint());
    Bigint& bigint = Bigint::Handle(isolate);
    bigint ^= int_obj.raw();
    if (BigintOperations::FitsIntoMint(bigint)) {
      *value = BigintOperations::ToMint(bigint);
      return Api::Success(isolate);
    }
  }
  return Api::NewError("%s: Integer %s cannot be represented as an int64_t.",
                       CURRENT_FUNC, int_obj.ToCString());
}


DART_EXPORT Dart_Handle Dart_IntegerToUint64(Dart_Handle integer,
                                             uint64_t* value) {
  // Fast path for Smis.
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (Api::IsSmi(integer)) {
    intptr_t smi_value = Api::SmiValue(integer);
    if (smi_value >= 0) {
      *value = smi_value;
      return Api::Success(isolate);
    }
  }

  DARTSCOPE_NOCHECKS(isolate);
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  if (int_obj.IsSmi() || int_obj.IsMint()) {
    if (!int_obj.IsNegative()) {
      *value = int_obj.AsInt64Value();
      return Api::Success(isolate);
    }
  } else {
    ASSERT(int_obj.IsBigint());
    Bigint& bigint = Bigint::Handle(isolate);
    bigint ^= int_obj.raw();
    if (BigintOperations::FitsIntoUint64(bigint)) {
      *value = BigintOperations::ToUint64(bigint);
      return Api::Success(isolate);
    }
  }
  return Api::NewError("%s: Integer %s cannot be represented as a uint64_t.",
                       CURRENT_FUNC, int_obj.ToCString());
}


static uword ApiAllocate(intptr_t size) {
  return Api::Allocate(Isolate::Current(), size);
}


DART_EXPORT Dart_Handle Dart_IntegerToHexCString(Dart_Handle integer,
                                                 const char** value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  Bigint& bigint = Bigint::Handle(isolate);
  if (int_obj.IsSmi() || int_obj.IsMint()) {
    bigint ^= BigintOperations::NewFromInt64(int_obj.AsInt64Value());
    *value = BigintOperations::ToHexCString(bigint, ApiAllocate);
  } else {
    ASSERT(int_obj.IsBigint());
    bigint ^= int_obj.raw();
    *value = BigintOperations::ToHexCString(bigint, ApiAllocate);
  }
  return Api::Success(isolate);
}


// --- Booleans ----


DART_EXPORT Dart_Handle Dart_True() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE_SCOPE(isolate);
  return Api::True(isolate);
}


DART_EXPORT Dart_Handle Dart_False() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE_SCOPE(isolate);
  return Api::False(isolate);
}


DART_EXPORT bool Dart_IsBoolean(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsBool();
}


DART_EXPORT Dart_Handle Dart_NewBoolean(bool value) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE_SCOPE(isolate);
  return value ? Api::True(isolate) : Api::False(isolate);
}


DART_EXPORT Dart_Handle Dart_BooleanValue(Dart_Handle boolean_obj,
                                          bool* value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Bool& obj = Api::UnwrapBoolHandle(isolate, boolean_obj);
  if (obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, boolean_obj, Bool);
  }
  *value = obj.value();
  return Api::Success(isolate);
}


// --- Doubles ---


DART_EXPORT bool Dart_IsDouble(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsDouble();
}


DART_EXPORT Dart_Handle Dart_NewDouble(double value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return Api::NewHandle(isolate, Double::New(value));
}


DART_EXPORT Dart_Handle Dart_DoubleValue(Dart_Handle double_obj,
                                         double* value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Double& obj = Api::UnwrapDoubleHandle(isolate, double_obj);
  if (obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, double_obj, Double);
  }
  *value = obj.value();
  return Api::Success(isolate);
}


// --- Strings ---


DART_EXPORT bool Dart_IsString(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsString();
}


DART_EXPORT bool Dart_IsString8(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsOneByteString() || obj.IsExternalOneByteString();
}


DART_EXPORT bool Dart_IsString16(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return (obj.IsOneByteString() || obj.IsExternalOneByteString() ||
          obj.IsTwoByteString() || obj.IsExternalTwoByteString());
}


DART_EXPORT Dart_Handle Dart_StringLength(Dart_Handle str, intptr_t* len) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(str));
  if (obj.IsString()) {
    String& string_obj = String::Handle(isolate);
    string_obj ^= obj.raw();
    *len = string_obj.Length();
    return Api::Success(isolate);
  }
  return Api::NewError("Object is not a String");
}


DART_EXPORT Dart_Handle Dart_NewString(const char* str) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return Api::NewHandle(isolate, String::New(str));
}


DART_EXPORT Dart_Handle Dart_NewString8(const uint8_t* codepoints,
                                        intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return Api::NewHandle(isolate, String::New(codepoints, length));
}


DART_EXPORT Dart_Handle Dart_NewString16(const uint16_t* codepoints,
                                         intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return Api::NewHandle(isolate, String::New(codepoints, length));
}


DART_EXPORT Dart_Handle Dart_NewString32(const uint32_t* codepoints,
                                         intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return Api::NewHandle(isolate, String::New(codepoints, length));
}


DART_EXPORT bool Dart_IsExternalString(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& str = Api::UnwrapStringHandle(isolate, object);
  if (str.IsNull()) {
    return false;
  }
  return str.IsExternal();
}


DART_EXPORT Dart_Handle Dart_ExternalStringGetPeer(Dart_Handle object,
                                                   void** peer) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& str = Api::UnwrapStringHandle(isolate, object);
  if (str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, object, String);
  }
  if (!str.IsExternal()) {
    return
        Api::NewError("%s expects argument 'object' to be an external String.",
                      CURRENT_FUNC);
  }
  if (peer == NULL) {
    return Api::NewError("%s expects argument 'peer' to be non-null.",
                         CURRENT_FUNC);
  }
  *peer = str.GetPeer();
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_NewExternalString8(const uint8_t* codepoints,
                                                intptr_t length,
                                                void* peer,
                                                Dart_PeerFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (codepoints == NULL && length != 0) {
    return Api::NewError("%s expects argument 'codepoints' to be non-null.",
                         CURRENT_FUNC);
  }
  if (length < 0) {
    return Api::NewError("%s expects argument 'length' to be greater than 0.",
                         CURRENT_FUNC);
  }
  return Api::NewHandle(
      isolate, String::NewExternal(codepoints, length, peer, callback));
}


DART_EXPORT Dart_Handle Dart_NewExternalString16(const uint16_t* codepoints,
                                                 intptr_t length,
                                                 void* peer,
                                                 Dart_PeerFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (codepoints == NULL && length != 0) {
    return Api::NewError("%s expects argument 'codepoints' to be non-null.",
                         CURRENT_FUNC);
  }
  if (length < 0) {
    return Api::NewError("%s expects argument 'length' to be greater than 0.",
                         CURRENT_FUNC);
  }
  return Api::NewHandle(
      isolate, String::NewExternal(codepoints, length, peer, callback));
}


DART_EXPORT Dart_Handle Dart_NewExternalString32(const uint32_t* codepoints,
                                                 intptr_t length,
                                                 void* peer,
                                                 Dart_PeerFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (codepoints == NULL && length != 0) {
    return Api::NewError("%s expects argument 'codepoints' to be non-null.",
                         CURRENT_FUNC);
  }
  if (length < 0) {
    return Api::NewError("%s expects argument 'length' to be greater than 0.",
                         CURRENT_FUNC);
  }
  return Api::NewHandle(
      isolate, String::NewExternal(codepoints, length, peer, callback));
}


DART_EXPORT Dart_Handle Dart_StringGet8(Dart_Handle str,
                                        uint8_t* codepoints,
                                        intptr_t* length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(str));
  if (obj.IsString()) {
    String& string_obj = String::Handle(isolate);
    string_obj ^= obj.raw();
    if (string_obj.CharSize() == String::kOneByteChar) {
      intptr_t str_len = string_obj.Length();
      intptr_t copy_len = (str_len > *length) ? *length : str_len;
      for (intptr_t i = 0; i < copy_len; i++) {
        codepoints[i] = static_cast<uint8_t>(string_obj.CharAt(i));
      }
      *length= copy_len;
      return Api::Success(isolate);
    }
  }
  return Api::NewError(obj.IsString()
                       ? "Object is not a String8"
                       : "Object is not a String");
}


DART_EXPORT Dart_Handle Dart_StringGet16(Dart_Handle str,
                                         uint16_t* codepoints,
                                         intptr_t* length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(str));
  if (obj.IsString()) {
    String& string_obj = String::Handle(isolate);
    string_obj ^= obj.raw();
    if (string_obj.CharSize() <= String::kTwoByteChar) {
      intptr_t str_len = string_obj.Length();
      intptr_t copy_len = (str_len > *length) ? *length : str_len;
      for (intptr_t i = 0; i < copy_len; i++) {
        codepoints[i] = static_cast<uint16_t>(string_obj.CharAt(i));
      }
      *length = copy_len;
      return Api::Success(isolate);
    }
  }
  return Api::NewError(obj.IsString()
                       ? "Object is not a String16"
                       : "Object is not a String");
}


DART_EXPORT Dart_Handle Dart_StringGet32(Dart_Handle str,
                                         uint32_t* codepoints,
                                         intptr_t* length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(str));
  if (obj.IsString()) {
    String& string_obj = String::Handle(isolate);
    string_obj ^= obj.raw();
    intptr_t str_len = string_obj.Length();
    intptr_t copy_len = (str_len > *length) ? *length : str_len;
    for (intptr_t i = 0; i < copy_len; i++) {
      codepoints[i] = static_cast<uint32_t>(string_obj.CharAt(i));
    }
    *length = copy_len;
    return Api::Success(isolate);
  }
  return Api::NewError("Object is not a String");
}


DART_EXPORT Dart_Handle Dart_StringToCString(Dart_Handle object,
                                             const char** result) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (obj.IsString()) {
    const char* string_value = obj.ToCString();
    intptr_t string_length = strlen(string_value);
    char* res =
        reinterpret_cast<char*>(Api::Allocate(isolate, string_length + 1));
    if (res == NULL) {
      return Api::NewError("Unable to allocate memory");
    }
    strncpy(res, string_value, string_length + 1);
    ASSERT(res[string_length] == '\0');
    *result = res;
    return Api::Success(isolate);
  }
  return Api::NewError("Object is not a String");
}


// --- Lists ---


static RawInstance* GetListInstance(Isolate* isolate, const Object& obj) {
  if (obj.IsInstance()) {
    Instance& instance = Instance::Handle(isolate);
    instance ^= obj.raw();
    const Type& type =
        Type::Handle(isolate, isolate->object_store()->list_interface());
    Error& malformed_type_error = Error::Handle(isolate);
    if (instance.IsInstanceOf(type,
                              TypeArguments::Handle(isolate),
                              &malformed_type_error)) {
      ASSERT(malformed_type_error.IsNull());  // Type is a raw List.
      return instance.raw();
    }
  }
  return Instance::null();
}


DART_EXPORT bool Dart_IsList(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return (obj.IsArray() || obj.IsGrowableObjectArray() ||
          (GetListInstance(isolate, obj) != Instance::null()));
}


DART_EXPORT Dart_Handle Dart_NewList(intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return Api::NewHandle(isolate, Array::New(length));
}


#define GET_LIST_LENGTH(isolate, type, obj, len)                               \
  type& array = type::Handle(isolate);                                         \
  array ^= obj.raw();                                                          \
  *len = array.Length();                                                       \
  return Api::Success(isolate);                                                \


DART_EXPORT Dart_Handle Dart_ListLength(Dart_Handle list, intptr_t* len) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(list));
  if (obj.IsByteArray()) {
    GET_LIST_LENGTH(isolate, ByteArray, obj, len);
  }
  if (obj.IsArray()) {
    GET_LIST_LENGTH(isolate, Array, obj, len);
  }
  if (obj.IsGrowableObjectArray()) {
    GET_LIST_LENGTH(isolate, GrowableObjectArray, obj, len);
  }
  // Now check and handle a dart object that implements the List interface.
  const Instance& instance =
      Instance::Handle(isolate, GetListInstance(isolate, obj));
  if (instance.IsNull()) {
    return Api::NewError("Object does not implement the List inteface");
  }
  String& name = String::Handle(isolate, String::New("length"));
  name = Field::GetterName(name);
  const Function& function =
      Function::Handle(isolate, Resolver::ResolveDynamic(instance, name, 1, 0));
  if (function.IsNull()) {
    return Api::NewError("List object does not have a 'length' field.");
  }

  GrowableArray<const Object*> args(0);
  const Array& kNoArgumentNames = Array::Handle(isolate);
  const Object& retval = Object::Handle(
      isolate,
      DartEntry::InvokeDynamic(instance, function, args, kNoArgumentNames));
  if (retval.IsSmi() || retval.IsMint()) {
    Integer& integer = Integer::Handle(isolate);
    integer ^= retval.raw();
    *len = integer.AsInt64Value();
    return Api::Success(isolate);
  } else if (retval.IsBigint()) {
    Bigint& bigint = Bigint::Handle(isolate);
    bigint ^= retval.raw();
    if (BigintOperations::FitsIntoMint(bigint)) {
      *len = BigintOperations::ToMint(bigint);
      return Api::Success(isolate);
    } else {
      return Api::NewError("Length of List object is greater than the "
                           "maximum value that 'len' parameter can hold");
    }
  } else if (retval.IsError()) {
    return Api::NewHandle(isolate, retval.raw());
  } else {
    return Api::NewError("Length of List object is not an integer");
  }
}


#define GET_LIST_ELEMENT(isolate, type, obj, index)                            \
  type& array_obj = type::Handle(isolate);                                     \
  array_obj ^= obj.raw();                                                      \
  if ((index >= 0) && (index < array_obj.Length())) {                          \
    return Api::NewHandle(isolate, array_obj.At(index));                       \
  }                                                                            \
  return Api::NewError("Invalid index passed in to access list element");      \


DART_EXPORT Dart_Handle Dart_ListGetAt(Dart_Handle list, intptr_t index) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(list));
  if (obj.IsArray()) {
    GET_LIST_ELEMENT(isolate, Array, obj, index);
  }
  if (obj.IsGrowableObjectArray()) {
    GET_LIST_ELEMENT(isolate, GrowableObjectArray, obj, index);
  }
  // Now check and handle a dart object that implements the List interface.
  const Instance& instance =
      Instance::Handle(isolate, GetListInstance(isolate, obj));
  if (!instance.IsNull()) {
    String& name = String::Handle(isolate, String::New("[]"));
    const Function& function =
        Function::Handle(isolate,
                         Resolver::ResolveDynamic(instance, name, 2, 0));
    if (!function.IsNull()) {
      GrowableArray<const Object*> args(1);
      Integer& indexobj = Integer::Handle(isolate);
      indexobj = Integer::New(index);
      args.Add(&indexobj);
      const Array& kNoArgumentNames = Array::Handle(isolate);
      return Api::NewHandle(
          isolate,
          DartEntry::InvokeDynamic(instance, function, args, kNoArgumentNames));
    }
  }
  return Api::NewError("Object does not implement the 'List' interface");
}


#define SET_LIST_ELEMENT(isolate, type, obj, index, value)                     \
  type& array = type::Handle(isolate);                                         \
  array ^= obj.raw();                                                          \
  const Object& value_obj = Object::Handle(isolate, Api::UnwrapHandle(value)); \
  if ((index >= 0) && (index < array.Length())) {                              \
    array.SetAt(index, value_obj);                                             \
    return Api::Success(isolate);                                              \
  }                                                                            \
  return Api::NewError("Invalid index passed in to set list element");         \


DART_EXPORT Dart_Handle Dart_ListSetAt(Dart_Handle list,
                                       intptr_t index,
                                       Dart_Handle value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(list));
  if (obj.IsArray()) {
    if (obj.IsImmutableArray()) {
      return Api::NewError("Cannot modify immutable array");
    }
    SET_LIST_ELEMENT(isolate, Array, obj, index, value);
  }
  if (obj.IsGrowableObjectArray()) {
    SET_LIST_ELEMENT(isolate, GrowableObjectArray, obj, index, value);
  }
  // Now check and handle a dart object that implements the List interface.
  const Instance& instance =
      Instance::Handle(isolate, GetListInstance(isolate, obj));
  if (!instance.IsNull()) {
    String& name = String::Handle(isolate, String::New("[]="));
    const Function& function =
        Function::Handle(isolate,
                         Resolver::ResolveDynamic(instance, name, 3, 0));
    if (!function.IsNull()) {
      const Integer& index_obj = Integer::Handle(isolate, Integer::New(index));
      const Object& value_obj =
          Object::Handle(isolate, Api::UnwrapHandle(value));
      GrowableArray<const Object*> args(2);
      args.Add(&index_obj);
      args.Add(&value_obj);
      const Array& kNoArgumentNames = Array::Handle(isolate);
      return Api::NewHandle(
          isolate,
          DartEntry::InvokeDynamic(instance, function, args, kNoArgumentNames));
    }
  }
  return Api::NewError("Object does not implement the 'List' interface");
}


// TODO(hpayer): value should always be smaller then 0xff. Add error handling.
#define GET_LIST_ELEMENT_AS_BYTES(isolate, type, obj, native_array, offset,    \
                                   length)                                     \
  type& array = type::Handle(isolate);                                         \
  array ^= obj.raw();                                                          \
  if (Utils::RangeCheck(offset, length, array.Length())) {                     \
    Object& element = Object::Handle(isolate);                                 \
    Integer& integer  = Integer::Handle(isolate);                              \
    for (int i = 0; i < length; i++) {                                         \
      element = array.At(offset + i);                                          \
      if (!element.IsInteger()) {                                              \
        return Api::NewError("%s expects the argument 'list' to be "           \
                             "a List of int", CURRENT_FUNC);                   \
      }                                                                        \
      integer ^= element.raw();                                                \
      native_array[i] = static_cast<uint8_t>(integer.AsInt64Value() & 0xff);   \
      ASSERT(integer.AsInt64Value() <= 0xff);                                  \
    }                                                                          \
    return Api::Success(isolate);                                              \
  }                                                                            \
  return Api::NewError("Invalid length passed in to access array elements");   \


DART_EXPORT Dart_Handle Dart_ListGetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            uint8_t* native_array,
                                            intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(list));
  if (obj.IsByteArray()) {
    ByteArray& byte_array = ByteArray::Handle(isolate);
    byte_array ^= obj.raw();
    if (Utils::RangeCheck(offset, length, byte_array.Length())) {
      ByteArray::Copy(native_array, byte_array, offset, length);
      return Api::Success(isolate);
    }
    return Api::NewError("Invalid length passed in to access list elements");
  }
  if (obj.IsArray()) {
    GET_LIST_ELEMENT_AS_BYTES(isolate,
                              Array,
                              obj,
                              native_array,
                              offset,
                              length);  }
  if (obj.IsGrowableObjectArray()) {
    GET_LIST_ELEMENT_AS_BYTES(isolate,
                              GrowableObjectArray,
                              obj,
                              native_array,
                              offset,
                              length);
  }
  // Now check and handle a dart object that implements the List interface.
  const Instance& instance =
      Instance::Handle(isolate, GetListInstance(isolate, obj));
  if (!instance.IsNull()) {
    String& name = String::Handle(isolate, String::New("[]"));
    const Function& function =
        Function::Handle(isolate,
                         Resolver::ResolveDynamic(instance, name, 2, 0));
    if (!function.IsNull()) {
      Object& result = Object::Handle(isolate);
      Integer& intobj = Integer::Handle(isolate);
      for (int i = 0; i < length; i++) {
        intobj = Integer::New(offset + i);
        GrowableArray<const Object*> args(1);
        args.Add(&intobj);
        const Array& kNoArgumentNames = Array::Handle(isolate);
        result = DartEntry::InvokeDynamic(
            instance, function, args, kNoArgumentNames);
        if (result.IsError()) {
          return Api::NewHandle(isolate, result.raw());
        }
        if (!result.IsInteger()) {
          return Api::NewError("%s expects the argument 'list' to be "
                               "a List of int", CURRENT_FUNC);
        }
        intobj ^= result.raw();
        ASSERT(intobj.AsInt64Value() <= 0xff);
        // TODO(hpayer): value should always be smaller then 0xff. Add error
        // handling.
        native_array[i] = static_cast<uint8_t>(intobj.AsInt64Value() & 0xff);
      }
      return Api::Success(isolate);
    }
  }
  return Api::NewError("Object does not implement the 'List' interface");
}


#define SET_LIST_ELEMENT_AS_BYTES(isolate, type, obj, native_array, offset,    \
                                  length)                                      \
  type& array = type::Handle(isolate);                                         \
  array ^= obj.raw();                                                          \
  Integer& integer = Integer::Handle(isolate);                                 \
  if (Utils::RangeCheck(offset, length, array.Length())) {                     \
    for (int i = 0; i < length; i++) {                                         \
      integer = Integer::New(native_array[i]);                                 \
      array.SetAt(offset + i, integer);                                        \
    }                                                                          \
    return Api::Success(isolate);                                              \
  }                                                                            \
  return Api::NewError("Invalid length passed in to set array elements");      \


DART_EXPORT Dart_Handle Dart_ListSetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            uint8_t* native_array,
                                            intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(list));
  if (obj.IsByteArray()) {
    ByteArray& byte_array = ByteArray::Handle(isolate);
    byte_array ^= obj.raw();
    if (Utils::RangeCheck(offset, length, byte_array.Length())) {
      ByteArray::Copy(byte_array, offset, native_array, length);
      return Api::Success(isolate);
    }
    return Api::NewError("Invalid length passed in to set list elements");
  }
  if (obj.IsArray()) {
    if (obj.IsImmutableArray()) {
      return Api::NewError("Cannot modify immutable array");
    }
    SET_LIST_ELEMENT_AS_BYTES(isolate,
                              Array,
                              obj,
                              native_array,
                              offset,
                              length);
  }
  if (obj.IsGrowableObjectArray()) {
    SET_LIST_ELEMENT_AS_BYTES(isolate,
                              GrowableObjectArray,
                              obj,
                              native_array,
                              offset,
                              length);
  }
  // Now check and handle a dart object that implements the List interface.
  const Instance& instance =
      Instance::Handle(isolate, GetListInstance(isolate, obj));
  if (!instance.IsNull()) {
    String& name = String::Handle(isolate, String::New("[]="));
    const Function& function =
        Function::Handle(isolate,
                         Resolver::ResolveDynamic(instance, name, 3, 0));
    if (!function.IsNull()) {
      Integer& indexobj = Integer::Handle(isolate);
      Integer& valueobj = Integer::Handle(isolate);
      for (int i = 0; i < length; i++) {
        indexobj = Integer::New(offset + i);
        valueobj = Integer::New(native_array[i]);
        GrowableArray<const Object*> args(2);
        args.Add(&indexobj);
        args.Add(&valueobj);
        const Array& kNoArgumentNames = Array::Handle(isolate);
        const Object& result = Object::Handle(
            isolate,
            DartEntry::InvokeDynamic(
                instance, function, args, kNoArgumentNames));
        if (result.IsError()) {
          return Api::NewHandle(isolate, result.raw());
        }
      }
      return Api::Success(isolate);
    }
  }
  return Api::NewError("Object does not implement the 'List' interface");
}


// --- Byte Arrays ---


DART_EXPORT bool Dart_IsByteArray(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsByteArray();
}


DART_EXPORT Dart_Handle Dart_NewByteArray(intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return Api::NewHandle(isolate, InternalByteArray::New(length));
}


DART_EXPORT Dart_Handle Dart_NewExternalByteArray(uint8_t* data,
                                                  intptr_t length,
                                                  void* peer,
                                                  Dart_PeerFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (data == NULL && length != 0) {
    return Api::NewError("%s expects argument 'data' to be non-null.",
                         CURRENT_FUNC);
  }
  if (length < 0) {
    return Api::NewError("%s expects argument 'length' to be greater than 0.",
                         CURRENT_FUNC);
  }
  return Api::NewHandle(
      isolate, ExternalByteArray::New(data, length, peer, callback));
}


DART_EXPORT Dart_Handle Dart_ExternalByteArrayGetPeer(Dart_Handle object,
                                                      void** peer) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const ExternalByteArray& array =
      Api::UnwrapExternalByteArrayHandle(isolate, object);
  if (array.IsNull()) {
    RETURN_TYPE_ERROR(isolate, object, ExternalByteArray);
  }
  if (peer == NULL) {
    return Api::NewError("%s expects argument 'peer' to be non-null.",
                         CURRENT_FUNC);
  }
  *peer = array.GetPeer();
  return Api::Success(isolate);
}


template<typename T>
Dart_Handle ByteArrayGetAt(T* value, Dart_Handle array, intptr_t offset) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  const ByteArray& array_obj = Api::UnwrapByteArrayHandle(isolate, array);
  if (array_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, array, ByteArray);
  }
  intptr_t length = sizeof(T);
  if (!Utils::RangeCheck(offset, length, array_obj.Length())) {
    return Api::NewError("Invalid index passed in to get byte array element");
  }
  uint8_t* dst = reinterpret_cast<uint8_t*>(value);
  ByteArray::Copy(dst, array_obj, offset, length);
  return Api::Success(isolate);
}


template<typename T>
Dart_Handle ByteArraySetAt(Dart_Handle array, intptr_t offset, T value) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  const ByteArray& array_obj = Api::UnwrapByteArrayHandle(isolate, array);
  if (array_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, array, ByteArray);
  }
  intptr_t length = sizeof(T);
  if (!Utils::RangeCheck(offset, length, array_obj.Length())) {
    return Api::NewError("Invalid index passed in to get byte array element");
  }
  const uint8_t* src = reinterpret_cast<uint8_t*>(&value);
  ByteArray::Copy(array_obj, offset, src, length);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetInt8At(Dart_Handle array,
                                                intptr_t offset,
                                                int8_t* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetInt8At(Dart_Handle array,
                                                intptr_t offset,
                                                int8_t value) {
  return ByteArraySetAt(array, offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetUint8At(Dart_Handle array,
                                                 intptr_t offset,
                                                 uint8_t* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetUint8At(Dart_Handle array,
                                                 intptr_t offset,
                                                 uint8_t value) {
  return ByteArraySetAt(array, offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetInt16At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int16_t* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetInt16At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int16_t value) {
  return ByteArraySetAt(array, offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetUint16At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint16_t* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetUint16At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint16_t value) {
  return ByteArraySetAt(array, offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetInt32At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int32_t* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetInt32At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int32_t value) {
  return ByteArraySetAt(array, offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetUint32At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint32_t* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetUint32At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint32_t value) {
  return ByteArraySetAt(array, offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetInt64At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int64_t* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetInt64At(Dart_Handle array,
                                                 intptr_t offset,
                                                 int64_t value) {
  return ByteArraySetAt(array, offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetUint64At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint64_t* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetUint64At(Dart_Handle array,
                                                  intptr_t offset,
                                                  uint64_t value) {
  return ByteArraySetAt(array, offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetFloat32At(Dart_Handle array,
                                                   intptr_t offset,
                                                   float* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetFloat32At(Dart_Handle array,
                                                   intptr_t offset,
                                                   float value) {
  return ByteArraySetAt(array, offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetFloat64At(Dart_Handle array,
                                                   intptr_t offset,
                                                   double* value) {
  return ByteArrayGetAt(value, array, offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetFloat64At(Dart_Handle array,
                                                   intptr_t offset,
                                                   double value) {
  return ByteArraySetAt(array, offset, value);
}


// --- Closures ---


DART_EXPORT bool Dart_IsClosure(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsClosure();
}


DART_EXPORT Dart_Handle Dart_InvokeClosure(Dart_Handle closure,
                                           int number_of_arguments,
                                           Dart_Handle* arguments) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(closure));
  if (obj.IsNull()) {
    return Api::NewError("Null object passed in to invoke closure");
  }
  if (!obj.IsClosure()) {
    return Api::NewError("Invalid closure passed to invoke closure");
  }
  ASSERT(ClassFinalizer::AllClassesFinalized());

  // Now try to invoke the closure.
  Closure& closure_obj = Closure::Handle(isolate);
  closure_obj ^= obj.raw();
  GrowableArray<const Object*> dart_arguments(number_of_arguments);
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg =
        Object::Handle(isolate, Api::UnwrapHandle(arguments[i]));
    dart_arguments.Add(&arg);
  }
  const Array& kNoArgumentNames = Array::Handle(isolate);
  return Api::NewHandle(
      isolate,
      DartEntry::InvokeClosure(closure_obj, dart_arguments, kNoArgumentNames));
}


DART_EXPORT int64_t Dart_ClosureSmrck(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Closure& obj =
      Closure::CheckedHandle(isolate, Api::UnwrapHandle(object));
  const Integer& smrck = Integer::Handle(isolate, obj.smrck());
  return smrck.IsNull() ? 0 : smrck.AsInt64Value();
}


DART_EXPORT void Dart_ClosureSetSmrck(Dart_Handle object, int64_t value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Closure& obj =
      Closure::CheckedHandle(isolate, Api::UnwrapHandle(object));
  const Integer& smrck = Integer::Handle(isolate, Integer::New(value));
  obj.set_smrck(smrck);
}


// --- Methods and Fields ---


DART_EXPORT Dart_Handle Dart_Invoke(Dart_Handle target,
                                    Dart_Handle name,
                                    int number_of_arguments,
                                    Dart_Handle* arguments) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  const String& function_name = Api::UnwrapStringHandle(isolate, name);
  if (function_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, name, String);
  }
  if (number_of_arguments < 0) {
    return Api::NewError(
        "%s expects argument 'number_of_arguments' to be non-negative.",
        CURRENT_FUNC);
  }

  // Check for malformed arguments in the arguments list.
  GrowableArray<const Object*> dart_args(number_of_arguments);
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg =
        Object::Handle(isolate, Api::UnwrapHandle(arguments[i]));
    if (!arg.IsNull() && !arg.IsInstance()) {
      if (arg.IsError()) {
        return Api::NewHandle(isolate, arg.raw());
      } else {
        return Api::NewError(
            "%s expects argument %d to be an instance of Object.",
            CURRENT_FUNC, i);
      }
    }
    dart_args.Add(&arg);
  }

  const Array& kNoArgNames = Array::Handle(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsNull()) {
    return Api::NewError("%s expects argument 'target' to be non-null.",
                         CURRENT_FUNC);
  } else if (obj.IsInstance()) {
    Instance& instance = Instance::Handle(isolate);
    instance ^= obj.raw();
    const Function& function = Function::Handle(
        isolate,
        Resolver::ResolveDynamic(instance,
                                 function_name,
                                 (number_of_arguments + 1),
                                 Resolver::kIsQualified));
    if (function.IsNull()) {
      const Type& type = Type::Handle(isolate, instance.GetType());
      const String& cls_name = String::Handle(isolate, type.ClassName());
      return Api::NewError("%s: did not find instance method '%s.%s'.",
                           CURRENT_FUNC,
                           cls_name.ToCString(),
                           function_name.ToCString());
    }
    return Api::NewHandle(
        isolate,
        DartEntry::InvokeDynamic(instance, function, dart_args, kNoArgNames));

  } else if (obj.IsClass()) {
    // Finalize all classes.
    const char* msg = CheckIsolateState(isolate);
    if (msg != NULL) {
      return Api::NewError(msg);
    }

    Class& cls = Class::Handle(isolate);
    cls ^= obj.raw();
    const Function& function = Function::Handle(
        isolate,
        Resolver::ResolveStatic(cls,
                                function_name,
                                number_of_arguments,
                                Array::Handle(isolate),
                                Resolver::kIsQualified));
    if (function.IsNull()) {
      const String& cls_name = String::Handle(isolate, cls.Name());
      return Api::NewError("%s: did not find static method '%s.%s'.",
                           CURRENT_FUNC,
                           cls_name.ToCString(),
                           function_name.ToCString());
    }
    return Api::NewHandle(
        isolate,
        DartEntry::InvokeStatic(function, dart_args, kNoArgNames));

  } else if (obj.IsLibrary()) {
    // Check whether class finalization is needed.
    bool finalize_classes = true;
    Library& lib = Library::Handle(isolate);
    lib ^= obj.raw();

    // When calling functions in the dart:builtin library do not finalize as it
    // should have been prefinalized.
    Library& builtin =
        Library::Handle(isolate, isolate->object_store()->builtin_library());
    if (builtin.raw() == lib.raw()) {
      finalize_classes = false;
    }

    // Finalize all classes if needed.
    if (finalize_classes) {
      const char* msg = CheckIsolateState(isolate);
      if (msg != NULL) {
        return Api::NewError(msg);
      }
    }

    Function& function = Function::Handle(isolate);
    function = lib.LookupLocalFunction(function_name);
    // LookupLocalFunction does not check argument arity, so we do it here.
    if (!function.IsNull() &&
        !function.AreValidArgumentCounts(number_of_arguments, 0)) {
      function = Function::null();
    }
    if (function.IsNull()) {
      return Api::NewError("%s: did not find top-level function '%s'.",
                           CURRENT_FUNC,
                           function_name.ToCString());
    }
    return Api::NewHandle(
        isolate, DartEntry::InvokeStatic(function, dart_args, kNoArgNames));

  } else {
    return Api::NewError(
        "%s expects argument 'target' to be an object, class, or library.",
        CURRENT_FUNC);
  }
}


DART_EXPORT Dart_Handle Dart_InvokeStatic(Dart_Handle library_in,
                                          Dart_Handle class_name_in,
                                          Dart_Handle function_name_in,
                                          int number_of_arguments,
                                          Dart_Handle* arguments) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  // Check whether class finalization is needed.
  bool finalize_classes = true;
  const Library& library =
      Library::CheckedHandle(isolate, Api::UnwrapHandle(library_in));
  if (library.IsNull()) {
    return Api::NewError("No library specified");
  }

  // When calling functions in the dart:builtin library do not finalize as it
  // should have been prefinalized.
  Library& builtin =
      Library::Handle(isolate, isolate->object_store()->builtin_library());
  if (builtin.raw() == library.raw()) {
    finalize_classes = false;
  }

  // Finalize all classes if needed.
  if (finalize_classes) {
    const char* msg = CheckIsolateState(isolate);
    if (msg != NULL) {
      return Api::NewError(msg);
    }
  }

  // Now try to resolve and invoke the static function.
  const String& class_name =
      String::CheckedHandle(isolate, Api::UnwrapHandle(class_name_in));
  const String& function_name =
      String::CheckedHandle(isolate, Api::UnwrapHandle(function_name_in));
  const Function& function = Function::Handle(
      isolate,
      Resolver::ResolveStatic(library,
                              class_name,
                              function_name,
                              number_of_arguments,
                              Array::Handle(isolate),  // Named arguments are
                                                       // not yet supported.
                              Resolver::kIsQualified));
  if (function.IsNull()) {
    char* msg;
    if (class_name.IsNull()) {
      const char* format = "Unable to find entrypoint: %s()";
      intptr_t length = OS::SNPrint(NULL, 0, format, function_name.ToCString());
      msg = reinterpret_cast<char*>(Api::Allocate(isolate, length + 1));
      OS::SNPrint(msg, (length + 1), format, function_name.ToCString());
    } else {
      const char* format = "Unable to find entrypoint: static %s.%s()";
      intptr_t length = OS::SNPrint(NULL, 0, format,
                                    class_name.ToCString(),
                                    function_name.ToCString());
      msg = reinterpret_cast<char*>(Api::Allocate(isolate, length + 1));
      OS::SNPrint(msg, (length + 1), format,
                  class_name.ToCString(), function_name.ToCString());
    }
    return Api::NewError(msg);
  }
  GrowableArray<const Object*> dart_arguments(number_of_arguments);
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg =
        Object::Handle(isolate, Api::UnwrapHandle(arguments[i]));
    dart_arguments.Add(&arg);
  }
  const Array& kNoArgumentNames = Array::Handle(isolate);
  return Api::NewHandle(
      isolate,
      DartEntry::InvokeStatic(function, dart_arguments, kNoArgumentNames));
}


DART_EXPORT Dart_Handle Dart_InvokeDynamic(Dart_Handle object,
                                           Dart_Handle function_name,
                                           int number_of_arguments,
                                           Dart_Handle* arguments) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  // Let the resolver figure out the correct target for null receiver.
  // E.g., (null).toString() should execute correctly.
  if (!obj.IsNull() && !obj.IsInstance()) {
    return Api::NewError(
        "Invalid receiver (not instance) passed to invoke dynamic");
  }
  if (function_name == NULL) {
    return Api::NewError("Invalid function name specified");
  }
  ASSERT(ClassFinalizer::AllClassesFinalized());

  // Now try to resolve and invoke the dynamic function on this object.
  Instance& receiver = Instance::Handle(isolate);
  receiver ^= obj.raw();
  const String& name =
      String::CheckedHandle(isolate, Api::UnwrapHandle(function_name));
  const Function& function = Function::Handle(
      isolate,
      Resolver::ResolveDynamic(receiver,
                               name,
                               (number_of_arguments + 1),
                               0));  // Named args not yet supported in API.
  if (function.IsNull()) {
    // TODO(5415268): Invoke noSuchMethod instead of failing.
    OS::PrintErr("Unable to find instance function: %s\n", name.ToCString());
    return Api::NewError("Unable to find instance function");
  }
  GrowableArray<const Object*> dart_arguments(number_of_arguments);
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg =
        Object::Handle(isolate, Api::UnwrapHandle(arguments[i]));
    dart_arguments.Add(&arg);
  }
  const Array& kNoArgumentNames = Array::Handle(isolate);
  return Api::NewHandle(
      isolate,
      DartEntry::InvokeDynamic(
          receiver, function, dart_arguments, kNoArgumentNames));
}


static const bool kGetter = true;
static const bool kSetter = false;


static bool FieldIsUninitialized(Isolate* isolate, const Field& fld) {
  ASSERT(!fld.IsNull());

  // Return getter method for uninitialized fields, rather than the
  // field object, since the value in the field object will not be
  // initialized until the first time the getter is invoked.
  const Instance& value = Instance::Handle(isolate, fld.value());
  ASSERT(value.raw() != Object::transition_sentinel());
  return value.raw() == Object::sentinel();
}


static Dart_Handle LookupStaticField(Isolate* isolate,
                                     Dart_Handle clazz,
                                     Dart_Handle field_name,
                                     bool is_getter) {
  const Object& param1 = Object::Handle(isolate, Api::UnwrapHandle(clazz));
  const Object& param2 = Object::Handle(isolate, Api::UnwrapHandle(field_name));
  if (param1.IsNull() || !param1.IsClass()) {
    return Api::NewError("Invalid class specified");
  }
  if (param2.IsNull() || !param2.IsString()) {
    return Api::NewError("Invalid field name specified");
  }
  Class& cls = Class::Handle(isolate);
  cls ^= param1.raw();
  String& fld_name = String::Handle(isolate);
  fld_name ^= param2.raw();
  const Field& fld = Field::Handle(isolate, cls.LookupStaticField(fld_name));
  if (is_getter && (fld.IsNull() || FieldIsUninitialized(isolate, fld))) {
    const String& func_name =
        String::Handle(isolate, Field::GetterName(fld_name));
    const Function& function =
        Function::Handle(isolate, cls.LookupStaticFunction(func_name));
    if (!function.IsNull()) {
      return Api::NewHandle(isolate, function.raw());
    }
    return Api::NewError("Specified field is not found in the class");
  }
  if (fld.IsNull()) {
    return Api::NewError("Specified field is not found in the class");
  }
  return Api::NewHandle(isolate, fld.raw());
}


static Dart_Handle LookupInstanceField(Isolate* isolate,
                                       const Object& object,
                                       Dart_Handle name,
                                       bool is_getter) {
  const Object& param = Object::Handle(isolate, Api::UnwrapHandle(name));
  if (param.IsNull() || !param.IsString()) {
    return Api::NewError("Invalid field name specified");
  }
  String& field_name = String::Handle(isolate);
  field_name ^= param.raw();
  String& func_name = String::Handle(isolate);
  Field& fld = Field::Handle(isolate);
  Class& cls = Class::Handle(isolate, object.clazz());
  while (!cls.IsNull()) {
    fld = cls.LookupInstanceField(field_name);
    if (!fld.IsNull()) {
      if (!is_getter && fld.is_final()) {
        return Api::NewError("Cannot set value of final fields");
      }
      func_name = (is_getter
                   ? Field::GetterName(field_name)
                   : Field::SetterName(field_name));
      const Function& function =
          Function::Handle(isolate, cls.LookupDynamicFunction(func_name));
      if (function.IsNull()) {
        return Api::NewError("Unable to find accessor function in the class");
      }
      return Api::NewHandle(isolate, function.raw());
    }
    cls = cls.SuperClass();
  }
  return Api::NewError("Unable to find field '%s'.", field_name.ToCString());
}


DART_EXPORT Dart_Handle Dart_GetField(Dart_Handle container, Dart_Handle name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  const String& field_name = Api::UnwrapStringHandle(isolate, name);
  if (field_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, name, String);
  }

  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(container));

  Field& field = Field::Handle(isolate);
  Function& getter = Function::Handle(isolate);
  if (obj.IsNull()) {
    return Api::NewError("%s expects argument 'container' to be non-null.",
                         CURRENT_FUNC);
  } else if (obj.IsInstance()) {
    // Every instance field has a getter Function.  Try to find the
    // getter in any superclass and use that function to access the
    // field.
    Instance& instance = Instance::Handle(isolate);
    instance ^= obj.raw();
    Class& cls = Class::Handle(isolate, instance.clazz());
    while (!cls.IsNull()) {
      String& getter_name =
          String::Handle(isolate, Field::GetterName(field_name));
      getter = cls.LookupDynamicFunction(getter_name);
      if (!getter.IsNull()) {
        break;
      }
      cls = cls.SuperClass();
    }

    if (getter.IsNull()) {
      return Api::NewError("%s: did not find instance field '%s'.",
                           CURRENT_FUNC, field_name.ToCString());
    }

    // Invoke the getter and return the result.
    GrowableArray<const Object*> args;
    const Array& kNoArgNames = Array::Handle(isolate);
    return Api::NewHandle(
        isolate,
        DartEntry::InvokeDynamic(instance, getter, args, kNoArgNames));

  } else if (obj.IsClass()) {
    // To access a static field we may need to use the Field or the
    // getter Function.
    Class& cls = Class::Handle(isolate);
    cls ^= obj.raw();
    field = cls.LookupStaticField(field_name);
    if (field.IsNull() || FieldIsUninitialized(isolate, field)) {
      const String& getter_name =
          String::Handle(isolate, Field::GetterName(field_name));
      getter = cls.LookupStaticFunction(getter_name);
    }

    if (!getter.IsNull()) {
      // Invoke the getter and return the result.
      GrowableArray<const Object*> args;
      const Array& kNoArgNames = Array::Handle(isolate);
      return Api::NewHandle(
          isolate, DartEntry::InvokeStatic(getter, args, kNoArgNames));
    } else if (!field.IsNull()) {
      return Api::NewHandle(isolate, field.value());
    } else {
      return Api::NewError("%s: did not find static field '%s'.",
                           CURRENT_FUNC, field_name.ToCString());
    }

  } else if (obj.IsLibrary()) {
    // To access a top-level we may need to use the Field or the
    // getter Function.  The getter function may either be in the
    // library or in the field's owner class, depending.
    Library& lib = Library::Handle(isolate);
    lib ^= obj.raw();
    field = lib.LookupLocalField(field_name);
    if (field.IsNull()) {
      // No field found.  Check for a getter in the lib.
      const String& getter_name =
          String::Handle(isolate, Field::GetterName(field_name));
      getter = lib.LookupLocalFunction(getter_name);
    } else if (FieldIsUninitialized(isolate, field)) {
      // A field was found.  Check for a getter in the field's owner classs.
      const Class& cls = Class::Handle(isolate, field.owner());
      const String& getter_name =
          String::Handle(isolate, Field::GetterName(field_name));
      getter = cls.LookupStaticFunction(getter_name);
    }

    if (!getter.IsNull()) {
      // Invoke the getter and return the result.
      GrowableArray<const Object*> args;
      const Array& kNoArgNames = Array::Handle(isolate);
      return Api::NewHandle(
          isolate, DartEntry::InvokeStatic(getter, args, kNoArgNames));
    } else if (!field.IsNull()) {
      return Api::NewHandle(isolate, field.value());
    } else {
      return Api::NewError("%s: did not find top-level variable '%s'.",
                           CURRENT_FUNC, field_name.ToCString());
    }

  } else {
    return Api::NewError(
        "%s expects argument 'container' to be an object, class, or library.",
        CURRENT_FUNC);
  }
}


DART_EXPORT Dart_Handle Dart_SetField(Dart_Handle container,
                                      Dart_Handle name,
                                      Dart_Handle value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  const String& field_name = Api::UnwrapStringHandle(isolate, name);
  if (field_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, name, String);
  }

  // Since null is allowed for value, we don't use UnwrapInstanceHandle.
  const Object& value_obj = Object::Handle(isolate, Api::UnwrapHandle(value));
  if (!value_obj.IsNull() && !value_obj.IsInstance()) {
    RETURN_TYPE_ERROR(isolate, value, Instance);
  }
  Instance& value_instance = Instance::Handle(isolate);
  value_instance ^= value_obj.raw();

  Field& field = Field::Handle(isolate);
  Function& setter = Function::Handle(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(container));
  if (obj.IsNull()) {
    return Api::NewError("%s expects argument 'container' to be non-null.",
                         CURRENT_FUNC);
  } else if (obj.IsInstance()) {
    // Every instance field has a setter Function.  Try to find the
    // setter in any superclass and use that function to access the
    // field.
    Instance& instance = Instance::Handle(isolate);
    instance ^= obj.raw();
    Class& cls = Class::Handle(isolate, instance.clazz());
    while (!cls.IsNull()) {
      field = cls.LookupInstanceField(field_name);
      if (!field.IsNull() && field.is_final()) {
        return Api::NewError("%s: cannot set final field '%s'.",
                             CURRENT_FUNC, field_name.ToCString());
      }
      String& setter_name =
          String::Handle(isolate, Field::SetterName(field_name));
      setter = cls.LookupDynamicFunction(setter_name);
      if (!setter.IsNull()) {
        break;
      }
      cls = cls.SuperClass();
    }

    if (setter.IsNull()) {
      return Api::NewError("%s: did not find instance field '%s'.",
                           CURRENT_FUNC, field_name.ToCString());
    }

    // Invoke the setter and return the result.
    GrowableArray<const Object*> args(1);
    args.Add(&value_instance);
    const Array& kNoArgNames = Array::Handle(isolate);
    return Api::NewHandle(
        isolate,
        DartEntry::InvokeDynamic(instance, setter, args, kNoArgNames));

  } else if (obj.IsClass()) {
    // To access a static field we may need to use the Field or the
    // setter Function.
    Class& cls = Class::Handle(isolate);
    cls ^= obj.raw();
    field = cls.LookupStaticField(field_name);
    if (field.IsNull()) {
      String& setter_name =
          String::Handle(isolate, Field::SetterName(field_name));
      setter = cls.LookupStaticFunction(setter_name);
    }

    if (!setter.IsNull()) {
      // Invoke the setter and return the result.
      GrowableArray<const Object*> args(1);
      args.Add(&value_instance);
      const Array& kNoArgNames = Array::Handle(isolate);
      const Object& result = Object::Handle(
          isolate,
          DartEntry::InvokeStatic(setter, args, kNoArgNames));
      if (result.IsError()) {
        return Api::NewHandle(isolate, result.raw());
      } else {
        return Api::Success(isolate);
      }
    } else if (!field.IsNull()) {
      if (field.is_final()) {
        return Api::NewError("%s: cannot set final field '%s'.",
                             CURRENT_FUNC, field_name.ToCString());
      } else {
        field.set_value(value_instance);
        return Api::Success(isolate);
      }
    } else {
      return Api::NewError("%s: did not find static field '%s'.",
                           CURRENT_FUNC, field_name.ToCString());
    }

  } else if (obj.IsLibrary()) {
    // To access a top-level we may need to use the Field or the
    // setter Function.  The setter function may either be in the
    // library or in the field's owner class, depending.
    Library& lib = Library::Handle(isolate);
    lib ^= obj.raw();
    field = lib.LookupLocalField(field_name);
    if (field.IsNull()) {
      const String& setter_name =
          String::Handle(isolate, Field::SetterName(field_name));
      setter ^= lib.LookupLocalFunction(setter_name);
    }

    if (!setter.IsNull()) {
      // Invoke the setter and return the result.
      GrowableArray<const Object*> args(1);
      args.Add(&value_instance);
      const Array& kNoArgNames = Array::Handle(isolate);
      const Object& result = Object::Handle(
          isolate, DartEntry::InvokeStatic(setter, args, kNoArgNames));
      if (result.IsError()) {
        return Api::NewHandle(isolate, result.raw());
      } else {
        return Api::Success(isolate);
      }
    } else if (!field.IsNull()) {
      if (field.is_final()) {
        return Api::NewError("%s: cannot set final top-level variable '%s'.",
                             CURRENT_FUNC, field_name.ToCString());
      } else {
        field.set_value(value_instance);
        return Api::Success(isolate);
      }
    } else {
      return Api::NewError("%s: did not find top-level variable '%s'.",
                           CURRENT_FUNC, field_name.ToCString());
    }

  } else {
    return Api::NewError(
        "%s expects argument 'container' to be an object, class, or library.",
        CURRENT_FUNC);
  }
}


DART_EXPORT Dart_Handle Dart_GetStaticField(Dart_Handle cls,
                                            Dart_Handle name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Dart_Handle result = LookupStaticField(isolate, cls, name, kGetter);
  if (::Dart_IsError(result)) {
    return result;
  }
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(result));
  if (obj.IsField()) {
    Field& fld = Field::Handle(isolate);
    fld ^= obj.raw();
    return Api::NewHandle(isolate, fld.value());
  } else {
    Function& func = Function::Handle(isolate);
    func ^= obj.raw();
    GrowableArray<const Object*> args;
    const Array& kNoArgumentNames = Array::Handle(isolate);
    return Api::NewHandle(
        isolate, DartEntry::InvokeStatic(func, args, kNoArgumentNames));
  }
}


// TODO(iposva): The value parameter should be documented as being an instance.
// TODO(turnidge): Is this skipping the setter?
DART_EXPORT Dart_Handle Dart_SetStaticField(Dart_Handle cls,
                                            Dart_Handle name,
                                            Dart_Handle value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Dart_Handle result = LookupStaticField(isolate, cls, name, kSetter);
  if (::Dart_IsError(result)) {
    return result;
  }
  Field& fld = Field::Handle(isolate);
  fld ^= Api::UnwrapHandle(result);
  if (fld.is_final()) {
    return Api::NewError(
        "Specified field is a static final field in the class");
  }
  const Object& val = Object::Handle(isolate, Api::UnwrapHandle(value));
  Instance& instance = Instance::Handle(isolate);
  instance ^= val.raw();
  fld.set_value(instance);
  return Api::NewHandle(isolate, val.raw());
}


DART_EXPORT Dart_Handle Dart_GetInstanceField(Dart_Handle obj,
                                              Dart_Handle name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& param = Object::Handle(isolate, Api::UnwrapHandle(obj));
  if (param.IsNull() || !param.IsInstance()) {
    return Api::NewError("Invalid object passed in to access instance field");
  }
  Instance& object = Instance::Handle(isolate);
  object ^= param.raw();
  Dart_Handle result = LookupInstanceField(isolate, object, name, kGetter);
  if (::Dart_IsError(result)) {
    return result;
  }
  Function& func = Function::Handle(isolate);
  func ^= Api::UnwrapHandle(result);
  GrowableArray<const Object*> arguments;
  const Array& kNoArgumentNames = Array::Handle(isolate);
  return Api::NewHandle(
      isolate,
      DartEntry::InvokeDynamic(object, func, arguments, kNoArgumentNames));
}


DART_EXPORT Dart_Handle Dart_SetInstanceField(Dart_Handle obj,
                                              Dart_Handle name,
                                              Dart_Handle value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& param = Object::Handle(isolate, Api::UnwrapHandle(obj));
  if (param.IsNull() || !param.IsInstance()) {
    return Api::NewError("Invalid object passed in to access instance field");
  }
  Instance& object = Instance::Handle(isolate);
  object ^= param.raw();
  Dart_Handle result = LookupInstanceField(isolate, object, name, kSetter);
  if (::Dart_IsError(result)) {
    return result;
  }
  Function& func = Function::Handle(isolate);
  func ^= Api::UnwrapHandle(result);
  GrowableArray<const Object*> arguments(1);
  const Object& arg = Object::Handle(isolate, Api::UnwrapHandle(value));
  arguments.Add(&arg);
  const Array& kNoArgumentNames = Array::Handle(isolate);
  return Api::NewHandle(
      isolate,
      DartEntry::InvokeDynamic(object, func, arguments, kNoArgumentNames));
}


DART_EXPORT Dart_Handle Dart_CreateNativeWrapperClass(Dart_Handle library,
                                                      Dart_Handle name,
                                                      int field_count) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& param = Object::Handle(isolate, Api::UnwrapHandle(name));
  if (param.IsNull() || !param.IsString() || field_count <= 0) {
    return Api::NewError(
        "Invalid arguments passed to Dart_CreateNativeWrapperClass");
  }
  String& cls_name = String::Handle(isolate);
  cls_name ^= param.raw();
  cls_name = String::NewSymbol(cls_name);
  Library& lib = Library::Handle(isolate);
  lib ^= Api::UnwrapHandle(library);
  if (lib.IsNull()) {
    return Api::NewError(
        "Invalid arguments passed to Dart_CreateNativeWrapperClass");
  }
  const Class& cls = Class::Handle(
      isolate, Class::NewNativeWrapper(&lib, cls_name, field_count));
  if (cls.IsNull()) {
    return Api::NewError(
        "Unable to create native wrapper class : already exists");
  }
  return Api::NewHandle(isolate, cls.raw());
}


DART_EXPORT Dart_Handle Dart_GetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t* value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& param = Object::Handle(isolate, Api::UnwrapHandle(obj));
  if (param.IsNull() || !param.IsInstance()) {
    return Api::NewError(
        "Invalid object passed in to access native instance field");
  }
  Instance& object = Instance::Handle(isolate);
  object ^= param.raw();
  if (!object.IsValidNativeIndex(index)) {
    return Api::NewError(
        "Invalid index passed in to access native instance field");
  }
  *value = object.GetNativeField(index);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_SetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& param = Object::Handle(isolate, Api::UnwrapHandle(obj));
  if (param.IsNull() || !param.IsInstance()) {
    return Api::NewError(
        "Invalid object passed in to set native instance field");
  }
  Instance& object = Instance::Handle(isolate);
  object ^= param.raw();
  if (!object.IsValidNativeIndex(index)) {
    return Api::NewError(
        "Invalid index passed in to set native instance field");
  }
  object.SetNativeField(index, value);
  return Api::Success(isolate);
}


// --- Exceptions ----


DART_EXPORT Dart_Handle Dart_ThrowException(Dart_Handle exception) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (isolate->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    return Api::NewError("No Dart frames on stack, cannot throw exception");
  }
  const Instance& excp =
      Instance::CheckedHandle(isolate, Api::UnwrapHandle(exception));
  // Unwind all the API scopes till the exit frame before throwing an
  // exception.
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  state->UnwindScopes(isolate->top_exit_frame_info());
  Exceptions::Throw(excp);
  return Api::NewError("Exception was not thrown, internal error");
}


DART_EXPORT Dart_Handle Dart_ReThrowException(Dart_Handle exception,
                                              Dart_Handle stacktrace) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (isolate->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    return Api::NewError("No Dart frames on stack, cannot throw exception");
  }
  DARTSCOPE(isolate);
  const Instance& excp =
      Instance::CheckedHandle(isolate, Api::UnwrapHandle(exception));
  const Instance& stk =
      Instance::CheckedHandle(isolate, Api::UnwrapHandle(stacktrace));
  // Unwind all the API scopes till the exit frame before throwing an
  // exception.
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  state->UnwindScopes(isolate->top_exit_frame_info());
  Exceptions::ReThrow(excp, stk);
  return Api::NewError("Exception was not re thrown, internal error");
}


// --- Native functions ---


DART_EXPORT Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args,
                                               int index) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  if (index < 0 || index >= arguments->Count()) {
    return Api::NewError(
        "%s: argument 'index' out of range. Expected 0..%d but saw %d.",
        CURRENT_FUNC, arguments->Count() - 1, index);
  }
  Isolate* isolate = arguments->isolate();
  CHECK_ISOLATE(isolate);
  return Api::NewHandle(isolate, arguments->At(index));
}


DART_EXPORT int Dart_GetNativeArgumentCount(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  return arguments->Count();
}


DART_EXPORT void Dart_SetReturnValue(Dart_NativeArguments args,
                                     Dart_Handle retval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Isolate* isolate = arguments->isolate();
  DARTSCOPE(isolate);
  arguments->SetReturn(Object::Handle(isolate, Api::UnwrapHandle(retval)));
}


// --- Scripts and Libraries ---


// NOTE: Need to pass 'result' as a parameter here in order to avoid
// warning: variable 'result' might be clobbered by 'longjmp' or 'vfork'
// which shows up because of the use of setjmp.
static void CompileSource(Isolate* isolate,
                          const Library& lib,
                          const String& url,
                          const String& source,
                          RawScript::Kind kind,
                          Dart_Handle* result) {
  bool update_lib_status = (kind == RawScript::kScript ||
                            kind == RawScript::kLibrary);
  if (update_lib_status) {
    lib.SetLoadInProgress();
  }
  const Script& script =
      Script::Handle(isolate, Script::New(url, source, kind));
  ASSERT(isolate != NULL);
  const Error& error = Error::Handle(isolate, Compiler::Compile(lib, script));
  if (error.IsNull()) {
    *result = Api::NewHandle(isolate, lib.raw());
    if (update_lib_status) {
      lib.SetLoaded();
    }
  } else {
    *result = Api::NewHandle(isolate, error.raw());
    if (update_lib_status) {
      lib.SetLoadError();
    }
  }
}


DART_EXPORT Dart_Handle Dart_LoadScript(Dart_Handle url,
                                        Dart_Handle source,
                                        Dart_LibraryTagHandler handler,
                                        Dart_Handle import_map) {
  TIMERSCOPE(time_script_loading);
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& url_str = Api::UnwrapStringHandle(isolate, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(isolate, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, source, String);
  }
  const Array& mapping_array = Api::UnwrapArrayHandle(isolate, import_map);
  Library& library =
      Library::Handle(isolate, isolate->object_store()->root_library());
  if (!library.IsNull()) {
    const String& library_url = String::Handle(isolate, library.url());
    return Api::NewError("%s: A script has already been loaded from '%s'.",
                         CURRENT_FUNC, library_url.ToCString());
  }
  isolate->set_library_tag_handler(handler);
  library = Library::New(url_str);
  if (mapping_array.IsNull()) {
    library.set_import_map(Array::Handle(isolate, Array::Empty()));
  } else {
    library.set_import_map(mapping_array);
  }
  library.Register();
  isolate->object_store()->set_root_library(library);
  Dart_Handle result;
  CompileSource(isolate,
                library,
                url_str,
                source_str,
                RawScript::kScript,
                &result);
  return result;
}


DART_EXPORT Dart_Handle Dart_LoadScriptFromSnapshot(const uint8_t* buffer) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  TIMERSCOPE(time_script_loading);
  if (buffer == NULL) {
    return Api::NewError("%s expects argument 'buffer' to be non-null.",
                         CURRENT_FUNC);
  }
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);
  if (!snapshot->IsScriptSnapshot()) {
    return Api::NewError("%s expects parameter 'buffer' to be a script type"
                         " snapshot", CURRENT_FUNC);
  }
  Library& library =
      Library::Handle(isolate, isolate->object_store()->root_library());
  if (!library.IsNull()) {
    const String& library_url = String::Handle(isolate, library.url());
    return Api::NewError("%s: A script has already been loaded from '%s'.",
                         CURRENT_FUNC, library_url.ToCString());
  }
  SnapshotReader reader(snapshot, isolate);
  const Object& tmp = Object::Handle(isolate, reader.ReadObject());
  if (!tmp.IsLibrary()) {
    return Api::NewError("%s: Unable to deserialize snapshot correctly.",
                         CURRENT_FUNC);
  }
  library ^= tmp.raw();
  isolate->object_store()->set_root_library(library);
  return Api::NewHandle(isolate, library.raw());
}


static void CompileAll(Isolate* isolate, Dart_Handle* result) {
  ASSERT(isolate != NULL);
  const Error& error = Error::Handle(isolate, Library::CompileAll());
  if (error.IsNull()) {
    *result = Api::Success(isolate);
  } else {
    *result = Api::NewHandle(isolate, error.raw());
  }
}


DART_EXPORT Dart_Handle Dart_CompileAll() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Dart_Handle result;
  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }
  CompileAll(isolate, &result);
  return result;
}


DART_EXPORT bool Dart_IsLibrary(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsLibrary();
}


DART_EXPORT Dart_Handle Dart_GetClass(Dart_Handle library, Dart_Handle name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& param = Object::Handle(isolate, Api::UnwrapHandle(name));
  if (param.IsNull() || !param.IsString()) {
    return Api::NewError("Invalid class name specified");
  }
  const Library& lib =
      Library::CheckedHandle(isolate, Api::UnwrapHandle(library));
  if (lib.IsNull()) {
    return Api::NewError("Invalid parameter, Unknown library specified");
  }
  String& cls_name = String::Handle(isolate);
  cls_name ^= param.raw();
  const Class& cls = Class::Handle(isolate, lib.LookupClass(cls_name));
  if (cls.IsNull()) {
    const String& lib_name = String::Handle(isolate, lib.name());
    return Api::NewError("Class '%s' not found in library '%s'.",
                         cls_name.ToCString(), lib_name.ToCString());
  }
  return Api::NewHandle(isolate, cls.raw());
}


DART_EXPORT Dart_Handle Dart_LibraryUrl(Dart_Handle library) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }
  const String& url = String::Handle(isolate, lib.url());
  ASSERT(!url.IsNull());
  return Api::NewHandle(isolate, url.raw());
}


DART_EXPORT Dart_Handle Dart_LookupLibrary(Dart_Handle url) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& url_str = Api::UnwrapStringHandle(isolate, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, url, String);
  }
  const Library& library =
      Library::Handle(isolate, Library::LookupLibrary(url_str));
  if (library.IsNull()) {
    return Api::NewError("%s: library '%s' not found.",
                         CURRENT_FUNC, url_str.ToCString());
  } else {
    return Api::NewHandle(isolate, library.raw());
  }
}


DART_EXPORT Dart_Handle Dart_LoadLibrary(Dart_Handle url,
                                         Dart_Handle source,
                                         Dart_Handle import_map) {
  TIMERSCOPE(time_script_loading);
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& url_str = Api::UnwrapStringHandle(isolate, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(isolate, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, source, String);
  }
  const Array& mapping_array = Api::UnwrapArrayHandle(isolate, import_map);
  Library& library = Library::Handle(isolate, Library::LookupLibrary(url_str));
  if (library.IsNull()) {
    library = Library::New(url_str);
    if (mapping_array.IsNull()) {
      library.set_import_map(Array::Handle(isolate, Array::Empty()));
    } else {
      library.set_import_map(mapping_array);
    }
    library.Register();
  } else if (!library.LoadNotStarted()) {
    // The source for this library has either been loaded or is in the
    // process of loading.  Return an error.
    return Api::NewError("%s: library '%s' has already been loaded.",
                         CURRENT_FUNC, url_str.ToCString());
  }
  Dart_Handle result;
  CompileSource(isolate,
                library,
                url_str,
                source_str,
                RawScript::kLibrary,
                &result);
  // Propagate the error out right now.
  if (::Dart_IsError(result)) {
    return result;
  }

  // If this is the dart:builtin library, register it with the VM.
  if (url_str.Equals("dart:builtin")) {
    isolate->object_store()->set_builtin_library(library);
    const char* msg = CheckIsolateState(isolate);
    if (msg != NULL) {
      return Api::NewError(msg);
    }
  }
  return result;
}


DART_EXPORT Dart_Handle Dart_LibraryImportLibrary(Dart_Handle library,
                                                  Dart_Handle import) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& library_vm = Api::UnwrapLibraryHandle(isolate, library);
  if (library_vm.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }
  const Library& import_vm = Api::UnwrapLibraryHandle(isolate, import);
  if (import_vm.IsNull()) {
    RETURN_TYPE_ERROR(isolate, import, Library);
  }
  library_vm.AddImport(import_vm);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_LoadSource(Dart_Handle library,
                                        Dart_Handle url,
                                        Dart_Handle source) {
  TIMERSCOPE(time_script_loading);
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }
  const String& url_str = Api::UnwrapStringHandle(isolate, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(isolate, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, source, String);
  }
  Dart_Handle result;
  CompileSource(isolate, lib, url_str, source_str, RawScript::kSource, &result);
  return result;
}


DART_EXPORT Dart_Handle Dart_SetNativeResolver(
    Dart_Handle library,
    Dart_NativeEntryResolver resolver) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }
  lib.set_native_entry_resolver(resolver);
  return Api::Success(isolate);
}


// --- Profiling support ----


DART_EXPORT void Dart_InitPprofSupport() {
  DebugInfo* pprof_symbol_generator = DebugInfo::NewGenerator();
  ASSERT(pprof_symbol_generator != NULL);
  Dart::set_pprof_symbol_generator(pprof_symbol_generator);
}


DART_EXPORT void Dart_GetPprofSymbolInfo(void** buffer, int* buffer_size) {
  Isolate* isolate = Isolate::Current();
  DebugInfo* pprof_symbol_generator = Dart::pprof_symbol_generator();
  if (pprof_symbol_generator != NULL) {
    DebugInfo::ByteBuffer* debug_region = new DebugInfo::ByteBuffer();
    ASSERT(debug_region != NULL);
    pprof_symbol_generator->WriteToMemory(debug_region);
    *buffer_size = debug_region->size();
    if (*buffer_size != 0) {
      *buffer = reinterpret_cast<void*>(Api::Allocate(isolate, *buffer_size));
      memmove(*buffer, debug_region->data(), *buffer_size);
    } else {
      *buffer = NULL;
    }
    delete debug_region;
  } else {
    *buffer = NULL;
    *buffer_size = 0;
  }
}

}  // namespace dart
