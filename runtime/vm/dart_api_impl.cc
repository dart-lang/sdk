// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "include/dart_mirrors_api.h"
#include "include/dart_native_api.h"

#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/debuginfo.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os_thread.h"
#include "vm/port.h"
#include "vm/precompiler.h"
#include "vm/profiler.h"
#include "vm/resolver.h"
#include "vm/reusable_handles.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/service.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/timer.h"
#include "vm/unicode.h"
#include "vm/verifier.h"
#include "vm/version.h"

namespace dart {

// Facilitate quick access to the current zone once we have the curren thread.
#define Z (T->zone())


DECLARE_FLAG(bool, load_deferred_eagerly);
DECLARE_FLAG(bool, print_class_table);
DECLARE_FLAG(bool, verify_handles);
#if defined(DART_NO_SNAPSHOT)
DEFINE_FLAG(bool, check_function_fingerprints, true,
            "Check function fingerprints");
#endif  // defined(DART_NO_SNAPSHOT).
DEFINE_FLAG(bool, trace_api, false,
            "Trace invocation of API calls (debug mode only)");
DEFINE_FLAG(bool, verify_acquired_data, false,
            "Verify correct API acquire/release of typed data.");

ThreadLocalKey Api::api_native_key_ = OSThread::kUnsetThreadLocalKey;
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


#if defined(DEBUG)
// An object visitor which will iterate over all the function objects in the
// heap and check if the result type and parameter types are canonicalized
// or not. An assertion is raised if a type is not canonicalized.
class FunctionVisitor : public ObjectVisitor {
 public:
  explicit FunctionVisitor(Isolate* isolate) :
      ObjectVisitor(isolate),
      classHandle_(Class::Handle(isolate)),
      funcHandle_(Function::Handle(isolate)),
      typeHandle_(AbstractType::Handle(isolate)) {}

  void VisitObject(RawObject* obj) {
    if (obj->IsFunction()) {
      funcHandle_ ^= obj;
      classHandle_ ^= funcHandle_.Owner();
      // Verify that the result type of a function is canonical or a
      // TypeParameter.
      typeHandle_ ^= funcHandle_.result_type();
      ASSERT(typeHandle_.IsNull() ||
             !typeHandle_.IsResolved() ||
             typeHandle_.IsTypeParameter() ||
             typeHandle_.IsCanonical());
      // Verify that the types in the function signature are all canonical or
      // a TypeParameter.
      const intptr_t num_parameters = funcHandle_.NumParameters();
      for (intptr_t i = 0; i < num_parameters; i++) {
        typeHandle_ = funcHandle_.ParameterTypeAt(i);
        ASSERT(typeHandle_.IsTypeParameter() ||
               !typeHandle_.IsResolved() ||
               typeHandle_.IsCanonical());
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
    if (obj_class.IsSubtypeOf(Object::null_type_arguments(),
                              list_class,
                              Object::null_type_arguments(),
                              &malformed_type_error)) {
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
    if (obj_class.IsSubtypeOf(Object::null_type_arguments(),
                              map_class,
                              Object::null_type_arguments(),
                              &malformed_type_error)) {
      ASSERT(malformed_type_error.IsNull());  // Type is a raw Map.
      return instance.raw();
    }
  }
  return Instance::null();
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
  Isolate* isolate = arguments->thread()->isolate();
  ASSERT(isolate == Isolate::Current());
  *peer = NULL;
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& obj = isolate->ObjectHandle();
  obj = arguments->NativeArgAt(arg_index);
  if (RawObject::IsStringClassId(obj.GetClassId())) {
    ASSERT(isolate->api_state() &&
           isolate->api_state()->top_scope() != NULL);
    *str = Api::NewHandle(isolate, obj.raw());
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
  Isolate* isolate = arguments->thread()->isolate();
  ASSERT(isolate == Isolate::Current());
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& obj = isolate->ObjectHandle();
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
  Isolate* isolate = arguments->thread()->isolate();
  ASSERT(isolate == Isolate::Current());
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& obj = isolate->ObjectHandle();
  obj = arguments->NativeArgAt(arg_index);
  intptr_t cid = obj.GetClassId();
  if (cid == kBigintCid) {
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
  Isolate* isolate = arguments->thread()->isolate();
  ASSERT(isolate == Isolate::Current());
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& obj = isolate->ObjectHandle();
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
  if (Api::GetNativeFieldsOfArgument(arguments,
                                     arg_index,
                                     num_fields,
                                     field_values)) {
    return Api::Success();
  }
  Isolate* isolate = arguments->thread()->isolate();
  ASSERT(isolate == Isolate::Current());
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& obj = isolate->ObjectHandle();
  obj = arguments->NativeArgAt(arg_index);
  if (obj.IsNull()) {
    memset(field_values, 0, (num_fields * sizeof(field_values[0])));
    return Api::Success();
  }
  // We did not succeed in extracting the native fields report the
  // appropriate error.
  if (!obj.IsInstance()) {
    return Api::NewError("%s expects argument at index '%d' to be of"
                         " type Instance.", current_func, arg_index);
  }
  const Instance& instance = Instance::Cast(obj);
  int field_count = instance.NumNativeFields();
  ASSERT(num_fields != field_count);
  return Api::NewError(
      "%s: expected %d 'num_fields' but was passed in %d.",
      current_func, field_count, num_fields);
}


Heap::Space SpaceForExternal(Isolate* isolate, intptr_t size) {
  Heap* heap = isolate->heap();
  // If 'size' would be a significant fraction of new space, then use old.
  static const int kExtNewRatio = 16;
  if (size > (heap->CapacityInWords(Heap::kNew) * kWordSize) / kExtNewRatio) {
    return Heap::kOld;
  } else {
    return Heap::kNew;
  }
}


static RawObject* Send0Arg(const Instance& receiver,
                           const String& selector) {
  const intptr_t kNumArgs = 1;
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kNumArgs)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver, selector, args_desc));
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
  const intptr_t kNumArgs = 2;
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kNumArgs)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver, selector, args_desc));
  if (function.IsNull()) {
    return ApiError::New(String::Handle(String::New("")));
  }
  const Array& args = Array::Handle(Array::New(kNumArgs));
  args.SetAt(0, receiver);
  args.SetAt(1, argument);
  return DartEntry::InvokeFunction(function, args);
}


WeakReferenceSetBuilder* ApiState::NewWeakReferenceSetBuilder() {
  return new WeakReferenceSetBuilder(this);
}


void ApiState::DelayWeakReferenceSet(WeakReferenceSet* reference_set) {
  WeakReferenceSet::Push(reference_set, &delayed_weak_reference_sets_);
}


Dart_Handle Api::InitNewHandle(Isolate* isolate, RawObject* raw) {
  LocalHandles* local_handles = Api::TopScope(isolate)->local_handles();
  ASSERT(local_handles != NULL);
  LocalHandle* ref = local_handles->AllocateHandle();
  ref->set_raw(raw);
  return ref->apiHandle();
}


Dart_Handle Api::NewHandle(Isolate* isolate, RawObject* raw) {
  if (raw == Object::null()) {
    return Null();
  }
  if (raw == Bool::True().raw()) {
    return True();
  }
  if (raw == Bool::False().raw()) {
    return False();
  }
  return InitNewHandle(isolate, raw);
}


RawObject* Api::UnwrapHandle(Dart_Handle object) {
#if defined(DEBUG)
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ASSERT(!FLAG_verify_handles ||
         state->IsValidLocalHandle(object) ||
         Dart::IsReadOnlyApiHandle(object));
  ASSERT(FinalizablePersistentHandle::raw_offset() == 0 &&
         PersistentHandle::raw_offset() == 0 &&
         LocalHandle::raw_offset() == 0);
#endif
  return (reinterpret_cast<LocalHandle*>(object))->raw();
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
    const ReusableObjectHandleScope& reuse, Dart_Handle dart_handle) {
  Object& ref = reuse.Handle();
  ref = Api::UnwrapHandle(dart_handle);
  if (ref.IsInstance()) {
    return Instance::Cast(ref);
  }
  return Object::null_instance();
}


Dart_Handle Api::CheckAndFinalizePendingClasses(Isolate* isolate) {
  if (!isolate->AllowClassFinalization()) {
    // Class finalization is blocked for the isolate. Do nothing.
    return Api::Success();
  }
  if (ClassFinalizer::ProcessPendingClasses()) {
    return Api::Success();
  }
  ASSERT(isolate->object_store()->sticky_error() != Object::null());
  return Api::NewHandle(isolate, isolate->object_store()->sticky_error());
}


Dart_Isolate Api::CastIsolate(Isolate* isolate) {
  return reinterpret_cast<Dart_Isolate>(isolate);
}


Dart_Handle Api::NewError(const char* format, ...) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);

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
  return Api::NewHandle(I, ApiError::New(message));
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


ApiLocalScope* Api::TopScope(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  ASSERT(scope != NULL);
  return scope;
}


void Api::InitOnce() {
  ASSERT(api_native_key_ == OSThread::kUnsetThreadLocalKey);
  api_native_key_ = OSThread::CreateThreadLocal();
  ASSERT(api_native_key_ != OSThread::kUnsetThreadLocalKey);
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
    if (cid > kNumPredefinedCids) {
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
    if (cid > kNumPredefinedCids) {
      RawTypedData* native_fields = *reinterpret_cast<RawTypedData**>(
          RawObject::ToAddr(raw_obj) + sizeof(RawObject));
      if (native_fields == TypedData::null()) {
        memset(field_values, 0, (num_fields * sizeof(field_values[0])));
      } else if (num_fields == Smi::Value(native_fields->ptr()->length_)) {
        intptr_t* native_values =
            bit_cast<intptr_t*, uint8_t*>(native_fields->ptr()->data());
        memmove(field_values,
                native_values,
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
  ASSERT(state->IsValidWeakPersistentHandle(handle) ||
         state->IsValidPrologueWeakPersistentHandle(handle));
#endif
  return reinterpret_cast<FinalizablePersistentHandle*>(handle);
}


void FinalizablePersistentHandle::Finalize(
    Isolate* isolate, FinalizablePersistentHandle* handle) {
  if (!handle->raw()->IsHeapObject()) {
    return;
  }
  Dart_WeakPersistentHandleFinalizer callback = handle->callback();
  ASSERT(callback != NULL);
  void* peer = handle->peer();
  Dart_WeakPersistentHandle object = handle->apiHandle();
  (*callback)(isolate->init_callback_data(), object, peer);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  if (handle->IsPrologueWeakPersistent()) {
    state->prologue_weak_persistent_handles().FreeHandle(handle);
  } else {
    state->weak_persistent_handles().FreeHandle(handle);
  }
}


// --- Handles ---

DART_EXPORT bool Dart_IsError(Dart_Handle handle) {
  TRACE_API_CALL(CURRENT_FUNC);
  return RawObject::IsErrorClassId(Api::ClassId(handle));
}


DART_EXPORT bool Dart_IsApiError(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(object) == kApiErrorCid;
}


DART_EXPORT bool Dart_IsUnhandledExceptionError(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(object) == kUnhandledExceptionCid;
}


DART_EXPORT bool Dart_IsCompilationError(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(object) == kLanguageErrorCid;
}


DART_EXPORT bool Dart_IsFatalError(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(object) == kUnwindErrorCid;
}


DART_EXPORT const char* Dart_GetError(Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  if (obj.IsError()) {
    const Error& error = Error::Cast(obj);
    const char* str = error.ToErrorCString();
    intptr_t len = strlen(str) + 1;
    char* str_copy = Api::TopScope(I)->zone()->Alloc<char>(len);
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
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  return obj.IsUnhandledException();
}


DART_EXPORT Dart_Handle Dart_ErrorGetException(Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  if (obj.IsUnhandledException()) {
    const UnhandledException& error = UnhandledException::Cast(obj);
    return Api::NewHandle(I, error.exception());
  } else if (obj.IsError()) {
    return Api::NewError("This error is not an unhandled exception error.");
  } else {
    return Api::NewError("Can only get exceptions from error handles.");
  }
}


DART_EXPORT Dart_Handle Dart_ErrorGetStacktrace(Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  if (obj.IsUnhandledException()) {
    const UnhandledException& error = UnhandledException::Cast(obj);
    return Api::NewHandle(I, error.stacktrace());
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
  CHECK_CALLBACK_STATE(I);

  const String& message = String::Handle(Z, String::New(error));
  return Api::NewHandle(I, ApiError::New(message));
}


DART_EXPORT Dart_Handle Dart_NewUnhandledExceptionError(Dart_Handle exception) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);

  Instance& obj = Instance::Handle(Z);
  intptr_t class_id = Api::ClassId(exception);
  if ((class_id == kApiErrorCid) || (class_id == kLanguageErrorCid)) {
    obj = String::New(::Dart_GetError(exception));
  } else {
    obj = Api::UnwrapInstanceHandle(I, exception).raw();
    if (obj.IsNull()) {
      RETURN_TYPE_ERROR(I, exception, Instance);
    }
  }
  const Stacktrace& stacktrace = Stacktrace::Handle(Z);
  return Api::NewHandle(I, UnhandledException::New(obj, stacktrace));
}


DART_EXPORT Dart_Handle Dart_PropagateError(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  {
    const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
    if (!obj.IsError()) {
      return Api::NewError(
          "%s expects argument 'handle' to be an error handle.  "
          "Did you forget to check Dart_IsError first?",
          CURRENT_FUNC);
    }
  }
  if (isolate->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // propagate an error here.
    return Api::NewError("No Dart frames on stack, cannot propagate error.");
  }

  // Unwind all the API scopes till the exit frame before propagating.
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  const Error* error;
  {
    // We need to preserve the error object across the destruction of zones
    // when the ApiScopes are unwound.  By using NoSafepointScope, we can ensure
    // that GC won't touch the raw error object before creating a valid
    // handle for it in the surviving zone.
    NoSafepointScope no_safepoint;
    RawError* raw_error = Api::UnwrapErrorHandle(isolate, handle).raw();
    state->UnwindScopes(isolate->top_exit_frame_info());
    error = &Error::Handle(isolate, raw_error);
  }
  Exceptions::PropagateError(*error);
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
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  if (obj.IsString()) {
    return Api::NewHandle(I, obj.raw());
  } else if (obj.IsInstance()) {
    CHECK_CALLBACK_STATE(I);
    const Instance& receiver = Instance::Cast(obj);
    return Api::NewHandle(I, DartLibraryCalls::ToString(receiver));
  } else {
    CHECK_CALLBACK_STATE(I);
    // This is a VM internal object. Call the C++ method of printing.
    return Api::NewHandle(I, String::New(obj.ToCString()));
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


DART_EXPORT uint64_t Dart_IdentityHash(Dart_Handle obj) {
  DARTSCOPE(Thread::Current());

  const Object& object = Object::Handle(Z, Api::UnwrapHandle(obj));
  if (!object.IsInstance() && !object.IsNull()) {
    return 0;
  }

  const Library& libcore = Library::Handle(Z, Library::CoreLibrary());
  const String& function_name = String::Handle(Z,
                                               String::New("identityHashCode"));
  const Function& function =
      Function::Handle(Z, libcore.LookupFunctionAllowPrivate(function_name));
  if (function.IsNull()) {
    UNREACHABLE();
    return 0;
  }

  const Array& arguments = Array::Handle(Z, Array::New(1));
  arguments.SetAt(0, object);
  const Object& result =
      Object::Handle(Z, DartEntry::InvokeFunction(function, arguments));

  if (result.IsSmi()) {
    return Smi::Cast(result).Value();
  }
  if (result.IsMint()) {
    const Mint& mint = Mint::Cast(result);
    if (!mint.IsNegative()) {
      return mint.AsInt64Value();
    }
  }
  if (result.IsBigint()) {
    const Bigint& bigint = Bigint::Cast(result);
    if (bigint.FitsIntoUint64()) {
      return bigint.AsUint64Value();
    }
  }
  return 0;
}


DART_EXPORT Dart_Handle Dart_HandleFromPersistent(
    Dart_PersistentHandle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  PersistentHandle* ref = PersistentHandle::Cast(object);
  return Api::NewHandle(isolate, ref->raw());
}


DART_EXPORT Dart_Handle Dart_HandleFromWeakPersistent(
    Dart_WeakPersistentHandle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  FinalizablePersistentHandle* weak_ref =
      FinalizablePersistentHandle::Cast(object);
  return Api::NewHandle(isolate, weak_ref->raw());
}


DART_EXPORT Dart_PersistentHandle Dart_NewPersistentHandle(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
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
  ApiState* state = I->api_state();
  ASSERT(state != NULL);
  ASSERT(state->IsValidPersistentHandle(obj1));
  const Object& obj2_ref = Object::Handle(Z, Api::UnwrapHandle(obj2));
  PersistentHandle* obj1_ref = PersistentHandle::Cast(obj1);
  obj1_ref->set_raw(obj2_ref);
}


static Dart_WeakPersistentHandle AllocateFinalizableHandle(
    Isolate* isolate,
    Dart_Handle object,
    bool is_prologue,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback) {
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& ref = isolate->ObjectHandle();
  ref = Api::UnwrapHandle(object);
  FinalizablePersistentHandle* finalizable_ref =
      FinalizablePersistentHandle::New(isolate,
                                       is_prologue,
                                       ref,
                                       peer,
                                       callback,
                                       external_allocation_size);
  return finalizable_ref->apiHandle();
}


DART_EXPORT Dart_WeakPersistentHandle Dart_NewWeakPersistentHandle(
    Dart_Handle object,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (callback == NULL) {
    return NULL;
  }
  return AllocateFinalizableHandle(isolate,
                                   object,
                                   false,
                                   peer,
                                   external_allocation_size,
                                   callback);
}


DART_EXPORT Dart_WeakPersistentHandle Dart_NewPrologueWeakPersistentHandle(
    Dart_Handle object,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (callback == NULL) {
    return NULL;
  }
  return AllocateFinalizableHandle(isolate,
                                   object,
                                   true,
                                   peer,
                                   external_allocation_size,
                                   callback);
}


DART_EXPORT void Dart_DeletePersistentHandle(Dart_PersistentHandle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
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
  ASSERT(isolate == Isolate::Current());
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  FinalizablePersistentHandle* weak_ref =
      FinalizablePersistentHandle::Cast(object);
  weak_ref->EnsureFreeExternal(isolate);
  if (weak_ref->IsPrologueWeakPersistent()) {
    ASSERT(state->IsValidPrologueWeakPersistentHandle(object));
    state->prologue_weak_persistent_handles().FreeHandle(weak_ref);
  } else {
    ASSERT(!state->IsValidPrologueWeakPersistentHandle(object));
    state->weak_persistent_handles().FreeHandle(weak_ref);
  }
}


DART_EXPORT bool Dart_IsPrologueWeakPersistentHandle(
    Dart_WeakPersistentHandle object) {
  FinalizablePersistentHandle* weak_ref =
      FinalizablePersistentHandle::Cast(object);
  return weak_ref->IsPrologueWeakPersistent();
}


DART_EXPORT Dart_WeakReferenceSetBuilder Dart_NewWeakReferenceSetBuilder() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  return reinterpret_cast<Dart_WeakReferenceSetBuilder>(
      state->NewWeakReferenceSetBuilder());
}


DART_EXPORT Dart_WeakReferenceSet Dart_NewWeakReferenceSet(
    Dart_WeakReferenceSetBuilder set_builder,
    Dart_WeakPersistentHandle key,
    Dart_WeakPersistentHandle value) {
  ASSERT(set_builder != NULL && key != NULL);
  WeakReferenceSetBuilder* builder =
      reinterpret_cast<WeakReferenceSetBuilder*>(set_builder);
  ApiState* state = builder->api_state();
  ASSERT(state == Isolate::Current()->api_state());
  WeakReferenceSet* reference_set = builder->NewWeakReferenceSet();
  reference_set->AppendKey(key);
  if (value != NULL) {
    reference_set->AppendValue(value);
  }
  state->DelayWeakReferenceSet(reference_set);
  return reinterpret_cast<Dart_WeakReferenceSet>(reference_set);
}


DART_EXPORT Dart_Handle Dart_AppendToWeakReferenceSet(
    Dart_WeakReferenceSet reference_set,
    Dart_WeakPersistentHandle key,
    Dart_WeakPersistentHandle value) {
  ASSERT(reference_set != NULL);
  WeakReferenceSet* set = reinterpret_cast<WeakReferenceSet*>(reference_set);
  set->Append(key, value);
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_AppendKeyToWeakReferenceSet(
    Dart_WeakReferenceSet reference_set,
    Dart_WeakPersistentHandle key) {
  ASSERT(reference_set != NULL);
  WeakReferenceSet* set = reinterpret_cast<WeakReferenceSet*>(reference_set);
  set->AppendKey(key);
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_AppendValueToWeakReferenceSet(
    Dart_WeakReferenceSet reference_set,
    Dart_WeakPersistentHandle value) {
  ASSERT(reference_set != NULL);
  WeakReferenceSet* set = reinterpret_cast<WeakReferenceSet*>(reference_set);
  set->AppendValue(value);
  return Api::Success();
}


// --- Garbage Collection Callbacks --

DART_EXPORT Dart_Handle Dart_SetGcCallbacks(
    Dart_GcPrologueCallback prologue_callback,
    Dart_GcEpilogueCallback epilogue_callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (prologue_callback != NULL) {
    if (isolate->gc_prologue_callback() != NULL) {
      return Api::NewError(
          "%s permits only one gc prologue callback to be registered, please "
          "remove the existing callback and then add this callback",
          CURRENT_FUNC);
    }
  } else {
    if (isolate->gc_prologue_callback() == NULL) {
      return Api::NewError(
          "%s expects 'prologue_callback' to be present in the callback set.",
          CURRENT_FUNC);
    }
  }
  if (epilogue_callback != NULL) {
    if (isolate->gc_epilogue_callback() != NULL) {
      return Api::NewError(
          "%s permits only one gc epilogue callback to be registered, please "
          "remove the existing callback and then add this callback",
          CURRENT_FUNC);
    }
  } else {
    if (isolate->gc_epilogue_callback() == NULL) {
      return Api::NewError(
          "%s expects 'epilogue_callback' to be present in the callback set.",
          CURRENT_FUNC);
    }
  }
  isolate->set_gc_prologue_callback(prologue_callback);
  isolate->set_gc_epilogue_callback(epilogue_callback);
  return Api::Success();
}


class PrologueWeakVisitor : public HandleVisitor {
 public:
  PrologueWeakVisitor(Isolate* isolate,
                      Dart_GcPrologueWeakHandleCallback callback)
      :  HandleVisitor(isolate),
         callback_(callback) {
  }

  void VisitHandle(uword addr) {
    NoSafepointScope no_safepoint;
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    RawObject* raw_obj = handle->raw();
    if (raw_obj->IsHeapObject()) {
      ASSERT(handle->IsPrologueWeakPersistent());
      ReusableInstanceHandleScope reused_instance_handle(isolate());
      Instance& instance = reused_instance_handle.Handle();
      instance ^= reinterpret_cast<RawInstance*>(handle->raw());
      intptr_t num_native_fields = instance.NumNativeFields();
      intptr_t* native_fields = instance.NativeFieldsDataAddr();
      if (native_fields != NULL) {
        callback_(isolate()->init_callback_data(),
                  reinterpret_cast<Dart_WeakPersistentHandle>(addr),
                  num_native_fields,
                  native_fields);
      }
    }
  }

 private:
  Dart_GcPrologueWeakHandleCallback callback_;

  DISALLOW_COPY_AND_ASSIGN(PrologueWeakVisitor);
};


DART_EXPORT Dart_Handle Dart_VisitPrologueWeakHandles(
    Dart_GcPrologueWeakHandleCallback callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  PrologueWeakVisitor visitor(isolate, callback);
  isolate->VisitPrologueWeakPersistentHandles(&visitor);
  return Api::Success();
}


// --- Initialization and Globals ---

DART_EXPORT const char* Dart_VersionString() {
  return Version::String();
}

DART_EXPORT bool Dart_Initialize(
    const uint8_t* vm_isolate_snapshot,
    const uint8_t* instructions_snapshot,
    Dart_IsolateCreateCallback create,
    Dart_IsolateInterruptCallback interrupt,
    Dart_IsolateUnhandledExceptionCallback unhandled,
    Dart_IsolateShutdownCallback shutdown,
    Dart_FileOpenCallback file_open,
    Dart_FileReadCallback file_read,
    Dart_FileWriteCallback file_write,
    Dart_FileCloseCallback file_close,
    Dart_EntropySource entropy_source) {
  const char* err_msg = Dart::InitOnce(vm_isolate_snapshot,
                                       instructions_snapshot,
                                       create, interrupt, unhandled, shutdown,
                                       file_open, file_read, file_write,
                                       file_close, entropy_source);
  if (err_msg != NULL) {
    OS::PrintErr("Dart_Initialize: %s\n", err_msg);
    return false;
  }
  return true;
}


DART_EXPORT bool Dart_Cleanup() {
  CHECK_NO_ISOLATE(Isolate::Current());
  const char* err_msg = Dart::Cleanup();
  if (err_msg != NULL) {
    OS::PrintErr("Dart_Cleanup: %s\n", err_msg);
    return false;
  }
  return true;
}


DART_EXPORT bool Dart_SetVMFlags(int argc, const char** argv) {
  return Flags::ProcessCommandLineFlags(argc, argv);
}


DART_EXPORT bool Dart_IsVMFlagSet(const char* flag_name) {
  return Flags::IsSet(flag_name);
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


DART_EXPORT Dart_Isolate Dart_CreateIsolate(const char* script_uri,
                                            const char* main,
                                            const uint8_t* snapshot,
                                            Dart_IsolateFlags* flags,
                                            void* callback_data,
                                            char** error) {
  CHECK_NO_ISOLATE(Isolate::Current());
  char* isolate_name = BuildIsolateName(script_uri, main);
  Thread::EnsureInit();

  // Setup default flags in case none were passed.
  Dart_IsolateFlags api_flags;
  if (flags == NULL) {
    Isolate::Flags vm_flags;
    vm_flags.CopyTo(&api_flags);
    flags = &api_flags;
  }
  Isolate* I = Dart::CreateIsolate(isolate_name, *flags);
  free(isolate_name);
  {
    Thread* T = Thread::Current();
    StackZone zone(T);
    HANDLESCOPE(T);
    // We enter an API scope here as InitializeIsolate could compile some
    // bootstrap library files which call out to a tag handler that may create
    // Api Handles when an error is encountered.
    Dart_EnterScope();
    const Error& error_obj =
        Error::Handle(Z, Dart::InitializeIsolate(snapshot, callback_data));
    if (error_obj.IsNull()) {
  #if defined(DART_NO_SNAPSHOT)
      if (FLAG_check_function_fingerprints) {
        Library::CheckFunctionFingerprints();
      }
  #endif  // defined(DART_NO_SNAPSHOT).
      // We exit the API scope entered above.
      Dart_ExitScope();
      START_TIMER(I, time_total_runtime);
      return Api::CastIsolate(I);
    }
    *error = strdup(error_obj.ToErrorCString());
    // We exit the API scope entered above.
    Dart_ExitScope();
  }
  Dart::ShutdownIsolate();
  return reinterpret_cast<Dart_Isolate>(NULL);
}


DART_EXPORT void Dart_ShutdownIsolate() {
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  CHECK_ISOLATE(I);
  {
    StackZone zone(T);
    HandleScope handle_scope(T);
    Dart::RunShutdownCallback();
  }
  STOP_TIMER(I, time_total_runtime);
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


DART_EXPORT void* Dart_IsolateData(Dart_Isolate isolate) {
  TRACE_API_CALL(CURRENT_FUNC);
  if (isolate == NULL) {
    FATAL1("%s expects argument 'isolate' to be non-null.",  CURRENT_FUNC);
  }
  // TODO(16615): Validate isolate parameter.
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  return iso->init_callback_data();
}


DART_EXPORT Dart_Handle Dart_DebugName() {
  DARTSCOPE(Thread::Current());
  return Api::NewHandle(I, String::New(I->name()));
}



DART_EXPORT void Dart_EnterIsolate(Dart_Isolate isolate) {
  CHECK_NO_ISOLATE(Isolate::Current());
  // TODO(16615): Validate isolate parameter.
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  if (iso->HasMutatorThread()) {
    FATAL("Multiple mutators within one isolate is not supported.");
  }
  Thread::EnsureInit();
  Thread::EnterIsolate(iso);
}


DART_EXPORT void Dart_IsolateBlocked() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  profiler_data->Block();
}


DART_EXPORT void Dart_IsolateUnblocked() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  profiler_data->Unblock();
}


DART_EXPORT void Dart_ExitIsolate() {
  CHECK_ISOLATE(Isolate::Current());
  Thread::ExitIsolate();
}


// TODO(iposva): Remove this API and instead expose the underlying flags.
DART_EXPORT Dart_Handle Dart_IsolateSetStrictCompilation(bool value) {
  CHECK_ISOLATE(Isolate::Current());
  Isolate* isolate = Isolate::Current();
  if (isolate->has_compiled()) {
    return Api::NewError(
        "%s expects that the isolate has not yet compiled code.", CURRENT_FUNC);
  }
  if (!value) {
    return Api::NewError(
        "%s expects that the value is set to true only.", CURRENT_FUNC);
  }
  Isolate::Current()->set_strict_compilation();
  return Api::Null();
}


static uint8_t* ApiReallocate(uint8_t* ptr,
                              intptr_t old_size,
                              intptr_t new_size) {
  return Api::TopScope(Isolate::Current())->zone()->Realloc<uint8_t>(
      ptr, old_size, new_size);
}


DART_EXPORT Dart_Handle Dart_CreateSnapshot(
    uint8_t** vm_isolate_snapshot_buffer,
    intptr_t* vm_isolate_snapshot_size,
    uint8_t** isolate_snapshot_buffer,
    intptr_t* isolate_snapshot_size) {
  ASSERT(FLAG_load_deferred_eagerly);
  DARTSCOPE(Thread::Current());
  TIMERSCOPE(T, time_creating_snapshot);
  if (vm_isolate_snapshot_buffer != NULL &&
      vm_isolate_snapshot_size == NULL) {
    RETURN_NULL_ERROR(vm_isolate_snapshot_size);
  }
  if (isolate_snapshot_buffer == NULL) {
    RETURN_NULL_ERROR(isolate_snapshot_buffer);
  }
  if (isolate_snapshot_size == NULL) {
    RETURN_NULL_ERROR(isolate_snapshot_size);
  }
  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(I);
  if (::Dart_IsError(state)) {
    return state;
  }
  I->heap()->CollectAllGarbage();
#if defined(DEBUG)
  FunctionVisitor check_canonical(I);
  I->heap()->IterateObjects(&check_canonical);
#endif  // #if defined(DEBUG).

  // Since this is only a snapshot the root library should not be set.
  I->object_store()->set_root_library(Library::Handle(Z));
  FullSnapshotWriter writer(vm_isolate_snapshot_buffer,
                            isolate_snapshot_buffer,
                            NULL, /* instructions_snapshot_buffer */
                            ApiReallocate,
                            false, /* snapshot_code */
                            true /* vm_isolate_is_symbolic */);
  writer.WriteFullSnapshot();
  *vm_isolate_snapshot_size = writer.VmIsolateSnapshotSize();
  *isolate_snapshot_size = writer.IsolateSnapshotSize();
  return Api::Success();
}


static Dart_Handle createLibrarySnapshot(Dart_Handle library,
                                         uint8_t** buffer,
                                         intptr_t* size) {
  DARTSCOPE(Thread::Current());
  TIMERSCOPE(T, time_creating_snapshot);
  if (buffer == NULL) {
    RETURN_NULL_ERROR(buffer);
  }
  if (size == NULL) {
    RETURN_NULL_ERROR(size);
  }
  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(I);
  if (::Dart_IsError(state)) {
    return state;
  }
  Library& lib = Library::Handle(Z);
  if (library == Dart_Null()) {
    lib ^= I->object_store()->root_library();
  } else {
    lib ^= Api::UnwrapHandle(library);
  }
  I->heap()->CollectAllGarbage();
#if defined(DEBUG)
  FunctionVisitor check_canonical(I);
  I->heap()->IterateObjects(&check_canonical);
#endif  // #if defined(DEBUG).
  ScriptSnapshotWriter writer(buffer, ApiReallocate);
  writer.WriteScriptSnapshot(lib);
  *size = writer.BytesWritten();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_CreateScriptSnapshot(uint8_t** buffer,
                                                  intptr_t* size) {
  return createLibrarySnapshot(Dart_Null(), buffer, size);
}


DART_EXPORT Dart_Handle Dart_CreateLibrarySnapshot(Dart_Handle library,
                                                   uint8_t** buffer,
                                                   intptr_t* size) {
  return createLibrarySnapshot(library, buffer, size);
}


DART_EXPORT void Dart_InterruptIsolate(Dart_Isolate isolate) {
  TRACE_API_CALL(CURRENT_FUNC);
  if (isolate == NULL) {
    FATAL1("%s expects argument 'isolate' to be non-null.",  CURRENT_FUNC);
  }
  // TODO(16615): Validate isolate parameter.
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  // Schedule the interrupt. The isolate will notice this bit being set if it
  // is currently executing in Dart code.
  iso->ScheduleInterrupts(Isolate::kApiInterrupt);
  // If the isolate is blocked on the message queue, we post a dummy message
  // to the isolate's main port. The message will be ultimately ignored, but as
  // part of handling the message the interrupt bit which was set above will be
  // honored.
  // Can't use Dart_Post() since there isn't a current isolate.
  Dart_CObject api_null = { Dart_CObject_kNull , { 0 } };
  Dart_PostCObject(iso->main_port(), &api_null);
}


DART_EXPORT bool Dart_IsolateMakeRunnable(Dart_Isolate isolate) {
  CHECK_NO_ISOLATE(Isolate::Current());
  if (isolate == NULL) {
    FATAL1("%s expects argument 'isolate' to be non-null.",  CURRENT_FUNC);
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
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  CHECK_ISOLATE_SCOPE(I);
  CHECK_CALLBACK_STATE(I);
  Monitor monitor;
  MonitorLocker ml(&monitor);
  {
    SwitchIsolateScope switch_scope(NULL);

    RunLoopData data;
    data.monitor = &monitor;
    data.done = false;
    I->message_handler()->Run(
        Dart::thread_pool(),
        NULL, RunLoopDone, reinterpret_cast<uword>(&data));
    while (!data.done) {
      ml.Wait();
    }
  }
  if (I->object_store()->sticky_error() != Object::null()) {
    Dart_Handle error = Api::NewHandle(I, I->object_store()->sticky_error());
    I->object_store()->clear_sticky_error();
    return error;
  }
  if (FLAG_print_class_table) {
    HANDLESCOPE(T);
    I->class_table()->Print();
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_HandleMessage() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE_SCOPE(isolate);
  CHECK_CALLBACK_STATE(isolate);
  if (!isolate->message_handler()->HandleNextMessage()) {
    Dart_Handle error = Api::NewHandle(isolate,
                                       isolate->object_store()->sticky_error());
    isolate->object_store()->clear_sticky_error();
    return error;
  }
  return Api::Success();
}


DART_EXPORT bool Dart_HandleServiceMessages() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE_SCOPE(isolate);
  CHECK_CALLBACK_STATE(isolate);

  ASSERT(isolate->GetAndClearResumeRequest() == false);
  isolate->message_handler()->HandleOOBMessages();
  return isolate->GetAndClearResumeRequest();
}


DART_EXPORT bool Dart_HasServiceMessages() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate);
  return isolate->message_handler()->HasOOBMessages();
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


DART_EXPORT bool Dart_Post(Dart_Port port_id, Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  if (port_id == ILLEGAL_PORT) {
    return false;
  }
  const Object& object = Object::Handle(Z, Api::UnwrapHandle(handle));
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator, false);
  writer.WriteMessage(object);
  intptr_t len = writer.BytesWritten();
  return PortMap::PostMessage(new Message(
      port_id, data, len, Message::kNormalPriority));
}


DART_EXPORT Dart_Handle Dart_NewSendPort(Dart_Port port_id) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  if (port_id == ILLEGAL_PORT) {
    return Api::NewError("%s: illegal port_id %" Pd64 ".",
                         CURRENT_FUNC,
                         port_id);
  }
  return Api::NewHandle(I, SendPort::New(port_id));
}


DART_EXPORT Dart_Handle Dart_SendPortGetId(Dart_Handle port,
                                           Dart_Port* port_id) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  const SendPort& send_port = Api::UnwrapSendPortHandle(I, port);
  if (send_port.IsNull()) {
    RETURN_TYPE_ERROR(I, port, SendPort);
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
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* new_scope = state->reusable_scope();
  if (new_scope == NULL) {
    new_scope = new ApiLocalScope(state->top_scope(),
                                  thread->top_exit_frame_info());
    ASSERT(new_scope != NULL);
  } else {
    new_scope->Reinit(thread,
                      state->top_scope(),
                      thread->top_exit_frame_info());
    state->set_reusable_scope(NULL);
  }
  state->set_top_scope(new_scope);  // New scope is now the top scope.
}


DART_EXPORT void Dart_ExitScope() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE_SCOPE(isolate);
  ApiState* state = isolate->api_state();
  ApiLocalScope* scope = state->top_scope();
  ApiLocalScope* reusable_scope = state->reusable_scope();
  state->set_top_scope(scope->previous());  // Reset top scope to previous.
  if (reusable_scope == NULL) {
    scope->Reset(thread);  // Reset the old scope which we just exited.
    state->set_reusable_scope(scope);
  } else {
    ASSERT(reusable_scope != scope);
    delete scope;
  }
}


DART_EXPORT uint8_t* Dart_ScopeAllocate(intptr_t size) {
  Zone* zone;
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


DART_EXPORT Dart_Handle Dart_ObjectEquals(Dart_Handle obj1, Dart_Handle obj2,
                                          bool* value) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  const Instance& expected =
      Instance::CheckedHandle(Z, Api::UnwrapHandle(obj1));
  const Instance& actual =
      Instance::CheckedHandle(Z, Api::UnwrapHandle(obj2));
  const Object& result =
      Object::Handle(Z, DartLibraryCalls::Equals(expected, actual));
  if (result.IsBool()) {
    *value = Bool::Cast(result).value();
    return Api::Success();
  } else if (result.IsError()) {
    return Api::NewHandle(I, result.raw());
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

  const Type& type_obj = Api::UnwrapTypeHandle(I, type);
  if (type_obj.IsNull()) {
    *value = false;
    RETURN_TYPE_ERROR(I, type, Type);
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
  const Instance& instance = Api::UnwrapInstanceHandle(I, object);
  if (instance.IsNull()) {
    *value = false;
    RETURN_TYPE_ERROR(I, object, Instance);
  }
  CHECK_CALLBACK_STATE(I);
  Error& malformed_type_error = Error::Handle(Z);
  *value = instance.IsInstanceOf(type_obj,
                                 Object::null_type_arguments(),
                                 &malformed_type_error);
  ASSERT(malformed_type_error.IsNull());  // Type was created from a class.
  return Api::Success();
}


DART_EXPORT bool Dart_IsInstance(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& ref = isolate->ObjectHandle();
  ref = Api::UnwrapHandle(object);
  return ref.IsInstance();
}


DART_EXPORT bool Dart_IsNumber(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return RawObject::IsNumberClassId(Api::ClassId(object));
}


DART_EXPORT bool Dart_IsInteger(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return RawObject::IsIntegerClassId(Api::ClassId(object));
}


DART_EXPORT bool Dart_IsDouble(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(object) == kDoubleCid;
}


DART_EXPORT bool Dart_IsBoolean(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(object) == kBoolCid;
}


DART_EXPORT bool Dart_IsString(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return RawObject::IsStringClassId(Api::ClassId(object));
}


DART_EXPORT bool Dart_IsStringLatin1(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return RawObject::IsOneByteStringClassId(Api::ClassId(object));
}


DART_EXPORT bool Dart_IsExternalString(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  return RawObject::IsExternalStringClassId(Api::ClassId(object));
}


DART_EXPORT bool Dart_IsList(Dart_Handle object) {
  if (RawObject::IsBuiltinListClassId(Api::ClassId(object))) {
    TRACE_API_CALL(CURRENT_FUNC);
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
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(object) == kLibraryCid;
}


DART_EXPORT bool Dart_IsType(Dart_Handle handle) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(handle) == kTypeCid;
}


DART_EXPORT bool Dart_IsFunction(Dart_Handle handle) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(handle) == kFunctionCid;
}


DART_EXPORT bool Dart_IsVariable(Dart_Handle handle) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(handle) == kFieldCid;
}


DART_EXPORT bool Dart_IsTypeVariable(Dart_Handle handle) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(handle) == kTypeParameterCid;
}


DART_EXPORT bool Dart_IsClosure(Dart_Handle object) {
  // We can't use a fast class index check here because there are many
  // different signature classes for closures.
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ReusableObjectHandleScope reused_obj_handle(isolate);
  const Instance& closure_obj =
      Api::UnwrapInstanceHandle(reused_obj_handle, object);
  return (!closure_obj.IsNull() && closure_obj.IsClosure());
}


DART_EXPORT bool Dart_IsTypedData(Dart_Handle handle) {
  TRACE_API_CALL(CURRENT_FUNC);
  intptr_t cid = Api::ClassId(handle);
  return RawObject::IsTypedDataClassId(cid) ||
         RawObject::IsExternalTypedDataClassId(cid) ||
         RawObject::IsTypedDataViewClassId(cid);
}


DART_EXPORT bool Dart_IsByteBuffer(Dart_Handle handle) {
  TRACE_API_CALL(CURRENT_FUNC);
  return Api::ClassId(handle) == kByteBufferCid;
}


DART_EXPORT bool Dart_IsFuture(Dart_Handle handle) {
  TRACE_API_CALL(CURRENT_FUNC);
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  if (obj.IsInstance()) {
    const Class& future_class =
        Class::Handle(I->object_store()->future_class());
    ASSERT(!future_class.IsNull());
    const Class& obj_class = Class::Handle(Z, obj.clazz());
    Error& malformed_type_error = Error::Handle(Z);
    bool is_future = obj_class.IsSubtypeOf(Object::null_type_arguments(),
                                           future_class,
                                           Object::null_type_arguments(),
                                           &malformed_type_error);
    ASSERT(malformed_type_error.IsNull());  // Type is a raw Future.
    return is_future;
  }
  return false;
}


// --- Instances ----

DART_EXPORT Dart_Handle Dart_InstanceGetType(Dart_Handle instance) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(instance));
  if (obj.IsNull()) {
    return Api::NewHandle(I, I->object_store()->null_type());
  }
  if (!obj.IsInstance()) {
    RETURN_TYPE_ERROR(I, instance, Instance);
  }
  const Type& type = Type::Handle(Instance::Cast(obj).GetType());
  return Api::NewHandle(I, type.Canonicalize());
}


// --- Numbers, Integers and Doubles ----

DART_EXPORT Dart_Handle Dart_IntegerFitsIntoInt64(Dart_Handle integer,
                                                  bool* fits) {
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
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
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
  if (Api::IsSmi(integer)) {
    *fits = (Api::SmiValue(integer) >= 0);
    return Api::Success();
  }
  // Slow path for Mints and Bigints.
  DARTSCOPE(thread);
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  ASSERT(!int_obj.IsSmi());
  if (int_obj.IsMint()) {
    *fits = !int_obj.IsNegative();
  } else {
    *fits = Bigint::Cast(int_obj).FitsIntoUint64();
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_NewInteger(int64_t value) {
  // Fast path for Smis.
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  if (Smi::IsValid(value)) {
    NOHANDLESCOPE(thread);
    return Api::NewHandle(isolate, Smi::New(static_cast<intptr_t>(value)));
  }
  // Slow path for Mints and Bigints.
  DARTSCOPE(thread);
  CHECK_CALLBACK_STATE(isolate);
  return Api::NewHandle(isolate, Integer::New(value));
}


DART_EXPORT Dart_Handle Dart_NewIntegerFromUint64(uint64_t value) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  return Api::NewHandle(I, Integer::NewFromUint64(value));
}


DART_EXPORT Dart_Handle Dart_NewIntegerFromHexCString(const char* str) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  const String& str_obj = String::Handle(Z, String::New(str));
  return Api::NewHandle(I, Integer::New(str_obj));
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
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  ASSERT(!int_obj.IsSmi());
  if (int_obj.IsMint()) {
    *value = int_obj.AsInt64Value();
    return Api::Success();
  } else {
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
  const Integer& int_obj = Api::UnwrapIntegerHandle(isolate, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, integer, Integer);
  }
  if (int_obj.IsSmi()) {
    ASSERT(int_obj.IsNegative());
  } else if (int_obj.IsMint() && !int_obj.IsNegative()) {
    *value = int_obj.AsInt64Value();
    return Api::Success();
  } else {
    const Bigint& bigint = Bigint::Cast(int_obj);
    if (bigint.FitsIntoUint64()) {
      *value = bigint.AsUint64Value();
      return Api::Success();
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
  DARTSCOPE(Thread::Current());
  const Integer& int_obj = Api::UnwrapIntegerHandle(I, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(I, integer, Integer);
  }
  if (int_obj.IsSmi() || int_obj.IsMint()) {
    const Bigint& bigint = Bigint::Handle(Z,
        Bigint::NewFromInt64(int_obj.AsInt64Value()));
    *value = bigint.ToHexCString(BigintAllocate);
  } else {
    *value = Bigint::Cast(int_obj).ToHexCString(BigintAllocate);
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_NewDouble(double value) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  return Api::NewHandle(I, Double::New(value));
}


DART_EXPORT Dart_Handle Dart_DoubleValue(Dart_Handle double_obj,
                                         double* value) {
  DARTSCOPE(Thread::Current());
  const Double& obj = Api::UnwrapDoubleHandle(I, double_obj);
  if (obj.IsNull()) {
    RETURN_TYPE_ERROR(I, double_obj, Double);
  }
  *value = obj.value();
  return Api::Success();
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
  const Bool& obj = Api::UnwrapBoolHandle(I, boolean_obj);
  if (obj.IsNull()) {
    RETURN_TYPE_ERROR(I, boolean_obj, Bool);
  }
  *value = obj.value();
  return Api::Success();
}


// --- Strings ---


DART_EXPORT Dart_Handle Dart_StringLength(Dart_Handle str, intptr_t* len) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ReusableObjectHandleScope reused_obj_handle(isolate);
  const String& str_obj = Api::UnwrapStringHandle(reused_obj_handle, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, str, String);
  }
  *len = str_obj.Length();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_NewStringFromCString(const char* str) {
  DARTSCOPE(Thread::Current());
  if (str == NULL) {
    RETURN_NULL_ERROR(str);
  }
  CHECK_CALLBACK_STATE(I);
  return Api::NewHandle(I, String::New(str));
}


DART_EXPORT Dart_Handle Dart_NewStringFromUTF8(const uint8_t* utf8_array,
                                               intptr_t length) {
  DARTSCOPE(Thread::Current());
  if (utf8_array == NULL && length != 0) {
    RETURN_NULL_ERROR(utf8_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  if (!Utf8::IsValid(utf8_array, length)) {
    return Api::NewError("%s expects argument 'str' to be valid UTF-8.",
                         CURRENT_FUNC);
  }
  CHECK_CALLBACK_STATE(I);
  return Api::NewHandle(I, String::FromUTF8(utf8_array, length));
}


DART_EXPORT Dart_Handle Dart_NewStringFromUTF16(const uint16_t* utf16_array,
                                                intptr_t length) {
  DARTSCOPE(Thread::Current());
  if (utf16_array == NULL && length != 0) {
    RETURN_NULL_ERROR(utf16_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(I);
  return Api::NewHandle(I, String::FromUTF16(utf16_array, length));
}


DART_EXPORT Dart_Handle Dart_NewStringFromUTF32(const int32_t* utf32_array,
                                                intptr_t length) {
  DARTSCOPE(Thread::Current());
  if (utf32_array == NULL && length != 0) {
    RETURN_NULL_ERROR(utf32_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(I);
  return Api::NewHandle(I, String::FromUTF32(utf32_array, length));
}


DART_EXPORT Dart_Handle Dart_NewExternalLatin1String(
    const uint8_t* latin1_array,
    intptr_t length,
    void* peer,
    Dart_PeerFinalizer cback) {
  DARTSCOPE(Thread::Current());
  if (latin1_array == NULL && length != 0) {
    RETURN_NULL_ERROR(latin1_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(I);
  return Api::NewHandle(I,
                        String::NewExternal(latin1_array,
                                            length,
                                            peer,
                                            cback,
                                            SpaceForExternal(I, length)));
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
  CHECK_CALLBACK_STATE(I);
  intptr_t bytes = length * sizeof(*utf16_array);
  return Api::NewHandle(I,
                        String::NewExternal(utf16_array,
                                            length,
                                            peer,
                                            cback,
                                            SpaceForExternal(I, bytes)));
}


DART_EXPORT Dart_Handle Dart_StringToCString(Dart_Handle object,
                                             const char** cstr) {
  DARTSCOPE(Thread::Current());
  if (cstr == NULL) {
    RETURN_NULL_ERROR(cstr);
  }
  const String& str_obj = Api::UnwrapStringHandle(I, object);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(I, object, String);
  }
  intptr_t string_length = Utf8::Length(str_obj);
  char* res = Api::TopScope(I)->zone()->Alloc<char>(string_length + 1);
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
  DARTSCOPE(Thread::Current());
  if (utf8_array == NULL) {
    RETURN_NULL_ERROR(utf8_array);
  }
  if (length == NULL) {
    RETURN_NULL_ERROR(length);
  }
  const String& str_obj = Api::UnwrapStringHandle(I, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(I, str, String);
  }
  intptr_t str_len = Utf8::Length(str_obj);
  *utf8_array = Api::TopScope(I)->zone()->Alloc<uint8_t>(str_len);
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
  DARTSCOPE(Thread::Current());
  if (latin1_array == NULL) {
    RETURN_NULL_ERROR(latin1_array);
  }
  if (length == NULL) {
    RETURN_NULL_ERROR(length);
  }
  const String& str_obj = Api::UnwrapStringHandle(I, str);
  if (str_obj.IsNull() || !str_obj.IsOneByteString()) {
    RETURN_TYPE_ERROR(I, str, String);
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
  DARTSCOPE(Thread::Current());
  const String& str_obj = Api::UnwrapStringHandle(I, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(I, str, String);
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
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ReusableObjectHandleScope reused_obj_handle(isolate);
  const String& str_obj = Api::UnwrapStringHandle(reused_obj_handle, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(isolate, str, String);
  }
  if (size == NULL) {
    RETURN_NULL_ERROR(size);
  }
  *size = (str_obj.Length() * str_obj.CharSize());
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_MakeExternalString(Dart_Handle str,
                                                void* array,
                                                intptr_t length,
                                                void* peer,
                                                Dart_PeerFinalizer cback) {
  DARTSCOPE(Thread::Current());
  const String& str_obj = Api::UnwrapStringHandle(I, str);
  if (str_obj.IsExternal()) {
    return str;  // String is already an external string.
  }
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(I, str, String);
  }
  if (array == NULL) {
    RETURN_NULL_ERROR(array);
  }
  intptr_t str_size = (str_obj.Length() * str_obj.CharSize());
  if ((length < str_size) || (length > String::kMaxElements)) {
    return Api::NewError("Dart_MakeExternalString "
                         "expects argument length to be in the range"
                         "[%" Pd "..%" Pd "].",
                         str_size, String::kMaxElements);
  }
  if (str_obj.InVMHeap()) {
    // Since the string object is read only we do not externalize
    // the string but instead copy the contents of the string into the
    // specified buffer add the specified peer/cback as a Peer object
    // to this string. The Api::StringGetPeerHelper function picks up
    // the peer from the Peer table.
    intptr_t copy_len = str_obj.Length();
    if (str_obj.IsOneByteString()) {
      ASSERT(length >= copy_len);
      uint8_t* latin1_array = reinterpret_cast<uint8_t*>(array);
      for (intptr_t i = 0; i < copy_len; i++) {
        latin1_array[i] = static_cast<uint8_t>(str_obj.CharAt(i));
      }
      OneByteString::SetPeer(str_obj, peer, cback);
    } else {
      ASSERT(str_obj.IsTwoByteString());
      ASSERT(length >= (copy_len * str_obj.CharSize()));
      uint16_t* utf16_array = reinterpret_cast<uint16_t*>(array);
      for (intptr_t i = 0; i < copy_len; i++) {
        utf16_array[i] = str_obj.CharAt(i);
      }
      TwoByteString::SetPeer(str_obj, peer, cback);
    }
    return str;
  }
  return Api::NewHandle(I, str_obj.MakeExternal(array, length, peer, cback));
}


DART_EXPORT Dart_Handle Dart_StringGetProperties(Dart_Handle object,
                                                 intptr_t* char_size,
                                                 intptr_t* str_len,
                                                 void** peer) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ReusableObjectHandleScope reused_obj_handle(isolate);
  const String& str = Api::UnwrapStringHandle(reused_obj_handle, object);
  if (str.IsNull()) {
    RETURN_TYPE_ERROR(isolate, object, String);
  }
  if (str.IsExternal()) {
    *peer = str.GetPeer();
    ASSERT(*peer != NULL);
  } else {
    NoSafepointScope no_safepoint_scope;
    *peer = isolate->heap()->GetPeer(str.raw());
  }
  *char_size = str.CharSize();
  *str_len = str.Length();
  return Api::Success();
}


// --- Lists ---

DART_EXPORT Dart_Handle Dart_NewList(intptr_t length) {
  DARTSCOPE(Thread::Current());
  CHECK_LENGTH(length, Array::kMaxElements);
  CHECK_CALLBACK_STATE(I);
  return Api::NewHandle(I, Array::New(length));
}


#define GET_LIST_LENGTH(zone, type, obj, len)                                  \
  type& array = type::Handle(zone);                                            \
  array ^= obj.raw();                                                          \
  *len = array.Length();                                                       \
  return Api::Success();                                                       \


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
  CHECK_CALLBACK_STATE(I);

  // Now check and handle a dart object that implements the List interface.
  const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
  if (instance.IsNull()) {
    return Api::NewError("Object does not implement the List interface");
  }
  const String& name = String::Handle(Z, Field::GetterName(Symbols::Length()));
  const int kNumArgs = 1;
  ArgumentsDescriptor args_desc(
      Array::Handle(Z, ArgumentsDescriptor::New(kNumArgs)));
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
    return Api::NewError("Length of List object is greater than the "
                         "maximum value that 'len' parameter can hold");
  } else if (retval.IsError()) {
    return Api::NewHandle(I, retval.raw());
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
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsArray()) {
    GET_LIST_ELEMENT(I, Array, obj, index);
  } else if (obj.IsGrowableObjectArray()) {
    GET_LIST_ELEMENT(I, GrowableObjectArray, obj, index);
  } else if (obj.IsError()) {
    return list;
  } else {
    CHECK_CALLBACK_STATE(I);
    // Check and handle a dart object that implements the List interface.
    const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
    if (!instance.IsNull()) {
      return Api::NewHandle(I, Send1Arg(
          instance,
          Symbols::IndexToken(),
          Instance::Handle(Z, Integer::New(index))));
    }
    return Api::NewError("Object does not implement the 'List' interface");
  }
}


#define GET_LIST_RANGE(isolate, type, obj, offset, length)                     \
  const type& array_obj = type::Cast(obj);                                     \
  if ((offset >= 0) && (offset + length <= array_obj.Length())) {              \
    for (intptr_t index = 0; index < length; ++index) {                        \
      result[index] = Api::NewHandle(isolate, array_obj.At(index + offset));   \
    }                                                                          \
    return Api::Success();                                                     \
  }                                                                            \
  return Api::NewError("Invalid offset/length passed in to access list");      \


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
    GET_LIST_RANGE(I, Array, obj, offset, length);
  } else if (obj.IsGrowableObjectArray()) {
    GET_LIST_RANGE(I, GrowableObjectArray, obj, offset, length);
  } else if (obj.IsError()) {
    return list;
  } else {
    CHECK_CALLBACK_STATE(I);
    // Check and handle a dart object that implements the List interface.
    const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
    if (!instance.IsNull()) {
      const intptr_t kNumArgs = 2;
      ArgumentsDescriptor args_desc(
          Array::Handle(ArgumentsDescriptor::New(kNumArgs)));
      const Function& function = Function::Handle(Z,
          Resolver::ResolveDynamic(instance,
                                   Symbols::AssignIndexToken(),
                                   args_desc));
      if (!function.IsNull()) {
        const Array& args = Array::Handle(Array::New(kNumArgs));
        args.SetAt(0, instance);
        Instance& index = Instance::Handle(Z);
        for (intptr_t i = 0; i < length; ++i) {
          index = Integer::New(i);
          args.SetAt(1, index);
          Dart_Handle value = Api::NewHandle(I,
              DartEntry::InvokeFunction(function, args));
          if (::Dart_IsError(value))
            return value;
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
    RETURN_TYPE_ERROR(I, value, Instance);                                     \
  }                                                                            \
  if ((index >= 0) && (index < array.Length())) {                              \
    array.SetAt(index, value_obj);                                             \
    return Api::Success();                                                     \
  }                                                                            \
  return Api::NewError("Invalid index passed in to set list element");         \


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
    CHECK_CALLBACK_STATE(I);

    // Check and handle a dart object that implements the List interface.
    const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
    if (!instance.IsNull()) {
      const intptr_t kNumArgs = 3;
      ArgumentsDescriptor args_desc(
          Array::Handle(ArgumentsDescriptor::New(kNumArgs)));
      const Function& function = Function::Handle(Z,
          Resolver::ResolveDynamic(instance,
                                   Symbols::AssignIndexToken(),
                                   args_desc));
      if (!function.IsNull()) {
        const Integer& index_obj = Integer::Handle(Z, Integer::New(index));
        const Object& value_obj = Object::Handle(Z, Api::UnwrapHandle(value));
        if (!value_obj.IsNull() && !value_obj.IsInstance()) {
          RETURN_TYPE_ERROR(I, value, Instance);
        }
        const Array& args = Array::Handle(Z, Array::New(kNumArgs));
        args.SetAt(0, instance);
        args.SetAt(1, index_obj);
        args.SetAt(2, value_obj);
        return Api::NewHandle(I, DartEntry::InvokeFunction(function,
                                                                 args));
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
  Isolate* isolate = thread->isolate();
  // Lookup the class ArgumentError in dart:core.
  const String& lib_url = String::Handle(String::New("dart:core"));
  const String& class_name = String::Handle(String::New("ArgumentError"));
  const Library& lib =
      Library::Handle(isolate, Library::LookupLibrary(lib_url));
  if (lib.IsNull()) {
    const String& message = String::Handle(
        String::NewFormatted("%s: library '%s' not found.",
                             CURRENT_FUNC, lib_url.ToCString()));
    return ApiError::New(message);
  }
  const Class& cls = Class::Handle(
      isolate, lib.LookupClassAllowPrivate(class_name));
  ASSERT(!cls.IsNull());
  Object& result = Object::Handle(isolate);
  String& dot_name = String::Handle(String::New("."));
  String& constr_name = String::Handle(String::Concat(class_name, dot_name));
  result = ResolveConstructor(CURRENT_FUNC, cls, class_name, constr_name, 1);
  if (result.IsError()) return result.raw();
  ASSERT(result.IsFunction());
  Function& constructor = Function::Handle(isolate);
  constructor ^= result.raw();
  if (!constructor.IsGenerativeConstructor()) {
    const String& message = String::Handle(
        String::NewFormatted("%s: class '%s' is not a constructor.",
                             CURRENT_FUNC, class_name.ToCString()));
    return ApiError::New(message);
  }
  Instance& exception = Instance::Handle(isolate);
  exception = Instance::New(cls);
  const Array& args = Array::Handle(isolate, Array::New(3));
  args.SetAt(0, exception);
  args.SetAt(1,
             Smi::Handle(isolate, Smi::New(Function::kCtorPhaseAll)));
  args.SetAt(2, String::Handle(String::New(exception_message)));
  result = DartEntry::InvokeFunction(constructor, args);
  if (result.IsError()) return result.raw();
  ASSERT(result.IsNull());

  if (isolate->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    const String& message = String::Handle(
            String::New("No Dart frames on stack, cannot throw exception"));
    return ApiError::New(message);
  }
  // Unwind all the API scopes till the exit frame before throwing an
  // exception.
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  const Instance* saved_exception;
  {
    NoSafepointScope no_safepoint;
    RawInstance* raw_exception = exception.raw();
    state->UnwindScopes(isolate->top_exit_frame_info());
    saved_exception = &Instance::Handle(raw_exception);
  }
  Exceptions::Throw(thread, *saved_exception);
  const String& message = String::Handle(
          String::New("Exception was not thrown, internal error"));
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
        return Api::NewHandle(I,                                               \
            ThrowArgumentError("List contains non-int elements"));             \
                                                                               \
      }                                                                        \
      const Integer& integer = Integer::Cast(element);                         \
      native_array[i] = static_cast<uint8_t>(integer.AsInt64Value() & 0xff);   \
      ASSERT(integer.AsInt64Value() <= 0xff);                                  \
    }                                                                          \
    return Api::Success();                                                     \
  }                                                                            \
  return Api::NewError("Invalid length passed in to access array elements");   \

template<typename T>
static Dart_Handle CopyBytes(const T& array,
                             intptr_t offset,
                             uint8_t* native_array,
                             intptr_t length) {
  ASSERT(array.ElementSizeInBytes() == 1);
  NoSafepointScope no_safepoint;
  memmove(native_array,
          reinterpret_cast<uint8_t*>(array.DataAddr(offset)),
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
    GET_LIST_ELEMENT_AS_BYTES(
        GrowableObjectArray, obj, native_array, offset, length);
  }
  if (obj.IsError()) {
    return list;
  }
  CHECK_CALLBACK_STATE(I);

  // Check and handle a dart object that implements the List interface.
  const Instance& instance =
      Instance::Handle(Z, GetListInstance(Z, obj));
  if (!instance.IsNull()) {
    const int kNumArgs = 2;
    ArgumentsDescriptor args_desc(
        Array::Handle(ArgumentsDescriptor::New(kNumArgs)));
    const Function& function = Function::Handle(Z,
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
          return Api::NewHandle(I, result.raw());
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
  return Api::NewError("Invalid length passed in to set array elements");      \


DART_EXPORT Dart_Handle Dart_ListSetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            uint8_t* native_array,
                                            intptr_t length) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsTypedData()) {
    const TypedData& array = TypedData::Cast(obj);
    if (array.ElementSizeInBytes() == 1) {
      if (Utils::RangeCheck(offset, length, array.Length())) {
        NoSafepointScope no_safepoint;
        memmove(reinterpret_cast<uint8_t*>(array.DataAddr(offset)),
                native_array,
                length);
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
    SET_LIST_ELEMENT_AS_BYTES(
        GrowableObjectArray, obj, native_array, offset, length);
  }
  if (obj.IsError()) {
    return list;
  }
  CHECK_CALLBACK_STATE(I);

  // Check and handle a dart object that implements the List interface.
  const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
  if (!instance.IsNull()) {
    const int kNumArgs = 3;
    ArgumentsDescriptor args_desc(
        Array::Handle(ArgumentsDescriptor::New(kNumArgs)));
    const Function& function = Function::Handle(Z,
        Resolver::ResolveDynamic(instance,
                                 Symbols::AssignIndexToken(),
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
        const Object& result = Object::Handle(Z,
            DartEntry::InvokeFunction(function, args));
        if (result.IsError()) {
          return Api::NewHandle(I, result.raw());
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
  CHECK_CALLBACK_STATE(I);
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(map));
  const Instance& instance = Instance::Handle(Z, GetMapInstance(Z, obj));
  if (!instance.IsNull()) {
    const Object& key_obj = Object::Handle(Api::UnwrapHandle(key));
    if (!(key_obj.IsInstance() || key_obj.IsNull())) {
      return Api::NewError("Key is not an instance");
    }
    return Api::NewHandle(I,
        Send1Arg(instance, Symbols::IndexToken(), Instance::Cast(key_obj)));
  }
  return Api::NewError("Object does not implement the 'Map' interface");
}


DART_EXPORT Dart_Handle Dart_MapContainsKey(Dart_Handle map, Dart_Handle key) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(map));
  const Instance& instance = Instance::Handle(Z, GetMapInstance(Z, obj));
  if (!instance.IsNull()) {
    const Object& key_obj = Object::Handle(Z, Api::UnwrapHandle(key));
    if (!(key_obj.IsInstance() || key_obj.IsNull())) {
      return Api::NewError("Key is not an instance");
    }
    return Api::NewHandle(I, Send1Arg(
       instance,
       String::Handle(Z, String::New("containsKey")),
       Instance::Cast(key_obj)));
  }
  return Api::NewError("Object does not implement the 'Map' interface");
}


DART_EXPORT Dart_Handle Dart_MapKeys(Dart_Handle map) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  Object& obj = Object::Handle(Z, Api::UnwrapHandle(map));
  Instance& instance = Instance::Handle(Z, GetMapInstance(Z, obj));
  if (!instance.IsNull()) {
    const Object& iterator = Object::Handle(Send0Arg(
        instance, String::Handle(Z, String::New("get:keys"))));
    if (!iterator.IsInstance()) {
      return Api::NewHandle(I, iterator.raw());
    }
    return Api::NewHandle(I, Send0Arg(
        Instance::Cast(iterator),
        String::Handle(String::New("toList"))));
  }
  return Api::NewError("Object does not implement the 'Map' interface");
}


// --- Typed Data ---

// Helper method to get the type of a TypedData object.
static Dart_TypedData_Type GetType(intptr_t class_id) {
  Dart_TypedData_Type type;
  switch (class_id) {
    case kByteDataViewCid :
      type = Dart_TypedData_kByteData;
      break;
    case kTypedDataInt8ArrayCid :
    case kTypedDataInt8ArrayViewCid :
    case kExternalTypedDataInt8ArrayCid :
      type = Dart_TypedData_kInt8;
      break;
    case kTypedDataUint8ArrayCid :
    case kTypedDataUint8ArrayViewCid :
    case kExternalTypedDataUint8ArrayCid :
      type = Dart_TypedData_kUint8;
      break;
    case kTypedDataUint8ClampedArrayCid :
    case kTypedDataUint8ClampedArrayViewCid :
    case kExternalTypedDataUint8ClampedArrayCid :
      type = Dart_TypedData_kUint8Clamped;
      break;
    case kTypedDataInt16ArrayCid :
    case kTypedDataInt16ArrayViewCid :
    case kExternalTypedDataInt16ArrayCid :
      type = Dart_TypedData_kInt16;
      break;
    case kTypedDataUint16ArrayCid :
    case kTypedDataUint16ArrayViewCid :
    case kExternalTypedDataUint16ArrayCid :
      type = Dart_TypedData_kUint16;
      break;
    case kTypedDataInt32ArrayCid :
    case kTypedDataInt32ArrayViewCid :
    case kExternalTypedDataInt32ArrayCid :
      type = Dart_TypedData_kInt32;
      break;
    case kTypedDataUint32ArrayCid :
    case kTypedDataUint32ArrayViewCid :
    case kExternalTypedDataUint32ArrayCid :
      type = Dart_TypedData_kUint32;
      break;
    case kTypedDataInt64ArrayCid :
    case kTypedDataInt64ArrayViewCid :
    case kExternalTypedDataInt64ArrayCid :
      type = Dart_TypedData_kInt64;
      break;
    case kTypedDataUint64ArrayCid :
    case kTypedDataUint64ArrayViewCid :
    case kExternalTypedDataUint64ArrayCid :
      type = Dart_TypedData_kUint64;
      break;
    case kTypedDataFloat32ArrayCid :
    case kTypedDataFloat32ArrayViewCid :
    case kExternalTypedDataFloat32ArrayCid :
      type = Dart_TypedData_kFloat32;
      break;
    case kTypedDataFloat64ArrayCid :
    case kTypedDataFloat64ArrayViewCid :
    case kExternalTypedDataFloat64ArrayCid :
      type = Dart_TypedData_kFloat64;
      break;
    case kTypedDataFloat32x4ArrayCid :
    case kTypedDataFloat32x4ArrayViewCid :
    case kExternalTypedDataFloat32x4ArrayCid :
      type = Dart_TypedData_kFloat32x4;
      break;
    default:
      type = Dart_TypedData_kInvalid;
      break;
  }
  return type;
}


DART_EXPORT Dart_TypedData_Type Dart_GetTypeOfTypedData(Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  intptr_t class_id = Api::ClassId(object);
  if (RawObject::IsTypedDataClassId(class_id) ||
      RawObject::IsTypedDataViewClassId(class_id)) {
    return GetType(class_id);
  }
  return Dart_TypedData_kInvalid;
}


DART_EXPORT Dart_TypedData_Type Dart_GetTypeOfExternalTypedData(
    Dart_Handle object) {
  TRACE_API_CALL(CURRENT_FUNC);
  intptr_t class_id = Api::ClassId(object);
  if (RawObject::IsExternalTypedDataClassId(class_id)) {
    return GetType(class_id);
  }
  if (RawObject::IsTypedDataViewClassId(class_id)) {
    // Check if data object of the view is external.
    Isolate* isolate = Isolate::Current();
    const Instance& view_obj = Api::UnwrapInstanceHandle(isolate, object);
    ASSERT(!view_obj.IsNull());
    const Instance& data_obj =
        Instance::Handle(isolate, TypedDataView::Data(view_obj));
    if (ExternalTypedData::IsExternalTypedData(data_obj)) {
      return GetType(class_id);
    }
  }
  return Dart_TypedData_kInvalid;
}


static RawObject* GetByteDataConstructor(Isolate* isolate,
                                         const String& constructor_name,
                                         intptr_t num_args) {
  const Library& lib =
      Library::Handle(isolate->object_store()->typed_data_library());
  ASSERT(!lib.IsNull());
  const Class& cls = Class::Handle(
      isolate, lib.LookupClassAllowPrivate(Symbols::ByteData()));
  ASSERT(!cls.IsNull());
  return ResolveConstructor(CURRENT_FUNC,
                            cls,
                            Symbols::ByteData(),
                            constructor_name,
                            num_args);
}


static Dart_Handle NewByteData(Isolate* isolate, intptr_t length) {
  CHECK_LENGTH(length, TypedData::MaxElements(kTypedDataInt8ArrayCid));
  Object& result = Object::Handle(isolate);
  result = GetByteDataConstructor(isolate, Symbols::ByteDataDot(), 1);
  ASSERT(!result.IsNull());
  ASSERT(result.IsFunction());
  const Function& factory = Function::Cast(result);
  ASSERT(!factory.IsGenerativeConstructor());

  // Create the argument list.
  const Array& args = Array::Handle(isolate, Array::New(2));
  // Factories get type arguments.
  args.SetAt(0, Object::null_type_arguments());
  args.SetAt(1, Smi::Handle(isolate, Smi::New(length)));

  // Invoke the constructor and return the new object.
  result = DartEntry::InvokeFunction(factory, args);
  ASSERT(result.IsInstance() || result.IsNull() || result.IsError());
  return Api::NewHandle(isolate, result.raw());
}


static Dart_Handle NewTypedData(Isolate* isolate,
                                intptr_t cid,
                                intptr_t length) {
  CHECK_LENGTH(length, TypedData::MaxElements(cid));
  return Api::NewHandle(isolate, TypedData::New(cid, length));
}


static Dart_Handle NewExternalTypedData(
    Isolate* isolate, intptr_t cid, void* data, intptr_t length) {
  CHECK_LENGTH(length, ExternalTypedData::MaxElements(cid));
  intptr_t bytes = length * ExternalTypedData::ElementSizeInBytes(cid);
  const ExternalTypedData& result = ExternalTypedData::Handle(
      isolate,
      ExternalTypedData::New(cid,
                             reinterpret_cast<uint8_t*>(data),
                             length,
                             SpaceForExternal(isolate, bytes)));
  return Api::NewHandle(isolate, result.raw());
}


static Dart_Handle NewExternalByteData(
    Isolate* isolate, void* data, intptr_t length) {
  Dart_Handle ext_data = NewExternalTypedData(
      isolate, kExternalTypedDataUint8ArrayCid, data, length);
  if (::Dart_IsError(ext_data)) {
    return ext_data;
  }
  Object& result = Object::Handle(isolate);
  result = GetByteDataConstructor(isolate, Symbols::ByteDataDot_view(), 3);
  ASSERT(!result.IsNull());
  ASSERT(result.IsFunction());
  const Function& factory = Function::Cast(result);
  ASSERT(!factory.IsGenerativeConstructor());

  // Create the argument list.
  const intptr_t num_args = 3;
  const Array& args = Array::Handle(isolate, Array::New(num_args + 1));
  // Factories get type arguments.
  args.SetAt(0, Object::null_type_arguments());
  const ExternalTypedData& array =
      Api::UnwrapExternalTypedDataHandle(isolate, ext_data);
  args.SetAt(1, array);
  Smi& smi = Smi::Handle(isolate);
  smi = Smi::New(0);
  args.SetAt(2, smi);
  smi = Smi::New(length);
  args.SetAt(3, smi);

  // Invoke the constructor and return the new object.
  result = DartEntry::InvokeFunction(factory, args);
  ASSERT(result.IsNull() || result.IsInstance() || result.IsError());
  return Api::NewHandle(isolate, result.raw());
}


DART_EXPORT Dart_Handle Dart_NewTypedData(Dart_TypedData_Type type,
                                          intptr_t length) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  switch (type) {
    case Dart_TypedData_kByteData :
      return NewByteData(I, length);
    case Dart_TypedData_kInt8 :
      return NewTypedData(I, kTypedDataInt8ArrayCid, length);
    case Dart_TypedData_kUint8 :
      return NewTypedData(I, kTypedDataUint8ArrayCid, length);
    case Dart_TypedData_kUint8Clamped :
      return NewTypedData(I, kTypedDataUint8ClampedArrayCid, length);
    case Dart_TypedData_kInt16 :
      return NewTypedData(I, kTypedDataInt16ArrayCid, length);
    case Dart_TypedData_kUint16 :
      return NewTypedData(I, kTypedDataUint16ArrayCid, length);
    case Dart_TypedData_kInt32 :
      return NewTypedData(I, kTypedDataInt32ArrayCid, length);
    case Dart_TypedData_kUint32 :
      return NewTypedData(I, kTypedDataUint32ArrayCid, length);
    case Dart_TypedData_kInt64 :
      return NewTypedData(I, kTypedDataInt64ArrayCid, length);
    case Dart_TypedData_kUint64 :
      return NewTypedData(I, kTypedDataUint64ArrayCid, length);
    case Dart_TypedData_kFloat32 :
      return NewTypedData(I, kTypedDataFloat32ArrayCid,  length);
    case Dart_TypedData_kFloat64 :
      return NewTypedData(I, kTypedDataFloat64ArrayCid, length);
    case Dart_TypedData_kFloat32x4:
      return NewTypedData(I, kTypedDataFloat32x4ArrayCid, length);
    default:
      return Api::NewError("%s expects argument 'type' to be of 'TypedData'",
                           CURRENT_FUNC);
  }
  UNREACHABLE();
  return Api::Null();
}


DART_EXPORT Dart_Handle Dart_NewExternalTypedData(
    Dart_TypedData_Type type,
    void* data,
    intptr_t length) {
  DARTSCOPE(Thread::Current());
  if (data == NULL && length != 0) {
    RETURN_NULL_ERROR(data);
  }
  CHECK_CALLBACK_STATE(I);
  switch (type) {
    case Dart_TypedData_kByteData:
      return NewExternalByteData(I, data, length);
    case Dart_TypedData_kInt8:
      return NewExternalTypedData(I,
          kExternalTypedDataInt8ArrayCid, data, length);
    case Dart_TypedData_kUint8:
      return NewExternalTypedData(I,
          kExternalTypedDataUint8ArrayCid, data, length);
    case Dart_TypedData_kUint8Clamped:
      return NewExternalTypedData(I,
          kExternalTypedDataUint8ClampedArrayCid, data, length);
    case Dart_TypedData_kInt16:
      return NewExternalTypedData(I,
          kExternalTypedDataInt16ArrayCid, data, length);
    case Dart_TypedData_kUint16:
      return NewExternalTypedData(I,
          kExternalTypedDataUint16ArrayCid, data, length);
    case Dart_TypedData_kInt32:
      return NewExternalTypedData(I,
          kExternalTypedDataInt32ArrayCid, data, length);
    case Dart_TypedData_kUint32:
      return NewExternalTypedData(I,
          kExternalTypedDataUint32ArrayCid, data, length);
    case Dart_TypedData_kInt64:
      return NewExternalTypedData(I,
          kExternalTypedDataInt64ArrayCid, data, length);
    case Dart_TypedData_kUint64:
      return NewExternalTypedData(I,
          kExternalTypedDataUint64ArrayCid, data, length);
    case Dart_TypedData_kFloat32:
      return NewExternalTypedData(I,
          kExternalTypedDataFloat32ArrayCid, data, length);
    case Dart_TypedData_kFloat64:
      return NewExternalTypedData(I,
          kExternalTypedDataFloat64ArrayCid, data, length);
    case Dart_TypedData_kFloat32x4:
      return NewExternalTypedData(I,
          kExternalTypedDataFloat32x4ArrayCid, data, length);
    default:
      return Api::NewError("%s expects argument 'type' to be of"
                           " 'external TypedData'", CURRENT_FUNC);
  }
  UNREACHABLE();
  return Api::Null();
}


static RawObject* GetByteBufferConstructor(Isolate* isolate,
                                           const String& class_name,
                                           const String& constructor_name,
                                           intptr_t num_args) {
  const Library& lib =
      Library::Handle(isolate->object_store()->typed_data_library());
  ASSERT(!lib.IsNull());
  const Class& cls = Class::Handle(
      isolate, lib.LookupClassAllowPrivate(class_name));
  ASSERT(!cls.IsNull());
  return ResolveConstructor(CURRENT_FUNC,
                            cls,
                            class_name,
                            constructor_name,
                            num_args);
}


DART_EXPORT Dart_Handle Dart_NewByteBuffer(Dart_Handle typed_data) {
  DARTSCOPE(Thread::Current());
  intptr_t class_id = Api::ClassId(typed_data);
  if (!RawObject::IsExternalTypedDataClassId(class_id) &&
      !RawObject::IsTypedDataViewClassId(class_id) &&
      !RawObject::IsTypedDataClassId(class_id)) {
    RETURN_TYPE_ERROR(I, typed_data, 'TypedData');
  }
  Object& result = Object::Handle(Z);
  result = GetByteBufferConstructor(I,
                                    Symbols::_ByteBuffer(),
                                    Symbols::_ByteBufferDot_New(),
                                    1);
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
  return Api::NewHandle(I, result.raw());
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
  intptr_t class_id = Api::ClassId(object);
  if (!RawObject::IsExternalTypedDataClassId(class_id) &&
      !RawObject::IsTypedDataViewClassId(class_id) &&
      !RawObject::IsTypedDataClassId(class_id)) {
    RETURN_TYPE_ERROR(I, object, 'TypedData');
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
        Api::UnwrapExternalTypedDataHandle(I, object);
    ASSERT(!obj.IsNull());
    length = obj.Length();
    size_in_bytes = length * ExternalTypedData::ElementSizeInBytes(class_id);
    data_tmp = obj.DataAddr(0);
    external = true;
  } else if (RawObject::IsTypedDataClassId(class_id)) {
    // Regular typed data object, set up some GC and API callback guards.
    const TypedData& obj = Api::UnwrapTypedDataHandle(I, object);
    ASSERT(!obj.IsNull());
    length = obj.Length();
    size_in_bytes = length * TypedData::ElementSizeInBytes(class_id);
    T->IncrementNoSafepointScopeDepth();
    START_NO_CALLBACK_SCOPE(I);
    data_tmp = obj.DataAddr(0);
  } else {
    ASSERT(RawObject::IsTypedDataViewClassId(class_id));
    const Instance& view_obj = Api::UnwrapInstanceHandle(I, object);
    ASSERT(!view_obj.IsNull());
    Smi& val = Smi::Handle();
    val ^= TypedDataView::Length(view_obj);
    length = val.Value();
    size_in_bytes = length * TypedDataView::ElementSizeInBytes(class_id);
    val ^= TypedDataView::OffsetInBytes(view_obj);
    intptr_t offset_in_bytes = val.Value();
    const Instance& obj = Instance::Handle(TypedDataView::Data(view_obj));
    T->IncrementNoSafepointScopeDepth();
    START_NO_CALLBACK_SCOPE(I);
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
  intptr_t class_id = Api::ClassId(object);
  if (!RawObject::IsExternalTypedDataClassId(class_id) &&
      !RawObject::IsTypedDataViewClassId(class_id) &&
      !RawObject::IsTypedDataClassId(class_id)) {
    RETURN_TYPE_ERROR(I, object, 'TypedData');
  }
  if (!RawObject::IsExternalTypedDataClassId(class_id)) {
    T->DecrementNoSafepointScopeDepth();
    END_NO_CALLBACK_SCOPE(I);
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
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  intptr_t class_id = Api::ClassId(object);
  if (class_id != kByteBufferCid) {
    RETURN_TYPE_ERROR(isolate, object, 'ByteBuffer');
  }
  const Instance& instance = Api::UnwrapInstanceHandle(isolate, object);
  ASSERT(!instance.IsNull());
  return Api::NewHandle(isolate, ByteBuffer::Data(instance));
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
  int extra_args = (constructor.IsGenerativeConstructor() ? 2 : 1);
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


DART_EXPORT Dart_Handle Dart_New(Dart_Handle type,
                                 Dart_Handle constructor_name,
                                 int number_of_arguments,
                                 Dart_Handle* arguments) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  Object& result = Object::Handle(Z);

  if (number_of_arguments < 0) {
    return Api::NewError(
        "%s expects argument 'number_of_arguments' to be non-negative.",
        CURRENT_FUNC);
  }

  // Get the class to instantiate.
  Object& unchecked_type = Object::Handle(Api::UnwrapHandle(type));
  if (unchecked_type.IsNull() || !unchecked_type.IsType()) {
    RETURN_TYPE_ERROR(I, type, Type);
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
    RETURN_TYPE_ERROR(I, constructor_name, String);
  }

  // Resolve the constructor.
  String& constr_name =
      String::Handle(String::Concat(base_constructor_name, dot_name));
  result = ResolveConstructor("Dart_New",
                              cls,
                              base_constructor_name,
                              constr_name,
                              number_of_arguments);
  if (result.IsError()) {
    return Api::NewHandle(I, result.raw());
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
      return Api::NewHandle(I, redirect_type.error());
    }

    if (!redirect_type.IsInstantiated()) {
      // The type arguments of the redirection type are instantiated from the
      // type arguments of the type argument.
      Error& bound_error = Error::Handle();
      redirect_type ^= redirect_type.InstantiateFrom(type_arguments,
                                                     &bound_error);
      if (!bound_error.IsNull()) {
        return Api::NewHandle(I, bound_error.raw());
      }
      redirect_type ^= redirect_type.Canonicalize();
    }

    type_obj = redirect_type.raw();
    type_arguments = redirect_type.arguments();

    cls = type_obj.type_class();
  }
  if (constructor.IsGenerativeConstructor()) {
    // Create the new object.
    new_object = Instance::New(cls);
  }

  // Create the argument list.
  intptr_t arg_index = 0;
  int extra_args = (constructor.IsGenerativeConstructor() ? 2 : 1);
  const Array& args =
      Array::Handle(Z, Array::New(number_of_arguments + extra_args));
  if (constructor.IsGenerativeConstructor()) {
    // Constructors get the uninitialized object and a constructor phase.
    if (!type_arguments.IsNull()) {
      // The type arguments will be null if the class has no type parameters, in
      // which case the following call would fail because there is no slot
      // reserved in the object for the type vector.
      new_object.SetTypeArguments(type_arguments);
    }
    args.SetAt(arg_index++, new_object);
    args.SetAt(arg_index++, Smi::Handle(Z, Smi::New(Function::kCtorPhaseAll)));
  } else {
    // Factories get type arguments.
    args.SetAt(arg_index++, type_arguments);
  }
  Object& argument = Object::Handle(Z);
  for (int i = 0; i < number_of_arguments; i++) {
    argument = Api::UnwrapHandle(arguments[i]);
    if (!argument.IsNull() && !argument.IsInstance()) {
      if (argument.IsError()) {
        return Api::NewHandle(I, argument.raw());
      } else {
        return Api::NewError(
            "%s expects arguments[%d] to be an Instance handle.",
            CURRENT_FUNC, i);
      }
    }
    args.SetAt(arg_index++, argument);
  }

  // Invoke the constructor and return the new object.
  result = DartEntry::InvokeFunction(constructor, args);
  if (result.IsError()) {
    return Api::NewHandle(I, result.raw());
  }

  if (constructor.IsGenerativeConstructor()) {
    ASSERT(result.IsNull());
  } else {
    ASSERT(result.IsNull() || result.IsInstance());
    new_object ^= result.raw();
  }
  return Api::NewHandle(I, new_object.raw());
}


static RawInstance* AllocateObject(Isolate* isolate, const Class& cls) {
  if (!cls.is_fields_marked_nullable()) {
    // Mark all fields as nullable.
    Class& iterate_cls = Class::Handle(isolate, cls.raw());
    Field& field = Field::Handle(isolate);
    Array& fields = Array::Handle(isolate);
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
  CHECK_CALLBACK_STATE(I);

  const Type& type_obj = Api::UnwrapTypeHandle(I, type);
  // Get the class to instantiate.
  if (type_obj.IsNull()) {
    RETURN_TYPE_ERROR(I, type, Type);
  }
  const Class& cls = Class::Handle(Z, type_obj.type_class());
  const Error& error = Error::Handle(Z, cls.EnsureIsFinalized(I));
  if (!error.IsNull()) {
    // An error occurred, return error object.
    return Api::NewHandle(I, error.raw());
  }
  return Api::NewHandle(I, AllocateObject(I, cls));
}


DART_EXPORT Dart_Handle Dart_AllocateWithNativeFields(
    Dart_Handle type,
    intptr_t num_native_fields,
    const intptr_t* native_fields) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);

  const Type& type_obj = Api::UnwrapTypeHandle(I, type);
  // Get the class to instantiate.
  if (type_obj.IsNull()) {
    RETURN_TYPE_ERROR(I, type, Type);
  }
  if (native_fields == NULL) {
    RETURN_NULL_ERROR(native_fields);
  }
  const Class& cls = Class::Handle(Z, type_obj.type_class());
  const Error& error = Error::Handle(Z, cls.EnsureIsFinalized(I));
  if (!error.IsNull()) {
    // An error occurred, return error object.
    return Api::NewHandle(I, error.raw());
  }
  if (num_native_fields != cls.num_native_fields()) {
    return Api::NewError(
        "%s: invalid number of native fields %" Pd " passed in, expected %d",
        CURRENT_FUNC, num_native_fields, cls.num_native_fields());
  }
  const Instance& instance = Instance::Handle(Z, AllocateObject(I, cls));
  instance.SetNativeFields(num_native_fields, native_fields);
  return Api::NewHandle(I, instance.raw());
}


static Dart_Handle SetupArguments(Isolate* isolate,
                                  int num_args,
                                  Dart_Handle* arguments,
                                  int extra_args,
                                  Array* args) {
  // Check for malformed arguments in the arguments list.
  *args = Array::New(num_args + extra_args);
  Object& arg = Object::Handle(isolate);
  for (int i = 0; i < num_args; i++) {
    arg = Api::UnwrapHandle(arguments[i]);
    if (!arg.IsNull() && !arg.IsInstance()) {
      *args = Array::null();
      if (arg.IsError()) {
        return Api::NewHandle(isolate, arg.raw());
      } else {
        return Api::NewError(
            "%s expects arguments[%d] to be an Instance handle.",
            "Dart_Invoke", i);
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
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);

  if (number_of_arguments < 0) {
    return Api::NewError(
        "%s expects argument 'number_of_arguments' to be non-negative.",
        CURRENT_FUNC);
  }
  const String& constructor_name = Api::UnwrapStringHandle(I, name);
  if (constructor_name.IsNull()) {
    RETURN_TYPE_ERROR(I, name, String);
  }
  const Instance& instance = Api::UnwrapInstanceHandle(I, object);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(I, object, Instance);
  }

  // Since we have allocated an object it would mean that the type
  // is finalized.
  // TODO(asiva): How do we ensure that a constructor is not called more than
  // once for the same object.

  // Construct name of the constructor to invoke.
  const Type& type_obj = Type::Handle(Z, instance.GetType());
  const Class& cls = Class::Handle(Z, type_obj.type_class());
  const String& class_name = String::Handle(Z, cls.Name());
  const Array& strings = Array::Handle(Z, Array::New(3));
  strings.SetAt(0, class_name);
  strings.SetAt(1, Symbols::Dot());
  strings.SetAt(2, constructor_name);
  const String& dot_name = String::Handle(Z, String::ConcatAll(strings));
  const TypeArguments& type_arguments =
      TypeArguments::Handle(Z, type_obj.arguments());
  const Function& constructor =
      Function::Handle(Z, cls.LookupFunctionAllowPrivate(dot_name));
  const int extra_args = 2;
  if (!constructor.IsNull() &&
      constructor.IsGenerativeConstructor() &&
      constructor.AreValidArgumentCounts(number_of_arguments + extra_args,
                                         0,
                                         NULL)) {
    // Create the argument list.
    // Constructors get the uninitialized object and a constructor phase.
    if (!type_arguments.IsNull()) {
      // The type arguments will be null if the class has no type
      // parameters, in which case the following call would fail
      // because there is no slot reserved in the object for the
      // type vector.
      instance.SetTypeArguments(type_arguments);
    }
    Dart_Handle result;
    Array& args = Array::Handle(Z);
    result = SetupArguments(I,
        number_of_arguments, arguments, extra_args, &args);
    if (!::Dart_IsError(result)) {
      args.SetAt(0, instance);
      args.SetAt(1, Smi::Handle(Z, Smi::New(Function::kCtorPhaseAll)));
      const Object& retval = Object::Handle(Z,
          DartEntry::InvokeFunction(constructor, args));
      if (retval.IsError()) {
        result = Api::NewHandle(I, retval.raw());
      } else {
        result = Api::NewHandle(I, instance.raw());
      }
    }
    return result;
  }
  return Api::NewError(
      "%s expects argument 'name' to be a valid constructor.",
      CURRENT_FUNC);
}


DART_EXPORT Dart_Handle Dart_Invoke(Dart_Handle target,
                                    Dart_Handle name,
                                    int number_of_arguments,
                                    Dart_Handle* arguments) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  // TODO(turnidge): This is a bit simplistic.  It overcounts when
  // other operations (gc, compilation) are active.
  TIMERSCOPE(T, time_dart_execution);

  const String& function_name = Api::UnwrapStringHandle(I, name);
  if (function_name.IsNull()) {
    RETURN_TYPE_ERROR(I, name, String);
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
  if (obj.IsType()) {
    if (!Type::Cast(obj).IsFinalized()) {
      return Api::NewError(
          "%s expects argument 'target' to be a fully resolved type.",
          CURRENT_FUNC);
    }

    const Class& cls = Class::Handle(Z, Type::Cast(obj).type_class());
    const Function& function = Function::Handle(Z,
        Resolver::ResolveStaticAllowPrivate(cls,
                                            function_name,
                                            number_of_arguments,
                                            Object::empty_array()));
    if (function.IsNull()) {
      const String& cls_name = String::Handle(Z, cls.Name());
      return Api::NewError("%s: did not find static method '%s.%s'.",
                           CURRENT_FUNC,
                           cls_name.ToCString(),
                           function_name.ToCString());
    }
    // Setup args and check for malformed arguments in the arguments list.
    result = SetupArguments(I, number_of_arguments, arguments, 0, &args);
    if (!::Dart_IsError(result)) {
      result = Api::NewHandle(I, DartEntry::InvokeFunction(function, args));
    }
    return result;
  } else if (obj.IsNull() || obj.IsInstance()) {
    // Since we have allocated an object it would mean that the type of the
    // receiver is already resolved and finalized, hence it is not necessary
    // to check here.
    Instance& instance = Instance::Handle(Z);
    instance ^= obj.raw();
    ArgumentsDescriptor args_desc(
        Array::Handle(Z, ArgumentsDescriptor::New(number_of_arguments + 1)));
    const Function& function = Function::Handle(Z,
        Resolver::ResolveDynamic(instance, function_name, args_desc));
    if (function.IsNull()) {
      // Setup args and check for malformed arguments in the arguments list.
      result = SetupArguments(I,
                              number_of_arguments,
                              arguments,
                              1,
                              &args);
      if (!::Dart_IsError(result)) {
        args.SetAt(0, instance);
        const Array& args_descriptor =
          Array::Handle(Z, ArgumentsDescriptor::New(args.Length()));
        result = Api::NewHandle(I,
                                DartEntry::InvokeNoSuchMethod(instance,
                                                              function_name,
                                                              args,
                                                              args_descriptor));
      }
      return result;
    }
    // Setup args and check for malformed arguments in the arguments list.
    result = SetupArguments(I, number_of_arguments, arguments, 1, &args);
    if (!::Dart_IsError(result)) {
      args.SetAt(0, instance);
      result = Api::NewHandle(I, DartEntry::InvokeFunction(function, args));
    }
    return result;
  } else if (obj.IsLibrary()) {
    // Check whether class finalization is needed.
    const Library& lib = Library::Cast(obj);

    // Check that the library is loaded.
    if (!lib.Loaded()) {
      return Api::NewError(
          "%s expects library argument 'target' to be loaded.",
          CURRENT_FUNC);
    }

    const Function& function =
        Function::Handle(Z, lib.LookupFunctionAllowPrivate(function_name));
    if (function.IsNull()) {
      return Api::NewError("%s: did not find top-level function '%s'.",
                           CURRENT_FUNC,
                           function_name.ToCString());
    }
    // LookupFunctionAllowPrivate does not check argument arity, so we
    // do it here.
    String& error_message = String::Handle(Z);
    if (!function.AreValidArgumentCounts(number_of_arguments,
                                         0,
                                         &error_message)) {
      return Api::NewError("%s: wrong argument count for function '%s': %s.",
                           CURRENT_FUNC,
                           function_name.ToCString(),
                           error_message.ToCString());
    }
    // Setup args and check for malformed arguments in the arguments list.
    result = SetupArguments(I, number_of_arguments, arguments, 0, &args);
    if (!::Dart_IsError(result)) {
      result = Api::NewHandle(I, DartEntry::InvokeFunction(function, args));
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
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);
  const Instance& closure_obj = Api::UnwrapInstanceHandle(I, closure);
  if (closure_obj.IsNull() || !closure_obj.IsCallable(NULL)) {
    RETURN_TYPE_ERROR(I, closure, Instance);
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
      RETURN_TYPE_ERROR(I, arguments[i], Instance);
    }
    args.SetAt(i + 1, obj);
  }
  // Now try to invoke the closure.
  return Api::NewHandle(I, DartEntry::InvokeClosure(args));
}


DART_EXPORT Dart_Handle Dart_GetField(Dart_Handle container, Dart_Handle name) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);

  const String& field_name = Api::UnwrapStringHandle(I, name);
  if (field_name.IsNull()) {
    RETURN_TYPE_ERROR(I, name, String);
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

    field = cls.LookupStaticField(field_name);
    if (field.IsNull() || field.IsUninitialized()) {
      const String& getter_name =
          String::Handle(Z, Field::GetterName(field_name));
      getter = cls.LookupStaticFunctionAllowPrivate(getter_name);
    }

    if (!getter.IsNull()) {
      // Invoke the getter and return the result.
      return Api::NewHandle(I,
          DartEntry::InvokeFunction(getter, Object::empty_array()));
    } else if (!field.IsNull()) {
      return Api::NewHandle(I, field.StaticValue());
    } else {
      return Api::NewError("%s: did not find static field '%s'.",
                           CURRENT_FUNC, field_name.ToCString());
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

    // Invoke the getter and return the result.
    const int kNumArgs = 1;
    const Array& args = Array::Handle(Z, Array::New(kNumArgs));
    args.SetAt(0, instance);
    if (getter.IsNull()) {
      const Array& args_descriptor =
          Array::Handle(Z, ArgumentsDescriptor::New(args.Length()));
      return Api::NewHandle(I,
                            DartEntry::InvokeNoSuchMethod(instance,
                                                          getter_name,
                                                          args,
                                                          args_descriptor));
    }
    return Api::NewHandle(I, DartEntry::InvokeFunction(getter, args));

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
      // A field was found.  Check for a getter in the field's owner classs.
      const Class& cls = Class::Handle(Z, field.owner());
      const String& getter_name = String::Handle(Z,
          Field::GetterName(field_name));
      getter = cls.LookupStaticFunctionAllowPrivate(getter_name);
    }

    if (!getter.IsNull()) {
      // Invoke the getter and return the result.
      return Api::NewHandle(I,
          DartEntry::InvokeFunction(getter, Object::empty_array()));
    }
    if (!field.IsNull()) {
      return Api::NewHandle(I, field.StaticValue());
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
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);

  const String& field_name = Api::UnwrapStringHandle(I, name);
  if (field_name.IsNull()) {
    RETURN_TYPE_ERROR(I, name, String);
  }

  // Since null is allowed for value, we don't use UnwrapInstanceHandle.
  const Object& value_obj = Object::Handle(Z, Api::UnwrapHandle(value));
  if (!value_obj.IsNull() && !value_obj.IsInstance()) {
    RETURN_TYPE_ERROR(I, value, Instance);
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

    field = cls.LookupStaticField(field_name);
    if (field.IsNull()) {
      String& setter_name = String::Handle(Z, Field::SetterName(field_name));
      setter = cls.LookupStaticFunctionAllowPrivate(setter_name);
    }

    if (!setter.IsNull()) {
      // Invoke the setter and return the result.
      const int kNumArgs = 1;
      const Array& args = Array::Handle(Z, Array::New(kNumArgs));
      args.SetAt(0, value_instance);
      const Object& result = Object::Handle(Z,
          DartEntry::InvokeFunction(setter, args));
      if (result.IsError()) {
        return Api::NewHandle(I, result.raw());
      } else {
        return Api::Success();
      }
    } else if (!field.IsNull()) {
      if (field.is_final()) {
        return Api::NewError("%s: cannot set final field '%s'.",
                             CURRENT_FUNC, field_name.ToCString());
      } else {
        field.SetStaticValue(value_instance);
        return Api::Success();
      }
    } else {
      return Api::NewError("%s: did not find static field '%s'.",
                           CURRENT_FUNC, field_name.ToCString());
    }

  } else if (obj.IsInstance()) {
    // Every instance field has a setter Function.  Try to find the
    // setter in any superclass and use that function to access the
    // field.
    const Instance& instance = Instance::Cast(obj);
    Class& cls = Class::Handle(Z, instance.clazz());
    String& setter_name = String::Handle(Z, Field::SetterName(field_name));
    while (!cls.IsNull()) {
      field = cls.LookupInstanceField(field_name);
      if (!field.IsNull() && field.is_final()) {
        return Api::NewError("%s: cannot set final field '%s'.",
                             CURRENT_FUNC, field_name.ToCString());
      }
      setter = cls.LookupDynamicFunctionAllowPrivate(setter_name);
      if (!setter.IsNull()) {
        break;
      }
      cls = cls.SuperClass();
    }

    // Invoke the setter and return the result.
    const int kNumArgs = 2;
    const Array& args = Array::Handle(Z, Array::New(kNumArgs));
    args.SetAt(0, instance);
    args.SetAt(1, value_instance);
    if (setter.IsNull()) {
      const Array& args_descriptor =
          Array::Handle(Z, ArgumentsDescriptor::New(args.Length()));
      return Api::NewHandle(I, DartEntry::InvokeNoSuchMethod(instance,
                                                             setter_name,
                                                             args,
                                                             args_descriptor));
    }
    return Api::NewHandle(I, DartEntry::InvokeFunction(setter, args));

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
        return Api::NewHandle(I, result.raw());
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
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  CHECK_CALLBACK_STATE(isolate);
  {
    const Instance& excp = Api::UnwrapInstanceHandle(isolate, exception);
    if (excp.IsNull()) {
      RETURN_TYPE_ERROR(isolate, exception, Instance);
    }
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
  const Instance* saved_exception;
  {
    NoSafepointScope no_safepoint;
    RawInstance* raw_exception =
        Api::UnwrapInstanceHandle(isolate, exception).raw();
    state->UnwindScopes(isolate->top_exit_frame_info());
    saved_exception = &Instance::Handle(raw_exception);
  }
  Exceptions::Throw(thread, *saved_exception);
  return Api::NewError("Exception was not thrown, internal error");
}


DART_EXPORT Dart_Handle Dart_ReThrowException(Dart_Handle exception,
                                              Dart_Handle stacktrace) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  CHECK_CALLBACK_STATE(isolate);
  {
    const Instance& excp = Api::UnwrapInstanceHandle(isolate, exception);
    if (excp.IsNull()) {
      RETURN_TYPE_ERROR(isolate, exception, Instance);
    }
    const Instance& stk = Api::UnwrapInstanceHandle(isolate, stacktrace);
    if (stk.IsNull()) {
      RETURN_TYPE_ERROR(isolate, stacktrace, Instance);
    }
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
  const Instance* saved_exception;
  const Stacktrace* saved_stacktrace;
  {
    NoSafepointScope no_safepoint;
    RawInstance* raw_exception =
        Api::UnwrapInstanceHandle(isolate, exception).raw();
    RawStacktrace* raw_stacktrace =
        Api::UnwrapStacktraceHandle(isolate, stacktrace).raw();
    state->UnwindScopes(isolate->top_exit_frame_info());
    saved_exception = &Instance::Handle(raw_exception);
    saved_stacktrace = &Stacktrace::Handle(raw_stacktrace);
  }
  Exceptions::ReThrow(thread, *saved_exception, *saved_stacktrace);
  return Api::NewError("Exception was not re thrown, internal error");
}


// --- Native fields and functions ---

DART_EXPORT Dart_Handle Dart_CreateNativeWrapperClass(Dart_Handle library,
                                                      Dart_Handle name,
                                                      int field_count) {
  DARTSCOPE(Thread::Current());
  const String& cls_name = Api::UnwrapStringHandle(I, name);
  if (cls_name.IsNull()) {
    RETURN_TYPE_ERROR(I, name, String);
  }
  const Library& lib = Api::UnwrapLibraryHandle(I, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(I, library, Library);
  }
  if (!Utils::IsUint(16, field_count)) {
    return Api::NewError(
        "Invalid field_count passed to Dart_CreateNativeWrapperClass");
  }
  CHECK_CALLBACK_STATE(I);

  String& cls_symbol = String::Handle(Z, Symbols::New(cls_name));
  const Class& cls = Class::Handle(Z,
      Class::NewNativeWrapper(lib, cls_symbol, field_count));
  if (cls.IsNull()) {
    return Api::NewError(
        "Unable to create native wrapper class : already exists");
  }
  return Api::NewHandle(I, cls.RareType());
}


DART_EXPORT Dart_Handle Dart_GetNativeInstanceFieldCount(Dart_Handle obj,
                                                         int* count) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ReusableObjectHandleScope reused_obj_handle(isolate);
  const Instance& instance = Api::UnwrapInstanceHandle(reused_obj_handle, obj);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(isolate, obj, Instance);
  }
  *count = instance.NumNativeFields();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_GetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t* value) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  ReusableObjectHandleScope reused_obj_handle(isolate);
  const Instance& instance = Api::UnwrapInstanceHandle(reused_obj_handle, obj);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(isolate, obj, Instance);
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
  const Instance& instance = Api::UnwrapInstanceHandle(I, obj);
  if (instance.IsNull()) {
    RETURN_TYPE_ERROR(I, obj, Instance);
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
    Dart_NativeArgument_Type arg_type = static_cast<Dart_NativeArgument_Type>(
        desc.type);
    int arg_index = desc.index;
    ASSERT(arg_index >= 0 && arg_index < arguments->NativeArgCount());
    Dart_NativeArgument_Value* native_value = &(arg_values[i]);
    switch (arg_type) {
      case Dart_NativeArgument_kBool:
        if (!Api::GetNativeBooleanArgument(arguments,
                                           arg_index,
                                           &(native_value->as_bool))) {
          return Api::NewError("%s: expects argument at index %d to be of"
                               " type Boolean.", CURRENT_FUNC, i);
        }
        break;

      case Dart_NativeArgument_kInt32: {
        int64_t value = 0;
        if (!GetNativeIntegerArgument(arguments,
                                      arg_index,
                                      &value)) {
          return Api::NewError("%s: expects argument at index %d to be of"
                               " type Integer.", CURRENT_FUNC, i);
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
        if (!GetNativeIntegerArgument(arguments,
                                      arg_index,
                                      &value)) {
          return Api::NewError("%s: expects argument at index %d to be of"
                               " type Integer.", CURRENT_FUNC, i);
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
        if (!GetNativeIntegerArgument(arguments,
                                      arg_index,
                                      &value)) {
          return Api::NewError("%s: expects argument at index %d to be of"
                               " type Integer.", CURRENT_FUNC, i);
        }
        native_value->as_int64 = value;
        break;
      }

      case Dart_NativeArgument_kUint64: {
        uint64_t value = 0;
        if (!GetNativeUnsignedIntegerArgument(arguments,
                                              arg_index,
                                              &value)) {
          return Api::NewError("%s: expects argument at index %d to be of"
                               " type Integer.", CURRENT_FUNC, i);
        }
        native_value->as_uint64 = value;
        break;
      }

      case Dart_NativeArgument_kDouble:
        if (!GetNativeDoubleArgument(arguments,
                                     arg_index,
                                     &(native_value->as_double))) {
          return Api::NewError("%s: expects argument at index %d to be of"
                               " type Double.", CURRENT_FUNC, i);
        }
        break;

      case Dart_NativeArgument_kString:
        if (!GetNativeStringArgument(arguments,
                                     arg_index,
                                     &(native_value->as_string.dart_str),
                                     &(native_value->as_string.peer))) {
          return Api::NewError("%s: expects argument at index %d to be of"
                               " type String.", CURRENT_FUNC, i);
        }
        break;

      case Dart_NativeArgument_kNativeFields: {
        Dart_Handle result = GetNativeFieldsOfArgument(
            arguments,
            arg_index,
            native_value->as_native_fields.num_fields,
            native_value->as_native_fields.values,
            CURRENT_FUNC);
        if (result != Api::Success()) {
          return result;
        }
        break;
      }

      case Dart_NativeArgument_kInstance: {
        Isolate* isolate = arguments->thread()->isolate();
        ASSERT(isolate == Isolate::Current());
        ASSERT(isolate->api_state() &&
               isolate->api_state()->top_scope() != NULL);
        native_value->as_instance =
            Api::NewHandle(isolate, arguments->NativeArgAt(arg_index));
        break;
      }

      default:
        return Api::NewError("%s: invalid argument type %d.",
                             CURRENT_FUNC, arg_type);
    }
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args,
                                               int index) {
  TRACE_API_CALL(CURRENT_FUNC);
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  if ((index < 0) || (index >= arguments->NativeArgCount())) {
    return Api::NewError(
        "%s: argument 'index' out of range. Expected 0..%d but saw %d.",
        CURRENT_FUNC, arguments->NativeArgCount() - 1, index);
  }
  return Api::NewHandle(arguments->thread()->isolate(),
                        arguments->NativeArgAt(index));
}


DART_EXPORT int Dart_GetNativeArgumentCount(Dart_NativeArguments args) {
  TRACE_API_CALL(CURRENT_FUNC);
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  return arguments->NativeArgCount();
}


DART_EXPORT Dart_Handle Dart_GetNativeFieldsOfArgument(
    Dart_NativeArguments args,
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
  return GetNativeFieldsOfArgument(arguments,
                                   arg_index,
                                   num_fields,
                                   field_values,
                                   CURRENT_FUNC);
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
  return Api::NewError("%s expects receiver argument to be non-null and of"
                       " type Instance.", CURRENT_FUNC);
}


DART_EXPORT Dart_Handle Dart_GetNativeStringArgument(Dart_NativeArguments args,
                                                     int arg_index,
                                                     void** peer) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Dart_Handle result = Api::Null();
  if (!GetNativeStringArgument(arguments, arg_index, &result, peer)) {
    return Api::NewError("%s expects argument at %d to be of"
                         " type String.", CURRENT_FUNC, arg_index);
  }
  return result;
}


DART_EXPORT Dart_Handle Dart_GetNativeIntegerArgument(Dart_NativeArguments args,
                                                      int index,
                                                      int64_t* value) {
  TRACE_API_CALL(CURRENT_FUNC);
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  if ((index < 0) || (index >= arguments->NativeArgCount())) {
    return Api::NewError(
        "%s: argument 'index' out of range. Expected 0..%d but saw %d.",
        CURRENT_FUNC, arguments->NativeArgCount() - 1, index);
  }
  if (!GetNativeIntegerArgument(arguments, index, value)) {
    return Api::NewError("%s: expects argument at %d to be of"
                         " type Integer.", CURRENT_FUNC, index);
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_GetNativeBooleanArgument(Dart_NativeArguments args,
                                                      int index,
                                                      bool* value) {
  TRACE_API_CALL(CURRENT_FUNC);
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
  TRACE_API_CALL(CURRENT_FUNC);
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  if ((index < 0) || (index >= arguments->NativeArgCount())) {
    return Api::NewError(
        "%s: argument 'index' out of range. Expected 0..%d but saw %d.",
        CURRENT_FUNC, arguments->NativeArgCount() - 1, index);
  }
  if (!GetNativeDoubleArgument(arguments, index, value)) {
    return Api::NewError("%s: expects argument at %d to be of"
                         " type Double.", CURRENT_FUNC, index);
  }
  return Api::Success();
}


DART_EXPORT void Dart_SetReturnValue(Dart_NativeArguments args,
                                     Dart_Handle retval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  if ((retval != Api::Null()) && (!Api::IsInstance(retval))) {
    const Object& ret_obj = Object::Handle(Api::UnwrapHandle(retval));
    FATAL1("Return value check failed: saw '%s' expected a dart Instance.",
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
         (isolate->api_state()->IsValidWeakPersistentHandle(rval) ||
          isolate->api_state()->IsValidPrologueWeakPersistentHandle(rval)));
#endif
  Api::SetWeakHandleReturnValue(arguments, rval);
}


// --- Environment ---
RawString* Api::CallEnvironmentCallback(Isolate* isolate, const String& name) {
  Scope api_scope(isolate);
  Dart_EnvironmentCallback callback = isolate->environment_callback();
  String& result = String::Handle(isolate);
  if (callback != NULL) {
    Dart_Handle response = callback(Api::NewHandle(isolate, name.raw()));
    if (::Dart_IsString(response)) {
      result ^= Api::UnwrapHandle(response);
    } else if (::Dart_IsError(response)) {
      const Object& error =
          Object::Handle(isolate, Api::UnwrapHandle(response));
      Exceptions::ThrowArgumentError(
          String::Handle(String::New(Error::Cast(error).ToErrorCString())));
    } else if (!::Dart_IsNull(response)) {
      // At this point everything except null are invalid environment values.
      Exceptions::ThrowArgumentError(
          String::Handle(String::New("Illegal environment value")));
    }
  }
  if (result.IsNull()) {
    // TODO(iposva): Determine whether builtin values can be overriden by the
    // embedder.
    // Check for default VM provided values. If it was not overriden on the
    // command line.
    if (Symbols::DartIsVM().Equals(name)) {
      return Symbols::True().raw();
    }
  }
  return result.raw();
}


DART_EXPORT Dart_Handle Dart_SetEnvironmentCallback(
    Dart_EnvironmentCallback callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  isolate->set_environment_callback(callback);
  return Api::Success();
}


// --- Scripts and Libraries ---
DART_EXPORT void Dart_SetBooleanReturnValue(Dart_NativeArguments args,
                                            bool retval) {
  TRACE_API_CALL(CURRENT_FUNC);
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
    ASSERT_CALLBACK_STATE(arguments->thread()->isolate());
    Api::SetIntegerReturnValue(arguments, retval);
  }
}


DART_EXPORT void Dart_SetDoubleReturnValue(Dart_NativeArguments args,
                                           double retval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
#if defined(DEBUG)
  Isolate* isolate = arguments->thread()->isolate();
  ASSERT(isolate == Isolate::Current());
  ASSERT_CALLBACK_STATE(isolate);
#endif
  Api::SetDoubleReturnValue(arguments, retval);
}


// --- Scripts and Libraries ---

DART_EXPORT Dart_Handle Dart_SetLibraryTagHandler(
    Dart_LibraryTagHandler handler) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  isolate->set_library_tag_handler(handler);
  return Api::Success();
}


// NOTE: Need to pass 'result' as a parameter here in order to avoid
// warning: variable 'result' might be clobbered by 'longjmp' or 'vfork'
// which shows up because of the use of setjmp.
static void CompileSource(Isolate* isolate,
                          const Library& lib,
                          const Script& script,
                          Dart_Handle* result) {
  bool update_lib_status = (script.kind() == RawScript::kScriptTag ||
                            script.kind() == RawScript::kLibraryTag);
  if (update_lib_status) {
    lib.SetLoadInProgress();
  }
  ASSERT(isolate != NULL);
  const Error& error = Error::Handle(isolate, Compiler::Compile(lib, script));
  if (error.IsNull()) {
    *result = Api::NewHandle(isolate, lib.raw());
  } else {
    *result = Api::NewHandle(isolate, error.raw());
    // Compilation errors are not Dart instances, so just mark the library
    // as having failed to load without providing an error instance.
    lib.SetLoadError(Object::null_instance());
  }
}


DART_EXPORT Dart_Handle Dart_LoadScript(Dart_Handle url,
                                        Dart_Handle source,
                                        intptr_t line_offset,
                                        intptr_t column_offset) {
  DARTSCOPE(Thread::Current());
  TIMERSCOPE(T, time_script_loading);
  const String& url_str = Api::UnwrapStringHandle(I, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(I, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(I, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(I, source, String);
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
  CHECK_CALLBACK_STATE(I);

  NoHeapGrowthControlScope no_growth_control;

  library = Library::New(url_str);
  library.set_debuggable(true);
  library.Register();
  I->object_store()->set_root_library(library);

  const Script& script = Script::Handle(Z,
      Script::New(url_str, source_str, RawScript::kScriptTag));
  script.SetLocationOffset(line_offset, column_offset);
  Dart_Handle result;
  CompileSource(I, library, script, &result);
  return result;
}


DART_EXPORT Dart_Handle Dart_LoadScriptFromSnapshot(const uint8_t* buffer,
                                                    intptr_t buffer_len) {
  DARTSCOPE(Thread::Current());
  TIMERSCOPE(T, time_script_loading);
  StackZone zone(T);
  if (buffer == NULL) {
    RETURN_NULL_ERROR(buffer);
  }
  NoHeapGrowthControlScope no_growth_control;

  const Snapshot* snapshot = Snapshot::SetupFromBuffer(buffer);
  if (!snapshot->IsScriptSnapshot()) {
    return Api::NewError("%s expects parameter 'buffer' to be a script type"
                         " snapshot.", CURRENT_FUNC);
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
  CHECK_CALLBACK_STATE(I);

  ASSERT(snapshot->kind() == Snapshot::kScript);
  ScriptSnapshotReader reader(snapshot->content(), snapshot->length(), T);
  const Object& tmp = Object::Handle(Z, reader.ReadScriptSnapshot());
  if (tmp.IsError()) {
    return Api::NewHandle(I, tmp.raw());
  }
  library ^= tmp.raw();
  library.set_debuggable(true);
  I->object_store()->set_root_library(library);
  return Api::NewHandle(I, library.raw());
}


DART_EXPORT Dart_Handle Dart_RootLibrary() {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  return Api::NewHandle(isolate, isolate->object_store()->root_library());
}


DART_EXPORT Dart_Handle Dart_GetClass(Dart_Handle library,
                                      Dart_Handle class_name) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(I, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(I, library, Library);
  }
  const String& cls_name = Api::UnwrapStringHandle(I, class_name);
  if (cls_name.IsNull()) {
    RETURN_TYPE_ERROR(I, class_name, String);
  }
  const Class& cls = Class::Handle(Z, lib.LookupClassAllowPrivate(cls_name));
  if (cls.IsNull()) {
    // TODO(turnidge): Return null or error in this case?
    const String& lib_name = String::Handle(Z, lib.name());
    return Api::NewError("Class '%s' not found in library '%s'.",
                         cls_name.ToCString(), lib_name.ToCString());
  }
  return Api::NewHandle(I, cls.RareType());
}


DART_EXPORT Dart_Handle Dart_GetType(Dart_Handle library,
                                     Dart_Handle class_name,
                                     intptr_t number_of_type_arguments,
                                     Dart_Handle* type_arguments) {
  DARTSCOPE(Thread::Current());

  // Validate the input arguments.
  const Library& lib = Api::UnwrapLibraryHandle(I, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(I, library, Library);
  }
  if (!lib.Loaded()) {
    return Api::NewError(
        "%s expects library argument 'library' to be loaded.",
        CURRENT_FUNC);
  }
  const String& name_str = Api::UnwrapStringHandle(I, class_name);
  if (name_str.IsNull()) {
    RETURN_TYPE_ERROR(I, class_name, String);
  }
  const Class& cls = Class::Handle(Z, lib.LookupClassAllowPrivate(name_str));
  if (cls.IsNull()) {
    const String& lib_name = String::Handle(Z, lib.name());
    return Api::NewError("Type '%s' not found in library '%s'.",
                         name_str.ToCString(), lib_name.ToCString());
  }
  if (cls.NumTypeArguments() == 0) {
    if (number_of_type_arguments != 0) {
      return Api::NewError("Invalid number of type arguments specified, "
                           "got %" Pd " expected 0", number_of_type_arguments);
    }
    return Api::NewHandle(I, Type::NewNonParameterizedType(cls));
  }
  intptr_t num_expected_type_arguments = cls.NumTypeParameters();
  TypeArguments& type_args_obj = TypeArguments::Handle();
  if (number_of_type_arguments > 0) {
    if (type_arguments == NULL) {
      RETURN_NULL_ERROR(type_arguments);
    }
    if (num_expected_type_arguments != number_of_type_arguments) {
      return Api::NewError("Invalid number of type arguments specified, "
                           "got %" Pd " expected %" Pd,
                           number_of_type_arguments,
                           num_expected_type_arguments);
    }
    const Array& array = Api::UnwrapArrayHandle(I, *type_arguments);
    if (array.IsNull()) {
      RETURN_TYPE_ERROR(I, *type_arguments, Array);
    }
    if (array.Length() != num_expected_type_arguments) {
      return Api::NewError("Invalid type arguments specified, expected an "
                           "array of len %" Pd " but got an array of len %" Pd,
                           number_of_type_arguments,
                           array.Length());
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
  Type& instantiated_type = Type::Handle(
      Type::New(cls, type_args_obj, Scanner::kNoSourcePos));
  instantiated_type ^= ClassFinalizer::FinalizeType(
      cls, instantiated_type, ClassFinalizer::kCanonicalize);
  return Api::NewHandle(I, instantiated_type.raw());
}


DART_EXPORT Dart_Handle Dart_LibraryUrl(Dart_Handle library) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(I, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(I, library, Library);
  }
  const String& url = String::Handle(Z, lib.url());
  ASSERT(!url.IsNull());
  return Api::NewHandle(I, url.raw());
}


DART_EXPORT Dart_Handle Dart_LookupLibrary(Dart_Handle url) {
  DARTSCOPE(Thread::Current());
  const String& url_str = Api::UnwrapStringHandle(I, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(I, url, String);
  }
  const Library& library = Library::Handle(Z, Library::LookupLibrary(url_str));
  if (library.IsNull()) {
    return Api::NewError("%s: library '%s' not found.",
                         CURRENT_FUNC, url_str.ToCString());
  } else {
    return Api::NewHandle(I, library.raw());
  }
}


DART_EXPORT Dart_Handle Dart_LibraryHandleError(Dart_Handle library_in,
                                                Dart_Handle error_in) {
  DARTSCOPE(Thread::Current());

  const Library& lib = Api::UnwrapLibraryHandle(I, library_in);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(I, library_in, Library);
  }
  const Instance& err = Api::UnwrapInstanceHandle(I, error_in);
  if (err.IsNull()) {
    RETURN_TYPE_ERROR(I, error_in, Instance);
  }
  CHECK_CALLBACK_STATE(I);

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
                                         Dart_Handle source,
                                         intptr_t line_offset,
                                         intptr_t column_offset) {
  DARTSCOPE(Thread::Current());
  TIMERSCOPE(T, time_script_loading);
  const String& url_str = Api::UnwrapStringHandle(I, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(I, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(I, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(I, source, String);
  }
  if (line_offset < 0) {
    return Api::NewError("%s: argument 'line_offset' must be positive number",
                         CURRENT_FUNC);
  }
  if (column_offset < 0) {
    return Api::NewError("%s: argument 'column_offset' must be positive number",
                         CURRENT_FUNC);
  }
  CHECK_CALLBACK_STATE(I);

  NoHeapGrowthControlScope no_growth_control;

  Library& library = Library::Handle(Z, Library::LookupLibrary(url_str));
  if (library.IsNull()) {
    library = Library::New(url_str);
    library.Register();
  } else if (library.LoadInProgress() ||
      library.Loaded() ||
      library.LoadFailed()) {
    // The source for this library has either been loaded or is in the
    // process of loading.  Return an error.
    return Api::NewError("%s: library '%s' has already been loaded.",
                         CURRENT_FUNC, url_str.ToCString());
  }
  const Script& script = Script::Handle(Z,
      Script::New(url_str, source_str, RawScript::kLibraryTag));
  script.SetLocationOffset(line_offset, column_offset);
  Dart_Handle result;
  CompileSource(I, library, script, &result);
  // Propagate the error out right now.
  if (::Dart_IsError(result)) {
    return result;
  }

  // If this is the dart:_builtin library, register it with the VM.
  if (url_str.Equals("dart:_builtin")) {
    I->object_store()->set_builtin_library(library);
    Dart_Handle state = Api::CheckAndFinalizePendingClasses(I);
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
  const Library& library_vm = Api::UnwrapLibraryHandle(I, library);
  if (library_vm.IsNull()) {
    RETURN_TYPE_ERROR(I, library, Library);
  }
  const Library& import_vm = Api::UnwrapLibraryHandle(I, import);
  if (import_vm.IsNull()) {
    RETURN_TYPE_ERROR(I, import, Library);
  }
  const Object& prefix_object = Object::Handle(Z, Api::UnwrapHandle(prefix));
  const String& prefix_vm = prefix_object.IsNull()
      ? Symbols::Empty()
      : String::Cast(prefix_object);
  if (prefix_vm.IsNull()) {
    RETURN_TYPE_ERROR(I, prefix, String);
  }
  CHECK_CALLBACK_STATE(I);

  const String& prefix_symbol = String::Handle(Z, Symbols::New(prefix_vm));
  const Namespace& import_ns = Namespace::Handle(Z,
      Namespace::New(import_vm, Object::null_array(), Object::null_array()));
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


DART_EXPORT Dart_Handle Dart_LoadSource(Dart_Handle library,
                                        Dart_Handle url,
                                        Dart_Handle source,
                                        intptr_t line_offset,
                                        intptr_t column_offset) {
  DARTSCOPE(Thread::Current());
  TIMERSCOPE(T, time_script_loading);
  const Library& lib = Api::UnwrapLibraryHandle(I, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(I, library, Library);
  }
  const String& url_str = Api::UnwrapStringHandle(I, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(I, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(I, source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(I, source, String);
  }
  if (line_offset < 0) {
    return Api::NewError("%s: argument 'line_offset' must be positive number",
                         CURRENT_FUNC);
  }
  if (column_offset < 0) {
    return Api::NewError("%s: argument 'column_offset' must be positive number",
                         CURRENT_FUNC);
  }
  CHECK_CALLBACK_STATE(I);

  NoHeapGrowthControlScope no_growth_control;

  const Script& script = Script::Handle(Z,
      Script::New(url_str, source_str, RawScript::kSourceTag));
  script.SetLocationOffset(line_offset, column_offset);
  Dart_Handle result;
  CompileSource(I, lib, script, &result);
  return result;
}


DART_EXPORT Dart_Handle Dart_LibraryLoadPatch(Dart_Handle library,
                                              Dart_Handle url,
                                              Dart_Handle patch_source) {
  DARTSCOPE(Thread::Current());
  TIMERSCOPE(T, time_script_loading);
  const Library& lib = Api::UnwrapLibraryHandle(I, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(I, library, Library);
  }
  const String& url_str = Api::UnwrapStringHandle(I, url);
  if (url_str.IsNull()) {
    RETURN_TYPE_ERROR(I, url, String);
  }
  const String& source_str = Api::UnwrapStringHandle(I, patch_source);
  if (source_str.IsNull()) {
    RETURN_TYPE_ERROR(I, patch_source, String);
  }
  CHECK_CALLBACK_STATE(I);

  NoHeapGrowthControlScope no_growth_control;

  const Script& script = Script::Handle(Z,
      Script::New(url_str, source_str, RawScript::kPatchTag));
  Dart_Handle result;
  CompileSource(I, lib, script, &result);
  return result;
}


// Finalizes classes and invokes Dart core library function that completes
// futures of loadLibrary calls (deferred library loading).
DART_EXPORT Dart_Handle Dart_FinalizeLoading(bool complete_futures) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(I);

  I->DoneLoading();

  // TODO(hausner): move the remaining code below (finalization and
  // invoing of _completeDeferredLoads) into Isolate::DoneLoading().

  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(I);
  if (::Dart_IsError(state)) {
    return state;
  }

  // Now that the newly loaded classes are finalized, notify the debugger
  // that new code has been loaded. If there are latent breakpoints in
  // the new code, the debugger convert them to unresolved source breakpoints.
  // The code that completes the futures (invoked below) may call into the
  // newly loaded code and trigger one of these breakpoints.
  I->debugger()->NotifyDoneLoading();

  // Notify mirrors that MirrorSystem.libraries needs to be recomputed.
  const Library& libmirrors = Library::Handle(Z, Library::MirrorsLibrary());
  const Field& dirty_bit = Field::Handle(Z,
      libmirrors.LookupLocalField(String::Handle(String::New("dirty"))));
  ASSERT(!dirty_bit.IsNull() && dirty_bit.is_static());
  dirty_bit.SetStaticValue(Bool::True());

  if (complete_futures) {
    const Library& corelib = Library::Handle(Z, Library::CoreLibrary());
    const String& function_name =
        String::Handle(Z, String::New("_completeDeferredLoads"));
    const Function& function = Function::Handle(Z,
        corelib.LookupFunctionAllowPrivate(function_name));
    ASSERT(!function.IsNull());
    const Array& args = Array::empty_array();

    const Object& res =
        Object::Handle(Z, DartEntry::InvokeFunction(function, args));
    I->object_store()->clear_pending_deferred_loads();
    if (res.IsError() || res.IsUnhandledException()) {
      return Api::NewHandle(I, res.raw());
    }
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_SetNativeResolver(
    Dart_Handle library,
    Dart_NativeEntryResolver resolver,
    Dart_NativeEntrySymbol symbol) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(I, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(I, library, Library);
  }
  lib.set_native_entry_resolver(resolver);
  lib.set_native_entry_symbol_resolver(symbol);
  return Api::Success();
}


// --- Peer support ---

DART_EXPORT Dart_Handle Dart_GetPeer(Dart_Handle object, void** peer) {
  if (peer == NULL) {
    RETURN_NULL_ERROR(peer);
  }
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& obj = isolate->ObjectHandle();
  obj = Api::UnwrapHandle(object);
  if (obj.IsNull() || obj.IsNumber() || obj.IsBool()) {
    const char* msg =
        "%s: argument 'object' cannot be a subtype of Null, num, or bool";
    return Api::NewError(msg, CURRENT_FUNC);
  }
  {
    NoSafepointScope no_safepoint;
    RawObject* raw_obj = obj.raw();
    *peer = isolate->heap()->GetPeer(raw_obj);
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_SetPeer(Dart_Handle object, void* peer) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& obj = isolate->ObjectHandle();
  obj = Api::UnwrapHandle(object);
  if (obj.IsNull() || obj.IsNumber() || obj.IsBool()) {
    const char* msg =
        "%s: argument 'object' cannot be a subtype of Null, num, or bool";
    return Api::NewError(msg, CURRENT_FUNC);
  }
  {
    NoSafepointScope no_safepoint;
    RawObject* raw_obj = obj.raw();
    isolate->heap()->SetPeer(raw_obj, peer);
  }
  return Api::Success();
}


// --- Service support ---

DART_EXPORT bool Dart_IsServiceIsolate(Dart_Isolate isolate) {
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  return ServiceIsolate::IsServiceIsolate(iso);
}


DART_EXPORT Dart_Port Dart_ServiceWaitForLoadPort() {
  return ServiceIsolate::WaitForLoadPort();
}


DART_EXPORT void Dart_RegisterIsolateServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
  Service::RegisterIsolateEmbedderCallback(name, callback, user_data);
}


DART_EXPORT void Dart_RegisterRootServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
  Service::RegisterRootEmbedderCallback(name, callback, user_data);
}


DART_EXPORT Dart_Handle Dart_SetServiceStreamCallbacks(
    Dart_ServiceStreamListenCallback listen_callback,
    Dart_ServiceStreamCancelCallback cancel_callback) {
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
  Service::SendEmbedderEvent(I, stream_id, event_kind,
                             bytes, bytes_length);
  return Api::Success();
}


DART_EXPORT void Dart_TimelineSetRecordedStreams(int64_t stream_mask) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  isolate->GetAPIStream()->set_enabled(
      (stream_mask & DART_TIMELINE_STREAM_API) != 0);
  isolate->GetCompilerStream()->set_enabled(
      (stream_mask & DART_TIMELINE_STREAM_COMPILER) != 0);
  isolate->GetEmbedderStream()->set_enabled(
      (stream_mask & DART_TIMELINE_STREAM_EMBEDDER) != 0);
  isolate->GetGCStream()->set_enabled(
      (stream_mask & DART_TIMELINE_STREAM_GC) != 0);
  isolate->GetIsolateStream()->set_enabled(
      (stream_mask & DART_TIMELINE_STREAM_ISOLATE) != 0);
}


DART_EXPORT bool Dart_TimelineGetTrace(Dart_StreamConsumer consumer,
                                       void* user_data) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (consumer == NULL) {
    return false;
  }
  TimelineEventRecorder* timeline_recorder = Timeline::recorder();
  if (timeline_recorder == NULL) {
    // Nothing has been recorded.
    return false;
  }
  // Suspend execution of other threads while serializing to JSON.
  isolate->thread_registry()->SafepointThreads();
  JSONStream js;
  IsolateTimelineEventFilter filter(isolate);
  timeline_recorder->PrintJSON(&js, &filter);
  // Resume execution of other threads.
  isolate->thread_registry()->ResumeAllThreads();

  // Copy output.
  char* output = NULL;
  intptr_t output_length = 0;
  js.Steal(const_cast<const char**>(&output), &output_length);
  if (output != NULL) {
    // Add one for the '\0' character.
    output_length++;
  }
  // Start stream.
  const char* kStreamName = "timeline";
  const intptr_t kDataSize = 64 * KB;
  consumer(Dart_StreamConsumer_kStart,
           kStreamName,
           NULL,
           0,
           user_data);

  // Stream out data.
  intptr_t cursor = 0;
  intptr_t remaining = output_length;
  while (remaining >= kDataSize) {
    consumer(Dart_StreamConsumer_kData,
             kStreamName,
             reinterpret_cast<uint8_t*>(&output[cursor]),
             kDataSize,
             user_data);
    cursor += kDataSize;
    remaining -= kDataSize;
  }
  if (remaining > 0) {
    ASSERT(remaining < kDataSize);
    consumer(Dart_StreamConsumer_kData,
             kStreamName,
             reinterpret_cast<uint8_t*>(&output[cursor]),
             remaining,
             user_data);
    cursor += remaining;
    remaining -= remaining;
  }
  ASSERT(cursor == output_length);
  ASSERT(remaining == 0);
  // We stole the JSONStream's output buffer, free it.
  free(output);

  // Finish stream.
  consumer(Dart_StreamConsumer_kFinish,
           kStreamName,
           NULL,
           0,
           user_data);
  return true;
}


DART_EXPORT Dart_Handle Dart_TimelineDuration(const char* label,
                                              int64_t start_micros,
                                              int64_t end_micros) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (label == NULL) {
    RETURN_NULL_ERROR(label);
  }
  if (start_micros > end_micros) {
    const char* msg = "%s: start_micros must be <= end_micros";
    return Api::NewError(msg, CURRENT_FUNC);
  }
  TimelineStream* stream = isolate->GetEmbedderStream();
  ASSERT(stream != NULL);
  TimelineEvent* event = stream->StartEvent();
  if (event != NULL) {
    event->Duration(label, start_micros, end_micros);
    event->Complete();
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_TimelineInstant(const char* label) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (label == NULL) {
    RETURN_NULL_ERROR(label);
  }
  TimelineStream* stream = isolate->GetEmbedderStream();
  ASSERT(stream != NULL);
  TimelineEvent* event = stream->StartEvent();
  if (event != NULL) {
    event->Instant(label);
    event->Complete();
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_TimelineAsyncBegin(const char* label,
                                                int64_t* async_id) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (label == NULL) {
    RETURN_NULL_ERROR(label);
  }
  if (async_id == NULL) {
    RETURN_NULL_ERROR(async_id);
  }
  *async_id = -1;
  TimelineStream* stream = isolate->GetEmbedderStream();
  ASSERT(stream != NULL);
  TimelineEvent* event = stream->StartEvent();
  if (event != NULL) {
    TimelineEventRecorder* recorder = Timeline::recorder();
    ASSERT(recorder != NULL);
    *async_id = recorder->GetNextAsyncId();
    event->AsyncBegin(label, *async_id);
    event->Complete();
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_TimelineAsyncInstant(const char* label,
                                                  int64_t async_id) {
  if (async_id < 0) {
    return Api::Success();
  }
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (label == NULL) {
    RETURN_NULL_ERROR(label);
  }
  TimelineStream* stream = isolate->GetEmbedderStream();
  ASSERT(stream != NULL);
  TimelineEvent* event = stream->StartEvent();
  if (event != NULL) {
    event->AsyncInstant(label, async_id);
    event->Complete();
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_TimelineAsyncEnd(const char* label,
                                              int64_t async_id) {
  if (async_id < 0) {
    return Api::Success();
  }
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  if (label == NULL) {
    RETURN_NULL_ERROR(label);
  }
  TimelineStream* stream = isolate->GetEmbedderStream();
  ASSERT(stream != NULL);
  TimelineEvent* event = stream->StartEvent();
  if (event != NULL) {
    event->AsyncEnd(label, async_id);
    event->Complete();
  }
  return Api::Success();
}


static void Precompile(Isolate* isolate, Dart_Handle* result) {
  ASSERT(isolate != NULL);
  const Error& error = Error::Handle(isolate, Precompiler::CompileAll());
  if (error.IsNull()) {
    *result = Api::Success();
  } else {
    *result = Api::NewHandle(isolate, error.raw());
  }
}


DART_EXPORT Dart_Handle Dart_Precompile() {
  DARTSCOPE(Thread::Current());
  Dart_Handle result = Api::CheckAndFinalizePendingClasses(I);
  if (::Dart_IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(I);
  Precompile(I, &result);
  return result;
}


DART_EXPORT Dart_Handle Dart_CreatePrecompiledSnapshot(
    uint8_t** vm_isolate_snapshot_buffer,
    intptr_t* vm_isolate_snapshot_size,
    uint8_t** isolate_snapshot_buffer,
    intptr_t* isolate_snapshot_size,
    uint8_t** instructions_snapshot_buffer,
    intptr_t* instructions_snapshot_size) {
  ASSERT(FLAG_load_deferred_eagerly);
  DARTSCOPE(Thread::Current());
  if (vm_isolate_snapshot_buffer == NULL) {
    RETURN_NULL_ERROR(vm_isolate_snapshot_buffer);
  }
  if (vm_isolate_snapshot_size == NULL) {
    RETURN_NULL_ERROR(vm_isolate_snapshot_size);
  }
  if (isolate_snapshot_buffer == NULL) {
    RETURN_NULL_ERROR(isolate_snapshot_buffer);
  }
  if (isolate_snapshot_size == NULL) {
    RETURN_NULL_ERROR(isolate_snapshot_size);
  }
  if (instructions_snapshot_buffer == NULL) {
    RETURN_NULL_ERROR(instructions_snapshot_buffer);
  }
  if (instructions_snapshot_size == NULL) {
    RETURN_NULL_ERROR(instructions_snapshot_size);
  }
  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(I);
  if (::Dart_IsError(state)) {
    return state;
  }
  I->heap()->CollectAllGarbage();
  PrecompiledSnapshotWriter writer(vm_isolate_snapshot_buffer,
                                   isolate_snapshot_buffer,
                                   instructions_snapshot_buffer,
                                   ApiReallocate);
  writer.WriteFullSnapshot();
  *vm_isolate_snapshot_size = writer.VmIsolateSnapshotSize();
  *isolate_snapshot_size = writer.IsolateSnapshotSize();
  *instructions_snapshot_size = writer.InstructionsSnapshotSize();

  return Api::Success();
}

}  // namespace dart
