// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_store.h"

#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/visitor.h"

namespace dart {

void IsolateObjectStore::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->set_gc_root_type("isolate_object store");
  visitor->VisitPointers(from(), to());
  visitor->clear_gc_root_type();
}

void IsolateObjectStore::Init() {
  for (ObjectPtr* current = from(); current <= to(); current++) {
    *current = Object::null();
  }
}

#ifndef PRODUCT
void IsolateObjectStore::PrintToJSONObject(JSONObject* jsobj) {
  jsobj->AddProperty("type", "_IsolateObjectStore");

  {
    JSONObject fields(jsobj, "fields");
    Object& value = Object::Handle();

    static const char* const names[] = {
#define EMIT_FIELD_NAME(type, name) #name "_",
        ISOLATE_OBJECT_STORE_FIELD_LIST(EMIT_FIELD_NAME, EMIT_FIELD_NAME)
#undef EMIT_FIELD_NAME
    };
    ObjectPtr* current = from();
    intptr_t i = 0;
    while (current <= to()) {
      value = *current;
      fields.AddProperty(names[i], value);
      current++;
      i++;
    }
    ASSERT(i == ARRAY_SIZE(names));
  }
}
#endif  // !PRODUCT

static StackTracePtr CreatePreallocatedStackTrace(Zone* zone) {
  const Array& code_array = Array::Handle(
      zone, Array::New(StackTrace::kPreallocatedStackdepth, Heap::kOld));
  const TypedData& pc_offset_array = TypedData::Handle(
      zone, TypedData::New(kUintPtrCid, StackTrace::kPreallocatedStackdepth,
                           Heap::kOld));
  const StackTrace& stack_trace =
      StackTrace::Handle(zone, StackTrace::New(code_array, pc_offset_array));
  // Expansion of inlined functions requires additional memory at run time,
  // avoid it.
  stack_trace.set_expand_inlined(false);
  return stack_trace.ptr();
}

ErrorPtr IsolateObjectStore::PreallocateObjects(const Object& out_of_memory) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  ASSERT(isolate != NULL && isolate->isolate_object_store() == this);
  ASSERT(preallocated_stack_trace() == StackTrace::null());
  resume_capabilities_ = GrowableObjectArray::New();
  exit_listeners_ = GrowableObjectArray::New();
  error_listeners_ = GrowableObjectArray::New();

  // Allocate pre-allocated unhandled exception object initialized with the
  // pre-allocated OutOfMemoryError.
  const StackTrace& preallocated_stack_trace =
      StackTrace::Handle(zone, CreatePreallocatedStackTrace(zone));
  set_preallocated_stack_trace(preallocated_stack_trace);
  set_preallocated_unhandled_exception(UnhandledException::Handle(
      zone, UnhandledException::New(Instance::Cast(out_of_memory),
                                    preallocated_stack_trace)));

  return Error::null();
}

ObjectStore::ObjectStore()
    :
#define EMIT_FIELD_INIT(type, name) name##_(nullptr),
      OBJECT_STORE_FIELD_LIST(EMIT_FIELD_INIT,
                              EMIT_FIELD_INIT,
                              EMIT_FIELD_INIT,
                              EMIT_FIELD_INIT,
                              EMIT_FIELD_INIT,
                              EMIT_FIELD_INIT,
                              EMIT_FIELD_INIT,
                              EMIT_FIELD_INIT)
#undef EMIT_FIELD_INIT
          unused_field_(0)  // Just to prevent a trailing comma.
{
  for (ObjectPtr* current = from(); current <= to(); current++) {
    *current = Object::null();
  }
}

ObjectStore::~ObjectStore() {}

void ObjectStore::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->set_gc_root_type("object store");
  visitor->VisitPointers(from(), to());
  visitor->clear_gc_root_type();
}

void ObjectStore::InitStubs() {
#define DO(member, name) set_##member(StubCode::name());
  OBJECT_STORE_STUB_CODE_LIST(DO)
#undef DO
}

#ifndef PRODUCT
void ObjectStore::PrintToJSONObject(JSONObject* jsobj) {
  jsobj->AddProperty("type", "_ObjectStore");

  {
    JSONObject fields(jsobj, "fields");
    Object& value = Object::Handle();
    static const char* const names[] = {
#define EMIT_FIELD_NAME(type, name) #name "_",
        OBJECT_STORE_FIELD_LIST(
            EMIT_FIELD_NAME, EMIT_FIELD_NAME, EMIT_FIELD_NAME, EMIT_FIELD_NAME,
            EMIT_FIELD_NAME, EMIT_FIELD_NAME, EMIT_FIELD_NAME, EMIT_FIELD_NAME)
#undef EMIT_FIELD_NAME
    };
    ObjectPtr* current = from();
    intptr_t i = 0;
    while (current <= to()) {
      value = *current;
      fields.AddProperty(names[i], value);
      current++;
      i++;
    }
    ASSERT(i == ARRAY_SIZE(names));
  }
}
#endif  // !PRODUCT

static InstancePtr AllocateObjectByClassName(const Library& library,
                                             const String& class_name) {
  const Class& cls = Class::Handle(library.LookupClassAllowPrivate(class_name));
  ASSERT(!cls.IsNull());
  return Instance::New(cls);
}

ErrorPtr ObjectStore::PreallocateObjects() {
  Thread* thread = Thread::Current();
  IsolateGroup* isolate_group = thread->isolate_group();
  // Either we are the object store on isolate group, or isolate group has no
  // object store and we are the object store on the isolate.
  ASSERT(isolate_group != nullptr && isolate_group->object_store() == this);

  if (this->stack_overflow() != Instance::null()) {
    ASSERT(this->out_of_memory() != Instance::null());
    return Error::null();
  }
  ASSERT(this->stack_overflow() == Instance::null());
  ASSERT(this->out_of_memory() == Instance::null());

  this->closure_functions_ = GrowableObjectArray::New();

  Object& result = Object::Handle();
  const Library& library = Library::Handle(Library::CoreLibrary());

  result = AllocateObjectByClassName(library, Symbols::StackOverflowError());
  if (result.IsError()) {
    return Error::Cast(result).ptr();
  }
  set_stack_overflow(Instance::Cast(result));

  result = AllocateObjectByClassName(library, Symbols::OutOfMemoryError());
  if (result.IsError()) {
    return Error::Cast(result).ptr();
  }
  set_out_of_memory(Instance::Cast(result));

  return Error::null();
}

FunctionPtr ObjectStore::PrivateObjectLookup(const String& name) {
  const Library& core_lib = Library::Handle(core_library());
  const String& mangled = String::ZoneHandle(core_lib.PrivateName(name));
  const Class& cls = Class::Handle(object_class());
  Thread* thread = Thread::Current();
  const auto& error = cls.EnsureIsFinalized(thread);
  ASSERT(error == Error::null());
  const Function& result = Function::Handle(
      Resolver::ResolveDynamicFunction(thread->zone(), cls, mangled));
  ASSERT(!result.IsNull());
  return result.ptr();
}

void ObjectStore::InitKnownObjects() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Class& cls = Class::Handle(zone);
  const Library& collection_lib = Library::Handle(zone, collection_library());
  cls = collection_lib.LookupClassAllowPrivate(Symbols::_LinkedHashSet());
  ASSERT(!cls.IsNull());
  set_linked_hash_set_class(cls);

#ifdef DART_PRECOMPILED_RUNTIME
  // The rest of these objects are only needed for code generation.
  return;
#else
  auto isolate_group = thread->isolate_group();
  ASSERT(isolate_group != nullptr && isolate_group->object_store() == this);

  const Library& async_lib = Library::Handle(zone, async_library());
  ASSERT(!async_lib.IsNull());
  cls = async_lib.LookupClass(Symbols::Future());
  ASSERT(!cls.IsNull());
  set_future_class(cls);
  cls = async_lib.LookupClass(Symbols::Completer());
  ASSERT(!cls.IsNull());
  set_completer_class(cls);

  String& function_name = String::Handle(zone);
  Function& function = Function::Handle(zone);

  function_name = async_lib.PrivateName(Symbols::AsyncStarMoveNextHelper());
  ASSERT(!function_name.IsNull());
  function = Resolver::ResolveStatic(async_lib, Object::null_string(),
                                     function_name, 0, 1, Object::null_array());
  ASSERT(!function.IsNull());
  set_async_star_move_next_helper(function);

  function_name = async_lib.PrivateName(Symbols::_CompleteOnAsyncReturn());
  ASSERT(!function_name.IsNull());
  function = Resolver::ResolveStatic(async_lib, Object::null_string(),
                                     function_name, 0, 3, Object::null_array());
  ASSERT(!function.IsNull());
  set_complete_on_async_return(function);
  if (FLAG_async_debugger) {
    // Disable debugging and inlining the _CompleteOnAsyncReturn function.
    function.set_is_debuggable(false);
    function.set_is_inlinable(false);
  }

  function_name = async_lib.PrivateName(Symbols::_CompleteOnAsyncError());
  ASSERT(!function_name.IsNull());
  function = Resolver::ResolveStatic(async_lib, Object::null_string(),
                                     function_name, 0, 4, Object::null_array());
  ASSERT(!function.IsNull());
  set_complete_on_async_error(function);
  if (FLAG_async_debugger) {
    // Disable debugging and inlining the _CompleteOnAsyncError function.
    function.set_is_debuggable(false);
    function.set_is_inlinable(false);
  }

  cls =
      async_lib.LookupClassAllowPrivate(Symbols::_AsyncStarStreamController());
  ASSERT(!cls.IsNull());
  set_async_star_stream_controller(cls);

  if (FLAG_async_debugger) {
    // Disable debugging and inlining of all functions on the
    // _AsyncStarStreamController class.
    const Array& functions = Array::Handle(zone, cls.current_functions());
    for (intptr_t i = 0; i < functions.Length(); i++) {
      function ^= functions.At(i);
      if (function.IsNull()) {
        break;
      }
      function.set_is_debuggable(false);
      function.set_is_inlinable(false);
    }
  }

  const Library& core_lib = Library::Handle(zone, core_library());
  cls = core_lib.LookupClassAllowPrivate(Symbols::_CompileTimeError());
  ASSERT(!cls.IsNull());
  set_compiletime_error_class(cls);

  cls = core_lib.LookupClassAllowPrivate(Symbols::Pragma());
  ASSERT(!cls.IsNull());
  set_pragma_class(cls);
  RELEASE_ASSERT(cls.EnsureIsFinalized(thread) == Error::null());
  set_pragma_name(Field::Handle(zone, cls.LookupField(Symbols::name())));
  set_pragma_options(Field::Handle(zone, cls.LookupField(Symbols::options())));

  cls = core_lib.LookupClassAllowPrivate(Symbols::_GrowableList());
  ASSERT(!cls.IsNull());
  RELEASE_ASSERT(cls.EnsureIsFinalized(thread) == Error::null());
  growable_list_factory_ =
      cls.LookupFactoryAllowPrivate(Symbols::_GrowableListFactory());
  ASSERT(growable_list_factory_ != Function::null());

  cls = core_lib.LookupClassAllowPrivate(Symbols::Error());
  ASSERT(!cls.IsNull());
  set_error_class(cls);

  cls = core_lib.LookupClassAllowPrivate(Symbols::Expando());
  ASSERT(!cls.IsNull());
  set_expando_class(cls);

  // Cache the core private functions used for fast instance of checks.
  simple_instance_of_function_ =
      PrivateObjectLookup(Symbols::_simpleInstanceOf());
  simple_instance_of_true_function_ =
      PrivateObjectLookup(Symbols::_simpleInstanceOfTrue());
  simple_instance_of_false_function_ =
      PrivateObjectLookup(Symbols::_simpleInstanceOfFalse());

  // Ensure AddSmiSmiCheckForFastSmiStubs run by the background compiler
  // will not create new functions.
  const Class& smi_class = Class::Handle(zone, this->smi_class());
  RELEASE_ASSERT(smi_class.EnsureIsFinalized(thread) == Error::null());
  function_name =
      Function::CreateDynamicInvocationForwarderName(Symbols::Plus());
  Resolver::ResolveDynamicAnyArgs(zone, smi_class, function_name);
  function_name =
      Function::CreateDynamicInvocationForwarderName(Symbols::Minus());
  Resolver::ResolveDynamicAnyArgs(zone, smi_class, function_name);
  function_name =
      Function::CreateDynamicInvocationForwarderName(Symbols::Equals());
  Resolver::ResolveDynamicAnyArgs(zone, smi_class, function_name);
  function_name =
      Function::CreateDynamicInvocationForwarderName(Symbols::LAngleBracket());
  Resolver::ResolveDynamicAnyArgs(zone, smi_class, function_name);
  function_name =
      Function::CreateDynamicInvocationForwarderName(Symbols::RAngleBracket());
  Resolver::ResolveDynamicAnyArgs(zone, smi_class, function_name);
  function_name =
      Function::CreateDynamicInvocationForwarderName(Symbols::BitAnd());
  Resolver::ResolveDynamicAnyArgs(zone, smi_class, function_name);
  function_name =
      Function::CreateDynamicInvocationForwarderName(Symbols::BitOr());
  Resolver::ResolveDynamicAnyArgs(zone, smi_class, function_name);
  function_name =
      Function::CreateDynamicInvocationForwarderName(Symbols::Star());
  Resolver::ResolveDynamicAnyArgs(zone, smi_class, function_name);
#endif
}

void ObjectStore::LazyInitCoreMembers() {
  auto* const thread = Thread::Current();
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  if (list_class_.load() == Type::null()) {
    ASSERT(non_nullable_list_rare_type_.load() == Type::null());
    ASSERT(non_nullable_map_rare_type_.load() == Type::null());
    ASSERT(_object_equals_function_.load() == Function::null());
    ASSERT(_object_hash_code_function_.load() == Function::null());
    ASSERT(_object_to_string_function_.load() == Function::null());

    auto* const zone = thread->zone();
    const auto& core_lib = Library::Handle(zone, Library::CoreLibrary());
    auto& cls = Class::Handle(zone);

    cls = core_lib.LookupClass(Symbols::List());
    ASSERT(!cls.IsNull());
    list_class_.store(cls.ptr());

    auto& type = Type::Handle(zone);
    type ^= cls.RareType();
    non_nullable_list_rare_type_.store(type.ptr());

    cls = core_lib.LookupClass(Symbols::Map());
    ASSERT(!cls.IsNull());
    type ^= cls.RareType();
    non_nullable_map_rare_type_.store(type.ptr());

    auto& function = Function::Handle(zone);

    function = core_lib.LookupFunctionAllowPrivate(Symbols::_objectHashCode());
    ASSERT(!function.IsNull());
    _object_hash_code_function_.store(function.ptr());

    function = core_lib.LookupFunctionAllowPrivate(Symbols::_objectEquals());
    ASSERT(!function.IsNull());
    _object_equals_function_.store(function.ptr());

    function = core_lib.LookupFunctionAllowPrivate(Symbols::_objectToString());
    ASSERT(!function.IsNull());
    _object_to_string_function_.store(function.ptr());
  }
}

void ObjectStore::LazyInitAsyncMembers() {
  auto* const thread = Thread::Current();
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  if (non_nullable_future_rare_type_.load() == Type::null()) {
    ASSERT(non_nullable_future_never_type_.load() == Type::null());
    ASSERT(nullable_future_null_type_.load() == Type::null());

    auto* const zone = thread->zone();
    const auto& cls = Class::Handle(zone, future_class());
    ASSERT(!cls.IsNull());

    auto& type_args = TypeArguments::Handle(zone);
    auto& type = Type::Handle(zone);
    type = never_type();
    ASSERT(!type.IsNull());
    type_args = TypeArguments::New(1);
    type_args.SetTypeAt(0, type);
    type = Type::New(cls, type_args, Nullability::kNonNullable);
    type.SetIsFinalized();
    type ^= type.Canonicalize(thread, nullptr);
    non_nullable_future_never_type_.store(type.ptr());

    type = null_type();
    ASSERT(!type.IsNull());
    type_args = TypeArguments::New(1);
    type_args.SetTypeAt(0, type);
    type = Type::New(cls, type_args, Nullability::kNullable);
    type.SetIsFinalized();
    type ^= type.Canonicalize(thread, nullptr);
    nullable_future_null_type_.store(type.ptr());

    type ^= cls.RareType();
    non_nullable_future_rare_type_.store(type.ptr());
  }
}

void ObjectStore::LazyInitIsolateMembers() {
  auto* const thread = Thread::Current();
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  if (lookup_port_handler_.load() == Type::null()) {
    ASSERT(lookup_open_ports_.load() == Type::null());
    ASSERT(handle_message_function_.load() == Type::null());

    auto* const zone = thread->zone();
    const auto& isolate_lib = Library::Handle(zone, Library::IsolateLibrary());
    auto& cls = Class::Handle(zone);
    auto& function = Function::Handle(zone);

    cls = isolate_lib.LookupClassAllowPrivate(Symbols::_RawReceivePortImpl());
    ASSERT(!cls.IsNull());
    const auto& error = cls.EnsureIsFinalized(thread);
    ASSERT(error == Error::null());

    function = cls.LookupFunctionAllowPrivate(Symbols::_lookupHandler());
    ASSERT(!function.IsNull());
    lookup_port_handler_.store(function.ptr());

    function = cls.LookupFunctionAllowPrivate(Symbols::_lookupOpenPorts());
    ASSERT(!function.IsNull());
    lookup_open_ports_.store(function.ptr());

    function = cls.LookupFunctionAllowPrivate(Symbols::_handleMessage());
    ASSERT(!function.IsNull());
    handle_message_function_.store(function.ptr());
  }
}

void ObjectStore::LazyInitInternalMembers() {
  auto* const thread = Thread::Current();
  SafepointWriteRwLocker locker(thread,
                                thread->isolate_group()->program_lock());
  if (symbol_class_.load() == Type::null()) {
    ASSERT(symbol_name_field_.load() == Field::null());

    auto* const zone = thread->zone();
    auto& cls = Class::Handle(zone);
    auto& field = Field::Handle(zone);

    const auto& internal_lib =
        Library::Handle(zone, Library::InternalLibrary());
    cls = internal_lib.LookupClass(Symbols::Symbol());
    ASSERT(!cls.IsNull());
    const auto& error = cls.EnsureIsFinalized(thread);
    ASSERT(error == Error::null());
    symbol_class_.store(cls.ptr());

    field = cls.LookupInstanceFieldAllowPrivate(Symbols::_name());
    ASSERT(!field.IsNull());
    symbol_name_field_.store(field.ptr());
  }
}

}  // namespace dart
