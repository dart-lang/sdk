// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_store.h"

#include "vm/exceptions.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

ObjectStore::ObjectStore()
  : object_class_(Class::null()),
    object_type_(Type::null()),
    null_type_(Type::null()),
    dynamic_type_(Type::null()),
    void_type_(Type::null()),
    function_type_(Type::null()),
    type_class_(Class::null()),
    number_type_(Type::null()),
    int_type_(Type::null()),
    integer_implementation_class_(Class::null()),
    smi_class_(Class::null()),
    mint_class_(Class::null()),
    bigint_class_(Class::null()),
    double_class_(Class::null()),
    string_type_(Type::null()),
    one_byte_string_class_(Class::null()),
    two_byte_string_class_(Class::null()),
    external_one_byte_string_class_(Class::null()),
    external_two_byte_string_class_(Class::null()),
    bool_type_(Type::null()),
    bool_class_(Class::null()),
    list_class_(Class::null()),
    array_class_(Class::null()),
    array_type_(Type::null()),
    immutable_array_class_(Class::null()),
    growable_object_array_class_(Class::null()),
    float32x4_class_(Class::null()),
    uint32x4_class_(Class::null()),
    typeddata_classes_(Array::null()),
    stacktrace_class_(Class::null()),
    jsregexp_class_(Class::null()),
    weak_property_class_(Class::null()),
    symbol_table_(Array::null()),
    canonical_type_arguments_(Array::null()),
    async_library_(Library::null()),
    builtin_library_(Library::null()),
    core_library_(Library::null()),
    core_impl_library_(Library::null()),
    crypto_library_(Library::null()),
    isolate_library_(Library::null()),
    json_library_(Library::null()),
    math_library_(Library::null()),
    mirrors_library_(Library::null()),
    native_wrappers_library_(Library::null()),
    root_library_(Library::null()),
    typeddata_library_(Library::null()),
    uri_library_(Library::null()),
    utf_library_(Library::null()),
    libraries_(GrowableObjectArray::null()),
    pending_classes_(GrowableObjectArray::null()),
    sticky_error_(Error::null()),
    unhandled_exception_handler_(String::null()),
    empty_context_(Context::null()),
    stack_overflow_(Instance::null()),
    out_of_memory_(Instance::null()),
    preallocated_stack_trace_(Stacktrace::null()),
    keyword_symbols_(Array::null()),
    receive_port_create_function_(Function::null()),
    lookup_receive_port_function_(Function::null()),
    handle_message_function_(Function::null()) {
}


ObjectStore::~ObjectStore() {
}


void ObjectStore::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->VisitPointers(from(), to());
}


void ObjectStore::Init(Isolate* isolate) {
  ASSERT(isolate->object_store() == NULL);
  ObjectStore* store = new ObjectStore();
  isolate->set_object_store(store);
}


bool ObjectStore::PreallocateObjects() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL && isolate->object_store() == this);
  if (this->stack_overflow() != Instance::null()) {
    ASSERT(this->out_of_memory() != Instance::null());
    ASSERT(this->preallocated_stack_trace() != Stacktrace::null());
    return true;
  }
  ASSERT(this->stack_overflow() == Instance::null());
  ASSERT(this->out_of_memory() == Instance::null());
  ASSERT(this->preallocated_stack_trace() == Stacktrace::null());
  // TODO(regis): Reenable this code for arm and mips when possible.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
  Object& result = Object::Handle();

  result = Exceptions::Create(Exceptions::kStackOverflow,
                              Object::empty_array());
  if (result.IsError()) {
    return false;
  }
  set_stack_overflow(Instance::Cast(result));

  result = Exceptions::Create(Exceptions::kOutOfMemory, Object::empty_array());
  if (result.IsError()) {
    return false;
  }
  set_out_of_memory(Instance::Cast(result));
  const Array& func_array = Array::Handle(
      isolate,
      Array::New(Stacktrace::kPreallocatedStackdepth, Heap::kOld));
  const Array& code_array = Array::Handle(
      isolate,
      Array::New(Stacktrace::kPreallocatedStackdepth, Heap::kOld));
  const Array& pc_offset_array = Array::Handle(
      isolate,
      Array::New(Stacktrace::kPreallocatedStackdepth, Heap::kOld));
  result = Stacktrace::New(func_array, code_array, pc_offset_array);
  set_preallocated_stack_trace(Stacktrace::Cast(result));
#endif
  return true;
}


void ObjectStore::InitKeywordTable() {
  // Set up the keywords symbol array so that we can access it while scanning.
  Array& keywords = Array::Handle(keyword_symbols());
  ASSERT(keywords.IsNull());
  keywords = Array::New(Token::numKeywords, Heap::kOld);
  ASSERT(!keywords.IsError() && !keywords.IsNull());
  set_keyword_symbols(keywords);
}

}  // namespace dart
