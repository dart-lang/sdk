// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "include/dart_native_api.h"

#include <cstring>
#include <memory>
#include <utility>

#include "lib/stacktrace.h"
#include "platform/assert.h"
#include "platform/unicode.h"
#include "vm/app_snapshot.h"
#include "vm/class_finalizer.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/dwarf.h"
#include "vm/elf.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/heap/verifier.h"
#include "vm/image_snapshot.h"
#include "vm/isolate_reload.h"
#include "vm/kernel_isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/message_snapshot.h"
#include "vm/native_entry.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/object_graph.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/os_thread.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/profiler_service.h"
#include "vm/program_visitor.h"
#include "vm/resolver.h"
#include "vm/reusable_handles.h"
#include "vm/service.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/uri.h"
#include "vm/version.h"
#include "vm/zone_text_buffer.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/aot/precompiler.h"
#include "vm/kernel_loader.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

// Facilitate quick access to the current zone once we have the current thread.
#define Z (T->zone())

DECLARE_FLAG(bool, print_class_table);
#if defined(DEBUG) && !defined(DART_PRECOMPILED_RUNTIME)
DEFINE_FLAG(bool,
            check_function_fingerprints,
            true,
            "Check function fingerprints");
#endif  // defined(DEBUG) && !defined(DART_PRECOMPILED_RUNTIME).
DEFINE_FLAG(bool,
            verify_acquired_data,
            false,
            "Verify correct API acquire/release of typed data.");
DEFINE_FLAG(bool,
            dump_tables,
            false,
            "Dump common hash tables before snapshotting.");

#define CHECK_ERROR_HANDLE(error)                                              \
  {                                                                            \
    ErrorPtr err = (error);                                                    \
    if (err != Error::null()) {                                                \
      return Api::NewHandle(T, err);                                           \
    }                                                                          \
  }

ThreadLocalKey Api::api_native_key_ = kUnsetThreadLocalKey;
Dart_Handle Api::true_handle_ = nullptr;
Dart_Handle Api::false_handle_ = nullptr;
Dart_Handle Api::null_handle_ = nullptr;
Dart_Handle Api::empty_string_handle_ = nullptr;
Dart_Handle Api::no_callbacks_error_handle_ = nullptr;
Dart_Handle Api::unwind_in_progress_error_handle_ = nullptr;

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
class CheckFunctionTypesVisitor : public ObjectVisitor {
 public:
  explicit CheckFunctionTypesVisitor(Thread* thread)
      : classHandle_(Class::Handle(thread->zone())),
        funcHandle_(Function::Handle(thread->zone())),
        typeHandle_(AbstractType::Handle(thread->zone())) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsFunction()) {
      funcHandle_ ^= obj;
      classHandle_ ^= funcHandle_.Owner();
      // Verify that the result type of a function is canonical or a
      // TypeParameter.
      typeHandle_ ^= funcHandle_.result_type();
      ASSERT(typeHandle_.IsTypeParameter() || typeHandle_.IsCanonical());
      // Verify that the types in the function signature are all canonical or
      // a TypeParameter.
      const intptr_t num_parameters = funcHandle_.NumParameters();
      for (intptr_t i = 0; i < num_parameters; i++) {
        typeHandle_ = funcHandle_.ParameterTypeAt(i);
        ASSERT(typeHandle_.IsTypeParameter() || typeHandle_.IsCanonical());
      }
    }
  }

 private:
  Class& classHandle_;
  Function& funcHandle_;
  AbstractType& typeHandle_;
};
#endif  // #if defined(DEBUG).

static InstancePtr GetListInstance(Zone* zone, const Object& obj) {
  if (obj.IsInstance()) {
    ObjectStore* object_store = IsolateGroup::Current()->object_store();
    const Type& list_rare_type =
        Type::Handle(zone, object_store->non_nullable_list_rare_type());
    ASSERT(!list_rare_type.IsNull());
    const Instance& instance = Instance::Cast(obj);
    const Class& obj_class = Class::Handle(zone, obj.clazz());
    if (Class::IsSubtypeOf(obj_class, Object::null_type_arguments(),
                           Nullability::kNonNullable, list_rare_type,
                           Heap::kNew)) {
      return instance.ptr();
    }
  }
  return Instance::null();
}

static InstancePtr GetMapInstance(Zone* zone, const Object& obj) {
  if (obj.IsInstance()) {
    ObjectStore* object_store = IsolateGroup::Current()->object_store();
    const Type& map_rare_type =
        Type::Handle(zone, object_store->non_nullable_map_rare_type());
    ASSERT(!map_rare_type.IsNull());
    const Instance& instance = Instance::Cast(obj);
    const Class& obj_class = Class::Handle(zone, obj.clazz());
    if (Class::IsSubtypeOf(obj_class, Object::null_type_arguments(),
                           Nullability::kNonNullable, map_rare_type,
                           Heap::kNew)) {
      return instance.ptr();
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
  auto isolate_group = Thread::Current()->isolate_group();
  const Class& error_class = Class::Handle(
      zone, isolate_group->object_store()->compiletime_error_class());
  ASSERT(!error_class.IsNull());
  return (obj.GetClassId() == error_class.id());
#endif
}

static bool GetNativeStringArgument(NativeArguments* arguments,
                                    int arg_index,
                                    Dart_Handle* str,
                                    void** peer) {
  ASSERT(peer != nullptr);
  if (Api::StringGetPeerHelper(arguments, arg_index, peer)) {
    *str = nullptr;
    return true;
  }
  Thread* thread = arguments->thread();
  ASSERT(thread == Thread::Current());
  *peer = nullptr;
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& obj = thread->ObjectHandle();
  obj = arguments->NativeArgAt(arg_index);
  if (IsStringClassId(obj.GetClassId())) {
    ASSERT(thread->api_top_scope() != nullptr);
    *str = Api::NewHandle(thread, obj.ptr());
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
  ASSERT(value != nullptr);
  return Api::GetNativeIntegerArgument(arguments, arg_index, value);
}

static bool GetNativeUnsignedIntegerArgument(NativeArguments* arguments,
                                             int arg_index,
                                             uint64_t* value) {
  ASSERT(value != nullptr);
  int64_t arg_value = 0;
  if (Api::GetNativeIntegerArgument(arguments, arg_index, &arg_value)) {
    *value = static_cast<uint64_t>(arg_value);
    return true;
  }
  return false;
}

static bool GetNativeDoubleArgument(NativeArguments* arguments,
                                    int arg_index,
                                    double* value) {
  ASSERT(value != nullptr);
  return Api::GetNativeDoubleArgument(arguments, arg_index, value);
}

static Dart_Handle GetNativeFieldsOfArgument(NativeArguments* arguments,
                                             int arg_index,
                                             int num_fields,
                                             intptr_t* field_values,
                                             const char* current_func) {
  ASSERT(field_values != nullptr);
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

static FunctionPtr FindCoreLibPrivateFunction(Zone* zone, const String& name) {
  const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
  ASSERT(!core_lib.IsNull());
  const Function& function =
      Function::Handle(zone, core_lib.LookupFunctionAllowPrivate(name));
  ASSERT(!function.IsNull());
  return function.ptr();
}

static ObjectPtr CallStatic1Arg(Zone* zone,
                                const String& name,
                                const Instance& arg0) {
  const intptr_t kNumArgs = 1;
  const Function& function =
      Function::Handle(zone, FindCoreLibPrivateFunction(zone, name));
  const Array& args = Array::Handle(zone, Array::New(kNumArgs));
  args.SetAt(0, arg0);
  return DartEntry::InvokeFunction(function, args);
}

static ObjectPtr CallStatic2Args(Zone* zone,
                                 const String& name,
                                 const Instance& arg0,
                                 const Instance& arg1) {
  const intptr_t kNumArgs = 2;
  const Function& function =
      Function::Handle(zone, FindCoreLibPrivateFunction(zone, name));
  const Array& args = Array::Handle(zone, Array::New(kNumArgs));
  args.SetAt(0, arg0);
  args.SetAt(1, arg1);
  return DartEntry::InvokeFunction(function, args);
}

static ObjectPtr CallStatic3Args(Zone* zone,
                                 const String& name,
                                 const Instance& arg0,
                                 const Instance& arg1,
                                 const Instance& arg2) {
  const intptr_t kNumArgs = 3;
  const Function& function =
      Function::Handle(zone, FindCoreLibPrivateFunction(zone, name));
  const Array& args = Array::Handle(Array::New(kNumArgs));
  args.SetAt(0, arg0);
  args.SetAt(1, arg1);
  args.SetAt(2, arg2);
  return DartEntry::InvokeFunction(function, args);
}

static const char* GetErrorString(Thread* thread, const Object& obj) {
  // This function requires an API scope to be present.
  if (obj.IsError()) {
    ASSERT(thread->api_top_scope() != nullptr);
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

Dart_Handle Api::InitNewHandle(Thread* thread, ObjectPtr raw) {
  LocalHandles* local_handles = Api::TopScope(thread)->local_handles();
  ASSERT(local_handles != nullptr);
  LocalHandle* ref = local_handles->AllocateHandle();
  ref->set_ptr(raw);
  return ref->apiHandle();
}

Dart_Handle Api::NewHandle(Thread* thread, ObjectPtr raw) {
  if (raw == Object::null()) {
    return Null();
  }
  if (raw == Bool::True().ptr()) {
    return True();
  }
  if (raw == Bool::False().ptr()) {
    return False();
  }
  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  return InitNewHandle(thread, raw);
}

ObjectPtr Api::UnwrapHandle(Dart_Handle object) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  ASSERT(thread->IsDartMutatorThread());
  ASSERT(thread->isolate() != nullptr);
  ASSERT(FinalizablePersistentHandle::ptr_offset() == 0 &&
         PersistentHandle::ptr_offset() == 0 && LocalHandle::ptr_offset() == 0);
#endif
  return (reinterpret_cast<LocalHandle*>(object))->ptr();
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

Dart_IsolateGroup Api::CastIsolateGroup(IsolateGroup* isolate_group) {
  return reinterpret_cast<Dart_IsolateGroup>(isolate_group);
}

Dart_Handle Api::NewError(const char* format, ...) {
  Thread* T = Thread::Current();
  CHECK_API_SCOPE(T);
  CHECK_CALLBACK_STATE(T);
  // Ensure we transition safepoint state to VM if we are not already in
  // that state.
  TransitionToVM transition(T);
  HANDLESCOPE(T);

  va_list args;
  va_start(args, format);
  char* buffer = OS::VSCreate(Z, format, args);
  va_end(args);

  const String& message = String::Handle(Z, String::New(buffer));
  return Api::NewHandle(T, ApiError::New(message));
}

Dart_Handle Api::NewArgumentError(const char* format, ...) {
  Thread* T = Thread::Current();
  CHECK_API_SCOPE(T);
  CHECK_CALLBACK_STATE(T);
  // Ensure we transition safepoint state to VM if we are not already in
  // that state.
  TransitionToVM transition(T);
  HANDLESCOPE(T);

  va_list args;
  va_start(args, format);
  char* buffer = OS::VSCreate(Z, format, args);
  va_end(args);

  const String& message = String::Handle(Z, String::New(buffer));
  const Array& arguments = Array::Handle(Z, Array::New(1));
  arguments.SetAt(0, message);
  Object& error = Object::Handle(
      Z, DartLibraryCalls::InstanceCreate(
             Library::Handle(Z, Library::CoreLibrary()),
             Symbols::ArgumentError(), Symbols::Dot(), arguments));
  if (!error.IsError()) {
    error = UnhandledException::New(Instance::Cast(error), Instance::Handle());
  }
  return Api::NewHandle(T, error.ptr());
}

bool Api::IsValid(Dart_Handle handle) {
  Isolate* isolate = Isolate::Current();
  Thread* thread = Thread::Current();
  ASSERT(thread->IsDartMutatorThread());
  CHECK_ISOLATE(isolate);

  // Check against all of the handles in the current isolate as well as the
  // read-only handles.
  return thread->IsValidHandle(handle) ||
         isolate->group()->api_state()->IsActivePersistentHandle(
             reinterpret_cast<Dart_PersistentHandle>(handle)) ||
         isolate->group()->api_state()->IsActiveWeakPersistentHandle(
             reinterpret_cast<Dart_WeakPersistentHandle>(handle)) ||
         Dart::IsReadOnlyApiHandle(handle) ||
         Dart::IsReadOnlyHandle(reinterpret_cast<uword>(handle));
}

ApiLocalScope* Api::TopScope(Thread* thread) {
  ASSERT(thread != nullptr);
  ApiLocalScope* scope = thread->api_top_scope();
  ASSERT(scope != nullptr);
  return scope;
}

void Api::Init() {
  if (api_native_key_ == kUnsetThreadLocalKey) {
    api_native_key_ = OSThread::CreateThreadLocal();
  }
  ASSERT(api_native_key_ != kUnsetThreadLocalKey);
}

static Dart_Handle InitNewReadOnlyApiHandle(ObjectPtr raw) {
  ASSERT(raw->untag()->InVMIsolateHeap());
  LocalHandle* ref = Dart::AllocateReadOnlyApiHandle();
  ref->set_ptr(raw);
  return ref->apiHandle();
}

void Api::InitHandles() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != nullptr);
  ASSERT(isolate == Dart::vm_isolate());
  ApiState* state = isolate->group()->api_state();
  ASSERT(state != nullptr);

  ASSERT(true_handle_ == nullptr);
  true_handle_ = InitNewReadOnlyApiHandle(Bool::True().ptr());

  ASSERT(false_handle_ == nullptr);
  false_handle_ = InitNewReadOnlyApiHandle(Bool::False().ptr());

  ASSERT(null_handle_ == nullptr);
  null_handle_ = InitNewReadOnlyApiHandle(Object::null());

  ASSERT(empty_string_handle_ == nullptr);
  empty_string_handle_ = InitNewReadOnlyApiHandle(Symbols::Empty().ptr());

  ASSERT(no_callbacks_error_handle_ == nullptr);
  no_callbacks_error_handle_ =
      InitNewReadOnlyApiHandle(Object::no_callbacks_error().ptr());

  ASSERT(unwind_in_progress_error_handle_ == nullptr);
  unwind_in_progress_error_handle_ =
      InitNewReadOnlyApiHandle(Object::unwind_in_progress_error().ptr());
}

void Api::Cleanup() {
  true_handle_ = nullptr;
  false_handle_ = nullptr;
  null_handle_ = nullptr;
  empty_string_handle_ = nullptr;
  no_callbacks_error_handle_ = nullptr;
  unwind_in_progress_error_handle_ = nullptr;
}

bool Api::StringGetPeerHelper(NativeArguments* arguments,
                              int arg_index,
                              void** peer) {
  NoSafepointScope no_safepoint_scope;
  ObjectPtr raw_obj = arguments->NativeArgAt(arg_index);
  if (!raw_obj->IsHeapObject()) {
    return false;
  }
  intptr_t cid = raw_obj->GetClassId();
  if (cid == kExternalOneByteStringCid) {
    ExternalOneByteStringPtr raw_string =
        static_cast<ExternalOneByteStringPtr>(raw_obj);
    *peer = raw_string->untag()->peer_;
    return true;
  }
  if (cid == kOneByteStringCid || cid == kTwoByteStringCid) {
    auto isolate_group = arguments->thread()->isolate_group();
    *peer = isolate_group->heap()->GetPeer(raw_obj);
    return (*peer != nullptr);
  }
  if (cid == kExternalTwoByteStringCid) {
    ExternalTwoByteStringPtr raw_string =
        static_cast<ExternalTwoByteStringPtr>(raw_obj);
    *peer = raw_string->untag()->peer_;
    return true;
  }
  return false;
}

bool Api::GetNativeReceiver(NativeArguments* arguments, intptr_t* value) {
  NoSafepointScope no_safepoint_scope;
  ObjectPtr raw_obj = arguments->NativeArg0();
  if (raw_obj->IsHeapObject()) {
    intptr_t cid = raw_obj->GetClassId();
    if (cid >= kNumPredefinedCids) {
      ASSERT(Instance::Cast(Object::Handle(raw_obj)).IsValidNativeIndex(0));
      TypedDataPtr native_fields =
          reinterpret_cast<CompressedTypedDataPtr*>(
              UntaggedObject::ToAddr(raw_obj) + sizeof(UntaggedObject))
              ->Decompress(raw_obj->heap_base());
      if (native_fields == TypedData::null()) {
        *value = 0;
      } else {
        *value = *bit_cast<intptr_t*, uint8_t*>(native_fields->untag()->data());
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
  ObjectPtr raw_obj = arguments->NativeArgAt(arg_index);
  if (raw_obj->IsHeapObject()) {
    intptr_t cid = raw_obj->GetClassId();
    if (cid == kBoolCid) {
      *value = (raw_obj == Object::bool_true().ptr());
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
  ObjectPtr raw_obj = arguments->NativeArgAt(arg_index);
  if (raw_obj->IsHeapObject()) {
    intptr_t cid = raw_obj->GetClassId();
    if (cid == kMintCid) {
      *value = static_cast<MintPtr>(raw_obj)->untag()->value_;
      return true;
    }
    return false;
  }
  *value = Smi::Value(static_cast<SmiPtr>(raw_obj));
  return true;
}

bool Api::GetNativeDoubleArgument(NativeArguments* arguments,
                                  int arg_index,
                                  double* value) {
  NoSafepointScope no_safepoint_scope;
  ObjectPtr raw_obj = arguments->NativeArgAt(arg_index);
  if (raw_obj->IsHeapObject()) {
    intptr_t cid = raw_obj->GetClassId();
    if (cid == kDoubleCid) {
      *value = static_cast<DoublePtr>(raw_obj)->untag()->value_;
      return true;
    }
    if (cid == kMintCid) {
      *value =
          static_cast<double>(static_cast<MintPtr>(raw_obj)->untag()->value_);
      return true;
    }
    return false;
  }
  *value = static_cast<double>(Smi::Value(static_cast<SmiPtr>(raw_obj)));
  return true;
}

bool Api::GetNativeFieldsOfArgument(NativeArguments* arguments,
                                    int arg_index,
                                    int num_fields,
                                    intptr_t* field_values) {
  NoSafepointScope no_safepoint_scope;
  ObjectPtr raw_obj = arguments->NativeArgAt(arg_index);
  intptr_t cid = raw_obj->GetClassIdMayBeSmi();
  int class_num_fields = arguments->thread()
                             ->isolate_group()
                             ->class_table()
                             ->At(cid)
                             ->untag()
                             ->num_native_fields_;
  if (num_fields != class_num_fields) {
    // No native fields or mismatched native field count.
    return false;
  }
  TypedDataPtr native_fields =
      reinterpret_cast<CompressedTypedDataPtr*>(
          UntaggedObject::ToAddr(raw_obj) + sizeof(UntaggedObject))
          ->Decompress(raw_obj->heap_base());
  if (native_fields == TypedData::null()) {
    // Native fields not initialized.
    memset(field_values, 0, (num_fields * sizeof(field_values[0])));
    return true;
  }
  ASSERT(class_num_fields == Smi::Value(native_fields->untag()->length()));
  intptr_t* native_values =
      reinterpret_cast<intptr_t*>(native_fields->untag()->data());
  memmove(field_values, native_values, (num_fields * sizeof(field_values[0])));
  return true;
}

void Api::SetWeakHandleReturnValue(NativeArguments* args,
                                   Dart_WeakPersistentHandle retval) {
  args->SetReturnUnsafe(FinalizablePersistentHandle::Cast(retval)->ptr());
}

PersistentHandle* PersistentHandle::Cast(Dart_PersistentHandle handle) {
  ASSERT(IsolateGroup::Current()->api_state()->IsValidPersistentHandle(handle));
  return reinterpret_cast<PersistentHandle*>(handle);
}

FinalizablePersistentHandle* FinalizablePersistentHandle::Cast(
    Dart_WeakPersistentHandle handle) {
#if defined(DEBUG)
  ApiState* state = IsolateGroup::Current()->api_state();
  ASSERT(state->IsValidWeakPersistentHandle(handle));
#endif
  return reinterpret_cast<FinalizablePersistentHandle*>(handle);
}
FinalizablePersistentHandle* FinalizablePersistentHandle::Cast(
    Dart_FinalizableHandle handle) {
#if defined(DEBUG)
  ApiState* state = IsolateGroup::Current()->api_state();
  ASSERT(state->IsValidFinalizableHandle(handle));
#endif
  return reinterpret_cast<FinalizablePersistentHandle*>(handle);
}

void FinalizablePersistentHandle::Finalize(
    IsolateGroup* isolate_group,
    FinalizablePersistentHandle* handle) {
  if (!handle->ptr()->IsHeapObject()) {
    return;  // Free handle.
  }
  Dart_HandleFinalizer callback = handle->callback();
  ASSERT(callback != nullptr);
  void* peer = handle->peer();
  ApiState* state = isolate_group->api_state();
  ASSERT(state != nullptr);

  if (!handle->auto_delete()) {
    // Clear handle before running finalizer, finalizer can free the handle.
    state->ClearWeakPersistentHandle(handle);
  }

  (*callback)(isolate_group->embedder_data(), peer);

  if (handle->auto_delete()) {
    state->FreeWeakPersistentHandle(handle);
  }
}

// --- Handles ---

DART_EXPORT bool Dart_IsError(Dart_Handle handle) {
  Thread* thread = Thread::Current();
  TransitionNativeToVM transition(thread);
  return Api::IsError(handle);
}

DART_EXPORT void Dart_KillIsolate(Dart_Isolate handle) {
  Isolate* isolate = reinterpret_cast<Isolate*>(handle);
  CHECK_ISOLATE(isolate);
  Isolate::KillIfExists(isolate, Isolate::kKillMsg);
}

DART_EXPORT bool Dart_IsApiError(Dart_Handle object) {
  Thread* thread = Thread::Current();
  TransitionNativeToVM transition(thread);
  return Api::ClassId(object) == kApiErrorCid;
}

DART_EXPORT bool Dart_IsUnhandledExceptionError(Dart_Handle object) {
  Thread* thread = Thread::Current();
  TransitionNativeToVM transition(thread);
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

  Thread* thread = Thread::Current();
  TransitionNativeToVM transition(thread);
  return Api::ClassId(object) == kLanguageErrorCid;
}

DART_EXPORT bool Dart_IsFatalError(Dart_Handle object) {
  Thread* thread = Thread::Current();
  TransitionNativeToVM transition(thread);
  return Api::ClassId(object) == kUnwindErrorCid;
}

DART_EXPORT const char* Dart_GetError(Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
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

DART_EXPORT Dart_Handle Dart_NewApiError(const char* error) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  const String& message = String::Handle(Z, String::New(error));
  return Api::NewHandle(T, ApiError::New(message));
}

DART_EXPORT Dart_Handle Dart_NewCompilationError(const char* error) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);

  const String& message = String::Handle(Z, String::New(error));
  return Api::NewHandle(T, LanguageError::New(message));
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
    obj = Api::UnwrapInstanceHandle(Z, exception).ptr();
    if (obj.IsNull()) {
      RETURN_TYPE_ERROR(Z, exception, Instance);
    }
  }
  const StackTrace& stacktrace = StackTrace::Handle(Z);
  return Api::NewHandle(T, UnhandledException::New(obj, stacktrace));
}

DART_EXPORT void Dart_PropagateError(Dart_Handle handle) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  const Object& obj = Object::Handle(thread->zone(), Api::UnwrapHandle(handle));
  if (!obj.IsError()) {
    FATAL(
        "%s expects argument 'handle' to be an error handle.  "
        "Did you forget to check Dart_IsError first?",
        CURRENT_FUNC);
  }
  if (thread->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // propagate an error here.
    FATAL("No Dart frames on stack, cannot propagate error.");
  }
  // Unwind all the API scopes till the exit frame before propagating.
  const Error* error;
  {
    // We need to preserve the error object across the destruction of zones
    // when the ApiScopes are unwound.  By using NoSafepointScope, we can ensure
    // that GC won't touch the raw error object before creating a valid
    // handle for it in the surviving zone.
    NoSafepointScope no_safepoint;
    ErrorPtr raw_error = Api::UnwrapErrorHandle(thread->zone(), handle).ptr();
    thread->UnwindScopes(thread->top_exit_frame_info());
    // Note that thread's zone is different here than at the beginning of this
    // function.
    error = &Error::Handle(thread->zone(), raw_error);
  }
  Exceptions::PropagateError(*error);
  UNREACHABLE();
}

DART_EXPORT Dart_Handle Dart_ToString(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  if (obj.IsString()) {
    return Api::NewHandle(T, obj.ptr());
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
  ApiState* state = isolate->group()->api_state();
  ASSERT(state != nullptr);
  TransitionNativeToVM transition(thread);
  NoSafepointScope no_safepoint_scope;
  PersistentHandle* ref = PersistentHandle::Cast(object);
  return Api::NewHandle(thread, ref->ptr());
}

DART_EXPORT Dart_Handle
Dart_HandleFromWeakPersistent(Dart_WeakPersistentHandle object) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->group()->api_state();
  ASSERT(state != nullptr);
  TransitionNativeToVM transition(thread);
  NoSafepointScope no_safepoint_scope;
  FinalizablePersistentHandle* weak_ref =
      FinalizablePersistentHandle::Cast(object);
  if (weak_ref->IsFinalizedNotFreed()) {
    return Dart_Null();
  }
  return Api::NewHandle(thread, weak_ref->ptr());
}

static Dart_Handle HandleFromFinalizable(Dart_FinalizableHandle object) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  ApiState* state = isolate->group()->api_state();
  ASSERT(state != nullptr);
  TransitionNativeToVM transition(thread);
  NoSafepointScope no_safepoint_scope;
  FinalizablePersistentHandle* weak_ref =
      FinalizablePersistentHandle::Cast(object);
  return Api::NewHandle(thread, weak_ref->ptr());
}

DART_EXPORT Dart_PersistentHandle Dart_NewPersistentHandle(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  ApiState* state = I->group()->api_state();
  ASSERT(state != nullptr);
  const Object& old_ref = Object::Handle(Z, Api::UnwrapHandle(object));
  PersistentHandle* new_ref = state->AllocatePersistentHandle();
  new_ref->set_ptr(old_ref);
  return new_ref->apiHandle();
}

DART_EXPORT void Dart_SetPersistentHandle(Dart_PersistentHandle obj1,
                                          Dart_Handle obj2) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  ApiState* state = I->group()->api_state();
  ASSERT(state != nullptr);
  ASSERT(state->IsValidPersistentHandle(obj1));
  const Object& obj2_ref = Object::Handle(Z, Api::UnwrapHandle(obj2));
  PersistentHandle* obj1_ref = PersistentHandle::Cast(obj1);
  obj1_ref->set_ptr(obj2_ref);
}

static bool IsFfiCompound(Thread* T, const Object& obj) {
  if (obj.IsNull()) {
    return false;
  }

  // CFE guarantees we can only have direct subclasses of `Struct` and `Union`
  // (no implementations or indirect subclasses are allowed).
  const auto& klass = Class::Handle(Z, obj.clazz());
  const auto& super_klass = Class::Handle(Z, klass.SuperClass());
  if (super_klass.IsNull()) {
    // This means klass is Object.
    return false;
  }
  if (super_klass.Name() != Symbols::Struct().ptr() &&
      super_klass.Name() != Symbols::Union().ptr()) {
    return false;
  }
  const auto& library = Library::Handle(Z, super_klass.library());
  return library.url() == Symbols::DartFfi().ptr();
}

static Dart_WeakPersistentHandle AllocateWeakPersistentHandle(
    Thread* thread,
    const Object& ref,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback) {
  if (!ref.ptr()->IsHeapObject()) {
    return nullptr;
  }
  if (ref.IsPointer()) {
    return nullptr;
  }
  if (IsFfiCompound(thread, ref)) {
    return nullptr;
  }

  FinalizablePersistentHandle* finalizable_ref =
      FinalizablePersistentHandle::New(thread->isolate_group(), ref, peer,
                                       callback, external_allocation_size,
                                       /*auto_delete=*/false);
  return finalizable_ref == nullptr
             ? nullptr
             : finalizable_ref->ApiWeakPersistentHandle();
}

static Dart_WeakPersistentHandle AllocateWeakPersistentHandle(
    Thread* T,
    Dart_Handle object,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback) {
  const auto& ref = Object::Handle(Z, Api::UnwrapHandle(object));
  return AllocateWeakPersistentHandle(T, ref, peer, external_allocation_size,
                                      callback);
}

static Dart_FinalizableHandle AllocateFinalizableHandle(
    Thread* thread,
    const Object& ref,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback) {
  if (!ref.ptr()->IsHeapObject()) {
    return nullptr;
  }
  if (ref.IsPointer()) {
    return nullptr;
  }
  if (IsFfiCompound(thread, ref)) {
    return nullptr;
  }

  FinalizablePersistentHandle* finalizable_ref =
      FinalizablePersistentHandle::New(thread->isolate_group(), ref, peer,
                                       callback, external_allocation_size,
                                       /*auto_delete=*/true);
  return finalizable_ref == nullptr ? nullptr
                                    : finalizable_ref->ApiFinalizableHandle();
}

static Dart_FinalizableHandle AllocateFinalizableHandle(
    Thread* T,
    Dart_Handle object,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback) {
  const auto& ref = Object::Handle(Z, Api::UnwrapHandle(object));
  return AllocateFinalizableHandle(T, ref, peer, external_allocation_size,
                                   callback);
}

DART_EXPORT Dart_WeakPersistentHandle
Dart_NewWeakPersistentHandle(Dart_Handle object,
                             void* peer,
                             intptr_t external_allocation_size,
                             Dart_HandleFinalizer callback) {
  DARTSCOPE(Thread::Current());
  if (callback == nullptr) {
    return nullptr;
  }

  return AllocateWeakPersistentHandle(T, object, peer, external_allocation_size,
                                      callback);
}

DART_EXPORT Dart_FinalizableHandle
Dart_NewFinalizableHandle(Dart_Handle object,
                          void* peer,
                          intptr_t external_allocation_size,
                          Dart_HandleFinalizer callback) {
  DARTSCOPE(Thread::Current());
  if (callback == nullptr) {
    return nullptr;
  }

  return AllocateFinalizableHandle(T, object, peer, external_allocation_size,
                                   callback);
}

DART_EXPORT void Dart_DeletePersistentHandle(Dart_PersistentHandle object) {
  Thread* T = Thread::Current();
  IsolateGroup* isolate_group = T->isolate_group();
  CHECK_ISOLATE_GROUP(isolate_group);
  TransitionToVM transition(T);
  ApiState* state = isolate_group->api_state();
  ASSERT(state != nullptr);
  ASSERT(state->IsActivePersistentHandle(object));
  ASSERT(!Api::IsProtectedHandle(object));
  if (!Api::IsProtectedHandle(object)) {
    PersistentHandle* ref = PersistentHandle::Cast(object);
    state->FreePersistentHandle(ref);
  }
}

DART_EXPORT void Dart_DeleteWeakPersistentHandle(
    Dart_WeakPersistentHandle object) {
  Thread* T = Thread::Current();
  IsolateGroup* isolate_group = T->isolate_group();
  CHECK_ISOLATE_GROUP(isolate_group);
  TransitionToVM transition(T);
  ApiState* state = isolate_group->api_state();
  ASSERT(state != nullptr);
  ASSERT(state->IsActiveWeakPersistentHandle(object));
  auto weak_ref = FinalizablePersistentHandle::Cast(object);
  weak_ref->EnsureFreedExternal(isolate_group);
  state->FreeWeakPersistentHandle(weak_ref);
}

DART_EXPORT void Dart_DeleteFinalizableHandle(
    Dart_FinalizableHandle object,
    Dart_Handle strong_ref_to_object) {
  if (!::Dart_IdentityEquals(strong_ref_to_object,
                             HandleFromFinalizable(object))) {
    FATAL(
        "%s expects arguments 'object' and 'strong_ref_to_object' to point to "
        "the same object.",
        CURRENT_FUNC);
  }

  auto wph_object = reinterpret_cast<Dart_WeakPersistentHandle>(object);

  ::Dart_DeleteWeakPersistentHandle(wph_object);
}

// --- Initialization and Globals ---

DART_EXPORT const char* Dart_VersionString() {
  return Version::String();
}

DART_EXPORT char* Dart_Initialize(Dart_InitializeParams* params) {
  if (params == nullptr) {
    return Utils::StrDup(
        "Dart_Initialize: "
        "Dart_InitializeParams is null.");
  }

  if (params->version != DART_INITIALIZE_PARAMS_CURRENT_VERSION) {
    return Utils::StrDup(
        "Dart_Initialize: "
        "Invalid Dart_InitializeParams version.");
  }

  return Dart::Init(params);
}

DART_EXPORT char* Dart_Cleanup() {
  CHECK_NO_ISOLATE(Isolate::Current());
  return Dart::Cleanup();
}

DART_EXPORT char* Dart_SetVMFlags(int argc, const char** argv) {
  return Flags::ProcessCommandLineFlags(argc, argv);
}

DART_EXPORT bool Dart_IsVMFlagSet(const char* flag_name) {
  return Flags::IsSet(flag_name);
}

#define ISOLATE_GROUP_METRIC_API(type, variable, name, unit)                   \
  DART_EXPORT int64_t Dart_IsolateGroup##variable##Metric(                     \
      Dart_IsolateGroup isolate_group) {                                       \
    if (isolate_group == nullptr) {                                            \
      FATAL("%s expects argument 'isolate_group' to be non-null.",             \
            CURRENT_FUNC);                                                     \
    }                                                                          \
    IsolateGroup* group = reinterpret_cast<IsolateGroup*>(isolate_group);      \
    return group->Get##variable##Metric()->Value();                            \
  }
DART_API_ISOLATE_GROUP_METRIC_LIST(ISOLATE_GROUP_METRIC_API)
#undef ISOLATE_GROUP_METRIC_API

#if !defined(PRODUCT)
#define ISOLATE_METRIC_API(type, variable, name, unit)                         \
  DART_EXPORT int64_t Dart_Isolate##variable##Metric(Dart_Isolate isolate) {   \
    if (isolate == nullptr) {                                                  \
      FATAL("%s expects argument 'isolate' to be non-null.", CURRENT_FUNC);    \
    }                                                                          \
    Isolate* iso = reinterpret_cast<Isolate*>(isolate);                        \
    return iso->Get##variable##Metric()->Value();                              \
  }
ISOLATE_METRIC_LIST(ISOLATE_METRIC_API)
#undef ISOLATE_METRIC_API
#else  // !defined(PRODUCT)
#define ISOLATE_METRIC_API(type, variable, name, unit)                         \
  DART_EXPORT int64_t Dart_Isolate##variable##Metric(Dart_Isolate isolate) {   \
    return -1;                                                                 \
  }
ISOLATE_METRIC_LIST(ISOLATE_METRIC_API)
#undef ISOLATE_METRIC_API
#endif  // !defined(PRODUCT)

// --- Isolates ---

static Dart_Isolate CreateIsolate(IsolateGroup* group,
                                  bool is_new_group,
                                  const char* name,
                                  void* isolate_data,
                                  char** error) {
  CHECK_NO_ISOLATE(Isolate::Current());

  auto source = group->source();
  Isolate* I = Dart::CreateIsolate(name, source->flags, group);
  if (I == nullptr) {
    if (error != nullptr) {
      *error = Utils::StrDup("Isolate creation failed");
    }
    return static_cast<Dart_Isolate>(nullptr);
  }

  Thread* T = Thread::Current();
  bool success = false;
  {
    StackZone zone(T);
    HandleScope handle_scope(T);

#if defined(SUPPORT_TIMELINE)
    TimelineBeginEndScope tbes(T, Timeline::GetIsolateStream(),
                               "InitializeIsolate");
    tbes.SetNumArguments(1);
    tbes.CopyArgument(0, "isolateName", I->name());
#endif

    // We enter an API scope here as InitializeIsolate could compile some
    // bootstrap library files which call out to a tag handler that may create
    // Api Handles when an error is encountered.
    T->EnterApiScope();
    auto& error_obj = Error::Handle(Z);
    if (is_new_group) {
      error_obj = Dart::InitializeIsolateGroup(
          T, source->snapshot_data, source->snapshot_instructions,
          source->kernel_buffer, source->kernel_buffer_size);
    }
    if (error_obj.IsNull()) {
      error_obj = Dart::InitializeIsolate(T, is_new_group, isolate_data);
    }
    if (error_obj.IsNull()) {
#if defined(DEBUG) && !defined(DART_PRECOMPILED_RUNTIME)
      if (FLAG_check_function_fingerprints && !FLAG_precompiled_mode) {
        Library::CheckFunctionFingerprints();
      }
#endif  // defined(DEBUG) && !defined(DART_PRECOMPILED_RUNTIME).
      success = true;
    } else if (error != nullptr) {
      *error = Utils::StrDup(error_obj.ToErrorCString());
    }
    // We exit the API scope entered above.
    T->ExitApiScope();
  }

  if (success) {
    // A Thread structure has been associated to the thread, we do the
    // safepoint transition explicitly here instead of using the
    // TransitionXXX scope objects as the reverse transition happens
    // outside this scope in Dart_ShutdownIsolate/Dart_ExitIsolate.
    T->set_execution_state(Thread::kThreadInNative);
    T->EnterSafepoint();
    if (error != nullptr) {
      *error = nullptr;
    }
    return Api::CastIsolate(I);
  }

  Dart::ShutdownIsolate(T);
  return static_cast<Dart_Isolate>(nullptr);
}

static bool IsServiceOrKernelIsolateName(const char* name) {
  if (ServiceIsolate::NameEquals(name)) {
    ASSERT(!ServiceIsolate::Exists());
    return true;
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (KernelIsolate::NameEquals(name)) {
    ASSERT(!KernelIsolate::Exists());
    return true;
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  return false;
}

Isolate* CreateWithinExistingIsolateGroup(IsolateGroup* group,
                                          const char* name,
                                          char** error) {
  API_TIMELINE_DURATION(Thread::Current());
  CHECK_NO_ISOLATE(Isolate::Current());

  auto spawning_group = group;

  Isolate* isolate = reinterpret_cast<Isolate*>(
      CreateIsolate(spawning_group, /*is_new_group=*/false, name,
                    /*isolate_data=*/nullptr, error));
  if (isolate == nullptr) return nullptr;

  auto source = spawning_group->source();
  ASSERT(isolate->source() == source);

  return isolate;
}

DART_EXPORT void Dart_IsolateFlagsInitialize(Dart_IsolateFlags* flags) {
  Isolate::FlagsInitialize(flags);
}

DART_EXPORT Dart_Isolate
Dart_CreateIsolateGroup(const char* script_uri,
                        const char* name,
                        const uint8_t* snapshot_data,
                        const uint8_t* snapshot_instructions,
                        Dart_IsolateFlags* flags,
                        void* isolate_group_data,
                        void* isolate_data,
                        char** error) {
  API_TIMELINE_DURATION(Thread::Current());

  Dart_IsolateFlags api_flags;
  if (flags == nullptr) {
    Isolate::FlagsInitialize(&api_flags);
    flags = &api_flags;
  }

  const char* non_null_name = name == nullptr ? "isolate" : name;
  std::unique_ptr<IsolateGroupSource> source(
      new IsolateGroupSource(script_uri, non_null_name, snapshot_data,
                             snapshot_instructions, nullptr, -1, *flags));
  auto group = new IsolateGroup(std::move(source), isolate_group_data, *flags);
  group->CreateHeap(
      /*is_vm_isolate=*/false, IsServiceOrKernelIsolateName(non_null_name));
  IsolateGroup::RegisterIsolateGroup(group);
  Dart_Isolate isolate = CreateIsolate(group, /*is_new_group=*/true,
                                       non_null_name, isolate_data, error);
  if (isolate != nullptr) {
    group->set_initial_spawn_successful();
  }
  return isolate;
}

DART_EXPORT Dart_Isolate
Dart_CreateIsolateGroupFromKernel(const char* script_uri,
                                  const char* name,
                                  const uint8_t* kernel_buffer,
                                  intptr_t kernel_buffer_size,
                                  Dart_IsolateFlags* flags,
                                  void* isolate_group_data,
                                  void* isolate_data,
                                  char** error) {
  API_TIMELINE_DURATION(Thread::Current());

  Dart_IsolateFlags api_flags;
  if (flags == nullptr) {
    Isolate::FlagsInitialize(&api_flags);
    flags = &api_flags;
  }

  const char* non_null_name = name == nullptr ? "isolate" : name;
  std::shared_ptr<IsolateGroupSource> source(
      new IsolateGroupSource(script_uri, non_null_name, nullptr, nullptr,
                             kernel_buffer, kernel_buffer_size, *flags));
  auto group = new IsolateGroup(source, isolate_group_data, *flags);
  IsolateGroup::RegisterIsolateGroup(group);
  group->CreateHeap(
      /*is_vm_isolate=*/false, IsServiceOrKernelIsolateName(non_null_name));
  Dart_Isolate isolate = CreateIsolate(group, /*is_new_group=*/true,
                                       non_null_name, isolate_data, error);
  if (isolate != nullptr) {
    group->set_initial_spawn_successful();
  }
  return isolate;
}

DART_EXPORT Dart_Isolate
Dart_CreateIsolateInGroup(Dart_Isolate group_member,
                          const char* name,
                          Dart_IsolateShutdownCallback shutdown_callback,
                          Dart_IsolateCleanupCallback cleanup_callback,
                          void* child_isolate_data,
                          char** error) {
  CHECK_NO_ISOLATE(Isolate::Current());
  auto member = reinterpret_cast<Isolate*>(group_member);
  if (member->IsScheduled()) {
    FATAL("The given member isolate (%s) must not have been entered.",
          member->name());
  }

  *error = nullptr;

  Isolate* isolate;
  isolate = CreateWithinExistingIsolateGroup(member->group(), name, error);
  if (isolate != nullptr) {
    isolate->set_origin_id(member->origin_id());
    isolate->set_init_callback_data(child_isolate_data);
    isolate->set_on_shutdown_callback(shutdown_callback);
    isolate->set_on_cleanup_callback(cleanup_callback);
  }

  return Api::CastIsolate(isolate);
}

DART_EXPORT void Dart_ShutdownIsolate() {
  Thread* T = Thread::Current();
  auto I = T->isolate();
  CHECK_ISOLATE(I);

  // The Thread structure is disassociated from the isolate, we do the
  // safepoint transition explicitly here instead of using the TransitionXXX
  // scope objects as the original transition happened outside this scope in
  // Dart_EnterIsolate/Dart_CreateIsolateGroup.
  ASSERT(T->execution_state() == Thread::kThreadInNative);
  T->ExitSafepoint();
  T->set_execution_state(Thread::kThreadInVM);

  I->WaitForOutstandingSpawns();

  // Release any remaining API scopes.
  ApiLocalScope* scope = T->api_top_scope();
  while (scope != nullptr) {
    ApiLocalScope* previous = scope->previous();
    delete scope;
    scope = previous;
  }
  T->set_api_top_scope(nullptr);

  {
    StackZone zone(T);
    HandleScope handle_scope(T);
    Dart::RunShutdownCallback();
  }
  Dart::ShutdownIsolate(T);
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
  if (isolate == nullptr) {
    FATAL("%s expects argument 'isolate' to be non-null.", CURRENT_FUNC);
  }
  // TODO(http://dartbug.com/16615): Validate isolate parameter.
  return reinterpret_cast<Isolate*>(isolate)->init_callback_data();
}

DART_EXPORT Dart_IsolateGroup Dart_CurrentIsolateGroup() {
  return Api::CastIsolateGroup(IsolateGroup::Current());
}

DART_EXPORT void* Dart_CurrentIsolateGroupData() {
  IsolateGroup* isolate_group = IsolateGroup::Current();
  CHECK_ISOLATE_GROUP(isolate_group);
  NoSafepointScope no_safepoint_scope;
  return isolate_group->embedder_data();
}

DART_EXPORT Dart_IsolateGroupId Dart_CurrentIsolateGroupId() {
  IsolateGroup* isolate_group = IsolateGroup::Current();
  CHECK_ISOLATE_GROUP(isolate_group);
  return isolate_group->id();
}

DART_EXPORT void* Dart_IsolateGroupData(Dart_Isolate isolate) {
  if (isolate == nullptr) {
    FATAL("%s expects argument 'isolate' to be non-null.", CURRENT_FUNC);
  }
  // TODO(http://dartbug.com/16615): Validate isolate parameter.
  return reinterpret_cast<Isolate*>(isolate)->group()->embedder_data();
}

DART_EXPORT Dart_Handle Dart_DebugName() {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  return Api::NewHandle(
      T, String::NewFormatted("(%" Pd64 ") '%s'",
                              static_cast<int64_t>(I->main_port()), I->name()));
}

DART_EXPORT const char* Dart_DebugNameToCString() {
  Thread* thread = Thread::Current();
  if (thread == nullptr) {
    return nullptr;
  }
  Isolate* I = thread->isolate();
  if (I == nullptr) {
    return nullptr;
  }
  int64_t main_port = static_cast<int64_t>(I->main_port());
  const char* fmt = "%s (%" Pd64 ")";
  int length = snprintf(nullptr, 0, fmt, I->name(), main_port) + 1;
  char* res = Api::TopScope(thread)->zone()->Alloc<char>(length);
  snprintf(res, length, fmt, I->name(), main_port);
  return res;
}

DART_EXPORT const char* Dart_IsolateServiceId(Dart_Isolate isolate) {
  if (isolate == nullptr) {
    FATAL("%s expects argument 'isolate' to be non-null.", CURRENT_FUNC);
  }
  // TODO(http://dartbug.com/16615): Validate isolate parameter.
  Isolate* I = reinterpret_cast<Isolate*>(isolate);
  int64_t main_port = static_cast<int64_t>(I->main_port());
  return OS::SCreate(nullptr, "isolates/%" Pd64, main_port);
}

DART_EXPORT void Dart_EnterIsolate(Dart_Isolate isolate) {
  CHECK_NO_ISOLATE(Isolate::Current());
  // TODO(http://dartbug.com/16615): Validate isolate parameter.
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  if (iso->IsScheduled()) {
    FATAL(
        "Isolate %s is already scheduled on mutator thread %p, "
        "failed to schedule from os thread 0x%" Px "\n",
        iso->name(), iso->scheduled_mutator_thread(),
        OSThread::ThreadIdToIntPtr(OSThread::GetCurrentThreadId()));
  }
  Thread::EnterIsolate(iso);
  // A Thread structure has been associated to the thread, we do the
  // safepoint transition explicitly here instead of using the
  // TransitionXXX scope objects as the reverse transition happens
  // outside this scope in Dart_ExitIsolate/Dart_ShutdownIsolate.
  Thread* T = Thread::Current();
  T->set_execution_state(Thread::kThreadInNative);
  T->EnterSafepoint();
}

DART_EXPORT void Dart_StartProfiling() {
#if !defined(PRODUCT)
  if (!FLAG_profiler) {
    FLAG_profiler = true;
    Profiler::Init();
  }
#endif  // !defined(PRODUCT)
}

DART_EXPORT void Dart_StopProfiling() {
#if !defined(PRODUCT)
  if (FLAG_profiler) {
    Profiler::Cleanup();
    FLAG_profiler = false;
  }
#endif  // !defined(PRODUCT)
}

DART_EXPORT void Dart_ThreadDisableProfiling() {
  OSThread* os_thread = OSThread::Current();
  if (os_thread == nullptr) {
    return;
  }
  os_thread->DisableThreadInterrupts();
}

DART_EXPORT void Dart_ThreadEnableProfiling() {
  OSThread* os_thread = OSThread::Current();
  if (os_thread == nullptr) {
    return;
  }
  os_thread->EnableThreadInterrupts();
}

DART_EXPORT void Dart_AddSymbols(const char* dso_name,
                                 void* buffer,
                                 intptr_t buffer_size) {
  NativeSymbolResolver::AddSymbols(dso_name, buffer, buffer_size);
}

DART_EXPORT bool Dart_WriteProfileToTimeline(Dart_Port main_port,
                                             char** error) {
#if defined(PRODUCT)
  return false;
#else
  if (!FLAG_profiler) {
    if (error != nullptr) {
      *error = Utils::StrDup("The profiler is not running.");
    }
    return false;
  }

  const intptr_t kBufferLength = 512;
  char method[kBufferLength];

  // clang-format off
  intptr_t method_length = snprintf(method, kBufferLength, "{"
      "\"jsonrpc\": \"2.0\","
      "\"method\": \"_writeCpuProfileTimeline\","
      "\"id\": \"\","
      "\"params\": {"
      "  \"isolateId\": \"isolates/%" Pd64 "\","
      "  \"tags\": \"None\""
      "}"
  "}", main_port);
  // clang-format on
  ASSERT(method_length <= kBufferLength);

  char* response = nullptr;
  intptr_t response_length;
  bool success = Dart_InvokeVMServiceMethod(
      reinterpret_cast<uint8_t*>(method), method_length,
      reinterpret_cast<uint8_t**>(&response), &response_length, error);
  free(response);
  return success;
#endif
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
    FATAL("%s(true) is not supported in a PRODUCT build", CURRENT_FUNC);
  }
#else
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  NoSafepointScope no_safepoint_scope;
  if (isolate->is_runnable()) {
    FATAL("%s expects the current isolate to not be runnable yet.",
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
    FATAL("%s(true) is not supported in a PRODUCT build", CURRENT_FUNC);
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
    FATAL("%s(true) is not supported in a PRODUCT build", CURRENT_FUNC);
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
    FATAL("%s(true) is not supported in a PRODUCT build", CURRENT_FUNC);
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
  const Error& error_handle = Api::UnwrapErrorHandle(Z, error);
  if ((isolate->sticky_error() != Error::null()) &&
      (error_handle.ptr() != Object::null())) {
    FATAL("%s expects there to be no sticky error.", CURRENT_FUNC);
  }
  if (!error_handle.IsUnhandledException() &&
      (error_handle.ptr() != Object::null())) {
    FATAL("%s expects the error to be an unhandled exception error or null.",
          CURRENT_FUNC);
  }
  isolate->SetStickyError(error_handle.ptr());
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
  {
    NoSafepointScope no_safepoint_scope;
    if (I->sticky_error() == Error::null()) {
      return Api::Null();
    }
  }
  TransitionNativeToVM transition(T);
  return Api::NewHandle(T, I->sticky_error());
}

DART_EXPORT void Dart_NotifyIdle(int64_t deadline) {
  Thread* T = Thread::Current();
  CHECK_ISOLATE(T->isolate());
  API_TIMELINE_BEGIN_END(T);
  TransitionNativeToVM transition(T);
  T->isolate()->group()->idle_time_handler()->NotifyIdle(deadline);
}

DART_EXPORT void Dart_NotifyDestroyed() {
  Thread* T = Thread::Current();
  CHECK_ISOLATE(T->isolate());
  API_TIMELINE_BEGIN_END(T);
  TransitionNativeToVM transition(T);
  T->heap()->NotifyDestroyed();
}

DART_EXPORT void Dart_EnableHeapSampling() {
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  HeapProfileSampler::Enable(true);
#endif
}

DART_EXPORT void Dart_DisableHeapSampling() {
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  HeapProfileSampler::Enable(false);
#endif
}

DART_EXPORT void Dart_RegisterHeapSamplingCallback(
    Dart_HeapSamplingCreateCallback create_callback,
    Dart_HeapSamplingDeleteCallback delete_callback) {
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  HeapProfileSampler::SetSamplingCallback(create_callback, delete_callback);
#endif
}

DART_EXPORT void Dart_ReportSurvivingAllocations(
    Dart_HeapSamplingReportCallback callback,
    void* context,
    bool force_gc) {
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  CHECK_NO_ISOLATE(Thread::Current());
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    Thread::EnterIsolateGroupAsHelper(group, Thread::kUnknownTask,
                                      /*bypass_safepoint=*/false);
    if (force_gc) {
      group->heap()->CollectAllGarbage(GCReason::kDebugging);
    }
    group->heap()->ReportSurvivingAllocations(callback, context);
    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/false);
  });
#endif
}

DART_EXPORT void Dart_SetHeapSamplingPeriod(intptr_t bytes) {
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  HeapProfileSampler::SetSamplingInterval(bytes);
#endif
}

DART_EXPORT void Dart_NotifyLowMemory() {
  API_TIMELINE_BEGIN_END(Thread::Current());
  Page::ClearCache();
  Zone::ClearCache();

  // For each isolate's global variables, we might also clear:
  //  - RegExp backtracking stack (both bytecode and compiled versions)
  //  - String -> RegExp cache
  //  - BigInt division/remainder cache
  //  - double.toString cache
  // But cache invalidation code might be larger than the expected size of some
  // caches.
}

DART_EXPORT Dart_PerformanceMode
Dart_SetPerformanceMode(Dart_PerformanceMode mode) {
  Thread* T = Thread::Current();
  CHECK_ISOLATE(T->isolate());
  TransitionNativeToVM transition(T);
  return T->heap()->SetMode(mode);
}

DART_EXPORT void Dart_ExitIsolate() {
  Thread* T = Thread::Current();
  CHECK_ISOLATE(T->isolate());
  // The Thread structure is disassociated from the isolate, we do the
  // safepoint transition explicitly here instead of using the TransitionXXX
  // scope objects as the original transition happened outside this scope in
  // Dart_EnterIsolate/Dart_CreateIsolateGroup.
  ASSERT(T->execution_state() == Thread::kThreadInNative);
  T->ExitSafepoint();
  T->set_execution_state(Thread::kThreadInVM);
  Thread::ExitIsolate();
}

DART_EXPORT Dart_Handle
Dart_CreateSnapshot(uint8_t** vm_snapshot_data_buffer,
                    intptr_t* vm_snapshot_data_size,
                    uint8_t** isolate_snapshot_data_buffer,
                    intptr_t* isolate_snapshot_data_size,
                    bool is_core) {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("Cannot create snapshots on an AOT runtime.");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  if (vm_snapshot_data_buffer != nullptr) {
    CHECK_NULL(vm_snapshot_data_size);
  }
  CHECK_NULL(isolate_snapshot_data_buffer);
  CHECK_NULL(isolate_snapshot_data_size);
  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(T);
  if (Api::IsError(state)) {
    return state;
  }
  NoBackgroundCompilerScope no_bg_compiler(T);

#if defined(DEBUG)
  T->isolate_group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  {
    HeapIterationScope iteration(T);
    CheckFunctionTypesVisitor check_canonical(T);
    iteration.IterateObjects(&check_canonical);
  }
#endif  // #if defined(DEBUG)

  ZoneWriteStream vm_snapshot_data(Api::TopScope(T)->zone(),
                                   FullSnapshotWriter::kInitialSize);
  ZoneWriteStream isolate_snapshot_data(Api::TopScope(T)->zone(),
                                        FullSnapshotWriter::kInitialSize);
  const Snapshot::Kind snapshot_kind =
      is_core ? Snapshot::kFullCore : Snapshot::kFull;
  FullSnapshotWriter writer(
      snapshot_kind, &vm_snapshot_data, &isolate_snapshot_data,
      nullptr /* vm_image_writer */, nullptr /* isolate_image_writer */);
  writer.WriteFullSnapshot();
  if (vm_snapshot_data_buffer != nullptr) {
    *vm_snapshot_data_buffer = vm_snapshot_data.buffer();
    *vm_snapshot_data_size = writer.VmIsolateSnapshotSize();
  }
  *isolate_snapshot_data_buffer = isolate_snapshot_data.buffer();
  *isolate_snapshot_data_size = writer.IsolateSnapshotSize();
  return Api::Success();
#endif
}

DART_EXPORT bool Dart_IsKernel(const uint8_t* buffer, intptr_t buffer_size) {
  if (buffer_size < 4) {
    return false;
  }
  return (buffer[0] == 0x90) && (buffer[1] == 0xab) && (buffer[2] == 0xcd) &&
         (buffer[3] == 0xef);
}

DART_EXPORT char* Dart_IsolateMakeRunnable(Dart_Isolate isolate) {
  CHECK_NO_ISOLATE(Isolate::Current());
  API_TIMELINE_DURATION(Thread::Current());
  if (isolate == nullptr) {
    FATAL("%s expects argument 'isolate' to be non-null.", CURRENT_FUNC);
  }
  // TODO(16615): Validate isolate parameter.
  const char* error = reinterpret_cast<Isolate*>(isolate)->MakeRunnable();
  if (error != nullptr) {
    return Utils::StrDup(error);
  }
  return nullptr;
}

// --- Messages and Ports ---

DART_EXPORT void Dart_SetMessageNotifyCallback(
    Dart_MessageNotifyCallback message_notify_callback) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);

  {
    NoSafepointScope no_safepoint_scope;
    isolate->set_message_notify_callback(message_notify_callback);
  }

  if (message_notify_callback != nullptr && isolate->HasPendingMessages()) {
    ::Dart_ExitIsolate();

    // If a new handler gets installed and there are pending messages in the
    // queue (e.g. OOB messages for doing vm service work) we need to notify
    // the newly registered callback, otherwise the embedder might never get
    // notified about the pending messages.
    message_notify_callback(Api::CastIsolate(isolate));

    ::Dart_EnterIsolate(Api::CastIsolate(isolate));
  }
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
  ASSERT(data->monitor != nullptr);
  MonitorLocker ml(data->monitor);
  data->done = true;
  ml.Notify();
}

DART_EXPORT Dart_Handle Dart_RunLoop() {
  Isolate* I;
  bool result;
  {
    Thread* T = Thread::Current();
    I = T->isolate();
    CHECK_API_SCOPE(T);
    CHECK_CALLBACK_STATE(T);
  }
  API_TIMELINE_BEGIN_END(Thread::Current());
  // The message handler run loop does not expect to have a current isolate
  // so we exit the isolate here and enter it again after the runloop is done.
  ::Dart_ExitIsolate();
  {
    Monitor monitor;
    MonitorLocker ml(&monitor);
    RunLoopData data;
    data.monitor = &monitor;
    data.done = false;
    result =
        I->message_handler()->Run(I->group()->thread_pool(), nullptr,
                                  RunLoopDone, reinterpret_cast<uword>(&data));
    if (result) {
      while (!data.done) {
        ml.Wait();
      }
    }
  }
  ::Dart_EnterIsolate(Api::CastIsolate(I));
  if (!result) {
    Thread* T = Thread::Current();
    TransitionNativeToVM transition(T);
    return Api::NewError("Run method in isolate message handler failed");
  } else if (I->sticky_error() != Object::null()) {
    Thread* T = Thread::Current();
    TransitionNativeToVM transition(T);
    return Api::NewHandle(T, I->StealStickyError());
  }
  if (FLAG_print_class_table) {
    HANDLESCOPE(Thread::Current());
    I->group()->class_table()->Print();
  }
  return Api::Success();
}

DART_EXPORT bool Dart_RunLoopAsync(bool errors_are_fatal,
                                   Dart_Port on_error_port,
                                   Dart_Port on_exit_port,
                                   char** error) {
  auto thread = Thread::Current();
  auto isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  *error = nullptr;

  if (thread->api_top_scope() != nullptr) {
    *error = Utils::StrDup("There must not be an active api scope.");
    return false;
  }

  if (!isolate->is_runnable()) {
    const char* error_msg = isolate->MakeRunnable();
    if (error_msg != nullptr) {
      *error = Utils::StrDup(error_msg);
      return false;
    }
  }

  isolate->SetErrorsFatal(errors_are_fatal);

  if (on_error_port != ILLEGAL_PORT || on_exit_port != ILLEGAL_PORT) {
    auto thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);

    if (on_error_port != ILLEGAL_PORT) {
      const auto& port =
          SendPort::Handle(thread->zone(), SendPort::New(on_error_port));
      isolate->AddErrorListener(port);
    }
    if (on_exit_port != ILLEGAL_PORT) {
      const auto& port =
          SendPort::Handle(thread->zone(), SendPort::New(on_exit_port));
      isolate->AddExitListener(port, Instance::null_instance());
    }
  }

  Dart_ExitIsolate();
  isolate->Run();
  return true;
}

DART_EXPORT Dart_Handle Dart_HandleMessage() {
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  CHECK_API_SCOPE(T);
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_BEGIN_END(T);
  TransitionNativeToVM transition(T);
  if (I->message_handler()->HandleNextMessage() != MessageHandler::kOK) {
    return Api::NewHandle(T, T->StealStickyError());
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_WaitForEvent(int64_t timeout_millis) {
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  CHECK_API_SCOPE(T);
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_BEGIN_END(T);
  TransitionNativeToVM transition(T);
  if (I->message_notify_callback() != nullptr) {
    return Api::NewError("waitForEventSync is not supported by this embedder");
  }
  Object& result =
      Object::Handle(Z, DartLibraryCalls::EnsureScheduleImmediate());
  if (result.IsError()) {
    return Api::NewHandle(T, result.ptr());
  }

  // Drain the microtask queue. Propagate any errors to the entry frame.
  result = DartLibraryCalls::DrainMicrotaskQueue();
  if (result.IsError()) {
    // Persist the error across unwiding scopes before propagating.
    const Error* error;
    {
      NoSafepointScope no_safepoint;
      ErrorPtr raw_error = Error::Cast(result).ptr();
      T->UnwindScopes(T->top_exit_frame_info());
      error = &Error::Handle(T->zone(), raw_error);
    }
    Exceptions::PropagateToEntry(*error);
    UNREACHABLE();
    return Api::NewError("Unreachable");
  }

  // Block to wait for messages and then handle them. Propagate any errors to
  // the entry frame.
  if (I->message_handler()->PauseAndHandleAllMessages(timeout_millis) !=
      MessageHandler::kOK) {
    // Persist the error across unwiding scopes before propagating.
    const Error* error;
    {
      NoSafepointScope no_safepoint;
      ErrorPtr raw_error = T->StealStickyError();
      T->UnwindScopes(T->top_exit_frame_info());
      error = &Error::Handle(T->zone(), raw_error);
    }
    Exceptions::PropagateToEntry(*error);
    UNREACHABLE();
    return Api::NewError("Unreachable");
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
  API_TIMELINE_DURATION(T);
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
  return isolate->HasLivePorts();
}

DART_EXPORT bool Dart_Post(Dart_Port port_id, Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  NoSafepointScope no_safepoint_scope;
  if (port_id == ILLEGAL_PORT) {
    return false;
  }

  const Object& object = Object::Handle(Z, Api::UnwrapHandle(handle));
  return PortMap::PostMessage(WriteMessage(/* same_group */ false, object,
                                           port_id, Message::kNormalPriority));
}

DART_EXPORT Dart_Handle Dart_NewSendPort(Dart_Port port_id) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  if (port_id == ILLEGAL_PORT) {
    return Api::NewError("%s: illegal port_id %" Pd64 ".", CURRENT_FUNC,
                         port_id);
  }
  int64_t origin_id = PortMap::GetOriginId(port_id);
  return Api::NewHandle(T, SendPort::New(port_id, origin_id));
}

DART_EXPORT Dart_Handle Dart_SendPortGetId(Dart_Handle port,
                                           Dart_Port* port_id) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION(T);
  const SendPort& send_port = Api::UnwrapSendPortHandle(Z, port);
  if (send_port.IsNull()) {
    RETURN_TYPE_ERROR(Z, port, SendPort);
  }
  if (port_id == nullptr) {
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
  TransitionNativeToVM transition(thread);
  thread->EnterApiScope();
}

DART_EXPORT void Dart_ExitScope() {
  Thread* thread = Thread::Current();
  CHECK_API_SCOPE(thread);
  TransitionNativeToVM transition(thread);
  thread->ExitApiScope();
}

DART_EXPORT uint8_t* Dart_ScopeAllocate(intptr_t size) {
  Zone* zone;
  Thread* thread = Thread::Current();
  if (thread != nullptr) {
    ApiLocalScope* scope = thread->api_top_scope();
    zone = scope->zone();
  } else {
    ApiNativeScope* scope = ApiNativeScope::Current();
    if (scope == nullptr) return nullptr;
    zone = scope->zone();
  }
  return reinterpret_cast<uint8_t*>(zone->AllocUnsafe(size));
}

// --- Objects ----

DART_EXPORT Dart_Handle Dart_Null() {
  ASSERT(Isolate::Current() != nullptr);
  return Api::Null();
}

DART_EXPORT bool Dart_IsNull(Dart_Handle object) {
  TransitionNativeToVM transition(Thread::Current());
  return Api::UnwrapHandle(object) == Object::null();
}

DART_EXPORT Dart_Handle Dart_EmptyString() {
  ASSERT(Isolate::Current() != nullptr);
  return Api::EmptyString();
}

DART_EXPORT Dart_Handle Dart_TypeDynamic() {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION(T);
  return Api::NewHandle(T, Type::DynamicType());
}

DART_EXPORT Dart_Handle Dart_TypeVoid() {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION(T);
  return Api::NewHandle(T, Type::VoidType());
}

DART_EXPORT Dart_Handle Dart_TypeNever() {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION(T);
  return Api::NewHandle(T, Type::NeverType());
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
    return Api::NewHandle(T, result.ptr());
  } else {
    return Api::NewError("Expected boolean result from ==");
  }
}

// Assumes type is non-null.
static bool InstanceIsType(const Thread* thread,
                           const Instance& instance,
                           const Type& type) {
  ASSERT(!type.IsNull());
  CHECK_CALLBACK_STATE(thread);
  return instance.IsInstanceOf(type, Object::null_type_arguments(),
                               Object::null_type_arguments());
}

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
  *value = InstanceIsType(T, instance, type_obj);
  return Api::Success();
}

DART_EXPORT bool Dart_IsInstance(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Object& ref = thread->ObjectHandle();
  ref = Api::UnwrapHandle(object);
  return ref.IsInstance();
}

DART_EXPORT bool Dart_IsNumber(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return IsNumberClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsInteger(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return IsIntegerClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsDouble(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return Api::ClassId(object) == kDoubleCid;
}

DART_EXPORT bool Dart_IsBoolean(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return Api::ClassId(object) == kBoolCid;
}

DART_EXPORT bool Dart_IsString(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return IsStringClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsStringLatin1(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return IsOneByteStringClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsExternalString(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return IsExternalStringClassId(Api::ClassId(object));
}

DART_EXPORT bool Dart_IsList(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  if (IsBuiltinListClassId(Api::ClassId(object))) {
    return true;
  }

  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  return GetListInstance(Z, obj) != Instance::null();
}

DART_EXPORT bool Dart_IsMap(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  return GetMapInstance(Z, obj) != Instance::null();
}

DART_EXPORT bool Dart_IsLibrary(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return Api::ClassId(object) == kLibraryCid;
}

DART_EXPORT bool Dart_IsType(Dart_Handle handle) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return IsTypeClassId(Api::ClassId(handle));
}

DART_EXPORT bool Dart_IsFunction(Dart_Handle handle) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return Api::ClassId(handle) == kFunctionCid;
}

DART_EXPORT bool Dart_IsVariable(Dart_Handle handle) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return Api::ClassId(handle) == kFieldCid;
}

DART_EXPORT bool Dart_IsTypeVariable(Dart_Handle handle) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return Api::ClassId(handle) == kTypeParameterCid;
}

DART_EXPORT bool Dart_IsClosure(Dart_Handle object) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return Api::ClassId(object) == kClosureCid;
}

DART_EXPORT bool Dart_IsTearOff(Dart_Handle object) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
  if (obj.IsClosure()) {
    const Closure& closure = Closure::Cast(obj);
    const Function& func = Function::Handle(Z, closure.function());
    return func.IsImplicitClosureFunction();
  }
  return false;
}

DART_EXPORT bool Dart_IsTypedData(Dart_Handle handle) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  intptr_t cid = Api::ClassId(handle);
  return IsTypedDataClassId(cid) || IsExternalTypedDataClassId(cid) ||
         IsTypedDataViewClassId(cid) || IsUnmodifiableTypedDataViewClassId(cid);
}

DART_EXPORT bool Dart_IsByteBuffer(Dart_Handle handle) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  return Api::ClassId(handle) == kByteBufferCid;
}

DART_EXPORT bool Dart_IsFuture(Dart_Handle handle) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  if (obj.IsInstance()) {
    const Class& obj_class = Class::Handle(Z, obj.clazz());
    return obj_class.is_future_subtype();
  }
  return false;
}

// --- Instances ----

DART_EXPORT Dart_Handle Dart_InstanceGetType(Dart_Handle instance) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  auto isolate_group = T->isolate_group();
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(instance));
  if (obj.IsNull()) {
    return Api::NewHandle(T, isolate_group->object_store()->null_type());
  }
  if (!obj.IsInstance()) {
    RETURN_TYPE_ERROR(Z, instance, Instance);
  }
  const AbstractType& type =
      AbstractType::Handle(Instance::Cast(obj).GetType(Heap::kNew));
  return Api::NewHandle(T, type.Canonicalize(T));
}

DART_EXPORT Dart_Handle Dart_FunctionName(Dart_Handle function) {
  DARTSCOPE(Thread::Current());
  const Function& func = Api::UnwrapFunctionHandle(Z, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(Z, function, Function);
  }
  return Api::NewHandle(T, func.UserVisibleName());
}

DART_EXPORT Dart_Handle Dart_ClassName(Dart_Handle cls_type) {
  DARTSCOPE(Thread::Current());
  const Type& type_obj = Api::UnwrapTypeHandle(Z, cls_type);
  if (type_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, cls_type, Type);
  }
  const Class& klass = Class::Handle(Z, type_obj.type_class());
  if (klass.IsNull()) {
    return Api::NewError(
        "cls_type must be a Type object which represents a Class.");
  }
  return Api::NewHandle(T, klass.UserVisibleName());
}

DART_EXPORT Dart_Handle Dart_FunctionOwner(Dart_Handle function) {
  DARTSCOPE(Thread::Current());
  const Function& func = Api::UnwrapFunctionHandle(Z, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(Z, function, Function);
  }
  if (func.IsNonImplicitClosureFunction()) {
    FunctionPtr parent_function = func.parent_function();
    return Api::NewHandle(T, parent_function);
  }
  const Class& owner = Class::Handle(Z, func.Owner());
  ASSERT(!owner.IsNull());
  if (owner.IsTopLevel()) {
// Top-level functions are implemented as members of a hidden class. We hide
// that class here and instead answer the library.
#if defined(DEBUG)
    const Library& lib = Library::Handle(Z, owner.library());
    if (lib.IsNull()) {
      ASSERT(owner.IsDynamicClass() || owner.IsVoidClass() ||
             owner.IsNeverClass());
    }
#endif
    return Api::NewHandle(T, owner.library());
  } else {
    return Api::NewHandle(T, owner.RareType());
  }
}

DART_EXPORT Dart_Handle Dart_FunctionIsStatic(Dart_Handle function,
                                              bool* is_static) {
  DARTSCOPE(Thread::Current());
  if (is_static == nullptr) {
    RETURN_NULL_ERROR(is_static);
  }
  const Function& func = Api::UnwrapFunctionHandle(Z, function);
  if (func.IsNull()) {
    RETURN_TYPE_ERROR(Z, function, Function);
  }
  *is_static = func.is_static();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_ClosureFunction(Dart_Handle closure) {
  DARTSCOPE(Thread::Current());
  const Instance& closure_obj = Api::UnwrapInstanceHandle(Z, closure);
  if (closure_obj.IsNull() || !closure_obj.IsClosure()) {
    RETURN_TYPE_ERROR(Z, closure, Instance);
  }

  ASSERT(ClassFinalizer::AllClassesFinalized());

  FunctionPtr rf = Closure::Cast(closure_obj).function();
  return Api::NewHandle(T, rf);
}

DART_EXPORT Dart_Handle Dart_ClassLibrary(Dart_Handle cls_type) {
  DARTSCOPE(Thread::Current());
  const Type& type_obj = Api::UnwrapTypeHandle(Z, cls_type);
  const Class& klass = Class::Handle(Z, type_obj.type_class());
  if (klass.IsNull()) {
    return Api::NewError(
        "cls_type must be a Type object which represents a Class.");
  }
  const Library& library = Library::Handle(klass.library());
  if (library.IsNull()) {
    return Dart_Null();
  }
  return Api::NewHandle(Thread::Current(), library.ptr());
}

// --- Numbers, Integers and Doubles ----

DART_EXPORT Dart_Handle Dart_IntegerFitsIntoInt64(Dart_Handle integer,
                                                  bool* fits) {
  // Fast path for Smis and Mints.
  Thread* thread = Thread::Current();
  API_TIMELINE_DURATION(thread);
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  if (Api::IsSmi(integer)) {
    *fits = true;
    return Api::Success();
  }
  // Slow path for mints and type error.
  DARTSCOPE(thread);
  if (Api::ClassId(integer) == kMintCid) {
    *fits = true;
    return Api::Success();
  }
  const Integer& int_obj = Api::UnwrapIntegerHandle(Z, integer);
  ASSERT(int_obj.IsNull());
  RETURN_TYPE_ERROR(Z, integer, Integer);
}

DART_EXPORT Dart_Handle Dart_IntegerFitsIntoUint64(Dart_Handle integer,
                                                   bool* fits) {
  // Fast path for Smis.
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  API_TIMELINE_DURATION(thread);
  if (Api::IsSmi(integer)) {
    *fits = (Api::SmiValue(integer) >= 0);
    return Api::Success();
  }
  // Slow path for Mints.
  DARTSCOPE(thread);
  const Integer& int_obj = Api::UnwrapIntegerHandle(Z, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, integer, Integer);
  }
  ASSERT(int_obj.IsMint());
  *fits = !int_obj.IsNegative();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_NewInteger(int64_t value) {
  // Fast path for Smis.
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  API_TIMELINE_DURATION(thread);
  DARTSCOPE(thread);
  CHECK_CALLBACK_STATE(thread);
  return Api::NewHandle(thread, Integer::New(value));
}

DART_EXPORT Dart_Handle Dart_NewIntegerFromUint64(uint64_t value) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION(T);
  if (Integer::IsValueInRange(value)) {
    return Api::NewHandle(T, Integer::NewFromUint64(value));
  }
  return Api::NewError("%s: Cannot create Dart integer from value %" Pu64,
                       CURRENT_FUNC, value);
}

DART_EXPORT Dart_Handle Dart_NewIntegerFromHexCString(const char* str) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  API_TIMELINE_DURATION(T);
  const String& str_obj = String::Handle(Z, String::New(str));
  IntegerPtr integer = Integer::New(str_obj);
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
  // Slow path for Mints.
  DARTSCOPE(thread);
  const Integer& int_obj = Api::UnwrapIntegerHandle(Z, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, integer, Integer);
  }
  ASSERT(int_obj.IsMint());
  *value = int_obj.AsInt64Value();
  return Api::Success();
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
  // Slow path for Mints.
  DARTSCOPE(thread);
  const Integer& int_obj = Api::UnwrapIntegerHandle(Z, integer);
  if (int_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, integer, Integer);
  }
  if (int_obj.IsSmi()) {
    ASSERT(int_obj.IsNegative());
  } else {
    ASSERT(int_obj.IsMint());
    if (!int_obj.IsNegative()) {
      *value = int_obj.AsInt64Value();
      return Api::Success();
    }
  }
  return Api::NewError("%s: Integer %s cannot be represented as a uint64_t.",
                       CURRENT_FUNC, int_obj.ToCString());
}

DART_EXPORT Dart_Handle Dart_IntegerToHexCString(Dart_Handle integer,
                                                 const char** value) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
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

DART_EXPORT Dart_Handle Dart_GetStaticMethodClosure(Dart_Handle library,
                                                    Dart_Handle cls_type,
                                                    Dart_Handle function_name) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }

  const Type& type_obj = Api::UnwrapTypeHandle(Z, cls_type);
  if (type_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, cls_type, Type);
  }

  const Class& klass = Class::Handle(Z, type_obj.type_class());
  if (klass.IsNull()) {
    return Api::NewError(
        "cls_type must be a Type object which represents a Class");
  }

  const auto& error = klass.EnsureIsFinalized(Thread::Current());
  if (error != Error::null()) {
    return Api::NewHandle(T, error);
  }

  const String& func_name = Api::UnwrapStringHandle(Z, function_name);
  if (func_name.IsNull()) {
    RETURN_TYPE_ERROR(Z, function_name, String);
  }

  Function& func =
      Function::Handle(Z, klass.LookupStaticFunctionAllowPrivate(func_name));
  if (func.IsNull()) {
    return Dart_Null();
  }

  if (!func.is_static()) {
    return Api::NewError("function_name must refer to a static method.");
  }

  if (func.kind() != UntaggedFunction::kRegularFunction) {
    return Api::NewError(
        "function_name must be the name of a regular function.");
  }
  func = func.ImplicitClosureFunction();
  if (func.IsNull()) {
    return Dart_Null();
  }

  return Api::NewHandle(T, func.ImplicitStaticClosure());
}

// --- Booleans ----

DART_EXPORT Dart_Handle Dart_True() {
  ASSERT(Isolate::Current() != nullptr);
  return Api::True();
}

DART_EXPORT Dart_Handle Dart_False() {
  ASSERT(Isolate::Current() != nullptr);
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
  DARTSCOPE(thread);
  {
    ReusableObjectHandleScope reused_obj_handle(thread);
    const String& str_obj = Api::UnwrapStringHandle(reused_obj_handle, str);
    if (!str_obj.IsNull()) {
      *len = str_obj.Length();
      return Api::Success();
    }
  }
  RETURN_TYPE_ERROR(thread->zone(), str, String);
}

DART_EXPORT Dart_Handle Dart_NewStringFromCString(const char* str) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  if (str == nullptr) {
    RETURN_NULL_ERROR(str);
  }
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(T, String::New(str));
}

DART_EXPORT Dart_Handle Dart_NewStringFromUTF8(const uint8_t* utf8_array,
                                               intptr_t length) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  if (utf8_array == nullptr && length != 0) {
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
  if (utf16_array == nullptr && length != 0) {
    RETURN_NULL_ERROR(utf16_array);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(T, String::FromUTF16(utf16_array, length));
}

DART_EXPORT Dart_Handle Dart_NewStringFromUTF32(const int32_t* utf32_array,
                                                intptr_t length) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  if (utf32_array == nullptr && length != 0) {
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
                             intptr_t external_allocation_size,
                             Dart_HandleFinalizer callback) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  if (latin1_array == nullptr && length != 0) {
    RETURN_NULL_ERROR(latin1_array);
  }
  if (callback == nullptr) {
    RETURN_NULL_ERROR(callback);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  return Api::NewHandle(
      T,
      String::NewExternal(latin1_array, length, peer, external_allocation_size,
                          callback, T->heap()->SpaceForExternal(length)));
}

DART_EXPORT Dart_Handle
Dart_NewExternalUTF16String(const uint16_t* utf16_array,
                            intptr_t length,
                            void* peer,
                            intptr_t external_allocation_size,
                            Dart_HandleFinalizer callback) {
  DARTSCOPE(Thread::Current());
  if (utf16_array == nullptr && length != 0) {
    RETURN_NULL_ERROR(utf16_array);
  }
  if (callback == nullptr) {
    RETURN_NULL_ERROR(callback);
  }
  CHECK_LENGTH(length, String::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  intptr_t bytes = length * sizeof(*utf16_array);
  return Api::NewHandle(
      T,
      String::NewExternal(utf16_array, length, peer, external_allocation_size,
                          callback, T->heap()->SpaceForExternal(bytes)));
}

DART_EXPORT Dart_Handle Dart_StringToCString(Dart_Handle object,
                                             const char** cstr) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  if (cstr == nullptr) {
    RETURN_NULL_ERROR(cstr);
  }
  const String& str_obj = Api::UnwrapStringHandle(Z, object);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, object, String);
  }
  intptr_t string_length = Utf8::Length(str_obj);
  char* res = Api::TopScope(T)->zone()->Alloc<char>(string_length + 1);
  if (res == nullptr) {
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
  API_TIMELINE_DURATION(T);
  if (utf8_array == nullptr) {
    RETURN_NULL_ERROR(utf8_array);
  }
  if (length == nullptr) {
    RETURN_NULL_ERROR(length);
  }
  const String& str_obj = Api::UnwrapStringHandle(Z, str);
  if (str_obj.IsNull()) {
    RETURN_TYPE_ERROR(Z, str, String);
  }
  intptr_t str_len = Utf8::Length(str_obj);
  *utf8_array = Api::TopScope(T)->zone()->Alloc<uint8_t>(str_len);
  if (*utf8_array == nullptr) {
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
  API_TIMELINE_DURATION(T);
  if (latin1_array == nullptr) {
    RETURN_NULL_ERROR(latin1_array);
  }
  if (length == nullptr) {
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
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
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
  TransitionNativeToVM transition(thread);
  if (size == nullptr) {
    RETURN_NULL_ERROR(size);
  }
  {
    ReusableObjectHandleScope reused_obj_handle(thread);
    const String& str_obj = Api::UnwrapStringHandle(reused_obj_handle, str);
    if (!str_obj.IsNull()) {
      *size = (str_obj.Length() * str_obj.CharSize());
      return Api::Success();
    }
  }
  RETURN_TYPE_ERROR(thread->zone(), str, String);
}

DART_EXPORT Dart_Handle Dart_StringGetProperties(Dart_Handle object,
                                                 intptr_t* char_size,
                                                 intptr_t* str_len,
                                                 void** peer) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  {
    ReusableObjectHandleScope reused_obj_handle(thread);
    const String& str = Api::UnwrapStringHandle(reused_obj_handle, object);
    if (!str.IsNull()) {
      if (str.IsExternal()) {
        *peer = str.GetPeer();
        ASSERT(*peer != nullptr);
      } else {
        NoSafepointScope no_safepoint_scope;
        *peer = thread->heap()->GetPeer(str.ptr());
      }
      *char_size = str.CharSize();
      *str_len = str.Length();
      return Api::Success();
    }
  }
  RETURN_TYPE_ERROR(thread->zone(), object, String);
}

// --- Lists ---

DART_EXPORT Dart_Handle Dart_NewList(intptr_t length) {
  return Dart_NewListOf(Dart_CoreType_Dynamic, length);
}

static TypeArgumentsPtr TypeArgumentsForElementType(
    ObjectStore* store,
    Dart_CoreType_Id element_type_id) {
  switch (element_type_id) {
    case Dart_CoreType_Dynamic:
      return TypeArguments::null();
    case Dart_CoreType_Int:
      return store->type_argument_legacy_int();
    case Dart_CoreType_String:
      return store->type_argument_legacy_string();
  }
  UNREACHABLE();
  return TypeArguments::null();
}

DART_EXPORT Dart_Handle Dart_NewListOf(Dart_CoreType_Id element_type_id,
                                       intptr_t length) {
  DARTSCOPE(Thread::Current());
  if (T->isolate_group()->null_safety() &&
      element_type_id != Dart_CoreType_Dynamic) {
    return Api::NewError(
        "Cannot use legacy types with --sound-null-safety enabled. "
        "Use Dart_NewListOfType or Dart_NewListOfTypeFilled instead.");
  }
  CHECK_LENGTH(length, Array::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  const Array& arr = Array::Handle(Z, Array::New(length));
  if (element_type_id != Dart_CoreType_Dynamic) {
    arr.SetTypeArguments(TypeArguments::Handle(
        Z, TypeArgumentsForElementType(T->isolate_group()->object_store(),
                                       element_type_id)));
  }
  return Api::NewHandle(T, arr.ptr());
}

static bool CanTypeContainNull(const Type& type) {
  return (type.nullability() == Nullability::kLegacy) ||
         (type.nullability() == Nullability::kNullable);
}

DART_EXPORT Dart_Handle Dart_NewListOfType(Dart_Handle element_type,
                                           intptr_t length) {
  DARTSCOPE(Thread::Current());
  CHECK_LENGTH(length, Array::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  const Type& type = Api::UnwrapTypeHandle(Z, element_type);
  if (type.IsNull()) {
    RETURN_TYPE_ERROR(Z, element_type, Type);
  }
  if (!type.IsFinalized()) {
    return Api::NewError(
        "%s expects argument 'type' to be a fully resolved type.",
        CURRENT_FUNC);
  }
  if ((length > 0) && !CanTypeContainNull(type)) {
    return Api::NewError("%s expects argument 'type' to be a nullable type.",
                         CURRENT_FUNC);
  }
  return Api::NewHandle(T, Array::New(length, type));
}

DART_EXPORT Dart_Handle Dart_NewListOfTypeFilled(Dart_Handle element_type,
                                                 Dart_Handle fill_object,
                                                 intptr_t length) {
  DARTSCOPE(Thread::Current());
  CHECK_LENGTH(length, Array::kMaxElements);
  CHECK_CALLBACK_STATE(T);
  const Type& type = Api::UnwrapTypeHandle(Z, element_type);
  if (type.IsNull()) {
    RETURN_TYPE_ERROR(Z, element_type, Type);
  }
  if (!type.IsFinalized()) {
    return Api::NewError(
        "%s expects argument 'type' to be a fully resolved type.",
        CURRENT_FUNC);
  }
  const Instance& instance = Api::UnwrapInstanceHandle(Z, fill_object);
  if (!instance.IsNull() && !InstanceIsType(T, instance, type)) {
    return Api::NewError(
        "%s expects argument 'fill_object' to have the same type as "
        "'element_type'.",
        CURRENT_FUNC);
  }
  if ((length > 0) && instance.IsNull() && !CanTypeContainNull(type)) {
    return Api::NewError(
        "%s expects argument 'fill_object' to be non-null for a non-nullable "
        "'element_type'.",
        CURRENT_FUNC);
  }
  Array& arr = Array::Handle(Z, Array::New(length, type));
  for (intptr_t i = 0; i < arr.Length(); ++i) {
    arr.SetAt(i, instance);
  }
  return Api::NewHandle(T, arr.ptr());
}

#define GET_LIST_LENGTH(zone, type, obj, len)                                  \
  type& array = type::Handle(zone);                                            \
  array ^= obj.ptr();                                                          \
  *len = array.Length();                                                       \
  return Api::Success();

DART_EXPORT Dart_Handle Dart_ListLength(Dart_Handle list, intptr_t* len) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsError()) {
    // Pass through errors.
    return list;
  }
  if (obj.IsTypedDataBase()) {
    GET_LIST_LENGTH(Z, TypedDataBase, obj, len);
  }
  if (obj.IsArray()) {
    GET_LIST_LENGTH(Z, Array, obj, len);
  }
  if (obj.IsGrowableObjectArray()) {
    GET_LIST_LENGTH(Z, GrowableObjectArray, obj, len);
  }
  CHECK_CALLBACK_STATE(T);

  // Now check and handle a dart object that implements the List interface.
  const Instance& instance = Instance::Handle(Z, GetListInstance(Z, obj));
  if (instance.IsNull()) {
    return Api::NewArgumentError(
        "Object does not implement the List interface");
  }
  const Object& retval =
      Object::Handle(Z, CallStatic1Arg(Z, Symbols::_listLength(), instance));
  if (retval.IsSmi()) {
    *len = Smi::Cast(retval).Value();
    return Api::Success();
  } else if (retval.IsMint()) {
    int64_t mint_value = Mint::Cast(retval).value();
    if (mint_value >= kIntptrMin && mint_value <= kIntptrMax) {
      *len = static_cast<intptr_t>(mint_value);
      return Api::Success();
    }
    return Api::NewError(
        "Length of List object is greater than the "
        "maximum value that 'len' parameter can hold");
  } else if (retval.IsError()) {
    return Api::NewHandle(T, retval.ptr());
  } else {
    return Api::NewError("Length of List object is not an integer");
  }
}

#define GET_LIST_ELEMENT(thread, type, obj, index)                             \
  const type& array_obj = type::Cast(obj);                                     \
  if ((index >= 0) && (index < array_obj.Length())) {                          \
    return Api::NewHandle(thread, array_obj.At(index));                        \
  }                                                                            \
  return Api::NewError("Invalid index passed into access list element");

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
      return Api::NewHandle(
          T, CallStatic2Args(Z, Symbols::_listGetAt(), instance,
                             Instance::Handle(Z, Integer::New(index))));
    }
    return Api::NewArgumentError(
        "Object does not implement the 'List' interface");
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
  return Api::NewError("Invalid offset/length passed into access list");

DART_EXPORT Dart_Handle Dart_ListGetRange(Dart_Handle list,
                                          intptr_t offset,
                                          intptr_t length,
                                          Dart_Handle* result) {
  DARTSCOPE(Thread::Current());
  if (result == nullptr) {
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
      const intptr_t kNumArgs = 2;
      const Function& function = Function::Handle(
          Z, FindCoreLibPrivateFunction(Z, Symbols::_listGetAt()));
      const Array& args = Array::Handle(Z, Array::New(kNumArgs));
      args.SetAt(0, instance);
      Instance& index = Instance::Handle(Z);
      for (intptr_t i = 0; i < length; ++i) {
        index = Integer::New(i);
        args.SetAt(1, index);
        Dart_Handle value =
            Api::NewHandle(T, DartEntry::InvokeFunction(function, args));
        if (Api::IsError(value)) return value;
        result[i] = value;
      }
      return Api::Success();
    }
    return Api::NewArgumentError(
        "Object does not implement the 'List' interface");
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
  return Api::NewError("Invalid index passed into set list element");

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
      const Integer& index_obj = Integer::Handle(Z, Integer::New(index));
      const Object& value_obj = Object::Handle(Z, Api::UnwrapHandle(value));
      if (!value_obj.IsNull() && !value_obj.IsInstance()) {
        RETURN_TYPE_ERROR(Z, value, Instance);
      }
      return Api::NewHandle(
          T, CallStatic3Args(Z, Symbols::_listSetAt(), instance, index_obj,
                             Instance::Cast(value_obj)));
    }
    return Api::NewArgumentError(
        "Object does not implement the 'List' interface");
  }
}

static ObjectPtr ResolveConstructor(const char* current_func,
                                    const Class& cls,
                                    const String& class_name,
                                    const String& dotted_name,
                                    int num_args);

static ObjectPtr ThrowArgumentError(const char* exception_message) {
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
  if (result.IsError()) return result.ptr();
  ASSERT(result.IsFunction());
  Function& constructor = Function::Handle(zone);
  constructor ^= result.ptr();
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
  if (result.IsError()) return result.ptr();
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
    InstancePtr raw_exception = exception.ptr();
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
  return Api::NewError("Invalid length passed into access array elements");

DART_EXPORT Dart_Handle Dart_ListGetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            uint8_t* native_array,
                                            intptr_t length) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsTypedDataBase()) {
    const TypedDataBase& array = TypedDataBase::Cast(obj);
    if (array.ElementSizeInBytes() == 1) {
      if (Utils::RangeCheck(offset, length, array.Length())) {
        NoSafepointScope no_safepoint;
        memmove(native_array,
                reinterpret_cast<uint8_t*>(array.DataAddr(offset)), length);
        return Api::Success();
      }
      return Api::NewError("Invalid length passed into access list elements");
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
    const int kNumArgs = 2;
    const Function& function = Function::Handle(
        Z, FindCoreLibPrivateFunction(Z, Symbols::_listGetAt()));
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
        return Api::NewHandle(T, result.ptr());
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
  return Api::NewArgumentError(
      "Object does not implement the 'List' interface");
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
  return Api::NewError("Invalid length passed into set array elements");

DART_EXPORT Dart_Handle Dart_ListSetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            const uint8_t* native_array,
                                            intptr_t length) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(list));
  if (obj.IsTypedDataBase()) {
    const TypedDataBase& array = TypedDataBase::Cast(obj);
    if (array.ElementSizeInBytes() == 1) {
      if (Utils::RangeCheck(offset, length, array.Length())) {
        NoSafepointScope no_safepoint;
        memmove(reinterpret_cast<uint8_t*>(array.DataAddr(offset)),
                native_array, length);
        return Api::Success();
      }
      return Api::NewError("Invalid length passed into access list elements");
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
    const int kNumArgs = 3;
    const Function& function = Function::Handle(
        Z, FindCoreLibPrivateFunction(Z, Symbols::_listSetAt()));
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
        return Api::NewHandle(T, result.ptr());
      }
    }
    return Api::Success();
  }
  return Api::NewArgumentError(
      "Object does not implement the 'List' interface");
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
    return Api::NewHandle(T, CallStatic2Args(Z, Symbols::_mapGet(), instance,
                                             Instance::Cast(key_obj)));
  }
  return Api::NewArgumentError("Object does not implement the 'Map' interface");
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
        T, CallStatic2Args(Z, Symbols::_mapContainsKey(), instance,
                           Instance::Cast(key_obj)));
  }
  return Api::NewArgumentError("Object does not implement the 'Map' interface");
}

DART_EXPORT Dart_Handle Dart_MapKeys(Dart_Handle map) {
  DARTSCOPE(Thread::Current());
  CHECK_CALLBACK_STATE(T);
  Object& obj = Object::Handle(Z, Api::UnwrapHandle(map));
  Instance& instance = Instance::Handle(Z, GetMapInstance(Z, obj));
  if (!instance.IsNull()) {
    return Api::NewHandle(T, CallStatic1Arg(Z, Symbols::_mapKeys(), instance));
  }
  return Api::NewArgumentError("Object does not implement the 'Map' interface");
}

// --- Typed Data ---

// Helper method to get the type of a TypedData object.
static Dart_TypedData_Type GetType(intptr_t class_id) {
  Dart_TypedData_Type type;
  switch (class_id) {
    case kByteDataViewCid:
    case kUnmodifiableByteDataViewCid:
      type = Dart_TypedData_kByteData;
      break;
    case kTypedDataInt8ArrayCid:
    case kTypedDataInt8ArrayViewCid:
    case kUnmodifiableTypedDataInt8ArrayViewCid:
    case kExternalTypedDataInt8ArrayCid:
      type = Dart_TypedData_kInt8;
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ArrayViewCid:
    case kUnmodifiableTypedDataUint8ArrayViewCid:
    case kExternalTypedDataUint8ArrayCid:
      type = Dart_TypedData_kUint8;
      break;
    case kTypedDataUint8ClampedArrayCid:
    case kTypedDataUint8ClampedArrayViewCid:
    case kUnmodifiableTypedDataUint8ClampedArrayViewCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      type = Dart_TypedData_kUint8Clamped;
      break;
    case kTypedDataInt16ArrayCid:
    case kTypedDataInt16ArrayViewCid:
    case kUnmodifiableTypedDataInt16ArrayViewCid:
    case kExternalTypedDataInt16ArrayCid:
      type = Dart_TypedData_kInt16;
      break;
    case kTypedDataUint16ArrayCid:
    case kTypedDataUint16ArrayViewCid:
    case kUnmodifiableTypedDataUint16ArrayViewCid:
    case kExternalTypedDataUint16ArrayCid:
      type = Dart_TypedData_kUint16;
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataInt32ArrayViewCid:
    case kUnmodifiableTypedDataInt32ArrayViewCid:
    case kExternalTypedDataInt32ArrayCid:
      type = Dart_TypedData_kInt32;
      break;
    case kTypedDataUint32ArrayCid:
    case kTypedDataUint32ArrayViewCid:
    case kUnmodifiableTypedDataUint32ArrayViewCid:
    case kExternalTypedDataUint32ArrayCid:
      type = Dart_TypedData_kUint32;
      break;
    case kTypedDataInt64ArrayCid:
    case kTypedDataInt64ArrayViewCid:
    case kUnmodifiableTypedDataInt64ArrayViewCid:
    case kExternalTypedDataInt64ArrayCid:
      type = Dart_TypedData_kInt64;
      break;
    case kTypedDataUint64ArrayCid:
    case kTypedDataUint64ArrayViewCid:
    case kUnmodifiableTypedDataUint64ArrayViewCid:
    case kExternalTypedDataUint64ArrayCid:
      type = Dart_TypedData_kUint64;
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat32ArrayViewCid:
    case kUnmodifiableTypedDataFloat32ArrayViewCid:
    case kExternalTypedDataFloat32ArrayCid:
      type = Dart_TypedData_kFloat32;
      break;
    case kTypedDataFloat64ArrayCid:
    case kTypedDataFloat64ArrayViewCid:
    case kUnmodifiableTypedDataFloat64ArrayViewCid:
    case kExternalTypedDataFloat64ArrayCid:
      type = Dart_TypedData_kFloat64;
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataInt32x4ArrayViewCid:
    case kUnmodifiableTypedDataInt32x4ArrayViewCid:
    case kExternalTypedDataInt32x4ArrayCid:
      type = Dart_TypedData_kInt32x4;
      break;
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataFloat32x4ArrayViewCid:
    case kUnmodifiableTypedDataFloat32x4ArrayViewCid:
    case kExternalTypedDataFloat32x4ArrayCid:
      type = Dart_TypedData_kFloat32x4;
      break;
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataFloat64x2ArrayViewCid:
    case kUnmodifiableTypedDataFloat64x2ArrayViewCid:
    case kExternalTypedDataFloat64x2ArrayCid:
      type = Dart_TypedData_kFloat64x2;
      break;
    default:
      type = Dart_TypedData_kInvalid;
      break;
  }
  return type;
}

DART_EXPORT Dart_TypedData_Type Dart_GetTypeOfTypedData(Dart_Handle object) {
  Thread* thread = Thread::Current();
  API_TIMELINE_DURATION(thread);
  TransitionNativeToVM transition(thread);
  intptr_t class_id = Api::ClassId(object);
  if (IsTypedDataClassId(class_id) || IsTypedDataViewClassId(class_id) ||
      IsUnmodifiableTypedDataViewClassId(class_id)) {
    return GetType(class_id);
  }
  return Dart_TypedData_kInvalid;
}

DART_EXPORT Dart_TypedData_Type
Dart_GetTypeOfExternalTypedData(Dart_Handle object) {
  Thread* thread = Thread::Current();
  API_TIMELINE_DURATION(thread);
  TransitionNativeToVM transition(thread);
  intptr_t class_id = Api::ClassId(object);
  if (IsExternalTypedDataClassId(class_id)) {
    return GetType(class_id);
  }
  if (IsTypedDataViewClassId(class_id) ||
      IsUnmodifiableTypedDataViewClassId(class_id)) {
    // Check if data object of the view is external.
    Zone* zone = thread->zone();
    const auto& view_obj = Api::UnwrapTypedDataViewHandle(zone, object);
    ASSERT(!view_obj.IsNull());
    const auto& data_obj = Instance::Handle(zone, view_obj.typed_data());
    if (ExternalTypedData::IsExternalTypedData(data_obj)) {
      return GetType(class_id);
    }
  }
  return Dart_TypedData_kInvalid;
}

static Dart_Handle NewByteData(Thread* thread, intptr_t length) {
  CHECK_LENGTH(length, TypedData::MaxElements(kTypedDataUint8ArrayCid));
  const TypedData& array =
      TypedData::Handle(TypedData::New(kTypedDataUint8ArrayCid, length));
  return Api::NewHandle(thread,
                        TypedDataView::New(kByteDataViewCid, array, 0, length));
}

static Dart_Handle NewTypedData(Thread* thread, intptr_t cid, intptr_t length) {
  CHECK_LENGTH(length, TypedData::MaxElements(cid));
  return Api::NewHandle(thread, TypedData::New(cid, length));
}

static Dart_Handle NewExternalTypedData(Thread* thread,
                                        intptr_t cid,
                                        void* data,
                                        intptr_t length,
                                        void* peer,
                                        intptr_t external_allocation_size,
                                        Dart_HandleFinalizer callback,
                                        bool unmodifiable) {
  CHECK_LENGTH(length, ExternalTypedData::MaxElements(cid));
  Zone* zone = thread->zone();
  intptr_t bytes = length * ExternalTypedData::ElementSizeInBytes(cid);
  Object& result = Object::Handle(
      zone,
      ExternalTypedData::New(cid, reinterpret_cast<uint8_t*>(data), length,
                             thread->heap()->SpaceForExternal(bytes)));
  if (callback != nullptr) {
    AllocateFinalizableHandle(thread, result, peer, external_allocation_size,
                              callback);
  }
  if (unmodifiable) {
    result.SetImmutable();  // Can pass by reference.
    const intptr_t view_cid = cid - kTypedDataCidRemainderExternal +
                              kTypedDataCidRemainderUnmodifiable;
    result = TypedDataView::New(view_cid, ExternalTypedData::Cast(result), 0,
                                length);
  }
  return Api::NewHandle(thread, result.ptr());
}

static Dart_Handle NewExternalByteData(Thread* thread,
                                       void* data,
                                       intptr_t length,
                                       void* peer,
                                       intptr_t external_allocation_size,
                                       Dart_HandleFinalizer callback,
                                       bool unmodifiable) {
  Zone* zone = thread->zone();
  Dart_Handle ext_data = NewExternalTypedData(
      thread, kExternalTypedDataUint8ArrayCid, data, length, peer,
      external_allocation_size, callback, false);
  if (Api::IsError(ext_data)) {
    return ext_data;
  }
  const ExternalTypedData& array =
      Api::UnwrapExternalTypedDataHandle(zone, ext_data);
  if (unmodifiable) {
    array.SetImmutable();  // Can pass by reference.
  }
  return Api::NewHandle(
      thread, TypedDataView::New(unmodifiable ? kUnmodifiableByteDataViewCid
                                              : kByteDataViewCid,
                                 array, 0, length));
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
    case Dart_TypedData_kInt32x4:
      return NewTypedData(T, kTypedDataInt32x4ArrayCid, length);
    case Dart_TypedData_kFloat32x4:
      return NewTypedData(T, kTypedDataFloat32x4ArrayCid, length);
    case Dart_TypedData_kFloat64x2:
      return NewTypedData(T, kTypedDataFloat64x2ArrayCid, length);
    default:
      return Api::NewError("%s expects argument 'type' to be of 'TypedData'",
                           CURRENT_FUNC);
  }
  UNREACHABLE();
  return Api::Null();
}

static Dart_Handle NewExternalTypedDataWithFinalizer(
    Dart_TypedData_Type type,
    void* data,
    intptr_t length,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback,
    bool unmodifiable) {
  DARTSCOPE(Thread::Current());
  if (data == nullptr && length != 0) {
    RETURN_NULL_ERROR(data);
  }
  CHECK_CALLBACK_STATE(T);
  switch (type) {
    case Dart_TypedData_kByteData:
      return NewExternalByteData(T, data, length, peer,
                                 external_allocation_size, callback,
                                 unmodifiable);
    case Dart_TypedData_kInt8:
      return NewExternalTypedData(T, kExternalTypedDataInt8ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kUint8:
      return NewExternalTypedData(T, kExternalTypedDataUint8ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kUint8Clamped:
      return NewExternalTypedData(T, kExternalTypedDataUint8ClampedArrayCid,
                                  data, length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kInt16:
      return NewExternalTypedData(T, kExternalTypedDataInt16ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kUint16:
      return NewExternalTypedData(T, kExternalTypedDataUint16ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kInt32:
      return NewExternalTypedData(T, kExternalTypedDataInt32ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kUint32:
      return NewExternalTypedData(T, kExternalTypedDataUint32ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kInt64:
      return NewExternalTypedData(T, kExternalTypedDataInt64ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kUint64:
      return NewExternalTypedData(T, kExternalTypedDataUint64ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kFloat32:
      return NewExternalTypedData(T, kExternalTypedDataFloat32ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kFloat64:
      return NewExternalTypedData(T, kExternalTypedDataFloat64ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kInt32x4:
      return NewExternalTypedData(T, kExternalTypedDataInt32x4ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kFloat32x4:
      return NewExternalTypedData(T, kExternalTypedDataFloat32x4ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    case Dart_TypedData_kFloat64x2:
      return NewExternalTypedData(T, kExternalTypedDataFloat64x2ArrayCid, data,
                                  length, peer, external_allocation_size,
                                  callback, unmodifiable);
    default:
      return Api::NewError(
          "%s expects argument 'type' to be of"
          " 'external TypedData'",
          CURRENT_FUNC);
  }
  UNREACHABLE();
  return Api::Null();
}

DART_EXPORT Dart_Handle Dart_NewExternalTypedData(Dart_TypedData_Type type,
                                                  void* data,
                                                  intptr_t length) {
  return NewExternalTypedDataWithFinalizer(type, data, length, nullptr, 0,
                                           nullptr, false);
}

DART_EXPORT Dart_Handle
Dart_NewExternalTypedDataWithFinalizer(Dart_TypedData_Type type,
                                       void* data,
                                       intptr_t length,
                                       void* peer,
                                       intptr_t external_allocation_size,
                                       Dart_HandleFinalizer callback) {
  return NewExternalTypedDataWithFinalizer(
      type, data, length, peer, external_allocation_size, callback, false);
}

DART_EXPORT Dart_Handle Dart_NewUnmodifiableExternalTypedDataWithFinalizer(
    Dart_TypedData_Type type,
    const void* data,
    intptr_t length,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback) {
  return NewExternalTypedDataWithFinalizer(
      type, const_cast<void*>(data), length, peer, external_allocation_size,
      callback, true);
}

static ObjectPtr GetByteBufferConstructor(Thread* thread,
                                          const String& class_name,
                                          const String& constructor_name,
                                          intptr_t num_args) {
  const Library& lib = Library::Handle(
      thread->isolate_group()->object_store()->typed_data_library());
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
  if (!IsExternalTypedDataClassId(class_id) &&
      !IsTypedDataViewClassId(class_id) && !IsTypedDataClassId(class_id)) {
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
  return Api::NewHandle(T, result.ptr());
}

// Structure to record acquired typed data for verification purposes.
class AcquiredData {
 public:
  AcquiredData(void* data, intptr_t size_in_bytes, bool copy)
      : size_in_bytes_(size_in_bytes), data_(data), data_copy_(nullptr) {
    if (copy) {
      data_copy_ = malloc(size_in_bytes_);
      memmove(data_copy_, data_, size_in_bytes_);
    }
  }

  // The pointer to hand out via the API.
  void* GetData() const { return data_copy_ != nullptr ? data_copy_ : data_; }

  // Writes back and deletes/zaps, if a copy was made.
  ~AcquiredData() {
    if (data_copy_ != nullptr) {
      memmove(data_, data_copy_, size_in_bytes_);
      memset(data_copy_, kZapReleasedByte, size_in_bytes_);
      free(data_copy_);
    }
  }

 private:
  static constexpr uint8_t kZapReleasedByte = 0xda;
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
  if (!IsExternalTypedDataClassId(class_id) &&
      !IsTypedDataViewClassId(class_id) && !IsTypedDataClassId(class_id) &&
      !IsUnmodifiableTypedDataViewClassId(class_id)) {
    RETURN_TYPE_ERROR(Z, object, 'TypedData');
  }
  if (type == nullptr) {
    RETURN_NULL_ERROR(type);
  }
  if (data == nullptr) {
    RETURN_NULL_ERROR(data);
  }
  if (len == nullptr) {
    RETURN_NULL_ERROR(len);
  }
  // Get the type of typed data object.
  *type = GetType(class_id);
  intptr_t length = 0;
  intptr_t size_in_bytes = 0;
  void* data_tmp = nullptr;
  bool external = false;
  T->IncrementNoSafepointScopeDepth();
  START_NO_CALLBACK_SCOPE(T);
  if (IsExternalTypedDataClassId(class_id)) {
    const ExternalTypedData& obj =
        Api::UnwrapExternalTypedDataHandle(Z, object);
    ASSERT(!obj.IsNull());
    length = obj.Length();
    size_in_bytes = length * ExternalTypedData::ElementSizeInBytes(class_id);
    data_tmp = obj.DataAddr(0);
    external = true;
  } else if (IsTypedDataClassId(class_id)) {
    const TypedData& obj = Api::UnwrapTypedDataHandle(Z, object);
    ASSERT(!obj.IsNull());
    length = obj.Length();
    size_in_bytes = length * TypedData::ElementSizeInBytes(class_id);
    data_tmp = obj.DataAddr(0);
  } else {
    ASSERT(IsTypedDataViewClassId(class_id) ||
           IsUnmodifiableTypedDataViewClassId(class_id));
    const auto& view_obj = Api::UnwrapTypedDataViewHandle(Z, object);
    ASSERT(!view_obj.IsNull());
    Smi& val = Smi::Handle();
    val = view_obj.length();
    length = val.Value();
    size_in_bytes = length * TypedDataView::ElementSizeInBytes(class_id);
    val = view_obj.offset_in_bytes();
    intptr_t offset_in_bytes = val.Value();
    const auto& obj = Instance::Handle(view_obj.typed_data());
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
    {
      NoSafepointScope no_safepoint(T);
      bool sweep_in_progress;
      {
        PageSpace* old_space = T->heap()->old_space();
        MonitorLocker ml(old_space->tasks_lock());
        sweep_in_progress = (old_space->phase() == PageSpace::kSweepingLarge) ||
                            (old_space->phase() == PageSpace::kSweepingRegular);
      }
      if (!sweep_in_progress) {
        if (external) {
          ASSERT(!T->heap()->Contains(reinterpret_cast<uword>(data_tmp)));
        } else {
          ASSERT(T->heap()->Contains(reinterpret_cast<uword>(data_tmp)));
        }
      }
    }
    const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
    WeakTable* table = I->group()->api_state()->acquired_table();
    intptr_t current = table->GetValue(obj.ptr());
    if (current != 0) {
      return Api::NewError("Data was already acquired for this object.");
    }
    // Do not make a copy if the data is external. Some callers expect external
    // data to remain in place, even though the API spec doesn't guarantee it.
    // TODO(koda/asiva): Make final decision and document it.
    AcquiredData* ad = new AcquiredData(data_tmp, size_in_bytes, !external);
    table->SetValue(obj.ptr(), reinterpret_cast<intptr_t>(ad));
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
  if (!IsExternalTypedDataClassId(class_id) &&
      !IsTypedDataViewClassId(class_id) && !IsTypedDataClassId(class_id) &&
      !IsUnmodifiableTypedDataViewClassId(class_id)) {
    RETURN_TYPE_ERROR(Z, object, 'TypedData');
  }
  if (FLAG_verify_acquired_data) {
    const Object& obj = Object::Handle(Z, Api::UnwrapHandle(object));
    WeakTable* table = I->group()->api_state()->acquired_table();
    intptr_t current = table->GetValue(obj.ptr());
    if (current == 0) {
      return Api::NewError("Data was not acquired for this object.");
    }
    AcquiredData* ad = reinterpret_cast<AcquiredData*>(current);
    table->SetValue(obj.ptr(), 0);  // Delete entry from table.
    delete ad;
  }
  T->DecrementNoSafepointScopeDepth();
  END_NO_CALLBACK_SCOPE(T);
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetDataFromByteBuffer(Dart_Handle object) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  TransitionNativeToVM transition(thread);
  intptr_t class_id = Api::ClassId(object);
  if (class_id != kByteBufferCid) {
    RETURN_TYPE_ERROR(zone, object, 'ByteBuffer');
  }
  const Instance& instance = Api::UnwrapInstanceHandle(zone, object);
  ASSERT(!instance.IsNull());
  return Api::NewHandle(thread, ByteBuffer::Data(instance));
}

// ---  Invoking Constructors, Methods, and Field accessors ---

static ObjectPtr ResolveConstructor(const char* current_func,
                                    const Class& cls,
                                    const String& class_name,
                                    const String& constr_name,
                                    int num_args) {
  // The constructor must be present in the interface.
  Function& constructor = Function::Handle();
  if (cls.EnsureIsFinalized(Thread::Current()) == Error::null()) {
    constructor = cls.LookupFunctionAllowPrivate(constr_name);
  }
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
  ErrorPtr error = constructor.VerifyCallEntryPoint();
  if (error != Error::null()) return error;
  return constructor.ptr();
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
  type_obj ^= unchecked_type.ptr();
  if (!type_obj.IsFinalized()) {
    return Api::NewError(
        "%s expects argument 'type' to be a fully resolved type.",
        CURRENT_FUNC);
  }
  Class& cls = Class::Handle(Z, type_obj.type_class());
  CHECK_ERROR_HANDLE(cls.EnsureIsAllocateFinalized(T));

  TypeArguments& type_arguments =
      TypeArguments::Handle(Z, type_obj.GetInstanceTypeArguments(T));

  const String& base_constructor_name = String::Handle(Z, cls.Name());

  // And get the name of the constructor to invoke.
  String& dot_name = String::Handle(Z);
  result = Api::UnwrapHandle(constructor_name);
  if (result.IsNull()) {
    dot_name = Symbols::Dot().ptr();
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
    return Api::NewHandle(T, result.ptr());
  }
  ASSERT(result.IsFunction());
  Function& constructor = Function::Handle(Z);
  constructor ^= result.ptr();

  Instance& new_object = Instance::Handle(Z);
  if (constructor.IsGenerativeConstructor()) {
    CHECK_ERROR_HANDLE(cls.VerifyEntryPoint());
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
        return Api::NewHandle(T, argument.ptr());
      } else {
        return Api::NewError(
            "%s expects arguments[%d] to be an Instance handle.", CURRENT_FUNC,
            i);
      }
    }
    args.SetAt(arg_index++, argument);
  }

  const int kTypeArgsLen = 0;
  Array& args_descriptor_array = Array::Handle(
      Z, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, args.Length()));

  ArgumentsDescriptor args_descriptor(args_descriptor_array);
  ObjectPtr type_error = constructor.DoArgumentTypesMatch(
      args, args_descriptor, type_arguments, Object::empty_type_arguments());
  if (type_error != Error::null()) {
    return Api::NewHandle(T, type_error);
  }

  // Invoke the constructor and return the new object.
  result = DartEntry::InvokeFunction(constructor, args);
  if (result.IsError()) {
    return Api::NewHandle(T, result.ptr());
  }

  if (constructor.IsGenerativeConstructor()) {
    ASSERT(result.IsNull());
  } else {
    ASSERT(result.IsNull() || result.IsInstance());
    new_object ^= result.ptr();
  }
  return Api::NewHandle(T, new_object.ptr());
}

static InstancePtr AllocateObject(Thread* thread, const Class& cls) {
  if (!cls.is_fields_marked_nullable()) {
    // Mark all fields as nullable.
    Zone* zone = thread->zone();
    Class& iterate_cls = Class::Handle(zone, cls.ptr());
    Field& field = Field::Handle(zone);
    Array& fields = Array::Handle(zone);
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    if (!cls.is_fields_marked_nullable()) {
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

  if (!type_obj.IsFinalized()) {
    return Api::NewError(
        "%s expects argument 'type' to be a fully resolved type.",
        CURRENT_FUNC);
  }

  const Class& cls = Class::Handle(Z, type_obj.type_class());
  const TypeArguments& type_arguments =
      TypeArguments::Handle(Z, type_obj.GetInstanceTypeArguments(T));

  CHECK_ERROR_HANDLE(cls.VerifyEntryPoint());
#if defined(DEBUG)
  if (!cls.is_allocated() && (Dart::vm_snapshot_kind() == Snapshot::kFullAOT)) {
    return Api::NewError("Precompilation dropped '%s'", cls.ToCString());
  }
#endif
  CHECK_ERROR_HANDLE(cls.EnsureIsAllocateFinalized(T));
  const Instance& new_obj = Instance::Handle(Z, AllocateObject(T, cls));
  if (!type_arguments.IsNull()) {
    new_obj.SetTypeArguments(type_arguments);
  }
  return Api::NewHandle(T, new_obj.ptr());
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
  if (native_fields == nullptr) {
    RETURN_NULL_ERROR(native_fields);
  }
  const Class& cls = Class::Handle(Z, type_obj.type_class());
  CHECK_ERROR_HANDLE(cls.VerifyEntryPoint());
#if defined(DEBUG)
  if (!cls.is_allocated() && (Dart::vm_snapshot_kind() == Snapshot::kFullAOT)) {
    return Api::NewError("Precompilation dropped '%s'", cls.ToCString());
  }
#endif
  CHECK_ERROR_HANDLE(cls.EnsureIsAllocateFinalized(T));
  if (num_native_fields != cls.num_native_fields()) {
    return Api::NewError(
        "%s: invalid number of native fields %" Pd " passed in, expected %d",
        CURRENT_FUNC, num_native_fields, cls.num_native_fields());
  }
  const Instance& instance = Instance::Handle(Z, AllocateObject(T, cls));
  instance.SetNativeFields(num_native_fields, native_fields);
  return Api::NewHandle(T, instance.ptr());
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
        return Api::NewHandle(thread, arg.ptr());
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
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
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
  AbstractType& type_obj =
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
  TypeArguments& type_arguments = TypeArguments::Handle(Z);
  if (type_obj.IsType()) {
    type_arguments = Type::Cast(type_obj).GetInstanceTypeArguments(T);
  }
  const Function& constructor =
      Function::Handle(Z, cls.LookupFunctionAllowPrivate(dot_name));
  const int kTypeArgsLen = 0;
  const int extra_args = 1;
  if (!constructor.IsNull() && constructor.IsGenerativeConstructor() &&
      constructor.AreValidArgumentCounts(
          kTypeArgsLen, number_of_arguments + extra_args, 0, nullptr)) {
    CHECK_ERROR_HANDLE(constructor.VerifyCallEntryPoint());
    // Create the argument list.
    Dart_Handle result;
    Array& args = Array::Handle(Z);
    result =
        SetupArguments(T, number_of_arguments, arguments, extra_args, &args);
    if (!Api::IsError(result)) {
      args.SetAt(0, instance);

      const int kTypeArgsLen = 0;
      const Array& args_descriptor_array = Array::Handle(
          Z, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, args.Length()));
      ArgumentsDescriptor args_descriptor(args_descriptor_array);
      ObjectPtr type_error = constructor.DoArgumentTypesMatch(
          args, args_descriptor, type_arguments);
      if (type_error != Error::null()) {
        return Api::NewHandle(T, type_error);
      }

      const Object& retval =
          Object::Handle(Z, DartEntry::InvokeFunction(constructor, args));
      if (retval.IsError()) {
        result = Api::NewHandle(T, retval.ptr());
      } else {
        result = Api::NewHandle(T, instance.ptr());
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
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  CHECK_CALLBACK_STATE(T);

  String& function_name =
      String::Handle(Z, Api::UnwrapStringHandle(Z, name).ptr());
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
  // This API does not provide a way to pass named parameters.
  const Array& arg_names = Object::empty_array();
  const bool respect_reflectable = false;
  const bool check_is_entrypoint = FLAG_verify_entry_points;
  if (obj.IsType()) {
    if (!Type::Cast(obj).IsFinalized()) {
      return Api::NewError(
          "%s expects argument 'target' to be a fully resolved type.",
          CURRENT_FUNC);
    }

    const Class& cls = Class::Handle(Z, Type::Cast(obj).type_class());
    if (Library::IsPrivate(function_name)) {
      const Library& lib = Library::Handle(Z, cls.library());
      function_name = lib.PrivateName(function_name);
    }

    // Setup args and check for malformed arguments in the arguments list.
    result = SetupArguments(T, number_of_arguments, arguments, 0, &args);
    if (Api::IsError(result)) {
      return result;
    }
    return Api::NewHandle(
        T, cls.Invoke(function_name, args, arg_names, respect_reflectable,
                      check_is_entrypoint));
  } else if (obj.IsNull() || obj.IsInstance()) {
    // Since we have allocated an object it would mean that the type of the
    // receiver is already resolved and finalized, hence it is not necessary
    // to check here.
    Instance& instance = Instance::Handle(Z);
    instance ^= obj.ptr();

    // Setup args and check for malformed arguments in the arguments list.
    result = SetupArguments(T, number_of_arguments, arguments, 1, &args);
    if (Api::IsError(result)) {
      return result;
    }
    args.SetAt(0, instance);
    return Api::NewHandle(
        T, instance.Invoke(function_name, args, arg_names, respect_reflectable,
                           check_is_entrypoint));
  } else if (obj.IsLibrary()) {
    // Check whether class finalization is needed.
    const Library& lib = Library::Cast(obj);

    // Check that the library is loaded.
    if (!lib.Loaded()) {
      return Api::NewError("%s expects library argument 'target' to be loaded.",
                           CURRENT_FUNC);
    }

    if (Library::IsPrivate(function_name)) {
      function_name = lib.PrivateName(function_name);
    }

    // Setup args and check for malformed arguments in the arguments list.
    result = SetupArguments(T, number_of_arguments, arguments, 0, &args);
    if (Api::IsError(result)) {
      return result;
    }

    return Api::NewHandle(
        T, lib.Invoke(function_name, args, arg_names, respect_reflectable,
                      check_is_entrypoint));
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
  API_TIMELINE_DURATION(T);
  CHECK_CALLBACK_STATE(T);
  const Instance& closure_obj = Api::UnwrapInstanceHandle(Z, closure);
  if (closure_obj.IsNull() || !closure_obj.IsCallable(nullptr)) {
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
  return Api::NewHandle(T, DartEntry::InvokeClosure(T, args));
}

DART_EXPORT Dart_Handle Dart_GetField(Dart_Handle container, Dart_Handle name) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  CHECK_CALLBACK_STATE(T);

  String& field_name =
      String::Handle(Z, Api::UnwrapStringHandle(Z, name).ptr());
  if (field_name.IsNull()) {
    RETURN_TYPE_ERROR(Z, name, String);
  }
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(container));
  const bool throw_nsm_if_absent = true;
  const bool respect_reflectable = false;
  const bool check_is_entrypoint = FLAG_verify_entry_points;

  if (obj.IsType()) {
    if (!Type::Cast(obj).IsFinalized()) {
      return Api::NewError(
          "%s expects argument 'container' to be a fully resolved type.",
          CURRENT_FUNC);
    }
    Class& cls = Class::Handle(Z, Type::Cast(obj).type_class());
    if (Library::IsPrivate(field_name)) {
      const Library& lib = Library::Handle(Z, cls.library());
      field_name = lib.PrivateName(field_name);
    }
    return Api::NewHandle(
        T, cls.InvokeGetter(field_name, throw_nsm_if_absent,
                            respect_reflectable, check_is_entrypoint));
  } else if (obj.IsNull() || obj.IsInstance()) {
    Instance& instance = Instance::Handle(Z);
    instance ^= obj.ptr();
    if (Library::IsPrivate(field_name)) {
      const Class& cls = Class::Handle(Z, instance.clazz());
      const Library& lib = Library::Handle(Z, cls.library());
      field_name = lib.PrivateName(field_name);
    }
    return Api::NewHandle(T,
                          instance.InvokeGetter(field_name, respect_reflectable,
                                                check_is_entrypoint));
  } else if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    // Check that the library is loaded.
    if (!lib.Loaded()) {
      return Api::NewError(
          "%s expects library argument 'container' to be loaded.",
          CURRENT_FUNC);
    }
    if (Library::IsPrivate(field_name)) {
      field_name = lib.PrivateName(field_name);
    }
    return Api::NewHandle(
        T, lib.InvokeGetter(field_name, throw_nsm_if_absent,
                            respect_reflectable, check_is_entrypoint));
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
  API_TIMELINE_DURATION(T);
  CHECK_CALLBACK_STATE(T);

  String& field_name =
      String::Handle(Z, Api::UnwrapStringHandle(Z, name).ptr());
  if (field_name.IsNull()) {
    RETURN_TYPE_ERROR(Z, name, String);
  }

  // Since null is allowed for value, we don't use UnwrapInstanceHandle.
  const Object& value_obj = Object::Handle(Z, Api::UnwrapHandle(value));
  if (!value_obj.IsNull() && !value_obj.IsInstance()) {
    RETURN_TYPE_ERROR(Z, value, Instance);
  }
  Instance& value_instance = Instance::Handle(Z);
  value_instance ^= value_obj.ptr();

  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(container));
  const bool respect_reflectable = false;
  const bool check_is_entrypoint = FLAG_verify_entry_points;

  if (obj.IsType()) {
    if (!Type::Cast(obj).IsFinalized()) {
      return Api::NewError(
          "%s expects argument 'container' to be a fully resolved type.",
          CURRENT_FUNC);
    }

    // To access a static field we may need to use the Field or the
    // setter Function.
    Class& cls = Class::Handle(Z, Type::Cast(obj).type_class());
    if (Library::IsPrivate(field_name)) {
      const Library& lib = Library::Handle(Z, cls.library());
      field_name = lib.PrivateName(field_name);
    }
    return Api::NewHandle(
        T, cls.InvokeSetter(field_name, value_instance, respect_reflectable,
                            check_is_entrypoint));
  } else if (obj.IsNull() || obj.IsInstance()) {
    Instance& instance = Instance::Handle(Z);
    instance ^= obj.ptr();
    if (Library::IsPrivate(field_name)) {
      const Class& cls = Class::Handle(Z, instance.clazz());
      const Library& lib = Library::Handle(Z, cls.library());
      field_name = lib.PrivateName(field_name);
    }
    return Api::NewHandle(
        T, instance.InvokeSetter(field_name, value_instance,
                                 respect_reflectable, check_is_entrypoint));
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

    if (Library::IsPrivate(field_name)) {
      field_name = lib.PrivateName(field_name);
    }
    return Api::NewHandle(
        T, lib.InvokeSetter(field_name, value_instance, respect_reflectable,
                            check_is_entrypoint));
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
  if (::Dart_IsError(exception)) {
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
    InstancePtr raw_exception =
        Api::UnwrapInstanceHandle(zone, exception).ptr();
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
    InstancePtr raw_exception =
        Api::UnwrapInstanceHandle(zone, exception).ptr();
    StackTracePtr raw_stacktrace =
        Api::UnwrapStackTraceHandle(zone, stacktrace).ptr();
    thread->UnwindScopes(thread->top_exit_frame_info());
    saved_exception = &Instance::Handle(raw_exception);
    saved_stacktrace = &StackTrace::Handle(raw_stacktrace);
  }
  Exceptions::ReThrow(thread, *saved_exception, *saved_stacktrace);
  return Api::NewError("Exception was not re thrown, internal error");
}

// --- Native fields and functions ---

DART_EXPORT Dart_Handle Dart_GetNativeInstanceFieldCount(Dart_Handle obj,
                                                         int* count) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  {
    ReusableObjectHandleScope reused_obj_handle(thread);
    const Instance& instance =
        Api::UnwrapInstanceHandle(reused_obj_handle, obj);
    if (!instance.IsNull()) {
      *count = instance.NumNativeFields();
      return Api::Success();
    }
  }
  RETURN_TYPE_ERROR(thread->zone(), obj, Instance);
}

DART_EXPORT Dart_Handle Dart_GetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t* value) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
  bool is_null = false;
  {
    ReusableObjectHandleScope reused_obj_handle(thread);
    const Instance& instance =
        Api::UnwrapInstanceHandle(reused_obj_handle, obj);
    if (!instance.IsNull()) {
      if (instance.IsValidNativeIndex(index)) {
        *value = instance.GetNativeField(index);
        return Api::Success();
      }
    } else {
      is_null = true;
    }
  }
  if (is_null) {
    RETURN_TYPE_ERROR(thread->zone(), obj, Instance);
  }
  return Api::NewError(
      "%s: invalid index %d passed into access native instance field",
      CURRENT_FUNC, index);
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
        "%s: invalid index %d passed into set native instance field",
        CURRENT_FUNC, index);
  }
  instance.SetNativeField(index, value);
  return Api::Success();
}

DART_EXPORT void* Dart_GetNativeIsolateGroupData(Dart_NativeArguments args) {
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
  TransitionNativeToVM transition(arguments->thread());
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  if (arg_values == nullptr) {
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
          return Api::NewArgumentError(
              "%s: expects argument at index %d to be of"
              " type Boolean.",
              CURRENT_FUNC, i);
        }
        break;

      case Dart_NativeArgument_kInt32: {
        int64_t value = 0;
        if (!GetNativeIntegerArgument(arguments, arg_index, &value)) {
          return Api::NewArgumentError(
              "%s: expects argument at index %d to be of"
              " type Integer.",
              CURRENT_FUNC, i);
        }
        if (value < INT32_MIN || value > INT32_MAX) {
          return Api::NewArgumentError(
              "%s: argument value at index %d is out of range", CURRENT_FUNC,
              i);
        }
        native_value->as_int32 = static_cast<int32_t>(value);
        break;
      }

      case Dart_NativeArgument_kUint32: {
        int64_t value = 0;
        if (!GetNativeIntegerArgument(arguments, arg_index, &value)) {
          return Api::NewArgumentError(
              "%s: expects argument at index %d to be of"
              " type Integer.",
              CURRENT_FUNC, i);
        }
        if (value < 0 || value > UINT32_MAX) {
          return Api::NewArgumentError(
              "%s: argument value at index %d is out of range", CURRENT_FUNC,
              i);
        }
        native_value->as_uint32 = static_cast<uint32_t>(value);
        break;
      }

      case Dart_NativeArgument_kInt64: {
        int64_t value = 0;
        if (!GetNativeIntegerArgument(arguments, arg_index, &value)) {
          return Api::NewArgumentError(
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
          return Api::NewArgumentError(
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
          return Api::NewArgumentError(
              "%s: expects argument at index %d to be of"
              " type Double.",
              CURRENT_FUNC, i);
        }
        break;

      case Dart_NativeArgument_kString:
        if (!GetNativeStringArgument(arguments, arg_index,
                                     &(native_value->as_string.dart_str),
                                     &(native_value->as_string.peer))) {
          return Api::NewArgumentError(
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
        ASSERT(arguments->thread()->api_top_scope() != nullptr);
        native_value->as_instance = Api::NewHandle(
            arguments->thread(), arguments->NativeArgAt(arg_index));
        break;
      }

      default:
        return Api::NewArgumentError("%s: invalid argument type %d.",
                                     CURRENT_FUNC, arg_type);
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
  TransitionNativeToVM transition(arguments->thread());
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
  if (field_values == nullptr) {
    RETURN_NULL_ERROR(field_values);
  }
  return GetNativeFieldsOfArgument(arguments, arg_index, num_fields,
                                   field_values, CURRENT_FUNC);
}

DART_EXPORT Dart_Handle Dart_GetNativeReceiver(Dart_NativeArguments args,
                                               intptr_t* value) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  TransitionNativeToVM transition(arguments->thread());
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  if (value == nullptr) {
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
  TransitionNativeToVM transition(arguments->thread());
  Dart_Handle result = Api::Null();
  if (!GetNativeStringArgument(arguments, arg_index, &result, peer)) {
    return Api::NewArgumentError(
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
    return Api::NewArgumentError(
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
    return Api::NewArgumentError(
        "%s: expects argument at %d to be of type Boolean.", CURRENT_FUNC,
        index);
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
    return Api::NewArgumentError(
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
  ASSERT_CALLBACK_STATE(arguments->thread());
  TransitionNativeToVM transition(arguments->thread());
  if ((retval != Api::Null()) && !Api::IsInstance(retval) &&
      !Api::IsError(retval)) {
    // Print the current stack trace to make the problematic caller
    // easier to find.
    const StackTrace& stacktrace = GetCurrentStackTrace(0);
    OS::PrintErr("=== Current Trace:\n%s===\n", stacktrace.ToCString());

    const Object& ret_obj = Object::Handle(Api::UnwrapHandle(retval));
    FATAL(
        "Return value check failed: saw '%s' expected a dart Instance or "
        "an Error.",
        ret_obj.ToCString());
  }
  ASSERT(retval != nullptr);
  Api::SetReturnValue(arguments, retval);
}

DART_EXPORT void Dart_SetWeakHandleReturnValue(Dart_NativeArguments args,
                                               Dart_WeakPersistentHandle rval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  TransitionNativeToVM transition(arguments->thread());
#if defined(DEBUG)
  Isolate* isolate = arguments->thread()->isolate();
  ASSERT(isolate == Isolate::Current());
  ASSERT(isolate->group()->api_state() != nullptr &&
         (isolate->group()->api_state()->IsValidWeakPersistentHandle(rval)));
#endif
  Api::SetWeakHandleReturnValue(arguments, rval);
}

// --- Environment ---
StringPtr Api::GetEnvironmentValue(Thread* thread, const String& name) {
  String& result = String::Handle(CallEnvironmentCallback(thread, name));
  if (result.IsNull()) {
    // Every 'dart:X' library introduces an environment variable
    // 'dart.library.X' that is set to 'true'.
    // We just need to make sure to hide private libraries (starting with
    // "_", and the mirrors library, if it is not supported.

    if (!FLAG_enable_mirrors && name.Equals(Symbols::DartLibraryMirrors())) {
      return Symbols::False().ptr();
    }

    if (!Api::IsFfiEnabled() && name.Equals(Symbols::DartLibraryFfi())) {
      return Symbols::False().ptr();
    }

    if (name.Equals(Symbols::DartVMProduct())) {
#ifdef PRODUCT
      return Symbols::True().ptr();
#else
      return Symbols::False().ptr();
#endif
    }

    if (name.Equals(Symbols::DartDeveloperTimeline())) {
#ifdef SUPPORT_TIMELINE
      return Symbols::True().ptr();
#else
      return Symbols::False().ptr();
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
          return Symbols::True().ptr();
        }
      }
    }
    // Check for default VM provided values. If it was not overridden on the
    // command line.
    if (Symbols::DartIsVM().Equals(name)) {
      return Symbols::True().ptr();
    }
  }
  return result.ptr();
}

StringPtr Api::CallEnvironmentCallback(Thread* thread, const String& name) {
  Isolate* isolate = thread->isolate();
  Dart_EnvironmentCallback callback = isolate->environment_callback();
  if (callback != nullptr) {
    Scope api_scope(thread);
    Dart_Handle api_name = Api::NewHandle(thread, name.ptr());
    Dart_Handle api_response;
    {
      TransitionVMToNative transition(thread);
      api_response = callback(api_name);
    }
    const Object& response =
        Object::Handle(thread->zone(), Api::UnwrapHandle(api_response));
    if (response.IsString()) {
      return String::Cast(response).ptr();
    } else if (response.IsError()) {
      Exceptions::ThrowArgumentError(
          String::Handle(String::New(Error::Cast(response).ToErrorCString())));
    } else if (!response.IsNull()) {
      // At this point everything except null are invalid environment values.
      Exceptions::ThrowArgumentError(
          String::Handle(String::New("Illegal environment value")));
    }
  }
  return String::null();
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
  TransitionNativeToVM transition(arguments->thread());
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  ASSERT_CALLBACK_STATE(arguments->thread());
  arguments->SetReturn(Bool::Get(retval));
}

DART_EXPORT void Dart_SetIntegerReturnValue(Dart_NativeArguments args,
                                            int64_t retval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  TransitionNativeToVM transition(arguments->thread());
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  ASSERT_CALLBACK_STATE(arguments->thread());
  if (Smi::IsValid(retval)) {
    Api::SetSmiReturnValue(arguments, static_cast<intptr_t>(retval));
  } else {
    // Slow path for Mints.
    Api::SetIntegerReturnValue(arguments, retval);
  }
}

DART_EXPORT void Dart_SetDoubleReturnValue(Dart_NativeArguments args,
                                           double retval) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  ASSERT(arguments->thread()->isolate() == Isolate::Current());
  ASSERT_CALLBACK_STATE(arguments->thread());
  TransitionNativeToVM transition(arguments->thread());
  Api::SetDoubleReturnValue(arguments, retval);
}

// --- Scripts and Libraries ---

DART_EXPORT Dart_Handle
Dart_SetLibraryTagHandler(Dart_LibraryTagHandler handler) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  isolate->group()->set_library_tag_handler(handler);
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_DefaultCanonicalizeUrl(Dart_Handle base_url,
                                                    Dart_Handle url) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
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

DART_EXPORT Dart_Handle
Dart_SetDeferredLoadHandler(Dart_DeferredLoadHandler handler) {
  Isolate* isolate = Isolate::Current();
  CHECK_ISOLATE(isolate);
  isolate->group()->set_deferred_load_handler(handler);
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_LoadScriptFromKernel(const uint8_t* buffer,
                                                  intptr_t buffer_size) {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("%s: Cannot compile on an AOT runtime.", CURRENT_FUNC);
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  StackZone zone(T);
  IsolateGroup* IG = T->isolate_group();

  Library& library = Library::Handle(Z, IG->object_store()->root_library());
  if (!library.IsNull()) {
    const String& library_url = String::Handle(Z, library.url());
    return Api::NewError("%s: A script has already been loaded from '%s'.",
                         CURRENT_FUNC, library_url.ToCString());
  }
  CHECK_CALLBACK_STATE(T);

  // NOTE: We do not attach a finalizer for this object, because the embedder
  // will free it once the isolate group has shutdown.
  const auto& td = ExternalTypedData::Handle(ExternalTypedData::New(
      kExternalTypedDataUint8ArrayCid, const_cast<uint8_t*>(buffer),
      buffer_size, Heap::kOld));

  const char* error = nullptr;
  std::unique_ptr<kernel::Program> program =
      kernel::Program::ReadFromTypedData(td, &error);
  if (program == nullptr) {
    return Api::NewError("Can't load Kernel binary: %s.", error);
  }
  const Object& tmp = kernel::KernelLoader::LoadEntireProgram(program.get());
  program.reset();

  if (tmp.IsError()) {
    return Api::NewHandle(T, tmp.ptr());
  }

  IG->source()->script_kernel_size = buffer_size;
  IG->source()->script_kernel_buffer = buffer;

  // TODO(32618): Setting root library based on whether it has 'main' or not
  // is not correct because main can be in the exported namespace of a library
  // or it could be a getter.
  if (tmp.IsNull()) {
    return Api::NewError(
        "Invoked Dart programs must have a 'main' function defined:\n"
        "https://dart.dev/guides/language/"
        "language-tour#a-basic-dart-program");
  }
  library ^= tmp.ptr();
  IG->object_store()->set_root_library(library);
  return Api::NewHandle(T, library.ptr());
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

DART_EXPORT Dart_Handle Dart_RootLibrary() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  TransitionNativeToVM transition(thread);
  return Api::NewHandle(thread,
                        isolate->group()->object_store()->root_library());
}

DART_EXPORT Dart_Handle Dart_SetRootLibrary(Dart_Handle library) {
  DARTSCOPE(Thread::Current());
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(library));
  if (obj.IsNull() || obj.IsLibrary()) {
    Library& lib = Library::Handle(Z);
    lib ^= obj.ptr();
    T->isolate_group()->object_store()->set_root_library(lib);
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
  cls.EnsureDeclarationLoaded();
  CHECK_ERROR_HANDLE(cls.VerifyEntryPoint());
  return Api::NewHandle(T, cls.RareType());
}

static Dart_Handle GetTypeCommon(Dart_Handle library,
                                 Dart_Handle class_name,
                                 intptr_t number_of_type_arguments,
                                 Dart_Handle* type_arguments,
                                 Nullability nullability) {
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
  cls.EnsureDeclarationLoaded();
  CHECK_ERROR_HANDLE(cls.VerifyEntryPoint());

  Type& type = Type::Handle();
  if (cls.NumTypeArguments() == 0) {
    if (number_of_type_arguments != 0) {
      return Api::NewError(
          "Invalid number of type arguments specified, "
          "got %" Pd " expected 0",
          number_of_type_arguments);
    }
    type ^= Type::NewNonParameterizedType(cls);
    type ^= type.ToNullability(nullability, Heap::kOld);
  } else {
    intptr_t num_expected_type_arguments = cls.NumTypeParameters();
    TypeArguments& type_args_obj = TypeArguments::Handle();
    if (number_of_type_arguments > 0) {
      if (type_arguments == nullptr) {
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
      type_args_obj = TypeArguments::New(num_expected_type_arguments);
      AbstractType& type_arg = AbstractType::Handle();
      for (intptr_t i = 0; i < number_of_type_arguments; i++) {
        type_arg ^= array.At(i);
        type_args_obj.SetTypeAt(i, type_arg);
      }
    }

    // Construct the type object, canonicalize it and return.
    type ^= Type::New(cls, type_args_obj, nullability);
  }
  type ^= ClassFinalizer::FinalizeType(type);
  return Api::NewHandle(T, type.ptr());
}

DART_EXPORT Dart_Handle Dart_GetType(Dart_Handle library,
                                     Dart_Handle class_name,
                                     intptr_t number_of_type_arguments,
                                     Dart_Handle* type_arguments) {
  if (IsolateGroup::Current()->null_safety()) {
    return Api::NewError(
        "Cannot use legacy types with --sound-null-safety enabled. "
        "Use Dart_GetNullableType or Dart_GetNonNullableType instead.");
  }
  return GetTypeCommon(library, class_name, number_of_type_arguments,
                       type_arguments, Nullability::kLegacy);
}

DART_EXPORT Dart_Handle Dart_GetNullableType(Dart_Handle library,
                                             Dart_Handle class_name,
                                             intptr_t number_of_type_arguments,
                                             Dart_Handle* type_arguments) {
  return GetTypeCommon(library, class_name, number_of_type_arguments,
                       type_arguments, Nullability::kNullable);
}

DART_EXPORT Dart_Handle
Dart_GetNonNullableType(Dart_Handle library,
                        Dart_Handle class_name,
                        intptr_t number_of_type_arguments,
                        Dart_Handle* type_arguments) {
  return GetTypeCommon(library, class_name, number_of_type_arguments,
                       type_arguments, Nullability::kNonNullable);
}

static Dart_Handle TypeToHelper(Dart_Handle type, Nullability nullability) {
  DARTSCOPE(Thread::Current());
  const Type& ty = Api::UnwrapTypeHandle(Z, type);
  if (ty.IsNull()) {
    RETURN_TYPE_ERROR(Z, type, Type);
  }
  if (ty.nullability() == nullability) {
    return type;
  }
  return Api::NewHandle(T, ty.ToNullability(nullability, Heap::kOld));
}

DART_EXPORT Dart_Handle Dart_TypeToNullableType(Dart_Handle type) {
  return TypeToHelper(type, Nullability::kNullable);
}

DART_EXPORT Dart_Handle Dart_TypeToNonNullableType(Dart_Handle type) {
  return TypeToHelper(type, Nullability::kNonNullable);
}

static Dart_Handle IsOfTypeNullabilityHelper(Dart_Handle type,
                                             Nullability nullability,
                                             bool* result) {
  DARTSCOPE(Thread::Current());
  const Type& ty = Api::UnwrapTypeHandle(Z, type);
  if (ty.IsNull()) {
    *result = false;
    RETURN_TYPE_ERROR(Z, type, Type);
  }
  *result = (ty.nullability() == nullability);
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_IsNullableType(Dart_Handle type, bool* result) {
  return IsOfTypeNullabilityHelper(type, Nullability::kNullable, result);
}

DART_EXPORT Dart_Handle Dart_IsNonNullableType(Dart_Handle type, bool* result) {
  return IsOfTypeNullabilityHelper(type, Nullability::kNonNullable, result);
}

DART_EXPORT Dart_Handle Dart_IsLegacyType(Dart_Handle type, bool* result) {
  return IsOfTypeNullabilityHelper(type, Nullability::kLegacy, result);
}

DART_EXPORT Dart_Handle Dart_LibraryUrl(Dart_Handle library) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  const String& url = String::Handle(Z, lib.url());
  ASSERT(!url.IsNull());
  return Api::NewHandle(T, url.ptr());
}

DART_EXPORT Dart_Handle Dart_LibraryResolvedUrl(Dart_Handle library) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  const Class& toplevel = Class::Handle(lib.toplevel_class());
  ASSERT(!toplevel.IsNull());
  const Script& script = Script::Handle(toplevel.script());
  ASSERT(!script.IsNull());
  const String& url = String::Handle(script.resolved_url());
  ASSERT(!url.IsNull());
  return Api::NewHandle(T, url.ptr());
}

DART_EXPORT Dart_Handle Dart_GetLoadedLibraries() {
  DARTSCOPE(Thread::Current());
  auto IG = T->isolate_group();

  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(Z, IG->object_store()->libraries());
  int num_libs = libs.Length();

  // Create new list and populate with the loaded libraries.
  Library& lib = Library::Handle();
  const Array& library_list = Array::Handle(Z, Array::New(num_libs));
  for (int i = 0; i < num_libs; i++) {
    lib ^= libs.At(i);
    ASSERT(!lib.IsNull());
    library_list.SetAt(i, lib);
  }
  return Api::NewHandle(T, library_list.ptr());
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
    return Api::NewHandle(T, library.ptr());
  }
}

DART_EXPORT Dart_Handle Dart_LibraryHandleError(Dart_Handle library_in,
                                                Dart_Handle error_in) {
  DARTSCOPE(Thread::Current());

  const Library& lib = Api::UnwrapLibraryHandle(Z, library_in);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library_in, Library);
  }
  const Instance& err = Api::UnwrapInstanceHandle(Z, error_in);
  if (err.IsNull()) {
    RETURN_TYPE_ERROR(Z, error_in, Instance);
  }
  CHECK_CALLBACK_STATE(T);

  return error_in;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static Dart_Handle LoadLibrary(Thread* T, const ExternalTypedData& td) {
  const char* error = nullptr;
  std::unique_ptr<kernel::Program> program =
      kernel::Program::ReadFromTypedData(td, &error);
  if (program == nullptr) {
    return Api::NewError("Can't load Kernel binary: %s.", error);
  }
  const Object& result =
      kernel::KernelLoader::LoadEntireProgram(program.get(), false);
  program.reset();

  IsolateGroupSource* source = Isolate::Current()->source();
  source->add_loaded_blob(Z, td);

  return Api::NewHandle(T, result.ptr());
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

DART_EXPORT Dart_Handle Dart_LoadLibraryFromKernel(const uint8_t* buffer,
                                                   intptr_t buffer_size) {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("%s: Cannot compile on an AOT runtime.", CURRENT_FUNC);
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  StackZone zone(T);

  CHECK_CALLBACK_STATE(T);

  // NOTE: We do not attach a finalizer for this object, because the embedder
  // will/should free it once the isolate group has shutdown.
  const auto& td = ExternalTypedData::Handle(ExternalTypedData::New(
      kExternalTypedDataUint8ArrayCid, const_cast<uint8_t*>(buffer),
      buffer_size, Heap::kOld));
  return LoadLibrary(T, td);
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

DART_EXPORT Dart_Handle Dart_LoadLibrary(Dart_Handle kernel_buffer) {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("%s: Cannot compile on an AOT runtime.", CURRENT_FUNC);
#else
  DARTSCOPE(Thread::Current());
  const ExternalTypedData& td =
      Api::UnwrapExternalTypedDataHandle(Z, kernel_buffer);
  if (td.IsNull()) {
    RETURN_TYPE_ERROR(Z, kernel_buffer, ExternalTypedData);
  }
  return LoadLibrary(T, td);
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

// Finalizes classes and invokes Dart core library function that completes
// futures of loadLibrary calls (deferred library loading).
DART_EXPORT Dart_Handle Dart_FinalizeLoading(bool complete_futures) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  Isolate* I = T->isolate();
  CHECK_CALLBACK_STATE(T);

  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(T);
  if (Api::IsError(state)) {
    return state;
  }

#if !defined(PRODUCT)
  // Now that the newly loaded classes are finalized, notify the debugger
  // that new code has been loaded. If there are latent breakpoints in
  // the new code, the debugger convert them to unresolved source breakpoints.
  // The code that completes the futures (invoked below) may call into the
  // newly loaded code and trigger one of these breakpoints.
  I->debugger()->NotifyDoneLoading();
#endif

  // After having loaded all the code, we can let the GC set reasonable limits
  // for the heap growth.
  // If this is an auxiliary isolate inside a larger isolate group, we will not
  // re-initialize the growth policy.
  if (I->group()->ContainsOnlyOneIsolate()) {
    I->group()->heap()->old_space()->EvaluateAfterLoading();
  }

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

  return Api::Success();
}

static Dart_Handle DeferredLoadComplete(intptr_t loading_unit_id,
                                        bool error,
                                        const uint8_t* snapshot_data,
                                        const uint8_t* snapshot_instructions,
                                        const char* error_message,
                                        bool transient_error) {
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  auto IG = T->isolate_group();
  CHECK_CALLBACK_STATE(T);

  const Array& loading_units =
      Array::Handle(IG->object_store()->loading_units());
  if (loading_units.IsNull() || (loading_unit_id < LoadingUnit::kRootId) ||
      (loading_unit_id >= loading_units.Length())) {
    return Api::NewError("Invalid loading unit");
  }
  LoadingUnit& unit = LoadingUnit::Handle();
  unit ^= loading_units.At(loading_unit_id);
  if (unit.loaded()) {
    return Api::NewError("Unit already loaded");
  }

  if (error) {
    CHECK_NULL(error_message);
    return Api::NewHandle(
        T, unit.CompleteLoad(String::Handle(String::New(error_message)),
                             transient_error));
  } else {
#if defined(SUPPORT_TIMELINE)
    TimelineBeginEndScope tbes(T, Timeline::GetIsolateStream(),
                               "ReadUnitSnapshot");
#endif  // defined(SUPPORT_TIMELINE)
    const Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_data);
    if (snapshot == nullptr) {
      return Api::NewError("Invalid snapshot");
    }
    if (!IsSnapshotCompatible(Dart::vm_snapshot_kind(), snapshot->kind())) {
      const String& message = String::Handle(String::NewFormatted(
          "Incompatible snapshot kinds: vm '%s', isolate '%s'",
          Snapshot::KindToCString(Dart::vm_snapshot_kind()),
          Snapshot::KindToCString(snapshot->kind())));
      return Api::NewHandle(T, ApiError::New(message));
    }

    FullSnapshotReader reader(snapshot, snapshot_instructions, T);
    const Error& error = Error::Handle(reader.ReadUnitSnapshot(unit));
    if (!error.IsNull()) {
      return Api::NewHandle(T, error.ptr());
    }

    return Api::NewHandle(T, unit.CompleteLoad(String::Handle(), false));
  }
}

DART_EXPORT Dart_Handle
Dart_DeferredLoadComplete(intptr_t loading_unit_id,
                          const uint8_t* snapshot_data,
                          const uint8_t* snapshot_instructions) {
  return DeferredLoadComplete(loading_unit_id, false, snapshot_data,
                              snapshot_instructions, nullptr, false);
}

DART_EXPORT Dart_Handle
Dart_DeferredLoadCompleteError(intptr_t loading_unit_id,
                               const char* error_message,
                               bool transient) {
  return DeferredLoadComplete(loading_unit_id, true, nullptr, nullptr,
                              error_message, transient);
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
  if (resolver == nullptr) {
    RETURN_NULL_ERROR(resolver);
  }
  *resolver = nullptr;
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
  if (resolver == nullptr) {
    RETURN_NULL_ERROR(resolver);
  }
  *resolver = nullptr;
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  *resolver = lib.native_entry_symbol_resolver();
  return Api::Success();
}

DART_EXPORT Dart_Handle
Dart_SetFfiNativeResolver(Dart_Handle library,
                          Dart_FfiNativeResolver resolver) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  lib.set_ffi_native_resolver(resolver);
  return Api::Success();
}

// --- Peer support ---

DART_EXPORT Dart_Handle Dart_GetPeer(Dart_Handle object, void** peer) {
  if (peer == nullptr) {
    RETURN_NULL_ERROR(peer);
  }
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
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
    ObjectPtr raw_obj = obj.ptr();
    *peer = thread->heap()->GetPeer(raw_obj);
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_SetPeer(Dart_Handle object, void* peer) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  TransitionNativeToVM transition(thread);
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
    ObjectPtr raw_obj = obj.ptr();
    thread->heap()->SetPeer(raw_obj, peer);
  }
  return Api::Success();
}

// --- Dart Front-End (Kernel) support ---

DART_EXPORT bool Dart_IsKernelIsolate(Dart_Isolate isolate) {
#if defined(DART_PRECOMPILED_RUNTIME)
  return false;
#else
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  return KernelIsolate::IsKernelIsolate(iso);
#endif
}

DART_EXPORT bool Dart_KernelIsolateIsRunning() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return false;
#else
  return KernelIsolate::IsRunning();
#endif
}

DART_EXPORT Dart_Port Dart_KernelPort() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return false;
#else
  return KernelIsolate::KernelPort();
#endif
}

DART_EXPORT Dart_KernelCompilationResult
Dart_CompileToKernel(const char* script_uri,
                     const uint8_t* platform_kernel,
                     intptr_t platform_kernel_size,
                     bool incremental_compile,
                     bool for_snapshot,
                     bool embed_sources,
                     const char* package_config,
                     Dart_KernelCompilationVerbosityLevel verbosity) {
  API_TIMELINE_DURATION(Thread::Current());

  Dart_KernelCompilationResult result = {};
#if defined(DART_PRECOMPILED_RUNTIME)
  result.status = Dart_KernelCompilationStatus_Unknown;
  result.error = Utils::StrDup("Dart_CompileToKernel is unsupported.");
#else
  result = KernelIsolate::CompileToKernel(
      script_uri, platform_kernel, platform_kernel_size, 0, nullptr,
      incremental_compile, for_snapshot, embed_sources, package_config, nullptr,
      nullptr, verbosity);
  if (incremental_compile) {
    Dart_KernelCompilationResult ack_result =
        result.status == Dart_KernelCompilationStatus_Ok ?
            KernelIsolate::AcceptCompilation():
            KernelIsolate::RejectCompilation();
    if (ack_result.status != Dart_KernelCompilationStatus_Ok) {
      FATAL(
          "An error occurred in the CFE while acking the most recent"
          " compilation results: %s",
          ack_result.error);
    }
  }
#endif
  return result;
}

DART_EXPORT Dart_KernelCompilationResult Dart_KernelListDependencies() {
  Dart_KernelCompilationResult result = {};
#if defined(DART_PRECOMPILED_RUNTIME)
  result.status = Dart_KernelCompilationStatus_Unknown;
  result.error = Utils::StrDup("Dart_KernelListDependencies is unsupported.");
#else
  result = KernelIsolate::ListDependencies();
#endif
  return result;
}

DART_EXPORT void Dart_SetDartLibrarySourcesKernel(
    const uint8_t* platform_kernel,
    const intptr_t platform_kernel_size) {
#if !defined(PRODUCT)
  Service::SetDartLibraryKernelForSources(platform_kernel,
                                          platform_kernel_size);
#endif
}

DART_EXPORT bool Dart_DetectNullSafety(const char* script_uri,
                                       const char* package_config,
                                       const char* original_working_directory,
                                       const uint8_t* snapshot_data,
                                       const uint8_t* snapshot_instructions,
                                       const uint8_t* kernel_buffer,
                                       intptr_t kernel_buffer_size) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  // If snapshot is an app-jit snapshot we will figure out the mode by
  // sniffing the feature string in the snapshot.
  if (snapshot_data != nullptr) {
    // Read the snapshot and check for null safety option.
    const Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_data);
    if (!Snapshot::IsAgnosticToNullSafety(snapshot->kind())) {
      return SnapshotHeaderReader::NullSafetyFromSnapshot(snapshot);
    }
  }
  // If kernel_buffer is specified, it could be a self contained
  // kernel file or the kernel file of the application,
  // figure out the null safety mode by sniffing the kernel file.
  if (kernel_buffer != nullptr) {
    const auto null_safety =
        kernel::Program::DetectNullSafety(kernel_buffer, kernel_buffer_size);
    if (null_safety != NNBDCompiledMode::kInvalid) {
      return null_safety == NNBDCompiledMode::kStrong;
    }
  }
#endif
  return FLAG_sound_null_safety;
}

// --- Service support ---

DART_EXPORT bool Dart_IsServiceIsolate(Dart_Isolate isolate) {
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  return ServiceIsolate::IsServiceIsolate(iso);
}

DART_EXPORT void Dart_RegisterIsolateServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
#if !defined(PRODUCT)
  Service::RegisterIsolateEmbedderCallback(name, callback, user_data);
#endif
}

DART_EXPORT void Dart_RegisterRootServiceRequestCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
#if !defined(PRODUCT)
  Service::RegisterRootEmbedderCallback(name, callback, user_data);
#endif
}

DART_EXPORT void Dart_SetEmbedderInformationCallback(
    Dart_EmbedderInformationCallback callback) {
#if !defined(PRODUCT)
  Service::SetEmbedderInformationCallback(callback);
#endif
}

DART_EXPORT char* Dart_SetServiceStreamCallbacks(
    Dart_ServiceStreamListenCallback listen_callback,
    Dart_ServiceStreamCancelCallback cancel_callback) {
#if defined(PRODUCT)
  return nullptr;
#else
  if (listen_callback != nullptr) {
    if (Service::stream_listen_callback() != nullptr) {
      return Utils::StrDup(
          "Dart_SetServiceStreamCallbacks "
          "permits only one listen callback to be registered, please "
          "remove the existing callback and then add this callback");
    }
  } else {
    if (Service::stream_listen_callback() == nullptr) {
      return Utils::StrDup(
          "Dart_SetServiceStreamCallbacks "
          "expects 'listen_callback' to be present in the callback set.");
    }
  }
  if (cancel_callback != nullptr) {
    if (Service::stream_cancel_callback() != nullptr) {
      return Utils::StrDup(
          "Dart_SetServiceStreamCallbacks "
          "permits only one cancel callback to be registered, please "
          "remove the existing callback and then add this callback");
    }
  } else {
    if (Service::stream_cancel_callback() == nullptr) {
      return Utils::StrDup(
          "Dart_SetServiceStreamCallbacks "
          "expects 'cancel_callback' to be present in the callback set.");
    }
  }
  Service::SetEmbedderStreamCallbacks(listen_callback, cancel_callback);
  return nullptr;
#endif
}

DART_EXPORT char* Dart_ServiceSendDataEvent(const char* stream_id,
                                            const char* event_kind,
                                            const uint8_t* bytes,
                                            intptr_t bytes_length) {
#if !defined(PRODUCT)
  if (stream_id == nullptr) {
    return Utils::StrDup(
        "Dart_ServiceSendDataEvent expects argument 'stream_id' to be "
        "non-null.");
  }
  if (event_kind == nullptr) {
    return Utils::StrDup(
        "Dart_ServiceSendDataEvent expects argument 'event_kind' to be "
        "non-null.");
  }
  if (bytes == nullptr) {
    return Utils::StrDup(
        "Dart_ServiceSendDataEvent expects argument 'bytes' to be non-null.");
  }
  if (bytes_length < 0) {
    return Utils::StrDup(
        "Dart_ServiceSendDataEvent expects argument 'bytes_length' to be >= "
        "0.");
  }
  Service::SendEmbedderEvent(Isolate::Current(),  // May be nullptr
                             stream_id, event_kind, bytes, bytes_length);
#endif
  return nullptr;
}

DART_EXPORT void Dart_SetDwarfStackTraceFootnoteCallback(
    Dart_DwarfStackTraceFootnoteCallback callback) {
  Dart::set_dwarf_stacktrace_footnote_callback(callback);
}

DART_EXPORT char* Dart_SetFileModifiedCallback(
    Dart_FileModifiedCallback file_modified_callback) {
#if !defined(PRODUCT)
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (file_modified_callback != nullptr) {
    if (IsolateGroupReloadContext::file_modified_callback() != nullptr) {
      return Utils::StrDup(
          "Dart_SetFileModifiedCallback permits only one callback to be"
          " registered, please remove the existing callback and then add"
          " this callback");
    }
  } else {
    if (IsolateGroupReloadContext::file_modified_callback() == nullptr) {
      return Utils::StrDup(
          "Dart_SetFileModifiedCallback expects 'file_modified_callback' to"
          " be set before it is cleared.");
    }
  }
  IsolateGroupReloadContext::SetFileModifiedCallback(file_modified_callback);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // !defined(PRODUCT)
  return nullptr;
}

DART_EXPORT bool Dart_IsReloading() {
#if defined(PRODUCT) || defined(DART_PRECOMPILED_RUNTIME)
  return false;
#else
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CHECK_ISOLATE(isolate);
  return isolate->group()->IsReloading();
#endif
}

DART_EXPORT bool Dart_SetEnabledTimelineCategory(const char* categories) {
#if defined(SUPPORT_TIMELINE)
  bool result = false;
  if (categories != nullptr) {
    char* carray = Utils::SCreate("[%s]", categories);
    result = Service::EnableTimelineStreams(carray);
    free(carray);
  }
  return result;
#else
  return false;
#endif
}

DART_EXPORT int64_t Dart_TimelineGetMicros() {
  return OS::GetCurrentMonotonicMicros();
}

DART_EXPORT int64_t Dart_TimelineGetTicks() {
  return OS::GetCurrentMonotonicTicks();
}

DART_EXPORT int64_t Dart_TimelineGetTicksFrequency() {
  return OS::GetCurrentMonotonicFrequency();
}

DART_EXPORT void Dart_TimelineEvent(const char* label,
                                    int64_t timestamp0,
                                    int64_t timestamp1_or_id,
                                    Dart_Timeline_Event_Type type,
                                    intptr_t argument_count,
                                    const char** argument_names,
                                    const char** argument_values) {
  Dart_RecordTimelineEvent(label, timestamp0, timestamp1_or_id,
                           /*flow_id_count=*/0, /*flow_ids=*/nullptr, type,
                           argument_count, argument_names, argument_values);
}

DART_EXPORT void Dart_RecordTimelineEvent(const char* label,
                                          int64_t timestamp0,
                                          int64_t timestamp1_or_id,
                                          intptr_t flow_id_count,
                                          const int64_t* flow_ids,
                                          Dart_Timeline_Event_Type type,
                                          intptr_t argument_count,
                                          const char** argument_names,
                                          const char** argument_values) {
#if defined(SUPPORT_TIMELINE)
  if (type < Dart_Timeline_Event_Begin) {
    return;
  }
  if (type > Dart_Timeline_Event_Flow_End) {
    return;
  }
  if (!Dart::SetActiveApiCall()) {
    return;
  }
  TimelineStream* stream = Timeline::GetEmbedderStream();
  ASSERT(stream != nullptr);
  TimelineEvent* event = stream->StartEvent();
  if (event != nullptr) {
    switch (type) {
      case Dart_Timeline_Event_Begin:
        event->Begin(label, timestamp1_or_id, timestamp0);
        break;
      case Dart_Timeline_Event_End:
        event->End(label, timestamp1_or_id, timestamp0);
        break;
      case Dart_Timeline_Event_Instant:
        event->Instant(label, timestamp0);
        break;
      case Dart_Timeline_Event_Duration:
        event->Duration(label, timestamp0, timestamp1_or_id);
        break;
      case Dart_Timeline_Event_Async_Begin:
        event->AsyncBegin(label, timestamp1_or_id, timestamp0);
        break;
      case Dart_Timeline_Event_Async_End:
        event->AsyncEnd(label, timestamp1_or_id, timestamp0);
        break;
      case Dart_Timeline_Event_Async_Instant:
        event->AsyncInstant(label, timestamp1_or_id, timestamp0);
        break;
      case Dart_Timeline_Event_Counter:
        event->Counter(label, timestamp0);
        break;
      case Dart_Timeline_Event_Flow_Begin:
        event->FlowBegin(label, timestamp1_or_id, timestamp0);
        break;
      case Dart_Timeline_Event_Flow_Step:
        event->FlowStep(label, timestamp1_or_id, timestamp0);
        break;
      case Dart_Timeline_Event_Flow_End:
        event->FlowEnd(label, timestamp1_or_id, timestamp0);
        break;
      default:
        FATAL("Unknown Dart_Timeline_Event_Type");
    }
    if (flow_id_count > 0 && flow_ids != nullptr) {
      std::unique_ptr<const int64_t[]> flow_ids_copy;
      int64_t* flow_ids_internal = new int64_t[flow_id_count];
      for (intptr_t i = 0; i < flow_id_count; ++i) {
        flow_ids_internal[i] = flow_ids[i];
      }
      flow_ids_copy = std::unique_ptr<const int64_t[]>(flow_ids_internal);
      event->SetFlowIds(flow_id_count, flow_ids_copy);
    }
    event->SetNumArguments(argument_count);
    for (intptr_t i = 0; i < argument_count; i++) {
      event->CopyArgument(i, argument_names[i], argument_values[i]);
    }
    event->Complete();
  }
  Dart::ResetActiveApiCall();
#endif
}

DART_EXPORT void Dart_SetTimelineRecorderCallback(
    Dart_TimelineRecorderCallback callback) {
#if defined(SUPPORT_TIMELINE)
  Timeline::set_callback(callback);
#endif
}

DART_EXPORT void Dart_SetThreadName(const char* name) {
  OSThread* thread = OSThread::Current();
  if (thread == nullptr) {
    // VM is shutting down.
    return;
  }
  thread->SetName(name);
}

DART_EXPORT Dart_Handle Dart_SortClasses() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("%s: Cannot compile on an AOT runtime.", CURRENT_FUNC);
#else
  DARTSCOPE(Thread::Current());

  // Prevent background compiler from running while code is being cleared and
  // adding new code.
  NoBackgroundCompilerScope no_bg_compiler(T);

  // We don't have mechanisms to change class-ids that are embedded in code and
  // ICData.
  ClassFinalizer::ClearAllCode();
  // Make sure that ICData etc. that have been cleared are also removed from
  // the heap so that they are not found by the heap verifier.
  IsolateGroup::Current()->heap()->CollectAllGarbage();
  ClassFinalizer::SortClasses();
  return Api::Success();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

DART_EXPORT Dart_Handle Dart_Precompile() {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_BEGIN_END(T);
  if (!FLAG_precompiled_mode) {
    return Api::NewError("Flag --precompilation was not specified.");
  }
  Dart_Handle result = Api::CheckAndFinalizePendingClasses(T);
  if (Api::IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(T);
  CompilerState state(Thread::Current(), /*is_aot=*/true,
                      /*is_optimizing=*/true);
  CHECK_ERROR_HANDLE(Precompiler::CompileAll());
  return Api::Success();
#endif
}

// Used for StreamingWriteStream/BlobImageWriter sizes for ELF and blobs.
#if !defined(TARGET_ARCH_IA32) && defined(DART_PRECOMPILER)
static constexpr intptr_t kAssemblyInitialSize = 512 * KB;
static constexpr intptr_t kInitialSize = 2 * MB;
static constexpr intptr_t kInitialDebugSize = 1 * MB;

static void CreateAppAOTSnapshot(
    Dart_StreamingWriteCallback callback,
    void* callback_data,
    bool strip,
    bool as_elf,
    void* debug_callback_data,
    GrowableArray<LoadingUnitSerializationData*>* units,
    LoadingUnitSerializationData* unit,
    uint32_t program_hash) {
  Thread* T = Thread::Current();

  NOT_IN_PRODUCT(TimelineBeginEndScope tbes2(T, Timeline::GetIsolateStream(),
                                             "WriteAppAOTSnapshot"));

  ZoneWriteStream vm_snapshot_data(T->zone(), FullSnapshotWriter::kInitialSize);
  ZoneWriteStream vm_snapshot_instructions(T->zone(), kInitialSize);
  ZoneWriteStream isolate_snapshot_data(T->zone(),
                                        FullSnapshotWriter::kInitialSize);
  ZoneWriteStream isolate_snapshot_instructions(T->zone(), kInitialSize);

  const bool generate_debug = debug_callback_data != nullptr;

  auto* const deobfuscation_trie =
      (strip && !generate_debug) ? nullptr
                                 : ImageWriter::CreateReverseObfuscationTrie(T);

  if (as_elf) {
    StreamingWriteStream elf_stream(kInitialSize, callback, callback_data);
    StreamingWriteStream debug_stream(generate_debug ? kInitialDebugSize : 0,
                                      callback, debug_callback_data);

    auto const dwarf = strip ? nullptr : new (Z) Dwarf(Z, deobfuscation_trie);
    auto const elf = new (Z) Elf(Z, &elf_stream, Elf::Type::Snapshot, dwarf);
    // Re-use the same DWARF object if the snapshot is unstripped.
    auto const debug_elf =
        generate_debug
            ? new (Z) Elf(Z, &debug_stream, Elf::Type::DebugInfo,
                          strip ? new (Z) Dwarf(Z, deobfuscation_trie) : dwarf)
            : nullptr;

    BlobImageWriter image_writer(T, &vm_snapshot_instructions,
                                 &isolate_snapshot_instructions,
                                 deobfuscation_trie, debug_elf, elf);
    FullSnapshotWriter writer(Snapshot::kFullAOT, &vm_snapshot_data,
                              &isolate_snapshot_data, &image_writer,
                              &image_writer);

    if (unit == nullptr || unit->id() == LoadingUnit::kRootId) {
      writer.WriteFullSnapshot(units);
    } else {
      writer.WriteUnitSnapshot(units, unit, program_hash);
    }

    elf->Finalize();
    if (debug_elf != nullptr) {
      debug_elf->Finalize();
    }
  } else {
    StreamingWriteStream assembly_stream(kAssemblyInitialSize, callback,
                                         callback_data);
    StreamingWriteStream debug_stream(generate_debug ? kInitialDebugSize : 0,
                                      callback, debug_callback_data);

    auto const elf = generate_debug
                         ? new (Z) Elf(Z, &debug_stream, Elf::Type::DebugInfo,
                                       new (Z) Dwarf(Z, deobfuscation_trie))
                         : nullptr;

    AssemblyImageWriter image_writer(T, &assembly_stream, deobfuscation_trie,
                                     strip, elf);
    FullSnapshotWriter writer(Snapshot::kFullAOT, &vm_snapshot_data,
                              &isolate_snapshot_data, &image_writer,
                              &image_writer);

    if (unit == nullptr || unit->id() == LoadingUnit::kRootId) {
      writer.WriteFullSnapshot(units);
    } else {
      writer.WriteUnitSnapshot(units, unit, program_hash);
    }
    image_writer.Finalize();
  }
}

static void Split(Dart_CreateLoadingUnitCallback next_callback,
                  void* next_callback_data,
                  bool strip,
                  bool as_elf,
                  Dart_StreamingWriteCallback write_callback,
                  Dart_StreamingCloseCallback close_callback) {
  Thread* T = Thread::Current();
  ProgramVisitor::AssignUnits(T);

  const Array& loading_units =
      Array::Handle(T->isolate_group()->object_store()->loading_units());
  const uint32_t program_hash = ProgramVisitor::Hash(T);
  loading_units.SetAt(0, Smi::Handle(Z, Smi::New(program_hash)));
  GrowableArray<LoadingUnitSerializationData*> data;
  data.SetLength(loading_units.Length());
  data[0] = nullptr;

  LoadingUnit& loading_unit = LoadingUnit::Handle();
  LoadingUnit& parent = LoadingUnit::Handle();
  for (intptr_t id = 1; id < loading_units.Length(); id++) {
    loading_unit ^= loading_units.At(id);
    parent = loading_unit.parent();
    LoadingUnitSerializationData* parent_data =
        parent.IsNull() ? nullptr : data[parent.id()];
    data[id] = new LoadingUnitSerializationData(id, parent_data);
  }

  for (intptr_t id = 1; id < loading_units.Length(); id++) {
    void* write_callback_data = nullptr;
    void* write_debug_callback_data = nullptr;
    {
      TransitionVMToNative transition(T);
      next_callback(next_callback_data, id, &write_callback_data,
                    &write_debug_callback_data);
    }
    CreateAppAOTSnapshot(write_callback, write_callback_data, strip, as_elf,
                         write_debug_callback_data, &data, data[id],
                         program_hash);
    {
      TransitionVMToNative transition(T);
      close_callback(write_callback_data);
      if (write_debug_callback_data != nullptr) {
        close_callback(write_debug_callback_data);
      }
    }
  }
}
#endif

DART_EXPORT Dart_Handle
Dart_CreateAppAOTSnapshotAsAssembly(Dart_StreamingWriteCallback callback,
                                    void* callback_data,
                                    bool strip,
                                    void* debug_callback_data) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif defined(DART_TARGET_OS_WINDOWS)
  return Api::NewError("Assembly generation is not implemented for Windows.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  CHECK_NULL(callback);

  // Mark as not split.
  T->isolate_group()->object_store()->set_loading_units(Object::null_array());

  CreateAppAOTSnapshot(callback, callback_data, strip, /*as_elf*/ false,
                       debug_callback_data, nullptr, nullptr, 0);

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle Dart_CreateAppAOTSnapshotAsAssemblies(
    Dart_CreateLoadingUnitCallback next_callback,
    void* next_callback_data,
    bool strip,
    Dart_StreamingWriteCallback write_callback,
    Dart_StreamingCloseCallback close_callback) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif defined(DART_TARGET_OS_WINDOWS)
  return Api::NewError("Assembly generation is not implemented for Windows.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  CHECK_NULL(next_callback);
  CHECK_NULL(write_callback);
  CHECK_NULL(close_callback);

  Split(next_callback, next_callback_data, strip, /*as_elf*/ false,
        write_callback, close_callback);

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle
Dart_CreateVMAOTSnapshotAsAssembly(Dart_StreamingWriteCallback callback,
                                   void* callback_data) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif defined(DART_TARGET_OS_WINDOWS)
  return Api::NewError("Assembly generation is not implemented for Windows.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  CHECK_NULL(callback);

  TIMELINE_DURATION(T, Isolate, "WriteVMAOTSnapshot");
  StreamingWriteStream assembly_stream(kAssemblyInitialSize, callback,
                                       callback_data);
  AssemblyImageWriter image_writer(T, &assembly_stream);
  ZoneWriteStream vm_snapshot_data(T->zone(), FullSnapshotWriter::kInitialSize);
  FullSnapshotWriter writer(Snapshot::kFullAOT, &vm_snapshot_data, nullptr,
                            &image_writer, nullptr);

  writer.WriteFullSnapshot();

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle
Dart_CreateAppAOTSnapshotAsElf(Dart_StreamingWriteCallback callback,
                               void* callback_data,
                               bool strip,
                               void* debug_callback_data) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  CHECK_NULL(callback);

  // Mark as not split.
  T->isolate_group()->object_store()->set_loading_units(Object::null_array());

  CreateAppAOTSnapshot(callback, callback_data, strip, /*as_elf*/ true,
                       debug_callback_data, nullptr, nullptr, 0);

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle
Dart_CreateAppAOTSnapshotAsElfs(Dart_CreateLoadingUnitCallback next_callback,
                                void* next_callback_data,
                                bool strip,
                                Dart_StreamingWriteCallback write_callback,
                                Dart_StreamingCloseCallback close_callback) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  CHECK_NULL(next_callback);
  CHECK_NULL(write_callback);
  CHECK_NULL(close_callback);

  Split(next_callback, next_callback_data, strip, /*as_elf*/ true,
        write_callback, close_callback);

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle Dart_LoadingUnitLibraryUris(intptr_t loading_unit_id) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("AOT compilation is not supported on IA32.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError(
      "This VM was built without support for AOT compilation.");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);

  const Array& loading_units =
      Array::Handle(Z, T->isolate_group()->object_store()->loading_unit_uris());
  if (loading_unit_id >= 0 && loading_unit_id < loading_units.Length()) {
    return Api::NewHandle(T, loading_units.At(loading_unit_id));
  }
  return Api::NewError("Invalid loading_unit_id");
#endif
}

#if (!defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME))

// Any flag that affects how we compile code might cause a problem when the
// snapshot writer generates code with one value of the flag and the snapshot
// reader expects code to behave according to another value of the flag.
// Normally, we add these flags to Dart::FeaturesString and refuse to run the
// snapshot it they don't match, but since --interpret-irregexp affects only
// 2 functions we choose to remove the code instead. See issue #34422.
static void DropRegExpMatchCode(Zone* zone) {
  const String& execute_match_name =
      String::Handle(zone, String::New("_ExecuteMatch"));
  const String& execute_match_sticky_name =
      String::Handle(zone, String::New("_ExecuteMatchSticky"));

  const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
  const Class& reg_exp_class =
      Class::Handle(zone, core_lib.LookupClassAllowPrivate(Symbols::_RegExp()));
  ASSERT(!reg_exp_class.IsNull());

  auto thread = Thread::Current();
  Function& func = Function::Handle(
      zone, reg_exp_class.LookupFunctionAllowPrivate(execute_match_name));
  ASSERT(!func.IsNull());
  Code& code = Code::Handle(zone);
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  if (func.HasCode()) {
    code = func.CurrentCode();
    ASSERT(!code.IsNull());
    code.DisableDartCode();
  }
  func.ClearCode();
  func.ClearICDataArray();
  ASSERT(!func.HasCode());

  func = reg_exp_class.LookupFunctionAllowPrivate(execute_match_sticky_name);
  ASSERT(!func.IsNull());
  if (func.HasCode()) {
    code = func.CurrentCode();
    ASSERT(!code.IsNull());
    code.DisableDartCode();
  }
  func.ClearCode();
  func.ClearICDataArray();
  ASSERT(!func.HasCode());
}

#endif  // (!defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME))

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
#elif defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("JIT app snapshots cannot be taken from an AOT runtime");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
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
  if (Api::IsError(state)) {
    return state;
  }

  NoBackgroundCompilerScope no_bg_compiler(T);

  DropRegExpMatchCode(Z);

  ProgramVisitor::Dedup(T);

  TIMELINE_DURATION(T, Isolate, "WriteCoreJITSnapshot");
  ZoneWriteStream vm_snapshot_data(Api::TopScope(T)->zone(),
                                   FullSnapshotWriter::kInitialSize);
  ZoneWriteStream vm_snapshot_instructions(Api::TopScope(T)->zone(),
                                           FullSnapshotWriter::kInitialSize);
  ZoneWriteStream isolate_snapshot_data(Api::TopScope(T)->zone(),
                                        FullSnapshotWriter::kInitialSize);
  ZoneWriteStream isolate_snapshot_instructions(
      Api::TopScope(T)->zone(), FullSnapshotWriter::kInitialSize);

  BlobImageWriter image_writer(T, &vm_snapshot_instructions,
                               &isolate_snapshot_instructions);
  FullSnapshotWriter writer(Snapshot::kFullJIT, &vm_snapshot_data,
                            &isolate_snapshot_data, &image_writer,
                            &image_writer);
  writer.WriteFullSnapshot();

  *vm_snapshot_data_buffer = vm_snapshot_data.buffer();
  *vm_snapshot_data_size = vm_snapshot_data.bytes_written();
  *vm_snapshot_instructions_buffer = vm_snapshot_instructions.buffer();
  *vm_snapshot_instructions_size = vm_snapshot_instructions.bytes_written();
  *isolate_snapshot_data_buffer = isolate_snapshot_data.buffer();
  *isolate_snapshot_data_size = isolate_snapshot_data.bytes_written();
  *isolate_snapshot_instructions_buffer =
      isolate_snapshot_instructions.buffer();
  *isolate_snapshot_instructions_size =
      isolate_snapshot_instructions.bytes_written();

  return Api::Success();
#endif
}

#if !defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME)
static void KillNonMainIsolatesSlow(Thread* thread, Isolate* main_isolate) {
  auto group = main_isolate->group();
  while (true) {
    bool non_main_isolates_alive = false;
    {
      DeoptSafepointOperationScope safepoint(thread);
      group->ForEachIsolate(
          [&](Isolate* isolate) {
            if (isolate != main_isolate) {
              Isolate::KillIfExists(isolate, Isolate::kKillMsg);
              non_main_isolates_alive = true;
            }
          },
          /*at_safepoint=*/true);
      if (!non_main_isolates_alive) {
        break;
      }
    }
    OS::SleepMicros(10 * 1000);
  }
}
#endif  // !defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME)

DART_EXPORT Dart_Handle
Dart_CreateAppJITSnapshotAsBlobs(uint8_t** isolate_snapshot_data_buffer,
                                 intptr_t* isolate_snapshot_data_size,
                                 uint8_t** isolate_snapshot_instructions_buffer,
                                 intptr_t* isolate_snapshot_instructions_size) {
#if defined(TARGET_ARCH_IA32)
  return Api::NewError("Snapshots with code are not supported on IA32.");
#elif defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("JIT app snapshots cannot be taken from an AOT runtime");
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  auto I = T->isolate();
  auto IG = T->isolate_group();
  CHECK_NULL(isolate_snapshot_data_buffer);
  CHECK_NULL(isolate_snapshot_data_size);
  CHECK_NULL(isolate_snapshot_instructions_buffer);
  CHECK_NULL(isolate_snapshot_instructions_size);

  // Finalize all classes if needed.
  Dart_Handle state = Api::CheckAndFinalizePendingClasses(T);
  if (Api::IsError(state)) {
    return state;
  }

  // Kill off any auxiliary isolates before starting with deduping.
  KillNonMainIsolatesSlow(T, I);

  NoBackgroundCompilerScope no_bg_compiler(T);
  DropRegExpMatchCode(Z);

  ProgramVisitor::Dedup(T);

  if (FLAG_dump_tables) {
    Symbols::DumpTable(IG);
    DumpTypeTable(I);
    DumpTypeParameterTable(I);
    DumpTypeArgumentsTable(I);
  }

  TIMELINE_DURATION(T, Isolate, "WriteAppJITSnapshot");
  ZoneWriteStream isolate_snapshot_data(Api::TopScope(T)->zone(),
                                        FullSnapshotWriter::kInitialSize);
  ZoneWriteStream isolate_snapshot_instructions(
      Api::TopScope(T)->zone(), FullSnapshotWriter::kInitialSize);
  BlobImageWriter image_writer(T, /*vm_instructions=*/nullptr,
                               &isolate_snapshot_instructions);
  FullSnapshotWriter writer(Snapshot::kFullJIT, nullptr, &isolate_snapshot_data,
                            nullptr, &image_writer);
  writer.WriteFullSnapshot();

  *isolate_snapshot_data_buffer = isolate_snapshot_data.buffer();
  *isolate_snapshot_data_size = isolate_snapshot_data.bytes_written();
  *isolate_snapshot_instructions_buffer =
      isolate_snapshot_instructions.buffer();
  *isolate_snapshot_instructions_size =
      isolate_snapshot_instructions.bytes_written();

  return Api::Success();
#endif
}

DART_EXPORT Dart_Handle Dart_GetObfuscationMap(uint8_t** buffer,
                                               intptr_t* buffer_length) {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("No obfuscation map to save on an AOT runtime.");
#elif !defined(DART_PRECOMPILER)
  return Api::NewError("Obfuscation is only supported for AOT compiler.");
#else
  Thread* thread = Thread::Current();
  DARTSCOPE(thread);
  auto isolate_group = thread->isolate_group();

  if (buffer == nullptr) {
    RETURN_NULL_ERROR(buffer);
  }
  if (buffer_length == nullptr) {
    RETURN_NULL_ERROR(buffer_length);
  }

  // Note: can't use JSONStream in PRODUCT builds.
  const intptr_t kInitialBufferSize = 1 * MB;
  ZoneTextBuffer text_buffer(Api::TopScope(T)->zone(), kInitialBufferSize);

  text_buffer.AddChar('[');
  if (isolate_group->obfuscation_map() != nullptr) {
    for (intptr_t i = 0; isolate_group->obfuscation_map()[i] != nullptr; i++) {
      if (i > 0) {
        text_buffer.AddChar(',');
      }
      text_buffer.AddChar('"');
      text_buffer.AddEscapedString(isolate_group->obfuscation_map()[i]);
      text_buffer.AddChar('"');
    }
  }
  text_buffer.AddChar(']');

  *buffer_length = text_buffer.length();
  *reinterpret_cast<char**>(buffer) = text_buffer.buffer();
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
#if !defined(PRODUCT) || defined(DART_PRECOMPILER)
  Profiler::DumpStackTrace(context);
#endif
}

DART_EXPORT void Dart_PrepareToAbort() {
  OS::PrepareToAbort();
}

DART_EXPORT Dart_Handle Dart_GetCurrentUserTag() {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  DARTSCOPE(thread);
  Isolate* isolate = thread->isolate();
  return Api::NewHandle(thread, isolate->current_tag());
}

DART_EXPORT Dart_Handle Dart_GetDefaultUserTag() {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  DARTSCOPE(thread);
  Isolate* isolate = thread->isolate();
  return Api::NewHandle(thread, isolate->default_tag());
}

DART_EXPORT Dart_Handle Dart_NewUserTag(const char* label) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  DARTSCOPE(thread);
  if (label == nullptr) {
    return Api::NewError(
        "Dart_NewUserTag expects argument 'label' to be non-null");
  }
  const String& value = String::Handle(String::New(label));
  return Api::NewHandle(thread, UserTag::New(value));
}

DART_EXPORT Dart_Handle Dart_SetCurrentUserTag(Dart_Handle user_tag) {
  Thread* thread = Thread::Current();
  CHECK_ISOLATE(thread->isolate());
  DARTSCOPE(thread);
  const UserTag& tag = Api::UnwrapUserTagHandle(Z, user_tag);
  if (tag.IsNull()) {
    RETURN_TYPE_ERROR(Z, user_tag, UserTag);
  }
  return Api::NewHandle(thread, tag.MakeActive());
}

DART_EXPORT char* Dart_GetUserTagLabel(Dart_Handle user_tag) {
  DARTSCOPE(Thread::Current());
  const UserTag& tag = Api::UnwrapUserTagHandle(Z, user_tag);
  if (tag.IsNull()) {
    return nullptr;
  }
  const String& label = String::Handle(Z, tag.label());
  return Utils::StrDup(label.ToCString());
}

DART_EXPORT char* Dart_WriteHeapSnapshot(
    Dart_HeapSnapshotWriteChunkCallback write,
    void* context) {
#if defined(DART_ENABLE_HEAP_SNAPSHOT_WRITER)
  DARTSCOPE(Thread::Current());
  CallbackHeapSnapshotWriter callback_writer(T, write, context);
  HeapSnapshotWriter writer(T, &callback_writer);
  writer.Write();
  return nullptr;
#else
  return Utils::StrDup("VM is built without the heap snapshot writer.");
#endif
}

}  // namespace dart
