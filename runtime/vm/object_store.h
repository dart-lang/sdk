// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_STORE_H_
#define RUNTIME_VM_OBJECT_STORE_H_

#include "vm/object.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;

// A list of the bootstrap libraries including CamelName and name.
//
// These are listed in the order that they are compiled (see vm/bootstrap.cc).
#define FOR_EACH_BOOTSTRAP_LIBRARY(M)                                          \
  M(Core, core)                                                                \
  M(Async, async)                                                              \
  M(Collection, collection)                                                    \
  M(Convert, convert)                                                          \
  M(Developer, developer)                                                      \
  M(Internal, _internal)                                                       \
  M(Isolate, isolate)                                                          \
  M(Math, math)                                                                \
  M(Mirrors, mirrors)                                                          \
  M(Profiler, profiler)                                                        \
  M(TypedData, typed_data)                                                     \
  M(VMService, _vmservice)

// The object store is a per isolate instance which stores references to
// objects used by the VM.
// TODO(iposva): Move the actual store into the object heap for quick handling
// by snapshots eventually.
class ObjectStore {
 public:
  enum BootstrapLibraryId {
#define MAKE_ID(Name, _) k##Name,

    FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_ID)
#undef MAKE_ID
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
  void set_object_type(const Type& value) { object_type_ = value.raw(); }

  RawClass* null_class() const {
    ASSERT(null_class_ != Object::null());
    return null_class_;
  }
  void set_null_class(const Class& value) { null_class_ = value.raw(); }

  RawType* null_type() const { return null_type_; }
  void set_null_type(const Type& value) { null_type_ = value.raw(); }

  RawType* function_type() const { return function_type_; }
  void set_function_type(const Type& value) { function_type_ = value.raw(); }

  RawClass* closure_class() const { return closure_class_; }
  void set_closure_class(const Class& value) { closure_class_ = value.raw(); }

  RawType* number_type() const { return number_type_; }
  void set_number_type(const Type& value) { number_type_ = value.raw(); }

  RawType* int_type() const { return int_type_; }
  void set_int_type(const Type& value) { int_type_ = value.raw(); }
  static intptr_t int_type_offset() {
    return OFFSET_OF(ObjectStore, int_type_);
  }

  RawType* int64_type() const { return int64_type_; }
  void set_int64_type(const Type& value) { int64_type_ = value.raw(); }

  RawClass* integer_implementation_class() const {
    return integer_implementation_class_;
  }
  void set_integer_implementation_class(const Class& value) {
    integer_implementation_class_ = value.raw();
  }

  RawClass* smi_class() const { return smi_class_; }
  void set_smi_class(const Class& value) { smi_class_ = value.raw(); }

  RawType* smi_type() const { return smi_type_; }
  void set_smi_type(const Type& value) { smi_type_ = value.raw(); }

  RawClass* double_class() const { return double_class_; }
  void set_double_class(const Class& value) { double_class_ = value.raw(); }

  RawType* double_type() const { return double_type_; }
  void set_double_type(const Type& value) { double_type_ = value.raw(); }
  static intptr_t double_type_offset() {
    return OFFSET_OF(ObjectStore, double_type_);
  }

  RawClass* mint_class() const { return mint_class_; }
  void set_mint_class(const Class& value) { mint_class_ = value.raw(); }

  RawType* mint_type() const { return mint_type_; }
  void set_mint_type(const Type& value) { mint_type_ = value.raw(); }

  RawClass* bigint_class() const { return bigint_class_; }
  void set_bigint_class(const Class& value) { bigint_class_ = value.raw(); }

  RawType* string_type() const { return string_type_; }
  void set_string_type(const Type& value) { string_type_ = value.raw(); }
  static intptr_t string_type_offset() {
    return OFFSET_OF(ObjectStore, string_type_);
  }

  RawClass* compiletime_error_class() const { return compiletime_error_class_; }
  void set_compiletime_error_class(const Class& value) {
    compiletime_error_class_ = value.raw();
  }

  RawClass* future_class() const { return future_class_; }
  void set_future_class(const Class& value) { future_class_ = value.raw(); }

  RawClass* completer_class() const { return completer_class_; }
  void set_completer_class(const Class& value) {
    completer_class_ = value.raw();
  }

  RawClass* stream_iterator_class() const { return stream_iterator_class_; }
  void set_stream_iterator_class(const Class& value) {
    stream_iterator_class_ = value.raw();
  }

  RawClass* symbol_class() { return symbol_class_; }
  void set_symbol_class(const Class& value) { symbol_class_ = value.raw(); }

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

  RawClass* linked_hash_map_class() const { return linked_hash_map_class_; }
  void set_linked_hash_map_class(const Class& value) {
    linked_hash_map_class_ = value.raw();
  }

  RawClass* float32x4_class() const { return float32x4_class_; }
  void set_float32x4_class(const Class& value) {
    float32x4_class_ = value.raw();
  }

  RawType* float32x4_type() const { return float32x4_type_; }
  void set_float32x4_type(const Type& value) { float32x4_type_ = value.raw(); }

  RawClass* int32x4_class() const { return int32x4_class_; }
  void set_int32x4_class(const Class& value) { int32x4_class_ = value.raw(); }

  RawType* int32x4_type() const { return int32x4_type_; }
  void set_int32x4_type(const Type& value) { int32x4_type_ = value.raw(); }

  RawClass* float64x2_class() const { return float64x2_class_; }
  void set_float64x2_class(const Class& value) {
    float64x2_class_ = value.raw();
  }

  RawType* float64x2_type() const { return float64x2_type_; }
  void set_float64x2_type(const Type& value) { float64x2_type_ = value.raw(); }

  RawClass* error_class() const { return error_class_; }
  void set_error_class(const Class& value) { error_class_ = value.raw(); }
  static intptr_t error_class_offset() {
    return OFFSET_OF(ObjectStore, error_class_);
  }

  RawClass* weak_property_class() const { return weak_property_class_; }
  void set_weak_property_class(const Class& value) {
    weak_property_class_ = value.raw();
  }

  RawArray* symbol_table() const { return symbol_table_; }
  void set_symbol_table(const Array& value) { symbol_table_ = value.raw(); }

  RawArray* canonical_types() const { return canonical_types_; }
  void set_canonical_types(const Array& value) {
    canonical_types_ = value.raw();
  }

  RawArray* canonical_type_arguments() const {
    return canonical_type_arguments_;
  }
  void set_canonical_type_arguments(const Array& value) {
    canonical_type_arguments_ = value.raw();
  }

#define MAKE_GETTER(_, name)                                                   \
  RawLibrary* name##_library() const { return name##_library_; }

  FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_GETTER)
#undef MAKE_GETTER

  RawLibrary* bootstrap_library(BootstrapLibraryId index) {
    switch (index) {
#define MAKE_CASE(CamelName, name)                                             \
  case k##CamelName:                                                           \
    return name##_library_;

      FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_CASE)
#undef MAKE_CASE

      default:
        UNREACHABLE();
        return Library::null();
    }
  }

  void set_bootstrap_library(BootstrapLibraryId index, const Library& value) {
    switch (index) {
#define MAKE_CASE(CamelName, name)                                             \
  case k##CamelName:                                                           \
    name##_library_ = value.raw();                                             \
    break;

      FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_CASE)
#undef MAKE_CASE
      default:
        UNREACHABLE();
    }
  }

  RawLibrary* builtin_library() const { return builtin_library_; }
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
  void set_root_library(const Library& value) { root_library_ = value.raw(); }

  RawGrowableObjectArray* libraries() const { return libraries_; }
  void set_libraries(const GrowableObjectArray& value) {
    libraries_ = value.raw();
  }

  RawArray* libraries_map() const { return libraries_map_; }
  void set_libraries_map(const Array& value) { libraries_map_ = value.raw(); }

  RawGrowableObjectArray* closure_functions() const {
    return closure_functions_;
  }
  void set_closure_functions(const GrowableObjectArray& value) {
    ASSERT(!value.IsNull());
    closure_functions_ = value.raw();
  }

  RawGrowableObjectArray* pending_classes() const { return pending_classes_; }
  void set_pending_classes(const GrowableObjectArray& value) {
    ASSERT(!value.IsNull());
    pending_classes_ = value.raw();
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

  RawGrowableObjectArray* exit_listeners() const { return exit_listeners_; }

  RawGrowableObjectArray* error_listeners() const { return error_listeners_; }

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

  RawStackTrace* preallocated_stack_trace() const {
    return preallocated_stack_trace_;
  }
  void set_preallocated_stack_trace(const StackTrace& value) {
    preallocated_stack_trace_ = value.raw();
  }

  RawFunction* lookup_port_handler() const { return lookup_port_handler_; }
  void set_lookup_port_handler(const Function& function) {
    lookup_port_handler_ = function.raw();
  }

  RawTypedData* empty_uint32_array() const { return empty_uint32_array_; }
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

  RawArray* unique_dynamic_targets() const { return unique_dynamic_targets_; }
  void set_unique_dynamic_targets(const Array& value) {
    unique_dynamic_targets_ = value.raw();
  }

  RawGrowableObjectArray* token_objects() const { return token_objects_; }
  void set_token_objects(const GrowableObjectArray& value) {
    token_objects_ = value.raw();
  }

  RawArray* token_objects_map() const { return token_objects_map_; }
  void set_token_objects_map(const Array& value) {
    token_objects_map_ = value.raw();
  }

  RawArray* obfuscation_map() const { return obfuscation_map_; }
  void set_obfuscation_map(const Array& value) {
    obfuscation_map_ = value.raw();
  }

  RawGrowableObjectArray* megamorphic_cache_table() const {
    return megamorphic_cache_table_;
  }
  void set_megamorphic_cache_table(const GrowableObjectArray& value) {
    megamorphic_cache_table_ = value.raw();
  }
  RawCode* megamorphic_miss_code() const { return megamorphic_miss_code_; }
  RawFunction* megamorphic_miss_function() const {
    return megamorphic_miss_function_;
  }
  void SetMegamorphicMissHandler(const Code& code, const Function& func) {
    // Hold onto the code so it is traced and not detached from the function.
    megamorphic_miss_code_ = code.raw();
    megamorphic_miss_function_ = func.raw();
  }

  RawFunction* simple_instance_of_function() const {
    return simple_instance_of_function_;
  }
  void set_simple_instance_of_function(const Function& value) {
    simple_instance_of_function_ = value.raw();
  }
  RawFunction* simple_instance_of_true_function() const {
    return simple_instance_of_true_function_;
  }
  void set_simple_instance_of_true_function(const Function& value) {
    simple_instance_of_true_function_ = value.raw();
  }
  RawFunction* simple_instance_of_false_function() const {
    return simple_instance_of_false_function_;
  }
  void set_simple_instance_of_false_function(const Function& value) {
    simple_instance_of_false_function_ = value.raw();
  }
  RawFunction* async_clear_thread_stack_trace() const {
    return async_clear_thread_stack_trace_;
  }
  void set_async_clear_thread_stack_trace(const Function& func) {
    async_clear_thread_stack_trace_ = func.raw();
    ASSERT(async_clear_thread_stack_trace_ != Object::null());
  }
  RawFunction* async_set_thread_stack_trace() const {
    return async_set_thread_stack_trace_;
  }
  void set_async_set_thread_stack_trace(const Function& func) {
    async_set_thread_stack_trace_ = func.raw();
  }
  RawFunction* async_star_move_next_helper() const {
    return async_star_move_next_helper_;
  }
  void set_async_star_move_next_helper(const Function& func) {
    async_star_move_next_helper_ = func.raw();
  }
  RawFunction* complete_on_async_return() const {
    return complete_on_async_return_;
  }
  void set_complete_on_async_return(const Function& func) {
    complete_on_async_return_ = func.raw();
  }
  RawClass* async_star_stream_controller() const {
    return async_star_stream_controller_;
  }
  void set_async_star_stream_controller(const Class& cls) {
    async_star_stream_controller_ = cls.raw();
  }

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called to initialize objects required by the vm but which invoke
  // dart code.  If an error occurs the error object is returned otherwise
  // a null object is returned.
  RawError* PreallocateObjects();

  void InitKnownObjects();

  static void Init(Isolate* isolate);

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* jsobj);
#endif

 private:
  ObjectStore();

  // Finds a core library private method in Object.
  RawFunction* PrivateObjectLookup(const String& name);

#define OBJECT_STORE_FIELD_LIST(V)                                             \
  V(RawClass*, object_class_)                                                  \
  V(RawType*, object_type_)                                                    \
  V(RawClass*, null_class_)                                                    \
  V(RawType*, null_type_)                                                      \
  V(RawType*, function_type_)                                                  \
  V(RawClass*, closure_class_)                                                 \
  V(RawType*, number_type_)                                                    \
  V(RawType*, int_type_)                                                       \
  V(RawClass*, integer_implementation_class_)                                  \
  V(RawType*, int64_type_)                                                     \
  V(RawClass*, smi_class_)                                                     \
  V(RawType*, smi_type_)                                                       \
  V(RawClass*, mint_class_)                                                    \
  V(RawType*, mint_type_)                                                      \
  V(RawClass*, bigint_class_)                                                  \
  V(RawClass*, double_class_)                                                  \
  V(RawType*, double_type_)                                                    \
  V(RawType*, float32x4_type_)                                                 \
  V(RawType*, int32x4_type_)                                                   \
  V(RawType*, float64x2_type_)                                                 \
  V(RawType*, string_type_)                                                    \
  V(RawClass*, compiletime_error_class_)                                       \
  V(RawClass*, future_class_)                                                  \
  V(RawClass*, completer_class_)                                               \
  V(RawClass*, stream_iterator_class_)                                         \
  V(RawClass*, symbol_class_)                                                  \
  V(RawClass*, one_byte_string_class_)                                         \
  V(RawClass*, two_byte_string_class_)                                         \
  V(RawClass*, external_one_byte_string_class_)                                \
  V(RawClass*, external_two_byte_string_class_)                                \
  V(RawType*, bool_type_)                                                      \
  V(RawClass*, bool_class_)                                                    \
  V(RawClass*, array_class_)                                                   \
  V(RawType*, array_type_)                                                     \
  V(RawClass*, immutable_array_class_)                                         \
  V(RawClass*, growable_object_array_class_)                                   \
  V(RawClass*, linked_hash_map_class_)                                         \
  V(RawClass*, float32x4_class_)                                               \
  V(RawClass*, int32x4_class_)                                                 \
  V(RawClass*, float64x2_class_)                                               \
  V(RawClass*, error_class_)                                                   \
  V(RawClass*, weak_property_class_)                                           \
  V(RawArray*, symbol_table_)                                                  \
  V(RawArray*, canonical_types_)                                               \
  V(RawArray*, canonical_type_arguments_)                                      \
  V(RawLibrary*, async_library_)                                               \
  V(RawLibrary*, builtin_library_)                                             \
  V(RawLibrary*, core_library_)                                                \
  V(RawLibrary*, collection_library_)                                          \
  V(RawLibrary*, convert_library_)                                             \
  V(RawLibrary*, developer_library_)                                           \
  V(RawLibrary*, _internal_library_)                                           \
  V(RawLibrary*, isolate_library_)                                             \
  V(RawLibrary*, math_library_)                                                \
  V(RawLibrary*, mirrors_library_)                                             \
  V(RawLibrary*, native_wrappers_library_)                                     \
  V(RawLibrary*, profiler_library_)                                            \
  V(RawLibrary*, root_library_)                                                \
  V(RawLibrary*, typed_data_library_)                                          \
  V(RawLibrary*, _vmservice_library_)                                          \
  V(RawGrowableObjectArray*, libraries_)                                       \
  V(RawArray*, libraries_map_)                                                 \
  V(RawGrowableObjectArray*, closure_functions_)                               \
  V(RawGrowableObjectArray*, pending_classes_)                                 \
  V(RawGrowableObjectArray*, pending_deferred_loads_)                          \
  V(RawGrowableObjectArray*, resume_capabilities_)                             \
  V(RawGrowableObjectArray*, exit_listeners_)                                  \
  V(RawGrowableObjectArray*, error_listeners_)                                 \
  V(RawInstance*, stack_overflow_)                                             \
  V(RawInstance*, out_of_memory_)                                              \
  V(RawUnhandledException*, preallocated_unhandled_exception_)                 \
  V(RawStackTrace*, preallocated_stack_trace_)                                 \
  V(RawFunction*, lookup_port_handler_)                                        \
  V(RawTypedData*, empty_uint32_array_)                                        \
  V(RawFunction*, handle_message_function_)                                    \
  V(RawFunction*, simple_instance_of_function_)                                \
  V(RawFunction*, simple_instance_of_true_function_)                           \
  V(RawFunction*, simple_instance_of_false_function_)                          \
  V(RawFunction*, async_clear_thread_stack_trace_)                             \
  V(RawFunction*, async_set_thread_stack_trace_)                               \
  V(RawFunction*, async_star_move_next_helper_)                                \
  V(RawFunction*, complete_on_async_return_)                                   \
  V(RawClass*, async_star_stream_controller_)                                  \
  V(RawArray*, library_load_error_table_)                                      \
  V(RawArray*, unique_dynamic_targets_)                                        \
  V(RawGrowableObjectArray*, token_objects_)                                   \
  V(RawArray*, token_objects_map_)                                             \
  V(RawGrowableObjectArray*, megamorphic_cache_table_)                         \
  V(RawCode*, megamorphic_miss_code_)                                          \
  V(RawFunction*, megamorphic_miss_function_)                                  \
  V(RawArray*, obfuscation_map_)                                               \
  // Please remember the last entry must be referred in the 'to' function below.

  RawObject** from() { return reinterpret_cast<RawObject**>(&object_class_); }
#define DECLARE_OBJECT_STORE_FIELD(type, name) type name;
  OBJECT_STORE_FIELD_LIST(DECLARE_OBJECT_STORE_FIELD)
#undef DECLARE_OBJECT_STORE_FIELD
  RawObject** to() { return reinterpret_cast<RawObject**>(&obfuscation_map_); }
  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFull:
        return reinterpret_cast<RawObject**>(&library_load_error_table_);
      case Snapshot::kFullJIT:
      case Snapshot::kFullAOT:
        return reinterpret_cast<RawObject**>(&megamorphic_miss_function_);
      case Snapshot::kScript:
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }

  friend class Serializer;
  friend class Deserializer;

  DISALLOW_COPY_AND_ASSIGN(ObjectStore);
};

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_STORE_H_
