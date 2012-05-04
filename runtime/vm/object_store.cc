// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
    function_interface_(Type::null()),
    number_interface_(Type::null()),
    int_interface_(Type::null()),
    smi_class_(Class::null()),
    mint_class_(Class::null()),
    bigint_class_(Class::null()),
    double_interface_(Type::null()),
    double_class_(Class::null()),
    string_interface_(Type::null()),
    one_byte_string_class_(Class::null()),
    two_byte_string_class_(Class::null()),
    four_byte_string_class_(Class::null()),
    external_one_byte_string_class_(Class::null()),
    external_two_byte_string_class_(Class::null()),
    external_four_byte_string_class_(Class::null()),
    bool_interface_(Type::null()),
    bool_class_(Class::null()),
    list_interface_(Type::null()),
    array_class_(Class::null()),
    immutable_array_class_(Class::null()),
    growable_object_array_class_(Class::null()),
    byte_array_interface_(Type::null()),
    internal_byte_array_class_(Class::null()),
    external_byte_array_class_(Class::null()),
    stacktrace_class_(Class::null()),
    jsregexp_class_(Class::null()),
    true_value_(Bool::null()),
    false_value_(Bool::null()),
    empty_array_(Array::null()),
    symbol_table_(Array::null()),
    canonical_type_arguments_(Array::null()),
    core_library_(Library::null()),
    core_impl_library_(Library::null()),
    isolate_library_(Library::null()),
    mirrors_library_(Library::null()),
    native_wrappers_library_(Library::null()),
    builtin_library_(Library::null()),
    root_library_(Library::null()),
    registered_libraries_(Library::null()),
    pending_classes_(GrowableObjectArray::null()),
    sticky_error_(Error::null()),
    empty_context_(Context::null()),
    stack_overflow_(Instance::null()),
    out_of_memory_(Instance::null()),
    keyword_symbols_(Array::null()) {
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
  if (this->stack_overflow() != Instance::null() &&
      this->out_of_memory() != Instance::null()) {
    return true;
  }
  ASSERT(this->stack_overflow() == Instance::null());
  ASSERT(this->out_of_memory() == Instance::null());
  GrowableArray<const Object*> args;
  Object& result = Object::Handle();
  Instance& exception = Instance::Handle();

  result = Exceptions::Create(Exceptions::kStackOverflow, args);
  if (result.IsError()) {
    return false;
  }
  exception ^= result.raw();
  set_stack_overflow(exception);

  result = Exceptions::Create(Exceptions::kOutOfMemory, args);
  if (result.IsError()) {
    return false;
  }
  exception ^= result.raw();
  set_out_of_memory(exception);
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


RawClass* ObjectStore::GetClass(int index) {
  switch (index) {
    case kObjectClass: return object_class_;
    case kSmiClass: return smi_class_;
    case kMintClass: return mint_class_;
    case kBigintClass: return bigint_class_;
    case kDoubleClass: return double_class_;
    case kOneByteStringClass: return one_byte_string_class_;
    case kTwoByteStringClass: return two_byte_string_class_;
    case kFourByteStringClass: return four_byte_string_class_;
    case kExternalOneByteStringClass: return external_one_byte_string_class_;
    case kExternalTwoByteStringClass: return external_two_byte_string_class_;
    case kExternalFourByteStringClass: return external_four_byte_string_class_;
    case kBoolClass: return bool_class_;
    case kArrayClass: return array_class_;
    case kImmutableArrayClass: return immutable_array_class_;
    case kGrowableObjectArrayClass: return growable_object_array_class_;
    case kInternalByteArrayClass: return internal_byte_array_class_;
    case kExternalByteArrayClass: return external_byte_array_class_;
    case kStacktraceClass: return stacktrace_class_;
    case kJSRegExpClass: return jsregexp_class_;
    default: break;
  }
  UNREACHABLE();
  return Class::null();
}


int ObjectStore::GetClassIndex(const RawClass* raw_class) {
  ASSERT(raw_class->IsHeapObject());
  if (raw_class == object_class_) {
    return kObjectClass;
  } else if (raw_class == smi_class_) {
    return kSmiClass;
  } else if (raw_class == mint_class_) {
    return kMintClass;
  } else if (raw_class == bigint_class_) {
    return kBigintClass;
  } else if (raw_class == double_class_) {
    return kDoubleClass;
  } else if (raw_class == one_byte_string_class_) {
    return kOneByteStringClass;
  } else if (raw_class == two_byte_string_class_) {
    return kTwoByteStringClass;
  } else if (raw_class == four_byte_string_class_) {
    return kFourByteStringClass;
  } else if (raw_class == external_one_byte_string_class_) {
    return kExternalOneByteStringClass;
  } else if (raw_class == external_two_byte_string_class_) {
    return kExternalTwoByteStringClass;
  } else if (raw_class == external_four_byte_string_class_) {
    return kExternalFourByteStringClass;
  } else if (raw_class == bool_class_) {
    return kBoolClass;
  } else if (raw_class == array_class_) {
    return kArrayClass;
  } else if (raw_class == immutable_array_class_) {
    return kImmutableArrayClass;
  } else if (raw_class == growable_object_array_class_) {
    return kGrowableObjectArrayClass;
  } else if (raw_class == internal_byte_array_class_) {
    return kInternalByteArrayClass;
  } else if (raw_class == external_byte_array_class_) {
    return kExternalByteArrayClass;
  } else if (raw_class == stacktrace_class_) {
    return kStacktraceClass;
  } else if (raw_class == jsregexp_class_) {
    return kJSRegExpClass;
  }
  return kInvalidIndex;
}


RawType* ObjectStore::GetType(int index) {
  switch (index) {
    case kObjectType: return object_type();
    case kNullType: return null_type();
    case kDynamicType: return dynamic_type();
    case kVoidType: return void_type();
    case kFunctionInterface: return function_interface();
    case kNumberInterface: return number_interface();
    case kDoubleInterface: return double_interface();
    case kIntInterface: return int_interface();
    case kBoolInterface: return bool_interface();
    case kStringInterface: return string_interface();
    case kListInterface: return list_interface();
    case kByteArrayInterface: return byte_array_interface();
    default: break;
  }
  UNREACHABLE();
  return Type::null();
}


int ObjectStore::GetTypeIndex(const RawType* raw_type) {
  ASSERT(raw_type->IsHeapObject());
  if (raw_type == object_type()) {
    return kObjectType;
  } else if (raw_type == null_type()) {
    return kNullType;
  } else if (raw_type == dynamic_type()) {
    return kDynamicType;
  } else if (raw_type == void_type()) {
    return kVoidType;
  } else if (raw_type == function_interface()) {
    return kFunctionInterface;
  } else if (raw_type == number_interface()) {
    return kNumberInterface;
  } else if (raw_type == double_interface()) {
    return kDoubleInterface;
  } else if (raw_type == int_interface()) {
    return kIntInterface;
  } else if (raw_type == bool_interface()) {
    return kBoolInterface;
  } else if (raw_type == string_interface()) {
    return kStringInterface;
  } else if (raw_type == list_interface()) {
    return kListInterface;
  } else if (raw_type == byte_array_interface()) {
    return kByteArrayInterface;
  }
  return kInvalidIndex;
}

}  // namespace dart
