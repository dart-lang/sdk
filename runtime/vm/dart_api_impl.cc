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
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/message.h"
#include "vm/native_entry.h"
#include "vm/native_message_handler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/timer.h"
#include "vm/unicode.h"
#include "vm/verifier.h"

namespace dart {

DECLARE_FLAG(bool, print_class_table);
DECLARE_FLAG(bool, use_cha);

ThreadLocalKey Api::api_native_key_ = Thread::kUnsetThreadLocalKey;


const char* CanonicalFunction(const char* func) {
  if (strncmp(func, "dart::", 6) == 0) {
    return func + 6;
  } else {
    return func;
  }
}


#define RETURN_TYPE_ERROR(isolate, dart_handle, type)                          \
  do {                                                                         \
    const Object& tmp =                                                        \
        Object::Handle(isolate, Api::UnwrapHandle((dart_handle)));             \
    if (tmp.IsNull()) {                                                        \
      return Api::NewError("%s expects argument '%s' to be non-null.",         \
                           CURRENT_FUNC, #dart_handle);                        \
    } else if (tmp.IsError()) {                                                \
      return dart_handle;                                                      \
    } else {                                                                   \
      return Api::NewError("%s expects argument '%s' to be of type %s.",       \
                           CURRENT_FUNC, #dart_handle, #type);                 \
    }                                                                          \
  } while (0)


#define RETURN_NULL_ERROR(parameter)                                           \
  return Api::NewError("%s expects argument '%s' to be non-null.",             \
                       CURRENT_FUNC, #parameter);


#define CHECK_LENGTH(length, max_elements)                                     \
  do {                                                                         \
    intptr_t len = (length);                                                   \
    intptr_t max = (max_elements);                                             \
    if (len < 0 || len > max) {                                                \
      return Api::NewError(                                                    \
          "%s expects argument '%s' to be in the range [0..%ld].",             \
          CURRENT_FUNC, #length, max);                                         \
    }                                                                          \
  } while (0)


// Return error if isolate is in an inconsistent state.
// Return NULL when no error condition exists.
//
// TODO(turnidge): Make this function return an error handle directly
// rather than returning an error string.  The current behavior can
// cause compilation errors to appear to be api errors.
const char* CheckIsolateState(Isolate* isolate) {
  if (ClassFinalizer::FinalizePendingClasses() &&
      isolate->object_store()->PreallocateObjects()) {
    // Success.
    return NULL;
  }
  // Make a copy of the error message as the original message string
  // may get deallocated when we return back from the Dart API call.
  const Error& err = Error::Handle(isolate->object_store()->sticky_error());
  const char* errmsg = err.ToErrorCString();
  intptr_t errlen = strlen(errmsg) + 1;
  char* msg = Api::TopScope(isolate)->zone()->Alloc<char>(errlen);
  OS::SNPrint(msg, errlen, "%s", errmsg);
  return msg;
}


void SetupErrorResult(Isolate* isolate, Dart_Handle* handle) {
  *handle = Api::NewHandle(
      isolate, Isolate::Current()->object_store()->sticky_error());
}


Dart_Handle Api::NewHandle(Isolate* isolate, RawObject* raw) {
  LocalHandles* local_handles = Api::TopScope(isolate)->local_handles();
  ASSERT(local_handles != NULL);
  LocalHandle* ref = local_handles->AllocateHandle();
  ref->set_raw(raw);
  return reinterpret_cast<Dart_Handle>(ref);
}

RawObject* Api::UnwrapHandle(Dart_Handle object) {
#if defined(DEBUG)
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ASSERT(state->IsValidLocalHandle(object) ||
         state->IsValidPersistentHandle(object) ||
         state->IsValidWeakPersistentHandle(object) ||
         state->IsValidPrologueWeakPersistentHandle(object));
  ASSERT(FinalizablePersistentHandle::raw_offset() == 0 &&
         PersistentHandle::raw_offset() == 0 &&
         LocalHandle::raw_offset() == 0);
#endif
  return *(reinterpret_cast<RawObject**>(object));
}

#define DEFINE_UNWRAP(type)                                                    \
  const type& Api::Unwrap##type##Handle(Isolate* iso,                          \
                                        Dart_Handle dart_handle) {             \
    const Object& obj = Object::Handle(iso, Api::UnwrapHandle(dart_handle));   \
    if (obj.Is##type()) {                                                      \
      return type::Cast(obj);                                                  \
    }                                                                          \
    return type::Handle(iso);                                                  \
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

  char* buffer = zone.Alloc<char>(len + 1);
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


ApiLocalScope* Api::TopScope(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  ASSERT(scope != NULL);
  return scope;
}


void Api::InitOnce() {
  ASSERT(api_native_key_ == Thread::kUnsetThreadLocalKey);
  api_native_key_ = Thread::CreateThreadLocal();
  ASSERT(api_native_key_ != Thread::kUnsetThreadLocalKey);
}


// --- Handles ---


DART_EXPORT bool Dart_IsError(Dart_Handle handle) {
  return RawObject::IsErrorClassId(Api::ClassId(handle));
}


DART_EXPORT bool Dart_IsApiError(Dart_Handle object) {
  return Api::ClassId(object) == kApiErrorCid;
}


DART_EXPORT bool Dart_IsUnhandledExceptionError(Dart_Handle object) {
  return Api::ClassId(object) == kUnhandledExceptionCid;
}


DART_EXPORT bool Dart_IsCompilationError(Dart_Handle object) {
  return Api::ClassId(object) == kLanguageErrorCid;
}


DART_EXPORT bool Dart_IsFatalError(Dart_Handle object) {
  return Api::ClassId(object) == kUnwindErrorCid;
}


DART_EXPORT const char* Dart_GetError(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  if (obj.IsError()) {
    const Error& error = Error::Cast(obj);
    const char* str = error.ToErrorCString();
    intptr_t len = strlen(str) + 1;
    char* str_copy = Api::TopScope(isolate)->zone()->Alloc<char>(len);
    strncpy(str_copy, str, len);
    // Strip a possible trailing '\n'.
    if ((len > 1) && (str_copy[len - 2] == '\n')) {
      str_copy[len - 2] = '\0';
    }
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
    const UnhandledException& error = UnhandledException::Cast(obj);
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
    const UnhandledException& error = UnhandledException::Cast(obj);
    return Api::NewHandle(isolate, error.stacktrace());
  } else if (obj.IsError()) {
    return Api::NewError("This error is not an unhandled exception error.");
  } else {
    return Api::NewError("Can only get stacktraces from error handles.");
  }
}


// Deprecated.
// TODO(turnidge): Remove all uses and delete.
DART_EXPORT Dart_Handle Dart_Error(const char* format, ...) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);

  char* buffer = zone.Alloc<char>(len + 1);
  va_list args2;
  va_start(args2, format);
  OS::VSNPrint(buffer, (len + 1), format, args2);
  va_end(args2);

  const String& message = String::Handle(isolate, String::New(buffer));
  return Api::NewHandle(isolate, ApiError::New(message));
}


// TODO(turnidge): This clones Api::NewError.  I need to use va_copy to
// fix this but not sure if it available on all of our builds.
DART_EXPORT Dart_Handle Dart_NewApiError(const char* format, ...) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);

  char* buffer = zone.Alloc<char>(len + 1);
  va_list args2;
  va_start(args2, format);
  OS::VSNPrint(buffer, (len + 1), format, args2);
  va_end(args2);

  const String& message = String::Handle(isolate, String::New(buffer));
  return Api::NewHandle(isolate, ApiError::New(message));
}


DART_EXPORT Dart_Handle Dart_NewUnhandledExceptionError(Dart_Handle exception) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Instance& obj = Api::UnwrapInstanceHandle(isolate, exception);
  if (obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, exception, Instance);
  }
  const Instance& stacktrace = Instance::Handle(isolate);
  return Api::NewHandle(isolate, UnhandledException::New(obj, stacktrace));
}


DART_EXPORT Dart_Handle Dart_PropagateError(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  if (!obj.IsError()) {
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
  Exceptions::PropagateError(Error::Cast(obj));
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
    const Instance& receiver = Instance::Cast(obj);
    return Api::NewHandle(isolate, DartLibraryCalls::ToString(receiver));
  } else {
    // This is a VM internal object. Call the C++ method of printing.
    return Api::NewHandle(isolate, String::New(obj.ToCString()));
  }
}


DART_EXPORT bool Dart_IdentityEquals(Dart_Handle obj1, Dart_Handle obj2) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoGCScope ngc;
  return Api::UnwrapHandle(obj1) == Api::UnwrapHandle(obj2);
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
    RETURN_NULL_ERROR(keys);
  }
  if (num_keys <= 0) {
    return Api::NewError(
        "%s expects argument 'num_keys' to be greater than 0.",
        CURRENT_FUNC);
  }
  if (values == NULL) {
    RETURN_NULL_ERROR(values);
  }
  if (num_values <= 0) {
    return Api::NewError(
        "%s expects argument 'num_values' to be greater than 0.",
        CURRENT_FUNC);
  }

  WeakReferenceSet* reference_set = new WeakReferenceSet(keys, num_keys,
                                                         values, num_values);
  state->DelayWeakReferenceSet(reference_set);
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


DART_EXPORT Dart_Handle Dart_HeapProfile(Dart_HeapProfileWriteCallback callback,
                                         void* stream) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (callback == NULL) {
    RETURN_NULL_ERROR(callback);
  }
  isolate->heap()->Profile(callback, stream);
  return Api::Success(isolate);
}

// --- Initialization and Globals ---


DART_EXPORT bool Dart_Initialize(Dart_IsolateCreateCallback create,
                                 Dart_IsolateInterruptCallback interrupt,
                                 Dart_IsolateShutdownCallback shutdown) {
  return Dart::InitOnce(create, interrupt, shutdown);
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


static char* BuildIsolateName(const char* script_uri,
                              const char* main) {
  if (script_uri == NULL) {
    // Just use the main as the name.
    if (main == NULL) {
      return strdup("isolate");
    } else {
      return strdup(main);
    }
  }

  // Skip past any slashes and backslashes in the script uri.
  const char* last_slash = strrchr(script_uri, '/');
  if (last_slash != NULL) {
    script_uri = last_slash + 1;
  }
  const char* last_backslash = strrchr(script_uri, '\\');
  if (last_backslash != NULL) {
    script_uri = last_backslash + 1;
  }
  if (main == NULL) {
    main = "main";
  }

  char* chars = NULL;
  intptr_t len = OS::SNPrint(NULL, 0, "%s/%s", script_uri, main) + 1;
  chars = reinterpret_cast<char*>(malloc(len));
  OS::SNPrint(chars, len, "%s/%s", script_uri, main);
  return chars;
}


DART_EXPORT Dart_Isolate Dart_CreateIsolate(const char* script_uri,
                                            const char* main,
                                            const uint8_t* snapshot,
                                            void* callback_data,
                                            char** error) {
  char* isolate_name = BuildIsolateName(script_uri, main);
  Isolate* isolate = Dart::CreateIsolate(isolate_name);
  free(isolate_name);
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


DART_EXPORT void* Dart_CurrentIsolateData() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  return isolate->init_callback_data();
}


DART_EXPORT Dart_Handle Dart_DebugName() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  return Api::NewHandle(isolate, String::New(isolate->name()));
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
  return Api::TopScope(Isolate::Current())->zone()->Realloc<uint8_t>(
      ptr, old_size, new_size);
}


DART_EXPORT Dart_Handle Dart_CreateSnapshot(uint8_t** buffer,
                                            intptr_t* size) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  TIMERSCOPE(time_creating_snapshot);
  if (buffer == NULL) {
    RETURN_NULL_ERROR(buffer);
  }
  if (size == NULL) {
    RETURN_NULL_ERROR(size);
  }
  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }
  // Since this is only a snapshot the root library should not be set.
  isolate->object_store()->set_root_library(Library::Handle(isolate));
  FullSnapshotWriter writer(buffer, ApiReallocate);
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
    RETURN_NULL_ERROR(buffer);
  }
  if (size == NULL) {
    RETURN_NULL_ERROR(size);
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
  if (FLAG_print_class_table) {
    isolate->class_table()->Print();
  }
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
      port_id, Message::kIllegalPort, buffer, writer.BytesWritten(),
      Message::kNormalPriority));
}


DART_EXPORT bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message) {
  uint8_t* buffer = NULL;
  ApiMessageWriter writer(&buffer, allocator);
  writer.WriteCMessage(message);

  // Post the message at the given port.
  return PortMap::PostMessage(new Message(
      port_id, Message::kIllegalPort, buffer, writer.BytesWritten(),
      Message::kNormalPriority));
}


DART_EXPORT bool Dart_Post(Dart_Port port_id, Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  DARTSCOPE_NOCHECKS(isolate);
  const Object& object = Object::Handle(isolate, Api::UnwrapHandle(handle));
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(object);
  intptr_t len = writer.BytesWritten();
  return PortMap::PostMessage(new Message(
      port_id, Message::kIllegalPort, data, len, Message::kNormalPriority));
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
    return ILLEGAL_PORT;
  }
  // Start the native port without a current isolate.
  IsolateSaver saver(Isolate::Current());
  Isolate::SetCurrent(NULL);

  NativeMessageHandler* nmh = new NativeMessageHandler(name, handler);
  Dart_Port port_id = PortMap::CreatePort(nmh);
  nmh->Run(Dart::thread_pool(), NULL, NULL, 0);
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
      String::Handle(isolate, Symbols::New("_get_or_create"));
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
  return reinterpret_cast<uint8_t*>(zone->AllocUnsafe(size));
}


// --- Objects ----


DART_EXPORT Dart_Handle Dart_Null() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE_SCOPE(isolate);
  return Api::Null(isolate);
}


DART_EXPORT bool Dart_IsNull(Dart_Handle object) {
  return Api::ClassId(object) == kNullCid;
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
    *value = Bool::Cast(result).value();
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

  const Class& cls = Api::UnwrapClassHandle(isolate, clazz);
  if (cls.IsNull()) {
    RETURN_TYPE_ERROR(isolate, clazz, Class);
  }
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  if (obj.IsError()) {
    return object;
  } else if (!obj.IsNull() && !obj.IsInstance()) {
    return Api::NewError(
        "%s expects argument 'object' to be an instance of Object.",
        CURRENT_FUNC);
  }
  // Finalize all classes.
  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }
  if (obj.IsInstance()) {
    const Type& type = Type::Handle(isolate,
                                    Type::NewNonParameterizedType(cls));
    Error& malformed_type_error = Error::Handle(isolate);
    *value = Instance::Cast(obj).IsInstanceOf(type,
                                              TypeArguments::Handle(isolate),
                                              &malformed_type_error);
    ASSERT(malformed_type_error.IsNull());  // Type was created from a class.
  } else {
    *value = false;
  }
  return Api::Success(isolate);
}


// --- Instances ----


DART_EXPORT bool Dart_IsInstance(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsInstance();
}


// TODO(turnidge): Technically, null has a class.  Should we allow it?
DART_EXPORT Dart_Handle Dart_InstanceGetClass(Dart_Handle instance) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Instance& obj = Api::UnwrapInstanceHandle(isolate, instance);
  if (obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, instance, Instance);
  }
  return Api::NewHandle(isolate, obj.clazz());
}


// --- Numbers ----


DART_EXPORT bool Dart_IsNumber(Dart_Handle object) {
  return RawObject::IsNumberClassId(Api::ClassId(object));
}


// --- Integers ----


DART_EXPORT bool Dart_IsInteger(Dart_Handle object) {
  return RawObject::IsIntegerClassId(Api::ClassId(object));
}


DART_EXPORT Dart_Handle Dart_IntegerFitsIntoInt64(Dart_Handle integer,
                                                  bool* fits) {
  // Fast path for Smis and Mints.
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  intptr_t class_id = Api::ClassId(integer);
  if (class_id == kSmiCid || class_id == kMintCid) {
    *fits = true;
    return Api::Success(isolate);
  }

  DARTSCOPE_NOCHECKS(isolate);
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  ASSERT(!BigintOperations::FitsIntoMint(Bigint::Cast(int_obj)));
  *fits = false;
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
    *fits = BigintOperations::FitsIntoUint64(Bigint::Cast(int_obj));
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
    const Bigint& bigint = Bigint::Cast(int_obj);
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
    const Bigint& bigint = Bigint::Cast(int_obj);
    if (BigintOperations::FitsIntoUint64(bigint)) {
      *value = BigintOperations::ToUint64(bigint);
      return Api::Success(isolate);
    }
  }
  return Api::NewError("%s: Integer %s cannot be represented as a uint64_t.",
                       CURRENT_FUNC, int_obj.ToCString());
}


static uword BigintAllocate(intptr_t size) {
  return Api::TopScope(Isolate::Current())->zone()->AllocUnsafe(size);
}


DART_EXPORT Dart_Handle Dart_IntegerToHexCString(Dart_Handle integer,
                                                 const char** value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  if (int_obj.IsSmi() || int_obj.IsMint()) {
    const Bigint& bigint = Bigint::Handle(isolate,
        BigintOperations::NewFromInt64(int_obj.AsInt64Value()));
    *value = BigintOperations::ToHexCString(bigint, BigintAllocate);
  } else {
    *value = BigintOperations::ToHexCString(Bigint::Cast(int_obj),
                                            BigintAllocate);
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
  return Api::ClassId(object) == kBoolCid;
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
  return Api::ClassId(object) == kDoubleCid;
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
  return RawObject::IsStringClassId(Api::ClassId(object));
}


DART_EXPORT bool Dart_IsString8(Dart_Handle object) {
  return RawObject::IsOneByteStringClassId(Api::ClassId(object));
}


DART_EXPORT bool Dart_IsString16(Dart_Handle object) {
  return RawObject::IsTwoByteStringClassId(Api::ClassId(object));
}


DART_EXPORT Dart_Handle Dart_StringLength(Dart_Handle str, intptr_t* len) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& str_obj = Api::UnwrapStringHandle(isolate, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, str, String);
  }
  *len = str_obj.Length();
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_NewString(const char* str) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (str == NULL) {
    RETURN_NULL_ERROR(str);
  }
  if (!Utf8::IsValid(str)) {
    return Api::NewError("%s expects argument 'str' to be valid UTF-8.",
                         CURRENT_FUNC);
  }
  return Api::NewHandle(isolate, String::New(str));
}


DART_EXPORT Dart_Handle Dart_NewString8(const uint8_t* codepoints,
                                        intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (codepoints == NULL && length != 0) {
    RETURN_NULL_ERROR(codepoints);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  return Api::NewHandle(isolate, String::New(codepoints, length));
}


DART_EXPORT Dart_Handle Dart_NewString16(const uint16_t* codepoints,
                                         intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (codepoints == NULL && length != 0) {
    RETURN_NULL_ERROR(codepoints);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  return Api::NewHandle(isolate, String::New(codepoints, length));
}


DART_EXPORT Dart_Handle Dart_NewString32(const uint32_t* codepoints,
                                         intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (codepoints == NULL && length != 0) {
    RETURN_NULL_ERROR(codepoints);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  return Api::NewHandle(isolate, String::New(codepoints, length));
}


DART_EXPORT bool Dart_IsExternalString(Dart_Handle object) {
  return RawObject::IsExternalStringClassId(Api::ClassId(object));
}

DART_EXPORT Dart_Handle Dart_ExternalStringGetPeer(Dart_Handle object,
                                                   void** peer) {
  if (peer == NULL) {
    RETURN_NULL_ERROR(peer);
  }
//  NoGCScope no_gc_scope;
  if (Dart_IsExternalString(object)) {
    Isolate* isolate = Isolate::Current();
    intptr_t class_id = Api::ClassId(object);
    void* raw_peer ;
    switch (class_id) {
      case kExternalOneByteStringCid: {
        asm("");
        RawExternalOneByteString* raw_string =
            (*(reinterpret_cast<RawExternalOneByteString**>(object)))->ptr();
        ExternalStringData<uint8_t>* data = raw_string->external_data_;
        raw_peer = data != NULL ? data->peer() : NULL;
        break;
      }
      case kExternalTwoByteStringCid: {
        RawExternalTwoByteString* raw_string =
            (*(reinterpret_cast<RawExternalTwoByteString**>(object)))->ptr();
        ExternalStringData<uint16_t>* data = raw_string->external_data_;
        raw_peer = data != NULL ? data->peer() : NULL;
        break;
      }
      default: {
        RawExternalFourByteString* raw_string =
            (*(reinterpret_cast<RawExternalFourByteString**>(object)))->ptr();
        ExternalStringData<uint32_t>* data = raw_string->external_data_;
        raw_peer = data != NULL ? data->peer() : NULL;
        break;
      }
    }
    if (raw_peer != NULL) {
      *peer = raw_peer;
      return Api::Success(isolate);
    } else {
      RETURN_TYPE_ERROR(isolate, object, String);
    }
  }
  const char* error_msg = Dart_IsString(object) ?
      "%s expects argument 'object' to be an external String." :
      "%s expects argument 'object' to be of type String.";
  return Api::NewError(error_msg, CURRENT_FUNC);
}


DART_EXPORT Dart_Handle Dart_NewExternalString8(const uint8_t* codepoints,
                                                intptr_t length,
                                                void* peer,
                                                Dart_PeerFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (codepoints == NULL && length != 0) {
    RETURN_NULL_ERROR(codepoints);
  }
  CHECK_LENGTH(length, String::kMaxElements);
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
    RETURN_NULL_ERROR(codepoints);
  }
  CHECK_LENGTH(length, String::kMaxElements);
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
    RETURN_NULL_ERROR(codepoints);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  return Api::NewHandle(
      isolate, String::NewExternal(codepoints, length, peer, callback));
}


DART_EXPORT Dart_Handle Dart_StringGet8(Dart_Handle str,
                                        uint8_t* codepoints,
                                        intptr_t* length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const OneByteString& str_obj = Api::UnwrapOneByteStringHandle(isolate, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, str, String8);
  }
  intptr_t str_len = str_obj.Length();
  intptr_t copy_len = (str_len > *length) ? *length : str_len;
  for (intptr_t i = 0; i < copy_len; i++) {
    codepoints[i] = static_cast<uint8_t>(str_obj.CharAt(i));
  }
  *length= copy_len;
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_StringGet16(Dart_Handle str,
                                         uint16_t* codepoints,
                                         intptr_t* length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& str_obj = Api::UnwrapStringHandle(isolate, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, str, String);
  }
  if (str_obj.CharSize() > String::kTwoByteChar) {
    return Api::NewError("Object is not a String16 or String8");
  }
  intptr_t str_len = str_obj.Length();
  intptr_t copy_len = (str_len > *length) ? *length : str_len;
  for (intptr_t i = 0; i < copy_len; i++) {
    codepoints[i] = static_cast<uint16_t>(str_obj.CharAt(i));
  }
  *length = copy_len;
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_StringGet32(Dart_Handle str,
                                         uint32_t* codepoints,
                                         intptr_t* length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& str_obj = Api::UnwrapStringHandle(isolate, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, str, String);
  }
  intptr_t str_len = str_obj.Length();
  intptr_t copy_len = (str_len > *length) ? *length : str_len;
  for (intptr_t i = 0; i < copy_len; i++) {
    codepoints[i] = static_cast<uint32_t>(str_obj.CharAt(i));
  }
  *length = copy_len;
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_StringToCString(Dart_Handle object,
                                             const char** result) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& str_obj = Api::UnwrapStringHandle(isolate, object);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, object, String);
  }
  intptr_t string_length = Utf8::Length(str_obj);
  char* res = Api::TopScope(isolate)->zone()->Alloc<char>(string_length + 1);
  if (res == NULL) {
    return Api::NewError("Unable to allocate memory");
  }
  const char* string_value = str_obj.ToCString();
  memmove(res, string_value, string_length + 1);
  ASSERT(res[string_length] == '\0');
  *result = res;
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_StringToBytes(Dart_Handle object,
                                           const uint8_t** bytes,
                                           intptr_t *length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& str = Api::UnwrapStringHandle(isolate, object);
  if (str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, object, String);
  }
  if (bytes == NULL) {
    RETURN_NULL_ERROR(bytes);
  }
  if (length == NULL) {
    RETURN_NULL_ERROR(length);
  }
  const char* cstring = str.ToCString();
  *length = Utf8::Length(str);
  uint8_t* result = Api::TopScope(isolate)->zone()->Alloc<uint8_t>(*length);
  if (result == NULL) {
    return Api::NewError("Unable to allocate memory");
  }
  memmove(result, cstring, *length);
  *bytes = result;
  return Api::Success(isolate);
}


// --- Lists ---


static RawInstance* GetListInstance(Isolate* isolate, const Object& obj) {
  if (obj.IsInstance()) {
    const Instance& instance = Instance::Cast(obj);
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
  if (RawObject::IsBuiltinListClassId(Api::ClassId(object))) {
    return true;
  }

  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return GetListInstance(isolate, obj) != Instance::null();
}


DART_EXPORT Dart_Handle Dart_NewList(intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_LENGTH(length, Array::kMaxElements);
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
  if (obj.IsError()) {
    // Pass through errors.
    return list;
  }
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
    return Api::NewError("Object does not implement the List interface");
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
    *len = Integer::Cast(retval).AsInt64Value();
    return Api::Success(isolate);
  } else if (retval.IsBigint()) {
    const Bigint& bigint = Bigint::Cast(retval);
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
  const type& array_obj = type::Cast(obj);                                     \
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
  } else if (obj.IsGrowableObjectArray()) {
    GET_LIST_ELEMENT(isolate, GrowableObjectArray, obj, index);
  } else if (obj.IsError()) {
    return list;
  } else {
    // Check and handle a dart object that implements the List interface.
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
        return Api::NewHandle(isolate, DartEntry::InvokeDynamic(
            instance, function, args, kNoArgumentNames));
      }
    }
    return Api::NewError("Object does not implement the 'List' interface");
  }
}


#define SET_LIST_ELEMENT(isolate, type, obj, index, value)                     \
  const type& array = type::Cast(obj);                                         \
  const Object& value_obj = Object::Handle(isolate, Api::UnwrapHandle(value)); \
  if (!value_obj.IsNull() && !value_obj.IsInstance()) {                        \
    RETURN_TYPE_ERROR(isolate, value, Instance);                               \
  }                                                                            \
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
  } else if (obj.IsGrowableObjectArray()) {
    SET_LIST_ELEMENT(isolate, GrowableObjectArray, obj, index, value);
  } else if (obj.IsError()) {
    return list;
  } else {
    // Check and handle a dart object that implements the List interface.
    const Instance& instance =
        Instance::Handle(isolate, GetListInstance(isolate, obj));
    if (!instance.IsNull()) {
      String& name = String::Handle(isolate, String::New("[]="));
      const Function& function =
          Function::Handle(isolate,
                           Resolver::ResolveDynamic(instance, name, 3, 0));
      if (!function.IsNull()) {
        const Integer& index_obj =
            Integer::Handle(isolate, Integer::New(index));
        const Object& value_obj =
            Object::Handle(isolate, Api::UnwrapHandle(value));
        if (!value_obj.IsNull() && !value_obj.IsInstance()) {
          RETURN_TYPE_ERROR(isolate, value, Instance);
        }
        GrowableArray<const Object*> args(2);
        args.Add(&index_obj);
        args.Add(&value_obj);
        const Array& kNoArgumentNames = Array::Handle(isolate);
        return Api::NewHandle(isolate, DartEntry::InvokeDynamic(
            instance, function, args, kNoArgumentNames));
      }
    }
    return Api::NewError("Object does not implement the 'List' interface");
  }
}


// TODO(hpayer): value should always be smaller then 0xff. Add error handling.
#define GET_LIST_ELEMENT_AS_BYTES(isolate, type, obj, native_array, offset,    \
                                   length)                                     \
  const type& array = type::Cast(obj);                                         \
  if (Utils::RangeCheck(offset, length, array.Length())) {                     \
    Object& element = Object::Handle(isolate);                                 \
    for (int i = 0; i < length; i++) {                                         \
      element = array.At(offset + i);                                          \
      if (!element.IsInteger()) {                                              \
        return Api::NewError("%s expects the argument 'list' to be "           \
                             "a List of int", CURRENT_FUNC);                   \
      }                                                                        \
      const Integer& integer = Integer::Cast(element);                         \
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
  if (obj.IsUint8Array() || obj.IsExternalUint8Array()) {
    const ByteArray& byte_array = ByteArray::Cast(obj);
    if (Utils::RangeCheck(offset, length, byte_array.Length())) {
      ByteArray::Copy(native_array, byte_array, offset, length);
      return Api::Success(isolate);
    }
    return Api::NewError("Invalid length passed in to access list elements");
  } else if (obj.IsArray()) {
    GET_LIST_ELEMENT_AS_BYTES(isolate,
                              Array,
                              obj,
                              native_array,
                              offset,
                              length);
  } else if (obj.IsGrowableObjectArray()) {
    GET_LIST_ELEMENT_AS_BYTES(isolate,
                              GrowableObjectArray,
                              obj,
                              native_array,
                              offset,
                              length);
  } else if (obj.IsError()) {
    return list;
  } else {
    // Check and handle a dart object that implements the List interface.
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
          const Integer& integer_result = Integer::Cast(result);
          ASSERT(integer_result.AsInt64Value() <= 0xff);
          // TODO(hpayer): value should always be smaller then 0xff. Add error
          // handling.
          native_array[i] =
              static_cast<uint8_t>(integer_result.AsInt64Value() & 0xff);
        }
        return Api::Success(isolate);
      }
    }
    return Api::NewError("Object does not implement the 'List' interface");
  }
}


#define SET_LIST_ELEMENT_AS_BYTES(isolate, type, obj, native_array, offset,    \
                                  length)                                      \
  const type& array = type::Cast(obj);                                         \
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
  if (obj.IsUint8Array() || obj.IsExternalUint8Array()) {
    const ByteArray& byte_array = ByteArray::Cast(obj);
    if (Utils::RangeCheck(offset, length, byte_array.Length())) {
      ByteArray::Copy(byte_array, offset, native_array, length);
      return Api::Success(isolate);
    }
    return Api::NewError("Invalid length passed in to set list elements");
  } else if (obj.IsArray()) {
    if (obj.IsImmutableArray()) {
      return Api::NewError("Cannot modify immutable array");
    }
    SET_LIST_ELEMENT_AS_BYTES(isolate,
                              Array,
                              obj,
                              native_array,
                              offset,
                              length);
  } else if (obj.IsGrowableObjectArray()) {
    SET_LIST_ELEMENT_AS_BYTES(isolate,
                              GrowableObjectArray,
                              obj,
                              native_array,
                              offset,
                              length);
  } else if (obj.IsError()) {
    return list;
  } else {
  // Check and handle a dart object that implements the List interface.
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
}


// --- Byte Arrays ---


DART_EXPORT bool Dart_IsByteArray(Dart_Handle object) {
  return RawObject::IsByteArrayClassId(Api::ClassId(object));
}


DART_EXPORT Dart_Handle Dart_NewByteArray(intptr_t length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_LENGTH(length, Uint8Array::kMaxElements);
  return Api::NewHandle(isolate, Uint8Array::New(length));
}


DART_EXPORT Dart_Handle Dart_NewExternalByteArray(uint8_t* data,
                                                  intptr_t length,
                                                  void* peer,
                                                  Dart_PeerFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (data == NULL && length != 0) {
    RETURN_NULL_ERROR(data);
  }
  CHECK_LENGTH(length, ExternalUint8Array::kMaxElements);
  return Api::NewHandle(
      isolate, ExternalUint8Array::New(data, length, peer, callback));
}


DART_EXPORT Dart_Handle Dart_ExternalByteArrayGetPeer(Dart_Handle object,
                                                      void** peer) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const ExternalUint8Array& array =
      Api::UnwrapExternalUint8ArrayHandle(isolate, object);
  if (array.IsNull()) {
    RETURN_TYPE_ERROR(isolate, object, ExternalUint8Array);
  }
  if (peer == NULL) {
    RETURN_NULL_ERROR(peer);
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
  if (!Utils::RangeCheck(offset, length, array_obj.ByteLength())) {
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
  if (!Utils::RangeCheck(offset, length, array_obj.ByteLength())) {
    return Api::NewError("Invalid index passed in to get byte array element");
  }
  const uint8_t* src = reinterpret_cast<uint8_t*>(&value);
  ByteArray::Copy(array_obj, offset, src, length);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetInt8At(Dart_Handle array,
                                                intptr_t byte_offset,
                                                int8_t* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetInt8At(Dart_Handle array,
                                                intptr_t byte_offset,
                                                int8_t value) {
  return ByteArraySetAt(array, byte_offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetUint8At(Dart_Handle array,
                                                 intptr_t byte_offset,
                                                 uint8_t* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetUint8At(Dart_Handle array,
                                                 intptr_t byte_offset,
                                                 uint8_t value) {
  return ByteArraySetAt(array, byte_offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetInt16At(Dart_Handle array,
                                                 intptr_t byte_offset,
                                                 int16_t* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetInt16At(Dart_Handle array,
                                                 intptr_t byte_offset,
                                                 int16_t value) {
  return ByteArraySetAt(array, byte_offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetUint16At(Dart_Handle array,
                                                  intptr_t byte_offset,
                                                  uint16_t* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetUint16At(Dart_Handle array,
                                                  intptr_t byte_offset,
                                                  uint16_t value) {
  return ByteArraySetAt(array, byte_offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetInt32At(Dart_Handle array,
                                                 intptr_t byte_offset,
                                                 int32_t* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetInt32At(Dart_Handle array,
                                                 intptr_t byte_offset,
                                                 int32_t value) {
  return ByteArraySetAt(array, byte_offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetUint32At(Dart_Handle array,
                                                  intptr_t byte_offset,
                                                  uint32_t* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetUint32At(Dart_Handle array,
                                                  intptr_t byte_offset,
                                                  uint32_t value) {
  return ByteArraySetAt(array, byte_offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetInt64At(Dart_Handle array,
                                                 intptr_t byte_offset,
                                                 int64_t* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetInt64At(Dart_Handle array,
                                                 intptr_t byte_offset,
                                                 int64_t value) {
  return ByteArraySetAt(array, byte_offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetUint64At(Dart_Handle array,
                                                  intptr_t byte_offset,
                                                  uint64_t* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetUint64At(Dart_Handle array,
                                                  intptr_t byte_offset,
                                                  uint64_t value) {
  return ByteArraySetAt(array, byte_offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetFloat32At(Dart_Handle array,
                                                   intptr_t byte_offset,
                                                   float* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetFloat32At(Dart_Handle array,
                                                   intptr_t byte_offset,
                                                   float value) {
  return ByteArraySetAt(array, byte_offset, value);
}


DART_EXPORT Dart_Handle Dart_ByteArrayGetFloat64At(Dart_Handle array,
                                                   intptr_t byte_offset,
                                                   double* value) {
  return ByteArrayGetAt(value, array, byte_offset);
}


DART_EXPORT Dart_Handle Dart_ByteArraySetFloat64At(Dart_Handle array,
                                                   intptr_t byte_offset,
                                                   double value) {
  return ByteArraySetAt(array, byte_offset, value);
}


// --- Closures ---


DART_EXPORT bool Dart_IsClosure(Dart_Handle object) {
  // We can't use a fast class index check here because there are many
  // different signature classes for closures.
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(object));
  return obj.IsClosure();
}


DART_EXPORT Dart_Handle Dart_ClosureFunction(Dart_Handle closure) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Closure& closure_obj = Api::UnwrapClosureHandle(isolate, closure);
  if (closure_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, closure, Closure);
  }
  ASSERT(ClassFinalizer::AllClassesFinalized());

  RawFunction* rf = closure_obj.function();
  return Api::NewHandle(isolate, rf);
}


DART_EXPORT Dart_Handle Dart_InvokeClosure(Dart_Handle closure,
                                           int number_of_arguments,
                                           Dart_Handle* arguments) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Closure& closure_obj = Api::UnwrapClosureHandle(isolate, closure);
  if (closure_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, closure, Closure);
  }
  if (number_of_arguments < 0) {
    return Api::NewError(
        "%s expects argument 'number_of_arguments' to be non-negative.",
        CURRENT_FUNC);
  }
  ASSERT(ClassFinalizer::AllClassesFinalized());

  // Now try to invoke the closure.
  GrowableArray<const Object*> dart_arguments(number_of_arguments);
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg =
        Object::Handle(isolate, Api::UnwrapHandle(arguments[i]));
    if (!arg.IsNull() && !arg.IsInstance()) {
      RETURN_TYPE_ERROR(isolate, arguments[i], Instance);
    }
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


// --- Classes and Interfaces ---


DART_EXPORT bool Dart_IsClass(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  if (obj.IsClass()) {
    return !Class::Cast(obj).is_interface();
  }
  return false;
}


DART_EXPORT bool Dart_IsInterface(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  if (obj.IsClass()) {
    return Class::Cast(obj).is_interface();
  }
  return false;
}


DART_EXPORT Dart_Handle Dart_ClassName(Dart_Handle clazz) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Class& cls = Api::UnwrapClassHandle(isolate, clazz);
  if (cls.IsNull()) {
    RETURN_TYPE_ERROR(isolate, clazz, Class);
  }
  return Api::NewHandle(isolate, cls.UserVisibleName());
}


DART_EXPORT Dart_Handle Dart_ClassGetLibrary(Dart_Handle clazz) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Class& cls = Api::UnwrapClassHandle(isolate, clazz);
  if (cls.IsNull()) {
    RETURN_TYPE_ERROR(isolate, clazz, Class);
  }

#if defined(DEBUG)
  const Library& lib = Library::Handle(cls.library());
  if (lib.IsNull()) {
    ASSERT(cls.IsDynamicClass() || cls.IsVoidClass());
  }
#endif

  return Api::NewHandle(isolate, cls.library());
}


DART_EXPORT Dart_Handle Dart_ClassGetDefault(Dart_Handle clazz) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Class& cls = Api::UnwrapClassHandle(isolate, clazz);
  if (cls.IsNull()) {
    RETURN_TYPE_ERROR(isolate, clazz, Class);
  }

  // Finalize all classes.
  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }

  if (cls.HasFactoryClass() && cls.HasResolvedFactoryClass()) {
    return Api::NewHandle(isolate, cls.FactoryClass());
  }
  return Api::Null(isolate);
}


DART_EXPORT Dart_Handle Dart_ClassGetInterfaceCount(Dart_Handle clazz,
                                                    intptr_t* count) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Class& cls = Api::UnwrapClassHandle(isolate, clazz);
  if (cls.IsNull()) {
    RETURN_TYPE_ERROR(isolate, clazz, Class);
  }

  const Array& interface_types = Array::Handle(isolate, cls.interfaces());
  if (interface_types.IsNull()) {
    *count = 0;
  } else {
    *count = interface_types.Length();
  }
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_ClassGetInterfaceAt(Dart_Handle clazz,
                                                 intptr_t index) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Class& cls = Api::UnwrapClassHandle(isolate, clazz);
  if (cls.IsNull()) {
    RETURN_TYPE_ERROR(isolate, clazz, Class);
  }

  // Finalize all classes.
  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }

  const Array& interface_types = Array::Handle(isolate, cls.interfaces());
  if (index < 0 || index >= interface_types.Length()) {
    return Api::NewError("%s: argument 'index' out of bounds.", CURRENT_FUNC);
  }
  Type& interface_type = Type::Handle(isolate);
  interface_type ^= interface_types.At(index);
  if (interface_type.HasResolvedTypeClass()) {
    return Api::NewHandle(isolate, interface_type.type_class());
  }
  const String& type_name =
      String::Handle(isolate, interface_type.TypeClassName());
  return Api::NewError("%s: internal error: found unresolved type class '%s'.",
                       CURRENT_FUNC, type_name.ToCString());
}


// --- Function and Variable Reflection ---


// Outside of the vm, we expose setter names with a trailing '='.
static bool HasExternalSetterSuffix(const String& name) {
  return name.CharAt(name.Length() - 1) == '=';
}


static RawString* RemoveExternalSetterSuffix(const String& name) {
  ASSERT(HasExternalSetterSuffix(name));
  return String::SubString(name, 0, name.Length() - 1);
}


DART_EXPORT Dart_Handle Dart_GetFunctionNames(Dart_Handle target) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }

  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New());
  Function& func = Function::Handle();
  String& name = String::Handle();

  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    const Array& func_array = Array::Handle(cls.functions());

    // Some special types like 'Dynamic' have a null functions list.
    if (!func_array.IsNull()) {
      for (intptr_t i = 0; i < func_array.Length(); ++i) {
        func ^= func_array.At(i);

        // Skip implicit getters and setters.
        if (func.kind() == RawFunction::kImplicitGetter ||
            func.kind() == RawFunction::kImplicitSetter ||
            func.kind() == RawFunction::kConstImplicitGetter) {
          continue;
        }

        name = func.UserVisibleName();
        names.Add(name);
      }
    }
  } else if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    DictionaryIterator it(lib);
    Object& obj = Object::Handle();
    while (it.HasNext()) {
      obj = it.GetNext();
      if (obj.IsFunction()) {
        func ^= obj.raw();
        name = func.UserVisibleName();
        names.Add(name);
      }
    }
  } else {
    return Api::NewError(
        "%s expects argument 'target' to be a class or library.",
        CURRENT_FUNC);
  }
  return Api::NewHandle(isolate, Array::MakeArray(names));
}


DART_EXPORT Dart_Handle Dart_LookupFunction(Dart_Handle target,
                                            Dart_Handle function_name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }
  const String& func_name = Api::UnwrapStringHandle(isolate, function_name);
  if (func_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function_name, String);
  }

  Function& func = Function::Handle(isolate);
  String& tmp_name = String::Handle(isolate);
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);

    // Case 1.  Lookup the unmodified function name.
    func = cls.LookupFunction(func_name);

    // Case 2.  Lookup the function without the external setter suffix
    // '='.  Make sure to do this check after the regular lookup, so
    // that we don't interfere with operator lookups (like ==).
    if (func.IsNull() && HasExternalSetterSuffix(func_name)) {
      tmp_name = RemoveExternalSetterSuffix(func_name);
      tmp_name = Field::SetterName(tmp_name);
      func = cls.LookupFunction(tmp_name);
    }

    // Case 3.  Lookup the funciton with the getter prefix prepended.
    if (func.IsNull()) {
      tmp_name = Field::GetterName(func_name);
      func = cls.LookupFunction(tmp_name);
    }

    // Case 4.  Lookup the function with a . appended to find the
    // unnamed constructor.
    if (func.IsNull()) {
      const String& dot = String::Handle(Symbols::Dot());
      tmp_name = String::Concat(func_name, dot);
      func = cls.LookupFunction(tmp_name);
    }
  } else if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);

    // Case 1.  Lookup the unmodified function name.
    func = lib.LookupFunctionAllowPrivate(func_name);

    // Case 2.  Lookup the function without the external setter suffix
    // '='.  Make sure to do this check after the regular lookup, so
    // that we don't interfere with operator lookups (like ==).
    if (func.IsNull() && HasExternalSetterSuffix(func_name)) {
      tmp_name = RemoveExternalSetterSuffix(func_name);
      tmp_name = Field::SetterName(tmp_name);
      func = lib.LookupFunctionAllowPrivate(tmp_name);
    }

    // Case 3.  Lookup the funciton with the getter prefix prepended.
    if (func.IsNull()) {
      tmp_name = Field::GetterName(func_name);
      func = lib.LookupFunctionAllowPrivate(tmp_name);
    }
  } else {
    return Api::NewError(
        "%s expects argument 'target' to be a class or library.",
        CURRENT_FUNC);
  }

#if defined(DEBUG)
  if (!func.IsNull()) {
    // We only provide access to a subset of function kinds.
    RawFunction::Kind func_kind = func.kind();
    ASSERT(func_kind == RawFunction::kRegularFunction ||
           func_kind == RawFunction::kGetterFunction ||
           func_kind == RawFunction::kSetterFunction ||
           func_kind == RawFunction::kConstructor);
  }
#endif
  return Api::NewHandle(isolate, func.raw());
}


DART_EXPORT bool Dart_IsFunction(Dart_Handle handle) {
  return Api::ClassId(handle) == kFunctionCid;
}


DART_EXPORT Dart_Handle Dart_FunctionName(Dart_Handle function) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  return Api::NewHandle(isolate, func.UserVisibleName());
}


DART_EXPORT Dart_Handle Dart_FunctionOwner(Dart_Handle function) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  if (func.IsNonImplicitClosureFunction()) {
    RawFunction* parent_function = func.parent_function();
    return Api::NewHandle(isolate, parent_function);
  }
  const Class& owner = Class::Handle(func.Owner());
  ASSERT(!owner.IsNull());
  if (owner.IsTopLevel()) {
    // Top-level functions are implemented as members of a hidden class. We hide
    // that class here and instead answer the library.
#if defined(DEBUG)
    const Library& lib = Library::Handle(owner.library());
    if (lib.IsNull()) {
      ASSERT(owner.IsDynamicClass() || owner.IsVoidClass());
    }
#endif
    return Api::NewHandle(isolate, owner.library());
  } else {
    return Api::NewHandle(isolate, owner.raw());
  }
}


DART_EXPORT Dart_Handle Dart_FunctionIsAbstract(Dart_Handle function,
                                                bool* is_abstract) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_abstract == NULL) {
    RETURN_NULL_ERROR(is_abstract);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_abstract = func.is_abstract();
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_FunctionIsStatic(Dart_Handle function,
                                              bool* is_static) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_static == NULL) {
    RETURN_NULL_ERROR(is_static);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_static = func.is_static();
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_FunctionIsConstructor(Dart_Handle function,
                                                   bool* is_constructor) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_constructor == NULL) {
    RETURN_NULL_ERROR(is_constructor);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_constructor = func.kind() == RawFunction::kConstructor;
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_FunctionIsGetter(Dart_Handle function,
                                              bool* is_getter) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_getter == NULL) {
    RETURN_NULL_ERROR(is_getter);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_getter = func.IsGetterFunction();
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_FunctionIsSetter(Dart_Handle function,
                                              bool* is_setter) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_setter == NULL) {
    RETURN_NULL_ERROR(is_setter);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }
  *is_setter = (func.kind() == RawFunction::kSetterFunction);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_FunctionParameterCounts(
    Dart_Handle function,
    int64_t* fixed_param_count,
    int64_t* opt_param_count) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (fixed_param_count == NULL) {
    RETURN_NULL_ERROR(fixed_param_count);
  }
  if (opt_param_count == NULL) {
    RETURN_NULL_ERROR(opt_param_count);
  }
  const Function& func = Api::UnwrapFunctionHandle(isolate, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(isolate, function, Function);
  }

  // We hide implicit parameters, such as a method's receiver. This is
  // consistent with Invoke or New, which don't expect their callers to
  // provide them in the argument lists they are handed.
  *fixed_param_count = (func.num_fixed_parameters() -
                        func.NumberOfImplicitParameters());
  *opt_param_count = func.num_optional_parameters();

  ASSERT(*fixed_param_count >= 0);
  ASSERT(*opt_param_count >= 0);

  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_GetVariableNames(Dart_Handle target) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }

  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New());
  Field& field = Field::Handle(isolate);
  String& name = String::Handle(isolate);

  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    const Array& field_array = Array::Handle(cls.fields());

    // Some special types like 'Dynamic' have a null fields list.
    //
    // TODO(turnidge): Fix 'Dynamic' so that it does not have a null
    // fields list.  This will have to wait until the empty array is
    // allocated in the vm isolate.
    if (!field_array.IsNull()) {
      for (intptr_t i = 0; i < field_array.Length(); ++i) {
        field ^= field_array.At(i);
        name = field.UserVisibleName();
        names.Add(name);
      }
    }
  } else if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    DictionaryIterator it(lib);
    Object& obj = Object::Handle(isolate);
    while (it.HasNext()) {
      obj = it.GetNext();
      if (obj.IsField()) {
        field ^= obj.raw();
        name = field.UserVisibleName();
        names.Add(name);
      }
    }
  } else {
    return Api::NewError(
        "%s expects argument 'target' to be a class or library.",
        CURRENT_FUNC);
  }
  return Api::NewHandle(isolate, Array::MakeArray(names));
}


DART_EXPORT Dart_Handle Dart_LookupVariable(Dart_Handle target,
                                            Dart_Handle variable_name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }
  const String& var_name = Api::UnwrapStringHandle(isolate, variable_name);
  if (var_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, variable_name, String);
  }
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    return Api::NewHandle(isolate, cls.LookupField(var_name));
  }
  if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    return Api::NewHandle(isolate, lib.LookupFieldAllowPrivate(var_name));
  }
  return Api::NewError(
      "%s expects argument 'target' to be a class or library.",
      CURRENT_FUNC);
}


DART_EXPORT bool Dart_IsVariable(Dart_Handle handle) {
  return Api::ClassId(handle) == kFieldCid;
}


DART_EXPORT Dart_Handle Dart_VariableName(Dart_Handle variable) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Field& var = Api::UnwrapFieldHandle(isolate, variable);
  if (var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, variable, Field);
  }
  return Api::NewHandle(isolate, var.UserVisibleName());
}


DART_EXPORT Dart_Handle Dart_VariableIsStatic(Dart_Handle variable,
                                              bool* is_static) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_static == NULL) {
    RETURN_NULL_ERROR(is_static);
  }
  const Field& var = Api::UnwrapFieldHandle(isolate, variable);
  if (var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, variable, Field);
  }
  *is_static = var.is_static();
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_VariableIsFinal(Dart_Handle variable,
                                             bool* is_final) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (is_final == NULL) {
    RETURN_NULL_ERROR(is_final);
  }
  const Field& var = Api::UnwrapFieldHandle(isolate, variable);
  if (var.IsNull()) {
    RETURN_TYPE_ERROR(isolate, variable, Field);
  }
  *is_final = var.is_final();
  return Api::Success(isolate);
}

// --- Constructors, Methods, and Fields ---


static RawObject* ResolveConstructor(const char* current_func,
                                     const Class& cls,
                                     const String& class_name,
                                     const String& dotted_name,
                                     int num_args) {
  // The constructor must be present in the interface.
  String& constr_name = String::Handle(String::Concat(class_name, dotted_name));
  const Function& constructor =
      Function::Handle(cls.LookupFunction(constr_name));
  if (constructor.IsNull() ||
      (!constructor.IsConstructor() && !constructor.IsFactory())) {
    const String& lookup_class_name = String::Handle(cls.Name());
    if (!class_name.Equals(lookup_class_name)) {
      // When the class name used to build the constructor name is
      // different than the name of the class in which we are doing
      // the lookup, it can be confusing to the user to figure out
      // what's going on.  Be a little more explicit for these error
      // messages.
      const String& message = String::Handle(
          String::NewFormatted(
              "%s: could not find factory '%s' in class '%s'.",
              current_func,
              constr_name.ToCString(),
              lookup_class_name.ToCString()));
      return ApiError::New(message);
    } else {
      const String& message = String::Handle(
          String::NewFormatted("%s: could not find constructor '%s'.",
                               current_func, constr_name.ToCString()));
      return ApiError::New(message);
    }
  }
  int extra_args = (constructor.IsConstructor() ? 2 : 1);
  String& error_message = String::Handle();
  if (!constructor.AreValidArgumentCounts(num_args + extra_args,
                                          0,
                                          &error_message)) {
    const String& message = String::Handle(
        String::NewFormatted("%s: wrong argument count for "
                             "constructor '%s': %s.",
                             current_func,
                             constr_name.ToCString(),
                             error_message.ToCString()));
    return ApiError::New(message);
  }
  return constructor.raw();
}


DART_EXPORT Dart_Handle Dart_New(Dart_Handle clazz,
                                 Dart_Handle constructor_name,
                                 int number_of_arguments,
                                 Dart_Handle* arguments) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Object& result = Object::Handle(isolate);

  if (number_of_arguments < 0) {
    return Api::NewError(
        "%s expects argument 'number_of_arguments' to be non-negative.",
        CURRENT_FUNC);
  }

  // Get the class to instantiate.
  Class& cls =
      Class::Handle(isolate, Api::UnwrapClassHandle(isolate, clazz).raw());
  if (cls.IsNull()) {
    RETURN_TYPE_ERROR(isolate, clazz, Class);
  }
  String& base_constructor_name = String::Handle();
  base_constructor_name = cls.Name();

  // And get the name of the constructor to invoke.
  String& dot_name = String::Handle(isolate);
  const Object& name_obj =
      Object::Handle(isolate, Api::UnwrapHandle(constructor_name));
  if (name_obj.IsNull()) {
    dot_name = Symbols::Dot();
  } else if (name_obj.IsString()) {
    const String& dot = String::Handle(isolate, Symbols::Dot());
    dot_name = String::Concat(dot, String::Cast(name_obj));
  } else {
    RETURN_TYPE_ERROR(isolate, constructor_name, String);
  }
  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }

  // Check for interfaces with default implementations.
  if (cls.is_interface()) {
    // Make sure that the constructor is found in the interface.
    result = ResolveConstructor(
        "Dart_New", cls, base_constructor_name, dot_name, number_of_arguments);
    if (result.IsError()) {
      return Api::NewHandle(isolate, result.raw());
    }

    ASSERT(cls.HasResolvedFactoryClass());
    const Class& factory_class = Class::Handle(cls.FactoryClass());

    // If the factory class implements the requested interface, then
    // we use the name of the factory class when looking up the
    // constructor.  Otherwise we use the original interface name when
    // looking up the constructor.
    const TypeArguments& no_type_args = TypeArguments::Handle(isolate);
    Error& error = Error::Handle();
    if (factory_class.IsSubtypeOf(no_type_args, cls, no_type_args, &error)) {
      base_constructor_name = factory_class.Name();
    }
    if (!error.IsNull()) {
      return Api::NewHandle(isolate, error.raw());
    }

    cls = cls.FactoryClass();
  }

  // Resolve the constructor.
  result = ResolveConstructor(
      "Dart_New", cls, base_constructor_name, dot_name, number_of_arguments);
  if (result.IsError()) {
    return Api::NewHandle(isolate, result.raw());
  }
  ASSERT(result.IsFunction());
  Function& constructor = Function::Handle(isolate);
  constructor ^= result.raw();

  Instance& new_object = Instance::Handle(isolate);
  if (constructor.IsConstructor()) {
    // Create the new object.
    new_object = Instance::New(cls);
  }

  // Create the argument list.
  int extra_args = (constructor.IsConstructor() ? 2 : 1);
  GrowableArray<const Object*> args(number_of_arguments + extra_args);
  if (constructor.IsConstructor()) {
    // Constructors get the uninitialized object and a constructor phase.
    args.Add(&new_object);
    args.Add(&Smi::Handle(isolate, Smi::New(Function::kCtorPhaseAll)));
  } else {
    // Factories get type arguments.
    args.Add(&TypeArguments::Handle(isolate));
  }
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg =
        Object::Handle(isolate, Api::UnwrapHandle(arguments[i]));
    if (!arg.IsNull() && !arg.IsInstance()) {
      if (arg.IsError()) {
        return Api::NewHandle(isolate, arg.raw());
      } else {
        return Api::NewError(
            "%s expects arguments[%d] to be an Instance handle.",
            CURRENT_FUNC, i);
      }
    }
    args.Add(&arg);
  }

  // Invoke the constructor and return the new object.
  const Array& kNoArgNames = Array::Handle(isolate);
  result = DartEntry::InvokeStatic(constructor, args, kNoArgNames);
  if (result.IsError()) {
    return Api::NewHandle(isolate, result.raw());
  }
  if (constructor.IsConstructor()) {
    ASSERT(result.IsNull());
  } else {
    ASSERT(result.IsNull() || result.IsInstance());
    new_object ^= result.raw();
  }
  return Api::NewHandle(isolate, new_object.raw());
}


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
  GrowableArray<const Object*> args(number_of_arguments);
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg =
        Object::Handle(isolate, Api::UnwrapHandle(arguments[i]));
    if (!arg.IsNull() && !arg.IsInstance()) {
      if (arg.IsError()) {
        return Api::NewHandle(isolate, arg.raw());
      } else {
        return Api::NewError(
            "%s expects arguments[%d] to be an Instance handle.",
            CURRENT_FUNC, i);
      }
    }
    args.Add(&arg);
  }

  const Array& kNoArgNames = Array::Handle(isolate);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }

  if (obj.IsNull() || obj.IsInstance()) {
    Instance& instance = Instance::Handle(isolate);
    instance ^= obj.raw();
    const Function& function = Function::Handle(
        isolate,
        Resolver::ResolveDynamic(instance,
                                 function_name,
                                 (number_of_arguments + 1),
                                 Resolver::kIsQualified));
    // TODO(5415268): Invoke noSuchMethod instead of failing.
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
        DartEntry::InvokeDynamic(instance, function, args, kNoArgNames));

  } else if (obj.IsClass()) {
    // Finalize all classes.
    const char* msg = CheckIsolateState(isolate);
    if (msg != NULL) {
      return Api::NewError(msg);
    }

    const Class& cls = Class::Cast(obj);
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
        DartEntry::InvokeStatic(function, args, kNoArgNames));

  } else if (obj.IsLibrary()) {
    // Check whether class finalization is needed.
    bool finalize_classes = true;
    const Library& lib = Library::Cast(obj);

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
    function = lib.LookupFunctionAllowPrivate(function_name);
    if (function.IsNull()) {
      return Api::NewError("%s: did not find top-level function '%s'.",
                           CURRENT_FUNC,
                           function_name.ToCString());
    }
    // LookupFunctionAllowPrivate does not check argument arity, so we
    // do it here.
    String& error_message = String::Handle();
    if (!function.AreValidArgumentCounts(number_of_arguments,
                                         0,
                                         &error_message)) {
      return Api::NewError("%s: wrong argument count for function '%s': %s.",
                           CURRENT_FUNC,
                           function_name.ToCString(),
                           error_message.ToCString());
    }
    return Api::NewHandle(
        isolate, DartEntry::InvokeStatic(function, args, kNoArgNames));

  } else {
    return Api::NewError(
        "%s expects argument 'target' to be an object, class, or library.",
        CURRENT_FUNC);
  }
}


static bool FieldIsUninitialized(Isolate* isolate, const Field& fld) {
  ASSERT(!fld.IsNull());

  // Return getter method for uninitialized fields, rather than the
  // field object, since the value in the field object will not be
  // initialized until the first time the getter is invoked.
  const Instance& value = Instance::Handle(isolate, fld.value());
  ASSERT(value.raw() != Object::transition_sentinel());
  return value.raw() == Object::sentinel();
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
    const Instance& instance = Instance::Cast(obj);
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
    // Finalize all classes.
    const char* msg = CheckIsolateState(isolate);
    if (msg != NULL) {
      return Api::NewError(msg);
    }
    // To access a static field we may need to use the Field or the
    // getter Function.
    const Class& cls = Class::Cast(obj);
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
    // TODO(turnidge): Do we need to call CheckIsolateState here?

    // To access a top-level we may need to use the Field or the
    // getter Function.  The getter function may either be in the
    // library or in the field's owner class, depending.
    const Library& lib = Library::Cast(obj);
    field = lib.LookupFieldAllowPrivate(field_name);
    if (field.IsNull()) {
      // No field found.  Check for a getter in the lib.
      const String& getter_name =
          String::Handle(isolate, Field::GetterName(field_name));
      getter = lib.LookupFunctionAllowPrivate(getter_name);
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

  } else if (obj.IsError()) {
      return container;
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
    const Instance& instance = Instance::Cast(obj);
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
    const Class& cls = Class::Cast(obj);
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
    const Library& lib = Library::Cast(obj);
    field = lib.LookupFieldAllowPrivate(field_name);
    if (field.IsNull()) {
      const String& setter_name =
          String::Handle(isolate, Field::SetterName(field_name));
      setter ^= lib.LookupFunctionAllowPrivate(setter_name);
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

  } else if (obj.IsError()) {
      return container;
  } else {
    return Api::NewError(
        "%s expects argument 'container' to be an object, class, or library.",
        CURRENT_FUNC);
  }
}


DART_EXPORT Dart_Handle Dart_CreateNativeWrapperClass(Dart_Handle library,
                                                      Dart_Handle name,
                                                      int field_count) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const String& cls_name = Api::UnwrapStringHandle(isolate, name);
  if (cls_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, name, String);
  }
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }
  if (field_count <= 0) {
    return Api::NewError(
        "Negative field_count passed to Dart_CreateNativeWrapperClass");
  }

  String& cls_symbol = String::Handle(isolate, Symbols::New(cls_name));
  const Class& cls = Class::Handle(
      isolate, Class::NewNativeWrapper(lib, cls_symbol, field_count));
  if (cls.IsNull()) {
    return Api::NewError(
        "Unable to create native wrapper class : already exists");
  }
  return Api::NewHandle(isolate, cls.raw());
}


DART_EXPORT Dart_Handle Dart_GetNativeInstanceFieldCount(Dart_Handle obj,
                                                         int* count) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Instance& instance = Api::UnwrapInstanceHandle(isolate, obj);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(isolate, obj, Instance);
  }
  const Class& cls = Class::Handle(isolate, instance.clazz());
  *count = cls.num_native_fields();
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_GetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t* value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Instance& instance = Api::UnwrapInstanceHandle(isolate, obj);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(isolate, obj, Instance);
  }
  if (!instance.IsValidNativeIndex(index)) {
    return Api::NewError(
        "%s: invalid index %d passed in to access native instance field",
        CURRENT_FUNC, index);
  }
  *value = instance.GetNativeField(index);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_SetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t value) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Instance& instance = Api::UnwrapInstanceHandle(isolate, obj);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(isolate, obj, Instance);
  }
  if (!instance.IsValidNativeIndex(index)) {
    return Api::NewError(
        "%s: invalid index %d passed in to set native instance field",
        CURRENT_FUNC, index);
  }
  instance.SetNativeField(index, value);
  return Api::Success(isolate);
}


// --- Exceptions ----


DART_EXPORT Dart_Handle Dart_ThrowException(Dart_Handle exception) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Instance& excp = Api::UnwrapInstanceHandle(isolate, exception);
  if (excp.IsNull()) {
    RETURN_TYPE_ERROR(isolate, exception, Instance);
  }
  if (isolate->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    return Api::NewError("No Dart frames on stack, cannot throw exception");
  }
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
  DARTSCOPE(isolate);
  const Instance& excp = Api::UnwrapInstanceHandle(isolate, exception);
  if (excp.IsNull()) {
    RETURN_TYPE_ERROR(isolate, exception, Instance);
  }
  const Instance& stk = Api::UnwrapInstanceHandle(isolate, stacktrace);
  if (stk.IsNull()) {
    RETURN_TYPE_ERROR(isolate, stacktrace, Instance);
  }
  if (isolate->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    return Api::NewError("No Dart frames on stack, cannot throw exception");
  }
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


DART_EXPORT Dart_Handle Dart_SetLibraryTagHandler(
    Dart_LibraryTagHandler handler) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  isolate->set_library_tag_handler(handler);
  return Api::Success(isolate);
}


DART_EXPORT Dart_Handle Dart_SetImportMap(Dart_Handle import_map) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Array& mapping_array = Api::UnwrapArrayHandle(isolate, import_map);
  if (mapping_array.IsNull()) {
    RETURN_TYPE_ERROR(isolate, import_map, Array);
  }
  isolate->object_store()->set_import_map(mapping_array);
  return Api::Success(isolate);
}


// NOTE: Need to pass 'result' as a parameter here in order to avoid
// warning: variable 'result' might be clobbered by 'longjmp' or 'vfork'
// which shows up because of the use of setjmp.
static void CompileSource(Isolate* isolate,
                          const Library& lib,
                          const String& url,
                          const String& source,
                          RawScript::Kind kind,
                          Dart_Handle* result) {
  bool update_lib_status = (kind == RawScript::kScriptTag ||
                            kind == RawScript::kLibraryTag);
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


// Removes optimized code once we load more classes, since --use_cha based
// optimizations may have become invalid.
// TODO(srdjan): Note which functions use which CHA decision and deoptimize
// only the necessary ones.
static void RemoveOptimizedCode() {
  ASSERT(FLAG_use_cha);
  const ClassTable& class_table = *Isolate::Current()->class_table();
  Class& cls = Class::Handle();
  Array& array = Array::Handle();
  Function& function = Function::Handle();
  const intptr_t num_cids = class_table.NumCids();
  for (intptr_t i = kInstanceCid; i < num_cids; i++) {
    if (!class_table.HasValidClassAt(i)) continue;
    cls = class_table.At(i);
    ASSERT(!cls.IsNull());
    array = cls.functions();
    intptr_t num_functions = array.IsNull() ? 0 : array.Length();
    for (intptr_t f = 0; f < num_functions; f++) {
      function ^= array.At(f);
      ASSERT(!function.IsNull());
      if (function.HasOptimizedCode()) {
        function.SwitchToUnoptimizedCode();
      }
    }
  }
}


DART_EXPORT Dart_Handle Dart_LoadScript(Dart_Handle url,
                                        Dart_Handle source) {
  TIMERSCOPE(time_script_loading);
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (FLAG_use_cha) {
    RemoveOptimizedCode();
  }
  const String& url_str = Api::UnwrapStringHandle(isolate, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(isolate, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, source, String);
  }
  Library& library =
      Library::Handle(isolate, isolate->object_store()->root_library());
  if (!library.IsNull()) {
    const String& library_url = String::Handle(isolate, library.url());
    return Api::NewError("%s: A script has already been loaded from '%s'.",
                         CURRENT_FUNC, library_url.ToCString());
  }
  library = Library::New(url_str);
  library.set_debuggable(true);
  library.Register();
  isolate->object_store()->set_root_library(library);
  Dart_Handle result;
  CompileSource(isolate,
                library,
                url_str,
                source_str,
                RawScript::kScriptTag,
                &result);
  return result;
}


DART_EXPORT Dart_Handle Dart_LoadScriptFromSnapshot(const uint8_t* buffer) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  TIMERSCOPE(time_script_loading);
  if (buffer == NULL) {
    RETURN_NULL_ERROR(buffer);
  }
  if (FLAG_use_cha) {
    RemoveOptimizedCode();
  }
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);
  if (!snapshot->IsScriptSnapshot()) {
    return Api::NewError("%s expects parameter 'buffer' to be a script type"
                         " snapshot.", CURRENT_FUNC);
  }
  Library& library =
      Library::Handle(isolate, isolate->object_store()->root_library());
  if (!library.IsNull()) {
    const String& library_url = String::Handle(isolate, library.url());
    return Api::NewError("%s: A script has already been loaded from '%s'.",
                         CURRENT_FUNC, library_url.ToCString());
  }
  SnapshotReader reader(snapshot->content(),
                        snapshot->length(),
                        snapshot->kind(),
                        isolate);
  const Object& tmp = Object::Handle(isolate, reader.ReadObject());
  if (!tmp.IsLibrary()) {
    return Api::NewError("%s: Unable to deserialize snapshot correctly.",
                         CURRENT_FUNC);
  }
  library ^= tmp.raw();
  library.set_debuggable(true);
  isolate->object_store()->set_root_library(library);
  return Api::NewHandle(isolate, library.raw());
}


DART_EXPORT Dart_Handle Dart_RootLibrary() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Library& library =
      Library::Handle(isolate, isolate->object_store()->root_library());
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
  return Api::ClassId(object) == kLibraryCid;
}


DART_EXPORT Dart_Handle Dart_GetClass(Dart_Handle library,
                                      Dart_Handle class_name) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }
  const String& cls_name = Api::UnwrapStringHandle(isolate, class_name);
  if (cls_name.IsNull()) {
    RETURN_TYPE_ERROR(isolate, class_name, String);
  }
  const Class& cls =
      Class::Handle(isolate, lib.LookupClassAllowPrivate(cls_name));
  if (cls.IsNull()) {
    // TODO(turnidge): Return null or error in this case?
    const String& lib_name = String::Handle(isolate, lib.name());
    return Api::NewError("Class '%s' not found in library '%s'.",
                         cls_name.ToCString(), lib_name.ToCString());
  }
  return Api::NewHandle(isolate, cls.raw());
}


DART_EXPORT Dart_Handle Dart_LibraryName(Dart_Handle library) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }
  const String& name = String::Handle(isolate, lib.name());
  ASSERT(!name.IsNull());
  return Api::NewHandle(isolate, name.raw());
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


DART_EXPORT Dart_Handle Dart_LibraryGetClassNames(Dart_Handle library) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }

  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New());
  ClassDictionaryIterator it(lib);
  Class& cls = Class::Handle();
  String& name = String::Handle();
  while (it.HasNext()) {
    cls = it.GetNextClass();
    // For now we suppress the signature classes of closures.
    //
    // TODO(turnidge): Add this to the unit test.
    const Function& signature_func = Function::Handle(cls.signature_function());
    if (signature_func.IsNull()) {
      name = cls.UserVisibleName();
      names.Add(name);
    }
  }
  return Api::NewHandle(isolate, Array::MakeArray(names));
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
                                         Dart_Handle source) {
  TIMERSCOPE(time_script_loading);
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (FLAG_use_cha) {
    RemoveOptimizedCode();
  }
  const String& url_str = Api::UnwrapStringHandle(isolate, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(isolate, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, source, String);
  }
  Library& library = Library::Handle(isolate, Library::LookupLibrary(url_str));
  if (library.IsNull()) {
    library = Library::New(url_str);
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
                RawScript::kLibraryTag,
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
  if (FLAG_use_cha) {
    RemoveOptimizedCode();
  }
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
  CompileSource(isolate, lib, url_str, source_str,
                RawScript::kSourceTag, &result);
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
      ApiZone* zone = Api::TopScope(isolate)->zone();
      *buffer = reinterpret_cast<void*>(zone->AllocUnsafe(*buffer_size));
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


DART_EXPORT void Dart_InitPerfEventsSupport(Dart_FileWriterFunction function) {
  Dart::set_perf_events_writer(function);
}


DART_EXPORT void Dart_InitFlowGraphPrinting(Dart_FileWriterFunction function) {
  Dart::set_flow_graph_writer(function);
}

}  // namespace dart
