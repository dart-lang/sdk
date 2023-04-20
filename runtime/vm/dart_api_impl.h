// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DART_API_IMPL_H_
#define RUNTIME_VM_DART_API_IMPL_H_

#include <memory>

#include "vm/allocation.h"
#include "vm/heap/safepoint.h"
#include "vm/native_arguments.h"
#include "vm/object.h"
#include "vm/timeline.h"

namespace dart {

class ApiLocalScope;
class ApiState;
class FinalizablePersistentHandle;
class LocalHandle;
class PersistentHandle;
class ReusableObjectHandleScope;
class ThreadRegistry;

const char* CanonicalFunction(const char* func);

#define CURRENT_FUNC CanonicalFunction(__FUNCTION__)

// Checks that the current isolate group is not nullptr.
#define CHECK_ISOLATE_GROUP(isolate_group)                                     \
  do {                                                                         \
    if ((isolate_group) == nullptr) {                                          \
      FATAL(                                                                   \
          "%s expects there to be a current isolate group. Did you "           \
          "forget to call Dart_CreateIsolateGroup or Dart_EnterIsolate?",      \
          CURRENT_FUNC);                                                       \
    }                                                                          \
  } while (0)

// Checks that the current isolate is not nullptr.
#define CHECK_ISOLATE(isolate)                                                 \
  do {                                                                         \
    if ((isolate) == nullptr) {                                                \
      FATAL(                                                                   \
          "%s expects there to be a current isolate. Did you "                 \
          "forget to call Dart_CreateIsolateGroup or Dart_EnterIsolate?",      \
          CURRENT_FUNC);                                                       \
    }                                                                          \
  } while (0)

// Checks that the current isolate is nullptr.
#define CHECK_NO_ISOLATE(isolate)                                              \
  do {                                                                         \
    if ((isolate) != nullptr) {                                                \
      FATAL(                                                                   \
          "%s expects there to be no current isolate. Did you "                \
          "forget to call Dart_ExitIsolate?",                                  \
          CURRENT_FUNC);                                                       \
    }                                                                          \
  } while (0)

// Checks that the current isolate is not nullptr and that it has an API scope.
#define CHECK_API_SCOPE(thread)                                                \
  do {                                                                         \
    Thread* tmpT = (thread);                                                   \
    Isolate* tmpI = tmpT == nullptr ? nullptr : tmpT->isolate();               \
    CHECK_ISOLATE(tmpI);                                                       \
    if (tmpT->api_top_scope() == nullptr) {                                    \
      FATAL(                                                                   \
          "%s expects to find a current scope. Did you forget to call "        \
          "Dart_EnterScope?",                                                  \
          CURRENT_FUNC);                                                       \
    }                                                                          \
  } while (0);

#define DARTSCOPE(thread)                                                      \
  Thread* T = (thread);                                                        \
  CHECK_API_SCOPE(T);                                                          \
  TransitionNativeToVM transition(T);                                          \
  HANDLESCOPE(T);

#define RETURN_TYPE_ERROR(zone, dart_handle, type)                             \
  do {                                                                         \
    const Object& tmp =                                                        \
        Object::Handle(zone, Api::UnwrapHandle((dart_handle)));                \
    if (tmp.IsNull()) {                                                        \
      return Api::NewArgumentError("%s expects argument '%s' to be non-null.", \
                                   CURRENT_FUNC, #dart_handle);                \
    } else if (tmp.IsError()) {                                                \
      return dart_handle;                                                      \
    }                                                                          \
    return Api::NewArgumentError("%s expects argument '%s' to be of type %s.", \
                                 CURRENT_FUNC, #dart_handle, #type);           \
  } while (0)

#define RETURN_NULL_ERROR(parameter)                                           \
  return Api::NewError("%s expects argument '%s' to be non-null.",             \
                       CURRENT_FUNC, #parameter)

#define CHECK_NULL(parameter)                                                  \
  if (parameter == nullptr) {                                                  \
    RETURN_NULL_ERROR(parameter);                                              \
  }

#define CHECK_LENGTH(length, max_elements)                                     \
  do {                                                                         \
    intptr_t len = (length);                                                   \
    intptr_t max = (max_elements);                                             \
    if (len < 0 || len > max) {                                                \
      return Api::NewError(                                                    \
          "%s expects argument '%s' to be in the range [0..%" Pd "].",         \
          CURRENT_FUNC, #length, max);                                         \
    }                                                                          \
  } while (0)

#ifdef SUPPORT_TIMELINE
#define API_TIMELINE_DURATION(thread)                                          \
  TimelineBeginEndScope api_tbes(thread, Timeline::GetAPIStream(), CURRENT_FUNC)

#define API_TIMELINE_BEGIN_END(thread)                                         \
  TimelineBeginEndScope api_tbes(thread, Timeline::GetAPIStream(), CURRENT_FUNC)

#else
#define API_TIMELINE_DURATION(thread)                                          \
  do {                                                                         \
  } while (false)
#define API_TIMELINE_BEGIN_END(thread)                                         \
  do {                                                                         \
  } while (false)
#endif  // SUPPORT_TIMELINE

class Api : AllStatic {
 public:
  // Create on the stack to provide a new throw-safe api scope.
  class Scope : public ThreadStackResource {
   public:
    explicit Scope(Thread* thread) : ThreadStackResource(thread) {
      thread->EnterApiScope();
    }
    ~Scope() { thread()->ExitApiScope(); }

   private:
    DISALLOW_COPY_AND_ASSIGN(Scope);
  };

  // Creates a new local handle.
  static Dart_Handle NewHandle(Thread* thread, ObjectPtr raw);

  // Unwraps the raw object from the handle.
  static ObjectPtr UnwrapHandle(Dart_Handle object);

// Unwraps a raw Type from the handle.  The handle will be null if
// the object was not of the requested Type.
#define DECLARE_UNWRAP(Type)                                                   \
  static const Type& Unwrap##Type##Handle(Zone* zone, Dart_Handle object);
  CLASS_LIST_FOR_HANDLES(DECLARE_UNWRAP)
#undef DECLARE_UNWRAP

  // Unwraps the raw object from the handle using a reused handle.
  static const String& UnwrapStringHandle(
      const ReusableObjectHandleScope& reused,
      Dart_Handle object);
  static const Instance& UnwrapInstanceHandle(
      const ReusableObjectHandleScope& reused,
      Dart_Handle object);

  // Returns an Error handle if isolate is in an inconsistent state
  // or there was an error while finalizing classes.
  // Returns a Success handle when no error condition exists.
  static Dart_Handle CheckAndFinalizePendingClasses(Thread* thread);

  // Casts the internal Isolate* type to the external Dart_Isolate type.
  static Dart_Isolate CastIsolate(Isolate* isolate);

  // Casts the internal IsolateGroup* type to the external Dart_IsolateGroup
  // type.
  static Dart_IsolateGroup CastIsolateGroup(IsolateGroup* isolate_group);

  // Gets the handle used to designate successful return.
  static Dart_Handle Success() { return Api::True(); }

  // Returns true if the handle holds a Smi.
  static bool IsSmi(Dart_Handle handle) {
    // Important: we do not require current thread to be in VM state because
    // we do not dereference the handle.
    ObjectPtr raw = *(reinterpret_cast<ObjectPtr*>(handle));
    return !raw->IsHeapObject();
  }

  // Returns the value of a Smi.
  static intptr_t SmiValue(Dart_Handle handle) {
    // Important: we do not require current thread to be in VM state because
    // we do not dereference the handle.
    ObjectPtr value = *(reinterpret_cast<ObjectPtr*>(handle));
    return Smi::Value(static_cast<SmiPtr>(value));
  }

  // Returns true if the handle holds a Dart Instance.
  static bool IsInstance(Dart_Handle handle) {
    return !IsInternalOnlyClassId(ClassId(handle));
  }

  // Returns true if the handle is non-dangling.
  static bool IsValid(Dart_Handle handle);

  // Returns true if the handle holds an Error.
  static bool IsError(Dart_Handle handle) {
    return IsErrorClassId(ClassId(handle));
  }

  static intptr_t ClassId(Dart_Handle handle) {
    ObjectPtr raw = UnwrapHandle(handle);
    if (!raw->IsHeapObject()) {
      return kSmiCid;
    }
    return raw->GetClassId();
  }

  // Generates a handle used to designate an error return.
  static Dart_Handle NewError(const char* format, ...) PRINTF_ATTRIBUTE(1, 2);
  static Dart_Handle NewArgumentError(const char* format, ...)
      PRINTF_ATTRIBUTE(1, 2);

  // Gets a handle to Null.
  static Dart_Handle Null() { return null_handle_; }

  // Gets a handle to True.
  static Dart_Handle True() { return true_handle_; }

  // Gets a handle to False.
  static Dart_Handle False() { return false_handle_; }

  // Gets a handle to EmptyString.
  static Dart_Handle EmptyString() { return empty_string_handle_; }

  // Gets the handle which holds the pre-created acquired error object.
  static Dart_Handle NoCallbacksError() { return no_callbacks_error_handle_; }

  // Gets the handle for unwind-is-in-progress error.
  static Dart_Handle UnwindInProgressError() {
    return unwind_in_progress_error_handle_;
  }

  static bool IsProtectedHandle(Dart_Handle object) {
    if (object == nullptr) return false;
    return (object == true_handle_) || (object == false_handle_) ||
           (object == null_handle_) || (object == empty_string_handle_) ||
           (object == no_callbacks_error_handle_) ||
           (object == unwind_in_progress_error_handle_);
  }

  // Retrieves the top ApiLocalScope.
  static ApiLocalScope* TopScope(Thread* thread);

  // Performs initialization needed by the API.
  static void Init();

  // Allocates handles for objects in the VM isolate.
  static void InitHandles();

  // Cleanup
  static void Cleanup();

  // Helper function to get the peer value of an external string object.
  static bool StringGetPeerHelper(NativeArguments* args,
                                  int arg_index,
                                  void** peer);

  // Helper function to get the native field from a native receiver argument.
  static bool GetNativeReceiver(NativeArguments* args, intptr_t* value);

  // Helper function to get the boolean value of a Bool native argument.
  static bool GetNativeBooleanArgument(NativeArguments* args,
                                       int arg_index,
                                       bool* value);

  // Helper function to get the integer value of a Integer native argument.
  static bool GetNativeIntegerArgument(NativeArguments* args,
                                       int arg_index,
                                       int64_t* value);

  // Helper function to get the double value of a Double native argument.
  static bool GetNativeDoubleArgument(NativeArguments* args,
                                      int arg_index,
                                      double* value);

  // Helper function to get the native fields of an Instance native argument.
  static bool GetNativeFieldsOfArgument(NativeArguments* args,
                                        int arg_index,
                                        int num_fields,
                                        intptr_t* field_values);

  // Helper function to set the return value of native functions.
  static void SetReturnValue(NativeArguments* args, Dart_Handle retval) {
    args->SetReturnUnsafe(UnwrapHandle(retval));
  }
  static void SetSmiReturnValue(NativeArguments* args, intptr_t retval) {
    args->SetReturnUnsafe(Smi::New(retval));
  }
  static void SetIntegerReturnValue(NativeArguments* args, int64_t retval) {
    args->SetReturnUnsafe(Integer::New(retval));
  }
  static void SetDoubleReturnValue(NativeArguments* args, double retval) {
    args->SetReturnUnsafe(Double::New(retval));
  }
  static void SetWeakHandleReturnValue(NativeArguments* args,
                                       Dart_WeakPersistentHandle retval);

  static StringPtr GetEnvironmentValue(Thread* thread, const String& name);

  static bool IsFfiEnabled() { return FLAG_enable_ffi; }

 private:
  static Dart_Handle InitNewHandle(Thread* thread, ObjectPtr raw);

  static StringPtr CallEnvironmentCallback(Thread* thread, const String& name);

  // Thread local key used by the API. Currently holds the current
  // ApiNativeScope if any.
  static ThreadLocalKey api_native_key_;
  static Dart_Handle true_handle_;
  static Dart_Handle false_handle_;
  static Dart_Handle null_handle_;
  static Dart_Handle empty_string_handle_;
  static Dart_Handle no_callbacks_error_handle_;
  static Dart_Handle unwind_in_progress_error_handle_;

  friend class ApiNativeScope;
};

// Start a scope in which no Dart API call backs are allowed.
#define START_NO_CALLBACK_SCOPE(thread) thread->IncrementNoCallbackScopeDepth()

// End a no Dart API call backs Scope.
#define END_NO_CALLBACK_SCOPE(thread)                                          \
  do {                                                                         \
    thread->DecrementNoCallbackScopeDepth();                                   \
    if (thread->no_callback_scope_depth() == 0) {                              \
      thread->heap()->CheckExternalGC(thread);                                 \
    }                                                                          \
  } while (false)

#define CHECK_CALLBACK_STATE(thread)                                           \
  if (thread->no_callback_scope_depth() != 0) {                                \
    return reinterpret_cast<Dart_Handle>(Api::NoCallbacksError());             \
  }                                                                            \
  if (thread->is_unwind_in_progress()) {                                       \
    return reinterpret_cast<Dart_Handle>(Api::UnwindInProgressError());        \
  }

#define ASSERT_CALLBACK_STATE(thread)                                          \
  ASSERT(thread->no_callback_scope_depth() == 0)

class IsolateGroupSource;

// Creates a new isolate from [source] (which should come from an existing
// isolate).
Isolate* CreateWithinExistingIsolateGroup(IsolateGroup* group,
                                          const char* name,
                                          char** error);

}  // namespace dart.

#endif  // RUNTIME_VM_DART_API_IMPL_H_
