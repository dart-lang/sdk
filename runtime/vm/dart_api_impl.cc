// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "include/dart_mirrors_api.h"
#include "include/dart_native_api.h"

#include "lib/stacktrace.h"
#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/clustered_snapshot.h"
#include "vm/compilation_trace.h"
#include "vm/compiler.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/kernel_reader.h"
#endif
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/isolate_reload.h"
#include "vm/kernel_isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/os_thread.h"
#include "vm/port.h"
#include "vm/precompiler.h"
#include "vm/profiler.h"
#include "vm/program_visitor.h"
#include "vm/resolver.h"
#include "vm/reusable_handles.h"
#include "vm/service.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/timer.h"
#include "vm/unicode.h"
#include "vm/uri.h"
#include "vm/verifier.h"
#include "vm/version.h"

namespace dart {

// Facilitate quick access to the current zone once we have the current thread.
#define Z (T->zone())

DECLARE_FLAG(bool, print_class_table);
DECLARE_FLAG(bool, verify_handles);
#if defined(DART_NO_SNAPSHOT)
DEFINE_FLAG(bool,
            check_function_fingerprints,
            true,
            "Check function fingerprints");
#endif  // defined(DART_NO_SNAPSHOT).
DEFINE_FLAG(bool,
            verify_acquired_data,
            false,
            "Verify correct API acquire/release of typed data.");

ThreadLocalKey Api::api_native_key_ = kUnsetThreadLocalKey;
Dart_Handle Api::true_handle_ = NULL;
Dart_Handle Api::false_handle_ = NULL;
Dart_Handle Api::null_handle_ = NULL;
Dart_Handle Api::empty_string_handle_ = NULL;

const char* CanonicalFunction(const char* func) {
  if (strncmp(func, "dart::", 6) == 0) {
    return func + 6;
  } else {
    return func;
  }
}

#ifndef PRODUCT
#define API_TIMELINE_DURATION                                                  \
  TimelineDurationScope tds(Thread::Current(), Timeline::GetAPIStream(),       \
                            CURRENT_FUNC)

#define API_TIMELINE_BEGIN_END                                                 \
  TimelineBeginEndScope tbes(Thread::Current(), Timeline::GetAPIStream(),      \
                             CURRENT_FUNC)
#else
#define API_TIMELINE_DURATION                                                  \
  do {                                                                         \
  } while (false)
#define API_TIMELINE_BEGIN_END                                                 \
  do {                                                                         \
  } while (false)
#endif  // !PRODUCT

#if defined(DEBUG)
// An object visitor which will iterate over all the function objects in the
// heap and check if the result type and parameter types are canonicalized
// or not. An assertion is raised if a type is not canonicalized.
class CheckFunctionTypesVisitor : public ObjectVisitor {
 public:
  explicit CheckFunctionTypesVisitor(Thread* thread)
      : classHandle_(Class::Handle(thread->zone())),
        funcHandle_(Function::Handle(thread->zone())),
        typeHandle_(AbstractType::Handle(thread->zone())) {}

  void VisitObject(RawObject* obj) {
    if (obj->IsFunction()) {
      funcHandle_ ^= obj;
      classHandle_ ^= funcHandle_.Owner();
      // Signature functions get created, but not canonicalized, when function
      // types get instantiated during run time type tests.
      if (funcHandle_.IsSignatureFunction()) {
        return;
      }
      // Verify that the result type of a function is canonical or a
      // TypeParameter.
      typeHandle_ ^= funcHandle_.result_type();
      ASSERT(typeHandle_.IsMalformed() || !typeHandle_.IsResolved() ||
             typeHandle_.IsTypeParameter() || typeHandle_.IsCanonical());
      // Verify that the types in the function signature are all canonical or
      // a TypeParameter.
      const intptr_t num_parameters = funcHandle_.NumParameters();
      for (intptr_t i = 0; i < num_parameters; i++) {
        typeHandle_ = funcHandle_.ParameterTypeAt(i);
        ASSERT(typeHandle_.IsMalformed() || !typeHandle_.IsResolved() ||
               typeHandle_.IsTypeParameter() || typeHandle_.IsCanonical());
      }
    }
  }

 private:
  Class& classHandle_;
  Function& funcHandle_;
  AbstractType& typeHandle_;
};
#endif  // #if defined(DEBUG).

static RawInstance* GetListInstance(Zone* zone, const Object& obj) {
  if (obj.IsInstance()) {
    const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
    const Class& list_class =
        Class::Handle(zone, core_lib.LookupClass(Symbols::List()));
    ASSERT(!list_class.IsNull());
    const Instance& instance = Instance::Cast(obj);
    const Class& obj_class = Class::Handle(zone, obj.clazz());
    Error& malformed_type_error = Error::Handle(zone);
    if (obj_class.IsSubtypeOf(Object::null_type_arguments(), list_class,
                              Object::null_type_arguments(),
                              &malformed_type_error, NULL, Heap::kNew)) {
      ASSERT(malformed_type_error.IsNull());  // Type is a raw List.
      return instance.raw();
    }
  }
  return Instance::null();
}

static RawInstance* GetMapInstance(Zone* zone, const Object& obj) {
  if (obj.IsInstance()) {
    const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
    const Class& map_class =
        Class::Handle(core_lib.LookupClass(Symbols::Map()));
    ASSERT(!map_class.IsNull());
    const Instance& instance = Instance::Cast(obj);
    const Class& obj_class = Class::Handle(zone, obj.clazz());
    Error& malformed_type_error = Error::Handle(zone);
    if (obj_class.IsSubtypeOf(Object::null_type_arguments(), map_class,
                              Object::null_type_arguments(),
                              &malformed_type_error, NULL, Heap::kNew)) {
      ASSERT(malformed_type_error.IsNull());  // Type is a raw Map.
      return instance.raw();
    }
  }
  return Instance::null();
}

static bool IsCompiletimeErrorObject(Zone* zone, const Object& obj) {
#if defined(DART_PRECOMPILED_RUNTIME)
  // All compile-time errors were handled at snapshot generation time and
  // compiletime_error_class was removed.
  return false;
#else
  Isolate* I = Thread::Current()->isolate();
  const Class& error_class =
      Class::Handle(zone, I->object_store()->compiletime_error_class());
  ASSERT(!error_class.IsNull());
  return (obj.GetClassId() == error_class.id());
#endif
}

static bool GetNativeStringArgument(NativeArguments* arguments,
                                    int arg_index,
                                    Dart_Handle* str,
                                    void** peer) {
  ASSERT(peer != NULL);
  if (Api::StringGetPeerHelper(arguments, arg_index, peer)) {
    *str = NULL;
    return true;
  }
  Thread* thread = arguments->thread();
  ASSERT(thread == Thread::Current());
  *peer = NULL;
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& obj = thread->ObjectHandle();
  obj = arguments->NativeArgAt(arg_index);
  if (RawObject::IsStringClassId(obj.GetClassId())) {
    ASSERT(thread->api_top_scope() != NULL);
    *str = Api::NewHandle(thread, obj.raw());
    return true;
  }
  if (obj.IsNull()) {
    *str = Api::Null();
    return true;
  }
  return false;
}

static bool GetNativeIntegerArgument(NativeArguments* arguments,
                                     int arg_index,
                                     int64_t* value) {
  ASSERT(value != NULL);
  if (Api::GetNativeIntegerArgument(arguments, arg_index, value)) {
    return true;
  }
  Thread* thread = arguments->thread();
  ASSERT(thread == Thread::Current());
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& obj = thread->ObjectHandle();
  obj = arguments->NativeArgAt(arg_index);
  intptr_t cid = obj.GetClassId();
  if (cid == kBigintCid) {
    const Bigint& bigint = Bigint::Cast(obj);
    if (bigint.FitsIntoInt64()) {
      *value = bigint.AsInt64Value();
      return true;
    }
  }
  return false;
}

static bool GetNativeUnsignedIntegerArgument(NativeArguments* arguments,
                                             int arg_index,
                                             uint64_t* value) {
  ASSERT(value != NULL);
  int64_t arg_value = 0;
  if (Api::GetNativeIntegerArgument(arguments, arg_index, &arg_value)) {
    *value = static_cast<uint64_t>(arg_value);
    return true;
  }
  Thread* thread = arguments->thread();
  ASSERT(thread == Thread::Current());
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& obj = thread->ObjectHandle();
  obj = arguments->NativeArgAt(arg_index);
  intptr_t cid = obj.GetClassId();
  if (cid == kBigintCid) {
    ASSERT(!Bigint::IsDisabled());
    const Bigint& bigint = Bigint::Cast(obj);
    if (bigint.FitsIntoUint64()) {
      *value = bigint.AsUint64Value();
      return true;
    }
  }
  return false;
}

static bool GetNativeDoubleArgument(NativeArguments* arguments,
                                    int arg_index,
                                    double* value) {
  ASSERT(value != NULL);
  if (Api::GetNativeDoubleArgument(arguments, arg_index, value)) {
    return true;
  }
  Thread* thread = arguments->thread();
  ASSERT(thread == Thread::Current());
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& obj = thread->ObjectHandle();
  obj = arguments->NativeArgAt(arg_index);
  intptr_t cid = obj.GetClassId();
  if (cid == kBigintCid) {
    *value = Bigint::Cast(obj).AsDoubleValue();
    return true;
  }
  return false;
}

static Dart_Handle GetNativeFieldsOfArgument(NativeArguments* arguments,
                                             int arg_index,
                                             int num_fields,
                                             intptr_t* field_values,
                                             const char* current_func) {
  ASSERT(field_values != NULL);
  if (Api::GetNativeFieldsOfArgument(arguments, arg_index, num_fields,
                                     field_values)) {
    return Api::Success();
  }
  Thread* thread = arguments->thread();
  ASSERT(thread == Thread::Current());
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& obj = thread->ObjectHandle();
  obj = arguments->NativeArgAt(arg_index);
  if (obj.IsNull()) {
    memset(field_values, 0, (num_fields * sizeof(field_values[0])));
    return Api::Success();
  }
  // We did not succeed in extracting the native fields report the
  // appropriate error.
  if (!obj.IsInstance()) {
    return Api::NewError(
        "%s expects argument at index '%d' to be of"
        " type Instance.",
        current_func, arg_index);
  }
  const Instance& instance = Instance::Cast(obj);
  int field_count = instance.NumNativeFields();
  ASSERT(num_fields != field_count);
  return Api::NewError("%s: expected %d 'num_fields' but was passed in %d.",
                       current_func, field_count, num_fields);
}

Heap::Space SpaceForExternal(Thread* thread, intptr_t size) {
  Heap* heap = thread->heap();
  // If 'size' would be a significant fraction of new space, then use old.
  static const int kExtNewRatio = 16;
  if (size > (heap->CapacityInWords(Heap::kNew) * kWordSize) / kExtNewRatio) {
    return Heap::kOld;
  } else {
    return Heap::kNew;
  }
}

static RawObject* Send0Arg(const Instance& receiver, const String& selector) {
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgs = 1;
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArgs)));
  const Function& function =
      Function::Handle(Resolver::ResolveDynamic(receiver, selector, args_desc));
  if (function.IsNull()) {
    return ApiError::New(String::Handle(String::New("")));
  }
  const Array& args = Array::Handle(Array::New(kNumArgs));
  args.SetAt(0, receiver);
  return DartEntry::InvokeFunction(function, args);
}

static RawObject* Send1Arg(const Instance& receiver,
                           const String& selector,
                           const Instance& argument) {
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgs = 2;
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArgs)));
  const Function& function =
      Function::Handle(Resolver::ResolveDynamic(receiver, selector, args_desc));
  if (function.IsNull()) {
    return ApiError::New(String::Handle(String::New("")));
  }
  const Array& args = Array::Handle(Array::New(kNumArgs));
  args.SetAt(0, receiver);
  args.SetAt(1, argument);
  return DartEntry::InvokeFunction(function, args);
}

static const char* GetErrorString(Thread* thread, const Object& obj) {
  // This function requires an API scope to be present.
  if (obj.IsError()) {
    ASSERT(thread->api_top_scope() != NULL);
    const Error& error = Error::Cast(obj);
    const char* str = error.ToErrorCString();
    intptr_t len = strlen(str) + 1;
    char* str_copy = Api::TopScope(thread)->zone()->Alloc<char>(len);
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

Dart_Handle Api::InitNewHandle(Thread* thread, RawObject* raw) {
  LocalHandles* local_handles = Api::TopScope(thread)->local_handles();
  ASSERT(local_handles != NULL);
  LocalHandle* ref = local_handles->AllocateHandle();
  ref->set_raw(raw);
  return ref->apiHandle();
}

Dart_Handle Api::NewHandle(Thread* thread, RawObject* raw) {
  if (raw == Object::null()) {
    return Null();
  }
  if (raw == Bool::True().raw()) {
    return True();
  }
  if (raw == Bool::False().raw()) {
    return False();
  }
  return InitNewHandle(thread, raw);
}

RawObject* Api::UnwrapHandle(Dart_Handle object) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread->isolate() != NULL);
  ASSERT(!FLAG_verify_handles || thread->IsValidLocalHandle(object) ||
         thread->isolate()->api_state()->IsActivePersistentHandle(
             reinterpret_cast<Dart_PersistentHandle>(object)) ||
         Dart::IsReadOnlyApiHandle(object));
  ASSERT(FinalizablePersistentHandle::raw_offset() == 0 &&
         PersistentHandle::raw_offset() == 0 && LocalHandle::raw_offset() == 0);
#endif
  return (reinterpret_cast<LocalHandle*>(object))->raw();
}

#define DEFINE_UNWRAP(type)                                                    \
  const type& Api::Unwrap##type##Handle(Zone* zone, Dart_Handle dart_handle) { \
    const Object& obj = Object::Handle(zone, Api::UnwrapHandle(dart_handle));  \
    if (obj.Is##type()) {                                                      \
      return type::Cast(obj);                                                  \
    }                                                                          \
    return type::Handle(zone);                                                 \
  }
CLASS_LIST_FOR_HANDLES(DEFINE_UNWRAP)
#undef DEFINE_UNWRAP

const String& Api::UnwrapStringHandle(const ReusableObjectHandleScope& reuse,
                                      Dart_Handle dart_handle) {
  Object& ref = reuse.Handle();
  ref = Api::UnwrapHandle(dart_handle);
  if (ref.IsString()) {
    return String::Cast(ref);
  }
  return Object::null_string();
}

const Instance& Api::UnwrapInstanceHandle(
    const ReusableObjectHandleScope& reuse,
    Dart_Handle dart_handle) {
  Object& ref = reuse.Handle();
  ref = Api::UnwrapHandle(dart_handle);
  if (ref.IsInstance()) {
    return Instance::Cast(ref);
  }
  return Object::null_instance();
}

Dart_Handle Api::CheckAndFinalizePendingClasses(Thread* thread) {
  Isolate* isolate = thread->isolate();
  if (!isolate->AllowClassFinalization()) {
    // Class finalization is blocked for the isolate. Do nothing.
    return Api::Success();
  }
  if (ClassFinalizer::ProcessPendingClasses()) {
    return Api::Success();
  }
  ASSERT(thread->sticky_error() != Object::null());
  return Api::NewHandle(thread, thread->sticky_error());
}

Dart_Isolate Api::CastIsolate(Isolate* isolate) {
  return reinterpret_cast<Dart_Isolate>(isolate);
}

Dart_Handle Api::NewError(const char* format, ...) {
  Thread* T = Thread::Current();
  CHECK_API_SCOPE(T);
  HANDLESCOPE(T);
  CHECK_CALLBACK_STATE(T);
  // Ensure we transition safepoint state to VM if we are not already in
  // that state.
  TransitionToVM transition(T);

  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);

  char* buffer = Z->Alloc<char>(len + 1);
  va_list args2;
  va_start(args2, format);
  OS::VSNPrint(buffer, (len + 1), format, args2);
  va_end(args2);

  const String& message = String::Handle(Z, String::New(buffer));
  return Api::NewHandle(T, ApiError::New(message));
}

void Api::SetupAcquiredError(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  state->SetupAcquiredError();
}

Dart_Handle Api::AcquiredError(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  PersistentHandle* acquired_error_handle = state->AcquiredError();
  return reinterpret_cast<Dart_Handle>(acquired_error_handle);
}

bool Api::IsValid(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  CHECK_ISOLATE(isolate);

  // Check against all of the handles in the current isolate as well as the
  // read-only handles.
  return thread->IsValidHandle(handle) ||
         isolate->api_state()->IsActivePersistentHandle(
             reinterpret_cast<Dart_PersistentHandle>(handle)) ||
         isolate->api_state()->IsActiveWeakPersistentHandle(
             reinterpret_cast<Dart_WeakPersistentHandle>(handle)) ||
         Dart::IsReadOnlyApiHandle(handle) ||
         Dart::IsReadOnlyHandle(reinterpret_cast<uword>(handle));
}

ApiLocalScope* Api::TopScope(Thread* thread) {
  ASSERT(thread != NULL);
  ApiLocalScope* scope = thread->api_top_scope();
  ASSERT(scope != NULL);
  return scope;
}

void Api::InitOnce() {
  ASSERT(api_native_key_ == kUnsetThreadLocalKey);
  api_native_key_ = OSThread::CreateThreadLocal();
  ASSERT(api_native_key_ != kUnsetThreadLocalKey);
}

static Dart_Handle InitNewReadOnlyApiHandle(RawObject* raw) {
  ASSERT(raw->IsVMHeapObject());
  LocalHandle* ref = Dart::AllocateReadOnlyApiHandle();
  ref->set_raw(raw);
  return ref->apiHandle();
}

void Api::InitHandles() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ASSERT(isolate == Dart::vm_isolate());
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);

  ASSERT(true_handle_ == NULL);
  true_handle_ = InitNewReadOnlyApiHandle(Bool::True().raw());

  ASSERT(false_handle_ == NULL);
  false_handle_ = InitNewReadOnlyApiHandle(Bool::False().raw());

  ASSERT(null_handle_ == NULL);
  null_handle_ = InitNewReadOnlyApiHandle(Object::null());

  ASSERT(empty_string_handle_ == NULL);
  empty_string_handle_ = InitNewReadOnlyApiHandle(Symbols::Empty().raw());
}

bool Api::StringGetPeerHelper(NativeArguments* arguments,
                              int arg_index,
                              void** peer) {
  NoSafepointScope no_safepoint_scope;
  RawObject* raw_obj = arguments->NativeArgAt(arg_index);
  if (!raw_obj->IsHeapObject()) {
    return false;
  }
  intptr_t cid = raw_obj->GetClassId();
  if (cid == kExternalOneByteStringCid) {
    RawExternalOneByteString* raw_string =
        reinterpret_cast<RawExternalOneByteString*>(raw_obj)->ptr();
    ExternalStringData<uint8_t>* data = raw_string->external_data_;
    *peer = data->peer();
    return true;
  }
  if (cid == kOneByteStringCid || cid == kTwoByteStringCid) {
    Isolate* isolate = arguments->thread()->isolate();
    *peer = isolate->heap()->GetPeer(raw_obj);
    return (*peer != 0);
  }
  if (cid == kExternalTwoByteStringCid) {
    RawExternalTwoByteString* raw_string =
        reinterpret_cast<RawExternalTwoByteString*>(raw_obj)->ptr();
    ExternalStringData<uint16_t>* data = raw_string->external_data_;
    *peer = data->peer();
    return true;
  }
  return false;
}

bool Api::GetNativeReceiver(NativeArguments* arguments, intptr_t* value) {
  NoSafepointScope no_safepoint_scope;
  RawObject* raw_obj = arguments->NativeArg0();
  if (raw_obj->IsHeapObject()) {
    intptr_t cid = raw_obj->GetClassId();
    if (cid >= kNumPredefinedCids) {
      ASSERT(Instance::Cast(Object::Handle(raw_obj)).IsValidNativeIndex(0));
      RawTypedData* native_fields = *reinterpret_cast<RawTypedData**>(
          RawObject::ToAddr(raw_obj) + sizeof(RawObject));
      if (native_fields == TypedData::null()) {
        *value = 0;
      } else {
        *value = *bit_cast<intptr_t*, uint8_t*>(native_fields->ptr()->data());
      }
      return true;
    }
  }
  return false;
}

bool Api::GetNativeBooleanArgument(NativeArguments* arguments,
                                   int arg_index,
                                   bool* value) {
  NoSafepointScope no_safepoint_scope;
  RawObject* raw_obj = arguments->NativeArgAt(arg_index);
  if (raw_obj->IsHeapObject()) {
    intptr_t cid = raw_obj->GetClassId();
    if (cid == kBoolCid) {
      *value = (raw_obj == Object::bool_true().raw());
      return true;
    }
    if (cid == kNullCid) {
      *value = false;
      return true;
    }
  }
  return false;
}

bool Api::GetNativeIntegerArgument(NativeArguments* arguments,
                                   int arg_index,
                                   int64_t* value) {
  NoSafepointScope no_safepoint_scope;
  RawObject* raw_obj = arguments->NativeArgAt(arg_index);
  if (raw_obj->IsHeapObject()) {
    intptr_t cid = raw_obj->GetClassId();
    if (cid == kMintCid) {
      *value = reinterpret_cast<RawMint*>(raw_obj)->ptr()->value_;
      return true;
    }
    return false;
  }
  *value = Smi::Value(reinterpret_cast<RawSmi*>(raw_obj));
  return true;
}

bool Api::GetNativeDoubleArgument(NativeArguments* arguments,
                                  int arg_index,
                                  double* value) {
  NoSafepointScope no_safepoint_scope;
  RawObject* raw_obj = arguments->NativeArgAt(arg_index);
  if (raw_obj->IsHeapObject()) {
    intptr_t cid = raw_obj->GetClassId();
    if (cid == kDoubleCid) {
      *value = reinterpret_cast<RawDouble*>(raw_obj)->ptr()->value_;
      return true;
    }
    if (cid == kMintCid) {
      *value = static_cast<double>(
          reinterpret_cast<RawMint*>(raw_obj)->ptr()->value_);
      return true;
    }
    return false;
  }
  *value = static_cast<double>(Smi::Value(reinterpret_cast<RawSmi*>(raw_obj)));
  return true;
}

bool Api::GetNativeFieldsOfArgument(NativeArguments* arguments,
                                    int arg_index,
                                    int num_fields,
                                    intptr_t* field_values) {
  NoSafepointScope no_safepoint_scope;
  RawObject* raw_obj = arguments->NativeArgAt(arg_index);
  if (raw_obj->IsHeapObject()) {
    intptr_t cid = raw_obj->GetClassId();
    if (cid >= kNumPredefinedCids) {
      RawTypedData* native_fields = *reinterpret_cast<RawTypedData**>(
          RawObject::ToAddr(raw_obj) + sizeof(RawObject));
      if (native_fields == TypedData::null()) {
        memset(field_values, 0, (num_fields * sizeof(field_values[0])));
      } else if (num_fields == Smi::Value(native_fields->ptr()->length_)) {
        intptr_t* native_values =
            bit_cast<intptr_t*, uint8_t*>(native_fields->ptr()->data());
        memmove(field_values, native_values,
                (num_fields * sizeof(field_values[0])));
      }
      return true;
    }
  }
  return false;
}

void Api::SetWeakHandleReturnValue(NativeArguments* args,
                                   Dart_WeakPersistentHandle retval) {
  args->SetReturnUnsafe(FinalizablePersistentHandle::Cast(retval)->raw());
}

PersistentHandle* PersistentHandle::Cast(Dart_PersistentHandle handle) {
  ASSERT(Isolate::Current()->api_state()->IsValidPersistentHandle(handle));
  return reinterpret_cast<PersistentHandle*>(handle);
}

FinalizablePersistentHandle* FinalizablePersistentHandle::Cast(
    Dart_WeakPersistentHandle handle) {
#if defined(DEBUG)
  ApiState* state = Isolate::Current()->api_state();
  ASSERT(state->IsValidWeakPersistentHandle(handle));
#endif
  return reinterpret_cast<FinalizablePersistentHandle*>(handle);
}

void FinalizablePersistentHandle::Finalize(
    Isolate* isolate,
    FinalizablePersistentHandle* handle) {
  if (!handle->raw()->IsHeapObject()) {
    return;  // Free handle.
  }
  Dart_WeakPersistentHandleFinalizer callback = handle->callback();
  ASSERT(callback != NULL);
  void* peer = handle->peer();
  Dart_WeakPersistentHandle object = handle->apiHandle();
  (*callback)(isolate->init_callback_data(), object, peer);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  state->weak_persistent_handles().FreeHandle(handle);
}

// --- Handles ---

DART_EXPORT bool Dart_IsError(Dart_Handle handle) {
  return Api::IsError(handle);
}

DART_EXPORT bool Dart_IsApiError(Dart_Handle object) {
  return Api::ClassId(object) == kApiErrorCid;
}

DART_EXPORT bool Dart_IsUnhandledExceptionError(Dart_Handle object) {
  return Api::ClassId(object) == kUnhandledExceptionCid;
}

DART_EXPORT bool Dart_IsCompilationError(Dart_Handle object) {
  if (::Dart_IsUnhandledExceptionError(object)) {
    DARTSCOPE(Thread::Current());
    const UnhandledException& error =
        UnhandledException::Cast(Object::Handle(Z, Api::UnwrapHandle(object)));
    const Instance& exc = Instance::Handle(Z, error.exception());
    return IsCompiletimeErrorObject(Z, exc);
  }
  return Api::ClassId(object) == kLanguageErrorCid;
}

DART_EXPORT bool Dart_IsFatalError(Dart_Handle object) {
  return Api::ClassId(object) == kUnwindErrorCid;
}

DART_EXPORT const char* Dart_GetError(Dart_Handle handle) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  return GetErrorString(T, obj);
}

DART_EXPORT bool Dart_ErrorHasException(Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  return obj.IsUnhandledException();
}

DART_EXPORT Dart_Handle Dart_ErrorGetException(Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  if (obj.IsUnhandledException()) {
    const UnhandledException& error = UnhandledException::Cast(obj);
    return Api::NewHandle(T, error.exception());
  } else if (obj.IsError()) {
    return Api::NewError("This error is not an unhandled exception error.");
  } else {
    return Api::NewError("Can only get exceptions from error handles.");
  }
}

DART_EXPORT Dart_Handle Dart_ErrorGetStackTrace(Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  if (obj.IsUnhandledException()) {
    const UnhandledException& error = UnhandledException::Cast(obj);
    return Api::NewHandle(T, error.stacktrace());
  } else if (obj.IsError()) {
    return Api::NewError("This error is not an unhandled exception error.");
  } else {
    return Api::NewError("Can only get stacktraces from error handles.");
  }
}

// TODO(turnidge): This clones Api::NewError.  I need to use va_copy to
// fix this but not sure if it available on all of our builds.
DART_EXPORT Dart_Handle Dart_NewApiError(const char* error) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  const String& message = String::Handle(Z, String::New(error));
  return Api::NewHandle(T, ApiError::New(message));
}

DART_EXPORT Dart_Handle Dart_NewUnhandledExceptionError(Dart_Handle exception) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  Instance& obj = Instance::Handle(Z);
  intptr_t class_id = Api::ClassId(exception);
  if ((class_id == kApiErrorCid) || (class_id == kLanguageErrorCid)) {
    const Object& excp = Object::Handle(Z, Api::UnwrapHandle(exception));
    obj = String::New(GetErrorString(T, excp));
  } else {
    obj = Api::UnwrapInstanceHandle(Z, exception).raw();
    if (obj.IsNull()) {
      RETURN_TYPE_ERROR(Z, exception, Instance);
    }
  }
  const StackTrace& stacktrace = StackTrace::Handle(Z);
  return Api::NewHandle(T, UnhandledException::New(obj, stacktrace));
}

DART_EXPORT Dart_Handle Dart_PropagateError(Dart_Handle handle) {
  Thread* thread = Thread::Current();
  TransitionNativeToVM transition(thread);
  const Object& obj = Object::Handle(thread->zone(), Api::UnwrapHandle(handle));
  if (!obj.IsError()) {
    return Api::NewError(
        "%s expects argument 'handle' to be an error handle.  "
        "Did you forget to check Dart_IsError first?",
        CURRENT_FUNC);
  }
  if (thread->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // propagate an error here.
    return Api::NewError("No Dart frames on stack, cannot propagate error.");
  }
  // Unwind all the API scopes till the exit frame before propagating.
  const Error* error;
  {
    // We need to preserve the error object across the destruction of zones
    // when the ApiScopes are unwound.  By using NoSafepointScope, we can ensure
    // that GC won't touch the raw error object before creating a valid
    // handle for it in the surviving zone.
    NoSafepointScope no_safepoint;
    RawError* raw_error = Api::UnwrapErrorHandle(thread->zone(), handle).raw();
    thread->UnwindScopes(thread->top_exit_frame_info());
    // Note that thread's zone is different here than at the beginning of this
    // function.
    error = &Error::Handle(thread->zone(), raw_error);
  }
  Exceptions::PropagateError(*error);
  UNREACHABLE();
  return Api::NewError("Cannot reach here.  Internal error.");
}

DART_EXPORT void _Dart_ReportErrorHandle(const char* file,
                                         int line,
                                         const char* handle,
                                         const char* message) {
  fprintf(stderr, "%s:%d: error handle: '%s':\n    '%s'\n", file, line, handle,
          message);
  OS::Abort();
}

DART_EXPORT Dart_Handle Dart_ToString(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  if (obj.IsString()) {
    return Api::NewHandle(T, obj.raw());
  } else if (obj.IsInstance()) {
    CHECK_CALLBACK_STATE(T);
    const Instance& receiver = Instance::Cast(obj);
    return Api::NewHandle(T, DartLibraryCalls::ToString(receiver));
  } else {
    CHECK_CALLBACK_STATE(T);
    // This is a VM internal object. Call the C++ method of printing.
    return Api::NewHandle(T, String::New(obj.ToCString()));
  }
}

DART_EXPORT bool Dart_IdentityEquals(Dart_Handle obj1, Dart_Handle obj2) {
  DARTSCOPE(Thread::Current());
  {
    NoSafepointScope no_safepoint_scope;
    if (Api::UnwrapHandle(obj1) == Api::UnwrapHandle(obj2)) {
      return true;
    }
  }
  const Object& object1 = Object::Handle(Z, Api::UnwrapHandle(obj1));
  const Object& object2 = Object::Handle(Z, Api::UnwrapHandle(obj2));
  if (object1.IsInstance() && object2.IsInstance()) {
    return Instance::Cast(object1).IsIdenticalTo(Instance::Cast(object2));
  }
  return false;
}

DART_EXPORT Dart_Handle
Dart_HandleFromPersistent(Dart_PersistentHandle object) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  PersistentHandle* ref = PersistentHandle::Cast(object);
  return Api::NewHandle(thread, ref->raw());
}

DART_EXPORT Dart_Handle
Dart_HandleFromWeakPersistent(Dart_WeakPersistentHandle object) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  FinalizablePersistentHandle* weak_ref =
      FinalizablePersistentHandle::Cast(object);
  return Api::NewHandle(thread, weak_ref->raw());
}

DART_EXPORT Dart_PersistentHandle Dart_NewPersistentHandle(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  ApiState* state = I->api_state();
  ASSERT(state != NULL);
  const Object& old_ref = Object::Handle(Z, Api::UnwrapHandle(object));
  PersistentHandle* new_ref = state->persistent_handles().AllocateHandle();
  new_ref->set_raw(old_ref);
  return new_ref->apiHandle();
}

DART_EXPORT void Dart_SetPersistentHandle(Dart_PersistentHandle obj1,
                                          Dart_Handle obj2) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  ApiState* state = I->api_state();
  ASSERT(state != NULL);
  ASSERT(state->IsValidPersistentHandle(obj1));
  const Object& obj2_ref = Object::Handle(Z, Api::UnwrapHandle(obj2));
  PersistentHandle* obj1_ref = PersistentHandle::Cast(obj1);
  obj1_ref->set_raw(obj2_ref);
}

static Dart_WeakPersistentHandle AllocateFinalizableHandle(
    Thread* thread,
    Dart_Handle object,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback) {
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& ref = thread->ObjectHandle();
  ref = Api::UnwrapHandle(object);
  if (!ref.raw()->IsHeapObject()) {
    return NULL;
  }
  FinalizablePersistentHandle* finalizable_ref =
      FinalizablePersistentHandle::New(thread->isolate(), ref, peer, callback,
                                       external_allocation_size);
  return finalizable_ref->apiHandle();
}

DART_EXPORT Dart_WeakPersistentHandle
Dart_NewWeakPersistentHandle(Dart_Handle object,
                             void* peer,
                             intptr_t external_allocation_size,
                             Dart_WeakPersistentHandleFinalizer callback) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  if (callback == NULL) {
    return NULL;
  }
  TransitionNativeToVM transition(thread);
  return AllocateFinalizableHandle(thread, object, peer,
                                   external_allocation_size, callback);
}

DART_EXPORT void Dart_DeletePersistentHandle(Dart_PersistentHandle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  PersistentHandle* ref = PersistentHandle::Cast(object);
  ASSERT(!state->IsProtectedHandle(ref));
  if (!state->IsProtectedHandle(ref)) {
    state->persistent_handles().FreeHandle(ref);
  }
}

DART_EXPORT void Dart_DeleteWeakPersistentHandle(
    Dart_Isolate current_isolate,
    Dart_WeakPersistentHandle object) {
  Isolate* isolate = reinterpret_cast<Isolate*>(current_isolate);
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  ASSERT(isolate == Isolate::Current());
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  FinalizablePersistentHandle* weak_ref =
      FinalizablePersistentHandle::Cast(object);
  weak_ref->EnsureFreeExternal(isolate);
  state->weak_persistent_handles().FreeHandle(weak_ref);
}

// --- Initialization and Globals ---

DART_EXPORT const char* Dart_VersionString() {
  return Version::String();
}

DART_EXPORT char* Dart_Initialize(Dart_InitializeParams* params) {
  if (params == NULL) {
    return strdup(
        "Dart_Initialize: "
        "Dart_InitializeParams is null.");
  }

  if (params->version != DART_INITIALIZE_PARAMS_CURRENT_VERSION) {
    return strdup(
        "Dart_Initialize: "
        "Invalid Dart_InitializeParams version.");
  }

  return Dart::InitOnce(
      params->vm_snapshot_data, params->vm_snapshot_instructions,
      params->create, params->shutdown, params->cleanup, params->thread_exit,
      params->file_open, params->file_read, params->file_write,
      params->file_close, params->entropy_source, params->get_service_assets,
      params->start_kernel_isolate);
}

DART_EXPORT char* Dart_Cleanup() {
  CHECK_NO_ISOLATE(Isolate::Current());
  const char* err_msg = Dart::Cleanup();
  if (err_msg != NULL) {
    return strdup(err_msg);
  }
  return NULL;
}

DART_EXPORT bool Dart_SetVMFlags(int argc, const char** argv) {
  return Flags::ProcessCommandLineFlags(argc, argv);
}

DART_EXPORT bool Dart_IsVMFlagSet(const char* flag_name) {
  return Flags::IsSet(flag_name);
}

// --- Isolates ---

static char* BuildIsolateName(const char* script_uri, const char* main) {
  if (script_uri == NULL) {
    // Just use the main as the name.
    if (main == NULL) {
      return strdup("isolate");
    } else {
      return strdup(main);
    }
  }

  if (ServiceIsolate::NameEquals(script_uri)) {
    return strdup(script_uri);
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
  intptr_t len = OS::SNPrint(NULL, 0, "%s$%s", script_uri, main) + 1;
  chars = reinterpret_cast<char*>(malloc(len));
  OS::SNPrint(chars, len, "%s$%s", script_uri, main);
  return chars;
}

static Dart_Isolate CreateIsolate(const char* script_uri,
                                  const char* main,
                                  const uint8_t* snapshot_data,
                                  const uint8_t* snapshot_instructions,
                                  intptr_t snapshot_length,
                                  kernel::Program* kernel_program,
                                  Dart_IsolateFlags* flags,
                                  void* callback_data,
                                  char** error) {
  CHECK_NO_ISOLATE(Isolate::Current());
  char* isolate_name = BuildIsolateName(script_uri, main);

  // Setup default flags in case none were passed.
  Dart_IsolateFlags api_flags;
  if (flags == NULL) {
    Isolate::FlagsInitialize(&api_flags);
    flags = &api_flags;
  }
  Isolate* I = Dart::CreateIsolate(isolate_name, *flags);
  free(isolate_name);
  if (I == NULL) {
    *error = strdup("Isolate creation failed");
    return reinterpret_cast<Dart_Isolate>(NULL);
  }
  {
    Thread* T = Thread::Current();
    StackZone zone(T);
    HANDLESCOPE(T);
    // We enter an API scope here as InitializeIsolate could compile some
    // bootstrap library files which call out to a tag handler that may create
    // Api Handles when an error is encountered.
    Dart_EnterScope();
    const Error& error_obj =
        Error::Handle(Z, Dart::InitializeIsolate(
                             snapshot_data, snapshot_instructions,
                             snapshot_length, kernel_program, callback_data));
    if (error_obj.IsNull()) {
#if defined(DART_NO_SNAPSHOT) && !defined(PRODUCT)
      if (FLAG_check_function_fingerprints && kernel_program == NULL) {
        Library::CheckFunctionFingerprints();
      }
#endif  // defined(DART_NO_SNAPSHOT) && !defined(PRODUCT).
      // We exit the API scope entered above.
      Dart_ExitScope();
      // A Thread structure has been associated to the thread, we do the
      // safepoint transition explicitly here instead of using the
      // TransitionXXX scope objects as the reverse transition happens
      // outside this scope in Dart_ShutdownIsolate/Dart_ExitIsolate.
      T->set_execution_state(Thread::kThreadInNative);
      T->EnterSafepoint();
      return Api::CastIsolate(I);
    }
    *error = strdup(error_obj.ToErrorCString());
    // We exit the API scope entered above.
    Dart_ExitScope();
  }
  Dart::ShutdownIsolate();
  return reinterpret_cast<Dart_Isolate>(NULL);
}

DART_EXPORT Dart_Isolate
Dart_CreateIsolate(const char* script_uri,
                   const char* main,
                   const uint8_t* snapshot_data,
                   const uint8_t* snapshot_instructions,
                   Dart_IsolateFlags* flags,
                   void* callback_data,
                   char** error) {
  return CreateIsolate(script_uri, main, snapshot_data, snapshot_instructions,
                       -1, NULL, flags, callback_data, error);
}

DART_EXPORT Dart_Isolate Dart_CreateIsolateFromKernel(const char* script_uri,
                                                      const char* main,
                                                      void* kernel_program,
                                                      Dart_IsolateFlags* flags,
                                                      void* callback_data,
                                                      char** error) {
  // Setup default flags in case none were passed.
  Dart_IsolateFlags api_flags;
  if (flags == NULL) {
    Isolate::FlagsInitialize(&api_flags);
    flags = &api_flags;
  }
  flags->use_dart_frontend = true;
  return CreateIsolate(script_uri, main, NULL, NULL, -1,
                       reinterpret_cast<kernel::Program*>(kernel_program),
                       flags, callback_data, error);
}

DART_EXPORT void Dart_ShutdownIsolate() {
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  CHECK_ISOLATE(I);
  I->WaitForOutstandingSpawns();
  {
    StackZone zone(T);
    HandleScope handle_scope(T);
    Dart::RunShutdownCallback();
    // The Thread structure is disassociated from the isolate, we do the
    // safepoint transition explicitly here instead of using the TransitionXXX
    // scope objects as the original transition happened outside this scope in
    // Dart_EnterIsolate/Dart_CreateIsolate.
    T->ExitSafepoint();
    T->set_execution_state(Thread::kThreadInVM);
    ServiceIsolate::SendIsolateShutdownMessage();
  }
  Dart::ShutdownIsolate();
}

DART_EXPORT Dart_Isolate Dart_CurrentIsolate() {
  return Api::CastIsolate(Isolate::Current());
}

DART_EXPORT void* Dart_CurrentIsolateData() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  return isolate->init_callback_data();
}

DART_EXPORT void* Dart_IsolateData(Dart_Isolate isolate) {
  if (isolate == NULL) {
    FATAL1("%s expects argument 'isolate' to be non-null.", CURRENT_FUNC);
  }
  // TODO(16615): Validate isolate parameter.
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  return iso->init_callback_data();
}

DART_EXPORT Dart_Handle Dart_DebugName() {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  return Api::NewHandle(T, String::New(I->name()));
}

DART_EXPORT void Dart_EnterIsolate(Dart_Isolate isolate) {
  CHECK_NO_ISOLATE(Isolate::Current());
  // TODO(16615): Validate isolate parameter.
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  if (!Thread::EnterIsolate(iso)) {
    FATAL(
        "Unable to Enter Isolate : "
        "Multiple mutators entering an isolate / "
        "Dart VM is shutting down");
  }
  // A Thread structure has been associated to the thread, we do the
  // safepoint transition explicitly here instead of using the
  // TransitionXXX scope objects as the reverse transition happens
  // outside this scope in Dart_ExitIsolate/Dart_ShutdownIsolate.
  Thread* T = Thread::Current();
  T->set_execution_state(Thread::kThreadInNative);
  T->EnterSafepoint();
}

DART_EXPORT void Dart_ThreadDisableProfiling() {
  OSThread* os_thread = OSThread::Current();
  if (os_thread == NULL) {
    return;
  }
  os_thread->DisableThreadInterrupts();
}

DART_EXPORT void Dart_ThreadEnableProfiling() {
  OSThread* os_thread = OSThread::Current();
  if (os_thread == NULL) {
    return;
  }
  os_thread->EnableThreadInterrupts();
}

DART_EXPORT bool Dart_ShouldPauseOnStart() {
#if defined(PRODUCT)
  return false;
#else
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  return isolate->message_handler()->should_pause_on_start();
#endif
}

DART_EXPORT void Dart_SetShouldPauseOnStart(bool should_pause) {
#if defined(PRODUCT)
  if (should_pause) {
    FATAL1("%s(true) is not supported in a PRODUCT build", CURRENT_FUNC);
  }
#else
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  if (isolate->is_runnable()) {
    FATAL1("%s expects the current isolate to not be runnable yet.",
           CURRENT_FUNC);
  }
  isolate->message_handler()->set_should_pause_on_start(should_pause);
#endif
}

DART_EXPORT bool Dart_IsPausedOnStart() {
#if defined(PRODUCT)
  return false;
#else
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  return isolate->message_handler()->is_paused_on_start();
#endif
}

DART_EXPORT void Dart_SetPausedOnStart(bool paused) {
#if defined(PRODUCT)
  if (paused) {
    FATAL1("%s(true) is not supported in a PRODUCT build", CURRENT_FUNC);
  }
#else
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  if (isolate->message_handler()->is_paused_on_start() != paused) {
    isolate->message_handler()->PausedOnStart(paused);
  }
#endif
}

DART_EXPORT bool Dart_ShouldPauseOnExit() {
#if defined(PRODUCT)
  return false;
#else
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  return isolate->message_handler()->should_pause_on_exit();
#endif
}

DART_EXPORT void Dart_SetShouldPauseOnExit(bool should_pause) {
#if defined(PRODUCT)
  if (should_pause) {
    FATAL1("%s(true) is not supported in a PRODUCT build", CURRENT_FUNC);
  }
#else
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  isolate->message_handler()->set_should_pause_on_exit(should_pause);
#endif
}

DART_EXPORT bool Dart_IsPausedOnExit() {
#if defined(PRODUCT)
  return false;
#else
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  return isolate->message_handler()->is_paused_on_exit();
#endif
}

DART_EXPORT void Dart_SetPausedOnExit(bool paused) {
#if defined(PRODUCT)
  if (paused) {
    FATAL1("%s(true) is not supported in a PRODUCT build", CURRENT_FUNC);
  }
#else
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  if (isolate->message_handler()->is_paused_on_exit() != paused) {
    isolate->message_handler()->PausedOnExit(paused);
  }
#endif
}

DART_EXPORT void Dart_SetStickyError(Dart_Handle error) {
  Thread* thread = Thread::Current();
  DARTSCOPE(thread);
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  if ((isolate->sticky_error() != Error::null()) && !::Dart_IsNull(error)) {
    FATAL1("%s expects there to be no sticky error.", CURRENT_FUNC);
  }
  if (!::Dart_IsUnhandledExceptionError(error) && !::Dart_IsNull(error)) {
    FATAL1("%s expects the error to be an unhandled exception error or null.",
           CURRENT_FUNC);
  }
  isolate->SetStickyError(Api::UnwrapErrorHandle(Z, error).raw());
}

DART_EXPORT bool Dart_HasStickyError() {
  Thread* T = Thread::Current();
  Isolate* isolate = T->isolate();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  return isolate->sticky_error() != Error::null();
}

DART_EXPORT Dart_Handle Dart_GetStickyError() {
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  CHECK_ISOLATE(I);
  NoSafepointScope no_safepoint_scope;
  if (I->sticky_error() != Error::null()) {
    Dart_Handle error = Api::NewHandle(T, I->sticky_error());
    return error;
  }
  return Dart_Null();
}

DART_EXPORT void Dart_NotifyIdle(int64_t deadline) {
  Thread* T = Thread::Current();
  CHECK_ISOLATE(T->isolate());
  API_TIMELINE_BEGIN_END;
}

DART_EXPORT void Dart_ExitIsolate() {
  Thread* T = Thread::Current();
  CHECK_ISOLATE(T->isolate());
  // The Thread structure is disassociated from the isolate, we do the
  // safepoint transition explicitly here instead of using the TransitionXXX
  // scope objects as the original transition happened outside this scope in
  // Dart_EnterIsolate/Dart_CreateIsolate.
  ASSERT(T->execution_state() == Thread::kThreadInNative);
  T->ExitSafepoint();
  T->set_execution_state(Thread::kThreadInVM);
  Thread::ExitIsolate();
}

static uint8_t* ApiReallocate(uint8_t* ptr,
                              intptr_t old_size,
                              intptr_t new_size) {
  return Api::TopScope(Thread::Current())
      ->zone()
      ->Realloc<uint8_t>(ptr, old_size, new_size);
}

DART_EXPORT Dart_Handle
Dart_CreateSnapshot(uint8_t** vm_snapshot_data_buffer,
                    intptr_t* vm_snapshot_data_size,
                    uint8_t** isolate_snapshot_data_buffer,
                    intptr_t* isolate_snapshot_data_size) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION;
  Isolate* I = T->isolate();
  if (!FLAG_load_deferred_eagerly) {
    return Api::NewError(
        "Creating full snapshots requires --load_deferred_eagerly");
  }
  if (vm_snapshot_data_buffer != NULL && vm_snapshot_data_size == NULL) {
    RETURN_NULL_ERROR(vm_snapshot_data_size);
  }
  CHECK_NULL(isolate_snapshot_data_buffer);
  CHECK_NULL(isolate_snapshot_data_size);
  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(state)) {
    return state;
  }
  I->StopBackgroundCompiler();

#if defined(DEBUG)
  I->heap()->CollectAllGarbage();
  {
    HeapIterationScope iteration(T);
    CheckFunctionTypesVisitor check_canonical(T);
    iteration.IterateObjects(&check_canonical);
  }
#endif  // #if defined(DEBUG)

  Symbols::Compact(I);

  FullSnapshotWriter writer(Snapshot::kFull, vm_snapshot_data_buffer,
                            isolate_snapshot_data_buffer, ApiReallocate,
                            NULL /* vm_image_writer */,
                            NULL /* isolate_image_writer */);
  writer.WriteFullSnapshot();
  if (vm_snapshot_data_buffer != NULL) {
    *vm_snapshot_data_size = writer.VmIsolateSnapshotSize();
  }
  *isolate_snapshot_data_size = writer.IsolateSnapshotSize();
  return Api::Success();
}

DART_EXPORT Dart_Handle
Dart_CreateScriptSnapshot(uint8_t** script_snapshot_buffer,
                          intptr_t* script_snapshot_size) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  CHECK_NULL(script_snapshot_buffer);
  CHECK_NULL(script_snapshot_size);
  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(state)) {
    return state;
  }
  Library& lib = Library::Handle(Z, I->object_store()->root_library());

#if defined(DEBUG)
  I->heap()->CollectAllGarbage();
  {
    HeapIterationScope iteration(T);
    CheckFunctionTypesVisitor check_canonical(T);
    iteration.IterateObjects(&check_canonical);
  }
#endif  // #if defined(DEBUG)

  ScriptSnapshotWriter writer(script_snapshot_buffer, ApiReallocate);
  writer.WriteScriptSnapshot(lib);
  *script_snapshot_size = writer.BytesWritten();
  return Api::Success();
}

DART_EXPORT void Dart_InterruptIsolate(Dart_Isolate isolate) {
  if (isolate == NULL) {
    FATAL1("%s expects argument 'isolate' to be non-null.", CURRENT_FUNC);
  }
  // TODO(16615): Validate isolate parameter.
  TransitionNativeToVM transition(Thread::Current());
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  iso->SendInternalLibMessage(Isolate::kInterruptMsg, iso->pause_capability());
}

DART_EXPORT bool Dart_IsolateMakeRunnable(Dart_Isolate isolate) {
  CHECK_NO_ISOLATE(Isolate::Current());
  API_TIMELINE_DURATION;
  if (isolate == NULL) {
    FATAL1("%s expects argument 'isolate' to be non-null.", CURRENT_FUNC);
  }
  // TODO(16615): Validate isolate parameter.
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  if (iso->object_store()->root_library() == Library::null()) {
    // The embedder should have called Dart_LoadScript by now.
    return false;
  }
  return iso->MakeRunnable();
}

// --- Messages and Ports ---

DART_EXPORT void Dart_SetMessageNotifyCallback(
    Dart_MessageNotifyCallback message_notify_callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  isolate->set_message_notify_callback(message_notify_callback);
}

DART_EXPORT Dart_MessageNotifyCallback Dart_GetMessageNotifyCallback() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  return isolate->message_notify_callback();
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
  Isolate* I;
  {
    Thread* T = Thread::Current();
    I = T->isolate();
    CHECK_API_SCOPE(T);
    CHECK_CALLBACK_STATE(T);
  }
  API_TIMELINE_BEGIN_END;
  // The message handler run loop does not expect to have a current isolate
  // so we exit the isolate here and enter it again after the runloop is done.
  ::Dart_ExitIsolate();
  {
    Monitor monitor;
    MonitorLocker ml(&monitor);
    RunLoopData data;
    data.monitor = &monitor;
    data.done = false;
    I->message_handler()->Run(Dart::thread_pool(), NULL, RunLoopDone,
                              reinterpret_cast<uword>(&data));
    while (!data.done) {
      ml.Wait();
    }
  }
  ::Dart_EnterIsolate(Api::CastIsolate(I));
  if (I->sticky_error() != Object::null()) {
    Dart_Handle error = Api::NewHandle(Thread::Current(), I->sticky_error());
    I->clear_sticky_error();
    return error;
  }
  if (FLAG_print_class_table) {
    HANDLESCOPE(Thread::Current());
    I->class_table()->Print();
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_HandleMessage() {
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  CHECK_API_SCOPE(T);
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_BEGIN_END;
  TransitionNativeToVM transition(T);
  if (I->message_handler()->HandleNextMessage() != MessageHandler::kOK) {
    Dart_Handle error = Api::NewHandle(T, T->sticky_error());
    T->clear_sticky_error();
    return error;
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_HandleMessages() {
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  CHECK_API_SCOPE(T);
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_BEGIN_END;
  TransitionNativeToVM transition(T);
  if (I->message_handler()->HandleAllMessages() != MessageHandler::kOK) {
    Dart_Handle error = Api::NewHandle(T, T->sticky_error());
    T->clear_sticky_error();
    return error;
  }
  return Api::Success();
}

DART_EXPORT bool Dart_HandleServiceMessages() {
#if defined(PRODUCT)
  return true;
#else
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  CHECK_API_SCOPE(T);
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION;
  TransitionNativeToVM transition(T);
  ASSERT(I->GetAndClearResumeRequest() == false);
  MessageHandler::MessageStatus status =
      I->message_handler()->HandleOOBMessages();
  bool resume = I->GetAndClearResumeRequest();
  return (status != MessageHandler::kOK) || resume;
#endif
}

DART_EXPORT bool Dart_HasServiceMessages() {
#if defined(PRODUCT)
  return false;
#else
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate);
  NoSafepointScope no_safepoint_scope;
  return isolate->message_handler()->HasOOBMessages();
#endif
}

DART_EXPORT bool Dart_HasLivePorts() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate);
  NoSafepointScope no_safepoint_scope;
  return isolate->message_handler()->HasLivePorts();
}

static uint8_t* malloc_allocator(uint8_t* ptr,
                                 intptr_t old_size,
                                 intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}

static void malloc_deallocator(uint8_t* ptr) {
  free(reinterpret_cast<void*>(ptr));
}

DART_EXPORT bool Dart_Post(Dart_Port port_id, Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION;
  NoSafepointScope no_safepoint_scope;
  if (port_id == ILLEGAL_PORT) {
    return false;
  }

  // Smis and null can be sent without serialization.
  RawObject* raw_obj = Api::UnwrapHandle(handle);
  if (ApiObjectConverter::CanConvert(raw_obj)) {
    return PortMap::PostMessage(
        new Message(port_id, raw_obj, Message::kNormalPriority));
  }

  const Object& object = Object::Handle(Z, raw_obj);
  uint8_t* data = NULL;
  MessageWriter writer(&data, &malloc_allocator, &malloc_deallocator, false);
  writer.WriteMessage(object);
  intptr_t len = writer.BytesWritten();
  return PortMap::PostMessage(
      new Message(port_id, data, len, Message::kNormalPriority));
}

DART_EXPORT Dart_Handle Dart_NewSendPort(Dart_Port port_id) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  if (port_id == ILLEGAL_PORT) {
    return Api::NewError("%s: illegal port_id %" Pd64 ".", CURRENT_FUNC,
                         port_id);
  }
  return Api::NewHandle(T, SendPort::New(port_id));
}

DART_EXPORT Dart_Handle Dart_SendPortGetId(Dart_Handle port,
                                           Dart_Port* port_id) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION;
  const SendPort& send_port = Api::UnwrapSendPortHandle(Z, port);
  if (send_port.IsNull()) {
    RETURN_TYPE_ERROR(Z, port, SendPort);
  }
  if (port_id == NULL) {
    RETURN_NULL_ERROR(port_id);
  }
  *port_id = send_port.Id();
  return Api::Success();
}

DART_EXPORT Dart_Port Dart_GetMainPortId() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  return isolate->main_port();
}

// --- Scopes ----

DART_EXPORT void Dart_EnterScope() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  ApiLocalScope* new_scope = thread->api_reusable_scope();
  if (new_scope == NULL) {
    new_scope = new ApiLocalScope(thread->api_top_scope(),
                                  thread->top_exit_frame_info());
    ASSERT(new_scope != NULL);
  } else {
    new_scope->Reinit(thread, thread->api_top_scope(),
                      thread->top_exit_frame_info());
    thread->set_api_reusable_scope(NULL);
  }
  thread->set_api_top_scope(new_scope);  // New scope is now the top scope.
}

DART_EXPORT void Dart_ExitScope() {
  Thread* T = Thread::Current();
  CHECK_API_SCOPE(T);
  NoSafepointScope no_safepoint_scope;
  ApiLocalScope* scope = T->api_top_scope();
  ApiLocalScope* reusable_scope = T->api_reusable_scope();
  T->set_api_top_scope(scope->previous());  // Reset top scope to previous.
  if (reusable_scope == NULL) {
    scope->Reset(T);  // Reset the old scope which we just exited.
    T->set_api_reusable_scope(scope);
  } else {
    ASSERT(reusable_scope != scope);
    delete scope;
  }
}

DART_EXPORT uint8_t* Dart_ScopeAllocate(intptr_t size) {
  Zone* zone;
  Thread* thread = Thread::Current();
  if (thread != NULL) {
    ApiLocalScope* scope = thread->api_top_scope();
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
  ASSERT(Isolate::Current() != NULL);
  return Api::Null();
}

DART_EXPORT Dart_Handle Dart_EmptyString() {
  ASSERT(Isolate::Current() != NULL);
  return Api::EmptyString();
}

DART_EXPORT bool Dart_IsNull(Dart_Handle object) {
  return Api::UnwrapHandle(object) == Object::null();
}

DART_EXPORT Dart_Handle Dart_ObjectEquals(Dart_Handle obj1,
                                          Dart_Handle obj2,
                                          bool* value) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  const Instance& expected =
      Instance::CheckedHandle(Z, Api::UnwrapHandle(obj1));
  const Instance& actual = Instance::CheckedHandle(Z, Api::UnwrapHandle(obj2));
  const Object& result =
      Object::Handle(Z, DartLibraryCalls::Equals(expected, actual));
  if (result.IsBool()) {
    *value = Bool::Cast(result).value();
    return Api::Success();
  } else if (result.IsError()) {
    return Api::NewHandle(T, result.raw());
  } else {
    return Api::NewError("Expected boolean result from ==");
  }
}

// TODO(iposva): This call actually implements IsInstanceOfClass.
// Do we also need a real Dart_IsInstanceOf, which should take an instance
// rather than an object?
DART_EXPORT Dart_Handle Dart_ObjectIsType(Dart_Handle object,
                                          Dart_Handle type,
                                          bool* value) {
  DARTSCOPE(Thread::Current());

  const Type& type_obj = Api::UnwrapTypeHandle(Z, type);
  if (type_obj.IsNull()) {
    *value = false;
    RETURN_TYPE_ERROR(Z, type, Type);
  }
  if (!type_obj.IsFinalized()) {
    return Api::NewError(
        "%s expects argument 'type' to be a fully resolved type.",
        CURRENT_FUNC);
  }
  if (object == Api::Null()) {
    *value = false;
    return Api::Success();
  }
  const Instance& instance = Api::UnwrapInstanceHandle(Z, object);
  if (instance.IsNull()) {
    *value = false;
    RETURN_TYPE_ERROR(Z, object, Instance);
  }
  CHECK_CALLBACK_STATE(T);
  Error& malformed_type_error = Error::Handle(Z);
  *value = instance.IsInstanceOf(type_obj, Object::null_type_arguments(),
                                 Object::null_type_arguments(),
                                 &malformed_type_error);
  ASSERT(malformed_type_error.IsNull());  // Type was created from a class.
  return Api::Success();
}

DART_EXPORT bool Dart_IsInstance(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& ref = thread->ObjectHandle();
  ref = Api::UnwrapHandle(object);
  return ref.IsInstance();
}

DART_EXPORT bool Dart_IsNumber(Dart_Handle object) {
  return RawObject::IsNumberClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsInteger(Dart_Handle object) {
  return RawObject::IsIntegerClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsDouble(Dart_Handle object) {
  return Api::ClassId(object) == kDoubleCid;
}

DART_EXPORT bool Dart_IsBoolean(Dart_Handle object) {
  return Api::ClassId(object) == kBoolCid;
}

DART_EXPORT bool Dart_IsString(Dart_Handle object) {
  return RawObject::IsStringClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsStringLatin1(Dart_Handle object) {
  return RawObject::IsOneByteStringClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsExternalString(Dart_Handle object) {
  return RawObject::IsExternalStringClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsList(Dart_Handle object) {
  if (RawObject::IsBuiltinListClassId(Api::ClassId(object))) {
    return true;
  }

  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  return GetListInstance(Z, obj) != Instance::null();
}

DART_EXPORT bool Dart_IsMap(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  return GetMapInstance(Z, obj) != Instance::null();
}

DART_EXPORT bool Dart_IsLibrary(Dart_Handle object) {
  return Api::ClassId(object) == kLibraryCid;
}

DART_EXPORT bool Dart_IsType(Dart_Handle handle) {
  return Api::ClassId(handle) == kTypeCid;
}

DART_EXPORT bool Dart_IsFunction(Dart_Handle handle) {
  return Api::ClassId(handle) == kFunctionCid;
}

DART_EXPORT bool Dart_IsVariable(Dart_Handle handle) {
  return Api::ClassId(handle) == kFieldCid;
}

DART_EXPORT bool Dart_IsTypeVariable(Dart_Handle handle) {
  return Api::ClassId(handle) == kTypeParameterCid;
}

DART_EXPORT bool Dart_IsClosure(Dart_Handle object) {
  return Api::ClassId(object) == kClosureCid;
}

DART_EXPORT bool Dart_IsTypedData(Dart_Handle handle) {
  intptr_t cid = Api::ClassId(handle);
  return RawObject::IsTypedDataClassId(cid) ||
         RawObject::IsExternalTypedDataClassId(cid) ||
         RawObject::IsTypedDataViewClassId(cid);
}

DART_EXPORT bool Dart_IsByteBuffer(Dart_Handle handle) {
  return Api::ClassId(handle) == kByteBufferCid;
}

DART_EXPORT bool Dart_IsFuture(Dart_Handle handle) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  if (obj.IsInstance()) {
    const Class& future_class =
        Class::Handle(I->object_store()->future_class());
    ASSERT(!future_class.IsNull());
    const Class& obj_class = Class::Handle(Z, obj.clazz());
    Error& malformed_type_error = Error::Handle(Z);
    bool is_future = obj_class.IsSubtypeOf(
        Object::null_type_arguments(), future_class,
        Object::null_type_arguments(), &malformed_type_error, NULL, Heap::kNew);
    ASSERT(malformed_type_error.IsNull());  // Type is a raw Future.
    return is_future;
  }
  return false;
}

// --- Instances ----

DART_EXPORT Dart_Handle Dart_InstanceGetType(Dart_Handle instance) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(instance));
  if (obj.IsNull()) {
    return Api::NewHandle(T, I->object_store()->null_type());
  }
  if (!obj.IsInstance()) {
    RETURN_TYPE_ERROR(Z, instance, Instance);
  }
  const AbstractType& type =
      AbstractType::Handle(Instance::Cast(obj).GetType(Heap::kNew));
  return Api::NewHandle(T, type.Canonicalize());
}

// --- Numbers, Integers and Doubles ----

DART_EXPORT Dart_Handle Dart_IntegerFitsIntoInt64(Dart_Handle integer,
                                                  bool* fits) {
  API_TIMELINE_DURATION;
  // Fast path for Smis and Mints.
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  intptr_t class_id = Api::ClassId(integer);
  if (class_id == kSmiCid || class_id == kMintCid) {
    *fits = true;
    return Api::Success();
  }
  // Slow path for Mints and Bigints.
  DARTSCOPE(thread);
  const Integer& int_obj = Api::UnwrapIntegerHandle(Z, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, integer, Integer);
  }
  ASSERT(!Bigint::Cast(int_obj).FitsIntoInt64());
  *fits = false;
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_IntegerFitsIntoUint64(Dart_Handle integer,
                                                   bool* fits) {
  // Fast path for Smis.
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  API_TIMELINE_DURATION;
  if (Api::IsSmi(integer)) {
    *fits = (Api::SmiValue(integer) >= 0);
    return Api::Success();
  }
  // Slow path for Mints and Bigints.
  DARTSCOPE(thread);
  const Integer& int_obj = Api::UnwrapIntegerHandle(Z, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, integer, Integer);
  }
  ASSERT(!int_obj.IsSmi());
  if (int_obj.IsMint()) {
    *fits = !int_obj.IsNegative();
  } else {
    ASSERT(!Bigint::IsDisabled());
    *fits = Bigint::Cast(int_obj).FitsIntoUint64();
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_NewInteger(int64_t value) {
  // Fast path for Smis.
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  API_TIMELINE_DURATION;
  if (Smi::IsValid(value)) {
    NOHANDLESCOPE(thread);
    return Api::NewHandle(thread, Smi::New(static_cast<intptr_t>(value)));
  }
  // Slow path for Mints and Bigints.
  DARTSCOPE(thread);
  CHECK_CALLBACK_STATE(thread);
  return Api::NewHandle(thread, Integer::New(value));
}

DART_EXPORT Dart_Handle Dart_NewIntegerFromUint64(uint64_t value) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION;
  if (Integer::IsValueInRange(value)) {
    return Api::NewHandle(T, Integer::NewFromUint64(value));
  }
  return Api::NewError("%s: Cannot create Dart integer from value %" Pu64,
                       CURRENT_FUNC, value);
}

DART_EXPORT Dart_Handle Dart_NewIntegerFromHexCString(const char* str) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION;
  const String& str_obj = String::Handle(Z, String::New(str));
  RawInteger* integer = Integer::New(str_obj);
  if (integer == Integer::null()) {
    return Api::NewError("%s: Cannot create Dart integer from string %s",
                         CURRENT_FUNC, str);
  }
  return Api::NewHandle(T, integer);
}

DART_EXPORT Dart_Handle Dart_IntegerToInt64(Dart_Handle integer,
                                            int64_t* value) {
  // Fast path for Smis.
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  if (Api::IsSmi(integer)) {
    *value = Api::SmiValue(integer);
    return Api::Success();
  }
  // Slow path for Mints and Bigints.
  DARTSCOPE(thread);
  const Integer& int_obj = Api::UnwrapIntegerHandle(Z, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, integer, Integer);
  }
  ASSERT(!int_obj.IsSmi());
  if (int_obj.IsMint()) {
    *value = int_obj.AsInt64Value();
    return Api::Success();
  } else {
    ASSERT(!Bigint::IsDisabled());
    const Bigint& bigint = Bigint::Cast(int_obj);
    if (bigint.FitsIntoInt64()) {
      *value = bigint.AsInt64Value();
      return Api::Success();
    }
  }
  return Api::NewError("%s: Integer %s cannot be represented as an int64_t.",
                       CURRENT_FUNC, int_obj.ToCString());
}

DART_EXPORT Dart_Handle Dart_IntegerToUint64(Dart_Handle integer,
                                             uint64_t* value) {
  // Fast path for Smis.
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  if (Api::IsSmi(integer)) {
    intptr_t smi_value = Api::SmiValue(integer);
    if (smi_value >= 0) {
      *value = smi_value;
      return Api::Success();
    }
  }
  // Slow path for Mints and Bigints.
  DARTSCOPE(thread);
  const Integer& int_obj = Api::UnwrapIntegerHandle(Z, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, integer, Integer);
  }
  if (int_obj.IsSmi()) {
    ASSERT(int_obj.IsNegative());
  } else if (int_obj.IsMint()) {
    if (!int_obj.IsNegative()) {
      *value = int_obj.AsInt64Value();
      return Api::Success();
    }
  } else {
    ASSERT(!Bigint::IsDisabled());
    const Bigint& bigint = Bigint::Cast(int_obj);
    if (bigint.FitsIntoUint64()) {
      *value = bigint.AsUint64Value();
      return Api::Success();
    }
  }
  return Api::NewError("%s: Integer %s cannot be represented as a uint64_t.",
                       CURRENT_FUNC, int_obj.ToCString());
}

DART_EXPORT Dart_Handle Dart_IntegerToHexCString(Dart_Handle integer,
                                                 const char** value) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  const Integer& int_obj = Api::UnwrapIntegerHandle(Z, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, integer, Integer);
  }
  Zone* scope_zone = Api::TopScope(Thread::Current())->zone();
  *value = int_obj.ToHexCString(scope_zone);
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_NewDouble(double value) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(T, Double::New(value));
}

DART_EXPORT Dart_Handle Dart_DoubleValue(Dart_Handle double_obj,
                                         double* value) {
  DARTSCOPE(Thread::Current());
  const Double& obj = Api::UnwrapDoubleHandle(Z, double_obj);
  if (obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, double_obj, Double);
  }
  *value = obj.value();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetClosure(Dart_Handle library,
                                        Dart_Handle function_name) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  const String& name = Api::UnwrapStringHandle(Z, function_name);
  if (name.IsNull()) {
    RETURN_TYPE_ERROR(Z, function_name, String);
  }
  return Api::NewHandle(T, lib.GetFunctionClosure(name));
}

// --- Booleans ----

DART_EXPORT Dart_Handle Dart_True() {
  ASSERT(Isolate::Current() != NULL);
  return Api::True();
}

DART_EXPORT Dart_Handle Dart_False() {
  ASSERT(Isolate::Current() != NULL);
  return Api::False();
}

DART_EXPORT Dart_Handle Dart_NewBoolean(bool value) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  return value ? Api::True() : Api::False();
}

DART_EXPORT Dart_Handle Dart_BooleanValue(Dart_Handle boolean_obj,
                                          bool* value) {
  DARTSCOPE(Thread::Current());
  const Bool& obj = Api::UnwrapBoolHandle(Z, boolean_obj);
  if (obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, boolean_obj, Bool);
  }
  *value = obj.value();
  return Api::Success();
}

// --- Strings ---

DART_EXPORT Dart_Handle Dart_StringLength(Dart_Handle str, intptr_t* len) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  ReusableObjectHandleScope reused_obj_handle(thread);
  const String& str_obj = Api::UnwrapStringHandle(reused_obj_handle, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(thread->zone(), str, String);
  }
  *len = str_obj.Length();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_NewStringFromCString(const char* str) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  if (str == NULL) {
    RETURN_NULL_ERROR(str);
  }
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(T, String::New(str));
}

DART_EXPORT Dart_Handle Dart_NewStringFromUTF8(const uint8_t* utf8_array,
                                               intptr_t length) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  if (utf8_array == NULL && length != 0) {
    RETURN_NULL_ERROR(utf8_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  if (!Utf8::IsValid(utf8_array, length)) {
    return Api::NewError("%s expects argument 'str' to be valid UTF-8.",
                         CURRENT_FUNC);
  }
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(T, String::FromUTF8(utf8_array, length));
}

DART_EXPORT Dart_Handle Dart_NewStringFromUTF16(const uint16_t* utf16_array,
                                                intptr_t length) {
  DARTSCOPE(Thread::Current());
  if (utf16_array == NULL && length != 0) {
    RETURN_NULL_ERROR(utf16_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(T, String::FromUTF16(utf16_array, length));
}

DART_EXPORT Dart_Handle Dart_NewStringFromUTF32(const int32_t* utf32_array,
                                                intptr_t length) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  if (utf32_array == NULL && length != 0) {
    RETURN_NULL_ERROR(utf32_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(T, String::FromUTF32(utf32_array, length));
}

DART_EXPORT Dart_Handle
Dart_NewExternalLatin1String(const uint8_t* latin1_array,
                             intptr_t length,
                             void* peer,
                             Dart_PeerFinalizer cback) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  if (latin1_array == NULL && length != 0) {
    RETURN_NULL_ERROR(latin1_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(T,
                        String::NewExternal(latin1_array, length, peer, cback,
                                            SpaceForExternal(T, length)));
}

DART_EXPORT Dart_Handle Dart_NewExternalUTF16String(const uint16_t* utf16_array,
                                                    intptr_t length,
                                                    void* peer,
                                                    Dart_PeerFinalizer cback) {
  DARTSCOPE(Thread::Current());
  if (utf16_array == NULL && length != 0) {
    RETURN_NULL_ERROR(utf16_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  intptr_t bytes = length * sizeof(*utf16_array);
  return Api::NewHandle(T, String::NewExternal(utf16_array, length, peer, cback,
                                               SpaceForExternal(T, bytes)));
}

DART_EXPORT Dart_Handle Dart_StringToCString(Dart_Handle object,
                                             const char** cstr) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  if (cstr == NULL) {
    RETURN_NULL_ERROR(cstr);
  }
  const String& str_obj = Api::UnwrapStringHandle(Z, object);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, object, String);
  }
  intptr_t string_length = Utf8::Length(str_obj);
  char* res = Api::TopScope(T)->zone()->Alloc<char>(string_length + 1);
  if (res == NULL) {
    return Api::NewError("Unable to allocate memory");
  }
  const char* string_value = str_obj.ToCString();
  memmove(res, string_value, string_length + 1);
  ASSERT(res[string_length] == '\0');
  *cstr = res;
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_StringToUTF8(Dart_Handle str,
                                          uint8_t** utf8_array,
                                          intptr_t* length) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  if (utf8_array == NULL) {
    RETURN_NULL_ERROR(utf8_array);
  }
  if (length == NULL) {
    RETURN_NULL_ERROR(length);
  }
  const String& str_obj = Api::UnwrapStringHandle(Z, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, str, String);
  }
  intptr_t str_len = Utf8::Length(str_obj);
  *utf8_array = Api::TopScope(T)->zone()->Alloc<uint8_t>(str_len);
  if (*utf8_array == NULL) {
    return Api::NewError("Unable to allocate memory");
  }
  str_obj.ToUTF8(*utf8_array, str_len);
  *length = str_len;
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_StringToLatin1(Dart_Handle str,
                                            uint8_t* latin1_array,
                                            intptr_t* length) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  if (latin1_array == NULL) {
    RETURN_NULL_ERROR(latin1_array);
  }
  if (length == NULL) {
    RETURN_NULL_ERROR(length);
  }
  const String& str_obj = Api::UnwrapStringHandle(Z, str);
  if (str_obj.IsNull() || !str_obj.IsOneByteString()) {
    RETURN_TYPE_ERROR(Z, str, String);
  }
  intptr_t str_len = str_obj.Length();
  intptr_t copy_len = (str_len > *length) ? *length : str_len;

  // We have already asserted that the string object is a Latin-1 string
  // so we can copy the characters over using a simple loop.
  for (intptr_t i = 0; i < copy_len; i++) {
    latin1_array[i] = str_obj.CharAt(i);
  }
  *length = copy_len;
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_StringToUTF16(Dart_Handle str,
                                           uint16_t* utf16_array,
                                           intptr_t* length) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  const String& str_obj = Api::UnwrapStringHandle(Z, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, str, String);
  }
  intptr_t str_len = str_obj.Length();
  intptr_t copy_len = (str_len > *length) ? *length : str_len;
  for (intptr_t i = 0; i < copy_len; i++) {
    utf16_array[i] = str_obj.CharAt(i);
  }
  *length = copy_len;
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_StringStorageSize(Dart_Handle str,
                                               intptr_t* size) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  ReusableObjectHandleScope reused_obj_handle(thread);
  const String& str_obj = Api::UnwrapStringHandle(reused_obj_handle, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(thread->zone(), str, String);
  }
  if (size == NULL) {
    RETURN_NULL_ERROR(size);
  }
  *size = (str_obj.Length() * str_obj.CharSize());
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_StringGetProperties(Dart_Handle object,
                                                 intptr_t* char_size,
                                                 intptr_t* str_len,
                                                 void** peer) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  ReusableObjectHandleScope reused_obj_handle(thread);
  const String& str = Api::UnwrapStringHandle(reused_obj_handle, object);
  if (str.IsNull()) {
    RETURN_TYPE_ERROR(thread->zone(), object, String);
  }
  if (str.IsExternal()) {
    *peer = str.GetPeer();
    ASSERT(*peer != NULL);
  } else {
    NoSafepointScope no_safepoint_scope;
    *peer = thread->isolate()->heap()->GetPeer(str.raw());
  }
  *char_size = str.CharSize();
  *str_len = str.Length();
  return Api::Success();
}

// --- Lists ---

DART_EXPORT Dart_Handle Dart_NewList(intptr_t length) {
  DARTSCOPE(Thread::Current());
  CHECK_LENGTH(length, Array::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(T, Array::New(length));
}

#define GET_LIST_LENGTH(zone, type, obj, len)                                  \
  type& array = type::Handle(zone);                                            \
  array ^= obj.raw();                                                          \
  *len = array.Length();                                                       \
  return Api::Success();

DART_EXPORT Dart_Handle Dart_ListLength(Dart_Handle list, intptr_t* len) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsError()) {
    // Pass through errors.
    return list;
  }
  if (obj.IsTypedData()) {
    GET_LIST_LENGTH(Z, TypedData, obj, len);
  }
  if (obj.IsArray()) {
    GET_LIST_LENGTH(Z, Array, obj, len);
  }
  if (obj.IsGrowableObjectArray()) {
    GET_LIST_LENGTH(Z, GrowableObjectArray, obj, len);
  }
  if (obj.IsExternalTypedData()) {
    GET_LIST_LENGTH(Z, ExternalTypedData, obj, len);
  }
  CHECK_CALLBACK_STATE(T);

  // Now check and handle a dart object that implements the List interface.
  const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
  if (instance.IsNull()) {
    return Api::NewError("Object does not implement the List interface");
  }
  const String& name = String::Handle(Z, Field::GetterName(Symbols::Length()));
  const int kTypeArgsLen = 0;
  const int kNumArgs = 1;
  ArgumentsDescriptor args_desc(
      Array::Handle(Z, ArgumentsDescriptor::New(kTypeArgsLen, kNumArgs)));
  const Function& function =
      Function::Handle(Z, Resolver::ResolveDynamic(instance, name, args_desc));
  if (function.IsNull()) {
    return Api::NewError("List object does not have a 'length' field.");
  }

  const Array& args = Array::Handle(Z, Array::New(kNumArgs));
  args.SetAt(0, instance);  // Set up the receiver as the first argument.
  const Object& retval =
      Object::Handle(Z, DartEntry::InvokeFunction(function, args));
  if (retval.IsSmi()) {
    *len = Smi::Cast(retval).Value();
    return Api::Success();
  } else if (retval.IsMint() || retval.IsBigint()) {
    if (retval.IsMint()) {
      int64_t mint_value = Mint::Cast(retval).value();
      if (mint_value >= kIntptrMin && mint_value <= kIntptrMax) {
        *len = static_cast<intptr_t>(mint_value);
      }
    } else {
      // Check for a non-canonical Mint range value.
      ASSERT(retval.IsBigint());
      const Bigint& bigint = Bigint::Handle();
      if (bigint.FitsIntoInt64()) {
        int64_t bigint_value = bigint.AsInt64Value();
        if (bigint_value >= kIntptrMin && bigint_value <= kIntptrMax) {
          *len = static_cast<intptr_t>(bigint_value);
        }
      }
    }
    return Api::NewError(
        "Length of List object is greater than the "
        "maximum value that 'len' parameter can hold");
  } else if (retval.IsError()) {
    return Api::NewHandle(T, retval.raw());
  } else {
    return Api::NewError("Length of List object is not an integer");
  }
}

#define GET_LIST_ELEMENT(thread, type, obj, index)                             \
  const type& array_obj = type::Cast(obj);                                     \
  if ((index >= 0) && (index < array_obj.Length())) {                          \
    return Api::NewHandle(thread, array_obj.At(index));                        \
  }                                                                            \
  return Api::NewError("Invalid index passed in to access list element");

DART_EXPORT Dart_Handle Dart_ListGetAt(Dart_Handle list, intptr_t index) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsArray()) {
    GET_LIST_ELEMENT(T, Array, obj, index);
  } else if (obj.IsGrowableObjectArray()) {
    GET_LIST_ELEMENT(T, GrowableObjectArray, obj, index);
  } else if (obj.IsError()) {
    return list;
  } else {
    CHECK_CALLBACK_STATE(T);
    // Check and handle a dart object that implements the List interface.
    const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
    if (!instance.IsNull()) {
      return Api::NewHandle(T,
                            Send1Arg(instance, Symbols::IndexToken(),
                                     Instance::Handle(Z, Integer::New(index))));
    }
    return Api::NewError("Object does not implement the 'List' interface");
  }
}

#define GET_LIST_RANGE(thread, type, obj, offset, length)                      \
  const type& array_obj = type::Cast(obj);                                     \
  if ((offset >= 0) && (offset + length <= array_obj.Length())) {              \
    for (intptr_t index = 0; index < length; ++index) {                        \
      result[index] = Api::NewHandle(thread, array_obj.At(index + offset));    \
    }                                                                          \
    return Api::Success();                                                     \
  }                                                                            \
  return Api::NewError("Invalid offset/length passed in to access list");

DART_EXPORT Dart_Handle Dart_ListGetRange(Dart_Handle list,
                                          intptr_t offset,
                                          intptr_t length,
                                          Dart_Handle* result) {
  DARTSCOPE(Thread::Current());
  if (result == NULL) {
    RETURN_NULL_ERROR(result);
  }
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsArray()) {
    GET_LIST_RANGE(T, Array, obj, offset, length);
  } else if (obj.IsGrowableObjectArray()) {
    GET_LIST_RANGE(T, GrowableObjectArray, obj, offset, length);
  } else if (obj.IsError()) {
    return list;
  } else {
    CHECK_CALLBACK_STATE(T);
    // Check and handle a dart object that implements the List interface.
    const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
    if (!instance.IsNull()) {
      const intptr_t kTypeArgsLen = 0;
      const intptr_t kNumArgs = 2;
      ArgumentsDescriptor args_desc(
          Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArgs)));
      const Function& function = Function::Handle(
          Z, Resolver::ResolveDynamic(instance, Symbols::AssignIndexToken(),
                                      args_desc));
      if (!function.IsNull()) {
        const Array& args = Array::Handle(Array::New(kNumArgs));
        args.SetAt(0, instance);
        Instance& index = Instance::Handle(Z);
        for (intptr_t i = 0; i < length; ++i) {
          index = Integer::New(i);
          args.SetAt(1, index);
          Dart_Handle value =
              Api::NewHandle(T, DartEntry::InvokeFunction(function, args));
          if (::Dart_IsError(value)) return value;
          result[i] = value;
        }
        return Api::Success();
      }
    }
    return Api::NewError("Object does not implement the 'List' interface");
  }
}

#define SET_LIST_ELEMENT(type, obj, index, value)                              \
  const type& array = type::Cast(obj);                                         \
  const Object& value_obj = Object::Handle(Z, Api::UnwrapHandle(value));       \
  if (!value_obj.IsNull() && !value_obj.IsInstance()) {                        \
    RETURN_TYPE_ERROR(Z, value, Instance);                                     \
  }                                                                            \
  if ((index >= 0) && (index < array.Length())) {                              \
    array.SetAt(index, value_obj);                                             \
    return Api::Success();                                                     \
  }                                                                            \
  return Api::NewError("Invalid index passed in to set list element");

DART_EXPORT Dart_Handle Dart_ListSetAt(Dart_Handle list,
                                       intptr_t index,
                                       Dart_Handle value) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  // If the list is immutable we call into Dart for the indexed setter to
  // get the unsupported operation exception as the result.
  if (obj.IsArray() && !Array::Cast(obj).IsImmutable()) {
    SET_LIST_ELEMENT(Array, obj, index, value);
  } else if (obj.IsGrowableObjectArray()) {
    SET_LIST_ELEMENT(GrowableObjectArray, obj, index, value);
  } else if (obj.IsError()) {
    return list;
  } else {
    CHECK_CALLBACK_STATE(T);

    // Check and handle a dart object that implements the List interface.
    const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
    if (!instance.IsNull()) {
      const intptr_t kTypeArgsLen = 0;
      const intptr_t kNumArgs = 3;
      ArgumentsDescriptor args_desc(
          Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArgs)));
      const Function& function = Function::Handle(
          Z, Resolver::ResolveDynamic(instance, Symbols::AssignIndexToken(),
                                      args_desc));
      if (!function.IsNull()) {
        const Integer& index_obj = Integer::Handle(Z, Integer::New(index));
        const Object& value_obj = Object::Handle(Z, Api::UnwrapHandle(value));
        if (!value_obj.IsNull() && !value_obj.IsInstance()) {
          RETURN_TYPE_ERROR(Z, value, Instance);
        }
        const Array& args = Array::Handle(Z, Array::New(kNumArgs));
        args.SetAt(0, instance);
        args.SetAt(1, index_obj);
        args.SetAt(2, value_obj);
        return Api::NewHandle(T, DartEntry::InvokeFunction(function, args));
      }
    }
    return Api::NewError("Object does not implement the 'List' interface");
  }
}

static RawObject* ResolveConstructor(const char* current_func,
                                     const Class& cls,
                                     const String& class_name,
                                     const String& dotted_name,
                                     int num_args);

static RawObject* ThrowArgumentError(const char* exception_message) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  // Lookup the class ArgumentError in dart:core.
  const String& lib_url = String::Handle(String::New("dart:core"));
  const String& class_name = String::Handle(String::New("ArgumentError"));
  const Library& lib =
      Library::Handle(zone, Library::LookupLibrary(thread, lib_url));
  if (lib.IsNull()) {
    const String& message = String::Handle(String::NewFormatted(
        "%s: library '%s' not found.", CURRENT_FUNC, lib_url.ToCString()));
    return ApiError::New(message);
  }
  const Class& cls =
      Class::Handle(zone, lib.LookupClassAllowPrivate(class_name));
  ASSERT(!cls.IsNull());
  Object& result = Object::Handle(zone);
  String& dot_name = String::Handle(String::New("."));
  String& constr_name = String::Handle(String::Concat(class_name, dot_name));
  result = ResolveConstructor(CURRENT_FUNC, cls, class_name, constr_name, 1);
  if (result.IsError()) return result.raw();
  ASSERT(result.IsFunction());
  Function& constructor = Function::Handle(zone);
  constructor ^= result.raw();
  if (!constructor.IsGenerativeConstructor()) {
    const String& message = String::Handle(
        String::NewFormatted("%s: class '%s' is not a constructor.",
                             CURRENT_FUNC, class_name.ToCString()));
    return ApiError::New(message);
  }
  Instance& exception = Instance::Handle(zone);
  exception = Instance::New(cls);
  const Array& args = Array::Handle(zone, Array::New(2));
  args.SetAt(0, exception);
  args.SetAt(1, String::Handle(String::New(exception_message)));
  result = DartEntry::InvokeFunction(constructor, args);
  if (result.IsError()) return result.raw();
  ASSERT(result.IsNull());

  if (thread->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    const String& message = String::Handle(
        String::New("No Dart frames on stack, cannot throw exception"));
    return ApiError::New(message);
  }
  // Unwind all the API scopes till the exit frame before throwing an
  // exception.
  const Instance* saved_exception;
  {
    NoSafepointScope no_safepoint;
    RawInstance* raw_exception = exception.raw();
    thread->UnwindScopes(thread->top_exit_frame_info());
    saved_exception = &Instance::Handle(raw_exception);
  }
  Exceptions::Throw(thread, *saved_exception);
  const String& message =
      String::Handle(String::New("Exception was not thrown, internal error"));
  return ApiError::New(message);
}

// TODO(sgjesse): value should always be smaller then 0xff. Add error handling.
#define GET_LIST_ELEMENT_AS_BYTES(type, obj, native_array, offset, length)     \
  const type& array = type::Cast(obj);                                         \
  if (Utils::RangeCheck(offset, length, array.Length())) {                     \
    Object& element = Object::Handle(Z);                                       \
    for (int i = 0; i < length; i++) {                                         \
      element = array.At(offset + i);                                          \
      if (!element.IsInteger()) {                                              \
        return Api::NewHandle(                                                 \
            T, ThrowArgumentError("List contains non-int elements"));          \
      }                                                                        \
      const Integer& integer = Integer::Cast(element);                         \
      native_array[i] = static_cast<uint8_t>(integer.AsInt64Value() & 0xff);   \
      ASSERT(integer.AsInt64Value() <= 0xff);                                  \
    }                                                                          \
    return Api::Success();                                                     \
  }                                                                            \
  return Api::NewError("Invalid length passed in to access array elements");

template <typename T>
static Dart_Handle CopyBytes(const T& array,
                             intptr_t offset,
                             uint8_t* native_array,
                             intptr_t length) {
  ASSERT(array.ElementSizeInBytes() == 1);
  NoSafepointScope no_safepoint;
  memmove(native_array, reinterpret_cast<uint8_t*>(array.DataAddr(offset)),
          length);
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_ListGetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            uint8_t* native_array,
                                            intptr_t length) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsTypedData()) {
    const TypedData& array = TypedData::Cast(obj);
    if (array.ElementSizeInBytes() == 1) {
      if (!Utils::RangeCheck(offset, length, array.Length())) {
        return Api::NewError(
            "Invalid length passed in to access list elements");
      }
      return CopyBytes(array, offset, native_array, length);
    }
  }
  if (obj.IsExternalTypedData()) {
    const ExternalTypedData& external_array = ExternalTypedData::Cast(obj);
    if (external_array.ElementSizeInBytes() == 1) {
      if (!Utils::RangeCheck(offset, length, external_array.Length())) {
        return Api::NewError(
            "Invalid length passed in to access list elements");
      }
      return CopyBytes(external_array, offset, native_array, length);
    }
  }
  if (RawObject::IsTypedDataViewClassId(obj.GetClassId())) {
    const Instance& view = Instance::Cast(obj);
    if (TypedDataView::ElementSizeInBytes(view) == 1) {
      intptr_t view_length = Smi::Value(TypedDataView::Length(view));
      if (!Utils::RangeCheck(offset, length, view_length)) {
        return Api::NewError(
            "Invalid length passed in to access list elements");
      }
      const Instance& data = Instance::Handle(TypedDataView::Data(view));
      if (data.IsTypedData()) {
        const TypedData& array = TypedData::Cast(data);
        if (array.ElementSizeInBytes() == 1) {
          intptr_t data_offset =
              Smi::Value(TypedDataView::OffsetInBytes(view)) + offset;
          // Range check already performed on the view object.
          ASSERT(Utils::RangeCheck(data_offset, length, array.Length()));
          return CopyBytes(array, data_offset, native_array, length);
        }
      }
    }
  }
  if (obj.IsArray()) {
    GET_LIST_ELEMENT_AS_BYTES(Array, obj, native_array, offset, length);
  }
  if (obj.IsGrowableObjectArray()) {
    GET_LIST_ELEMENT_AS_BYTES(GrowableObjectArray, obj, native_array, offset,
                              length);
  }
  if (obj.IsError()) {
    return list;
  }
  CHECK_CALLBACK_STATE(T);

  // Check and handle a dart object that implements the List interface.
  const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
  if (!instance.IsNull()) {
    const int kTypeArgsLen = 0;
    const int kNumArgs = 2;
    ArgumentsDescriptor args_desc(
        Array::Handle(ArgumentsDescriptor::New(kTypeArgsLen, kNumArgs)));
    const Function& function = Function::Handle(
        Z,
        Resolver::ResolveDynamic(instance, Symbols::IndexToken(), args_desc));
    if (!function.IsNull()) {
      Object& result = Object::Handle(Z);
      Integer& intobj = Integer::Handle(Z);
      const Array& args = Array::Handle(Z, Array::New(kNumArgs));
      args.SetAt(0, instance);  // Set up the receiver as the first argument.
      for (int i = 0; i < length; i++) {
        HANDLESCOPE(T);
        intobj = Integer::New(offset + i);
        args.SetAt(1, intobj);
        result = DartEntry::InvokeFunction(function, args);
        if (result.IsError()) {
          return Api::NewHandle(T, result.raw());
        }
        if (!result.IsInteger()) {
          return Api::NewError(
              "%s expects the argument 'list' to be "
              "a List of int",
              CURRENT_FUNC);
        }
        const Integer& integer_result = Integer::Cast(result);
        ASSERT(integer_result.AsInt64Value() <= 0xff);
        // TODO(hpayer): value should always be smaller then 0xff. Add error
        // handling.
        native_array[i] =
            static_cast<uint8_t>(integer_result.AsInt64Value() & 0xff);
      }
      return Api::Success();
    }
  }
  return Api::NewError("Object does not implement the 'List' interface");
}

#define SET_LIST_ELEMENT_AS_BYTES(type, obj, native_array, offset, length)     \
  const type& array = type::Cast(obj);                                         \
  Integer& integer = Integer::Handle(Z);                                       \
  if (Utils::RangeCheck(offset, length, array.Length())) {                     \
    for (int i = 0; i < length; i++) {                                         \
      integer = Integer::New(native_array[i]);                                 \
      array.SetAt(offset + i, integer);                                        \
    }                                                                          \
    return Api::Success();                                                     \
  }                                                                            \
  return Api::NewError("Invalid length passed in to set array elements");

DART_EXPORT Dart_Handle Dart_ListSetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            const uint8_t* native_array,
                                            intptr_t length) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsTypedData()) {
    const TypedData& array = TypedData::Cast(obj);
    if (array.ElementSizeInBytes() == 1) {
      if (Utils::RangeCheck(offset, length, array.Length())) {
        NoSafepointScope no_safepoint;
        memmove(reinterpret_cast<uint8_t*>(array.DataAddr(offset)),
                native_array, length);
        return Api::Success();
      }
      return Api::NewError("Invalid length passed in to access list elements");
    }
  }
  if (obj.IsArray() && !Array::Cast(obj).IsImmutable()) {
    // If the list is immutable we call into Dart for the indexed setter to
    // get the unsupported operation exception as the result.
    SET_LIST_ELEMENT_AS_BYTES(Array, obj, native_array, offset, length);
  }
  if (obj.IsGrowableObjectArray()) {
    SET_LIST_ELEMENT_AS_BYTES(GrowableObjectArray, obj, native_array, offset,
                              length);
  }
  if (obj.IsError()) {
    return list;
  }
  CHECK_CALLBACK_STATE(T);

  // Check and handle a dart object that implements the List interface.
  const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
  if (!instance.IsNull()) {
    const int kTypeArgsLen = 0;
    const int kNumArgs = 3;
    ArgumentsDescriptor args_desc(
        Array::Handle(Z, ArgumentsDescriptor::New(kTypeArgsLen, kNumArgs)));
    const Function& function = Function::Handle(
        Z, Resolver::ResolveDynamic(instance, Symbols::AssignIndexToken(),
                                    args_desc));
    if (!function.IsNull()) {
      Integer& indexobj = Integer::Handle(Z);
      Integer& valueobj = Integer::Handle(Z);
      const Array& args = Array::Handle(Z, Array::New(kNumArgs));
      args.SetAt(0, instance);  // Set up the receiver as the first argument.
      for (int i = 0; i < length; i++) {
        indexobj = Integer::New(offset + i);
        valueobj = Integer::New(native_array[i]);
        args.SetAt(1, indexobj);
        args.SetAt(2, valueobj);
        const Object& result =
            Object::Handle(Z, DartEntry::InvokeFunction(function, args));
        if (result.IsError()) {
          return Api::NewHandle(T, result.raw());
        }
      }
      return Api::Success();
    }
  }
  return Api::NewError("Object does not implement the 'List' interface");
}

// --- Maps ---

DART_EXPORT Dart_Handle Dart_MapGetAt(Dart_Handle map, Dart_Handle key) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(map));
  const Instance& instance = Instance::Handle(Z, GetMapInstance(Z, obj));
  if (!instance.IsNull()) {
    const Object& key_obj = Object::Handle(Api::UnwrapHandle(key));
    if (!(key_obj.IsInstance() || key_obj.IsNull())) {
      return Api::NewError("Key is not an instance");
    }
    return Api::NewHandle(
        T, Send1Arg(instance, Symbols::IndexToken(), Instance::Cast(key_obj)));
  }
  return Api::NewError("Object does not implement the 'Map' interface");
}

DART_EXPORT Dart_Handle Dart_MapContainsKey(Dart_Handle map, Dart_Handle key) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(map));
  const Instance& instance = Instance::Handle(Z, GetMapInstance(Z, obj));
  if (!instance.IsNull()) {
    const Object& key_obj = Object::Handle(Z, Api::UnwrapHandle(key));
    if (!(key_obj.IsInstance() || key_obj.IsNull())) {
      return Api::NewError("Key is not an instance");
    }
    return Api::NewHandle(
        T, Send1Arg(instance, String::Handle(Z, String::New("containsKey")),
                    Instance::Cast(key_obj)));
  }
  return Api::NewError("Object does not implement the 'Map' interface");
}

DART_EXPORT Dart_Handle Dart_MapKeys(Dart_Handle map) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  Object& obj = Object::Handle(Z, Api::UnwrapHandle(map));
  Instance& instance = Instance::Handle(Z, GetMapInstance(Z, obj));
  if (!instance.IsNull()) {
    const Object& iterator = Object::Handle(
        Send0Arg(instance, String::Handle(Z, String::New("get:keys"))));
    if (!iterator.IsInstance()) {
      return Api::NewHandle(T, iterator.raw());
    }
    return Api::NewHandle(T, Send0Arg(Instance::Cast(iterator),
                                      String::Handle(String::New("toList"))));
  }
  return Api::NewError("Object does not implement the 'Map' interface");
}

// --- Typed Data ---

// Helper method to get the type of a TypedData object.
static Dart_TypedData_Type GetType(intptr_t class_id) {
  Dart_TypedData_Type type;
  switch (class_id) {
    case kByteDataViewCid:
      type = Dart_TypedData_kByteData;
      break;
    case kTypedDataInt8ArrayCid:
    case kTypedDataInt8ArrayViewCid:
    case kExternalTypedDataInt8ArrayCid:
      type = Dart_TypedData_kInt8;
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ArrayViewCid:
    case kExternalTypedDataUint8ArrayCid:
      type = Dart_TypedData_kUint8;
      break;
    case kTypedDataUint8ClampedArrayCid:
    case kTypedDataUint8ClampedArrayViewCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      type = Dart_TypedData_kUint8Clamped;
      break;
    case kTypedDataInt16ArrayCid:
    case kTypedDataInt16ArrayViewCid:
    case kExternalTypedDataInt16ArrayCid:
      type = Dart_TypedData_kInt16;
      break;
    case kTypedDataUint16ArrayCid:
    case kTypedDataUint16ArrayViewCid:
    case kExternalTypedDataUint16ArrayCid:
      type = Dart_TypedData_kUint16;
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataInt32ArrayViewCid:
    case kExternalTypedDataInt32ArrayCid:
      type = Dart_TypedData_kInt32;
      break;
    case kTypedDataUint32ArrayCid:
    case kTypedDataUint32ArrayViewCid:
    case kExternalTypedDataUint32ArrayCid:
      type = Dart_TypedData_kUint32;
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataInt64ArrayViewCid:
    case kExternalTypedDataInt64ArrayCid:
      type = Dart_TypedData_kInt64;
      break;
    case kTypedDataUint64ArrayCid:
    case kTypedDataUint64ArrayViewCid:
    case kExternalTypedDataUint64ArrayCid:
      type = Dart_TypedData_kUint64;
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat32ArrayViewCid:
    case kExternalTypedDataFloat32ArrayCid:
      type = Dart_TypedData_kFloat32;
      break;
    case kTypedDataFloat64ArrayCid:
    case kTypedDataFloat64ArrayViewCid:
    case kExternalTypedDataFloat64ArrayCid:
      type = Dart_TypedData_kFloat64;
      break;
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataFloat32x4ArrayViewCid:
    case kExternalTypedDataFloat32x4ArrayCid:
      type = Dart_TypedData_kFloat32x4;
      break;
    default:
      type = Dart_TypedData_kInvalid;
      break;
  }
  return type;
}

DART_EXPORT Dart_TypedData_Type Dart_GetTypeOfTypedData(Dart_Handle object) {
  API_TIMELINE_DURATION;
  intptr_t class_id = Api::ClassId(object);
  if (RawObject::IsTypedDataClassId(class_id) ||
      RawObject::IsTypedDataViewClassId(class_id)) {
    return GetType(class_id);
  }
  return Dart_TypedData_kInvalid;
}

DART_EXPORT Dart_TypedData_Type
Dart_GetTypeOfExternalTypedData(Dart_Handle object) {
  API_TIMELINE_DURATION;
  intptr_t class_id = Api::ClassId(object);
  if (RawObject::IsExternalTypedDataClassId(class_id)) {
    return GetType(class_id);
  }
  if (RawObject::IsTypedDataViewClassId(class_id)) {
    // Check if data object of the view is external.
    Zone* zone = Thread::Current()->zone();
    const Instance& view_obj = Api::UnwrapInstanceHandle(zone, object);
    ASSERT(!view_obj.IsNull());
    const Instance& data_obj =
        Instance::Handle(zone, TypedDataView::Data(view_obj));
    if (ExternalTypedData::IsExternalTypedData(data_obj)) {
      return GetType(class_id);
    }
  }
  return Dart_TypedData_kInvalid;
}

static RawObject* GetByteDataConstructor(Thread* thread,
                                         const String& constructor_name,
                                         intptr_t num_args) {
  const Library& lib =
      Library::Handle(thread->isolate()->object_store()->typed_data_library());
  ASSERT(!lib.IsNull());
  const Class& cls = Class::Handle(
      thread->zone(), lib.LookupClassAllowPrivate(Symbols::ByteData()));
  ASSERT(!cls.IsNull());
  return ResolveConstructor(CURRENT_FUNC, cls, Symbols::ByteData(),
                            constructor_name, num_args);
}

static Dart_Handle NewByteData(Thread* thread, intptr_t length) {
  CHECK_LENGTH(length, TypedData::MaxElements(kTypedDataInt8ArrayCid));
  Zone* zone = thread->zone();
  Object& result = Object::Handle(zone);
  result = GetByteDataConstructor(thread, Symbols::ByteDataDot(), 1);
  ASSERT(!result.IsNull());
  ASSERT(result.IsFunction());
  const Function& factory = Function::Cast(result);
  ASSERT(!factory.IsGenerativeConstructor());

  // Create the argument list.
  const Array& args = Array::Handle(zone, Array::New(2));
  // Factories get type arguments.
  args.SetAt(0, Object::null_type_arguments());
  args.SetAt(1, Smi::Handle(zone, Smi::New(length)));

  // Invoke the constructor and return the new object.
  result = DartEntry::InvokeFunction(factory, args);
  ASSERT(result.IsInstance() || result.IsNull() || result.IsError());
  return Api::NewHandle(thread, result.raw());
}

static Dart_Handle NewTypedData(Thread* thread, intptr_t cid, intptr_t length) {
  CHECK_LENGTH(length, TypedData::MaxElements(cid));
  return Api::NewHandle(thread, TypedData::New(cid, length));
}

static Dart_Handle NewExternalTypedData(Thread* thread,
                                        intptr_t cid,
                                        void* data,
                                        intptr_t length) {
  CHECK_LENGTH(length, ExternalTypedData::MaxElements(cid));
  Zone* zone = thread->zone();
  intptr_t bytes = length * ExternalTypedData::ElementSizeInBytes(cid);
  const ExternalTypedData& result = ExternalTypedData::Handle(
      zone, ExternalTypedData::New(cid, reinterpret_cast<uint8_t*>(data),
                                   length, SpaceForExternal(thread, bytes)));
  return Api::NewHandle(thread, result.raw());
}

static Dart_Handle NewExternalByteData(Thread* thread,
                                       void* data,
                                       intptr_t length) {
  Zone* zone = thread->zone();
  Dart_Handle ext_data = NewExternalTypedData(
      thread, kExternalTypedDataUint8ArrayCid, data, length);
  if (::Dart_IsError(ext_data)) {
    return ext_data;
  }
  Object& result = Object::Handle(zone);
  result = GetByteDataConstructor(thread, Symbols::ByteDataDot_view(), 3);
  ASSERT(!result.IsNull());
  ASSERT(result.IsFunction());
  const Function& factory = Function::Cast(result);
  ASSERT(!factory.IsGenerativeConstructor());

  // Create the argument list.
  const intptr_t num_args = 3;
  const Array& args = Array::Handle(zone, Array::New(num_args + 1));
  // Factories get type arguments.
  args.SetAt(0, Object::null_type_arguments());
  const ExternalTypedData& array =
      Api::UnwrapExternalTypedDataHandle(zone, ext_data);
  args.SetAt(1, array);
  Smi& smi = Smi::Handle(zone);
  smi = Smi::New(0);
  args.SetAt(2, smi);
  smi = Smi::New(length);
  args.SetAt(3, smi);

  // Invoke the constructor and return the new object.
  result = DartEntry::InvokeFunction(factory, args);
  ASSERT(result.IsNull() || result.IsInstance() || result.IsError());
  return Api::NewHandle(thread, result.raw());
}

DART_EXPORT Dart_Handle Dart_NewTypedData(Dart_TypedData_Type type,
                                          intptr_t length) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  switch (type) {
    case Dart_TypedData_kByteData:
      return NewByteData(T, length);
    case Dart_TypedData_kInt8:
      return NewTypedData(T, kTypedDataInt8ArrayCid, length);
    case Dart_TypedData_kUint8:
      return NewTypedData(T, kTypedDataUint8ArrayCid, length);
    case Dart_TypedData_kUint8Clamped:
      return NewTypedData(T, kTypedDataUint8ClampedArrayCid, length);
    case Dart_TypedData_kInt16:
      return NewTypedData(T, kTypedDataInt16ArrayCid, length);
    case Dart_TypedData_kUint16:
      return NewTypedData(T, kTypedDataUint16ArrayCid, length);
    case Dart_TypedData_kInt32:
      return NewTypedData(T, kTypedDataInt32ArrayCid, length);
    case Dart_TypedData_kUint32:
      return NewTypedData(T, kTypedDataUint32ArrayCid, length);
    case Dart_TypedData_kInt64:
      return NewTypedData(T, kTypedDataInt64ArrayCid, length);
    case Dart_TypedData_kUint64:
      return NewTypedData(T, kTypedDataUint64ArrayCid, length);
    case Dart_TypedData_kFloat32:
      return NewTypedData(T, kTypedDataFloat32ArrayCid, length);
    case Dart_TypedData_kFloat64:
      return NewTypedData(T, kTypedDataFloat64ArrayCid, length);
    case Dart_TypedData_kFloat32x4:
      return NewTypedData(T, kTypedDataFloat32x4ArrayCid, length);
    default:
      return Api::NewError("%s expects argument 'type' to be of 'TypedData'",
                           CURRENT_FUNC);
  }
  UNREACHABLE();
  return Api::Null();
}

DART_EXPORT Dart_Handle Dart_NewExternalTypedData(Dart_TypedData_Type type,
                                                  void* data,
                                                  intptr_t length) {
  DARTSCOPE(Thread::Current());
  if (data == NULL && length != 0) {
    RETURN_NULL_ERROR(data);
  }
  CHECK_CALLBACK_STATE(T);
  switch (type) {
    case Dart_TypedData_kByteData:
      return NewExternalByteData(T, data, length);
    case Dart_TypedData_kInt8:
      return NewExternalTypedData(T, kExternalTypedDataInt8ArrayCid, data,
                                  length);
    case Dart_TypedData_kUint8:
      return NewExternalTypedData(T, kExternalTypedDataUint8ArrayCid, data,
                                  length);
    case Dart_TypedData_kUint8Clamped:
      return NewExternalTypedData(T, kExternalTypedDataUint8ClampedArrayCid,
                                  data, length);
    case Dart_TypedData_kInt16:
      return NewExternalTypedData(T, kExternalTypedDataInt16ArrayCid, data,
                                  length);
    case Dart_TypedData_kUint16:
      return NewExternalTypedData(T, kExternalTypedDataUint16ArrayCid, data,
                                  length);
    case Dart_TypedData_kInt32:
      return NewExternalTypedData(T, kExternalTypedDataInt32ArrayCid, data,
                                  length);
    case Dart_TypedData_kUint32:
      return NewExternalTypedData(T, kExternalTypedDataUint32ArrayCid, data,
                                  length);
    case Dart_TypedData_kInt64:
      return NewExternalTypedData(T, kExternalTypedDataInt64ArrayCid, data,
                                  length);
    case Dart_TypedData_kUint64:
      return NewExternalTypedData(T, kExternalTypedDataUint64ArrayCid, data,
                                  length);
    case Dart_TypedData_kFloat32:
      return NewExternalTypedData(T, kExternalTypedDataFloat32ArrayCid, data,
                                  length);
    case Dart_TypedData_kFloat64:
      return NewExternalTypedData(T, kExternalTypedDataFloat64ArrayCid, data,
                                  length);
    case Dart_TypedData_kFloat32x4:
      return NewExternalTypedData(T, kExternalTypedDataFloat32x4ArrayCid, data,
                                  length);
    default:
      return Api::NewError(
          "%s expects argument 'type' to be of"
          " 'external TypedData'",
          CURRENT_FUNC);
  }
  UNREACHABLE();
  return Api::Null();
}

static RawObject* GetByteBufferConstructor(Thread* thread,
                                           const String& class_name,
                                           const String& constructor_name,
                                           intptr_t num_args) {
  const Library& lib =
      Library::Handle(thread->isolate()->object_store()->typed_data_library());
  ASSERT(!lib.IsNull());
  const Class& cls =
      Class::Handle(thread->zone(), lib.LookupClassAllowPrivate(class_name));
  ASSERT(!cls.IsNull());
  return ResolveConstructor(CURRENT_FUNC, cls, class_name, constructor_name,
                            num_args);
}

DART_EXPORT Dart_Handle Dart_NewByteBuffer(Dart_Handle typed_data) {
  DARTSCOPE(Thread::Current());
  intptr_t class_id = Api::ClassId(typed_data);
  if (!RawObject::IsExternalTypedDataClassId(class_id) &&
      !RawObject::IsTypedDataViewClassId(class_id) &&
      !RawObject::IsTypedDataClassId(class_id)) {
    RETURN_TYPE_ERROR(Z, typed_data, 'TypedData');
  }
  Object& result = Object::Handle(Z);
  result = GetByteBufferConstructor(T, Symbols::_ByteBuffer(),
                                    Symbols::_ByteBufferDot_New(), 1);
  ASSERT(!result.IsNull());
  ASSERT(result.IsFunction());
  const Function& factory = Function::Cast(result);
  ASSERT(!factory.IsGenerativeConstructor());

  // Create the argument list.
  const Array& args = Array::Handle(Z, Array::New(2));
  // Factories get type arguments.
  args.SetAt(0, Object::null_type_arguments());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(typed_data));
  args.SetAt(1, obj);

  // Invoke the factory constructor and return the new object.
  result = DartEntry::InvokeFunction(factory, args);
  ASSERT(result.IsInstance() || result.IsNull() || result.IsError());
  return Api::NewHandle(T, result.raw());
}

// Structure to record acquired typed data for verification purposes.
class AcquiredData {
 public:
  AcquiredData(void* data, intptr_t size_in_bytes, bool copy)
      : size_in_bytes_(size_in_bytes), data_(data), data_copy_(NULL) {
    if (copy) {
      data_copy_ = malloc(size_in_bytes_);
      memmove(data_copy_, data_, size_in_bytes_);
    }
  }

  // The pointer to hand out via the API.
  void* GetData() const { return data_copy_ != NULL ? data_copy_ : data_; }

  // Writes back and deletes/zaps, if a copy was made.
  ~AcquiredData() {
    if (data_copy_ != NULL) {
      memmove(data_, data_copy_, size_in_bytes_);
      memset(data_copy_, kZapReleasedByte, size_in_bytes_);
      free(data_copy_);
    }
  }

 private:
  static const uint8_t kZapReleasedByte = 0xda;
  intptr_t size_in_bytes_;
  void* data_;
  void* data_copy_;

  DISALLOW_COPY_AND_ASSIGN(AcquiredData);
};

DART_EXPORT Dart_Handle Dart_TypedDataAcquireData(Dart_Handle object,
                                                  Dart_TypedData_Type* type,
                                                  void** data,
                                                  intptr_t* len) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  intptr_t class_id = Api::ClassId(object);
  if (!RawObject::IsExternalTypedDataClassId(class_id) &&
      !RawObject::IsTypedDataViewClassId(class_id) &&
      !RawObject::IsTypedDataClassId(class_id)) {
    RETURN_TYPE_ERROR(Z, object, 'TypedData');
  }
  if (type == NULL) {
    RETURN_NULL_ERROR(type);
  }
  if (data == NULL) {
    RETURN_NULL_ERROR(data);
  }
  if (len == NULL) {
    RETURN_NULL_ERROR(len);
  }
  // Get the type of typed data object.
  *type = GetType(class_id);
  intptr_t length = 0;
  intptr_t size_in_bytes = 0;
  void* data_tmp = NULL;
  bool external = false;
  // If it is an external typed data object just return the data field.
  if (RawObject::IsExternalTypedDataClassId(class_id)) {
    const ExternalTypedData& obj =
        Api::UnwrapExternalTypedDataHandle(Z, object);
    ASSERT(!obj.IsNull());
    length = obj.Length();
    size_in_bytes = length * ExternalTypedData::ElementSizeInBytes(class_id);
    data_tmp = obj.DataAddr(0);
    external = true;
  } else if (RawObject::IsTypedDataClassId(class_id)) {
    // Regular typed data object, set up some GC and API callback guards.
    const TypedData& obj = Api::UnwrapTypedDataHandle(Z, object);
    ASSERT(!obj.IsNull());
    length = obj.Length();
    size_in_bytes = length * TypedData::ElementSizeInBytes(class_id);
    T->IncrementNoSafepointScopeDepth();
    START_NO_CALLBACK_SCOPE(T);
    data_tmp = obj.DataAddr(0);
  } else {
    ASSERT(RawObject::IsTypedDataViewClassId(class_id));
    const Instance& view_obj = Api::UnwrapInstanceHandle(Z, object);
    ASSERT(!view_obj.IsNull());
    Smi& val = Smi::Handle();
    val ^= TypedDataView::Length(view_obj);
    length = val.Value();
    size_in_bytes = length * TypedDataView::ElementSizeInBytes(class_id);
    val ^= TypedDataView::OffsetInBytes(view_obj);
    intptr_t offset_in_bytes = val.Value();
    const Instance& obj = Instance::Handle(TypedDataView::Data(view_obj));
    T->IncrementNoSafepointScopeDepth();
    START_NO_CALLBACK_SCOPE(T);
    if (TypedData::IsTypedData(obj)) {
      const TypedData& data_obj = TypedData::Cast(obj);
      data_tmp = data_obj.DataAddr(offset_in_bytes);
    } else {
      ASSERT(ExternalTypedData::IsExternalTypedData(obj));
      const ExternalTypedData& data_obj = ExternalTypedData::Cast(obj);
      data_tmp = data_obj.DataAddr(offset_in_bytes);
      external = true;
    }
  }
  if (FLAG_verify_acquired_data) {
    if (external) {
      ASSERT(!I->heap()->Contains(reinterpret_cast<uword>(data_tmp)));
    } else {
      ASSERT(I->heap()->Contains(reinterpret_cast<uword>(data_tmp)));
    }
    const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
    WeakTable* table = I->api_state()->acquired_table();
    intptr_t current = table->GetValue(obj.raw());
    if (current != 0) {
      return Api::NewError("Data was already acquired for this object.");
    }
    // Do not make a copy if the data is external. Some callers expect external
    // data to remain in place, even though the API spec doesn't guarantee it.
    // TODO(koda/asiva): Make final decision and document it.
    AcquiredData* ad = new AcquiredData(data_tmp, size_in_bytes, !external);
    table->SetValue(obj.raw(), reinterpret_cast<intptr_t>(ad));
    data_tmp = ad->GetData();
  }
  *data = data_tmp;
  *len = length;
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_TypedDataReleaseData(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  intptr_t class_id = Api::ClassId(object);
  if (!RawObject::IsExternalTypedDataClassId(class_id) &&
      !RawObject::IsTypedDataViewClassId(class_id) &&
      !RawObject::IsTypedDataClassId(class_id)) {
    RETURN_TYPE_ERROR(Z, object, 'TypedData');
  }
  if (!RawObject::IsExternalTypedDataClassId(class_id)) {
    T->DecrementNoSafepointScopeDepth();
    END_NO_CALLBACK_SCOPE(T);
  }
  if (FLAG_verify_acquired_data) {
    const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
    WeakTable* table = I->api_state()->acquired_table();
    intptr_t current = table->GetValue(obj.raw());
    if (current == 0) {
      return Api::NewError("Data was not acquired for this object.");
    }
    AcquiredData* ad = reinterpret_cast<AcquiredData*>(current);
    table->SetValue(obj.raw(), 0);  // Delete entry from table.
    delete ad;
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetDataFromByteBuffer(Dart_Handle object) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  intptr_t class_id = Api::ClassId(object);
  if (class_id != kByteBufferCid) {
    RETURN_TYPE_ERROR(zone, object, 'ByteBuffer');
  }
  const Instance& instance = Api::UnwrapInstanceHandle(zone, object);
  ASSERT(!instance.IsNull());
  return Api::NewHandle(thread, ByteBuffer::Data(instance));
}

// ---  Invoking Constructors, Methods, and Field accessors ---

static RawObject* ResolveConstructor(const char* current_func,
                                     const Class& cls,
                                     const String& class_name,
                                     const String& constr_name,
                                     int num_args) {
  // The constructor must be present in the interface.
  const Function& constructor =
      Function::Handle(cls.LookupFunctionAllowPrivate(constr_name));
  if (constructor.IsNull() ||
      (!constructor.IsGenerativeConstructor() && !constructor.IsFactory())) {
    const String& lookup_class_name = String::Handle(cls.Name());
    if (!class_name.Equals(lookup_class_name)) {
      // When the class name used to build the constructor name is
      // different than the name of the class in which we are doing
      // the lookup, it can be confusing to the user to figure out
      // what's going on.  Be a little more explicit for these error
      // messages.
      const String& message = String::Handle(String::NewFormatted(
          "%s: could not find factory '%s' in class '%s'.", current_func,
          constr_name.ToCString(), lookup_class_name.ToCString()));
      return ApiError::New(message);
    } else {
      const String& message = String::Handle(
          String::NewFormatted("%s: could not find constructor '%s'.",
                               current_func, constr_name.ToCString()));
      return ApiError::New(message);
    }
  }
  const int kTypeArgsLen = 0;
  const int extra_args = 1;
  String& error_message = String::Handle();
  if (!constructor.AreValidArgumentCounts(kTypeArgsLen, num_args + extra_args,
                                          0, &error_message)) {
    const String& message = String::Handle(String::NewFormatted(
        "%s: wrong argument count for "
        "constructor '%s': %s.",
        current_func, constr_name.ToCString(), error_message.ToCString()));
    return ApiError::New(message);
  }
  return constructor.raw();
}

DART_EXPORT Dart_Handle Dart_New(Dart_Handle type,
                                 Dart_Handle constructor_name,
                                 int number_of_arguments,
                                 Dart_Handle* arguments) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  Object& result = Object::Handle(Z);

  if (number_of_arguments < 0) {
    return Api::NewError(
        "%s expects argument 'number_of_arguments' to be non-negative.",
        CURRENT_FUNC);
  }

  // Get the class to instantiate.
  Object& unchecked_type = Object::Handle(Api::UnwrapHandle(type));
  if (unchecked_type.IsNull() || !unchecked_type.IsType()) {
    RETURN_TYPE_ERROR(Z, type, Type);
  }
  Type& type_obj = Type::Handle();
  type_obj ^= unchecked_type.raw();
  if (!type_obj.IsFinalized()) {
    return Api::NewError(
        "%s expects argument 'type' to be a fully resolved type.",
        CURRENT_FUNC);
  }
  Class& cls = Class::Handle(Z, type_obj.type_class());
  TypeArguments& type_arguments =
      TypeArguments::Handle(Z, type_obj.arguments());

  const String& base_constructor_name = String::Handle(Z, cls.Name());

  // And get the name of the constructor to invoke.
  String& dot_name = String::Handle(Z);
  result = Api::UnwrapHandle(constructor_name);
  if (result.IsNull()) {
    dot_name = Symbols::Dot().raw();
  } else if (result.IsString()) {
    dot_name = String::Concat(Symbols::Dot(), String::Cast(result));
  } else {
    RETURN_TYPE_ERROR(Z, constructor_name, String);
  }

  // Resolve the constructor.
  String& constr_name =
      String::Handle(String::Concat(base_constructor_name, dot_name));
  result = ResolveConstructor("Dart_New", cls, base_constructor_name,
                              constr_name, number_of_arguments);
  if (result.IsError()) {
    return Api::NewHandle(T, result.raw());
  }
  ASSERT(result.IsFunction());
  Function& constructor = Function::Handle(Z);
  constructor ^= result.raw();

  Instance& new_object = Instance::Handle(Z);
  if (constructor.IsRedirectingFactory()) {
    ClassFinalizer::ResolveRedirectingFactory(cls, constructor);
    Type& redirect_type = Type::Handle(constructor.RedirectionType());
    constructor = constructor.RedirectionTarget();
    if (constructor.IsNull()) {
      ASSERT(redirect_type.IsMalformed());
      return Api::NewHandle(T, redirect_type.error());
    }

    if (!redirect_type.IsInstantiated()) {
      // The type arguments of the redirection type are instantiated from the
      // type arguments of the type argument.
      // We do not support generic constructors.
      ASSERT(redirect_type.IsInstantiated(kFunctions));
      Error& bound_error = Error::Handle();
      redirect_type ^= redirect_type.InstantiateFrom(
          type_arguments, Object::null_type_arguments(), &bound_error, NULL,
          NULL, Heap::kNew);
      if (!bound_error.IsNull()) {
        return Api::NewHandle(T, bound_error.raw());
      }
      redirect_type ^= redirect_type.Canonicalize();
    }

    type_obj = redirect_type.raw();
    type_arguments = redirect_type.arguments();

    cls = type_obj.type_class();
  }
  if (constructor.IsGenerativeConstructor()) {
#if defined(DEBUG)
    if (!cls.is_allocated() &&
        (Dart::vm_snapshot_kind() == Snapshot::kFullAOT)) {
      return Api::NewError("Precompilation dropped '%s'", cls.ToCString());
    }
#endif
    // Create the new object.
    new_object = Instance::New(cls);
  }

  // Create the argument list.
  intptr_t arg_index = 0;
  int extra_args = 1;
  const Array& args =
      Array::Handle(Z, Array::New(number_of_arguments + extra_args));
  if (constructor.IsGenerativeConstructor()) {
    // Constructors get the uninitialized object.
    if (!type_arguments.IsNull()) {
      // The type arguments will be null if the class has no type parameters, in
      // which case the following call would fail because there is no slot
      // reserved in the object for the type vector.
      new_object.SetTypeArguments(type_arguments);
    }
    args.SetAt(arg_index++, new_object);
  } else {
    // Factories get type arguments.
    args.SetAt(arg_index++, type_arguments);
  }
  Object& argument = Object::Handle(Z);
  for (int i = 0; i < number_of_arguments; i++) {
    argument = Api::UnwrapHandle(arguments[i]);
    if (!argument.IsNull() && !argument.IsInstance()) {
      if (argument.IsError()) {
        return Api::NewHandle(T, argument.raw());
      } else {
        return Api::NewError(
            "%s expects arguments[%d] to be an Instance handle.", CURRENT_FUNC,
            i);
      }
    }
    args.SetAt(arg_index++, argument);
  }

  // Invoke the constructor and return the new object.
  result = DartEntry::InvokeFunction(constructor, args);
  if (result.IsError()) {
    return Api::NewHandle(T, result.raw());
  }

  if (constructor.IsGenerativeConstructor()) {
    ASSERT(result.IsNull());
  } else {
    ASSERT(result.IsNull() || result.IsInstance());
    new_object ^= result.raw();
  }
  return Api::NewHandle(T, new_object.raw());
}

static RawInstance* AllocateObject(Thread* thread, const Class& cls) {
  if (!cls.is_fields_marked_nullable()) {
    // Mark all fields as nullable.
    Zone* zone = thread->zone();
    Class& iterate_cls = Class::Handle(zone, cls.raw());
    Field& field = Field::Handle(zone);
    Array& fields = Array::Handle(zone);
    while (!iterate_cls.IsNull()) {
      ASSERT(iterate_cls.is_finalized());
      iterate_cls.set_is_fields_marked_nullable();
      fields = iterate_cls.fields();
      iterate_cls = iterate_cls.SuperClass();
      for (int field_num = 0; field_num < fields.Length(); field_num++) {
        field ^= fields.At(field_num);
        if (field.is_static()) {
          continue;
        }
        field.RecordStore(Object::null_object());
      }
    }
  }

  // Allocate an object for the given class.
  return Instance::New(cls);
}

DART_EXPORT Dart_Handle Dart_Allocate(Dart_Handle type) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  const Type& type_obj = Api::UnwrapTypeHandle(Z, type);
  // Get the class to instantiate.
  if (type_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, type, Type);
  }
  const Class& cls = Class::Handle(Z, type_obj.type_class());
#if defined(DEBUG)
  if (!cls.is_allocated() && (Dart::vm_snapshot_kind() == Snapshot::kFullAOT)) {
    return Api::NewError("Precompilation dropped '%s'", cls.ToCString());
  }
#endif
  const Error& error = Error::Handle(Z, cls.EnsureIsFinalized(T));
  if (!error.IsNull()) {
    // An error occurred, return error object.
    return Api::NewHandle(T, error.raw());
  }
  return Api::NewHandle(T, AllocateObject(T, cls));
}

DART_EXPORT Dart_Handle
Dart_AllocateWithNativeFields(Dart_Handle type,
                              intptr_t num_native_fields,
                              const intptr_t* native_fields) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  const Type& type_obj = Api::UnwrapTypeHandle(Z, type);
  // Get the class to instantiate.
  if (type_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, type, Type);
  }
  if (native_fields == NULL) {
    RETURN_NULL_ERROR(native_fields);
  }
  const Class& cls = Class::Handle(Z, type_obj.type_class());
#if defined(DEBUG)
  if (!cls.is_allocated() && (Dart::vm_snapshot_kind() == Snapshot::kFullAOT)) {
    return Api::NewError("Precompilation dropped '%s'", cls.ToCString());
  }
#endif
  const Error& error = Error::Handle(Z, cls.EnsureIsFinalized(T));
  if (!error.IsNull()) {
    // An error occurred, return error object.
    return Api::NewHandle(T, error.raw());
  }
  if (num_native_fields != cls.num_native_fields()) {
    return Api::NewError(
        "%s: invalid number of native fields %" Pd " passed in, expected %d",
        CURRENT_FUNC, num_native_fields, cls.num_native_fields());
  }
  const Instance& instance = Instance::Handle(Z, AllocateObject(T, cls));
  instance.SetNativeFields(num_native_fields, native_fields);
  return Api::NewHandle(T, instance.raw());
}

static Dart_Handle SetupArguments(Thread* thread,
                                  int num_args,
                                  Dart_Handle* arguments,
                                  int extra_args,
                                  Array* args) {
  Zone* zone = thread->zone();
  // Check for malformed arguments in the arguments list.
  *args = Array::New(num_args + extra_args);
  Object& arg = Object::Handle(zone);
  for (int i = 0; i < num_args; i++) {
    arg = Api::UnwrapHandle(arguments[i]);
    if (!arg.IsNull() && !arg.IsInstance()) {
      *args = Array::null();
      if (arg.IsError()) {
        return Api::NewHandle(thread, arg.raw());
      } else {
        return Api::NewError(
            "%s expects arguments[%d] to be an Instance handle.", "Dart_Invoke",
            i);
      }
    }
    args->SetAt((i + extra_args), arg);
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_InvokeConstructor(Dart_Handle object,
                                               Dart_Handle name,
                                               int number_of_arguments,
                                               Dart_Handle* arguments) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  if (number_of_arguments < 0) {
    return Api::NewError(
        "%s expects argument 'number_of_arguments' to be non-negative.",
        CURRENT_FUNC);
  }
  const Instance& instance = Api::UnwrapInstanceHandle(Z, object);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(Z, object, Instance);
  }

  // Since we have allocated an object it would mean that the type
  // is finalized.
  // TODO(asiva): How do we ensure that a constructor is not called more than
  // once for the same object.

  // Construct name of the constructor to invoke.
  const String& constructor_name = Api::UnwrapStringHandle(Z, name);
  const AbstractType& type_obj =
      AbstractType::Handle(Z, instance.GetType(Heap::kNew));
  const Class& cls = Class::Handle(Z, type_obj.type_class());
  const String& class_name = String::Handle(Z, cls.Name());
  const Array& strings = Array::Handle(Z, Array::New(3));
  strings.SetAt(0, class_name);
  strings.SetAt(1, Symbols::Dot());
  if (constructor_name.IsNull()) {
    strings.SetAt(2, Symbols::Empty());
  } else {
    strings.SetAt(2, constructor_name);
  }
  const String& dot_name = String::Handle(Z, String::ConcatAll(strings));
  const TypeArguments& type_arguments =
      TypeArguments::Handle(Z, type_obj.arguments());
  const Function& constructor =
      Function::Handle(Z, cls.LookupFunctionAllowPrivate(dot_name));
  const int kTypeArgsLen = 0;
  const int extra_args = 1;
  if (!constructor.IsNull() && constructor.IsGenerativeConstructor() &&
      constructor.AreValidArgumentCounts(
          kTypeArgsLen, number_of_arguments + extra_args, 0, NULL)) {
    // Create the argument list.
    // Constructors get the uninitialized object.
    if (!type_arguments.IsNull()) {
      // The type arguments will be null if the class has no type
      // parameters, in which case the following call would fail
      // because there is no slot reserved in the object for the
      // type vector.
      instance.SetTypeArguments(type_arguments);
    }
    Dart_Handle result;
    Array& args = Array::Handle(Z);
    result =
        SetupArguments(T, number_of_arguments, arguments, extra_args, &args);
    if (!::Dart_IsError(result)) {
      args.SetAt(0, instance);
      const Object& retval =
          Object::Handle(Z, DartEntry::InvokeFunction(constructor, args));
      if (retval.IsError()) {
        result = Api::NewHandle(T, retval.raw());
      } else {
        result = Api::NewHandle(T, instance.raw());
      }
    }
    return result;
  }
  return Api::NewError("%s expects argument 'name' to be a valid constructor.",
                       CURRENT_FUNC);
}

DART_EXPORT Dart_Handle Dart_Invoke(Dart_Handle target,
                                    Dart_Handle name,
                                    int number_of_arguments,
                                    Dart_Handle* arguments) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  const String& function_name = Api::UnwrapStringHandle(Z, name);
  if (function_name.IsNull()) {
    RETURN_TYPE_ERROR(Z, name, String);
  }
  if (number_of_arguments < 0) {
    return Api::NewError(
        "%s expects argument 'number_of_arguments' to be non-negative.",
        CURRENT_FUNC);
  }
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(target));
  if (obj.IsError()) {
    return target;
  }
  Dart_Handle result;
  Array& args = Array::Handle(Z);
  const intptr_t kTypeArgsLen = 0;
  if (obj.IsType()) {
    if (!Type::Cast(obj).IsFinalized()) {
      return Api::NewError(
          "%s expects argument 'target' to be a fully resolved type.",
          CURRENT_FUNC);
    }

    const Class& cls = Class::Handle(Z, Type::Cast(obj).type_class());
    const Function& function =
        Function::Handle(Z, Resolver::ResolveStaticAllowPrivate(
                                cls, function_name, kTypeArgsLen,
                                number_of_arguments, Object::empty_array()));
    if (function.IsNull()) {
      const String& cls_name = String::Handle(Z, cls.Name());
      return Api::NewError("%s: did not find static method '%s.%s'.",
                           CURRENT_FUNC, cls_name.ToCString(),
                           function_name.ToCString());
    }
#if !defined(PRODUCT)
    if (tds.enabled()) {
      const String& cls_name = String::Handle(Z, cls.Name());
      tds.SetNumArguments(1);
      tds.FormatArgument(0, "name", "%s.%s", cls_name.ToCString(),
                         function_name.ToCString());
    }
#endif  // !defined(PRODUCT)
    // Setup args and check for malformed arguments in the arguments list.
    result = SetupArguments(T, number_of_arguments, arguments, 0, &args);
    if (!::Dart_IsError(result)) {
      result = Api::NewHandle(T, DartEntry::InvokeFunction(function, args));
    }
    return result;
  } else if (obj.IsNull() || obj.IsInstance()) {
    // Since we have allocated an object it would mean that the type of the
    // receiver is already resolved and finalized, hence it is not necessary
    // to check here.
    Instance& instance = Instance::Handle(Z);
    instance ^= obj.raw();
    ArgumentsDescriptor args_desc(Array::Handle(
        Z, ArgumentsDescriptor::New(kTypeArgsLen, number_of_arguments + 1)));
    const Function& function = Function::Handle(
        Z, Resolver::ResolveDynamic(instance, function_name, args_desc));
    if (function.IsNull()) {
      // Setup args and check for malformed arguments in the arguments list.
      result = SetupArguments(T, number_of_arguments, arguments, 1, &args);
      if (!::Dart_IsError(result)) {
        args.SetAt(0, instance);
        const Array& args_descriptor = Array::Handle(
            Z, ArgumentsDescriptor::New(kTypeArgsLen, args.Length()));
        result = Api::NewHandle(
            T, DartEntry::InvokeNoSuchMethod(instance, function_name, args,
                                             args_descriptor));
      }
      return result;
    }
#if !defined(PRODUCT)
    if (tds.enabled()) {
      const Class& cls = Class::Handle(Z, instance.clazz());
      ASSERT(!cls.IsNull());
      const String& cls_name = String::Handle(Z, cls.Name());
      tds.SetNumArguments(1);
      tds.FormatArgument(0, "name", "%s.%s", cls_name.ToCString(),
                         function_name.ToCString());
    }
#endif  // !defined(PRODUCT)
    // Setup args and check for malformed arguments in the arguments list.
    result = SetupArguments(T, number_of_arguments, arguments, 1, &args);
    if (!::Dart_IsError(result)) {
      args.SetAt(0, instance);
      result = Api::NewHandle(T, DartEntry::InvokeFunction(function, args));
    }
    return result;
  } else if (obj.IsLibrary()) {
    // Check whether class finalization is needed.
    const Library& lib = Library::Cast(obj);

    // Check that the library is loaded.
    if (!lib.Loaded()) {
      return Api::NewError("%s expects library argument 'target' to be loaded.",
                           CURRENT_FUNC);
    }

    const Function& function =
        Function::Handle(Z, lib.LookupFunctionAllowPrivate(function_name));
    if (function.IsNull()) {
      return Api::NewError("%s: did not find top-level function '%s'.",
                           CURRENT_FUNC, function_name.ToCString());
    }

#if !defined(PRODUCT)
    if (tds.enabled()) {
      const String& lib_name = String::Handle(Z, lib.url());
      tds.SetNumArguments(1);
      tds.FormatArgument(0, "name", "%s.%s", lib_name.ToCString(),
                         function_name.ToCString());
    }
#endif  // !defined(PRODUCT)

    // LookupFunctionAllowPrivate does not check argument arity, so we
    // do it here.
    String& error_message = String::Handle(Z);
    if (!function.AreValidArgumentCounts(kTypeArgsLen, number_of_arguments, 0,
                                         &error_message)) {
      return Api::NewError("%s: wrong argument count for function '%s': %s.",
                           CURRENT_FUNC, function_name.ToCString(),
                           error_message.ToCString());
    }
    // Setup args and check for malformed arguments in the arguments list.
    result = SetupArguments(T, number_of_arguments, arguments, 0, &args);
    if (!::Dart_IsError(result)) {
      result = Api::NewHandle(T, DartEntry::InvokeFunction(function, args));
    }
    return result;
  } else {
    return Api::NewError(
        "%s expects argument 'target' to be an object, type, or library.",
        CURRENT_FUNC);
  }
}

DART_EXPORT Dart_Handle Dart_InvokeClosure(Dart_Handle closure,
                                           int number_of_arguments,
                                           Dart_Handle* arguments) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  const Instance& closure_obj = Api::UnwrapInstanceHandle(Z, closure);
  if (closure_obj.IsNull() || !closure_obj.IsCallable(NULL)) {
    RETURN_TYPE_ERROR(Z, closure, Instance);
  }
  if (number_of_arguments < 0) {
    return Api::NewError(
        "%s expects argument 'number_of_arguments' to be non-negative.",
        CURRENT_FUNC);
  }

  // Set up arguments to include the closure as the first argument.
  const Array& args = Array::Handle(Z, Array::New(number_of_arguments + 1));
  Object& obj = Object::Handle(Z);
  args.SetAt(0, closure_obj);
  for (int i = 0; i < number_of_arguments; i++) {
    obj = Api::UnwrapHandle(arguments[i]);
    if (!obj.IsNull() && !obj.IsInstance()) {
      RETURN_TYPE_ERROR(Z, arguments[i], Instance);
    }
    args.SetAt(i + 1, obj);
  }
  // Now try to invoke the closure.
  return Api::NewHandle(T, DartEntry::InvokeClosure(args));
}

DART_EXPORT Dart_Handle Dart_GetField(Dart_Handle container, Dart_Handle name) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  const String& field_name = Api::UnwrapStringHandle(Z, name);
  if (field_name.IsNull()) {
    RETURN_TYPE_ERROR(Z, name, String);
  }

  Field& field = Field::Handle(Z);
  Function& getter = Function::Handle(Z);
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(container));
  if (obj.IsNull()) {
    return Api::NewError("%s expects argument 'container' to be non-null.",
                         CURRENT_FUNC);
  } else if (obj.IsType()) {
    if (!Type::Cast(obj).IsFinalized()) {
      return Api::NewError(
          "%s expects argument 'container' to be a fully resolved type.",
          CURRENT_FUNC);
    }
    // To access a static field we may need to use the Field or the
    // getter Function.
    Class& cls = Class::Handle(Z, Type::Cast(obj).type_class());

    field = cls.LookupStaticFieldAllowPrivate(field_name);
    if (field.IsNull() || field.IsUninitialized()) {
      const String& getter_name =
          String::Handle(Z, Field::GetterName(field_name));
      getter = cls.LookupStaticFunctionAllowPrivate(getter_name);
    }

#if !defined(PRODUCT)
    if (tds.enabled()) {
      const String& cls_name = String::Handle(cls.Name());
      tds.SetNumArguments(1);
      tds.FormatArgument(0, "name", "%s.%s", cls_name.ToCString(),
                         field_name.ToCString());
    }
#endif  // !defined(PRODUCT)

    if (!getter.IsNull()) {
      // Invoke the getter and return the result.
      return Api::NewHandle(
          T, DartEntry::InvokeFunction(getter, Object::empty_array()));
    } else if (!field.IsNull()) {
      return Api::NewHandle(T, field.StaticValue());
    } else {
      return Api::NewError("%s: did not find static field '%s'.", CURRENT_FUNC,
                           field_name.ToCString());
    }

  } else if (obj.IsInstance()) {
    // Every instance field has a getter Function.  Try to find the
    // getter in any superclass and use that function to access the
    // field.
    const Instance& instance = Instance::Cast(obj);
    Class& cls = Class::Handle(Z, instance.clazz());
    String& getter_name = String::Handle(Z, Field::GetterName(field_name));
    while (!cls.IsNull()) {
      getter = cls.LookupDynamicFunctionAllowPrivate(getter_name);
      if (!getter.IsNull()) {
        break;
      }
      cls = cls.SuperClass();
    }

#if !defined(PRODUCT)
    if (tds.enabled()) {
      const String& cls_name = String::Handle(cls.Name());
      tds.SetNumArguments(1);
      tds.FormatArgument(0, "name", "%s.%s", cls_name.ToCString(),
                         field_name.ToCString());
    }
#endif  // !defined(PRODUCT)

    // Invoke the getter and return the result.
    const int kTypeArgsLen = 0;
    const int kNumArgs = 1;
    const Array& args = Array::Handle(Z, Array::New(kNumArgs));
    args.SetAt(0, instance);
    if (getter.IsNull()) {
      const Array& args_descriptor = Array::Handle(
          Z, ArgumentsDescriptor::New(kTypeArgsLen, args.Length()));
      return Api::NewHandle(
          T, DartEntry::InvokeNoSuchMethod(instance, getter_name, args,
                                           args_descriptor));
    }
    return Api::NewHandle(T, DartEntry::InvokeFunction(getter, args));

  } else if (obj.IsLibrary()) {
    // To access a top-level we may need to use the Field or the
    // getter Function.  The getter function may either be in the
    // library or in the field's owner class, depending.
    const Library& lib = Library::Cast(obj);
    // Check that the library is loaded.
    if (!lib.Loaded()) {
      return Api::NewError(
          "%s expects library argument 'container' to be loaded.",
          CURRENT_FUNC);
    }
    field = lib.LookupFieldAllowPrivate(field_name);
    if (field.IsNull()) {
      // No field found and no ambiguity error.  Check for a getter in the lib.
      const String& getter_name =
          String::Handle(Z, Field::GetterName(field_name));
      getter = lib.LookupFunctionAllowPrivate(getter_name);
    } else if (!field.IsNull() && field.IsUninitialized()) {
      // A field was found.  Check for a getter in the field's owner class.
      const Class& cls = Class::Handle(Z, field.Owner());
      const String& getter_name =
          String::Handle(Z, Field::GetterName(field_name));
      getter = cls.LookupStaticFunctionAllowPrivate(getter_name);
    }

#if !defined(PRODUCT)
    if (tds.enabled()) {
      const String& lib_name = String::Handle(lib.url());
      tds.SetNumArguments(1);
      tds.FormatArgument(0, "name", "%s.%s", lib_name.ToCString(),
                         field_name.ToCString());
    }
#endif  // !defined(PRODUCT)

    if (!getter.IsNull()) {
      // Invoke the getter and return the result.
      return Api::NewHandle(
          T, DartEntry::InvokeFunction(getter, Object::empty_array()));
    }
    if (!field.IsNull()) {
      return Api::NewHandle(T, field.StaticValue());
    }
    return Api::NewError("%s: did not find top-level variable '%s'.",
                         CURRENT_FUNC, field_name.ToCString());

  } else if (obj.IsError()) {
    return container;
  } else {
    return Api::NewError(
        "%s expects argument 'container' to be an object, type, or library.",
        CURRENT_FUNC);
  }
}

DART_EXPORT Dart_Handle Dart_SetField(Dart_Handle container,
                                      Dart_Handle name,
                                      Dart_Handle value) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  const String& field_name = Api::UnwrapStringHandle(Z, name);
  if (field_name.IsNull()) {
    RETURN_TYPE_ERROR(Z, name, String);
  }

  // Since null is allowed for value, we don't use UnwrapInstanceHandle.
  const Object& value_obj = Object::Handle(Z, Api::UnwrapHandle(value));
  if (!value_obj.IsNull() && !value_obj.IsInstance()) {
    RETURN_TYPE_ERROR(Z, value, Instance);
  }
  Instance& value_instance = Instance::Handle(Z);
  value_instance ^= value_obj.raw();

  Field& field = Field::Handle(Z);
  Function& setter = Function::Handle(Z);
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(container));
  if (obj.IsNull()) {
    return Api::NewError("%s expects argument 'container' to be non-null.",
                         CURRENT_FUNC);
  } else if (obj.IsType()) {
    if (!Type::Cast(obj).IsFinalized()) {
      return Api::NewError(
          "%s expects argument 'container' to be a fully resolved type.",
          CURRENT_FUNC);
    }

    // To access a static field we may need to use the Field or the
    // setter Function.
    Class& cls = Class::Handle(Z, Type::Cast(obj).type_class());

    field = cls.LookupStaticFieldAllowPrivate(field_name);
    if (field.IsNull()) {
      String& setter_name = String::Handle(Z, Field::SetterName(field_name));
      setter = cls.LookupStaticFunctionAllowPrivate(setter_name);
    }

    if (!setter.IsNull()) {
      // Invoke the setter and return the result.
      const int kNumArgs = 1;
      const Array& args = Array::Handle(Z, Array::New(kNumArgs));
      args.SetAt(0, value_instance);
      const Object& result =
          Object::Handle(Z, DartEntry::InvokeFunction(setter, args));
      if (result.IsError()) {
        return Api::NewHandle(T, result.raw());
      } else {
        return Api::Success();
      }
    } else if (!field.IsNull()) {
      if (field.is_final()) {
        return Api::NewError("%s: cannot set final field '%s'.", CURRENT_FUNC,
                             field_name.ToCString());
      } else {
        field.SetStaticValue(value_instance);
        return Api::Success();
      }
    } else {
      return Api::NewError("%s: did not find static field '%s'.", CURRENT_FUNC,
                           field_name.ToCString());
    }

  } else if (obj.IsInstance()) {
    // Every instance field has a setter Function.  Try to find the
    // setter in any superclass and use that function to access the
    // field.
    const Instance& instance = Instance::Cast(obj);
    Class& cls = Class::Handle(Z, instance.clazz());
    String& setter_name = String::Handle(Z, Field::SetterName(field_name));
    while (!cls.IsNull()) {
      field = cls.LookupInstanceFieldAllowPrivate(field_name);
      if (!field.IsNull() && field.is_final()) {
        return Api::NewError("%s: cannot set final field '%s'.", CURRENT_FUNC,
                             field_name.ToCString());
      }
      setter = cls.LookupDynamicFunctionAllowPrivate(setter_name);
      if (!setter.IsNull()) {
        break;
      }
      cls = cls.SuperClass();
    }

    // Invoke the setter and return the result.
    const int kTypeArgsLen = 0;
    const int kNumArgs = 2;
    const Array& args = Array::Handle(Z, Array::New(kNumArgs));
    args.SetAt(0, instance);
    args.SetAt(1, value_instance);
    if (setter.IsNull()) {
      const Array& args_descriptor = Array::Handle(
          Z, ArgumentsDescriptor::New(kTypeArgsLen, args.Length()));
      return Api::NewHandle(
          T, DartEntry::InvokeNoSuchMethod(instance, setter_name, args,
                                           args_descriptor));
    }
    return Api::NewHandle(T, DartEntry::InvokeFunction(setter, args));

  } else if (obj.IsLibrary()) {
    // To access a top-level we may need to use the Field or the
    // setter Function.  The setter function may either be in the
    // library or in the field's owner class, depending.
    const Library& lib = Library::Cast(obj);
    // Check that the library is loaded.
    if (!lib.Loaded()) {
      return Api::NewError(
          "%s expects library argument 'container' to be loaded.",
          CURRENT_FUNC);
    }
    field = lib.LookupFieldAllowPrivate(field_name);
    if (field.IsNull()) {
      const String& setter_name =
          String::Handle(Z, Field::SetterName(field_name));
      setter ^= lib.LookupFunctionAllowPrivate(setter_name);
    }

    if (!setter.IsNull()) {
      // Invoke the setter and return the result.
      const int kNumArgs = 1;
      const Array& args = Array::Handle(Z, Array::New(kNumArgs));
      args.SetAt(0, value_instance);
      const Object& result =
          Object::Handle(Z, DartEntry::InvokeFunction(setter, args));
      if (result.IsError()) {
        return Api::NewHandle(T, result.raw());
      }
      return Api::Success();
    }
    if (!field.IsNull()) {
      if (field.is_final()) {
        return Api::NewError("%s: cannot set final top-level variable '%s'.",
                             CURRENT_FUNC, field_name.ToCString());
      }
      field.SetStaticValue(value_instance);
      return Api::Success();
    }
    return Api::NewError("%s: did not find top-level variable '%s'.",
                         CURRENT_FUNC, field_name.ToCString());

  } else if (obj.IsError()) {
    return container;
  }
  return Api::NewError(
      "%s expects argument 'container' to be an object, type, or library.",
      CURRENT_FUNC);
}

// --- Exceptions ----

DART_EXPORT Dart_Handle Dart_ThrowException(Dart_Handle exception) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  CHECK_CALLBACK_STATE(thread);
  if (Api::IsError(exception)) {
    ::Dart_PropagateError(exception);
  }
  TransitionNativeToVM transition(thread);
  const Instance& excp = Api::UnwrapInstanceHandle(zone, exception);
  if (excp.IsNull()) {
    RETURN_TYPE_ERROR(zone, exception, Instance);
  }
  if (thread->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    return Api::NewError("No Dart frames on stack, cannot throw exception");
  }
  // Unwind all the API scopes till the exit frame before throwing an
  // exception.
  const Instance* saved_exception;
  {
    NoSafepointScope no_safepoint;
    RawInstance* raw_exception =
        Api::UnwrapInstanceHandle(zone, exception).raw();
    thread->UnwindScopes(thread->top_exit_frame_info());
    saved_exception = &Instance::Handle(raw_exception);
  }
  Exceptions::Throw(thread, *saved_exception);
  return Api::NewError("Exception was not thrown, internal error");
}

DART_EXPORT Dart_Handle Dart_ReThrowException(Dart_Handle exception,
                                              Dart_Handle stacktrace) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  CHECK_CALLBACK_STATE(thread);
  TransitionNativeToVM transition(thread);
  {
    const Instance& excp = Api::UnwrapInstanceHandle(zone, exception);
    if (excp.IsNull()) {
      RETURN_TYPE_ERROR(zone, exception, Instance);
    }
    const Instance& stk = Api::UnwrapInstanceHandle(zone, stacktrace);
    if (stk.IsNull()) {
      RETURN_TYPE_ERROR(zone, stacktrace, Instance);
    }
  }
  if (thread->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    return Api::NewError("No Dart frames on stack, cannot throw exception");
  }
  // Unwind all the API scopes till the exit frame before throwing an
  // exception.
  const Instance* saved_exception;
  const StackTrace* saved_stacktrace;
  {
    NoSafepointScope no_safepoint;
    RawInstance* raw_exception =
        Api::UnwrapInstanceHandle(zone, exception).raw();
    RawStackTrace* raw_stacktrace =
        Api::UnwrapStackTraceHandle(zone, stacktrace).raw();
    thread->UnwindScopes(thread->top_exit_frame_info());
    saved_exception = &Instance::Handle(raw_exception);
    saved_stacktrace = &StackTrace::Handle(raw_stacktrace);
  }
  Exceptions::ReThrow(thread, *saved_exception, *saved_stacktrace);
  return Api::NewError("Exception was not re thrown, internal error");
}

// --- Native fields and functions ---

DART_EXPORT Dart_Handle Dart_CreateNativeWrapperClass(Dart_Handle library,
                                                      Dart_Handle name,
                                                      int field_count) {
  DARTSCOPE(Thread::Current());
  const String& cls_name = Api::UnwrapStringHandle(Z, name);
  if (cls_name.IsNull()) {
    RETURN_TYPE_ERROR(Z, name, String);
  }
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  if (!Utils::IsUint(16, field_count)) {
    return Api::NewError(
        "Invalid field_count passed to Dart_CreateNativeWrapperClass");
  }
  CHECK_CALLBACK_STATE(T);

  String& cls_symbol = String::Handle(Z, Symbols::New(T, cls_name));
  const Class& cls =
      Class::Handle(Z, Class::NewNativeWrapper(lib, cls_symbol, field_count));
  if (cls.IsNull()) {
    return Api::NewError(
        "Unable to create native wrapper class : already exists");
  }
  return Api::NewHandle(T, cls.RareType());
}

DART_EXPORT Dart_Handle Dart_GetNativeInstanceFieldCount(Dart_Handle obj,
                                                         int* count) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  ReusableObjectHandleScope reused_obj_handle(thread);
  const Instance& instance = Api::UnwrapInstanceHandle(reused_obj_handle, obj);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(thread->zone(), obj, Instance);
  }
  *count = instance.NumNativeFields();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t* value) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  ReusableObjectHandleScope reused_obj_handle(thread);
  const Instance& instance = Api::UnwrapInstanceHandle(reused_obj_handle, obj);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(thread->zone(), obj, Instance);
  }
  if (!instance.IsValidNativeIndex(index)) {
    return Api::NewError(
        "%s: invalid index %d passed in to access native instance field",
        CURRENT_FUNC, index);
  }
  *value = instance.GetNativeField(index);
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_SetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t value) {
  DARTSCOPE(Thread::Current());
  const Instance& instance = Api::UnwrapInstanceHandle(Z, obj);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(Z, obj, Instance);
  }
  if (!instance.IsValidNativeIndex(index)) {
    return Api::NewError(
        "%s: invalid index %d passed in to set native instance field",
        CURRENT_FUNC, index);
  }
  instance.SetNativeField(index, value);
  return Api::Success();
}

DART_EXPORT void* Dart_GetNativeIsolateData(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Isolate* isolate = arguments->thread()->isolate();
  ASSERT(isolate == Isolate::Current());
  return isolate->init_callback_data();
}

DART_EXPORT Dart_Handle Dart_GetNativeArguments(
    Dart_NativeArguments args,
    int num_arguments,
    const Dart_NativeArgument_Descriptor* argument_descriptors,
    Dart_NativeArgument_Value* arg_values) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  if (arg_values == NULL) {
    RETURN_NULL_ERROR(arg_values);
  }
  for (int i = 0; i < num_arguments; i++) {
    Dart_NativeArgument_Descriptor desc = argument_descriptors[i];
    Dart_NativeArgument_Type arg_type =
        static_cast<Dart_NativeArgument_Type>(desc.type);
    int arg_index = desc.index;
    ASSERT(arg_index >= 0 && arg_index < arguments->NativeArgCount());
    Dart_NativeArgument_Value* native_value = &(arg_values[i]);
    switch (arg_type) {
      case Dart_NativeArgument_kBool:
        if (!Api::GetNativeBooleanArgument(arguments, arg_index,
                                           &(native_value->as_bool))) {
          return Api::NewError(
              "%s: expects argument at index %d to be of"
              " type Boolean.",
              CURRENT_FUNC, i);
        }
        break;

      case Dart_NativeArgument_kInt32: {
        int64_t value = 0;
        if (!GetNativeIntegerArgument(arguments, arg_index, &value)) {
          return Api::NewError(
              "%s: expects argument at index %d to be of"
              " type Integer.",
              CURRENT_FUNC, i);
        }
        if (value < INT_MIN || value > INT_MAX) {
          return Api::NewError("%s: argument value at index %d is out of range",
                               CURRENT_FUNC, i);
        }
        native_value->as_int32 = static_cast<int32_t>(value);
        break;
      }

      case Dart_NativeArgument_kUint32: {
        int64_t value = 0;
        if (!GetNativeIntegerArgument(arguments, arg_index, &value)) {
          return Api::NewError(
              "%s: expects argument at index %d to be of"
              " type Integer.",
              CURRENT_FUNC, i);
        }
        if (value < 0 || value > UINT_MAX) {
          return Api::NewError("%s: argument value at index %d is out of range",
                               CURRENT_FUNC, i);
        }
        native_value->as_uint32 = static_cast<uint32_t>(value);
        break;
      }

      case Dart_NativeArgument_kInt64: {
        int64_t value = 0;
        if (!GetNativeIntegerArgument(arguments, arg_index, &value)) {
          return Api::NewError(
              "%s: expects argument at index %d to be of"
              " type Integer.",
              CURRENT_FUNC, i);
        }
        native_value->as_int64 = value;
        break;
      }

      case Dart_NativeArgument_kUint64: {
        uint64_t value = 0;
        if (!GetNativeUnsignedIntegerArgument(arguments, arg_index, &value)) {
          return Api::NewError(
              "%s: expects argument at index %d to be of"
              " type Integer.",
              CURRENT_FUNC, i);
        }
        native_value->as_uint64 = value;
        break;
      }

      case Dart_NativeArgument_kDouble:
        if (!GetNativeDoubleArgument(arguments, arg_index,
                                     &(native_value->as_double))) {
          return Api::NewError(
              "%s: expects argument at index %d to be of"
              " type Double.",
              CURRENT_FUNC, i);
        }
        break;

      case Dart_NativeArgument_kString:
        if (!GetNativeStringArgument(arguments, arg_index,
                                     &(native_value->as_string.dart_str),
                                     &(native_value->as_string.peer))) {
          return Api::NewError(
              "%s: expects argument at index %d to be of"
              " type String.",
              CURRENT_FUNC, i);
        }
        break;

      case Dart_NativeArgument_kNativeFields: {
        Dart_Handle result = GetNativeFieldsOfArgument(
            arguments, arg_index, native_value->as_native_fields.num_fields,
            native_value->as_native_fields.values, CURRENT_FUNC);
        if (result != Api::Success()) {
          return result;
        }
        break;
      }

      case Dart_NativeArgument_kInstance: {
        ASSERT(arguments->thread() == Thread::Current());
        ASSERT(arguments->thread()->api_top_scope() != NULL);
        native_value->as_instance = Api::NewHandle(
            arguments->thread(), arguments->NativeArgAt(arg_index));
        break;
      }

      default:
        return Api::NewError("%s: invalid argument type %d.", CURRENT_FUNC,
                             arg_type);
    }
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args,
                                               int index) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  if ((index < 0) || (index >= arguments->NativeArgCount())) {
    return Api::NewError(
        "%s: argument 'index' out of range. Expected 0..%d but saw %d.",
        CURRENT_FUNC, arguments->NativeArgCount() - 1, index);
  }
  return Api::NewHandle(arguments->thread(), arguments->NativeArgAt(index));
}

DART_EXPORT int Dart_GetNativeArgumentCount(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  return arguments->NativeArgCount();
}

DART_EXPORT Dart_Handle
Dart_GetNativeFieldsOfArgument(Dart_NativeArguments args,
                               int arg_index,
                               int num_fields,
                               intptr_t* field_values) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  if ((arg_index < 0) || (arg_index >= arguments->NativeArgCount())) {
    return Api::NewError(
        "%s: argument 'arg_index' out of range. Expected 0..%d but saw %d.",
        CURRENT_FUNC, arguments->NativeArgCount() - 1, arg_index);
  }
  if (field_values == NULL) {
    RETURN_NULL_ERROR(field_values);
  }
  return GetNativeFieldsOfArgument(arguments, arg_index, num_fields,
                                   field_values, CURRENT_FUNC);
}

DART_EXPORT Dart_Handle Dart_GetNativeReceiver(Dart_NativeArguments args,
                                               intptr_t* value) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  if (value == NULL) {
    RETURN_NULL_ERROR(value);
  }
  if (Api::GetNativeReceiver(arguments, value)) {
    return Api::Success();
  }
  return Api::NewError(
      "%s expects receiver argument to be non-null and of"
      " type Instance.",
      CURRENT_FUNC);
}

DART_EXPORT Dart_Handle Dart_GetNativeStringArgument(Dart_NativeArguments args,
                                                     int arg_index,
                                                     void** peer) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Dart_Handle result = Api::Null();
  if (!GetNativeStringArgument(arguments, arg_index, &result, peer)) {
    return Api::NewError(
        "%s expects argument at %d to be of"
        " type String.",
        CURRENT_FUNC, arg_index);
  }
  return result;
}

DART_EXPORT Dart_Handle Dart_GetNativeIntegerArgument(Dart_NativeArguments args,
                                                      int index,
                                                      int64_t* value) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  if ((index < 0) || (index >= arguments->NativeArgCount())) {
    return Api::NewError(
        "%s: argument 'index' out of range. Expected 0..%d but saw %d.",
        CURRENT_FUNC, arguments->NativeArgCount() - 1, index);
  }
  if (!GetNativeIntegerArgument(arguments, index, value)) {
    return Api::NewError(
        "%s: expects argument at %d to be of"
        " type Integer.",
        CURRENT_FUNC, index);
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetNativeBooleanArgument(Dart_NativeArguments args,
                                                      int index,
                                                      bool* value) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  if ((index < 0) || (index >= arguments->NativeArgCount())) {
    return Api::NewError(
        "%s: argument 'index' out of range. Expected 0..%d but saw %d.",
        CURRENT_FUNC, arguments->NativeArgCount() - 1, index);
  }
  if (!Api::GetNativeBooleanArgument(arguments, index, value)) {
    return Api::NewError("%s: expects argument at %d to be of type Boolean.",
                         CURRENT_FUNC, index);
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetNativeDoubleArgument(Dart_NativeArguments args,
                                                     int index,
                                                     double* value) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  if ((index < 0) || (index >= arguments->NativeArgCount())) {
    return Api::NewError(
        "%s: argument 'index' out of range. Expected 0..%d but saw %d.",
        CURRENT_FUNC, arguments->NativeArgCount() - 1, index);
  }
  if (!GetNativeDoubleArgument(arguments, index, value)) {
    return Api::NewError(
        "%s: expects argument at %d to be of"
        " type Double.",
        CURRENT_FUNC, index);
  }
  return Api::Success();
}

DART_EXPORT void Dart_SetReturnValue(Dart_NativeArguments args,
                                     Dart_Handle retval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  if ((retval != Api::Null()) && !Api::IsInstance(retval) &&
      !Api::IsError(retval)) {
    // Print the current stack trace to make the problematic caller
    // easier to find.
    const StackTrace& stacktrace = GetCurrentStackTrace(0);
    OS::PrintErr("=== Current Trace:\n%s===\n", stacktrace.ToCString());

    const Object& ret_obj = Object::Handle(Api::UnwrapHandle(retval));
    FATAL1(
        "Return value check failed: saw '%s' expected a dart Instance or "
        "an Error.",
        ret_obj.ToCString());
  }
  ASSERT(retval != 0);
  Api::SetReturnValue(arguments, retval);
}

DART_EXPORT void Dart_SetWeakHandleReturnValue(Dart_NativeArguments args,
                                               Dart_WeakPersistentHandle rval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
#if defined(DEBUG)
  Isolate* isolate = arguments->thread()->isolate();
  ASSERT(isolate == Isolate::Current());
  ASSERT(isolate->api_state() != NULL &&
         (isolate->api_state()->IsValidWeakPersistentHandle(rval)));
#endif
  Api::SetWeakHandleReturnValue(arguments, rval);
}

// --- Environment ---
RawString* Api::GetEnvironmentValue(Thread* thread, const String& name) {
  String& result = String::Handle(CallEnvironmentCallback(thread, name));
  if (result.IsNull()) {
    // Every 'dart:X' library introduces an environment variable
    // 'dart.library.X' that is set to 'true'.
    // We just need to make sure to hide private libraries (starting with
    // "_", and the mirrors library, if it is not supported.

    if (!FLAG_enable_mirrors && name.Equals(Symbols::DartLibraryMirrors())) {
      return Symbols::False().raw();
    }

    if (name.Equals(Symbols::DartVMProduct())) {
#ifdef PRODUCT
      return Symbols::True().raw();
#else
      return Symbols::False().raw();
#endif
    }

    const String& prefix = Symbols::DartLibrary();
    if (name.StartsWith(prefix)) {
      const String& library_name =
          String::Handle(String::SubString(name, prefix.Length()));

      // Private libraries (starting with "_") are not exposed to the user.
      if (!library_name.IsNull() && library_name.CharAt(0) != '_') {
        const String& dart_library_name =
            String::Handle(String::Concat(Symbols::DartScheme(), library_name));
        const Library& library =
            Library::Handle(Library::LookupLibrary(thread, dart_library_name));
        if (!library.IsNull()) {
          return Symbols::True().raw();
        }
      }
    }
    // Check for default VM provided values. If it was not overridden on the
    // command line.
    if (Symbols::DartIsVM().Equals(name)) {
      return Symbols::True().raw();
    }
    if (FLAG_causal_async_stacks) {
      if (Symbols::DartDeveloperCausalAsyncStacks().Equals(name)) {
        return Symbols::True().raw();
      }
    }
  }
  return result.raw();
}

RawString* Api::CallEnvironmentCallback(Thread* thread, const String& name) {
  Isolate* isolate = thread->isolate();
  Dart_EnvironmentCallback callback = isolate->environment_callback();
  String& result = String::Handle(thread->zone());
  if (callback != NULL) {
    TransitionVMToNative transition(thread);
    Scope api_scope(thread);
    Dart_Handle response = callback(Api::NewHandle(thread, name.raw()));
    if (::Dart_IsString(response)) {
      result ^= Api::UnwrapHandle(response);
    } else if (::Dart_IsError(response)) {
      const Object& error =
          Object::Handle(thread->zone(), Api::UnwrapHandle(response));
      Exceptions::ThrowArgumentError(
          String::Handle(String::New(Error::Cast(error).ToErrorCString())));
    } else if (!::Dart_IsNull(response)) {
      // At this point everything except null are invalid environment values.
      Exceptions::ThrowArgumentError(
          String::Handle(String::New("Illegal environment value")));
    }
  }
  return result.raw();
}

DART_EXPORT Dart_Handle
Dart_SetEnvironmentCallback(Dart_EnvironmentCallback callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  isolate->set_environment_callback(callback);
  return Api::Success();
}

// --- Scripts and Libraries ---
DART_EXPORT void Dart_SetBooleanReturnValue(Dart_NativeArguments args,
                                            bool retval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  arguments->SetReturn(Bool::Get(retval));
}

DART_EXPORT void Dart_SetIntegerReturnValue(Dart_NativeArguments args,
                                            int64_t retval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  if (Smi::IsValid(retval)) {
    Api::SetSmiReturnValue(arguments, static_cast<intptr_t>(retval));
  } else {
    // Slow path for Mints and Bigints.
    ASSERT_CALLBACK_STATE(arguments->thread());
    TransitionNativeToVM transition(arguments->thread());
    Api::SetIntegerReturnValue(arguments, retval);
  }
}

DART_EXPORT void Dart_SetDoubleReturnValue(Dart_NativeArguments args,
                                           double retval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  ASSERT_CALLBACK_STATE(arguments->thread());
  TransitionNativeToVM transition(arguments->thread());
  Api::SetDoubleReturnValue(arguments, retval);
}

// --- Scripts and Libraries ---

DART_EXPORT Dart_Handle
Dart_SetLibraryTagHandler(Dart_LibraryTagHandler handler) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  isolate->set_library_tag_handler(handler);
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_DefaultCanonicalizeUrl(Dart_Handle base_url,
                                                    Dart_Handle url) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  const String& base_uri = Api::UnwrapStringHandle(Z, base_url);
  if (base_uri.IsNull()) {
    RETURN_TYPE_ERROR(Z, base_url, String);
  }
  const String& uri = Api::UnwrapStringHandle(Z, url);
  if (uri.IsNull()) {
    RETURN_TYPE_ERROR(Z, url, String);
  }

  const char* resolved_uri;
  if (!ResolveUri(uri.ToCString(), base_uri.ToCString(), &resolved_uri)) {
    return Api::NewError("%s: Unable to canonicalize uri '%s'.", CURRENT_FUNC,
                         uri.ToCString());
  }
  return Api::NewHandle(T, String::New(resolved_uri));
}

// NOTE: Need to pass 'result' as a parameter here in order to avoid
// warning: variable 'result' might be clobbered by 'longjmp' or 'vfork'
// which shows up because of the use of setjmp.
static void CompileSource(Thread* thread,
                          const Library& lib,
                          const Script& script,
                          Dart_Handle* result) {
  bool update_lib_status = (script.kind() == RawScript::kScriptTag ||
                            script.kind() == RawScript::kLibraryTag);
  if (update_lib_status) {
    lib.SetLoadInProgress();
  }
  ASSERT(thread != NULL);
  const Error& error =
      Error::Handle(thread->zone(), Compiler::Compile(lib, script));
  if (error.IsNull()) {
    *result = Api::NewHandle(thread, lib.raw());
  } else {
    *result = Api::NewHandle(thread, error.raw());
    // Compilation errors are not Dart instances, so just mark the library
    // as having failed to load without providing an error instance.
    lib.SetLoadError(Object::null_instance());
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static Dart_Handle LoadKernelProgram(Thread* T,
                                     const String& url,
                                     void* kernel) {
  // NOTE: Now the VM owns the [kernel_program] memory!
  // We will promptly delete it when done.
  kernel::Program* program = reinterpret_cast<kernel::Program*>(kernel);
  kernel::KernelReader reader(program);
  const Object& tmp = reader.ReadProgram();
  delete program;

  if (tmp.IsError()) {
    return Api::NewHandle(T, tmp.raw());
  }
  return Dart_Null();
}
#endif

DART_EXPORT Dart_Handle Dart_LoadScript(Dart_Handle url,
                                        Dart_Handle resolved_url,
                                        Dart_Handle source,
                                        intptr_t line_offset,
                                        intptr_t column_offset) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  const String& url_str = Api::UnwrapStringHandle(Z, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, url, String);
  }
  if (::Dart_IsNull(resolved_url)) {
    resolved_url = url;
  }
  const String& resolved_url_str = Api::UnwrapStringHandle(Z, resolved_url);
  if (resolved_url_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, resolved_url, String);
  }
  Library& library = Library::Handle(Z, I->object_store()->root_library());
  if (!library.IsNull()) {
    const String& library_url = String::Handle(Z, library.url());
    return Api::NewError("%s: A script has already been loaded from '%s'.",
                         CURRENT_FUNC, library_url.ToCString());
  }
  if (line_offset < 0) {
    return Api::NewError("%s: argument 'line_offset' must be positive number",
                         CURRENT_FUNC);
  }
  if (column_offset < 0) {
    return Api::NewError("%s: argument 'column_offset' must be positive number",
                         CURRENT_FUNC);
  }
  CHECK_CALLBACK_STATE(T);
  CHECK_COMPILATION_ALLOWED(I);

  Dart_Handle result;
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (I->use_dart_frontend()) {
    if ((source == Api::Null()) || (source == NULL)) {
      RETURN_NULL_ERROR(source);
    }
    void* kernel_pgm = reinterpret_cast<void*>(source);
    result = LoadKernelProgram(T, resolved_url_str, kernel_pgm);
    if (::Dart_IsError(result)) {
      return result;
    }
    library ^= Library::LookupLibrary(T, resolved_url_str);
    if (library.IsNull()) {
      return Api::NewError("%s: Unable to load script '%s' correctly.",
                           CURRENT_FUNC, resolved_url_str.ToCString());
    }
    I->object_store()->set_root_library(library);
    return Api::NewHandle(T, library.raw());
  }
#endif

  const String& source_str = Api::UnwrapStringHandle(Z, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, source, String);
  }

  NoHeapGrowthControlScope no_growth_control;

  library = Library::New(url_str);
  library.set_debuggable(true);
  library.Register(T);
  I->object_store()->set_root_library(library);

  const Script& script =
      Script::Handle(Z, Script::New(url_str, resolved_url_str, source_str,
                                    RawScript::kScriptTag));
  script.SetLocationOffset(line_offset, column_offset);
  CompileSource(T, library, script, &result);
  return result;
}

DART_EXPORT Dart_Handle Dart_LoadScriptFromSnapshot(const uint8_t* buffer,
                                                    intptr_t buffer_len) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  StackZone zone(T);
  if (buffer == NULL) {
    RETURN_NULL_ERROR(buffer);
  }
  NoHeapGrowthControlScope no_growth_control;

  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);
  if (snapshot == NULL) {
    return Api::NewError(
        "%s expects parameter 'buffer' to be a script type"
        " snapshot with a valid length.",
        CURRENT_FUNC);
  }
  if (snapshot->kind() != Snapshot::kScript) {
    return Api::NewError(
        "%s expects parameter 'buffer' to be a script type"
        " snapshot.",
        CURRENT_FUNC);
  }
  if (snapshot->length() != buffer_len) {
    return Api::NewError("%s: 'buffer_len' of %" Pd " is not equal to %" Pd
                         " which is the expected length in the snapshot.",
                         CURRENT_FUNC, buffer_len, snapshot->length());
  }
  Library& library = Library::Handle(Z, I->object_store()->root_library());
  if (!library.IsNull()) {
    const String& library_url = String::Handle(Z, library.url());
    return Api::NewError("%s: A script has already been loaded from '%s'.",
                         CURRENT_FUNC, library_url.ToCString());
  }
  CHECK_CALLBACK_STATE(T);
  CHECK_COMPILATION_ALLOWED(I);

  ASSERT(snapshot->kind() == Snapshot::kScript);
  NOT_IN_PRODUCT(TimelineDurationScope tds2(T, Timeline::GetIsolateStream(),
                                            "ScriptSnapshotReader"));

  ScriptSnapshotReader reader(snapshot->content(), snapshot->length(), T);
  const Object& tmp = Object::Handle(Z, reader.ReadScriptSnapshot());
  if (tmp.IsError()) {
    return Api::NewHandle(T, tmp.raw());
  }
#if !defined(PRODUCT)
  if (tds2.enabled()) {
    tds2.SetNumArguments(2);
    tds2.FormatArgument(0, "snapshotSize", "%" Pd, snapshot->length());
    tds2.FormatArgument(1, "heapSize", "%" Pd64,
                        I->heap()->UsedInWords(Heap::kOld) * kWordSize);
  }
#endif  // !defined(PRODUCT)
  library ^= tmp.raw();
  library.set_debuggable(true);
  I->object_store()->set_root_library(library);
  return Api::NewHandle(T, library.raw());
}

DART_EXPORT void* Dart_ReadKernelBinary(const uint8_t* buffer,
                                        intptr_t buffer_len) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
  return NULL;
#else
  kernel::Program* program =
      ReadPrecompiledKernelFromBuffer(buffer, buffer_len);
  return program;
#endif
}

DART_EXPORT Dart_Handle Dart_LoadKernel(void* kernel_program) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  StackZone zone(T);

#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("%s: Can't load Kernel files from precompiled runtime.",
                       CURRENT_FUNC);
#else
  Isolate* I = T->isolate();

  Library& library = Library::Handle(Z, I->object_store()->root_library());
  if (!library.IsNull()) {
    const String& library_url = String::Handle(Z, library.url());
    return Api::NewError("%s: A script has already been loaded from '%s'.",
                         CURRENT_FUNC, library_url.ToCString());
  }
  CHECK_CALLBACK_STATE(T);
  CHECK_COMPILATION_ALLOWED(I);

  // NOTE: Now the VM owns the [kernel_program] memory!
  // We will promptly delete it when done.
  kernel::Program* program = reinterpret_cast<kernel::Program*>(kernel_program);
  kernel::KernelReader reader(program);
  const Object& tmp = reader.ReadProgram();
  delete program;

  if (tmp.IsError()) {
    return Api::NewHandle(T, tmp.raw());
  }
  // TODO(kernel): Setting root library based on whether it has 'main' or not
  // is not correct because main can be in the exported namespace of a library
  // or it could be a getter.
  if (tmp.IsNull()) {
    return Api::NewError("%s: The binary program does not contain 'main'.",
                         CURRENT_FUNC);
  }
  library ^= tmp.raw();
  I->object_store()->set_root_library(library);
  return Api::NewHandle(T, library.raw());
#endif
}

DART_EXPORT Dart_Handle Dart_RootLibrary() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  return Api::NewHandle(thread, isolate->object_store()->root_library());
}

DART_EXPORT Dart_Handle Dart_SetRootLibrary(Dart_Handle library) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(library));
  if (obj.IsNull() || obj.IsLibrary()) {
    Library& lib = Library::Handle(Z);
    lib ^= obj.raw();
    T->isolate()->object_store()->set_root_library(lib);
    return library;
  }
  RETURN_TYPE_ERROR(Z, library, Library);
}

DART_EXPORT Dart_Handle Dart_GetClass(Dart_Handle library,
                                      Dart_Handle class_name) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  const String& cls_name = Api::UnwrapStringHandle(Z, class_name);
  if (cls_name.IsNull()) {
    RETURN_TYPE_ERROR(Z, class_name, String);
  }
  const Class& cls = Class::Handle(Z, lib.LookupClassAllowPrivate(cls_name));
  if (cls.IsNull()) {
    // TODO(turnidge): Return null or error in this case?
    const String& lib_name = String::Handle(Z, lib.name());
    return Api::NewError("Class '%s' not found in library '%s'.",
                         cls_name.ToCString(), lib_name.ToCString());
  }
  return Api::NewHandle(T, cls.RareType());
}

DART_EXPORT Dart_Handle Dart_GetType(Dart_Handle library,
                                     Dart_Handle class_name,
                                     intptr_t number_of_type_arguments,
                                     Dart_Handle* type_arguments) {
  DARTSCOPE(Thread::Current());

  // Validate the input arguments.
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  if (!lib.Loaded()) {
    return Api::NewError("%s expects library argument 'library' to be loaded.",
                         CURRENT_FUNC);
  }
  const String& name_str = Api::UnwrapStringHandle(Z, class_name);
  if (name_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, class_name, String);
  }
  const Class& cls = Class::Handle(Z, lib.LookupClassAllowPrivate(name_str));
  if (cls.IsNull()) {
    const String& lib_name = String::Handle(Z, lib.name());
    return Api::NewError("Type '%s' not found in library '%s'.",
                         name_str.ToCString(), lib_name.ToCString());
  }
  if (cls.NumTypeArguments() == 0) {
    if (number_of_type_arguments != 0) {
      return Api::NewError(
          "Invalid number of type arguments specified, "
          "got %" Pd " expected 0",
          number_of_type_arguments);
    }
    return Api::NewHandle(T, Type::NewNonParameterizedType(cls));
  }
  intptr_t num_expected_type_arguments = cls.NumTypeParameters();
  TypeArguments& type_args_obj = TypeArguments::Handle();
  if (number_of_type_arguments > 0) {
    if (type_arguments == NULL) {
      RETURN_NULL_ERROR(type_arguments);
    }
    if (num_expected_type_arguments != number_of_type_arguments) {
      return Api::NewError(
          "Invalid number of type arguments specified, "
          "got %" Pd " expected %" Pd,
          number_of_type_arguments, num_expected_type_arguments);
    }
    const Array& array = Api::UnwrapArrayHandle(Z, *type_arguments);
    if (array.IsNull()) {
      RETURN_TYPE_ERROR(Z, *type_arguments, Array);
    }
    if (array.Length() != num_expected_type_arguments) {
      return Api::NewError(
          "Invalid type arguments specified, expected an "
          "array of len %" Pd " but got an array of len %" Pd,
          number_of_type_arguments, array.Length());
    }
    // Set up the type arguments array.
    type_args_obj ^= TypeArguments::New(num_expected_type_arguments);
    AbstractType& type_arg = AbstractType::Handle();
    for (intptr_t i = 0; i < number_of_type_arguments; i++) {
      type_arg ^= array.At(i);
      type_args_obj.SetTypeAt(i, type_arg);
    }
  }

  // Construct the type object, canonicalize it and return.
  Type& instantiated_type =
      Type::Handle(Type::New(cls, type_args_obj, TokenPosition::kNoSource));
  instantiated_type ^= ClassFinalizer::FinalizeType(cls, instantiated_type);
  return Api::NewHandle(T, instantiated_type.raw());
}

DART_EXPORT Dart_Handle Dart_LibraryUrl(Dart_Handle library) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  const String& url = String::Handle(Z, lib.url());
  ASSERT(!url.IsNull());
  return Api::NewHandle(T, url.raw());
}

DART_EXPORT Dart_Handle Dart_GetLoadedLibraries() {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();

  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(Z, I->object_store()->libraries());
  int num_libs = libs.Length();

  // Create new list and populate with the loaded libraries.
  Library& lib = Library::Handle();
  const Array& library_list = Array::Handle(Z, Array::New(num_libs));
  for (int i = 0; i < num_libs; i++) {
    lib ^= libs.At(i);
    ASSERT(!lib.IsNull());
    library_list.SetAt(i, lib);
  }
  return Api::NewHandle(T, library_list.raw());
}

DART_EXPORT Dart_Handle Dart_LookupLibrary(Dart_Handle url) {
  DARTSCOPE(Thread::Current());
  const String& url_str = Api::UnwrapStringHandle(Z, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, url, String);
  }
  const Library& library =
      Library::Handle(Z, Library::LookupLibrary(T, url_str));
  if (library.IsNull()) {
    return Api::NewError("%s: library '%s' not found.", CURRENT_FUNC,
                         url_str.ToCString());
  } else {
    return Api::NewHandle(T, library.raw());
  }
}

DART_EXPORT Dart_Handle Dart_LibraryHandleError(Dart_Handle library_in,
                                                Dart_Handle error_in) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();

  const Library& lib = Api::UnwrapLibraryHandle(Z, library_in);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library_in, Library);
  }
  const Instance& err = Api::UnwrapInstanceHandle(Z, error_in);
  if (err.IsNull()) {
    RETURN_TYPE_ERROR(Z, error_in, Instance);
  }
  CHECK_CALLBACK_STATE(T);

  const GrowableObjectArray& pending_deferred_loads =
      GrowableObjectArray::Handle(Z,
                                  I->object_store()->pending_deferred_loads());
  for (intptr_t i = 0; i < pending_deferred_loads.Length(); i++) {
    if (pending_deferred_loads.At(i) == lib.raw()) {
      lib.SetLoadError(err);
      return Api::Null();
    }
  }
  return error_in;
}

DART_EXPORT Dart_Handle Dart_LoadLibrary(Dart_Handle url,
                                         Dart_Handle resolved_url,
                                         Dart_Handle source,
                                         intptr_t line_offset,
                                         intptr_t column_offset) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();

  const String& url_str = Api::UnwrapStringHandle(Z, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, url, String);
  }
  Dart_Handle result;
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (I->use_dart_frontend()) {
    result = LoadKernelProgram(T, url_str, reinterpret_cast<void*>(source));
    if (::Dart_IsError(result)) {
      return result;
    }
    return Api::NewHandle(T, Library::LookupLibrary(T, url_str));
  }
#endif
  if (::Dart_IsNull(resolved_url)) {
    resolved_url = url;
  }
  const String& resolved_url_str = Api::UnwrapStringHandle(Z, resolved_url);
  if (resolved_url_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, resolved_url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(Z, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, source, String);
  }
  if (line_offset < 0) {
    return Api::NewError("%s: argument 'line_offset' must be positive number",
                         CURRENT_FUNC);
  }
  if (column_offset < 0) {
    return Api::NewError("%s: argument 'column_offset' must be positive number",
                         CURRENT_FUNC);
  }
  CHECK_CALLBACK_STATE(T);
  CHECK_COMPILATION_ALLOWED(I);

  NoHeapGrowthControlScope no_growth_control;

  Library& library = Library::Handle(Z, Library::LookupLibrary(T, url_str));
  if (library.IsNull()) {
    library = Library::New(url_str);
    library.Register(T);
  } else if (library.LoadInProgress() || library.Loaded() ||
             library.LoadFailed()) {
    // The source for this library has either been loaded or is in the
    // process of loading.  Return an error.
    return Api::NewError("%s: library '%s' has already been loaded.",
                         CURRENT_FUNC, url_str.ToCString());
  }
  const Script& script =
      Script::Handle(Z, Script::New(url_str, resolved_url_str, source_str,
                                    RawScript::kLibraryTag));
  script.SetLocationOffset(line_offset, column_offset);
  CompileSource(T, library, script, &result);
  // Propagate the error out right now.
  if (::Dart_IsError(result)) {
    return result;
  }

  // If this is the dart:_builtin library, register it with the VM.
  if (url_str.Equals("dart:_builtin")) {
    I->object_store()->set_builtin_library(library);
    Dart_Handle state = Api::CheckAndFinalizePendingClasses(T);
    if (::Dart_IsError(state)) {
      return state;
    }
  }
  return result;
}

DART_EXPORT Dart_Handle Dart_LibraryImportLibrary(Dart_Handle library,
                                                  Dart_Handle import,
                                                  Dart_Handle prefix) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  const Library& library_vm = Api::UnwrapLibraryHandle(Z, library);
  if (library_vm.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  const Library& import_vm = Api::UnwrapLibraryHandle(Z, import);
  if (import_vm.IsNull()) {
    RETURN_TYPE_ERROR(Z, import, Library);
  }
  const Object& prefix_object = Object::Handle(Z, Api::UnwrapHandle(prefix));
  const String& prefix_vm =
      prefix_object.IsNull() ? Symbols::Empty() : String::Cast(prefix_object);
  if (prefix_vm.IsNull()) {
    RETURN_TYPE_ERROR(Z, prefix, String);
  }
  CHECK_CALLBACK_STATE(T);
  CHECK_COMPILATION_ALLOWED(I);

  const String& prefix_symbol = String::Handle(Z, Symbols::New(T, prefix_vm));
  const Namespace& import_ns = Namespace::Handle(
      Z, Namespace::New(import_vm, Object::null_array(), Object::null_array()));
  if (prefix_vm.Length() == 0) {
    library_vm.AddImport(import_ns);
  } else {
    LibraryPrefix& library_prefix = LibraryPrefix::Handle();
    library_prefix = library_vm.LookupLocalLibraryPrefix(prefix_symbol);
    if (!library_prefix.IsNull()) {
      library_prefix.AddImport(import_ns);
    } else {
      library_prefix =
          LibraryPrefix::New(prefix_symbol, import_ns, false, library_vm);
      library_vm.AddObject(library_prefix, prefix_symbol);
    }
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetImportsOfScheme(Dart_Handle scheme) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  const String& scheme_vm = Api::UnwrapStringHandle(Z, scheme);
  if (scheme_vm.IsNull()) {
    RETURN_TYPE_ERROR(Z, scheme, String);
  }

  const GrowableObjectArray& libraries =
      GrowableObjectArray::Handle(Z, I->object_store()->libraries());
  const GrowableObjectArray& result =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  Library& importer = Library::Handle(Z);
  Array& imports = Array::Handle(Z);
  Namespace& ns = Namespace::Handle(Z);
  Library& importee = Library::Handle(Z);
  String& importee_uri = String::Handle(Z);
  for (intptr_t i = 0; i < libraries.Length(); i++) {
    importer ^= libraries.At(i);
    imports = importer.imports();
    for (intptr_t j = 0; j < imports.Length(); j++) {
      ns ^= imports.At(j);
      if (ns.IsNull()) continue;
      importee = ns.library();
      importee_uri = importee.url();
      if (importee_uri.StartsWith(scheme_vm)) {
        result.Add(importer);
        result.Add(importee);
      }
    }
  }

  return Api::NewHandle(T, Array::MakeFixedLength(result));
}

DART_EXPORT Dart_Handle Dart_LoadSource(Dart_Handle library,
                                        Dart_Handle url,
                                        Dart_Handle resolved_url,
                                        Dart_Handle source,
                                        intptr_t line_offset,
                                        intptr_t column_offset) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  const String& url_str = Api::UnwrapStringHandle(Z, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, url, String);
  }
  if (::Dart_IsNull(resolved_url)) {
    resolved_url = url;
  }
  const String& resolved_url_str = Api::UnwrapStringHandle(Z, resolved_url);
  if (resolved_url_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, resolved_url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(Z, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, source, String);
  }
  if (line_offset < 0) {
    return Api::NewError("%s: argument 'line_offset' must be positive number",
                         CURRENT_FUNC);
  }
  if (column_offset < 0) {
    return Api::NewError("%s: argument 'column_offset' must be positive number",
                         CURRENT_FUNC);
  }
  CHECK_CALLBACK_STATE(T);
  CHECK_COMPILATION_ALLOWED(I);

  NoHeapGrowthControlScope no_growth_control;

  const Script& script =
      Script::Handle(Z, Script::New(url_str, resolved_url_str, source_str,
                                    RawScript::kSourceTag));
  script.SetLocationOffset(line_offset, column_offset);
  Dart_Handle result;
  CompileSource(T, lib, script, &result);
  return result;
}

DART_EXPORT Dart_Handle Dart_LibraryLoadPatch(Dart_Handle library,
                                              Dart_Handle url,
                                              Dart_Handle patch_source) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  const String& url_str = Api::UnwrapStringHandle(Z, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(Z, patch_source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(Z, patch_source, String);
  }
  CHECK_CALLBACK_STATE(T);
  CHECK_COMPILATION_ALLOWED(I);

  NoHeapGrowthControlScope no_growth_control;

  const Script& script = Script::Handle(
      Z, Script::New(url_str, url_str, source_str, RawScript::kPatchTag));
  Dart_Handle result;
  CompileSource(T, lib, script, &result);
  return result;
}

// Finalizes classes and invokes Dart core library function that completes
// futures of loadLibrary calls (deferred library loading).
DART_EXPORT Dart_Handle Dart_FinalizeLoading(bool complete_futures) {
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  CHECK_CALLBACK_STATE(T);

  I->DoneLoading();

  // TODO(hausner): move the remaining code below (finalization and
  // invoking of _completeDeferredLoads) into Isolate::DoneLoading().

  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(state)) {
    return state;
  }

  I->DoneFinalizing();

#if !defined(PRODUCT)
  // Now that the newly loaded classes are finalized, notify the debugger
  // that new code has been loaded. If there are latent breakpoints in
  // the new code, the debugger convert them to unresolved source breakpoints.
  // The code that completes the futures (invoked below) may call into the
  // newly loaded code and trigger one of these breakpoints.
  I->debugger()->NotifyDoneLoading();
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_enable_mirrors) {
    // Notify mirrors that MirrorSystem.libraries needs to be recomputed.
    const Library& libmirrors = Library::Handle(Z, Library::MirrorsLibrary());
    const Field& dirty_bit = Field::Handle(
        Z, libmirrors.LookupLocalField(String::Handle(String::New("_dirty"))));
    ASSERT(!dirty_bit.IsNull() && dirty_bit.is_static());
    dirty_bit.SetStaticValue(Bool::True());
  }
#endif

  if (complete_futures) {
    const Library& corelib = Library::Handle(Z, Library::CoreLibrary());
    const String& function_name =
        String::Handle(Z, String::New("_completeDeferredLoads"));
    const Function& function =
        Function::Handle(Z, corelib.LookupFunctionAllowPrivate(function_name));
    ASSERT(!function.IsNull());
    const Array& args = Array::empty_array();

    const Object& res =
        Object::Handle(Z, DartEntry::InvokeFunction(function, args));
    I->object_store()->clear_pending_deferred_loads();
    if (res.IsError() || res.IsUnhandledException()) {
      return Api::NewHandle(T, res.raw());
    }
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle
Dart_SetNativeResolver(Dart_Handle library,
                       Dart_NativeEntryResolver resolver,
                       Dart_NativeEntrySymbol symbol) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  lib.set_native_entry_resolver(resolver);
  lib.set_native_entry_symbol_resolver(symbol);
  return Api::Success();
}

DART_EXPORT Dart_Handle
Dart_GetNativeResolver(Dart_Handle library,
                       Dart_NativeEntryResolver* resolver) {
  if (resolver == NULL) {
    RETURN_NULL_ERROR(resolver);
  }
  *resolver = NULL;
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  *resolver = lib.native_entry_resolver();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetNativeSymbol(Dart_Handle library,
                                             Dart_NativeEntrySymbol* resolver) {
  if (resolver == NULL) {
    RETURN_NULL_ERROR(resolver);
  }
  *resolver = NULL;
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  *resolver = lib.native_entry_symbol_resolver();
  return Api::Success();
}

// --- Peer support ---

DART_EXPORT Dart_Handle Dart_GetPeer(Dart_Handle object, void** peer) {
  if (peer == NULL) {
    RETURN_NULL_ERROR(peer);
  }
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& obj = thread->ObjectHandle();
  obj = Api::UnwrapHandle(object);
  if (obj.IsNull() || obj.IsNumber() || obj.IsBool()) {
    const char* msg =
        "%s: argument 'object' cannot be a subtype of Null, num, or bool";
    return Api::NewError(msg, CURRENT_FUNC);
  }
  {
    NoSafepointScope no_safepoint;
    RawObject* raw_obj = obj.raw();
    *peer = thread->isolate()->heap()->GetPeer(raw_obj);
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_SetPeer(Dart_Handle object, void* peer) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& obj = thread->ObjectHandle();
  obj = Api::UnwrapHandle(object);
  if (obj.IsNull() || obj.IsNumber() || obj.IsBool()) {
    const char* msg =
        "%s: argument 'object' cannot be a subtype of Null, num, or bool";
    return Api::NewError(msg, CURRENT_FUNC);
  }
  {
    NoSafepointScope no_safepoint;
    RawObject* raw_obj = obj.raw();
    thread->isolate()->heap()->SetPeer(raw_obj, peer);
  }
  return Api::Success();
}

// --- Dart Front-End (Kernel) support ---

DART_EXPORT bool Dart_IsKernelIsolate(Dart_Isolate isolate) {
#ifdef DART_PRECOMPILED_RUNTIME
  return false;
#else
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  return KernelIsolate::IsKernelIsolate(iso);
#endif
}

DART_EXPORT bool Dart_KernelIsolateIsRunning() {
#ifdef DART_PRECOMPILED_RUNTIME
  return false;
#else
  return KernelIsolate::IsRunning();
#endif
}

DART_EXPORT Dart_Port Dart_KernelPort() {
#ifdef DART_PRECOMPILED_RUNTIME
  return false;
#else
  return KernelIsolate::KernelPort();
#endif
}

DART_EXPORT Dart_KernelCompilationResult
Dart_CompileToKernel(const char* script_uri, const char* platform_kernel) {
#ifdef DART_PRECOMPILED_RUNTIME
  Dart_KernelCompilationResult result;
  result.status = Dart_KernelCompilationStatus_Unknown;
  result.error = strdup("Dart_CompileToKernel is unsupported.");
  return result;
#else
  return KernelIsolate::CompileToKernel(script_uri, platform_kernel);
#endif
}

DART_EXPORT Dart_KernelCompilationResult
Dart_CompileSourcesToKernel(const char* script_uri,
                            const char* platform_kernel,
                            int source_files_count,
                            Dart_SourceFile sources[],
                            bool incremental_compile) {
#ifdef DART_PRECOMPILED_RUNTIME
  Dart_KernelCompilationResult result;
  result.status = Dart_KernelCompilationStatus_Unknown;
  result.error = strdup("Dart_CompileSourcesToKernel is unsupported.");
  return result;
#else
  return KernelIsolate::CompileToKernel(script_uri, platform_kernel,
                                        source_files_count, sources,
                                        incremental_compile);
#endif
}

// --- Service support ---

DART_EXPORT bool Dart_IsServiceIsolate(Dart_Isolate isolate) {
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  return ServiceIsolate::IsServiceIsolate(iso);
}

DART_EXPORT Dart_Port Dart_ServiceWaitForLoadPort() {
  return ServiceIsolate::WaitForLoadPort();
}

DART_EXPORT int64_t Dart_TimelineGetMicros() {
  return OS::GetCurrentMonotonicMicros();
}

#if defined(PRODUCT)
DART_EXPORT void Dart_RegisterIsolateServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
  return;
}

DART_EXPORT void Dart_RegisterRootServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
  return;
}

DART_EXPORT void Dart_SetEmbedderInformationCallback(
    Dart_EmbedderInformationCallback callback) {
  return;
}

DART_EXPORT Dart_Handle Dart_SetServiceStreamCallbacks(
    Dart_ServiceStreamListenCallback listen_callback,
    Dart_ServiceStreamCancelCallback cancel_callback) {
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_ServiceSendDataEvent(const char* stream_id,
                                                  const char* event_kind,
                                                  const uint8_t* bytes,
                                                  intptr_t bytes_length) {
  return Api::Success();
}

DART_EXPORT Dart_Handle
Dart_SetFileModifiedCallback(Dart_FileModifiedCallback file_mod_callback) {
  return Api::Success();
}

DART_EXPORT bool Dart_IsReloading() {
  return false;
}

DART_EXPORT void Dart_GlobalTimelineSetRecordedStreams(int64_t stream_mask) {
  return;
}

DART_EXPORT void Dart_SetEmbedderTimelineCallbacks(
    Dart_EmbedderTimelineStartRecording start_recording,
    Dart_EmbedderTimelineStopRecording stop_recording) {
  return;
}

DART_EXPORT bool Dart_GlobalTimelineGetTrace(Dart_StreamConsumer consumer,
                                             void* user_data) {
  return false;
}

DART_EXPORT void Dart_TimelineEvent(const char* label,
                                    int64_t timestamp0,
                                    int64_t timestamp1_or_async_id,
                                    Dart_Timeline_Event_Type type,
                                    intptr_t argument_count,
                                    const char** argument_names,
                                    const char** argument_values) {
  return;
}
#else   // defined(PRODUCT)
DART_EXPORT void Dart_RegisterIsolateServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
  if (FLAG_support_service) {
    Service::RegisterIsolateEmbedderCallback(name, callback, user_data);
  }
}

DART_EXPORT void Dart_RegisterRootServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
  if (FLAG_support_service) {
    Service::RegisterRootEmbedderCallback(name, callback, user_data);
  }
}

DART_EXPORT void Dart_SetEmbedderInformationCallback(
    Dart_EmbedderInformationCallback callback) {
  if (FLAG_support_service) {
    Service::SetEmbedderInformationCallback(callback);
  }
}

DART_EXPORT Dart_Handle Dart_SetServiceStreamCallbacks(
    Dart_ServiceStreamListenCallback listen_callback,
    Dart_ServiceStreamCancelCallback cancel_callback) {
  if (!FLAG_support_service) {
    return Api::Success();
  }
  if (listen_callback != NULL) {
    if (Service::stream_listen_callback() != NULL) {
      return Api::NewError(
          "%s permits only one listen callback to be registered, please "
          "remove the existing callback and then add this callback",
          CURRENT_FUNC);
    }
  } else {
    if (Service::stream_listen_callback() == NULL) {
      return Api::NewError(
          "%s expects 'listen_callback' to be present in the callback set.",
          CURRENT_FUNC);
    }
  }
  if (cancel_callback != NULL) {
    if (Service::stream_cancel_callback() != NULL) {
      return Api::NewError(
          "%s permits only one cancel callback to be registered, please "
          "remove the existing callback and then add this callback",
          CURRENT_FUNC);
    }
  } else {
    if (Service::stream_cancel_callback() == NULL) {
      return Api::NewError(
          "%s expects 'cancel_callback' to be present in the callback set.",
          CURRENT_FUNC);
    }
  }
  Service::SetEmbedderStreamCallbacks(listen_callback, cancel_callback);
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_ServiceSendDataEvent(const char* stream_id,
                                                  const char* event_kind,
                                                  const uint8_t* bytes,
                                                  intptr_t bytes_length) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  if (stream_id == NULL) {
    RETURN_NULL_ERROR(stream_id);
  }
  if (event_kind == NULL) {
    RETURN_NULL_ERROR(event_kind);
  }
  if (bytes == NULL) {
    RETURN_NULL_ERROR(bytes);
  }
  if (bytes_length < 0) {
    return Api::NewError("%s expects argument 'bytes_length' to be >= 0.",
                         CURRENT_FUNC);
  }
  Service::SendEmbedderEvent(I, stream_id, event_kind, bytes, bytes_length);
  return Api::Success();
}

DART_EXPORT Dart_Handle
Dart_SetFileModifiedCallback(Dart_FileModifiedCallback file_modified_callback) {
  if (!FLAG_support_service) {
    return Api::Success();
  }
  if (file_modified_callback != NULL) {
    if (IsolateReloadContext::file_modified_callback() != NULL) {
      return Api::NewError(
          "%s permits only one callback to be registered, please "
          "remove the existing callback and then add this callback",
          CURRENT_FUNC);
    }
  } else {
    if (IsolateReloadContext::file_modified_callback() == NULL) {
      return Api::NewError(
          "%s expects 'file_modified_callback' to be set before it is cleared.",
          CURRENT_FUNC);
    }
  }
  IsolateReloadContext::SetFileModifiedCallback(file_modified_callback);
  return Api::Success();
}

DART_EXPORT bool Dart_IsReloading() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  return isolate->IsReloading();
}

DART_EXPORT void Dart_GlobalTimelineSetRecordedStreams(int64_t stream_mask) {
  if (!FLAG_support_timeline) {
    return;
  }
  const bool api_enabled = (stream_mask & DART_TIMELINE_STREAM_API) != 0;
  const bool compiler_enabled =
      (stream_mask & DART_TIMELINE_STREAM_COMPILER) != 0;
  const bool dart_enabled = (stream_mask & DART_TIMELINE_STREAM_DART) != 0;
  const bool debugger_enabled =
      (stream_mask & DART_TIMELINE_STREAM_DEBUGGER) != 0;
  const bool embedder_enabled =
      (stream_mask & DART_TIMELINE_STREAM_EMBEDDER) != 0;
  const bool gc_enabled = (stream_mask & DART_TIMELINE_STREAM_GC) != 0;
  const bool isolate_enabled =
      (stream_mask & DART_TIMELINE_STREAM_ISOLATE) != 0;
  const bool vm_enabled = (stream_mask & DART_TIMELINE_STREAM_VM) != 0;
  Timeline::SetStreamAPIEnabled(api_enabled);
  Timeline::SetStreamCompilerEnabled(compiler_enabled);
  Timeline::SetStreamDartEnabled(dart_enabled);
  Timeline::SetStreamDebuggerEnabled(debugger_enabled);
  Timeline::SetStreamEmbedderEnabled(embedder_enabled);
  Timeline::SetStreamGCEnabled(gc_enabled);
  Timeline::SetStreamIsolateEnabled(isolate_enabled);
  Timeline::SetStreamVMEnabled(vm_enabled);
}

static void StartStreamToConsumer(Dart_StreamConsumer consumer,
                                  void* user_data,
                                  const char* stream_name) {
  // Start stream.
  consumer(Dart_StreamConsumer_kStart, stream_name, NULL, 0, user_data);
}

static void FinishStreamToConsumer(Dart_StreamConsumer consumer,
                                   void* user_data,
                                   const char* stream_name) {
  // Finish stream.
  consumer(Dart_StreamConsumer_kFinish, stream_name, NULL, 0, user_data);
}

static void DataStreamToConsumer(Dart_StreamConsumer consumer,
                                 void* user_data,
                                 const char* output,
                                 intptr_t output_length,
                                 const char* stream_name) {
  if (output == NULL) {
    return;
  }
  const intptr_t kDataSize = 64 * KB;
  intptr_t cursor = 0;
  intptr_t remaining = output_length;
  while (remaining >= kDataSize) {
    consumer(Dart_StreamConsumer_kData, stream_name,
             reinterpret_cast<const uint8_t*>(&output[cursor]), kDataSize,
             user_data);
    cursor += kDataSize;
    remaining -= kDataSize;
  }
  if (remaining > 0) {
    ASSERT(remaining < kDataSize);
    consumer(Dart_StreamConsumer_kData, stream_name,
             reinterpret_cast<const uint8_t*>(&output[cursor]), remaining,
             user_data);
    cursor += remaining;
    remaining -= remaining;
  }
  ASSERT(cursor == output_length);
  ASSERT(remaining == 0);
}

static bool StreamTraceEvents(Dart_StreamConsumer consumer,
                              void* user_data,
                              JSONStream* js) {
  ASSERT(js != NULL);
  // Steal output from JSONStream.
  char* output = NULL;
  intptr_t output_length = 0;
  js->Steal(&output, &output_length);
  if (output_length < 3) {
    // Empty JSON array.
    free(output);
    return false;
  }
  // We want to send the JSON array without the leading '[' or trailing ']'
  // characters.
  ASSERT(output[0] == '[');
  ASSERT(output[output_length - 1] == ']');
  // Replace the ']' with the null character.
  output[output_length - 1] = '\0';
  char* start = &output[1];
  // We are skipping the '['.
  output_length -= 1;

  DataStreamToConsumer(consumer, user_data, start, output_length, "timeline");

  // We stole the JSONStream's output buffer, free it.
  free(output);

  return true;
}

DART_EXPORT void Dart_SetEmbedderTimelineCallbacks(
    Dart_EmbedderTimelineStartRecording start_recording,
    Dart_EmbedderTimelineStopRecording stop_recording) {
  if (!FLAG_support_timeline) {
    return;
  }
  Timeline::set_start_recording_cb(start_recording);
  Timeline::set_stop_recording_cb(stop_recording);
}

DART_EXPORT bool Dart_GlobalTimelineGetTrace(Dart_StreamConsumer consumer,
                                             void* user_data) {
  if (!FLAG_support_timeline) {
    return false;
  }
  // To support various embedders, it must be possible to call this function
  // from a thread for which we have not entered an Isolate and set up a Thread
  // TLS object. Therefore, a Zone may not be available, a StackZone cannot be
  // created, and no ZoneAllocated objects can be allocated.
  if (consumer == NULL) {
    return false;
  }
  TimelineEventRecorder* timeline_recorder = Timeline::recorder();
  if (timeline_recorder == NULL) {
    // Nothing has been recorded.
    return false;
  }
  Timeline::ReclaimCachedBlocksFromThreads();
  bool success = false;
  JSONStream js;
  TimelineEventFilter filter;
  timeline_recorder->PrintTraceEvent(&js, &filter);
  StartStreamToConsumer(consumer, user_data, "timeline");
  if (StreamTraceEvents(consumer, user_data, &js)) {
    success = true;
  }
  FinishStreamToConsumer(consumer, user_data, "timeline");
  return success;
}

DART_EXPORT void Dart_TimelineEvent(const char* label,
                                    int64_t timestamp0,
                                    int64_t timestamp1_or_async_id,
                                    Dart_Timeline_Event_Type type,
                                    intptr_t argument_count,
                                    const char** argument_names,
                                    const char** argument_values) {
  if (!FLAG_support_timeline) {
    return;
  }
  if (type < Dart_Timeline_Event_Begin) {
    return;
  }
  if (type > Dart_Timeline_Event_Flow_End) {
    return;
  }
  TimelineStream* stream = Timeline::GetEmbedderStream();
  ASSERT(stream != NULL);
  TimelineEvent* event = stream->StartEvent();
  if (event == NULL) {
    return;
  }
  label = strdup(label);
  switch (type) {
    case Dart_Timeline_Event_Begin:
      event->Begin(label, timestamp0);
      break;
    case Dart_Timeline_Event_End:
      event->End(label, timestamp0);
      break;
    case Dart_Timeline_Event_Instant:
      event->Instant(label, timestamp0);
      break;
    case Dart_Timeline_Event_Duration:
      event->Duration(label, timestamp0, timestamp1_or_async_id);
      break;
    case Dart_Timeline_Event_Async_Begin:
      event->AsyncBegin(label, timestamp1_or_async_id, timestamp0);
      break;
    case Dart_Timeline_Event_Async_End:
      event->AsyncEnd(label, timestamp1_or_async_id, timestamp0);
      break;
    case Dart_Timeline_Event_Async_Instant:
      event->AsyncInstant(label, timestamp1_or_async_id, timestamp0);
      break;
    case Dart_Timeline_Event_Counter:
      event->Counter(label, timestamp0);
      break;
    case Dart_Timeline_Event_Flow_Begin:
      event->FlowBegin(label, timestamp1_or_async_id, timestamp0);
      break;
    case Dart_Timeline_Event_Flow_Step:
      event->FlowStep(label, timestamp1_or_async_id, timestamp0);
      break;
    case Dart_Timeline_Event_Flow_End:
      event->FlowEnd(label, timestamp1_or_async_id, timestamp0);
      break;
    default:
      FATAL("Unknown Dart_Timeline_Event_Type");
  }
  event->set_owns_label(true);
  event->SetNumArguments(argument_count);
  for (intptr_t i = 0; i < argument_count; i++) {
    event->CopyArgument(i, argument_names[i], argument_values[i]);
  }
  event->Complete();
}
#endif  // defined(PRODUCT)

DART_EXPORT void Dart_SetThreadName(const char* name) {
  OSThread* thread = OSThread::Current();
  if (thread == NULL) {
    // VM is shutting down.
    return;
  }
  thread->SetName(name);
}

DART_EXPORT
Dart_Handle Dart_SaveCompilationTrace(uint8_t** buffer,
                                      intptr_t* buffer_length) {
  API_TIMELINE_DURATION;
  Thread* thread = Thread::Current();
  DARTSCOPE(thread);
  CHECK_NULL(buffer);
  CHECK_NULL(buffer_length);
  CompilationTraceSaver saver(thread->zone());
  ProgramVisitor::VisitFunctions(&saver);
  saver.StealBuffer(buffer, buffer_length);
  return Api::Success();
}

DART_EXPORT
Dart_Handle Dart_LoadCompilationTrace(uint8_t* buffer, intptr_t buffer_length) {
  Thread* thread = Thread::Current();
  API_TIMELINE_DURATION;
  DARTSCOPE(thread);
  CHECK_NULL(buffer);
  CompilationTraceLoader loader(thread);
  const Object& error =
      Object::Handle(loader.CompileTrace(buffer, buffer_length));
  if (error.IsError()) {
    return Api::NewHandle(T, Error::Cast(error).raw());
  }
  return Api::Success();
}

DART_EXPORT
Dart_Handle Dart_SaveJITFeedback(uint8_t** buffer, intptr_t* buffer_length) {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("No JIT feedback to save on an AOT runtime.");
#elif defined(PRODUCT)
  // TOOD(rmacnak): We'd need to include the JSON printing code again.
  return Api::NewError("Dart_SaveJITFeedback not supported in PRODUCT mode.");
#else
  Thread* thread = Thread::Current();
  DARTSCOPE(thread);
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();

  if (buffer == NULL) {
    RETURN_NULL_ERROR(buffer);
  }
  if (buffer_length == NULL) {
    RETURN_NULL_ERROR(buffer_length);
  }

  JSONStream js_stream;
  {
    JSONObject js_profile(&js_stream);
    js_profile.AddProperty("vmVersion", Version::CommitString());
    js_profile.AddProperty("asserts", FLAG_enable_asserts);
    js_profile.AddProperty("typeChecks", FLAG_enable_type_checks);

    {
      JSONArray js_scripts(&js_profile, "scripts");

      const GrowableObjectArray& libraries = GrowableObjectArray::Handle(
          zone, isolate->object_store()->libraries());
      Library& library = Library::Handle(zone);
      Array& scripts = Array::Handle(zone);
      Script& script = Script::Handle(zone);
      String& uri = String::Handle(zone);
      for (intptr_t i = 0; i < libraries.Length(); i++) {
        library ^= libraries.At(i);
        scripts = library.LoadedScripts();
        for (intptr_t j = 0; j < scripts.Length(); j++) {
          script ^= scripts.At(j);
          JSONObject js_script(&js_scripts);
          uri = script.url();
          js_script.AddProperty("uri", uri.ToCString());
          int64_t fp = script.SourceFingerprint();
          js_script.AddProperty64("checksum", fp);
        }
      }
    }

    {
      JSONArray js_classes(&js_profile, "classes");

      ClassTable* classes = isolate->class_table();
      Class& cls = Class::Handle(zone);
      Library& library = Library::Handle(zone);
      String& uri = String::Handle(zone);
      String& name = String::Handle(zone);
      for (intptr_t cid = kNumPredefinedCids; cid < classes->NumCids(); cid++) {
        if (!classes->HasValidClassAt(cid)) continue;
        cls ^= classes->At(cid);
        library = cls.library();
        JSONObject js_class(&js_classes);
        js_class.AddProperty("cid", cid);
        uri = library.url();
        js_class.AddProperty("uri", uri.ToCString());
        name = cls.Name();
        name = String::RemovePrivateKey(name);
        js_class.AddProperty("name", name.ToCString());
      }
    }

    {
      JSONArray js_functions(&js_profile, "functions");

      class JITFeedbackFunctionVisitor : public FunctionVisitor {
       public:
        JITFeedbackFunctionVisitor(JSONArray* js_functions, Zone* zone)
            : js_functions_(js_functions),
              function_(Function::Handle(zone)),
              owner_(Class::Handle(zone)),
              name_(String::Handle(zone)),
              ic_datas_(Array::Handle(zone)),
              ic_data_(ICData::Handle(zone)),
              entry_(Object::Handle(zone)) {}

        void Visit(const Function& function) {
          if (function.usage_counter() == 0) return;

          JSONObject js_function(js_functions_);
          name_ = function.name();
          name_ = String::RemovePrivateKey(name_);
          js_function.AddProperty("name", name_.ToCString());
          owner_ ^= function.Owner();
          js_function.AddProperty("class", owner_.id());
          js_function.AddProperty("tokenPos", function.token_pos().value());
          js_function.AddProperty("kind",
                                  static_cast<intptr_t>(function.kind()));
          intptr_t usage = function.usage_counter();
          if (usage < 0) {
            // Function was in the background compiler's queue.
            usage = FLAG_optimization_counter_threshold;
          }
          js_function.AddProperty("usageCounter", usage);

          ic_datas_ = function.ic_data_array();
          JSONArray js_icdatas(&js_function, "ics");
          if (ic_datas_.IsNull()) return;

          for (intptr_t j = 0; j < ic_datas_.Length(); j++) {
            entry_ = ic_datas_.At(j);
            if (!entry_.IsICData()) continue;  // Skip edge counters.
            ic_data_ ^= entry_.raw();

            JSONObject js_icdata(&js_icdatas);
            js_icdata.AddProperty("deoptId", ic_data_.deopt_id());
            name_ = ic_data_.target_name();
            name_ = String::RemovePrivateKey(name_);
            js_icdata.AddProperty("selector", name_.ToCString());
            js_icdata.AddProperty("isStaticCall", ic_data_.is_static_call());
            intptr_t num_args_checked = ic_data_.NumArgsTested();
            js_icdata.AddProperty("argsTested", num_args_checked);
            JSONArray js_entries(&js_icdata, "entries");
            const intptr_t number_of_checks = ic_data_.NumberOfChecks();
            for (intptr_t check = 0; check < number_of_checks; check++) {
              GrowableArray<intptr_t> class_ids(num_args_checked);
              ic_data_.GetClassIdsAt(check, &class_ids);
              for (intptr_t k = 0; k < num_args_checked; k++) {
                ASSERT(class_ids[k] != kIllegalCid);
                js_entries.AddValue(class_ids[k]);
              }
              js_entries.AddValue(ic_data_.GetCountAt(check));
            }
          }
        }

       private:
        JSONArray* js_functions_;
        Function& function_;
        Class& owner_;
        String& name_;
        Array& ic_datas_;
        ICData& ic_data_;
        Object& entry_;
      };

      JITFeedbackFunctionVisitor visitor(&js_functions, zone);
      ProgramVisitor::VisitFunctions(&visitor);
    }
  }

  js_stream.Steal(reinterpret_cast<char**>(buffer), buffer_length);
  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle Dart_SortClasses() {
  DARTSCOPE(Thread::Current());
  // We don't have mechanisms to change class-ids that are embedded in code and
  // ICData.
  ClassFinalizer::ClearAllCode();
  // Make sure that ICData etc. that have been cleared are also removed from
  // the heap so that they are not found by the heap verifier.
  Isolate::Current()->heap()->CollectAllGarbage();
  ClassFinalizer::SortClasses();
  return Api::Success();
}

DART_EXPORT Dart_Handle
Dart_Precompile(Dart_QualifiedFunctionName entry_points[],
                uint8_t* jit_feedback,
                intptr_t jit_feedback_length) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif defined(TARGET_ARCH_DBC)
  return Api::NewError("AOT compilation is not supported on DBC.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  API_TIMELINE_BEGIN_END;
  DARTSCOPE(Thread::Current());
  if (!FLAG_precompiled_mode) {
    return Api::NewError("Flag --precompilation was not specified.");
  }
  Dart_Handle result = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(T);
  const Error& error = Error::Handle(
      Precompiler::CompileAll(entry_points, jit_feedback, jit_feedback_length));
  if (!error.IsNull()) {
    return Api::NewHandle(T, error.raw());
  }
  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle
Dart_CreateAppAOTSnapshotAsAssembly(uint8_t** assembly_buffer,
                                    intptr_t* assembly_size) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif defined(TARGET_ARCH_DBC)
  return Api::NewError("AOT compilation is not supported on DBC.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  if (I->compilation_allowed()) {
    return Api::NewError(
        "Isolate is not precompiled. "
        "Did you forget to call Dart_Precompile?");
  }
  ASSERT(FLAG_load_deferred_eagerly);
  CHECK_NULL(assembly_buffer);
  CHECK_NULL(assembly_size);

  NOT_IN_PRODUCT(TimelineDurationScope tds2(T, Timeline::GetIsolateStream(),
                                            "WriteAppAOTSnapshot"));
  AssemblyImageWriter image_writer(assembly_buffer, ApiReallocate,
                                   2 * MB /* initial_size */);
  uint8_t* vm_snapshot_data_buffer = NULL;
  uint8_t* isolate_snapshot_data_buffer = NULL;
  FullSnapshotWriter writer(Snapshot::kFullAOT, &vm_snapshot_data_buffer,
                            &isolate_snapshot_data_buffer, ApiReallocate,
                            &image_writer, &image_writer);

  writer.WriteFullSnapshot();
  image_writer.Finalize();
  *assembly_size = image_writer.AssemblySize();

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle
Dart_CreateVMAOTSnapshotAsAssembly(uint8_t** assembly_buffer,
                                   intptr_t* assembly_size) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif defined(TARGET_ARCH_DBC)
  return Api::NewError("AOT compilation is not supported on DBC.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  CHECK_NULL(assembly_buffer);
  CHECK_NULL(assembly_size);

  NOT_IN_PRODUCT(TimelineDurationScope tds2(T, Timeline::GetIsolateStream(),
                                            "WriteVMAOTSnapshot"));
  AssemblyImageWriter image_writer(assembly_buffer, ApiReallocate,
                                   2 * MB /* initial_size */);
  uint8_t* vm_snapshot_data_buffer = NULL;
  FullSnapshotWriter writer(Snapshot::kFullAOT, &vm_snapshot_data_buffer, NULL,
                            ApiReallocate, &image_writer, NULL);

  writer.WriteFullSnapshot();
  *assembly_size = image_writer.AssemblySize();

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle
Dart_CreateAppAOTSnapshotAsBlobs(uint8_t** vm_snapshot_data_buffer,
                                 intptr_t* vm_snapshot_data_size,
                                 uint8_t** vm_snapshot_instructions_buffer,
                                 intptr_t* vm_snapshot_instructions_size,
                                 uint8_t** isolate_snapshot_data_buffer,
                                 intptr_t* isolate_snapshot_data_size,
                                 uint8_t** isolate_snapshot_instructions_buffer,
                                 intptr_t* isolate_snapshot_instructions_size) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif defined(TARGET_ARCH_DBC)
  return Api::NewError("AOT compilation is not supported on DBC.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#elif defined(TARGET_OS_FUCHSIA)
  return Api::NewError(
      "AOT as blobs is not supported on Fuchsia; use dylibs instead.");
#else
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  if (I->compilation_allowed()) {
    return Api::NewError(
        "Isolate is not precompiled. "
        "Did you forget to call Dart_Precompile?");
  }
  ASSERT(FLAG_load_deferred_eagerly);
  CHECK_NULL(vm_snapshot_data_buffer);
  CHECK_NULL(vm_snapshot_data_size);
  CHECK_NULL(vm_snapshot_instructions_buffer);
  CHECK_NULL(vm_snapshot_instructions_size);
  CHECK_NULL(isolate_snapshot_data_buffer);
  CHECK_NULL(isolate_snapshot_data_size);
  CHECK_NULL(isolate_snapshot_instructions_buffer);
  CHECK_NULL(isolate_snapshot_instructions_size);

  NOT_IN_PRODUCT(TimelineDurationScope tds2(T, Timeline::GetIsolateStream(),
                                            "WriteAppAOTSnapshot"));
  BlobImageWriter vm_image_writer(vm_snapshot_instructions_buffer,
                                  ApiReallocate, 2 * MB /* initial_size */);
  BlobImageWriter isolate_image_writer(isolate_snapshot_instructions_buffer,
                                       ApiReallocate,
                                       2 * MB /* initial_size */);
  FullSnapshotWriter writer(Snapshot::kFullAOT, vm_snapshot_data_buffer,
                            isolate_snapshot_data_buffer, ApiReallocate,
                            &vm_image_writer, &isolate_image_writer);

  writer.WriteFullSnapshot();
  *vm_snapshot_data_size = writer.VmIsolateSnapshotSize();
  *vm_snapshot_instructions_size = vm_image_writer.InstructionsBlobSize();
  *isolate_snapshot_data_size = writer.IsolateSnapshotSize();
  *isolate_snapshot_instructions_size =
      isolate_image_writer.InstructionsBlobSize();

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle Dart_CreateCoreJITSnapshotAsBlobs(
    uint8_t** vm_snapshot_data_buffer,
    intptr_t* vm_snapshot_data_size,
    uint8_t** vm_snapshot_instructions_buffer,
    intptr_t* vm_snapshot_instructions_size,
    uint8_t** isolate_snapshot_data_buffer,
    intptr_t* isolate_snapshot_data_size,
    uint8_t** isolate_snapshot_instructions_buffer,
    intptr_t* isolate_snapshot_instructions_size) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("Snapshots with code are not supported on IA32.");
#elif defined(TARGET_ARCH_DBC)
  return Api::NewError("Snapshots with code are not supported on DBC.");
#elif defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("JIT app snapshots cannot be taken from an AOT runtime");
#else
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  if (!FLAG_load_deferred_eagerly) {
    return Api::NewError(
        "Creating full snapshots requires --load_deferred_eagerly");
  }
  CHECK_NULL(vm_snapshot_data_buffer);
  CHECK_NULL(vm_snapshot_data_size);
  CHECK_NULL(vm_snapshot_instructions_buffer);
  CHECK_NULL(vm_snapshot_instructions_size);
  CHECK_NULL(isolate_snapshot_data_buffer);
  CHECK_NULL(isolate_snapshot_data_size);
  CHECK_NULL(isolate_snapshot_instructions_buffer);
  CHECK_NULL(isolate_snapshot_instructions_size);
  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(state)) {
    return state;
  }
  I->StopBackgroundCompiler();

  ProgramVisitor::Dedup();
  Symbols::Compact(I);

  NOT_IN_PRODUCT(TimelineDurationScope tds2(T, Timeline::GetIsolateStream(),
                                            "WriteCoreJITSnapshot"));
  BlobImageWriter vm_image_writer(vm_snapshot_instructions_buffer,
                                  ApiReallocate, 2 * MB /* initial_size */);
  BlobImageWriter isolate_image_writer(isolate_snapshot_instructions_buffer,
                                       ApiReallocate,
                                       2 * MB /* initial_size */);
  FullSnapshotWriter writer(Snapshot::kFullJIT, vm_snapshot_data_buffer,
                            isolate_snapshot_data_buffer, ApiReallocate,
                            &vm_image_writer, &isolate_image_writer);
  writer.WriteFullSnapshot();

  *vm_snapshot_data_size = writer.VmIsolateSnapshotSize();
  *vm_snapshot_instructions_size = vm_image_writer.InstructionsBlobSize();
  *isolate_snapshot_data_size = writer.IsolateSnapshotSize();
  *isolate_snapshot_instructions_size =
      isolate_image_writer.InstructionsBlobSize();

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle
Dart_CreateAppJITSnapshotAsBlobs(uint8_t** isolate_snapshot_data_buffer,
                                 intptr_t* isolate_snapshot_data_size,
                                 uint8_t** isolate_snapshot_instructions_buffer,
                                 intptr_t* isolate_snapshot_instructions_size) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("Snapshots with code are not supported on IA32.");
#elif defined(TARGET_ARCH_DBC)
  return Api::NewError("Snapshots with code are not supported on DBC.");
#elif defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("JIT app snapshots cannot be taken from an AOT runtime");
#else
  API_TIMELINE_DURATION;
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  if (!FLAG_load_deferred_eagerly) {
    return Api::NewError(
        "Creating full snapshots requires --load_deferred_eagerly");
  }
  CHECK_NULL(isolate_snapshot_data_buffer);
  CHECK_NULL(isolate_snapshot_data_size);
  CHECK_NULL(isolate_snapshot_instructions_buffer);
  CHECK_NULL(isolate_snapshot_instructions_size);
  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(state)) {
    return state;
  }
  I->StopBackgroundCompiler();

  ProgramVisitor::Dedup();
  Symbols::Compact(I);

  NOT_IN_PRODUCT(TimelineDurationScope tds2(T, Timeline::GetIsolateStream(),
                                            "WriteAppJITSnapshot"));
  BlobImageWriter isolate_image_writer(isolate_snapshot_instructions_buffer,
                                       ApiReallocate,
                                       2 * MB /* initial_size */);
  FullSnapshotWriter writer(Snapshot::kFullJIT, NULL,
                            isolate_snapshot_data_buffer, ApiReallocate, NULL,
                            &isolate_image_writer);
  writer.WriteFullSnapshot();

  *isolate_snapshot_data_size = writer.IsolateSnapshotSize();
  *isolate_snapshot_instructions_size =
      isolate_image_writer.InstructionsBlobSize();

  return Api::Success();
#endif
}

DART_EXPORT bool Dart_IsPrecompiledRuntime() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return true;
#else
  return false;
#endif
}

DART_EXPORT void Dart_DumpNativeStackTrace(void* context) {
#ifndef PRODUCT
  Profiler::DumpStackTrace(context);
#endif
}

}  // namespace dart
