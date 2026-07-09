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
  M(CompactHash, _compact_hash)                                                \
  M(Collection, collection)                                                    \
  M(Convert, convert)                                                          \
  M(Developer, developer)                                                      \
  M(Ffi, ffi)                                                                  \
  M(Internal, _internal)                                                       \
  M(Isolate, isolate)                                                          \
  M(Math, math)                                                                \
  M(Mirrors, mirrors)                                                          \
  M(TypedData, typed_data)                                                     \
  M(VM, _vm)                                                                   \
  M(VMService, _vmservice)                                                     \
  M(Concurrent, concurrent)

// R_ - needs getter only
// RW - needs getter and setter
// ARW_RELAXED - needs getter and setter with relaxed atomic access
// ARW_AR - needs getter and setter with acq/rel atomic access
// LAZY_CORE - needs lazy init getter for a "dart:core" member
// LAZY_ASYNC - needs lazy init getter for a "dart:async" member
// LAZY_ISOLATE - needs lazy init getter for a "dart:isolate" member
// LAZY_INTERNAL - needs lazy init getter for a "dart:_internal" member
#define OBJECT_STORE_FIELD_LIST(R_, RW, ARW_RELAXED, ARW_AR, LAZY_CORE,        \
                                LAZY_ASYNC, LAZY_ISOLATE, LAZY_INTERNAL,       \
                                LAZY_FFI)                                      \
  LAZY_CORE(Class, list_class)                                                 \
  LAZY_CORE(Class, map_class)                                                  \
  LAZY_CORE(Class, set_class)                                                  \
  LAZY_CORE(Class, bigint_impl_class)                                          \
  LAZY_CORE(Type, non_nullable_list_rare_type)                                 \
  LAZY_CORE(Type, non_nullable_map_rare_type)                                  \
  LAZY_CORE(Field, enum_index_field)                                           \
  LAZY_CORE(Field, enum_name_field)                                            \
  LAZY_CORE(Function, _object_equals_function)                                 \
  LAZY_CORE(Function, _object_hash_code_function)                              \
  LAZY_CORE(Function, _object_to_string_function)                              \
  LAZY_INTERNAL(Class, symbol_class)                                           \
  LAZY_INTERNAL(Field, symbol_name_field)                                      \
  LAZY_FFI(Class, ffi_array_class)                                             \
  LAZY_FFI(Class, ffi_compound_class)                                          \
  LAZY_FFI(Class, ffi_struct_class)                                            \
  LAZY_FFI(Class, ffi_union_class)                                             \
  LAZY_FFI(Class, ffi_varargs_class)                                           \
  LAZY_FFI(Field, compound_offset_in_bytes_field)                              \
  LAZY_FFI(Field, compound_typed_data_base_field)                              \
  LAZY_FFI(Function, ffi_resolver_function)                                    \
  LAZY_FFI(Function, handle_finalizer_message_function)                        \
  LAZY_FFI(Function, handle_native_finalizer_message_function)                 \
  LAZY_ASYNC(Type, non_nullable_future_never_type)                             \
  LAZY_ASYNC(Type, nullable_future_null_type)                                  \
  LAZY_ISOLATE(Class, send_port_class)                                         \
  LAZY_ISOLATE(Class, capability_class)                                        \
  LAZY_ISOLATE(Class, transferable_class)                                      \
  LAZY_ISOLATE(Function, lookup_port_handler)                                  \
  LAZY_ISOLATE(Function, lookup_open_ports)                                    \
  LAZY_ISOLATE(Function, handle_message_function)                              \
  RW(Class, object_class)                                                      \
  RW(Type, object_type)                                                        \
  RW(Type, non_nullable_object_type)                                           \
  RW(Type, nullable_object_type)                                               \
  RW(Class, null_class)                                                        \
  RW(Type, null_type)                                                          \
  RW(Class, never_class)                                                       \
  RW(Type, never_type)                                                         \
  RW(Type, function_type)                                                      \
  RW(Type, type_type)                                                          \
  RW(Class, closure_class)                                                     \
  RW(Class, record_class)                                                      \
  RW(Type, number_type)                                                        \
  RW(Type, nullable_number_type)                                               \
  RW(Type, int_type)                                                           \
  RW(Type, non_nullable_int_type)                                              \
  RW(Type, nullable_int_type)                                                  \
  RW(Class, integer_implementation_class)                                      \
  RW(Type, int64_type)                                                         \
  RW(Class, smi_class)                                                         \
  RW(Type, smi_type)                                                           \
  RW(Class, mint_class)                                                        \
  RW(Type, mint_type)                                                          \
  RW(Class, double_class)                                                      \
  RW(Type, double_type)                                                        \
  RW(Type, nullable_double_type)                                               \
  RW(Type, float32x4_type)                                                     \
  RW(Type, int32x4_type)                                                       \
  RW(Type, float64x2_type)                                                     \
  RW(Type, string_type)                                                        \
  RW(TypeArguments, type_argument_int)                                         \
  RW(TypeArguments, type_argument_double)                                      \
  RW(TypeArguments, type_argument_never)                                       \
  RW(TypeArguments, type_argument_string)                                      \
  RW(TypeArguments, type_argument_string_dynamic)                              \
  RW(TypeArguments, type_argument_string_string)                               \
  RW(Class, compiletime_error_class)                                           \
  RW(Class, pragma_class)                                                      \
  RW(Field, pragma_name)                                                       \
  RW(Field, pragma_options)                                                    \
  RW(Class, future_class)                                                      \
  RW(Class, future_or_class)                                                   \
  RW(Class, one_byte_string_class)                                             \
  RW(Class, two_byte_string_class)                                             \
  RW(Type, bool_type)                                                          \
  RW(Class, bool_class)                                                        \
  RW(Class, array_class)                                                       \
  RW(Type, array_type)                                                         \
  RW(Class, immutable_array_class)                                             \
  RW(Class, growable_object_array_class)                                       \
  RW(Class, map_impl_class)                                                    \
  RW(Class, const_map_impl_class)                                              \
  RW(Class, set_impl_class)                                                    \
  RW(Class, const_set_impl_class)                                              \
  RW(Class, float32x4_class)                                                   \
  RW(Class, int32x4_class)                                                     \
  RW(Class, float64x2_class)                                                   \
  RW(Class, error_class)                                                       \
  RW(Class, expando_class)                                                     \
  RW(Class, iterable_class)                                                    \
  RW(Class, weak_property_class)                                               \
  RW(Class, weak_reference_class)                                              \
  RW(Class, finalizer_class)                                                   \
  RW(Class, finalizer_entry_class)                                             \
  RW(Class, native_finalizer_class)                                            \
  RW(Class, dart_condition_variable_class)                                     \
  RW(Class, dart_mutex_class)                                                  \
  RW(Class, ffi_pointer_class)                                                 \
  RW(Class, ffi_native_type_class)                                             \
  ARW_AR(WeakArray, symbol_table)                                              \
  ARW_AR(WeakArray, regexp_table)                                              \
  RW(Array, canonical_types)                                                   \
  RW(Array, canonical_function_types)                                          \
  RW(Array, canonical_record_types)                                            \
  RW(Array, canonical_type_parameters)                                         \
  RW(Array, canonical_type_arguments)                                          \
  RW(Library, async_library)                                                   \
  RW(Library, core_library)                                                    \
  RW(Library, _compact_hash_library)                                           \
  RW(Library, collection_library)                                              \
  RW(Library, concurrent_library)                                              \
  RW(Library, convert_library)                                                 \
  RW(Library, developer_library)                                               \
  RW(Library, ffi_library)                                                     \
  RW(Library, _internal_library)                                               \
  RW(Library, isolate_library)                                                 \
  RW(Library, math_library)                                                    \
  RW(Library, mirrors_library)                                                 \
  RW(Library, native_wrappers_library)                                         \
  RW(Library, root_library)                                                    \
  RW(Library, typed_data_library)                                              \
  RW(Library, _vm_library)                                                     \
  RW(Library, _vmservice_library)                                              \
  RW(Library, native_assets_library)                                           \
  RW(Array, native_assets_map)                                                 \
  RW(GrowableObjectArray, libraries)                                           \
  RW(Array, libraries_map)                                                     \
  RW(Array, uri_to_resolved_uri_map)                                           \
  RW(Array, resolved_uri_to_uri_map)                                           \
  RW(Smi, last_libraries_count)                                                \
  RW(Array, loading_units)                                                     \
  RW(GrowableObjectArray, closure_functions)                                   \
  RW(Array, closure_functions_table)                                           \
  RW(GrowableObjectArray, pending_classes)                                     \
  RW(Array, record_field_names_map)                                            \
  ARW_AR(Array, record_field_names)                                            \
  RW(Instance, stack_overflow)                                                 \
  RW(Instance, out_of_memory)                                                  \
  RW(Function, growable_list_factory)                                          \
  RW(Function, simple_instance_of_function)                                    \
  RW(Function, simple_instance_of_true_function)                               \
  RW(Function, simple_instance_of_false_function)                              \
  RW(Function, async_star_stream_controller_add)                               \
  RW(Function, async_star_stream_controller_add_stream)                        \
  RW(Function, suspend_state_init_async)                                       \
  RW(Function, suspend_state_await)                                            \
  RW(Function, suspend_state_await_with_type_check)                            \
  RW(Function, suspend_state_return_async)                                     \
  RW(Function, suspend_state_return_async_not_future)                          \
  RW(Function, suspend_state_init_async_star)                                  \
  RW(Function, suspend_state_yield_async_star)                                 \
  RW(Function, suspend_state_return_async_star)                                \
  RW(Function, suspend_state_init_sync_star)                                   \
  RW(Function, suspend_state_suspend_sync_star_at_start)                       \
  RW(Function, suspend_state_handle_exception)                                 \
  RW(Class, async_star_stream_controller)                                      \
  RW(Class, stream_class)                                                      \
  RW(Class, sync_star_iterator_class)                                          \
  RW(Field, async_star_stream_controller_async_star_body)                      \
  RW(Field, sync_star_iterator_current)                                        \
  RW(Field, sync_star_iterator_state)                                          \
  RW(Field, sync_star_iterator_yield_star_iterable)                            \
  RW(CompressedStackMaps, canonicalized_stack_map_entries)                     \
  RW(ObjectPool, global_object_pool)                                           \
  RW(Array, unique_dynamic_targets)                                            \
  RW(Array, saved_unlinked_calls)                                              \
  RW(GrowableObjectArray, megamorphic_cache_table)                             \
  RW(GrowableObjectArray, ffi_callback_code)                                   \
  ARW_AR(Class, typed_data_class)                                              \
  RW(Array, ffi_callback_functions)                                            \
  /* Roots for JIT/AOT snapshots are up until here (see to_snapshot() below)*/ \
  RW(Array, dispatch_table_code_entries)                                       \
  RW(GrowableObjectArray, instructions_tables)                                 \
  RW(GrowableObjectArray, tag_table)                                           \
  RW(Array, obfuscation_map)                                                   \
  RW(Array, loading_unit_uris)                                                 \
  // Please remember the last entry must be referred in the 'to' function below.

#define ISOLATE_OBJECT_STORE_FIELD_LIST(R_, RW)                                \
  R_(Array, dart_args_1)                                                       \
  R_(Array, dart_args_2)                                                       \
  RW(Array, thread_locals)                                                     \
  R_(GrowableObjectArray, resume_capabilities)                                 \
  R_(GrowableObjectArray, exit_listeners)                                      \
  R_(GrowableObjectArray, error_listeners)
// Please remember the last entry must be referred in the 'to' function below.

class IsolateObjectStore {
 public:
  IsolateObjectStore() {}
  ~IsolateObjectStore() {}

#define DECLARE_GETTER(Type, name)                                             \
  Type##Ptr name() const { return name##_; }                                   \
  static intptr_t name##_offset() {                                            \
    return OFFSET_OF(IsolateObjectStore, name##_);                             \
  }

#define DECLARE_GETTER_AND_SETTER(Type, name)                                  \
  DECLARE_GETTER(Type, name)                                                   \
  void set_##name(const Type& value) { name##_ = value.ptr(); }
  ISOLATE_OBJECT_STORE_FIELD_LIST(DECLARE_GETTER, DECLARE_GETTER_AND_SETTER)
#undef DECLARE_GETTER
#undef DECLARE_GETTER_AND_SETTER

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called to initialize objects required by the vm but which invoke
  // dart code.  If an error occurs the error object is returned otherwise
  // a null object is returned.
  ErrorPtr PreallocateObjects();

  void Init();
  void PostLoad();

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* jsobj);
#endif

 private:
  // Finds a core library private method in Object.
  FunctionPtr PrivateObjectLookup(const String& name);

  ObjectPtr* from() { return reinterpret_cast<ObjectPtr*>(&dart_args_1_); }
#define DECLARE_OBJECT_STORE_FIELD(type, name) type##Ptr name##_;
  ISOLATE_OBJECT_STORE_FIELD_LIST(DECLARE_OBJECT_STORE_FIELD,
                                  DECLARE_OBJECT_STORE_FIELD)
#undef DECLARE_OBJECT_STORE_FIELD
  ObjectPtr* to() { return reinterpret_cast<ObjectPtr*>(&error_listeners_); }

  friend class Serializer;
  friend class Deserializer;

  DISALLOW_COPY_AND_ASSIGN(IsolateObjectStore);
};

// The object store is a per isolate group instance which stores references to
// objects used by the VM shared by all isolates in a group.
class ObjectStore {
 public:
  enum BootstrapLibraryId {
#define MAKE_ID(Name, _) k##Name,

    FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_ID)
#undef MAKE_ID
  };

  ObjectStore();
  ~ObjectStore();

#define DECLARE_OFFSET(name)                                                   \
  static intptr_t name##_offset() { return OFFSET_OF(ObjectStore, name##_); }
#define DECLARE_GETTER(Type, name)                                             \
  Type##Ptr name() const { return name##_; }                                   \
  DECLARE_OFFSET(name)
#define DECLARE_GETTER_AND_SETTER(Type, name)                                  \
  DECLARE_GETTER(Type, name)                                                   \
  void set_##name(const Type& value) { name##_ = value.ptr(); }
#define DECLARE_RELAXED_ATOMIC_GETTER_AND_SETTER(Type, name)                   \
  template <std::memory_order order = std::memory_order_relaxed>               \
  Type##Ptr name() const {                                                     \
    return name##_.load(order);                                                \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##name(const Type& value) {                                         \
    name##_.store(value.ptr(), order);                                         \
  }                                                                            \
  DECLARE_OFFSET(name)
#define DECLARE_ACQREL_ATOMIC_GETTER_AND_SETTER(Type, name)                    \
  Type##Ptr name() const { return name##_.load(); }                            \
  void set_##name(const Type& value) { name##_.store(value.ptr()); }           \
  DECLARE_OFFSET(name)
#define DECLARE_LAZY_INIT_GETTER(Type, name, init)                             \
  Type##Ptr name() {                                                           \
    if (name##_.load() == Type::null()) {                                      \
      init();                                                                  \
    }                                                                          \
    return name##_.load();                                                     \
  }                                                                            \
  DECLARE_OFFSET(name)
#define DECLARE_LAZY_INIT_CORE_GETTER(Type, name)                              \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitCoreMembers)
#define DECLARE_LAZY_INIT_ASYNC_GETTER(Type, name)                             \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitAsyncMembers)
#define DECLARE_LAZY_INIT_ISOLATE_GETTER(Type, name)                           \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitIsolateMembers)
#define DECLARE_LAZY_INIT_INTERNAL_GETTER(Type, name)                          \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitInternalMembers)
#define DECLARE_LAZY_INIT_FFI_GETTER(Type, name)                               \
  DECLARE_LAZY_INIT_GETTER(Type, name, LazyInitFfiMembers)
  OBJECT_STORE_FIELD_LIST(DECLARE_GETTER,
                          DECLARE_GETTER_AND_SETTER,
                          DECLARE_RELAXED_ATOMIC_GETTER_AND_SETTER,
                          DECLARE_ACQREL_ATOMIC_GETTER_AND_SETTER,
                          DECLARE_LAZY_INIT_CORE_GETTER,
                          DECLARE_LAZY_INIT_ASYNC_GETTER,
                          DECLARE_LAZY_INIT_ISOLATE_GETTER,
                          DECLARE_LAZY_INIT_INTERNAL_GETTER,
                          DECLARE_LAZY_INIT_FFI_GETTER)
#undef DECLARE_OFFSET
#undef DECLARE_GETTER
#undef DECLARE_GETTER_AND_SETTER
#undef DECLARE_RELAXED_ATOMIC_GETTER_AND_SETTER
#undef DECLARE_ACQREL_ATOMIC_GETTER_AND_SETTER
#undef DECLARE_LAZY_INIT_GETTER
#undef DECLARE_LAZY_INIT_CORE_GETTER
#undef DECLARE_LAZY_INIT_ASYNC_GETTER
#undef DECLARE_LAZY_INIT_ISOLATE_GETTER
#undef DECLARE_LAZY_INIT_INTERNAL_GETTER
#undef DECLARE_LAZY_INIT_FFI_GETTER

  LibraryPtr bootstrap_library(BootstrapLibraryId index) {
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
    name##_library_ = value.ptr();                                             \
    break;

      FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_CASE)
#undef MAKE_CASE
      default:
        UNREACHABLE();
    }
  }

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Called to initialize objects required by the vm but which invoke
  // dart code.  If an error occurs the error object is returned otherwise
  // a null object is returned.
  ErrorPtr PreallocateObjects();

  void InitKnownObjects();

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* jsobj);
#endif

 private:
  void LazyInitCoreMembers();
  void LazyInitAsyncMembers();
  void LazyInitFfiMembers();
  void LazyInitIsolateMembers();
  void LazyInitInternalMembers();

  // Finds a core library private method in Object.
  FunctionPtr PrivateObjectLookup(const String& name);

  ObjectPtr* from() { return reinterpret_cast<ObjectPtr*>(&list_class_); }
#define DECLARE_OBJECT_STORE_FIELD(type, name) type##Ptr name##_;
#define DECLARE_ATOMIC_OBJECT_STORE_FIELD(type, name)                          \
  std::atomic<type##Ptr> name##_;
#define DECLARE_LAZY_OBJECT_STORE_FIELD(type, name)                            \
  AcqRelAtomic<type##Ptr> name##_;
  OBJECT_STORE_FIELD_LIST(DECLARE_OBJECT_STORE_FIELD,
                          DECLARE_OBJECT_STORE_FIELD,
                          DECLARE_ATOMIC_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD,
                          DECLARE_LAZY_OBJECT_STORE_FIELD)
#undef DECLARE_OBJECT_STORE_FIELD
#undef DECLARE_ATOMIC_OBJECT_STORE_FIELD
#undef DECLARE_LAZY_OBJECT_STORE_FIELD
  ObjectPtr* to() { return reinterpret_cast<ObjectPtr*>(&loading_unit_uris_); }
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFull:
        return reinterpret_cast<ObjectPtr*>(&global_object_pool_);
      case Snapshot::kFullJIT:
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&ffi_callback_functions_);
      case Snapshot::kModule:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }
  uword unused_field_;

  friend class ProgramSerializationRoots;
  friend class ProgramDeserializationRoots;
  friend class ProgramVisitor;

  DISALLOW_COPY_AND_ASSIGN(ObjectStore);
};

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_STORE_H_
