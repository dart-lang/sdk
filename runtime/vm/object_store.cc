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
    int8_array_class_(Class::null()),
    uint8_array_class_(Class::null()),
    int16_array_class_(Class::null()),
    uint16_array_class_(Class::null()),
    int32_array_class_(Class::null()),
    uint32_array_class_(Class::null()),
    int64_array_class_(Class::null()),
    uint64_array_class_(Class::null()),
    float32_array_class_(Class::null()),
    float64_array_class_(Class::null()),
    external_int8_array_class_(Class::null()),
    external_uint8_array_class_(Class::null()),
    external_int16_array_class_(Class::null()),
    external_uint16_array_class_(Class::null()),
    external_int32_array_class_(Class::null()),
    external_uint32_array_class_(Class::null()),
    external_int64_array_class_(Class::null()),
    external_uint64_array_class_(Class::null()),
    external_float32_array_class_(Class::null()),
    external_float64_array_class_(Class::null()),
    stacktrace_class_(Class::null()),
    jsregexp_class_(Class::null()),
    true_value_(Bool::null()),
    false_value_(Bool::null()),
    empty_array_(Array::null()),
    symbol_table_(Array::null()),
    canonical_type_arguments_(Array::null()),
    core_library_(Library::null()),
    core_impl_library_(Library::null()),
    math_library_(Library::null()),
    isolate_library_(Library::null()),
    mirrors_library_(Library::null()),
    native_wrappers_library_(Library::null()),
    builtin_library_(Library::null()),
    root_library_(Library::null()),
    import_map_(Array::null()),
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
    case kInt8ArrayClass: return int8_array_class_;
    case kUint8ArrayClass: return uint8_array_class_;
    case kInt16ArrayClass: return int16_array_class_;
    case kUint16ArrayClass: return uint16_array_class_;
    case kInt32ArrayClass: return int32_array_class_;
    case kUint32ArrayClass: return uint32_array_class_;
    case kInt64ArrayClass: return int64_array_class_;
    case kUint64ArrayClass: return uint64_array_class_;
    case kFloat32ArrayClass: return float32_array_class_;
    case kFloat64ArrayClass: return float64_array_class_;
    case kExternalInt8ArrayClass: return external_int8_array_class_;
    case kExternalUint8ArrayClass: return external_uint8_array_class_;
    case kExternalInt16ArrayClass: return external_int16_array_class_;
    case kExternalUint16ArrayClass: return external_uint16_array_class_;
    case kExternalInt32ArrayClass: return external_int32_array_class_;
    case kExternalUint32ArrayClass: return external_uint32_array_class_;
    case kExternalInt64ArrayClass: return external_int64_array_class_;
    case kExternalUint64ArrayClass: return external_uint64_array_class_;
    case kExternalFloat32ArrayClass: return external_float32_array_class_;
    case kExternalFloat64ArrayClass: return external_float64_array_class_;
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
  } else if (raw_class == int8_array_class_) {
    return kInt8ArrayClass;
  } else if (raw_class == uint8_array_class_) {
    return kUint8ArrayClass;
  } else if (raw_class == int16_array_class_) {
    return kInt16ArrayClass;
  } else if (raw_class == uint16_array_class_) {
    return kUint16ArrayClass;
  } else if (raw_class == int32_array_class_) {
    return kInt32ArrayClass;
  } else if (raw_class == uint32_array_class_) {
    return kUint32ArrayClass;
  } else if (raw_class == int64_array_class_) {
    return kInt64ArrayClass;
  } else if (raw_class == uint64_array_class_) {
    return kUint64ArrayClass;
  } else if (raw_class == float32_array_class_) {
    return kFloat32ArrayClass;
  } else if (raw_class == float64_array_class_) {
    return kFloat64ArrayClass;
  } else if (raw_class == external_int8_array_class_) {
    return kExternalInt8ArrayClass;
  } else if (raw_class == external_uint8_array_class_) {
    return kExternalUint8ArrayClass;
  } else if (raw_class == external_int16_array_class_) {
    return kExternalInt16ArrayClass;
  } else if (raw_class == external_uint16_array_class_) {
    return kExternalUint16ArrayClass;
  } else if (raw_class == external_int32_array_class_) {
    return kExternalInt32ArrayClass;
  } else if (raw_class == external_uint32_array_class_) {
    return kExternalUint32ArrayClass;
  } else if (raw_class == external_int64_array_class_) {
    return kExternalInt64ArrayClass;
  } else if (raw_class == external_uint64_array_class_) {
    return kExternalUint64ArrayClass;
  } else if (raw_class == external_float32_array_class_) {
    return kExternalFloat32ArrayClass;
  } else if (raw_class == external_float64_array_class_) {
    return kExternalFloat64ArrayClass;
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
