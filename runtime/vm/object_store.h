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
  enum BootstrapLibraryId {
    kNone = 0,
    kAsync,
    kCore,
    kCollection,
    kConvert,
    kInternal,
    kIsolate,
    kMath,
    kMirrors,
    kTypedData,
    kProfiler,
  };

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

  RawClass* null_class() const {
    ASSERT(null_class_ != Object::null());
    return null_class_;
  }
  void set_null_class(const Class& value) { null_class_ = value.raw(); }

  RawType* null_type() const { return null_type_; }
  void set_null_type(const Type& value) {
    null_type_ = value.raw();
  }

  RawType* function_type() const { return function_type_; }
  void set_function_type(const Type& value) {
    function_type_ = value.raw();
  }

  RawType* function_impl_type() const { return function_impl_type_; }
  void set_function_impl_type(const Type& value) {
    function_impl_type_ = value.raw();
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

  RawType* string_type() const { return string_type_; }
  void set_string_type(const Type& value) {
    string_type_ = value.raw();
  }

  RawClass* future_class() const { return future_class_; }
  void set_future_class(const Class& value) {
    future_class_ = value.raw();
  }

  RawClass* completer_class() const { return completer_class_; }
  void set_completer_class(const Class& value) {
    completer_class_ = value.raw();
  }

  RawClass* one_byte_string_class() const { return one_byte_string_class_; }
  void set_one_byte_string_class(const Class& value) {
    one_byte_string_class_ = value.raw();
  }

  RawClass* two_byte_string_class() const { return two_byte_string_class_; }
  void set_two_byte_string_class(const Class& value) {
    two_byte_string_class_ = value.raw();
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

  RawType* bool_type() const { return bool_type_; }
  void set_bool_type(const Type& value) { bool_type_ = value.raw(); }

  RawClass* bool_class() const { return bool_class_; }
  void set_bool_class(const Class& value) { bool_class_ = value.raw(); }

  RawClass* array_class() const { return array_class_; }
  void set_array_class(const Class& value) { array_class_ = value.raw(); }
  static intptr_t array_class_offset() {
    return OFFSET_OF(ObjectStore, array_class_);
  }

  RawType* array_type() const { return array_type_; }
  void set_array_type(const Type& value) { array_type_ = value.raw(); }

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

  RawClass* linked_hash_map_class() const {
    return linked_hash_map_class_;
  }
  void set_linked_hash_map_class(const Class& value) {
    linked_hash_map_class_ = value.raw();
  }

  RawClass* float32x4_class() const {
    return float32x4_class_;
  }
  void set_float32x4_class(const Class& value) {
    float32x4_class_ = value.raw();
  }

  RawType* float32x4_type() const { return float32x4_type_; }
  void set_float32x4_type(const Type& value) { float32x4_type_ = value.raw(); }

  RawClass* int32x4_class() const {
    return int32x4_class_;
  }
  void set_int32x4_class(const Class& value) {
    int32x4_class_ = value.raw();
  }

  RawType* int32x4_type() const { return int32x4_type_; }
  void set_int32x4_type(const Type& value) { int32x4_type_ = value.raw(); }

  RawClass* float64x2_class() const {
    return float64x2_class_;
  }
  void set_float64x2_class(const Class& value) {
    float64x2_class_ = value.raw();
  }

  RawType* float64x2_type() const { return float64x2_type_; }
  void set_float64x2_type(const Type& value) { float64x2_type_ = value.raw(); }

  RawClass* error_class() const {
    return error_class_;
  }
  void set_error_class(const Class& value) {
    error_class_ = value.raw();
  }
  static intptr_t error_class_offset() {
    return OFFSET_OF(ObjectStore, error_class_);
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

  RawLibrary* async_library() const { return async_library_; }
  RawLibrary* builtin_library() const { return builtin_library_; }
  RawLibrary* core_library() const { return core_library_; }
  RawLibrary* collection_library() const { return collection_library_; }
  RawLibrary* convert_library() const { return convert_library_; }
  RawLibrary* internal_library() const { return internal_library_; }
  RawLibrary* isolate_library() const { return isolate_library_; }
  RawLibrary* math_library() const { return math_library_; }
  RawLibrary* mirrors_library() const { return mirrors_library_; }
  RawLibrary* typed_data_library() const { return typed_data_library_; }
  RawLibrary* profiler_library() const { return profiler_library_; }
  void set_bootstrap_library(BootstrapLibraryId index, const Library& value) {
    switch (index) {
      case kAsync:
        async_library_ = value.raw();
        break;
      case kCore:
        core_library_ = value.raw();
        break;
      case kCollection:
        collection_library_ = value.raw();
        break;
      case kConvert:
        convert_library_ = value.raw();
        break;
      case kInternal:
        internal_library_ = value.raw();
        break;
      case kIsolate:
        isolate_library_ = value.raw();
        break;
      case kMath:
        math_library_ = value.raw();
        break;
      case kMirrors:
        mirrors_library_ = value.raw();
        break;
      case kTypedData:
        typed_data_library_ = value.raw();
        break;
      case kProfiler:
        profiler_library_ = value.raw();
        break;
      default:
        UNREACHABLE();
    }
  }

  void set_builtin_library(const Library& value) {
    builtin_library_ = value.raw();
  }

  RawLibrary* native_wrappers_library() const {
    return native_wrappers_library_;
  }
  void set_native_wrappers_library(const Library& value) {
    native_wrappers_library_ = value.raw();
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

  RawGrowableObjectArray* pending_functions() const {
    return pending_functions_;
  }

  RawGrowableObjectArray* pending_deferred_loads() const {
    return pending_deferred_loads_;
  }
  void clear_pending_deferred_loads() {
    pending_deferred_loads_ = GrowableObjectArray::New();
  }

  RawGrowableObjectArray* resume_capabilities() const {
    return resume_capabilities_;
  }

  RawError* sticky_error() const { return sticky_error_; }
  void set_sticky_error(const Error& value) {
    ASSERT(!value.IsNull());
    sticky_error_ = value.raw();
  }
  void clear_sticky_error() { sticky_error_ = Error::null(); }

  RawString* unhandled_exception_handler() const {
    return unhandled_exception_handler_;
  }
  void set_unhandled_exception_handler(const String& value) {
    unhandled_exception_handler_ = value.raw();
  }

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

  RawUnhandledException* preallocated_unhandled_exception() const {
    return preallocated_unhandled_exception_;
  }
  void set_preallocated_unhandled_exception(const UnhandledException& value) {
    preallocated_unhandled_exception_ = value.raw();
  }

  RawStacktrace* preallocated_stack_trace() const {
    return preallocated_stack_trace_;
  }
  void set_preallocated_stack_trace(const Stacktrace& value) {
    preallocated_stack_trace_ = value.raw();
  }

  RawFunction* lookup_port_handler() const {
    return lookup_port_handler_;
  }
  void set_lookup_port_handler(const Function& function) {
    lookup_port_handler_ = function.raw();
  }

  RawTypedData* empty_uint32_array() const {
    return empty_uint32_array_;
  }
  void set_empty_uint32_array(const TypedData& array) {
    // Only set once.
    ASSERT(empty_uint32_array_ == TypedData::null());
    ASSERT(!array.IsNull());
    empty_uint32_array_ = array.raw();
  }

  RawFunction* handle_message_function() const {
    return handle_message_function_;
  }
  void set_handle_message_function(const Function& function) {
    handle_message_function_ = function.raw();
  }

  RawArray* library_load_error_table() const {
    return library_load_error_table_;
  }
  void set_library_load_error_table(const Array& table) {
    library_load_error_table_ = table.raw();
  }
  static intptr_t library_load_error_table_offset() {
    return OFFSET_OF(ObjectStore, library_load_error_table_);
  }

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called to initialize objects required by the vm but which invoke
  // dart code.  If an error occurs then false is returned and error
  // information is stored in sticky_error().
  bool PreallocateObjects();

  void InitAsyncObjects();

  static void Init(Isolate* isolate);

 private:
  ObjectStore();

  RawObject** from() { return reinterpret_cast<RawObject**>(&object_class_); }
  RawClass* object_class_;
  RawType* object_type_;
  RawClass* null_class_;
  RawType* null_type_;
  RawType* function_type_;
  RawType* function_impl_type_;
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
  RawType* float32x4_type_;
  RawType* int32x4_type_;
  RawType* float64x2_type_;
  RawType* string_type_;
  RawClass* future_class_;
  RawClass* completer_class_;
  RawClass* one_byte_string_class_;
  RawClass* two_byte_string_class_;
  RawClass* external_one_byte_string_class_;
  RawClass* external_two_byte_string_class_;
  RawType* bool_type_;
  RawClass* bool_class_;
  RawClass* array_class_;
  RawType* array_type_;
  RawClass* immutable_array_class_;
  RawClass* growable_object_array_class_;
  RawClass* linked_hash_map_class_;
  RawClass* float32x4_class_;
  RawClass* int32x4_class_;
  RawClass* float64x2_class_;
  RawClass* error_class_;
  RawClass* weak_property_class_;
  RawArray* symbol_table_;
  RawArray* canonical_type_arguments_;
  RawLibrary* async_library_;
  RawLibrary* builtin_library_;
  RawLibrary* core_library_;
  RawLibrary* collection_library_;
  RawLibrary* convert_library_;
  RawLibrary* internal_library_;
  RawLibrary* isolate_library_;
  RawLibrary* math_library_;
  RawLibrary* mirrors_library_;
  RawLibrary* native_wrappers_library_;
  RawLibrary* root_library_;
  RawLibrary* typed_data_library_;
  RawLibrary* profiler_library_;
  RawGrowableObjectArray* libraries_;
  RawGrowableObjectArray* pending_classes_;
  RawGrowableObjectArray* pending_functions_;
  RawGrowableObjectArray* pending_deferred_loads_;
  RawGrowableObjectArray* resume_capabilities_;
  RawError* sticky_error_;
  RawString* unhandled_exception_handler_;
  RawContext* empty_context_;
  RawInstance* stack_overflow_;
  RawInstance* out_of_memory_;
  RawUnhandledException* preallocated_unhandled_exception_;
  RawStacktrace* preallocated_stack_trace_;
  RawFunction* lookup_port_handler_;
  RawTypedData* empty_uint32_array_;
  RawFunction* handle_message_function_;
  RawArray* library_load_error_table_;
  RawObject** to() {
    return reinterpret_cast<RawObject**>(&library_load_error_table_);
  }

  friend class SnapshotReader;

  DISALLOW_COPY_AND_ASSIGN(ObjectStore);
};

}  // namespace dart

#endif  // VM_OBJECT_STORE_H_
