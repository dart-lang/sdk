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
#include "vm/symbols.h"
#include "vm/visitor.h"

namespace dart {

ObjectStore::ObjectStore()
    : object_class_(Class::null()),
      object_type_(Type::null()),
      null_class_(Class::null()),
      null_type_(Type::null()),
      function_type_(Type::null()),
      type_type_(Type::null()),
      closure_class_(Class::null()),
      number_type_(Type::null()),
      int_type_(Type::null()),
      integer_implementation_class_(Class::null()),
      int64_type_(Type::null()),
      smi_class_(Class::null()),
      smi_type_(Type::null()),
      mint_class_(Class::null()),
      mint_type_(Type::null()),
      bigint_class_(Class::null()),
      double_class_(Class::null()),
      double_type_(Type::null()),
      float32x4_type_(Type::null()),
      int32x4_type_(Type::null()),
      float64x2_type_(Type::null()),
      string_type_(Type::null()),
      compiletime_error_class_(Class::null()),
      future_class_(Class::null()),
      completer_class_(Class::null()),
      stream_iterator_class_(Class::null()),
      symbol_class_(Class::null()),
      one_byte_string_class_(Class::null()),
      two_byte_string_class_(Class::null()),
      external_one_byte_string_class_(Class::null()),
      external_two_byte_string_class_(Class::null()),
      bool_type_(Type::null()),
      bool_class_(Class::null()),
      array_class_(Class::null()),
      array_type_(Type::null()),
      immutable_array_class_(Class::null()),
      growable_object_array_class_(Class::null()),
      linked_hash_map_class_(Class::null()),
      float32x4_class_(Class::null()),
      int32x4_class_(Class::null()),
      float64x2_class_(Class::null()),
      error_class_(Class::null()),
      weak_property_class_(Class::null()),
      symbol_table_(Array::null()),
      canonical_types_(Array::null()),
      canonical_type_arguments_(Array::null()),
      async_library_(Library::null()),
      builtin_library_(Library::null()),
      core_library_(Library::null()),
      collection_library_(Library::null()),
      convert_library_(Library::null()),
      developer_library_(Library::null()),
      _internal_library_(Library::null()),
      isolate_library_(Library::null()),
      math_library_(Library::null()),
      mirrors_library_(Library::null()),
      native_wrappers_library_(Library::null()),
      profiler_library_(Library::null()),
      root_library_(Library::null()),
      typed_data_library_(Library::null()),
      _vmservice_library_(Library::null()),
      libraries_(GrowableObjectArray::null()),
      libraries_map_(Array::null()),
      closure_functions_(GrowableObjectArray::null()),
      pending_classes_(GrowableObjectArray::null()),
      pending_deferred_loads_(GrowableObjectArray::null()),
      resume_capabilities_(GrowableObjectArray::null()),
      exit_listeners_(GrowableObjectArray::null()),
      error_listeners_(GrowableObjectArray::null()),
      stack_overflow_(Instance::null()),
      out_of_memory_(Instance::null()),
      preallocated_unhandled_exception_(UnhandledException::null()),
      preallocated_stack_trace_(StackTrace::null()),
      lookup_port_handler_(Function::null()),
      empty_uint32_array_(TypedData::null()),
      handle_message_function_(Function::null()),
      simple_instance_of_function_(Function::null()),
      simple_instance_of_true_function_(Function::null()),
      simple_instance_of_false_function_(Function::null()),
      async_clear_thread_stack_trace_(Function::null()),
      async_set_thread_stack_trace_(Function::null()),
      async_star_move_next_helper_(Function::null()),
      complete_on_async_return_(Function::null()),
      async_star_stream_controller_(Class::null()),
      library_load_error_table_(Array::null()),
      unique_dynamic_targets_(Array::null()),
      token_objects_(GrowableObjectArray::null()),
      token_objects_map_(Array::null()),
      megamorphic_cache_table_(GrowableObjectArray::null()),
      megamorphic_miss_code_(Code::null()),
      megamorphic_miss_function_(Function::null()),
      obfuscation_map_(Array::null()),
      changed_in_last_reload_(GrowableObjectArray::null()) {
  for (RawObject** current = from(); current <= to(); current++) {
    ASSERT(*current == Object::null());
  }
}

ObjectStore::~ObjectStore() {}

void ObjectStore::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->VisitPointers(from(), to());
}

void ObjectStore::Init(Isolate* isolate) {
  ASSERT(isolate->object_store() == NULL);
  ObjectStore* store = new ObjectStore();
  isolate->set_object_store(store);
}

#ifndef PRODUCT
void ObjectStore::PrintToJSONObject(JSONObject* jsobj) {
  if (!FLAG_support_service) {
    return;
  }
  jsobj->AddProperty("type", "_ObjectStore");

  {
    JSONObject fields(jsobj, "fields");
    Object& value = Object::Handle();
#define PRINT_OBJECT_STORE_FIELD(type, name)                                   \
  value = name;                                                                \
  fields.AddProperty(#name, value);
    OBJECT_STORE_FIELD_LIST(PRINT_OBJECT_STORE_FIELD);
#undef PRINT_OBJECT_STORE_FIELD
  }
}
#endif  // !PRODUCT

RawError* ObjectStore::PreallocateObjects() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  ASSERT(isolate != NULL && isolate->object_store() == this);
  if (this->stack_overflow() != Instance::null()) {
    ASSERT(this->out_of_memory() != Instance::null());
    ASSERT(this->preallocated_stack_trace() != StackTrace::null());
    return Error::null();
  }
  ASSERT(this->stack_overflow() == Instance::null());
  ASSERT(this->out_of_memory() == Instance::null());
  ASSERT(this->preallocated_stack_trace() == StackTrace::null());

  this->pending_deferred_loads_ = GrowableObjectArray::New();

  this->closure_functions_ = GrowableObjectArray::New();
  this->resume_capabilities_ = GrowableObjectArray::New();
  this->exit_listeners_ = GrowableObjectArray::New();
  this->error_listeners_ = GrowableObjectArray::New();

  Object& result = Object::Handle();
  const Library& library = Library::Handle(Library::CoreLibrary());

  result =
      DartLibraryCalls::InstanceCreate(library, Symbols::StackOverflowError(),
                                       Symbols::Dot(), Object::empty_array());
  if (result.IsError()) {
    return Error::Cast(result).raw();
  }
  set_stack_overflow(Instance::Cast(result));

  result =
      DartLibraryCalls::InstanceCreate(library, Symbols::OutOfMemoryError(),
                                       Symbols::Dot(), Object::empty_array());
  if (result.IsError()) {
    return Error::Cast(result).raw();
  }
  set_out_of_memory(Instance::Cast(result));

  // Allocate pre-allocated unhandled exception object initialized with the
  // pre-allocated OutOfMemoryError.
  const UnhandledException& unhandled_exception =
      UnhandledException::Handle(UnhandledException::New(
          Instance::Cast(result), StackTrace::Handle(zone)));
  set_preallocated_unhandled_exception(unhandled_exception);

  const Array& code_array = Array::Handle(
      zone, Array::New(StackTrace::kPreallocatedStackdepth, Heap::kOld));
  const Array& pc_offset_array = Array::Handle(
      zone, Array::New(StackTrace::kPreallocatedStackdepth, Heap::kOld));
  const StackTrace& stack_trace =
      StackTrace::Handle(zone, StackTrace::New(code_array, pc_offset_array));
  // Expansion of inlined functions requires additional memory at run time,
  // avoid it.
  stack_trace.set_expand_inlined(false);
  set_preallocated_stack_trace(stack_trace);

  return Error::null();
}

RawFunction* ObjectStore::PrivateObjectLookup(const String& name) {
  const Library& core_lib = Library::Handle(core_library());
  const String& mangled = String::ZoneHandle(core_lib.PrivateName(name));
  const Class& cls = Class::Handle(object_class());
  const Function& result = Function::Handle(cls.LookupDynamicFunction(mangled));
  ASSERT(!result.IsNull());
  return result.raw();
}

void ObjectStore::InitKnownObjects() {
#ifdef DART_PRECOMPILED_RUNTIME
  // These objects are only needed for code generation.
  return;
#else
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL && isolate->object_store() == this);

  const Library& async_lib = Library::Handle(async_library());
  ASSERT(!async_lib.IsNull());
  Class& cls = Class::Handle(zone);
  cls = async_lib.LookupClass(Symbols::Future());
  ASSERT(!cls.IsNull());
  set_future_class(cls);
  cls = async_lib.LookupClass(Symbols::Completer());
  ASSERT(!cls.IsNull());
  set_completer_class(cls);
  cls = async_lib.LookupClass(Symbols::StreamIterator());
  ASSERT(!cls.IsNull());
  set_stream_iterator_class(cls);

  String& function_name = String::Handle(zone);
  Function& function = Function::Handle(zone);
  function_name ^= async_lib.PrivateName(Symbols::SetAsyncThreadStackTrace());
  ASSERT(!function_name.IsNull());
  function ^=
      Resolver::ResolveStatic(async_lib, Object::null_string(), function_name,
                              0, 1, Object::null_array());
  ASSERT(!function.IsNull());
  set_async_set_thread_stack_trace(function);

  function_name ^= async_lib.PrivateName(Symbols::ClearAsyncThreadStackTrace());
  ASSERT(!function_name.IsNull());
  function ^=
      Resolver::ResolveStatic(async_lib, Object::null_string(), function_name,
                              0, 0, Object::null_array());
  ASSERT(!function.IsNull());
  set_async_clear_thread_stack_trace(function);

  function_name ^= async_lib.PrivateName(Symbols::AsyncStarMoveNextHelper());
  ASSERT(!function_name.IsNull());
  function ^=
      Resolver::ResolveStatic(async_lib, Object::null_string(), function_name,
                              0, 1, Object::null_array());
  ASSERT(!function.IsNull());
  set_async_star_move_next_helper(function);

  function_name ^= async_lib.PrivateName(Symbols::_CompleteOnAsyncReturn());
  ASSERT(!function_name.IsNull());
  function ^=
      Resolver::ResolveStatic(async_lib, Object::null_string(), function_name,
                              0, 2, Object::null_array());
  ASSERT(!function.IsNull());
  set_complete_on_async_return(function);
  if (FLAG_async_debugger) {
    // Disable debugging and inlining the _CompleteOnAsyncReturn function.
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
    const Array& functions = Array::Handle(cls.functions());
    for (intptr_t i = 0; i < functions.Length(); i++) {
      function ^= functions.At(i);
      if (function.IsNull()) {
        break;
      }
      function.set_is_debuggable(false);
      function.set_is_inlinable(false);
    }
  }

  const Library& internal_lib = Library::Handle(_internal_library());
  cls = internal_lib.LookupClass(Symbols::Symbol());
  set_symbol_class(cls);

  const Library& core_lib = Library::Handle(core_library());
  cls = core_lib.LookupClassAllowPrivate(Symbols::_CompileTimeError());
  ASSERT(!cls.IsNull());
  set_compiletime_error_class(cls);

  // Cache the core private functions used for fast instance of checks.
  simple_instance_of_function_ =
      PrivateObjectLookup(Symbols::_simpleInstanceOf());
  simple_instance_of_true_function_ =
      PrivateObjectLookup(Symbols::_simpleInstanceOfTrue());
  simple_instance_of_false_function_ =
      PrivateObjectLookup(Symbols::_simpleInstanceOfFalse());
#endif
}

}  // namespace dart
