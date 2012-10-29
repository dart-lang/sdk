// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OBJECT_STORE_H_
#define VM_OBJECT_STORE_H_

#include "vm/object.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;

// The object store is a per isolate instance which stores references to
// objects used by the VM.
// TODO(iposva): Move the actual store into the object heap for quick handling
// by snapshots eventually.
class ObjectStore {
 public:
  ~ObjectStore();

  RawClass* object_class() const {
    ASSERT(object_class_ != Object::null());
    return object_class_;
  }
  void set_object_class(const Class& value) { object_class_ = value.raw(); }
  static intptr_t object_class_offset() {
    return OFFSET_OF(ObjectStore, object_class_);
  }

  RawType* object_type() const { return object_type_; }
  void set_object_type(const Type& value) {
    object_type_ = value.raw();
  }

  RawType* null_type() const { return null_type_; }
  void set_null_type(const Type& value) {
    null_type_ = value.raw();
  }

  RawType* dynamic_type() const { return dynamic_type_; }
  void set_dynamic_type(const Type& value) {
    dynamic_type_ = value.raw();
  }

  RawType* void_type() const { return void_type_; }
  void set_void_type(const Type& value) {
    void_type_ = value.raw();
  }

  RawType* function_type() const { return function_type_; }
  void set_function_type(const Type& value) {
    function_type_ = value.raw();
  }

  RawClass* type_class() const { return type_class_; }
  void set_type_class(const Class& value) { type_class_ = value.raw(); }

  RawClass* type_parameter_class() const { return type_parameter_class_; }
  void set_type_parameter_class(const Class& value) {
    type_parameter_class_ = value.raw();
  }

  RawType* number_type() const { return number_type_; }
  void set_number_type(const Type& value) {
    number_type_ = value.raw();
  }

  RawType* int_type() const { return int_type_; }
  void set_int_type(const Type& value) {
    int_type_ = value.raw();
  }

  RawClass* integer_implementation_class() const {
    return integer_implementation_class_;
  }
  void set_integer_implementation_class(const Class& value) {
    integer_implementation_class_ = value.raw();
  }

  RawClass* smi_class() const { return smi_class_; }
  void set_smi_class(const Class& value) { smi_class_ = value.raw(); }

  RawType* smi_type() const { return smi_type_; }
  void set_smi_type(const Type& value) { smi_type_ = value.raw();
  }

  RawClass* double_class() const { return double_class_; }
  void set_double_class(const Class& value) { double_class_ = value.raw(); }

  RawType* double_type() const { return double_type_; }
  void set_double_type(const Type& value) { double_type_ = value.raw(); }

  RawClass* mint_class() const { return mint_class_; }
  void set_mint_class(const Class& value) { mint_class_ = value.raw(); }

  RawType* mint_type() const { return mint_type_; }
  void set_mint_type(const Type& value) { mint_type_ = value.raw(); }

  RawClass* bigint_class() const { return bigint_class_; }
  void set_bigint_class(const Class& value) { bigint_class_ = value.raw(); }

  RawType* string_interface() const { return string_interface_; }
  void set_string_interface(const Type& value) {
    string_interface_ = value.raw();
  }

  RawClass* one_byte_string_class() const { return one_byte_string_class_; }
  void set_one_byte_string_class(const Class& value) {
    one_byte_string_class_ = value.raw();
  }

  RawClass* two_byte_string_class() const { return two_byte_string_class_; }
  void set_two_byte_string_class(const Class& value) {
    two_byte_string_class_ = value.raw();
  }

  RawClass* four_byte_string_class() const { return four_byte_string_class_; }
  void set_four_byte_string_class(const Class& value) {
    four_byte_string_class_ = value.raw();
  }

  RawClass* external_one_byte_string_class() const {
    return external_one_byte_string_class_;
  }
  void set_external_one_byte_string_class(const Class& value) {
    external_one_byte_string_class_ = value.raw();
  }

  RawClass* external_two_byte_string_class() const {
    return external_two_byte_string_class_;
  }
  void set_external_two_byte_string_class(const Class& value) {
    external_two_byte_string_class_ = value.raw();
  }

  RawClass* external_four_byte_string_class() const {
    return external_four_byte_string_class_;
  }
  void set_external_four_byte_string_class(const Class& value) {
    external_four_byte_string_class_ = value.raw();
  }

  RawType* bool_type() const { return bool_type_; }
  void set_bool_type(const Type& value) { bool_type_ = value.raw(); }

  RawClass* bool_class() const { return bool_class_; }
  void set_bool_class(const Class& value) { bool_class_ = value.raw(); }

  RawType* list_interface() const { return list_interface_; }
  void set_list_interface(const Type& value) {
    list_interface_ = value.raw();
  }

  RawClass* array_class() const { return array_class_; }
  void set_array_class(const Class& value) { array_class_ = value.raw(); }
  static intptr_t array_class_offset() {
    return OFFSET_OF(ObjectStore, array_class_);
  }

  RawClass* immutable_array_class() const { return immutable_array_class_; }
  void set_immutable_array_class(const Class& value) {
    immutable_array_class_ = value.raw();
  }

  RawClass* growable_object_array_class() const {
    return growable_object_array_class_;
  }
  void set_growable_object_array_class(const Class& value) {
    growable_object_array_class_ = value.raw();
  }
  static intptr_t growable_object_array_class_offset() {
    return OFFSET_OF(ObjectStore, growable_object_array_class_);
  }

  RawClass* int8_array_class() const {
    return int8_array_class_;
  }
  void set_int8_array_class(const Class& value) {
    int8_array_class_ = value.raw();
  }

  RawClass* uint8_array_class() const {
    return uint8_array_class_;
  }
  void set_uint8_array_class(const Class& value) {
    uint8_array_class_ = value.raw();
  }

  RawClass* int16_array_class() const {
    return int16_array_class_;
  }
  void set_int16_array_class(const Class& value) {
    int16_array_class_ = value.raw();
  }

  RawClass* uint16_array_class() const {
    return uint16_array_class_;
  }
  void set_uint16_array_class(const Class& value) {
    uint16_array_class_ = value.raw();
  }

  RawClass* int32_array_class() const {
    return int32_array_class_;
  }
  void set_int32_array_class(const Class& value) {
    int32_array_class_ = value.raw();
  }

  RawClass* uint32_array_class() const {
    return uint32_array_class_;
  }
  void set_uint32_array_class(const Class& value) {
    uint32_array_class_ = value.raw();
  }

  RawClass* int64_array_class() const {
    return int64_array_class_;
  }
  void set_int64_array_class(const Class& value) {
    int64_array_class_ = value.raw();
  }

  RawClass* uint64_array_class() const {
    return uint64_array_class_;
  }
  void set_uint64_array_class(const Class& value) {
    uint64_array_class_ = value.raw();
  }

  RawClass* float32_array_class() const {
    return float32_array_class_;
  }
  void set_float32_array_class(const Class& value) {
    float32_array_class_ = value.raw();
  }

  RawClass* float64_array_class() const {
    return float64_array_class_;
  }
  void set_float64_array_class(const Class& value) {
    float64_array_class_ = value.raw();
  }

  RawClass* external_int8_array_class() const {
    return external_int8_array_class_;
  }
  void set_external_int8_array_class(const Class& value) {
    external_int8_array_class_ = value.raw();
  }

  RawClass* external_uint8_array_class() const {
    return external_uint8_array_class_;
  }
  void set_external_uint8_array_class(const Class& value) {
    external_uint8_array_class_ = value.raw();
  }

  RawClass* external_int16_array_class() const {
    return external_int16_array_class_;
  }
  void set_external_int16_array_class(const Class& value) {
    external_int16_array_class_ = value.raw();
  }

  RawClass* external_uint16_array_class() const {
    return external_uint16_array_class_;
  }
  void set_external_uint16_array_class(const Class& value) {
    external_uint16_array_class_ = value.raw();
  }

  RawClass* external_int32_array_class() const {
    return external_int32_array_class_;
  }
  void set_external_int32_array_class(const Class& value) {
    external_int32_array_class_ = value.raw();
  }

  RawClass* external_uint32_array_class() const {
    return external_uint32_array_class_;
  }
  void set_external_uint32_array_class(const Class& value) {
    external_uint32_array_class_ = value.raw();
  }

  RawClass* external_int64_array_class() const {
    return external_int64_array_class_;
  }
  void set_external_int64_array_class(const Class& value) {
    external_int64_array_class_ = value.raw();
  }

  RawClass* external_uint64_array_class() const {
    return external_uint64_array_class_;
  }
  void set_external_uint64_array_class(const Class& value) {
    external_uint64_array_class_ = value.raw();
  }

  RawClass* external_float32_array_class() const {
    return external_float32_array_class_;
  }
  void set_external_float32_array_class(const Class& value) {
    external_float32_array_class_ = value.raw();
  }

  RawClass* external_float64_array_class() const {
    return external_float64_array_class_;
  }
  void set_external_float64_array_class(const Class& value) {
    external_float64_array_class_ = value.raw();
  }

  RawClass* stacktrace_class() const {
    return stacktrace_class_;
  }
  void set_stacktrace_class(const Class& value) {
    stacktrace_class_ = value.raw();
  }
  static intptr_t stacktrace_class_offset() {
    return OFFSET_OF(ObjectStore, stacktrace_class_);
  }

  RawClass* jsregexp_class() const {
    return jsregexp_class_;
  }
  void set_jsregexp_class(const Class& value) {
    jsregexp_class_ = value.raw();
  }
  static intptr_t jsregexp_class_offset() {
    return OFFSET_OF(ObjectStore, jsregexp_class_);
  }

  RawClass* weak_property_class() const {
    return weak_property_class_;
  }
  void set_weak_property_class(const Class& value) {
    weak_property_class_ = value.raw();
  }

  RawArray* symbol_table() const { return symbol_table_; }
  void set_symbol_table(const Array& value) { symbol_table_ = value.raw(); }

  RawArray* canonical_type_arguments() const {
    return canonical_type_arguments_;
  }
  void set_canonical_type_arguments(const Array& value) {
    canonical_type_arguments_ = value.raw();
  }

  RawLibrary* core_library() const { return core_library_; }
  void set_core_library(const Library& value) {
    core_library_ = value.raw();
  }

  RawLibrary* core_impl_library() const { return core_impl_library_; }
  void set_core_impl_library(const Library& value) {
    core_impl_library_ = value.raw();
  }

  RawLibrary* collection_library() const {
    return collection_library_;
  }
  void set_collection_library(const Library& value) {
    collection_library_ = value.raw();
  }

  RawLibrary* math_library() const {
    return math_library_;
  }
  void set_math_library(const Library& value) {
    math_library_ = value.raw();
  }

  RawLibrary* isolate_library() const {
    return isolate_library_;
  }
  void set_isolate_library(const Library& value) {
    isolate_library_ = value.raw();
  }

  RawLibrary* native_wrappers_library() const {
    return native_wrappers_library_;
  }
  void set_native_wrappers_library(const Library& value) {
    native_wrappers_library_ = value.raw();
  }

  RawLibrary* mirrors_library() const { return mirrors_library_; }
  void set_mirrors_library(const Library& value) {
    mirrors_library_ = value.raw();
  }

  RawLibrary* scalarlist_library() const {
    return scalarlist_library_;
  }
  void set_scalarlist_library(const Library& value) {
    scalarlist_library_ = value.raw();
  }

  RawLibrary* builtin_library() const {
    return builtin_library_;
  }
  void set_builtin_library(const Library& value) {
    builtin_library_ = value.raw();
  }

  RawLibrary* root_library() const { return root_library_; }
  void set_root_library(const Library& value) {
    root_library_ = value.raw();
  }

  RawGrowableObjectArray* libraries() const { return libraries_; }
  void set_libraries(const GrowableObjectArray& value) {
    libraries_ = value.raw();
  }

  RawGrowableObjectArray* pending_classes() const { return pending_classes_; }
  void set_pending_classes(const GrowableObjectArray& value) {
    ASSERT(!value.IsNull());
    pending_classes_ = value.raw();
  }

  RawError* sticky_error() const { return sticky_error_; }
  void set_sticky_error(const Error& value) {
    ASSERT(!value.IsNull());
    sticky_error_ = value.raw();
  }
  void clear_sticky_error() { sticky_error_ = Error::null(); }

  RawBool* true_value() const { return true_value_; }
  void set_true_value(const Bool& value) { true_value_ = value.raw(); }

  RawBool* false_value() const { return false_value_; }
  void set_false_value(const Bool& value) { false_value_ = value.raw(); }

  RawContext* empty_context() const { return empty_context_; }
  void set_empty_context(const Context& value) {
    empty_context_ = value.raw();
  }

  RawInstance* stack_overflow() const { return stack_overflow_; }
  void set_stack_overflow(const Instance& value) {
    stack_overflow_ = value.raw();
  }

  RawInstance* out_of_memory() const { return out_of_memory_; }
  void set_out_of_memory(const Instance& value) {
    out_of_memory_ = value.raw();
  }

  RawArray* keyword_symbols() const { return keyword_symbols_; }
  void set_keyword_symbols(const Array& value) {
    keyword_symbols_ = value.raw();
  }
  void InitKeywordTable();

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called to initialize objects required by the vm but which invoke
  // dart code.  If an error occurs then false is returned and error
  // information is stored in sticky_error().
  bool PreallocateObjects();

  static void Init(Isolate* isolate);

 private:
  ObjectStore();

  RawObject** from() { return reinterpret_cast<RawObject**>(&object_class_); }
  RawClass* object_class_;
  RawType* object_type_;
  RawType* null_type_;
  RawType* dynamic_type_;
  RawType* void_type_;
  RawType* function_type_;
  RawClass* type_class_;
  RawClass* type_parameter_class_;
  RawType* number_type_;
  RawType* int_type_;
  RawClass* integer_implementation_class_;
  RawClass* smi_class_;
  RawType* smi_type_;
  RawClass* mint_class_;
  RawType* mint_type_;
  RawClass* bigint_class_;
  RawClass* double_class_;
  RawType* double_type_;
  RawType* string_interface_;
  RawClass* one_byte_string_class_;
  RawClass* two_byte_string_class_;
  RawClass* four_byte_string_class_;
  RawClass* external_one_byte_string_class_;
  RawClass* external_two_byte_string_class_;
  RawClass* external_four_byte_string_class_;
  RawType* bool_type_;
  RawClass* bool_class_;
  RawType* list_interface_;
  RawClass* array_class_;
  RawClass* immutable_array_class_;
  RawClass* growable_object_array_class_;
  RawClass* int8_array_class_;
  RawClass* uint8_array_class_;
  RawClass* int16_array_class_;
  RawClass* uint16_array_class_;
  RawClass* int32_array_class_;
  RawClass* uint32_array_class_;
  RawClass* int64_array_class_;
  RawClass* uint64_array_class_;
  RawClass* float32_array_class_;
  RawClass* float64_array_class_;
  RawClass* external_int8_array_class_;
  RawClass* external_uint8_array_class_;
  RawClass* external_int16_array_class_;
  RawClass* external_uint16_array_class_;
  RawClass* external_int32_array_class_;
  RawClass* external_uint32_array_class_;
  RawClass* external_int64_array_class_;
  RawClass* external_uint64_array_class_;
  RawClass* external_float32_array_class_;
  RawClass* external_float64_array_class_;
  RawClass* stacktrace_class_;
  RawClass* jsregexp_class_;
  RawClass* weak_property_class_;
  RawBool* true_value_;
  RawBool* false_value_;
  RawArray* symbol_table_;
  RawArray* canonical_type_arguments_;
  RawLibrary* core_library_;
  RawLibrary* core_impl_library_;
  RawLibrary* collection_library_;
  RawLibrary* math_library_;
  RawLibrary* isolate_library_;
  RawLibrary* mirrors_library_;
  RawLibrary* scalarlist_library_;
  RawLibrary* native_wrappers_library_;
  RawLibrary* builtin_library_;
  RawLibrary* root_library_;
  RawGrowableObjectArray* libraries_;
  RawGrowableObjectArray* pending_classes_;
  RawError* sticky_error_;
  RawContext* empty_context_;
  RawInstance* stack_overflow_;
  RawInstance* out_of_memory_;
  RawArray* keyword_symbols_;
  RawObject** to() { return reinterpret_cast<RawObject**>(&keyword_symbols_); }

  friend class SnapshotReader;

  DISALLOW_COPY_AND_ASSIGN(ObjectStore);
};

}  // namespace dart

#endif  // VM_OBJECT_STORE_H_
